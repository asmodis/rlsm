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
require File.join(File.dirname(__FILE__), 'monoid')
require File.join(File.dirname(__FILE__), 'regexp')
require File.join(File.dirname(__FILE__), 'exceptions.rb')

module RLSM
  class DFA
    def initialize(alph, states, initial, finals, transitions)
      @alphabet = alph.sort

      #State identifiers should be unique and shouldn't be trap
      if states.uniq != states or states.include? 'trap'
        raise DFAException, "Bad states. State names must be unique and not 'trap'"
      end
    
      #Create the states
      @states = states.map do |state|
        if state == initial
          if finals.include? state
            State.new(self, state.to_s, :initial => true, :final => true)
          else
            State.new(self, state.to_s, :initial => true)
          end
        elsif finals.include? state
          State.new(self, state.to_s, :final => true)
        else
          State.new(self, state.to_s)
        end
      end
      
      #Add the transitions and check for completness
      @states.each do |state|
        transitions.select { |c, s1, s2| s1.to_s == state.label }.each do |c, s1, s2|
          state.add_transition c, _get_state(s2.to_s)
        end
      end
      
      #Calculate the reachable states
      @reachable_states = [initial_state]
      changed = true
      
      while changed
        changed = false
        (@states - @reachable_states).each do |state|
          if @reachable_states.any? { |s| s.reachable_states.include? state }
            @reachable_states << state
            changed = true
          end
        end
      end

      #Bring the initial state to index 0
      ii = @states.index(initial_state)
      if ii != 0
        @states[0], @states[ii] = @states[ii], @states[0]
      end
    end
    
    attr_reader :alphabet, :reachable_states
    
    #Returns the initial state
    def initial_state
      @initial ||= @states.find { |state| state.initial? }.deep_copy
    end

    #Returns an array of all final states.
    def final_states
      @finals ||= @states.find_all { |state| state.final? }.deep_copy
    end

    #Returns an array of all states.
    def states
      @states.deep_copy
    end

    #The number of states
    def num_states
      @states.size
    end

    #The number of final states.
    def num_finals
      final_states.size
    end

    #Returns the state in which the DFA halts if started in state and given str. Returns nil if this string isn't parseable by the DFA started in state. If the state is omitted, default start state is the initial state (surprising, isn't it).
    def process(str, state = nil)
      s = state || initial_state
      str.each_char do |char|
        s = s.process(char)
        return nil if s.nil?
      end

      s
    end

    #Returns true if the given string is accepted by the DFA.
    def accepts?(str)
      s = process(str)
      #Full String parsed, are we now in a final state or was an error?
      s ? s.final? : false
    end

    #Returns an array of states. The state at position i is the state in which the DFA halts, if started in states[i] and given str.
#
#Caution: If a state can't process str, for this state nil is returned. In a complete DFA for any valid input string, a non nil State will be returnd. 
    def transition_function(str)
      @states.map { |state| process(str, state) }
    end

    #Returns true if a DFA isomorphism between self and other exists.
    def isomorph_to?(other)
      #First a few necessary conditions
      return false if num_states != other.num_states
      return false if num_finals != other.num_finals
      return false if alphabet != other.alphabet

      initial_index = @states.index(initial_state)
      final_indices = final_states.map { |f| @states.index(f) }
      (0...num_states).to_a.permutations.each do |per|
        #Initial state must map to initial state
        next unless other.states[per[initial_index]].initial?

        #Finals must map to finals
        next unless final_indices.all? { |fi| other.states[fi].final? }

        #Transactions respected?
        bad = @states.find do |state|
          not @alphabet.all? do |char|
            si = @states.index(state)
            ps = state.process(char)

            if ps.nil?
              other.states[per[si]].process(char).nil?
            else
              os = other.states[per[si]].process(char)
              if os.nil?
                false
              else
                per[@states.index(ps)] == other.states.index(os)
              end
            end
          end
        end

        #Found an iso, i.e. no bad states?
        return true unless bad
      end

      #No isomorphism found
      return false
    end

    #A synonym for isomorph_to?
    def ==(other)
      isomorph_to? other
    end

    #Returns true, if the two DFAs accepts the same language, i.e. the mimimized DFAs are isomorph.
    def equivalent_to?(other)
      minimze == other.minimize
    end

    #Returns true, if the two DFAs accepts languages of the same structure, i.e. if the languages differs only in the used alphabet. For example the languages aab and bba are similar.
    def similar_to?(other)
      dfa1 = minimize
      dfa2 = other.minimize

      #First a few necessary conditions
      return false if dfa1.num_states != dfa2.num_states
      return false if dfa1.num_finals != dfa2.num_finals

      dfa1.alphabet.permutations do |per|
        #Get the states
        states = other.states.map { |st| st.label }

        #Get the initial
        initial = other.initial_state.label
        
        #Get the finals
        finals = other.final_states.map { |fs| fs.label }

        #Get the transitions
        trans = []
        other.states.each do |s| 
          s.transitions.each_pair { |c,os| trans << [c,s.label, os.label].dup }
        end

        #Alter the transitions wrt to the permutation
        trans.map! do |c,s1,s2|
          [per[other.alphabet.index(c)],s1,s2]
        end

        #Exisits now an isomorphism between self and the new dfa?
        return true if self == new(@alphabet, states, initial, finals, trans)
      end

      #No similarity found
      return false
    end
       
    #Returns a minimal DFA which accepts the same language (see minimize!)
    def minimize(opts = {})
      self.deep_copy.minimize!(opts)
    end

    #Alters the DFA to a minimal one which accepts the same language.
    #If the DFA is complete, then the minimal DFA returned is also complete, i.e. if there is a trap state (a dead state, but without, the DFA isn't complete), it will not be deleted. To do so, call remove_dead_states after minimizing.
