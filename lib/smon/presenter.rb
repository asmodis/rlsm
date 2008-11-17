require File.join(File.dirname(__FILE__), 'presenter', 'txt_presenter')

class Presenter
  #Returns a LaTeX representation of the given object as a string.
  def self.to_tex(obj, opts = {})
    puts "Not yet implemented"
  end

  #Returns an ASCII representation of the given object as a string.
  def self.to_txt(obj)    
    TxtPresenter.new.output obj
  end

  #Creates a pdf document in the tmp directory.
  def self.to_pdf(obj, opts = {})
    puts "Not yet implemented"
  end
end
