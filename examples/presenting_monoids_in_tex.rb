require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')
require 'enumerator'
require 'tempfile'

class Presenter
  @@template = <<TEMPLATE
\\begin{minipage}{\\linewidth}
%%heading%%

\\begin{tabular}[t]{l}
 %%table2tex%%
\\end{tabular}\\\\[2ex]

\\begin{tabular}{llcll}
  \\multicolumn{2}{l}{\\textbf{%l%props%%:}} & & \\multicolumn{2}{l}{\\textbf{%l%special%%:}} \\\\
  %l%generator%%: & %%generating_subset%%    & & %l%idem_els%%: & %%idempotents%% \\\\
  %l%group%%:     & %%group?%%       &         & %%zero1%% \\\\
  %l%comm%%:      & %%commutative?%% &         & %%zero2%% \\\\
  %l%idem%%:      & %%idempotent?%%  &         &                  & \\\\
  %l%syn%%:       & %%syntactic?%%   &         & \\multicolumn{2}{l}{\\textbf{%l%green%%:}} \\\\
  %l%aper%%:      & %%aperiodic?%%   &         & %l%lclasses%%:   & %%l_classes%% \\\\
  %l%ltriv%%:     & %%l_trivial?%%   &         & %l%rclasses%%:   & %%r_classes%% \\\\
  %l%rtriv%%:     & %%r_trivial?%%   &         & %l%hclasses%%:   & %%h_classes%% \\\\
  %l%jtriv%%:     & %%j_trivial?%%   &         & %l%dclasses%%:   & %%d_classes%% \\\\
  %l%has_zero%%:  & %%zero?%%        &         &                  &               \\\\
\\end{tabular}\\\\[1ex]

\\textbf{%l%submons%%:} %%submonoids%%

