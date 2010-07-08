require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')


File.open("order8.txt",'w') do |file|

  count = 0
  
  RLSM::Monoid.each(8) do |mon|
    count +=1
    puts count
    file.puts mon.to_s
  end
end
