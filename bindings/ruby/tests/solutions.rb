#
# Solutions provide 'exit strategies' for Problems.
#
# Solutions are enumeratable through Problem.each_solution
#
#

$:.unshift "../../../build/bindings/ruby"
require 'pathname'

# test Solutions
require 'test/unit'
require 'satsolver'

class SolutionTest < Test::Unit::TestCase
  def test_solutions
    pool = Satsolver::Pool.new
    assert pool
    
    installed = pool.create_repo( 'system' )
    assert installed
    installed.create_solvable( 'A', '0.0-0' )
    installed.create_solvable( 'B', '1.0-0' )
    solv = installed.create_solvable( 'C', '2.0-0' )
    solv.requires << Satsolver::Relation.new( pool, "D", Satsolver::REL_EQ, "3.0-0" )
    installed.create_solvable( 'D', '3.0-0' )

    repo = pool.create_repo( 'test' )
    assert repo
    
    solv1 = repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv1.obsoletes << Satsolver::Relation.new( pool, "C" )
    solv1.requires << Satsolver::Relation.new( pool, "B", Satsolver::REL_GT, "2.0-0" )
    
    solv2 = repo.create_solvable( 'B', '2.0-0' )
    assert solv2
    
    solv3 = repo.create_solvable( 'CC', '3.3-0' )
#    solv3.requires << Satsolver::Relation.new( pool, "Z" )
    repo.create_solvable( 'DD', '4.4-0' )

    
    request = pool.create_request
    request.install( solv1 )
    request.remove( "Z" )
    
    pool.installed = installed
    solver = pool.create_solver( )
#    solver.allow_uninstall = true;
#    @pool.debug = 255
    solver.solve( request )
    assert solver.problems?
    puts "Problems found"
    i = 0
  end
end
