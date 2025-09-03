# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Char;
use Arithmetic::PaperAndPencil::Number;
use Arithmetic::PaperAndPencil::Label;

unit class Arithmetic::PaperAndPencil:ver<0.0.2>:auth<zef:jforget>;

has Arithmetic::PaperAndPencil::Action @.action is rw;

multi method BUILD () {
  @.action = ();
}

multi method BUILD(Str:D :$csv) {
  my $fh = $csv.IO.open(:r);
  @.action = $fh.lines.map( { Arithmetic::PaperAndPencil::Action.new-from-csv(csv => $_) } );
}

method csv(--> Str) {
 join '', @!action.map( { $_.csv ~ "\n" } );
}

method addition(*@numbers --> Arithmetic::PaperAndPencil::Number) {
  if @numbers.elems == 0 {
    die "The addition needs at least one number to add";
  }

  my Arithmetic::PaperAndPencil::Action $action;
  my Int $nb         = @numbers.elems;
  my Int $radix      = @numbers[0].radix;
  my Int $max-length = 0;
  my     @digits; # storing the numbers' digits
  my     @total;  # storing the total's digit positions

  $action .= new(level => 9, label => "TIT01", val1 => $radix.Str);
  self.action.push($action);

  for @numbers.kv -> $i, $n {
    # checking the number
    if $n.radix != $radix {
      die "All numbers must have the same radix";
    }
    # writing the number
    $action .= new(level => 5, label => 'WRI00', w1l => $i, w1c => 0, w1val => $n.value);
    self.action.push($action);
    # preparing the horizontal line
    if $max-length < $n.chars {
      $max-length = $n.chars;
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
  my $result = self!adding(@digits, @total, 0, $radix);
  return Arithmetic::PaperAndPencil::Number.new(value => $result, radix => $radix);
}

method subtraction(Arithmetic::PaperAndPencil::Number :$high
                 , Arithmetic::PaperAndPencil::Number :$low
                 , Str :$type = 'std'
                 --> Arithmetic::PaperAndPencil::Number
                 ) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $high.radix;
  my Int $leng  = $high.chars;
  if $low.radix != $radix {
    die "The two numbers have different bases: {$radix} != {$low.radix}";
  }
  if $type ne 'std' | 'compl' {
    die "Subtraction type '$type' unknown";
  }
  if $high ☈< $low {
    die "The high number {$high.value} must be greater than or equal to the low number {$low.value}";
  }
  if @.action {
    self.action[* - 1].level = 0;
  }
  if $type eq 'std' {
    $action .= new(level => 9, label => 'TIT02', val1 => $high.value, val2 => $low.value, val3 => $radix.Str);
    self.action.push($action);
    # set-up
    $action .= new(level => 5, label => 'WRI00', w1l => 0, w1c => $leng, w1val => $high.value);
    self.action.push($action);
    $action .= new(level => 5, label => 'WRI00', w1l => 1, w1c => $leng, w1val => $low.value);
    self.action.push($action);

    # computation
    my Str $result = '';
    $result = self!embedded-sub(basic-level => 0, l-hi => 0, c-hi => $leng, high => $high
                                                , l-lo => 1, c-lo => $leng, low  => $low
                                                , l-re => 2, c-re => $leng);
    self.action[* - 1].level = 0;
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $result);
  }
  else {
    $action .= new(level => 9, label => 'TIT15', val1 => $high.value, val2 => $low.value, val3 => $radix.Str);
    self.action.push($action);
    my Arithmetic::PaperAndPencil::Number $complement = $low.complement($leng);
    # set-up
    $action .= new(level => 5, label => 'SUB03', val1 => $radix.Str, val2 => $low.value, val3 => $complement.value
                                               , w1l => 0, w1c => $leng, w1val => $high.value
                                               , w2l => 1, w2c => $leng, w2val => $complement.value);
    self.action.push($action);
    $action .= new(level => 2, label => 'DRA02', w1l => 1, w1c => 1
                                               , w2l => 1, w2c => $leng);
    self.action.push($action);

    my @digits; # storing the numbers' digits
    my @result; # storing the result's digit positions
    my Str $compl-val = '0' x ($leng - $complement.chars) ~ $complement.value;
    for (0 ..^ $leng) -> $i {
      @digits[$i; 0] = %( lin => 0, col => $leng - $i, val => $high.value.substr($leng - $i - 1, 1));
      @digits[$i; 1] = %( lin => 1, col => $leng - $i, val => $compl-val .substr($leng - $i - 1, 1));
      @result[$i]    = %( lin => 2, col => $leng - $i);
    }
    my Str $result = self!adding(@digits, @result, 0, $radix).substr(1);
    # getting rid of leading zeroes except if the result is zero
    $result ~~ s/^ '0' * //;
    if $result eq '' {
      $result = '0';
    }
    $action .= new(level => 0, label => 'SUB04', val1 => $result, r1l => 2, r1c => 0, r1val => '1', r1str => True);
    self.action.push($action);
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $result);
  }
}

