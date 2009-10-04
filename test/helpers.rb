#Setting up the testing environment
require "rubygems"
require "minitest/unit"
require "minitest/autorun"

#Add the lib dir to the load path
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

#Defining some convinience methods for tests (doesn't want to load the minitest/spec)
#Basically copied from minitest/spec and removed nested describe feature and renamed things
module Kernel
  def context desc, &block
    name  = desc.to_s.split(/\W+/).map { |s| s.capitalize }.join + "Spec"
    cls   = Object.class_eval "class #{name} < MiniTest::Spec; end; #{name}"

    cls.class_eval(&block)
  end
  private :context
end

class MiniTest::Spec < MiniTest::Unit::TestCase
  def initialize name
    super
  end

  def self.before(type = :each, &block)
    raise "unsupported before type: #{type}" unless type == :each
    define_method :setup, &block
  end

  def self.after(type = :each, &block)
    raise "unsupported after type: #{type}" unless type == :each
    define_method :teardown, &block
  end

  def self.test desc, &block
    default_block = lambda { skip "Pending: #{desc}" }
    block = default_block unless block_given?
    
    define_method "test_#{desc.gsub(/\W+/, '_').downcase}", &block     
  end
end

#Adding two IMHO missing assertions.
module MiniTest::Assertions
  def assert_nothing_raised msg = nil, &block
    begin
      yield
    rescue Exception => exception
      msg = message(msg) { exception_details exception, "Expected nothing raises, but" }
      assert false, msg
    else
      pass
    end
  end

  def assert_same_elements expected, actual, msg = nil
    msg = message(msg) { "Expected that #{p expected} and #{p actual} have same elements" }
    assert_equal expected.size, actual.size, msg
    refute expected.uniq!, "assert_same_elements expects unique elements."
    refute actual.uniq!, "assert_same_elements expects unique elements."
    expected.each do |element|
      assert actual.include?(element), msg
    end
  end
end
