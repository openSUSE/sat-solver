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

#include <stdlib.h>

#include "request.h"


Request *
request_new( Pool *pool )
{
  Request *t = (Request *)malloc( sizeof( Request ));
  t->pool = pool;
  queue_init( &(t->queue) );
  return t;
}

void
request_free( Request *t )
{
  queue_free( &(t->queue) );
  free( t );
}


/*
 * number of actions in request
 * every two queue elements make one action
 */

int
request_size( Request *t )
{
  return t->queue.count >> 1;
}


void
request_install_xsolvable( Request *t, XSolvable *xs )
{
  queue_push( &(t->queue), SOLVER_INSTALL|SOLVER_SOLVABLE );
  /* FIXME: check: s->repo->pool == $self->pool */
  queue_push( &(t->queue), xs->id );
}


void
request_remove_xsolvable( Request *t, XSolvable *xs )
{
  queue_push( &(t->queue), SOLVER_ERASE|SOLVER_SOLVABLE );
  /* FIXME: check: s->repo->pool == $self->pool */
  queue_push( &(t->queue), xs->id );
}


void
request_install_name( Request *t, const char *name )
{
  queue_push( &(t->queue), SOLVER_INSTALL|SOLVER_SOLVABLE_NAME );
  queue_push( &(t->queue), str2id( t->pool, name, 1 ));
}


void
request_remove_name( Request *t, const char *name )
{
  queue_push( &(t->queue), SOLVER_ERASE|SOLVER_SOLVABLE_NAME );
  queue_push( &(t->queue), str2id( t->pool, name, 1 ));
}


void
request_install_relation( Request *t, const Relation *rel )
{
  queue_push( &(t->queue), SOLVER_INSTALL|SOLVER_SOLVABLE_PROVIDES );
  /* FIXME: check: rel->pool == $self->pool */
  queue_push( &(t->queue), rel->id );
}


void
request_remove_relation( Request *t, const Relation *rel )
{
  queue_push( &(t->queue), SOLVER_ERASE|SOLVER_SOLVABLE_PROVIDES );
  /* FIXME: check: rel->pool == $self->pool */
  queue_push( &(t->queue), rel->id );
}


Job *
request_job_get( Request *t, int i )
{
  int size, cmd;
  Id id;
  i <<= 1;
  size = t->queue.count;
  if (i-1 >= size)
    return NULL;
  cmd = t->queue.elements[i];
  id = t->queue.elements[i+1];
  return job_new( t->pool, cmd, id );
}


void
request_jobs_iterate( Request *t, int (*callback)( const Job *j))
{
  int i;
  for (i = 0; i < t->queue.count-1; )
    {
      int cmd = t->queue.elements[i++];
      Id id = t->queue.elements[i++];
      if (callback( job_new( t->pool, cmd, id ) ) )
	break;
    }
}
