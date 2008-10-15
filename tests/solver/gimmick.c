/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * gimmick - with gimmick
 * 
 * command line interface to repo data
 *
 * Usage:
 *   cat x.solv | gimmick <name>
 *   cat x.solv | gimmick <name> <op> <version>
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "pool.h"
#include "repo_solv.h"
#include "solver.h"

int main(int argc, char **argv)
{
  Pool *pool;
  Repo *repo;
  Id id;
  Id p, pp;
  char *arch = 0;
  int debuglevel = 0;
  int nevr = 0;
  int c;

  pool = pool_create();
  while ((c = getopt(argc, argv, "vna:")) >= 0)
    {
      switch(c)
        {
	case 'n':
	  nevr = 1;
	  break;
	case 'a':
	  arch = optarg;
	  break;
	case 'v':
          debuglevel++;
          break;
	default:
	  exit(1);
	}
    }
  pool_setdebuglevel(pool, debuglevel);
  repo = repo_create(pool, "<stdin>");
  repo_add_solv(repo, stdin);
  argc -= optind - 1;
  argv += optind - 1;
  id = str2id(pool, argv[1], 1);
  if (arch)
    id = rel2id(pool, id, str2id(pool, arch, 1), REL_ARCH, 1);
  if (argc > 2)
    id = rel2id(pool, id, str2id(pool, argv[2], 1), atoi(argv[3]), 1);

  pool_createwhatprovides(pool);

  printf("%s:\n", dep2str(pool, id));
  if (nevr)
    {
      for (p = 1; p < pool->nsolvables; p++)
	if (pool_match_nevr(pool, pool->solvables + p, id))
	  printf("  %s\n", solvable2str(pool, pool->solvables + p));
    }
  else
    {
      FOR_PROVIDES(p, pp, id)
	printf("  %s\n", solvable2str(pool, pool->solvables + p));
    }
  pool_free(pool);
  return 0;
}

// EOF
