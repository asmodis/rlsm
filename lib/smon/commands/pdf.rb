#category RLSM
=begin help
Creates a pdf in the current working directory.

Usage: pdf obj

Creates a pdf with name "obj.class-time.pdf" in the current working directory.
First, a latex file is produced and then this file is processed with pdflatex.
If no latex is found, nothing happens.
=end

def pdf(obj)
  file = obj.class.to_s[(6..-1)].downcase + '_' + Time.now.strftime("%H%M%S")
  Presenter.to_tex obj, :compile => true, :pdf => true, :filename => file + ".tex"

  Dir.glob("#{file}*").reject { |f| f =~ /.pdf$/ }.each { |f| system "rm #{f}" }
end
