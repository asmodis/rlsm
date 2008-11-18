require File.join(File.dirname(__FILE__), 'presenter', 'txt_presenter')

class Presenter
  #Returns a LaTeX representation of the given object as a string.
  def self.to_tex(obj, opts = {})
    TexPresenter.new.output obj, opts
  end

  #Returns an ASCII representation of the given object as a string.
  def self.to_txt(obj)    
    TxtPresenter.new.output obj
  end
end
