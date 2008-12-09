/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Decision
 *
 * A successful solver result.
 *
 * Set of 'job items' needed to solve the Transaction.
 *
 */

#include <stdlib.h>

#include "decision.h"
#include "solverdebug.h"

Decision *
decision_new( Pool *pool, int op, Id solvable, Rule *rule )
{
  Decision *d = (Decision *)malloc( sizeof( Decision ));
  d->pool = pool;
  d->op = op;
  d->solvable = solvable;
  d->rule = rule;
  return d;
}

void
decision_free( Decision *d )
{
  free( d );
}

void
solver_decisions_iterate( Solver *solver, int (*callback)( const Decision *d, void *user_data ), void *user_data )
{
  Pool *pool = solver->pool;
  Repo *installed = solver->installed;
  Id p, *obsoletesmap = solver_create_decisions_obsoletesmap( solver );
  Id s;
  int why;
  int op;
  Decision *d;
  int i;
  
  if (!callback)
    return; /* no use to iterate without callback */
  
  for ( i = 0; i < solver->decisionq.count; i++)
    {
      p = solver->decisionq.elements[i];
      why = solver->decisionq_why.elements[i];

      if (p < 0)     /* remove */
        {
	  p = -p;
	  s = p;
	  if (obsoletesmap[p])
	    {
	      op = DECISION_OBSOLETE;
	    }
	  else
	    {
	      op = DECISION_REMOVE;
	    }
	}
      else if (p == SYSTEMSOLVABLE)
        {
	  continue;  /* don't report 'keep system solvable installed' decision */
	}
      else /* p > 0 */
        {
	  s = p;
	  if (installed)
	    {
	      Solvable *solv = pool_id2solvable( pool, p );
	      if (solv->repo == installed)
		continue;  /* don't report 'keep installed' decision */
	    }
	  if (obsoletesmap[p])
	    {
	      op = DECISION_UPDATE;
	    }
	  else
	    {
	      op = DECISION_INSTALL;
	    }
	}
      d = decision_new( pool, op, s, why ? solver->rules + why : NULL );
      if (callback( d, user_data ))
	break;
    }
}
