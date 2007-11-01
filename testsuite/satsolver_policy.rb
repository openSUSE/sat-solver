#
# Sat solver policy class
#
# Implements policies as singleton methods
#

class SatPolicy
  #
  # print rules before solving ?
  # 
  #
  def self.printrules
    STDERR.puts "printrules?"
    return true
  end
end