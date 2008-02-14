require 'satsolverx'

module Satsolverx
#  class Solvable
#     def to_s
#       "#{id_2str(self.source.pool, name)}-#{id_2str(self.source.pool, vr)}-#{id_2str(self.source.pool, arch)}"
#     end
#  end
  class Solvable
    def Solvable.method_missing(meth, *args)
      puts "Method missing"
      puts "Solvable #{meth.id2name}"
    end
  end
end

module SatSolver
  include Satsolverx
end