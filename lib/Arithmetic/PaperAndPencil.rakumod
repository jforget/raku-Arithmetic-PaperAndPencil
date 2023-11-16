# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Char;
use Arithmetic::PaperAndPencil::Number;
use Arithmetic::PaperAndPencil::Label;

unit class Arithmetic::PaperAndPencil:ver<0.0.1>:auth<cpan:JFORGET>;

has Arithmetic::PaperAndPencil::Action @.action is rw;

multi method BUILD () {
  @.action = ();
}

multi method BUILD(Str:D :$csv) {
  my $fh = $csv.IO.open(:r);
  @.action = $fh.lines.map( { Arithmetic::PaperAndPencil::Action.new-from-csv(csv => $_) } );
}

method csv() {
 join '', @!action.map( { $_.csv ~ "\n" } );
}

method addition(@numbers) {
  if @numbers.elems == 0 {
    die "The addition needs at least one number to add";
  }

  my Arithmetic::PaperAndPencil::Action $action;
  my Int $nb         = @numbers.elems;
  my Int $base       = @numbers[0].base;
  my Int $max-length = 0;
  my     @digits; # storing the numbers' digits
  my     @total;  # storing the total's digit positions

  $action .= new(level => 9, label => "TIT01", val1 => $base.Str);
  self.action.push($action);

  for @numbers.kv -> $i, $n {
    # checking the number
    if $n.base != $base {
      die "All numbers must have the same base";
    }
    # writing the number
    $action .= new(level => 5, label => 'WRI00', w1l => $i, w1c => 0, w1val => $n.value);
    self.action.push($action);
    # preparing the horizontal line
    if $max-length < $n.value.chars {
      $max-length = $n.value.chars;
    }
    # feeding the table of digits
    for $n.value.flip.comb.kv -> $j, $x {
      @digits[$j].push( %( lin => $i, col => -$j, val => $x) );
    }
  }
  $action .= new(level => 2, label => 'DRA02', w1l => $nb - 1, w1c => 1 - $max-length
                                             , w2l => $nb - 1, w2c => 0);
  self.action.push($action);
  for 0 ..^$max-length -> $j {
    @total[$j] = %( lin => $nb, col => -$j );
  }
  my $result = self!adding(@digits, @total, 0, $base);
  return Arithmetic::PaperAndPencil::Number.new(value => $result, base => $base);
}

