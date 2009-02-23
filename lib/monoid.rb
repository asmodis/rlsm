require File.expand_path(File.join(File.dirname(__FILE__), 'rlsm'))
require 'dfa'

=begin rdoc
=The RLSM::Monoid class
===Definition of a monoid
A _monoid_ is a tuple <tt>(M,B)</tt> where
* +M+ is a set of _elements_
* <tt>B:M x M -> M</tt> is a _binary_ _operation_
with the following properties
* the binary operation is associative ( <tt>B(a,B(b,c)) = B(B(a,b),c)</tt> for all <tt>a,b,c</tt> in +M+)
* It exists an element +e+ in +M+ with <tt>B(a,e) = B(e,a) = a</tt> for all +a+ in +M+ (the neutral element).

In theory the set +M+ may be of infinite size, but for obvious reasons we consider here only the finite case. The size of +M+ is called the _order_ of the monoid.

Also we denote the product of two elements by

 B(x,y) =: xy


===A word on the binary operation
Suppose that <tt>M = {e,b,c}</tt>. We can describe the binary operation as a table, for example

    | e | a | b |  <-- this row gives only a correspondence between
 ---+---+---+---+      columns and monoid elements (analog the first column,
  e | e | a | b |      which gives a correspondence between rows and elements).
 ---+---+---+---+
  a | a | a | b |
 ---+---+---+---+
  b | b | a | b |
 ---+---+---+---+

For two elements <tt>x,y</tt>, the product +xy+ can be looked up in the table as follows: Say <tt>x = a</tt> and <tt>y = b</tt> the product +ab+ is then the entry in row +a+ and column +b+ (in this case it is +b+).

This gives us an easy way to express a binary operation in code. It is simply a 2D-array. We see immediatly two restrictions:
* Ignoring the descreptive first row and first column, the array must be quadratic
* Each entry must be a monoid element

If we now agree upon the convention that the first row and column belongs to the neutral element, we can discard the row and column description because of the fact, that in this case the first row and column are identical with the descriptions (compare above example).

===Basic properties of monoids and monoid elements
Given two monoids <tt>(M,B), (N,C)</tt> we say the monoids are _isomorph_ _to_ each other iff there exists a bijective map <tt>I : M -> N</tt> such that the equality
 I(B(x,y)) = C(I(x),I(y))
holds for all <tt>x,y</tt> in +M+. The map +I+ is then called an _isomorphism_.

The monoids are _anti_-_isomorph_ _to_ each other iff there exists a bijective map <tt>A : M -> N </tt>  such that the equality
 A(B(x,y)) = C(A(y),A(x))
holds for all <tt>x,y</tt> in +M+. The map +A+ is then called an _anti_-_isomorphism_.

We say a monoid <tt>(M,B)</tt> is _commutative_ iff the equality
 B(x,y) = B(y,x)
holds for all <tt>x,y</tt> in +M+.

An element +l+ of +M+ is called a _left_-_zero_ iff for all +x+ in +M+
 lx = l
holds. An element +r+ of +M+ is called a _right_-_zero_ iff for all +x+ in +M+
 xr = r
holds. An element +z+ of +M+ is called a _zero_ _element_ iff for all +x+ in +M+
 zx = xz = z
holds. If it exists, the zero element is unique.

An element +a+ of +M+ is called a _idempotent_ iff <tt>xx = x</tt>. A monoid +M+ is called _idempotent_ if all elements are idempotent.

It is easy to see that a monoid is a group (i.e. for all elements +x+ there exists an element +y+ such that <tt>xy = yx = 1</tt> where +1+ is the neutral element) if the neutral element is the only idempotent element.

===Submonoids and generators
Given two monoids <tt>(M,B), (N,C)</tt> we say +M+ is a _submonoid_ of +N+ iff there exists an injective map <tt>S : M -> N</tt> such that the equality
 S(B(x,y)) = C(S(x),S(y))
holds for all <tt>x,y</tt> in +M+ and +M+ is a subset of +N+.

