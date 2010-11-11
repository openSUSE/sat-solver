%w(../../../build/bindings/ruby).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end
require 'pathname'
require 'test/unit'
require 'satsolver'
require 'pp'

