$:.unshift File.expand_path(File.dirname(__FILE__))

require 'monkey_patching/array_ext'

module RLSM
  VERSION = '0.4.0'
end

#Setting up the exception classes.
class RLSMException < Exception; end
class MonoidException < RLSMException; end
class DFAException < RLSMException; end
class REException < RLSMException; end

require 'rlsm/monoid'
require 'rlsm/dfa'
require 'rlsm/re'
