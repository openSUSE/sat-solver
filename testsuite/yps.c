/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * yps - without gimmick
 * 
 * command line interface to solver
 * Usage:
 *   yps <system> <repo> [ ... <repo>] <name>
 *     to install a package <name>
 * 
 *   yps -e <system> <name>
 *     to erase a package <name>
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "pool.h"
#include "poolarch.h"
#include "repo_solv.h"
#include "solver.h"
#include "solverdebug.h"
#include "policy.h"
#include "evr.h"

// find solvable by name
//   If repo != NULL, find there (installed packages)
//   else find in pool (available packages)
//

static Solvable *
select_solvable(Solver *solv, Pool *pool, Repo *repo, char *name)
{
  Id id;
  Queue plist;
  int i, end;
  Solvable *s;

  id = str2id(pool, name, 1);
  queue_init( &plist);
  i = repo ? repo->start : 1;
  end = repo ? repo->end : pool->nsolvables;
  for (; i < end; i++)
    {
      s = pool->solvables + i;
      if (repo && s->repo != repo)
	continue;
      if (!pool_installable(pool, s))
	continue;
      if (s->name == id)
	queue_push(&plist, i);
    }

  prune_best_arch_name_version(solv, pool, &plist);

  if (plist.count == 0)
    {
      printf("unknown package '%s'\n", name);
      exit(1);
    }

  id = plist.elements[0];
  queue_free(&plist);

  return pool->solvables + id;
}

static int
solution_callback(Solver *solv, void *data)
{
  printf("*** Found another decision:\n");
  solver_printdecisions(solv);
  return 0;
}

static FILE *
load_callback(Pool *pool, Repodata *data, void *cbdata)
{
  FILE *fp = 0;
  if (data->location)
    {
      printf("loading %s\n", data->location);
      fp = fopen (data->location, "r");
      if (!fp)
        perror(data->location);
    }
  return fp;
}

//-----------------------------------------------

void
langdemo(Pool *pool)
{
  Id screenid, p, *pp;

  screenid = str2id(pool, "3ddiag", 1);
  static const char *languages[] = {"es", "de"};
  pool_set_languages(pool, languages, 2);
  FOR_PROVIDES(p, pp, screenid)
    {
      unsigned int medianr;
      Id chktype = 0;
      char *loc = solvable_get_location(pool->solvables + p, &medianr);
      const char *chksum;
      chksum = solvable_lookup_checksum(pool->solvables + p, SOLVABLE_CHECKSUM, &chktype);
      printf("%s: %s\n%s[%d] %s:%s\n", solvable2str(pool, pool->solvables + p), solvable_lookup_str_poollang(pool->solvables + p, SOLVABLE_DESCRIPTION), loc, medianr, id2str(pool, chktype), chksum);
      printf("DE: %s\n", solvable_lookup_str_lang(pool->solvables + p, SOLVABLE_DESCRIPTION, "de"));
    }
}

static Id
nscallback(Pool *pool, void *data, Id name, Id evr)
{
  if (name == NAMESPACE_LANGUAGE && !ISRELDEP(evr))
    {
      if (!strcmp(id2str(pool, evr), "de"))
	return 1;
    }
  return 0;
}

//-----------------------------------------------

