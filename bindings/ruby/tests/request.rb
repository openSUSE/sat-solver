$:.unshift "../../../build/bindings/ruby"
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
      cmd = case a.cmd
            when Satsolver::INSTALL_SOLVABLE: "install #{a.solvable}"
	    when Satsolver::REMOVE_SOLVABLE: "remove #{a.solvable}"
	    when Satsolver::INSTALL_SOLVABLE_NAME: "install by name #{a.name}"
	    when Satsolver::REMOVE_SOLVABLE_NAME: "remove by name #{a.name}"
	    when Satsolver::INSTALL_SOLVABLE_PROVIDES: "install by relation #{a.relation}"
	    when Satsolver::REMOVE_SOLVABLE_PROVIDES: "remove by relation #{a.relation}"
	    else "<NONE>"
	    end
      puts cmd
    }
    request.clear!
    assert request.empty?
  end
end
