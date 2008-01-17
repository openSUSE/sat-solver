#!/usr/bin/env ruby
#
# runtest.rb
#
# ruby script to run zypp/libredcarpet testcases
#
# Usage:
#  runtest.rb <testcase1> [... <testcaseN>]
#     run one or more test cases
#  runtest.rb [-r] <dir>
#     run all test cases (*test.xml) below a specific directory
#     if -r is given, recursively descend to sub-directories
#

require 'test/unit'
require 'pp'

$verbose = false
$redcarpet = false

$tests = Array.new
if File.executable?( "./deptestomatic" )
  execdir = Dir.getwd
else
  execdir = "../build/testsuite"
end
$deptestomatic = File.join( execdir, "deptestomatic" )

raise "Cannot find 'deptestomatic' executable. Please fix path in runtest.rb'" unless File.executable?( $deptestomatic )

$topdir = Dir.getwd
$fails = Array.new
$ignorecount = 0

class CompareResult
  Incomplete = 0
  KnownFailure = 1
  UnexpectedFailure = 2
  KnownPass = 3
  UnexpectedPass = 4
end

class Solution

  # poor mans diff
  def Solution.filediff name1, name2
    begin
      f1 = File.new( name1, "r" )
    rescue
      STDERR.puts "Cannot open #{name1}"
      return false
    end
    begin
      f2 = File.new( name2, "r" )
    rescue
      STDERR.puts "Cannot open #{name2}"
      return false
    end
    a1 = f1.readlines
    a2 = f2.readlines
    i = 0
    a1.each { |l1|
      if (l1 =~ /unflag/)
	next
      end
      l2 = a2[i]
      if (l2 =~ /unflag/)
	i += 1
	retry
      end
      if l2
	if (l1 != l2)
	  puts "- #{l1}"
	  puts "+ #{l2}"
	end
      else
#	puts "- #{l1}"
      end
      i += 1
    }
    while i < a2.size
      puts "+ #{a2[i]}"
      i += 1
    end
  end

  def Solution.read fname
    solutions = Array.new
    solution = nil
    problemFound = false
    
    # read solution and filter irrelevant lines
    IO.foreach( fname ) { |l|
      l = l + "\n"
      case l.chomp!
      when /Solution \#([0-9]+):/
	if solution && !solution.empty?
	   if problemFound
	      solutions << solution # no sorting
           else
	      solutions << solution.sort!
	   end 
        end
	solution = Array.new
	problemFound = false
      when /Problem ([0-9]+):/
	if solution && !solution.empty?
	   if problemFound
	      solutions << solution # no sorting
           else
	      solutions << solution.sort!
	   end 
        end
	solution = Array.new
	problemFound = true
      when /> install /, /> upgrade /, /> remove /
	STDERR.puts "No 'Solution' in #{fname}" unless solution
	solution << l
      else
	if problemFound
	   solution << l
        end
      end
    }
    
    # last entry insert
    if solution && !solution.empty?
       if problemFound
	      solutions << solution # no sorting
       else
	      solutions << solution.sort!
       end 
    end

    solutions
  end

  # compare solution s with result r
  def Solution.compare sname, rname
    unless File.readable?( sname )
      return CompareResult::Incomplete
    end
    unless File.readable?( rname )
      STDERR.puts "Cannot open #{rname}"
      return CompareResult::Incomplete
    end

    solutions = Solution.read sname
    results = Solution.read rname

    if (solutions.empty? && results.empty?)
      if ( $fails.member?( rname ) )
	STDERR.puts "#{rname} passed"
	return CompareResult::UnexpectedPass
      else
	return CompareResult::KnownPass  
      end
    end

    # solutions,results is an array of sulutions AND problems
    # As the SAT solver does returns only one sulution and one or more
    # problems ALL these entries has to fit to the given solution

    if solutions.size == results.size
       solutionFit = false
       results.each { |r|
          solutionFit = false
          solutions.each { |s|
	     if s == r
	        solutionFit = true
                break
             end
          }
       }
       if solutionFit
	   if ( $fails.member?( rname ) )
	     STDERR.puts "#{rname} passed"
	     return CompareResult::UnexpectedPass
	   else
	     return CompareResult::KnownPass  
	   end
       end
    else
       if $verbose
         puts "The number of results does not fit to the number of given solutions."
       end
    end

    if ( $fails.member?( rname ) )
      return CompareResult::KnownFailure
    end

    case sname
    when /\.solution([2-9]+)$/
      # we print error with solution1
      return CompareResult::UnexpectedFailure
    end


    STDERR.puts "#{rname} failed"
    if $verbose
	Solution.filediff( sname, rname)
