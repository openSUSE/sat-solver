require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

# test 'installability' of Repo
#
# queues every single package for installation
# and checks if solving succeeds.
#
# Usage:
#
# installable <arch> <solv>...
#
# Multiple solv files can be given and all are added to the pool.
# The last one will be tested.
#

raise "Usage: installable <arch> <solv>..." unless ARGV.size > 1

pool = Satsolver::Pool.new

arch = ARGV.shift
raise "Bad arch" unless ["i386", "i486", "i586","i686","x86_64","ppc","ppc64","ia64","s390", "s390x", "arm","noarch",].include? arch
pool.arch = arch

repo = nil

while (ARGV.size > 0)
  solvname = ARGV.shift
  repo = pool.add_solv( solvname )
  repo.name = solvname
end
  
pool.prepare

repo.each do |s|
  request = Satsolver::Request.new( pool )
  request.install( s )

  solver = Satsolver::Solver.new( pool )
  res = solver.solve( request )
  $stderr.puts "Package #{s} is not installable" unless res
end
