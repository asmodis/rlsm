require File.join(File.dirname(__FILE__), 'helper')
require File.join(File.dirname(__FILE__), 'dfa')

RLSM::require_extension 'array'
RLSM::require_extension 'monoid'

module RLSM

  # Implements the mathematical idea of a finite monoid.
  class Monoid

    class << self
      # Iterates over each monoid of the given order.
      #
      # @param [Integer] order Specifies over which monoids the method iterates.
      #
      # @raise [RLSMError] The given parameter must be greater than zero.
      #
      # @yield [monoid] A monoid of the given order.
      def each(order)
        each_table(order) { |table| yield new(table,false) }
      end

      # Iterates over each transition table of a monoid of the given order.
      #
      # @param [Integer] order Specifies over which monoids the method iterates.
      #
      # @raise [RLSMError] The given parameter must be greater than zero.
      #
      # @yield [table] An array describing the transition table of a monoid.
      def each_table(order)
        raise RLSMError, "Given order must be > 0" if order <= 0

        if order == 1  #trivial case
          yield [0]
          return
        end
        
        #calculate the permutations once
        permutations = 
          RLSM::ArrayExt::permutations((1...order).to_a).map { |p| p.unshift 0 }

        each_diagonal(order,permutations) do |diagonal|
          each_with_diagonal(diagonal,permutations) do |table|
            yield table
          end
        end
      end
    end

    #The elements of the monoid.
    attr_reader :elements
    
    #The order of the monoid.
    attr_reader :order

    #The transition table of the monoid.
    attr_reader :table

    # Creates a new monoid.
    # @see RLSM::Monoid#initialize
    def self.[](table)
      new(table)
    end

    # Creates a new Monoid from the given table.
    # The table is interpreted as follows:
    #
    # * Case 1: Table is an Array.
    #
    #   It is assumed, that the array is flat and that every entry
    #   is an entry in the transition table. The neutral element must
    #   be described in the first row and column.
    #
    # * Case 2: Table is a String.
    #
    #   The string will be parsed into a flat Array.
    #   If commas are present, the String will be splitted at these,
    #   otherwise it will be splitted at each character.
    #   Whitespaces will be ignored or threted as commas.
    #   After parsing, the resulting array will be treated as in case 1.
    #
    # @example Some different ways to create a Monoid
    #   RLSM::Monoid.new [0,1,1,1]
    #   RLSM::Monoid.new "0110"
    #   RLSM::Monoid.new "01 10"
    #   RLSM::Monoid.new "0,1,1,0"
    #   RLSM::Monoid.new "0,1 1,0"
    #
    # @param [Array,String] table The transition table of the monoid, either as
    #                             a flat Array or a string.
    #
    # @param [Boolean] validate If true, the given table will be validated.
    #
    # @raise [RLSMError] If validate is true and the given table isn't
    #                    associative or has no neutral element or the neutral
    #                    element isn't in the first row and column.
    def initialize(table, validate = true)
      @table = parse(table)
      @order = Math::sqrt(@table.size).to_i
      @elements = @table[0,@order].clone
      @internal = {}
      @elements.each_with_index { |x,i| @internal[x] = i }
      @table.map! { |x| @internal[x] }

      if validate
        if @order == 0
          raise RLSMError, "No elements given."
        end
        
        unless @table.size == @order**2
          raise RLSMError, "Binary operation must be quadratic."
        end

        unless @table.uniq.size == @order
          raise RLSMError, "Number of different elements is wrong."
        end

        enforce_identity_position(@table, @order)

        nat = non_associative_triple
        unless nat.nil?
          err_str = "(#{nat[0]}#{nat[0]})#{nat[0]} != #{nat[0]}(#{nat[1]}#{nat[2]})"
          raise RLSMError, "Associativity required, but #{err_str}."
        end
      end
    end


    # Parses a transition table description.
    #
    # @param [Array,String] table the transition table description.
    # @return [Array] The parsed description.
    def parse(table)
      return table if Array === table

      if table.include?(',')
        table.gsub(/\W/,',').squeeze(',').split(',').reject { |x| x.empty? }
      else
        table.gsub(/\W/,'').scan(/./)
      end
    end
    
    #Calculates the product of the given elements.
    # @return The result of the operation
    # @raise [RLSMError] If at least one of the given elements isn't a element
    #                    of the monoid or too few elements are given.
    def [](*args)
      case args.size
      when 0,1
        raise RLSMError, "At least two elements must be provided."
      when 2
        begin
          @elements[ @table[ @order*@internal[args[0]] + @internal[args[1]] ] ]
        rescue
          raise RLSMError, "Given arguments aren't monoid elements."
        end
      else
        args[0,2] = self[ *args[0,2] ]
        self[*args]
      end
    end

    
    # Transforms monoid into a string.
    #
    # @return [String] The string representation of the monoid.
    def to_s
      result = ""
      sep = @elements.any? { |x| x.to_s.length > 1 } ? ',' : ''
      @table.each_with_index do |el,i|
        result += @elements[el].to_s
        if (i+1) % (@order) == 0
          result += ' '
        else
          result += sep unless i = @order**2 - 1
        end
      end

      result
    end

    
    # Transforms monoid into a string for debug purposes.
    #
    # @return [String] The string representation of the monoid.
    def inspect
      "<#{self.class}: #{to_s}>"
    end

    # Tests for monoid equality. Two monoids are equal if the have the same
    # set of elements and the same transition table.
    #
    # @param [Monoid] other The righthand side of the equality test.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the equality check.
    def ==(other)
      return nil unless RLSM::Monoid === other

      @table == other.table and
        @elements == other.elements
    end

    # Checks if this monoid is a proper submonoid (i.e. not equal)
    # of the other one.
    #
    # @param [Monoid] other Righthand side of the inequality test.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the inequality test.
    def <(other)
      return nil unless RLSM::Monoid === other
      return false if @order >= other.order

      @elements.each do |e1|
        @elements.each do |e2|
          begin
            return false if self[e1,e2] != other[e1,e2]
          rescue RLSMError
            return false
          end
        end
      end

      true
    end

    # Checks if this monoid is a submonoid of the other one.
    #
    # @param [Monoid] other Righthand side of the inequality test.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the inequality test.
    def <=(other)
      (self == other) || (self < other)
    end

    # Checks if the other monoid is a proper submonoid (i.e. not equal)
    # of this one.
    #
    # @param [Monoid] other Righthand side of the inequality test.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the inequality test.
    def >(other)
      other < self
    end

    # Checks if the other monoid is a submonoid of this one.
    #
    # @param [Monoid] other Righthand side of the inequality test.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the inequality test.
    def >=(other)
      other <= self
      endy
    end

    # @see RLSM::Monoid#isomorph?
    def =~(other)
      isomorph?(other)
    end

    # Checks if this monoid is isomorph to the other one.
    #
    # @param [Monoid] other Righthand side of the isomorphism check.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the isomorphism check.
    def isomorph?(other)
      return nil unless RLSM::Monoid === other
      isomorphisms(other) { return true }

      false
    end

    # Checks if this monoid is antiisomorph to the other one.
    #
    # @param [Monoid] other Righthand side of the isomorphism check.
    #
    # @return [nil] if other isn't a monoid.
    # @return [Boolean] the result of the antiisomorphism check.
    def antiisomorph?(other)
      return nil unless RLSM::Monoid === other

      antiisomorphisms(other) { return true }

      false
    end

    # Calculates the set of elements which will be generated by the given set.
    #
    # @param [Array] set The elements which act as generators
    #
    # @return [Array] the generated set.
    #
    # @raise [RLSMError] if one of the elements isn't a monoid element.
    #
    # @see RLSM::Monoid#get_submonoid.
    def generated_set(set)
      gen_set = set | @elements[0,1]
      
      unfinished = true
      
      while unfinished
        unfinished = false

        gen_set.each do |el1|
          gen_set.each do |el2|
            element = self[el1,el2]
            unless gen_set.include? element
              gen_set << element
              unfinished = true
            end
          end
        end
      end
        
      gen_set.sort(&element_sorter)
    end

    # Calculates the set of elements which will be generated by the given set.
    #
    # @param [Array] set The elements which act as generators
    #
    # @return [Monoid] the monoid generated by the given set.
    #
    # @raise [RLSMError] if one of the elements isn't a monoid element.
    #
    # @see RLSM::Monoid#get_generated_set.
    def get_submonoid(set)
      elements = generated_set(set)

      set_to_monoid(elements)
    end

    # Calculates all submonoids.
    #
    # @return [Array] List with all submonoids in it.
    def submonoids
      candidates = get_submonoid_candidates
      candidates.map { |set| set_to_monoid(set) }
    end

    # Calculates all proper submonoids (i.e. all submonoids without the
    # monoid itself and the trivial one).
    #
    # @return [Array] List with all proper submonoids in it.
    def proper_submonoids
      candidates = get_submonoid_candidates.select do |cand| 
        cand.size > 1 and cand.size < @order 
      end

      candidates.map { |set| set_to_monoid(set) }
    end

    # Finds the smallest set which generates the whole monoid
    # (smallest in the sense of cardinality of the set).
    #
    # @return [Array] A set of elements which generates the whole monoid.
    def generating_subset
      sorted_subsets.find { |set| generated_set(set).size == @order }
    end

    # @overload idempotent?
    # Checks if the monoid is idempotent (i.e. all elements are idempotent).
    #
    # @overload idempotent?(element)
    # Checks if given element is idempotent.
    #
    # @return [Boolean] result of the check
    def idempotent?(element = nil)
      if element
        self[element,element] == element
      else
        @elements.all? { |el| idempotent?(el) }
      end
    end

    # Calculates the order of the monoid.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Integer] Order of the given element.
    def order_of(element)
      generated_set([element]).size
    end

    # Calculates the principal right ideal of the given element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] Principle right ideal of the given element.
    def right_ideal(element)
      @elements.map { |el| self[element,el] }.uniq.sort(&element_sorter)
    end

    # Calculates the principal left ideal of the given element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] Principle left ideal of the given element.
    def left_ideal(element)
      @elements.map { |el| self[el,element] }.uniq.sort(&element_sorter)
    end

    # Calculates the principal (twosided) ideal of the given element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] Principle ideal of the given element.
    def ideal(element)
      result = []
      @elements.each do |el1|
        @elements.each do |el2|
          result << self[el1,element,el2]
        end
      end

      result.uniq.sort(&element_sorter)
    end

    # The neutral element of the monoid.
    #
    # @return neutral element of the monoid.
    def identity
      @elements.first
    end

    # Checks if given element is the neutral element.
    #
    # @param element An element of the monoid.
    #
    # @return [Boolean] Result of the check.
    def identity?(element)
      element == identity
    end

    # @overload zero?
    # Checks if the monoid has a zero element.
    #
    # @overload zero?(element)
    # Checks if the given element is the zero element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if element isn't a monoid element
    #
    # @return [Boolean] Result of the check.
    def zero?(element = nil)
      if element
        return false if @order == 1
        @elements.all? do |el| 
          self[el,element] == element and self[element,el] == element
        end
      else
        !!zero
      end
    end

    # Calculates the zero element of the monoid (if it exists).
    #
    # @return [nil] if the monoid has no zero element
    # @return [Object] the zero element
    def zero
      @elements.find { |el| zero?(el) }
    end

    # Checks if the given element is a left zero element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if element isn't a monoid element
    #
    # @return [Boolean] Result of the check.
    def left_zero?(element)
      return false if @order == 1
      @elements.all? { |x| self[element,x] == element }
    end

    # Checks if the given element is a right zero element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if element isn't a monoid element
    #
    # @return [Boolean] Result of the check.
    def right_zero?(element)
      return false if @order == 1
      @elements.all? { |x| self[x,element] == element }
    end

    # Calculates all right zero elements of the monoid.
    #
    # @return [Array] the right zero elements of the monoid.
    def right_zeros
      @elements.select { |el| right_zero?(el) }
    end

    # Calculates all left zero elements of the monoid.
    #
    # @return [Array] the left zero elements of the monoid.
    def left_zeros
      @elements.select { |el| left_zero?(el) }
    end

    # Calculates all idempotent elements of the monoid.
    #
    # @return [Array] the idempotent elements of the monoid.
    def idempotents
      @elements.select { |el| idempotent?(el) }
    end

    # Checks if the monoid is a group.
    #
    # @return [Boolean] Result of the check.
    def group?
      idempotents.size == 1
    end

    # Checks if the monoid is commutative.
    #
    # @return [Boolean] Result of the check.
    def commutative?
      is_commutative
    end

    # Checks if the monoid is monogenic (i.e. generated by a single element).
    #
    # @return [Boolean] Result of the check.
    def monogenic?
      generating_subset.size == 1
    end

    # Calculates the L-class of an element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] L-class of the given element.
    def l_class(element)
      li = left_ideal(element)
      @elements.select { |el| left_ideal(el) == li }
    end

    # Calculates the R-class of an element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] R-class of the given element.
    def r_class(element)
      r = right_ideal(element)
      @elements.select { |el| right_ideal(el) == r }
    end

    # Calculates the J-class of an element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] J-class of the given element.
    def j_class(element)
      d = ideal(element)
      @elements.select { |el| ideal(el) == d }
    end

    # Calculates the H-class of an element.
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] H-class of the given element.
    def h_class(element)
      l_class(element) & r_class(element)
    end
    
    # Calculates the D-class of an element.
    # Synonym for j_class (J and D relation are the same for a finite monoid).
    #
    # @param element An element of the monoid.
    #
    # @raise [RLSMError] if the element isn't a monoid element.
    #
    # @return [Array] D-class of the given element.
    def d_class(element)
      j_class(element)
    end

    # Calculates all R-classes of the monoid.
    #
    # @return [Array] List of all R-classes.
    def r_classes
      not_tested = @elements.dup
      classes = []
      
      until not_tested.empty?
        classes << r_class(not_tested.first)
        not_tested = not_tested.reject { |el| classes.last.include? el }
      end
      
      classes.sort(&subset_sorter)
    end

    # Calculates all L-classes of the monoid.
    #
    # @return [Array] List of all L-classes.
    def l_classes
      not_tested = @elements.dup
      classes = []
      
      until not_tested.empty?
        classes << l_class(not_tested.first)
        not_tested = not_tested.reject { |el| classes.last.include? el }
      end
      
      classes.sort(&subset_sorter)
    end

    # Calculates all J-classes of the monoid.
    #
    # @return [Array] List of all J-classes.
    def j_classes
      not_tested = @elements.dup
      classes = []
      
      until not_tested.empty?
        classes << j_class(not_tested.first)
        not_tested = not_tested.reject { |el| classes.last.include? el }
      end
      
      classes.sort(&subset_sorter)
    end

    # Calculates all H-classes of the monoid.
    #
    # @return [Array] List of all H-classes.
    def h_classes
      not_tested = @elements.dup
      classes = []
      
      until not_tested.empty?
        classes << h_class(not_tested.first)
        not_tested = not_tested.reject { |el| classes.last.include? el }
      end
      
      classes.sort(&subset_sorter)
    end

    # Calculates all D-classes of the monoid.
    #
    # @return [Array] List of all D-classes.
    def d_classes
      j_classes
    end
    
    # Checks if all R-classes of the monoid are singleton sets.
    #
    # @return [Boolean] Result of the check.
    def r_trivial?
      @elements.all? { |el| r_class(el).size == 1 }
    end
    
    # Checks if all L-classes of the monoid are singleton sets.
    #
    # @return [Boolean] Result of the check.
    def l_trivial?
      @elements.all? { |el| l_class(el).size == 1 }
    end

    # Checks if all J-classes of the monoid are singleton sets.
    #
    # @return [Boolean] Result of the check.
    def j_trivial?
      @elements.all? { |el| j_class(el).size == 1 }
    end

    # Checks if all H-classes of the monoid are singleton sets.
    #
    # @return [Boolean] Result of the check.
    def h_trivial?
      @elements.all? { |el| h_class(el).size == 1 }
    end

    # Checks if all D-classes of the monoid are singleton sets.
    #
    # @return [Boolean] Result of the check.
    def d_trivial?
      @elements.all? { |el| d_class(el).size == 1 }
    end
    
    # Checks if the monoid is aperiodic (i.e. H-trivial).
    #
    # @return [Boolean] Result of the check.
    #
    # @see RLSM::Monoid#h_trivial?
    def aperiodic?
      h_trivial?
    end

    # Checks if the given set is a disjunctive subset.
    #
    # @param [Array] set A set of monoid elements
    #
    # @raise [RLSMError] If one of the given elements isn't a monoid element.
    #
    # @return [Boolean] Result of the check.
    def subset_disjunctive?(set)
      tupels = []
      @elements.each do |el1|
        @elements.each do |el2|
	  tupels << [el1, el2]
        end
      end

      tupels.all? do |a,b|
        a == b or tupels.any? do |x,y|
          set.include?(self[x,a,y]) ^ set.include?(self[x,b,y])
        end
      end
    end

    # Calculate a disjunctive subset if one exists.
    #
    # @return [nil] if no disjunctive subset exists.
    # @return [Array] a disjunctive subset.
    def disjunctive_subset
      RLSM::ArrayExt::powerset(@elements).find { |s| subset_disjunctive? s }
    end

    # Calculate all disjunctive subsets.
    #
    # @return [Array] all disjunctive subsets.
    def all_disjunctive_subsets
      RLSM::ArrayExt::powerset(@elements).select { |s| subset_disjunctive? s }
    end

    # Checks if the monoid is syntactic, i.e. if it has a disjunctive subset.
    #
    # @return [Boolean] Result of the check.
    def syntactic?
      !!disjunctive_subset
    end

    #Returns a regular expression which represents a language with a syntactic monoid isomorph to +self+.
    def to_regexp
      to_dfa.to_regexp
    end

    #Returns a DFA which represents a language with a syntactic monoid isomorph to +self+.
    def to_dfa(finals = nil)
      finals = finals || disjunctive_subset || []

      if syntactic?
        unless all_disjunctive_subsets.include? finals
          raise MonoidError, "#{finals} isn't a disjunctive subset."
        end
      end

      string = "}s#{@elements.index(identity)} "

      finals.each do |element|
        string += "*s#{@elements.index(element)} "
      end

      generating_subset.each do |let|
        @elements.each do |start|
          string += "s#{@elements.index(start)}-#{let}->s#{@elements.index(self[start,let])} "
        end
      end

      RLSM::DFA.new string   
    end

    # @overload regular?
    # Checks if the monoid is regular.
    #
    # @overload regular?(a)
    # Checks if given element is regular.
    #
    # @param a an element of the monoid
    # @raise [RLSMError] if given element isn't a monoid element.
    # @return [Boolean] Result of the check.
    def regular?(a=nil)
      if a.nil?
        @elements.all? { |x| regular?(x) }
      else
        @elements.any? { |x| self[a,x,a] == a}
      end
    end

    # Checks if the monoid is inverse.
    #
    # @return [Boolean] Result of the check.
    def inverse?
      regular? and
        idempotents.all? { |x| idempotents.all? { |y| self[x,y] == self[y,x] } }
    end
    

    # Transforms a given subset of the elements to a submonoid.
    #
    # @raise [RLSMError] if set isn't a subset of the monoid elements or the set
    #                    isn't a submonoid.
    # @return [Monoid] the submonoid formed by the given set.
    def set_to_monoid(set)
      description = set.map do |el1|
        set.map { |el2| self[el1,el2] }.join(",")
      end

      RLSM::Monoid[ description.join(' ') ]
    end

    
    # The order in the transition table is the natural order for the elements.
    #
    # @return [Proc] As argument for the sort method, elements will be compared
    #                 by their indices rather than by their names.
    def element_sorter
      Proc.new { |el1,el2| @elements.index(el1) <=> @elements.index(el2)}
    end

    # Subsets are first ordered by size and then lexicographically.
    #
    # @return [Proc] As argument for the sort method, subsets will be sorted
    #                first by size, then lexicographically.
    def subset_sorter
      Proc.new do |set1,set2|
        if set1.size == set2.size
          set1.map { |el| @elements.index(el) } <=> 
            set2.map { |el| @elements.index(el) }
        else
          set1.size <=> set2.size
        end
      end
    end

    # Calculates a list of all subsets and sorts them.
    #
    # @return [Array] List of subsets sorted by size and lexicographically
    def sorted_subsets
      subsets = RLSM::ArrayExt::powerset(@elements)

      subsets.sort(&subset_sorter)
    end

    # Calculates a list of sets of elements which form a submonoid.
    # Sorts the result.
    #
    # @return [Array] List of sets of elements which form a submonoid.
    def get_submonoid_candidates
      submons =  []
      
      RLSM::ArrayExt::powerset(@elements).each do |set|
        candidate = generated_set(set)
        submons << candidate unless submons.include? candidate
      end

      submons.sort(&subset_sorter)
    end

    # Iterates over all isomorphisms form this monoid to the other.
    #
    # @yield [isomorphism] An isomorphism from this monoid to the other.
    def isomorphisms(other)
      return [] if @order != other.order

      RLSM::ArrayExt::permutations(other.elements).map do |perm| 
        map = Hash[*@elements.zip(perm).flatten]

        if @elements.all? { |x| @elements.all? { |y|
              map[self[x,y]] == other[map[x],map[y]]
            } }
          yield map
        end
      end
    end

    # Iterates over all antiisomorphisms form this monoid to the other.
    #
    # @yield [isomorphism] An antiisomorphism from this monoid to the other.
    def antiisomorphisms(other)
      return [] if @order != other.order

      RLSM::ArrayExt::permutations(other.elements).map do |perm| 
        map = Hash[*@elements.zip(perm).flatten]

        if @elements.all? { |x| @elements.all? { |y|
              map[self[x,y]] == other[map[y],map[x]]
            } }
          yield map
        end
      end
    end
    

  end   # of class Monoid
end     # of module RLSM
