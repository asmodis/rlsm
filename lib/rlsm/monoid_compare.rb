module RLSM
  module MonoidCompare
    #Two monoids are equal if they have the same binary operation on the same set.
    def ==(other)
      return nil unless RLSM::Monoid === other

      @table == other.table and
        @elements == other.elements
    end

    #Checks if +self+ is a proper submonoid of +other+.
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

    #Checks if +self+ is a submonoid of (or equal to) +other+.
    def <=(other)
      (self == other) || (self < other)
    end

    def >(other) #:nodoc:
      other < self
    end

    def >=(other) #:nodoc:
      other <= self
      endy
    end
  end
end
