/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Job
 *
 * A single 'job' item of a Transaction
 *
 */

#include <stdlib.h>

#include "job.h"
#include "applayer.h"

Job *
job_new( Pool *pool, SolverCmd cmd, Id id )
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
job_xsolvable( Job *j )
{
  if (j->cmd == SOLVER_INSTALL_SOLVABLE
      || j->cmd == SOLVER_ERASE_SOLVABLE)
    {
      return xsolvable_new( j->pool, j->id );
    }
  return NULL;
}


const char *
job_name( Job *j )
{
  if (j->cmd == SOLVER_INSTALL_SOLVABLE_NAME
      || j->cmd == SOLVER_ERASE_SOLVABLE_NAME)
    {
      return my_id2str( j->pool, j->id );
    }
  return NULL;
}


Relation *
job_relation( Job *j )
{
  if (j->cmd == SOLVER_INSTALL_SOLVABLE_PROVIDES
      || j->cmd == SOLVER_ERASE_SOLVABLE_PROVIDES)
    {
      return relation_new( j->pool, j->id );
    }
  return NULL;
}
