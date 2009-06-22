/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_SOLUTION_H
#define SATSOLVER_SOLUTION_H

/************************************************
 * Solution
 *
 * A possible solution to a Problem.
 *
 * For each reported Problem, the Solver might generate
 * one or more Solutions to make the Request solvable.
 *
 */

#include "pool.h"

#include "problem.h"

typedef struct _Solution {
  const Problem *problem;
  Id s;       /* solution set id. */
  Id p;
  Id rp;
} Solution;

Solution *solution_new( const Problem *problem, Id s, Id p, Id rp );
void solution_free( Solution *s );

#endif  /* SATSOLVER_SOLUTION_H */
