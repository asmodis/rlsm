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


class Object
  #Makes a deep copy. Usful for cloning complexer classes.
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end


class Array
  def tuples
    res = []
    self.each { |a| self.each { |b| res << [a,b] } }

    res
  end

  def triples
    res = []
    tuples.each { |a,b| self.each { |c| res << [a,b,c] } }

    res
  end

  #Only syntactic sugar. Adds an element unless the element is already in the array.
  def add?(x)
    if x
      unless include? x
        push(x).sort
      end
    end

    self
  end

  #Returns the powerset of the array (interpreted as set).
  def powerset
    ret = self.inject([[]]) do |acc, x|
      res = []
      acc.each { |s| res << s; res << ([x]+s).sort }
      res
    end

    ret.sort do |s1,s2|
      if s1.size == s2.size
        s1 <=> s2
      else
        s1.size <=> s2.size
      end
    end
  end

  #Returns all proper subsets of the array (the array interpreted as a set).
  def proper_subsets
    powerset.select { |s| s.size > 0 and s.size < size }
  end

  #Returns all permutations of the array.
  def permutations
    return [self] if size < 2
    perm = []
    each { |e| (self - [e]).permutations.each { |p| perm << ([e] + p) } }
    perm
  end

  #Returns the Array divided into subarrays each of length +l+. If The size of the array isn't even divisible by +l+, then the last subarray isn't of size +l+.
  def /(l)
    res = []
    
    each_with_index do |x,i|
      res << [] if i % l == 0
      res.last << x
    end

    res
  end

  #This is some hack, that in my regexp code, it works for both Strings and Arrays...
  def each_char(&block)
    each &block
  end
end

class String
  #Iterates over every character in a string. (Compatibility with 1.9 and convinience)
  def each_char
    if block_given?
      scan(/./m) { |c| yield c }
    else
      scan(/./m)
    end
  end

  #This is some hack, that in my regexp code, it works for both Strings and Arrays...
  def reject(&block)
    tmp = scan(/./m).reject &block
    tmp.join
  end
end