method multiplication(Arithmetic::PaperAndPencil::Number :$multiplicand
                    , Arithmetic::PaperAndPencil::Number :$multiplier
                    , Str :$type = 'std'
                    ) {
  my Arithmetic::PaperAndPencil::Action $action;
  if $multiplicand.base != $multiplier.base {
    die "Multiplicand and multiplier have different bases: {$multiplicand.base} != {$multiplier.base}";
  }
  my Str $title = '';
  my Int $base  = $multiplicand.base;
  given $type {
    when 'std'      { $title = 'TIT03' ; }
    when 'shortcut' { $title = 'TIT04' ; }
    when 'prepared' { $title = 'TIT05' ; }
    when 'rectA'    { $title = 'TIT06' ; }
    when 'rectB'    { $title = 'TIT07' ; }
    when 'rhombic'  { $title = 'TIT08' ; }
  }
  if $title eq '' {
    die "Multiplication type '$type' unknown";
  }

  my Int $len1 = $multiplicand.value.chars;
  my Int $len2 = $multiplier.value.chars;
  if @.action {
    self.action[* - 1].level = 0;
  }
  $action .= new(level => 9
               , label => $title
               , val1  => $multiplicand.value
               , val2  => $multiplier.value
               , val3  => $multiplier.base.Str
               );
  self.action.push($action);

  # caching the partial products for prepared and shortcut multiplications
  my %mult-cache = 1 => $multiplicand;
  if $type eq 'prepared' {
    my Str $limit = $multiplier.value.comb.max;
    self!preparation(factor => $multiplicand, limit => $limit, cache => %mult-cache);
  }

  if $type eq 'std' | 'shortcut' | 'prepared' {
    # set-up
    $action .= new(level => 5, label => 'WRI00', w1l => 0, w1c => $len1 + $len2, w1val => $multiplicand.value
                                               , w2l => 1, w2c => $len1 + $len2, w2val => $multiplier.value);
    self.action.push($action);
    $action .= new(level => 2, label => 'DRA02', w1l => 1, w1c => min($len1, $len2)
                                               , w2l => 1, w2c => $len1 + $len2);
    self.action.push($action);

    # multiplication of two single-digit numbers
    if $len1 == 1 && $len2 == 1 {
      my Arithmetic::PaperAndPencil::Number $pdt = $multiplier ☈× $multiplicand;
      $action .= new(level => 0, label => 'MUL02'
                   , r1l => 0, r1c => 2, r1val => $multiplier.value   , val1 => $multiplier.value
                   , r2l => 1, r2c => 2, r2val => $multiplicand.value , val2 => $multiplicand.value
                   , w1l => 2, w1c => 2, w1val => $pdt.value          , val3 => $pdt.value
                   );
      self.action.push($action);
      return $pdt;
    }
    # multiplication with a single-digit multiplier
    if $len2 == 1 && $type eq 'prepared' {
      # to do
    }
    if $len2 == 1 {
      my Arithmetic::PaperAndPencil::Number $pdt;
      $pdt = self!simple-mult(:basic-level(0), :l-md(0), :c-md($len1 + 1), :multiplicand($multiplicand)
                                             , :l-mr(1), :c-mr($len1 + 1), :multiplier(  $multiplier)
                                             , :l-pd(2), :c-pd($len1 + 1) );
      self.action[* - 1].level = 0;
      return $pdt;
    }
    # multiplication with a multi-digit multiplier
    my Arithmetic::PaperAndPencil::Number $pdt;
    $pdt = self!adv-mult(:basic-level(0), :l-md(0), :c-md($len1 + $len2), :multiplicand($multiplicand)
                                        , :l-mr(1), :c-mr($len1 + $len2), :multiplier(  $multiplier)
                                        , :l-pd(2), :c-pd($len1 + $len2)
                                        , :type($type), :cache(%mult-cache));
    self.action[* - 1].level = 0;
    return $pdt;
  }
  if $type eq 'rectA' | 'rectB' {
    $action .= new(level => 5, label => 'DRA02', w1l => 0, w1c => 1
                                               , w2l => 0, w2c => 2 × $len1);
    self.action.push($action);
    $action .= new(level => 5, label => 'DRA01', w1l => 1        , w1c => 0
                                               , w2l => 2 × $len2, w2c => 0);
    self.action.push($action);
    $action .= new(level => 5, label => 'DRA01', w1l => 1        , w1c => 2 × $len1
                                               , w2l => 2 × $len2, w2c => 2 × $len1);
    self.action.push($action);
    $action .= new(level => 5, label => 'DRA02', w1l => 2 × $len2, w1c => 1
                                               , w2l => 2 × $len2, w2c => 2 × $len1);
    self.action.push($action);
  }
  if $type eq 'rectA' {
    for 1 .. $len1 -> $i {
      $action .= new(level => 5, label => 'WRI00', w1l => 0, w1c => 2 × $i - 1, w1val => $multiplicand.value.substr($i - 1, 1));
      self.action.push($action);
    }
    for 1 .. $len2 -> $i {
      $action .= new(level => 5, label => 'WRI00', w1l => 2 × $i, w1c => 2 × $len1 + 1, w1val => $multiplier.value.substr($i - 1, 1));
      self.action.push($action);
    }
    for 1 ..^ $len1 + $len2 -> $i {
      my $l1 = 1;
      my $c1 = 2 × $i;
      my $l2 = 2 × $len2;
      my $c2 = 2 × ($i - $len2) + 1;
      if $c1 ≥ 2 × $len1 {
        $l1 += $c1 - 2 × $len1;
        $c1  = 2 × $len1;
      }
      if $c2 ≤ 0 {
        $l2 -= 1 - $c2;
        $c2  = 1;
      }
      $action .= new(level => 5, label => 'DRA04', w1l => $l1, w1c => $c1, w2l => $l2, w2c => $c2);
      self.action.push($action);
    }
    # end of set-up phase
    self.action[* - 1].level = 2;

    # multiplication phase
    my @partial;
    for 1 .. $len2 -> $l {
      my Arithmetic::PaperAndPencil::Number $x .= new(base => $base, value => $multiplier.value.substr($l - 1, 1));
      for 1 .. $len1 -> $c {
        my Arithmetic::PaperAndPencil::Number $y .= new(base => $base, value => $multiplicand.value.substr($c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x ☈× $y;
        my Arithmetic::PaperAndPencil::Number $unit  = $pdt.unit;
        my Arithmetic::PaperAndPencil::Number $carry = $pdt.carry;
        $action .= new(level => 5, label => 'MUL01', r1l => 2 × $l    , r1c => 2 × $len1 + 1, r1val => $x.value    , val1 => $x.value
                                                   , r2l => 0         , r2c => 2 × $c - 1   , r2val => $y.value    , val2 => $y.value
                                                   , w1l => 2 × $l - 1, w1c => 2 × $c - 1   , w1val => $carry.value, val3 => $pdt.value
                                                   , w2l => 2 × $l    , w2c => 2 × $c       , w2val => $unit.value
                                                   );
        self.action.push($action);
        @partial[$len1 + $len2 - $l - $c    ; 2 × $l    ] = %( lin => 2 × $l    , col => 2 × $c    , val => $unit.value);
        @partial[$len1 + $len2 - $l - $c + 1; 2 × $l - 1] = %( lin => 2 × $l - 1, col => 2 × $c - 1, val => $carry.value);
      }
      # end of line
      self.action[* - 1].level = 3;
    }
    # end of multiplication phase
    self.action[* - 1].level = 2;

    # Addition phase
    my Str $result = '';
    my Str $carry  = '0';
    for @partial.kv -> $i, $l {
      my @l = $l.grep({ $_ }); # to remove the Nil entries
      if $i == 0 {
        # the first slant line has only one entry, so there is no addition and no carry
        $action .= new(level => 3, label => 'WRI03'                          , val1  => @l[0]<val>
                                 , r1l => @l[0]<lin>   , r1c => @l[0]<col>   , r1val => @l[0]<val>
                                 , w1l => 2 × $len2 + 1, w1c => 2 × $len1 - 1, w1val => @l[0]<val>
                                 );
        self.action.push($action);
        $result = @l[0]<val>;
      }
      elsif $i < @partial.elems - 1 {
        my Int $first;
        my Arithmetic::PaperAndPencil::Number $sum .= new(base => $base, value => @l[0]<val>);
        if $carry eq '0' {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[1]<val>);
          $action .= new(level => 6, label => 'ADD01', val1  => @l[0]<val>, val2 => @l[1]<val>, val3 => $sum.value
                                   , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>
                                   , r2l => @l[1]<lin>, r2c => @l[1]<col>, r2val => @l[1]<val>
                                   );
          $first = 2;
        }
        else {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => $carry);
          $action .= new(level => 6, label => 'ADD01', val1  => @l[0]<val>, val2 => $carry, val3 => $sum.value
                                   , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>
                                   );
          $first = 1;
        }
        self.action.push($action);
        for $first ..^ @l.elems -> $j {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[$j]<val>);
          $action .= new(level => 6, label => 'ADD02', val1  => @l[$j]<val>, val2 => $sum.value
                                   , r1l => @l[$j]<lin>, r1c => @l[$j]<col>, r1val => @l[$j]<val>
                                   );
          self.action.push($action);
        }
        my Str $digit = $sum.unit.value;
        $carry        = $sum.carry.value;
        my Int $lin;
        my Int $col;
        my Str $code = 'WRI02';
        if $carry eq '0' {
          $code = 'WRI03';
        }
        if $i < $len1 {
          $lin = 2 × $len2 + 1;
          $col = 2 × ($len1 - $i) - 1;
        }
        else {
          $lin = 2 × ($len1 + $len2 - $i);
          $col = 0;
        }
        $action .= new(level => 3, label => $code, val1 => $digit, val2 => $carry
                                 , w1l => $lin, w1c => $col, w1val => $digit
                                 );
        self.action.push($action);
        $result = $digit ~ $result;
      }
      else {
        # the last slant line has only one entry, but there can be a carry from the next-to-last slant line
        my $sum =  Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[0]<val>);
        my Str $code = 'WRI04';
        if $carry ne '0' {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => $carry);
          $code  = 'ADD01';
        }
        $action .= new(level => 0, label => $code, val1 => @l[0]<val>, val2 => $carry, val3 => $sum.value
                                 , r1l => 1, r1c => 1, r1val => @l[0]<val>
                                 , w1l => 2, w1c => 0, w1val => $sum.value
                                 );
        self.action.push($action);
        $result = $sum.value ~ $result;
      }
    }
    return Arithmetic::PaperAndPencil::Number.new(base => $base, value => $result);
  }
  if $type eq 'rectB' {
    for 1 .. $len1 -> $i {
      $action .= new(level => 5, label => 'WRI00', w1l => 0, w1c => 2 × $i, w1val => $multiplicand.value.substr($i - 1, 1));
      self.action.push($action);
    }
    for 1 .. $len2 -> $i {
      $action .= new(level => 5, label => 'WRI00', w1l => 2 × ($len2 - $i + 1), w1c => 0, w1val => $multiplier.value.substr($i - 1, 1));
      self.action.push($action);
    }
    for 1 - $len2 ..^ $len1 -> $i {
      my $l1 = 1;
      my $c1 = 1 + 2 × $i;
      my $l2 = 2 × $len2;
      my $c2 = 2 × ($i + $len2);
      if $c1 ≤ 0 {
        $l1 += 1 - $c1;
        $c1  = 1;
      }
      if $c2 ≥ 2 × $len1 {
        $l2 -= $c2 - 2 × $len1;
        $c2  = 2 × $len1;
      }
      $action .= new(level => 5, label => 'DRA03', w1l => $l1, w1c => $c1, w2l => $l2, w2c => $c2);
      self.action.push($action);
    }
    # end of set-up phase
    self.action[* - 1].level = 2;

    # multiplication phase
    my @partial;
    for 1 .. $len2 -> $l {
      my Arithmetic::PaperAndPencil::Number $x .= new(base => $base, value => $multiplier.value.substr($len2 - $l, 1));
      for 1 .. $len1 -> $c {
        my Arithmetic::PaperAndPencil::Number $y .= new(base => $base, value => $multiplicand.value.substr($c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x ☈× $y;
        my Arithmetic::PaperAndPencil::Number $unit  = $pdt.unit;
        my Arithmetic::PaperAndPencil::Number $carry = $pdt.carry;
        $action .= new(level => 5, label => 'MUL01', r1l => 2 × $l    , r1c => 0         , r1val => $x.value    , val1 => $x.value
                                                   , r2l => 0         , r2c => 2 × $c    , r2val => $y.value    , val2 => $y.value
                                                   , w1l => 2 × $l    , w1c => 2 × $c - 1, w1val => $carry.value, val3 => $pdt.value
                                                   , w2l => 2 × $l - 1, w2c => 2 × $c    , w2val => $unit.value
                                                   );
        self.action.push($action);
        @partial[$len1 - $c + $l - 1; 2 × $l - 1] = %( lin => 2 × $l - 1, col => 2 × $c    , val => $unit.value);
        @partial[$len1 - $c + $l    ; 2 × $l    ] = %( lin => 2 × $l    , col => 2 × $c - 1, val => $carry.value);
      }
      # end of line
      self.action[* - 1].level = 3;
    }
    # end of multiplication phase
    self.action[* - 1].level = 2;

    # Addition phase
    my Str $result = '';
    my Str $carry  = '0';
    for @partial.kv -> $i, $l {
      my @l = $l.grep({ $_ }); # to remove the Nil entries
      if $i == 0 {
        # the first slant line has only one entry, so there is no addition and no carry
        $action .= new(level => 3, label => 'WRI03'                          , val1  => @l[0]<val>
                                 , r1l => @l[0]<lin>   , r1c => @l[0]<col>   , r1val => @l[0]<val>
                                 , w1l => 2 , w1c => 2 × $len1 + 1, w1val => @l[0]<val>
                                 );
        self.action.push($action);
        $result = @l[0]<val>;
      }
      elsif $i < @partial.elems - 1 {
        my Int $first;
        my Arithmetic::PaperAndPencil::Number $sum .= new(base => $base, value => @l[0]<val>);
        if $carry eq '0' {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[1]<val>);
          $action .= new(level => 6, label => 'ADD01', val1  => @l[0]<val>, val2 => @l[1]<val>, val3 => $sum.value
                                   , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>
                                   , r2l => @l[1]<lin>, r2c => @l[1]<col>, r2val => @l[1]<val>
                                   );
          $first = 2;
        }
        else {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => $carry);
          $action .= new(level => 6, label => 'ADD01', val1  => @l[0]<val>, val2 => $carry, val3 => $sum.value
                                   , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>
                                   );
          $first = 1;
        }
        self.action.push($action);
        for $first ..^ @l.elems -> $j {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[$j]<val>);
          $action .= new(level => 6, label => 'ADD02', val1  => @l[$j]<val>, val2 => $sum.value
                                   , r1l => @l[$j]<lin>, r1c => @l[$j]<col>, r1val => @l[$j]<val>
                                   );
          self.action.push($action);
        }
        my Str $digit = $sum.unit.value;
        $carry        = $sum.carry.value;
        my Int $lin;
        my Int $col;
        my Str $code = 'WRI02';
        if $carry eq '0' {
          $code = 'WRI03';
        }
        if $i < $len2 {
          $lin = 2 × $i + 2;
          $col = 2 × $len1 + 1;
        }
        else {
          $lin = 2 × $len2  + 1;
          $col = 2 × ($len1 + $len2 - $i);
        }
        $action .= new(level => 3, label => $code, val1 => $digit, val2 => $carry
                                 , w1l => $lin, w1c => $col, w1val => $digit
                                 );
        self.action.push($action);
        $result = $digit ~ $result;
      }
      else {
        # the last slant line has only one entry, but there can be a carry from the next-to-last slant line
        my $sum =  Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[0]<val>);
        my Str $code = 'WRI04';
        if $carry ne '0' {
          $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => $carry);
          $code  = 'ADD01';
        }
        $action .= new(level => 0, label => $code, val1 => @l[0]<val>, val2 => $carry, val3 => $sum.value
                                 , r1l => 1            , r1c => 1, r1val => @l[0]<val>
                                 , w1l => 2 × $len2 + 1, w1c => 2, w1val => $sum.value
                                 );
        self.action.push($action);
        $result = $sum.value ~ $result;
      }
    }
    return Arithmetic::PaperAndPencil::Number.new(base => $base, value => $result);
  }
  self.action[* - 1].level = 0;
}

