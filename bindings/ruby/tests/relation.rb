$: << "../../../build/bindings/ruby"
# test Relation
require 'test/unit'
require 'satsolver'

class SolvableTest < Test::Unit::TestCase
  def setup
    @pool = SatSolver::Pool.new
    assert @pool
    @repo = SatSolver::Repo.new( @pool, "test" )
    assert @repo
    @pool.arch = "i686"
    @repo = @pool.add_solv( "../../../testsuite/data.libzypp/basic-exercises/exercise-1-packages.solv" )
    assert @repo.size > 0
  end
  def test_relation
    rel = SatSolver::Relation.new( @pool, "A", SatSolver::REL_EQ, "1.0-0" )
    puts "Relation: #{rel}"
    @repo.each { |s|
      unless (s.provides.empty?)
	puts s.provides[0]
      end
      s.provides.each { |p|
	res1 = (p <=> rel)
	puts "#{p} cmp #{rel} => #{res1}"
	res2 = (p =~ rel)
	puts "#{p} match #{rel} => #{res1}"
      }
    }
  end
end
