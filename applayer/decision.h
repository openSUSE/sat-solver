/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_DECISION_H
#define SATSOLVER_DECISION_H

/************************************************
 * Decision
 *
 * A successful solver result.
 *
 * Set of 'job items' needed to solve the Transaction.
 *
 */

#include "solver.h"

enum decisions {
  DECISION_INSTALL = 1,
  DECISION_REMOVE,
  DECISION_UPDATE,
  DECISION_OBSOLETE
};

typedef struct _Decision {
  enum decisions op;
  Solver *solver;
  Id solvable;
  Rule *rule;
} Decision;

Decision *decision_new( Solver *solver, int op, Id solvable, Rule *rule );
void decision_free( Decision *d );

void solver_decisions_iterate( Solver *solver, int (*callback)( const Decision *d, void *user_data ), void *user_data);

#endif  /* SATSOLVER_DECISION_H */
