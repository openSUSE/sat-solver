#!/usr/bin/env ruby
#
# gen-data.rb
#
# ruby script to generated test data directory tree
#  from zypp/libredcarpet 'data.deptestomatic' directory
#
# Usage:
#  gen-data.rb <path-to-test-data> <toplevel-name-of-local-data>
#
# It will
#  - recursively descend the test-data directory
#  - recreate the same hierachy below local-data
#  - convert all *-packages*.xml[.gz] files to .solv files
#  - convert all *-system*.xml[.gz] files to .solv files
#  - copy all *-test*.xml files
#  - convert all *.solution files

class Recurse
  def initialize from_dir, dest_dir
    raise "<origin> is not a directory" unless File.directory?( from_dir )
    @from = Dir.new( from_dir )               # absolute path to origin
    Dir.mkdir( dest_dir ) unless File.directory?( dest_dir )
    @dest = Dir.new( dest_dir )               # absolute path to destination
    @path = ""                                # relative path within
  end

private
  
  def check_name name
    case name
    when /-test/
      "cat"
    else
      "|../../build/tools/helix2solv"
    end
  end
  
  def process_file name
    dots = name.split "."
    #return if dots.size < 2
    cmd = nil
    srcdir = File.join( @from.path, @path )
    srcname = File.join( srcdir, name )
    suffix = nil
    destdir = File.join( @dest.path, @path )
    case dots.last
    when /solution/                       # some are named .solution1
      cmd = "cat #{srcname}"
      suffix = dots.last
      return if File.exists?( File.join( destdir, name ) )
    when /ignore/ 
      cmd = "cat #{srcname}"
      return if File.exists?( File.join( destdir, name ) )
    when /modalias/
      cmd = "cat #{srcname}"
    when "bz2"
      chk = check_name name
      return unless chk
      cmd = "bzcat #{srcname} "
      cmd += chk
      suffix = "solv"
      name = File.basename name, ".bz2"
    when "gz"
      chk = check_name name
      return unless chk
      cmd = "zcat #{srcname} "
      cmd += chk
      suffix = "solv"
      name = File.basename name, ".gz"
    when "xml"
      cmd = check_name name
      return unless cmd
      if cmd[0,1] == "|"
	cmd = "cat #{srcname} " + cmd
	suffix = "solv"
      else
	cmd += " #{srcname}"
	suffix = "xml"
	return if File.exists?( File.join( destdir, name ) )
      end
    else
      return
    end
    destname = File.basename name, ".*"
    destname += ".#{suffix}" if suffix
    cmd += " > "
    fulldest = File.join( destdir, destname )
    cmd += fulldest
    puts "*** FAILED: #{fulldest}" unless system cmd
  end
  
  def process_dir name
    return if name[0,1] == "."
    print "#{name} "
    STDOUT.flush
    start = @path
    @path = File.join( @path, name )
    process
    @path = start
  end

public
  # process current directory
  #
  def process
    from = Dir.new( File.join( @from.path, @path ) )
    dest = File.join( @dest.path, @path )
    Dir.mkdir dest unless File.directory?( dest )
    Dir.new( dest )
    
    from.each { |fname|
      if File.directory?( File.join( from.path, fname ) )
	process_dir fname
      else
	process_file fname
      end
    }
    
  end
  
end

def recurse path
  return unless File.directory?( path )
  dir = Dir.new path
  dir.each{ |fname|
    next if fname[0,1] == '.'
    fullname = dir.path + "/" + fname
    if File.directory?( fullname )
      #puts "Dir #{fullname}"
      next unless recursive
      if tags.include?( fname )
	STDERR.puts "Directory #{fname} already seen, symlink loop ?"
	next
      end
      tags.push fname.downcase
      import( [ Dir.new( fullname ), recursive, tags ] )
      tags.pop
    elsif File.file?( fullname )
      #puts "File #{fullname}"
      args = [ "-t" ]
      args << tags.join(",")
      args << fullname
      add( args )
    else
      STDERR.puts "Unknown file #{fullname} : #{File.stat(fullname).ftype}, skipping"
    end
  }															    
end

#----------------------------

def usage err=nil
  STDERR.puts "** Error: #{err}" if err
  STDERR.puts "Usage:"
  STDERR.puts "\tgen-data.rb <path-to-test-data> <toplevel-name-of-local-data>"
  exit 1
end

#------
# main

test_path = ARGV.shift
usage "<test-path> missing" unless test_path
local_path = ARGV.shift
usage "<local-path> missing" unless local_path

recurse = Recurse.new test_path, local_path
recurse.process
puts
