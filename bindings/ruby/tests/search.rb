#
# Search
#

$:.unshift "../../../build/bindings/ruby"
require 'pathname'

# test Repodata
require 'test/unit'
require 'satsolver'

class RepodataTest < Test::Unit::TestCase
  #
  # Pool search
  #
  def test_pool_search
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "x86_64"
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    repo.name = "openSUSE 11.0 Beta3 BiArch"
    puts "Repo #{repo.name} loaded with #{repo.size} solvables"
    
    pool.search("yast2", Satsolver::SEARCH_STRING) do |d|
      puts "#{d.solvable} matches 'yast2' in #{d.key.name}:  #{d.value}"
    end
  end
    
  def test_pool_search_files
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "i686"
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    repo.name = "test"
    pool.search("/usr/bin/python", Satsolver::SEARCH_STRING|Satsolver::SEARCH_FILES) do |d|
      puts "#{d.solvable} matches '/usr/bin/python' in #{d.key.name}: #{d.value}"
    end
  end

  #
  # Repo search
  #
  def test_repo_search
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "x86_64"
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    repo.name = "openSUSE 11.0 Beta3 BiArch"
    puts "Repo #{repo.name} loaded with #{repo.size} solvables"
    
    pool.search("yast2", Satsolver::SEARCH_STRING) do |d|
      puts "#{d.solvable} matches 'yast2' in #{d.key.name}: #{d.value}"
    end
  end
    
  def test_repo_search_files
    pool = Satsolver::Pool.new
    assert pool
    pool.arch = "i686"
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-biarch.solv"
    repo = pool.add_solv( solvpath )
    repo.name = "test"
    pool.search("/usr/bin/python", Satsolver::SEARCH_STRING|Satsolver::SEARCH_FILES) do |d|
      puts "#{d.solvable} matches '/usr/bin/python' in #{d.key.name}: #{d.value}"
    end
  end

end