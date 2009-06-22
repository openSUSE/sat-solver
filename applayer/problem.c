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
 * If a request is not solvable, one or more
 * Problems will be reported by the Solver.
 *
 */

#include <stdlib.h>
#include <policy.h>

#include "problem.h"
#include "solution.h"
#include "evr.h"


Problem *
problem_new( Solver *s, Request *t, Id id )
{
  Problem *p = (Problem *)malloc( sizeof( Problem ));
  p->solver = s;
  p->request = t;
  p->id = id;
  return p;
}

void
problem_free( Problem *p )
{
  free( p );
}


void
solver_problems_iterate( Solver *solver, Request *t, int (*callback)(const Problem *p, void *user_data), void *user_data )
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
problem_ruleinfos_iterate( Problem *problem, int (*callback)( const Ruleinfo *ri, void *user_data), void *user_data )
{
  Queue rules;
  Id rule;
  queue_init(&rules);
  
  solver_findallproblemrules(problem->solver, problem->id, &rules);
  while ((rule = queue_shift(&rules))) 
    {
      int result;
      Ruleinfo *ri = ruleinfo_new( problem->solver, rule );
      result = callback( ri, user_data );
      ruleinfo_free(ri);
      if (result)
	break;
    }
  return;
}


void
problem_solutions_iterate( Problem *problem, int (*callback)( const Solution *s, void *user_data ), void *user_data )
{
  if (!callback) /* no use to iterate without callback */
    return;

  Id solution = 0;
  
  while ((solution = solver_next_solution( problem->solver, problem->id, solution )) != 0)
    {
      Id p, rp, element = 0;
     
      
      /*  from src/problems.c:
       * 
       *  return the next item of the proposed solution
       *  here are the possibilities for p / rp and what
       *  the solver expects the application to do:
       *    p                             rp
       *  -------------------------------------------------------
       *    SOLVER_SOLUTION_INFARCH       pkgid
       *    -> add (SOLVER_INSTALL|SOLVER_SOLVABLE, rp) to the job
       * 
       *    SOLVER_SOLUTION_DISTUPGRADE   pkgid
       *    -> add (SOLVER_INSTALL|SOLVER_SOLVABLE, rp) to the job
       * 
       *    SOLVER_SOLUTION_JOB           jobidx
       *    -> remove job (jobidx - 1, jobidx) from job queue
       * 
       *    pkgid (> 0)                   0
       *    -> add (SOLVER_ERASE|SOLVER_SOLVABLE, p) to the job
       * 
       *    pkgid (> 0)                   pkgid (> 0)
       *    -> add (SOLVER_INSTALL|SOLVER_SOLVABLE, rp) to the job
       *       (this will replace package p)
       *         
       * Thus, the solver will either ask the application to remove
       * a specific job from the job queue, or ask to add an install/erase
       * job to it.
       *
       */
    
      while ((element = solver_next_solutionelement( problem->solver, problem->id, solution, element, &p, &rp)) != 0)
        {
	  Solution *s = solution_new( problem, solution, p, rp );
	  int result = callback( s, user_data );
	  solution_free(s);
	  if (result)
	    break;
	}
    }
}