method !adv-mult(Int :$basic-level, Str :$type = 'std'
               , Int :$l-md, Int :$c-md # coordinates of the multiplicand
               , Int :$l-mr, Int :$c-mr # coordinates of the multiplier
               , Int :$l-pd, Int :$c-pd # coordinates of the product
               , Arithmetic::PaperAndPencil::Number :$multiplicand
               , Arithmetic::PaperAndPencil::Number :$multiplier
               , :%cache) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Str $result = '';
  my Int $base  = $multiplier.base;
  my Int $line  = $l-pd;
  my Int $pos   = $multiplier.value.chars - 1;
  my Int $shift = 0;
  my Str $shift-char = '0';
  my     @partial; # storing the partial products' digits
  my     @final  ; # storing the final product's digit positions

  while $pos ≥ 0 {
    # shifting the current simple multiplication because of embedded zeroes
    if $multiplier.value.substr(0, $pos + 1) ~~ / ( '0' + ) $ / {
      $shift += $0.chars;
      $pos   -= $0.chars;
    }
    if $shift != 0 {
      $action .= new(level => $basic-level + 5, label => 'WRI00', w1l => $line, w1c => $c-pd, w1val => $shift-char x $shift);
      self.action.push($action);
      if $shift-char eq '0' {
        for 0 ..^ $shift -> $i {
          push @partial[$i], %( lin => $line, col => $c-pd - $i, val => '0');
        }
      }
    }
    # computing the simple multiplication
    my Arithmetic::PaperAndPencil::Number $mul .= new(base => $base, value => $multiplier.value.substr($pos, 1));
    my Arithmetic::PaperAndPencil::Number $pdt;
    if $type ne 'std' && %cache{$mul.value} {
      $pdt = %cache{$mul.value};
      $action .= new(level => $basic-level + 3, label => 'WRI05', val1 => $pdt.value
                   , w1l => $line, w1c => $c-pd - $shift, w1val => $pdt.value
                   );
      self.action.push($action);

    }
    else {
      $pdt = self!simple-mult(basic-level => $basic-level
                            , l-md => $l-md, c-md => $c-md         , multiplicand => $multiplicand
                            , l-mr => $l-mr, c-mr => $c-mr - $shift, multiplier   => $mul
                            , l-pd => $line, c-pd => $c-pd - $shift);
      # filling the cache
      %cache{$mul.value} = $pdt;
    }
    # storing the digits of $pdt
    for $pdt.value.comb.reverse.kv -> $i, $x {
      push @partial[$i + $shift], %( lin => $line, col => $c-pd - $shift - $i, val => $x);
    }
    # shifting the next simple multiplication
    $pos--;
    $shift++;
    $shift-char = '.';
    $line++;
  }
  $action .= new(level => $basic-level + 2, label => 'DRA02'
               , w1l => $line - 1, w1c => $c-pd + 1 - $multiplicand.value.chars - $multiplier.value.chars
               , w2l => $line - 1, w2c => $c-pd);
  self.action.push($action);
  for (0..$c-pd) -> $i {
    @final[$i] = %( lin => $line, col => $c-pd - $i );
  }

  $result = self!adding(@partial, @final, $basic-level, $base);
  return  Arithmetic::PaperAndPencil::Number.new(:base($base), :value($result));
}

