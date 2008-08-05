#
# Check Repodata of Repo
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver


class TestSequenceFunctions(unittest.TestCase):
    
  def test_repo_create(self):
    pool = satsolver.Pool()
    assert pool
    pool.set_arch("x86_64")
    repo = pool.add_solv( "os11-biarch.solv" )
    repo.set_name( "openSUSE 11.0 Beta3 BiArch" )
    print "Repo ", repo.name(), " loaded with ", repo.size(), " solvables"
    
    print "Repo has ", repo.datasize(), " Repodatas attached"
    assert repo.datasize() > 0
    assert repo.data(-1) == None
    assert repo.data(repo.datasize()) == None
    assert repo.data(repo.datasize()-1)
    for i in range(0, repo.datasize()):
      assert repo.data(i)
    
    repodata = repo.data(0)
    assert repodata
    
    print "Repodata is at ", repodata.location(), " with ", repodata.keysize(), " keys"
    for i in range(0, repodata.keysize()):
        k = repodata.key(i)
        print "  Key ", k.name(), " is ", k.type(), " with ", k.size(), " bytes"
    
    for s in repo:
      print "Solvable %s: group %s, time %s, downloadsize %s, installsize %s" % (s, s.attr('solvable:group'), s.attr('solvable:buildtime'), s.attr('solvable:downloadsize'), s.attr('solvable:installsize'))
      if i == 10:
          break

if __name__ == '__main__':
  unittest.main()

