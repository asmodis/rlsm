module RLSM::RENodes
  private
  class Concat
    def initialize(parent, str)
      @parent = parent
      @childs = _split(str).map do |substr|
        RLSM::RENodes.new(substr, self)
      end.reject { |child| child.lambda? }
    end
    
    def null?
      @childs.all? { |child| child.null? }
    end

    def first
      res = []
      @childs.each do |child|
        child.first.each do |f|
          res << f
        end
        
        break unless child.null?
      end

      res
    end

    def last
      res = []
      @childs.reverse.each do |child|
        child.last.each do |f|
          res << f
        end
        
        break unless child.null?
      end
      
      res
    end
    
    def follow
      res = []
      
      @childs.each do |child|
        child.follow.each do |f|
          res << f
        end
      end

      (1...@childs.size).each do |i|
        @childs[i-1].last.each do |l|
          @childs[(i..-1)].each do |ch|
            ch.first.each do |f|
              res << [l,f]
            end
            
            break unless ch.null?
          end
        end
      end
      
      res
    end

    def to_s
      @childs.map { |child| child.to_s }.join
    end
    
    def lambda?
      false
    end

    def empty?
      false
    end

    private
    def _split(str)
      state = 0
      count = Hash.new(0)
      count['('] = 1
      count[')'] = -1
      
      res = [[]]
      previous = nil
      str.each_char do |c|
        state += count[c]
        
        if state == 1 and c == '('
          res << []
          res.last << c
        elsif state == 0 and c == '*'
          if previous == ')'
            res[-2] << c
          else
            res << [res.last.pop, c]
            res << []
          end
        elsif state == 0 and c == ')'
          res.last << c
          res << []
        else
          res.last << c
        end
        
        previous = c
      end
      
      res.select { |subarr| subarr.size > 0 }#.map { |substr| substr.join }
    end
  end
end
