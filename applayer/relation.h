/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_RELATION_H
#define SATSOLVER_RELATION_H

#include "pool.h"

/************************************************
 * Relation
 *
 */

#define REL_NONE 0

typedef struct _Relation {
  Offset id;
  Pool *pool;
} Relation;

Relation *relation_new( Pool *pool, Id id );
Relation *relation_create( Pool *pool, const char *name, int op, const char *evr );
void relation_free( Relation *r );
Id relation_evrid( const Relation *r );

#endif  /* SATSOLVER_RELATION_H */
