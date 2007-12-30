$: << "../../../build/bindings/ruby"
# test Decisions
require 'test/unit'
require 'satsolver'

class DecisionTest < Test::Unit::TestCase
  def test_decision
    pool = SatSolver::Pool.new
    assert pool
    pool.arch = "i686"
    
    installed = pool.create_repo( 'system' )
    assert installed
    installed.create_solvable( 'A', '0.0-0' )
    installed.create_solvable( 'B', '1.0-0' )
    installed.create_solvable( 'C', '2.0-0' )
    installed.create_solvable( 'D', '3.0-0' )

    repo = pool.create_repo( 'test' )
    assert repo
    
    solv1 = repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv1.obsoletes << SatSolver::Relation.new( pool, "C" )
    solv1.requires << SatSolver::Relation.new( pool, "B", SatSolver::REL_GE, "2.0-0" )
    
    solv2 = repo.create_solvable( 'B', '2.0-0', 'noarch' )
    assert solv2
    
    solv3 = repo.create_solvable( 'CC', '3.3-0', 'noarch' )
    solv3.requires << SatSolver::Relation.new( pool, "A", SatSolver::REL_GT, "0.0-0" )
    repo.create_solvable( 'DD', '4.4-0', 'noarch' )

    
    transaction = pool.create_transaction
    transaction.install( solv3 )
    transaction.remove( "D" )
    
    solver = pool.create_solver( installed )
    solver.allow_uninstall = 1;
#    @pool.debug = 255
    solver.solve( transaction )
    puts "#{solver.problem_count} problems found"
    assert solver.decision_count > 0
    i = 0
    solver.each_decision { |d|
      i += 1
      case d.op
      when SatSolver::DEC_INSTALL
	puts "#{i}: Install #{d.solvable} #{d.reason}"
      when SatSolver::DEC_REMOVE
	puts "#{i}: Remove #{d.solvable} #{d.reason}"
      when SatSolver::DEC_OBSOLETE
	puts "#{i}: Obsolete #{d.solvable} #{d.reason}"
      when SatSolver::DEC_UPDATE
	puts "#{i}: Update #{d.solvable} #{d.reason}"
      else
	puts "#{i}: Decision op #{d.op}"
      end
    }
  end
end
