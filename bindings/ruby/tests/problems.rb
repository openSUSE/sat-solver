$: << "../../../build/bindings/ruby"
# test Problems
require 'test/unit'
require 'satsolver'

def solve_and_check pool, installed, transaction, problem
  
  solver = pool.create_solver( installed )
  solver.solve( transaction )
  assert solver.problems?
  puts "Problems found"
  i = 0
  found = false
  solver.each_problem( transaction ) { |p|
    found = true if p.reason == problem
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
  return found
end

class ProblemTest < Test::Unit::TestCase
  def setup
    @pool = SatSolver::Pool.new
    assert @pool
    
    @installed = @pool.create_repo( 'system' )
    assert @installed
    @installed.create_solvable( 'A', '0.0-0' )
    @installed.create_solvable( 'B', '1.0-0' )
    @installed.create_solvable( 'C', '2.0-0' )
    @installed.create_solvable( 'D', '3.0-0' )
    
    @repo = @pool.create_repo( 'test' )
    assert @repo
    @repo.create_solvable( 'A', '1.0-0' )
    @repo.create_solvable( 'B', '2.0-0' )
    @repo.create_solvable( 'CC', '3.3-0' )
    @repo.create_solvable( 'DD', '4.4-0' )

  end
  
  def test_update_rule
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_UPDATE_RULE )
  end
  def test_job_rule
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_JOB_RULE )
  end
  def test_job_nothing_provides
    transaction = @pool.create_transaction
    solv = @pool.find( "A", @repo )
    solv.requires << @pool.create_relation( "ZZ" )
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP )
  end
  def test_not_installable
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_NOT_INSTALLABLE )
  end
  def test_nothing_provides
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_NOTHING_PROVIDES_DEP )
  end
  def test_same_name
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_SAME_NAME )
  end
  def test_package_conflict
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_PACKAGE_CONFLICT )
  end
  def test_package_obsoletes
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_PACKAGE_OBSOLETES )
  end
  def test_providers_not_installable
    transaction = @pool.create_transaction
    assert solve_and_check( @pool, @installed, transaction, SatSolver::SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE )
  end
end
