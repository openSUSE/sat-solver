/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Ruleinfo
 *
 * Information about a single solver rule.
 *
 */


#ifndef SATSOLVER_RULEINFO_H
#define SATSOLVER_RULEINFO_H

#include "pool.h"
#include "solver.h"

#include "xsolvable.h"
#include "relation.h"

typedef struct _Ruleinfo {
  const Solver *solver;
  int cmd;
  Id source;
  Id target;
  Id dep;
} Ruleinfo;


Ruleinfo *ruleinfo_new( const Solver *solver, Id rule );
void ruleinfo_free( Ruleinfo *ri );

int command(const Ruleinfo *ri);
XSolvable *source(const Ruleinfo *ri);
XSolvable *target(const Ruleinfo *ri);
Relation *relation(const Ruleinfo *ri);

#endif  /* SATSOLVER_RULEINFO_H */
