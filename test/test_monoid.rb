require File.join(File.dirname(__FILE__), 'helpers')

require "rlsm/monoid"

#Create one nontrivial monoid (Transposed transition monoid of {1,2,3})
#Make it global for speed reasons
$monoid = RLSM::Monoid[ <<MONOID
1abcdefghijklmnopqrstuvwxyz
aaaaaaaaaaaaaaaaaaaaaaaaaaa
baabaaddeaabaabddeiijiijllm
caacaaffhaacaacffhrrtrrtxxz
dabadeabaijilmlijiabadedaba
eabbdedeeijjlmmlmmijjlmmlmm
facafhacartrxzxrtracafhfaca
gacbfhd1ertsxzyuwvikjoqplnm
haccfhfhhrttxzzxzzrttxzzxzz
imlljijiieddbaabaaeddbaabaa
jmlmjimlmedebabedemlmjijmlm
kmlnjipoqed1bacgfhvuwsrtyxz 
lmmlmmjjimmlmmljjieedeedbba
mmmmmmmmmmmmmmmmmmmmmmmmmmm
nmmnmmppqmmnmmnppqvvwvvwyyz
omnlpqjkivwuyzxstre1dghfbca
pmnmpqmnmvwvyzyvwvmnmpqpmnm
qmnnpqpqqvwwyzzyzzvwwyzzyzz
rzxxtrtrrhffcaacaahffcaacaa
szxytrwuvhfgcab1deqopkijnlm
tzxztrzxzhfhcachfhzxztrtzxz
uzyxwvtsrqponmlkjihgf1edcba
vzyywvwvvqppnmmnmmqppnmmnmm
wzyzwvzyzqpqnmnqpqzyzwvwzyz
xzzxzzttrzzxzzxttrhhfhhfcca
yzzyzzwwvzzyzzywwvqqpqqpnnm
zzzzzzzzzzzzzzzzzzzzzzzzzzz
MONOID
]

context "Creation of a monoid:" do
  test "Monoid::new : Should accept a valid description." do
    assert_nothing_raised do
      RLSM::Monoid[ "012 120 201" ]
    end
  end

  test "Monoid::new : Should require a description." do
    assert_raises ArgumentError do
      RLSM::Monoid[]
    end
  end

  test "Monoid::new : Should reject an empty description." do
    assert_raises RLSMError do
      RLSM::Monoid[ "" ]
    end
  end

  test "Monoid::new : Should reject a description with only whitespaces." do
    assert_raises RLSMError do
      RLSM::Monoid[ " \t\n" ]
    end
  end
  
  test "Monoid::new : Description should describe a quadratic matrix." do
    assert_raises RLSMError do
      RLSM::Monoid[ "012 120 20" ]
    end
  end

  test "Monoid::new : Described n x n - matrix should contain n symbols." do
    assert_raises RLSMError do
      RLSM::Monoid[ "123 456 789" ]
    end

    assert_raises RLSMError do
      RLSM::Monoid[ "000 000 000" ]
    end
  end

  test "Monoid::new : Identity should be first row and column." do
    assert_raises RLSMError do
      RLSM::Monoid[ "00 01" ]
    end
  end

  test "Monoid::new : Described monoid should be associative." do
    assert_raises RLSMError do
      RLSM::Monoid[ "012 100 200" ]
    end
  end


  test "Monoid::new : Column separators are optional commas." do
    assert_nothing_raised do
      RLSM::Monoid[ "0,1,2 1,2,0 2,0,1" ]
    end
  end

  test "Monoid::new : Column seperators must either be used or not in a row." do
    assert_raises RLSMError do
      RLSM::Monoid[ "0,12 120 201" ]
    end
  end

  test "Monoid::new : Row seperator is whitespaces without leading comma." do
    assert_nothing_raised do
      RLSM::Monoid[ "012   \t120\n 201" ]
      RLSM::Monoid[ "0, 1, 2    1,2,0 2,\t0,1" ]
    end
  end
