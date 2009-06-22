/*
 * Document-class: Problem
 *
 * If solving a Request is unsucccessful (+Solver+.+solve+ returning +false+), the Solver provides
 * information on possible reason and how to fix them.
 *
 * The Problem class represents such a reason and provides solutions.
 *
 * === Constructor
 * There is no constructor defined for Problem. Problems are created by accessing
 * the Solver result. See 'Solver.each_problem'.
 *
 */

%{
/*
 * iterating over problem causes ('yield' in Ruby)
 */
					
static int
problem_rules_iterate_callback(const Rule *r, void *user_data)
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) r, SWIGTYPE_p__Rule, 0) );
#endif
  return 0;
}


/*
 * iterating over problem solutions ('yield' in Ruby)
 */
					
static int
problem_solutions_iterate_callback(const Solution *s, void *user_data)
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solution, 0) );
#endif
  return 0;
}

%}


%nodefault _Problem;
%rename(Problem) _Problem;
typedef struct _Problem {} Problem;


%extend Problem {
			    
  %constant int SOLVER_RULE_RPM = SOLVER_RULE_RPM;
  %constant int SOLVER_RULE_RPM_NOT_INSTALLABLE = SOLVER_RULE_RPM_NOT_INSTALLABLE,
  %constant int SOLVER_RULE_RPM_NOTHING_PROVIDES_DEP = SOLVER_RULE_RPM_NOTHING_PROVIDES_DEP,
  %constant int SOLVER_RULE_RPM_PACKAGE_REQUIRES = SOLVER_RULE_RPM_PACKAGE_REQUIRES,
  %constant int SOLVER_RULE_RPM_SELF_CONFLICT = SOLVER_RULE_RPM_SELF_CONFLICT,
  %constant int SOLVER_RULE_RPM_PACKAGE_CONFLICT = SOLVER_RULE_RPM_PACKAGE_CONFLICT,
  %constant int SOLVER_RULE_RPM_SAME_NAME = SOLVER_RULE_RPM_SAME_NAME,
  %constant int SOLVER_RULE_RPM_PACKAGE_OBSOLETES = SOLVER_RULE_RPM_PACKAGE_OBSOLETES,
  %constant int SOLVER_RULE_RPM_IMPLICIT_OBSOLETES = SOLVER_RULE_RPM_IMPLICIT_OBSOLETES,
  %constant int SOLVER_RULE_UPDATE = SOLVER_RULE_UPDATE = 0x200,
  %constant int SOLVER_RULE_FEATURE = SOLVER_RULE_FEATURE = 0x300,
  %constant int SOLVER_RULE_JOB = SOLVER_RULE_JOB = 0x400,
  %constant int SOLVER_RULE_JOB_NOTHING_PROVIDES_DEP = SOLVER_RULE_JOB_NOTHING_PROVIDES_DEP,
  %constant int SOLVER_RULE_DISTUPGRADE = SOLVER_RULE_DISTUPGRADE;
  %constant int SOLVER_RULE_INFARCH = SOLVER_RULE_INFARCH;
  %constant int SOLVER_RULE_LEARNT = SOLVER_RULE_LEARNT;
  
  ~Problem()
  { problem_free ($self); }

  /*
   * The solver this problem belongs to
   */
  Solver *solver()
  { return $self->solver; }

  /*
   * The Request causing the Problem
   */
  Request *request()
  { return $self->request; }

  /*
   * The reason for the problem. One of +Satsolver::SOLVER_RULE_*+
   *
   */
  int reason()
  { return $self->reason; }

  /*
   * The Solvable causing the problem
   */
  XSolvable *source()
  { return xsolvable_new( $self->solver->pool, $self->source ); }

  /*
   * The affected relation
   */
  Relation *relation()
  { return relation_new( $self->solver->pool, $self->relation ); }

  /*
   * The Solvable affected by the problem
   */
  XSolvable *target()
  { return xsolvable_new( $self->solver->pool, $self->target ); }

  /*
   * Number of available solutions for problem
   *
   */
  int solutions_count()
  { return solver_solution_count( $self->solver, $self->id ); }

  /*
   * An iterator providing possible Solutions to the Problem
   *
   * call-seq:
   *   problem.each_solution { |solution| ... }
   *
   */
  void each_solution()
  { problem_solutions_iterate( $self, problem_solutions_iterate_callback, NULL );  }

}