method multiplication(Arithmetic::PaperAndPencil::Number :$multiplicand
                    , Arithmetic::PaperAndPencil::Number :$multiplier
                    , Str :$type      = 'std'
                    , Str :$direction = 'ltr'   # for the 'boat' type, elementary products are processed left-to-right or right-to-left ('rtl')
                    , Str :$mult-and-add = 'separate'   # for the 'boat' type, addition is a separate subphase (contrary: 'combined')
                    , Str :$product      = 'L-shaped'   # for the 'jalousie-?" types, the product is L-shaped along the rectangle (contrary: 'straight' on the bottom line)
                    --> Arithmetic::PaperAndPencil::Number
                    ) {
  my Arithmetic::PaperAndPencil::Action $action;
  if $multiplicand.radix != $multiplier.radix {
    die "Multiplicand and multiplier have different bases: {$multiplicand.radix} != {$multiplier.radix}";
  }
  my Str $title = '';
  my Int $radix = $multiplicand.radix;
  given $type {
    when 'std'        { $title = 'TIT03' ; }
    when 'shortcut'   { $title = 'TIT04' ; }
    when 'prepared'   { $title = 'TIT05' ; }
    when 'jalousie-A' { $title = 'TIT06' ; }
    when 'jalousie-B' { $title = 'TIT07' ; }
    when 'boat'       { $title = 'TIT08' ; }
    when 'russian'    { $title = 'TIT19' ; }
  }
  if $title eq '' {
    die "Multiplication type '$type' unknown";
  }
  if $type eq 'jalousie-A' | 'jalousie-B' {
    if $product ne 'L-shaped' | 'straight' {
      die "Product shape '$product' should be 'L-shaped' or 'straight'";
    }
  }
  if $type eq 'boat' {
    if $direction ne 'ltr' | 'rtl' {
      die "Direction '$direction' should be 'ltr' (left-to-right) or 'rtl' (right-to-left)";
    }
    if $mult-and-add ne 'separate' | 'combined' {
      die "Parameter mult-and-add '$mult-and-add' should be 'separate' or 'combined'";
    }
  }

  my Int $len1 = $multiplicand.chars;
  my Int $len2 = $multiplier.chars;
  if @.action {
    self.action[* - 1].level = 0;
  }
  $action .= new(level => 9
               , label => $title
               , val1  => $multiplicand.value
               , val2  => $multiplier.value
               , val3  => $multiplier.radix.Str
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
      my Arithmetic::PaperAndPencil::Number $pdt;
      $pdt = %mult-cache{$multiplier.value};
      $action .= new(level => 0, label => 'WRI05', val1 => $pdt.value
                   , w1l => 2, w1c => $len1 + 1, w1val => $pdt.value
                   );
      self.action.push($action);
      return $pdt;
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
  if $type eq 'jalousie-A' | 'jalousie-B' {
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
  if $type eq 'jalousie-A' {
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
      if $c2 ≤ 0 && $product eq 'L-shaped' {
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
      my Arithmetic::PaperAndPencil::Number $x .= new(radix => $radix, value => $multiplier.value.substr($l - 1, 1));
      for 1 .. $len1 -> $c {
        my Arithmetic::PaperAndPencil::Number $y .= new(radix => $radix, value => $multiplicand.value.substr($c - 1, 1));
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
    my @final;
    my Int $limit;
    given $product {
      when 'L-shaped' { $limit = $len1;         }
      when 'straight' { $limit = $len1 + $len2; }
    }
    for 0 ..^ $limit -> $i {
      @final[$i] = %( lin => 2 × $len2 + 1, col => 2 × ($len1 - $i) - 1);
    }
    for $limit ..^ $len1 + $len2 -> $i {
      @final[$i] = %( lin => 2 × ($len1 + $len2 - $i), col => 0 );
    }
    my Str $result = self!adding(@partial, @final, 0, $radix);
    self.action[* - 1].level = 0;
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $result);
  }
  if $type eq 'jalousie-B' {
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
      if $c2 ≥ 2 × $len1 && $product eq 'L-shaped' {
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
      my Arithmetic::PaperAndPencil::Number $x .= new(radix => $radix, value => $multiplier.value.substr($len2 - $l, 1));
      for 1 .. $len1 -> $c {
        my Arithmetic::PaperAndPencil::Number $y .= new(radix => $radix, value => $multiplicand.value.substr($c - 1, 1));
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
    my @final;
    my Int $limit;
    given $product {
      when 'L-shaped' { $limit = $len2; }
      when 'straight' { $limit = 0;     }
    }
    for 0 ..^ $limit -> $i {
      @final[$i] = %( lin => 2 × $i + 2, col => 2 × $len1 + 1);
    }
    for $limit ..^ $len1 + $len2 -> $i {
      @final[$i] = %( lin => 2 × $len2 + 1, col => 2 × ($len1 + $len2 - $i) );
    }
    my Str $result = self!adding(@partial, @final, 0, $radix);
    self.action[* - 1].level = 0;
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $result);
  }
  if $type eq 'boat' {
    # set up phase
    my Int $tot-len = $len1 + $len2 - 1;
    $action .= new(level => 5, label => 'WRI00', w1l =>  0, w1c => $tot-len, w1val => $multiplicand.value);
    self.action.push($action);
    $action .= new(level => 5, label => 'DRA02', w1l => -1, w1c => 0, w2l => -1, w2c => $tot-len);
    self.action.push($action);
    $action .= new(level => 2, label => 'DRA02', w1l =>  0, w1c => 0, w2l =>  0, w2c => $tot-len);
    self.action.push($action);

    # arrays of line numbers per column
    my @lines-below = ( 1 ) xx ($len1 + $len2);
    my @lines-above = (-1 ) xx ($len1 + $len2);
    my @result      = ('0') xx ($len1 + $len2);

    # multiplication phase
    my @partial;
    for $len2 .. $tot-len -> $col {
      my Arithmetic::PaperAndPencil::Number $x .= new(radix => $radix, value => $multiplicand.value.substr($col - $len2, 1));
      # write the multiplier at the proper column
      self!push-below($multiplier, $col, @lines-below);

      # partial products
      my     $range = 1 .. $len2;
      my Int $last  = $len2;
      if $direction eq 'rtl' {
        $range = $range.reverse;
        $last  = 1;
      }
      for $range.list -> $c {
        my Arithmetic::PaperAndPencil::Number $y .= new(radix => $radix, value => $multiplier.value.substr($c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x ☈× $y;
        $action .= new(level => 6, label => 'MUL01', val1 => $y.value, r1l => @lines-below[$col - $len2 + $c] - 1, r1c => $col - $len2 + $c, r1val => $y.value, r1str => True
                                                   , val2 => $x.value, r2l => 0                                  , r2c => $col             , r2val => $x.value, r2str => ($c == $last)
                                                   , val3 => $pdt.value);
        self.action.push($action);
        if $mult-and-add eq 'separate' {
          self!push-above($pdt, $col - $len2 + $c, @lines-above, @partial, $tot-len);
        }
        else {
          self!add-above($pdt, $col - $len2 + $c, @lines-above, @result);
        }
        self.action[* - 1].level = 4;
      }
      self.action[* - 1].level = 3;
    }

    # addition phase
    my @final;
    my Str $result;
    if $mult-and-add eq 'separate' {
      for 0 ..^ @lines-above.elems -> $col {
        @final[ $col] = %( lin => @lines-above[$tot-len - $col], col => $tot-len - $col );
      }
      $result = self!adding(@partial, @final, 0, $radix, striking => True);
    }
    else {
       $result = @result.join;
    }
    self.action[* - 1].level = 0;
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $result);
  }
  if $type eq 'russian' {
    # set-up
    my Arithmetic::PaperAndPencil::Number $md = $multiplicand;
    my Arithmetic::PaperAndPencil::Number $mr = $multiplier;
    my Int $c-md = 2 × $len2 + 1 + $len1;
    my Int $c-mr = $len2;
    $action .= new(level => 3, label => 'WRI00', w1l => 0, w1c => $c-md, w1val => $md.value
                                               , w2l => 0, w2c => $c-mr, w2val => $mr.value);
    self.action.push($action);

    # first phase, doubling the multiplicand and halving the multiplier
    my Int $l = 0;
    my @lines = ();
    @lines.push( { mr => $mr, md => $md });
    while $mr.value ne '1' {
      $mr = self!halving( l1 => $l, c1 => $c-mr, l2 => $l + 1, c2 => $c-mr, number => $mr);
      $md = self!doubling(l1 => $l, c1 => $c-md, l2 => $l + 1, c2 => $c-md, number => $md);
      @lines.push( { mr => $mr, md => $md });
      $l++;
    }
    self.action[* - 1].level = 2;

    # second phase, testing even numbers and striking
    my @partial;
    my @final;
    for @lines.kv -> $l, $line {
      $mr = $line<mr>;
      $md = $line<md>;
      if $mr.is-odd {
        for $md.value.flip.comb.kv -> $i, $x {
          push @partial[$i], %( lin => $l, col => $c-md - $i, val => $x );
        }
      }
      else {
        $action .= new(level => 4, label => 'MUL03', val1 => $mr.value, r1l => $l, r1c => $c-mr, r1val => $mr.value
                                                   , val2 => $md.value, r2l => $l, r2c => $c-md, r2val => $md.value, r2str => True);
        self.action.push($action);
      }
      if $mr.value eq '1' {
        for $md.value.flip.comb.kv -> $i, $x {
          @final[$i] = %( lin => @lines.elems, col => $c-md - $i );
        }
        $action .= new(level => 2, label => 'DRA02'
                     , w1l => $l, w1c => $c-md + 1 - $md.chars
                     , w2l => $l, w2c => $c-md);
        self.action.push($action);
      }
    }
    self.action[* - 1].level = 2;

    # third phase, adding
    my Str $result = self!adding(@partial, @final, 0, $radix);
    self.action[* - 1].level = 0;

    return  Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($result));
  }
}

method division(Arithmetic::PaperAndPencil::Number :$dividend
              , Arithmetic::PaperAndPencil::Number :$divisor
              , Str :$type   = 'std'
              , Str :$result = 'quotient'
              , Str :$mult-and-sub is copy = 'combined'
              ) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $dividend.radix;
  if $radix != $divisor.radix {
    die "Dividend and divisor have different bases: {$radix} != {$divisor.radix}";
  }
  if $divisor.value eq '0' {
    die "Division by zero is impossible";
  }

  if @.action {
    self.action[* - 1].level = 0;
  }
  my Int $len1  = $dividend.chars;
  my Int $len2  = $divisor .chars;
  my Int $bot   = 2;
  my Str $title = '';
  given $type {
    when 'std'      { $title = 'TIT09' ; }
    when 'cheating' { $title = 'TIT10' ; }
    when 'prepared' { $title = 'TIT11' ; $mult-and-sub = 'separate' }
    when 'boat'     { $title = 'TIT12' ; }
  }
  if $title eq '' {
    die "Division type '$type' unknown";
  }
  if $result ne 'quotient' | 'remainder' | 'both' {
    die "Result type '$result' unknown";
  }
  if $mult-and-sub ne 'combined' | 'separate' {
    die "Mult and sub type '$mult-and-sub' unknown";
  }
  $action .= new(level => 9
               , label => $title
               , val1  => $dividend.value
               , val2  => $divisor.value
               , val3  => $radix.Str
               );
  self.action.push($action);

  # Divisions with obvious results
  my $zero = Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value<0>);
  my $one  = Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value<1>);
  if $divisor.value eq '1' {
    $action .= new(level => 0, label => 'DIV05', val1 => $dividend.value, w1l => 1, w1c => 0, w1val => $dividend.value);
    self.action.push($action);
    given $result {
      when 'quotient'  { return $dividend; }
      when 'remainder' { return $zero; }
      when 'both'      { return ($dividend, $zero); }
    }
  }
  if $dividend ☈< $divisor {
    $action .= new(level => 0, label => 'DIV06', val1 => $dividend.value, val2 => $divisor.value
                 , w1l => 1, w1c => 0, w1val => '0');
    self.action.push($action);
    given $result {
      when 'quotient'  { return $zero; }
      when 'remainder' { return $dividend; }
      when 'both'      { return ($zero, $dividend); }
    }
  }

  # caching the partial products for prepared, cheating and boat divisions
  my %div-cache = 0 => $zero, 1 => $divisor;
  if $type eq 'prepared' {
    self!preparation(factor => $divisor, limit => 'Z', cache => %div-cache);
    # the actual limit will be '9' for radix 10, 'F' for radix 16, etc. But 'Z' will give the same result
  }
  if $type eq 'cheating' | 'boat' {
    my Arithmetic::PaperAndPencil $dummy .= new;
    $dummy!preparation(factor => $divisor, limit => 'Z', cache => %div-cache);
  }

  # setup
  my Int $delta = $len2 - 1; # how long we must shorten the divisor and the partial dividend to compute the quotient first candidate
  my Int $lin-d = 0;         # line   for the successive partial dividends
  my Int $col-q = $len1 + 1; # column for the successive single-digit partial quotients
  my Int $col-r = $len2;     # column for the successive partial dividends and remainders
  my Int $len-dvd1 = 1;      # length of the part of the dividend used to compute the first candidate digit
  # yes, string comparison or left-aligned comparison, to know if we need a short hook or a long hook
  if $dividend ☈lt $divisor {
    $col-r++;
    $len-dvd1++;
  }

  # computation
  if $type eq 'std' | 'cheating' | 'prepared' {
    $action .= new(level => 5, label => 'WRI00', w1l => 0, w1c => $len1        , w1val => $dividend.value);
    self.action.push($action);
    $action .= new(level => 5, label => 'DRA02', w1l => 0, w1c => $len1 + 1
                                               , w2l => 0, w2c => $len1 + $len2);
    self.action.push($action);
    my Arithmetic::PaperAndPencil::Number $quotient;
    my Arithmetic::PaperAndPencil::Number $rem;
    ($quotient, $rem) = self!embedded-div(l-dd => 0, c-dd => $len1        , dividend => $dividend
                                        , l-dr => 0, c-dr => $len1 + $len2, divisor  => $divisor
                                        , l-qu => 1, c-qu => $len1 + 1
                                        , basic-level => 0, type => $type, mult-and-sub => $mult-and-sub, mult-cache => %div-cache
                                        , stand-alone => True
                                        );
    self.action[* - 1].level = 0;
    given $result {
      when 'quotient'  { return   $quotient; }
      when 'remainder' { return   $rem; }
      when 'both'      { return ( $quotient, $rem); }
    }
  }
  if $type eq 'boat' {
    $action .= new(level => 6, label => 'WRI00', w1l => 0, w1c => $len1 + 1, w1val => $dividend.value ~ '{');
    self.action.push($action);
    $action .= new(level => 6, label => 'DRA02', w1l => 0, w1c => 1
                                               , w2l => 0, w2c => $len1);
    self.action.push($action);

    # arrays of line numbers per column
    my @lines-below = ( 1) xx ($len1 + 1);
    my @lines-above = (-1) xx ($len1 + 1);
    self!push-below($divisor, $col-r, @lines-below);

    $col-q++;
    my Str $quotient = '';
    my Str $rem      = '';
    my Arithmetic::PaperAndPencil::Number $part-dvr1 = $divisor.carry($delta); # single-digit divisor to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $part-dvd .= new(:radix($radix), :value($dividend.value.substr(0, $col-r)));

    while $col-r ≤ $len1 {
      my Arithmetic::PaperAndPencil::Number $part-dvd1 = $part-dvd.carry($delta);  # single-digit dividend or 2-digit dividend to compute the quotient first candidate
      my Arithmetic::PaperAndPencil::Number $theo-quo  = $part-dvd1 ☈÷ $part-dvr1; # theoretical quotient first candidate
      my Arithmetic::PaperAndPencil::Number $act-quo;                              # actual quotient first candidate
      $rem = '';
      my Str $label;
      if $part-dvd ☈< $divisor {
        $theo-quo = $zero;
        $act-quo  = $zero;
      }
      else {
        $act-quo .= new(radix => $radix, value => %div-cache.keys.grep(-> $x { %div-cache{$x} ☈≤ $part-dvd }).max);
        $label = 'DIV03';
      }
      if $theo-quo.value eq '0' {
        # cannot flag $part-dvd and $divisor as read, because there are not on a single line.
        $action .= new(level => 5, label => 'DIV01', val1 => $part-dvd.value
                                                   , val2 => $divisor .value
                                                   , val3 => '0', w1l => 0, w1c => $col-q, w1val => '0');
        self.action.push($action);
        # striking the useless divisor
        for 0 ..^ $len2 -> $i {
          $action .= new(level => 6, label => 'WRI00', r1l => @lines-below[$col-r - $i] - 1, r1c => $col-r - $i, r1val => $divisor.value.substr(* -$i - 1, 1), r1str => True);
          self.action.push($action);
        }
        $rem = $part-dvd.value;
        $quotient ~= '0';
        ++$col-q;
        ++$col-r;
        if  $col-r ≤ $len1 {
          self!push-below($divisor, $col-r, @lines-below);
        }
        $part-dvd = Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($rem ~ $dividend.value.substr($col-r - 1, 1)));
        next;
      }
      elsif $theo-quo.value eq $act-quo.value {
        # cannot flag $part-dvd and $divisor as read, because there are not on a single line.
        $action .= new(level => 5, label => 'DIV01', val1 => $part-dvd1.value
                                                   , val2 => $part-dvr1.value
                                                   , val3 => $theo-quo .value, w1l => 0, w1c => $col-q, w1val => $act-quo.value);
        self.action.push($action);
      }
      else {
        # cannot flag $part-dvd and $divisor as read, because there are not on a single line.
        $action .= new(level => 6, label => 'DIV01', val1 => $part-dvd1.value, val2 => $part-dvr1.value, val3 => $theo-quo.value);
        self.action.push($action);
        $action .= new(level => 5, label => $label, val1 => $act-quo.value, w1l => 0, w1c => $col-q, w1val => $act-quo.value);
        self.action.push($action);
      }
      my Str $carry = '0';
      for 0 ..^ $divisor.chars -> $i {
        my Str $divisor-digit = $divisor.value.substr(* - $i - 1, 1);
        my Arithmetic::PaperAndPencil::Number $temp .= new(radix => $radix, value => $divisor-digit);
        $temp ☈×= $act-quo;
        $action .= new(level => 6                            , label => 'MUL01'                                            , val3 => $temp.value
                     , r1l   => 1                            , r1c   => $col-q     , r1val => $act-quo.value               , val1 => $act-quo.value
                     , r2l   => @lines-below[$col-r - $i] - 1, r2c   => $col-r - $i, r2val => $divisor-digit, r2str => True, val2 => $divisor-digit
                     );
        self.action.push($action);
        if $carry ne '0' {
          $temp ☈+= Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $carry);
          $action .= new(level => 6, label => 'ADD02', val1 => $carry, val2 => $temp.value);
          self.action.push($action);
        }
        my Arithmetic::PaperAndPencil::Number $dividend-digit .= new(radix => $radix, value => $part-dvd.value.substr(* - $i - 1, 1));
        my Arithmetic::PaperAndPencil::Number $adjusted-dividend;
        my Arithmetic::PaperAndPencil::Number $rem-digit;
        ($adjusted-dividend, $rem-digit) = adjust-sub($dividend-digit, $temp);
        if $i == $divisor.chars - 1 {
          $action .= new(level => 6, label => 'SUB02', val1  => $rem-digit.value, val2 => $adjusted-dividend.value
                     , r1l => @lines-above[$col-r - $i] + 1, r1c => $col-r - $i, r1val => $adjusted-dividend.value, r1str => True
                     );
          self.action.push($action);
          $action .= new(level => 6, label => 'WRI04'                            , val1  => $rem-digit.value
                       , w1l   => @lines-above[$col-r - $i]--, w1c => $col-r - $i, w1val => $rem-digit.value
                       );
          self.action.push($action);
          $rem   = $rem-digit.value ~ $rem;
        }
        else {
          $action .= new(level => 6, label => 'SUB02', val1  => $rem-digit.value   , val2  => $adjusted-dividend.value
                       , r1l   => @lines-above[$col-r - $i] + 1, r1c => $col-r - $i, r1val => $adjusted-dividend.value, r1str => True
                       );
          self.action.push($action);
          my Str $label = 'WRI02';
          if $adjusted-dividend.carry.value eq '0' {
            $label = 'WRI03';
          }
          $action .= new(level => 6, label => $label                             , val1  => $rem-digit.value, val2 => $adjusted-dividend.carry.value
                       , w1l   => @lines-above[$col-r - $i]--, w1c => $col-r - $i, w1val => $rem-digit.value
                       );
          self.action.push($action);
          $rem   = $rem-digit.value ~ $rem;
          $carry = $adjusted-dividend.carry.value;
        }
      }
      self.action[* - 1].level = 4;
      $quotient ~= $act-quo.value;
      ++$col-q;
      ++$col-r;
      if  $col-r ≤ $len1 {
        self!push-below($divisor, $col-r, @lines-below);
      }
      $part-dvd = Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($rem ~ $dividend.value.substr($col-r - 1, 1)));
    }

    self.action[* - 1].level = 0;
    given $result {
      when 'quotient'  { return   Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($quotient)); }
      when 'remainder' { return   Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($rem)); }
      when 'both'      { return ( Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($quotient))
                                , Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($rem))); }
    }
  }

}

