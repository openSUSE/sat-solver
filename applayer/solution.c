/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Solution
 *
 * A possible solution to a Problem.
 *
 * For each reported Problem, the Solver might generate
 * one or more Solutions to make the Request solvable.
 *
 */

#include <stdlib.h>

#include "applayer.h"
#include "solution.h"
#include "request.h"

#include "solverdebug.h"

Solution *
solution_new( const Problem *problem, Id id )
{
  Solution *solution = (Solution *)malloc( sizeof( Solution ));
  solution->problem = problem;
  solution->id = id;
  return solution;
}


void
solution_free( Solution *s )
{
  free( s );
}


char *
solution_string( const Solution *s )
{
  app_debugstart(s->problem->solver->pool,SAT_DEBUG_RESULT);
  solver_printsolution(s->problem->solver, s->problem->id, s->id);
  return app_debugend();
}

/**************************
 * SolutionElement
 * 
 */

SolutionElement *
solutionelement_new( const Solution *solution, Id p, Id rp )
{
  SolutionElement *element = (SolutionElement *)malloc( sizeof( SolutionElement ));
  element->solution = solution;
  element->p = p;
  element->rp = rp;

  return element;
}


void
solutionelement_free( SolutionElement *se )
{
  free( se );
}


void
solution_elements_iterate( const Solution *solution, int (*callback)( const SolutionElement *se, void *user_data ), void *user_data )
{
  if (!callback) /* no use to iterate without callback */
    return;

  Id p, rp, element = 0;
  
  while ((element = solver_next_solutionelement( solution->problem->solver, solution->problem->id, solution->id, element, &p, &rp)) != 0)
    {
      
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
    
      SolutionElement *se = solutionelement_new( solution, p, rp );
      int result = callback( se, user_data );
      if (result)
	break;
    }
}


char *
solutionelemen_string( const SolutionElement *se )
{
#if 0
  switch (se->p) {
    case SOLVER_SOLUTION_INFARCH:
      to_string("Install %s", solvable_
      return job_new( pool, SOLVER_INSTALL|SOLVER_SOLVABLE, se->rp );
      break;
    case SOLVER_SOLUTION_DISTUPGRADE:
      return job_new( pool, SOLVER_INSTALL|SOLVER_SOLVABLE, se->rp );
      break;
    case SOLVER_SOLUTION_JOB:
      return request_job_get( problem->request, se->rp);
      break;
    default:
    }
  return job_new( pool, SOLVER_INSTALL|SOLVER_SOLVABLE, se->rp );
#endif
  return to_string("SolutionElement %p", se);
}


int
solutionelement_cause( const SolutionElement *se )
{
  if (se->p > 0)
    return 0;
  else
    return se->p - 1;
}


Job *
solutionelement_job( const SolutionElement *se )
{
  const Problem *problem = se->solution->problem;
  Pool *pool = problem->solver->pool;
  
  switch (se->p) {
    case SOLVER_SOLUTION_INFARCH:
      return job_new( pool, SOLVER_INSTALL|SOLVER_SOLVABLE, se->rp );
      break;
    case SOLVER_SOLUTION_DISTUPGRADE:
      return job_new( pool, SOLVER_INSTALL|SOLVER_SOLVABLE, se->rp );
      break;
    case SOLVER_SOLUTION_JOB:
      return request_job_get( problem->request, se->rp);
      break;
  }
  return job_new( pool, SOLVER_INSTALL|SOLVER_SOLVABLE, se->rp );
}
