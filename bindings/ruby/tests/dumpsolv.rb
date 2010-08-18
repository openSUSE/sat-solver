#
# dumpsolv.rb
#
# Example code how to use Ruby bindings to implement tools/dumpsolv
#

$:.unshift "../../../build/bindings/ruby"
$:.unshift File.join(File.dirname(__FILE__), "..")
require 'pathname'

require 'satsolver'
require 'pp'

#
# usage() function, called on error
#


def usage reason=nil
  STDERR.puts reason if reason
  STDERR.puts "Usage: dumpsolv <solv-file>"
  exit 1
end

usage if ARGV.size < 1

filename = ARGV[0]

usage "File #{filename} does not exist / is not readable" unless File.exists?( filename)

#
# create pool, load solv to repo
#

pool = Satsolver::Pool.new
repo = pool.add_solv( filename )

usage "No solvables found in #{filename}" if repo.empty?

#
# Give repo a name
#
repo.name = File.basename filename

#
# Display number of solvables
#
puts "#{filename} with #{repo.size} solvables"

puts pool.dump
puts repo.dump
