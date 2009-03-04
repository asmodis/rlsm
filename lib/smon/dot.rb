module SMONLIBdot
  #Creates a picture of a DFA using dot.
  def dfa2pic(dfa)
    STDERR.puts "Not implemented."
  end

  #Creates string which is a dot representation of a DFA.
  def dfa2dot(dfa)
    STDERR.puts "Not implemented."
  end

  def self.included(child)
    unless system("which dot > /dev/null")
      remove_method :dfa2pic
      STDERR.puts "W: No 'dot' command found."
    end
  end
end
