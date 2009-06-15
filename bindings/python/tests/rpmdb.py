#
# Load repository from rpm database
#
#   repo = pool.add_rpmdb( "/root/dir/of/system" )
# will create an unnamed repository by reading the rpm database
# and create a solvable for each installed package.
# Use
#   repo.name = "..."
# to name the repository
#
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

class TestSequenceFunctions(unittest.TestCase):
    
  def test_rpmdb(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_rpmdb( "/" )
    assert repo.size() > 0
    print repo.size(), " installed packages"

    i = 0
    name = None
    for s in pool:
      print s, " Vendor: ", s.vendor()
      if i == 7:
        name = s.name()
      i += 1
      if i > 10:
        break

    s = pool.find( name )
    print "Seventh: ", name, " -> ", s


if __name__ == '__main__':
  unittest.main()
