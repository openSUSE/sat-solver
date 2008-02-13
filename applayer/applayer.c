/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Sat solver application layer
 *
 * Helper functions
 *
 */

#include "applayer.h"

const char *
my_id2str( Pool *pool, Id id )
{
  if (id == STRID_NULL)
    return NULL;
  if (id == STRID_EMPTY)
    return "";
  return id2str( pool, id );
}

unsigned int
pool_size( Pool *pool )
{
  /* decrease by one since Id 0 is reserved
   * decrease by one since Id 1 is the system solvable and not
   *   accessible to the outside
   */
  return pool->nsolvables - 1 - 1;
}

void
pool_xsolvables_iterate( Pool *pool, int (*callback)(const XSolvable *xs))
{
  Solvable *s;
  Id p;
  /* skip Id 0 and Id 1, see pool_size() above */
  for (p = 2, s = pool->solvables + p; p < pool->nsolvables; p++, s++)
    {
      if (!s->name)
        continue;
      if (callback( xsolvable_new( pool, p ) ) )
	break;
    }
}

