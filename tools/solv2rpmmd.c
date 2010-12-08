/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

static int with_attr = 0;

#include "pool.h"
#include "repo_solv.h"

//static int dump_repoattrs_cb(void *vcbdata, Solvable *s, Repodata *data, Repokey *key, KeyValue *kv);

#define XML_HEADER "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
#define METADATA_TAG_OPEN "<metadata xmlns=\"http://linux.duke.edu/metadata/common\" xmlns:rpm=\"http://linux.duke.edu/metadata/rpm\" packages=\"%d\">"
#define METADATA_TAG_CLOSE "</metadata>"
#define PACKAGE_TAG_OPEN "<package type=\"rpm\">"
#define PACKAGE_TAG_CLOSE "</package>"

/**
 * To carry all the file pointers as callback user data
 */
struct Context
  {
    FILE *primary;
  };

const char * evr_release(const char *evr)
{
  const char * str = evr;
  const char * sep = strrchr( str, '-' );
  // get release
  if ( sep )
    return sep+1;

  return "";
}

char * evr_dup_version(const char *evr)
{
  const char * str = evr;
  const char * sep = str;
  // skip edition
  for ( ; *sep >= '0' && *sep <= '9'; ++sep )
    ; // NOOP
  if ( *sep == ':' )
    str = sep+1;
  // strip release
  sep = strrchr( str, '-' );

  if ( sep )
    {
      char *tmp = (char *)(malloc(sep - str + 1));
      if (tmp != NULL)
        {
          strncpy(tmp, str, sep - str);
          tmp[sep - str + 1] = 0;
          return tmp;
        }
    }
  return strdup(str);
}

int evr_epoch(const char *evr)
{
  int ret = 0;
  const char *s;

  for (s = evr; *s >= '0' && *s <= '9'; s++)
    ;

  if (s != evr && *s == ':')
    {
      char *tmp = (char *)(malloc(s - evr + 1));
      if (tmp != NULL)
        {
          strncpy(tmp, evr, s - evr);
          tmp[s - evr + 1] = 0;
          ret = atoi(tmp);
          free(tmp);
        }
    }

  return ret;
}

static inline int write_simple_tag(FILE *fp, const char *tag, const char *val)
{
  if (val)
    fprintf(fp, "<%s>%s</%s>", tag, val, tag);
  else
    fprintf(fp, "<%s/>", tag);
  return 0;
}

int write_solvable_deps(FILE *fp, Solvable *s, const char *depname, Offset deploc)
{
  Id *reqp, req;
  char *version;

  fprintf(fp, "<rpm:%s>", depname);

  reqp = s->repo->idarraydata + deploc;
  while ((req = *reqp++) != 0 )
    {
      //  for (reqp = s->repo->idarraydata + deploc; req != 0; req = *reqp++ )
      //    {
      const char *name, *evr;
      if (ISRELDEP(req))
        {
          Reldep *rd = GETRELDEP(s->repo->pool, req);
          if (ISRELDEP(rd->name) || ISRELDEP(rd->evr) || rd->flags >= 8)
            continue;
          name = id2str(s->repo->pool, rd->name);
          if (name == NULL) {
            printf("OOPS! %s\n", id2str(s->repo->pool, s->name));
            exit(1);
          }
          fprintf(fp, "<rpm:entry name=\"%s\"", name);
          evr = id2str(s->repo->pool, rd->evr);

          switch (rd->flags)
            {
            case REL_GT:
              fprintf(fp, " flags=\"GT\"");
              break;
            case REL_EQ:
              fprintf(fp, " flags=\"EQ\"");
              break;
            case REL_LT:
              fprintf(fp, " flags=\"LT\"");
              break;
            case REL_LT|REL_EQ:
              fprintf(fp, " flags=\"LE\"");
              break;
            case REL_GT|REL_EQ:
              fprintf(fp, " flags=\"GE\"");
              break;
            default:
              printf("Unknown relation type %d\n", rd->flags);
            }

          version = evr_dup_version(evr);
          fprintf(fp,
                  " epoch=\"%d\" ver=\"%s\" rel=\"%s\"",
                  evr_epoch(evr),
                  version,
                  evr_release(evr));
          /* version is the only one that is malloc'ed */
          //if (version != NULL)



          fprintf(fp, "<rpm:entry name=\"%s\"/>", name);
        }
      else
        {
          name = id2str(s->repo->pool, req);
          if (name == NULL) {
            printf("OOPS! %s\n", id2str(s->repo->pool, s->name));
            exit(1);
          }
          fprintf(fp, "<rpm:entry name=\"%s\"/>", name);
        }
    }
  fprintf(fp, "</rpm:%s>", depname);
  return 0;
}

