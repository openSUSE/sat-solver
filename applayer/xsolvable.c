/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

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

#include <stdlib.h>
#include <string.h>
#include <policy.h>

#include "xsolvable.h"
#include "solverdebug.h"


XSolvable *
xsolvable_new( Pool *pool, Id id )
{
  XSolvable *xsolvable = (XSolvable *)malloc( sizeof( XSolvable ));
  xsolvable->pool = pool;
  xsolvable->id = id;

  return xsolvable;
}


XSolvable *
xsolvable_create( Repo *repo, const char *name, const char *evr, const char *arch )
{
  Id sid = repo_add_solvable( repo );
  Pool *pool = repo->pool;
  XSolvable *xsolvable = xsolvable_new( pool, sid );
  Solvable *s = pool_id2solvable( pool, sid );
  Id nameid = str2id( pool, name, 1 );
  Id evrid = str2id( pool, evr, 1 );
  Id archid, rel;
  if (arch == NULL) arch = "noarch";
  archid = str2id( pool, arch, 1 );
  s->name = nameid;
  s->evr = evrid;
  s->arch = archid;

  /* add self-provides */
  rel = rel2id( pool, nameid, evrid, REL_EQ, 1 );
  s->provides = repo_addid_dep( repo, s->provides, rel, 0 );

  return xsolvable;
}


void
xsolvable_free( XSolvable *xs )
{
  free( xs );
}


Solvable *
xsolvable_solvable( const XSolvable *xs )
{
  return pool_id2solvable( xs->pool, xs->id );
}


/*
 * equality
 */

int
xsolvable_equal( XSolvable *xs1, XSolvable *xs2 )
{
/*  fprintf(stderr, "%p[%p/%d] == %p[%p/%d] ?\n", xs1, xs1->pool, xs1->id, xs2, xs2->pool, xs2->id); */
  if ((xs1 == xs2)
      || ((xs1->pool == xs2->pool)
         && (xs1->id == xs2->id)))
    {
      return 1;
    }
  return 0;
}


static void
copy_deps( Repo *repo, Offset *ndeps, Id *odeps )
{
  while (*odeps) {
    *ndeps = repo_addid( repo, *ndeps, *odeps );
    ++odeps;
  }
}

/*
 * crude hack of adding an existing Solvable to another Repo
 */

XSolvable *
xsolvable_add( Repo *repo, XSolvable *xs )
{
  Id sid;
  Solvable *old_s, *new_s;
  
  if (repo->pool != xs->pool)
    return NULL;                       /* must be of same repo */

  sid = repo_add_solvable( repo );

  old_s = pool_id2solvable( xs->pool, xs->id );
  new_s = pool_id2solvable( repo->pool, sid );

  new_s->name = old_s->name;
  new_s->evr = old_s->evr;
  new_s->arch = old_s->arch;
  new_s->vendor = old_s->vendor;

  copy_deps( repo, &(new_s->provides), old_s->repo->idarraydata + old_s->provides );
  copy_deps( repo, &(new_s->requires), old_s->repo->idarraydata + old_s->requires );
  copy_deps( repo, &(new_s->obsoletes), old_s->repo->idarraydata + old_s->obsoletes );
  copy_deps( repo, &(new_s->conflicts), old_s->repo->idarraydata + old_s->conflicts );

  copy_deps( repo, &(new_s->recommends), old_s->repo->idarraydata + old_s->recommends );
  copy_deps( repo, &(new_s->suggests), old_s->repo->idarraydata + old_s->suggests );
  copy_deps( repo, &(new_s->supplements), old_s->repo->idarraydata + old_s->supplements );
  copy_deps( repo, &(new_s->enhances), old_s->repo->idarraydata + old_s->enhances );

  return xsolvable_new( repo->pool, sid );
}

/************************************************
 * Pool/Repo
 *
 */

XSolvable *
xsolvable_find( Pool *pool, char *name, const Repo *repo )
{
  Id id;
  Queue plist;
  int i, end;
  Solvable *s;
  Solver *solver = solver_create(pool);

  id = str2id( pool, name, 1 );
  queue_init( &plist);
  i = repo ? repo->start : 1;
  end = repo ? repo->start + repo->nsolvables : pool->nsolvables;
  for (; i < end; i++) {
    s = pool->solvables + i;
    if (!pool_installable(pool, s))
      continue;
    if (repo && (s->repo != repo))
      continue;
    if (s->name == id)
      queue_push(&plist, i);
  }

  prune_to_best_arch(pool, &plist);
  prune_to_best_version(solver, &plist);
  if (plist.count == 0) {
    return NULL;
  }

  id = plist.elements[0];
  queue_free(&plist);

  return xsolvable_new( pool, id );
}


