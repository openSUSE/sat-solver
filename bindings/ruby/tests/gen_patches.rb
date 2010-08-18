$:.unshift "../../../build/bindings/ruby"
$:.unshift File.join(File.dirname(__FILE__), "..")
require 'pathname'

#
#
# Generate 'code11 patches' from code10 patch repo
#

require 'satsolver'
require '_patch'
require '_solv2patches'

pool = Satsolver::Pool.new( "x86_64" )
repo = pool.create_repo( "patches" )

patches = solv2patches "patches.solv", repo 
patches.each { |p| puts p }
