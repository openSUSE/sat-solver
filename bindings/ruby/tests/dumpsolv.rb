#
# dumpsolv.rb
#
# Example code how to use Ruby bindings to implement tools/dumpsolv
#

$:.unshift "../../../build/bindings/ruby"

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


class Satsolverx::Pool
  def dump
    puts "Pool has #{count_repos} repositories, #{size} solvables"
  end
end


class Satsolverx::Repokey
  def dump
    puts "    #{name} (type #{type} size #{size})"
  end
end

class Satsolverx::Repodata
  def dump
    puts "  Repodata #{(location) ? location : '*EMBEDDED*' } has #{keysize} keys"
    each_key { |key| key.dump }
  end
end

class Satsolverx::Relation
  def dump
    puts "   #{to_s}"
  end
end

class Satsolverx::Dependency
  def dump name
    return if empty?
    puts "  #{name}:"
    each { |rel| rel.dump }
  end
end

class Satsolverx::Solvable
  def dump
    puts " Solvable #{name} #{evr} #{arch}"
    puts " Vendor #{vendor}"
    provides.dump "Provides"
    requires.dump "Requires"
    conflicts.dump "Conflicts"
    obsoletes.dump "Obsoletes"
#    each_attr { |attr|
#      pp attr
#    }
  end
end

class Satsolverx::Repo
  def dump
    puts " Repo #{name} refers to #{datasize} subfiles"
    each_data { |data| data.dump }
    puts
    puts " Repo #{name} contains #{size} solvables"
    each { |solvable|
      solvable.dump
      pp solvable[:update_collection_name]
      puts " Name2: #{solvable.attr('solvable:buildtime')}"
      puts
    }
  end
end


#
#  main()
#

usage if ARGV.size < 1

filename = ARGV[0]

usage "File #{filename} does not exist / is not readable" unless File.exists?( filename)

#
# create pool, load solv to repo
#

pool = SatSolver::Pool.new
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

pool.dump
repo.dump