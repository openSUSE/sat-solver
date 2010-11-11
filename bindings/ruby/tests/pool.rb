require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
#
# The Pool is the main data structure for sat-solver.
#
# It contains all solvables, grouped by Repo(sitorie)s
# and is needed to create instances of other classes.
#
# For Solvable, Repo, Request, Solver and Relation,
# Pool provides create_... methods as counterparts to
# the instance contructors, all requiring a Pool argument.
#
# The main object within a Pool is the Solvable. So Pool.size,
# Pool.each, Pool.get (resp. Pool[]) and Pool.find all operate
# on Solvables.
#
# For Repos there is each_repo, count_repos, get_repo and find_repo.
#
# test Pool
class PoolTest < Test::Unit::TestCase
  def test_pool
    pool = Satsolver::Pool.new
    assert pool
    assert pool.count_repos == 0
  end
  def test_pool1
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "i686"
  end
  def test_pool2
    pool = Satsolver::Pool.new "i686"
    assert pool
  end
end
