$:.unshift "../../../build/bindings/ruby"

# test Covenants

require 'test/unit'
require 'satsolver'

class CovenantTest < Test::Unit::TestCase
  def test_convenant
    pool = SatSolver::Pool.new "i686"
    assert pool
    repo = pool.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    repo.name = "test"

    solver = pool.create_solver

    solver.include( "foo" )
    solver.include( repo[0] )
    solver.include( SatSolver::Relation.new( pool, "foo", SatSolver::REL_EQ, "42-7" ) )
    solver.exclude( "bar" )
    solver.exclude( repo[1] )
    solver.exclude( SatSolver::Relation.new( pool, "bar", SatSolver::REL_EQ, "42-7" ) )
    assert solver.covenants_count == 6
    solver.each_covenant do |c|
      cmd = case c.cmd
        when SatSolver::INCLUDE_SOLVABLE: "include #{c.solvable}"
	when SatSolver::EXCLUDE_SOLVABLE: "exclude #{c.solvable}"
	when SatSolver::INCLUDE_SOLVABLE_NAME: "include by name #{c.name}"
	when SatSolver::EXCLUDE_SOLVABLE_NAME: "exclude by name #{c.name}"
	when SatSolver::INCLUDE_SOLVABLE_PROVIDES: "include by relation #{c.relation}"
	when SatSolver::EXCLUDE_SOLVABLE_PROVIDES: "exclude by relation #{c.relation}"
	else "<NONE>"
	end
      puts cmd
    end
    solver.covenants_clear!
    assert solver.covenants_empty?
  end
end
