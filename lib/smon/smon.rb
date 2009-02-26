require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rlsm'))

class SMON
  def initialize(files, messenger)
    @out = messenger
    @objects = []

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
      monoid, dfa = obj.to_monoid, obj.to_dfa
      print_language(monoid, dfa)
      print_monoid_properties(monoid)
      print_submonoids(monoid)
      print_syntactic_properties(monoid)
    else
      STDERR.puts "No object present."
    end
  end

  def help(*args)
    STDERR.puts "Not implemented."
  end


  private
  def print_syntactic_properties(m)
    if m.syntactic?
      @out.puts "SYNTACTIC PROPERTIES:"

      m.all_disjunctive_subsets.each do |ds|
        @out.puts "{#{ds.join(',')}} => #{m.to_dfa(ds).to_re}"
      end
      @out.puts
    end
  end

  def print_submonoids(m)
    subs = m.proper_submonoids.map do |sm|
      binary_operation(sm)
    end

    if subs.empty?
      @out.puts "SUBMONOIDS: none"
      @out.puts
    else
      @out.puts "SUBMONOIDS:"
      rows = [[]]
      width = 0
      subs.each do |sm|
        spl = sm.split("\n")
        if (width + spl[0].length) <= 30
          rows.last << spl
          width += spl[0].length
        else
          rows << [spl]
          width = spl[0].length
        end
      end
      rows.each do |row|
        max_lines = row.map { |sm| sm.size }.max

        row.map! { |sm| sm + [' '*sm[0].length]*(max_lines-sm.size) }
        (0...row[0].size).each do |i|
          @out.puts row.map { |sm| sm[i] }.join('  ')
        end
        @out.puts
      end
    end
  end

  def print_monoid_properties(m)
    block1 = []
    block1 << "PROPERTIES OF THE MONOID:"
    block1 << "   Generator: {#{m.generating_subset.join(',')}}"
    block1 << "       Group: #{m.group?}"
    block1 << " Commutative: #{m.commutative?}"
    block1 << "  Idempotent: #{m.idempotent?}"
    block1 << "   Syntactic: #{m.syntactic?}"
    block1 << "   Aperiodic: #{m.aperiodic?}"
    block1 << "   L-trivial: #{m.l_trivial?}"
    block1 << "   R-trivial: #{m.r_trivial?}"
    block1 << "   D-trivial: #{m.d_trivial?}"
    block1 << "Zero element: #{!m.zero_element.nil?}"

    max_length = block1.map { |row| row.length }.max
    block1.map! { |row| row + ' '*(max_length - row.length) }

    block2 = []
    block2 << "SPECIAL ELEMENTS:"
    block2 << " Idempotents: #{m.idempotents.join(',')}"
    if m.zero_element
      block2 << "Zero element: #{m.zero_element}"
    else
      lz = (m.left_zeros.empty? ? ['none'] : m.left_zeros).join(',')
      block2 << "  Left-Zeros: #{lz}"
      rz = (m.right_zeros.empty? ? ['none'] : m.right_zeros).join(',')
      block2 << " Right-Zeros: #{rz}"
    end
    block2 << ''
    block2 << ''
    block2 << "GREEN RELATIONS:"
    lc = m.l_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    rc = m.r_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    hc = m.h_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    dc = m.d_classes.map { |cl| '{' + cl.join(',') + '}' }.join(' ')
    block2 << "L-Classes: #{lc}"
    block2 << "R-Classes: #{rc}"
    block2 << "H-Classes: #{hc}"
    block2 << "D-Classes: #{dc}"
    block2 << ''

    @out.puts block1.zip(block2).map { |row| row.join('  ') }.join("\n")
    @out.puts
  end

  def print_language(m,d)
    @out.puts "\nDFA:\n#{d.to_s}\n"
    @out.puts "\nMONOID:\n"
    @out.puts binary_operation(m)
    @out.puts
  end

  def binary_operation(monoid)
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

    result = [first]
    result << seperator
    result << rows.join("\n" + seperator + "\n")
    result << seperator

    result.join("\n")
  end

  def get_elements(obj)
    [obj.to_monoid, obj.to_dfa, obj.to_re]
  end

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

  end
=end
