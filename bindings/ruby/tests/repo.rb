$: << "../../../build/bindings/ruby"
# test Repo
require 'test/unit'
require 'SatSolver'

class RepoTest < Test::Unit::TestCase
  def test_repo_create
    pool = SatSolver::Pool.new
    assert pool
    repo = SatSolver::Repo.new( pool, "test" )
    assert repo
    assert repo.size == 0
    assert repo.name == "test"
  end
  def test_repo_add
    pool = SatSolver::Pool.new
    assert pool
    repo = SatSolver::Repo.new( pool, "test" )
    assert repo
    pool.arch = "i686"
    puts repo.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    puts repo.name
    puts repo.size
  end
  def test_deps
    pool = SatSolver::Pool.new
    assert pool
    repo = SatSolver::Repo.new( pool, "test" )
    assert repo
    pool.arch = "i686"
    puts repo.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    repo.each_solvable{ |s|
      puts s
    }
    assert true
  end
end
