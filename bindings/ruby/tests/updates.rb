$:.unshift "../../../build/bindings/ruby"
require 'pathname'

# test Updates

require 'satsolver'

pool = Satsolver::Pool.new
pool.arch = "x86_64"

# load _all_ packages as 'installed'
system = pool.add_solv( "packages.solv" )

# now solve, fixing the system
solver = Satsolver::Solver.new( pool, system )
solver.allow_uninstall = true
solver.fix_system = true

pool.prepare
solver.solve( pool.create_request )

removals = []
solver.each_to_remove { |s|
  removals << s
}

puts "#{removals.size} solvables scheduled for removal"

# create new 'system' from old, dropping removals

new_system = pool.create_repo( "new_system" )
system.each { |s|
  new_system << s unless removals.include? s
}

#
# now check new system
#

solver = Satsolver::Solver.new( pool, new_system )
solver.allow_uninstall = true
solver.fix_system = true

pool.prepare
solver.solve( pool.create_request )

# these shouldn't print anything

solver.each_to_install { |s|
  puts "Install #{s}"
}
solver.each_to_remove { |s|
  puts "Remove #{s}"
}

#
# Add the repo with updates
#

updates = pool.add_solv( "updates.solv" )
updates.name = "updates"
  
pool.prepare
solver = Satsolver::Solver.new( pool, new_system )
solver.allow_uninstall = true
solver.update_system = true
solver.fix_system = true

pool.prepare
solver.solve( pool.create_request )
    
count = 0
solver.each_to_install { |s|
  count += 1
}
puts "#{count} installs"

count = 0
solver.each_to_remove { |s|
  count += 1
}
puts "#{count} removals"


count = 0
solver.each_to_update { |o,n|
  count += 1
  puts n
}
puts "#{count} updates"
