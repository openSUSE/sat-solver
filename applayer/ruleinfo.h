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

const char *ruleinfo_command_string(const Ruleinfo *ri);
int ruleinfo_command(const Ruleinfo *ri);
XSolvable *ruleinfo_source(const Ruleinfo *ri);
XSolvable *ruleinfo_target(const Ruleinfo *ri);
Relation *ruleinfo_relation(const Ruleinfo *ri);

#endif  /* SATSOLVER_RULEINFO_H */
