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

void request_xsolvable( Request *t, XSolvable *xs, int what );
void request_name( Request *t, const char *name, int what );
void request_relation( Request *t, const Relation *rel, int what );

int request_size( Request *t );
Job *request_job_get( Request *t, int i );

void request_jobs_iterate( Request *t, int (*callback)(const Job *j, void *user_data), void *user_data);

#endif  /* SATSOLVER_REQUEST_H */
