$:.unshift "../../../build/bindings/ruby"

# test Solvable

require 'test/unit'
require 'satsolver'

def show_dep name, deps
  return unless deps
  puts "    #{deps.size} #{name}: "
  i = 0
  while (i < deps.size)
    d = deps[i]
    puts "\t#{d.name} : #{d}" 
    i += 1
  end

  deps.each { |d|
    puts "\t#{d.name} #{d.op} #{d.evr}"
  }
end

class SolvableTest < Test::Unit::TestCase
  def setup
    @pool = SatSolver::Pool.new
    assert @pool
    @pool.arch = "i686"
    @pool.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    assert @pool.size > 0
  end
  def test_solvable
    solv = @pool[2]
    assert solv
    puts solv
    puts "#{solv.name}-#{solv.evr}.#{solv.arch}[#{solv.vendor}]"
  end
  def test_deps
    return
    @pool.each { |s|
      puts s
      show_dep "Provides", s.provides
      show_dep "Requires", s.requires
      show_dep "Obsoletes", s.obsoletes
      show_dep "Conflicts", s.conflicts
    }
  end
  def test_creation
    repo = @pool.create_repo( 'test' )
    assert repo
    solv1 = repo.create_solvable( 'one', '1.0-0' )
    assert solv1
    assert repo.size == 1
    assert solv1.name == 'one'
    assert solv1.evr == "1.0-0"
    assert solv1.vendor.nil?
    solv2 = SatSolver::Solvable.new( repo, 'two', '2.0-0', 'noarch' )
    assert solv2
    assert repo.size == 2
    assert solv2.name == 'two'
    assert solv2.evr == "2.0-0"
    solv2.vendor = "Ruby"
    assert solv2.vendor == "Ruby"
    
    rel = SatSolver::Relation.new( @pool, "two", SatSolver::REL_GE, "2.0-0" )
    assert rel
    solv1.requires << rel
    assert solv1.requires.size == 1
    
    transaction = @pool.create_transaction
    transaction.install( solv1 )
    
    solver = @pool.create_solver( @pool.create_repo( "system" ) )
#    @pool.debug = 255
    solver.solve( transaction )
    solver.each_to_install { |s|
      puts "Install #{s}"
    }
    solver.each_to_remove { |s|
      puts "Remove #{s}"
    }

  end
end
