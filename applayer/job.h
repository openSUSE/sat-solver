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


#ifndef SATSOLVER_JOB_H
#define SATSOLVER_JOB_H

#include "pool.h"
#include "solver.h"

#include "xsolvable.h"
#include "relation.h"

typedef struct _Job {
  Pool *pool;
  Id cmd;
  Id id;
} Job;


Job *job_new( Pool *pool, Id cmd, Id id );
void job_free( Job *j );

XSolvable *job_xsolvable( Job *j );
const char *job_name( Job *j );
Relation *job_relation( Job *j );

#endif  /* SATSOLVER_JOB_H */
