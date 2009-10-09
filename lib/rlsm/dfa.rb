require File.join(File.dirname(__FILE__), 'helper')
require File.join(File.dirname(__FILE__), 'regexp')
require File.join(File.dirname(__FILE__), 'monoid')
RLSM::require_extension('array')

require "strscan"

module RLSM
  class DFA
    #Synonym for new.
    def self.[](description)
      new(description)
    end

    #Creates a new DFA. The +description+ is a string which describes states and transitions.
    #A state is described by a descriptor, which consists of latin letters and numbers (no whitespaces).
    #
    #To indicate a final state, the state descriptor starts with a *. This is allowed multiple times, even for the same state.
    #
    #The initial state starts with a right brace ('}'). This is only allowed once.
    #
    #A transition is described as follows
    #   STATE -LETTERLIST-> STATE
    # were +STATE+ is a state descriptor (* and } modifiers allowed) and +LETTERLIST+ is either a single letter of the alphabet or a comma seperated list of alphabet letters.
    #
    #*Remark*: This desription format may be the worst design desicion in the whole gem ...
    #
    #*Example*:
    # RLSM::DFA["}s1-a,b->*s2"]
    # RLSM::DFA["}s1 s2 *s3 s1-a->s2 s2-a,b->*s3 s3-b->s1"]
    # RLSM::DFA["}s1 s2 *s3 }s1-a->s2 s2-a,b->*s3 s3-b->s1"] # => Error
    def initialize(description)
      parse_initial_state(description)
      parse_states(description)
      parse_final_states(description)
      parse_transitions(description)
    end
    
    #Initial state of the DFA.
    attr_reader :initial_state
    
    #Array of accepting states.
    attr_reader :final_states

    #Array of all states
    attr_reader :states

    #The alphabet of the DFA.
    attr_reader :alphabet

    #Returns array of transitions (a transition is a triple consisting of start, destination and label).
    def transitions
      return [] if @transitions.nil?

      result = []
      @transitions.each do |state,labels|
        labels.each do |label,dest|
          result << [state,dest,label]
        end
      end

      result
    end

    #Processes given +string+ starting in state +state+.
    def [](state, string)
      unless @states.include?(state)
        raise DFAError, "Unknown state: #{state}"
      end

      present_state = state
      string.scan(/./).each do |letter|
        if @transitions[present_state].nil?
          return nil
        else
          present_state = @transitions[present_state][letter]
        end
      end

      present_state
    end

    #Processes given +string+ starting in the initial state.
    def <<(string)
      self[@initial_state, string]
    end

    #Checks if this DFA accepts the given +string+, i.e. halts in a final state after processing the string.
    def accepts?(string)
      @final_states.include?( self << string )
    end

    #Checks if given +state+ is dead, i.e. its not a final state and it hs no outgoing transitions.
    def dead?(state)
      raise DFAError, "Unknown state: #{state}" unless @states.include?(state)
      
      state != @initial_state and
        ! @final_states.include?(state) and
        @alphabet.all? { |let| [nil,state].include? @transitions[state][let] }
    end

    #Checks if given +state+ is reachable, i.e. it exists a +string+, such that <tt>self << string == state</tt> is true.
    def reachable?(state)
      raise DFAError, "Unknown state: #{state}" unless @states.include?(state)

      reachable_states.include? state
    end

    #Checks if each state is reachable. See reachable?.
    def connected?
      @states.all? { |state| reachable?(state) }
    end
    
    #Checks if DFA is complete, i.e. each state accepts every alphabet letter.
    def complete?
      @states.all? do |state|
        @alphabet.all? do |letter| 
          self[state,letter]
        end
      end
    end

    #Calculates the transition monoid of the DFA.
    def transition_monoid
      maps = [@states.dup]
      elements = ['id']

      length = 1
      found_all_elements = false

      until found_all_elements
        words(length) do |word|
          found_all_elements = true
          
          map = get_map(word)
          unless maps.include?(map)
            maps << map
            elements << word
            found_all_elements = false
          end
        end

        length += 1
      end

      monoid_description = elements.join(',')

      elements[1..-1].each do |element|
        monoid_description += " #{element},"
        monoid_description += elements[1..-1].map do |element2|
          elements[maps.index(get_map(element+element2))]
        end.join(',')
      end

      RLSM::Monoid[ monoid_description ]
    end

    #Checks for equality. A DFA is equal to +other+ iff it has the same alphabet, states, final states, initial state and transitions.
    def ==(other)
      begin
        @alphabet == other.alphabet and
          @initial_state == other.initial_state and
          @states.sort == other.states.sort and
          @final_states.sort == other.final_states.sort and
          transitions.sort == other.transitions.sort
      rescue
        false
      end
    end

    #Checks if the DFA is minimal.
    def minimal?
      equivalent_state_pairs.empty?
    end

    #Alters the DFA in place to an equivalent minmal one.
    def minimize!
      remove_unneeded_states!

      unless minimal?
        state_classes = get_equivalent_state_classes
      
        states = state_classes.map { |cls| cls.min }

        rename = {}

        @states.each do |state|
          rename[state] = state_classes.find { |cls| cls.include?(state) }.min
        end

        transitions = {}

        @transitions.each_pair do |state, transition|
          start = (transitions[rename[state]] ||= {})

          transition.each_pair do |letter, destination|
            start[letter] = rename[destination]
          end
        end

        @initial_state = rename[@initial_state]
        @states = states
        @final_states.map! { |state| rename[state] }
        @final_states.uniq!
        @transitions = transitions
       end

      self
    end

    #Returns an equivalent minmal DFA.
    def minimize
      Marshal.load(Marshal.dump(self)).minimize!
    end

    #Checks if +self+ is isomorph to other.
    def =~(other)
      return false if other.class != self.class || 
        @alphabet != other.alphabet ||
        @states.size != other.states.size || 
        @final_states.size != other.final_states.size ||
        transitions.size != other.transitions.size

      bijective_maps_to(other).any? do |bijection|
        transitions.all? do |s1,s2,letter|
          other.transitions.include?([bijection[s1],bijection[s2],letter])
        end
      end
    end

    #Checks if +self+ is equivalent to +other+, i.e. they accepts the same language.
    def equivalent_to(other)
      return false if other.class != self.class

      minimize =~ other.minimize
    end

    #Calculates a regular expression which represents the same languge as the DFA.
    def to_regexp
      les = []
      les << initialize_row_for(@initial_state)
      (@states - [@initial_state]).each do |state|
        les << initialize_row_for(state)
      end

      #Solve for the initial state
      les = update_les(les, simplify_les_row(les.pop)) until les.size == 1

      simplify_les_row(les.pop)[:final]
    end

    #Simply returns self.
    def to_dfa
      self
    end

    #Returns the transition monoid of the equivalent minimal DFA (which is in fact isomorph to the syntactic monoid of the represented language.
    def to_monoid
      minimize.transition_monoid
    end

    private
    def initialize_row_for(state)
      row = { :state => state.clone, :final => RLSM::RegExp.new('') }
      @states.each do |s|
        row[s] = RLSM::RegExp.new ''
      end

      @alphabet.each do |letter|
        row[self[state,letter]] |= RLSM::RegExp.new(letter) if self[state,letter]
      end

      if @final_states.include? state
        row[:final] = RLSM::RegExp.empty_word
      end

      row
    end

    def update_les(les,act_row)
      les.map do |row|
        re = row[act_row[:state]]
        @states.each do |state|
          if state == act_row[:state]
            row[state] = RLSM::RegExp.new ''
          else
            row[state] |= re + act_row[state]
          end
        end

        row[:final] |= re + act_row[:final]
        row
      end
    end

    def simplify_les_row(row)
      #Have we something like Ri = ... + xRi + ...
      if row[row[:state]].parse_tree != RLSM::RE::EmptySet[]
        re = row[row[:state]].star
        @states.each do |state|
          if state == row[:state]
            row[state] = RLSM::RegExp.new ''
          else
            row[state] = re + row[state]
          end
        end
        
        row[:final] = re + row[:final]
      end

      row
    end

    def bijective_maps_to(other)
      bijective_maps = other.states.permutations.map do |perm| 
        Hash[*@states.zip(perm).flatten]
      end

      bijective_maps.select do |map|
        other.initial_state == map[@initial_state] &&
          @final_states.all? { |fi| other.final_states.include?(map[fi]) }
      end
    end

    def remove_unneeded_states!
      unneeded_states, states = @states.partition do |state| 
        dead?(state) or not reachable?(state)
      end

      transitions = self.transitions.reject do |transition|
        unneeded_states.any? { |dead| transition.include?(dead) }
      end

      @states = states
      @reachable_states = @states
      @final_states &= states
      @transitions = {}
      transitions.each do |start,destination,letter|
        (@transitions[start] ||= {})[letter] = destination
      end
    end
    
    def equivalent_state_pairs
      @states << nil unless complete?

      different, indifferent = [], []

      states[0..-2].each_with_index do |state1, i|
        states[(i+1)..-1].each do |state2|
          if @final_states.include?(state1) ^ @final_states.include?(state2)
            different << [state1, state2]
          else
            indifferent << [state1, state2]
          end
        end
      end

      begin
        new_different = indifferent.select do |state1, state2|
          
          @alphabet.any? do |letter| 
            test_pair = [self[state1,letter], self[state2,letter]]
            different.include?(test_pair) or 
              different.include?(test_pair.reverse)
          end
        end

        different |= new_different
        indifferent -= new_different
      end until new_different.empty?

      @states.compact!
          
      indifferent.reject { |pair| pair.include?(nil) }
    end

    def get_equivalent_state_classes
      pairs = equivalent_state_pairs

      classes = []

      @states.each do |state|
        next if classes.any? { |cls| cls.include? state }
        cls = [state]
        cls |= pairs.find_all { |pair| pair.include?(state) }
        classes << cls.flatten.compact.uniq
      end

      classes
    end

    def parse_initial_state(description)
      unless description.count('}') == 1
        raise DFAError, "None or at least two initial states."
      end

      @initial_state = description[/\}\s*\*?(\w+)/,1]
    end

    def parse_final_states(description)
      @final_states = []

      desc = StringScanner.new(description)
      loop do
        break unless desc.scan(/[^*]*\*\}?/) 
        final_state = desc.scan(/\w+/)
        @final_states << final_state unless @final_states.include?(final_state)
      end
    end

    def parse_states(description)
      desc = description.gsub(/[*}]/,'')
      desc.gsub!(/\s+/,' ')
      desc.gsub!(/\s*-+(\w+,?)+-+>\s*/, ' ')

      @states = desc.split.uniq      
    end

    def parse_transitions(description)
      @alphabet = []
      @transitions = {}
      
      return unless description =~ /[->]/
      
      parser = transition_parser(description)

      loop do
        transaction = parser.scan(/(\w+)-((\w+,?)+)->(\w+)/)
        if transaction
          start = parser[1]
          labels = parser[2].split(',').uniq
          destination = parser[4]

          insert_transition(start,destination,labels)
          insert_alphabet_letters(labels)
        elsif parser.scan(/\w+/)
          #do nothing (states already parsed)
        else
          raise DFAError, "Parse Error, could not parse #{description}"
        end
          
        break unless parser.scan(/ /)
      end

      unless parser.eos?
        raise DFAError, "Parse Error, could not parse #{description}"
      end
      
      @alphabet = @alphabet.sort
    end

    def transition_parser(description)
      #simplifying the description for easier parsing
      desc = description.gsub(/[*}]/, '')[/^\s*(.+?)\s*$/,1]
      desc.gsub!(/\s+/, ' ')
      desc.gsub!(/\s*-+\s*/,'-')
      desc.gsub!(/>\s*/,'>')
      desc.gsub!(/\s*,\s*/,',')
      
      StringScanner.new(desc)
    end

    def insert_transition(start,destination,labels)
      labels.each do |label|
        trans = (@transitions[start] ||= {})
        if trans[label].nil?
          trans[label] = destination
        elsif trans[label] != destination
          raise DFAError, "Parse Error: Transition labels must be uniq."
        end
      end
    end

    def insert_alphabet_letters(labels)
      @alphabet |= labels
    end

    def reachable_states
      @reachable_states ||= calc_reachable_states
    end

    def calc_reachable_states
      reachable = []
      new_states = [@initial_state]
      
      until new_states.empty?
        reachable |= new_states
        new_states = []
        reachable.each do |state|
          @alphabet.each do |letter|
            new_state = self[state,letter]
            
            unless new_state.nil? or reachable.include?(new_state)
              new_states << new_state
            end
          end
        end
        new_states.compact!
      end
      
      reachable
    end


    def get_map(word)
      @states.map { |state| self[state,word] }
    end

    def words(length)
      word = [@alphabet.first]*length
      last = [@alphabet.last]*length

      until word == last
        yield word.join
        word = get_next(word)
      end
      
      yield last.join
    end

    def get_next(word)
      i = (1..word.length).find { |i| word[-i] != @alphabet.last }
      word[-i] = @alphabet[@alphabet.index(word[-i])+1]
      if i > 1
        (1...i).each do |j|
          word[-j] = @alphabet.first
        end
      end
      
      word
    end
  end # of class DFA
end # of module RLSM
