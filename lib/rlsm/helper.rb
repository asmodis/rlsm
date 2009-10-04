class RLSMError < StandardError; end # :nodoc:
class ParseError < RLSMError; end # :nodoc:
class BinOpError < RLSMError; end # :nodoc:
class MonoidError < RLSMError; end # :nodoc:
class DFAError < RLSMError; end # :nodoc:
class RegExpError < RLSMError; end # :nodoc:

module RLSM
  def self.require_extension(extension)
    require File.join(File.dirname(__FILE__), '..', '..', 'ext', extension, extension + '_cext')
  end
end
