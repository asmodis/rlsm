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


require File.join(File.dirname(__FILE__), 'monkey_patching')
require File.join(File.dirname(__FILE__), 'dfa')

# A Monoid is a set of elements with an associative binary operation and a neutral element.
module RLSM
class Monoid

  def initialize(table, options = {})
    options[:normalize] = true if options[:normalize].nil?

    _create_binary_operation(table, options[:names])
    _check_form_of_binary_operation
    _check_associativity_of_binary_operation

    @elements = (0...@order).to_a
    
    #If no neutral element exists an exception is thrown, otherwise the 
    #neutral element is moved to position 0
    _check_and_rearrange_neutral_element
    _normalize if options[:normalize]
    _create_element_names if options[:create_names]
  end


#--
#READER METHODS
#++
  #Returns the order of the monoid.
  attr_reader :order
  
  #Returns a copy of the elements of the monoid.
  def elements
    @names.dup
  end

  #Returns a copy of the binary operation of the monoid.
  def binary_operation
    @bo.deep_copy
  end

  #Returns the product of the given elements
  def[](a,b)
    a,b = check_arguments(a,b)
    @bo[a][b]
  end


#--
#SOME PROPERTIES CHECKS
#++
  #Returns true if the monoid is commutative.
  def commutative?
    return @commutative unless @commutative.nil?

    @commutative = @elements.tuples.all? { |a,b| self[a,b] == self[b,a] }
  end

  #Returns true if the given element is idempotent. With no arguments called, returns true if all elements are idempotent.
  def idempotent?(x=nil)
    x = *check_arguments(x) if x

    x ? self[x,x] == x : @elements.all? { |x| idempotent? x }
  end

  #Returns true if the monoid is syntactic. 
  def syntactic?
    return @syntactic unless @syntactic.nil?

    #Order 1 is a bit special...
    return(@syntactic = true) if @order == 1

    disjunctive_subset ? @syntactic = true : @syntactic = false
  end

  #Returns true if the monoid is aperiodic.
  def aperiodic?
    return @aperiodic unless @aperiodic.nil?

    @aperiodic ||= h_classes.all? { |hc| hc.size == 1 }
  end

  #Returns true if the monoid is a group.
  def group?
    return @group unless @proup.nil?

    @group ||= (idempotents.size == 1)
  end

#--
#DISJUNCTIVE SET STUFF
#++
  #Returns true if the given set s is a disjunctive subset.
  def subset_disjunctive?(s)
    @elements.tuples.all? do |a,b|
      (a == b) or  @elements.tuples.any? do |x,y|
          s.include?(self[x,self[a,y]]) ^ s.include?(self[x,self[b,y]])
      end
    end
  end

  #Returns the first disjunctive subset if there is any. Otherwise nil is returned.
  def disjunctive_subset
    return [] if @order == 1

    @disjunctive_subset ||= 
      @elements.proper_subsets.find { |s| subset_disjunctive?(s) }
  end

  #Returns all disjunctive subsets.
  def all_disjunctive_subsets
    @ads ||= @elements.proper_subsets.select { |s| subset_disjunctive?(s) }
  end


#--
#SUBMONOID STUFF
#++
  #Returns (one of the) smallest sets of elements, which generates the monoid.
  def generating_subset
    @gs ||= @elements.powerset.find do |s| 
      _get_closure_of(s).size == @order
    end
  end

  #Returns true if this monoid is a submonoid of :other:
  def submonoid_of?(other)
    other.have_submonoid?(self)
  end

  #Returns true if :other: is a submonoid of this monoid.
  def have_as_submonoid?(other)
    submonoids_of_order(other.order).any? { |m| m == other }
  end

  #Returns all proper submonoids.
  def proper_submonoids(up_to_iso=true)
    (2..@order-1).to_a.map { |i| submonoids_of_order(i, up_to_iso) }.flatten
  end

  #Returns all submonoids.
  def submonoids(up_to_iso=true)
    (1..@order).to_a.map { |i| submonoids_of_order(i, up_to_iso) }.flatten
  end

  #Returns all submonoids of the given order.
  def submonoids_of_order(order, up_to_iso = true)
    pos = @elements.powerset.map { |s|
      _get_closure_of(s) }.select { |s| s.size == order }.uniq.sort

    pos.inject([]) do |soo,s|
      sm = get_submonoid(s)
      unless up_to_iso and soo.any? { |m| m == sm }
        soo << sm
      end
      soo
    end
  end

  #Returns the submonoid which is generated by the given set of elements :s:
  def get_submonoid(s)
    s = _get_closure_of(s)

    table = @bo.values_at(*s).map { |r| r.values_at(*s) }

    table.map! do |row|
      row.map { |x| s.index(x) }
    end

    Monoid.new table, :names => @names.values_at(*s), :normalize => false
  end

