require File.join(File.dirname(__FILE__), '..', 'lib', 'rlsm')

class Presenter
  @@template = <<TEMPLATE
\\begin{tabular}[t]{c|c}
\\textbf{%l%table%%} & \\textbf{%l%dfa%%} \\\\ \\hline
  %%table2tex%%  &  %%dfa2tex%%
\\end{table}

\\begin{tabular}{llcll}
  \\multicolumn{2}{l}{\\textbf{Eigenschaften des Monoids:}} & & \\multicolumn{2}{l}{\\textbf{Spezielle Elemente:}} \\\\
  %l%generator%%: & %%generating_subset%%   &                 & %l%idem_els%%: & %%idempotents%% \\\\
  %l%group%%:     & %%group?%%       &                        & %%zero1%% \\\\
  %l%comm%%:      & %%commutative?%% &                        & %%zero2%% \\\\
  %l%idem%%:      & %%idempotent?%%  &                        &                  & \\\\
  %l%syn%%:       & %%syntactic?%%   &                        & \\multicolumn{2}{l}{\\\\textbf{%l%green%%:}} \\\\
  %l%aper%%:      & %%aperiodic?%%   &                        & %l%lclasses%%:   & %%l_classes%% \\\\
  %l%ltriv%%:     & %%l_trivial?%%   &                        & %l%rclasses%%:   & %%r_classes%% \\\\
  %l%rtriv%%:     & %%r_trivial?%%   &                        & %l%hclasses%%:   & %%h_classes%% \\\\
  %l%jtriv%%:     & %%j_trivial?%%   &                        & %l%dclasses%%:   & %%d_classes%% \\\\
  %l%has_zero%%:  & %%zero?%%        &                        &                  &               \\\\
\\end{tabular}

\\textbf{%l%submons%%:} %%submonoids%%

%%syntactic_properties%%
TEMPLATE

  @@lang = { 
    :en => Hash['table', 'Binary Operation', 
                'dfa', 'DFA',
                'generator', 'Generator',
                'group', 'Group',
                'comm', 'Commutative',
                'idem', 'Idempotent',
                'syn', 'Syntactic',
                'aper', 'Aperiodic',
                'ltriv', 'L-trivial',
                'rtriv', 'R-trivial',
                'jtriv', 'J-trivial',
                'has_zero', 'Has zero elemnt',
                'idem_els', 'Idempotents',
                'zero', 'Zero element',
                'lzero', 'Left zeros',
                'rzero', 'Right zeros',
                'green', 'Green Relations',
                'lclasses', 'L-classes',
                'rclasses', 'R-classes',
                'hclasses', 'H-classes',
                'dclasses', 'D-classes',
                'submons', 'Submonoids',
                'none', 'none',
                true, 'yes',
                false, 'no'], 
    :de => Hash['table', 'Binäre Operation',
                'dfa', 'DFA',
                'generator', 'Erzeuger',
                'group', 'Gruppe',
                'comm', 'Kommutativ',
                'idem', 'Idempotent',
                'syn', 'Syntaktisch',
                'aper', 'Aperiodisch',
                'ltriv', 'L-trivial',
                'rtriv', 'R-trivial',
                'jtriv', 'J-trivial',
                'has_zero', 'mit Nullelement',
                'idem_els', 'Idempotente Elemente',
                'zero', 'Nullelement',
                'lzero', 'Linksnullelemente',
                'rzero', 'Rechtsnullelemente',
                'green', 'Greensche Relationen',
                'lclasses', 'L-Klassen',
                'rclasses', 'R-Klassen',
                'hclasses', 'H-Klassen',
                'dclasses', 'D-Klassen',
                'submons', 'Untermonoide',
                'none', 'keine',
                true, 'ja',
                false, 'nein'] 
  }

  def self.to_latex(monoid = RLSM::Monoid['012 120 201'], lang = :en)
    presenter = Presenter.new(monoid, lang)
    output = @@template.dup
    @@lang[lang].each_pair do |key, text|
      output.sub!("%l%#{key}%%", text)
    end

    while output =~ /%%(\w+\??)%%/
      output.sub!($~[0], presenter.send($~[1].to_sym))
    end

    puts output
  end

  def initialize(monoid,lang)
    @monoid = monoid 
    @lang = @@lang[lang]
  end

  def table2tex
    @monoid.to_s
  end

  def dfa2tex
    "not implemented"
  end

  def zero1
    'foo'
  end

  def zero2
    'bar'
  end

  def syntactic_properties
    'baz'
  end

  def method_missing(name, *args)
p name
p @monoid
    if name.to_s =~ /\?/
      @lang[@monoid.send(name)]
    else
      set2tex @monoid.send(name)
    end
  end

  def set2tex(set)
    "\{" + set.join(', ') + "\}"
  end
end