method !simple-mult(Int :$basic-level
                  , Int :$l-md, Int :$c-md # coordinates of the multiplicand
                  , Int :$l-mr, Int :$c-mr # coordinates of the multiplier (single-digit)
                  , Int :$l-pd, Int :$c-pd # coordinates of the product
                  , Arithmetic::PaperAndPencil::Number :$multiplicand
                  , Arithmetic::PaperAndPencil::Number :$multiplier) {
  my Str $result = '';
  my Int $base = $multiplier.base;
  my     $carry = '0';
  my Int $len1  = $multiplicand.value.chars;
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $pdt;
  for (0 ..^ $len1) -> $i {
    my Arithmetic::PaperAndPencil::Number $mul .= new(:base($base), :value($multiplicand.value.substr($len1 - $i - 1, 1)));
    $pdt   = $multiplier ☈× $mul;
    $action .= new(level => $basic-level + 6, label => 'MUL01'                , val3 => $pdt.value
                 , r1l => $l-mr, r1c => $c-mr     , r1val => $multiplier.value, val1 => $multiplier.value
                 , r2l => $l-md, r2c => $c-md - $i, r2val => $mul.value       , val2 => $mul.value
                 );
    self.action.push($action);
    if $carry ne '0' {
      $pdt ☈+= Arithmetic::PaperAndPencil::Number.new(:base($base), :value($carry));
      $action .= new(level => $basic-level + 6, label => 'ADD02', val1 => $carry, val2 => $pdt.value);
      self.action.push($action);
    }
    my Str $unit  = $pdt.unit.value;
    $carry        = $pdt.carry.value;
    my Str $code = 'WRI02';
    if $carry eq '0' {
      $code = 'WRI03';
    }
    if $i < $len1 - 1 {
      $action .= new(level => $basic-level + 5, label => $code, val1 => $unit, val2 => $carry
                   , w1l => $l-pd, w1c => $c-pd - $i, w1val => $unit
                     );
      self.action.push($action);
      $result = $unit ~ $result;
    }
  }
  $action .= new(level => $basic-level + 3, label => 'WRI00'
               , w1l => $l-pd, w1c => $c-pd + 1 - $len1, w1val => $pdt.value
                 );
  self.action.push($action);
  return  Arithmetic::PaperAndPencil::Number.new(:base($base), :value($pdt.value ~ $result));
}