#--
#ISOMORPHISM STUFF
#++
  #Returns true, if this monoid is isomorph to :other:.
  def isomorph_to?(other)
    #First a trivial check
    return false if @order != other.order

    isomorphisms.any? do |i|
      @elements.tuples.all? { |a,b| i[self[a,b]] == other[i[a],i[b]] }
    end
  end

  #Synonym for isomorph_to?
  def ==(other)
    isomorph_to?(other)
  end

  #Synonym for isomorph_to?
  def eql?(other)
    isomorph_to?(other)
  end

#--
#GREEN RELATIONS AND IDEAL STUFF
#++
  #Returns the left ideal of :a:.
  def left_ideal_of(a)
    a = *check_arguments(a)
    @elements.inject([]) { |li,x| li.add? self[x,a]; li }.sort
  end

  #Returns the right ideal of :a:.
  def right_ideal_of(a)
    a = *check_arguments(a)
    @elements.inject([]) { |ri,x| ri.add? self[a,x]; ri }.sort
  end

  #Returns the two-sided ideal of :a:.
  def ideal_of(a)
    a = *check_arguments(a)
    res = []
    @elements.tuples.each { |x,y| res.add? self[x,self[a,y]] }
    res.sort
  end

  #Returns the L-class of :a:.
  def l_class_of(a)
    l_a = left_ideal_of a
    (@elements.select { |x| left_ideal_of(x) == l_a }).sort
  end

  #Returns the R-class of :a:.
  def r_class_of(a)
    r_a = right_ideal_of a
    (@elements.select { |x| right_ideal_of(x) == r_a }).sort
  end

  #Returns the H-class of :a:.
  def h_class_of(a)
    (l_class_of(a) & r_class_of(a)).sort
  end

  #Returns the D-class of :a:.
  def d_class_of(a)
    rc_a = r_class_of a
    (@elements.select { |x| (l_class_of(x) & rc_a).size > 0}).sort
  end

  #Returns all L classes
  def l_classes
    @elements.map { |x| l_class_of(x) }.uniq
  end

  #Returns all R classes
  def r_classes
    @elements.map { |x| r_class_of(x) }.uniq
  end

  #Returns all H classes
  def h_classes
    @elements.map { |x| h_class_of(x) }.uniq
  end

  #Returns all D classes
  def d_classes
    @elements.map { |x| d_class_of(x) }.uniq
  end

  #Returns true if L relation is the identity
  def l_trivial?
    l_classes.all? { |lc| lc.size == 1 }
  end

  #Returns true if R relation is the identity
  def r_trivial?
    r_classes.all? { |rc| rc.size == 1 }
  end

  #Returns true if D relation is the identity
  def d_trivial?
    d_classes.all? { |dc| dc.size == 1 }
  end

  #Returns true if H relation is the identity. This is a synonym for aperiodic?
  def h_trivial?
    aperiodic?
  end

#--
#SPECIAL ELEMENTS
#++
  #Returns the index of the null element if any exists, otherwise false is returned.
  def null_element
    return @null_element unless @null_element.nil?

    #for a null element, there must exist at least two elements
    return @null_element = false if @order == 1

    ne = @elements.find do |n| 
      @elements.all? { |x| self[n,x] == n and self[x,n] == n }
    end

    @null_element = ne ? ne : false
  end

  #Returns true if the given element is a left null, i.e. ay = a for all y
  def left_null?(a)
    a = *check_arguments(a)
    return false if @order == 1
    @elements.all? { |y| self[a,y] == a }
  end

  #Returns true if the given element is a right null, i.e. ya = a for all y
  def right_null?(a)
    a = *check_arguments(a)
    return false if @order == 1
    @elements.all? { |y| self[y,a] == a }
  end

  #Returns an array containing all left nulls.
  def left_nulls
    @elements.select { |x| left_null? x }
  end

  #Returns an array containing all right nulls.
  def right_nulls
    @elements.select { |x| right_null? x }
  end

  #Returns an array with all idempotent elements. (Remark: the neutral element is always idempotent).
  def idempotents
    @idempotents ||= @elements.select { |x| idempotent? x }
  end


