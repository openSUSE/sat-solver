/*
 * Solver
=begin rdoc
Document-class: Solver
The solver class is at the heart of the satsolver, providing
ultra-fast dependency resolution.

The solver is always attached to a pool, containing all solvables the
solver can operate on. The pool also has designated repository for
'installed' solvables.

Solving is done by creating Transactions and feeding them to the
solver as input. On success (solver.solve() returning 'true'), one can
retrieve the Decisions made by the solver (i.e. install this, remove
that, update those). On failure, the solver creates a list of
Problems, explaining what went wrong and how to resolve the problem.

Solving can be controlled globally by setting solver flags.
Additionally, specific constraints can be set by using Covenants.
=end
 */

%{
#if defined(SWIGRUBY)
/*
 * iterating over updates (takes two (x)solvables) ('yield' in Ruby)
 */

static int
update_xsolvables_iterate_callback( const XSolvable *xs_old, const XSolvable *xs_new, void *user_data )
{
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield_values( 2, SWIG_NewPointerObj((void*)xs_old, SWIGTYPE_p__Solvable, 0), SWIG_NewPointerObj((void*)xs_new, SWIGTYPE_p__Solvable, 0) );
  return 0;
}

/*
 * iterating over solver decisions ('yield' in Ruby)
 */

static int
solver_decisions_iterate_callback( const Decision *d, void *user_data )
{
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield(SWIG_NewPointerObj((void*) d, SWIGTYPE_p__Decision, 0));
  return 0;
}


/*
 * iterating over solver problems ('yield' in Ruby)
 */

static int
solver_problems_iterate_callback( const Problem *p, void *user_data )
{
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) p, SWIGTYPE_p__Problem, 0) );
  return 0;
}
#endif /* SWIGRUBY */


%}


%nodefault solver;
%rename(Solver) solver;
typedef struct solver {} Solver;