method square-root(Arithmetic::PaperAndPencil::Number $number
                 , Str :$mult-and-sub is copy = 'combined'
                 --> Arithmetic::PaperAndPencil::Number
                   ) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $number.radix;

  $action .= new(level => 9, label => "TIT13", val1 => $number.value, val2 => $radix.Str);
  self.action.push($action);

  # set-up
  my Int $nb-dig = ($number.chars / 2).ceiling; # number of digits of the square root
  $action .= new(level => 6, label => 'WRI00', w1l => 0, w1c => 0, w1val => $number.value);
  self.action.push($action);
  $action .= new(level => 6, label => 'DRA01', w1l => 0, w1c => 0, w2l => 2, w2c => 0);
  self.action.push($action);
  $action .= new(level => 6, label => 'DRA02', w1l => 0, w1c => 1, w2l => 0, w2c => $nb-dig);
  self.action.push($action);
  $action .= new(level => 2, label => 'WRI00', w1l => 0, w1c => $nb-dig, w1val => '.' x $nb-dig);
  self.action.push($action);

  # first phase, square root proper
  my Int $col-first;
  my Str $remainder = '';
  my Arithmetic::PaperAndPencil::Number $partial-number = $number.carry(2 × ($nb-dig - 1));
  my Arithmetic::PaperAndPencil::Number $partial-root   = $partial-number.square-root;
  my Str $root = $partial-root.value;
  $action .= new(level => 5, label => 'SQR01'        , val1  => $partial-number.value, val2 => $root
                , r1l => 0, r1c => -2 × ($nb-dig - 1), r1val => $partial-number.value
                , w1l => 0, w1c => 1                 , w1val => $root
                );
  self.action.push($action);
  my Arithmetic::PaperAndPencil::Number $partial-square = $partial-root ☈× $partial-root;
  if $mult-and-sub eq 'combined' {
    $action .= new(level => 5, label => 'MUL01', val1 => $root, val2 => $root, val3 => $partial-square.value);
    self.action.push($action);
    my ($x, $y) = adjust-sub($partial-number.unit, $partial-square);
    $action .= new(level => 5, label => 'SUB02', val1 => $y.value
                                               , val2 => $x.value
                  );
    self.action.push($action);
    if $x.carry.value eq '0' {
      $action .= new(level => 5, label => 'WRI03'           , val1  => $y.value
                   , w1l   => 1, w1c   => -2 × ($nb-dig - 1), w1val => $y.value
                    );
      self.action.push($action);
      $remainder = $y.value;
    }
    else {
      $action .= new(level => 5, label => 'WRI02'           , val1  => $y.value, val2 => $x.carry.value
                   , w1l   => 1, w1c   => -2 × ($nb-dig - 1), w1val => $y.value
                    );
      self.action.push($action);
      my ($z, $t) = adjust-sub($partial-number.carry, $x.carry);
      $action .= new(level => 5, label => 'SUB01', val1 => $x.carry.value, val2 => $t.value, val3 => $z.value
                   , w1l   => 1, w1c   => -2 × $nb-dig + 1              , w1val => $t.value
                    );
      self.action.push($action);
      $remainder = $t.value ~ $y.value;
    }
  }
  else {
    $action .= new(level => 5, label => 'MUL01', val1 => $root, val2 => $root, val3 => $partial-square.value, w1l => 1, w1c => -2 × ($nb-dig - 1), w1val => $partial-square.value);
    self.action.push($action);
    $remainder = self!embedded-sub(basic-level => 0, l-hi => 0, c-hi => -2 × ($nb-dig - 1), high => $partial-number
                                                   , l-lo => 1, c-lo => -2 × ($nb-dig - 1), low  => $partial-square
                                                   , l-re => 2, c-re => -2 × ($nb-dig - 1));
  }
  my Arithmetic::PaperAndPencil::Number $divisor = $partial-root ☈+ $partial-root;
  $col-first = $divisor.chars;
  $action .= new(level => 3, label => 'ADD01'   , val1  => $partial-root.value, val2 => $partial-root.value, val3 => $divisor.value
                , r1l  => 0, r1c   => 1         , r1val => $partial-root.value
                , w1l  => 1, w1c   => $col-first, w1val => $divisor.value
                );
  self.action.push($action);

  my Arithmetic::PaperAndPencil::Number $zero     .= new(:radix($radix), :value<0>);
  my Arithmetic::PaperAndPencil::Number $one      .= new(:radix($radix), :value<1>);
  my Arithmetic::PaperAndPencil::Number $divisor1;

  # next phase, division
  my Int $bot      = 2; # bottom line number of the vertical line
  my Int $line-rem = 1; # line number of the partial remainder or partial dividend
  my Int $line-div = 1; # line number of the divisor
  if $mult-and-sub eq 'separate' {
    $line-rem = 2;
  }
  for 1 ..^ $nb-dig -> $i {
    my Int $pos = 2 × ($nb-dig - $i);
    my Str $two-digits = $number.value.substr(* - $pos, 2);
    $action .= new(level => 3        , label => 'DIV04'   , val1  => $two-digits
                  , r1l  => 0        , r1c   => 2 - $pos  , r1val => $two-digits
                  , w1l  => $line-rem, w1c   => 2 - $pos  , w1val => $two-digits
                  );
    self.action.push($action);
    $remainder ~= $two-digits;

    $partial-number .= new(radix => $radix, value => $remainder);
    my Arithmetic::PaperAndPencil::Number $part-dvr1 = $divisor.carry($divisor.chars - 1); # single-digit divisor to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $part-dvd1 = $partial-number.carry($i + $col-first - 1); # single-digit dividend or 2-digit dividend to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $theo-quo = $part-dvd1 ☈÷ $part-dvr1; # theoretical quotient first candidate
    my Arithmetic::PaperAndPencil::Number $act-quo;                             # actual quotient first candidate and then all successive candidates
    my Str $label;
    if $partial-number ☈≤ $divisor {
      $theo-quo = $zero;
      $act-quo  = $zero;
      $divisor1 .= new(radix => $radix, value => $divisor.value ~ '0');
    }
    elsif $theo-quo.chars == 2 {
      $act-quo  = max-unit($radix);
      $label = 'DIV02';
    }
    else {
      $act-quo  = $theo-quo;
    }
    my Bool $too-much = True; # we must loop with the next lower candidate
    if $theo-quo.value eq '0' {
      $action .= new(level => 5, label => 'DIV01', val1 => $part-dvd1.value, r1l => $line-rem, r1c => - $pos         , r1val => $part-dvd1.value
                                                 , val2 => $part-dvr1.value, r2l => $line-div, r2c => 0              , r2val => $part-dvr1.value
                                                 , val3 => '0'             , w1l => $line-div, w1c => $i + $col-first, w1val => '0');
      self.action.push($action);
      $too-much = False; # no need to loop on candidate values, no need to execute the mult-and-sub routine
      $remainder = $partial-number.value;
    }
    elsif $theo-quo.value eq $act-quo.value {
      $action .= new(level => 5, label => 'DIV01', val1 => $part-dvd1.value, r1l => $line-rem    , r1c => - $pos         , r1val => $part-dvd1.value
                                                 , val2 => $part-dvr1.value, r2l => $line-div    , r2c => 0              , r2val => $part-dvr1.value
                                                 , val3 => $theo-quo .value, w1l => $line-div    , w1c => $i + $col-first, w1val => $act-quo.value
                                                                           , w2l => $line-div + 1, w2c => $i + $col-first, w2val => $act-quo.value);
      self.action.push($action);
    }
    else {
      $action .= new(level => 6, label => 'DIV01', val1 => $part-dvd1.value, val2 => $part-dvr1.value, val3  => $theo-quo.value
                                                 , r1l  => $line-rem       , r1c  => - $pos          , r1val => $part-dvd1.value
                                                 , r2l  => $line-div       , r2c  => 0               , r2val => $part-dvr1.value);
      self.action.push($action);
      $action .= new(level => 5, label => $label, val1 => $act-quo.value, w1l => $line-div    , w1c => $i + $col-first, w1val => $act-quo.value
                                                                        , w2l => $line-div + 1, w2c => $i + $col-first, w2val => $act-quo.value);
      self.action.push($action);
    }
    my Str $rem;
    my Int $l-re;
    while $too-much {
      if $mult-and-sub eq 'separate' {
        $l-re = $line-rem + 2;
      }
      else {
        $l-re = $line-rem + 1;
      }
      if $bot < $l-re {
        $bot = $l-re;
        $action .= new(level => 5, label => 'DRA01', w1l => 0   , w1c => 0
                                                   , w2l => $bot, w2c => 0);
        self.action.push($action);
      }
      $divisor1 .= new(radix => $radix, value => $divisor.value ~ $act-quo.value);
      ($too-much, $rem) = self!mult-and-sub(l-dd => $line-rem    , c-dd => 2 - 2 × ($nb-dig - $i), dividend => $partial-number
                                          , l-dr => $line-div    , c-dr => $i + $col-first       , divisor  => $divisor1
                                          , l-qu => $line-div + 1, c-qu => $i + $col-first       , quotient => $act-quo
                                          , l-re => $l-re        , c-re => 2 - 2 × ($nb-dig - $i), basic-level => 0
                                          , l-pr => $line-rem + 1, c-pr => 2 - 2 × ($nb-dig - $i), mult-and-sub => $mult-and-sub);
      if $too-much {
        self.action[* - 1].level = 4;
        $act-quo ☈-= $one;
        $action .= new(level => 5, label => 'ERA01', w1l => $line-rem + 1, w1c => 0, w2l => $line-rem + 1, w2c => 1 - $number.chars);
        self.action.push($action);
        $action .= new(level => 4, label => 'DIV02', val1 => $act-quo.value, w1l => $line-div    , w1c => $i + $col-first, w1val => $act-quo.value
                                                                           , w2l => $line-div + 1, w2c => $i + $col-first, w2val => $act-quo.value);
        self.action.push($action);
      }
    }
    self.action[* - 1].level = 4;

    $action .= new(level => 5, label => 'WRI04', val1 => $act-quo.value, w1l => 0, w1c => $i + 1, w1val => $act-quo.value);
    self.action.push($action);
    $root ~= $act-quo.value;

    $divisor = $divisor1 ☈+ $act-quo;
    if $act-quo.value eq '0' {
      $action .= new(level => 3, label => 'ERA01', w1l => $line-div + 1, w1c => $i + $col-first, w2l => $line-div + 1, w2c => $i + $col-first);
      self.action.push($action);
    }
    elsif $i < $nb-dig - 1 {
      $remainder = $rem;
      $line-rem = $l-re;
      if $bot < $line-div + 3 {
        $bot = $line-div + 3;
      }
      $action .= new(level => 6, label => 'DRA01', w1l => 0, w1c => 0, w2l => $bot, w2c => 0);
      self.action.push($action);
      $action .= new(level => 6, label => 'DRA02', w1l => $line-div + 1, w1c => 1, w2l => $line-div + 1, w2c => $divisor.chars);
      self.action.push($action);
      $action .= new(level => 3, label => 'ADD01', r1l => $line-div    , r1c => $i + $col-first, r1val => $divisor1.value, val1 => $divisor1.value
                                                 , r2l => $line-div + 1, r2c => $i + $col-first, r2val => $act-quo.value , val2 => $act-quo.value
                                                 , w1l => $line-div + 2, w1c => $i + $col-first, w1val => $divisor.value , val3 => $divisor.value);
      self.action.push($action);
      $line-div += 2;
    }
  }

  self.action[* - 1].level = 0;
  return Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($root));
}

