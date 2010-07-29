require File.join(File.dirname(__FILE__), 'helper')

module RLSM
  # @private
  module RE #:nodoc:
    module ParserHelpers #:nodoc:
      OpenBracket = '('
      CloseBracket = ')'
      UnionSymbol = '|'
      StarSymbol = '*'
      EmptyWordSymbol = '@'
      LetterRegexp = /[a-zA-Z0-9]/

      def open_bracket?(char)
        char.to_s == OpenBracket
      end

      def close_bracket?(char)
        char.to_s == CloseBracket
      end

      def union_symbol?(char)
        char.to_s == UnionSymbol
      end

      def star_symbol?(char)
        char.to_s == StarSymbol
      end

      def empty_symbol?(char)
        char.to_s == EmptyWordSymbol
      end

      def letter?(char)
        char.to_s =~ LetterRegexp
      end

      def empty_set?(input)
        !input.any? { |position| letter?(position) or empty_symbol?(position) } 
      end

      def empty_word?(input)
        input.any? { |position| empty_symbol?(position) } and
          input.all? { |position| !letter?(position) } and not
          input.join.include?(OpenBracket + CloseBracket)
      end

      def single_letter?(input)
        input.size == 1 and letter?(input[0])
      end

      def union?(input)
        depth = 0
        input.each do |position|
          return true if depth == 0 and union_symbol?(position)
          depth += position.weight
        end

        false
      end

      def star?(input)
        return false unless star_symbol?(input[-1])
        return true if input.size == 2
        
        return star?(input[0..-2]) if star_symbol?(input[-2])

        open_bracket?(input[0]) and close_bracket?(input[-2]) and
          !Parser.unbalanced_brackets?(input[1..-3])
      end      
    end

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

      def weight
        return 1 if Parser.open_bracket?(@letter)
        return -1 if Parser.close_bracket?(@letter)

        0
      end

      def to_s
        @letter
      end

      def inspect
        "P(#@letter,#@index)"
      end
    end
    
    class Parser #:nodoc:
      extend ParserHelpers

      def self.[](string)
        index = -1
        input = string.gsub(/\s+/,'').scan(/./).map do |char| 
          letter?(char) ? Position.new(char,index += 1) : Position.new(char)
        end

        if unbalanced_brackets?(input)
          raise RLSM::Error, "Parse Error: Unbalanced brackets."
        end
        
        parse(input)      
      end

      def self.parse(input)
        input = remove_surrounding_brackets(input)

        if empty_set?(input)
          EmptySet[]
        elsif empty_word?(input)
          EmptyWord[]
        elsif single_letter?(input)
          Prim[ input.first ]      
        elsif star?(input)
          create_star_node( input )
        elsif union?(input)
          create_union_node(input)
        else #must be a concat
          create_concat_node(input)
        end
      end

      private
      def self.create_star_node(input)      
        content = parse(input[0..-2])

        if [Star, EmptySet, EmptyWord].include? content.class
          content
        elsif Union === content
          star_content = Union[ content.content.reject { |subexpr| subexpr == EmptyWord[] } ]
          Star[ star_content ]
        else
          Star[ content ]
        end
      end

      def self.create_union_node(input)
        subexpressions = union_split(input).map { |subexpression| parse(subexpression) }

        subexpressions = subexpressions.inject([]) do |result,subexpr|
          unless EmptySet === subexpr or result.include?(subexpr)
            result << subexpr
          end

          result
        end

        if subexpressions.any? { |subexpr| EmptyWord === subexpr }
          subexpressions = subexpressions.reject { |subexpr| subexpr == EmptyWord[] }
          unless subexpressions.any? { |subexpr| subexpr.null? }
            subexpressions.unshift EmptyWord[]
          end
        end

        star_exprs, subexpressions = subexpressions.partition { |subexpr| Star === subexpr }
        subexpressions.reject! { |subexpr| star_exprs.any? { |star| star.content == subexpr } }
        subexpressions |= star_exprs
        
        if subexpressions.size == 1
          subexpressions.first
        else
          Union[ subexpressions.sort ]
        end
      end

      def self.create_concat_node(input)
        subexpressions = concat_split(input)

        return EmptySet[] if subexpressions.any? { |subexpr| subexpr == EmptySet[] }

        subexpressions = subexpressions.reject { |subexpr| subexpr == EmptyWord[] }

        if subexpressions.empty?
          EmptyWord[]
        elsif subexpressions.size == 1
          subexpressions.first
        else
          Concat[ subexpressions ]
        end
      end

      def self.remove_surrounding_brackets(string)
        result = string
        result = result[1..-2] while( open_bracket?(result.first) &&
                                      close_bracket?(result.last) &&
                                      !unbalanced_brackets?(result[1..-2]) )
        
        result
      end

      def self.unbalanced_brackets?(string)
        nesting = string.inject(0) do |depth,char|
          depth += char.weight
          return true if depth < 0
          depth
        end
        
        nesting != 0 ? true : false
      end
      
      def self.union_split(string)
        result = [[]]
        depth = 0
        string.each do |char|
          if depth == 0 and union_symbol?(char)
            result << []
          else
            result.last << char
          end
          depth += char.weight
        end

        result
      end    
      
      def self.concat_split(string)
        result = []
        subexpr = []
        
        depth = 0
        string.each_with_index do |char,index|
          depth += char.weight

          if depth == 0
            subexpr << char if close_bracket?(char)

            unless subexpr.empty?
              subexpr << string[index+1] if star_symbol?(string[index + 1])
              result << parse(subexpr)
              subexpr = []
            end

            if letter?(char)
              if star_symbol?(string[index+1])
                result << Star[ Prim[ char ] ]
              else
                result << Prim[ char ]
              end
            end
          else #depth != 0
            subexpr << char
          end
        end

        result
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
  end #of module RE
end  #of module RLSM
