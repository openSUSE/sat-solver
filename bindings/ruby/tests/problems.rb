$: << "../../../build/bindings/ruby"
# test Problems
require 'test/unit'
require 'satsolver'

class ProblemTest < Test::Unit::TestCase
  def test_problems
    pool = SatSolver::Pool.new
    assert pool
    
    installed = pool.create_repo( 'system' )
    assert installed
    installed.create_solvable( 'A', '0.0-0' )
    installed.create_solvable( 'B', '1.0-0' )
    solv = installed.create_solvable( 'C', '2.0-0' )
    solv.requires << SatSolver::Relation.new( pool, "D", SatSolver::REL_EQ, "3.0-0" )
    installed.create_solvable( 'D', '3.0-0' )

    repo = pool.create_repo( 'test' )
    assert repo
    
    solv1 = repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv1.obsoletes << SatSolver::Relation.new( pool, "C" )
    solv1.requires << SatSolver::Relation.new( pool, "B", SatSolver::REL_GT, "2.0-0" )
    
    solv2 = repo.create_solvable( 'B', '2.0-0' )
    assert solv2
    
    solv3 = repo.create_solvable( 'CC', '3.3-0' )
#    solv3.requires << SatSolver::Relation.new( pool, "Z" )
    repo.create_solvable( 'DD', '4.4-0' )

    
    transaction = pool.create_transaction
    transaction.install( solv1 )
    transaction.remove( "Z" )
    
    solver = pool.create_solver( installed )
#    solver.allow_uninstall = 1;
#    @pool.debug = 255
    solver.solve( transaction )
    puts "#{solver.problem_count} problems found"
    assert solver.problem_count > 0
    i = 0
    solver.each_problem( transaction ) { |p|
      i += 1
      case p.reason
      when SatSolver::SOLVER_PROBLEM_UPDATE_RULE
	reason = "problem with installed"
      when SatSolver::SOLVER_PROBLEM_JOB_RULE
	reason = "conflicting requests"
      when SatSolver::SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP
	reason = "nothing provides requested"
      when SatSolver::SOLVER_PROBLEM_NOT_INSTALLABLE
	reason = "not installable"
      when SatSolver::SOLVER_PROBLEM_NOTHING_PROVIDES_DEP
	reason = "nothing provides rel required by source"
      when SatSolver::SOLVER_PROBLEM_SAME_NAME
	reason = "cannot install both"
      when SatSolver::SOLVER_PROBLEM_PACKAGE_CONFLICT
	reason = "source conflicts with rel provided by target"
      when SatSolver::SOLVER_PROBLEM_PACKAGE_OBSOLETES
	reason = "source obsoletes rel provided by target"
      when SatSolver::SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE
	reason = "source requires rel but no providers are installable"
      else
	reason = "**unknown**"
      end
      puts "#{i}: [#{reason}] Source #{p.source}, Rel #{p.relation}, Target #{p.target}"
    }
  end
end
