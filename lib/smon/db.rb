module SMONLIBdb
  def db_stat
    stat = RLSM::MonoidDB.statistic
    result = stat.shift.join(' | ')

    column_widths = result.scan(/./).inject([0]) do |res,char|
      if char == '|'
        res << 0
      else
        res << res.pop + 1
      end

      res
    end

    result += ("\n" + '   ' + result.gsub(/[^|]/, '-').gsub('|', '+'))

    stat.each do |row|
      justified = []
      row.each_with_index do |col,i|
        col = col.to_s
        space = ' '*((column_widths[i] - col.length)/2)
        extra_space = ' '*((column_widths[i] - col.length)%2)
        justified << space + col + space + extra_space
      end

      result += ("\n" + '   ' + justified.join('|'))
    end

    @out.puts result
    @out.puts
  end

  def db_find(args)
    count = RLSM::MonoidDB.count(args)
    STDOUT.puts "Found: #{count[0]} monoid(s) (#{count[1]} syntactic)"
    STDOUT.puts "Saved result in variable '@search_result'"

    @search_result = RLSM::MonoidDB.find(args).flatten
  end

  def self.included(mon)
    #Check if database is usable
    begin
      require 'database'

      mon.add_help :type => 'cmd',
      :name => 'db_stat',
      :summary => "Shows an overview of the database.",
      :usage => 'db_stat',
      :description => <<DESC
Prints for each order of a monoid the number of monoids in the database
and the number of monoids with certain properties.
DESC

      mon.add_help :type => 'cmd',
      :name => 'db_find',
      :summary => "Finds monoids in the database.",
      :usage => 'db_find [<options>]',
      :description => <<DESC
Finds monoids which matches the given options and saves the result
in the variable '@serach_result'.

The optional <options> parameter is a Hash with the following keys:
 :binop -> a String
           Searches in the database for a monoid with this binary operation.
           The :binop-value must have the same format as for the monoid command
           and in the database the element names are 0 1 2 3 4 5 ...
           (Not very useful in practice.)

 :m_order -> an Integer
             Searches for monoids with the given order.

 :num_generators
 :num_idempotents
 :num_left_nulls
 :num_right_nulls -> an Integer
                     Seraches for monoids with the given number of special
                     elements like idempotents or left-zeros.

 :syntactic
 :idempotent
 :aperiodic
 :commutative
 :is_group
 :has_null
 :l_trivial
 :r_trivial
 :d_trivial   -> true|false
                 Searches for monoids with the given attribute.
DESC
    rescue LoadError
      STDERR.puts "W: Could not load 'db'."
      remove_method :db_find
      remove_method :db_stat
    end
  end
end
