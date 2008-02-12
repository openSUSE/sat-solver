/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Action
 *
 * A single 'job' item of a Transaction
 *
 */


#ifndef SATSOLVER_ACTION_H
#define SATSOLVER_ACTION_H

#include "pool.h"
#include "solver.h"

#include "xsolvable.h"
#include "relation.h"

typedef struct _Action {
  Pool *pool;
  SolverCmd cmd;
  Id id;
} Action;


Action *action_new( Pool *pool, SolverCmd cmd, Id id );
void action_free( Action *a );

XSolvable *action_xsolvable( Action *a );
const char *action_name( Action *a );
Relation *action_relation( Action *a );

#endif  /* SATSOLVER_ACTION_H */
