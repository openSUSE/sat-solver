#
# reasons.rb
# test decision reasons
#

$:.unshift "../../../build/bindings/ruby"

require 'test/unit'
require 'satsolver'

class ReasonsTest < Test::Unit::TestCase
  def setup
    @pool = Satsolver::Pool.new
    @pool.arch = "i686"
    @repo = @pool.create_repo( 'test' )
  end
  def test_simple_requires
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    
    rel = @pool.create_relation( "A", Satsolver::REL_EQ, "1.0-0" )
    assert rel
    
    # B-1.0-0 requires A = 1.0-0
    solv2.requires << rel
    assert solv2.requires.size == 1
    
    transaction = @pool.create_transaction
    transaction.install( solv2 )
    
    solver = @pool.create_solver( )
    solver.solve( transaction )
    solver.each_to_install { |s|
      puts "Install #{s}"
    }
    solver.each_to_remove { |s|
      puts "Remove #{s}"
    }

    puts "#{solver.decision_count} decisions"
    solver.each_decision do |d|
      puts "Decision: #{d.solvable}: #{d.op_s} (#{d.reason})"
    end
  end
end
