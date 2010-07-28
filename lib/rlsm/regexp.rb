require File.join(File.dirname(__FILE__), 'helper')
require File.join(File.dirname(__FILE__), 'regexp_parser')
require File.join(File.dirname(__FILE__), 'dfa')

module RLSM
  # @private
  class RegExp
    #Returns a RegExp which is the empty word.
    def self.empty_word
      new RLSM::RE::ParserHelpers::EmptyWordSymbol
    end

    #Returns a RegExp which represents the empty language.
    def self.empty_set
      new ''
    end

    #Synonym for new.
    def self.[](description)
      new(description)
    end

    #Creates a new RegExp. The +description+ is a string consiting of latin letters, numbers and the following special characters
    #1. +(+, +)+  for grouping subexpressions
    #2. +|+ for union of regular expressions
    #3. +*+ for the Kleene-Closure of a regular expression
    #4. +@+ the empty word.
    #
    #Whitspaces will be ignored and the empty string represents the empty language.
    def initialize(description)
      @parse_tree = RE::Parser[ description ]
      @string = @parse_tree.to_s
    end

    attr_reader :parse_tree, :string

    #Concatenate +self+ with +other+.
    def +(other)
      RLSM::RegExp.new "(#@string)(#{other.string})"
    end

    #Returns the union of +self+ and +other+
    def |(other)
      RLSM::RegExp.new "#@string|#{other.string}"
    end

    #Returns the Kleene closure of +self+.
    def star
      RLSM::RegExp.new "(#@string)*"
    end

    #Calculates a minimal DFA which represents the same languge as +self+.
    def to_dfa
      RLSM::DFA.new(subset_construction).minimize!
    end

    #Simply returns self.
    def to_regexp
      self
    end

    #Calculates the syntactic monoid of the represented language.
    def to_monoid
      to_dfa.to_monoid
    end

    #Checks if +self+ is equal to +other+, i.e. they represent the same language.
    def ==(other)
      return true if @string == other.string

      first = @parse_tree.first.map { |pos| pos.to_s }.uniq 
      other_first = other.parse_tree.first.map { |pos| pos.to_s }.uniq
      return false if first != other_first

      last = @parse_tree.last.map { |pos| pos.to_s }.uniq 
      other_last = other.parse_tree.last.map { |pos| pos.to_s }.uniq
      return false if last != other_last

      to_dfa =~ other.to_dfa
    end

    private
    def set_up_subset_construction
      follow = @parse_tree.follow
      initial = RE::Position.new('i',-1)
      @parse_tree.first.each { |char| follow << [initial, char] }

      [[initial], @parse_tree.null? ? [[initial]] : [], follow, @parse_tree.last]
    end

    def subset_construction
      initial, finals, follow, last = set_up_subset_construction
      transitions = []

      unmarked = [initial]
      marked = []
      until unmarked.empty?
        marked << unmarked.shift
        new_states(marked.last,follow).each_pair do |char,state|
          unmarked << state unless  (unmarked | marked).include? state #bug
          finals |= [state] if last.any? { |pos| state.any? { |st_pos| st_pos === pos } }
          transitions << [marked.last,state, char]  
        end
      end
      
      string = "}s0 "
      string += finals.map { |state| "*s#{marked.index(state)}" }.join(' ')
      string += ' '

      string += transitions.map do |tr|
        "s#{marked.index(tr[0])}-#{tr[2]}->s#{marked.index(tr[1])}"
      end.join(' ')
    end

    def new_states(origin,follow)
      tmp = origin.map { |pos| follow.find_all { |pair| pair[0] === pos }.
        map { |pair| pair[-1] } }.flatten

        tmp.inject({}) do |result, pos|
        (result[pos.to_s] ||= []) << pos
        result
      end
    end
  end # of class RegExp
end   # of module RLSM

