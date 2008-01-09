$: << "../../../build/bindings/ruby"
# test Transction
require 'test/unit'
require 'satsolver'

class TransactionTest < Test::Unit::TestCase
  def test_transaction
    pool = SatSolver::Pool.new
    assert pool
    pool.arch = "i686"
    repo = pool.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    repo.name = "test"
    puts "repo[0] #{repo[0]}"
    puts "repo[1] #{repo[1]}"
    
    transaction = SatSolver::Transaction.new( pool )
    assert transaction
    transaction.install( "foo" )
    transaction.install( repo[0] )
    transaction.install( SatSolver::Relation.new( pool, "foo", SatSolver::REL_EQ, "42-7" ) )
    transaction.remove( "bar" )
    transaction.remove( repo[1] )
    transaction.remove( SatSolver::Relation.new( pool, "bar", SatSolver::REL_EQ, "42-7" ) )
    assert transaction.size == 6
    transaction.each { |a|
      cmd = case a.cmd
            when SatSolver::INSTALL_SOLVABLE: puts "install a."
	    when SatSolver::REMOVE_SOLVABLE: "remove"
	    when SatSolver::INSTALL_SOLVABLE_NAME: "install by name"
	    when SatSolver::REMOVE_SOLVABLE_NAME: "remove by name"
	    when SatSolver::INSTALL_SOLVABLE_PROVIDES: "install by relation"
	    when SatSolver::REMOVE_SOLVABLE_PROVIDES: "remove by relation"
	    else "<NONE>"
	    end
      puts "#{cmd}: #{a.id}"
    }
    transaction.clear!
    assert transaction.empty?
  end
end