#      system( "diff -U 0 #{sname} #{rname}")
    end
    return CompareResult::UnexpectedFailure
  end

end


class Tester < Test::Unit::TestCase
  
  def test_run
    upassed = 0
    epassed = 0
    ufailed = 0
    efailed = 0
    puts "#{$tests.size} tests ahead"
    $tests.sort!
    $tests.each { |test|
      if $verbose
         puts "Testing #{test}"
      end
      basename = File.basename(test, ".xml")
      #print "."
      #STDOUT.flush
      dir = File.dirname(test)
      args = ""
      args = "--redcarpet" if $redcarpet
      if ( system( "#{$deptestomatic} #{args} #{dir}/#{basename}.xml > #{dir}/#{basename}.result" ) )
        sname = File.join( dir, "#{basename}.solution" )
        rname = File.join( dir, "#{basename}.result" )
	result = Solution.compare( sname, rname )
	if result == CompareResult::Incomplete
	  sname = File.join( dir, "#{basename}.solution3" )
	  result = Solution.compare( sname, rname )
	  case result
	  when CompareResult::UnexpectedFailure, CompareResult::KnownFailure, CompareResult::Incomplete
	    sname = File.join( dir, "#{basename}.solution2" )
	    result = Solution.compare( sname, rname )
	  end
	  case result
	  when CompareResult::UnexpectedFailure, CompareResult::KnownFailure, CompareResult::Incomplete
	    sname = File.join( dir, "#{basename}.solution1" )
	    result = Solution.compare( sname, rname )
	  end
	end
	if result == CompareResult::Incomplete
	  puts "#{test} is incomplete"
	end
	case result
	when CompareResult::UnexpectedFailure
	  ufailed += 1
	when CompareResult::UnexpectedPass
	  upassed += 1
	when CompareResult::KnownFailure
	  efailed += 1
	when CompareResult::KnownPass
	  epassed += 1
	end
#        assert(  )
#      puts "(cd #{File.dirname(test)}; #{$deptestomatic} #{basename}.xml > #{basename}.result)" 
      else
	puts "#{test} is incomplete"
      end
    }
    puts "\n\t==> #{$tests.size} tests: (#{epassed}/#{upassed}) passed, (#{efailed}/#{ufailed}) failed, #{$ignorecount} ignored <==\n"
  end
end

class Runner
 
  def run wd, arg, recurse=nil
    fullname = File.join( wd, arg )
    if File.directory?( fullname )
      rundir( fullname, recurse ) 
    elsif (arg =~ /test.xml$/)
#         puts "Run #{fullname}"
      $tests << fullname
    end
  end
  
  # process current directory
  #
  def rundir path, recurse
    #puts "Rundir #{path}"
    ignores = Array.new
    ignorefile = File.join( path, "ignore" )
    if File.readable?( ignorefile )
      IO.foreach( ignorefile ) { |line|
	line.chomp!
	if ( line !~ /^\s/ && line !~ /^#/ )
	  ignores << line
	end
      }
    end
    
    dir = Dir.new( path )

    dir.each { |name|
      if File.directory?( name )
	rundir File.join( path, name ), recurse if recurse
      else
	#puts name, $ignores.member?(name)
	if !ignores.member?(name)
	  run path, name
	else
	  $ignorecount += 1
	end
      end
    }
    
  end
  
end

#----------------------------

def usage err=nil
  STDERR.puts "** Error: #{err}" if err
  STDERR.puts "Usage:"
  STDERR.puts "\truntest.rb <testcase1> [... <testcaseN>]"
  STDERR.puts "\t\trun one or more test cases"
  STDERR.puts "\truntest.rb [-r] <dir>"
  STDERR.puts "\t\trun all test cases (*test.xml) below a specific directory"
  STDERR.puts "\t\tif -r is given, recursively descend to sub-directories"
  exit 1
end

#------
# main

puts "Running in #{Dir.getwd}"

if ARGV.first == "--redcarpet"
  $redcarpet = true
  ARGV.shift
end

if ARGV.first == "-r"
  recurse = true
  ARGV.shift
end

if ARGV.first == "-v"
  $verbose = true
  ARGV.shift
end

if File.readable?("README.FAILS")
  IO.foreach( "README.FAILS") { |line|
    line.chomp
    if ( line !~ /^\s/ )
      line = line[0..-6] + ".result"
      $fails << line
    end
  }
end

r = Runner.new

ARGV.each { |arg|
  wd = "." unless arg[0,1] == "/"
  r.run wd, arg, recurse
}
