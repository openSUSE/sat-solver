#
# satsolver/ruleinfo
#

module Satsolver
  class Ruleinfo
    def to_s
      case command
      when SOLVER_RULE_DISTUPGRADE:
	"%s does not belong to a distupgrade repository" % source
      when SOLVER_RULE_INFARCH:
	"%s has inferior architecture" % source
      when SOLVER_RULE_UPDATE:
	"problem with installed package %s" % source
      when SOLVER_RULE_JOB:
	"job request"
      when SOLVER_RULE_JOB_NOTHING_PROVIDES_DEP:
	"nothing provides requested %s" % relation
      when SOLVER_RULE_RPM:
	"some dependency problem"
      when SOLVER_RULE_RPM_NOT_INSTALLABLE:
	"package %s is not installable" % source
      when SOLVER_RULE_RPM_NOTHING_PROVIDES_DEP:
	"nothing provides %s needed by %s" % [ relation, source ]
      when SOLVER_RULE_RPM_SAME_NAME:
	"%s updates %s" % [ source, target ]
      when SOLVER_RULE_RPM_PACKAGE_CONFLICT:
	"package %s conflicts with %s provided by %s" % [ source, relation, target ]
      when SOLVER_RULE_RPM_PACKAGE_OBSOLETES:
	"package %s obsoletes %s provided by %s" % [ source, relation, target ]
      when SOLVER_RULE_RPM_IMPLICIT_OBSOLETES:
	"package %s implicitely obsoletes %s provided by %s" % [ source, relation, target ]
      when SOLVER_RULE_RPM_PACKAGE_REQUIRES:
	"package %s requires %s" % [ source, relation ]
      when SOLVER_RULE_RPM_SELF_CONFLICT:
	"package %s conflicts with %s provided by itself" % [ source, relation ]
      when SOLVER_RULE_UNKNOWN:
        "unknown rule"
      when SOLVER_RULE_FEATURE:
        "feature rule"
      when SOLVER_RULE_LEARNT:
	"learnt rule"
      else
	"***BAD RULE [%d]***" % command
      end
    end
  end
end
