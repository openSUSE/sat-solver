#
# test Relation
#
# Relations are the primary means to specify dependencies.
# Relations combine names and version through an operator.
# Relations can be compared (<=> operator) or matched (=~ operator)
#
# The following operators are defined:
#   REL_GT: greater than
#   REL_EQ: equals
#   REL_GE: greater equal
#   REL_LT: less than
#   REL_NE: not equal
#   REL_LE: less equal
# Future extensions (not fully defined currently)
#   REL_AND:  and
#   REL_OR:   or
#   REL_WITH: with
#   REL_NAMESPACE: namespace
#
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

class TestSequenceFunctions(unittest.TestCase):
    
  def setUp(self):
    self.pool = satsolver.Pool()
    assert self.pool
    self.repo = satsolver.Repo( self.pool, "test" )
    assert self.repo
    self.pool.set_arch("i686")
    self.repo = self.pool.add_solv( "os11-biarch.solv" )
    assert self.repo.size() > 0

  def test_relation_accessors(self):
    rel1 = satsolver.Relation( self.pool, "A" )
    assert rel1
    assert rel1.name() == "A"
    assert rel1.op() == 0
    assert rel1.evr() == None
    rel2 = satsolver.Relation( self.pool, "A", satsolver.REL_EQ, "1.0-0" )
    assert rel2
    assert rel2.name() == "A"
    assert rel2.op() == satsolver.REL_EQ
    assert rel2.evr() == "1.0-0"

  
  def test_relation(self):
    rel = self.pool.create_relation( "A", satsolver.REL_EQ, "1.0-0" )
    assert rel
    print "Relation: ", rel
    for s in self.repo:
      if not s.provides().empty():
	print "%s provides %s" % (s, s.provides().get(1))

      for p in s.provides():
        if p is not None:
            res1 = cmp(p, rel)
            print p, " cmp ", rel, " => ", res1
            res2 = p.match(rel)
            print p, " match ", rel, " => ", res1

if __name__ == '__main__':
  unittest.main()
