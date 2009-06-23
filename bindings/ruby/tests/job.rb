#
# job.rb
#

module Satsolver
  class Job
    def to_s
      case cmd
      when INSTALL_SOLVABLE
	"Install %s" % solvable
      when UPDATE_SOLVABLE
	"Update %s" % solvable
      when REMOVE_SOLVABLE
	"Remove %s" % solvable
      when WEAKEN_SOLVABLE
	"Weaken %s" % solvable
      when LOCK_SOLVABLE
	"Lock %s" % solvable
      when INSTALL_SOLVABLE_NAME
	"Install %s" % name
      when UPDATE_SOLVABLE_NAME
	"Update %s" % name
      when REMOVE_SOLVABLE_NAME
	"Remove %s" % name
      when WEAKEN_SOLVABLE_NAME
	"Weaken %s" % name
      when LOCK_SOLVABLE_NAME
	"Lock %s" % name
      when INSTALL_SOLVABLE_PROVIDES
	"Install %s" % relation
      when UPDATE_SOLVABLE_PROVIDES
	"Update %s" % relation
      when REMOVE_SOLVABLE_PROVIDES
	"Remove %s" % relation
      when WEAKEN_SOLVABLE_PROVIDES
	"Weaken %s" % relation
      when LOCK_SOLVABLE_PROVIDES
	"Lock %s" % relation
      else
	"Job cmd %s" % cmd
      end
    end
  end
end
