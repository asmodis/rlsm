require File.join(File.dirname(__FILE__), 'helpers')

require "rlsm/dfa"
require "rlsm/monoid"

context "Parsing the description of a DFA." do
  test "A description of the DFA is required." do
    assert_raises ArgumentError do
      RLSM::DFA.new
    end
  end
  
  test "The empty string is not accepted" do
    assert_raises RLSM::Error do
      RLSM::DFA.new ""
    end
  end

  test "A valid description should be parsed" do
    assert_nothing_raised do
      RLSM::DFA.new "}s1-a->*s2 s2-b->s1"
    end
  end

  test "The description must include an initial state indicator." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "s1"
    end
  end

  test "The description may not include more than one initial state." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1-a->}s2"
    end
  end

  test "A DFA without transitions is allowed." do
    assert_nothing_raised do
      RLSM::DFA.new "}s1"
    end
  end

  test "A transition arrow must have a starting dash." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 a-> s2"
    end
  end

  test "A transition arrow must have a closing arrow." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 -a> s2"
    end

    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 -a- s2"
    end
  end

  test "A transition must have at least one label." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 --> s2"
    end
  end

  test "Multiple labels must be seperated by a comma." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 -a;b-> s2"
    end
  end

  test "Trailing and leading whitspaces will be ignored." do
    assert_nothing_raised do
      RLSM::DFA.new " }s1 -a, b-> *s2  "
    end
  end

  test "A transition must start with a state." do
    assert_raises RLSM::Error do
      RLSM::DFA.new " -a-> }s2"
    end
  end

  test "A transition must end with a state." do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 -a-> "
    end
  end
end

context "Creation of a DFA." do
  test "A DFA must have an initial state." do
    dfa = RLSM::DFA.new "}s1"

    assert_equal 's1', dfa.initial_state

    dfa = RLSM::DFA.new "}s2"

    assert_equal 's2', dfa.initial_state
  end

  test "A DFA without final states is allowed." do
    assert_equal [], RLSM::DFA.new("}s1").final_states
  end

  test "A DFA may have final states." do
    assert_equal ['s2'], RLSM::DFA.new("}s1-a->*s2").final_states
  end

  test "The initial state may be a final state" do
    assert_equal ['s1'], RLSM::DFA.new("}*s1-a->s2").final_states
    assert_equal ['s1'], RLSM::DFA.new("*}s1-a->s2").final_states
  end

  test "A DFA may have one state" do
    assert_equal ['s1'], RLSM::DFA.new("}*s1-a->s1").states
  end

  test "A DFA may have more than one state" do
    assert_equal ['s1','s2'], RLSM::DFA.new("}s1-a->*s2").states
  end

  test "A DFA may have more than one state without transitions." do
    assert_equal ['s1','s2'], RLSM::DFA.new("}s1 s2").states
  end

  test "A DFA must have an alphabet." do
    assert_equal ['1','a'], RLSM::DFA.new("}s1-a,1->*s1").alphabet
    assert_equal ['a','b'], RLSM::DFA.new("}s1-a,b->*s1").alphabet
  end

  test "A DFA may have none transitions." do
    assert_equal [], RLSM::DFA.new("}s1").transitions
  end

  test "A DFA may have transitions." do
    assert_equal [ %w(s1 s2 a) ], RLSM::DFA.new("}s1-a->s2").transitions
    assert_equal( [ %w(s1 s2 a), %w(s1 s2 b) ], 
                  RLSM::DFA.new("}s1-a,b->s2").transitions)
  end

  test "Transition labels out from one state must be unique" do
    assert_raises RLSM::Error do
      RLSM::DFA.new "}s1 -a-> s2 s1-a->s3"
    end
  end

  test "Duplications of transitions are allowed." do
    assert_nothing_raised do
      RLSM::DFA.new "}s1 -a-> s1 s1 -a->s1 s2 -a,a,a->s2"
    end
  end
end

context "Properties of a state" do
  test "There may be unreachable states." do
    dfa = RLSM::DFA.new "}s1 s2"
    
    assert dfa.reachable?('s1')
    refute dfa.reachable?('s2')
  end

  test "A DFA may be connected." do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s2 s3 -a-> s2"
    dfa2 = RLSM::DFA.new "}s1 -a-> *s2 s2 -a-> s3"

    refute dfa1.connected?
    assert dfa2.connected?
  end

  test "A DFA may be complete." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s1"
    dfa2 = RLSM::DFA.new "}s1 s2"

    assert dfa1.complete?
    assert dfa2.complete?
  end

  test "A DFA may be not complete." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2"
    dfa2 = RLSM::DFA.new "}s1 -a,b-> s2 s2 -a-> s1"

    refute dfa1.complete?
    refute dfa2.complete?
  end
  
  test "Dead States: Initial state is never dead." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}s1"
    dfa3 = RLSM::DFA.new "}s1 s2 s3"

    refute dfa1.dead?('s1')
    refute dfa2.dead?('s1')
    refute dfa3.dead?('s1')
  end

  test "Dead States: Final states are never dead." do
    dfa = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"

    refute dfa.dead?('s3')
  end

  test "Dead States: A state may be dead." do
    dfa = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"

    assert dfa.dead?('s2')
  end

  test "Arguments for state properties must be states of the DFA." do
    dfa = RLSM::DFA.new "}s1"
    assert_raises RLSM::Error do
      dfa.dead? "s3"
    end

    assert_raises RLSM::Error do
      dfa.reachable? "s3"
    end
  end
