#
# Relations are the primary means to specify dependencies.
# Relations combine names and version through an operator.
# Relations can be compared (<=> operator) or matched (=~ operator)
#
# The following operators are defined:
#   REL_GT: greater than
#   REL_EQ: equals
#   REL_GE: greater equal
#   REL_LT: less than
#   REL_NE: not equal
#   REL_LE: less equal
# Future extensions (not fully defined currently)
#   REL_AND:  and
#   REL_OR:   or
#   REL_WITH: with
#   REL_NAMESPACE: namespace
#
#

$:.unshift "../../../build/bindings/ruby"

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
  def test_relation_accessors
    rel1 = SatSolver::Relation.new( @pool, "A" )
    assert rel1
    assert rel1.name == "A"
    assert rel1.op == 0
    assert rel1.evr == nil
    rel2 = SatSolver::Relation.new( @pool, "A", SatSolver::REL_EQ, "1.0-0" )
    assert rel2
    assert rel2.name == "A"
    assert rel2.op == SatSolver::REL_EQ
    assert rel2.evr == "1.0-0"
  end
  
  def test_relation
    rel = SatSolver::Relation.new( @pool, "A", SatSolver::REL_EQ, "1.0-0" )
    # equivalent: @pool.create_relation( "A", SatSolver::REL_EQ, "1.0-0" )
    assert rel
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
