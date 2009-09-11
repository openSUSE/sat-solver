/*
 * Document-class: Step
 * A step is a single 'work item' of a Transaction
 *
 * === Constructor
 * There is no constructor defined for Step. Steps are created by accessing
 * a Transaction
 *
 */

%nodefault _Step;
%rename(Step) _Step;
typedef struct _Step {} Step;


%extend Step {
  %constant int STEP_IGNORE = SOLVER_TRANSACTION_IGNORE;

  %constant int STEP_ERASE = SOLVER_TRANSACTION_ERASE;
  %constant int STEP_REINSTALLED = SOLVER_TRANSACTION_REINSTALLED;
  %constant int STEP_DOWNGRADED = SOLVER_TRANSACTION_DOWNGRADED;
  %constant int STEP_CHANGED  = SOLVER_TRANSACTION_CHANGED;
  %constant int STEP_UPGRADED = SOLVER_TRANSACTION_UPGRADED;
  %constant int STEP_OBSOLETED = SOLVER_TRANSACTION_OBSOLETED;

  %constant int STEP_INSTALL = SOLVER_TRANSACTION_INSTALL;
  %constant int STEP_REINSTALL = SOLVER_TRANSACTION_REINSTALL;
  %constant int STEP_DOWNGRADE = SOLVER_TRANSACTION_DOWNGRADE;
  %constant int STEP_CHANGE = SOLVER_TRANSACTION_CHANGE;
  %constant int STEP_UPGRADE = SOLVER_TRANSACTION_UPGRADE;
  %constant int STEP_OBSOLETES = SOLVER_TRANSACTION_OBSOLETES;

  %constant int STEP_MULTIINSTALL = SOLVER_TRANSACTION_MULTIINSTALL;
  %constant int STEP_MULTIREINSTALL = SOLVER_TRANSACTION_MULTIREINSTALL;
  
  ~Step()
  { step_free( $self ); }

  /*
   * Solvable affected by the Step
   *
   */
  XSolvable *solvable()
  { return step_xsolvable( $self ); }

  /*
   * Type of Step
   *
   * mode: Bitmask of TRANSACTION_MODE_*
   *       Defaults to TRANSACTION_MODE_RPM_ONLY
   *
   * Returns one of STEP_*
   *
   */
  int type(int mode = SOLVER_TRANSACTION_RPM_ONLY)
  { return step_type( $self, mode ); }

  /*
   * String representation of type
   *
   */
  const char *type_s(int mode = SOLVER_TRANSACTION_RPM_ONLY)
  { return step_type_s( $self, mode ); }

  /*
   * Step equality
   *
   */

#if defined(SWIGPERL)
  /*
   * :nodoc:
   */
  int __eq__( const Step *step )
#endif
#if defined(SWIGRUBY)
  %typemap(out) int equal
    "$result = $1 ? Qtrue : Qfalse;";
  %rename("==") equal;
  /*
   * Equality operator
   *
   */
  int equal( const Step *step )
#endif

#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   * Python treats 'eq' and 'ne' distinct.
   */
  int __ne__( const Step *step )
  { return !steps_equal($self, step); }
  int __eq__( const Step *step )
#endif
  { return steps_equal($self, step); }

}
