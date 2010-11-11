#
# satsolver/covenant.rb
#

module Satsolver
  class Covenant
    def to_s
      case cmd
      when INCLUDE_SOLVABLE: "include #{solvable}"
      when EXCLUDE_SOLVABLE: "exclude #{solvable}"
      when INCLUDE_SOLVABLE_NAME: "include by name #{name}"
      when EXCLUDE_SOLVABLE_NAME: "exclude by name #{name}"
      when INCLUDE_SOLVABLE_PROVIDES: "include by relation #{relation}"
      when EXCLUDE_SOLVABLE_PROVIDES: "exclude by relation #{relation}"
      else "<NONE>"
      end
    end
  end
end