int
main(int argc, char **argv)
{
  Pool *pool;		// available packages (multiple repos)
  FILE *fp;
  Repo *system;	// installed packages (single repo, aka 'Repo')
  Solvable *xs;
  Solver *solv;
  Repo *channel;
  Queue job;
  Id id;
  int c;
  int erase = 0;
  int all = 0;
  int debuglevel = 1;
  int force = 0;
  int noreco = 0;
  int weak = 0;
  char *weakdeps = 0;
  int forceupdate = 0;
  char *keep = 0;
  char *multiinstall = 0;

  pool = pool_create();
  pool->nscallback = nscallback;
  pool_setloadcallback(pool, load_callback, 0);
  pool_setarch(pool, "i686");
  queue_init(&job);

  if (argc < 3)
    {
      fprintf(stderr, "Usage:\n  yps <system> <repo> [ ... <repo>] <name>\n");
      fprintf(stderr, "    to install a package <name>\n");
      fprintf(stderr, "\n  yps -e <system> <name>\n");
      fprintf(stderr, "    to erase a package <name>\n");
      exit(0);
    }

  while ((c = getopt(argc, argv, "uefrAvwk:m:W:")) >= 0)
    {
      switch(c)
	{
	case 'e':
	  erase = 1;
	  break;
	case 'u':
	  forceupdate = 1;
	  break;
	case 'f':
	  force = 1;
	  break;
	case 'A':
	  all = 1;
	  break;
	case 'r':
	  noreco = 1;
	  break;
	case 'w':
	  weak = SOLVER_WEAK;
	  break;
	case 'W':
	  weakdeps = optarg;
	  break;
	case 'k':
	  keep = optarg;
	  break;
	case 'm':
	  multiinstall = optarg;
	  break;
	case 'v':
	  debuglevel++;
	  break;
	default:
	  exit(1);
	}
    }

  argc -= optind - 1;
  argv += optind - 1;

  pool_setdebuglevel(pool, debuglevel);

  // Load system file (installed packages)

  if ((fp = fopen(argv[1], "r")) == NULL)
    {
      perror(argv[1]);
      exit(1);
    }
  system = repo_create(pool, "system");
  if (repo_add_solv(system, fp))
    {
      fprintf(stderr, "could not add system repository\n");
      exit(1);
    }
  channel = 0;
  fclose(fp);

  // Load further repo files (available packages)

  argc--;
  argv++;
  while (argc > 2)		       /* all but last arg are repos */
    {
      if ((fp = fopen(argv[1], "r")) == 0)
	{
	  perror(argv[1]);
	  exit(1);
	}
      channel = repo_create(pool, argv[1]);
      if (repo_add_solv(channel, fp))
	{
	  fprintf(stderr, "could not add repository %s\n", argv[1]);
	  exit(1);
	}
      fclose(fp);
      argv++;
      argc--;
    }


  pool_addfileprovides(pool, system);
  pool_createwhatprovides(pool);

  pool->promoteepoch = 0;

  // start solving

  solv = solver_create(pool, system);

  if (keep)
    {
      id = str2id(pool, keep, 1);
      queue_push(&job, SOLVER_ERASE_SOLVABLE_NAME | SOLVER_WEAK);
      queue_push(&job, id);
    }
  if (multiinstall)
    {
      id = str2id(pool, multiinstall, 1);
      queue_push(&job, SOLVER_NOOBSOLETES_SOLVABLE_NAME);
      queue_push(&job, id);
    }
  // setup job queue
  if (!argv[1][0])
    ;
  else if (forceupdate)
    {
      Id p, *pp;
      Solvable *s = 0;
      Queue qs;

      id = str2id(pool, argv[1], 1);
      FOR_PROVIDES(p, pp, id)
	{
	  s = pool->solvables + p;
	  if (s->name == id && s->repo == system)
	    break;
	}
      if (p)
	{
	  int i, j;

	  queue_init(&qs);
	  policy_findupdatepackages(solv, s, &qs, 0);
	  for (i = j = 0; i < qs.count; i++)
	    {
	      Solvable *s2 = pool->solvables + qs.elements[i];
	      /* filter out same evr */
	      if (s2->name == s->name && evrcmp(pool, s->evr, s2->evr, EVRCMP_MATCH_RELEASE) >= 0)
		continue;
	      qs.elements[j++] = qs.elements[i];
	    }
	  qs.count = j;
	  queue_push(&job, SOLVER_INSTALL_SOLVABLE_ONE_OF | weak);
	  queue_push(&job, pool_queuetowhatprovides(pool, &qs));
	  queue_free(&qs);
	}
      else
	{
	  /* a new one */
	  queue_push(&job, SOLVER_INSTALL_SOLVABLE_NAME | weak);
	  queue_push(&job, id);
	}
    }
  else if (!erase)
    {
      xs = select_solvable(solv, pool, channel, argv[1]);
      queue_push(&job, SOLVER_INSTALL_SOLVABLE | weak);
      queue_push(&job, xs - pool->solvables);
    }
  else
    {
      id = str2id(pool, argv[1], 1);
      queue_push(&job, SOLVER_ERASE_SOLVABLE_NAME | weak);
      queue_push(&job, id);
    }

  if (weakdeps)
    {
      Id p, *pp;
      Solvable *s;

      id = str2id(pool, weakdeps, 1);
      FOR_PROVIDES(p, pp, id)
	{
	  s = pool->solvables + p;
	  if (s->name != id)
	    continue;
	  queue_push(&job, SOLVER_WEAKEN_SOLVABLE_DEPS);
	  queue_push(&job, p);
	}
    }
  solv->fixsystem = 0;
  solv->updatesystem = 0;
  solv->allowdowngrade = 0;
  solv->allowuninstall = force ? 1 : 0;
  solv->noupdateprovide = 0;
  solv->dontinstallrecommended = noreco;

  // Solve !

  if (all)
    solv->solution_callback = solution_callback;
  solver_solve(solv, &job);
  if (solv->problems.count)
    solver_printsolutions(solv, &job);
  solver_printdecisions(solv);
  if (1)
    {
      DUChanges duc[4];
      int i;

      duc[0].path = "/";
      duc[1].path = "/usr/share/man";
      duc[2].path = "/sbin";
      duc[3].path = "/etc";
      solver_calc_duchanges(solv, duc, 4);
      for (i = 0; i < 4; i++)
        printf("duchanges %s: %d %d\n", duc[i].path, duc[i].kbytes, duc[i].files);
      printf("install size change: %d\n", solver_calc_installsizechange(solv));
    }

  langdemo(pool);

  solver_printtrivial(solv);

  // clean up

  queue_free(&job);
  solver_free(solv);
  pool_free(pool);

  exit(0);
}

// EOF
