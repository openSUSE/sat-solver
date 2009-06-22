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
 * Internally, a Job is translated to a solver rule. Thus, solver
 * problems will only reference bad rules.
 * 
 */


#ifndef SATSOLVER_JOB_H
#define SATSOLVER_JOB_H

#include "pool.h"
#include "solver.h"

#include "xsolvable.h"
#include "relation.h"

typedef struct _Job {
  const Pool *pool;
  int cmd;  /* solver queue command */
  Id id;    /* Id of Name, Relation, or Solvable */
} Job;


Job *job_new( const Pool *pool, int cmd, Id id );
void job_free( Job *j );


/* Return Solvable (or NULL if job doesn't affect Solvable) */
XSolvable *job_xsolvable( const Job *j );

/* Return Name (or NULL if job doesn't affect Name) */
const char *job_name( const Job *j );

/* Return Relation (or NULL if job doesn't affect Relation) */
Relation *job_relation( const Job *j );

#endif  /* SATSOLVER_JOB_H */
