#
# Search
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

class TestSearchFunctions(unittest.TestCase):
  #
  # Pool search
  #
  def test_pool_search(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    i = 0
    for d in pool.search("yast2", satsolver.SEARCH_STRING):
      print d.solvable(), "matches 'yast2' in ", d.keyname(), ":  ", d.value()
      i = i + 1
      if i > 10:
          break;
    assert True
    
  def test_pool_search_files(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    i = 0
    for d in pool.search("/usr/bin/python", satsolver.SEARCH_STRING|satsolver.SEARCH_FILES, None, "solvable:filelist"):
      print d.solvable(), "matches '/usr/bin/python' in ", d.keyname(), ":  ", d.value()
      i = i + 1
      if i > 10:
          break;
    assert True

  #
  # Repo search
  #
  def test_repo_search(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    i = 0
    for d in repo.search("yast2", satsolver.SEARCH_STRING):
      print d.solvable(), "matches 'yast2' in ", d.keyname(), ":  ", d.value()
      i = i + 1
      if i > 10:
          break;
    assert True
    
  def test_repo_search_files(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    i = 0
    for d in repo.search("/usr/bin/python", satsolver.SEARCH_STRING|satsolver.SEARCH_FILES, None, "solvable:filelist"):
      print d.solvable(), "matches '/usr/bin/python' in ", d.keyname(), ":  ", d.value()
      i = i + 1
      if i > 10:
          break;
    assert True

if __name__ == '__main__':
  unittest.main()
