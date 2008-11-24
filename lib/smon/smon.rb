#
# This file is part of the RLSM gem.
#
#(The MIT License)
#
#Copyright (c) 2008 Gunther Diemant <g.diemant@gmx.net>
#
#Permission is hereby granted, free of charge, to any person obtaining
#a copy of this software and associated documentation files (the
#'Software'), to deal in the Software without restriction, including
#without limitation the rights to use, copy, modify, merge, publish,
#distribute, sublicense, and/or sell copies of the Software, and to
#permit persons to whom the Software is furnished to do so, subject to
#the following conditions:
#
#The above copyright notice and this permission notice shall be
#included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require "readline"
require "abbrev"
require File.join(File.dirname(__FILE__), '..', 'rlsm')
require File.join(File.dirname(__FILE__), 'presenter')

class Smon
  Commands = []
  Columns = [':binop =>', ':m_order =>', ':num_generators =>',
             ':num_idempotents =>', ':has_null =>', ':num_left_nulls =>',
             ':num_right_nulls =>', ':is_group =>', ':commutative =>', 
             ':aperiodic =>', ':syntatctic =>', ':idempotent =>', 
             ':l_trivial =>', ':r_trivial =>', ':d_trivial =>']
  CmdHelp = {}
  Categories = {}
  LoadPath = File.join(File.dirname(__FILE__), 'commands')

  def initialize
    #Load all commands
    cmds = Dir.glob(File.join(LoadPath, '*.rb')).map { |f| File.basename(f)[/(.*)\.rb$/, 1] }
    cmds.each do |cmd|
      load cmd, false
    end

    #Add the built-in commands to the help system
    Commands << 'load'
    CmdHelp['load'] = ["Loads a command into the system.\n",
                       "\nUsage: load 'command'\n",
                       "\nSearches for a file called 'command.rb' in the LoadPath and adds the command in this file."]
    Categories['built-in'] = ['load']

    #Initialize the help system
    @cmd_abbrev = (Commands + Columns).abbrev

    #Setting up readline
    Readline.completion_proc = lambda { |str| @cmd_abbrev[str] }

    welcome_and_licence

    loop do
      begin
        instance_eval Readline.readline("rlsm (help for help) :> ", true)
      rescue Exception => e
        puts "Something went wrong."
        puts e
      end

      break if @quit
    end    
  end

  def load(cmd, reinit = true)
    #Parsing the file
    cat = nil
    name = nil
    help = []
    parse_help = false
    input = []
    File.open(File.join(LoadPath, cmd + ".rb")).each_line do |line|
      #Extracting the help
      parse_help = false if line =~ Regexp.new("=end.*") 
      help << line if parse_help
      parse_help = true if line =~ Regexp.new("=begin.*")
      

      #Getting the category
      cat = $1.dup if line =~ Regexp.new("#category\\s\+\(\\w\+\)")

      #Getting the name
      name = $1.dup if line =~ /def\s+(\w+)/

      input << line
    end

    #Adding the method
    self.class.class_eval input.join

    #Setting up the help system
    (Categories[cat] ||= []) << name
    Commands << name
    CmdHelp[name] = help
     
    @cmd_abbrev = Commands.abbrev if reinit
  end

  private
  def welcome_and_licence
    puts <<EOT
(The MIT License)

Copyright (c) 2008 Gunther Diemant <g.diemant@gmx.net>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


 RRRRRRR      LL            SSSSSSSSS  MM                MM
RR     RR     LL           SS          MMMM            MMMM
RR      RR    LL          SS           MM MM          MM MM 
RR      RR    LL          SS           MM  MM        MM  MM
RR     RR     LL           SS          MM   MM      MM   MM
RR    RR      LL            SSSSSSSS   MM    MM    MM    MM
RRRRRRR       LL                   SS  MM     MM  MM     MM
RR    RR      LL                    SS MM      MMMM      MM
RR     RR     LL                    SS MM                MM
RR      RR    LL                    SS MM                MM
RR       RR   LL                   SS  MM                MM
RR        RR  LLLLLLLLLLL SSSSSSSSSS   MM                MM

Welcome to the rlsm interactive shell.
Type help for an overview of the availible commands.

EOT
  end
end

