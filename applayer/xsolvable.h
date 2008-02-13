/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_XSOLVABLE_H
#define SATSOLVER_XSOLVABLE_H

#include <pool.h>
#include <repo.h>
#include <solvable.h>
#include <solver.h>

/************************************************
 * XSolvable - eXternally visible Solvable
 *
 * we cannot use a Solvable pointer since the Pool might realloc them
 * so we use a combination of Solvable Id and Pool the Solvable belongs
 * to. pool_id2solvable() gives us the pointer.
 *
 * And we cannot use Solvable because its already defined in solvable.h
 * Later, when defining the bindings, a %rename is used to make
 * 'Solvable' available in the target language. Swig tightrope walk.
 */

typedef struct _xsolvable {
  Pool *pool;
  Id id;
} XSolvable;

XSolvable *xsolvable_new( Pool *pool, Id id );
XSolvable *xsolvable_create( Repo *repo, const char *name, const char *evr, const char *arch );
void xsolvable_free( XSolvable *xs );
Solvable *xsolvable_solvable( const XSolvable *xs );
XSolvable *xsolvable_find( Pool *pool, char *name, const Repo *repo );
XSolvable *xsolvable_get( Pool *pool, int i, const Repo *repo );


void solver_installs_iterate( Solver *solver, int (*callback)( const XSolvable *xs ) );
void solver_removals_iterate( Solver *solver, int (*callback)( const XSolvable *xs ) );
void solver_suggestions_iterate( Solver *solver, int (*callback)( const XSolvable *xs ) );

void repo_xsolvables_iterate( Repo *repo, int (*callback)( const XSolvable *xs ) );

#endif  /* SATSOLVER_XSOLVABLE_H */
