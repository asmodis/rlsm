require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rlsm'))

class SMON
  def initialize(files, messenger)
    STDOUT.puts "Welcome to SMON (v#{RLSM::VERSION})"
    @out = messenger

    if files.empty?
      interactive_mode
    else
      files.each do |file|
        execute file
      end
    end
  end

  private
  def interactive_mode
    @out.puts "Entering interactive mode."
  end

  def execute(file)
    if File.exists? file
      STDOUT.puts "Executing file '#{file}' ..."
      instance_eval File.open(file, 'r') { |f| f.read }
    else
      raise Exception, "File '#{file}' not found."
    end
  end
end
=begin
  def run(args)
    if args.empty?
      interactive_mode
    else
      args.each do |file|
        process_file file
      end
    end
  end

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
      puts obj.to_s
    else
      puts "No object present."
    end
  end

  def help(*args)
    puts "Not implemented."
  end

  def db_stat
    stat = RLSM::MonoidDB.statistic
    result = stat.shift.join(' | ')

    column_widths = result.scan(/./).inject([0]) do |res,char|
      if char == '|'
        res << 0
      else
        res << res.pop + 1
      end

      res
    end

    result += ("\n" + '   ' + result.gsub(/[^|]/, '-').gsub('|', '+'))

    stat.each do |row|
      justified = []
      row.each_with_index do |col,i|
        col = col.to_s
        space = ' '*((column_widths[i] - col.length)/2)
        extra_space = ' '*((column_widths[i] - col.length)%2)
        justified << space + col + space + extra_space
      end

      result += ("\n" + '   ' + justified.join('|'))
    end

    puts result
  end

  def db_find(args)
    count = RLSM::MonoidDB.count(args)
    puts "Found: #{count[0]} monoid(s) (#{count[1]} syntactic)"
    puts "Saved result in variable '@search_result'"

    @search_result = RLSM::MonoidDB.find(args).flatten
  end

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

  def print_properties(monoid)
  end

  def print_syntactic_properties(monoid)
  end

  def interactive_mode
    puts "Starting interactive mode ..."
    puts "Type 'help' to get an overview of all availible commands or"
    puts "type 'help :help' for an explanation of the help system."

    @interactive = true

    #setup_help_system
    setup_readline

    loop { process_command Readline.readline("smon:> ", true) }
  end

  def setup_readline
    require 'readline'
    @_commands = %w(quit exit help show describe monoid regexp dfa
    db_find db_stat) + RLSM::MonoidDB::Columns.map { |c| c.inspect + " =>" }

    Readline.completion_proc = lambda do |str|
      pos = @_commands.find_all { |cmd| cmd =~ Regexp.new("^#{str}") }
      pos.size == 1 ? pos.first : nil
    end
  end

  def process_file(file)
    unless File.exists? file
      puts "Error: File '#{file}' not found."
      exit
    end

    puts "Processing file '#{file}' ..."
    script = File.open(file, 'r') { |f| f.read }
    begin
      instance_eval script
    rescue Exception => e
      puts "Error while processing '#{file}'."
      p e
    end
  end

  def process_command(cmd)
    begin
      if cmd =~ Regexp.new("^(#{@_commands.join('|')})")
        instance_eval(cmd)
      else
        puts "=> " + instance_eval(cmd).inspect
      end
    rescue RLSMException => e
      puts "An error occured."
      p e
    rescue SystemExit
      puts "Cya."
      exit
    rescue Exception => e
      puts "An unexpected error occured."
      p e
    end
  end
end
=end