method !adding(@digits, @pos, $basic-level, $base) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $sum;
  my Str $result = '';
  my Str $carry  = '0';
  for @digits.kv -> $i, $l {
    my @l = $l.grep({ $_ }); # to remove the Nil entries
    if @l.elems == 1 && $carry eq '0' {
        $action .= new(level => $basic-level + 3, label => 'WRI04'           , val1  => @l[0]<val>
                                 , r1l => @l[ 0  ]<lin>, r1c => @l[ 0  ]<col>, r1val => @l[0]<val>
                                 , w1l => @pos[$i]<lin>, w1c => @pos[$i]<col>, w1val => @l[0]<val>
                                 );
        self.action.push($action);
        $result = @l[0]<val> ~ $result;
    }
    else {
      my Int $first;
      $sum .= new(base => $base, value => @l[0]<val>);
      if $carry eq '0' {
        $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[1]<val>);
        $action .= new(level => $basic-level + 6, label => 'ADD01', val1  => @l[0]<val>, val2 => @l[1]<val>, val3 => $sum.value
                            , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>
                            , r2l => @l[1]<lin>, r2c => @l[1]<col>, r2val => @l[1]<val>
                            );
        $first = 2;
      }
      else {
        $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => $carry);
        $action .= new(level => $basic-level + 6, label => 'ADD01', val1  => @l[0]<val>, val2 => $carry, val3 => $sum.value
                            , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>
                            );
        $first = 1;
      }
      self.action.push($action);
      for $first ..^ @l.elems -> $j {
        $sum ☈+= Arithmetic::PaperAndPencil::Number.new(base => $base, value => @l[$j]<val>);
        $action .= new(level => $basic-level + 6, label => 'ADD02', val1  => @l[$j]<val>, val2 => $sum.value
                          , r1l => @l[$j]<lin>, r1c => @l[$j]<col>, r1val => @l[$j]<val>
                          );
        self.action.push($action);
      }
      if $i == @digits.elems - 1 {
        my $last-action = self.action[* - 1];
        self.action[* - 1] .= new(level => $basic-level + 2, label => $last-action.label, val1  => $last-action.val1, val2 => $last-action.val2, val3 => $last-action.val3
                          , r1l => $last-action.r1l, r1c => $last-action.r1c, r1val => $last-action.r1val
                          , r2l => $last-action.r2l, r2c => $last-action.r2c, r2val => $last-action.r2val
                          , w1l => @pos[$i]<lin>   , w1c => @pos[$i]<col> ,   w1val => $sum.value
                          );
        $result = $sum.value ~ $result;
      }
      else {
        my Str $digit = $sum.unit.value;
        $carry        = $sum.carry.value;
        my Int $lin;
        my Int $col;
        my Str $code = 'WRI02';
        if $carry eq '0' {
          $code = 'WRI03';
        }
        $action .= new(level => $basic-level + 3, label => $code, val1 => $digit, val2 => $carry
                   , w1l => @pos[$i]<lin>, w1c => @pos[$i]<col>, w1val => $digit
                   );
        self.action.push($action);
        $result = $digit ~ $result;
      }
    }
  }
  return $result;
}

