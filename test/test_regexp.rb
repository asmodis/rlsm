require File.join(File.dirname(__FILE__), 'helpers')

require "rlsm/regexp"

context "Parsing of a regexp:" do
  before :each do
    @a = RLSM::RE::Prim[ 'a' ]
    @b = RLSM::RE::Prim[ 'b' ]
    @c = RLSM::RE::Prim[ 'c' ]
    @d = RLSM::RE::Prim[ 'd' ]

    @aab = [@a, @a, @b] 
  end

  test "RegExp::new : Should require an argument." do
    assert_raises ArgumentError do
      RLSM::RegExp.new
    end
  end

  test "RegExp::new : Should check that parentheses are balanced." do
    assert_raises RLSM::Error do
      RLSM::RegExp.new "(ab(cUd)"
    end

    assert_raises RLSM::Error do
      RLSM::RegExp.new "ab)((cUd)"
    end
  end

  test "RegExp::new : Should parse empty string." do
    re = RLSM::RegExp.new ""

    assert_equal( RLSM::RE::EmptySet[], re.parse_tree )
  end

  test "RegExp::new : Should parse string with only parenthesis." do
    re = RLSM::RegExp.new "()(())"

    assert_equal( RLSM::RE::EmptySet[], re.parse_tree )
  end

  test "RegExp::new : Should parse string with only parenthesis and stars." do
    re = RLSM::RegExp.new "()*((*))"

    assert_equal( RLSM::RE::EmptySet[], re.parse_tree )
  end

  test "RegExp::new : Should parse empty word." do
    re = RLSM::RegExp.new "@"

    assert_equal( RLSM::RE::EmptyWord[], re.parse_tree )
  end

  test "RegExp::new : Should parse a single character." do
    re = RLSM::RegExp.new "a"

    assert_equal( RLSM::RE::Prim['a'], re.parse_tree )
  end

  test "RegExp::new : Should parse multiple characters." do
    re = RLSM::RegExp.new "aab"

    assert_equal( RLSM::RE::Concat[ @aab ], re.parse_tree )
  end

  test "RegExp::new : Should ignore surrounding parenthesis." do
    re = RLSM::RegExp.new "(((aab)))"

    assert_equal( RLSM::RE::Concat[ @aab ],
                  re.parse_tree )
  end

  test "RegExp::new : Should parse a trivial regexp with a kleene star." do
    re = RLSM::RegExp.new "a*"
    expected = 

    assert_equal( RLSM::RE::Star[ RLSM::RE::Prim['a'] ], re.parse_tree )
  end

  test "RegExp::new : Should parse a simple regexp with a kleene star." do
    re = RLSM::RegExp.new "(aab)*"

    assert_equal( RLSM::RE::Star[ RLSM::RE::Concat[ @aab ] ], re.parse_tree )
  end

  test "RegExp::new : Should simplify multiple stars." do
    re = RLSM::RegExp.new "a***"

    assert_equal( RLSM::RE::Star[ RLSM::RE::Prim['a'] ],
                  re.parse_tree )
  end

  test "RegExp::new : Should simplify multiple empty words." do
    re = RLSM::RegExp.new "@@@"

    assert_equal( RLSM::RE::EmptyWord[],
                  re.parse_tree )
  end

  test "RegExp::new : Should simplify stars after empty words." do
    re = RLSM::RegExp.new "@*"

    assert_equal( RLSM::RE::EmptyWord.new,
                  re.parse_tree )
  end
  
  test "RegExp::new : Should simplify empty words in a simple expression." do
    re = RLSM::RegExp.new "@aa@b@"

    assert_equal( RLSM::RE::Concat[ @aab ],
                  re.parse_tree )
  end

  test "RegExp::new : Should parse a simple union." do
    re = RLSM::RegExp.new "aab|b|ac"
    expected = RLSM::RE::Union[ [RLSM::RE::Concat[ @aab ], 
                                 RLSM::RE::Concat[ [@a,@c] ],
                                 @b] ]

    assert_equal( expected, re.parse_tree )
  end

  test "RegExp::new : Should ignore obviously unnedded parenthesis." do
    re = RLSM::RegExp.new "(@)aa(b)"

    assert_equal( RLSM::RE::Concat[ @aab ],
                  re.parse_tree )
  end

  test "RegExp::new : Should parse a concatenation with a kleene star." do
    re = RLSM::RegExp.new "aba*"
    expected = RLSM::RE::Concat[ [@a, @b, RLSM::RE::Star[ @a ]] ]
    assert_equal( expected, re.parse_tree )
  end

  test "RegExp::new : Should parse a union in a star expression." do
    re = RLSM::RegExp.new "(a|b)*"
    expected = RLSM::RE::Star[ RLSM::RE::Union[ [@a, @b] ] ]
    assert_equal( expected, re.parse_tree )
  end

  test "RegExp::new : Should parse a union in a concat expression." do
    re = RLSM::RegExp.new "ab(a|b)b"
    expected = RLSM::RE::Concat[ [@a, @b, RLSM::RE::Union[ [@a,@b] ], @b] ]

    assert_equal( expected, re.parse_tree )
  end

  test "RegExp::new : Should parse a complexer union." do
    re = RLSM::RegExp.new "a*|aab|ba(aab)*bb"
    concat = RLSM::RE::Concat[ [@b,@a, RLSM::RE::Star[ RLSM::RE::Concat[@aab] ], @b, @b] ]
    expected = RLSM::RE::Union[ [RLSM::RE::Star[@a], RLSM::RE::Concat[@aab], concat] ]

    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should parse a nested union." do
    re = RLSM::RegExp.new "a(a|b)|a*"
    expected = 
      RLSM::RE::Union[ [RLSM::RE::Concat[[@a, RLSM::RE::Union[[@a,@b]]]], RLSM::RE::Star[@a]] ]

    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should treat empty parenthesis as empty set." do
    re1 = RLSM::RegExp.new "()*"
    re2 = RLSM::RegExp.new "ab()"

    assert_equal RLSM::RE::EmptySet[], re1.parse_tree
    assert_equal RLSM::RE::EmptySet[], re2.parse_tree
  end

  test "RegExp::new : Should ignore union with an empty set." do
    re = RLSM::RegExp.new "a||b"
    
    expected = RLSM::RE::Union[ [ RLSM::RE::Prim[ 'a' ], RLSM::RE::Prim[ 'b' ] ] ]

    assert_equal expected, re.parse_tree
  end
