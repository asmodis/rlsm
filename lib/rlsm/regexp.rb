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
require File.join(File.dirname(__FILE__), 'exceptions.rb')
require File.join(File.dirname(__FILE__), 'regexp_nodes', 'renodes')
require File.join(File.dirname(__FILE__), 'dfa')

module RLSM
  class RegExp
    include RLSM::RENodes

    #Creates a new RegExp from a string description. Metacharacters are 
    #   & * | ( )
    #Here & is the empty word and an empty string represents the empty set.
    def initialize(desc = "")
      #Is the argument a well formed RegExp?
      _well_formed?(desc)
      
      @re = RLSM::RENodes.new(desc)
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
      @re = RLSM::RENodes.new(str)
      
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
          
      tmp_re = RLSM::RENodes.new(rre)

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
      str.each_char do |c|
        state += RLSM::RENodes::PCount[c]
      end
      
      if state != 0
        raise RegExpException, "Unbalanced parenthesis in #{str}"
      end

      #2 bad sequenzes
      if str =~ /\(\)|\|\)|\(\||\|\*|^\*|\(\*/
        raise RegExpException, "Bad character sequence #{$&} found in #{str}"
      end
    end    
  end     
end
