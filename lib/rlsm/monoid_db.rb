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


require "rubygems"
require "sqlite3"
require "singleton"

module RLSM
  class MonoidDB

    Columns = [:binop, :m_order, :num_generators,
               :num_idempotents, :num_left_nulls, :num_right_nulls,
               :syntactic, :idempotent, :aperiodic,
               :commutative, :is_group, :has_null,
               :l_trivial, :r_trivial, :d_trivial]
    
    include Singleton

    attr_reader :db    

    def self.query(query, &block)
      if block_given?
        instance.db.execute(query, &block)
      else
        instance.db.execute(query)
      end
    end

    def self.find(params = {}, &block)
      if block_given?
        query construct_query(params), &block
      else
        query construct_query(params)
      end
    end

    def self.count(params = {})
      q = construct_query(params).sub('T binop F', 
                                      "T count(*), total(syntactic) F")
      query(q).first.map { |x| x.to_i }
    end
                                     
    def self.statistic
      res = instance.db.execute2 <<SQL
SELECT
m_order AS 'Order',
count(*) AS 'Total',
total(syntactic) AS 'Syntactic',
total(is_group) AS 'Groups',
total(commutative) AS 'Commutative',
total(aperiodic) AS 'Aperiodic',
total(idempotent) AS 'Idempotent'
FROM monoids
GROUP BY m_order
ORDER BY 'Order' ASC;
SQL

      desc  = res.shift
      res.map! { |row| row.map { |x| x.to_i } }
      res.unshift desc

      res
    end
    
    private
    def initialize
      db_name = File.join(File.dirname(__FILE__), 'data', 'monoids.db')
      @db = SQLite3::Database.open(db_name)
    end

    def self.construct_query(params)
      limit = ""
      if params[:limit]
        limit = "\nLIMIT #{params[:limit]}"
        params.delete :limit
        if params[:offset]
          limit += " OFFSET #{params[:offset]}"
        end
      end

      order_by = "\nORDER BY binop #{params[:ordering] || 'ASC'}"

      params.delete :ordering

      q = "SELECT binop FROM monoids"

      where = Columns.map do |col|
        params[col] ? (col.to_s + " = " + params[col]) : nil
      end.compact.join(" AND ")

      if where.length > 0
        q += "\nWHERE " + where
      end
      
      q + order_by + limit + ";"
    end
  end
end
