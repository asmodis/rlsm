module RLSMArrayExt # :nodoc:
  #Returns all permutations of the array.
  def permutations
    return [self] if size < 2
    perm = []
    each { |e| (self - [e]).permutations.each { |p| perm << ([e] + p) } }
    perm
  end

  #Returns the powerset of the array (interpreted as set).
  def powerset
    ret = self.inject([[]]) do |acc, x|
      res = []
      acc.each { |s| res << s; res << ([x]+s).sort }
      res
    end

    ret.sort_lex
  end

  #Sorts an array of arrays more or less lexicographical.
  def sort_lex
    sort { |s1, s2| s1.size == s2.size ? s1 <=> s2 : s1.size <=> s2.size }
  end

  #Returns the cartesian product of self and the given arrays
  def product(*args)
    args.inject(self.map { |x| [x] }) do |res,arr|
      new = []
      arr.each do |x|
        new += res.map  { |tup| tup += [x] }
      end
      new
    end
  end

  #Returns all unordered pairs.
  def unordered_pairs
    pairs = []
    (0...size-1).each do |i|
      pairs |= self[i+1..-1].map { |x| [self[i],x] }
    end

    pairs
  end
end

class Array # :nodoc:
  include RLSMArrayExt
end
