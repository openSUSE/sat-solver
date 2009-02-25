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

#define DECISION_INSTALL  0x01
#define DECISION_REMOVE   0x02
#define DECISION_UPDATE   0x03
#define DECISION_OBSOLETE 0x04
#define DECISION_WEAK     0x10
#define DECISION_FREE     0x20

typedef struct _Decision {
  int op;
  Solver *solver;
  Id solvable;
  Rule *rule;
} Decision;

Decision *decision_new( Solver *solver, int op, Id solvable, Rule *rule );
void decision_free( Decision *d );

void solver_decisions_iterate( Solver *solver, int (*callback)( const Decision *d, void *user_data ), void *user_data);

#endif  /* SATSOLVER_DECISION_H */
