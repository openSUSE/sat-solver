$:.unshift "../../../build/bindings/ruby"
require 'pathname'

#
# After successful solving, the solver returns a transaction
#
# A Decision consists of a set of steps
#


# test Transaction
require 'test/unit'
require 'satsolver'
require 'ruleinfo'

class TransactionTest < Test::Unit::TestCase
  def test_transaction
    pool = Satsolver::Pool.new
    assert pool
    
    installed = pool.create_repo( 'system' )
    assert installed
    installed.create_solvable( 'A', '0.0-0' )
    installed.create_solvable( 'B', '1.0-0' )
    solv = installed.create_solvable( 'C', '2.0-0' )
    solv.requires << Satsolver::Relation.new( pool, "D", Satsolver::REL_EQ, "3.0-0" )
    installed.create_solvable( 'D', '3.0-0' )
    
    # installed: A-0.0-0, B-1.0-0, C-2.0-0, D-3.0-0
    #  C-2.0-0 requires D-3.0-0
    
    repo = pool.create_repo( 'test' )
    assert repo
    
    solv1 = repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv1.obsoletes << Satsolver::Relation.new( pool, "C" )
    solv1.requires << Satsolver::Relation.new( pool, "B", Satsolver::REL_GE, "2.0-0" )
    
    solv2 = repo.create_solvable( 'B', '2.0-0' )
    assert solv2

    solv3 = repo.create_solvable( 'CC', '3.3-0' )
    solv3.requires << Satsolver::Relation.new( pool, "A", Satsolver::REL_GT, "0.0-0" )
    repo.create_solvable( 'DD', '4.4-0' )

    request = pool.create_request
    request.install( solv3 )
    request.remove( "D" )
    
    pool.installed = installed
    solver = pool.create_solver( )
    solver.allow_uninstall = true;
#    @pool.debug = 255
    solver.solve( request )
    puts "** Problems found" if solver.problems?
    transaction = solver.transaction
    assert transaction
    assert transaction.size > 0
    assert !transaction.empty?
    i = 0
    transaction.each do |step|
      i += 1
      puts "Step #{i}: #{step} #{step.type_s} #{step.solvable}"
    end
  end
end
