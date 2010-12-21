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
  Solver *solver;
  Id id;
  int cmd;
  Id source;
  Id target;
  Id dep;
} Ruleinfo;


Ruleinfo *ruleinfo_new( Solver *solver, Id rule );
char *ruleinfo_string( const Ruleinfo *ri);
void ruleinfo_free( Ruleinfo *ri );

const char *ruleinfo_command_string(const Ruleinfo *ri);
int ruleinfo_command(const Ruleinfo *ri);
XSolvable *ruleinfo_source(const Ruleinfo *ri);
XSolvable *ruleinfo_target(const Ruleinfo *ri);
Relation *ruleinfo_relation(const Ruleinfo *ri);

#endif  /* SATSOLVER_RULEINFO_H */
