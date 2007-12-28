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