#If passed :rename_states => true, the state labels will be renamed to something short (propably 0,1,2,...).
    def minimize!(opts = {})
      #First step: remove unreachable states
      remove_unreachable_states!

      complete_temp = complete?

      #Second step: Find all equivalent states
      #Create the initial state partition
      sp = @states.partition { |state| state.final? }
      sp_labels = sp.map { |sc| sc.map {|st| st.label} }.sort
  
      #Calculate the new state partition for the first time
      nsp = new_state_partition(sp)
      nsp_labels = nsp.map { |sc| sc.map {|st| st.label} }.sort
      
      #Find all state classes (repeating process until nothing changes)
      while sp_labels != nsp_labels
        sp, nsp = nsp.deep_copy, new_state_partition(nsp)
        
        sp_labels = sp.map { |sc| sc.map {|st| st.label} }.sort
        nsp_labels = nsp.map { |sc| sc.map {|st| st.label} }.sort
      end

      #Third step: Are we done?
      #Check if the DFA was already minimal
      return self if sp.all? { |sc| sc.size == 1 }
      
      #Fourth step: Constructing the new DFA:
      #1 the states
      @states = sp.map do |sc|
        state_label = sc.map { |s| s.label }.join
        if sc.include? initial_state
          if final_states.any? {|f| sc.include? f }
            State.new(self, state_label, :initial => true, :final => true)
          else
            State.new(self, state_label, :initial => true)
          end
        elsif final_states.any? { |f| sc.include? f }
          State.new(self, state_label, :final => true)
        else
          State.new(self, state_label)
        end
      end

      #2 the transitions
      @states.each_with_index do |state, sc_index|
        sp[sc_index].first.transitions.each_pair do |char, s2|
          state.add_transition char, @states[_class_index_of(sp,s2)]
        end
      end
      
      
      #3 delete dead states
      remove_dead_states!(:except_trap => complete_temp)

      #4 Force recalculation of initial and final states
      @initial, @finals = nil, nil

      #Bring the initial state to index 0
      ii = @states.index(initial_state)
      if ii != 0
        @states[0], @states[ii] = @states[ii], @states[0]
      end


      #5 Was renaming of the states requested?
      if opts[:rename_states]
        @states.each_with_index do |state,index|
          state.label = index.to_s
        end
      end

      #6 update the reachable states (all are reachable in a minimal DFA)
      @reachable_states = @states.deep_copy


      self
    end

    #Returns true if the DFA is minimal (see minimize!).
    def minimal?
      num_states == minimize.num_states
    end

    #Returns a complete DFA which accepts the same language.
    def complete
      self.deep_copy.complete!
    end

    #Adds a dead state and adds to every other state a transition to this state for all missing alphabet elements. If the DFA is already complete nothing happens.
    #
    #In either case the complete DFA is returned.
    def complete!
      #Is work to do?
      return self if complete?
    
      #Create the trap state
      trap = State.new(self, 'trap')
      @alphabet.each do |char|
        trap.add_transition char, trap
      end
      
      #Add the necassery transitions
      @states.each do |state|
        unless state.complete?
          (@alphabet - state.accepted_chars).each do |char|
            state.add_transition char, trap
          end
        end
      end
      
      #Add the trap state to the DFA
      @states << trap
      @reachable_states << trap

      self
    end
    
    #Returns true if this DFA is complete, i.e. all states accepts all alphabet symbols.
    def complete?
      @states.all? do |state|
        state.complete?
      end
    end
    
    #Returns an array of dead states (a state is dead, if it is not final and has outdegree 0)
    def dead_states
      @states.find_all { |state| state.dead? }
    end
    
    #Returns true if the DFA has dead states (see also dead_states)
    def dead_states?
      @states.find { |state| state.dead? } ? true : false
    end
    
    #Removes all dead_states. If passed :except_trap => true, trap states wouldn't be removed.
    def remove_dead_states!(opt = {})
      @states.each do |state|
        state.remove_transitions_to_dead_states(opt)
      end

      #Remove the states
      if opt[:except_trap]
        @states = @states.reject do |state| 
          state.dead? and not state.trap? 
        end
        @reachable_states = @reachable_states.reject do |state| 
          state.dead? and not state.trap?
        end
      else
        @states = @states.reject { |state| state.dead? }
        @reachable_states = @reachable_states.reject { |state| state.dead? }
      end

      self
    end

    #Returns a copy with dead states removed.
    def remove_dead_states(opt = {})
      self.deep_copy.remove_dead_states!(opt)
    end
    
    #Returns an array of states, wich aren't reachable from the initial state.
    def unreachable_states
      @states.find_all { |state| state.unreachable?}
    end
    
    #Returns true if the DFA has unreachable states
    def unreachable_states?
      @states.find { |state| state.unreachable? } ? true : false
    end
    
    #Removes all unreachable states.
    def remove_unreachable_states!
      #No transition update necessary, because each state which reaches an unreachble state must be unreachable.
      @states = @states.reject { |state| state.unreachable? }
      @reachable_states = @states.deep_copy

      self
    end

    #Returns a copy with unreachable states removed.
    def remove_unreachable_states
      self.deep_copy.remove_unreachable_states!
    end

    #Returns an RLSM::RegExp instance representing the same language as this DFA.
    def to_regexp
      #No finals => no language
      return RLSM::RegExp.new if final_states.empty?

      #Calculate the coeffizients matrix
      #1 empty matrix with lambdas for final states
      matr = @states.map do |st|
        last = st.final? ? [RLSM::RegExp.new('&')] : [RLSM::RegExp.new]
        [RLSM::RegExp.new]*num_states + last
      end

      #2 remaining coeffizients
      @states.each_with_index do |state,i|
        state.transitions.each_pair do |ch, st|
          matr[i][@states.index(st)] += RLSM::RegExp.new(ch)
        end
      end

      #Solve the matrix for matr[0][0] (Remember 0 is index of initial state)
      (num_states-1).downto 1 do |i|
        #Depends Ri on itself? If so apply well known simplify rule
        # R = AR +B -> R = A*B
        unless matr[i][i].empty?
          matr[i].map! { |re| matr[i][i].star * re }
          matr[i][i] = RLSM::RegExp.new
        end

        #Substitute know Ri in everey row above
        ri = matr.pop

        matr.map! do |row|
          row.each_with_index do |re,j|
            row[j] = re + ri[j]
          end

          row[i] = RLSM::RegExp.new

          row
        end
      end

      #Examine now the last remaining first row (irritating...)
      regexp = matr.pop

      if regexp[0].empty?  #R0 depends not on R0
        return regexp.last
      else                 #R0 depends on R0
        return regexp[0].star * regexp.last
      end
    end
    
    #Calculate the transition monoid of the DFA. Because it is only possible for an complete DFA to compute the TM, the TM is calculated for the DFA returned by complete.
    def transition_monoid
      dfa = self.complete

      #Calculate the monoid elements
      trans_tab = [["", dfa.transition_function("")]]
      
      new_elements = true
      str_length = 1
      while new_elements
        new_elements = false
        dfa.each_str_with_length(str_length) do |str|
          tf = dfa.transition_function(str)
          unless trans_tab.map { |s,f| f}.include? tf
            trans_tab << [str, tf]
            new_elements = true
          end
        end
        str_length += 1
      end
     
      #Calculate the binary operation
      binop = [(0...trans_tab.size).to_a]

      (1...trans_tab.size).each do |i|
        str = trans_tab[i].first
        binop << trans_tab.map do |s, tf|
          trans_tab.map {|st,f| f }.index(dfa.transition_function(str + s))
        end
      end

      
      RLSM::Monoid.new binop.map { |row| row.join(',') }.join(' ')      
    end

    #Returns the syntactic monoid which belongs to the language accepted by the DFA. (In fact, the transition monoid of the minimal DFA is returned, both monoids are isomorph)
    def syntactic_monoid
      minimize.transition_monoid
    end

    #Returns a string represantation
    def to_s
      @states.map { |state| state.to_s }.join("\n")
    end

    def inspect
      "<#{self.class}: #{@states.map {|c| c.label }.join(', ') }"
    end

        

    protected
    def each_str_with_length(length)
      if length == 0
        yield ""
        return
      end
      
      str = [@alphabet.first.clone]*length
      pos = length-1
      finished = false
      loop do
        yield str.join

        loop do
          if str[pos] == @alphabet.last
            if pos == 0
              finished = true
              break
            end
            str[pos] = @alphabet.first
            pos -= 1
          else
            str[pos] = @alphabet[@alphabet.index(str[pos])+1]
            pos += 1 unless pos == length-1
            break
          end
        end

        break if finished
      end            
    end
    
    private
    def _get_state(label)
      @states.find { |state| state.label == label }
    end
    
    def _class_index_of(sp, s)
      sp.each_with_index { |sc,i| return i if sc.include? s }
    end
    
    def new_state_partition(sp)
      res = []
      sp.each do |set| 
        partitionate_set(set, sp).compact.each do |s|
          res << s
        end
      end
      
      res
    end
    
    def partitionate_set(s, p)
      #A singelton set is already partitionated
      return s if s.empty?

      acc_chars = s.first.accepted_chars.sort

      #Find the classes in which the first element of s is transitionated
      classes = {}

      acc_chars.each do |c|
        classes[c] = p.find { |set| set.include? s.first.process(c) }
      end

      first_class = s.find_all do |x|
        acc_chars.all? { |c| classes[c].include? x.process(c) } and
          acc_chars == x.accepted_chars.sort
      end
    
      rest = s - first_class

      [first_class, *partitionate_set(rest, p)]
    end
  end

  class DFA::State
    def initialize(dfa, label, opts = {})
      @label = label
      @dfa = dfa
      @is_initial = opts[:initial] || false
      @is_final = opts[:final] || false
      
      @trans = {}
    end
    
    attr_accessor :label
    
    def initial?
      @is_initial
    end
    
    def final?
      @is_final
    end

    #Return true if this state is dead. A state is dead if there is know edge leading to another state and the state himself isn't a final state.
    def dead?
      (@trans.empty? or reachable_states == [self]) and not final?
    end

    #Return true if this state is a trap state. A trap state is a dead_state which accepts all alphabet elements and is reachable. A trap state is useful if a complete DFA is requested.
    def trap?
      dead? and reachable? and accepted_chars.sort == @dfa.alphabet.sort
    end

    def add_transition(char, dest_state)
      if @trans.key? char
        raise DFAException, "Have already a transition for #{char}"
      end
 
      @trans[char] = dest_state
    end

    def process(char)
      if @trans.key? char
        @trans[char]
      else
        nil
      end
    end

    def complete?
      @trans.size == @dfa.alphabet.size
    end

    def accepted_chars
      @trans.keys
    end

    def reachable_states
      @trans.values
    end

    def transitions
      @trans
    end

    def remove_transitions_to_dead_states(opt = {})
      if opt[:except_trap]
        @trans = @trans.reject do |char, state| 
          state.dead? and not state.trap?
        end
      else
        @trans = @trans.reject { |char, state| state.dead? }
      end
    end

    def reachable?
      @dfa.reachable_states.include? self
    end

    def unreachable?
      not reachable?
    end
    
    def to_s
      str = ''
      str += '-> ' if initial?
      str += '* ' if final?
      str += @label.to_s + ': '
      str += @trans.to_a.map { |c,s| c+' -> '+s.label.to_s }.join('; ')

      str
    end

    def ==(other)
      return false if other.class != DFA::State
      return false if label != other.label

      @trans.all? do |char, state|
        state.label == other.process(char).label
      end
    end
  end
end
