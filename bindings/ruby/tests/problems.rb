require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
#
# In case the Solver cannot find a solution (Solver.problems? true),
# it reports Problems through Solver.each_problem.
#
# A problem is always related to a solver rule.
#
# Linked to each problem is a set of solutions, accessible
# through Problem.each_solution
#
# A solution is a set of elements, each suggesting changes to the initial request.
#

# test Problems
def solve_and_check pool, installed, request
  @pool.installed = @installed
  solver = @pool.create_solver( )
  return true if solver.solve( request )

  i = 0
  solver.each_problem( request ) do |p|
    i += 1
    j = 0
    p.each_ruleinfo do |ri|
      j += 1
      puts "#{i}.#{j}: cmd: #{ri.command_s}\n\tRuleinfo: #{ri}"
      job = ri.job
      puts "\tJob #{job}" if job
    end
  end
  true
end

class ProblemTest < Test::Unit::TestCase
  def setup
    @pool = Satsolver::Pool.new
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
  
  def test_not_installable
    request = @pool.create_request
    solv = @pool.find( "A", @repo )
    solv.requires << @pool.create_relation( "ZZ" )
    request.install( solv )
    assert solve_and_check( @pool, @installed, request )
  end
  def test_nothing_provides
    request = @pool.create_request
    solvA = @pool.find( "A", @repo )
    solvA.requires << @pool.create_relation( "B", Satsolver::REL_GE, "2.0-0" )
    solvB = @pool.find( "B", @repo )
    solvB.requires << @pool.create_relation( "ZZ" )
    request.install( solvA )
    assert solve_and_check( @pool, @installed, request )
  end
  def test_same_name
    request = @pool.create_request
    solvA = @pool.find( "A", @repo )
    request.install( solvA )
    solvA = @repo.create_solvable( "A", "2.0-0" )
    request.install( solvA )
    assert solve_and_check( @pool, @installed, request )
  end
  def test_package_conflict
    request = @pool.create_request
    solvA = @pool.find( "A", @repo )
    solvB = @pool.find( "B", @repo )
    solvA.conflicts << @pool.create_relation( solvB.name, Satsolver::REL_EQ, solvB.evr )
    solvB.conflicts << @pool.create_relation( solvA.name, Satsolver::REL_EQ, solvA.evr )
    request.install( solvA )
    request.install( solvB )
    assert solve_and_check( @pool, @installed, request )
  end
  def test_package_obsoletes
    request = @pool.create_request
    solvCC = @pool.find( "CC", @repo )
    solvCC.obsoletes << @pool.create_relation( "A" )
    request.install( solvCC )
    assert solve_and_check( @pool, @installed, request )
  end
end
