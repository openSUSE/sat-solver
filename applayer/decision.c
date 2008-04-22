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
decision_new( Pool *pool, int op, Id solvable, Id reason )
{
  Decision *d = (Decision *)malloc( sizeof( Decision ));
  d->pool = pool;
  d->op = op;
  d->solvable = solvable;
  d->reason = reason;
  return d;
}

void
decision_free( Decision *d )
{
  free( d );
}

void
solver_decisions_iterate( Solver *solver, int (*callback)( const Decision *d ) )
{
  Pool *pool = solver->pool;
  Repo *installed = solver->installed;
  Id p, *obsoletesmap = solver_create_decisions_obsoletesmap( solver );
  Id s, r;
  int op;
  Decision *d;
  int i;
  
  if (!callback)
    return; /* no use to iterate without callback */
  
#if 0
  if (installed)
    {
      FOR_REPO_SOLVABLES(installed, p, s)
        {
	  if (solver->decisionmap[p] >= 0)
	    continue;
	  if (obsoletesmap[p])
	    {
	      d = decision_new( pool, DECISION_OBSOLETE, s, pool_id2solvable( pool, obsoletesmap[p] ) );
	    }
	  else
	    {
	      d = decision_new( pool, DECISION_REMOVE, s, NULL );
	    }
	  callback( d );
	}
    }
#endif
  for ( i = 0; i < solver->decisionq.count; i++)
    {
      p = solver->decisionq.elements[i];
      r = 0;

      if (p < 0)     /* remove */
        {
	  p = -p;
	  s = p;
	  if (obsoletesmap[p])
	    {
	      op = DECISION_OBSOLETE;
	      r = obsoletesmap[p];
	    }
	  else
	    {
	      op = DECISION_REMOVE;
	    }
	}
      else if (p == SYSTEMSOLVABLE)
        {
	  continue;
	}
      else
        {
	  s = p;
	  if (installed)
	    {
	      Solvable *solv = pool_id2solvable( pool, p );
	      if (solv->repo == installed)
		continue;
	    }
	  if (!obsoletesmap[p])
	    {
	      op = DECISION_INSTALL;
	    }
	  else
	    {
	      int j;
	      op = DECISION_UPDATE;
	      for (j = installed->start; j < installed->end; j++)
	        {
		  if (obsoletesmap[j] == p)
		    {
		      r = j;
		      break;
		    }
		}
	    }
	}
      d = decision_new( pool, op, s, r );
      if (callback( d ))
	break;
    }
}