%%syntactic_properties%%
\\end{minipage}
TEMPLATE

  @@lang = { 
    :en => Hash['table', 'Binary Operation', 
                'dfa', 'DFA',
                'props', 'Properties of the monoid',
                'special','Special elements',
                'generator', 'Generator',
                'group', 'Group',
                'comm', 'Commutative',
                'idem', 'Idempotent',
                'syn', 'Syntactic',
                'aper', 'Aperiodic',
                'ltriv', 'L-trivial',
                'rtriv', 'R-trivial',
                'jtriv', 'J-trivial',
                'has_zero', 'Has zero element',
                'idem_els', 'Idempotents',
                'zero', 'Zero element',
                'lzero', 'Left zeros',
                'rzero', 'Right zeros',
                'green', 'Green Relations',
                'lclasses', 'L-classes',
                'rclasses', 'R-classes',
                'hclasses', 'H-classes',
                'dclasses', 'D-classes',
                'submons', 'Proper submonoids',
                'none', 'none',
                'synprop','Syntactic Properties',
                'disj', 'Disjunctive Subset',
                'reg', 'Regular Expression',
                true, 'yes',
                false, 'no'], 
    :de => Hash['table', 'Binaere Operation',
                'dfa', 'DFA',
                'props', 'Eigenschaften des Monoids',
                'special','Spezielle Elemente',
                'generator', 'Erzeuger',
                'group', 'Gruppe',
                'comm', 'Kommutativ',
                'idem', 'Idempotent',
                'syn', 'Syntaktisch',
                'aper', 'Aperiodisch',
                'ltriv', 'L-trivial',
                'rtriv', 'R-trivial',
                'jtriv', 'J-trivial',
                'has_zero', 'mit Nullelement',
                'idem_els', 'Idempotente Elemente',
                'zero', 'Nullelement',
                'lzero', 'Linksnullelemente',
                'rzero', 'Rechtsnullelemente',
                'green', 'Greensche Relationen',
                'lclasses', 'L-Klassen',
                'rclasses', 'R-Klassen',
                'hclasses', 'H-Klassen',
                'dclasses', 'D-Klassen',
                'submons', 'Echte Untermonoide',
                'none', 'keine',
                'synprop','Syntaktische Eigenschaften',
                'disj', 'Disjunktive Teilmenge',
                'reg', 'Regulaerer Ausdruck',
                true, 'ja',
                false, 'nein'] 
  }

  

  def self.to_latex(monoid, options = {})
    options[:lang] ||= :en
    presenter = Presenter.new(options[:monoid], options[:lang])
    output = @@template.dup
    @@lang[options[:lang]].each_pair do |key, text|
      output.sub!("%l%#{key}%%", text)
    end

    while output =~ /%%(\w+\??)%%/
      output.sub!($~[0], presenter.send($~[1].to_sym))
    end

    output
  end

  #Use with caution, many assumptions about the row parameter...
  def self.db_row_to_latex(row, options = {})    
    options[:lang] ||= :en

    monoid = RLSM::Monoid[row.first]

    presenter = Presenter.new(monoid, options[:lang])
    output = @@template.dup
    @@lang[options[:lang]].each_pair do |key, text|
      output.sub!("%l%#{key}%%", text)
    end

    #Use precalculated values
    ['zero?', 'syntactic?', 'commutative?', 'idempotent?','aperiodic?', 'l_trivial?',
     'r_trivial?', 'j_trivial?', 'group?'].each_with_index do |entry,i|
      output.sub!("%%#{entry}%%", @@lang[options[:lang]][row[i+6] == '1'])
    end

    while output =~ /%%(\w+\??)%%/
      output.sub!($~[0], presenter.send($~[1].to_sym))
    end

    output
  end

  def initialize(monoid,lang)
    @monoid = monoid 
    @lang = @@lang[lang]
  end

  def table2tex
    helper_table2tex(@monoid)
  end

  def heading
    "\\paragraph{Monoid #{@monoid.to_s}:}\\mbox{ }\\\\"
  end

  def dfa2tex(opts = { :dot => true })
    dfa = @monoid.to_dfa
    if opts[:dot] and not %x(which dot).empty?
      filename = tmp_filename
      dfa2pic dfa, :filename => filename, :format => 'plain'

      str = "\\begin{xy}\n0;<1.27cm,0cm>:\n"
      
      edges = []
      File.open(filename + ".plain", 'r').each_line do |line|
          values = line.split
        if ['edge','node'].include? values.first
          str += tex_xy_node(values)
        end
        edges << tex_xy_edge(values) if values.first == 'edge'
      end
      
      str += edges.join("\n")
      
      File.delete(filename + ".plain")
      
      return str + "\n\\end{xy}\n"
    else
      str = "\\begin{tabular}{r|" +
        (['c']*dfa.alphabet.size).join('|') + "}\n"
      str += " & " + dfa.alphabet.map do |l|
        "\\textbf{#{l}}"
      end.join(' & ') + " \\\\ \\hline\n"
      dfa.states.each do |state|
        tmp_str = ''
        tmp_str += "\\ensuremath{*}" if dfa.final_states.include? state
        tmp_str += "\\ensuremath{\\rightarrow}" if dfa.initial_state == state
        tmp_str += state + " & "
        tmp_str += dfa.alphabet.map do |letter|
          tmp = dfa[state,letter]
          tmp ? tmp : 'nil'
        end.join(' & ')
        str+= tmp_str + " \\\\\n"
      end
      
      return str + "\\end{tabular}\n"
    end
  end
  
  def submonoids
    submons = @monoid.proper_submonoids.map { |sm| helper_table2tex(sm) }

    if submons.empty?
      @lang['none'] + "\\\\\\\\[2ex]"
    else
      submons.join("\\quad") + "\\\\\\\\[2ex]"
    end
  end

  def zero1
    if @monoid.zero?
      "#{@lang['zero']}: & #{@monoid.zero} \\\\"
    else
      unless @monoid.left_zeros.empty?
        "#{@lang['lzero']}: & #{@monoid.left_zeros.join(', ')} \\\\"
      else
        "  &   \\\\"
      end
    end
  end

  def zero2
    if @monoid.zero?
      "  &   \\\\"
    else
      unless @monoid.right_zeros.empty?
        "#{@lang['rzero']}: & #{@monoid.right_zeros.join(', ')} \\\\"
      else
        "  &   \\\\"
      end
    end
  end

  def syntactic_properties
    if @monoid.syntactic?
      table_text = ""
      @monoid.all_disjunctive_subsets.each do |set|
        table_text += set2tex(set) + "& " + reg2tex(@monoid.to_dfa(set).to_regexp) + "\\\\\\\\"
      end

      output = <<TEXT
