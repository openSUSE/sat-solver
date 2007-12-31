$: << "../../../build/bindings/ruby"
# test Problems
require 'test/unit'
require 'satsolver'

def solve_and_check solver, transaction, problem
  
  assert solver.problems?
  puts "[#{problem}] Problems found"
  i = 0
  found = false
  solver.each_problem( transaction ) { |p|
    found = true if p.reason == problem
    i += 1
    case p.reason
      when SatSolver::SOLVER_PROBLEM_UPDATE_RULE #1
	reason = "problem with installed"
      when SatSolver::SOLVER_PROBLEM_JOB_RULE #2
	reason = "conflicting requests"
      when SatSolver::SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP #3
	reason = "nothing provides requested"
      when SatSolver::SOLVER_PROBLEM_NOT_INSTALLABLE #4
	reason = "not installable"
      when SatSolver::SOLVER_PROBLEM_NOTHING_PROVIDES_DEP #5
	reason = "nothing provides rel required by source"
      when SatSolver::SOLVER_PROBLEM_SAME_NAME #6
	reason = "cannot install both"
      when SatSolver::SOLVER_PROBLEM_PACKAGE_CONFLICT #7
	reason = "source conflicts with rel provided by target"
      when SatSolver::SOLVER_PROBLEM_PACKAGE_OBSOLETES #8
	reason = "source obsoletes rel provided by target"
      when SatSolver::SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE #9
	reason = "source requires rel but no providers are installable"
      else
	reason = "**unknown**"
    end
    puts "#{i}: [#{p.reason}]: #{reason}] Source #{p.source}, Rel #{p.relation}, Target #{p.target}"
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
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_UPDATE_RULE )
  end
  def test_job_rule
    transaction = @pool.create_transaction
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_JOB_RULE )
  end
  def test_job_nothing_provides
    transaction = @pool.create_transaction
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP )
  end
  def test_not_installable
    transaction = @pool.create_transaction
    solv = @pool.find( "A", @repo )
    solv.requires << @pool.create_relation( "ZZ" )
    transaction.install( solv )
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_NOT_INSTALLABLE )
  end
  def test_nothing_provides
    transaction = @pool.create_transaction
    solvA = @pool.find( "A", @repo )
    solvA.requires << @pool.create_relation( "B", SatSolver::REL_GE, "2.0-0" )
    solvB = @pool.find( "B", @repo )
    solvB.requires << @pool.create_relation( "ZZ" )
    transaction.install( solvA )
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_NOTHING_PROVIDES_DEP )
  end
  def test_same_name
    transaction = @pool.create_transaction
    solvA = @pool.find( "A", @repo )
    transaction.install( solvA )
    solvA = @repo.create_solvable( "A", "2.0-0" )
    transaction.install( solvA )
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_SAME_NAME )
  end
  def test_package_conflict
    transaction = @pool.create_transaction
    solvA = @pool.find( "A", @repo )
    solvB = @pool.find( "B", @repo )
    solvA.conflicts << @pool.create_relation( solvB.name, SatSolver::REL_EQ, solvB.evr )
    solvB.conflicts << @pool.create_relation( solvA.name, SatSolver::REL_EQ, solvA.evr )
    transaction.install( solvA )
    transaction.install( solvB )
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_PACKAGE_CONFLICT )
  end
  def test_package_obsoletes
    transaction = @pool.create_transaction
    solvCC = @pool.find( "CC", @repo )
    solvCC.obsoletes << @pool.create_relation( "A" )
    transaction.install( solvCC )
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_PACKAGE_OBSOLETES )
  end
  def test_providers_not_installable
    transaction = @pool.create_transaction
    solver = @pool.create_solver( @installed )
    solver.solve( transaction )
    assert solve_and_check( solver, transaction, SatSolver::SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE )
  end
end
