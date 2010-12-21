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
problem_ruleinfo_iterate_callback( Ruleinfo *ri, void *user_data)
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*)ri, SWIGTYPE_p__Ruleinfo, 0) );
  ruleinfo_free(ri);
#else
  AddPtrIndex(((PtrIndex*)user_data),const Ruleinfo **,ri);
#endif
  return 0;
}


/*
 * iterating over problem solutions ('yield' in Ruby)
 */
					
static int
problem_solutions_iterate_callback( Solution *s, void *user_data)
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solution, 0) );
  solution_free(s);
#else
  AddPtrIndex(((PtrIndex*)user_data),const Solution **,s);
#endif
  return 0;
}

%}


%nodefault _Problem;
%rename(Problem) _Problem;
typedef struct _Problem {} Problem;


%extend Problem {

  ~Problem()
  { problem_free ($self); }

  /*
   * The solver this problem belongs to
   */
  Solver *solver()
  { return $self->solver; }

#if defined(SWIGRUBY)
  %rename("to_s") string(int full = 0);
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string(int full = 0);
#endif
  char *string(int full = 0)
  { return problem_string( $self, full ); }

#if defined(SWIGRUBY)
  /*
   * An iterator providing information on the rules leading to the
   * problem.
   *
   * call-seq:
   *   problem.each_ruleinfo { |ruleinfo| ... }
   *
   */
  void each_ruleinfo()
  { problem_ruleinfos_iterate( $self, problem_ruleinfo_iterate_callback, NULL ); }
#else
  const Ruleinfo **ruleinfos()
  {
    PtrIndex pi;
    NewPtrIndex(pi,const Ruleinfo **,0);
    problem_ruleinfos_iterate( $self, problem_ruleinfo_iterate_callback, &pi );
    ReturnPtrIndex(pi,const Ruleinfo **);
  }
#endif

  /*
   * Number of available solutions for problem
   *
   */
  int solutions_count()
  { return solver_solution_count( $self->solver, $self->id ); }

#if defined(SWIGRUBY)
  /*
   * An iterator providing possible Solutions to the Problem
   *
   * call-seq:
   *   problem.each_solution { |solution| ... }
   *
   */
  void each_solution()
  { problem_solutions_iterate( $self, problem_solutions_iterate_callback, NULL );  }
#else
  const Solution **solutions()
  {
    PtrIndex pi;
    NewPtrIndex(pi,const Solution **,0);
    problem_solutions_iterate( $self, problem_solutions_iterate_callback, &pi );
    ReturnPtrIndex(pi,const Solution **);
  }
#endif

}

