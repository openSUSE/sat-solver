#
# Check each_provider callback
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver


class TestSequenceFunctions(unittest.TestCase):
    
  def test_each_provider(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("x86_64")
    repo = pool.add_solv( "../../testdata/os11-biarch.solv" )
    repo.set_name( "openSUSE 11.0 Beta3 BiArch" )
    print "Repo ", repo.name(), " loaded with ", repo.size(), " solvables"
    system = pool.add_rpmdb( "/" )
    system.set_name("@system")
    print "Repo ", system.name(), " loaded with ", system.size(), " solvables"

    pool.prepare()

    i = 0
    for solv in pool.providers("ispell_dictionary"):
      print solv, " provides ispell_dictionary"

    rel = pool.create_relation( "ispell_english_dictionary", satsolver.REL_GT, "3.3.02-23" )
    for solv in pool.providers(rel):
      print solv, solv.repo().name()
      
if __name__ == '__main__':
  unittest.main()
