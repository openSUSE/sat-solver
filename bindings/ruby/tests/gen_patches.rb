$:.unshift "../../../build/bindings/ruby"

#
# Generate 'code11 patches' from code10 patch repo
#

require 'satsolver'
require '_patch'
require '_solv2patches'

patches = solv2patches "patches.solv", "x86_64"
patches.each { |p| puts p }
