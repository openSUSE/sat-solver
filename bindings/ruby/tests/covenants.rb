require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class CovenantTest < Test::Unit::TestCase
  def test_convenant
    pool = Satsolver::Pool.new "i686"
    assert pool
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    assert repo.size > 0
    repo.name = "test"

    first = second = nil
    repo.each do |s|
      if first
	second = s
	break
      else
	first = s
      end
    end	
    
    solver = pool.create_solver

    solver.include( "foo" )
    solver.include( first )
    solver.include( Satsolver::Relation.new( pool, "foo", Satsolver::REL_EQ, "42-7" ) )
    solver.exclude( "bar" )
    solver.exclude( second )
    solver.exclude( Satsolver::Relation.new( pool, "bar", Satsolver::REL_EQ, "42-7" ) )
    assert solver.covenants_count == 6
    solver.each_covenant do |c|
      puts c.to_s
    end
    solver.covenants_clear!
    assert solver.covenants_empty?
  end
end
