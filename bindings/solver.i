/*
 * Document-class: Solver
 * 
 * The solver class is at the heart of the satsolver, providing
 * ultra-fast dependency resolution.
 * 
 * The solver is always attached to a pool, containing all solvables the
 * solver can operate on. The pool also has designated repository for
 * 'installed' solvables.
 * 
 * Solving is done by creating a Request and feeding it to the
 * solver as input. On success (solver.solve() returning 'true'), one can
 * retrieve the Decisions made by the solver (i.e. install this, remove
 * that, update those). On failure, the solver creates a list of
 * Problems, explaining what went wrong and how to resolve the problem.
 * 
 * Solving can be controlled globally by setting solver flags.
 * Additionally, specific constraints can be set by using Covenants.
 * 
 * === Example code
 *    pool = Satsolver::Pool.new
 *    pool.arch = "i686"
 *    system = pool.add_rpmdb( "/" )
 *    pool.installed = system
 *    repo = pool.add_solv( "myrepo.solv" )
 *    
 *    request = pool.create_request
 *    request.install( "packageA" )
 *    request.install( "packageB" )
 *    request.remove( "old_package" )
 *
 *    solver = pool.create_solver
 *    solver.allow_uninstall = true
 *    pool.prepare
 *    result = solver.solve( request )
 *    if !result
 *      raise "Couldn't solve request"
 *    end
 *
 *    solver.each_to_install do |s|
 *      puts "Install #{s}"
 *    end
 *    solver.each_to_remove do |s|
 *      puts "Remove #{s}"
 *    end
 *
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
   * Create a solver operating on a pool
   *
   * Equivalent: Pool.create_solver
   *
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
  %rename( "fix_system=" ) set_fix_system( int bflag );
#endif
  /*
   * Set the fix_system flag
   * call-seq:
   *   solver.fix_system = true
   *
   */
  void set_fix_system( int bflag )
  { $self->fixsystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_downgrade
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow downgrade
   * The normal solver operation tries to install (to update to) the 'best' package,
   * usually the one with the highest version.
   * If allow_downgrade is set, packages may be downgraded in order to
   * fulfill a request or a dependency
   * call-seq:
   *  solver.allow_downgrade -> bool
   *
   */
  int allow_downgrade()
  { return $self->allowdowngrade; }

#if defined(SWIGRUBY)
  %rename( "allow_downgrade=" ) set_allow_downgrade( int bflag );
#endif
  /*
   * Allow or disallow package downgrades
   *
   * call-seq:
   *  solver.allow_downgrade = true
   *
   */
  void set_allow_downgrade( int bflag )
  { $self->allowdowngrade = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_arch_change
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow arch change
   *
   * After installation, the architecture of a package is fixed an the
   * solver will not change it during upgrades.
   * This prevents updates to a higher version but inferior
   * architecture.
   * If this flag is set, packages can change their architecture. The
   * solver will usually try to select the 'best' architecture.
   *
   * call-seq:
   *  solver.allow_arch_change -> bool
   *
   */
  int allow_arch_change()
  { return $self->allowarchchange; }

#if defined(SWIGRUBY)
  %rename( "allow_arch_change=" ) set_allow_arch_change( int bflag );
#endif
  /*
   * Allow or disallow architecture changes
   * call-seq:
   *  solver.allow_arch_change = true
   *
   */
  void set_allow_arch_change( int bflag )
  { $self->allowarchchange = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_vendor_change
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow vendor change
   *
   * The package vendor is usually an indicator of the package origin.
   * Updates should only come from the same origin.
   * If this flag is true, the solver will allow vendor changes during
   * package upgrades.
   *
   * call-seq:
   *  solver.allow_vendor_change -> bool
   *
   */
  int allow_vendor_change()
  { return $self->allowvendorchange; }

#if defined(SWIGRUBY)
  %rename( "allow_vendor_change=" ) set_allow_vendor_change( int bflag );
#endif
  /*
   * Allow vendor change
   *
   * call-seq:
   *  solver.allow_vendor_change = true
   *
   */
  void set_allow_vendor_change( int bflag )
  { $self->allowvendorchange = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_uninstall
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * On package removal, also remove dependant packages.
   *
   * If removal of a package breaks dependencies, the request is
   * usually considered not solvable. The dependencies of installed
   * packages take precedence over request actions.
   *
   *
   * call-seq:
   *  solver.allow_uninstall -> bool
   *
   */
  int allow_uninstall()
  { return $self->allowuninstall; }

#if defined(SWIGRUBY)
  %rename( "allow_uninstall=" ) set_allow_uninstall( int bflag );
#endif
  /*
   * On package removal, also remove dependant packages.
   *
   * Setting allow_uninstall to 'true' will revert the precedence
   * and remove all dependant packages.
   *
   * call-seq:
   *  solver.allow_uninstall = true
   *
   */
  void set_allow_uninstall( int bflag )
  { $self->allowuninstall = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int update_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Update system
   *
   * call-seq:
   *  solver.update_system -> bool
   *
   */
  int update_system()
  { return $self->updatesystem; }

#if defined(SWIGRUBY)
  %rename( "update_system=" ) set_update_system( int bflag );
#endif
  /*
   * call-seq:
   *  solver.update_system = true
   *
   */
  void set_update_system( int bflag )
  { $self->updatesystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_virtual_conflicts
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow virtual conflicts
   *
   * call-seq:
   *  solver.allow_virtual_conflicts -> bool
   *
   */
  int allow_virtual_conflicts()
  { return $self->allowvirtualconflicts; }

#if defined(SWIGRUBY)
  %rename( "allow_virtual_conflicts=" ) set_allow_virtual_conflicts( int bflag );
#endif
  /*
   * call-seq:
   *  solver.allow_virtual_conflicts = true
   *
   */
  void set_allow_virtual_conflicts( int bflag )
  { $self->allowvirtualconflicts = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_self_conflicts
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow self conflicts
   *
   * If a package can conflict with itself
   *
   * call-seq:
   *  solver.allow_self_conflicts -> bool
   *
   */
  int allow_self_conflicts()
  { return $self->allowselfconflicts; }

#if defined(SWIGRUBY)
  %rename( "allow_self_conflicts=" ) set_allow_self_conflicts( int bflag );
#endif
  /*
   * call-seq:
   *  solver.allow_self_conflicts = true
   *
   */
  void set_allow_self_conflicts( int bflag )
  { $self->allowselfconflicts = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int obsolete_uses_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Obsolete uses provides
   *
   * Obsolete dependencies usually match on package names only.
   * Setting this flag will make obsoletes also match a provides.
   *
   * call-seq:
   *  solver.obsolete_uses_provides -> bool
   *
   */
  int obsolete_uses_provides()
  { return $self->obsoleteusesprovides; }

#if defined(SWIGRUBY)
  %rename( "obsolete_uses_provides=" ) set_obsolete_uses_provides( int bflag );
#endif
  /*
   * Obsolete uses provides
   *
   * call-seq:
   *  solver.obsolete_uses_provides = true
   *
   */
  void set_obsolete_uses_provides( int bflag )
  { $self->obsoleteusesprovides= bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int implicit_obsolete_uses_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Implicit obsolete uses provides
   *
   * call-seq:
   *  solver.implicit_obsolete_uses_provides -> bool
   *
   */
  int implicit_obsolete_uses_provides()
  { return $self->implicitobsoleteusesprovides; }

#if defined(SWIGRUBY)
  %rename( "implicit_obsolete_uses_provides=" ) set_implicit_obsolete_uses_provides( int bflag );
#endif
  /*
   * call-seq:
   *  solver.implicit_obsolete_uses_provides = true
   *
   */
  void set_implicit_obsolete_uses_provides( int bflag )
  { $self->implicitobsoleteusesprovides= bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int no_update_provide
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * No update provide
   *
   * call-seq:
   *  solver.no_update_provide -> bool
   *
   */
  int no_update_provide()
  { return $self->noupdateprovide; }

#if defined(SWIGRUBY)
  %rename( "no_update_provide=" ) set_no_update_provide( int bflag );
#endif
  /*
   * call-seq:
   *  solver.no_update_provide = true
   *
   */
  void set_no_update_provide( int bflag )
  { $self->noupdateprovide = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int do_split_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Do split provide
   *
   * call-seq:
   *  solver.do_split_provides -> bool
   *
   */
  int do_split_provides()
  { return $self->dosplitprovides; }

#if defined(SWIGRUBY)
  %rename( "do_split_provides=" ) set_do_split_provides( int bflag );
#endif
  /*
   * call-seq:
   *  solver.do_split_provides = true
   *
   */
  void set_do_split_provides( int bflag )
  { $self->dosplitprovides = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int dont_install_recommended
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Dont install recommended
   *
   * call-seq:
   *  solver.dont_install_recommended -> bool
   *
   */
  int dont_install_recommended()
  { return $self->dontinstallrecommended; }
#if defined(SWIGRUBY)
  %rename( "dont_install_recommended=" ) set_dont_install_recommended( int bflag );
#endif
  /*
   * call-seq:
   *  solver.dont_install_recommended = true
   *
   */
  void set_dont_install_recommended( int bflag )
  { $self->dontinstallrecommended= bflag; }

#if defined(SWIGRUBY)
  /*
   * Ignore already recommended
   *
   * call-seq:
   *  solver.ignore_already_recommended -> bool
   *
   */
  %typemap(out) int ignore_already_recommended
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int ignore_already_recommended()
  { return $self->ignorealreadyrecommended; }

#if defined(SWIGRUBY)
  %rename( "ignore_already_recommended=" ) set_ignore_already_recommended( int bflag );
#endif
  /*
   * call-seq:
   *  solver.ignore_already_recommended = true
   *
   */
  void set_ignore_already_recommended( int bflag )
  { $self->ignorealreadyrecommended= bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int dont_show_installed_recommended
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Dont show installed recommended
   *
   * call-seq:
   *  solver.dont_show_installed_recommended -> bool
   *
   */
  int dont_show_installed_recommended()
  { return $self->dontshowinstalledrecommended; }

#if defined(SWIGRUBY)
  %rename( "dont_show_installed_recommended=" ) set_dont_show_installed_recommended( int bflag );
#endif
  /*
   * call-seq:
   *  solver.dont_show_installed_recommended = true
   *
   */
  void set_dont_show_installed_recommended( int bflag )
  { $self->dontshowinstalledrecommended= bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int distupgrade
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Distupgrade
   *
   * call-seq:
   *  solver.distupgrade -> bool
   *
   */
  int distupgrade()
  { return $self->distupgrade; }

#if defined(SWIGRUBY)
  %rename( "distupgrade=" ) set_distupgrade( int bflag );
#endif
  /*
   * call-seq:
   *  solver.distupgrade = true
   *
   */
  void set_distupgrade( int bflag )
  { $self->distupgrade= bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int distupgrade_remove_unsupported
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Distupgrade, remove unsupported
   *
   * call-seq:
   *  solver.distupgrade_remove_unsupported -> bool
   *
   */
  int distupgrade_remove_unsupported()
  { return $self->distupgrade_removeunsupported; }

#if defined(SWIGRUBY)
  %rename( "distupgrade_remove_unsupported=" ) set_distupgrade_remove_unsupported( int bflag );
#endif
  /*
   * call-seq:
   *  solver.distupgrade_remove_unsupported = true
   *
   */
  void set_distupgrade_remove_unsupported( int bflag )
  { $self->distupgrade_removeunsupported= bflag; }

  /**************************
   * counts and ranges
   */

  /*
   * INTERNAL!
   *
   */
  int rule_count() { return $self->nrules; }

  /*
   * INTERNAL!
   *
   */
  int rpmrules_start() { return 0; }

  /*
   * INTERNAL!
   *
   */
  int rpmrules_end() { return $self->rpmrules_end; }

  /*
   * INTERNAL!
   *
   */
  int featurerules_start() { return $self->featurerules; }

  /*
   * INTERNAL!
   *
   */
  int featurerules_end() { return $self->featurerules_end; }

  /*
   * INTERNAL!
   *
   */
  int updaterules_start() { return $self->updaterules; }

  /*
   * INTERNAL!
   *
   */
  int updaterules_end() { return $self->updaterules_end; }

  /*
   * INTERNAL!
   *
   */
  int jobrules_start() { return $self->jobrules; }

  /*
   * INTERNAL!
   *
   */
  int jobrules_end() { return $self->jobrules_end; }

  /*
   * INTERNAL!
   *
   */
  int learntrules_start() { return $self->learntrules; }

  /*
   * INTERNAL!
   *
   */
  int learntrules_end() { return $self->nrules; }

  /**************************
   * Covenants
   */

  /*
   * Number of Covenants
   *
   * call-seq:
   *  solver.covenants_count -> int
   *
   */
  int covenants_count()
  { return $self->covenantq.count >> 1; }

#if defined(SWIGRUBY)
  %rename("covenants_empty?") covenants_empty();
  %typemap(out) int covenants_empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Shortcut for +covenants_count == 0+
   *
   * call-seq:
   *  solver.covenants_empty? -> bool
   *
   */
  int covenants_empty()
  { return $self->covenantq.count == 0; }

#if defined(SWIGRUBY)
  %rename("covenants_clear!") covenants_clear();
#endif
  /*
   * Remove all covenants from this solver
   *
   * call-seq:
   *  solver.covenants_clear! -> void
   *
   */
  void covenants_clear()
  { queue_empty( &($self->covenantq) ); }

  /*
   * Include (specific) solvable
   *
   * Including a Solvable explicitly means that this Solvable _must_ be installed.
   *
   * Including a Solvable by name means that one Solvable
   * with the given name must be installed. The solver is free to
   * choose one.
   *
   * Including a Solvable by relation means that any Solvable
   * providing the given relation must be installed.
   * 
   * call-seq:
   *  solver.include(solvable)
   *  solver.include("kernel")
   *  solver.include(relation)
   *
   */
  void include( XSolvable *xs )
  { return covenant_include_xsolvable( $self, xs ); }
  void include( const char *name )
  { return covenant_include_name( $self, name ); }
  void include( const Relation *rel )
  { return covenant_include_relation( $self, rel ); }

  /*
   * Exclude (specific) solvable
   *
   * Excluding a (specific) Solvable means that this Solvable _must_ _not_
   * be installed.
   *
   * Excluding a Solvable by name means that any Solvable
   * with the given name must not be installed.
   *
   * Excluding a Solvable by relation means that any Solvable
   * providing the given relation must not be installed.
   *
   * call-seq:
   *  solver.exclude(solvable)
   *  solver.exclude("mono-core")
   *  solver.exclude(relation)
   *
   */
  void exclude( XSolvable *xs )
  { return covenant_exclude_xsolvable( $self, xs ); }
  void exclude( const char *name )
  { return covenant_exclude_name( $self, name ); }
  void exclude( const Relation *rel )
  { return covenant_exclude_relation( $self, rel ); }

  /*
   * Get Covenant by index
   *
   * The index is just a convenience access method and
   * does NOT imply any preference/ordering of the Covenants.
   *
   * The solver always considers Covenants as a set.
   *
   * call-seq:
   *  solver.get_covenant(1) -> Covenant
   *
   */
  Covenant *get_covenant( unsigned int i )
  { return covenant_get( $self, i ); }

#if defined(SWIGRUBY)
  /*
   * Iterate over each Covenant of the Solver.
   *
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


#if defined(SWIGRUBY)
  %typemap(out) int solve
    "$result = $1 ? Qtrue : Qfalse;";
#endif
#if defined(SWIGPYTHON)
%typemap(out) int solve {
	$result = PyBool_FromLong((long) ($1 ? 1 : 0));
}
#endif
  /*
   * Solve the given Request
   *
   * Returns +true+ if a solution was found, else +false+.
   *
   * call-seq:
   *  solver.solve(request) -> bool
   *
   */
  int solve( Request *t )
  {
    if ($self->covenantq.count) {
      /* FIXME: Honor covenants */
    }
    solver_solve( $self, &(t->queue));
    return $self->problems.count == 0;
  }

  /*
   * Return the number of decisions after solving.
   *
   * If its >0, a solution of the Request was found.
   *
   * If its ==0, and 'Solver.problems?' returns +true+, the Request couldn't be solved.
   *
   * If its ==0, and 'Solver.problems?' returns +false+, the Request is trivially solved.
   *
   * call-seq:
   *  solver.decision_count -> int
   *
   */
  int decision_count()
  { return $self->decisionq.count; }

#if defined(SWIGRUBY)
  /*
   * Iterate over decisions
   *
   * call-seq:
   *  solver.each_decision { |decision| ... }
   *
   */
  void each_decision()
  { return solver_decisions_iterate( $self, solver_decisions_iterate_callback, NULL ); }
#endif

  /*
   * Return the size change of the installed system
   *
   * This is how much disk space gets allocated/freed after the
   * solver decisions are applied to the system.
   *
   */
  long sizechange()
  {
    return solver_calc_installsizechange($self);
  }

#if defined(SWIGRUBY)
  VALUE
#endif
#if defined(SWIGPYTHON)
  PyObject *
#endif
#if defined(SWIGPERL)
  SV *
#endif
  /*
   * Explain a decision
   *
   * returns 4-element Array [<SOLVER_PROBLEM_xxx>, Relation, Solvable, Solvable]
   *
   * *OBSOLETE*: Use Decision.explain instead
   *
   * call-seq:
   *  solver.explain(request, decision) -> [<SOLVER_PROBLEM_xxx>, Relation, Solvable, Solvable]
   *
   */
  __type explain(Request *unused, Decision *decision)
  {
    Swig_Type result = Swig_Null;
    Id rule = decision->rule - $self->rules;
    if (rule > 0) {
      Id depp = 0, sourcep = 0, targetp = 0;
      SolverProbleminfo pi = solver_ruleinfo($self, rule, &sourcep, &targetp, &depp);
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
  %rename("problems?") problems_found();
  %typemap(out) int problems_found
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  /*
   * Check if the last solver run had problems.
   *
   * Returns true if any problems occured during solve, returns false
   * on successful solve.
   *
   * There is no 'number of problems' available, but it can be computed
   * by iterating over the problems.
   *
   * call-seq:
   *  solver.problems? -> bool
   *
   */
  int problems_found()
  { return $self->problems.count != 0; }

#if defined(SWIGRUBY)
  /*
   * Iterate over problems.
   *
   * call-seq:
   *  solver.each_problem(request) { |problem| ... }
   *
   */
  void each_problem( Request *t )
  { return solver_problems_iterate( $self, t, solver_problems_iterate_callback, NULL ); }

  /*
   * Iterate over all to-be-*newly*-installed solvables
   * those brought in for update reasons are normally *not* reported.
   *
   * if true is passed, iterate over *all* to-be-installed solvables
   *
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
   * Iterate over all to-be-removed-without-replacement solvables
   * those replaced by an updated are normally *not* reported.
   *
   * if +true+ is passed, iterate over *all* to-be-removed solvables
   *
   * call-seq:
   *  solver.each_to_remove { |solvable| ... }
   *  solver.each_to_remove(true) { |solvable| ... }
   *
   */
  void each_to_remove(int bflag = 0)
  { return solver_removals_iterate( $self, bflag, generic_xsolvables_iterate_callback, NULL ); }

  /*
   * Iterate of all suggested (weak install) solvables.
   *
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
#if defined(SWIGPYTHON)
    XSolvable **installs() {
    	Pool *pool = $self->pool;
	Repo *installed = $self->installed;
	int count = $self->decisionq.count;
	Solvable *s;
	Id p, *obsoletesmap = solver_create_decisions_obsoletesmap($self);
	int i, j = 0;
	XSolvable **xs = (XSolvable **) malloc((count + 1) * sizeof(XSolvable **));

	for (i = 0; i < $self->decisionq.count; i++) {
	    p = $self->decisionq.elements[i];
	    if (p < 0)
	       continue;
	    if (p == SYSTEMSOLVABLE)
	       continue;
	    s = pool->solvables + p;
	    if (installed && s->repo == installed)
	       continue;
	    if (obsoletesmap[p])
	       continue;
	    xs[j] = xsolvable_new(pool, p);
            ++j;
       }
       xs[j] = NULL;
       sat_free(obsoletesmap);
       return xs;
    }

    XSolvable **updates() {
    	Pool *pool = $self->pool;
	Repo *installed = $self->installed;
	int count = $self->decisionq.count;
	Solvable *s;
	Id p, *obsoletesmap = solver_create_decisions_obsoletesmap($self);
	int i, j = 0;
	XSolvable **xs = (XSolvable **) malloc((count + 1) * sizeof(XSolvable **));

	for (i = 0; i < $self->decisionq.count; i++) {
	    p = $self->decisionq.elements[i];
	    if (p < 0)
	       continue;
	    if (p == SYSTEMSOLVABLE)
	       continue;
	    s = pool->solvables + p;
	    if (installed && s->repo == installed)
	       continue;
	    if (!obsoletesmap[p])
	       continue;
	    xs[j] = xsolvable_new(pool, p);
            ++j;
       }
       xs[j] = NULL;
       sat_free(obsoletesmap);
       return xs;
    }

    XSolvable **removes() {
    	Pool *pool = $self->pool;
	Repo *installed = $self->installed;
	int count = installed ? installed->nsolvables : 0;
	Solvable *s;
	Id p, *obsoletesmap = solver_create_decisions_obsoletesmap($self);
	int j = 0;
	XSolvable **xs = (XSolvable **) malloc((count + 1) * sizeof(XSolvable **));

	if (installed) {
	   FOR_REPO_SOLVABLES(installed, p, s) {
	      if ($self->decisionmap[p] > 0)
	      	 continue;
	      if (obsoletesmap[p])
	      	 continue;
	      xs[j] = xsolvable_new(pool, p);
              ++j;
       	   }
       }
       xs[j] = NULL;
       sat_free(obsoletesmap);
       return xs;
    }
#endif
};
