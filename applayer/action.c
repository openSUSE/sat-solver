/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Action
 *
 * A single 'job' item of a Transaction
 *
 */

#include <stdlib.h>

#include "action.h"
#include "applayer.h"

Action *
action_new( Pool *pool, SolverCmd cmd, Id id )
{
  Action *action = (Action *)malloc( sizeof( Action ));
  action->pool = pool;
  action->cmd = cmd;
  action->id = id;
  return action;
}


void
action_free( Action *a )
{
  free( a );
}


XSolvable *
action_xsolvable( Action *a )
{
  if (a->cmd == SOLVER_INSTALL_SOLVABLE
      || a->cmd == SOLVER_ERASE_SOLVABLE)
    {
      return xsolvable_new( a->pool, a->id );
    }
  return NULL;
}


const char *
action_name( Action *a )
{
  if (a->cmd == SOLVER_INSTALL_SOLVABLE_NAME
      || a->cmd == SOLVER_ERASE_SOLVABLE_NAME)
    {
      return my_id2str( a->pool, a->id );
    }
  return NULL;
}


Relation *
action_relation( Action *a )
{
  if (a->cmd == SOLVER_INSTALL_SOLVABLE_PROVIDES
      || a->cmd == SOLVER_ERASE_SOLVABLE_PROVIDES)
    {
      return relation_new( a->pool, a->id );
    }
  return NULL;
}