/*
 * get solvable by index (0..size-1)
 * If repo == NULL, index is relative to pool
 * If repo != NULL, index is relative to repo
 * 
 * index is _not_ the internal id, but used as an array index
 */

XSolvable *
xsolvable_get( Pool *pool, int i, const Repo *repo )
{
  if (repo == NULL)
    i += 2; /* adapt to internal Id, see size() above */
  if (i < 0)
    return NULL;
  if (i >= (repo ? repo->nsolvables : pool->nsolvables))
    return NULL;
  return xsolvable_new( repo ? repo->pool : pool, repo ? repo->start + i : i );
}


/*
 * Iterate over all installs
 */

void
solver_installs_iterate( Solver *solver, int all, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data )
{
  Id p;
  Solvable *s;
  int i;
  Id *obsoletesmap = 0;
  Repo *installed = solver->installed; /* repo of installed solvables */

  if (!callback)
    return;

  if (!all)
    obsoletesmap = solver_create_decisions_obsoletesmap( solver );
  
  for ( i = 0; i < solver->decisionq.count; i++)
    {
      p = solver->decisionq.elements[i];
      if (p <= 0)
        continue;       /* conflicting package, ignore */
      if (p == SYSTEMSOLVABLE)
        continue;       /* system resolvable, always installed */
      
      // getting repo
      s = solver->pool->solvables + p;
      Repo *repo = s->repo;
      if (!repo || repo == installed)
        continue;       /* already installed resolvable */

      if (!obsoletesmap || !obsoletesmap[p])
	if (callback( xsolvable_new( solver->pool, p ), user_data ) )
	  break;
    }
  if (obsoletesmap)
    sat_free( obsoletesmap );
}


/*
 * Iterate over all removals
 */

void
solver_removals_iterate( Solver *solver, int all, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data )
{
  Id p;
  Solvable *s;
  Id *obsoletesmap = NULL;
  Repo *installed = solver->installed; /* repo of installed solvables */

  if (!callback)
    return;
  
  if (!installed)
    return;

  if (!all)
    obsoletesmap = solver_create_decisions_obsoletesmap( solver );
  
  /* solvables to be removed */
  FOR_REPO_SOLVABLES(installed, p, s)
    {
      if (solver->decisionmap[p] >= 0)
        continue;       /* we keep this package */
      if (obsoletesmap && obsoletesmap[p])
	continue;       /* its being obsoleted (updated) */
      if (callback( xsolvable_new( solver->pool, p ), user_data ) )
	break;
    }
  if (obsoletesmap)
    sat_free( obsoletesmap );
}


/*
 * Iterate over all updates
 */

void
solver_updates_iterate( Solver *solver, int (*callback)( const XSolvable *xs_old, const XSolvable *xs_new, void *user_data ), void *user_data )
{
  Id p;
  Solvable *s;
  Id *obsoletesmap = NULL;
  Repo *installed = solver->installed; /* repo of installed solvables */

  if (!callback)
    return;
  
  
  if (!installed)
    return;

  obsoletesmap = solver_create_decisions_obsoletesmap( solver );

  /* solvables to be removed */
  FOR_REPO_SOLVABLES(installed, p, s)
    {
      if (solver->decisionmap[p] >= 0)
        continue;       /* we keep this package */
      if (obsoletesmap[p])
	if (callback( xsolvable_new( solver->pool, p ), xsolvable_new( solver->pool, obsoletesmap[p] ), user_data ) )
	  break;
    }
  sat_free( obsoletesmap );
}


void
solver_suggestions_iterate( Solver *solver, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data )
{
  int i;

  if (!callback)
    return;
  
  for (i = 0; i < solver->suggestions.count; i++)
    {
      if (callback( xsolvable_new( solver->pool, solver->suggestions.elements[i] ), user_data ) )
	break;
    }
}


/*
 * count solvables in Repo
 * This is the number of iterations in repo_xsolvables_iterate
 */

int
repo_xsolvables_count( Repo *repo )
{
  Solvable *s;
  Id p;
  int count = 0;
  FOR_REPO_SOLVABLES(repo, p, s)
    {
      if (!s)
        continue;
      if (!s->name)
        continue;
      count++;
    }
  return count;
}


/*
 * iterate over all solvables in Repo
 */

void
repo_xsolvables_iterate( Repo *repo, int (*callback)( const XSolvable *xs, void *user_data ), void *user_data )
{
  Solvable *s;
  Id p;
  FOR_REPO_SOLVABLES(repo, p, s)
    {
      if (!s)
        continue;
      if (!s->name)
        continue;
      if (callback( xsolvable_new( repo->pool, s - repo->pool->solvables ), user_data ) )
	break;
    }
}
