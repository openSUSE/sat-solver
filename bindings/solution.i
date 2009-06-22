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

%nodefault _Solution;
%rename(Solution) _Solution;
typedef struct _Solution {} Solution;


%extend Solution {
  ~Solution()
  { solution_free ($self); }
}


