module RLSM
  module MonoidIterator
    def each(order)
      raise ArgumentError, "Given order must be > 0" if order <= 0

      if order == 1  #trivial case
        yield new(RLSM::BinaryOperation.original_new([0], ['0'], { '0' => 0}))
        return
      end

      elements = (0...order).to_a.map { |x| x.to_s }
      mapping = {}
      elements.each_with_index { |x,i| mapping[x] = i }

      #calculate the permutations once
      permutations = (1...order).to_a.permutations.map { |p| p.unshift 0 }

      each_diagonal(order,permutations) do |diagonal|
        each_with_diagonal(diagonal,permutations) do |table|
          yield new(RLSM::BinaryOperation.original_new(table, elements, mapping))
        end
      end
    end
  end

  module MonoidCompareMethods
    #Two monoids are equal if they have the same binary operation on the same set.
    def ==(other)
      return nil unless RLSM::Monoid === other

      @binary_operation.table == other.binary_operation.table and
        @binary_operation.elements == other.binary_operation.elements
    end

    #Checks if +self+ is a proper submonoid of +other+.
    def <(other)
      return nil unless RLSM::Monoid === other
      return false if @order >= other.order

      @elements.each do |e1|
        @elements.each do |e2|
          begin
            return false if self[e1,e2] != other[e1,e2]
          rescue BinOpError
            return false
          end
        end
      end

      true
    end

    #Checks if +self+ is a submonoid of (or equal to) +other+.
    def <=(other)
      (self == other) || (self < other)
    end

    def >(other) #:nodoc:
      other < self
    end

    def >=(other) #:nodoc:
      other <= self
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

  end

  module MonoidGreenRelations
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

  end

  module MonoidSyntacticStuff
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
  end

  module MonoidSpecialElements
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
      @binary_operation.commutative?
    end

    #Checks if the monoid is monogenic, i.e it is generated by a single element.
    def monogenic?
      generating_subset.size == 1
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
  end

  module MonoidSubmonoidStuff
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
  end
end
