#category help
=begin help
Prints help topics.

Usage: help "command"
Prints the help topic for +command+. 
The command name must be surrounded by " (double quote).
Example: help help -> prints this text.

=end
def help(cmd = nil)
  if cmd.nil?
    puts "Known Commands:"
    Categories.each_pair do |cat, cmds|
      puts "  Category #{cat}"
      cmds.each do |cmd|
        puts "    #{cmd} : #{(CmdHelp[cmd] || [cmd]).first}"
      end
    end
    puts
    puts 'Type help "command" for more information for "command"'
    puts '(command must be surrounded by double quotes!)'
    puts
  else
    if CmdHelp[cmd]
      puts CmdHelp[cmd].join
    else
      puts "  Nothing known about #{cmd}"
    end
  end
end
