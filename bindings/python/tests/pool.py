#
# The Pool is the main data structure for sat-solver.
#
# It contains all solvables, grouped by Repo(sitorie)s
# and is needed to create instances of other classes.
#
# For Solvable, Repo, Transaction, Solver and Relation,
# Pool provides create_... methods as counterparts to
# the instance contructors, all requiring a Pool argument.
#
# The main object within a Pool is the Solvable. So Pool.size,
# Pool.each, Pool.get (resp. Pool[]) and Pool.find all operate
# on Solvables.
#
# For Repos there is each_repo, count_repos, get_repo and find_repo.
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

class TestSequenceFunctions(unittest.TestCase):
    def testpool(self):
        pool = satsolver.Pool()
        assert pool
        assert pool.count_repos() == 0
        
    def testpool1(self):
        pool = satsolver.Pool()
        assert pool
        pool.set_arch("i686")
    
    def testpool2(self):
        pool = satsolver.Pool("i686")
        assert pool
                
if __name__ == '__main__':
  unittest.main()
