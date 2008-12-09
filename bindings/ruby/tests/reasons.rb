#
# reasons.rb
# test decision reasons
#

$:.unshift "../../../build/bindings/ruby"

require 'test/unit'
require 'pathname'
require 'satsolver'

module Satsolver
  class Rule
    def to_solvable pool, id
      if (id < 0)
	"!#{pool.solvable(-id)}"
      else
	"#{pool.solvable(id)}"
      end
    end
    def to_s
      "p #{p}, d #{d}, w1 #{w1}, w2 #{w2}"
    end
    def solvables pool
      "p #{to_solvable(pool, p)}, d #{to_solvable(pool, d)}, w1 #{to_solvable(pool, w1)}, w2 #{to_solvable(pool, w2)}"
    end
    def to_dep pool
      if d == 0
	if w2 == 0
	  if p == w1
	    if p > 0
	      "install! #{to_solvable(pool, p)}"
	    else
	      "remove! #{to_solvable(pool, -p)}"
	    end
	  else # p != w1
	    "error d = 0, w2 = 0, p #{p} != w1 #{w1}"
	  end
	else # w2 != 0
	  if p == w1
	    if p > 0
	      "or! #{to_solvable(pool, p)}, #{to_solvable(pool, w2)}"
	    else
	      if w2 > 0
		"bin! #{to_solvable(pool, -p)} requires #{to_solvable(pool, w2)}"
	      else
		"bin! #{to_solvable(pool, -p)} obsoletes #{to_solvable(pool, -w2)}"
	      end
	    end
	  else # p != w1
	    "error d = 0, w2 = #{w2}, p #{p} != w1 #{w1}"
	  end
	end
      else # d != 0
	if d > 0
	  if p < 0
	    "req! #{to_solvable(pool, -p)} requires #{to_solvable(pool, d)}, provided by #{to_solvable(pool, w2)}..."
	  else
	    "upd! #{to_solvable(pool, d)} updates #{to_solvable(pool, p)}, provided by #{to_solvable(pool, w2)}..."
	  end
	else # d < 0
	  if p < 0
	    if d == -1
	      "del! #{to_solvable(pool, -p)}"
	    else
	      "cnf! #{to_solvable(pool, -p)} conflicts #{to_solvable(pool, -d)}"
	    end
	  else
	    "error p #{p}, d #{d}, w1 #{w1}, w2 {w2}"
	  end
	end
      end
    end # to_dep
  end # class Rule
end

def explain solver, transaction
  solver.each_to_install { |s|
    puts "Install #{s}"
  }
  solver.each_to_remove { |s|
    puts "Remove #{s}"
  }
  solver.each_decision do |d|
    puts "Decision: #{d.solvable}: #{d.op_s} (#{d.rule.to_dep(@pool) if d.rule})"
    e = solver.explain( transaction, d)
    if e.nil?
      puts "\t unexplainable"
    else
      pis = pi_s e.shift
      rel = e.shift
      src = e.shift
      if src.nil?
	puts "\t #{pis}"
      else
	tgt = e.shift
	if tgt
	  puts "\t [#{src}: #{pis} #{rel} provided by #{tgt}]"
	else
	  puts "\t [#{src}: #{pis} #{rel}]"
	end
      end
    end
  end
end

