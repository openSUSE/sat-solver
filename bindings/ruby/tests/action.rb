#
# Solving dependencies needs 'something to do'
#
# This is specified via Actions, collected in an Transaction.
#
# You should NOT create Actions manually, but via the Transaction
# class. See Transaction for details.
#
# An Action consist of
#  - a command (action.cmd)
#  - a name, solvable or relation id (action.id), depending on the command
#
# The command is one of
#   INSTALL_SOLVABLE
#     install a specific solvable, id specifies a solvable
#   REMOVE_SOLVABLE;
#     remove a specific solvable, id specifies a solvable
#   INSTALL_SOLVABLE_NAME
#     install a solvable by name, id specifies a name
#   REMOVE_SOLVABLE_NAME
#     remove a solvable by name, id specifies a name
#   INSTALL_SOLVABLE_PROVIDES
#     install a solvable by provides, id specifies a relation the solvable must provide
#   REMOVE_SOLVABLE_PROVIDES
#     remove a solvable by provides, id specifies a relation the solvable must provide
#	    
#


$: << "../../../build/bindings/ruby"
# test Action
require 'test/unit'
require 'satsolver'

class ActionTest < Test::Unit::TestCase
  def test_action
    action = SatSolver::Action.new( SatSolver::INSTALL_SOLVABLE, 1 )
    assert action
    assert action.cmd == SatSolver::INSTALL_SOLVABLE
    assert action.id == 1
  end
end
