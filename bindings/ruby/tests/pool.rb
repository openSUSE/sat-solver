$: << "../../../build/bindings/ruby"
# test Pool
require 'test/unit'
require 'satsolver'

class PoolTest < Test::Unit::TestCase
  def test_pool
    pool = SatSolver::Pool.new
    assert pool
    assert pool.count_repos == 0
  end
end