#--
#MISC
#++
  #Returns a string representation of the binary operator.
  def to_s
    @bo.map { |r| r.join(@order > 10 ? "," : "") }.join(" ")
  end

  def inspect # :nodoc:
    "<Monoid #{self.object_id}: {" + @names.join(",") + "};#{to_s}>"
  end

  def hash  # :nodoc:
    isomorphisms.map { |i| bo_str_after_iso(i) }.min
  end

  #Returns a DFA with the monoid elements as states, the neutral element as initial state and transitions given by the binary operation. The argument gives the final states. If the monoid is syntactic, the finals must be a disjunctive subset. If no argument is given in this case, the smallest disjunctive subset is used.
  def to_dfa(finals = [])
    alph = @names.values_at(generating_subset)
    states = @names.clone
    inital = @names.first

    if syntactic?
      if finals.empty?
        finals = disjunctive_subset
      else
        unless all_disjunctive_subsets.include? check_arguments(*finals).sort
          raise MonoidException, "finals must be a disjunctive subset"
        end
      end
    end
    
    trans = []
    alph.each do |char|
      @names.each { |s1| trans << [char, s1, self[s1,char]] }
    end

    RLSM::DFA.new alph, states, initial, finals, trans    
  end
  
  private
  def isomorphisms
    #In every monoid the neutral element is 0, so isomorphisms must
    #map 0 to 0
    @elements[1..-1].permutations.map { |p| p.unshift(0) }
  end

  def check_arguments(*args)
    #Get the internal representation of each argument
    args.map! { |x| if x.kind_of? Integer then x else @names.index(x) end }

    unless args.all? { |arg| @elements.include? arg }
      raise MonoidException, "Bad Argument: #{args.inspect}" 
    end
    
    args
  end

  def transpose(a,b)
    #somthing to do?
    return if a == b

    a,b = check_arguments(a,b)

    #create the transposition
    t = (0...@order).to_a
    t[a], t[b] = b, a

    #Rename the elements
    @bo = @bo.flatten.map { |x| t[x] }/@order

    #swap the columns
    @bo.map! { |r| r[a], r[b] = r[t[a]], r[t[b]]; r }

    #swap the rows
    @bo[a], @bo[b] = @bo[t[a]], @bo[t[b]]

    #update names
    @names[a], @names[b] = @names[b], @names[a]
  end

  def bo_str_after_iso(iso)
    bo = @bo.deep_copy
    (0...@order).to_a.tuples.each do |i,j|
      bo[i][j] = iso[@bo[iso.index(i)][iso.index(j)]]
    end

    bo.map { |r| r.join(@order >10 ? ',' : '') }.join(' ')
  end   

  def _get_closure_of(s)
    res = s.dup
    res = check_arguments(*res)
    res.add? 0

    order = 1

    loop do
      order = res.size
      res.tuples.each do |a,b|
        res.add? self[a,b]
        res.add? self[b,a]
      end
      
      break if order == res.size
    end

    res.sort
  end

  def _create_binary_operation(table, names)
    if table.instance_of? Array
      @order = table.size
      @bo = table
    elsif table.instance_of? String
      #Normalizing the string, i.e. removing double spaces, trailing newlines...
      table.chomp!
      table.squeeze!(' ')
      table.gsub!(", ", ",")

      #Take the number of rows as order of the monoid
      @order = table.split.size

      #Transform now the string in a matrix
      if table.include? ","
        @bo = table.gsub(" ", ",").split(",")/@order
      else
        @bo = table.gsub(" ", "").scan(/./)/@order
      end
    end

    #Convert to internal represenation
    #Names given?
    if names and names.class == Array and names.size == @order
      @names = names
    else
      #Make a guess, works if convention is followed.
      @names = @bo.flatten.uniq.clone
    end

    @bo = (@bo.flatten.map { |e| @names.index(e) })/@order
  end

  def _check_form_of_binary_operation
    #Is the matrix quadratic?
    unless @bo.all? { |r| r.size == @order }
      raise MonoidException, "InitError: A binary operation must be quadratic."
    end

    #Are the matrix elements in the right range? 
    unless @bo.flatten.all? { |e| (0...@order).include? e }
      raise MonoidException, "InitError: Too big numbers in description."
    end
  end

  def _check_associativity_of_binary_operation
    unless (0...@order).to_a.triples.all? do |a,b,c| 
        @bo[a][@bo[b][c]] == @bo[@bo[a][b]][c]
      end
      raise MonoidException, "InitError: Given binary operation isn't associative."
    end
  end

  def _check_and_rearrange_neutral_element
    one = (0...@order).find do |e|
      (0...@order).all? { |x| @bo[e][x] == @bo[x][e] and @bo[e][x] == x }
    end

    one ? transpose(0,one) : raise(MonoidException, "InitError: Given binary operation has no neutral element.")
  end

  def _create_element_names
    @names = []
    char = "a"
    @elements.each do |i|
      if i == 0
        @names << "1" 
      else
        @names << char.clone
        char.succ!
      end
    end
  end

  def _normalize
    gs = generating_subset

    #rearrange such that the generators are the first elements
    #after the neutral element
    gs.each_with_index { |x,i| transpose(x,i+1) }

    #set the new generating subset
    @gs = (1..gs.size).to_a
  end
end
end
