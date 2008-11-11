require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm', 'dfa')

describe RLSM::DFA do
  before :each do
    @dfa = RLSM::DFA.new ['a'],[0],0,[0],[['a',0,0]]
    @dfa2 = RLSM::DFA.new( ['a', 'b'], [0,1,2], 0, [2],
                           [['a',0,0], ['a',1,2], ['a',2,2],
                            ['b',0,1], ['b',1,1], ['b',2,2]])
    @dfa3 = RLSM::DFA.new( ['a', 'b'], [0,1,2], 0, [2],
                           [['a',0,0], ['a',1,2], ['a',2,2],
                            ['b',0,1], ['b',1,1]])

    @dfa4 = RLSM::DFA.new( ['a', 'b'], [0,1,2,3,4], 0, [2,3],
                           [['a',0,0], ['a',1,2], ['a',2,2],
                            ['b',0,1], ['b',1,1], 
                            ['a',3,4], ['a',4,3], ['b',3,2]])

    @dfa5 = RLSM::DFA.new( ['a', 'b'], [0,1,2], 0, [1],
                           [['a',0,0], ['a',1,2], ['a',2,2],
                            ['b',0,1], ['b',1,1]])

    @dfa5b = RLSM::DFA.new( ['a', 'b'], [0,1,'c'], 0, [1],
                           [['a',0,0], ['a',1,'c'], ['a','c','c'],
                            ['b',0,1], ['b',1,1]])
  end

  it "should have an initial state" do
    @dfa.initial_state.should_not be_nil
    @dfa.initial_state.label.should == '0'
    @dfa2.initial_state.should_not be_nil
    @dfa2.initial_state.label.should == '0'
  end

  it "should know the number of states" do
    @dfa.num_states.should == 1
    @dfa2.num_states.should == 3
  end

  it "should know the number of final states" do
    @dfa.num_finals.should == 1
    @dfa2.num_finals.should == 1
  end

  it "should know if it is complete" do
    @dfa.complete?.should == true
    @dfa2.complete?.should == true
    @dfa3.complete?.should == false
  end

  it "should complete a non complete DFA if requested" do
    @dfa3.complete.should be_complete
  end

  it "should find dead states" do
    [@dfa,@dfa2,@dfa3].each { |d| d.dead_states?.should == false }

    @dfa5.dead_states?.should == true
    @dfa5.dead_states.map { |s| s.label }.should == ['2']
  end

  it "should find unreachable states" do
    [@dfa,@dfa2,@dfa3].each { |d| d.unreachable_states?.should == false }

    @dfa4.unreachable_states?.should == true
    @dfa4.unreachable_states.size.should == 2
    @dfa4.unreachable_states.map { |s| s.label }.sort.should == ['3','4']
  end

  it "should remove dead states" do
    @dfa5.remove_dead_states.states.map { |s| s.label }.should == ['0','1']
  end

  it "should remove unreachable states" do
    d = @dfa4.remove_unreachable_states
    d.states.map { |s| s.label }.sort.should == ['0','1','2']
  end

  it "should minimize a DFA" do
    d = RLSM::DFA.new(['a','b','c'], [0,1,2,3,4], 0, [4],
                  [['a',0,1], ['b',0,2], ['c',1,3], ['c',2,3], ['c',3,4]])

    d.minimize!
    d.states.map { |s| s.label }.sort.should == ['0','12', '3','4']
  end

  it "should check for isomorphisms" do
    @dfa2.should be_isomorph_to(@dfa2)
    @dfa5.should be_isomorph_to(@dfa5b)
    @dfa3.should_not be_isomorph_to(@dfa2)
  end

  it "should calculate the transition monoid" do
    @dfa.transition_monoid.should == RLSM::Monoid.new('0')
  end
  
  it "should caclulate a RegExp representation" do
    @dfa.to_regexp.to_s.should == 'a*'
  end
end
