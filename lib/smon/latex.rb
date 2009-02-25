module SmonLatex
  def latex(obj)
    monoid = obj.to_monoid
    STDERR.puts "Not implemented."
  end

  def dvi(obj)
    STDERR.puts "Not implemented."
  end

  def pdf(obj)
    STDERR.puts "Not implemented."
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
end