method conversion(Arithmetic::PaperAndPencil::Number :$number is copy
                , Int :$radix
                , Int :$nb-op    = 0
                , Str :$type     = 'mult'
                , Str :$div-type = 'std'
                , Str :$mult-and-sub is copy = 'combined'
                --> Arithmetic::PaperAndPencil::Number
                ) {
  unless 2 ≤ $radix ≤ 36 {
    die "Radix should be between 2 and 36, instead of $radix";
  }
  my Str $title = '';
  given $type {
    when 'mult'   { $title = 'TIT14' ; }
    when 'Horner' { $title = 'TIT14' ; }
    when 'div'    { $title = 'TIT16' ; }
    default       { die "Conversion type '$type' unknown, should be 'mult', 'Horner' or 'div'"; }
  }
  if $type eq 'div' and $div-type ne 'std' | 'cheating' | 'prepared' {
    die "Division type '$div-type' unknown, should be 'std', 'cheating' or 'prepared'";
  }
  if $type eq 'div' and $mult-and-sub ne 'combined' | 'separate' {
    die "Mult and sub type '$mult-and-sub' unknown, should be 'combined' or 'separate'";
  }
  if $type eq 'div' and $div-type eq 'std' {
    $mult-and-sub = 'combined';
  }
  if $type eq 'div' and $div-type eq 'prepared' {
    $mult-and-sub = 'separate';
  }
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $old-radix = $number.radix;

  $action .= new(level => 9, label => $title, val1 => $number.value, val2 => $old-radix.Str, val3 => $radix.Str);
  self.action.push($action);

  if $radix == $old-radix or ($number.chars == 1 && $old-radix ≤ $radix) {
    $action .= new(level => 0, label => "CNV01", val1 => $number.value, val2 => $old-radix.Str, val3 => $radix.Str);
    self.action.push($action);
    return $number;
  }
  my %conv-cache;
  my Arithmetic::PaperAndPencil::Number $new-radix;
  my Arithmetic::PaperAndPencil::Number $zero .= new(:radix($old-radix), :value<0>);
  my %mult-cache;
  if $type eq 'mult' | 'Horner' {
    self!prep-conv($old-radix, $radix, %conv-cache, basic-level => 2);
  }
  else {
    %mult-cache = 0 => $zero, 1 => $new-radix;
    my %tmp-cache;
    self!prep-conv($radix, $old-radix, %tmp-cache, basic-level => 2);
    $new-radix = %tmp-cache<10>;
    for %tmp-cache.kv -> $new, $old {
      %conv-cache{$old.value} = $new;
    }
    if $div-type eq 'prepared' {
      my %tmp-cache;
      self!preparation(factor => $new-radix, limit => 'Z', cache => %mult-cache, basic-level => 2);
      self.action[* - 2].level = 1; # * - 2 to update the action **before** action NXP01
      # the actual limit will be '9' for radix 10, 'F' for radix 16, etc. But 'Z' will give the same result
    }
    if $div-type eq 'cheating' {
      my Arithmetic::PaperAndPencil $dummy .= new;
      $dummy!preparation(factor => $new-radix, limit => 'Z', cache => %mult-cache);
    }
  }

  my Arithmetic::PaperAndPencil::Number $result;
  if $type eq 'mult' | 'Horner' {
    my Str $old-digit = $number.value.substr(0,1);
    $result = %conv-cache{$old-digit};
    my Int $line   = 1;
    my Int $op     = 0;
    my Int $width  = %conv-cache<10>.chars;
    $action .= new(level => 3, label => "CNV02", val1 => $old-digit, val2 => $result.value
                                          , w1l => $line, w1c => 0, w1val => $result.value);
    self.action.push($action);
    for $number.value.substr(1).comb.kv -> $op1, $old-digit {
      # multiplication
      my Int $pos-sign =  %conv-cache<10>.chars max $result.chars;
      ++$line;
      $action .= new(level => 9, label => 'WRI00', w1l => $line, w1c => 0              , w1val => %conv-cache<10>.value
                                                 , w2l => $line, w2c => - $pos-sign - 1, w2val => '×');
      self.action.push($action);
      $action .= new(level => 5, label => 'DRA02', w1l => $line, w1c => 0, w2l => $line, w2c => - $width);
      self.action.push($action);
      if %conv-cache<10>.chars == 1 {
        $result = self!simple-mult(basic-level => 2
                                , l-md => $line - 1, c-md => 0, multiplicand => $result
                                , l-mr => $line    , c-mr => 0, multiplier   => %conv-cache<10>
                                , l-pd => $line + 1, c-pd => 0);
        $line++;
      }
      else {
        my %dummy-cache;
        $result = self!adv-mult(basic-level => 2
                                , l-md => $line - 1, c-md => 0, multiplicand => $result
                                , l-mr => $line    , c-mr => 0, multiplier   => %conv-cache<10>
                                , l-pd => $line + 1, c-pd => 0, cache        => %dummy-cache);
        $line += %conv-cache<10>.chars + 1;
      }
      if $width ≤ $result.chars {
        $width = $result.chars;
      }
      # addition
      my $added = %conv-cache{$old-digit};
      if $added.value eq '0' {
        $action .= new(level => 9, label => "CNV02", val1 => '0', val2  => '0');
        self.action.push($action);
      }
      else {
        $pos-sign =  %conv-cache<10>.chars max $width;
        ++$line;
        $action .= new(level => 9, label => "CNV02"       , val1 => $old-digit    , val2  => $added.value
                                            , w1l => $line, w1c => 0              , w1val => $added.value
                                            , w2l => $line, w2c => - $pos-sign - 1, w2val => '+');
        self.action.push($action);
        $action .= new(level => 5, label => 'DRA02', w1l =>   $line, w1c => 0, w2l => $line, w2c => - $width);
        self.action.push($action);
        my @added;
        my @total;
        for $result.value.flip.comb.kv -> $i, $digit {
          @added[$i][0] = %( lin => $line - 1, col => - $i, val => $digit);
          @total[$i]    = %( lin => $line + 1, col => - $i);
        }
        for $added.value.flip.comb.kv -> $i, $digit {
          @added[$i][1] = %( lin => $line    , col => - $i, val => $digit);
          @total[$i]    = %( lin => $line + 1, col => - $i);
        }
        $result .= new(radix => $radix, value => self!adding(@added, @total, 2, $radix));
        $line++;
      }
      self.action[* - 1].level = 3;
      # next step
      $op++;
      if $op == $nb-op && $op1 != $number.chars - 2 {
        # testing - 2 because of (a) the substr(1) method which has shortened the number, and (b) zero-based numbering in the .kv method
        self.action[* - 1].level = 1;
        $action .= new(level => 9, label => 'NXP01');
        self.action.push($action);
        $action .= new(level => 9, label => 'CNV03', val1 => $result.value, val2 => $number.value.substr($op1 + 2)
                              , w1l => 1, w1c => 0, w1val => $result.value);
        self.action.push($action);
        $op = 0;
        $line = 1;
      }
      if $width ≤ $result.chars {
        $width = $result.chars;
      }
    }
  }
  else {
    my Int $op   = 0;
    my Int $l-dd = 1;
    my Int $c-dd = 0;
    my Str $res  = '';
    $action .= new(level => 9, label => 'WRI00', w1l => $l-dd, w1c => $c-dd, w1val => $number.value);
    self.action.push($action);
    my Arithmetic::PaperAndPencil::Number $x;
    my Arithmetic::PaperAndPencil::Number $y;
    while $new-radix ☈≤ $number {
      $action .= new(level => 9, label => 'DRA02', w1l => $l-dd, w1c => $c-dd + 1
                                                 , w2l => $l-dd, w2c => $c-dd + $new-radix.chars);
      self.action.push($action);
      ($x, $y) = self!embedded-div(l-dd => $l-dd    , c-dd => $c-dd                   , dividend => $number
                                 , l-dr => $l-dd    , c-dr => $c-dd + $new-radix.chars, divisor  => $new-radix
                                 , l-qu => $l-dd + 1, c-qu => $c-dd + 1
                                 , basic-level => 3, type => $div-type, mult-and-sub => $mult-and-sub
                                 , mult-cache => %mult-cache);
      self.action[* - 1].level = 3;
      $res = %conv-cache{$y.value} ~ $res;
      $number = $x;
      $op++;
      $l-dd++;
      $c-dd += $number.chars;
      my Str $rewrite-dd = '';
      if $op == $nb-op && $new-radix ☈≤ $number {
        self.action[* - 1].level = 1;
        $action .= new(level => 9, label => 'NXP01');
        self.action.push($action);
        $op   = 0;
        $l-dd = 1;
        $c-dd = 0;
        $rewrite-dd = $number.value;
      }
      if $new-radix ☈≤ $number {
        $action .= new(level => 9, label => 'CNV03', val1 => $res, val2 => $number.value, w1l => $l-dd, w1c => $c-dd, w1val => $rewrite-dd);
        self.action.push($action);
      }
    }
    $res = %conv-cache{$number.value} ~ $res;
    $action .= new(level => 0, label => 'CNV03', val1 => $res, val2 => '0');
    self.action.push($action);
    $result .= new(value => $res, radix => $radix);
  }

  self.action[* - 1].level = 0;
  return $result;
}

method gcd(Arithmetic::PaperAndPencil::Number :$first  is copy
         , Arithmetic::PaperAndPencil::Number :$second is copy
         , Str :$div-type = 'std'
         --> Arithmetic::PaperAndPencil::Number
                 ) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $first.radix;
  if $second.radix != $radix {
    die "The two numbers have different bases: $radix != {$second.radix}";
  }
  if @.action {
    self.action[* - 1].level = 0;
  }
  if $first ☈< $second {
    ($first, $second) = ($second, $first);
  }
  my Str $title = '';
  given $div-type {
    when 'std'      { $title = 'TIT17' ; }
    when 'cheating' { $title = 'TIT18' ; }
  }
  if $title eq '' {
    die "Division type '$div-type' unknown";
  }
  $action .= new(level => 9
               , label => $title
               , val1  => $first.value
               , val2  => $second.value
               , val3  => $radix.Str
               );
  self.action.push($action);
  my Arithmetic::PaperAndPencil::Number $quo;
  my Arithmetic::PaperAndPencil::Number $rem;
  my %mult-cache;

  # set-up
  my Int $len2 = $second.chars;
  my Int $l-dd = 0;
  my Int $c-dd = 0;
  my Int $l-dr = 0;
  my Int $c-dr = $len2;
  my Int $l-qu = -1;
  my Int $c-qu =  1;
  $action .= new(level => 9, label => 'WRI00', w1l => $l-dd, w1c => $c-dd, w1val => $first.value);
  self.action.push($action);

  # computation
  while $second.value ne '0' {
    if $div-type eq 'cheating' {
      my Arithmetic::PaperAndPencil $dummy .= new;
      $dummy!preparation(factor => $second, limit => 'Z', cache => %mult-cache);
    }
    $action .= new(level => 9, label => 'DRA02', w1l => $l-qu, w1c => $c-dr - $len2 + 1
                                               , w2l => $l-qu, w2c => $c-dr);
    self.action.push($action);
    ($quo, $rem) = self!embedded-div(l-dd => $l-dd, c-dd => $c-dd, dividend => $first
                                   , l-dr => $l-dr, c-dr => $c-dr, divisor  => $second
                                   , l-qu => $l-qu, c-qu => $c-qu
                                   , basic-level => 3, type => $div-type, mult-and-sub => 'combined'
                                   , mult-cache => %mult-cache);
    self.action[* - 1].level = 3;
    $first  = $second;
    $second = $rem;
    $len2   = $rem.chars;
    $c-dd   = $c-dr;
    $c-qu  += max($quo.chars, $first.chars);
    $c-dr   = $c-qu + $len2 - 1;
  }
  self.action[* - 1].level = 0;
  return $first;
}

method !adv-mult(Int :$basic-level, Str :$type = 'std'
               , Int :$l-md, Int :$c-md # coordinates of the multiplicand
               , Int :$l-mr, Int :$c-mr # coordinates of the multiplier
               , Int :$l-pd, Int :$c-pd # coordinates of the product
               , Arithmetic::PaperAndPencil::Number :$multiplicand
               , Arithmetic::PaperAndPencil::Number :$multiplier
               , :%cache
               --> Arithmetic::PaperAndPencil::Number) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Str $result = '';
  my Int $radix = $multiplier.radix;
  my Int $line  = $l-pd;
  my Int $pos   = $multiplier.chars - 1;
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
    my Arithmetic::PaperAndPencil::Number $mul .= new(radix => $radix, value => $multiplier.value.substr($pos, 1));
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
               , w1l => $line - 1, w1c => $c-pd + 1 - $multiplicand.chars - $multiplier.chars
               , w2l => $line - 1, w2c => $c-pd);
  self.action.push($action);
  for (0 .. $multiplicand.chars + $multiplier.chars) -> $i {
    @final[$i] = %( lin => $line, col => $c-pd - $i );
  }
  $result = self!adding(@partial, @final, $basic-level, $radix);
  return  Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($result));
}

method !simple-mult(Int :$basic-level
                  , Int :$l-md, Int :$c-md # coordinates of the multiplicand
                  , Int :$l-mr, Int :$c-mr # coordinates of the multiplier (single-digit)
                  , Int :$l-pd, Int :$c-pd # coordinates of the product
                  , Arithmetic::PaperAndPencil::Number :$multiplicand
                  , Arithmetic::PaperAndPencil::Number :$multiplier
                --> Arithmetic::PaperAndPencil::Number) {
  my Str $result = '';
  my Int $radix  = $multiplier.radix;
  my     $carry  = '0';
  my Int $len1   = $multiplicand.chars;
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $pdt;
  for (0 ..^ $len1) -> $i {
    my Arithmetic::PaperAndPencil::Number $mul .= new(:radix($radix), :value($multiplicand.value.substr($len1 - $i - 1, 1)));
    $pdt   = $multiplier ☈× $mul;
    $action .= new(level => $basic-level + 6, label => 'MUL01'                , val3 => $pdt.value
                 , r1l => $l-mr, r1c => $c-mr     , r1val => $multiplier.value, val1 => $multiplier.value
                 , r2l => $l-md, r2c => $c-md - $i, r2val => $mul.value       , val2 => $mul.value
                 );
    self.action.push($action);
    if $carry ne '0' {
      $pdt ☈+= Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($carry));
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
  return  Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($pdt.value ~ $result));
}

