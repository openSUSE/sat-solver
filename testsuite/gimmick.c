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
  Solvable *s;
  Id p, *pp;

  pool = pool_create();
  repo = repo_create(pool, "<stdin>");
  repo_add_solv(repo, stdin);
  if (argc == 2)
    id = str2id(pool, argv[1], 1);
  else
    id = rel2id(pool, str2id(pool, argv[1], 1), str2id(pool, argv[2], 1), atoi(argv[3]), 1);

  pool_createwhatprovides(pool);

  printf("%s:\n", dep2str(pool, id));
  FOR_PROVIDES(p, pp, id)
    {
      s = pool->solvables + p;
      printf("  %s-%s.%s\n", id2str(pool, s->name), id2str(pool, s->evr), id2str(pool, s->arch));
    }
  pool_free(pool);
  return 0;
}

// EOF
