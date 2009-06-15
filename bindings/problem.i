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
  /* The problem is caused by an update rule (i.e. 'better' Solvable available) */
  %constant int SOLVER_PROBLEM_UPDATE_RULE = SOLVER_PROBLEM_UPDATE_RULE;
  /* The problem is caused by a Job inside the Request */
  %constant int SOLVER_PROBLEM_JOB_RULE = SOLVER_PROBLEM_JOB_RULE;
  /* A Job based on a Relation could not be fulfilled because there is no Solvable in the Pool providing it. */
  %constant int SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP = SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP;
  /* The Solvable is not installable (wrong architecture, etc.) */
  %constant int SOLVER_PROBLEM_NOT_INSTALLABLE = SOLVER_PROBLEM_NOT_INSTALLABLE;
  /* A requirement could not be fulfilled because there is no Solvable in the Pool providing it. */
  %constant int SOLVER_PROBLEM_NOTHING_PROVIDES_DEP = SOLVER_PROBLEM_NOTHING_PROVIDES_DEP;
  /* Same name */
  %constant int SOLVER_PROBLEM_SAME_NAME = SOLVER_PROBLEM_SAME_NAME;
  /* Packages conflict */
  %constant int SOLVER_PROBLEM_PACKAGE_CONFLICT = SOLVER_PROBLEM_PACKAGE_CONFLICT;
  /* Package is obsoleted */
  %constant int SOLVER_PROBLEM_PACKAGE_OBSOLETES = SOLVER_PROBLEM_PACKAGE_OBSOLETES;
  /* A requirement is fulfilled by an uninstallable Solvable */
  %constant int SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE = SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE;
  /* The Solvable conflicts with itself. */
  %constant int SOLVER_PROBLEM_SELF_CONFLICT = SOLVER_PROBLEM_SELF_CONFLICT;
  /* A dependency of an already installed Solvable could not be fulfilled (broken system) */
  %constant int SOLVER_PROBLEM_RPM_RULE = SOLVER_PROBLEM_RPM_RULE;

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
   * The reason for the problem. One of +Satsolver::SOLVER_PROBLEM_*+
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