end

context "Transformations of a DFA" do
  test "DFA#== : Equal DFAs must have same alphabet." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}s1 -c-> s2 s1 -b-> *s3 s2 -c,b-> s2 s3 -c,b-> s3"

    refute_equal dfa1, dfa2
  end

  test "DFA#== : Equal DFAs must have same initial state." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}t1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"

    refute_equal dfa1, dfa2
  end

  test "DFA#== : Equal DFAs must have same final_states." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}*s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"

    refute_equal dfa1, dfa2
  end

  test "DFA#== : Equal DFAs must have same states." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}s1 -a-> t2 s1 -b-> *s3 t2 -a,b-> t2 s3 -a,b-> s3"

    refute_equal dfa1, dfa2
  end

  test "DFA#== : Equal DFAs must have same transitions." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a-> s3"

    refute_equal dfa1, dfa2
  end
  
  test "DFA#== : Equal monoids must be equal." do
    dfa1 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"
    dfa2 = RLSM::DFA.new "}s1 -a-> s2 s1 -b-> *s3 s2 -a,b-> s2 s3 -a,b-> s3"

    assert_equal dfa1, dfa2
  end
  
  test "DFA#minimize! : Minimizing a connected complete DFA." do
    dfa = RLSM::DFA.new "}i -a-> 1 i -b-> 2 1 -b-> 2 2-b->1 1-a->3 2-a->*3 3 -a,b-> trap trap -a,b-> trap"

    dfa.minimize!

    expected = RLSM::DFA.new "}i-a,b-> 1 1 -b-> 1 1-a->*3"
    assert_equal expected, dfa
  end
  
  test "DFA#minimize! : Minimizing a connected DFA." do
    dfa = RLSM::DFA.new "}i -a-> 1 i -b-> 2 1 -b-> 2 2-b->1 1-a->3 2-a->*3"

    dfa.minimize!

    expected = RLSM::DFA.new "}i-a,b-> 1 1 -b-> 1 1-a->*3"
    assert_equal expected, dfa
  end

  test "DFA#minimize! : Minimizing a unconnected DFA." do
    dfa = RLSM::DFA.new "}i -a-> 1 i -b-> 2 1 -b-> 2 2-b->1 1-a->3 2-a->*3 s4-a->s5 *s5-a,b-> 3"

    dfa.minimize!

    expected = RLSM::DFA.new "}i-a,b-> 1 1 -b-> 1 1-a->*3"
    assert_equal expected, dfa
  end

  test "DFA#minimal? : Recognizing a minimal DFA." do
    assert RLSM::DFA.new("}i-a,b-> 1 1 -b-> 1 1-a->*3").minimal?
  end

  test "DFA#minimal? : Recognizing a nonminimal DFA." do
    refute RLSM::DFA.new("}i -a-> 1 i -b-> 2 1 -b-> 2 2-b->1 1-a->3 2-a->*3").minimal?
  end

  test "DFA#=~ : A DFA is isomorph with itself" do
    dfa = RLSM::DFA.new "}s1 -a-> *s1"
    assert dfa =~ dfa
  end

  test "DFA#=~ : A DFA is not isomorph to other things than DFAs." do
    dfa = RLSM::DFA.new "}s1 -a-> *s1"
    refute dfa =~ :dfa
  end

  test "DFA#=~ : A DFA is isomorph with another if only state names differs" do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s1"
    dfa2 = RLSM::DFA.new "}t1 -a-> *t1"
    assert dfa1 =~ dfa2
  end

  test "DFA#=~ : A DFA is not isomorph with another if alphabet differs" do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s1"
    dfa2 = RLSM::DFA.new "}s1 -b-> *s1"
    refute dfa1 =~ dfa2
  end

  test "DFA#=~ : A DFA is isomorph with another if number of state differs" do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s1 s3"
    dfa2 = RLSM::DFA.new "}t1 -a-> *t1"
    refute dfa1 =~ dfa2
  end

  test "DFA#=~ : DFA not isomorph with other if number of final state differs" do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s1 *s3"
    dfa2 = RLSM::DFA.new "}t1 -a-> *t1 s3"
    refute dfa1 =~ dfa2
  end

  test "DFA#=~ : DFA not isomorph with other if transition number differs" do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s1 s1-b->*s3"
    dfa2 = RLSM::DFA.new "}s1 -a,b-> *s1 *s3-a->s3"
    refute dfa1 =~ dfa2
  end

  test "DFA#=~ : DFA not isomorph with other if transitions differs" do
    dfa1 = RLSM::DFA.new "}s1 -a-> *s1 s1-b->*s3"
    dfa2 = RLSM::DFA.new "}s1 -a,b-> *s1 *s3"
    refute dfa1 =~ dfa2
  end


  test "DFA#equivalent_to : Recognising equivalent DFAs." do
    dfa1 = RLSM::DFA.new "}i -a-> 1 i -b-> 2 1 -b-> 2 2-b->1 1-a->3 2-a->*3"
    dfa2 = RLSM::DFA.new "}i-a,b-> 1 1 -b-> 1 1-a->*3"

    assert dfa1.equivalent_to(dfa2)
  end

  test "DFA#equivalent_to : Recognising nonequivalent DFAs." do
    dfa1 = RLSM::DFA.new "}i -a-> 1 i -b-> 2 1 -b-> 2 2-b->1 1-a->3 2-a->*3"
    dfa2 = RLSM::DFA.new "}i-a,b-> 1 1-a->*3"

    refute dfa1.equivalent_to(dfa2)
  end
