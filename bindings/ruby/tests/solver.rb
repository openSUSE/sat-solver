$:.unshift "../../../build/bindings/ruby"
require 'pathname'

# test Solver

require 'test/unit'
require 'satsolver'

class SolverTest < Test::Unit::TestCase
  def test_solver
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "i686"
    system = pool.add_rpmdb( "/" )
    repo = pool.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    repo.name = "test"
    
    transaction = Satsolver::Transaction.new( pool )
    transaction.install( "A" )
    transaction.remove( "xorg-x11" )
    
    pool.installed = system
    solver = Satsolver::Solver.new( pool )
    solver.allow_uninstall = true
    assert solver.allow_uninstall
    pool.prepare
    solver.solve( transaction )
    assert solver.sizechange
    puts "Size change #{solver.sizechange}"
    solver.each_to_install { |s|
      puts "Install #{s}"
    }
    solver.each_to_remove { |s|
      puts "Remove #{s}"
    }
  end
end
