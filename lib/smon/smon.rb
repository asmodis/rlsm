require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rlsm'))

class SMON
  def initialize(files, messenger)
    @out = messenger

    puts "Welcome to SMON (v#{RLSM::VERSION})"
    load_features

    if files.empty?
      interactive_mode
    else
      files.each do |file|
        execute file
      end
    end
  end

  #A synonym for exit.
  def quit
    exit
  end

  def method_missing(cmd, *args)
    puts "Error: Unknown command '#{cmd}'."
  end

  def monoid(mon)
    @objects << RLSM::Monoid.new(mon)
    puts "=> #{@objects.last.inspect}" if @interactive
    @monoid = @objects.last
  end

  def dfa(dfa)
    @objects << RLSM::DFA.create(dfa)
    puts "=> #{@objects.last.inspect}" if @interactive
    @dfa = @objects.last
  end

  def regexp(re)
    @objects << RLSM::RE.new(re)
    puts "=> #{@objects.last.inspect}" if @interactive
    @re = @objects.last
  end

  def show(obj = nil)
    obj ||= @objects.last
    if obj
      @out.puts obj.to_s
      @out.puts
    else
      STDERR.puts "No object present."
    end
  end

  def describe(obj = nil)
    obj ||= @objects.last

    if obj
      STDERR.puts "not implemented"
    else
      STDERR.puts "No object present."
    end
  end

  def help(*args)
    STDERR.puts "Not implemented."
  end


  private
  def interactive_mode
    puts "Entering interactive mode."

    puts "Setting up the help system ..."
    #setup_help_system

    puts "Setting up readline ..."
    setup_readline


    @interactive = true

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

  def load_features
    puts "Checking optional features ..."
    begin
      require 'database'
      require 'smon/db'
      self.class.class_eval "include SmonDB"
      @__db = true
    rescue => e
      STDERR.puts "W: Could not load feature 'db': #{e.message}"
    end

    require 'smon/latex'
    self.class.class_eval "include SmonLatex"

    require 'smon/dot'
    self.class.class_eval "include SmonDot"
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
=begin

  def describe(obj)
    monoid = obj.to_monoid
    print_binary_operation(monoid)
    print_properties(monoid)
    print_syntactic_properties(monoid)
  end

  private
  def print_binary_operation(monoid)
    max_length = monoid.elements.map { |e| e.length }.max
    rows = monoid.binary_operation.map do |row|
      row.map do |e|
        space = ' '*((max_length - e.length)/2)
        extra_space = ' '*((max_length - e.length)%2)
        space + extra_space + e + space
      end.join(' | ')
    end

    first =  ' '*(max_length + 2) + '| ' + rows[0].clone + ' |'
    seperator = first.gsub(/[^|]/,'-').gsub('|', '+')

    rows.map! do |row|
      ' ' + row[/^[^|]+\|/] + ' ' + row + " |"
    end

    puts first
    puts seperator
    puts rows.join("\n" + seperator + "\n")
    puts seperator
    puts
  end
=end
