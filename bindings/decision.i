/*
 * Decision
 */

%nodefault _Decision;
%rename(Decision) _Decision;
typedef struct _Decision {} Decision;


%extend Decision {
  %constant int DEC_INSTALL = DECISION_INSTALL;
  %constant int DEC_REMOVE = DECISION_REMOVE;
  %constant int DEC_UPDATE = DECISION_UPDATE;
  %constant int DEC_OBSOLETE = DECISION_OBSOLETE;

  /* no constructor defined, Decisions are created by accessing
     the Solver result. See 'Solver.each_decision'. */

  ~Decision()
  { decision_free( $self ); }
  Pool *pool()
  { return $self->pool; }
  int op()
  { return $self->op; }
  XSolvable *solvable()
  { return xsolvable_new( $self->pool, $self->solvable ); }
  XSolvable *reason()
  { return xsolvable_new( $self->pool, $self->reason ); }
}

