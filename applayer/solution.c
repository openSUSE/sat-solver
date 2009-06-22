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
solution_new( const Problem *problem, Id s, Id p, Id rp )
{
  Solution *solution = (Solution *)malloc( sizeof( Solution ));
  solution->problem = problem;
  solution->s = s;
  solution->p = p;
  solution->rp = rp;
  return solution;
}


void
solution_free( Solution *s )
{
  free( s );
}
