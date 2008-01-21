$:.unshift "../../../build/bindings/ruby"

# test Solver

require 'test/unit'
require 'satsolver'

class SolverTest < Test::Unit::TestCase
  def test_solver
    pool = SatSolver::Pool.new
    assert pool
    pool.arch = "i686"
    system = pool.add_rpmdb( "/" )
    repo = pool.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    repo.name = "test"
    
    transaction = SatSolver::Transaction.new( pool )
    transaction.install( "A" )
    transaction.remove( "xorg-x11" )
    
    solver = SatSolver::Solver.new( pool, system )
    solver.allow_uninstall = true
    assert solver.allow_uninstall
    pool.prepare
    solver.solve( transaction )
    solver.each_to_install { |s|
      puts "Install #{s}"
    }
    solver.each_to_remove { |s|
      puts "Remove #{s}"
    }
  end
end
