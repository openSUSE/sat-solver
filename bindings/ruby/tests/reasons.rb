#
# reasons.rb
# test decision reasons
#

puts $:.join("\n")

$:.unshift "../../../build/bindings/ruby"
$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'pathname'
require 'satsolver'

def explain solver
  solver.each_to_install { |s|
    puts "Install #{s}"
  }
  solver.each_to_remove { |s|
    puts "Remove #{s}"
  }
  solver.each_decision do |d|
    puts "Decision: #{d.solvable}: #{d.op_s} (#{d.ruleinfo})"
  end
end

class ReasonsTest < Test::Unit::TestCase
  def setup
    @pool = Satsolver::Pool.new
    @pool.arch = "i686"
    @repo = @pool.create_repo( 'test' )
  end
  
  
  def test_direct_requires
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    
    rel = @pool.create_relation( "A", Satsolver::REL_EQ, "1.0-0" )
    solv2.requires << rel
    
    puts "\n---\nB-1.0-0 requires A = 1.0-0"
    
    request = @pool.create_request
    request.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( request )
    explain solver
  end
  
  
  def test_indirect_requires
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    
    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    solv1.provides << rel
    solv2.requires << rel
    
    puts "\n---\nB-1.0-0 requires a = 42, provided by A-1.0-0"
    
    request = @pool.create_request
    request.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( request )
    explain solver
  end
  
  
  def test_indirect_requires_choose
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    solv3 = @repo.create_solvable( 'C', '1.0-0' )
    
    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    solv1.provides << rel
    solv2.requires << rel
    solv3.provides << rel
    
    puts "\n---\nB-1.0-0 requires a = 42, provided by A-1.0-0 and C-1.0-0"
    
    request = @pool.create_request
    request.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( request )
    explain solver
  end
  
  
  def test_install_bash
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-beta5-i386.solv"
    repo = @pool.add_solv( solvpath )
    repo.name = "beta5"

    puts "\n---\nInstalling bash"
    request = @pool.create_request
    request.install( "bash" )

    @pool.prepare
    solver = @pool.create_solver( )
#    solver.dont_install_recommended = true
    solver.solve( request )
    explain solver
  end
  
  
  def test_conflicts
    installed = @pool.create_repo( 'installed' )
    solv1 = installed.create_solvable( 'A', '1.0-0' )
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    
    @pool.installed = installed

    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    assert rel
    solv1.provides << rel
    solv2.conflicts << rel
    
    puts "\n---\nB-1.0-0 conflicts a = 42, provided by installed A-1.0-0"
    
    request = @pool.create_request
    request.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( request )
    explain solver
  end

  
  def test_obsoletes
    installed = @pool.create_repo( 'installed' )
    solv1 = installed.create_solvable( 'A', '1.0-0' )
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    
    @pool.installed = installed

    rel = @pool.create_relation( "A" )
    solv2.obsoletes << rel
    
    puts "\n---\n#{solv2} obsoletes #{rel}, provided by installed #{solv1}"
    
    request = @pool.create_request
    request.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( request )
    explain solver
  end
  
  
  def test_indirect_removal
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    
    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    solv1.provides << rel
    solv2.requires << rel
    
    puts "\n---\nB-1.0-0 requires a = 42, provided by A-1.0-0. Removal of A should remove B"
    assert solv2.requires.size == 1
    
    @pool.installed = @repo
    
    request = @pool.create_request
    request.remove( solv1 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.allow_uninstall = true
    solver.solve( request )

    explain solver
  end
end
