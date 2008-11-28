#category base
=begin help
Reloads a command.

Usage: reload "cmd"

Unloads the command +cmd+ if it exists, then tries to reload it.
For reloading, the program searches for an file "cmd.rb" in the load path.
=end

def reload(cmd)
  return false unless Commands.include? cmd

  #Removes the help entries and the command
  Commands.delete cmd
  CmdHelp.delete cmd
  Categories.each do |cat|
    cat.delete cmd
  end

  load(cmd)
end
