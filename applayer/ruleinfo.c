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

#include <stdlib.h>

#include "ruleinfo.h"

#include "applayer.h"


Ruleinfo *
ruleinfo_new( const Solver *solver, Id rule )
{
  Ruleinfo *ri = (Ruleinfo *)calloc( 1, sizeof( Ruleinfo ));
  ri->solver = solver;
  ri->cmd = solver_ruleinfo((Solver *)solver, rule, &(ri->source), &(ri->target), &(ri->dep));
  return ri;
}


void
ruleinfo_free( Ruleinfo *ri )
{
  free( ri );
}


int
ruleinfo_command(const Ruleinfo *ri)
{
  return ri->cmd;
}


XSolvable *
ruleinfo_source(const Ruleinfo *ri)
{
  return ri->source ? xsolvable_new( ri->solver->pool, ri->source ) : NULL;
}


XSolvable *
ruleinfo_target(const Ruleinfo *ri)
{
  return ri->target ? xsolvable_new( ri->solver->pool, ri->target ) : NULL;
}


Relation *
ruleinfo_relation(const Ruleinfo *ri)
{
  return ri->dep ? relation_new( ri->solver->pool, ri->dep ) : NULL;
}
