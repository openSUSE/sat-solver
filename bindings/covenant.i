/*
 * Covenant
 */

%nodefault _Covenant;
%rename(Covenant) _Covenant;
typedef struct _Covenant {} Covenant;

/*
 * Covenants ensure specific dependencies in the (installed) system.
 * They are usually used to implement locks.
 *
 * There is no constructor for Covenants defined, Covenants are created through the Solver,
 * see 'Solver.include' and 'Solver.exclude'
 *
 * Convenants can affect specific Solvables, Solvables per-name or
 * Solvables per-provides. In the latter case, when including
 * Solvables per-name or per-provides, the solver is free to
 * choose a matching solvable.
 *
 * See also: Solver.include, Solver.exclude
 *
 */
%extend Covenant {
  /* ensure this solvable is installed */
  %constant int INCLUDE_SOLVABLE = SOLVER_INSTALL_SOLVABLE;
  /* ensure this solvable is NOT installed */
  %constant int EXCLUDE_SOLVABLE = SOLVER_ERASE_SOLVABLE;
  /* ensure a solvable (any solvable) of this name is installed */
  %constant int INCLUDE_SOLVABLE_NAME = SOLVER_INSTALL_SOLVABLE_NAME;
  /* ensure NO solvable of this name is installed */
  %constant int EXCLUDE_SOLVABLE_NAME = SOLVER_ERASE_SOLVABLE_NAME;
  /* ensure a solvable (any solvable) providing this relation is installed */
  %constant int INCLUDE_SOLVABLE_PROVIDES = SOLVER_INSTALL_SOLVABLE_PROVIDES;
  /* ensure NO solvable providing this relation is installed */
  %constant int EXCLUDE_SOLVABLE_PROVIDES = SOLVER_ERASE_SOLVABLE_PROVIDES;

  ~Covenant()
  { covenant_free( $self ); }
  
  /* operation of this covenant
   * i.e. Satsolver::INCLUDE_SOLVABLE_PROVIDES
   *
   */
  int cmd()
  { return $self->cmd; }

  /* solvable this covenant affects
   * non-nil only for operations INCLUDE_SOLVABLE and EXCLUDE_SOLVABLE
   *
   */
  XSolvable *solvable()
  { return covenant_xsolvable( $self ); }

  /* name this covenant affects
   * non-nil only for operations INCLUDE_SOLVABLE_NAME and EXCLUDE_SOLVABLE_NAME
   *
   */
  const char *name()
  { return covenant_name( $self ); }

  /* relation this covenant affects
   * non-nil only for operations INCLUDE_SOLVABLE_PROVIDES and EXCLUDE_SOLVABLE_PROVIDES
   *
   */
  Relation *relation()
  { return covenant_relation( $self ); }
}
