require File.expand_path(File.join(File.dirname(__FILE__), 'rlsm'))

require "rubygems"
require "sqlite3"

class RLSM::MonoidDB
  @@db = SQLite3::Database.open(File.join(File.dirname(__FILE__), '..',
                                          'data', 'monoids.db'))

  Columns = [:binop, :m_order, :num_generators,
             :num_idempotents, :num_left_nulls, :num_right_nulls,
             :syntactic, :idempotent, :aperiodic,
             :commutative, :is_group, :has_null,
             :l_trivial, :r_trivial, :d_trivial]

  def self.query(query, &block)
    if block_given?
      @@db.execute(query, &block)
    else
      @@db.execute(query)
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
    res = @@db.execute2 <<SQL
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

    where = Columns.inject([]) do |res,col|
      if params[col]
        if [:binop, :m_order].include?(col) or col.to_s =~ /^num_/
          res << "#{col.to_s} = #{params[col]}"
        else
          res << "#{col.to_s} = 1"
        end
      end

      res
    end.join(" AND ")

    if where.length > 0
      q += "\nWHERE " + where
    end

    q + order_by + limit + ";"
  end
end
