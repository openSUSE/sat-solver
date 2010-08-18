#
# satsolver/request.rb
#

module Satsolver
  class Request
    def to_s
      case cmd
      when INSTALL_SOLVABLE: "install #{solvable}"
      when REMOVE_SOLVABLE: "remove #{solvable}"
      when INSTALL_SOLVABLE_NAME: "install by name #{name}"
      when REMOVE_SOLVABLE_NAME: "remove by name #{name}"
      when INSTALL_SOLVABLE_PROVIDES: "install by relation #{relation}"
      when REMOVE_SOLVABLE_PROVIDES: "remove by relation #{relation}"
      else "<NONE>"
      end
    end
  end
end
