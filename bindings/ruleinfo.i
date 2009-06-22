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

  %constant int SOLVER_RULE_RPM = SOLVER_RULE_RPM;
  %constant int SOLVER_RULE_RPM_NOT_INSTALLABLE = SOLVER_RULE_RPM_NOT_INSTALLABLE;
  %constant int SOLVER_RULE_RPM_NOTHING_PROVIDES_DEP = SOLVER_RULE_RPM_NOTHING_PROVIDES_DEP;
  %constant int SOLVER_RULE_RPM_PACKAGE_REQUIRES = SOLVER_RULE_RPM_PACKAGE_REQUIRES;
  %constant int SOLVER_RULE_RPM_SELF_CONFLICT = SOLVER_RULE_RPM_SELF_CONFLICT;
  %constant int SOLVER_RULE_RPM_PACKAGE_CONFLICT = SOLVER_RULE_RPM_PACKAGE_CONFLICT;
  %constant int SOLVER_RULE_RPM_SAME_NAME = SOLVER_RULE_RPM_SAME_NAME;
  %constant int SOLVER_RULE_RPM_PACKAGE_OBSOLETES = SOLVER_RULE_RPM_PACKAGE_OBSOLETES;
  %constant int SOLVER_RULE_RPM_IMPLICIT_OBSOLETES = SOLVER_RULE_RPM_IMPLICIT_OBSOLETES;
  %constant int SOLVER_RULE_UPDATE = SOLVER_RULE_UPDATE;
  %constant int SOLVER_RULE_FEATURE = SOLVER_RULE_FEATURE;
  %constant int SOLVER_RULE_JOB = SOLVER_RULE_JOB;
  %constant int SOLVER_RULE_JOB_NOTHING_PROVIDES_DEP = SOLVER_RULE_JOB_NOTHING_PROVIDES_DEP;
  %constant int SOLVER_RULE_DISTUPGRADE = SOLVER_RULE_DISTUPGRADE;
  %constant int SOLVER_RULE_INFARCH = SOLVER_RULE_INFARCH;
  %constant int SOLVER_RULE_LEARNT = SOLVER_RULE_LEARNT;

  int command()
  { return ruleinfo_command($self); }

  const char *command_s()
  { return ruleinfo_command_string($self); }

  XSolvable *source()
  { return ruleinfo_source($self); }
  
  XSolvable *target()
  { return ruleinfo_target($self); }

  Relation *relation()
  { return ruleinfo_relation($self); }

}