end


context "Multiplication of elements:" do
  before :each do
    @monoid = RLSM::Monoid[ "012 120 201" ]
  end

  test "Monoid#[] : Should require at least two arguments." do
    assert_raises RLSMError do
      @monoid["2"]
    end

    assert_raises RLSMError do
      @monoid[]
    end
  end
  
  test "Monoid#[] : Should allow arbirtary number >= 2 of arguments" do
    assert_equal "2", @monoid["0","2"]
    assert_equal "2", @monoid["1","1"]
    assert_equal "0", @monoid["1","2"]
    assert_equal "1", @monoid["0","2", "2"]
  end

  
  test "Monoid#[] : Should raise BinOpError for unknown elements." do
    assert_raises RLSMError do
      @monoid["1","3"]
    end
  end
end

context "Comparsion of two monoids:" do
  before :each do
    @m1 = RLSM::Monoid[ "012 120 201" ]
    @m1_dup = RLSM::Monoid[ "012 120 201" ]
    @m2 = RLSM::Monoid[ "012 112 212" ]
    @m2_dup = RLSM::Monoid[ "012 112 212" ]
    @submon1 = RLSM::Monoid[ "01 11" ]
    @submon2 = RLSM::Monoid[ "01 10" ]
  end

  test "Monoid#== : Should check for same binary operation." do
    assert_equal @m1, @m1
    assert_equal @m1, @m1_dup
    refute_equal @m1, @m2
  end

  test "Monoid#== : Should check for Object type." do
    refute_equal @m1, :some_other_thing
  end

  test "Monoid#< : Should recognize proper submonoids." do
    assert @submon1 < @m2
    refute @submon2 < @m2
    assert RLSM::Monoid[ "0" ] < @m2
    refute @m2 < @m2_dup
  end

  test "Monoid#<= : Should recognize all kind of submonoids" do
    assert @m1 <= @m1_dup
    assert @submon1 <= @m2
    refute @submon2 <= @m2
  end
end

context "Generating submonoids:" do
  test "Monoid#generated_set : Should require an argument." do
    m1 = RLSM::Monoid[ "0123 1203 2013 3333" ]
    
    assert_raises ArgumentError do
      m1.generated_set
    end
  end

  test "Monoid#generated_set : Empty set should generate identity singleton." do
    m1 = RLSM::Monoid[ "0123 1203 2013 3333" ]

    assert_equal ["0"], m1.generated_set([])
  end

  test "Monoid#generated_set : Should generate smallest closed subset." do
    m1 = RLSM::Monoid[ "0123 1203 2013 3333" ]

    assert_equal ["0"], m1.generated_set(["0"])
    assert_equal ["0","3"], m1.generated_set(["3"])
    assert_equal ["0","1","2"], m1.generated_set(["1"])
    assert_equal ["0","1","2","3"], m1.generated_set(["1","3"])
  end

  test "Monoid#generated_set : Should raise BinOpError for unknown elements." do
    m1 = RLSM::Monoid[ "0123 1203 2013 3333" ]

    assert_raises RLSMError do
      m1.generated_set(["4"])
    end
  end

  test "Monoid#generated_set : Should order result according to base monoid" do
    m1 = RLSM::Monoid[ "e103 10e3 0e13 3333" ]

    assert_equal ["e","3"], m1.generated_set(["3"])
    assert_equal ["e","1","0"], m1.generated_set(["1"])
    assert_equal ["e","1","0","3"], m1.generated_set(["1","3"])
  end

  test "Submonoid generated by a set" do
    m1 = RLSM::Monoid[ "e103 10e3 0e13 3333" ]

    assert_equal RLSM::Monoid["e3 33"], m1.get_submonoid(["3"])
  end

  test "Listing of all submonoids." do
    m1 = RLSM::Monoid[ "e103 10e3 0e13 3333" ]

    asserted = [RLSM::Monoid[ 'e' ],
                RLSM::Monoid[ 'e3 33' ],
                RLSM::Monoid[ 'e10 10e 0e1' ],
                RLSM::Monoid[ 'e103 10e3 0e13 3333' ]]

    assert_equal asserted, m1.submonoids
  end

  test "Listing of all proper submonoids." do
    m1 = RLSM::Monoid[ "e103 10e3 0e13 3333" ]

    asserted = [RLSM::Monoid[ 'e3 33' ],
                RLSM::Monoid[ 'e10 10e 0e1' ]]
                
    assert_equal asserted, m1.proper_submonoids
  end
  
  test "Calculation of a generating subset." do
    m1 = RLSM::Monoid[ "e103 10e3 0e13 3333" ]

    assert_equal ['1','3'], m1.generating_subset
  end
