require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')
require File.join(File.dirname(__FILE__), 'presenting_monoids_in_tex')

require "rubygems"
require "sqlite3"

File.open("monoidlist.tex", "w") do |f|
  db = SQLite3::Database.new(File.join(File.dirname(__FILE__), '..', 'data', 'monoids.db'))

  #Making the header
  f.puts "\\documentclass[8pt]{article}"
  f.puts "\\usepackage[a4paper, left=2cm, right=2cm, top=1cm, bottom=2cm]{geometry}"
  f.puts "\\usepackage[utf8]{inputenc}"
  f.puts "\\usepackage[T1]{fontenc}"
  f.puts "\\usepackage[all]{xy}"
  
  f.puts "\\begin{document}"
  f.puts "\\title{Nichtäquivalente Monoide bis Ordnung 5}"
  f.puts "\\date{}"
  f.puts "\\maketitle"
  f.puts "\\tableofcontents\n"

  f.puts "\\section{Überblick}"
  query = <<SQL
SELECT
ord AS 'Order',
count(*) AS 'Total',
total(is_syntactic) AS 'Syntactic',
total(is_group) AS 'Groups',
total(is_commutative) AS 'Commutative',
total(is_aperiodic) AS 'Aperiodic',
total(is_idempotent) AS 'Idempotent',
total(is_j_trivial) AS 'J-trivial',
total(is_r_trivial) AS 'R-trivial',
total(is_l_trivial) AS 'L-trivial',
total(has_zero) AS 'With zero element'
FROM monoids
GROUP BY ord
ORDER BY 'Order' ASC;
SQL
  result = db.execute2(query)

  f.puts "\\begin{center}"
  f.puts "\\begin{tabular}{r|ccccccc}"

  f.puts( (0..7).to_a.map { |i| "\\textbf{#{result[i][0]}}" }.join(' & ') + " \\\\ \\hline" )

  1.upto 10 do |row_index|
    f.puts "\\textbf{#{result[0][row_index]}} & "+ 
      (1..7).to_a.map { |i| result[i][row_index].to_i }.join(' & ') + " \\\\" 
  end

  f.puts "\\end{tabular}"
  f.puts "\\end{center}\n\n"
  
  1.upto 5 do |order|
    f.puts "\\section{Ordnung #{order}}\n"

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=1 AND is_commutative=1 AND is_idempotent=1 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Syntaktisch, Kommutativ und Idempotent}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end
 
    
    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=1 AND is_commutative=1 AND is_aperiodic=1 AND is_idempotent=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Syntaktisch, Kommutativ und Aperiodisch}\n"
      
      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end
    
    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=1 AND is_commutative=1 AND is_aperiodic=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Syntaktisch und Kommutativ}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=1 AND is_idempotent=1 AND is_commutative=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Syntaktisch und Idempotent}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end


    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=1 AND is_aperiodic=1 AND is_idempotent=0 AND is_commutative=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Syntaktisch und Aperiodisch}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=0 AND is_commutative=1 AND is_idempotent=1 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Nicht Syntaktisch, Kommutativ und Idempotent}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end
 

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=0 AND is_commutative=1 AND is_aperiodic=1 AND is_idempotent=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Nicht Syntaktisch, Kommutativ und Aperiodisch}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=0 AND is_commutative=1 AND is_aperiodic=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Nicht Syntaktisch und Kommutativ}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=0 AND is_idempotent=1 AND is_commutative=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Nicht Syntaktisch und Idempotent}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end
    end

    query = "SELECT * FROM monoids WHERE ord=#{order} AND is_syntactic=0 AND is_aperiodic=1 AND is_commutative=0 AND is_idempotent=0 ORDER BY binop;"
    result = db.execute(query)

    unless result.empty?
      f.puts "\\subsection{Nicht Syntaktisch und Aperiodisch}\n"

      result.each do |row| 
        f.puts Presenter.db_row_to_latex(row, :lang => :de)
        f.puts "\n\n"
      end    
    end  
  end
  
  f.puts "\\end{document}"
end
