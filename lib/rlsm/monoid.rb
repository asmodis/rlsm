require File.join(File.dirname(__FILE__), 'helper')
require File.join(File.dirname(__FILE__), 'dfa')

require File.join(File.dirname(__FILE__), 'monoid_compare')
require File.join(File.dirname(__FILE__), 'monoid_iterator')

RLSM::require_extension 'array'
RLSM::require_extension 'monoid'

module RLSM
  class Monoid
    extend MonoidIterator
        
    attr_accessor :elements, :order, :table

    def self.[](table)
      new(table)
    end
    
    def initialize(table, validate = true)
      @table = parse(table)
      @order = Math::sqrt(@table.size).to_i
      @elements = @table[0,@order].map { |x| x.to_s }
      @internal = {}
      @elements.each_with_index { |x,i| @internal[x] = i }
      @table.map! { |x| @internal[x.to_s] }

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

    def parse(table)
      return table if Array === table

      if table.include?(',')
        table.gsub(/\W/,',').squeeze(',').split(',').reject { |x| x.empty? }
      else
        table.gsub(/\W/,'').scan(/./)
      end
    end
    
    #Calculates the product of the given elements.
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

    def to_s # :nodoc:
      result = ""
      sep = @elements.any? { |x| x.length > 1 } ? ',' : ''
      @table.each_with_index do |el,i|
        result += @elements[el]
        if (i+1) % (@order) == 0
          result += ' '
        else
          result += sep unless i = @order**2 - 1
        end
      end

      result
    end

    def inspect # :nodoc:
      "<#{self.class}: #{to_s}>"
    end

    include MonoidCompare


    #Returns the submonoid generated by +set+.
    #
    #*Remark*: The returned value is only an Array, no Monoid. Use get_submonoid for this.
    def generated_set(set)
      if set.include? @elements.first
        gen_set = set.map { |element| element.to_s }
      else
        gen_set = set.map { |element| element.to_s } | @elements[0,1]
      end

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

    #Returns the submonoid generated by set.
    def get_submonoid(set)
      elements = generated_set(set)

      set_to_monoid(elements)
    end

    #Returns an array of all submonoids (including the trivial monoid and the monoid itself).
    def submonoids
      candidates = get_submonoid_candidates
      candidates.map { |set| set_to_monoid(set) }
    end

    #Returns an array of all proper submonoids. 
    def proper_submonoids
      candidates = get_submonoid_candidates.select do |cand| 
        cand.size > 1 and cand.size < @order 
      end

      candidates.map { |set| set_to_monoid(set) }
    end

    #Returns the smallest set (first in terms of cardinality, then lexicographically) which generates the monoid.
    def generating_subset
      sorted_subsets.find { |set| generated_set(set).size == @order }
    end

    #Checks if +self+ is isomorph to +other+ 
    def =~(other)
      bijective_maps_to(other).any? { |map| isomorphism?(map,other) }
    end

    #Synonym for =~
    def isomorph?(other)
      self =~ other
    end

    #Checks if +self+ is antiisomorph to +other+.
    def antiisomorph?(other)
      bijective_maps_to(other).any? { |map| antiisomorphism?(map,other) }
    end

    #If an argument is given, checks if this element is idempotent. Otherwise checks if the monoid itself is idempotent.
    def idempotent?(element = nil)
      if element
        self[element,element] == element
      else
        @elements.all? { |el| idempotent?(el) }
      end
    end

    #Returns the order of an element.
    def order_of(element)
      generated_set([element]).size
    end

    #Returns the principal right ideal of the element.
    def right_ideal(element)
      @elements.map { |el| self[element,el] }.uniq.sort(&element_sorter)
    end

    #Returns the principal left ideal of the element.
    def left_ideal(element)
      @elements.map { |el| self[el,element] }.uniq.sort(&element_sorter)
    end

    #Returns the principal (twosided) ideal of the element.
    def ideal(element)
      result = []
      @elements.each do |el1|
        @elements.each do |el2|
          result << self[el1,element,el2]
        end
      end

      result.uniq.sort(&element_sorter)
    end

    #Returns the neutral element of the monoid.
    def identity
      @elements.first
    end

    #Checks if +element+ is the neutral element.
    def identity?(element)
      element == identity
    end

    #If a argument is given, checks if +element+ is the zero element. If no arguement is given, checks if a zero element exists.
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

    #Returns the zero element if it exists. Return +nil+ if no zero element exists.
    def zero
      @elements.find { |el| zero?(el) }
    end

    #Checks if +element+ is a left zero element.
    def left_zero?(element)
      return false if @order == 1
      @elements.all? { |x| self[element,x] == element }
    end

    #Checks if +element+ is a right zero element.
    def right_zero?(element)
      return false if @order == 1
      @elements.all? { |x| self[x,element] == element }
    end

    #Returns an array with all right zero elements.
    def right_zeros
      @elements.select { |el| right_zero?(el) }
    end

    #Returns an array with all left zero elements.
    def left_zeros
      @elements.select { |el| left_zero?(el) }
    end

    #Returns an array with all idempotent elements.
    def idempotents
      @elements.select { |el| idempotent?(el) }
    end

    #Checks if the monoid is a group.
    def group?
      idempotents.size == 1
    end

    #Checks if the monoid is commutative.
    def commutative?
      is_commutative
    end

    #Checks if the monoid is monogenic, i.e it is generated by a single element.
    def monogenic?
      generating_subset.size == 1
    end

    #Calculates the L-class of an element.
    def l_class(element)
      li = left_ideal(element)
      @elements.select { |el| left_ideal(el) == li }
    end

    #Calculates the R-class of an element.
    def r_class(element)
      r = right_ideal(element)
      @elements.select { |el| right_ideal(el) == r }
    end

    #Calculates the J-class of an element.
    def j_class(element)
      d = ideal(element)
      @elements.select { |el| ideal(el) == d }
    end

    #Calculates the H-class of an element.
    def h_class(element)
      l_class(element) & r_class(element)
    end

    #Synonym for j_class (in a finite monoid the J and D relation are the same).
    def d_class(element)
      j_class(element)
    end

    #Synonym for h_trivial?.
    def aperiodic?
      h_trivial?
    end

    ##
    # :method: l_classes
    # Returns all L-classes of the monoid.

    ##
    # :method: r_classes
    # Returns all R-classes of the monoid.

    ##
    # :method: j_classes
    # Returns all J-classes of the monoid.

    ##
    # :method: h_classes
    # Returns all H-classes of the monoid.

    ##
    # :method: d_classes
    # Returns all D-classes of the monoid.

    ##
    # :method: l_trivial?
    # Checks if all L-classes consist of one element.

    ##
    # :method: r_trivial?
    # Checks if all R-classes consist of one element.

    ##
    # :method: j_trivial?
    # Checks if all J-classes consist of one element.

    ##
    # :method: h_trivial?
    # Checks if all H-classes consist of one element.

    ##
    # :method: d_trivial?
    # Checks if all D-classes consist of one element.

    ##
    # Method missing magic...
    def method_missing(name) #:nodoc:
      case name.to_s
      when /([jlrhd])_classes/
        green_classes($1)
      when /([jlrhd])_trivial?/
        green_trivial?($1)
      else
        super
      end
    end

    #Checks if the given set is a disjunctive subset.
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

    #Returns a disjunctive subset if any exists. Returns +nil+ otherwise.
    def disjunctive_subset
      @elements.powerset.find { |s| subset_disjunctive? s }
    end

    #Returns an array with all disjunctive subsets.
    def all_disjunctive_subsets
      @elements.powerset.select { |s| subset_disjunctive? s }
    end

    #Checks if the monoid is syntactic, i.e. if it has a disjunctive subset.
    def syntactic?
      !!disjunctive_subset
    end

    #Returns the monoid.
    def to_monoid
      self
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


    def regular?(a=nil)
      if a.nil?
        @elements.all? { |x| regular?(x) }
      else
        @elements.any? { |x| self[a,x,a] == a}
      end
    end

    def inverse?
      regular? and
        idempotents.all? { |x| idempotents.all? { |y| self[x,y] == self[y,x] } }
    end
    
    private
    def set_to_monoid(set)
      description = set.map do |el1|
        set.map { |el2| self[el1,el2] }.join(",")
      end

      RLSM::Monoid[ description.join(' ') ]
    end

    def element_sorter
      Proc.new { |el1,el2| @elements.index(el1) <=> @elements.index(el2)}
    end

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

    def sorted_subsets
      subsets = @elements.powerset

      subsets.sort(&subset_sorter)
    end
    
    def get_submonoid_candidates
      submons =  []
      
      @elements.powerset.each do |set|
        candidate = generated_set(set)
        submons << candidate unless submons.include? candidate
      end

      submons.sort(&subset_sorter)
    end

    def bijective_maps_to(other)
      return [] if @order != other.order

      other.elements.permutations.map do |perm| 
        Hash[*@elements.zip(perm).flatten]
      end
    end

    def isomorphism?(map,other)
      @elements.each do |el1|
        @elements.each do |el2|
          return false if map[self[el1,el2]] != other[map[el1],map[el2]]
        end
      end

      true
    end

    def antiisomorphism?(map,other)
      @elements.each do |el1|
        @elements.each do |el2|
          return false if map[self[el1,el2]] != other[map[el2],map[el1]]
        end
      end

      true
    end

    def green_classes(type)
      not_tested = @elements.dup
      classes = []

      until not_tested.empty?
        classes << self.send((type + '_class').to_sym, not_tested.first)
	not_tested = not_tested.reject { |el| classes.last.include? el }
      end

      classes.sort(&subset_sorter)
    end

    def green_trivial?(type)
      @elements.all? { |el| self.send((type + '_class').to_sym, el).size == 1 }
    end
  end   # of class Monoid
end     # of module RLSM
