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

  def d2tex(dfa)
  end

  def r2tex(re)
  end

  def tex_describe(obj, opts  = {})
    monoid = obj.to_monoid

    buffer = tex_binop(monoid)
    buffer << "\\qquad"
    buffer << tex_dfa(obj.to_dfa)
    buffer << ""
    buffer << "\\vspace*{.75\\baselineskip}"
    buffer << ""
    buffer += tex_properties(monoid)
    buffer << ""
    buffer << "\\vspace*{.75\\baselineskip}"
    buffer << ""
    buffer += tex_submonoids(monoid)
    buffer << ""
    buffer << "\\vspace*{.75\\baselineskip}"
    buffer << ""
    buffer += tex_syntactic_properties(monoid) if monoid.syntactic?

    @out.puts buffer.join("\n") if @interactive

    buffer.join("\n")
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
  def tex_dfa(dfa)
    buffer = []
    if @__cmds.include? 'dfa2pic'
      buffer << "Not implemented"
    else
      buffer << "\\begin{tabular}{r|" +
        (['c']*dfa.alphabet.size).join('|') + "}"
      buffer << " & " + dfa.alphabet.map do |l|
        "\\textbf{#{l}}"
      end.join(' & ') + " \\\\ \\hline"
      dfa.states.each do |state|
        str = ''
        str += "\\ensuremath{*}" if dfa.finals.include? state
        str += "\\ensuremath{\\rightarrow}" if dfa.initial_state == state
        str += state + " & "
        str += dfa.alphabet.map do |letter|
          tmp = dfa[letter,state]
          tmp ? tmp : 'nil'
        end.join(' & ')
        buffer << str + " \\\\"
      end

      buffer << "\\end{tabular}"
    end

    buffer
  end

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

    buffer
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

    buffer
  end

  def tex_re(re)
    str = re.gsub(RLSM::RE::Union, "\\mid ").
      gsub(RLSM::RE::Lambda, "\\lambda ").
      gsub(RLSM::RE::Star, "^{*}")

    "\\ensuremath{#{str}}"
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

    buffer
  end
end
