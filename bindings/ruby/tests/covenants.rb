$:.unshift "../../../build/bindings/ruby"
require 'pathname'

# test Covenants

require 'test/unit'
require 'satsolver'

class CovenantTest < Test::Unit::TestCase
  def test_convenant
    pool = Satsolver::Pool.new "i686"
    assert pool
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    assert repo.size > 0
    repo.name = "test"

    solver = pool.create_solver

    solver.include( "foo" )
      puts "Hi"
      puts "#{repo[0]}"
      puts "Ho"
    solver.include( repo[0] )
    solver.include( Satsolver::Relation.new( pool, "foo", Satsolver::REL_EQ, "42-7" ) )
    solver.exclude( "bar" )
    solver.exclude( repo[1] )
    solver.exclude( Satsolver::Relation.new( pool, "bar", Satsolver::REL_EQ, "42-7" ) )
    assert solver.covenants_count == 6
    solver.each_covenant do |c|
      cmd = case c.cmd
        when Satsolver::INCLUDE_SOLVABLE: "include #{c.solvable}"
	when Satsolver::EXCLUDE_SOLVABLE: "exclude #{c.solvable}"
	when Satsolver::INCLUDE_SOLVABLE_NAME: "include by name #{c.name}"
	when Satsolver::EXCLUDE_SOLVABLE_NAME: "exclude by name #{c.name}"
	when Satsolver::INCLUDE_SOLVABLE_PROVIDES: "include by relation #{c.relation}"
	when Satsolver::EXCLUDE_SOLVABLE_PROVIDES: "exclude by relation #{c.relation}"
	else "<NONE>"
	end
      puts cmd
    end
    solver.covenants_clear!
    assert solver.covenants_empty?
  end
end