method !adding(@digits, @pos, $basic-level, $radix, :$striking = False --> Str) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $sum;
  my Str $result = '';
  my Str $carry  = '0';
  for @digits.kv -> $i, $l {
    my @l = $l.grep({ $_ }); # to remove the Nil entries
    if @l.elems == 0 {
        $action .= new(level => $basic-level + 3, label => 'WRI04'           , val1  => $carry
                                 , w1l => @pos[$i]<lin>, w1c => @pos[$i]<col>, w1val => $carry
                                 );
        self.action.push($action);
        $result = $carry ~ $result;
    }
    elsif @l.elems == 1 && $carry eq '0' {
        $action .= new(level => $basic-level + 3, label => 'WRI04'           , val1  => @l[0]<val>
                                 , r1l => @l[ 0  ]<lin>, r1c => @l[ 0  ]<col>, r1val => @l[0]<val>, r1str => $striking
                                 , w1l => @pos[$i]<lin>, w1c => @pos[$i]<col>, w1val => @l[0]<val>
                                 );
        self.action.push($action);
        $result = @l[0]<val> ~ $result;
    }
    else {
      my Int $first;
      $sum .= new(radix => $radix, value => @l[0]<val>);
      if $carry eq '0' {
        $sum ☈+= Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => @l[1]<val>);
        $action .= new(level => $basic-level + 6, label => 'ADD01', val1  => @l[0]<val>, val2 => @l[1]<val>, val3 => $sum.value
                            , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>, r1str => $striking
                            , r2l => @l[1]<lin>, r2c => @l[1]<col>, r2val => @l[1]<val>, r2str => $striking
                            );
        $first = 2;
      }
      else {
        $sum ☈+= Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $carry);
        $action .= new(level => $basic-level + 6, label => 'ADD01', val1  => @l[0]<val>, val2 => $carry, val3 => $sum.value
                            , r1l => @l[0]<lin>, r1c => @l[0]<col>, r1val => @l[0]<val>, r1str => $striking
                            );
        $first = 1;
      }
      self.action.push($action);
      for $first ..^ @l.elems -> $j {
        $sum ☈+= Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => @l[$j]<val>);
        $action .= new(level => $basic-level + 6, label => 'ADD02', val1  => @l[$j]<val>, val2 => $sum.value
                          , r1l => @l[$j]<lin>, r1c => @l[$j]<col>, r1val => @l[$j]<val>, r1str => $striking
                          );
        self.action.push($action);
      }
      if $i == @digits.elems - 1 {
        my Arithmetic::PaperAndPencil::Action $last-action = self.action[* - 1];
        self.action[* - 1] .= new(level => $basic-level + 2, label => $last-action.label, val1  => $last-action.val1, val2 => $last-action.val2, val3 => $last-action.val3
                          , r1l => $last-action.r1l, r1c => $last-action.r1c, r1val => $last-action.r1val, r1str => $striking
                          , r2l => $last-action.r2l, r2c => $last-action.r2c, r2val => $last-action.r2val, r2str => $striking
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

method !embedded-sub(Int :$basic-level, Int :$l-hi, Int :$c-hi, Arithmetic::PaperAndPencil::Number :$high
                                      , Int :$l-lo, Int :$c-lo, Arithmetic::PaperAndPencil::Number :$low
                                      , Int :$l-re, Int :$c-re
                                      --> Str) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $high.radix;
  my Int $leng  = $high.chars;
  # set-up
  $action .= new(level => $basic-level + 2, label => 'DRA02', w1l => $l-lo, w1c => $c-lo - $leng + 1
                                                            , w2l => $l-lo, w2c => $c-lo);
  self.action.push($action);

  my Str $carry  = '0';
  my Str $result = '';
  my Str $label;

  # First subphase, looping over the low number's digits
  for (0 ..^ $low.chars) -> $i {
    my Arithmetic::PaperAndPencil::Number $high1 .= new(radix => $radix, value => $high.value.substr($leng      - $i - 1, 1));
    my Arithmetic::PaperAndPencil::Number $low1  .= new(radix => $radix, value => $low .value.substr($low.chars - $i - 1, 1));
    my Arithmetic::PaperAndPencil::Number $adj1;
    my Arithmetic::PaperAndPencil::Number $res1;
    my Arithmetic::PaperAndPencil::Number $low2;
    if $carry eq '0' {
      ($adj1, $res1) = adjust-sub($high1, $low1);
      $action .= new(level => $basic-level + 6, label => 'SUB01', val1  => $low1.value, val2 => $res1.value, val3 => $adj1.value
                   , r1l => $l-hi, r1c => $c-hi - $i, r1val => $high1.value
                   , r2l => $l-lo, r2c => $c-lo - $i, r2val => $low1.value
                   );
    }
    else {
      $low2 = $low1 ☈+ Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $carry);
      $action .= new(level => $basic-level + 6, label => 'ADD01'   , val1  => $low1.value, val2 => $carry, val3 => $low2.value
                   , r1l => $l-lo, r1c => $c-lo - $i, r1val => $low1.value
                   );
      self.action.push($action);
      ($adj1, $res1) = adjust-sub($high1, $low2);
      $action .= new(level => $basic-level + 6, label => 'SUB02'   , val1  => $res1.value, val2 => $adj1.value
                   , r1l => $l-hi, r1c => $c-hi - $i, r1val => $high1.value
                   );
    }
    self.action.push($action);
    $result = $res1.unit.value ~ $result;
    $carry  = $adj1.carry.value;
    if $carry eq '0' {
      $label = 'WRI03';
    }
    else {
      $label = 'WRI02';
    }
    $action .= new(level => $basic-level + 3, label => $label    , val1  => $res1.unit.value, val2 => $carry
                 , w1l   => $l-re           , w1c   => $c-re - $i, w1val => $res1.unit.value
                 );
    self.action.push($action);
  }
  # Second subphase, dealing with the carry
  my Int $pos = $low.chars;
  while $carry ne '0' {
    my Arithmetic::PaperAndPencil::Number $high1  .= new(radix => $radix, value => $high.value.substr($leng - $pos - 1, 1));
    my Arithmetic::PaperAndPencil::Number $carry1 .= new(radix => $radix, value => $carry);
    my Arithmetic::PaperAndPencil::Number $adj1;
    my Arithmetic::PaperAndPencil::Number $res1;
    ($adj1, $res1) = adjust-sub($high1, $carry1);
    $action .= new(level => $basic-level + 6, label => 'SUB01', val1  => $carry, val2 => $res1.value, val3 => $adj1.value
                 , r1l => $l-hi, r1c => $c-hi - $pos, r1val => $high1.value
                 );
    self.action.push($action);
    $result = $res1.unit.value ~ $result;
    $carry  = $adj1.carry.value;
    if $carry eq '0' {
      $label = 'WRI03';
    }
    else {
      $label = 'WRI02';
    }
    $action .= new(level => $basic-level + 3, label => $label      , val1  => $res1.unit.value, val2 => $carry
                 , w1l   => $l-re           , w1c   => $c-re - $pos, w1val => $res1.unit.value
                 );
    # no need to write the final zero if there is no carry
    if $res1.unit.value ne '0' or $carry ne '0' or $pos < $leng - 1 {
      self.action.push($action);
    }
    $pos++;
  }
  # Third subphase, a single copy
  if $pos < $leng {
    $action .= new(level => $basic-level, label => 'WRI05'     , val1  => $high.value.substr(0, $leng - $pos)
                 , w1l   => $l-re       , w1c   => $c-re - $pos, w1val => $high.value.substr(0, $leng - $pos)
                 );
    self.action.push($action);
    $result = $high.value.substr(0, $leng - $pos) ~ $result;
  }

  return $result;
}

method !mult-and-sub(Int :$l-dd, Int :$c-dd, Arithmetic::PaperAndPencil::Number :$dividend
                   , Int :$l-dr, Int :$c-dr, Arithmetic::PaperAndPencil::Number :$divisor
                   , Int :$l-qu, Int :$c-qu, Arithmetic::PaperAndPencil::Number :$quotient
                   , Int :$l-re, Int :$c-re, Int :$basic-level
                   , Int :$l-pr, Int :$c-pr, Str :$mult-and-sub = 'combined'
                   ) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $dividend.radix;
  my Str $carry = '0';
  my Str $rem   = '';
  my Bool $too-much = False;

  if $mult-and-sub eq 'separate' {
    my Arithmetic::PaperAndPencil::Number $pdt;
    $pdt = self!simple-mult(basic-level => $basic-level + 1
                         , l-md => $l-dr, c-md => $c-dr, multiplicand => $divisor
                         , l-mr => $l-qu, c-mr => $c-qu, multiplier   => $quotient
                         , l-pd => $l-pr, c-pd => $c-pr);
    if $dividend ☈< $pdt {
      return (True, '');
    }
    $rem = self!embedded-sub(basic-level => $basic-level + 3
                           , l-hi => $l-dd, c-hi => $c-dd, high => $dividend
                           , l-lo => $l-pr, c-lo => $c-pr, low  => $pdt
                           , l-re => $l-re, c-re => $c-re);
    return (False, $rem);
  }
  for 0 ..^ $divisor.chars -> $i {
    my Str $divisor-digit = $divisor.value.substr(* - $i - 1, 1);
    my Arithmetic::PaperAndPencil::Number $temp .= new(radix => $radix, value => $divisor-digit);
    $temp ☈×= $quotient;
    $action .= new(level => $basic-level + 6, label => 'MUL01'              , val3 => $temp.value
                 , r1l => $l-qu, r1c => $c-qu     , r1val => $quotient.value, val1 => $quotient.value
                 , r2l => $l-dr, r2c => $c-dr - $i, r2val => $divisor-digit , val2 => $divisor-digit
                 );
    self.action.push($action);
    if $carry ne '0' {
      $temp ☈+= Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $carry);
      $action .= new(level => $basic-level + 6, label => 'ADD02', val1 => $carry, val2 => $temp.value);
      self.action.push($action);
    }
    my Arithmetic::PaperAndPencil::Number $dividend-digit .= new(radix => $radix, value => $dividend.value.substr(* - $i - 1, 1));
    my Arithmetic::PaperAndPencil::Number $adjusted-dividend;
    my Arithmetic::PaperAndPencil::Number $rem-digit;
    ($adjusted-dividend, $rem-digit) = adjust-sub($dividend-digit, $temp);
    if $i == $divisor.chars - 1 {
      if $dividend.carry($i) ☈< $adjusted-dividend {
        $too-much = True;
      }
      else {
        $action .= new(level => $basic-level + 6, label => 'SUB02', val1  => $rem-digit.value, val2 => $adjusted-dividend.value
                                                           , r1l => $l-dd, r1c => $c-dd - $i, r1val => $adjusted-dividend.value
                     );
        self.action.push($action);
        $action .= new(level => $basic-level + 6, label => 'WRI04'   , val1  => $rem-digit.value
                     , w1l   => $l-re           , w1c   => $c-re - $i, w1val => $rem-digit.value
                     );
        self.action.push($action);
        $rem   = $rem-digit.value ~ $rem;
      }
    }
    else {
      $action .= new(level => $basic-level + 6, label => 'SUB02', val1  => $rem-digit.value, val2 => $adjusted-dividend.value
                                                         , r1l => $l-dd, r1c => $c-dd - $i, r1val => $adjusted-dividend.value
                   );
      self.action.push($action);
      my $label = 'WRI02';
      if $adjusted-dividend.carry.value eq '0' {
        $label = 'WRI03';
      }
      $action .= new(level => $basic-level + 6, label => $label, val1  => $rem-digit.value, val2 => $adjusted-dividend.carry.value
                              , w1l => $l-re, w1c => $c-re - $i, w1val => $rem-digit.value
                              );
      self.action.push($action);
      $rem   = $rem-digit.value ~ $rem;
      $carry = $adjusted-dividend.carry.value;
    }
  }
  return ($too-much, $rem);
}

