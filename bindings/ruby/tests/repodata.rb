#
# Check Repodata of Repo
#

$:.unshift "../../../build/bindings/ruby"

# test Repodata
require 'test/unit'
require 'satsolver'

class RepodataTest < Test::Unit::TestCase
  def test_repo_create
    pool = SatSolver::Pool.new
    assert pool
    pool.arch = "x86_64"
    repo = pool.add_solv( "10.3-x86_64.solv" )
    repo.name = "10.3-x86_64"
    puts "Repo #{repo.name} loaded with #{repo.size} solvables"
    
    puts "Repo has #{repo.datasize} Repodatas attached"
    assert repo.datasize > 0
    assert repo.data(-1) == nil
    assert repo.data(repo.datasize) == nil
    assert repo.data(repo.datasize-1)
    repo.each_data { |d|
      assert d
    }
    
    repodata = repo.data(0)
    assert repodata
    
    puts "Repodata is at '#{repodata.location}' with #{repodata.keysize} keys"
    repodata.each_key { |k|
      puts "  Key '#{k.name}' is #{k.type} with #{k.size} bytes"
    }
  end
end
