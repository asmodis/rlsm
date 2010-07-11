module RLSM
  module MonoidIterator
    def each(order)
      raise RLSMError, "Given order must be > 0" if order <= 0

      if order == 1  #trivial case
        yield new([0],false)
        return
      end

      elements = (0...order).to_a.map { |x| x.to_s }
      mapping = {}
      elements.each_with_index { |x,i| mapping[x] = i }

      #calculate the permutations once
      permutations = (1...order).to_a.permutations.map { |p| p.unshift 0 }

      each_diagonal(order,permutations) do |diagonal|
        each_with_diagonal(diagonal,permutations) do |table|
          yield new(table,false)
        end
      end
    end
  end
end
