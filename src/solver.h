/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * solver.h
 *
 */

#ifndef SOLVER_H
#define SOLVER_H

#include "pooltypes.h"
#include "pool.h"
#include "repo.h"
#include "queue.h"
#include "bitmap.h"

/* ----------------------------------------------
 * Rule
 *
 *   providerN(B) == Package Id of package providing tag B
 *   N = 1, 2, 3, in case of multiple providers
 *
 * A requires B : !A | provider1(B) | provider2(B)
 *
 * A conflicts B : (!A | !provider1(B)) & (!A | !provider2(B)) ...
 *
 * 'not' is encoded as a negative Id
 * 
 * Binary rule: p = first literal, d = 0, w2 = second literal, w1 = p
 */

typedef struct rule {
  Id p;			/* first literal in rule */
  Id d;			/* Id offset into 'list of providers terminated by 0' as used by whatprovides; pool->whatprovides + d */
			/* in case of binary rules, d == 0, w1 == p, w2 == other literal */
  Id w1, w2;		/* watches, literals not-yet-decided */
  				       /* if !w1, disabled */
  				       /* if !w2, assertion, not rule */
  Id n1, n2;		/* next rules in linked list, corresponding to w1,w2 */
} Rule;

struct solver;

typedef struct solver {
  Pool *pool;
  Repo *installed;

  int fixsystem;			/* repair errors in rpm dependency graph */
  int allowdowngrade;			/* allow to downgrade installed solvable */
  int allowarchchange;			/* allow to change architecture of installed solvables */
  int allowvendorchange;		/* allow to change vendor of installed solvables */
  int allowuninstall;			/* allow removal of installed solvables */
  int updatesystem;			/* distupgrade */
  int allowvirtualconflicts;		/* false: conflicts on package name, true: conflicts on package provides */
  int noupdateprovide;			/* true: update packages needs not to provide old package */
  
  Rule *rules;				/* all rules */
  Id nrules;				/* rpm rules */

  Id jobrules;				/* user rules */
  Id systemrules;			/* policy rules, e.g. keep packages installed or update. All literals > 0 */
  Id weakrules;				/* rules that can be autodisabled */
  Id learntrules;			/* learnt rules */

  Id *weaksystemrules;			/* please try to install (r->d) */
  Map noupdate;				/* don't try to update these
                                           installed solvables */

  Id *watches;				/* Array of rule offsets
					 * watches has nsolvables*2 entries and is addressed from the middle
					 * middle-solvable : decision to conflict, offset point to linked-list of rules
					 * middle+solvable : decision to install: offset point to linked-list of rules
					 */

  Queue ruletojob;

  /* our decisions: */
  Queue decisionq;
  Queue decisionq_why;			/* index of rule, Offset into rules */
  Id *decisionmap;			/* map for all available solvables, > 0: level of decision when installed, < 0 level of decision when conflict */

  /* learnt rule history */
  Queue learnt_why;
  Queue learnt_pool;

  Queue branches;
  int (*solution_callback)(struct solver *solv, void *data);
  void *solution_callback_data;

  int propagate_index;

  Queue problems;
  Queue suggestions;			/* suggested packages */

  Map recommendsmap;			/* recommended packages from decisionmap */
  Map suggestsmap;			/* suggested packages from decisionmap */
  int recommends_index;			/* recommended level */

  Id *obsoletes;			/* obsoletes for each installed solvable */
  Id *obsoletes_data;			/* data area for obsoletes */

  int rc_output;			/* output result compatible to redcarpet/zypp testsuite, set == 2 for pure rc (will suppress architecture) */
} Solver;

/*
 * queue commands
 */

enum solvcmds {
  SOLVCMD_NULL=0,
  SOLVER_INSTALL_SOLVABLE,
  SOLVER_ERASE_SOLVABLE,
  SOLVER_INSTALL_SOLVABLE_NAME,
  SOLVER_ERASE_SOLVABLE_NAME,
  SOLVER_INSTALL_SOLVABLE_PROVIDES,
  SOLVER_ERASE_SOLVABLE_PROVIDES,
  SOLVER_INSTALL_SOLVABLE_UPDATE
} SolverCmd;

extern Solver *solver_create(Pool *pool, Repo *installed);
extern void solver_free(Solver *solv);
extern void solve(Solver *solv, Queue *job);
extern int solver_dep_installed(Solver *solv, Id dep);

void printdecisions(Solver *solv);

void refine_suggestion(Solver *solv, Queue *job, Id *problem, Id sug, Queue *refined);
int archchanges(Pool *pool, Solvable *s1, Solvable *s2);

static inline int
solver_dep_fulfilled(Solver *solv, Id dep)
{
  Pool *pool = solv->pool;
  Id p, *pp;

  if (ISRELDEP(dep))
    {
      Reldep *rd = GETRELDEP(pool, dep);
      if (rd->flags == REL_AND)
        {
          if (!solver_dep_fulfilled(solv, rd->name))
            return 0;
          return solver_dep_fulfilled(solv, rd->evr);
        }
      if (rd->flags == REL_NAMESPACE && rd->name == NAMESPACE_INSTALLED)
        return solver_dep_installed(solv, rd->evr);
    }
  FOR_PROVIDES(p, pp, dep)
    {
      if (solv->decisionmap[p] > 0)
        return 1;
    }
  return 0;
}

static inline int
solver_is_supplementing(Solver *solv, Solvable *s)
{
  Id sup, *supp;
  if (!s->supplements && !s->freshens)
    return 0;
  if (s->supplements)
    {
      supp = s->repo->idarraydata + s->supplements;
      while ((sup = *supp++) != 0)
        if (solver_dep_fulfilled(solv, sup))
          break;
      if (!sup)
        return 0;
    }
  if (s->freshens)
    {
      supp = s->repo->idarraydata + s->freshens;
      while ((sup = *supp++) != 0)
        if (solver_dep_fulfilled(solv, sup))
          break;
      if (!sup)
        return 0;
    }
  return 1;
}

static inline int
solver_is_enhancing(Solver *solv, Solvable *s)
{
  Id enh, *enhp;
  if (!s->enhances)
    return 0;
  enhp = s->repo->idarraydata + s->enhances;
  while ((enh = *enhp++) != 0)
    if (solver_dep_fulfilled(solv, enh))
      return 1;
  return 0;
}

#endif /* SOLVER_H */
