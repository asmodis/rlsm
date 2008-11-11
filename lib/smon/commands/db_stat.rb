#category RLSM
=begin help
Shows a small summery of the database.

Usage: db_stat

Prints out a small overview of the monoids in the database.
=end

def db_stat
  res = RLSM::MonoidDB.statistic
  
  res.each_with_index do |row,i| 
    if i == 0
      puts row.map { |name| name[(0..4)] + '.' }.join("\t")
    else 
      puts row.join("\t")
    end
  end
end
