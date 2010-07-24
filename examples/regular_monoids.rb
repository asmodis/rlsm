# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')
require File.join(File.dirname(__FILE__), 'presenting_monoids_in_tex')

require "rubygems"
require "sqlite3"

db = SQLite3::Database.new(File.join(File.dirname(__FILE__), '..',
                                     'data', 'monoids.db'))

query = <<QUERY
SELECT
ord AS                   '      Order',
count(*) AS              '      Total',
total(is_inverse) AS     '    Inverse',
total(is_syntactic) AS   '  Syntactic',
total(is_group) AS       '     Groups',
total(is_commutative) AS 'Commutative',
total(is_aperiodic) AS   '  Aperiodic',
total(is_idempotent) AS  ' Idempotent',
total(is_j_trivial) AS   '  J-trivial',
total(is_r_trivial) AS   '  R-trivial',
total(is_l_trivial) AS   '  L-trivial',
total(has_zero) AS       '  With zero'
FROM monoids
WHERE ord>=4 AND is_regular=1
GROUP BY ord
ORDER BY 'Order' ASC;
QUERY

result = db.execute2(query)

output = result.shift.map { |x| [x] }

result.each do |col|
  col.each_with_index do |row,i|
    (output[i] ||= []) << row.to_i
  end
end

puts "Ubersicht regulaere Monoide:"
puts output.map { |row| row.join("\t") }.join("\n")
puts
puts


query = <<QUERY
SELECT
ord AS                   '      Order',
count(*) AS              '      Total',
total(is_inverse) AS     '    Inverse',
total(is_syntactic) AS   '  Syntactic',
total(is_group) AS       '     Groups',
total(is_commutative) AS 'Commutative',
total(is_aperiodic) AS   '  Aperiodic',
total(is_idempotent) AS  ' Idempotent',
total(is_j_trivial) AS   '  J-trivial',
total(is_r_trivial) AS   '  R-trivial',
total(is_l_trivial) AS   '  L-trivial',
total(has_zero) AS       '  With zero'
FROM monoids
WHERE ord>=4 AND is_regular=1 AND is_syntactic=1
GROUP BY ord
ORDER BY 'Order' ASC;
QUERY

result = db.execute2(query)

output = result.shift.map { |x| [x] }

result.each do |col|
  col.each_with_index do |row,i|
    (output[i] ||= []) << row.to_i
  end
end

puts "Regulaere syntaktische Monoide:"
puts output.map { |row| row.join("\t") }.join("\n")
puts
puts

query = <<QUERY
SELECT
ord AS                   '      Order',
count(*) AS              '      Total',
total(is_aperiodic) AS   '  Aperiodic',
total(is_idempotent) AS  ' Idempotent',
total(is_j_trivial) AS   '  J-trivial',
total(is_r_trivial) AS   '  R-trivial',
total(is_l_trivial) AS   '  L-trivial',
total(has_zero) AS       '  With zero'
FROM monoids
WHERE ord>=4 AND is_regular=1 AND is_syntactic=0
GROUP BY ord
ORDER BY 'Order' ASC;
QUERY

result = db.execute2(query)

output = result.shift.map { |x| [x] }

result.each do |col|
  col.each_with_index do |row,i|
    (output[i] ||= []) << row.to_i
  end
end

puts "Regulaere nichtsyntaktische Monoide:"
puts output.map { |row| row.join("\t") }.join("\n")
puts
puts

query = <<QUERY
SELECT
ord AS                   '      Order',
count(*) AS              '      Total',
total(is_inverse) AS     '    Inverse',
total(is_syntactic) AS   '  Syntactic',
total(is_group) AS       '     Groups',
total(is_commutative) AS 'Commutative',
total(is_j_trivial) AS   '  J-trivial',
total(is_r_trivial) AS   '  R-trivial',
total(is_l_trivial) AS   '  L-trivial',
total(has_zero) AS       '  With zero'
FROM monoids
WHERE ord>=4 AND is_regular=1 AND is_aperiodic=1 AND is_idempotent=1
GROUP BY ord
ORDER BY 'Order' ASC;
QUERY

result = db.execute2(query)

output = result.shift.map { |x| [x] }

result.each do |col|
  col.each_with_index do |row,i|
    (output[i] ||= []) << row.to_i
  end
end

puts "Regulaere aperiodische und idempotente Monoide:"
puts output.map { |row| row.join("\t") }.join("\n")
puts
puts