method !embedded-div(Int :$l-dd, Int :$c-dd, Arithmetic::PaperAndPencil::Number :$dividend
                   , Int :$l-dr, Int :$c-dr, Arithmetic::PaperAndPencil::Number :$divisor
                   , Int :$l-qu, Int :$c-qu is copy
                   , Int :$basic-level
                   , Str :$type, Str :$mult-and-sub, :%mult-cache
                   , Bool :$stand-alone = False
                   ) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $dividend.radix;
  my Arithmetic::PaperAndPencil::Number $zero .= new(:radix($radix), :value<0>);
  my Arithmetic::PaperAndPencil::Number $one  .= new(:radix($radix), :value<1>);
  my Int $len1  = $dividend.chars;
  my Int $len2  = $divisor .chars;
  my Int $col-r = $len2;     # column for the successive partial dividends and remainders
  my Int $len-dvd1 = 1;      # length of the part of the dividend used to compute the first candidate digit
  # yes, string comparison or left-aligned comparison, to know if we need a short hook or a long hook
  if $dividend ☈lt $divisor {
    $len-dvd1++;
    $col-r++;
  }
  my Int $bot      = $l-dd + 2;
  my Str $quotient = '';
  my Str $rem      = '';
  my Int $nb-dots  = $len1 - $col-r + 1;
  my Str $dots     = '.' x $nb-dots;
  $action .= new(level => $basic-level + 5, label => 'DRA01', w1l => $l-dr, w1c => $c-dr - $len2
                                                            , w2l => $bot , w2c => $c-dr - $len2);
  self.action.push($action);
  $action .= new(level => $basic-level + 5, label => 'WRI00'
               , w1l   => $l-dr, w1c => $c-dr               , w1val => $divisor.value
               , w2l   => $l-qu, w2c => $c-qu + $nb-dots - 1, w2val => $dots);
  self.action.push($action);
  $action .= new(level => $basic-level + 1, label => 'HOO01', w1l => $l-dd, w1c => $c-dd - $len1 + 1
                                                            , w2l => $l-dd, w2c => $c-dd - $len1 + $col-r);
  self.action.push($action);

  # computation
  if $type eq 'std' | 'cheating' {
    my Int $lin-d = $l-dd;     # line of the partial dividend
    my Int $delta = $len2 - 1; # how long we must shorten the divisor and the partial dividend to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $part-dvr1 = $divisor.carry($delta); # single-digit divisor to compute the quotient first candidate
    my Arithmetic::PaperAndPencil::Number $part-dvd .= new(:radix($radix), :value($dividend.value.substr(0, $col-r)));
    while $col-r ≤ $len1 {
      my Arithmetic::PaperAndPencil::Number $part-dvd1 = $part-dvd.carry($delta);  # single-digit dividend or 2-digit dividend to compute the quotient first candidate
      my Arithmetic::PaperAndPencil::Number $theo-quo  = $part-dvd1 ☈÷ $part-dvr1; # theoretical quotient first candidate
      my Arithmetic::PaperAndPencil::Number $act-quo;                              # actual quotient first candidate
      my Str $label;
      if $part-dvd ☈< $divisor {
        $theo-quo = $zero;
        $act-quo  = $zero;
      }
      elsif $type eq 'cheating' {
        $act-quo .= new(radix => $radix, value => %mult-cache.keys.grep(-> $x { %mult-cache{$x} ☈≤ $part-dvd }).max);
        $label    = 'DIV03';
      }
      elsif $theo-quo.chars == 2 {
        $act-quo  = max-unit($radix);
        $label    = 'DIV02';
      }
      else {
        $act-quo  = $theo-quo;
      }
      my Bool $too-much = True; # we must loop with the next lower candidate
      if $theo-quo.value eq '0' {
        $action .= new(level => $basic-level + 5, label => 'DIV01'
                     , val1  => $part-dvd.value , r1l => $lin-d, r1c => $c-dd + $col-r   , r1val => $part-dvd.value
                     , val2  => $divisor .value , r2l => $l-dr , r2c => $c-dr + $len2 - 1, r2val => $divisor.value
                     , val3  => '0'             , w1l => $l-qu , w1c => $c-qu            , w1val => '0');
        self.action.push($action);
        $too-much = False; # no need to loop on candidate values, no need to execute the mult-and-sub routine
        $rem = $part-dvd.value;
      }
      elsif $theo-quo.value eq $act-quo.value {
        $action .= new(level => $basic-level + 5, label => 'DIV01'
                     , val1  => $part-dvd1.value, r1l => $lin-d, r1c => $c-dd - $len1 + $col-r - $delta, r1val => $part-dvd1.value
                     , val2  => $part-dvr1.value, r2l => $l-dr , r2c => $c-dr - $len2 + 1      - $delta, r2val => $part-dvr1.value
                     , val3  => $theo-quo .value, w1l => $l-qu , w1c => $c-qu                          , w1val => $act-quo.value);
        self.action.push($action);
      }
      else {
        $action .= new(level => $basic-level + 6, label => 'DIV01'
                     , val1  => $part-dvd1.value, r1l => $lin-d, r1c => $c-dd - $len1 + $col-r - $delta, r1val => $part-dvd1.value
                     , val2  => $part-dvr1.value, r2l => $l-dr , r2c => $c-dr - $len2 + 1              , r2val => $part-dvr1.value
                     , val3  => $theo-quo.value);
        self.action.push($action);
        $action .= new(level => $basic-level + 5, label => $label, val1 => $act-quo.value, w1l => $l-qu, w1c => $c-qu, w1val => $act-quo.value);
        self.action.push($action);
      }
      my Int $l-re;
      while $too-much {
        if $mult-and-sub eq 'separate' {
          $l-re = $lin-d + 2;
        }
        else {
          $l-re = $lin-d + 1;
        }
        if $bot < $l-re {
          $bot = $l-re;
          $action .= new(level => $basic-level + 5, label => 'DRA01', w1l => $l-dd, w1c => $c-dr - $len2
                                                                    , w2l => $bot , w2c => $c-dr - $len2);
          self.action.push($action);
        }
        ($too-much, $rem) = self!mult-and-sub(l-dd => $lin-d    , c-dd => $c-dd - $len1 + $col-r, dividend     => $part-dvd
                                            , l-dr => $l-dr     , c-dr => $c-dr                 , divisor      => $divisor
                                            , l-qu => $l-qu     , c-qu => $c-qu                 , quotient     => $act-quo
                                            , l-re => $l-re     , c-re => $c-dd - $len1 + $col-r, basic-level  => $basic-level
                                            , l-pr => $lin-d + 1, c-pr => $c-dd - $len1 + $col-r, mult-and-sub => $mult-and-sub);
        if $too-much {
          self.action[* - 1].level = $basic-level + 4;
          $act-quo ☈-= $one;
          my Int $erased-column;
          if $stand-alone {
            $erased-column = $c-dd - $len1;
          }
          else {
            $erased-column = $c-dd - $len1 + 1;
          }
          $action .= new(level => $basic-level + 5, label => 'ERA01', w1l => $lin-d + 1, w1c => $c-dd, w2l => $lin-d + 1, w2c => $erased-column);
          self.action.push($action);
          $action .= new(level => $basic-level + 4, label => 'DIV02', val1 => $act-quo.value, w1l => $l-qu, w1c => $c-qu, w1val => $act-quo.value);
          self.action.push($action);
        }
      }

      $quotient ~= $act-quo.value;
      if $act-quo.value ne '0' {
        $lin-d = $l-re;
      }
      self.action[* - 1].level = $basic-level + 3;
      if $col-r < $len1 {
        $action .= new(level => $basic-level + 5, label => 'DRA01', w1l => $l-dr, w1c => $c-dr - $len2
                                                   , w2l => $bot , w2c => $c-dr - $len2);
        self.action.push($action);
        my Str $new-digit = $dividend.value.substr($col-r, 1);
        $action .= new(level => $basic-level + 3   , label => 'DIV04'   , val1  => $new-digit
                     , r1l => $l-dd , r1c => $c-dd - $len1 + $col-r  + 1, r1val => $new-digit
                     , w1l => $lin-d, w1c => $c-dd - $len1 + $col-r  + 1, w1val => $new-digit);
        self.action.push($action);
        $part-dvd .= new(radix => $radix, value => $rem ~ $new-digit);
      }
      $col-r++;
      $c-qu++;
    }
    self.action[* - 1].level = $basic-level;
  }
  if $type eq 'prepared' {
    my Arithmetic::PaperAndPencil::Number $part-div .= new(:radix($radix), :value($dividend.value.substr(0, $col-r)));
    my Int $n = 0;
    my Int $lin-d = $l-dd;
    while $col-r ≤ $len1 {
      my Str $part-quo = %mult-cache.keys.grep(-> $x { %mult-cache{$x} ☈≤ $part-div }).max;
      $action .= new(level => $basic-level + 5, label => 'DIV01'
                   , val1 => $part-div.value, r1l => $lin-d, r1c => $col-r       , r1val => $part-div.value
                   , val2 => $divisor.value , r2l => $l-dr , r2c => $c-dr        , r2val => $divisor.value
                   , val3 => $part-quo      , w1l => $l-qu , w1c => $c-qu + $n   , w1val => $part-quo);
      self.action.push($action);
      $quotient ~= $part-quo;
      if $part-quo eq '0' {
        $rem = $part-div.value;
      }
      else {
        $action .= new(level => $basic-level + 5, label => 'WRI05', val1 => %mult-cache{$part-quo}.value);
        self.action.push($action);
        $bot += 2;
        $action .= new(level => $basic-level + 8, label => 'WRI00'
                     , w1l => $lin-d + 1, w1c => $c-dd - $len1 + $col-r, w1val => %mult-cache{$part-quo}.value);
        self.action.push($action);
        $rem = self!embedded-sub(basic-level => $basic-level + 3
                     , l-hi => $lin-d    , c-hi => $c-dd - $len1 + $col-r, high => $part-div
                     , l-lo => $lin-d + 1, c-lo => $c-dd - $len1 + $col-r, low  => %mult-cache{$part-quo}
                     , l-re => $lin-d + 2, c-re => $c-dd - $len1 + $col-r);
        self.action[* - 1].level = $basic-level + 3;
        $lin-d += 2;
      }

      if $col-r < $len1 {
        $action .= new(level => $basic-level + 5, label => 'DRA01', w1l => $l-dd, w1c => $c-dd
                                                                  , w2l => $bot , w2c => $c-dd);
        self.action.push($action);
        my Str $new-digit = $dividend.value.substr($col-r, 1);
        $action .= new(level => $basic-level + 3, label => 'DIV04'      , val1  => $new-digit
                     , r1l => $l-dd , r1c => $c-dd - $len1 + $col-r  + 1, r1val => $new-digit
                     , w1l => $lin-d, w1c => $c-dd - $len1 + $col-r  + 1, w1val => $new-digit);
        self.action.push($action);
        $part-div .= new(radix => $radix, value => $rem ~ $new-digit);
      }
      ++$col-r;
      ++$n;
    }
  }
  return ( Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($quotient))
         , Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($rem)));
}

method !preparation(Arithmetic::PaperAndPencil::Number :$factor, Str :$limit, :%cache, :$basic-level = 0) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $one .= new(:radix($factor.radix), :value<1>);
  my Int $radix = $factor.radix;
  my Int $col   = $factor.chars + 3;

  # cache first entry
  %cache<1> = $factor;
  $action .= new(level => $basic-level + 3, label => 'WRI00'
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
  @total[$factor.chars] = %( lin => 1, col => $col - $factor.chars);

  my Str $result = $factor.value;
  my Int $lin    = 1;
  my Arithmetic::PaperAndPencil::Number $mul = $one ☈+ $one; # starting from 2; yet stopping immediately with a 2-digit $mul if $radix == 2
  while $mul.value le $limit && $mul.chars == 1 {
    # displaying the line number
    $action .= new(level => $basic-level + 9, label => 'WRI00', w1l => $lin, w1c => 0, w1val => $mul.value);
    self.action.push($action);

    # computation
    for $result.flip.comb.kv -> $i, $ch {
      @digits[$i][1] = %( lin => $lin - 1, col => $col - $i, val => $ch);
      @total[$i]<lin> = $lin;
    }
    $result = self!adding(@digits, @total, $basic-level + 1, $radix);
    self.action[* - 1].level = $basic-level + 3;

    # storing into cache
    %cache{$mul.value} = Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($result));

    # loop iteration
    $lin++;
    $mul ☈+= $one;
  }

  $action .= new(:level(1), :label<NXP01>);
  self.action.push($action);
}

method !prep-conv(Int $old-radix, Int $new-radix, %cache, :$basic-level = 0) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $old-number .= new(value => '0', radix => $old-radix);
  my Arithmetic::PaperAndPencil::Number $new-number .= new(value => '0', radix => $new-radix);
  my Arithmetic::PaperAndPencil::Number $old-one    .= new(value => '1', radix => $old-radix);
  my Arithmetic::PaperAndPencil::Number $new-one    .= new(value => '1', radix => $new-radix);
  my Int $line = 1;
  while $old-number.value ne '11' {
    %cache{$old-number.value} = $new-number;
    if $new-number.chars > 1 {
      $action .= new(level => $basic-level + 6, label => 'WRI00'
                   , w1l => $line, w1c =>  2, w1val => $old-number.value
                   , w2l => $line, w2c => 10, w2val => $new-number.value);
      self.action.push($action);
      $line++;
    }
    $old-number ☈+= $old-one;
    $new-number ☈+= $new-one;
  }
  if $line != 1 {
    self.action[* - 1].level = 1;
    $action .= new(:level($basic-level + 9), :label<NXP01>);
    self.action.push($action);
  }
}

method !push-below($number, $col is copy, @lines-below) {
  my Arithmetic::PaperAndPencil::Action $action;
  for $number.value.flip.comb -> $digit {
    $action .= new(level => 9, label => 'WRI00', w1l => @lines-below[$col]++, w1c => $col, w1val => $digit);
    self.action.push($action);
    $col--;
  }
  self.action[* - 1].level = 4;
}

method !push-above($number, $col is copy, @lines-above, @addition, Int $bias) {
  my Arithmetic::PaperAndPencil::Action $action;
  for $number.value.flip.comb -> $digit {
    @addition[$bias - $col; - @lines-above[$col] ] = %( lin => @lines-above[$col], col => $col, val => $digit );
    $action .= new(level => 9, label => 'WRI00', w1l => @lines-above[$col]--, w1c => $col, w1val => $digit);
    self.action.push($action);
    $col--;
  }
}

method !add-above($number is copy, $col is copy, @lines-above, @result) {
  my Arithmetic::PaperAndPencil::Action $action;
  my Int $radix = $number.radix;
  while $number.value ne '0' {
    if @lines-above[$col] == -1 {
      my Str $code = 'WRI02';
      if $number.chars == 1 {
        $code = 'WRI04';
      }
      $action .= new(level => 5, label => $code                ,  val1 => $number.unit.value, val2 => $number.carry.value
                   , w1l   => @lines-above[$col]--, w1c => $col, w1val => $number.unit.value);
      self.action.push($action);
      @result[$col] = $number.unit.value;
      $number       = $number.carry;
    }
    else {
      my Arithmetic::PaperAndPencil::Number $already-there .= new(radix => $radix, value => @result[$col]);
      my Arithmetic::PaperAndPencil::Number $sum = $number ☈+ $already-there;
      $action .= new(level => 6, label => 'ADD01'  , val1  => $number.value, val2 => $already-there.value, val3 => $sum.value
                   , r2l  => @lines-above[$col] + 1, r2c   => $col        , r2val => $already-there.value, r2str => True
                );
      self.action.push($action);
      my Str $code = 'WRI02';
      if $sum.chars == 1 {
        $code = 'WRI03';
      }
      $action .= new(level => 5                , label => $code, val1 => $sum.unit.value, val2 => $sum.carry.value
                    , w1l => @lines-above[$col]--, w1c => $col, w1val => $sum.unit.value
                    );
      self.action.push($action);
      @result[$col] = $sum.unit.value;
      $number       = $sum.carry;
    }
    --$col;
  }
}

method !halving(Int :$l1, Int :$c1, Int :$l2, Int :$c2, Arithmetic::PaperAndPencil::Number :$number, Int :$basic-level = 0
                --> Arithmetic::PaperAndPencil::Number) {
  my Int $radix = $number.radix;
  my Str $res   = '';
  my Arithmetic::PaperAndPencil::Action $action;
  if $radix == 2 {
    if $number.chars > 1 {
      $res = $number.value.substr(0, $number.chars - 1);
    }
    else {
      $res = '0';
    }
    $action .= new(:level($basic-level + 4), :label<SHF01>
                 , r1l => $l1, r1c => $c1, r1val => $number.value, val1 => $number.value
                 , w1l => $l2, w1c => $c2, w1val => $res         , val2 => $res
                 );
    self.action.push($action);
  }
  else {
    my Arithmetic::PaperAndPencil::Number $one .= new(:radix($radix), :value<1>);
    my Arithmetic::PaperAndPencil::Number $two .= new(:radix($radix), :value<2>);
    my Int $len = $number.chars;
    my Int $carry = 0;
    for $number.value.comb.kv -> Int $n, Str $digit {
      my Arithmetic::PaperAndPencil::Number $dividend;
      if $carry == 0 {
        $dividend .= new(:radix($radix), :value($digit));
      }
      else {
        $dividend .= new(:radix($radix), :value('1' ~ $digit));
      }
      my Arithmetic::PaperAndPencil::Number $quotient = $dividend ☈÷ $two;
      if $dividend.is-odd {
        $carry = 1;
      }
      else {
        $carry = 0;
      }
      $action .= new(level => $basic-level + 5, :label<DIV07>, :val1($dividend.value), :val2($quotient.value), :val3($carry.Str)
                   , r1l => $l1, r1c => $c1 -$len + $n + 1, r1val => $digit
                   , w1l => $l2, w1c => $c2 -$len + $n + 1, w1val => $quotient.value
                   );
      self.action.push($action);
      $res ~= $quotient.value;
    }
  }
  return Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($res));
}

