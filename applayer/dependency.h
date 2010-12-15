/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_DEPENDENCY_H
#define SATSOLVER_DEPENDENCY_H

#include "xsolvable.h"
#include "relation.h"

/************************************************
 * Dependency
 *
 * Collection of Relations -> Dependency
 */

enum dependencies {
  DEP_PRV = 1,
  DEP_REQ,
  DEP_CON,
  DEP_OBS,
  DEP_REC,
  DEP_SUG,
  DEP_SUP,
  DEP_ENH
};

typedef struct _Dependency {
  enum dependencies dep;           /* type of dep, any of DEP_xxx */
  XSolvable *xsolvable;            /* xsolvable this dep belongs to */
} Dependency;

Dependency *dependency_new( XSolvable *xsolvable, int dep );
void dependency_free( Dependency *dep );

/* get pointer to offset for dependency */
Offset *dependency_relations( const Dependency *dep );

int dependency_size( const Dependency *dep );

void dependency_relation_add( Dependency *dep, Relation *rel, int pre );
Relation *dependency_relation_get( Dependency *dep, int i );
void dependency_relations_iterate( Dependency *dep, int (*callback)(const Relation *rel, void *user_data), void *user_data);

#endif  /* SATSOLVER_DEPENDENCY_H */
