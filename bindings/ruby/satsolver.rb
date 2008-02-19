require 'satsolverx'

module Satsolverx
#  class Solvable
#     def to_s
#       "#{id_2str(self.source.pool, name)}-#{id_2str(self.source.pool, vr)}-#{id_2str(self.source.pool, arch)}"
#     end
#  end
  class Solvable
    def method_missing(meth, *args)
      attr meth.id2name
#      puts "Method missing"
#      puts "Solvable #{meth.id2name}"
    end
  end
end

module SatSolver
  include Satsolverx
end