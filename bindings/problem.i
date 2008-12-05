/*
 * Problem
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
  %constant int SOLVER_PROBLEM_UPDATE_RULE = SOLVER_PROBLEM_UPDATE_RULE;
  %constant int SOLVER_PROBLEM_JOB_RULE = SOLVER_PROBLEM_JOB_RULE;
  %constant int SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP = SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP;
  %constant int SOLVER_PROBLEM_NOT_INSTALLABLE = SOLVER_PROBLEM_NOT_INSTALLABLE;
  %constant int SOLVER_PROBLEM_NOTHING_PROVIDES_DEP = SOLVER_PROBLEM_NOTHING_PROVIDES_DEP;
  %constant int SOLVER_PROBLEM_SAME_NAME = SOLVER_PROBLEM_SAME_NAME;
  %constant int SOLVER_PROBLEM_PACKAGE_CONFLICT = SOLVER_PROBLEM_PACKAGE_CONFLICT;
  %constant int SOLVER_PROBLEM_PACKAGE_OBSOLETES = SOLVER_PROBLEM_PACKAGE_OBSOLETES;
  %constant int SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE = SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE;
  %constant int SOLVER_PROBLEM_SELF_CONFLICT = SOLVER_PROBLEM_SELF_CONFLICT;
  %constant int SOLVER_PROBLEM_RPM_RULE = SOLVER_PROBLEM_RPM_RULE;

  /* no constructor defined, Problems are created by accessing
     the Solver result. See 'Solver.each_problem'. */

  ~Problem()
  { problem_free ($self); }

  Solver *solver()
  { return $self->solver; }

  Transaction *transaction()
  { return $self->transaction; }

  int reason()
  { return $self->reason; }

  XSolvable *source()
  { return xsolvable_new( $self->solver->pool, $self->source ); }

  Relation *relation()
  { return relation_new( $self->solver->pool, $self->relation ); }

  XSolvable *target()
  { return xsolvable_new( $self->solver->pool, $self->target ); }

  void each_solution()
  { problem_solutions_iterate( $self, problem_solutions_iterate_callback, NULL );  }

}

