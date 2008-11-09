#
# This file is part of the RLSM gem.
#
#(The MIT License)
#
#Copyright (c) 2008 Gunther Diemant <g.diemant@gmx.net>
#
#Permission is hereby granted, free of charge, to any person obtaining
#a copy of this software and associated documentation files (the
#'Software'), to deal in the Software without restriction, including
#without limitation the rights to use, copy, modify, merge, publish,
#distribute, sublicense, and/or sell copies of the Software, and to
#permit persons to whom the Software is furnished to do so, subject to
#the following conditions:
#
#The above copyright notice and this permission notice shall be
#included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require File.join(File.dirname(__FILE__), 'monkey_patching')

module RLSM
  class RegExp
    #Creates a new RegExp from a string description. Metacharacters are 
    #   & * | ( )
    #Here & is the empty word and an empty string represents the empty set.
    def initialize(str = "")
      #Is the argument a well formed RegExp?
      _well_formed?(str)
      
      #More than one & or * in a row is useless
      re = str.squeeze('&*')

      #* on a & is &
      re = re.gsub('&*', '&')

      @re = NodeFactory.new_node(nil, re)
    end

#--
#Operations of a regexp
#++

    #Kleene star of the regexp. Alters the regexp in place
    def star!
      #For empty set and empty word a star changes nothing.
      #A double star is also useless
      return if empty? or lambda? or (@re.class == Star)
      str = '(' + to_s + ')*'
      @re = NodeFactory.new_node(nil, str)
      
      #Unset the str rep
      @re_str = nil
      
      self
    end

    #Returns the kleene star of this regexp. Leaves the regexp untouched.
    def star
      self.deep_copy.star!
    end

    #Returns the concatenation of two regexps
    def *(other)
      return RegExp.new if empty? or other.empty?
      RegExp.new('(' + to_s + ')(' + other.to_s + ')')
    end

    #Returns the union of two regexps
    def +(other)
      return self.deep_copy if other.empty?
      return other.deep_copy if empty?
      RegExp.new('(' + to_s + ')|(' + other.to_s + ')')
    end

#--
#Some small flags
#++
    #Returns true if this regexp is the empty word.
    def lambda?
      @re.lambda?
    end

    #Returns true if this regexp is the empty set.
    def empty?
      @re.empty?
    end

    #Returns true if the empty word matches this regexp
    def null?
      @re.null?
    end

#--
#Some properties of a regexp
#++

    #Returns an array of beginning symbols of the regexp.
    def first
      @re.first
    end

    #Returns an array of end symbols of the regexp.
    def last
      @re.last
    end

    #Returns an array of all possible two letter substrings of words matched by the regexp.
    def follow
      @re.follow.uniq
    end

#--
#Conversion methods
#++
    #Returns a string representation of the regexp
    def to_s
      @re_str ||= @re.to_s
    end

    #Returns a minimal DFA which accepts the same language as the regexp.
    def to_dfa
      #Step 1: Substitute every char such that every character is unique
      #Add also a beginning marker
      
      orig = []
      rre = [0]
      to_s.each_char do |c|
        if ['(', ')', '|', '*', '&'].include? c
          rre << c
        else
          orig << c
          rre << (orig.size)
        end
      end
          
      tmp_re = NodeFactory.new_node(nil, rre)

      #Step 2a: Construct a DFA representation of this new regexp
      #Step 2b: reverse the substitution (yields (maybe) a NFA)

      alph = orig.uniq
      initial = 0
      
      tmp_finals = tmp_re.last

      tmp_trans = tmp_re.follow.map do |s1,s2|
        [orig[s2-1], s1, s2]
      end

      #Step 4: Transform the NFA to a DFA
      states = [[0]]
      new_states = [[0]]
      trans = []
      while new_states.size > 0
        tmp = new_states.deep_copy
        new_states = []
        
        tmp.each do |new_state|
          alph.each do |char|
            tr_set = tmp_trans.find_all do |c,s1,s2|
              c == char and new_state.include? s1
            end

            unless tr_set.empty?
              state = tr_set.map { |c,s1,s2| s2 }.sort
              
              #Found a new state?
              unless states.include? state
                new_states << state
                states << state
              end

              tr = [char, states.index(new_state), states.index(state)]

              #Found new trans?
              trans << tr unless trans.include? tr
            end
          end
        end
      end
      
      finals = states.find_all do |state|
        tmp_finals.any? { |tf| state.include? tf }
      end.map { |fi| states.index(fi) }

      states = (0...states.size).to_a

      #Step 5: Return the result
      RLSM::DFA.new(alph,states,initial,finals,trans).minimize(:rename_states => true)
    end

    def inspect # :nodoc:
      "<#{self.class} : '#{to_s}' >"
    end

    #Returns true if the two regexps are the same, i.e. the dfas are isomorphic.
    def ==(other)
      to_dfa == other.to_dfa
    end

    
    private
    def _well_formed?(str)
      #parantheses must be balanced, somthing like |) or *a or (| isn't allowed
      #1 balanced parenthesis
      state = 0
      count = Hash.new(0)
      count['('] = 1
      count[')'] = -1
      str.each_char do |c|
        state += count[c]
      end
      
      if state != 0
        raise RegExpException, "Unbalanced parenthesis in #{str}"
      end

      #2 bad sequenzes
      if str =~ /\(\)|\|\)|\(\||\|\*|^\*|\(\*/
        raise RegExpException, "Bad character sequence #{$&} found in #{str}"
      end
    end    

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

    class Star
      def initialize(parent, str)
        @parent = parent
        @child = NodeFactory.new_node(self, str[(0..-2)])
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

    class Union
      def initialize(parent, str)
        @parent = parent
        @childs = _split(str).map do |substr|
          NodeFactory.new_node(self, substr)
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

    class Concat
      def initialize(parent, str)
        @parent = parent
        @childs = _split(str).map do |substr|
          NodeFactory.new_node(self, substr)
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

    class NodeFactory
      def self.new_node(parent, arg)

        #Remove parentheses
        str = arg.dup
        while sp(str)
          str = str[(1..-2)]
        end
#puts "Processing: #{arg} from #{parent.class}"
        #Choose the right node type
        if prim?(str)
          return PrimExp.new(parent, str)
        elsif star?(str)
          return Star.new(parent, str)
        elsif union?(str)
          return Union.new(parent, str)
        else
          return Concat.new(parent, str)
        end

      end

      private
      def self.sp(str)
        if str[0,1].include? '(' and str[-1,1].include? ')'
          state = 0
          l = 0
          count = Hash.new(0)
          count['('] = 1
          count[')'] = -1

          str.each_char do |c|
            state += count[c]
            l += 1
            break if state == 0
          end
          
          return true if str.length == l
        end
        
        false
      end

      def self.prim?(str)
        not ['(', ')', '|', '*'].any? { |c| str.include? c }
      end

      def self.star?(str)
        if str[-1,1].include? '*'
          return true if sp(str[(0..-2)]) #something like (....)*
          return true if str.length == 2  #something like a*
        end

        false
      end

      def self.union?(str)
        state = 0
        count = Hash.new(0)
        count['('] = 1
        count[')'] = -1

        str.each_char do |c|
          state += count[c]

          return true if c == '|' and state == 0
        end

        false
      end
    end
  end     
end
