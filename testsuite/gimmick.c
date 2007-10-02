/*
 * gimmick - with gimmick
 * 
 * command line interface to source data
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
#include "source_solv.h"
#include "solver.h"

int main(int argc, char **argv)
{
  Pool *pool;
  Id id;
  Solvable *s;
  Id p, *pp;

  pool = pool_create();
  pool_addsource_solv( pool, stdin, "" );
  if (argc == 2)
    id = str2id( pool, argv[1], 1 );
  else
    id = rel2id( pool, str2id( pool, argv[1], 1), str2id(pool, argv[2], 1), atoi(argv[3]), 1 );
  pool_freeidhashes( pool );

  pool_prepare( pool );

  printf("%s%s%s:\n", id2str( pool, id ), id2rel( pool, id ), id2evr( pool, id ) );
  FOR_PROVIDES(p, pp, id)
    {
      s = pool->solvables + p;
      printf("  %s-%s.%s\n", id2str( pool, s->name ), id2str( pool, s->evr ), id2str( pool, s->arch ));
    }
  return 0;
}

// EOF