\\textbf{#{@lang['synprop']}:}
\\begin{center}
\\begin{tabular}{cl}
\\textbf{#{@lang['disj']}} & \\textbf{#{@lang['reg']}} \\\\\\\\ \\hline
#{table_text}
\\end{tabular}
\\end{center}
TEXT
    else
      ""
    end
  end

  def method_missing(name, *args)
    if name.to_s =~ /\?/
      @lang[@monoid.send(name)]
    else
      set2tex @monoid.send(name)
    end
  end

  private
  def set2tex(set)
    if Array === set.first
      set.map! { |s| set2tex(s) }.join(', ')
    else
      "\\{" + set.join(', ') + "\\}"
    end
  end

  def helper_table2tex(monoid)
    table = []
    monoid.table.each_with_index do |x, i| 
      table << [] if i % monoid.order == 0
      table.last << monoid.elements[x]
    end

    buffer = ['\begin{tabular}[t]{' +
               (['c']*(monoid.order+1)).join('|') + '|}']
 
    buffer << ' & ' + table[0].map do |el|
      "\\textbf{#{el}}"
    end.join(' & ') + "\\\\\\\\ \\hline"
 
    table.each do |row|
      buffer << "\\textbf{#{row[0]}} & " + row.join(' & ') + "\\\\\\\\ \\hline"
    end
 
    buffer << ['\end{tabular}']
    buffer.join("\n")
  end

  def reg2tex(re)
    if re.string.empty?
      "\\ensuremath{\\emptyset}"
    else
      re_str = re.string.
        gsub(RLSM::RE::ParserHelpers::EmptyWordSymbol, "\\lambda ").
        gsub(RLSM::RE::ParserHelpers::UnionSymbol, "\\mid ").
        gsub(RLSM::RE::ParserHelpers::StarSymbol, "^{*}")

      "\\ensuremath{#{re_str}}"
    end
  end

  def tex_xy_node(n)
    if n.first == 'edge'
      return "" if n[1] == 'preinit'
 
      num_points = n[3].to_i
      lable_pos = n[2*num_points + 5,2].join(',')
      label = n[2*num_points + 4].gsub("\"",'')
 
      return ";(#{lable_pos})*[r]\\txt{#{label}}\n"
    else
      id = n[1]
      xypos = n[2,2].join(',')
      return "(#{xypos})*{}=\"#{id}\"\n" if n[1] == 'preinit'
 
      label = n[6]
      type = n[8] == 'circle' ? '' : '='
 
      return ";(#{xypos})*+=[o]++[F#{type}]{#{label}}=\"#{id}\"\n"
    end
  end
 
  def tex_xy_edge(e)
    from, to = e[1,2]
    num_points = e[3].to_i
    points = points_to_str(e[4,2*num_points])
 
    "\\ar @`{#{points}} \"#{from}\";\"#{to}\""
  end
 
  def points_to_str(a)
    "(" + a.enum_slice(2).to_a.map { |x| x.join(',') }.join('),(') + ")"
  end

  def tmp_filename
    File.join(Dir.tmpdir, "m#{@monoid.to_s.gsub(/\s*,?/, '_')}")
  end

  def dfa2pic(dfa, options = {:format => 'png'})
    filename = options[:filename] || tmp_filename
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
    (dfa.states - dfa.final_states).each do |state|
      str += state + "\n"
    end
    str += "node [shape=doublecircle]\n"
    dfa.final_states.each do |state|
      str += state + "\n"
    end
    str += "preinit -> #{dfa.initial_state}\n"
    dfa.states.each do |s1|
      dfa.states.each do |s2|
        res = dfa.transitions.find_all { |tr| tr[0] == s1 and tr[1] == s2 }
        unless res.empty?
          label = res.map { |tr| tr[2] }.join(',')
          str += s1 + "->" + s2 + "[label=\"#{label}\"]\n"
        end
      end
    end
 
    str + "}"
  end
end
