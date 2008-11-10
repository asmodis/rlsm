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
  if obj.class == RLSM::Monoid
    rows = obj.binary_operation.map { |row| row.join(' | ')}
    rows.map! { |r| '| ' + r.gsub(/\w/) { |c| obj.elements[c.to_i] } + " |\n" }
    row_sep = rows.first.scan(/./m).map do |c|
      case c
      when '|' : '+'
      when "\n" : "\n"
      else
        '-'
      end
    end.join

    puts row_sep
    puts rows.join(row_sep)
    puts row_sep
    puts
  else
    puts obj.to_s
    puts
  end
end
