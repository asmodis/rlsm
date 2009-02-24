module SmonDB
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
  end

  def db_find(args)
    count = RLSM::MonoidDB.count(args)
    STDOUT.puts "Found: #{count[0]} monoid(s) (#{count[1]} syntactic)"
    STDOUT.puts "Saved result in variable '@search_result'"

    @search_result = RLSM::MonoidDB.find(args).flatten
  end
end
