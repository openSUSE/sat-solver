#
# Search
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

class TestSearchFunctions(unittest.TestCase):

  def test_repo_search(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    for d in repo.search("yast2", satsolver.SEARCH_STRING):
      print d.solvable(), "matches 'yast2' in ", d.key(), ":  ", d.value()
    assert True
    
  def test_repo_search_files(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    for d in repo.search("/usr/bin/python", satsolver.SEARCH_STRING|satsolver.SEARCH_FILES):
      print d.solvable(), "matches '/usr/bin/python' in ", d.key(), ":  ", d.value()
    assert True

if __name__ == '__main__':
  unittest.main()
