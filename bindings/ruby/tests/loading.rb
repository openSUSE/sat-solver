$: << "../../../build/bindings/ruby"
# test loading of extension
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'SatSolver'
    assert true
  end
end
