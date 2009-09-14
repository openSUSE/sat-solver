/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Step
 *
 * A single 'step' item of a Transaction describing a Solvable to
 * install, update, or remove.
 * 
 */


#ifndef SATSOLVER_STEP_H
#define SATSOLVER_STEP_H

#include "pool.h"
#include "solver.h"

#include "xsolvable.h"
#include "transaction.h"

typedef struct _Step {
  Transaction *transaction;
  Id id;    /* Id of Solvable */
} Step;


Step *step_new( Transaction *transaction, Id id );
void step_free( Step *s );


/* Return Solvable affected by Step */
XSolvable *step_xsolvable( const Step *s );

/* Return type of Step */
int step_type( const Step *s, int mode );

/* Return string representation of type */
const char *step_type_s( const Step *s, int mode );

/* return non-zero if steps are equal */
int steps_equal( const Step *step1, const Step *step2 );

/* get specific step number from transaction. Returns NULL if step number is invalid. */
Step *step_get( Transaction *transaction, unsigned int num);

void transaction_steps_iterate( Transaction *transaction, int (*callback)( const Step *s ));

#endif  /* SATSOLVER_STEP_H */
