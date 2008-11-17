require File.join(File.dirname(__FILE__), '..', '..', 'rlsm')

class TxtPresenter
  #Returns a string with a txt representation of the given object.
  def output(obj)
    self.send obj.class.to_s[(6..-1)].downcase.to_sym, obj
  end

  private
  def monoid(m, with_syntactic_stuff = true)
    out = "Monoid '#{m.hash}':\n"

    #The binary operation:
    out += binop_to_txt(m)

    #The properties
    out += basic_props(m)
    out += submonoids_to_txt(m)
    out += classes_to_txt(m)
    out += special_elements(m)

    out += syntactic_stuff(m) if with_syntactic_stuff and m.syntactic?

    out
  end

  def regexp(re)
    out = "RegExp: #{re.to_s}\n\n"
    out += "Corresponding DFA:\n"
    dfa = re.to_dfa
    out += dfa.to_s + "\n\n"
    out += "Corresponding syntactic monoid:\n"
    out + monoid(dfa.syntactic_monoid, false)
  end

  def dfa(dfa)
    min = dfa.minimal?
    
    out = "DFA"
    if min
      out += " (is minimal):\n"
    else
      out += " (not minimal):\n"
    end
    
    out += dfa.to_s
    out += "\nCorresponding RegExp: #{dfa.to_regexp}\n\n"
    
    if min     
      out += "Transition monoid:\n"
      out += monoid(dfa.syntactic_monoid, false)
    else
      out += "Transition monoid:\n"
      out += binop_to_txt(dfa.transition_monoid)
      out += "\n\nSyntactic Monoid (the transition monoid of the minimal DFA):\n"
      out += monoid(dfa.syntactic_monoid, false)
    end

    out
  end

  def set_to_list(set, names)
    set.map {|x| names[x]}.join(', ')
  end

  def translate_binop(m)
   m.binary_operation.flatten.map { |c| m.elements[c] } / m.order
  end

  def binop_to_txt(m)
    table = translate_binop(m)
    col_width = (0...m.order).to_a.map { |i| table.map { |r| r[i].length }.max }

    i = -1
    table.map! do |row|
      i += 1
      row.inject("|") { |r,x| r + " #{x} " + " "*(col_width[i]-x.length) + "|" }
    end

    row_sep = "\n" + table.first.scan(/./m).map { |c| c == '|' ? '+' : '-' }.join + "\n"

    row_sep + table.join(row_sep) + row_sep + "\n"
  end

  def basic_props(m)
    out = "Order:      #{m.order}\n"
    out += "Generators: #{set_to_list m.generating_subset, m.elements}\n"
    out + "Properties: #{props m}\n\n"
  end

  def props(m)
    str = ['commutative', 'idempotent', 'aperiodic', 'syntactic', 'group'].select do |p|
      m.send((p + '?').to_sym)
    end.join(', ')
  end

  def submonoids_to_txt(m)
    psm = m.proper_submonoids
    out = "Submonoids: "    
    
    if psm.empty?
      out += "none\n\n"
    else
      out += psm.map! do |sm|
        translate_binop(sm).map { |r| r.join(sm.order > 10 ? ',' : '') }.join(" ")
      end.join("; ")
      
      out += "\n\n"
    end

    out
  end

  def classes_to_txt(m)
    out = "L-Classes: " + m.l_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out += "\n"
    out += "R-Classes: " + m.r_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out += "\n"
    out += "H-Classes: " + m.h_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out += "\n"
    out += "D-Classes: " + m.d_classes.map { |c| "{#{ set_to_list c, m.elements}}" }.join('; ')
    out + "\n\n"
  end

  def special_elements(m)
    out = "Special Elements:\n"
    out += "Null Element: " + (m.null_element ? m.elements[m.null_element] : 'none') + "\n"
    out += "Idempotents: #{set_to_list m.idempotents, m.elements}\n"

    unless m.null_element
      rn, ln = m.right_nulls, m.left_nulls
      unless rn.empty?
        out += "Right Nulls: #{set_to_list rn, m.elements}\n"
      end

      unless ln.empty?
        out += "Left Nulls: #{set_to_list ln, m.elements}\n"
      end
    end

    out + "\n"
  end

  def syntactic_stuff(m)
    out = "Disjunctive Subsets: " + m.all_disjunctive_subsets.map do |dss|
      "{"+ set_to_list(dss, m.elements) + "}"
    end.join("; ") + "\n"

    dfa = m.to_dfa
    re = dfa.to_regexp
    
    out += "DFA for {#{set_to_list m.disjunctive_subset, m.elements}}:\n"
    out += dfa.to_s + "\n\n"
      
    out + "Corresponding RegExp: #{re.to_s}\n\n"
  end
end
