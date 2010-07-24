#-*- ruby -*-

require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')
require "rubygems"
require "sqlite3"

$db = SQLite3::Database.new("../data/monoids.db")

[2,3,4,5,6,7].each do |i|
  puts "Monoids of order #{i}:"
  total = 0
  syntactic = 0
  regular = 0
  reg_ns = 0
  inverse = 0
  inv_ns = 0
  
  $db.execute("SELECT binop FROM monoids WHERE ord=#{i};").each do |binop|
    monoid = RLSM::Monoid[*binop]

    total += 1
    if monoid.syntactic?
      syntactic += 1
      regular += 1 if monoid.regular?
      inverse += 1 if monoid.inverse?
    else
      regular += 1; reg_ns += 1 if monoid.regular?
      inverse += 1; inv_ns += 1 if monoid.inverse?
    end
  end

  puts "        Total: #{total}"
  puts "    Syntactic: #{syntactic}"
  puts "Not Syntactic: #{total - syntactic}"
  puts "      Regular: #{regular}"
  puts "      Inverse: #{inverse}"
  puts "   Regular ns: #{reg_ns}"
  puts "   Inverse ns: #{inv_ns}"
  puts
  puts
end
