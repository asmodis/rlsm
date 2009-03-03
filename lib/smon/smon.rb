require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rlsm'))

class SMON
  def initialize(args = {:files => []})
    puts "Welcome to SMON (v#{RLSM::VERSION})"

    #Setting up internal variables
    @out = args[:messenger] || STDOUT

    if args[:path]
      @loadpath = args[:path].split ':'
    else
      @loadpath = [File.dirname(__FILE__)]
    end
    
    @objects = []
    @buffer = []
    @out_file = nil
    @__cmds = []
    @__help = {}

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
  end

  def method_missing(cmd, *args)
    puts "Error: Unknown command '#{cmd}'."
  end

  def help(topic = nil)
    if topic
      t = topic.to_s
      if @__help.key? t
        @out.puts @__help[t][:summary]
        @out.puts "\nUSAGE: " + @__help[t][:usage]
        @out.puts
        @out.puts @__help[t][:description]
      else
        @out.puts "No help for '#{t}' availible."
      end
    else
      @out.puts "Listing not implemented."
    end        
  end

  def add_help(desc)
    name = desc.delete(:name).to_s
    @__help[name] = desc
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

  def setup_readline
    require 'readline'

    @__cmds = (self.public_methods + ['exit']) -
      (Object.instance_methods + ['method_missing'])
    if @__db
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