end

context "Properties of a SyntaxNode:" do
  test "SyntaxNode#null? : Should return true for EmptySet." do
    assert RLSM::RE::EmptySet[].null?
  end

  test "SyntaxNode#null? : Should return true for EmptyWord." do
    assert RLSM::RE::EmptyWord[].null?
  end

  test "SyntaxNode#null? : Should return false for Prim." do
    refute RLSM::RE::Prim[ 'a' ].null?
  end

  test "SyntaxNode#null? : Should return true for a Star." do
    assert RLSM::RE::Star[ RLSM::RE::Prim[ 'a' ] ].null?
  end

  test "SyntaxNode#null? : Should return true for a union with at least one nullable entry." do
    parse_tree = RLSM::RE::Union[ [RLSM::RE::Prim[ 'a' ], RLSM::RE::EmptyWord[]] ]
    assert parse_tree.null?
  end

  test "SyntaxNode#null? : Should return false for a union with no nullable entries." do
    parse_tree = RLSM::RE::Union[ [RLSM::RE::Prim[ 'a' ], RLSM::RE::Prim[ 'b' ]] ]
    refute parse_tree.null?
  end

  test "SyntaxNode#null? : Should return false for a concat with at least one non null entry." do
    parse_tree = RLSM::RE::Concat[ [RLSM::RE::Star[ RLSM::RE::Prim[ 'a' ] ], RLSM::RE::Prim[ 'b' ]] ]
    refute parse_tree.null?
  end

  test "SyntaxNode#null? : Should return true for a concat with only nullable entries." do
    parse_tree = RLSM::RE::Concat[ [RLSM::RE::Star[RLSM::RE::Prim[ 'a' ]],RLSM::RE::Star[RLSM::RE::Prim[ 'b' ]]] ]
    assert parse_tree.null?
  end

  test "SyntaxNode#first : Should return empty Array for EmptySet." do
    assert_equal [], RLSM::RE::EmptySet[].first
  end

  test "SyntaxNode#first : Should return empty Array for EmptyWord." do
    assert_equal [], RLSM::RE::EmptyWord[].first
  end

  test "SyntaxNode#first : Should return first character of a Prim in an Array." do
    assert_equal ['a'], RLSM::RE::Prim[ 'a' ].first
    assert_equal ['b'], RLSM::RE::Prim[ 'b' ].first
  end

  test "SyntaxNode#first : Should return first of the content of a star." do
    assert_equal ['a'], RLSM::RE::Star[ RLSM::RE::Prim[ 'a' ] ].first
  end

  test "SyntaxNode#first : Should return union of first for all factors of a union." do
    parse_tree = RLSM::RE::Union[ [RLSM::RE::Prim[ 'c' ], RLSM::RE::Prim[ 'b' ]] ]

    assert_equal ['b','c'], parse_tree.first
  end

  test "SyntaxNode#first : Should return union of first upto first nonnull entry in concat." do
    parse_tree1 = RLSM::RE::Concat[[RLSM::RE::Prim[ 'b' ],RLSM::RE::Prim[ 'a' ]] ]
    parse_tree2 = RLSM::RE::Concat[[RLSM::RE::Star[RLSM::RE::Prim['c']], RLSM::RE::Prim['b']]]

    assert_equal ['b'], parse_tree1.first
    assert_equal ['b','c'], parse_tree2.first
  end

  test "SyntaxNode#last : Should return empty Array for EmptySet." do
    assert_equal [], RLSM::RE::EmptySet[].last
  end

  test "SyntaxNode#last : Should return empty Array for EmptyWord." do
    assert_equal [], RLSM::RE::EmptyWord[].last
  end

  test "SyntaxNode#last : Should return last character of a Prim in an Array." do
    assert_equal ['f'], RLSM::RE::Prim[ 'f' ].last
    assert_equal ['b'], RLSM::RE::Prim[ 'b' ].last
  end

  test "SyntaxNode#last : Should return last of the content of a star." do
    assert_equal ['f'], RLSM::RE::Star[ RLSM::RE::Prim[ 'f' ] ].last
  end

  test "SyntaxNode#last : Should return union of last for all factors of a union." do
    parse_tree = RLSM::RE::Union[ [RLSM::RE::Prim[ 'd' ], RLSM::RE::Prim[ 'b' ]] ]

    assert_equal ['b','d'], parse_tree.last
  end

  test "SyntaxNode#last : Should return union of last upto first nonnull entry in concat." do
    parse_tree1 = RLSM::RE::Concat[ [RLSM::RE::Prim[ 'c' ], RLSM::RE::Prim[ 'b' ]] ]
    parse_tree2 = RLSM::RE::Concat[[RLSM::RE::Prim['c'], RLSM::RE::Star[ RLSM::RE::Prim['d']]]]

    assert_equal ['b'], parse_tree1.last
    assert_equal ['c','d'], parse_tree2.last
  end

  test "SyntaxNode#follow : Should return nil for EmptySet." do
    assert_equal nil, RLSM::RE::EmptySet[].follow
  end

  test "SyntaxNode#follow : Should return nil for EmptyWord." do
    assert_equal nil, RLSM::RE::EmptyWord[].follow
  end

  test "SyntaxNode#follow : Should return empty Array for a single letter expression." do
    assert_equal [], RLSM::RE::Prim[ 'a' ].follow
  end

  test "SyntaxNode#follow : Should return every length two substring for a star." do
    assert_equal [['a','a']], RLSM::RE::Star[ RLSM::RE::Prim[ 'a' ] ].follow
  end

  test "SyntaxNode#follow : Should return every length two substring for a union." do
    concat = RLSM::RE::Concat[ %w(c c d).map { |char| RLSM::RE::Prim[char] } ]
    parse_tree = RLSM::RE::Union[ [RLSM::RE::Star[ RLSM::RE::Prim[ 'a' ] ],
                                   RLSM::RE::Prim[ 'b' ],
                                   concat ] ]
    assert_equal [['a','a'], ['c','c'], ['c','d']], parse_tree.follow
  end

  test "SyntaxNode#follow : Should return every length two substring for a concat." do
    parse_tree = RLSM::RE::Concat[ [RLSM::RE::Star[ RLSM::RE::Prim[ 'a' ] ],
                                RLSM::RE::Prim[ 'b' ],
                                RLSM::RE::Union[ [RLSM::RE::Prim[ 'c' ], RLSM::RE::Prim[ 'd' ]] ] ] ]
    assert_equal [['a','a'], ['a','b'], ['b','c'], ['b','d']], parse_tree.follow
  end
