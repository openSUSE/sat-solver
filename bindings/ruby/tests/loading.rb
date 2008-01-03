#
# Test loading of the bindings
#

$: << "../../../build/bindings/ruby"
# test loading of extension
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'satsolver'
    assert true
  end
end
