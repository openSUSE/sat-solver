/*
 * Document-class: Job
 * A job is a single 'work item' of a request
 *
 * === Constructor
 * There is no constructor defined for Job. Jobs are created by accessing
 * a Request
 *
 */

%nodefault _Job;
%rename(Job) _Job;
typedef struct _Job {} Job;


%extend Job {
  %constant int INSTALL_SOLVABLE = (SOLVER_INSTALL|SOLVER_SOLVABLE);
  %constant int UPDATE_SOLVABLE = (SOLVER_UPDATE|SOLVER_SOLVABLE);
  %constant int REMOVE_SOLVABLE = (SOLVER_ERASE|SOLVER_SOLVABLE);
  %constant int WEAKEN_SOLVABLE = (SOLVER_WEAKENDEPS|SOLVER_SOLVABLE);
  %constant int LOCK_SOLVABLE = (SOLVER_LOCK|SOLVER_SOLVABLE);
  
  %constant int INSTALL_SOLVABLE_NAME = (SOLVER_INSTALL|SOLVER_SOLVABLE_NAME);
  %constant int UPDATE_SOLVABLE_NAME = (SOLVER_UPDATE|SOLVER_SOLVABLE_NAME);
  %constant int REMOVE_SOLVABLE_NAME = (SOLVER_ERASE|SOLVER_SOLVABLE_NAME);
  %constant int WEAKEN_SOLVABLE_NAME = (SOLVER_WEAKENDEPS|SOLVER_SOLVABLE_NAME);
  %constant int LOCK_SOLVABLE_NAME = (SOLVER_LOCK|SOLVER_SOLVABLE_NAME);
  
  %constant int INSTALL_SOLVABLE_PROVIDES = (SOLVER_INSTALL|SOLVER_SOLVABLE_PROVIDES);
  %constant int UPDATE_SOLVABLE_PROVIDES = (SOLVER_UPDATE|SOLVER_SOLVABLE_PROVIDES);
  %constant int REMOVE_SOLVABLE_PROVIDES = (SOLVER_ERASE|SOLVER_SOLVABLE_PROVIDES);
  %constant int WEAKEN_SOLVABLE_PROVIDES = (SOLVER_WEAKENDEPS|SOLVER_SOLVABLE_PROVIDES);
  %constant int LOCK_SOLVABLE_PROVIDES = (SOLVER_LOCK|SOLVER_SOLVABLE_PROVIDES);
  
  %constant int INSTALL_ONE_OF = (SOLVER_INSTALL|SOLVER_SOLVABLE_ONE_OF);
  %constant int UPDATE_ONE_OF = (SOLVER_UPDATE|SOLVER_SOLVABLE_ONE_OF);
  %constant int REMOVE_ONE_OF = (SOLVER_ERASE|SOLVER_SOLVABLE_ONE_OF);
  %constant int LOCK_ONE_OF = (SOLVER_LOCK|SOLVER_SOLVABLE_ONE_OF);
  
  ~Job()
  { job_free( $self ); }

  int cmd()
  { return $self->cmd; }

  XSolvable *solvable()
  { return job_xsolvable( $self ); }

  const char *name()
  { return job_name( $self ); }

  Relation *relation()
  { return job_relation( $self ); }

  /*
   * Job equality
   */

#if defined(SWIGPERL)
  /*
   * :nodoc:
   */
  int __eq__( const Job *job )
#endif
#if defined(SWIGRUBY)
  %typemap(out) int equal
    "$result = $1 ? Qtrue : Qfalse;";
  %rename("==") equal;
  /*
   * Equality operator
   *
   */
  int equal( const Job *job )
#endif

#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   * Python treats 'eq' and 'ne' distinct.
   */
  int __ne__( const Job *job )
  { return !job_equal($self, job); }
  int __eq__( const Job *job )
#endif
  { return job_equal($self, job); }

#if defined(SWIGRUBY)
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string();
#endif
  char *string()
  { return job_string($self); }
}
