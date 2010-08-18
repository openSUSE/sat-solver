$:.unshift "../../../build/bindings/ruby"
$:.unshift File.join(File.dirname(__FILE__), "..")
require 'pathname'

# test Transction

require 'test/unit'
require 'satsolver'

class RequestTest < Test::Unit::TestCase
  def test_request
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "i686"
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    repo.name = "test1"
    
    request = Satsolver::Request.new( pool )
    assert request
    request.install( "foo" )
    request.install( repo.find "ruby" )
    request.install( Satsolver::Relation.new( pool, "foo", Satsolver::REL_EQ, "42-7" ) )
    request.remove( "bar" )
    request.remove( repo.find "glibc" )
    request.remove( Satsolver::Relation.new( pool, "bar", Satsolver::REL_EQ, "42-7" ) )
    assert request.size == 6
    request.each { |a|
      puts a.to_s
    }
    request.clear!
    assert request.empty?
  end
end
