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
  %constant int INSTALL_SOLVABLE = SOLVER_INSTALL_SOLVABLE;
  %constant int REMOVE_SOLVABLE = SOLVER_ERASE_SOLVABLE;
  %constant int INSTALL_SOLVABLE_NAME = SOLVER_INSTALL_SOLVABLE_NAME;
  %constant int REMOVE_SOLVABLE_NAME = SOLVER_ERASE_SOLVABLE_NAME;
  %constant int INSTALL_SOLVABLE_PROVIDES = SOLVER_INSTALL_SOLVABLE_PROVIDES;
  %constant int REMOVE_SOLVABLE_PROVIDES = SOLVER_ERASE_SOLVABLE_PROVIDES;

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

}

