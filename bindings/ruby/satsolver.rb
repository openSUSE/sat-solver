require 'satsolverx'

module Satsolverx
#  class Solvable
#     def to_s
#       "#{id_2str(self.source.pool, name)}-#{id_2str(self.source.pool, vr)}-#{id_2str(self.source.pool, arch)}"
#     end
#  end
end

module SatSolver
  include Satsolverx
end