%extend Solver {
  /*
   * Document-method: new
   * Create a solver operating on a pool
   * Equivalent: Pool.create_solver
   * call-seq:
   *  Solver.new(pool) -> Solver
   *
   */
  Solver( Pool *pool )
  { return solver_create( pool); }
  ~Solver()
  { solver_free( $self ); }

  /**************************
   * Solver policies
   */

  /* yeah, thats awkward. But %including solver.h and adding lots
     of %ignores is even worse ... */

#if defined(SWIGRUBY)
  %typemap(out) int fix_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Document-method: fix_system
   *
   * Check and fix inconsistencies of the installed system
   *
   * Normally, broken dependencies in the RPM database are silently
   * ignored in order to prevent clutter in the solution.
   * Setting fix_system to 'true' will repair broken system
   * dependencies.
   *
   * call-seq:
   *  solver.fix_system -> bool
   *
   */
  int fix_system()
  { return $self->fixsystem; }
#if defined(SWIGRUBY)
  /*
   * Document-method: fix_system=
   * Set the fix_system flag
   * call-seq:
   *   solver.fix_system = true
   *
   */
  %rename( "fix_system=" ) set_fix_system( int bflag );
#endif
  void set_fix_system( int bflag )
  { $self->fixsystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_downgrade
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Document-method: allow_downgrade
   * Allow downgrade
   * The normal solver operation tries to install (to update to) the 'best' package,
   * usually the one with the highest version.
   * If allow_downgrade is set, packages may be downgraded in order to
   * fulfill a transaction or a dependency
   * call-seq:
   *  solver.allow_downgrade -> bool
   *
   */
  int allow_downgrade()
  { return $self->allowdowngrade; }
#if defined(SWIGRUBY)
  /*
   * Document-method: allow_downgrade=
   * Allow or disallow package downgrades
   * call-seq:
   *  solver.allow_downgrade = true
   *
   */
  %rename( "allow_downgrade=" ) set_allow_downgrade( int bflag );
#endif
  void set_allow_downgrade( int bflag )
  { $self->allowdowngrade = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_arch_change
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Document-method: allow_arch_change
   * Allow arch change
   * After installation, the architecture of a package is fixed an the
   * solver will not change it during upgrades.
   * This prevents updates to a higher version but inferior
   * architecture.
   * If this flag is set, packages can change their architecture. The
   * solver will usually try to select the 'best' architecture.
   * call-seq:
   *  solver.allow_arch_change -> bool
   *
   */
  int allow_arch_change()
  { return $self->allowarchchange; }
#if defined(SWIGRUBY)
  /*
   * Document-method: allow_arch_change=
   * Allow or disallow architecture changes
   * call-seq:
   *  solver.allow_arch_change = true
   *
   */
  %rename( "allow_arch_change=" ) set_allow_arch_change( int bflag );
#endif
  void set_allow_arch_change( int bflag )
  { $self->allowarchchange = bflag; }

  /*
   * Document-method: allow_vendor_change
   * Allow vendor change
   * The package vendor is usually an indicator of the package origin.
   * Updates should only come from the same origin.
   * If this flag is true, the solver will allow vendor changes during
   * package upgrades.
   * call-seq:
   *  solver.allow_vendor_change -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int allow_vendor_change
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_vendor_change()
  { return $self->allowvendorchange; }
#if defined(SWIGRUBY)
  /*
   * Document-method: allow_vendor_change=
   * Allow vendor change
   * call-seq:
   *  solver.allow_vendor_change = true
   *
   */
  %rename( "allow_vendor_change=" ) set_allow_vendor_change( int bflag );
#endif
  void set_allow_vendor_change( int bflag )
  { $self->allowvendorchange = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_uninstall
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Document-method: allow_uninstall
   * On package removal, also remove dependant packages.
   *
   * If removal of a package breaks dependencies, the transaction is
   * usually considered not solvable. The dependencies of installed
   * packages take precedence over transaction actions.
   *
   *
   * call-seq:
   *  solver.allow_uninstall -> bool
   *
   */
  int allow_uninstall()
  { return $self->allowuninstall; }
#if defined(SWIGRUBY)
  /*
   * Document-method: allow_uninstall=
   * On package removal, also remove dependant packages.
   *
   * Setting allow_uninstall to 'true' will revert the precedence
   * and remove all dependant packages.
   * call-seq:
   *  solver.allow_uninstall = true
   *
   */
  %rename( "allow_uninstall=" ) set_allow_uninstall( int bflag );
#endif
  void set_allow_uninstall( int bflag )
  { $self->allowuninstall = bflag; }

  /*
   * Document-method: update_system
   * Update system
   * call-seq:
   *  solver.update_system -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int update_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int update_system()
  { return $self->updatesystem; }
#if defined(SWIGRUBY)
  /*
   * Document-method: update_system=
   * call-seq:
   *  solver.update_system = true
   *
   */
  %rename( "update_system=" ) set_update_system( int bflag );
#endif
  void set_update_system( int bflag )
  { $self->updatesystem = bflag; }

  /*
   * Document-method: allow_virtual_conflicts
   * Allow virtual conflicts
   * call-seq:
   *  solver.allow_virtual_conflicts -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int allow_virtual_conflicts
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_virtual_conflicts()
  { return $self->allowvirtualconflicts; }
#if defined(SWIGRUBY)
  /*
   * Document-method: allow_virtual_conflicts=
   * call-seq:
   *  solver.allow_virtual_conflicts = true
   *
   */
  %rename( "allow_virtual_conflicts=" ) set_allow_virtual_conflicts( int bflag );
#endif
  void set_allow_virtual_conflicts( int bflag )
  { $self->allowvirtualconflicts = bflag; }

  /*
   * Document-method: allow_self_conflicts
   * Allow self conflicts
   * If a package can conflict with itself
   * call-seq:
   *  solver.allow_self_conflicts -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int allow_self_conflicts
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_self_conflicts()
  { return $self->allowselfconflicts; }
#if defined(SWIGRUBY)
  /*
   * Document-method: allow_self_conflicts=
   * call-seq:
   *  solver.allow_self_conflicts = true
   *
   */
  %rename( "allow_self_conflicts=" ) set_allow_self_conflicts( int bflag );
#endif
  void set_allow_self_conflicts( int bflag )
  { $self->allowselfconflicts = bflag; }

  /*
   * Document-method: obsolete_uses_provides
   * Obsolete uses provides
   * Obsolete dependencies usually match on package names only.
   * Setting this flag will make obsoletes also match a provides.
   * call-seq:
   *  solver.obsolete_uses_provides -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int obsolete_uses_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int obsolete_uses_provides()
  { return $self->obsoleteusesprovides; }
#if defined(SWIGRUBY)
  /*
   * Document-method: obsolete_uses_provides=
   * Obsolete uses provides
   * call-seq:
   *  solver.obsolete_uses_provides = true
   *
   */
  %rename( "obsolete_uses_provides=" ) set_obsolete_uses_provides( int bflag );
#endif
  void set_obsolete_uses_provides( int bflag )
  { $self->obsoleteusesprovides= bflag; }

  /*
   * Document-method: implicit_obsolete_uses_provides
   * Implicit obsolete uses provides
   * call-seq:
   *  solver.implicit_obsolete_uses_provides -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int implicit_obsolete_uses_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int implicit_obsolete_uses_provides()
  { return $self->implicitobsoleteusesprovides; }
#if defined(SWIGRUBY)
  /*
   * Document-method: implicit_obsolete_uses_provides=
   * call-seq:
   *  solver.implicit_obsolete_uses_provides = true
   *
   */
  %rename( "implicit_obsolete_uses_provides=" ) set_implicit_obsolete_uses_provides( int bflag );
#endif
  void set_implicit_obsolete_uses_provides( int bflag )
  { $self->implicitobsoleteusesprovides= bflag; }

  /*
   * Document-method: no_update_provide
   * No update provide
   * call-seq:
   *  solver.no_update_provide -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int no_update_provide
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int no_update_provide()
  { return $self->noupdateprovide; }
#if defined(SWIGRUBY)
  /*
   * Document-method: no_update_provide=
   * call-seq:
   *  solver.no_update_provide = true
   *
   */
  %rename( "no_update_provide=" ) set_no_update_provide( int bflag );
#endif
  void set_no_update_provide( int bflag )
  { $self->noupdateprovide = bflag; }

  /*
   * Document-method: do_split_provides
   * Do split provide
   * call-seq:
   *  solver.do_split_provides -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int do_split_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int do_split_provides()
  { return $self->dosplitprovides; }
#if defined(SWIGRUBY)
  /*
   * Document-method: do_split_provides=
   * call-seq:
   *  solver.do_split_provides = true
   *
   */
  %rename( "do_split_provides=" ) set_do_split_provides( int bflag );
#endif
  void set_do_split_provides( int bflag )
  { $self->dosplitprovides = bflag; }

  /*
   * Document-method: dont_install_recommended
   * Dont install recommended
   * call-seq:
   *  solver.dont_install_recommended -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int dont_install_recommended
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int dont_install_recommended()
  { return $self->dontinstallrecommended; }
#if defined(SWIGRUBY)
  /*
   * Document-method: dont_install_recommended=
   * call-seq:
   *  solver.dont_install_recommended = true
   *
   */
  %rename( "dont_install_recommended=" ) set_dont_install_recommended( int bflag );
#endif
  void set_dont_install_recommended( int bflag )
  { $self->dontinstallrecommended= bflag; }

  /*
   * Document-method: ignore_already_recommended
   * Ignore already recommended
   * call-seq:
   *  solver.ignore_already_recommended -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int ignore_already_recommended
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int ignore_already_recommended()
  { return $self->ignorealreadyrecommended; }
#if defined(SWIGRUBY)
  /*
   * Document-method: ignore_already_recommended=
   * call-seq:
   *  solver.ignore_already_recommended = true
   *
   */
  %rename( "ignore_already_recommended=" ) set_ignore_already_recommended( int bflag );
#endif
  void set_ignore_already_recommended( int bflag )
  { $self->ignorealreadyrecommended= bflag; }

  /*
   * Document-method: dont_show_installed_recommended
   * Dont show installed recommended
   * call-seq:
   *  solver.dont_show_installed_recommended -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int dont_show_installed_recommended
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int dont_show_installed_recommended()
  { return $self->dontshowinstalledrecommended; }
#if defined(SWIGRUBY)
  /*
   * Document-method: dont_show_installed_recommended=
   * call-seq:
   *  solver.dont_show_installed_recommended = true
   *
   */
  %rename( "dont_show_installed_recommended=" ) set_dont_show_installed_recommended( int bflag );
#endif
  void set_dont_show_installed_recommended( int bflag )
  { $self->dontshowinstalledrecommended= bflag; }

  /*
   * Document-method: distupgrade
   * Distupgrade
   * call-seq:
   *  solver.distupgrade -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int distupgrade
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int distupgrade()
  { return $self->distupgrade; }
#if defined(SWIGRUBY)
  /*
   * Document-method: distupgrade=
   * call-seq:
   *  solver.distupgrade = true
   *
   */
  %rename( "distupgrade=" ) set_distupgrade( int bflag );
#endif
  void set_distupgrade( int bflag )
  { $self->distupgrade= bflag; }

  /*
   * Document-method: distupgrade_remove_unsupported
   * Distupgrade, remove unsupported
   * call-seq:
   *  solver.distupgrade_remove_unsupported -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int distupgrade_remove_unsupported
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int distupgrade_remove_unsupported()
  { return $self->distupgrade_removeunsupported; }
#if defined(SWIGRUBY)
  /*
   * Document-method: distupgrade_remove_unsupported=
   * call-seq:
   *  solver.distupgrade_remove_unsupported = true
   *
   */
  %rename( "distupgrade_remove_unsupported=" ) set_distupgrade_remove_unsupported( int bflag );
#endif
  void set_distupgrade_remove_unsupported( int bflag )
  { $self->distupgrade_removeunsupported= bflag; }

  /**************************
   * counts and ranges
   */

  /*
   * Document-method: rule_count
   * INTERNAL!
   * call-seq:
   *  solver.rule_count
   *
   */
  int rule_count() { return $self->nrules; }
  /*
   * Document-method: rpmrules_start
   * INTERNAL!
   * call-seq:
   *  solver.rpmrules_start
   *
   */
  int rpmrules_start() { return 0; }
  /*
   * Document-method: rpmrules_end
   * INTERNAL!
   * call-seq:
   *  solver.rpmrules_end
   *
   */
  int rpmrules_end() { return $self->rpmrules_end; }
  /*
   * Document-method: featurerules_start
   * INTERNAL!
   * call-seq:
   *  solver.featurerules_start
   *
   */
  int featurerules_start() { return $self->featurerules; }
  /*
   * Document-method: featurerules_end
   * INTERNAL!
   * call-seq:
   *  solver.featurerules_end
   *
   */
  int featurerules_end() { return $self->featurerules_end; }
  /*
   * Document-method: updaterules_start
   * INTERNAL!
   * call-seq:
   *  solver.updaterules_start
   *
   */
  int updaterules_start() { return $self->updaterules; }
  /*
   * Document-method: updaterules_end
   * INTERNAL!
   * call-seq:
   *  solver.updaterules_end
   *
   */
  int updaterules_end() { return $self->updaterules_end; }
  /*
   * Document-method: jobrules_start
   * INTERNAL!
   * call-seq:
   *  solver.jobrules_start
   *
   */
  int jobrules_start() { return $self->jobrules; }
  /*
   * Document-method: jobrules_end
   * INTERNAL!
   * call-seq:
   *  solver.jobrules_end
   *
   */
  int jobrules_end() { return $self->jobrules_end; }
  /*
   * Document-method: learntrules_start
   * INTERNAL!
   * call-seq:
   *  solver.learntrules_start
   *
   */
  int learntrules_start() { return $self->learntrules; }
  /*
   * Document-method: learntrules_end
   * INTERNAL!
   * call-seq:
   *  solver.learntrules_end
   *
   */
  int learntrules_end() { return $self->nrules; }

  /**************************
   * Covenants
   */

  /*
   * Document-method: covenants_count
   * call-seq:
   *  solver.covenants_count -> int
   *
   */
  int covenants_count()
  { return $self->covenantq.count >> 1; }

#if defined(SWIGRUBY)
  /*
   * Document-method: covenants_empty?
   * call-seq:
   *  solver.covenants_empty? -> bool
   *
   */
  %rename("covenants_empty?") covenants_empty();
  %typemap(out) int covenants_empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int covenants_empty()
  { return $self->covenantq.count == 0; }

#if defined(SWIGRUBY)
  /*
   * Document-method: covenants_clear!
   * Remove all covenants from this solver
   * call-seq:
   *  solver.covenants_clear! -> void
   *
   */
  %rename("covenants_clear!") covenants_clear();
#endif
  void covenants_clear()
  { queue_empty( &($self->covenantq) ); }

  /*
   * Document-method: include
   * Include (specific) solvable
   * Including a solvable means that it _must_ be installed.
   * call-seq:
   *  solver.include(solvable)
   *
   */
  void include( XSolvable *xs )
  { return covenant_include_xsolvable( $self, xs ); }

  /*
   * Document-method: exclude
   * Exclude (specific) solvable
   * Excluding a (specific) solvable means that it _must not_
   * be installed.
   * call-seq:
   *  solver.exclude(solvable)
   *
   */
  void exclude( XSolvable *xs )
  { return covenant_exclude_xsolvable( $self, xs ); }

  /*
   * Document-method: include
   * Include solvable by name
   * Including a solvable by name means that one solvable
   * with the given name must be installed. The solver is free to
   * choose one.
   * call-seq:
   *  solver.include("kernel")
   *
   */
  /*
   */
  void include( const char *name )
  { return covenant_include_name( $self, name ); }

  /*
   * Document-method: exclude
   * Exclude solvable by name
   * Excluding a solvable by name means that any solvable
   * with the given name must not be installed.
   * call-seq:
   *  solver.exclude("mono")
   *
   */
  /*
   */
  void exclude( const char *name )
  { return covenant_exclude_name( $self, name ); }

  /*
   * Document-method: include
   * Include solvable by relation
   * Including a solvable by relation means that any solvable
   * providing the given relation must be installed.
   * call-seq:
   *  solver.include(relation)
   *
   */
  void include( const Relation *rel )
  { return covenant_include_relation( $self, rel ); }

  /*
   * Document-method: exclude
   * Exclude solvable by relation
   * Excluding a solvable by relation means that any solvable
   * providing the given relation must be installed.
   * call-seq:
   *  solver.exclude(relation)
   *
   */
  void exclude( const Relation *rel )
  { return covenant_exclude_relation( $self, rel ); }

  /*
   * Document-method: get_covenant
   * Get Covenant by index
   * The index is just a convenience access method and
   * does NOT imply any preference/ordering of the Covenants.
   *
   * The solver always considers Covenants as a set.
   * call-seq:
   *  solver.get_covenant(1) -> Covenant
   *
   */
  /*
   */
  Covenant *get_covenant( unsigned int i )
  { return covenant_get( $self, i ); }

#if defined(SWIGRUBY)
  /*
   * Document-method: each_covenant
   * Iterate over each Covenant of the Solver.
   * call-seq:
   *  solver.each_covenant { |covenant| ... }
   *
   */
  void each_covenant()
  {
    int i;
    for (i = 0; i < $self->covenantq.count-1; ) {
      int cmd = $self->covenantq.elements[i++];
      Id id = $self->covenantq.elements[i++];
      rb_yield(SWIG_NewPointerObj((void*) covenant_new( $self->pool, cmd, id ), SWIGTYPE_p__Covenant, 0));
    }
  }
#endif

  /**************************
   */


  /*
   * Document-method: solve
   * Solve the given Transaction
   * Returns true if a solution was found, else false.
   * call-seq:
   *  solver.solve(transaction) -> bool
   *
   */
#if defined(SWIGRUBY)
  %typemap(out) int solve
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int solve( Transaction *t )
  {
    if ($self->covenantq.count) {
      /* FIXME: Honor covenants */
    }
    solver_solve( $self, &(t->queue));
    return $self->problems.count == 0;
  }

  /*
   * Document-method: decision_count
   * Return the number of decisions after solving.
   * If its >0, a solution of the Transaction was found.
   * If its ==0, and 'Solver.problems_found' (resp. 'Solver.problems?' for Ruby)
   *   returns true, the Transaction couldn't be solved.
   * If its ==0, and 'Solver.problems_found' (resp. 'Solver.problems?' for Ruby)
   *   returns false, the Transaction is trivially solved.
   * call-seq:
   *  solver.decision_count -> int
   *
   */
  int decision_count()
  { return $self->decisionq.count; }

#if defined(SWIGRUBY)
  /*
   * Document-method: each_decision
   * Iterate over decisions
   * call-seq:
   *  solver.each_decision { |decision| ... }
   *
   */
  void each_decision()
  { return solver_decisions_iterate( $self, solver_decisions_iterate_callback, NULL ); }
#endif

  /*
   * Document-method: explain
   * explain a decision
   *
   * returns 4-element list [<SOLVER_PROBLEM_xxx>, Relation, Solvable, Solvable]
   * call-seq:
   *  solver.explain(transaction, decision) -> [<SOLVER_PROBLEM_xxx>, Relation, Solvable, Solvable]
   *
   */
#if defined(SWIGRUBY)
  VALUE
#endif
#if defined(SWIGPYTHON)
  PyObject *
#endif
#if defined(SWIGPERL)
  SV *
#endif
  explain(Transaction *t, Decision *decision)
  {
    Swig_Type result = Swig_Null;
    Id rule = decision->rule - $self->rules;
    if (rule > 0) {
      Id depp = 0, sourcep = 0, targetp = 0;
      SolverProbleminfo pi = solver_problemruleinfo($self, &(t->queue), rule, &depp, &sourcep, &targetp);
      result = Swig_Array();
/*      fprintf(stderr, "Rule %d: [pi %d, rel %d, source %d, target %d]\n", rule, pi, depp, sourcep, targetp); */
      Swig_Append(result, Swig_Int(pi));
      Swig_Append(result, SWIG_NewPointerObj((void*)relation_new($self->pool, depp), SWIGTYPE_p__Relation, 0));
      Swig_Append(result, SWIG_NewPointerObj((void*)xsolvable_new($self->pool, sourcep), SWIGTYPE_p__Solvable, 0));
      Swig_Append(result, SWIG_NewPointerObj((void*)xsolvable_new($self->pool, targetp), SWIGTYPE_p__Solvable, 0));
    }
    return result;
  }

#if defined(SWIGRUBY)
  /*
   * Document-method: problems?
   * Returns true if any problems occured during solve, returns false
   * on successful solve.
   * There is no 'number of problems' available, but it can be computed
   * by iterating over the problems.
   * call-seq:
   *  solver.problems? -> bool
   *
   */
  %rename("problems?") problems_found();
  %typemap(out) int problems_found
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif

  int problems_found()
  { return $self->problems.count != 0; }

#if defined(SWIGRUBY)
  /*
   * Document-method: each_problem
   * call-seq:
   *  solver.each_problem(transaction) { |problem| ... }
   *
   */
  void each_problem( Transaction *t )
  { return solver_problems_iterate( $self, t, solver_problems_iterate_callback, NULL ); }

  /*
   * Document-method: each_to_install
   * iterate over all to-be-*newly*-installed solvables
   *   those brought in for update reasons are normally *not* reported.
   *
   * if true is passed, iterate over *all* to-be-installed solvables
   * call-seq:
   *  solver.each_to_install { |solvable| ... }
   *  solver.each_to_install(true) { |solvable| ... }
   *
   */
  void each_to_install(int bflag = 0)
  { return solver_installs_iterate( $self, bflag, generic_xsolvables_iterate_callback, NULL ); }

  /*
   * Document-method: each_to_update
   * iterate over all to-be-updated solvables
   * call-seq:
   *  solver.each_to_update { |solvable| ... }
   *
   */
  void each_to_update()
  { return solver_updates_iterate( $self, update_xsolvables_iterate_callback, NULL ); }

  /*
   * Document-method: each_to_remove
   * iterate over all to-be-removed-without-replacement solvables
   *   those replaced by an updated are normally *not* reported.
   *
   * if true (resp '1') is passed, iterate over *all* to-be-removed solvables
   * call-seq:
   *  solver.each_to_remove { |solvable| ... }
   *  solver.each_to_remove(true) { |solvable| ... }
   *
   */
  void each_to_remove(int bflag = 0)
  { return solver_removals_iterate( $self, bflag, generic_xsolvables_iterate_callback, NULL ); }

  /*
   * Document-method: each_suggested
   * Iterate of all suggested (weak install) solvables.
   * call-seq:
   *  solver.each_suggested { |solvable| ... }
   *
   */
  void each_suggested()
  { return solver_suggestions_iterate( $self, generic_xsolvables_iterate_callback, NULL ); }
#endif /* SWIGRUBY */

#if defined(SWIGPERL)
    SV* getInstallList()
    {
        int b = 0;
        AV *myav = newAV();
        SV *mysv = 0;
        SV *res  = 0;
        int len = self->decisionq.count;
        for (b = 0; b < len; b++) {
            Solvable *s;
            char *myel;
            Id p = self->decisionq.elements[b];
            if (p < 0) {
                continue; // ignore conflict
            }
            if (p == SYSTEMSOLVABLE) {
                continue; // ignore system solvable
            }
            s = self->pool->solvables + p;
            //printf ("SOLVER NAME: %d %s\n",p,id2str(self->pool, s->name));
            myel = (char*)id2str(self->pool, s->name);
            mysv = sv_newmortal();
            mysv = perl_get_sv (myel,TRUE);
            sv_setpv(mysv, myel);
            av_push (myav,mysv);
        }
        res = newRV((SV*)myav);
        sv_2mortal (res);
        return res;
    }
#endif

};
