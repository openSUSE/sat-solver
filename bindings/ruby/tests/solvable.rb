$: << "../../../build/bindings/ruby"
# test Solvable
require 'test/unit'
require 'SatSolver'

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
    puts "#{solv.id}: #{solv.name}-#{solv.evr}.#{solv.arch}[#{solv.vendor}]"
    solv = @pool.id2solvable solv.id
    puts "#{solv.id}: #{solv.name}-#{solv.evr}.#{solv.arch}[#{solv.vendor}]"
  end
  def test_deps
    @pool.each { |s|
      puts s
      show_dep "Provides", s.provides
      show_dep "Requires", s.requires
      show_dep "Obsoletes", s.obsoletes
      show_dep "Conflicts", s.conflicts
    }
  end
end
