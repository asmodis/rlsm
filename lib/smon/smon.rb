require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rlsm'))

class SMON
  def self.tmp_filename
    "tmp" + Time.now.to_s.gsub(/[ :+]/, '')
  end

  def self.add_help(desc)
    name = desc.delete(:name).to_s
    @@__help[name] = desc
  end

  @@__help = {}

  def initialize(args = {:files => []})
    puts "Welcome to SMON (v#{RLSM::VERSION})"

    #Setting up internal variables
    @out = args[:messenger] || STDOUT

    if args[:path]
      @loadpath = [File.expand_path(File.dirname(__FILE__))] +
        args[:path].split(':').map { |f| File.expand_path(f) }
    else
      @loadpath = [File.expand_path(File.dirname(__FILE__))]
    end

    @objects = []
    @__cmds = []

    #Set up internal help system.
    SMON.add_help :type => 'cmd',
    :name => 'help',
    :summary => 'Shows help for commands.',
    :usage => 'help [<cmd>]',
    :description => <<DESC
If no argument is given, displays an overview of all availible
commands.

The optional <cmd> parameter should be a String or a Symbol, if given,
displays the help to this command.
DESC

    SMON.add_help :type => 'cmd',
    :name => 'exit',
    :summary => 'Finishes the program.',
    :usage => 'exit',
    :description => <<DESC
Finishes the program. Mostly  useful in interactive mode.
DESC

    SMON.add_help :type => 'cmd',
    :name => 'libload',
    :summary => 'Loads a library.',
    :usage => 'libload <lib>',
    :description => <<DESC
Searches in the directorys listed in the @loadpath variable for a file
called '<lib>.rb' or '<lib>' and includes it.

The file content must be a module with name 'SMONLIB<lib>'.
DESC

    #Load all base libraries
    ['base', 'db', 'latex', 'dot'].each do |lib|
      process_command "libload '#{lib}'"
    end

    #Select the mode
    if args[:files].empty?
      interactive_mode
    else
      args[:files].each do |file|
        execute file
      end
    end
  end

  def libload(lib)
    load = []
    @loadpath.each do |path|
      load << Dir.glob( File.join(path, lib) )
      load << Dir.glob( File.join(path, lib + '.rb') )
    end

    load.flatten!

    if load.empty?
      STDERR.puts "E: Could not load library '#{lib}'."
    else
      require load[0]
      self.class.class_eval "include SMONLIB#{lib}"
      STDERR.puts "I: Loaded #{lib}"
    end

    @__cmds = find_all_commands
  end

  def method_missing(cmd, *args)
    puts "Error: Unknown command '#{cmd}'."
  end

  def help(topic = nil)
    if topic
      t = topic.to_s
      if @@__help.key? t
        @out.puts @@__help[t][:summary]
        @out.puts "\nUSAGE: " + @@__help[t][:usage]
        @out.puts
        @out.puts @@__help[t][:description]
      else
        @out.puts "No help for '#{t}' availible."
      end
    else
      @@__help.each_pair do |name, desc|
        @out.puts name.to_s + "\t\t" + desc[:summary]
      end
      @out.puts
    end
  end

  private
  def interactive_mode
    puts "Entering interactive mode."

    @interactive = true
    setup_readline

    puts "\nInteractive mode started."
    puts "Type 'help' to get an overview of all availible commands or"
    puts "type 'help :help' for an explanation of the help system."

    loop { process_command Readline.readline("smon:> ", true) }
  end

  def execute(file)
    if File.exists? file
      STDOUT.puts "Executing file '#{file}' ..."
      begin
        instance_eval File.open(file, 'r') { |f| f.read }
      rescue => e
        STDERR.puts "E: Error while executing '#{file}'. #{e.message}"
      end
    else
      raise Exception, "File '#{file}' not found."
    end
  end

  def find_all_commands
    ['exit'] + self.public_methods -
      (Object.public_methods + ['method_missing'])
  end

  def setup_readline
    require 'readline'

    if @__cmds.include? 'db_stat'
      @__cmds += RLSM::MonoidDB::Columns.map { |x| x.inspect + " =>" }
    end

    Readline.completion_proc = lambda do |str|
      pos = @__cmds.find_all { |cmd| cmd =~ Regexp.new("^#{str}") }
      pos.size == 1 ? pos.first : nil
    end
  end

  def process_command(cmd)
    begin
      if cmd =~ Regexp.new("^(#{@__cmds.join('|')})")
        instance_eval(cmd)
      else
        STDOUT.puts "=> " + instance_eval(cmd).inspect
      end
    rescue RLSMException => e
      STDERR.puts "An error occured. #{e.message}"
    rescue SystemExit
      STDOUT.puts "Cya."
      exit
    rescue Exception => e
      STDERR.puts "An unexpected error occured. #{e.message}"
    end
  end
end

