#
# A Repo (repository) groups Solvables
# A Repo has a name and always belongs to a Pool. The size of a Repo is the number
# of Solvables it contains.
#
# A Repo can be created
#  - from a .solv file
#    repo = Pool.add_solv( "path/to/repo.solv" )
#  - from the rpm database
#    repo = pool.add_rpmdb( "/" )
#  - empty
#    repo = pool.create_repo( "repo name" )
#
# Solvables are added to a Repo by creation. There is no 'add' method, use either
#   Repo.create_solvable( ... )
# or
#   Solvable.new( repo, ... )
#
# Solvables can be retrieved from a Repo by
# - index
#   repo.get( i ) or repo[i]
# - iteration
#   repo.each { |solvable| ... }
# - name
#   repo.find( "A" )
#   this will return the 'best' solvable named 'A' or nil if no such solvable exists.
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

class TestSequenceFunctions(unittest.TestCase):

  def test_repo_create(self):
    pool = satsolver.Pool()
    assert pool
    repo = satsolver.Repo( pool, "test" )
    # equivalent: repo = pool.create_repo( "test" )
    assert repo
    assert repo.size() == 0
    assert repo.name() == "test"

  def test_repo_add(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name("test")
    assert repo.name() == "test"
    assert repo.size() > 0

  def test_deps(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    i = 0
    for s in repo:
      i = i + 1
      if i > 10:
          break
      print s
    assert True
    
  def test_repo_iterate(self):
    pool = satsolver.Pool()
    assert pool
    repoA = pool.create_repo( "testA" )
    repoB = pool.create_repo( "testB" )
    repoC = pool.create_repo( "testC" )
    repoD = pool.create_repo( "testD" )
    assert pool.count_repos() == 4
    for r in pool.repos():
        print r
    assert True

  def test_providers(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("i686")
    repo = pool.add_solv( "os11-biarch.solv" )
    for s in pool.providers("glibc"):
      print s, "provides 'glibc'"
    assert True

if __name__ == '__main__':
  unittest.main()
