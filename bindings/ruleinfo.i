/*
 * Document-class: Ruleinfo
 *
 * Ruleinfos are useful to traceback a decision or a problem.
 *
 * === Constructor
 * There is no constructor for Ruleinfo. Ruleinfos are created when
 * iterating over problems
 *
 */

%nodefault _Ruleinfo;
%rename(Ruleinfo) _Ruleinfo;
typedef struct _Ruleinfo {} Ruleinfo;

 
%extend Ruleinfo {

  int command()
  { return $self->cmd; }
  
  XSolvable *source()
  { return ruleinfo_source($self); }
  
  XSolvable *target()
  { return ruleinfo_target($self); }

  Relation *relation()
  { return ruleinfo_relation($self); }
  
}
