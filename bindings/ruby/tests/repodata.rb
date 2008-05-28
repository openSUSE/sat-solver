#
# Check Repodata of Repo
#

$:.unshift ".."

# test Repodata
require 'test/unit'
require 'pathname'
require 'satsolver'

class RepodataTest < Test::Unit::TestCase
  def test_repo_create
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "x86_64"
    repo = pool.add_solv( Pathname( File.dirname( __FILE__ ) ) + "os11-biarch.solv" )
    repo.name = "openSUSE 11.0 Beta3 BiArch"
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
    
    i = 0
    repo.each { |s|
      puts "Solvable #{s}: group #{s['solvable:group']}, time #{s['solvable:buildtime']}, downloadsize #{s['solvable:downloadsize']}, installsize #{s['solvable:installsize']}"
      i += 1
      break if i == 10
    }
  end
end