A submonoid +N+ of +M+ is called a _proper_ _submonoid_ if <tt>N != M</tt> and +N+ has more than one element.

Let <tt>(M,B)</tt> with <tt>M = {m1,m2,m3,...}</tt> be a monoid and <tt>N = {n1,n2,...}</tt> be a subset of +M+. Then the set
 <N> := { x | x is the product of arbitary powers of elements in N }
is a submonoid of +M+ with +B+ restricted to <tt>NxN</tt>. It is called the submonoid _generated_ _by_ +N+ and +N+ is called the _generator_.

A _generating_ _subset_ of a Monoid +M+ is a subset +N+ of +M+ such that <tt><N>=M</tt>.

===Ideals of a monoid and Green Relations
Let +M+ be a monoid and +a+ in +M+. We define
 Ma  := {xa | x in M}
 aM  := {ax | x in M}
 MaM := {xay | x,y in M}
and call +Ma+ the _left_ _ideal_ of +a+, +aM+ the _right_ _ideal_ of +a+ and +MaM+ the (_two_-_sided_) _ideal_ of +a+.

We can now define some equivalent relations on +M+:
 a =L= b :<=> Ma = Mb
 a =R= b :<=> aM = bM
 a =J= b :<=> MaM = MbM
 a =H= b :<=> a =L= b and a =R= b
 a =D= b :<=> it exists a c in +M+ such that a =L= c and c =R= b
These relations are called the _Green_-_relations_ of the monoid +M+.

The relations =J= and =D= are the same for finite monoids, so we consider here only the relation =D=.

The equivalence classes of these relations are called _L_-_class_, _R_-_class_,_J_-_class_,_H_-_class_ and _D_-_class_.

A monoid is called _L_-_trivial_ iff all L-classes contains only one element. Analog for _R_,_J_,_H_,_D_-_trivial_.

===Disjunctive subsets and syntactic monoids.
A subset +D+ of a monoid +M+ is called a _disjunctive_ _subset_ iff for all <tt>a,b</tt> in +M+ with <tt>a != b</tt> a 'context' <tt>x,y</tt> in +M+ exists such that
 (xay in N and xby not in N) or vice versa

A monoid is called a _syntactic_ _monoid_ iff it has a disjunctive subset.

These definitions are motivated by the formal language theory in theoretical computer science. There one can define the _syntactic_ _monoid_ of a language as the factor monoid given by a congruence relation which depends on the language. It is shown that a monoid is syntactic in this sense iff it has a disjunctive subset.

Also it is shown that the syntactic monoid of a language is finite iff the language is regular.
=end

class RLSM::Monoid
=begin rdoc
The new method takes two parameters: the binary_operation and an (more or less) optional options hash.

The +binary_operation+ parameter should be either an array or a string.
If it is an array it must satisfy the following conditions:

* It is a two dimensional array and the rows are also arrays.
* It is quadratic.
* Each entry is an element of the monoid
* The first row and column belongs to the neutral element

If +binary_operation+ is a string, it must be of the form

 1abc aabc babc cabc

Such a string will be transformed in a 2D-array in the following way:
1. Each row is seperated by a space
2. In a row elements are seperated by ',' (comma) or each element consists of exactly one character (as in the above example)

The above example will be transformed to
 [['1','a','b','c'],['a','a','b','c'],['b','a','b','c'],['c','a','b','c']]
After the transformation, the same rules as for an array parameter applies.

Remark: The elements will always converted to a string, even if given an array with only numeric values. So multiplication will always be performed on strings.

The optional options hash knows the following keys.
[<tt>:elements</tt>] Takes an array as value and calls elements= with this array after the construction is complete.
[<tt>:normalize</tt>] If given non-nil and non-false value, the normalize method will be called after construction.
[<tt>:rename</tt>]If given non-nil and non-false value, the rename_elements method will be called after construction.

Other keys will be ignored and the order in which the methods will be called is
 normalize rename elements
