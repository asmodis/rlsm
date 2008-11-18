require File.join(File.dirname(__FILE__), '..', '..', 'rlsm')

class TexPresenter
  #Returns a string with a LaTeX representation of the given object.
  #As optional parameters you can pass (as a Hash)
  # - :standalone => true | false (default: false)
  # - :compile => true | false (default: false; implies :standalone)
  # - :pdf => true | false (default: false)
  # - :save => true | false (default: false; saves the str as file +:filename+)
  # - :filename => String (default: "/tmp/obj.class.tex")
  def output(obj, opts = {})
    cls = obj.class.to_s[(6..-1)].downcase
    str = self.send cls.to_sym, obj
    str = opts[:standalone] ? standalone(str) : str
    file = opts[:filename] || "/tmp/#{cls}-#{Time.now.strftime("%d%m%Y%H%M%S")}.tex"
    if opts[:compile]
      str = standalone(str) unless opts[:standalone]
      File.open(file, 'w') { |f| f.puts str }
      
      if opts[:pdf]
        if %x[which pdflatex] != ''
          puts %x[pdflatex file]
        else
          puts "No pdflatex found."
        end
      end

      if %x[which latex] != ''
        puts %x[latex file]
      else
        puts "No latex found."
      end
    elsif opts[:save]
      File.open(file, 'w') { |f| f.puts str }
    end

    str
  end

  private
  def standalone(str)
    '\documentclass{article}' + "\n" +
    '\begin{document}' + "\n" +
    str + "\n\\end{document}"
  end
  
  def monoid(m, with_syntactic_stuff = true)
    out = "\\paragraph{Monoid '#{m.hash}':}\n"

    #The binary operation:
    out += binop_to_tex(m)

    #The properties
    out += "\\begin{description}\n"
    out += basic_props(m)
    out += submonoids(m)
    out += classes(m)
    out += special_elements(m)

    out += syntactic_stuff(m) if with_syntactic_stuff and m.syntactic?
    
    out + "\\end{description}"
  end

  def regexp(re)
    out = "\\paragraph{RegExp: #{re_to_tex re}:}\n"
    out += "\\begin{description}\n"
    out += "\\item[Corresponding DFA:]\n"
    dfa = re.to_dfa
    out += dfa_to_tex + "\n\n"
    out += "\\item[Corresponding syntactic monoid:]\n"
    out += monoid(dfa.syntactic_monoid, false)
    out + "\\end{description}"
  end

  def dfa(dfa)
    min = dfa.minimal?
    
    out = "\\paragraph{DFA"
    if min
      out += " (is minimal):}\n"
    else
      out += " (not minimal):}\n"
    end
    
    out += dfa_to_tex
    out += "\\begin{description}\n"
    out += "\\item[Corresponding RegExp:] #{re_to_tex dfa.to_regexp}\n"
    
    if min     
      out += "\\item[Transition monoid:]\n"
      out += monoid(dfa.syntactic_monoid, false)
    else
      out += "\\item[Transition monoid:]\n"
      out += binop_to_tex(dfa.transition_monoid)
      out += "\\item[Syntactic Monoid (the transition monoid of the minimal DFA):]\n"
      out += monoid(dfa.syntactic_monoid, false)
    end

    out + "\\end{description}"
  end

  def set_to_list(set, names)
    set.map {|x| names[x]}.join(', ')
  end

  def translate_binop(m)
   m.binary_operation.flatten.map { |c| m.elements[c] } / m.order
  end

  def binop_to_tex(m)
    table = translate_binop(m)

    out = '\begin{tabular}{|c|' + table.map { 'c' }.join('|') + "|}\\hline\n"
    out += ' & ' + table.first.map { |c| "\\textbf{#{c}}" }.join(" & ") + "\\\\\\hline\n"
    out += table.map { |r| "\\textbf{#{r.first}} & " + r.join(" & ") }.join("\\\\\\hline\n")
    out + "\\\\\\hline\n" + '\end{tabular}' + "\n"
  end

  def basic_props(m)
    out = "\\item[Order:] #{m.order}\n"
    out += "\\item[Generators:] #{set_to_list m.generating_subset, m.elements}\n"
    out + "\\item[Properties:] #{props m}\n\n"
  end

  def props(m)
    str = ['commutative', 'idempotent', 'aperiodic', 'syntactic', 'group'].select do |p|
      m.send((p + '?').to_sym)
    end.join(', ')
  end

  def submonoids(m)
    psm = m.proper_submonoids
    out = "\\item[Submonoids:] "    
    
    if psm.empty?
      out += "none\n\n"
    else
      out += psm.map! do |sm|
        binop_to_tex(sm)
      end.join("; ")
      
      out += "\n\n"
    end

    out
  end

  def classes(m)
    out = "\\item[L-Classes:] " + m.l_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out += "\n"
    out += "\\item[R-Classes:] " + m.r_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out += "\n"
    out += "\\item[H-Classes:] " + m.h_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out += "\n"
    out += "\\item[D-Classes:] " + m.d_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out + "\n\n"
  end

  def special_elements(m)
    out += "\\item[Null Element:] " + (m.null_element ? m.elements[m.null_element] : 'none') + "\n"
    out += "\\item[Idempotents:] #{set_to_list m.idempotents, m.elements}\n"

    unless m.null_element
      rn, ln = m.right_nulls, m.left_nulls
      unless rn.empty?
        out += "\\item[Right Nulls:] #{set_to_list rn, m.elements}\n"
      end

      unless ln.empty?
        out += "\\item[Left Nulls:] #{set_to_list ln, m.elements}\n"
      end
    end

    out + "\n"
  end

  def syntactic_stuff(m)
    out = "\\item[Disjunctive Subsets:] " + m.all_disjunctive_subsets.map do |dss|
      "{"+ set_to_list(dss, m.elements) + "}"
    end.join("; ") + "\n"

    dfa = m.to_dfa
    re = dfa.to_regexp
    
    out += "\\item[DFA for $\lbrace{#{set_to_list m.disjunctive_subset, m.elements}}\rbrace$]:\n"
    out += dfa_to_tex(dfa) + "\n\n"
      
    out + "\\item[Corresponding RegExp:] #{re_to_tex re}\n\n"
  end

  def dfa_to_tex(dfa)
    "TODO"
  end

  def re_to_tex(re)
    "\\ensuremath{#{re.to_s.gsub('|', '\mid').gsub('&', '\lambda ')}}"
  end
end