end

context "Isomorphism and Antiisomorphism" do
  test "Isomorphism of two monoids." do
    m1 = RLSM::Monoid[ "012 112 212" ]
    m2 = RLSM::Monoid[ "abc bbc cbc" ]
    m3 = RLSM::Monoid[ "012 120 201" ]

    assert m1 =~ m2
    assert m2 =~ m1
    refute m1 =~ m3
    refute m2 =~ m3
  end

  test "Antiisomorphism of two monoids." do
    m1 = RLSM::Monoid[ "012 112 212" ]
    m2 = RLSM::Monoid[ "abc bbb ccc" ]

    assert m1.antiisomorph?(m2)
    assert m2.antiisomorph?(m1)
    refute m1.antiisomorph?(m1)
  end
end

context "Properties of an element" do
  test "Order of an element." do
    m1 = RLSM::Monoid[ "012 120 201" ]

    assert_equal 1, m1.order_of('0')
    assert_equal 3, m1.order_of('1')
  end

  test "Left ideal of an element." do
    m1 = RLSM::Monoid[ "012 120 201" ]
    m2 = RLSM::Monoid[ "012 112 222" ]
    m3 = RLSM::Monoid[ "012 112 212" ]

    assert_equal ['0','1','2'], m1.left_ideal('0')
    assert_equal ['0','1','2'], m1.left_ideal('1')
    assert_equal ['1','2'], m2.left_ideal('1')
    assert_equal ['2'], m2.left_ideal('2')
    assert_equal ['2'], m3.left_ideal('2')
  end

  test "Right ideal of an element." do
    m1 = RLSM::Monoid[ "012 120 201" ]
    m2 = RLSM::Monoid[ "012 112 222" ]
    m3 = RLSM::Monoid[ "012 112 212" ]

    assert_equal ['0','1','2'], m1.right_ideal('0')
    assert_equal ['0','1','2'], m1.right_ideal('1')
    assert_equal ['1','2'], m2.right_ideal('1')
    assert_equal ['2'], m2.right_ideal('2')
    assert_equal ['1','2'], m3.right_ideal('2')
  end
  
  test "Ideal of an element." do
    m1 = RLSM::Monoid[ "012 120 201" ]
    m2 = RLSM::Monoid[ "012 112 222" ]
    m3 = RLSM::Monoid[ "012 112 212" ]

    assert_equal ['0','1','2'], m1.ideal('0')
    assert_equal ['0','1','2'], m1.ideal('1')
    assert_equal ['1','2'], m2.ideal('1')
    assert_equal ['2'], m2.ideal('2')
    assert_equal ['1','2'], m3.ideal('2')
  end

  test "Idempotence of an element." do
    m1 = RLSM::Monoid[ "012 120 201" ]
    m2 = RLSM::Monoid[ "012 102 222" ]

    assert m1.idempotent?('0')
    assert m2.idempotent?('2')
    refute m1.idempotent?('1')
  end

  test "Neutral element." do
    m1 = RLSM::Monoid[ "01 11" ]

    assert m1.identity?('0')
    refute m1.identity?('1')

    assert_equal '0', m1.identity
  end

  test "Zero element." do
    m0 = RLSM::Monoid[ '0' ]
    m1 = RLSM::Monoid[ "01 11" ]

    assert m1.zero?('1')
    refute m1.zero?('0')
    refute m0.zero?('0')

    assert_nil m0.zero
    assert_equal '1', m1.zero
  end

  test "Left zeros." do
    m0 = RLSM::Monoid[ '0' ]
    m1 = RLSM::Monoid[ "012 111 222" ]
    m2 = RLSM::Monoid[ "012 112 212" ]

    assert m1.left_zero?('1')
    refute m2.left_zero?('1')
    refute m0.zero?('0')
  end

  test "Right zeros." do
    m0 = RLSM::Monoid[ '0' ]
    m1 = RLSM::Monoid[ "012 111 222" ]
    m2 = RLSM::Monoid[ "012 112 212" ]

    assert m2.right_zero?('1')
    refute m1.right_zero?('1')
    refute m0.zero?('0')
  end

  test "Set of all idempotents" do
    m1 = RLSM::Monoid[ "e10 111 000" ]
    m2 = RLSM::Monoid[ "012 120 201" ]

    assert_equal ['0'], m2.idempotents
    assert_equal ['e','1','0'], m1.idempotents
  end

  test "Set of all left zeros" do
    m1 = RLSM::Monoid[ "e10 111 000" ]
    m2 = RLSM::Monoid[ "012 120 201" ]
    m3 = RLSM::Monoid[ "012 102 222" ]

    assert_equal ['2'], m3.left_zeros
    assert_equal [], m2.left_zeros
    assert_equal ['1','0'], m1.left_zeros
  end

  test "Set of all right zeros" do
    m1 = RLSM::Monoid[ "e10 110 010" ]
    m2 = RLSM::Monoid[ "012 120 201" ]
    m3 = RLSM::Monoid[ "012 102 222" ]

    assert_equal ['2'], m3.right_zeros
    assert_equal [], m2.right_zeros
    assert_equal ['1','0'], m1.right_zeros
  end
