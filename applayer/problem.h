/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_PROBLEM_H
#define SATSOLVER_PROBLEM_H

/************************************************
 * Problem
 *
 * An unsuccessful solver result
 *
 * If a transaction is not solvable, one or more
 * Problems will be reported by the Solver.
 *
 */

#include "solver.h"

#include "transaction.h"
#include "solution.h"

typedef struct _Problem {
  Solver *solver;
  Transaction *transaction;
  Id id;                    /* [PRIVATE] problem id */
  SolverProbleminfo reason;
  Id source;                /* solvable id */
  Id relation;              /* relation id */
  Id target;                /* solvable id */
} Problem;

Problem *problem_new( Solver *s, Transaction *t, Id id );
void problem_free( Problem *p );

void solver_problems_iterate( Solver *solver, Transaction *t, int (*callback)( const Problem *p, void *user_data ), void *user_data );
void problem_solutions_iterate( Problem *p, int (*callback)( const Solution *s, void *user_data ), void *user_data );

#endif  /* SATSOLVER_PROBLEM_H */
