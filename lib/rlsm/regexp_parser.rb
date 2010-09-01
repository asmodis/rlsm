require File.join(File.dirname(__FILE__), 'helper')

module RLSM
  
  class Position #:nodoc:
    include Comparable
    
    def initialize(char, index = nil)
      @letter = char
      @index = index
    end
    
    attr_reader :letter, :index
    
    def <=>(other)
      case other
      when String
        @letter <=> other
      when Numeric
        @index <=> other
      when Position
        @letter == other.letter ? @index <=> other.index : @letter <=> other.letter
      else
        nil
      end
    end
    
    def to_s
      @letter
    end

    def inspect
      "P(#@letter,#@index)"
    end
  end
  
  class SyntaxNode #:nodoc:
    include Comparable

    def self.[](input = nil)
      self.new(input)
    end

    def initialize(input = nil)
      @content = input
    end
    
    attr_accessor :content

    def null?
      true
    end

    def first
      []
    end

    def last
      []
    end

    def follow
      nil
    end
    
    def <=>(other)
      to_s <=> other.to_s
    end

    def to_s
      @content.to_s
    end

    def inspect
      "#{self.class}[ #{@content.inspect} ]"
    end
  end

  class EmptySet < SyntaxNode #:nodoc:
    def initialize(input = nil)
      super ''
    end
  end

  class EmptyWord < SyntaxNode #:nodoc:
    def initialize(input = nil)
      super '@'
    end
  end

  class Prim < SyntaxNode #:nodoc:
    def null?
      false
    end

    def first
      [ @content ]
    end

    def last
      [ @content ]
    end

    def follow
      []
    end
  end

  class Star < SyntaxNode #:nodoc:
    def first
      @content.first
    end

    def last
      @content.last
    end

    def follow
      result = []

      @content.last.each do |char1|
        @content.first.each do |char2|
          result << [char1,char2]
        end
      end

      (@content.follow | result).sort
    end

    def to_s
      string  = @content.to_s

      string.length > 1 ? "(#{string})*" : "#{string}*"
    end
  end

  class Union < SyntaxNode #:nodoc:
    def null?
      @content.any? { |subexpr| subexpr.null? }
    end

    def first
      @content.map { |subexpr| subexpr.first }.flatten.sort
    end

    def last
      @content.map { |subexpr| subexpr.last }.flatten.sort
    end

    def follow
      @content.inject([]) { |result, subexpr| result | subexpr.follow }.sort
    end

    def to_s
      @content.map { |subexpr| subexpr.to_s }.join('|')
    end
  end

  class Concat < SyntaxNode #:nodoc:
    def null?
      @content.all? { |subexpr| subexpr.null? }
    end

    def first
      result = []
      @content.each do |subexpr|
        result << subexpr.first
        break unless subexpr.null?
      end

      result.flatten.sort
    end

    def last
      result = []
      @content.reverse.each do |subexpr|
        result << subexpr.last
        break unless subexpr.null?
      end

      result.flatten.sort
    end

    def follow
      result = []

      (@content.size-1).times do |i|
        result |= @content[i].follow
        @content[i].last.each do |char1|
          @content[i+1].first.each do |char2|
            result << [char1, char2]
          end
        end
      end

      result |= @content[-1].follow

      result.sort
    end

    def to_s
      string = ''
      
      @content.each do |subexpr|
        if Union === subexpr
          string += "(#{subexpr.to_s})"
        else
          string += subexpr.to_s
        end
      end

      string
    end
  end
end  #of module RLSM