=end
  def initialize(binary_operation, options = {})
    @binary_operation = get_binary_operation_from binary_operation
    @elements = @binary_operation.first.uniq unless @binary_operation.empty?
    @order = @binary_operation.size

    validate

    normalize if options[:normalize]
    rename_elements if options[:rename]
    self.elements = options[:elements] if options[:elements]
  end

  attr_reader :binary_operation, :elements, :order

=begin rdoc
Returns the product of the given elements. Raises a MonoidException if one of the arguments isn't a monoid element.
=end
  def [](*args)
    args.flatten!
    check_args(args)

    if args.size == 2
      x,y = args[0], args[1]
      return @binary_operation[@elements.index(x)][@elements.index(y)]
    else
      args[0,2] = self[args[0,2]]
      return self[*args]
    end
  end

=begin rdoc
Checks if this monoid is isomorph to +other+, if so returns true.
=end
  def isomorph_to?(other)
    #First a trivial check
    return false if @order != other.order

    #Search now an isomorphism
    iso = @elements.permutations.find do |p|
      @elements.product(@elements).all? do |x,y|
        px, py = other.elements[p.index(x)], other.elements[p.index(y)]

        other.elements[p.index(self[x,y])] == other[px,py]
      end
    end

    #Did we found an isomorphism?
    !iso.nil?
  end

=begin rdoc
Checks if this monoid is anti-isomorph to  +other+, if so returns true.
=end
  def anti_isomorph_to?(other)
    transposed = (0...@order).map do |i|
      @binary_operation.map { |row| row[i].clone }
    end

    RLSM::Monoid.new(transposed).isomorph_to?(other)
  end

=begin rdoc
Checks if the monoid is equal to +other+, i.e. the identity map is an isomorphism.
=end
  def ==(other)
    return false unless @elements == other.elements
    return false unless @binary_operation == other.binary_operation

    true
  end

=begin rdoc
Checks if the monoid is commutative, if so returns true.
=end
  def commutative?
    @elements.product(@elements).all? { |x,y| self[x,y] == self[y,x] }
  end

=begin rdoc
Returns the submonoid which is generated by the given elements. If one of the given  elements isn't a monoid element, an MonoidException is raised.
=end
  def get_submonoid(*args)
    element_indices = get_closure_of(args).map { |x| @elements.index(x) }

    RLSM::Monoid.new(@binary_operation.values_at(*element_indices).
                     map { |r| r.values_at *element_indices } )
  end

=begin rdoc
Returns an array of all submonoids of this monoid. The array is sorted in lexicographical order of the submonoid elements.
=end
  def submonoids
    @elements.powerset.map { |s| get_closure_of(s) }.uniq.sort_lex.map do |s|
      get_submonoid(s)
    end
  end

=begin rdoc
Returns an array of all proper submonoids of this monoid. The array is sorted in lexicographical order of the submonoid elements.
=end
  def proper_submonoids
    submonoids.reject { |m| [1,@order].include? m.order }
  end

=begin rdoc
Returns true if this monoid is a submonoid of +other+.
=end
  def submonoid_of?(other)
    other.submonoids.include? self
  end

  #A synonym for submonoid_of?
  def <=(other)
    submonoid_of?(other)
  end

=begin rdoc
Returns true if this monoid is a proper submonoid of +other+.
=end
  def proper_submonoid_of?(other)
    other.proper_submonoids.include? self
  end

  #A synonym for proper_submonoid_of?
  def <(other)
    proper_submonoid_of?(other)
  end

=begin rdoc
Returns true if this monoid has +other+ as a submonoid
=end
  def has_as_submonoid?(other)
    other.submonoid_of?(self)
  end

  #A synonym for has_as_submonoid?
  def >=(other)
    has_as_submonoid?(other)
  end

=begin rdoc
Returns true if this monoid has +other+ as a proper submonoid
=end
  def has_as_proper_submonoid?(other)
    other.proper_submonoid_of?(self)
  end

  #A synonym for has_as_proper_submonoid?
  def >(other)
    has_as_proper_submonoid?(other)
  end

=begin rdoc
Returns the lexicographical smallest subset which generates the monoid
=end
  def generating_subset
    @elements.powerset.find { |s| get_closure_of(s).size == @order }
  end

