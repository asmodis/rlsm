require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm', 'regexp')

describe RLSM::RegExp do
  ['(ab', '(|ab)', '(ab|)', 'ab(*)', '(*a|b)', 'ab()cd'].each do |str|
    it "should raise error for input #{str}" do
      lambda { RLSM::RegExp.new str }.should raise_error(Exception)
    end
  end

  ['', '&', 'a', 'a|b', 'ab', '(a|b)c', '(a*|bc&&&d)|abc|(a|b|c)*'].each do |s|
    it "should accept the input #{s}" do
      lambda { RLSM::RegExp.new s }.should_not raise_error(Exception)
    end
  end
  
  it "should simplify a input" do
    RLSM::RegExp.new('a&&**&&c***(bbbcccaa)**').to_s.should == 'ac*(bbbcccaa)*'
  end

  it "should convert a regexp to an dfa" do
    dfa1 = RLSM::RegExp.new('(a|b)aa*(&|b)a*').to_dfa
    dfa1.states.size.should == 4
    dfa1.final_states.map {|f| f.label}.sort.should == ['1', '2'].sort
  end
end
