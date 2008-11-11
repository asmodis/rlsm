#category RLSM
=begin help
Returns monoids from the database.

Usage: db_find params
Here, params is a comma seperated list of property requests.
A property request has the form:
  col => val

 Known columns are:
 - :binop  -> the binary operation
 - :m_order -> the order of the monoid
 - :num_generators -> the size of the smallest generating subset
 - :num_idempotents -> the number of idempotent elements
 - :num_right_nulls -> the number of elements a with the property: xa = a for all x
 - :num_left_nulls -> the number of elements a with the property: ax = a for all x
 - :has_null -> 1 if the monoid has a null element, 0 otherwise 
 - :is_group -> 1 if the monoid is a group, 0 otherwise 
 - :syntactic -> 1 if the monoid is syntactic, 0 otherwise 
 - :commutative -> 1 if the monoid is commutative, 0 otherwise 
 - :idempotent -> 1 if the monoid is idempotent, 0 otherwise 
 - :aperiodic -> 1 if the monoid is aperiodic, 0 otherwise 
 - :l_trivial -> 1 if the monoid is L-trivial, 0 otherwise 
 - :r_trivial -> 1 if the monoid is R-trivial, 0 otherwise 
 - :d_trivial -> 1 if the monoid is D-trivial, 0 otherwise

The values are numbers except for the binop column.

Example:
db_find :m_order => 3
db_find :binop => '01 10'
db_find :syntactic  => 1, :idempotent => 0
=end

def db_find(params = {})
  RLSM::MonoidDB.find(params).flatten
end
