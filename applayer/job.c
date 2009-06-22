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
  if (j->cmd & SOLVER_SOLVABLE) {
      return xsolvable_new( j->pool, j->id );
    }
  return NULL;
}


const char *
job_name( const Job *j )
{
  if (j->cmd & SOLVER_SOLVABLE_NAME)
    {
      return my_id2str( j->pool, j->id );
    }
  return NULL;
}


Relation *
job_relation( const Job *j )
{
  if (j->cmd == SOLVER_SOLVABLE_PROVIDES)
    {
      return relation_new( j->pool, j->id );
    }
  return NULL;
}
