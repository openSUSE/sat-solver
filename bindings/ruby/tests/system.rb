#
# Test the 'system' solvable
#
# The system solvable belongs to the pool and no repo
# Its used to represent dependencies of the system, like
# looks or hardware (modalias).
#
$: << "../../../build/bindings/ruby"
# test Pool:system
require 'test/unit'
require 'satsolver'

class SystemTest < Test::Unit::TestCase
  def test_system
    pool = SatSolver::Pool.new
    assert pool
    system = pool.system
    assert system
    assert system.name == "system:system"
  end
end