method !preparation(Arithmetic::PaperAndPencil::Number :$factor, Str :$limit, :%cache) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $one .= new(:base($factor.base), :value<1>);
  my Int $base = $factor.base;
  my Int $col  = $factor.value.chars + 3;

  # cache first entry
  %cache<1> = $factor;
  $action .= new(level => 3, label => 'WRI00'
               , w1l => 0, w1c => 0   , w1val => '1'
               , w2l => 0, w2c => $col, w2val => $factor.value);
  self.action.push($action);

  my @digits; # storing the numbers' digits
  my @total;  # storing the total's digit positions
  for $factor.value.flip.comb.kv -> $i, $ch {
    @digits[$i][0] = %( lin => 0, col => $col - $i, val => $ch);
    @total[ $i]    = %( lin => 1, col => $col - $i);
  }
  # in case the last partial products are longer than the factor
  @total[$factor.value.chars] = %( lin => 1, col => $col - $factor.value.chars);

  my Str $result = $factor.value;
  my Int $lin    = 1;
  my Arithmetic::PaperAndPencil::Number $mul = $one ☈+ $one; # starting from 2; yet stopping immediately with a 2-digit $mul if $base == 2
  while $mul.value le $limit && $mul.value.chars == 1 {
    # displaying the line number
    $action .= new(level => 9, label => 'WRI00', w1l => $lin, w1c => 0, w1val => $mul.value);
    self.action.push($action);

    # computation
    for $result.flip.comb.kv -> $i, $ch {
      @digits[$i][1] = %( lin => $lin - 1, col => $col - $i, val => $ch);
      @total[$i]<lin> = $lin;
    }
    $result = self!adding(@digits, @total, 1, $base);
    self.action[* - 1].level = 3;

    # storing into cache
    %cache{$mul.value} = Arithmetic::PaperAndPencil::Number.new(:base($base), :value($result));

    # loop iteration
    $lin++;
    $mul ☈+= $one;
  }

  $action .= new(:level(2), :label<NXP01>);
  self.action.push($action);
}

