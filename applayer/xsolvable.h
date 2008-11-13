/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_XSOLVABLE_H
#define SATSOLVER_XSOLVABLE_H

#include "pool.h"
#include "repo.h"
#include "solvable.h"
#include "solver.h"

#include "kinds.h"

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
  unsigned int kind;           /* one of KIND_xxx */
} XSolvable;

/*
 * Create a new XSolvable in pool from Solvable id
 */
XSolvable *xsolvable_new( Pool *pool, Id id );

/*
 * Create a new XSolvable in pool from name, evr, arch
 */
XSolvable *xsolvable_create( Repo *repo, const char *name, const char *evr, const char *arch );

/*
 * Free a previously created XSolvable
 */
void xsolvable_free( XSolvable *xs );

/*
 * Check for equality
 * Two XSolvables are equal if they both reference the same Id of the same pool.
 */
int xsolvable_equal( XSolvable *xs1, XSolvable *xs2 );

/*
 * Return the Solvable corresponding to the given XSolvable
 */
Solvable *xsolvable_solvable( const XSolvable *xs );

/*
 * Add an existing solvable to Repo
 */
XSolvable *xsolvable_add( Repo *repo, XSolvable *xs );

/*
 * Find XSolvable by name in pool (and repo)
 * If repo == NULL, search the complete pool
 * If repo != NULL, limit search to the given repo
 */
XSolvable *xsolvable_find( Pool *pool, char *name, const Repo *repo );

/* iterate over all (newly-)to-be-installed solvables
 * if all = 0, only report *newly* installed ones (non-updates)
 * if all = 1, report all to-be-installed ones
 */
void solver_installs_iterate( Solver *solver, int all, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data );

/* iterate over all to-be-removed solvables
 * if all = 0, only report *dropped* ones (non-updates)
 * if all = 1, report all to-be-removed  ones
 */
void solver_removals_iterate( Solver *solver, int all, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data );

/*
 * Iterate over all solvables which update installed ones
 */
void solver_updates_iterate( Solver *solver, int (*callback)( const XSolvable *xs_old, const XSolvable *xs_new, void *user_data ), void *user_data );

/*
 * Iterate over all solvables being suggested in the last solver run
 */
void solver_suggestions_iterate( Solver *solver, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data );

/*
 * Count solvables in a Repo
 * This is the number of iterations when calling repo_xsolvables_iterate for this Repo
 */
int repo_xsolvables_count( Repo *repo );

/*
 * Iterate over all solvables of the given repo
 */
void repo_xsolvables_iterate( Repo *repo, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data );

#endif  /* SATSOLVER_XSOLVABLE_H */
