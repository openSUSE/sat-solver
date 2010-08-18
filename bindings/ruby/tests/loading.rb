#
# Test loading of the bindings
#

$:.unshift "../../../build/bindings/ruby"
$:.unshift File.join(File.dirname(__FILE__), "..")
require 'pathname'

File.open("/tmp/output", "w") { |f|
  f.puts "PWD: #{Dir.pwd}"
}


# test loading of extension
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'satsolver'
    assert true
  end
end
