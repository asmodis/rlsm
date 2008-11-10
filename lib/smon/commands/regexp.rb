#category RLSM
=begin help
Creates a new Regular Expression.

Usage: regexp "desc"

+desc+ is here a description of the regexp.
A regexp may consist of
 - normal characters like a,b,c, 1,2, ... 
 - Special characters are
   - &   : the emmpty word
   - |   : Union
   - ( ) : Grouping of expressions
   - *   : Kleene star

=end

def regexp(desc)
  RLSM::RegExp.new desc
end
