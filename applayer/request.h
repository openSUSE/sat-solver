/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Request
 *
 * A set of Actions to be solved by the Solver
 *
 */

#ifndef SATSOLVER_REQUEST_H
#define SATSOLVER_REQUEST_H

#include "job.h"


typedef struct _Request {
  Pool *pool;
  Queue queue;
} Request;


Request *request_new( Pool *pool );
void request_free( Request *t );

void request_install_xsolvable( Request *t, XSolvable *xs );
void request_remove_xsolvable( Request *t, XSolvable *xs );
void request_install_name( Request *t, const char *name );
void request_remove_name( Request *t, const char *name );
void request_install_relation( Request *t, const Relation *rel );
void request_remove_relation( Request *t, const Relation *rel );
int request_size( Request *t );
Job *request_job_get( Request *t, int i );

void request_jobs_iterate( Request *t, int (*callback)( const Job *j));

#endif  /* SATSOLVER_REQUEST_H */
