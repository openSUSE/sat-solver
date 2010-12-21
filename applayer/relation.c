/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * Relation
 *
 */

#include <stdlib.h>
#include <string.h>

#include "relation.h"


Relation *
relation_new( const Pool *pool, Id id )
{
  Relation *relation;
  if (!id) return NULL;
  relation = (Relation *)malloc( sizeof( Relation ));
  relation->id = id;
  relation->pool = pool;
  return relation;
}


void
relation_free( Relation *r )
{
  free( r );
}


char *
relation_string(const Relation *r)
{
   return strdup(dep2str( (Pool *)r->pool, r->id ));
}


Relation *
relation_create( Pool *pool, const char *name, int op, const char *evr )
{
  Id name_id = str2id( pool, name, 1 );
  Id evr_id;
  Id rel;
  if (op == REL_NONE)
    return relation_new( pool, name_id );
  evr_id = str2id( pool, evr, 1 );
  rel = rel2id( pool, name_id, evr_id, op, 1 );
  return relation_new( pool, rel );
}


Id
relation_evrid( const Relation *r )
{
  if (ISRELDEP( r->id )) {
    Reldep *rd = GETRELDEP( r->pool, r->id );
    return rd->evr;
  }
  return ID_NULL;
}
