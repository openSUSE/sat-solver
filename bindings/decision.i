/*
 * Decision
 */

%nodefault _Decision;
%rename(Decision) _Decision;
typedef struct _Decision {} Decision;


%extend Decision {
  %constant int DECISION_INSTALL = DECISION_INSTALL;
  %constant int DECISION_REMOVE = DECISION_REMOVE;
  %constant int DECISION_UPDATE = DECISION_UPDATE;
  %constant int DECISION_OBSOLETE = DECISION_OBSOLETE;
  %constant int DECISION_WEAK = DECISION_WEAK;
  %constant int DECISION_FREE = DECISION_FREE;

  /* no constructor defined, Decisions are created by accessing
     the Solver result. See 'Solver.each_decision'. */

  ~Decision()
  { decision_free( $self ); }
  Solver *solver()
  { return $self->solver; }
  int op()
  { return $self->op; }
  const char *op_s()
  { switch ($self->op) {
      case DECISION_INSTALL: return "install";
      case DECISION_REMOVE: return "remove";
      case DECISION_UPDATE: return "update";
      case DECISION_OBSOLETE: return "obsolete";
      case DECISION_INSTALL|DECISION_FREE: return "free install";
      default: break;
    }
    return "unknown";
  }
  XSolvable *solvable()
  { return xsolvable_new( $self->solver->pool, $self->solvable ); }
  Rule *rule()
  { if ($self->rule > $self->solver->rules)
      return $self->rule;
    return NULL;
  }
}