=begin rdoc
Returns the right ideal of the given element. Raises a MonoidException if the given element isn't in the monoid.
=end
  def right_ideal_of(element)
    check_args(element)

    @binary_operation[@elements.index(element)].uniq.sort
  end

=begin rdoc
Returns the left ideal of the given element. Raises a MonoidException if the given element isn't in the monoid.
=end
  def left_ideal_of(element)
    check_args(element)

    i = @elements.index(element)
    @binary_operation.map { |row| row[i] }.uniq.sort
  end

=begin rdoc
Returns the (two-sided) ideal of the given element. Raises a MonoidException if the given element isn't in the monoid.
=end
  def ideal_of(element)
    @elements.product(@elements).inject([]) do |res,xy|
      x,y = xy.first, xy.last
      res << self[x,element,y] unless res.include? self[x,element,y]
      res.sort
    end
  end

=begin rdoc
Returns the L-class of the given element. Raises a MonoidException if the given element isn't a monoid element.
=end
  def l_class_of(element)
    l = left_ideal_of(element)
    @elements.select { |x| left_ideal_of(x) == l }
  end

=begin rdoc
Returns all different L-classes of the monoid ordered by the lexicographical smallest element of each class
=end
  def l_classes
    @elements.map { |x| l_class_of(x) }.uniq
  end

=begin rdoc
Returns true if the monoid is L-trivial.
=end
  def l_trivial?
    l_classes.all? { |l| l.size == 1 }
  end

=begin rdoc
Returns the R-class of the given element. Raises a MonoidException if the given element isn't a monoid element.
=end
  def r_class_of(element)
    r = right_ideal_of(element)
    @elements.select { |x| right_ideal_of(x) == r }
  end
=begin rdoc
Returns all different R-classes of the monoid ordered by the lexicographical smallest element of each class
=end
  def r_classes
    @elements.map { |x| r_class_of(x) }.uniq
  end

=begin rdoc
Returns true if the monoid is R-trivial.
=end
  def r_trivial?
    r_classes.all? { |r| r.size == 1 }
  end

=begin rdoc
Returns the H-class of the given element. Raises a MonoidException if the given element isn't a monoid element.
=end
  def h_class_of(element)
    l_class_of(element) & r_class_of(element)
  end

=begin rdoc
Returns all different H-classes of the monoid ordered by the lexicographical smallest element of each class
=end
  def h_classes
    @elements.map { |x| h_class_of(x) }.uniq
  end

=begin rdoc
Returns true if the monoid is H-trivial.
=end
  def h_trivial?
    h_classes.all? { |h| h.size == 1 }
  end

=begin rdoc
Returns the D-class of the given element. Raises a MonoidException if the given element isn't a monoid element.
=end
  def d_class_of(element)
    d = ideal_of(element)
    @elements.select { |x| ideal_of(x) == d }
  end

=begin rdoc
Returns all different D-classes of the monoid ordered by the lexicographical smallest element of each class
=end
  def d_classes
    @elements.map { |x| d_class_of(x) }.uniq
  end

=begin rdoc
Returns true if the monoid is D-trivial.
=end
  def d_trivial?
    d_classes.all? { |d| d.size == 1 }
  end

  #Synonym for d_class_of (in a finite monoid =D= is the same as =J=)
  def j_class_of(element)
    d_class_of(element)
  end

  #Synonym for d_classes (in a finite monoid =D= is the same as =J=)
  def j_classes
    d_classes
  end

  #Synonym for d_trivial? (in a finite monoid =D= is the same as =J=)
  def j_trivial?
    d_trivial?
  end

=begin rdoc
Returns true if the given element is idempotent.
=end
  def idempotent?(x = nil)
    x ? x == self[x,x] : @elements.all? { |x| idempotent?(x) }
  end

=begin rdoc
Returns all idempotent elements of the monoid.
=end
  def idempotents
    @elements.select { |x| idempotent?(x) }
  end

=begin rdoc
Returns true if the monoid is also a group.
=end
  def group?
    idempotents.size == 1
  end