int write_solvable(struct Context *ctx, Solvable *s)
{
  const char *tmp;
  unsigned int medianr;

  write_simple_tag(ctx->primary, "name", solvable_lookup_str(s, SOLVABLE_NAME));
  write_simple_tag(ctx->primary, "arch", solvable_lookup_str(s, SOLVABLE_ARCH));

  const char *evr = solvable_lookup_str(s, SOLVABLE_EVR);
  char *version = evr_dup_version(evr);
  fprintf(ctx->primary,
          "<version epoch=\"%d\" ver=\"%s\" rel=\"%s\"/>",
          evr_epoch(evr),
          version,
          evr_release(evr));
  /* version is the only one that is malloc'ed */
  //if (version != NULL)
    //free(version);

  Id checksumtype = 0;
  tmp = solvable_lookup_checksum(s, SOLVABLE_CHECKSUM, &checksumtype);
  if (tmp) {
    fprintf(ctx->primary, "<checksum type=\"");
    switch ( checksumtype )
      {
      case REPOKEY_TYPE_MD5:
        fprintf(ctx->primary, "md5");
        break;
      case REPOKEY_TYPE_SHA256:
        fprintf(ctx->primary, "sha256");
        break;
      case REPOKEY_TYPE_SHA1:
      default:
        fprintf(ctx->primary, "sha");
        break;
      }
    fprintf(ctx->primary, "\" PKGID=\"YES\">%s</checksum>", tmp);
  }

  write_simple_tag(ctx->primary, "summary", solvable_lookup_str(s, SOLVABLE_SUMMARY));
  write_simple_tag(ctx->primary, "description", solvable_lookup_str(s, SOLVABLE_DESCRIPTION));
  write_simple_tag(ctx->primary, "packager", solvable_lookup_str(s, SOLVABLE_PACKAGER));
  write_simple_tag(ctx->primary, "url", solvable_lookup_str(s, SOLVABLE_URL));

  /** FIXME add the file attribute (doing a stat with location?) */
  fprintf(ctx->primary, "<time build=\"%d\"/>", solvable_lookup_num(s, SOLVABLE_BUILDTIME, 0));

  fprintf(ctx->primary,
          "<size package=\"%d\" installed=\"%d\" archive=\"%d\"/>",
          (solvable_lookup_num(s, SOLVABLE_DOWNLOADSIZE, 0) * 1024) - 1023,
          (solvable_lookup_num(s, SOLVABLE_INSTALLSIZE, 0) * 1024) - 1023,
          0
          );

  fprintf(ctx->primary, "<location href=\"%s\"/>", solvable_get_location(s, &medianr));

  fprintf(ctx->primary, "<format>");
  write_simple_tag(ctx->primary, "rpm:license", solvable_lookup_str(s, SOLVABLE_LICENSE));
  write_simple_tag(ctx->primary, "rpm:vendor", solvable_lookup_str(s, SOLVABLE_VENDOR));
  write_simple_tag(ctx->primary, "rpm:group", solvable_lookup_str(s, SOLVABLE_GROUP));
  write_simple_tag(ctx->primary, "rpm:buildhost", solvable_lookup_str(s, SOLVABLE_BUILDHOST));

  tmp = solvable_lookup_str(s, SOLVABLE_SOURCENAME);
  if (tmp) {
    fprintf(ctx->primary, "<rpm:sourcerpm>");
    fprintf(ctx->primary, "%s-%s", tmp, solvable_lookup_str(s, SOLVABLE_SOURCEEVR));

    switch ( solvable_lookup_id(s, SOLVABLE_SOURCEARCH)  )
      {
      case ARCH_SRC:
        fprintf(ctx->primary, ".src.rpm");
        break;
      default:
        fprintf(ctx->primary, ".nosrc.rpm");
        break;
      }
    fprintf(ctx->primary, "</rpm:sourcerpm>");
  }

  fprintf(ctx->primary, "<rpm:header-range start=\"440\" end=\"%d\"/>", solvable_lookup_num(s, SOLVABLE_HEADEREND, 440));

  write_solvable_deps(ctx->primary, s, "requires", s->requires);
  write_solvable_deps(ctx->primary, s, "obsoletes", s->obsoletes);
  write_solvable_deps(ctx->primary, s, "conflicts", s->conflicts);
  write_solvable_deps(ctx->primary, s, "requires", s->requires);
  write_solvable_deps(ctx->primary, s, "recommends", s->recommends);
  write_solvable_deps(ctx->primary, s, "suggests", s->suggests);
  write_solvable_deps(ctx->primary, s, "supplements", s->supplements);
  write_solvable_deps(ctx->primary, s, "enhances", s->enhances);

  fprintf(ctx->primary, "</format>");

  return 0;

}

