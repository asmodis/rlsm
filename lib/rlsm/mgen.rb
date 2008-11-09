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

require File.join(File.dirname(__FILE__), 'monoid')

#Generates all monoids of a given order. May take some time if order is greater than 5.
module RLSM
  class MonoidGenerator

    #Iterates over all monoids of order n.
    def self.each(n=2)
      #The pathological cases...
      if n == 1
        yield Monoid.new('0')
        return
      elsif n == 2
        yield Monoid.new('01 10')
        yield Monoid.new('01 11')
        return
      end
      
      @@n = n-1
      @@t = ([0]*((n-1)*(n-1)))/(n-1)
      @@t = table_adjoin_one
      @@i, @@j = n-1, n-1
      
      @@end_reached = false
      yield Monoid.new(tab_to_str, :normalize => false) if restrictions_satisfied?
      succ

      while not @@end_reached
        yield Monoid.new(tab_to_str, :normalize => false)
        succ
      end
    end

    private
    def self.succ
      loop do
        @@t[@@i][@@j] += 1
        if @@t[@@i][@@j] > @@n
          @@t[@@i][@@j] = -1
          if @@i == 1 and @@j == 1
            @@end_reached = true
            break
          elsif @@j == 1
            @@j = @@n; @@i -= 1
          else
            @@j -= 1
          end
        else
          if restrictions_satisfied? and first?
            if @@i == @@n and @@j == @@n
              break
            elsif @@j == @@n
              @@j = 1; @@i += 1
            else
              @@j += 1
            end
          end
        end
      end
    end

    def self.first?
      (1..@@n).to_a.permutations.collect{|p| p.unshift 0}.all? do |p|
        #if a permutation changes some elements before the given position
        #and the replacement is undefined no answer can be given
        last = (@@i-1)*(@@n) + @@j -1
        
        index = (0..last).find do |ind|
          i,j = (ind / (@@n))+1, (ind % (@@n))+1
          bij = @@t[p.index(i)][p.index(j)]
          
          (bij == -1) or @@t[i][j] != p[bij]
        end
        
        if index
          i,j = (index / (@@n))+1, (index % (@@n))+1
          bij = @@t[p.index(i)][p.index(j)]
      
          (bij == -1) or (@@t[i][j] < p[@@t[p.index(i)][p.index(j)]])
        else
          true
        end
      end
    end

    def self.restrictions_satisfied?
      #Associativity
      return false unless (0..@@n).to_a.triples.all? do |a,b,c|
        if [@@t[a][b],
            @@t[b][c],
            @@t[a][@@t[b][c]],
            @@t[@@t[a][b]][c]].include? -1
          true
        else
          @@t[a][@@t[b][c]] == @@t[@@t[a][b]][c]
        end
      end

      true
    end

    def self.table_adjoin_one
      res = [(1..@@n).to_a] + @@t
      (0..@@n).to_a.zip(res).collect { |i,x| [i]+x }
    end

    def self.tab_to_str
      @@t.collect { |r| r.join(@@n >= 10 ? ',' : '') }.join(' ')
    end
  end
end