=begin rdoc
Returns true if the given element is a left zero. Raises a MonoidException if the given element isn't a monoid element.
=end
  def left_zero?(element)
    return false if @order == 1
    @elements.all? { |x| self[element,x] == element }
  end

=begin rdoc
Returns all left zeros of the monoid.
=end
  def left_zeros
    @elements.select { |x| left_zero?(x) }
  end

=begin rdoc
Returns true if the given element is a right zero. Raises a MonoidException if the given element isn't a monoid element.
=end
  def right_zero?(element)
    return false if @order == 1
    @elements.all? { |x| self[x,element] == element }
  end

=begin rdoc
Returns all right zeros of the monoid.
=end
  def right_zeros
    @elements.select { |x| right_zero?(x) }
  end

=begin rdoc
Returns the neutral element.
=end
  def neutral_element
    @elements.first.dup
  end

=begin rdoc
Returns the zero element if it exists, nil otherwise.
=end
  def zero_element
    @elements.find { |x| left_zero?(x) and right_zero?(x) }
  end


=begin rdoc
Returns true if the given set (as an array) is disjunctive.
=end
  def subset_disjunctive?(set)
    check_args(set)

    tup = @elements.product(@elements)

    tup.all? do |a,b|
      a == b or tup.any? do |x,y|
        set.include?(self[x,a,y]) ^ set.include?(self[x,b,y])
      end
    end
  end

=begin rdoc
Returns the lexicographical smallest subset which is disjunctive.
=end
  def disjunctive_subset
    @elements.powerset.find { |s| subset_disjunctive? s }
  end

=begin rdoc
Returns all disjunctive subsets of the monoid in lexicographical order.
=end
  def all_disjunctive_subsets
    @elements.powerset.select { |s| subset_disjunctive? s }
  end

=begin rdoc
Returns true if the monoid is syntactic.
=end
  def syntactic?
    !disjunctive_subset.nil?
  end

=begin rdoc
Returns true if the monoid is aperiodic. (A synonym for h_trivial?)
=end
  def aperiodic?
    h_trivial?
  end

  def to_s # :nodoc:
    sep = ''
    sep = ',' if @elements.any? { |x| x.length > 1 }
    @binary_operation.map { |row| row.join(sep) }.join(' ')
  end

  def inspect # :nodoc:
    "<#{self.class}: #{to_s}>"
  end

=begin rdoc
Arranges the elements in such a way that the generators follows directly the  neutral element.
=end
  def normalize
    #new element order
    elements =
      [@elements.first] +
      generating_subset +
      (@elements[(1..-1)] - generating_subset)

    indices = elements.map { |x| @elements.index(x) }

    #Adjust the binaray operation
    @binary_operation = @binary_operation.values_at(*indices).map do |row|
      row.values_at(*indices)
    end

    #Adjust the elements
    @elements = elements

    self
  end

=begin rdoc
Renames the elements to 1,a,b,c,d,e,... (see also elements=). It may be a little bit confusing if the monoid has more than 27 elements, because then the 28th element is named 'aa' which should not confused with the product in the monoid.
=end
  def rename_elements
    #Create the new elements
    eles = ['1']
    if @order > 1
      eles << 'a'
      eles << eles.last.succ while eles.size < @order
    end

    self.elements = eles
    self
  end

=begin rdoc
Renames the elements to the given array. Each array entry will be converted to a string.

A MonoidException will be raised if
* the given array has the wrong size
* the given array has duplicated elements (e.g. ['a','b','a'])
=end
  def elements=(els)
    els.map! { |x| x.to_s }

    if els.size != @order
      raise MonoidException, "Wrong number of elements given!"
    elsif els.uniq!
      raise MonoidException, "Given elements aren't unique!"
    end



    @binary_operation.map! do |row|
      row.map { |x| els[@elements.index(x)] }
    end

    @elements = els
  end
=begin rdoc
Returns a DFA which has the elements as states, the binary operation as transitions and the neutral element as initial state.

As optional parameter one may pass an array of elements which should become the final states. If the monoid is syntactic, these finals must be a disjunctive subset.

