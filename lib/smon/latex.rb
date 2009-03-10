require 'enumerator'

module SMONLIBlatex
  def m2tex(monoid)
    buffer = ['\begin{tabular}{' +
               (['c']*(monoid.order+1)).join('|') + '|}']

    buffer << ' & ' + monoid.binary_operation[0].map do |el|
      "\\textbf{#{el}}"
    end.join(' & ') + "\\\\ \\hline"

    monoid.binary_operation.each do |row|
      buffer << "\\textbf{#{row[0]}} & " + row.join(' & ') + "\\\\ \\hline"
    end

    buffer << ['\end{tabular}']
    buffer.join("\n")
  end

  def d2tex(dfa, opts = {:dot => true})
    #Have we dot support
    if opts[:dot] #and @__cmds.include? "dfa2pic"
      filename = SMON.tmp_filename
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
        tmp_str += "\\ensuremath{*}" if dfa.finals.include? state
        tmp_str += "\\ensuremath{\\rightarrow}" if dfa.initial_state == state
        tmp_str += state + " & "
        tmp_str += dfa.alphabet.map do |letter|
          tmp = dfa[letter,state]
          tmp ? tmp : 'nil'
        end.join(' & ')
        str+= tmp_str + " \\\\\n"
      end

      return str + "\\end{tabular}\n"
    end
  end

  def r2tex(re)
    re_str = re.pattern.
      gsub(RLSM::RE::Lambda, "\\lambda ").
      gsub(RLSM::RE::Union, "\\mid ").
      gsub(RLSM::RE::Star, "^{*}")

    "\\ensuremath{#{re_str}}"
  end

  def tex_describe(obj)
    monoid = obj.to_monoid
    dfa = obj.to_dfa

    str = <<LATEX
\\begin{tabular}[t]{c|c}
\\textbf{Binary Operation} & \\textbf{DFA} \\\\ \\hline
#{m2tex(monoid)} & #{d2tex(dfa)}
\\end{tabular}\\\\[2ex]
#{tex_properties(monoid)}\\\\[2ex]
#{tex_submonoids(monoid)}\\\\[2ex]
#{monoid.syntactic? ? tex_syntactic_properties(monoid) : ''}

LATEX

    @out.puts str if @interactive

    str
  end

  def tex_preamble
    <<PREAMBLE
\\documentclass[a4paper,DIV15,halfparskip*]{scrartcl}
\\usepackage[all]{xy}
\\usepackage{amsmath}

\\begin{document}
PREAMBLE
  end

  def compile(opts = {:format => 'dvi'})
    str = tex_preamble
    if opts[:object]
      str += tex_describe(opts[:object])
    else
      str += opts[:input]
    end
    str += "\n\\end{document}"

    filename = opts[:filename] || SMON.tmp_filename

    File.open(filename + ".tex", 'w') { |f| f.puts str }

    cmd = "latex -interaction=nonstopmode "
    cmd += "-output-format=#{opts[:format]} " + filename  + ".tex"

    system cmd

    clean_up filename
  end

  def self.included(mod)
    unless system("which latex >/dev/null")
      remove_method :complile
      STDERR.puts "W: compile command disabled."
    else
      mod.add_help :type => 'cmd',
      :name => 'compile',
      :summary => 'Creates a dvi or pdf from the given string or object.',
      :usage => 'compile <options>',
      :description => <<DESC
Possible options are
 :input -> a String.
           A string which contains a valid latex source file.

 :object -> a DFA or Monoid or Regular Expression.
            The object will be transformed using tex_describe
            and then typsetted.

 :format -> a String.
            Either 'dvi' or 'pdf'. Determines the output format of the
            latex command.

 :filename -> a String.
              The filename of the output.
DESC
    end

    mod.add_help :type => 'cmd',
    :name => 'm2tex',
    :summary => 'Transforms a monoid to tex code.',
    :usage => 'm2tex <monoid>',
    :description => <<DESC
Takes a monoid and returns a string containing tex code for
representing the monoid in tex.
DESC

    mod.add_help :type => 'cmd',
    :name => 'r2tex',
    :summary => 'Transforms a regular expression to tex code.',
    :usage => 'r2tex <re>',
    :description => <<DESC
Takes a regular expression and returns a string containing tex code for
representing the regular expression in tex.
DESC

    mod.add_help :type => 'cmd',
    :name => 'd2tex',
    :summary => 'Transforms a DFA to tex code.',
    :usage => 'd2tex <dfa> [<options>]',
    :description => <<DESC
