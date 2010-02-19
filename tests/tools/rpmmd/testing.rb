#!/usr/bin/env ruby

require 'test/unit'
require 'pathname'
require 'yaml'
require 'tmpdir'


SRCPATH = Pathname( File.dirname( __FILE__ ) )
BINPATH = ARGV[0]
TYPE = ARGV[1]
DATA = "#{TYPE}.yaml"

if ARGV.size < 2 || BINPATH == "--help"
  STDERR.puts "Usage: rpmmd_test [<bindir>] [<type>]"
  STDERR.puts "\t<bindir>: cmake binary dir (toplevel)"
  STDERR.puts "\t<type>: loads <type>.xml and compare to <type>.yaml"
  exit 0
end

#
# Called with <bindir> <type>
#

class RpmmdTest < Test::Unit::TestCase
  def setup

    @srcpath = Pathname.new SRCPATH
    assert @srcpath.directory?
    @binpath = Pathname.new BINPATH
    assert @binpath.directory?
    
    $:.unshift( @binpath + File.join("bindings","ruby") )
    require 'satsolver'
    
    @type = TYPE
    @tool = @binpath + File.join("tools","rpmmd2solv")
    assert @tool.executable?
    
    @outpath = @binpath + File.join("tests","tools","rpmmd")
    assert @outpath.directory?
    
    yamlpath = @srcpath + DATA

    @logf = File.open(File.join(Dir.tmpdir,"output"), "w")
    @logf.puts "Testing started at #{Time.now}\n--"
    @logf.puts "@binpath #{@binpath}"
    @logf.puts "@type #{@type}"
    @logf.puts "@tool #{@tool}"
    @logf.puts "@outpath #{@outpath}"
    @logf.puts "yamlpath #{yamlpath}"

    @testdata = YAML.load( File.open( yamlpath ) )
  end
  def teardown
    @logf.puts "--\nTesting ended at #{Time.now}" if @logf
  end
  #
  # test <type>.xml
  #  1. convert it to .solv
  #  2. load .solv
  #  3. assert properties as defined in @testdata YAML hash
  #
  
  def test_tag
    begin
      
      # convert content file to .solv

      inname = @srcpath + "#{@type}.xml"
      solvname = "#{@type}.solv"
      outname = @outpath + solvname
      cmd = "#{@tool} < #{inname} > #{outname}"
      assert system(cmd)
      
      # create the Pool, load the .solv file

      pool = Satsolver::Pool.new
      repo = pool.add_solv outname
      assert_equal @testdata.size, repo.size
      
      # get the solvable
      
      testdata_index = 0

      repo.each do |solvable|
      # loop over YAML hash entries and compare to solvable properties
      assert @testdata.has_key? solvable.name
      @testdata[solvable.name].each do |k,v|
	s = k.to_sym # symbol
	# retrieve property
	if solvable.respond_to?( s )
	  p = solvable.send(s)
	elsif solvable.attr?( k )
	  p = solvable[k]
	else
	  raise "Unknown property/attribute #{k.inspect}"
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
	    v.each do |k,v|
	      #
	      # Convert "<name> <op> <evr>" string to Satsolver::Relation
	      # 
	      nov = v.split " " # split to name,op,version
	      op = Satsolver::REL_NONE
	      
	      case nov[1]
	      when "=", "==":  op = Satsolver::REL_EQ
	      when "<":        op = Satsolver::REL_LT
	      when ">":	       op = Satsolver::REL_GT
	      when "<=":       op = Satsolver::REL_LE
	      when ">=":       op = Satsolver::REL_GE
	      when "<>", "!=": op = Satsolver::REL_NE
	      end
	      
	      if op == Satsolver::REL_NONE
		expected << Satsolver::Relation.new( pool, v )
	      else
		expected << Satsolver::Relation.new( pool, nov[0], op, nov[2] )
	      end
	    end
	    
	    # check equal size of solvable dependencies with expected dependencies
	    assert_equal p.size, expected.size

	    # now loop over the dependencies and check them one-by-one
	    p.each do |rel|
	      rel = Satsolver::Relation.new( pool, rel.name) if rel.op == Satsolver::REL_EQ and rel.evr.empty?
	      raise "Not a relation: #{rel.inspect}" unless expected.include?( rel )
	    end
	  else
	    raise "Don't know what to do with Hash for property/attribute #{k}"
	  end
	when NilClass
	  assert v.nil?
	when TrueClass
	  assert v
	when FalseClass
	  assert !v
	else
	  raise "Can't handle value class #{v.class} of YAML key #{k}"
	end
      end # testdata.each
      testdata_index += 1
    end # repo.each
    rescue Exception => e
      @logf.puts "**ERR #{e}"
      raise e
    end
  end
end
