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
  const char *op_s()
  { switch ($self->op) {
      case DECISION_INSTALL: return "install";
      case DECISION_REMOVE: return "remove";
      case DECISION_UPDATE: return "update";
      case DECISION_OBSOLETE: return "obsolete";
      default: break;
    }
    return "unknown";
  }
  XSolvable *solvable()
  { return xsolvable_new( $self->pool, $self->solvable ); }
  Rule *rule()
  { return $self->rule; }
}

