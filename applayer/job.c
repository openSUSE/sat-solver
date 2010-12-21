/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Job
 *
 * A single 'job' item of a Request
 *
 */

#include <stdlib.h>

#include "job.h"
#include "applayer.h"

Job *
job_new( Pool *pool, Id cmd, Id id )
{
  Job *job = (Job *)malloc( sizeof( Job ));
  job->pool = pool;
  job->cmd = cmd;
  job->id = id;
  return job;
}


void
job_free( Job *j )
{
  free( j );
}


XSolvable *
job_xsolvable( const Job *j )
{
  if ((j->cmd & SOLVER_SELECTMASK) == SOLVER_SOLVABLE) {
      return xsolvable_new( j->pool, j->id );
    }
  return NULL;
}


const char *
job_name( const Job *j )
{
  if ((j->cmd & SOLVER_SELECTMASK) == SOLVER_SOLVABLE_NAME)
    {
      return my_id2str( j->pool, j->id );
    }
  return NULL;
}


Relation *
job_relation( const Job *j )
{
  if ((j->cmd & SOLVER_SELECTMASK) == SOLVER_SOLVABLE_PROVIDES)
    {
      return relation_new( j->pool, j->id );
    }
  return NULL;
}


int
job_equal( const Job *job1, const Job *job2 )
{
  if (job1
      && job2
      && ((job1 == job2)
	  || (job1->pool == job2->pool
	      && job1->cmd == job2->cmd
	      && job1->id == job2->id)
	 )
      )
    return 1;
  return 0;
}


char *
job_string( const Job *job )
{
  char *res;
  XSolvable *xs = job_xsolvable( job );
  char *xs_str = NULL;
  const char *name = job_name( job );
  Relation *r = job_relation( job );
  char *r_str = NULL;

  if (xs)
    xs_str = xsolvable_string(xs);
  if (r)
    r_str = relation_string(r);
  
  switch(job->cmd) {
  case (SOLVER_INSTALL|SOLVER_SOLVABLE):
    res = to_string("Install %s", xs_str);
    break;
  case (SOLVER_UPDATE|SOLVER_SOLVABLE):
    res = to_string("Update %s", xs_str);
    break;
  case (SOLVER_ERASE|SOLVER_SOLVABLE):
    res = to_string("Remove %s", xs_str);
    break;
  case (SOLVER_WEAKENDEPS|SOLVER_SOLVABLE):
    res = to_string("Weaken %s", xs_str);
    break;
  case (SOLVER_LOCK|SOLVER_SOLVABLE):
    res = to_string("Lock %s", xs_str);
    break;
  case (SOLVER_INSTALL|SOLVER_SOLVABLE_NAME):
    res = to_string("Install %s", name);
    break;
  case (SOLVER_UPDATE|SOLVER_SOLVABLE_NAME):
    res = to_string("Update %s", name);
    break;
  case (SOLVER_ERASE|SOLVER_SOLVABLE_NAME):
    res = to_string("Remove %s", name);
    break;
  case (SOLVER_WEAKENDEPS|SOLVER_SOLVABLE_NAME):
    res = to_string("Weaken %s", name);
    break;
  case (SOLVER_LOCK|SOLVER_SOLVABLE_NAME):
    res = to_string("Lock %s", name);
    break;
  case (SOLVER_INSTALL|SOLVER_SOLVABLE_PROVIDES):
    res = to_string("Install %s", r_str);
    break;
  case (SOLVER_UPDATE|SOLVER_SOLVABLE_PROVIDES):
    res = to_string("Update %s", r_str);
    break;
  case (SOLVER_ERASE|SOLVER_SOLVABLE_PROVIDES):
    res = to_string("Remove %s", r_str);
    break;
  case (SOLVER_WEAKENDEPS|SOLVER_SOLVABLE_PROVIDES):
    res = to_string("Weaken %s", r_str);
    break;
  case (SOLVER_LOCK|SOLVER_SOLVABLE_PROVIDES):
    res = to_string("Lock %s", r_str);
    break;
  case (SOLVER_INSTALL|SOLVER_SOLVABLE_ONE_OF):
    res = to_string("Install one of %s", xs_str);
    break;
  case (SOLVER_UPDATE|SOLVER_SOLVABLE_ONE_OF):
    res = to_string("Update one of %s", xs_str);
    break;
  case (SOLVER_ERASE|SOLVER_SOLVABLE_ONE_OF):
    res = to_string("Remove one of %s", xs_str);
    break;
  case (SOLVER_LOCK|SOLVER_SOLVABLE_ONE_OF):
    res = to_string("Weaken one of %s", xs_str);
    break;

  default:
    res = to_string("Job cmd %d", job->cmd);
  }
  if (xs) xsolvable_free(xs);
  if (r) relation_free(r);
  return res;
}

