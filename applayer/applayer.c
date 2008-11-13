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
pool_xsolvables_count( Pool *pool )
{
  Solvable *s;
  Id p;
  int count = 0;
  /* skip Id 0 since it is reserved
   * skip Id 1 since it is the system solvable and not
   *   accessible to the outside
   */
  for (p = 2, s = pool->solvables + p; p < pool->nsolvables; p++, s++)
    {
      if (!s)
	continue;
      if (!s->name)
        continue;
      ++count;
    }
  
  return count;
}

void
pool_xsolvables_iterate( Pool *pool, int (*callback)(const XSolvable *xs, void *user_data), void *user_data)
{
  Solvable *s;
  Id p;
  /* skip Id 0 and Id 1, see pool_count() above */
  for (p = 2, s = pool->solvables + p; p < pool->nsolvables; p++, s++)
    {
      if (!s)
	continue;
      if (!s->name)
        continue;
      if (callback( xsolvable_new( pool, p ), user_data ) )
	break;
    }
}

