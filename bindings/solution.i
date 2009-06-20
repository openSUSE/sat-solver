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
  %constant int SOLUTION_UNKNOWN = SOLUTION_UNKNOWN;
  %constant int SOLUTION_NOKEEP_INSTALLED = SOLUTION_NOKEEP_INSTALLED;
  %constant int SOLUTION_NOINSTALL_SOLV = SOLUTION_NOINSTALL_SOLV;
  %constant int SOLUTION_NOREMOVE_SOLV = SOLUTION_NOREMOVE_SOLV;
  %constant int SOLUTION_NOFORBID_INSTALL = SOLUTION_NOFORBID_INSTALL;
  %constant int SOLUTION_NOINSTALL_NAME = SOLUTION_NOINSTALL_NAME;
  %constant int SOLUTION_NOREMOVE_NAME = SOLUTION_NOREMOVE_NAME;
  %constant int SOLUTION_NOINSTALL_REL = SOLUTION_NOINSTALL_REL;
  %constant int SOLUTION_NOREMOVE_REL = SOLUTION_NOREMOVE_REL;
  %constant int SOLUTION_NOUPDATE = SOLUTION_NOUPDATE;
  %constant int SOLUTION_ALLOW_DOWNGRADE = SOLUTION_ALLOW_DOWNGRADE;
  %constant int SOLUTION_ALLOW_ARCHCHANGE = SOLUTION_ALLOW_ARCHCHANGE;
  %constant int SOLUTION_ALLOW_VENDORCHANGE = SOLUTION_ALLOW_VENDORCHANGE;
  %constant int SOLUTION_ALLOW_REPLACEMENT = SOLUTION_ALLOW_REPLACEMENT;
  %constant int SOLUTION_ALLOW_REMOVE = SOLUTION_ALLOW_REMOVE;
  ~Solution()
  { solution_free ($self); }
  int solution()
  { return $self->solution; }
  /* without the %rename, swig converts it to 's_1'. Ouch! */
  %rename( "s1" ) s1( );
  XSolvable *s1()
  { return xsolvable_new( $self->pool, $self->s1 ); }
  %rename( "n1" ) n1( );
  const char *n1()
  { return id2str( $self->pool, $self->n1 ); }
  %rename( "r1" ) r1( );
  Relation *r1()
  { return relation_new( $self->pool, $self->n1 ); }
  %rename( "s2" ) s2( );
  XSolvable *s2()
  { return xsolvable_new( $self->pool, $self->s2 ); }
  %rename( "n2" ) n2( );
  const char *n2()
  { return id2str( $self->pool, $self->n2 ); }
}


