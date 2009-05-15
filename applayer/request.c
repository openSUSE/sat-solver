/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Transaction
 *
 * A set of Actions to be solved by the Solver
 *
 */

#include <stdlib.h>

#include "transaction.h"


Transaction *
transaction_new( Pool *pool )
{
  Transaction *t = (Transaction *)malloc( sizeof( Transaction ));
  t->pool = pool;
  queue_init( &(t->queue) );
  return t;
}

void
transaction_free( Transaction *t )
{
  queue_free( &(t->queue) );
  free( t );
}


/*
 * number of actions in transaction
 * every two queue elements make one action
 */

int
transaction_size( Transaction *t )
{
  return t->queue.count >> 1;
}


void
transaction_install_xsolvable( Transaction *t, XSolvable *xs )
{
  queue_push( &(t->queue), SOLVER_INSTALL_SOLVABLE );
  /* FIXME: check: s->repo->pool == $self->pool */
  queue_push( &(t->queue), xs->id );
}


void
transaction_remove_xsolvable( Transaction *t, XSolvable *xs )
{
  queue_push( &(t->queue), SOLVER_ERASE_SOLVABLE );
  /* FIXME: check: s->repo->pool == $self->pool */
  queue_push( &(t->queue), xs->id );
}


void
transaction_install_name( Transaction *t, const char *name )
{
  queue_push( &(t->queue), SOLVER_INSTALL_SOLVABLE_NAME );
  queue_push( &(t->queue), str2id( t->pool, name, 1 ));
}


void
transaction_remove_name( Transaction *t, const char *name )
{
  queue_push( &(t->queue), SOLVER_ERASE_SOLVABLE_NAME );
  queue_push( &(t->queue), str2id( t->pool, name, 1 ));
}


void
transaction_install_relation( Transaction *t, const Relation *rel )
{
  queue_push( &(t->queue), SOLVER_INSTALL_SOLVABLE_PROVIDES );
  /* FIXME: check: rel->pool == $self->pool */
  queue_push( &(t->queue), rel->id );
}


void
transaction_remove_relation( Transaction *t, const Relation *rel )
{
  queue_push( &(t->queue), SOLVER_ERASE_SOLVABLE_PROVIDES );
  /* FIXME: check: rel->pool == $self->pool */
  queue_push( &(t->queue), rel->id );
}


Job *
transaction_job_get( Transaction *t, int i )
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
transaction_jobs_iterate( Transaction *t, int (*callback)( const Job *j))
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
