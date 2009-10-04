require 'rubygems'
require 'shoulda'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rlsm/binary_operation'

class BinaryOperationTest < Test::Unit::TestCase
  context "BinaryOperation::new" do
    should "Require argument" do
      assert_raises ArgumentError do
        RLSM::BinaryOperation.new
      end
    end

    should "Parse a valid description with elements" do
      binop = RLSM::BinaryOperation.new "012:000 000 000"

      assert_equal Hash['0', 0, '1', 1, '2', 2], binop.mapping
      assert_equal %w(0 1 2), binop.elements
      assert_equal 3, binop.order
      assert_equal [0]*9, binop.table
    end

    should "Ignore whitspaces between element seperators" do
      binop = RLSM::BinaryOperation.new "0,   1,2:0,0,0 0,0,  0     0, 0,0"

      assert_equal Hash['0', 0, '1', 1, '2', 2], binop.mapping
      assert_equal %w(0 1 2), binop.elements
      assert_equal 3, binop.order
      assert_equal [0]*9, binop.table
    end

    should "Raise ParseError if some commas are missing" do
      assert_raises ParseError do
        RLSM::BinaryOperation.new "012:0,1,2 210 2,2,2"
      end
    end

    should "Parse commas in the elements part, no commas in table part" do
      binop = RLSM::BinaryOperation.new "0,1,2:000 000 000"

      assert_equal Hash['0', 0, '1', 1, '2', 2], binop.mapping
      assert_equal %w(0 1 2), binop.elements
      assert_equal 3, binop.order
      assert_equal [0]*9, binop.table
    end

    should "Parse commas in the table part, no commas in elements part" do
      binop = RLSM::BinaryOperation.new "012:0,0,0 0,0,0 0,0,0"

      assert_equal Hash['0', 0, '1', 1, '2', 2], binop.mapping
      assert_equal %w(0 1 2), binop.elements
      assert_equal 3, binop.order
      assert_equal [0]*9, binop.table
    end

    should "Raise ParseError if too many elements are given." do
      assert_raises ParseError do
        RLSM::BinaryOperation.new "012:0,1,3 210 2,2,2"
      end
    end

    should "Raise ParseError if too few elements are given." do
      assert_raises ParseError do
        RLSM::BinaryOperation.new "000 000 000"
      end
    end

    should "Raise ParseError if table format is wrong." do
      assert_raises ParseError do
        RLSM::BinaryOperation.new "012:0,1,2 2,1 2,2,2"
      end
    end

    should "Parse a monoid with neutral element in first row." do
      binop = RLSM::BinaryOperation.new "0123 1230 2301 3012"

      assert_equal Hash['0', 0, '1', 1, '2', 2, '3', 3], binop.mapping
      assert_equal %w(0 1 2 3), binop.elements
      assert_equal 4, binop.order
      assert_equal [0,1,2,3,1,2,3,0,2,3,0,1,3,0,1,2], binop.table
    end
  end

  context "BinaryOperation#associative?" do
    should "Return true if binary operation is associative." do
      assert_equal true, RLSM::BinaryOperation.new("01:00 00").associative?
    end

    should "Return false if binary operation is not associative." do
      assert_equal false, RLSM::BinaryOperation.new("01 00").associative?
    end
  end

  context "BinaryOperation#commutative?" do
    should "Return true if binary operation is commutative." do
      assert_equal true, RLSM::BinaryOperation.new("012 111 211").commutative?
    end

    should "Return false if binary operation is not commutative." do
      assert_equal false, RLSM::BinaryOperation.new("012 111 222").commutative?
    end
  end

  context "BinaryOperation#enforce_associativity" do
    should "Raise BinOpError for nonassociative binary operation." do
      assert_raises BinOpError do
        RLSM::BinaryOperation.new("01 00").enforce_associativity
      end
    end

    should "Do nothing for assovityive binary operation." do
      assert_nothing_raised do
        RLSM::BinaryOperation.new("01 10").enforce_associativity
      end
    end
  end
end
