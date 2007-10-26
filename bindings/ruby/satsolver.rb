require 'satsolverx'

module Satsolver
  include Satsolverx

  class Pool
    def addsource_solv( fp, s);
      pool_addsource_solv(self, fp, s);
    end
  end

end