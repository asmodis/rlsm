require File.join(File.dirname(__FILE__), 'helper')
RLSM.require_extension 'binop'

module RLSM
  class BinaryOperation
    class << self; alias original_new new; end
=begin rdoc
Creates a BinaryOperation from given description and validates the result.
Raises a ParseError if validation fails.

The description is of the form
  [<elements>:]<table>
where the optional <elements> part lists the elements on which the binary 
operation acts in the order in which they appear in the table part. 
The elements are seperated by commas. The commas are optional if each 
element is identified by a single letter. no withespaces are allowed in 
an element identifier.

The table part describes the transition table of the binary operation. 
Rows are seperated by at least one whitespace character and elements in 
a row are seperated by commas.  The commas are optional if each element 
is identified by a single letter.
If commas are used in one row to seperate the elements, one must use 
commas in each row.

*Remark*: If the elements part is omitted it is assumed that
the elements are appearing in the right order and all elements
are appearing. This is the case for a monoid with neutral element 
in the first row.

*Examples*
  012 120 201
  012:000 000 000
  x1,x2,x3: x1,x2,x2 x2,x2,x1 x3,x2,x1
  000 000 000   -> error
  0,1,2 120 2,1,0 -> error
=end
    def self.new(description)
      binop = new!(description)
      validate(binop)

      binop
    end

    #Like new, but without validation of the input.
    def self.new!(description)
      original_new *parse(description)
    end

    #:call-seq:
    #  original_new(table,elements,mapping) -> BinaryOperation
    #
    #Creates a BinaryOperation. The arguments are a table an array with elements
    #and a mapping.
    #*Remark*: Use this method only if you know what you're doing. No 
    #validation or argument checking is made. Its primary porpose is to speed up
    #monoid generation in the RLSM::Monoid.each method.
    def initialize(table, elements, mapping)
      @table, @elements, @mapping = table, elements, mapping
      @order = @mapping.size
    end

    #Internal representation of the table.
    attr_reader :table

    #Array with all different elements
    attr_reader :elements
    
    #The number of elements.
    attr_reader :order

    #Maps element names to numbers.
    attr_reader :mapping

    #Calculate the product of +x+ and +y+.
    #
    #If at least one of the given elements is unknown raises an ArgumentError.
    def [](x, y)
      if @mapping[x].nil?
        raise ArgumentError, "Unknown element #{x}"
      elsif @mapping[y].nil?
        raise ArgumentError, "Unknown element #{y}"
      else
        @elements[@table[@mapping[x]*@order + @mapping[y]]]
      end
    end

    #Checks if binary operation is associative.
    def associative?
      !non_associative_triple
    end

    #Checks if binary operation is commutative.
    def commutative?
      is_commutative
    end

    #Checks if the binary operation is associative. If not raises an BinOpError.
    def enforce_associativity
      nat = non_associative_triple

      unless nat.nil?
        err_str = "(#{nat[0]}#{nat[0]})#{nat[0]} != #{nat[0]}(#{nat[1]}#{nat[2]})"
        raise BinOpError, "Associativity required, but #{err_str}."
      end
    end
    
    private
    def self.validate(binop)
      if binop.table.size == 0
        raise ArgumentError, "No elements given."
      end

      if binop.table.size != binop.mapping.size**2
        raise ParseError, "Either to many elements or wrong table format."
      end
    end

    def self.parse(description)
      mapping = {}
      elements = []
      table = []
      if description =~ /\s*:\s*/
        elements = desc2ary(Regexp.last_match.pre_match)
        elements.each_with_index { |el,i| mapping[el] = i }

        desc2ary(Regexp.last_match.post_match).
          each { |el| table << mapping[el] }
      else
        desc2ary(description).each do |element|
          if mapping[element].nil?
            mapping[element] = elements.size
            elements << element
          end

          table << mapping[element]
        end
      end
      
      [table, elements, mapping]
    end

    def self.desc2ary(str)
      if str.include?(',')
        str.gsub(/^\s+/,'').gsub(/,*\s+,*/,',').split(',')
      else
        str.gsub(/\s+/,'').scan(/./)
      end
    end
  end
end