method !doubling(Int :$l1, Int :$c1, Int :$l2, Int :$c2, Arithmetic::PaperAndPencil::Number :$number, Int :$basic-level = 0
                 --> Arithmetic::PaperAndPencil::Number) {
  my Int $radix = $number.radix;
  my Str $res   = '';
  my Arithmetic::PaperAndPencil::Action $action;
  if $radix == 2 {
    $res = $number.value ~ '0';
    $action .= new(:level($basic-level + 4), :label<SHF01>
                 , r1l => $l1, r1c => $c1, r1val => $number.value, val1 => $number.value
                 , w1l => $l2, w1c => $c2, w1val => $res         , val2 => $res
                 );
    self.action.push($action);
  }
  else {
    my Arithmetic::PaperAndPencil::Number $carry .= new(:radix($radix), :value<0>);
    my Arithmetic::PaperAndPencil::Number $one   .= new(:radix($radix), :value<1>);
    my Arithmetic::PaperAndPencil::Number $two   .= new(:radix($radix), :value<2>);
    for $number.value.flip.comb.kv -> Int $n, Str $digit {
      my Arithmetic::PaperAndPencil::Number $product .= new(:radix($radix), :value($digit));
      $product ☈×= $two;
      if $carry.value eq '0' {
        $action .= new(level => $basic-level + 5, :label<MUL01>, :val1<2>, :val2($digit), :val3($product.value)
                     , r1l => $l1, r1c => $c1 - $n, r1val => $digit
                     , w1l => $l2, w1c => $c2 - $n, w1val => $product.value
                     );
        self.action.push($action);
      }
      else {
        $action .= new(level => $basic-level + 6, :label<MUL01>, :val1<2>, :val2($digit), :val3($product.value)
                     , r1l => $l1, r1c => $c1 - $n, r1val => $digit
                     );
        self.action.push($action);
        $product ☈+= $one;
        $action .= new(level => $basic-level + 5, :label<ADD02>, :val1<1>, :val2($product.value)
                     , w1l => $l2, w1c => $c2 - $n, w1val => $product.value
                     );
        self.action.push($action);
      }
      $res = $product.unit.value ~ $res;
      $carry = $product.carry;
    }
    if $carry.value eq '1' {
      $res = '1' ~ $res;
    }
  }
  return Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($res));
}

