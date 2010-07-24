require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')

#f = File.open("tempfile.txt",'w')
x=0
start = Time.now
2.times { RLSM::Monoid.each_table(6) { x += 1 } }
puts "Elapsed time: #{Time.now - start}"
puts

#f.close
