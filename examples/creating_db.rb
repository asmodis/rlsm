#-*- ruby -*-

require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')
require "rubygems"
require "sqlite3"

$db = SQLite3::Database.new("monoids.db")

$db.execute <<SQL
create table if not exists monoids (
  binop            TEXT,
  ord              INTEGER,
  num_gen          INTEGER,
  num_left_zeros   INTEGER,
  num_right_zeros  INTEGER,
  num_idempotents  INTEGER,
  has_zero         INTEGER,
  is_syntactic     INTEGER,
  is_commutative   INTEGER,
  is_idempotent    INTEGER,
  is_aperiodic     INTEGER,
  is_l_trivial     INTEGER,
  is_r_trivial     INTEGER,
  is_j_trivial     INTEGER,
  is_group         INTEGER
);
SQL

def monoid2sql(monoid)
  translate = { true => '1', false => '0' }
  sql = "insert into monoids values ("
  sql += "'#{monoid.to_s.chop}', "
  sql += "'#{monoid.order}', "
  sql += "'#{monoid.generating_subset.size.to_s}', "
  sql += "'#{monoid.left_zeros.size.to_s}', "
  sql += "'#{monoid.right_zeros.size.to_s}', "
  sql += "'#{monoid.idempotents.size.to_s}', "
  sql += "'#{translate[monoid.zero?]}', "
  sql += "'#{translate[monoid.syntactic?]}', "
  sql += "'#{translate[monoid.commutative?]}', "
  sql += "'#{translate[monoid.idempotent?]}', "
  sql += "'#{translate[monoid.aperiodic?]}', "
  sql += "'#{translate[monoid.l_trivial?]}', "
  sql += "'#{translate[monoid.r_trivial?]}', "
  sql += "'#{translate[monoid.j_trivial?]}', "
  sql + "'#{translate[monoid.group?]}');"
end

7.times do |i|
  RLSM::Monoid.each(i+1) { |mon| $db.execute monoid2sql(mon) }
end