end

context "Simplification of regexps:" do
  before :each do
    @a = RLSM::RE::Prim[ 'a' ]
    @b = RLSM::RE::Prim[ 'b' ]
    @c = RLSM::RE::Prim[ 'c' ]
    @d = RLSM::RE::Prim[ 'd' ]

    @aab = [@a, @a, @b] 
  end

  test "RegExp::new : Should simplify (@)* to @" do
    assert_equal RLSM::RE::EmptyWord[], RLSM::RegExp.new("(@)*").parse_tree
  end

  test "RegExp::new : Should ignore unneeded empty words in a union." do
    re = RLSM::RegExp.new "@|b|a*"
    
    expected = RLSM::RE::Union[ [ RLSM::RE::Star[ @a ], @b ] ]

    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should multiple empty words in a union reduce to one." do
    re = RLSM::RegExp.new "@|b|@"
    
    expected = RLSM::RE::Union[ [ RLSM::RE::EmptyWord[], @b ] ]

    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should simplify multiple identical entries in a union." do
    re = RLSM::RegExp.new "@|b|b"

    expected = RLSM::RE::Union[ [ RLSM::RE::EmptyWord[], @b ] ]

    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should simplify a empty word in a stared union." do
    re = RLSM::RegExp.new "(@|a|b)*"
    expected = RLSM::RE::Star[RLSM::RE::Union[ [@a, @b ] ]]
    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should simplify something like (a|a*|b) to (a*|b)" do
    re = RLSM::RegExp.new "(a|a*|b)"
    expected = RLSM::RE::Union[ [RLSM::RE::Star[@a], @b ] ]
    assert_equal expected, re.parse_tree
  end

  test "RegExp::new : Should simplify something like (a|a*)* to a*" do
    re = RLSM::RegExp.new "(a|a*)*"
    expected = RLSM::RE::Star[ @a ]
    assert_equal expected, re.parse_tree
  end

