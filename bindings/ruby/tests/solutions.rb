#
# Solutions provide 'exit strategies' for Problems.
#
# Solutions are enumeratable through Problem.each_solution
#
#

$:.unshift "../../../build/bindings/ruby"

# test Solutions
require 'test/unit'
require 'satsolver'

class SolutionTest < Test::Unit::TestCase
  def test_solutions
    pool = Satsolver::Pool.new
    assert pool
    
    installed = pool.create_repo( 'system' )
    assert installed
    installed.create_solvable( 'A', '0.0-0' )
    installed.create_solvable( 'B', '1.0-0' )
    solv = installed.create_solvable( 'C', '2.0-0' )
    solv.requires << Satsolver::Relation.new( pool, "D", Satsolver::REL_EQ, "3.0-0" )
    installed.create_solvable( 'D', '3.0-0' )

    repo = pool.create_repo( 'test' )
    assert repo
    
    solv1 = repo.create_solvable( 'A', '1.0-0' )
    assert solv1
    solv1.obsoletes << Satsolver::Relation.new( pool, "C" )
    solv1.requires << Satsolver::Relation.new( pool, "B", Satsolver::REL_GT, "2.0-0" )
    
    solv2 = repo.create_solvable( 'B', '2.0-0' )
    assert solv2
    
    solv3 = repo.create_solvable( 'CC', '3.3-0' )
#    solv3.requires << Satsolver::Relation.new( pool, "Z" )
    repo.create_solvable( 'DD', '4.4-0' )

    
    transaction = pool.create_transaction
    transaction.install( solv1 )
    transaction.remove( "Z" )
    
    solver = pool.create_solver( installed )
#    solver.allow_uninstall = true;
#    @pool.debug = 255
    solver.solve( transaction )
    assert solver.problems?
    puts "Problems found"
    i = 0
    solver.each_problem( transaction ) { |p|
      i += 1
      case p.reason
      when Satsolver::SOLVER_PROBLEM_UPDATE_RULE
	reason = "problem with installed"
      when Satsolver::SOLVER_PROBLEM_JOB_RULE
	reason = "conflicting requests"
      when Satsolver::SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP
	reason = "nothing provides requested"
      when Satsolver::SOLVER_PROBLEM_NOT_INSTALLABLE
	reason = "not installable"
      when Satsolver::SOLVER_PROBLEM_NOTHING_PROVIDES_DEP
	reason = "nothing provides rel required by source"
      when Satsolver::SOLVER_PROBLEM_SAME_NAME
	reason = "cannot install both"
      when Satsolver::SOLVER_PROBLEM_PACKAGE_CONFLICT
	reason = "source conflicts with rel provided by target"
      when Satsolver::SOLVER_PROBLEM_PACKAGE_OBSOLETES
	reason = "source obsoletes rel provided by target"
      when Satsolver::SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE
	reason = "source requires rel but no providers are installable"
      else
	reason = "**unknown**"
      end
      puts "#{i}: [#{reason}] Source #{p.source}, Rel #{p.relation}, Target #{p.target}"
      j = 0
      p.each_solution { |s|
	j += 1
	case s.solution
	when Satsolver::SOLUTION_UNKNOWN
          solution = "None available"
	when Satsolver::SOLUTION_NOKEEP_INSTALLED
          solution = "dont keep installed"
	when Satsolver::SOLUTION_NOINSTALL_SOLV
          solution = "dont install solvable"
	when Satsolver::SOLUTION_NOREMOVE_SOLV
          solution = "dont remove solvable"
	when Satsolver::SOLUTION_NOFORBID_INSTALL
          solution = "dont forbid install"
	when Satsolver::SOLUTION_NOINSTALL_NAME
          solution = "dont install name"
	when Satsolver::SOLUTION_NOREMOVE_NAME
          solution = "dont remove name"
	when Satsolver::SOLUTION_NOINSTALL_REL
          solution = "dont install relation"
	when Satsolver::SOLUTION_NOREMOVE_REL
          solution = "dont remove relation"
	when Satsolver::SOLUTION_NOUPDATE
          solution = "dont update"
	when Satsolver::SOLUTION_ALLOW_DOWNGRADE
          solution = "allow downgrade"
	when Satsolver::SOLUTION_ALLOW_ARCHCHANGE
          solution = "allow architecture change"
	when Satsolver::SOLUTION_ALLOW_VENDORCHANGE
          solution = "allow vendor change"
	when Satsolver::SOLUTION_ALLOW_REPLACEMENT
          solution = "allow replacement"
	when Satsolver::SOLUTION_ALLOW_REMOVE
          solution = "allow removal"
        else
          solution = "**UNKNOWN**"
        end
        puts "  #{j}: [#{solution}] #{s.s1}"
      }
    }
  end
end
