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
      str = "\\begin{xy}\n0;<2.54cm,0cm>:\n"

      edges = []
      File.open(filename + ".plain", 'r').each_line do |line|
        values = line.split
        if ['edge','node'].include? values.first
          str += tex_xy_node(values)
        end
        edges << tex_xy_edge(values) if values.first == 'edge'
      end

      str += edges.join("\n")
      
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

  def tex_describe(obj, opts  = {})
    monoid = obj.to_monoid
    dfa = obj.to_dfa
    
    str = <<LATEX
\\begin{tabular}{c|c}
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
\\usepackage[frame,curves,arrow]{xy}
\\usepackage{amsmath}
PREAMBLE
  end

  def dvi(obj)
    str = "\\documentclass[a4paper,DIV15,halfparskip*]{scrartcl}\n"
    str += "\\begin{document}\n"
    str += latex(obj)
    str += "\n\\end{document}"

    filename = "tmp" + Time.now.to_s.gsub(/[ :+]/, '')
    File.open(filename + ".tex", 'w') { |f| f.puts str }

    system "latex -interaction=nonstopmode " + filename  + ".tex"
    clean_up filename
  end

  def pdf(obj)
    str = "\\documentclass[a4paper,DIV15,halfparskip*]{scrartcl}\n"
    str += "\\begin{document}\n"
    str += latex(obj)
    str += "\n\\end{document}"

    filename = "tmp" + Time.now.to_s.gsub(/[ :+]/, '')
    File.open(filename + ".tex", 'w') { |f| f.puts str }

    system "pdflatex -interaction=nonstopmode " + filename  + ".tex"
    clean_up filename
  end

  def self.included(child)
    unless system("which latex > /dev/null")
      STDERR.puts "W: No 'latex' command found."
      remove_method :dvi
    end

    unless system("which pdflatex > /dev/null")
      STDERR.puts "W: No 'pdflatex' command found."
      remove_method :pdf
    end
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
    sm = m.proper_submonoids.map { |s| tex_binop(s).join("\n") }
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
      re = m.to_dfa(ds).to_re.to_s
      buffer << set(ds) + " & " + tex_re(re) + "\\\\"
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

      return ";(#{lable_pos})*\\txt{#{label}}\n"
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
