/*
 * Covenant
 */

%nodefault _Covenant;
%rename(Covenant) _Covenant;
typedef struct _Covenant {} Covenant;


%extend Covenant {
  %constant int INCLUDE_SOLVABLE = SOLVER_INSTALL_SOLVABLE;
  %constant int EXCLUDE_SOLVABLE = SOLVER_ERASE_SOLVABLE;
  %constant int INCLUDE_SOLVABLE_NAME = SOLVER_INSTALL_SOLVABLE_NAME;
  %constant int EXCLUDE_SOLVABLE_NAME = SOLVER_ERASE_SOLVABLE_NAME;
  %constant int INCLUDE_SOLVABLE_PROVIDES = SOLVER_INSTALL_SOLVABLE_PROVIDES;
  %constant int EXCLUDE_SOLVABLE_PROVIDES = SOLVER_ERASE_SOLVABLE_PROVIDES;

  /* no constructor defined, Covenants are created through the Solver,
     see 'Solver.include' and 'Solver.excluding' */
  ~Covenant()
  { covenant_free( $self ); }

  int cmd()
  { return $self->cmd; }

  XSolvable *solvable()
  { return covenant_xsolvable( $self ); }

  const char *name()
  { return covenant_name( $self ); }

  Relation *relation()
  { return covenant_relation( $self ); }
}


