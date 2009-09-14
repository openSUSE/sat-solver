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

#include <stdlib.h>
#include "step.h"

Step *
step_new( Transaction *transaction, Id id )
{
  Step *step = (Step *)malloc( sizeof( Step ));
  step->transaction = transaction;
  step->id = id;
  return step;
}


void
step_free( Step *s )
{
  free( s );
}


/* Return Solvable affected by Step */
XSolvable *
step_xsolvable( const Step *s )
{
  return xsolvable_new( s->transaction->pool, s->id );
}


int
step_type( const Step *s, int mode )
{
  return transaction_type(s->transaction, s->id, mode);
}

const char *
step_type_s( const Step *s, int mode )
{
  switch( step_type(s, mode) ) {    
  case SOLVER_TRANSACTION_IGNORE:         return "ignore";
  case SOLVER_TRANSACTION_ERASE:          return "erase";
  case SOLVER_TRANSACTION_REINSTALLED:    return "reinstalled";
  case SOLVER_TRANSACTION_DOWNGRADED:     return "downgraded";
  case SOLVER_TRANSACTION_CHANGED:        return "changed";
  case SOLVER_TRANSACTION_UPGRADED:       return "upgraded";
  case SOLVER_TRANSACTION_OBSOLETED:      return "obsoleted";
  case SOLVER_TRANSACTION_INSTALL:        return "install";
  case SOLVER_TRANSACTION_REINSTALL:      return "reinstall";
  case SOLVER_TRANSACTION_DOWNGRADE:      return "downgrade";
  case SOLVER_TRANSACTION_CHANGE:         return "change";
  case SOLVER_TRANSACTION_UPGRADE:        return "upgrade";
  case SOLVER_TRANSACTION_OBSOLETES:      return "obsoletes";
  case SOLVER_TRANSACTION_MULTIINSTALL:   return "multiinstall";
  case SOLVER_TRANSACTION_MULTIREINSTALL: return "multireinstall";
  default:
    break;
  }
  return "unknown";
}

/* return non-zero if steps are equal */
int
steps_equal( const Step *step1, const Step *step2 )
{
  if (step1
      && step2
      && ((step1 == step2)
	  || (step1->transaction == step2->transaction
	      && step1->id == step2->id)
	 )
      )
    return 1;
  return 0;
}

/* Get step number num. */
Step *
step_get( Transaction *transaction, unsigned int num)
{
  Id p;
  if (!transaction
      || num >= transaction->steps.count)
    return NULL;
  p = transaction->steps.elements[num];
  return step_new( transaction, p );
}

/* iterate over all transaction steps */
void
transaction_steps_iterate( Transaction *t, int (*callback)( const Step *s ))
{
  int i;
  for (i = 0; i < t->steps.count; ++i )
    {
      if (callback( step_get( t, i ) ) )
	break;
    }
}
