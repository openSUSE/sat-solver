$: << "../../../build/bindings/ruby"
# test Transction
require 'test/unit'
require 'SatSolver'

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
    transaction.erase( "bar" )
    transaction.erase( repo[1] )
    transaction.erase( SatSolver::Relation.new( pool, "bar", SatSolver::REL_EQ, "42-7" ) )
    assert transaction.size == 6
    transaction.each { |a|
      cmd = case a.cmd
            when SatSolver::INSTALL_SOLVABLE: "install"
	    when SatSolver::ERASE_SOLVABLE: "erase"
	    when SatSolver::INSTALL_SOLVABLE_NAME: "install name"
	    when SatSolver::ERASE_SOLVABLE_NAME: "erase name"
	    when SatSolver::INSTALL_SOLVABLE_PROVIDES: "install relation"
	    when SatSolver::ERASE_SOLVABLE_PROVIDES: "erase relation"
	    else "<NONE>"
	    end
      puts "#{cmd}: #{pool.idname(a.id)}"
    }
    transaction.clear!
    assert transaction.empty?
  end
end
