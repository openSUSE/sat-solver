/*
 * Document-class: Solution
 * Solutions are attached to Problems and give hints on how to solve problems.
 *
 * Solutions as coming from satsolver are 'raw' as they only tell you
 * which jobs to change. Thats either job items to remove (from the
 * Request) or new job items to add.
 *
 * How this relates to the application view is up to the application
 * using the bindings.
 *
 * === Constructor
 * There is no constructor defined for Solution. Solution are part of Problem and can be
 * accessed through Problem.each_solution
 *
 */

%{
/*
 * iterating over solution elements ('yield' in Ruby)
 */
					
static int
solutionelement_iterate_callback(const SolutionElement *se, void *user_data)
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*)se, SWIGTYPE_p__SolutionElement, 0) );
#endif
  return 0;
}

%}


%nodefault _Solution;
%rename(Solution) _Solution;
typedef struct _Solution {} Solution;

%nodefault _SolutionElement;
%rename(SolutionElement) _SolutionElement;
typedef struct _SolutionElement {} SolutionElement;


%extend Solution {
  /* No explicit constructor, use Problem#each_solution */
  ~Solution()
  { solution_free ($self); }
  /*
   * An iterator providing elements of the Solution
   *
   * call-seq:
   *   solution.each_element { |solution_element| ... }
   *
   */
  void each_element()
  { solution_elements_iterate( $self, solutionelement_iterate_callback, NULL );  }

}

%extend SolutionElement {
  /* caused by missing/dispensable solvable */
  %constant int SOLUTION_SOLVABLE = 0;
  /* caused by bad job */
  %constant int SOLUTION_JOB = SOLVER_SOLUTION_JOB-1;
  /* caused by upgrade */
  %constant int SOLUTION_DISTUPGRADE = SOLVER_SOLUTION_DISTUPGRADE-1;
  /* caused by wrong/inferior architecture */
  %constant int SOLUTION_INFARCH = SOLVER_SOLUTION_INFARCH-1;
  
  /* No explicit constructor, use Soltion#each_element */
  ~SolutionElement()
  { solutionelement_free ($self); }
  
  int cause()
  { return solutionelement_cause( $self ); }
  
  Job *job()
  { return solutionelement_job( $self ); }
}
