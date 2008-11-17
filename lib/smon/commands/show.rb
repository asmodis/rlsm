#category RLSM
=begin help
Shows a monoid or a regexp.

Usage: show obj

+obj+ is either a regexp or a monoid. If regexp a string representation is shown
if monoid, the binary operation is shown as a table.
Example: show monoid("0")
Not working: show "0" !
=end

def show(obj)
  if obj.class == Array
    obj.each { |o| puts Presenter.to_txt o }
    puts 
  else
    puts Presenter.to_txt o
    puts
  end
end
