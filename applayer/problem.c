/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Problem
 *
 * An unsuccessful solver result
 *
 * If a transaction is not solvable, one or more
 * Problems will be reported by the Solver.
 *
 */

#include <stdlib.h>
#include <policy.h>

#include "problem.h"
#include "evr.h"


Problem *
problem_new( Solver *s, Transaction *t, Id id )
{
  Id prule;

  Problem *p = (Problem *)malloc( sizeof( Problem ));
  p->solver = s;
  p->transaction = t;
  p->id = id;
  prule = solver_findproblemrule( s, id );
  p->reason = solver_problemruleinfo( s, &(t->queue), prule, &(p->relation), &(p->source), &(p->target) );
  return p;
}

void
problem_free( Problem *p )
{
  free( p );
}


void
solver_problems_iterate( Solver *solver, Transaction *t, int (*callback)(const Problem *p, void *user_data), void *user_data )
{
  Id problem = 0;
  if (!callback)
    return; /* no use to iterate without callback */
  
  while ((problem = solver_next_problem( solver, problem )) != 0)
    {
      Problem *p = problem_new( solver, t, problem );
      if (callback( p, user_data ) )
	break;
    }
}


void
problem_solutions_iterate( Problem *problem, int (*callback)( const Solution *s, void *user_data ), void *user_data )
{
  if (!callback) /* no use to iterate without callback */
    return;

  Id solution = 0;
  while ((solution = solver_next_solution( problem->solver, problem->id, solution )) != 0)
    {
      Id p, rp, element, what;
      
      Id s1, s2, n1, n2;
      int code = SOLUTION_UNKNOWN;
      
      Solver *solver = problem->solver;
      Pool *pool = solver->pool;
      element = 0;
      s1 = s2 = n1 = n2 = 0;
    
      while ((element = solver_next_solutionelement( solver, problem->id, solution, element, &p, &rp)) != 0)
        {
	  if (p == 0)
	    {
	
	      /* job, rp is index into job queue */
	      what = problem->transaction->queue.elements[rp];
	
	      switch (problem->transaction->queue.elements[rp - 1])
	        {
		 case SOLVER_INSTALL_SOLVABLE:
		  s1 = what;
		  if (solver->installed
		      && (pool->solvables + s1)->repo == solver->installed)
		    {
		      code = SOLUTION_NOKEEP_INSTALLED; /* s1 */
		    }
		  else
		  {
		    code = SOLUTION_NOINSTALL_SOLV; /* s1 */
		  }
		  break;
		 case SOLVER_ERASE_SOLVABLE:
		  s1 = what;
		  if (solver->installed
		      && (pool->solvables + s1)->repo == solver->installed)
		    {
		      code = SOLUTION_NOREMOVE_SOLV; /* s1 */
		    }
		  else
		    {
		      code = SOLUTION_NOFORBID_INSTALL; /* s1 */
		    }
		  break;
		 case SOLVER_INSTALL_SOLVABLE_NAME:
		  n1 = what;
		  code = SOLUTION_NOINSTALL_NAME; /* n1 */
		  break;
		 case SOLVER_ERASE_SOLVABLE_NAME:
		  n1 = what;
		  code = SOLUTION_NOREMOVE_NAME; /* n1 */
		  break;
		 case SOLVER_INSTALL_SOLVABLE_PROVIDES:
		  n1 = what;
		  code = SOLUTION_NOINSTALL_REL; /* r1 */
		  break;
		 case SOLVER_ERASE_SOLVABLE_PROVIDES:
		  n1 = what;
		  code = SOLUTION_NOREMOVE_REL; /* r1 */
		  break;
		 case SOLVER_INSTALL_SOLVABLE_UPDATE:
		  s1 = what;
		  code = SOLUTION_NOUPDATE;
		  break;
		 default:
		  code = SOLUTION_UNKNOWN;
		  break;
		}
	    }
	  else
	    {
	      s1 = p;
	      s2 = rp;
	      /* policy, replace p with rp */
	      Solvable *sp = pool->solvables + p;
	      Solvable *sr = rp ? pool->solvables + rp : 0;
	      if (sr)
	        {
		  if (!solver->allowdowngrade
		      && evrcmp( pool, sp->evr, sr->evr, EVRCMP_MATCH_RELEASE ) > 0)
		    {
		      code = SOLUTION_ALLOW_DOWNGRADE;
		    }
		  else if (!solver->allowarchchange
			   && sp->name == sr->name
			   && sp->arch != sr->arch
			   && policy_illegal_archchange(solver, sp, sr ) )
		    {
		      code = SOLUTION_ALLOW_ARCHCHANGE; /* s1, s2 */
		    }
		  else if (!solver->allowvendorchange
			   && sp->name == sr->name
			   && sp->vendor != sr->vendor
			   && policy_illegal_vendorchange( solver, sp, sr ) )
		    {
		      n1 = sp->vendor;
		      n2 = sr->vendor;
		      code = SOLUTION_ALLOW_VENDORCHANGE;
		    }
		  else
		    {
		      code = SOLUTION_ALLOW_REPLACEMENT;
		    }
		}
	      else
	        {
		  code = SOLUTION_ALLOW_REMOVE; /* s1 */
		}
	    }
	}
      Solution *s = solution_new( problem->solver->pool, code, s1, n1, s2, n2 );
      if (callback( s, user_data ))
	break;
    }
}
