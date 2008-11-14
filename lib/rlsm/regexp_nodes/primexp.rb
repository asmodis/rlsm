module RLSM::RENodes
  private
  class PrimExp
    def initialize(parent, str)
      @parent = parent
      if str == '&' or str == ['&']
        @content = '&'
        @null = true
      else
        @content = str.reject { |c| c == '&' }
        @null = false
      end
    end

    def null?
      @null
    end

    def first
      @null ? [] : @content[0,1]
    end

    def last
      @null ? [] : @content[-1,1]
    end

    def follow
      res = []
      
      (1...@content.length).each do |i|
        res << [@content[i-1,1], @content[i,1]]
      end

      res
    end

    def to_s
      @content.to_s
    end

    def lambda?
      @null
    end
    
    def empty?
      @content == '' or @content == []
    end
  end  
end
