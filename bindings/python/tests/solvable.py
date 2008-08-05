#
# test Solvable
#

import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

import satsolver

#
#
#def show_dep name, deps
#  return unless deps
#  puts "    #{deps.size} #{name}: "
#  i = 0
#  while (i < deps.size)
#    d = deps[i]
#    puts "\t#{d.name} : #{d}" 
#    i += 1
#  end
#
#  deps.each { |d|
#    puts "\t#{d.name} #{d.op} #{d.evr}"
#  }
#end

class TestSequenceFunctions(unittest.TestCase):

  def setUp(self):
    self.pool = satsolver.Pool()
    assert self.pool
    self.pool.set_arch("i686")
    self.pool.add_solv( "os11-biarch.solv" )
    assert self.pool.size() > 0
    
  def test_solvable(self):
    solv = self.pool.get(2)
    assert solv
    print solv
    print "%s-%s.%s[%s]" % (solv.name(),solv.evr(),solv.arch(),solv.vendor())

  def test_deps(self):
    return
    for i in range(0,self.pool.size()):
      s = self.pool.get(i)
      print s
      show_dep( "Provides", s.provides())
      show_dep( "Requires", s.requires())
      show_dep( "Obsoletes", s.obsoletes())
      show_dep( "Conflicts", s.conflicts())


  def test_creation(self):
    repo = self.pool.create_repo( 'test' )
    assert repo
    solv1 = repo.create_solvable( 'one', '1.0-0' )
    assert solv1
    assert repo.size() == 1
    assert solv1.name() == 'one'
    assert solv1.evr() == "1.0-0"
    assert solv1.vendor() == None
    solv2 = satsolver.Solvable( repo, 'two', '2.0-0', 'noarch' )
    assert solv2
    assert repo.size() == 2
    assert solv2.name() == 'two'
    assert solv2.evr() == "2.0-0"
    solv2.set_vendor("Ruby")
    assert solv2.vendor() == "Ruby"
    
    rel = satsolver.Relation( self.pool, "two", satsolver.REL_GE, "2.0-0" )
    assert rel
    solv1.requires().add(rel)
    assert solv1.requires().size() == 1
    
    transaction = self.pool.create_transaction()
    transaction.install( solv1 )
    
    solver = self.pool.create_solver( self.pool.create_repo( "system" ) )
#    self.pool.debug = 255
    solver.solve( transaction )
#    solver.each_to_install { |s|
#      puts "Install #{s}"
#    }
#    solver.each_to_remove { |s|
#      puts "Remove #{s}"
#    }


if __name__ == '__main__':
  unittest.main()
