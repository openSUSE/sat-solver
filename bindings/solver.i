/*
 * Solver
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

  Solver( Pool *pool )
  { return solver_create( pool); }
  ~Solver()
  { solver_free( $self ); }

  /**************************
   * Solver policies
   */

  /* yeah, thats awkward. But %including solver.h and adding lots
     of %ignores is even worse ... */

  /*
   * Check and fix inconsistencies of the installed system
   *
   * Normally, broken dependencies in the RPM database are silently
   * ignored in order to prevent clutter in the solution.
   * Setting fix_system to 'true' will repair broken system
   * dependencies.
   */
#if defined(SWIGRUBY)
  %typemap(out) int fix_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int fix_system()
  { return $self->fixsystem; }
#if defined(SWIGRUBY)
  %rename( "fix_system=" ) set_fix_system( int bflag );
#endif
  void set_fix_system( int bflag )
  { $self->fixsystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int update_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int update_system()
  { return $self->updatesystem; }
#if defined(SWIGRUBY)
  %rename( "update_system=" ) set_update_system( int bflag );
#endif
  void set_update_system( int bflag )
  { $self->updatesystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_downgrade
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_downgrade()
  { return $self->allowdowngrade; }
#if defined(SWIGRUBY)
  %rename( "allow_downgrade=" ) set_allow_downgrade( int bflag );
#endif
  void set_allow_downgrade( int bflag )
  { $self->allowdowngrade = bflag; }

  /*
   * On package removal, also remove dependant packages.
   *
   * If removal of a package breaks dependencies, the transaction is
   * usually considered not solvable. The dependencies of installed
   * packages take precedence over transaction actions.
   *
   * Setting allow_uninstall to 'true' will revert the precedence
   * and remove all dependant packages.
   */
#if defined(SWIGRUBY)
  %typemap(out) int allow_uninstall
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_uninstall()
  { return $self->allowuninstall; }
#if defined(SWIGRUBY)
  %rename( "allow_uninstall=" ) set_allow_uninstall( int bflag );
#endif
  void set_allow_uninstall( int bflag )
  { $self->allowuninstall = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int no_update_provide
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int no_update_provide()
  { return $self->noupdateprovide; }
#if defined(SWIGRUBY)
  %rename( "no_update_provide=" ) set_no_update_provide( int bflag );
#endif
  void set_no_update_provide( int bflag )
  { $self->noupdateprovide = bflag; }

  int rule_count() { return $self->nrules; }
  int rpmrules_start() { return 0; }
  int rpmrules_end() { return $self->rpmrules_end; }
  int featurerules_start() { return $self->featurerules; }
  int featurerules_end() { return $self->featurerules_end; }
  int updaterules_start() { return $self->updaterules; }
  int updaterules_end() { return $self->updaterules_end; }
  int jobrules_start() { return $self->jobrules; }
  int jobrules_end() { return $self->jobrules_end; }
  int learntrules_start() { return $self->learntrules; }
  int learntrules_end() { return $self->nrules; }

  /**************************
   * Covenants
   */

  int covenants_count()
  { return $self->covenantq.count >> 1; }

#if defined(SWIGRUBY)
  %rename("covenants_empty?") covenants_empty();
  %typemap(out) int covenants_empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int covenants_empty()
  { return $self->covenantq.count == 0; }

#if defined(SWIGRUBY)
  %rename("covenants_clear!") covenants_clear();
#endif
  /*
   * Remove all covenants from this solver
   */
  void covenants_clear()
  { queue_empty( &($self->covenantq) ); }

  /*
   * Include (specific) solvable
   * Including a solvable means that it must be installed.
   */
  void include( XSolvable *xs )
  { return covenant_include_xsolvable( $self, xs ); }

  /*
   * Exclude (specific) solvable
   * Excluding a (specific) solvable means that it must not
   * be installed.
   */
  void exclude( XSolvable *xs )
  { return covenant_exclude_xsolvable( $self, xs ); }

  /*
   * Include solvable by name
   * Including a solvable by name means that any solvable
   * with the given name must be installed.
   */
  void include( const char *name )
  { return covenant_include_name( $self, name ); }

  /*
   * Exclude solvable by name
   * Excluding a solvable by name means that any solvable
   * with the given name must not be installed.
   */
  void exclude( const char *name )
  { return covenant_exclude_name( $self, name ); }

  /*
   * Include solvable by relation
   * Including a solvable by relation means that any solvable
   * providing the given relation must be installed.
   */
  void include( const Relation *rel )
  { return covenant_include_relation( $self, rel ); }

  /*
   * Exclude solvable by relation
   * Excluding a solvable by relation means that any solvable
   * providing the given relation must be installed.
   */
  void exclude( const Relation *rel )
  { return covenant_exclude_relation( $self, rel ); }

  /*
   * Get Covenant by index
   * The index is just a convenience access method and
   * does NOT imply any preference/ordering of the Covenants.
   *
   * The solver always considers Covenants as a set.
   */
  Covenant *get_covenant( unsigned int i )
  { return covenant_get( $self, i ); }

#if defined(SWIGRUBY)
  /*
   * Iterate over each Covenant of the Solver.
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
   * Solve the given Transaction
   * Returns true if a solution was found, else false.
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
   * Return the number of decisions after solving.
   * If its >0, a solution of the Transaction was found.
   * If its ==0, and 'Solver.problems_found' (resp. 'Solver.problems?' for Ruby)
   *   returns true, the Transaction couldn't be solved.
   * If its ==0, and 'Solver.problems_found' (resp. 'Solver.problems?' for Ruby)
   *   returns false, the Transaction is trivially solved.
   */
  int decision_count()
  { return $self->decisionq.count; }

#if defined(SWIGRUBY)
  void each_decision()
  { return solver_decisions_iterate( $self, solver_decisions_iterate_callback, NULL ); }
#endif

  /*
   * explain a decision
   *
   * returns 4-element list [<SOLVER_PROBLEM_xxx>, Relation, Solvable, Solvable]
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
    Id depp = 0, sourcep = 0, targetp = 0;
    SolverProbleminfo pi;
    Swig_Type result = Swig_Array();
    Id rule = decision->rule - $self->rules;
    if (rule > 0) {
      pi = solver_problemruleinfo($self, &(t->queue), rule, &depp, &sourcep, &targetp);
      Swig_Append(result, Swig_Int(pi));
    }
    else {
      Swig_Append(result, Swig_Int(-1));
    }
    Swig_Append(result, SWIG_NewPointerObj((void*)relation_new($self->pool, depp), SWIGTYPE_p__Relation, 0));
    Swig_Append(result, SWIG_NewPointerObj((void*)xsolvable_new($self->pool, sourcep), SWIGTYPE_p__Solvable, 0));
    Swig_Append(result, SWIG_NewPointerObj((void*)xsolvable_new($self->pool, targetp), SWIGTYPE_p__Solvable, 0));
    return result;
  }

#if defined(SWIGRUBY)
  %rename("problems?") problems_found();
  %typemap(out) int problems_found
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif

  /*
   * Return if problems where found during solving.
   *
   * There is no 'number of problems' available, but it can be computed
   * by iterating over the problems.
   */
  int problems_found()
  { return $self->problems.count != 0; }

#if defined(SWIGRUBY)
  void each_problem( Transaction *t )
  { return solver_problems_iterate( $self, t, solver_problems_iterate_callback, NULL ); }

  /*
   * iterate over all to-be-*newly*-installed solvables
   *   those brought in for update reasons are normally *not* reported.
   *
   * if true (resp '1') is passed, iterate over *all* to-be-installed
   * solvables
   */
  void each_to_install(int bflag = 0)
  { return solver_installs_iterate( $self, bflag, generic_xsolvables_iterate_callback, NULL ); }

  void each_to_update()
  { return solver_updates_iterate( $self, update_xsolvables_iterate_callback, NULL ); }

  /*
   * iterate over all to-be-removed-without-replacement solvables
   *   those replaced by an updated are normally *not* reported.
   *
   * if true (resp '1') is passed, iterate over *all* to-be-removed solvables
   */
  void each_to_remove(int bflag = 0)
  { return solver_removals_iterate( $self, bflag, generic_xsolvables_iterate_callback, NULL ); }

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
