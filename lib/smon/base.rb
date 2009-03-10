module SMONLIBbase
  def quit
    exit
  end

  def monoid(mon, options = {})
    @objects << RLSM::Monoid.new(mon, options)
    puts "=> #{@objects.last.inspect}" if @interactive
    @monoid = @objects.last
  end

  def dfa(dfa)
    @objects << RLSM::DFA.create(dfa)
    puts "=> #{@objects.last.inspect}" if @interactive
    @dfa = @objects.last
  end

  def regexp(re)
    @objects << RLSM::RE.new(re)
    puts "=> #{@objects.last.inspect}" if @interactive
    @re = @objects.last
  end

  def show(obj = nil)
    obj ||= @objects.last
    if obj
      @out.puts obj.to_s
      @out.puts
    else
      STDERR.puts "No object present."
    end
  end

  def describe(obj = nil)
    obj ||= @objects.last

    if obj
      monoid, dfa = obj.to_monoid, obj.to_dfa
      print_language(monoid, dfa)
      print_monoid_properties(monoid)
      print_submonoids(monoid)
      print_syntactic_properties(monoid)
    else
      STDERR.puts "No object present."
    end
  end


  def self.included(mod)
    #Setting up the help system
    mod.add_help :type => 'cmd',
    :name => 'quit',
    :usage => 'quit',
    :summary => "Quits the program.",
    :description => <<DESC
The 'quit' command is a synonym for the 'exit' command.
Only needed in interactive mode.
DESC

    mod.add_help :type => 'cmd',
    :name => 'monoid',
    :usage => "monoid '<mon>' [<options>]",
    :summary => "Creates a new monoid.",
    :description => <<DESC
The <mon> parameter is a description of the binary operation
of the monoid as a table. The <mon> parameter is parsed as follows:
  * Rows are seperated by spaces.
  * Elements in a row are seperated by commas (',').
    Commas are optional if each element consists of a single letter.
  * IMPORTANT: The first row and column belongs to the neutral element!
  * IMPORTANT: The <mon> parameter must be enclosed
    in single or double quotes.

EXAMPLES:
monoid '1ab aab bbb'
monoid 'e,a1,a2 a1,a2,e a2,e,a1'

The optional <options> parameter is a Hash and can take the following keys:
 :elements  -> an array
               The value of this key is used to rename
               the elements of the monoid.
 :normalize -> true|false
               If true, the monoid will be normalized, i.e.
               the generating elements will be moved to the beginning.
 :rename    -> true|false
               If true, the elements ill be renamed to 1 a b c ...

Adds the  created monoid to the @objects array
and sets the variable @monoid to the created monoid.
DESC

    mod.add_help :type => 'cmd',
    :name => 'dfa',
    :usage => "dfa <hash>",
    :summary => "Creates a new DFA.",
    :description => <<DESC
The <hash> parameter must have the following keys:
 :initial     -> label
                 The label of the initial state.
 :finals      -> an Array
                 The array contains the labels of the final states.
 :transitions -> an Array
                 The array contains the transitions of the monoid.
                 A transition is an array consisting of
                  the label of the transition
                  the starting state of the transition
                  the destination of the transition

EXAMPLE:
dfa :initial => '0', :finals => ['1'], :transitions => [['a','0','1']]

Adds the  created DFA to the @objects array
and sets the variable @dfa to the created DFA.
DESC

    mod.add_help :type => 'cmd',
    :name => 'regexp',
    :usage => "regexp '<re>'",
    :summary => "Creates a new Regular Expression.",
    :description => <<DESC
The <re> parameter is simply a regular expression. Special Symbols are
 #{RLSM::RE::Lambda} -> the empty word
 #{RLSM::RE::Star} -> the Kleene star
 #{RLSM::RE::Union} -> the union of two regexps
 #{RLSM::RE::LeftBracket}, #{RLSM::RE::RightBracket} -> Parenthesis to group a subregexp

IMPORTANT: The <re> parameter must be enclosed in single or double quotes.
           Parentheses must be balanced.

EXAMPLES:
regexp 'a'
regexp
'#{RLSM::RE::Lambda}#{RLSM::RE::Union}#{RLSM::RE::LeftBracket}a#{RLSM::RE::Union}aab#{RLSM::RE::Star}#{RLSM::RE::RightBracket}'

Adds the  created regular expression to the @objects array
and sets the variable @re to the created regular expression.
DESC

    mod.add_help :type => 'cmd',
    :name => 'show',
    :usage => "show [<obj>]",
    :summary => "Prints a very concise description of <obj>.",
    :description => <<DESC