method html(Str :$lang, Bool :$silent, Int :$level, :%css = %() --> Str) {
  my Bool $talkative = not $silent; # "silent" better for API, "talkative" better for programming
  my Str  $result    = '';
  my      @sheet     = ();
  my Int  %vertical-lines;
  my Int  %cache-l2p-col;
  my Int  $c-min     = 0;
  my Int  $l-min     = 0;

  # checking the minimum line number
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

  # checking the minimum column number
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
      $c-min          = 0;
      $l-min          = 0;
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

    # drawing an horizontal line or drawing a hook over a dividend
    sub draw-h(Int :$at, Int :$from, Int :$to) {
      # checking the line and column minimum numbers
      check-l-min($at);
      check-c-min($from);
      check-c-min($to);
      # begin and end
      my ($c-beg, $c-end);
      if $from > $to {
        $c-beg = l2p-col($to);
        $c-end = l2p-col($from);
        filling-spaces($at, $from);
      }
      else {
        $c-beg = l2p-col($from);
        $c-end = l2p-col($to);
        filling-spaces($at, $to);
      }
      for $c-beg .. $c-end -> $i {
        @sheet[l2p-lin($at); $i].underline = True;
      }
    }

    # Drawing an horizontal line
    if $action.label eq 'DRA02' {
      if  $action.w1l != $action.w2l {
        die "The line is not horizontal, starting at line {$action.w1l} and ending at line {$action.w2l}";
      }
      draw-h(:at($action.w1l), :from($action.w1c), :to($action.w2c));
    }

    # Drawing a hook over a dividend (that is, an horizontal line above)
    if $action.label eq 'HOO01' {
      if  $action.w1l != $action.w2l {
        die "The hook is not horizontal, starting at line {$action.w1l} and ending at line {$action.w2l}";
      }
      draw-h(:at($action.w1l - 1), :from($action.w1c), :to($action.w2c));
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
        @sheet[$l1; $c1].char = backslash-char.char;
        # the line
        #   @sheet[$l1; $c1] = backslash-char();
        # would be wrong, because in some cases it would clobber the "underline" attribute of an already existing char
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
        @sheet[$l1; $c1].char = slash-char.char;
        # the line
        #   @sheet[$l1; $c1] = slash-char();
        # would be wrong, because in some cases it would clobber the "underline" attribute of an already existing char
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
      check-c-min($action.w2c);
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

Arithmetic::PaperAndPencil - simulating paper and pencil techniques for basic arithmetic operations

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil;

my Arithmetic::PaperAndPencil $operation .= new;
my Arithmetic::PaperAndPencil::Number $x .= new(value => '355000000');
my Arithmetic::PaperAndPencil::Number $y .= new(value => '113');

$operation.division(dividend => $x, divisor => $y);
my Str $html = $operation.html(lang => 'fr', silent => False, level => 3);
'division.html'.IO.spurt($html);

$operation .= new; # emptying previous content
my Arithmetic::PaperAndPencil::Number $dead .= new(value => 'DEAD', radix => 16);
my Arithmetic::PaperAndPencil::Number $beef .= new(value => 'BEEF', radix => 16);

$operation.addition($dead, $beef);
$html = $operation.html(lang => 'fr', silent => False, level => 3);
'addition.html'.IO.spurt($html);

=end code

The first HTML file ends with

=begin code
 355000000|113
 0160     |---
  0470    |3141592
   0180   |
    0670  |
     1050 |
      0330|
       104|
=end code

and the second one with

=begin code
  DEAD
  BEEF
 -----
 19D9C
=end code

=head1 DESCRIPTION

Arithmetic::PaperAndPencil  is a  module which  allows simulating  the
paper  and  pencil  techniques  for  basic  arithmetic  operations  on
integers: addition, subtraction, multiplication and division, but also
square root extraction and conversion from a radix to another.

An  object  from  the C<Arithmetic::PaperAndPencil>  class  is  called
"paper  sheet", because  it  represents  a paper  sheet  on which  the
simulated human scribbles  his computations. In some  cases, the human
would use a wad of sheets instead of a single sheet. This is simulated
in the module, but we still call the object a "paper sheet".

=head2 Problems, known bugs and acceptable breaks from reality

Most  humans  can only  compute  in  radix  10.  Some persons  have  a
theoretical knowledge  of numeric bases  other than 10, and  a limited
practical skill  of using radix  2, radix 8  and radix 16.  The module
uses any radix from 2 to 36, without difference.

The module  can use numbers  of any length.  Human beings will  not be
able to  multiply two  100-digit numbers.  Or if  they try,  they will
spend much effort  and the result may be wrong.  The module can easily
multiply two 100-digit numbers. The  output may be lengthy and boring,
but it will be correct.

Humans can  detect situations where  the computation procedure  can be
amended,  such as  a  multiplication where  the  multiplicand and  the
multiplier contain many  "0" digits. The module does  not detect these
cases and still uses the unaltered computation procedure.

Human beings write their calculations on A4 paper (21 cm × 29,7 cm) or
letter paper (21,6  cm × 27,9 cm). The module  writes its calculations
on unlimited  sheets of paper. If  you want to compute  the product of
two 1000-digit numbers, the multiplication will have a 2000-char width
and a 1000-line height and still be on a single sheet of paper.

If you  ask for the  operations with  the "talking" formulas,  most of
these  formulas are  the traditional  sentences which  accompanies the
writing of the  computation. But in some cases, the  module displays a
non-standard sentence, to explain better what is happening.

=head1 UTILITY METHODS

=head2 new

Without  parameters, creates  an  empty paper  sheet.  Or removes  the
content of an already existing paper sheet.

With a C<csv> keyword parameter, reads  a CSV file and creates a paper
sheet containing the operations listed in this CSV file. The parameter
is the CSV filename.

=head2 csv

Generates a string with a CSV format and listing all operations stored
in the sheet object. Storing this string into a file allows you to use
the C<< .new(csv => $filename) >> method to recreate a prior sheet.

=head2 html

Generates a string using the HTML format.

For a properly formatted HTML file, the module user should provide the
beginning of the file, from the C<< <html> >> tag until the C<< <body>
>> tag, and then  the end of the file, with  the C<< </body></html> >>
tags.

The parameters are the following:

=begin item

C<lang>

The  language for  the titles  and messages.  The C<"fr">  language is
fully specified, and the C<"en"> language is still incomplete. For the
moment, there are no other languages.

=end item

=begin item

C<silent>

Boolean parameter controlling the display of the "spoken" messages. If
C<True>, only the titles are  displayed. It C<False>, all messages are
displayed.

=end item

=begin item

C<level>

Integer parameter  controlling the  display of partial  operations. If
C<0>, only the final complete operation  is shown. If C<1>, each sheet
is displayed  upon switching  to another  sheet (when  using a  wad of
sheets). If C<2> or more, partial operations are displayed. The higher
the parameter, the more often the partial operations are displayed.

=end item

=begin item

C<css>

Overrides  the default  HTML formatting.  This is  a hash  table, with
entries among C<underline>, C<strike>,  C<write>, C<read> and C<talk>.
If  an entry  exists,  the default  format is  replaced  by C<<  <span
style='xxx'> >>. Exception: if the  C<talk> entry exists, the "spoken"
messages are formatted with C<< <p style='xxx'> >>.

=end item

=head1 ARITHMETIC METHODS

All  these  methods   return  a  C<Arithmetic::PaperAndPencil::Number>
instance,  equal to  the  result of  the  operation. Unless  specified
otherwise,  all input  C<Arithmetic::PaperAndPencil::Number> instances
must have the same numeric radix.

=head2 addition

Simulates the addition  of two or more numbers. The  numbers are given
as a  list variable  C<@list> or  a list  of scalar  variables C<$nb1,
$nb2,  $nb3>.  This is  a  positional  parameter.  Each number  is  an
instance of the C<Arithmetic::PaperAndPencil::Number> class.

=head2 subtraction

Simulates   the  subtraction   of  two   numbers,  instances   of  the
C<Arithmetic::PaperAndPencil::Number> class. The  keywords are C<high>
and C<low>.  The C<high> number must  be greater than or  equal to the
C<low> number. Negative results are not allowed.

A third  keyword parameter  is C<type>. With  this parameter,  you can
choose between a standard subtraction (parameter value C<std>, default
value) and a subtraction using  the radix-complement of the low number
(parameter value C<compl>).

Acceptable break  from reality. When  using the C<compl>  variant, the
module will write the extra digit  and then strike it, while the human
computer will stop before writing  this extra digit, especially in the
context of assembly programming, where  for example the registers hold
32 bits, not 33.

=head2 multiplication

Simulates the  multiplication of  two numbers. The  keyword parameters
are:

=begin item
C<multiplicand>, C<multiplier>

The two numbers to be multiplied, instances of C<Arithmetic::PaperAndPencil::Number>.
=end item

=begin item
C<type>

Specifies the variant technique. This parameter is a C<Str> value. The
default  variant  is  C<'std'>.   Other  values  are  C<'jalousie-A'>,
C<'jalousie-B'>, C<'boat'> or C<'russian'> (see below).
=end item

=begin item
C<direction>

This  parameter  is  used  with the  C<'boat'>  type.  Value  C<'ltr'>
(default value)  specifies that the elementary  products are processed
left-to-right,  value  C<'rtl'>  specifies  that  these  products  are
processed  right-to-left.   This  applies   only  to   processing  the
multiplier's   digits.  Whatever   the  value,   the  digits   of  the
multiplicand are processed left-to-right.

This   parameter   has   no  use   with   C<'std'>,   C<'jalousie-A'>,
C<'jalousie-B'> and C<'russian'> types.
=end item

=begin item
C<mult-and-add>

This parameter  is used with  the C<'boat'> type.  Value C<'separate'>
(default value) means that in a first phase, the digits resulting from
the elementary multiplications are written  and that in a second phase
these  digits are  added together  to obtain  the final  result. Value
C<'combined'> means that as soon  as a elementary product is computed,
its digits  are added to the  running sum which will  become the final
full product at the end.

This   parameter   has   no  use   with   C<'std'>,   C<'jalousie-A'>,
C<'jalousie-B'> and C<'russian'> types.
=end item

=begin item
C<product>

This  parameter   is  used  with  the   C<"jalousie-*">  types.  Value
C<"L-shaped"> (default value) means that the product is written in two
parts,  an horizontal  one  at  the bottom  of  the  operation and  an
vertical one, on the left side of the operation for C<"jalousie-A"> or
on the right side for  C<"jalousie-B">. Value C<"straight"> means than
the product  is written horizontaly  on the  bottom line, even  if the
bottom line is wider than the rectangle of the operation.

This parameter  has no use  with C<'std'>, C<'boat'>  and C<'russian'>
types.
=end item

The various types are

=begin item
C<std>

The standard multiplication.

Acceptable break  from reality:  remember that the  successive partial
products  shifts by  one column.  These shifts  are materialised  with
dots. When  the multiplier contains  a digit  C<0>, the line  with all
zeroes is not printed and the shift  is more than one column, with the
corresponding number of dots. Example:

  .      628
  .      203
  .      ---
  .     1884
  .   1256..
  .   ------
  .   127484

The actual acceptable  break from reality happens  when the multiplier
contains zeroes at the right. In this case, are there dots in the very
first line? Or do we write zeroes? See below both cases.

  .      628          628
  .      230          230
  .      ---          ---
  .    1884.        18840
  .   1256..       1256..
  .   ------       ------
  .   144440       144440

The module uses the second possibility, writing zeroes on the first line.
=end item

=begin item
C<shortcut>

The standard multiplication, but  if the multiplier  contains repeated
digits, the  partial products  are computed only  once. When  the same
digit appears a second time in the multiplier, the  partial product is
copied from the first occurrence instead of being recomputed.
=end item

=begin item
C<prepared>

This  variant  is  inspired  from  the  C<prepared>  variant  for  the
division.  Before  starting  the multiplication  proper,  all  partial
products are  preemptively computed. Then, when  the multiplication is
computed, all partial products are  simply copied from the preparation
step.

Acceptable  break  from  reality:  there  is  no  evidence  that  this
technique  is taught  or used.  It is  just an  possible extension  to
multiplication of the prepared division technique.
=end item

=begin item
C<jalousie-A>

The partial products are written in rectangular form. The multiplicand
is  written  left-to-right on  the  top  side  of the  rectangle,  the
multiplier  is  written  top-to-bottom  on   the  right  side  of  the
rectangle, the  final product is  written first, top-to-bottom  on the
left side  of the  rectangle and second,  left-to-right on  the bottom
side of  the rectangle. For example,  the multiplication C<15 ×  823 =
12345>  gives  the following  result  (omitting  the interior  of  the
rectangle):

  .     823
  .    1   1
  .    2   5
  .     345

If the C<product> parameter is C<"straight">, then the operation final
aspect is:

  .     823
  .        1
  .        5
  .   12345

Acceptable break from reality: the  outlying digits should be centered
with respect  to the inner  grid. The module  writes them in  a skewed
fashion. In addition, the inner  vertical and horizontal lines are not
drawn. Below left, the theoretical  output, below right the simplified
output:

  .     8   2   3         8 2 3
  .   -------------      --------
  .   |0 /|0 /|0 /|      |0/0/0/|
  .  1| / | / | / |1    1|/8/2/3|1
  .   |/ 8|/ 2|/ 3|      |4/1/1/|
  .   -------------     2|/0/0/5|5
  .   |4 /|1 /|1 /|      --------
  .  2| / | / | / |5      3 4 5
  .   |/ 0|/ 0|/ 5|
  .   -------------
  .     3   4   5

=end item

=begin item
C<jalousie-B>

The partial products are written in rectangular form. The multiplicand
is  written  left-to-right on  the  top  side  of the  rectangle,  the
multiplier is written bottom-to-top on the left side of the rectangle,
the final product  is written first, left-to-right on  the bottom side
of the  rectangle and second, bottom-to-top  on the right side  of the
rectangle. For  example, the multiplication C<15 × 823 =  12345> gives
the following result (omitting the interior of the rectangle):

  .  823
  . 5   5
  . 1   4
  .  123

If the C<product> parameter is C<"straight">, then the operation final
aspect is:

  .  823
  . 5
  . 1
  .  12345

Acceptable break from reality: same as for C<'jalousie-A'>.
=end item

=begin item
C<boat>

The  multiplicand  is  written   between  two  horizontal  lines.  The
multiplier is written below the bottom line and stricken and rewritten
as  the multiplication  progresses. The  partial products  are written
above the  top line.  When the  partial products  are added,  they are
stricken and the final product is written above the partial products.

Acceptable  break from  reality: I  am not  sure the  explanation from
I<Number Words and  Number Symbols> is authoritative. So  I have added
two parameters, C<direction> and  C<mult-and-add>, to allow the module
user to choose which subvariant he prefers.
=end item

=begin item
C<russian>

Better known  as the "Russian peasant  multiplication". The multiplier
and  the multiplicand  are written  side-by-side. Then,  on each  line
below, the multiplier is halved and the multiplicand is doubled, until
the  multiplier  reaches C<1>.  On  some  lines, the  multiplicand  is
stricken and then the unstricken lines are added together, which gives
the final product.
=end item

=head2 division

Simulates the division of two numbers. The keyword parameters are:

=begin item
C<dividend>, C<divisor>

The two numbers to be divided, instances of C<Arithmetic::PaperAndPencil::Number>.
=end item

=begin item
C<type>

Specifies the variant technique. This parameter is a C<Str> value. The
default variant is C<"std">.
=end item

=begin item
C<result>

This C<Str> parameter  can be either C<"quotient">  (default value) or
C<"remainder">,  or  C<"both">.  It  controls  which  value  is  (are)
returned by the method to the main programme.
=end item


=begin item
C<mult-and-sub>

This C<Str> parameter  can be either C<"combined">  (default value) or
C<"separate">. It  controls the computation of  the successive partial
remainders with  a multiplication (quotient digit  times full divisor)
and a subtraction  (from the partial dividend).  If C<"combined">, the
multiplication and  the subtraction are  done at the same  time, digit
per digit. If C<"separate">, the multiplication is done first in full,
then the subtraction is done.
=end item

The various types are

=begin item
C<std>

The standard division.
=end item

=begin item
C<cheating>

This is the  standard division with a twist. The  standard division is
usually a  trial-and-error process  in which several  candidate digits
are  tried  for   each  quotient  digit.  With   this  technique,  the
trial-and-error process is cut short  and only the successful digit is
tried.

Acceptable break  from reality: This is  not a real method,  this is a
convenience  method  which gives  shorter  HTML  files than  what  the
C<"std"> type generates.
=end item

=begin item
C<prepared>

Before starting the division, the module computes the partial products
of the divisor with any  single-digit number. These when computing the
intermediate  remainders,   instead  of   doing  a   multiplication  -
subtraction combination,  the already known partial  product is simply
copied from  the preparation  list then  subtracted from  the previous
intermediate  remainder.  The  C<mult-and-sub> parameter  defaults  to
C<"separate"> for this division type.
=end item

=begin item
C<boat>

The  dividend is  written above  an  horizontal line.  The divisor  is
written below this  line. As the first partial  remainder is computed,
the  used digits  of the  dividend and  divisor are  stricken and  the
digits of  the partial remainder are  written above the digits  of the
dividend. When computing the next digits, the divisor is rewritten and
the computation of the next partial remainder again strikes the digits
of the  first partial remainder  and of  the second occurrence  of the
divider.

Acceptable  break  from   reality:  I  have  not   found  anywhere  an
explanation for this technique. The way it is implemented is just some
guesswork after some  reverse engineering attempt. A  special point is
that  it  seems  to  require  something  similar  to  the  C<cheating>
technique above, because I do not see how we can "unstrike" the digits
that were stricken with the previous digit candidate.
=end item

=head2 square-root

Simulates the  extraction of the square  root of a number.  There is a
single     positional     parameter,     an    instance     of     the
C<Arithmetic::PaperAndPencil::Number> class.

There is  an optional keyword parameter,  C<mult-and-sub>. Its purpose
is the same as for division.  If set to C<'combined'> (default value),
the  computing  of the  product  (candidate  digit times  divisor)  is
combined with  the subtraction  from the partial  dividend. If  set to
C<'separate'>, the multiplication and  the subtraction are executed in
separate and successive phases.

=head2 conversion

Simulates the conversion  of a number from its current  radix to a new
radix.

The parameters are:

=begin item
C<number>

The number to convert, instance of C<Arithmetic::PaperAndPencil::Number>.
=end item

=begin item
C<radix>

The  destination radix  for the  conversion. This  is a  native C<Int>
number, not an instance of C<Arithmetic::PaperAndPencil::Number>.
=end item

=begin item
C<nb-op>

The  number of  operations  on a  single page.  After  this number  is
reached, a  new page  is generated. This  allows keeping  the complete
operation  sufficiently  short.  This  parameter is  a  native  C<Int>
number. If zero (default value), no new pages are generated.
=end item

=begin item
C<type>

A string  parameter specifying  which algorithm is  used to  convert a
number. Values  C<'mult'> and C<'Horner'>  are synonymous and  use the
cascading multiplication algorithm (or  Horner scheme). Value C<'div'>
uses the cascading division algorithm.
=end item

=begin item
C<div-type>

A string parameter specifying which kind of division is used: C<'std'>
(default value) uses  a standard division with  a full trial-and-error
processing  for  candidate  quotient   digits,  C<'cheating'>  uses  a
standard division  in which the trial-and-error  of candidate quotient
digits is  artificially reduced  to a single  iteration, C<'prepared'>
first computes the list of multiples  for the target radix and uses it
to openly and  accountably reduce the trial-and-error  processing to a
single iteration.

This parameter is  ignored if the conversion parameter  C<type> is not
C<'div'>.

See  the  C<type>  parameter  for the  C<division>  method.  Yet,  the
C<'boat'> value available for the C<type> parameter of the C<division>
method  is   not  allowed  for   the  C<div-type>  parameter   of  the
C<conversion> method.
=end item

=begin item
C<mult-and-sub>

This parameter  is similar  to the  C<mult-and-sub> parameter  for the
C<division> method, except that it is useful only if the value of the
C<div-type> parameter is C<'cheating'>.

The  parameter  controls the  computation  of  the successive  partial
remainders with  a multiplication (quotient digit  times full divisor)
and a  subtraction (from  the partial  dividend). Possible  values are
C<'combined'> or  C<'separate'>. If C<'combined'>,  the multiplication
and the  subtraction are done  at the same  time, digit per  digit. If
C<'separate'>,  the multiplication  is done  first in  full, then  the
subtraction is done.

If  the  C<div-type> parameter  is  C<'prepared'>,  this parameter  is
ignored  and   the  multiplication   and  the  subtraction   are  done
separately.

If  the   C<div-type>  parameter  is  C<'std'>,   the  C<mult-and-sub>
parameter is  ignored and the  multiplication and the  subtraction are
combined. The  reason for  this behaviour  is to  by-pass a  bug which
would appear in cramped situations where several divisions are crammed
side by side.

=end item

=head2 gcd

Simulates the computation of the GCD (greatest common divisor) of
two numbers.

The parameters are:

=begin item
C<first>

The first number used, instance of C<Arithmetic::PaperAndPencil::Number>.
=end item

=begin item
C<second>

The second number used, instance of C<Arithmetic::PaperAndPencil::Number>.
=end item

=begin item
C<div-type>

A string parameter specifying which kind of division is used: C<"std">
(default value) uses  a standard division with  a full trial-and-error
processing  for  candidate  quotient   digits,  C<"cheating">  uses  a
standard division  in which the trial-and-error  of candidate quotient
digits is artificially reduced to a single iteration.

See  the  C<type>  parameter  for the  C<division>  method.  Yet,  the
C<"boat"> and C<"prepared"> values available for the C<type> parameter
of  the  C<division>  method  are  not  allowed  for  the  C<div-type>
parameter of the C<gcd> method.
=end item

=head1 BUGS, ISSUES AND ACCEPTABLE BREAKS FROM REALITY

For the  various arithmetical methods, not  all parameter combinations
are  used in  real life.  This includes  especially the  C<"cheating">
variants.

The  values  assigned  to  the   C<level>  attribute  are  not  always
consistent and  they may lead to  awkward listings, in which  a boring
part is  printed in whole  detail and  an interesting part  is printed
without enough detail.

=head1 SECURITY MATTERS

As said above, the numbers are not limited in length. The flip side is
that  the  user can  ask  for  the  multiplication of  two  1000-digit
numbers, which  means several millions of  basic actions (single-digit
multiplications, basic  additions, etc). This  can lead to  a DOS-like
situation: filled-up memory, clogged CPU for example.

Another issue is the initialisation of a C<Arithmetic::PaperAndPencil>
object with a  CSV file. The content  of the CSV file  is not checked.
This  can  result  is  line  and column  coordinates  ranging  in  the
thousands or  beyond. In this  case, the  C<html> method will  build a
huge string result.

=head1 SEE ALSO

The background of this module is extensively described in the Github repository. See
L<https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-en.md>
(or L<https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-fr.md>
if you speak French).

Raku module dealing with numeric bases:
L<https://raku.land/github:thundergnat/Base::Any>

Perl module similar to this one:
L<https://github.com/jforget/perl-Arithmetic-PaperAndPencil>

HP48 / HP49 programme dealing with divisions:
L<https://www.hpcalc.org/details/5303>

=head1 DEDICATION

This module is dedicated to my  primary school teachers, who taught me
the basics of arithmetics, and even  some advanced features, and to my
secondary  school math  teachers, who  taught me  other advanced  math
concepts and features.

=head1 AUTHOR

Jean Forget <J2N-FORGET@orange.fr>

=head1 COPYRIGHT AND LICENSE

Copyright 2023, 2024 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
