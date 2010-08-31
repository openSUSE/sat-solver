# satsolver.rb
#
# picks up Ruby extensions for satsolver-bindings-ruby
#
require 'rbconfig'

require Config::CONFIG['arch']+'/satsolver' # the .so file
require 'satsolver/covenant'
require 'satsolver/dump'
require 'satsolver/job'
require 'satsolver/request'
require 'satsolver/ruleinfo'