static void
usage( const char *err )
{
  if (err)
    fprintf (stderr, "\n** Error:\n  %s\n", err);
  fprintf( stderr, "\nUsage:\n"
	   "dumpsolv [-a] [<solvfile>]\n"
	   "  -a  read attributes.\n"
	   );
  exit(0);
}

static int
loadcallback (Pool *pool, Repodata *data, void *vdata)
{
  FILE *fp = 0;
  int r;

printf("LOADCALLBACK\n");
  const char *location = repodata_lookup_str(data, SOLVID_META, REPOSITORY_LOCATION);
printf("loc %s\n", location);
  if (!location || !with_attr)
    return 0;
  fprintf (stderr, "Loading SOLV file %s\n", location);
  fp = fopen (location, "r");
  if (!fp)
    {
      perror(location);
      return 0;
    }
  r = repo_add_solv_flags(data->repo, fp, REPO_USE_LOADING|REPO_LOCALPOOL);
  fclose(fp);
  return !r ? 1 : 0;
}

int main(int argc, char **argv)
{
  Repo *repo;
  Pool *pool;
  int i, j, n;
  Solvable *s;

  struct Context ctx;
  memset(&ctx, 0, sizeof(ctx));

  ctx.primary = fopen("primary.xml", "w");
  if( !ctx.primary )
    {
      printf("Can't open primary file\n");
      exit(1);
    }

  pool = pool_create();
  pool_setdebuglevel(pool, 1);
  pool_setloadcallback(pool, loadcallback, 0);

  argv++;
  argc--;
  while (argc--)
    {
      const char *s = argv[0];
      if (*s++ == '-')
        while (*s)
          switch (*s++)
	    {
	      case 'h': usage(NULL); break;
	      case 'a': with_attr = 1; break;
	      default : break;
	    }
      else
	{
	  if (freopen (argv[0], "r", stdin) == 0)
	    {
	      perror(argv[0]);
	      exit(1);
	    }
	  repo = repo_create(pool, argv[0]);
	  if (repo_add_solv(repo, stdin))
	    printf("could not read repository\n");
	}
      argv++;
    }

  if (!pool->nrepos)
    {
      repo = repo_create(pool, argc != 1 ? argv[1] : "<stdin>");
      if (repo_add_solv(repo, stdin))
	printf("could not read repository\n");
    }
  printf("pool contains %d strings, %d rels, string size is %d\n", pool->ss.nstrings, pool->nrels, pool->ss.sstrings);

  n = 0;
  FOR_REPOS(j, repo)
    {
      printf("repo %d contains %d solvables\n", j, repo->nsolvables);
      printf("repo start: %d end: %d\n", repo->start, repo->end);

      fprintf(ctx.primary, XML_HEADER);
      fprintf(ctx.primary, METADATA_TAG_OPEN, repo->nsolvables);

      FOR_REPO_SOLVABLES(repo, i, s)
	{
          fprintf(ctx.primary, PACKAGE_TAG_OPEN);

	  n++;
	  printf("\n");
	  printf("solvable %d (%d):\n", n, i);
          write_solvable(&ctx, s);

          fprintf(ctx.primary, PACKAGE_TAG_CLOSE);
	}

      fprintf(ctx.primary, METADATA_TAG_CLOSE);
    }

  fclose(ctx.primary);

  pool_free(pool);
  exit(0);
}