Also if the monoid is syntactic the set returned by disjunctive subset will be used as the finals as default.
=end
  def to_dfa(finals = [])
    check_args *finals
    if generating_subset == []
      return RLSM::DFA.new(:alphabet => [], :states => @elements,
                           :initial => neutral_element,
                           :finals => finals, :transitions => [])
    end

    if syntactic?
      if finals.empty?
        finals = disjunctive_subset
      else
        unless all_disjunctive_subsets.include? finals.sort
          raise MonoidException, "Given finals aren't a disjunctive subset."
        end
      end
    end

    RLSM::DFA.create(:initial => neutral_element,
                     :finals => finals,
                     :transitions => get_transitions)
  end

  private
  def get_transitions
    trans = []
    generating_subset.each do |l|
      @elements.each do |s|
        trans << [l,s,self[s,l]]
      end
    end
    trans
  end

  def check_args(*args)
    args.flatten!
    bad = args.find_all { |x| !@elements.include? x }

    if bad.size == 1
      raise MonoidException, "Bad argument: #{bad[0]}"
    elsif bad.size > 1
      raise MonoidException, "Bad arguments: #{bad.join(',')}"
    end
  end

  def get_closure_of(*args)
    args.flatten!
    check_args(args)

    #Add the neutral element if necassary
    args.unshift @elements.first unless args.include? @elements.first

    searching = true
    while searching
      searching = false

      args.product(args).each do |x,y|
        unless args.include? self[x,y]
          args << self[x,y]
          searching = true
        end
      end
    end

    args.sort { |x,y| @elements.index(x) <=> @elements.index(y) }
  end

  def get_binary_operation_from(bo)
    if bo.class == String
      return from_string_to_array(bo)
    else
      begin
        return bo.map { |r| r.map { |x| x.to_s } }
      rescue
        raise MonoidException, "Something went wrong."
      end
    end
  end

  def from_string_to_array(bo)
    #Reduce multiple spaces and spaces before or after commas
    bo.squeeze!(' ')
    bo.gsub!(', ', ',')
    bo.gsub!(' ,', ',')

    bo.split.map { |row| split_rows(row) }
  end

  def split_rows(r)
    if r.include? ','
      return r.split(',')
    else
      return r.scan(/./)
    end
  end

  def validate
    validate_form_of_binary_operation
    validate_elements
    validate_neutral_element
    validate_associativity
  end

  def validate_form_of_binary_operation
    if @binary_operation.empty?
      raise(MonoidException,
            "No binary operation given!")
    end

    unless @binary_operation.all? { |r| r.size == @binary_operation.size }
      raise(MonoidException,
            "A binary operation must be quadratic!")
    end
  end

  def validate_elements
    #Have we enough elements
    unless @elements.size == @order
      raise(MonoidException,
            "Expected #@order elements, but got #{@elements.join(',')}")
    end

    #All elements of the table are known?
    unless @binary_operation.flatten.all? { |x| @elements.include? x }
      raise(MonoidException,
            "There are too many elements in the binary operation.")
    end
  end

  def validate_neutral_element
    #By convention 0 is the index of the neutral element, check this
    unless @elements.all? do |x|
        @binary_operation[0][@elements.index(x)] == x and
          @binary_operation[@elements.index(x)][0] == x
      end
      raise(MonoidException,
            "Convention violated. #{@elements.first} is not a neutral element.")
    end
  end

  def validate_associativity
    #Search for a triple which violates the associativity
    nat = @elements.product(@elements,@elements).find do |triple|
      x,y,z = triple.map { |a| @elements.index(a) }
      @binary_operation[x][@elements.index(@binary_operation[y][z])] !=
        @binary_operation[@elements.index(@binary_operation[x][y])][z]
    end

    #Found one?
    if nat
      err_str = "#{nat[0]}(#{nat[1]}#{nat[2]}) != (#{nat[0]}#{nat[1]})#{nat[2]}"
      raise(MonoidException,
            "Given binary operation is not associative: #{err_str}")
    end
  end
end