The optional <obj> parameter is either a monoid, a DFA or a RE.
If none is given the last created object will be used.
DESC

    mod.add_help :type => 'cmd',
    :name => 'describe',
    :usage => "describe [<obj>]",
    :summary => "Prints a verbose description of <obj>.",
    :description => <<DESC
The optional <obj> parameter is either a monoid, a DFA or a RE.
If none is given the last created object will be used.
DESC
  end

  private
  def print_syntactic_properties(m)
    if m.syntactic?
      @out.puts "SYNTACTIC PROPERTIES:"

      m.all_disjunctive_subsets.each do |ds|
        @out.puts "{#{ds.join(',')}} => #{m.to_dfa(ds).to_re}"
      end
      @out.puts
    end
  end

  def print_submonoids(m)
    subs = m.proper_submonoids.map do |sm|
      binary_operation(sm)
    end

    if subs.empty?
      @out.puts "SUBMONOIDS: none"
      @out.puts
    else
      @out.puts "SUBMONOIDS:"
      rows = [[]]
      width = 0
      subs.each do |sm|
        spl = sm.split("\n")
        if (width + spl[0].length) <= 30
          rows.last << spl
          width += spl[0].length
        else
          rows << [spl]
          width = spl[0].length
        end
      end
      rows.each do |row|
        max_lines = row.map { |sm| sm.size }.max

        row.map! { |sm| sm + [' '*sm[0].length]*(max_lines-sm.size) }
        (0...row[0].size).each do |i|
          @out.puts row.map { |sm| sm[i] }.join('  ')
        end
        @out.puts
      end
    end
  end

  def print_monoid_properties(m)
    block1 = []
    block1 << "PROPERTIES OF THE MONOID:"
    block1 << "   Generator: {#{m.generating_subset.join(',')}}"
    block1 << "       Group: #{m.group?}"
    block1 << " Commutative: #{m.commutative?}"
    block1 << "  Idempotent: #{m.idempotent?}"
    block1 << "   Syntactic: #{m.syntactic?}"
    block1 << "   Aperiodic: #{m.aperiodic?}"
    block1 << "   L-trivial: #{m.l_trivial?}"
    block1 << "   R-trivial: #{m.r_trivial?}"
    block1 << "   D-trivial: #{m.d_trivial?}"
    block1 << "Zero element: #{!m.zero_element.nil?}"

    max_length = block1.map { |row| row.length }.max
    block1.map! { |row| row + ' '*(max_length - row.length) }

    block2 = []
    block2 << "SPECIAL ELEMENTS:"
    block2 << " Idempotents: #{m.idempotents.join(',')}"
    if m.zero_element
      block2 << "Zero element: #{m.zero_element}"
    else
      lz = (m.left_zeros.empty? ? ['none'] : m.left_zeros).join(',')
      block2 << "  Left-Zeros: #{lz}"
      rz = (m.right_zeros.empty? ? ['none'] : m.right_zeros).join(',')
      block2 << " Right-Zeros: #{rz}"
    end
    block2 << ''
    block2 << ''
    block2 << "GREEN RELATIONS:"
    lc = m.l_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    rc = m.r_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    hc = m.h_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    dc = m.d_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    block2 << "L-Classes: #{lc}"
    block2 << "R-Classes: #{rc}"
    block2 << "H-Classes: #{hc}"
    block2 << "D-Classes: #{dc}"
    block2 << ''

    @out.puts block1.zip(block2).map { |row| row.join('  ') }.join("\n")
    @out.puts
  end

  def print_language(m,d)
    @out.puts "\nDFA:\n#{d.to_s}\n"
    @out.puts "\nMONOID:\n"
    @out.puts binary_operation(m)
    @out.puts
  end

  def binary_operation(monoid)
   max_length = monoid.elements.map { |e| e.length }.max
    rows = monoid.binary_operation.map do |row|
       row.map do |e|
        space = ' '*((max_length - e.length)/2)
        extra_space = ' '*((max_length - e.length)%2)
        space + extra_space + e + space
      end.join(' | ')
    end

    first =  ' '*(max_length + 2) + '| ' + rows[0].clone + ' |'
    seperator = first.gsub(/[^|]/,'-').gsub('|', '+')

    rows.map! do |row|
      ' ' + row[/^[^|]+\|/] + ' ' + row + " |"
    end

    result = [first]
    result << seperator
    result << rows.join("\n" + seperator + "\n")
    result << seperator

    result.join("\n")
  end

  def get_elements(obj)
    [obj.to_monoid, obj.to_dfa, obj.to_re]
  end
end
