/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_COVENANT_H
#define SATSOLVER_COVENANT_H

/************************************************
 * Covenant
 *
 * Covenants ensure specific dependencies in the (installed) system.
 * They are usually used to implement locks.
 *
 */

#include <solver.h>

#include "xsolvable.h"
#include "relation.h"

typedef struct _Covenant {
  Pool *pool;
  Id cmd;
  Id id;
} Covenant;

Covenant *covenant_new( Pool *pool, Id cmd, Id id );
void covenant_free( Covenant *c );

XSolvable *covenant_xsolvable( const Covenant *c );
const char *covenant_name( const Covenant *c );
Relation *covenant_relation( const Covenant *c );

void covenant_include_xsolvable( Solver *s, const XSolvable *xs );
void covenant_exclude_xsolvable( Solver *s, const XSolvable *xs );
void covenant_include_name( Solver *s, const char *name );
void covenant_exclude_name( Solver *s, const char *name );
void covenant_include_relation( Solver *s, const Relation *rel );
void covenant_exclude_relation( Solver *s, const Relation *rel );
Covenant *covenant_get( const Solver *s, int i );

#endif  /* SATSOLVER_COVENANT_H */