#   test "RegExp::new : Should simplify something like (aab|bab) to (a|b)ab." do
#     re = RLSM::RegExp.new "(aab|bab)"
#     expected = RLSM::RE::Concat[ [RLSM::RE::Union[ [@a,@b] ], @a, @b] ]
#     assert_equal expected, re.parse_tree
#   end
  
#   test "RegExp::new : Should simplify something like (abb|aba) to ab(a|b)."
end

context "Equality of regular expressions:" do
  test "RegExp#== : Should return true for identical string representations." do
    re1 = RLSM::RegExp.new "a(b)(a|b)"
    re2 = RLSM::RegExp.new "ab(a||b)"

    assert re1 == re2
  end

  test "RegExp#== : Should return false if first of two regexpes differs." do
    re1 = RLSM::RegExp.new "(a|b)a"
    re2 = RLSM::RegExp.new "(b|a)a"

    assert re1 == re2
    refute re1 == RLSM::RegExp.new("(b|a)b")
  end

  test "RegExp#== : Should return false if last of two regexpes differs." do
    re1 = RLSM::RegExp.new "a(a|b)"
    re2 = RLSM::RegExp.new "a(b|a)"

    assert re1 == re2
    refute re1 == RLSM::RegExp.new("a(b|c)")
  end

  test "RegExp#== : Should return true if two regexps only differs in order in a union." do
    re1 = RLSM::RegExp.new "a(a|b)a"
    re2 = RLSM::RegExp.new "a(b|a)a"

    assert re1 == re2
  end

  test "RegExp#== : Should return true if two regexps only differs in factorisation." do
    re1 = RLSM::RegExp.new "a(a|b)a"
    re2 = RLSM::RegExp.new "(aba|aaa)"
    re3 = RLSM::RegExp.new "aba"

    assert re1 == re2, "Oho?"
    refute re3 == re1, "Huh?"
  end
end

context "Calculation with regular expressions:" do
  test "RegExp::+ : Should concatenate two regexps." do
    re1 = RLSM::RegExp.new "ab(a|b)"
    re2 = RLSM::RegExp.new "ab"

    assert_equal RLSM::RegExp.new("ab(a|b)ab"), re1 + re2 
  end

  test "RegExp::| : Should unite two regexps." do
    re1 = RLSM::RegExp.new "ab(a|b)"
    re2 = RLSM::RegExp.new "ab"

    assert_equal RLSM::RegExp.new("ab(a|b)|ab"), re1 | re2 
  end

  test "RegExp::star : Should star a regexp." do
    re = RLSM::RegExp.new "ab(a|b)"

    assert_equal RLSM::RegExp.new("(ab(a|b))*"), re.star 
  end
end
