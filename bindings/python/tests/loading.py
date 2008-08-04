import unittest

import sys
sys.path.insert(0, '../../../build/bindings/python')

class TestSequenceFunctions(unittest.TestCase):
    
  def testloading(self):
    import satsolver


if __name__ == '__main__':
  unittest.main()