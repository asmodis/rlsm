#category base
=begin help
Runs a script.

Usage: script 'path/to/script'

Runs the script found at path/to/script.
=end

def script(file)
  str = ""
  File.open(file).each_line { |l| str += l }

  instance_eval str
end
