/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Transaction
 *
 * A set of Actions to be solved by the Solver
 *
 */

#ifndef SATSOLVER_TRANSACTION_H
#define SATSOLVER_TRANSACTION_H

#include "action.h"


typedef struct _Transaction {
  Pool *pool;
  Queue queue;
} Transaction;


Transaction *transaction_new( Pool *pool );
void transaction_free( Transaction *t );

void transaction_install_xsolvable( Transaction *t, XSolvable *xs );
void transaction_remove_xsolvable( Transaction *t, XSolvable *xs );
void transaction_install_name( Transaction *t, const char *name );
void transaction_remove_name( Transaction *t, const char *name );
void transaction_install_relation( Transaction *t, const Relation *rel );
void transaction_remove_relation( Transaction *t, const Relation *rel );
Action *transaction_action_get( Transaction *t, int i );

#endif  /* SATSOLVER_TRANSACTION_H */
