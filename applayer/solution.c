/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Solution
 *
 * A possible solution to a Problem.
 *
 * For each reported Problem, the Solver might generate
 * one or more Solutions to make the Request solvable.
 *
 */

#include <stdlib.h>

#include "solution.h"


Solution *
solution_new( Pool *pool, int solution, Id s1, Id n1, Id s2, Id n2 )
{
  Solution *s = (Solution *)malloc( sizeof( Solution ));
  s->pool = pool;
  s->solution = solution;
  s->s1 = s1;
  s->n1 = n1;
  s->s2 = s2;
  s->n2 = n2;
  return s;
}

void
solution_free( Solution *s )
{
  free( s );
}