Takes a DFA and returns a string containing tex code for
representing the DFA in tex.

Optional a parameter :dot can be given.
 :dot -> true|false
         If true and the dfa2pic command is found, uses dot and xy-pic
         to genearte a graph for the DFA.
         If false a simple table is used for representing the DFA.
DESC

    mod.add_help :type => 'cmd',
    :name => 'tex_describe',
    :summary => 'Returns tex code equivalent to the describe command.',
    :usage => 'tex_describe <object>',
    :description => <<DESC
Takes an object and returns a string containing tex code for
representing this object in tex. Focuses on the monoid properties.
DESC

    mod.add_help :type => 'cmd',
    :name => 'tex_preamble',
    :summary => 'Returns the tex preamble used by the compile command.',
    :usage => 'tex_preamble',
    :description => <<DESC
Not very useful in interactive mode.
DESC
  end

  private
  def clean_up(file)
    files = Dir.glob(file + ".*").reject { |f| f =~ /(dvi|pdf)$/ }
    files.each { |f| system("rm " + f) }
  end

  def set(s)
    "\\ensuremath{\\lbrace \\mbox{#{s.join(', ')}}\\rbrace}"
  end

  def list(s)
    str = s.join(', ')
    str.empty? ? 'none' : str
  end

  def tex_submonoids(m)
    sm = m.proper_submonoids.map { |s| m2tex(s) }
    buffer = nil
    if sm.empty?
      buffer = ["\\textbf{Submonoids:} none"]
    else
      buffer = ["\\textbf{Submonoids:}\\\\[.5\\baselineskip]"]
      buffer << sm.join("\\quad\n")
    end

    buffer.join("\n")
  end

  def tex_syntactic_properties(m)
    buffer = ["\\textbf{Syntactic Properties:}\\\\"]
    buffer << "\\begin{tabular}{ll}"
    buffer << "Disjunctive Subset & Possible Regular Expression \\\\"
    m.all_disjunctive_subsets.each do |ds|
      re = m.to_dfa(ds).to_re
      buffer << set(ds) + " & " + r2tex(re) + "\\\\"
    end
    buffer << "\\end{tabular}"

    buffer.join("\n")
  end


  def tex_properties(m)
    buffer = ['\begin{tabular}{llcll}']
    buffer << '\multicolumn{2}{l}{\textbf{Properties of the Monoid:}} &'
    buffer << ' & \multicolumn{2}{l}{\textbf{Special Elements:}} \\\\'
    buffer << "Generator: & #{set(m.generating_subset)} & \\quad &" +
      "Idempotents: & #{list(m.idempotents)} \\\\"

    buffer << "Group: & #{m.group?} & \\quad &"
    if m.zero_element
      buffer[-1] += " Zero Element: & #{m.zero_element} \\\\"
    else
      buffer[-1] += " Left-Zeros: & #{list(m.left_zeros)} \\\\"
    end

    buffer << "Commutative: & #{m.commutative?} & \\quad &"
    if m.zero_element
      buffer[-1] += " & \\\\"
    else
      buffer[-1] += " Rigth-Zeros: & #{list(m.right_zeros)} \\\\"
    end

    buffer << "Idempotent: & #{m.idempotent?} & \\quad & & \\\\"
    buffer << "Syntactic: & #{m.syntactic?} & \\quad &" +
      "\\multicolumn{2}{l}{\\textbf{Green Relations:}} \\\\"
    buffer << "Aperiodic: & #{m.aperiodic?} & \\quad &" +
      " L-Classes: & #{list(m.l_classes.map { |x| set(x) })} \\\\"
    buffer << "L-trivial: & #{m.l_trivial?} & \\quad &" +
      " R-Classes: & #{list(m.r_classes.map { |x| set(x) })} \\\\"
    buffer << "R-trivial: & #{m.r_trivial?} & \\quad &" +
      " H-Classes: & #{list(m.h_classes.map { |x| set(x) })} \\\\"
    buffer << "D-trivial: & #{m.d_trivial?} & \\quad &" +
      " D-Classes: & #{list(m.d_classes.map { |x| set(x) })} \\\\"
    buffer << "Zero Element: & #{!m.zero_element.nil?} & \\quad & & \\\\"
    buffer << '\end{tabular}'

    buffer.join("\n")
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
      return  "(#{xypos})*{}=\"#{id}\"\n" if n[1] == 'preinit'

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
end
