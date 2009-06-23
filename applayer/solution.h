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
  const Problem *problem; /* take solver and problem id from here */
  Id id;       /* solution set id. */
} Solution;

Solution *solution_new( const Problem *problem, Id id );
void solution_free( Solution *s );
const Problem *solution_problem( const Solution *s );


typedef struct _SolutionElement {
  const Solution *solution;
  Id p;
  Id rp;
} SolutionElement;

SolutionElement *solutionelement_new( const Solution *solution, Id p, Id rp );
void solutionelement_free( SolutionElement *se );

void solution_elements_iterate( const Solution *s, int (*callback)( const SolutionElement *se, void *user_data ), void *user_data );
int solutionelement_cause( const SolutionElement *se );
Job *solutionelement_job( const SolutionElement *se );

#endif  /* SATSOLVER_SOLUTION_H */
