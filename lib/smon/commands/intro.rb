#category help
=begin help
Displays a small introduction.

Usage: intro

Shows some of the rules for work with the program.
=end

def intro
  puts <<INTRO
======================
 INTRODUCTION TO SMON
======================

==Basic rules
 - Every input, which should be interpreted literally 
   must be surrounded by quotes or double quotes.

 - Parenthesis for commands may be omitted in the most cases. 
   When in doubt, write the parenthesis.

 - Basicly, every valid Ruby command is allowed.

==Basic Usage
 - Type < help > for an overview of availible commands.

 - If you wanna use variables, just type < @var = ... >.
   The @-sign is important!

INTRO
end
