require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rlsm'))
require 'enumerator'

class RLSM::RE
  LeftBracket = '('
  RightBracket = ')'
  Star = '*'
  Union = '|'
  Lambda = '&'
  Specials = [LeftBracket, RightBracket, Star, Union, Lambda]

  def to_s
    @pattern
  end

  def inspect
    "<#{self.class}: #@pattern>"
  end

  def initialize(pattern = '')
    if pattern == ''
      @empty_set = true
    elsif pattern.scan(/./).all? { |x| Specials.include? x }
      @pattern = Lambda
    else
      @pattern = pattern
    end

    unless @empty_set
      validate_brackets_balanced
      validate_form
      preparse
      parse
    else
      @pattern = ''
      @parsed  = { :first => [], :last => [], :follow => [], :null => false }
    end
  end

  #Returns the patttern of the regexp
  attr_reader :pattern

  #Returns the union of this and the other re as new re.
  def +(other)
    #One is the empty set?
    return RLSM::RE.new(@pattern) if other.pattern == ''
    return RLSM::RE.new(other.pattern) if @pattern == ''

    RLSM::RE.new(LeftBracket + @pattern + RightBracket +
                 Union +
                 LeftBracket + other.pattern + RightBracket)
  end

  #Returns the catenation of this and other re.
  def *(other)
    #One is the empty set?
    return RLSM::RE.new if other.pattern == '' or @pattern == ''

    RLSM::RE.new(LeftBracket + @pattern + RightBracket +
                  LeftBracket + other.pattern + RightBracket)
  end

  #Returns the stared re.
  def star
    return RLSM::RE.new if @pattern == ''
    RLSM::RE.new(LeftBracket + @pattern + RightBracket + Star)
  end

  #Alters the re in place to the star form. Returns the altered re.
  def star!
    unless @pattern == ''
      @pattern = LeftBracket + @pattern + RightBracket + Star
      parse
    end

    self
  end

  #Returns a minimal DFA which accepts the same language.
  def to_dfa
    if @empty_set
      RLSM::DFA.new(:alphabet => [],:states => ['0'],:initial => '0',
                        :finals => [], :transitions => [])
    else
      add_initial_state
      perform_subset_construction
      RLSM::DFA.create(@dfa_hash).minimize!(:rename => :new)
    end
  end

  #Returns the syntactic monoid to this language.
  def to_monoid
    to_dfa.to_monoid
  end

  #Returns true if the res are equal
  def ==(other)
    return true if @pattern == other.pattern

    to_dfa.isomorph_to?(other.to_dfa)
  end

  private
  def add_initial_state
    @parsed[:initial] = [-1]
    @parsed[:follow] |= @parsed[:initial].product(@parsed[:first])
  end

  def perform_subset_construction
    @dfa_hash = {:transitions => [], :finals => [], :initial => '0'}
    @dfa_hash[:finals] << @parsed[:initial] if @parsed[:null]
    alphabet = @iso.uniq
    unmarked = [@parsed[:initial]]
    marked = []
    until unmarked.empty?
      state = unmarked.shift
      marked << state
      alphabet.each do |char|
        nstate = move(state, char)
        unmarked << nstate unless (unmarked | marked).include? nstate
        if @parsed[:last].any? { |x| nstate.include? x }
          @dfa_hash[:finals] << nstate unless @dfa_hash[:finals].include? nstate
        end
        @dfa_hash[:transitions] << [char, state, nstate]
      end
    end

    @dfa_hash[:finals].map! { |x| marked.index(x).to_s }
    @dfa_hash[:transitions].map! { |c,x,y| [c,marked.index(x).to_s,
                                            marked.index(y).to_s] }
  end

  def move(state,c)
    state.map do |x|
      @parsed[:follow].find_all { |y,z| y == x and @iso[z] == c }.map do |a|
        a.last
      end
    end.flatten.uniq.sort
  end

  def parse
    pat, @iso = transform_pattern_to_unique_identifiers

    @parsed = parse_pattern(pat)
    @pattern = @parsed[:pattern]
  end

  def parse_pattern(pat, parent = nil)
    pat = remove_surrounding_brackets pat
    pat = [Lambda] if pat.all? { |x| Specials.include? x }

    case type_of pat
    when :term  : return parse_term(pat, parent)
    when :star  : return parse_star(pat, parent)
    when :union : return parse_union(pat, parent)
    when :cat : return parse_cat(pat, parent)
    else
      raise REException, "Unable to parse pattern: #{pat.join}"
    end
  end

  def parse_children(childs, parent)
    childs.map { |child| parse_pattern(child, parent) }
  end

  def recursive_split(child, type)
    if type_of(child) == type
      return self.send "split_#{type}".to_sym, child
    else
      return [child]
    end
  end

  def parse_union(p, parent)
    childs = parse_children(split_union(p), parent)
    childs = simplify_union(childs, parent)

    #If after simplification there is only one child left, the union isn't
    #needed anymore.
    return childs.first if childs.size == 1

    childs = sort_union(childs)

    construct_union_result_from childs
  end

  def split_union(p)
    depth = 0
    splitted = [[]]
    p.each do |x|
      depth += count(x)
      if depth == 0 and x == Union
        splitted << remove_surrounding_brackets(splitted.pop)
        splitted << []
      else
        splitted.last << x
      end
    end

    splitted.inject([]) { |res,x| res | recursive_split(x, :union) }
  end

  def simplify_union(childs, parent)
    #Check if we need an empty word, not the case if
    # - parent is a star
    # - some nullable choices exists
    if childs.any? { |x| x[:null] and x[:pattern] != Lambda } or parent == :star
      childs = childs.reject { |x| x[:pattern] == Lambda }
    end

    #Simplify somthing like 'a|a' to 'a'
    childs.inject([]) do |res,child|
      res << child unless res.any? { |x| x[:pattern] == child[:pattern] }
      res
    end
  end

  def sort_union(childs)
    childs.sort do |x1,x2|
      if x1[:pattern] == Lambda
        -1
      elsif x2[:pattern] == Lambda
        1
      else
        x1[:pattern] <=> x2[:pattern]
      end
    end
  end

  def construct_union_result_from(childs)
    res = {}
    res[:type] = :union

    res[:null] = childs.any? { |x| x[:null] }
    res[:first] = childs.map { |x| x[:first] }.flatten
    res[:last] = childs.map { |x| x[:last] }.flatten
    res[:follow] = childs.inject([]) { |r,x| r | x[:follow] }
    res[:pattern] = childs.map { |x| x[:pattern] }.join(Union)

    res
  end

  def parse_cat(p, parent)
    childs = parse_children(split_cat(p), parent)

    childs = simplify_cat(childs, parent)

    #If after simplification there is only one child left, the cat isn't
    #needed anymore.
    return childs.first if childs.size == 1

    construct_cat_result_from childs
  end

  def split_cat(p)
    splitted = [[]]
    depth = 0
    p.each_with_index do |x,i|
      depth += count(x)
      if depth == 1 and x == LeftBracket
        splitted << [LeftBracket]
      elsif depth == 0
        if p[i+1] == Star
          if x == RightBracket
            splitted.last << RightBracket
            splitted.last << Star
            splitted << []
          else
            splitted << [x,Star]
            splitted << []
          end
        else
          splitted.last << x unless x == Star
          if x == RightBracket
            last = splitted.pop
            splitted << remove_surrounding_brackets(last) unless last.empty?
            splitted << []
          end
        end
      else
        splitted.last << x
      end
    end

    splitted.inject([]) do |res,x|
      unless x.empty? or x == [Lambda]
        res | recursive_split(x, :cat)
      else
        res
      end
    end
  end

  def simplify_cat(childs, parent)
    #Simplify a*a* to a*
    childs = childs.inject([]) do |res, child|
      unless child[:type] == :star and
          res.last and res.last[:type] == :star and
          child[:pattern] == res.last[:pattern]
        res << child
      end

      res
    end

    #Simplify (aa*)* to a*
    if parent == :star and childs.size == 2
      star_exp, other = childs.partition { |x| x[:type] == :star }
      unless star_exp.empty? or other.empty?
        p1 = remove_surrounding_brackets(star_exp.first[:pattern].
                                         scan(/./)[0..-2])
        p2 = remove_surrounding_brackets(other.first[:pattern].
                                         scan(/./))

        if p1 == p2
          return other
        end
      end
    end

    childs
  end

  def construct_cat_result_from(childs)
    childs.map! do |x|
      if x[:type] == :union
        x[:pattern] = LeftBracket + x[:pattern] + RightBracket
        x
      else
        x
      end
    end

    res = {}
    res[:null] = childs.all? { |x| x[:null] }

    childs.each do |x|
      res[:first] = (res[:first] ||= []) | x[:first]
      break unless x[:null]
    end

    childs.reverse.each do |x|
      res[:last] = (res[:last] ||= []) | x[:last]
      break unless x[:null]
    end

    res[:follow] = childs.inject([]) { |r,x| r | x[:follow] }

    (1...childs.size).each do |i|
      res[:follow] |= childs[i-1][:last].product(childs[i][:first])
      j = i
      while childs[j][:null] and (j < childs.size - 1)
        res[:follow] |= childs[i-1][:last].product(childs[j+1][:first])
        j += 1
      end
    end

    res[:pattern] = childs.map { |x| x[:pattern] }.join

    res
  end

  def parse_term(pat, parent)
    pat = pat.reject { |x| x == Lambda }

    res = {}

    res[:first] = [pat.first].compact
    res[:last] = [pat.last].compact
    res[:follow] = pat.enum_cons(2).to_a
    res[:null] = pat.empty?
    res[:pattern] = if res[:null]
                      Lambda
                    else
                      pat.map { |i| @iso[i] }.join
                    end
    res
  end

  def parse_star(pat, parent)
    pat = remove_surrounding_brackets(pat[0..-2])
    child = parse_pattern(pat, :star)

    if child[:pattern] == Lambda or child[:type] == :star
      return child
    else
      res = {}
      res[:type] = :star
      res[:null] = true
      res[:first] = child[:first]
      res[:last] = child[:last]
      res[:follow] = (child[:follow] | child[:last].product(child[:first]))
      res[:pattern] = if child[:pattern].size > 1
                        LeftBracket + child[:pattern] + RightBracket + Star
                      else
                        child[:pattern] + Star
                      end

      return res
    end
  end

  def remove_surrounding_brackets(pat)
    pat = pat[1..-2] while type_of(pat) == :surr_brackets
    pat
  end

  def type_of(p)
    return :term unless p.any? { |x| (Specials - [Lambda]).include? x }

    unnested_characters = []
    depth = 0
    p.each do |x|
      if x == LeftBracket
        unnested_characters << x if depth == 0
        depth += 1
      elsif x == RightBracket
        depth -= 1
        unnested_characters << x if depth == 0
      else
        unnested_characters << x if depth == 0
      end
    end

    return :union if unnested_characters.include? Union
    return :star if p.size == 2 and p.last == Star and !Specials.include? p[0]
    return :star if unnested_characters == [LeftBracket, RightBracket, Star]
    return :surr_brackets if unnested_characters == [LeftBracket, RightBracket]
    :cat
  end

  def transform_pattern_to_unique_identifiers
    pat = @pattern.scan(/./)
    iso = []
    for i in (0...pat.size)
      next if Specials.include? pat[i]
      iso << pat[i]
      pat[i] = iso.size - 1
    end

    [pat, iso]
  end

  def preparse
    substitute_empty_brackets
    simplify_brackets_around_singeltons
    simplify_lambdastar_to_lambda
    simplify_implicit_empty_set_unions
    squeeze_repeated_specials
  end

  def squeeze_repeated_specials
    @pattern.squeeze! Star
    @pattern.squeeze! Union
    @pattern.squeeze! Lambda
  end

  def simplify_implicit_empty_set_unions
    @pattern.gsub!(LeftBracket + Union, LeftBracket)
    @pattern.gsub!(LeftBracket + Star + Union, LeftBracket)
    @pattern.gsub!(Union + Star + Union, Union)
  end

  def simplify_lambdastar_to_lambda
    str = Lambda + Star
    @pattern.gsub!(str, Lambda) while @pattern.include? str
  end

  def substitute_empty_brackets
    @pattern.gsub! LeftBracket + RightBracket, Lambda
  end

  def simplify_brackets_around_singeltons
    re = Regexp.new("\\#{LeftBracket}(.)\\#{RightBracket}")
    @pattern.gsub!(re, '\1') while @pattern =~ re
  end

  def validate_form
    if @pattern =~ Regexp.new("\\#{LeftBracket}\\#{Star}[^#{Specials.join}]")
      raise REException, "Not wellformed. Detected '#{Regexp.last_match(0)}'"
    end
  end

  def validate_brackets_balanced
    unless 0 == @pattern.scan(/./).inject(0) do |res,x|
        res += count(x)
        break if res < 0
        res
      end
      raise REException, "Unbalanced parentheses in pattern!"
    end
  end

  def count(x)
    return 1 if x == LeftBracket
    return -1 if x == RightBracket
    0
  end
end