end

 context "Green Relations" do
  test "L-Relation" do
    assert_equal ['a','m','z'], $monoid.l_class('a')
    assert_equal ['d','f','j','p','t','w'], $monoid.l_class('d')
    assert_equal ['1','g','k','o','s','u'], $monoid.l_class('u')
  end

  test "R-Relation" do
    assert_equal ['a',], $monoid.r_class('a')
    assert_equal ['b','d','e','i','j','l'], $monoid.r_class('d')
    assert_equal ['1','g','k','o','s','u'], $monoid.r_class('u')
  end

  test "J-Relation" do
    assert_equal ['a','m','z'], $monoid.j_class('a')
    assert_equal(['b','c','d','e','f','h','i','j','l',
                  'n','p','q','r','t','v','w','x','y'], $monoid.j_class('d'))
    assert_equal ['1','g','k','o','s','u'], $monoid.j_class('u')
  end

  test "H-Relation" do
    assert_equal ['a'], $monoid.h_class('a')
    assert_equal ['d','j'], $monoid.h_class('d')
    assert_equal ['1','g','k','o','s','u'], $monoid.h_class('u')
  end

  test "Listing of all classes of a type" do
    assert_equal([%w(a m z),
                  %w(1 g k o s u),
		  %w(b c d e f h i j l n p q r t v w x y)],
		  $monoid.j_classes)

    assert_equal([%w(a m z),
                  %w(1 g k o s u),
		  %w(b c l n x y),
		  %w(d f j p t w),
		  %w(e h i q r v)],
		  $monoid.l_classes)

    assert_equal([%w(a), %w(m), %w(z),
                  %w(1 g k o s u),
		  %w(b d e i j l),
		  %w(c f h r t x),
		  %w(n p q v w y)],
		  $monoid.r_classes)

    assert_equal([%w(a), %w(m), %w(z),
    		  %w(b l), %w(c x), %w(d j),
    		  %w(e i), %w(f t), %w(h r),
    		  %w(n y), %w(p w), %w(q v),
                  %w(1 g k o s u)],
		  $monoid.h_classes)
  end

  test "Triviality of a type"
