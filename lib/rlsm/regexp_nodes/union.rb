module RLSM::RENodes
  private
  class Union
    def initialize(parent, str)
      @parent = parent
      @childs = _split(str).map do |substr|
        RLSM::RENodes.new(substr,self)
      end
    end

    def null?
      @childs.any? { |child| child.null? }
    end

    def first
      res = []
      @childs.each do |child|
        child.first.each do |f|
          res << f
        end
      end

      res
    end

    def last
      res = []
      @childs.each do |child|
        child.last.each do |l|
          res << l
        end
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
      
      res
    end

    def to_s
      if @parent.nil? or @parent.class == Union or @paarent.class == Star
        return @childs.map { |child| child.to_s }.join('|')
      else
        return '(' + @childs.map { |child| child.to_s }.join('|') + ')'
      end
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
      
      str.each_char do |c|
        state += count[c]
        if c == '|' and state == 0
          res << []
        else
          res.last << c
        end
      end
      
      res#.map { |substr| substr.join }
    end
  end
end
