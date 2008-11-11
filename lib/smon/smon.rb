require "readline"
require "abbrev"
require "rubygems"
require "rlsm"

class Smon
  Commands = []
  CmdHelp = {}
  Categories = {}
  LoadPath = File.join(File.dirname(__FILE__), 'commands')

  def initialize
    #Load all commands
    cmds = Dir.glob(File.join(LoadPath, '*.rb'))
    cmds.each do |cmd|
      load cmd, false
    end

    #Add the built-in commands to the help system
    Commands << 'load'
    CmdHelp['load'] = ["Loads a command into the system.\n",
                       "\nUsage: load /path/to/cmd\n",
                       "\n Loads the file at the given location and prints a small message if loading succeded."]
    Categories['built-in'] = ['load']

    #Initialize the help system
    @cmd_abbrev = Commands.abbrev

    #Setting up readline
    Readline.completion_proc = lambda { |str| @cmd_abbrev[str] }

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

  def load(file, reinit = true)
    #Parsing the file
    cat = nil
    name = nil
    help = []
    parse_help = false
    input = []
    File.open(file).each_line do |line|
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
end