end

context "Accepting of words, transition monoid" do
  test "Following the transitions from an arbitrary state." do
    dfa = RLSM::DFA.new "}s1-a->s2 s2 -a-> *s3 s3 -b-> s2"

    assert_equal "s2", dfa['s3', 'b']
    assert_equal "s2", dfa['s1', 'a']
    assert_equal "s2", dfa['s3', 'bab']
  end

  test "Following the transitions from the initial state." do
    dfa = RLSM::DFA.new "}s1-a->s2 s2 -a-> *s3 s3 -b-> s2"

    assert_equal "s2", dfa << "a"
    assert_equal "s2", dfa << "aabab"
    assert_equal "s3", dfa << "aa"
  end

  test "Requesting a nonexistent transition." do
    dfa = RLSM::DFA.new "}s1-a->s2 s2 -a-> *s3 s3 -b-> s2 s4"

    assert_nil dfa << "b"
    assert_nil dfa['s4','a']
  end

  test "Requesting a transition from a nonexistant state." do
    assert_raises RLSM::Error do
      RLSM::DFA.new("}s1")['s2', 'a']
    end
  end

  test "Accepting words." do
    dfa = RLSM::DFA.new "}s1-a->s2 s2 -a-> *s3 s3 -b-> s2"

    assert dfa.accepts?("aa")
    assert dfa.accepts?("aaba")
  end

  test "Rejecting words." do
    dfa = RLSM::DFA.new "}s1-a->s2 s2 -a-> *s3 s3 -b-> s2"

    refute dfa.accepts?("a")
    refute dfa.accepts?("aab")
  end


  
  test "Calculating the transition monoid." do
    dfa = RLSM::DFA.new "}s1-a->s2 s2 -a-> *s3 s3 -b-> s2"
    expected_monoid = RLSM::Monoid[ <<MONOID
 id,  a,  b, aa, ab, ba, bb,aab,aba
  a, aa, ab, bb,aab,aba, bb, bb, aa
  b, ba, bb, bb,  b, bb, bb, bb, ba
 aa, bb,aab, bb, bb, aa, bb, bb, bb
 ab,aba, bb, bb, ab, bb, bb, bb,aba
 ba, bb,  b, bb, bb, ba, bb, bb, bb
 bb, bb, bb, bb, bb, bb, bb, bb, bb
aab, aa, bb, bb,aab, bb, bb, bb, aa
aba, bb, ab, bb, bb,aba, bb, bb, bb 
MONOID
]
    assert_equal expected_monoid, dfa.transition_monoid    
  end

end

context "DFA#to_regexp" do
  test "Should return emptyset for DFA['}s1']" do
    assert_equal RLSM::RegExp.empty_set, RLSM::DFA['}s1'].to_regexp
  end

  test "Should return empty word for DFA['}*s1']" do
    assert_equal RLSM::RegExp.empty_word, RLSM::DFA['}*s1'].to_regexp
  end

  test "Should return a* for DFA['}*s1-a->s1']" do
    assert_equal RLSM::RegExp['a*'], RLSM::DFA['}*s1-a->s1'].to_regexp
  end
end
