#!/usr/bin/env ruby

require 'test/unit'
require 'pathname'
require 'yaml'


SRCPATH = Pathname( File.dirname( __FILE__ ) )
BINPATH = ARGV[0]
TAG = ARGV[1]
DATA = "testdata.yaml"

if BINPATH.nil? || BINPATH == "--help"
  STDERR.puts "Usage: content_test [<bindir> [<tag>]]"
  STDERR.puts "\t<bindir>: cmake binary dir (toplevel)"
  STDERR.puts "\t<tag>: optional tag of content file, content.<tag>"
  STDERR.puts "\t\tif <tag> is omitted, process all content tags listed in 'testdata.yaml'"
  exit 0
end

#
# Called with <bindir> <tag>
#

class ContentTest < Test::Unit::TestCase
  def setup

    @srcpath = Pathname.new SRCPATH
    assert @srcpath.directory?
    @binpath = Pathname.new BINPATH
    assert @binpath.directory?
    
    $:.unshift( @binpath + "bindings/ruby" )
    require 'satsolver'
    
    @tag = TAG
    @tool = @binpath + "tools/susetags2solv"
    assert @tool.executable?
    
    @outpath = @binpath + "tools/tests/content"
    assert @outpath.directory?
    
    yamlpath = @srcpath + DATA

    @logf = File.open("/tmp/output", "w")
    @logf.puts "Testing started at #{Time.now}\n--"
    @logf.puts "@binpath #{@binpath}"
    @logf.puts "@tag #{@tag}"
    @logf.puts "@tool #{@tool}"
    @logf.puts "@outpath #{@outpath}"
    @logf.puts "yamlpath #{yamlpath}"

    @testdata = YAML.load( File.open( yamlpath ) )
  end
  def teardown
    @logf.puts "--\nTesting ended at #{Time.now}" if @logf
  end
  #
  # test content.<tag>
  #  1. convert it to .solv
  #  2. load .solv
  #  3. assert properties as defined in @testdata YAML hash
  #
  
  def test_tag
    begin
      
      # convert content file to .solv

      inname = @srcpath + "content.#{@tag}"
      solvname = "#{@tag}.solv"
      outname = @outpath + solvname
      cmd = "#{@tool} -c #{inname} < /dev/null > #{outname}"
      system cmd
      assert_equal 0, $?
      
      testdata = @testdata[@tag]

      # create the Pool, load the .solv file

      pool = Satsolver::Pool.new
      repo = pool.add_solv outname
      assert_equal testdata.size, repo.size
      
      # get the solvable
      
      testdata_index = 0

      repo.each { |solvable|
      
      # loop over YAML hash entries and compare to solvable properties
      
      testdata[testdata_index].each { |k,v|
	
	s = k.to_sym # symbol
	# retrieve property
	if solvable.respond_to?( s )
	  p = solvable.send(s)
	elsif solvable.attr?( s )
	  p = solvable[s]
	else
	  raise "Unknown property/attribute #{k}"
	end

	case v
	when String, Float
	  assert_equal v.to_s, p.to_s
	when Hash
	  if (p.class == Satsolver::Dependency)
	    #
	    # check dependency relations
	    #	    
	    expected = []
	    v.each { |k,v|
	      #
	      # Convert "<name> <op> <evr>" string to Satsolver::Relation
	      # 
	      nov = v.split " " # split to name,op,version
	      if nov.size == 1
		expected << Satsolver::Relation.new( pool, v )
	      elsif nov.size == 3
		op = Satsolver::REL_NONE
		case nov[1]
		when "=", "=="
		  op = Satsolver::REL_EQ
		when "<"
		  op = Satsolver::REL_LT
		when ">"
		  op = Satsolver::REL_GT
		when "<="
		  op = Satsolver::REL_LE
		when ">="
		  op = Satsolver::REL_GE
		when "<>", "!="
		  op = Satsolver::REL_NE
		else
		  raise "Not a parseable relation operator '#{nov[1]}'"
		end
		expected << Satsolver::Relation.new( pool, nov[0], op, nov[2] )
	      else
		raise "Not a parseable relation '#{v}'"
	      end
	    }
	    
	    # check equal size of solvable dependencies with expected dependencies
	    assert_equal p.size, expected.size

	    # now loop over the dependencies and check them one-by-one
	    p.each { |dep|
	      raise "Not a dependency: #{v}" unless expected.include?( dep )
	    }
	  else
	    raise "Don't know what to do with Hash for property/attribute #{k}"
	  end
	else
	  raise "Can't handle value class #{v.class} of YAML key #{k}"
	end
      } # testdata.each
      testdata_index += 1
    } # repo.each
    rescue Exception => e
      @logf.puts "**ERR #{e}"
      raise e
    end
  end
end
