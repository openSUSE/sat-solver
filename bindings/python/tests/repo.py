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
    for i in range(0,repo.size()):
      print repo.get(i)

    assert True

if __name__ == '__main__':
  unittest.main()