# SolverProbleminfo to string
def pi_s pi
  case pi
  when Satsolver::SOLVER_PROBLEM_UPDATE_RULE: "update"
  when Satsolver::SOLVER_PROBLEM_JOB_RULE: "job"
  when Satsolver::SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP: "job nothing provides"
  when Satsolver::SOLVER_PROBLEM_NOT_INSTALLABLE: "solvable not installable"
  when Satsolver::SOLVER_PROBLEM_NOTHING_PROVIDES_DEP: "nothing provides"
  when Satsolver::SOLVER_PROBLEM_SAME_NAME: "same name"
  when Satsolver::SOLVER_PROBLEM_PACKAGE_CONFLICT: "conflicts"
  when Satsolver::SOLVER_PROBLEM_PACKAGE_OBSOLETES: "obsoletes"
  when Satsolver::SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE: "requires"
  when Satsolver::SOLVER_PROBLEM_SELF_CONFLICT: "self conflict"
  when Satsolver::SOLVER_PROBLEM_RPM_RULE: "rpm rule"
  else
    "unknown (#{pi})"
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
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    
    rel = @pool.create_relation( "A", Satsolver::REL_EQ, "1.0-0" )
    assert rel
    
    puts "\n---\nB-1.0-0 requires A = 1.0-0"
    solv2.requires << rel
    assert solv2.requires.size == 1
    
    transaction = @pool.create_transaction
    transaction.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( transaction )

    explain solver, transaction
  end
  
  def test_indirect_requires
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    
    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    assert rel
    solv1.provides << rel
    
    puts "\n---\nB-1.0-0 requires a = 42, provided by A-1.0-0"
    solv2.requires << rel
    assert solv2.requires.size == 1
    
    transaction = @pool.create_transaction
    transaction.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( transaction )
    explain solver, transaction
  end
  
  
  def test_indirect_requires_choose
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    solv3 = @repo.create_solvable( 'C', '1.0-0' )
    assert solv3
    
    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    assert rel
    solv1.provides << rel
    solv3.provides << rel
    
    puts "\n---\nB-1.0-0 requires a = 42, provided by A-1.0-0 and C-1.0-0"
    solv2.requires << rel
    assert solv2.requires.size == 1
    
    transaction = @pool.create_transaction
    transaction.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( transaction )
    explain solver, transaction
  end
  
  
  def test_install_bash
    solvpath = Pathname( File.dirname( __FILE__ ) ) + Pathname( "../../testdata" ) + "os11-beta5-i386.solv"
    repo = @pool.add_solv( solvpath )
    repo.name = "beta5"

    puts "\n---\nInstalling bash"
    transaction = @pool.create_transaction
    transaction.install( "bash" )

    @pool.prepare
    solver = @pool.create_solver( )
#    solver.dont_install_recommended = true
    solver.solve( transaction )
    explain solver, transaction
  end
  
  
  def test_conflicts
    installed = @pool.create_repo( 'installed' )
    solv1 = installed.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    
    @pool.installed = installed

    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    assert rel
    solv1.provides << rel
    solv2.conflicts << rel
    
    puts "\n---\nB-1.0-0 conflicts a = 42, provided by installed A-1.0-0"
    
    transaction = @pool.create_transaction
    transaction.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( transaction )
    explain solver, transaction
  end

  
  def test_obsoletes
    installed = @pool.create_repo( 'installed' )
    solv1 = installed.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    
    @pool.installed = installed

    rel = @pool.create_relation( "A" )
    assert rel
    solv2.obsoletes << rel
    
    puts "\n---\nB-1.0-0 obsoletes a = 42, provided by installed A-1.0-0"
    
    transaction = @pool.create_transaction
    transaction.install( solv2 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.solve( transaction )
    explain solver, transaction
  end
  
  
  def test_indirect_removal
    solv1 = @repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv2 = @repo.create_solvable( 'B', '1.0-0' )
    assert solv2
    
    rel = @pool.create_relation( "a", Satsolver::REL_EQ, "42" )
    assert rel
    solv1.provides << rel
    
    puts "\n---\nB-1.0-0 requires a = 42, provided by A-1.0-0. Removal of A should remove B"
    solv2.requires << rel
    assert solv2.requires.size == 1
    
    @pool.installed = @repo
    
    transaction = @pool.create_transaction
    transaction.remove( solv1 )
    
    @pool.prepare
    solver = @pool.create_solver( )
    solver.allow_uninstall = true
    solver.solve( transaction )

    explain solver, transaction
  end
end
