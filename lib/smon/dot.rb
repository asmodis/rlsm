module SMONLIBdot
  #Creates a picture of a DFA using dot.
  def dfa2pic(dfa, options = {:format => 'png'})
    filename = options[:filename] || SMON.tmp_filename
    File.open(filename + ".dot", "w") { |f| f.puts dfa2dot(dfa) }
    system "dot -T#{options[:format]} -o #{filename}.#{options[:format]} #{filename}.dot"
    File.delete(filename + ".dot")
  end

  #Creates string which is a dot representation of a DFA.
  def dfa2dot(dfa)
    str = "digraph {\n"
    str += "size=\"2,2\"\nratio=1.0\n"
    str += "node [shape=circle]\n"
    str += "preinit [shape=plaintext, label=\"\"]\n"
    (dfa.states - dfa.finals).each do |state|
      str += state + "\n"
    end
    str += "node [shape=doublecircle]\n"
    dfa.finals.each do |state|
      str += state + "\n"
    end
    str += "preinit -> #{dfa.initial_state}\n"
    dfa.states.product(dfa.states).each do |s1,s2|
      res = dfa.transitions.find_all { |tr| tr[1] == s1 and tr[2] == s2 }
      unless res.empty?
        label = res.map { |tr| tr[0] }.join(',')
        str += s1 + "->" + s2 + "[label=\"#{label}\"]\n"
      end
    end

    str + "}"
  end

  def self.included(mod)
    unless system("which dot > /dev/null")
      remove_method :dfa2pic
      STDERR.puts "W: No 'dot' command found."
    else
      mod.add_help :type => 'cmd',
      :name => 'dfa2pic',
      :summary => 'Creates a picture of a DFA using dot.',
      :usage => 'dfa2pic <dfa> [<options>]',
      :description => <<DESC
The parameter <dfa> is a DFA which will be transformed with the dot program.
Possible optional parameters are
 :format -> a String.
            The output format. Defaults to 'png'. Could be all what dot
            accepts.

 :filename -> a String.
              The filename of the output.
DESC
    end

    mod.add_help :type => 'cmd',
      :name => 'dfa2dot',
      :summary => 'Creates a string with dot commands.',
      :usage => 'dfa2pic <dfa>',
      :description => <<DESC
The parameter <dfa> is a DFA which will be transformed to a string
which is a valid dot description of a digraph.
DESC
  end
end
