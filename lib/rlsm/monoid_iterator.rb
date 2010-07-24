module RLSM
  module MonoidIterator
    def each(order)
      raise RLSMError, "Given order must be > 0" if order <= 0

      if order == 1  #trivial case
        yield new([0],false)
        return
      end

      #calculate the permutations once
      permutations =
        RLSM::ArrayExt::permutations((1...order).to_a).map { |p| p.unshift 0 }

      each_diagonal(order,permutations) do |diagonal|
        each_with_diagonal(diagonal,permutations) do |table|
          yield new(table,false)
        end
      end
    end

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
end
