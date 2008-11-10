#category RLSM

=begin help
Creates a monoid.

Usage: monoid desc or monoid(desc)

+desc+ is here the description of a binary operation. The form of the
description follows some simple rules:
 - A binary operation is represented as a quadratic matrix
 - Rows are seperated by ' ' (space)
 - Columns are seperated by ',' (comma)
   The comma may be omitted if every element descriptor is only one
   char.
 - The first row and column belongs to the neutral element.
 - The +desc+ parameter must be surrounded by " (double quote)

Examples:
 monoid "1a aa"
 monoid "1ab aab bab"
 monoid "1,a a,1"
=end

def monoid(desc)
  RLSM::Monoid.new desc
end
  