method html(Str :$lang, Bool :$silent, Int :$level, :%css = %()) {
  my Bool $talkative = not $silent; # "silent" better for API, "talkative" better for programming
  my Str  $result    = '';
  my      @sheet     = ();
  my Int  %vertical-lines;
  my Int  %cache-l2p-col;
  my Int  $c-min     = 0;
  my Int  $l-min     = 0;

  # checking the line minimum number
  sub check-l-min(Int $l) {
    if $l < $l-min {
      # inserting new empty lines before the existing ones
      for $l ..^ $l-min {
        unshift @sheet, Nil;
      }
      # updating the line minimum number
      $l-min = $l;
    }
  }
  # logical to physical line number
  sub l2p-lin(Int $logl --> Int) {
    my Int $result = $logl - $l-min;
    return $result;
  }

  # checking the column minimum number
  sub check-c-min(Int $c) {
    if $c < $c-min {
      my Int $delta-c = $c-min - $c;
      for @sheet <-> $line {
        prepend $line, space-char() xx $delta-c;
      }
      $c-min = $c;
      %cache-l2p-col  = %();
    }
  }
  # logical to physical column number
  sub l2p-col(Int $logc --> Int) {
    if %cache-l2p-col{$logc} {
      return %cache-l2p-col{$logc};
    }
    my Int $result = $logc - $c-min;
    for %vertical-lines.keys -> $col {
      if $logc > $col {
        ++$result;
      }
    }
    %cache-l2p-col{$logc} = $result;
    return $result;
  }

  sub filling-spaces(Int $l, Int $c) {
    # putting spaces into all uninitialised boxes
    for 0 .. l2p-lin($l) -> $l1 {
       @sheet[$l1; 0] //= space-char;
    }
    for 0 .. l2p-col($c) -> $c1 {
       @sheet[l2p-lin($l); $c1] //= space-char;
    }
  }

  for @.action -> $action {
    if $action.label.starts-with('TIT') or $action.label eq 'NXP01' {
      @sheet          =  ();
      %vertical-lines = %();
      %cache-l2p-col  = %();
    }

    # Drawing a vertical line
    if $action.label eq 'DRA01' {
      if  $action.w1c != $action.w2c {
        die "The line is not vertical, starting at column {$action.w1c} and ending at column {$action.w2c}";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-l-min($action.w2l);
      check-c-min($action.w1c);
      # making some clear space for the vertical line
      unless %vertical-lines{$action.w1c} {
        %vertical-lines{$action.w1c} = 1;
        # clearing the cache
        %cache-l2p-col  = %();

        # shifting characters past the new vertical line's column
        for @sheet.keys -> $l {
          for 0 .. l2p-col($action.w1c) -> $c {
             @sheet[$l; $c] //= space-char;
          }
          my $line = @sheet[$l];
          splice($line, l2p-col($action.w1c) + 1, 0, space-char);
          @sheet[$l] = $line;
        }
      }
      # making the vertical line
      for $action.w1l .. $action.w2l -> $l {
        filling-spaces($l, $action.w1c);
        @sheet[l2p-lin($l); l2p-col($action.w1c) + 1] = pipe-char;
      }
    }

    # Drawing an horizontal line
    if $action.label eq 'DRA02' {
      if  $action.w1l != $action.w2l {
        die "The line is not horizontal, starting at line {$action.w1l} and ending at line {$action.w2l}";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-c-min($action.w1c);
      check-l-min($action.w2c);
      # begin and end
      my ($c-beg, $c-end);
      if $action.w1c > $action.w2c {
        $c-beg = l2p-col($action.w2c);
        $c-end = l2p-col($action.w1c);
        filling-spaces($action.w1l, $action.w1c);
      }
      else {
        $c-beg = l2p-col($action.w1c);
        $c-end = l2p-col($action.w2c);
        filling-spaces($action.w1l, $action.w2c);
      }
      for $c-beg .. $c-end -> $i {
        @sheet[l2p-lin($action.w1l); $i].underline = True;
      }
    }

    # Drawing an oblique line
    if $action.label eq 'DRA03' {
      if $action.w2c - $action.w1c != $action.w2l - $action.w1l {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-l-min($action.w2l);
      check-c-min($action.w1c);
      check-c-min($action.w2c);
      # begin and end
      my ($l-beg, $c-beg);
      if $action.w2l > $action.w1l {
        # line is defined top-left to bot-right
        $l-beg = $action.w1l;
        $c-beg = $action.w1c;
      }
      else {
        # line was defined bot-right to top-left
        $l-beg = $action.w2l;
        $c-beg = $action.w2c;
      }
      # drawing the line top-left to bot-right
      for 0 .. ($action.w2l - $action.w1l).abs -> $i {
        filling-spaces($l-beg + $i, $c-beg + $i);
        my $l1 = l2p-lin($l-beg + $i);
        my $c1 = l2p-col($c-beg + $i);
        @sheet[$l1; $c1].char = '\\';
      }
    }
    if $action.label eq 'DRA04' {
      if $action.w2c - $action.w1c != $action.w1l - $action.w2l {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-l-min($action.w2l);
      check-c-min($action.w1c);
      check-c-min($action.w2c);
      # begin and end
      my ($l-beg, $c-beg);
      if $action.w2l > $action.w1l {
        # line is defined top-right to bot-left
        $l-beg = $action.w1l;
        $c-beg = $action.w1c;
      }
      else {
        # line was defined bot-left to top-right
        $l-beg = $action.w2l;
        $c-beg = $action.w2c;
      }
      # drawing the line top-right to bot-left
      for 0 .. ($action.w2l - $action.w1l).abs -> $i {
        filling-spaces($l-beg + $i, $c-beg - $i);
        my $l1 = l2p-lin($l-beg + $i);
        my $c1 = l2p-col($c-beg - $i);
        @sheet[$l1; $c1].char = '/';
      }
    }

    # Reading some digits (or other characters) and possibly striking them
    if $action.r1val ne '' {

      # checking the line and column minimum numbers
      # (should not be necessary: if the digits are being read, they must have been previously written)
      check-l-min($action.r1l);
      check-c-min($action.r1c - $action.r1val.chars + 1);

      # putting spaces into all uninitialised boxes
      # (should not be necessary, for the same reason)
      filling-spaces($action.r1l, $action.r1c);

      # tagging each char
      for $action.r1val.comb('').kv -> $i, $str {
         with @sheet[l2p-lin($action.r1l); l2p-col($action.r1c - $action.r1val.chars + $i + 1)] {
           $_.read = True;
           if $action.r1str {
             $_.strike = True;
           }
         }
      }
    }
    if $action.r2val ne '' {

      # checking the line and column minimum numbers
      # (should not be necessary, for the same reason as r1val)
      check-l-min($action.r2l);
      check-c-min($action.r2c - $action.r2val.chars + 1);

      # putting spaces into all uninitialised boxes
      # (should not be necessary, for the same reason)
      filling-spaces($action.r2l, $action.r2c);

      # tagging each char
      for $action.r2val.comb('').kv -> $i, $str {
         with @sheet[l2p-lin($action.r2l); l2p-col($action.r2c - $action.r2val.chars + $i + 1)] {
           $_.read = True;
           if $action.r2str {
             $_.strike = True;
           }
         }
      }
    }

    # Writing some digits (or other characters)
    if $action.w1val ne '' {
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-c-min($action.w1c - $action.w1val.chars + 1);
      # putting spaces into all uninitialised boxes
      filling-spaces($action.w1l, $action.w1c);
      # putting each char separately into its designated box
      for $action.w1val.comb('').kv -> $i, $str {
         with @sheet[l2p-lin($action.w1l); l2p-col($action.w1c - $action.w1val.chars + $i + 1)] {
           $_.char  = $str;
           $_.write = True;
         }
      }
    }
    if $action.w2val ne '' {
      # checking the line and column minimum numbers
      check-l-min($action.w2l);
      check-c-min($action.w2c - $action.w2val.chars + 1);
      # putting spaces into all uninitialised boxes
      filling-spaces($action.w2l, $action.w2c);
      # putting each char separately into its designated box
      for $action.w2val.comb('').kv -> $i, $str {
         with @sheet[l2p-lin($action.w2l); l2p-col($action.w2c - $action.w2val.chars + $i + 1)] {
           $_.char  = $str;
           $_.write = True;
         }
      }
    }

    # Erasing characters
    if $action.label eq 'ERA01' {
      if  $action.w1l != $action.w2l {
        die "The chars are not horizontally aligned, starting at line {$action.w1l} and ending at line {$action.w2l}";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-c-min($action.w1c);
      check-l-min($action.w2c);
      # begin and end
      my ($c-beg, $c-end);
      if $action.w1c > $action.w2c {
        $c-beg = l2p-col($action.w2c);
        $c-end = l2p-col($action.w1c);
        filling-spaces($action.w1l, $action.w1c);
      }
      else {
        $c-beg = l2p-col($action.w1c);
        $c-end = l2p-col($action.w2c);
        filling-spaces($action.w1l, $action.w2c);
      }
      for $c-beg .. $c-end -> $i {
        @sheet[l2p-lin($action.w1l); $i].char = ' ';
      }
    }

    # Talking
    if $talkative or $action.label.starts-with('TIT') {
      my $line = full-label($action.label, $action.val1, $action.val2, $action.val3, $lang);
      if $line {
        if  $action.label.starts-with('TIT') {
          $line = "<operation>{$line}</operation>\n";
        }
        else {
          $line = "<talk>{$line}</talk>\n";
        }
        $result ~= $line;
      }
    }

    # Showing the operation
    if $action.level ≤ $level {
      my Str $op = '';
      for @sheet.kv -> $l, $line {
        my $line1 = $line.map({ $_.html }).join('');
        $op ~= $line1 ~ "\n";
      }
      if $op ne '' {
        $result ~= "<pre>\n{$op}</pre>\n";
      }
      # untagging written and read chars
      for @sheet -> $line {
        for @$line -> $char {
          $char.read  = False;
          $char.write = False;
        }
      }
    }
  }

  # simplyfing pseudo-HTML
  $result ~~ s:g/ "</underline><underline>" //;
  $result ~~ s:g/ "</strike><strike>" //;
  $result ~~ s:g/ "</write>" (\h*) "<write>" /$0/;
  $result ~~ s:g/ "</read>"  (\h*) "<read>"  /$0/;

  # changing pseudo-HTML into proper HTML
  $result ~~ s:g/"operation>"/h1>/;
  if %css<talk> {
    $result ~~ s:g! "</talk>" !</p>!;
    $result ~~ s:g! "<talk>"  !<p class='%css<talk>'>!;
  }
  else {
    $result ~~ s:g/"talk>"/p>/;
  }
  if %css<underline> {
    $result ~~ s:g! "</underline>" !</span>!;
    $result ~~ s:g! "<underline>"  !<span class='%css<underline>'>!;
  }
  else {
    $result ~~ s:g/"underline>"/u>/;
  }
  # maybe I should replace all "strike" tags by "del"? or by "s"?
  # see https://www.w3schools.com/tags/tag_strike.asp : <strike> is not supported in HTML5
  if %css<strike> {
    $result ~~ s:g! "</strike>" !</span>!;
    $result ~~ s:g! "<strike>"  !<span class='%css<strike>'>!;
  }
  if %css<read> {
    $result ~~ s:g! "</read>" !</span>!;
    $result ~~ s:g! "<read>"  !<span class='%css<read>'>!;
  }
  else {
    $result ~~ s:g/"read>"/em>/;
  }
  if %css<write> {
    $result ~~ s:g! "</write>" !</span>!;
    $result ~~ s:g! "<write>"  !<span class='%css<write>'>!;
  }
  else {
    $result ~~ s:g/"write>"/strong>/;
  }
  $result ~~ s:g/ \h+ $$//;

  return $result;
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil;

=end code

=head1 DESCRIPTION

Arithmetic::PaperAndPencil is ...

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
