# test Patch and Update

$:.unshift "../../../build/bindings/ruby"
require 'pathname'

require 'satsolver'
require '_solv2patches'

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
    
#
# Now match updates to patches
#

patchrepo = pool.create_repo( "patches" )
patches = solv2patches "patches.solv", patchrepo

#
# Build a lookup hash
# 
# Matching N patches to M updates would be a O(NxM) complexity
# hashing patches by package name should reduce this to O(M)
#

updates = Hash.new
patches.each { |patch|
  next if patch.name[0,3] == "lib"
  patch.contains.each { |c|
    l = updates[c.name] || []
    l << [c,patch]
    updates[c.name] = l
  }
}

output = []

#
# Now iterate over all computed package updates
# and match them to patches
# If a patch matches, collect it in 'output'
# If no patch matches, create an artificial one (severty 'normal')
#
count = 0
solver.each_to_update { |o,n|
  count += 1
  l = updates[n.name]             # any patches known for this update ?
  patch = nil
  if l
    l.each { |cp|                 # Y: find exact name,evr match
      c = cp.first
      if n.evr == c.evr
	patch = cp[1]
	break
      end
    }
  end
  unless patch
#    puts "Nothing patches #{n}"
    buildtime = 0 # should be: n.buildtime
    patch = Patch.new( n.name, n.evr, "normal", n.buildtime )
    patch.summary = "Update of #{o.name}-#{o.evr}.#{o.arch}"
    patch.add n.name, n.evr, n.arch
  end
  output << patch
}

final = output.uniq.sort { |a,b|
  res = a.timestamp <=> b.timestamp
  res = a.name <=> b.name if res == 0
  res
}
puts "Reduced #{count} updates to #{final.size} patches"

final.each { |p|
  puts "#{p.category}: #{p.name}-#{p.evr}  #{p.summary}"
}
