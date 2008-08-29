/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Covenant
 *
 * Covenants ensure specific dependencies in the (installed) system.
 * They are usually used to implement locks.
 *
 */

#include <stdlib.h>

#include "covenant.h"
#include "applayer.h"

Covenant *
covenant_new( Pool *pool, Id cmd, Id id )
{
  Covenant *covenant = (Covenant *)malloc( sizeof( Covenant ));
  covenant->pool = pool;
  covenant->cmd = cmd;
  covenant->id = id;
  return covenant;
}

void
covenant_free( Covenant *c )
{
  free( c );
}

XSolvable *
covenant_xsolvable( const Covenant *c )
{
  if (c->cmd == SOLVER_INSTALL_SOLVABLE
      || c->cmd == SOLVER_ERASE_SOLVABLE)
    {
      return xsolvable_new( c->pool, c->id );
    }
  return NULL;
}


const char *
covenant_name( const Covenant *c )
{
  if (c->cmd == SOLVER_INSTALL_SOLVABLE_NAME
      || c->cmd == SOLVER_ERASE_SOLVABLE_NAME)
    {
      return my_id2str( c->pool, c->id );
    }
  return NULL;
}


Relation *
covenant_relation( const Covenant *c )
{
  if (c->cmd == SOLVER_INSTALL_SOLVABLE_PROVIDES
      || c->cmd == SOLVER_ERASE_SOLVABLE_PROVIDES)
    {
      return relation_new( c->pool, c->id );
    }
  return NULL;
}

void
covenant_include_xsolvable( Solver *s, const XSolvable *xs )
{
  queue_push( &(s->covenantq), SOLVER_INSTALL_SOLVABLE );
  /* FIXME: check: xs->repo->pool == s->pool */
  queue_push( &(s->covenantq), xs->id );
}


void
covenant_exclude_xsolvable( Solver *s, const XSolvable *xs )
{
  queue_push( &(s->covenantq), SOLVER_ERASE_SOLVABLE );
  /* FIXME: check: s->repo->pool == $self->pool */
  queue_push( &(s->covenantq), xs->id );
}
      

void
covenant_include_name( Solver *s, const char *name )
{
  queue_push( &(s->covenantq), SOLVER_INSTALL_SOLVABLE_NAME );
  queue_push( &(s->covenantq), str2id( s->pool, name, 1 ));
}


void
covenant_exclude_name( Solver *s, const char *name )
{
  queue_push( &(s->covenantq), SOLVER_ERASE_SOLVABLE_NAME );
  queue_push( &(s->covenantq), str2id( s->pool, name, 1 ));
}


void
covenant_include_relation( Solver *s, const Relation *rel )
{
  queue_push( &(s->covenantq), SOLVER_INSTALL_SOLVABLE_PROVIDES );
  /* FIXME: check: rel->pool == s->pool */
  queue_push( &(s->covenantq), rel->id );
}


void
covenant_exclude_relation( Solver *s, const Relation *rel )
{
  queue_push( &(s->covenantq), SOLVER_ERASE_SOLVABLE_PROVIDES );
  /* FIXME: check: rel->pool == $self->pool */
  queue_push( &(s->covenantq), rel->id );
}


Covenant *covenant_get( const Solver *s, int i )
{
  int size, cmd;
  Id id;
  i <<= 1;
  size = s->covenantq.count;
  if (i-1 >= size)
    return NULL;
  cmd = s->covenantq.elements[i];
  id = s->covenantq.elements[i+1];
  return covenant_new( s->pool, cmd, id );
}
