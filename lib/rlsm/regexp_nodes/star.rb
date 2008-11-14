module RLSM::RENodes
  private
  class Star
    def initialize(parent, str)
      @parent = parent
      @child = RLSM::RENodes.new(str[(0..-2)], self)
    end
    
    def null?
      true
    end

    def first
      @child.first
    end

    def last
      @child.last
    end

    def follow
      res = @child.follow

      #Cross of last and first
      first.each do |f|
        last.each do |l|
          res << [l,f]
        end
      end

      res
    end

    def to_s
      if @child.class == PrimExp and @child.to_s.length == 1
        return "#{@child.to_s}*"
      else
        return "(#{@child.to_s})*"
      end
    end

    def lambda?
      false
    end

    def empty?
      false
    end
  end
end