end

context "Properties of a monoid" do
  test "Idempotence of a monoid." do
    m1 = RLSM::Monoid[ "e10 110 010" ]
    m2 = RLSM::Monoid[ "012 120 201" ]

    assert m1.idempotent?
    refute m2.idempotent?
  end

  test "Commutativity." do
    m1 = RLSM::Monoid[ "e10 110 010" ]
    m2 = RLSM::Monoid[ "012 120 201" ]

    assert m2.commutative?
    refute m1.commutative?
  end

  test "With zero?" do
    m1 = RLSM::Monoid[ "e10 110 000" ]
    m2 = RLSM::Monoid[ "012 120 201" ]

    assert m1.zero?
    refute m2.zero?
  end

  test "Group?" do
    m1 = RLSM::Monoid[ "e10 110 010" ]
    m2 = RLSM::Monoid[ "012 120 201" ]

    
    assert m2.group?
    refute m1.group?
  end

  test "Monogenic?" do
    m1 = RLSM::Monoid[ "e10 110 010" ]
    m2 = RLSM::Monoid[ "012 120 201" ]

    assert m2.monogenic?
    refute m1.monogenic?
  end
end

context "Syntactical properties of a monoid" do
  test "Decide syntacticity of a monoid" do
    m1 = RLSM::Monoid[ '012 112 212' ]
    m2 = RLSM::Monoid[ '0123 1111 2111 3111' ]

    assert m1.syntactic?
    refute m2.syntactic?
  end
end

context "Iterator: " do
  test "MonoidIterator" do
    i = 0
    RLSM::Monoid.each(3) { i += 1 }

    assert_equal 6, i, "order3"

    i = 0
    RLSM::Monoid.each(4) { i += 1 }

    assert_equal 27, i, "order4"

    i = 0
    RLSM::Monoid.each(5) { i += 1 }

    assert_equal 156, i, "order5"

    order4 = [RLSM::Monoid[ [0,1,2,3,1,0,3,2,2,3,0,1,3,2,1,0] ],
              RLSM::Monoid[ [0,1,2,3,1,0,3,2,2,3,1,0,3,2,0,1] ],
              RLSM::Monoid[ [0,1,2,3,1,0,2,3,2,2,2,2,3,3,2,2] ],
              RLSM::Monoid[ [0,1,2,3,1,0,2,3,2,2,2,3,3,3,3,2] ],
              RLSM::Monoid[ [0,1,2,3,1,0,3,2,2,3,2,3,3,2,3,2] ],
              RLSM::Monoid[ [0,1,2,3,1,0,2,3,2,2,2,2,3,3,2,3] ],
              RLSM::Monoid[ [0,1,2,3,1,0,2,3,2,2,2,2,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,0,2,3,2,3,2,3,3,2,2,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,1,1,3,1,1,1] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,3,2,1,1,3,3,3,3,1] ],
              RLSM::Monoid[ [0,1,2,3,1,1,2,2,2,2,1,1,3,2,1,1] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,1,1,3,1,1,2] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,1,1,3,1,1,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,1,1,3,1,2,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,1,1,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,1,2,3,1,2,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,3,2,1,1,3,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,2,1,2,2,1,2,3,1,2,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,2,3,2,2,1,3,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,2,1,3,1,1,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,2,1,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,2,2,3,1,2,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,2,2,3,1,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,2,3,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,2,2,2,3,3,3,3] ],
              RLSM::Monoid[ [0,1,2,3,1,1,1,1,2,1,3,0,3,1,0,2] ],
              RLSM::Monoid[ [0,1,2,3,1,1,2,3,2,2,3,1,3,3,1,2] ]]

    RLSM::Monoid.each(4) { |m| assert order4.include? m }
  end
end
