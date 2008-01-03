#
# The Pool is the main data structure for sat-solver.
#
# It contains all solvables, grouped by Repo(sitorie)s
# and is needed to create instances of other classes.
#
# For Solvable, Repo, Transaction, Solver and Relation,
# Pool provides create_... methods as counterparts to
# the instance contructors, all requiring a Pool argument.
#
# The main object within a Pool is the Solvable. So Pool.size,
# Pool.each, Pool.get (resp. Pool[]) and Pool.find all operate
# on Solvables.
#
# For Repos there is each_repo, count_repos, get_repo and find_repo.
#
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
