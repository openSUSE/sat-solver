#
# satsolver/dump.rb
#

module Satsolver
  class Pool
    def dump
      "Pool has #{count_repos} repositories, #{size} solvables"
    end
  end

  class Repokey
    def dump
      "    #{name} (type #{type} size #{size})"
    end
  end

  class Repodata
    def dump
      res = "  Repodata #{(location) ? location : '*EMBEDDED*' } has #{keysize} keys"
      each_key do |key|
	res << "\n"
	res << key.dump
      end
    end
  end

  class Relation
    def dump
      "   #{to_s}"
    end
  end

  class Dependency
    def dump name
      return if empty?
      res = "  #{name}:"
      each do |rel|
	res << "\n"
	res << rel.dump
      end
    end
  end

  class Solvable
    def dump
      res = " Solvable #{name} #{evr} #{arch}"
      res << "\n"
      res << " Vendor #{vendor}"
      res << "\n"
      res << provides.dump("Provides")
      res << "\n"
      res << requires.dump("Requires")
      res << "\n"
      res << conflicts.dump("Conflicts")
      res << "\n"
      res << obsoletes.dump("Obsoletes")
    end
  end

  class Satsolver::Repo
    def dump
      res = puts " Repo #{name} refers to #{datasize} subfiles"
      each_data do |data|
	res << "\n"
	res << data.dump
      end
      res << "\n"
      res << " Repo #{name} contains #{size} solvables"
      each do |solvable|
	res << "\n"
	res << solvable.dump
	res << solvable[:update_collection_name].to_s
	res << " Name2: #{solvable.attr('solvable:buildtime')}"
      end
    end
  end

end
