#!/usr/bin/env raku
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Computing a multiplication using Karatsuba's method
#
# Copyright 2026 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.
#

use lib '../lib';
use Arithmetic::PaperAndPencil;
use Arithmetic::PaperAndPencil::Number;

my  Arithmetic::PaperAndPencil::Number $zero;
my  Str $unknown = '???';
my  Str $href = 'a';

sub MAIN(
         Str  :$n1                           #= The first number
       , Str  :$n2                           #= The second number
       , Int  :$radix where 2 ≤ * ≤ 36 = 10  #= The radix, between 2 and 36
       , Int  :$hardware-length = 1          #= hardware length: the number of digits in an arithmetic register of the ALU
       , Bool :$knuth = False                #= The second number
       ) {
  $zero .= new(radix => $radix, value => '0');

  my Str $plural = '';
  if $hardware-length > 1 {
    $plural = 's';
  }
  my Str $href-top = $href;
  print qq:to/EOF/;
  <html>
  <head>
  <title>Multiplication $n1 × {$n2}</title>
  </head>
  <body>
  <h1 id='{$href-top}-b'>Multiplication $n1 × {$n2}</h1>
  <p>ALU: {$hardware-length} digit$plural in radix {$radix}</p>
  EOF
  my Arithmetic::PaperAndPencil::Number $result;
  $result = mult(a => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $n1)
               , b => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $n2)
               , radix => $radix
               , hw-ln => $hardware-length
               , knuth => $knuth
               , links => %(upper => $href-top, current => ++$href));
  print qq:to/EOF/;
  <h1 id='{$href-top}-e'>Final Result</h1>
  $n1 × $n2 = {$result.value}
  </body>
  </html>
  EOF
}

sub mult(Arithmetic::PaperAndPencil::Number :$a
       , Arithmetic::PaperAndPencil::Number :$b
       , Int  :$radix
       , Int  :$hw-ln
       , Bool :$knuth
       ,      :%links
       --> Arithmetic::PaperAndPencil::Number
       ) {

  if $a.chars == 1 && $b.chars == 1 {
    my Arithmetic::PaperAndPencil::Number $result = $a ☈× $b;

    my Str $links = format-link(%links, '');
    print qq:to/EOF/;
    <h1 id='%links<current>-b'>Direct Multiplication {$a.value} × {$b.value}</h1>
    $links
    a × b = {$a.value} × {$b.value} = {$result.value}
    EOF
    return $result;
  }

  if $a.chars ≤ $hw-ln && $b.chars ≤ $hw-ln {
    my Arithmetic::PaperAndPencil::Number $result;
    my Arithmetic::PaperAndPencil         $sheet .= new;
    $result = $sheet.multiplication(multiplicand => $a, multiplier => $b);

    my Str $text  = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
    my Str $links = format-link(%links, '');

    print qq:to/EOF/;
    <h1 id='%links<current>-b'>Hardware Multiplication {$a.value} × {$b.value}</h1>
    $links
    $text
    EOF

    return $result;
  }

  # Basic divide and conquer
  my Int $scale  = $hw-ln;
  my Int $ln     = $hw-ln;
  my Int $target = $a.chars max $b.chars;
  while $ln < $target {
    $scale = $ln;
    $ln ×= 2;
  }
  my Arithmetic::PaperAndPencil::Number $a0 = $a.unit( $scale);
  my Arithmetic::PaperAndPencil::Number $a1 = $a.carry($scale);
  my Arithmetic::PaperAndPencil::Number $b0 = $b.unit( $scale);
  my Arithmetic::PaperAndPencil::Number $b1 = $b.carry($scale);

  # Naive computation
  my Arithmetic::PaperAndPencil::Number $a0-b0;
  my Arithmetic::PaperAndPencil::Number $a0-b1;
  my Arithmetic::PaperAndPencil::Number $a1-b0;
  my Arithmetic::PaperAndPencil::Number $a1-b1;
  my Str $a0-b0-value = $unknown;
  my Str $a0-b1-value = $unknown;
  my Str $a1-b0-value = $unknown;
  my Str $a1-b1-value = $unknown;
  my Str $naive-reason = '';

  if $b1.value eq '1' { $naive-reason = 'b<sub>1</sub> = 1'; $a0-b1-value = $a0.value; $a1-b1-value = $a1.value; }
  if $b0.value eq '1' { $naive-reason = 'b<sub>0</sub> = 1'; $a0-b0-value = $a0.value; $a1-b0-value = $a1.value; }
  if $a1.value eq '1' { $naive-reason = 'a<sub>1</sub> = 1'; $a1-b0-value = $b0.value; $a1-b1-value = $b1.value; }
  if $a0.value eq '1' { $naive-reason = 'a<sub>0</sub> = 1'; $a0-b0-value = $b0.value; $a0-b1-value = $b1.value; }
  if $b1.value eq '0' { $naive-reason = 'b<sub>1</sub> = 0'; $a0-b1-value = '0'      ; $a1-b1-value = '0'; }
  if $b0.value eq '0' { $naive-reason = 'b<sub>0</sub> = 0'; $a0-b0-value = '0'      ; $a1-b0-value = '0'; }
  if $a1.value eq '0' { $naive-reason = 'a<sub>1</sub> = 0'; $a1-b0-value = '0'      ; $a1-b1-value = '0'; }
  if $a0.value eq '0' { $naive-reason = 'a<sub>0</sub> = 0'; $a0-b0-value = '0'      ; $a0-b1-value = '0'; }

  if $naive-reason ne '' {

    my Str $links = '';
    my Str $a0-b0-link = $a0-b0-value;
    my Str $a0-b1-link = $a0-b1-value;
    my Str $a1-b0-link = $a1-b0-value;
    my Str $a1-b1-link = $a1-b1-value;
    if $a1-b1-value eq $unknown { %links<a1-b1> = ++$href; $a1-b1-link = "<a href='#{$href}-b'>{$unknown}</a>"; }
    if $a1-b0-value eq $unknown { %links<a1-b0> = ++$href; $a1-b0-link = "<a href='#{$href}-b'>{$unknown}</a>"; }
    if $a0-b1-value eq $unknown { %links<a0-b1> = ++$href; $a0-b1-link = "<a href='#{$href}-b'>{$unknown}</a>"; }
    if $a0-b0-value eq $unknown { %links<a0-b0> = ++$href; $a0-b0-link = "<a href='#{$href}-b'>{$unknown}</a>"; }
    $links = format-link(%links, 'b');

    print qq:to/EOF/;
    <h1 id='%links<current>-b'>Naive Multiplication {$a.value} × {$b.value}</h1>
    $links
    <p>a = {$a1.value} × 10<sup>{$scale}</sup> + {$a0.value}
    <br />b = {$b1.value} × 10<sup>{$scale}</sup> + {$b0.value}</p>
    <p>$naive-reason, therefore using the naive multiplication method.</p>
    <p>   a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = $a1-b1-link
    <br />a<sub>1</sub> × b<sub>0</sub> = {$a1.value} × {$b0.value} = $a1-b0-link
    <br />a<sub>0</sub> × b<sub>1</sub> = {$a0.value} × {$b1.value} = $a0-b1-link
    <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = $a0-b0-link </p>
    EOF
    if $a1-b1-value ne $unknown {
      $a1-b1 .= new(radix => $radix, value => $a1-b1-value);
    }
    else {
      $a1-b1 = mult(a     => $a1
                  , b     => $b1
                  , radix => $radix
                  , hw-ln => $hw-ln
                  , knuth => $knuth
                  , links => %(upper => %links<current>, current => %links<a1-b1>)
                  );
    }
    if $a1-b0-value ne $unknown {
      $a1-b0 .= new(radix => $radix, value => $a1-b0-value);
    }
    else {
      $a1-b0 = mult(a     => $a1
                  , b     => $b0
                  , radix => $radix
                  , hw-ln => $hw-ln
                  , knuth => $knuth
                  , links => %(upper => %links<current>, current => %links<a1-b0>)
                  );
    }
    if $a0-b1-value ne $unknown {
      $a0-b1 .= new(radix => $radix, value => $a0-b1-value);
    }
    else {
      $a0-b1 = mult(a     => $a0
                  , b     => $b1
                  , radix => $radix
                  , hw-ln => $hw-ln
                  , knuth => $knuth
                  , links => %(upper => %links<current>, current => %links<a0-b1>)
                  );
    }
    if $a0-b0-value ne $unknown {
      $a0-b0 .= new(radix => $radix, value => $a0-b0-value);
    }
    else {
      $a0-b0 = mult(a     => $a0
                  , b     => $b0
                  , radix => $radix
                  , hw-ln => $hw-ln
                  , knuth => $knuth
                  , links => %(upper => %links<current>, current => %links<a0-b0>)
                  );
    }
    my @numbers-to-add = ();
    if $a1-b1.value ne '0' { @numbers-to-add.push($a1-b1 ☈+< (2 × $scale)); }
    if $a1-b0.value ne '0' { @numbers-to-add.push($a1-b0 ☈+<      $scale ); }
    if $a0-b1.value ne '0' { @numbers-to-add.push($a0-b1 ☈+<      $scale ); }
    if $a0-b0.value ne '0' { @numbers-to-add.push($a0-b0                 ); }

    my Arithmetic::PaperAndPencil::Number $result;
    my Arithmetic::PaperAndPencil         $sheet .= new;
    $result = $sheet.addition(numbers => @numbers-to-add, skip-zero => True);

    if %links<a1-b1> { $a1-b1-value = "<a href='#{%links<a1-b1>}-b'>{$a1-b1.value}</a>"; }
    if %links<a1-b0> { $a1-b0-value = "<a href='#{%links<a1-b0>}-b'>{$a1-b0.value}</a>"; }
    if %links<a0-b1> { $a0-b1-value = "<a href='#{%links<a0-b1>}-b'>{$a0-b1.value}</a>"; }
    if %links<a0-b0> { $a0-b0-value = "<a href='#{%links<a0-b0>}-b'>{$a0-b0.value}</a>"; }
    my $text = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
    $links = format-link(%links, 'e');

    print qq:to/EOF/;
    <h1 id='%links<current>-e'>Naive Multiplication {$a.value} × {$b.value} (continued)</h1>
    $links
    <p>   a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = {$a1-b1-value} scaled by 10<sup>{2 × $scale}</sup>
    <br />a<sub>1</sub> × b<sub>0</sub> = {$a1.value} × {$b0.value} = {$a1-b0-value} scaled by 10<sup>{$scale}</sup>
    <br />a<sub>0</sub> × b<sub>1</sub> = {$a0.value} × {$b1.value} = {$a0-b1-value} scaled by 10<sup>{$scale}</sup>
    <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = {$a0-b0-value}</p>
    $text
    EOF

    return $result;
  }

  if $knuth {
    my Arithmetic::PaperAndPencil::Number $α;
    my Arithmetic::PaperAndPencil::Number $β;
    my Arithmetic::PaperAndPencil::Number $α-β;
    my Arithmetic::PaperAndPencil::Number $result;
    my Str $α-formula;
    my Str $β-formula;
    my Str $α-comparison;
    my Str $β-comparison;
    my Int $αβ-sign;
    if $a1 ☈< $a0 {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $α = $sheet.subtraction(high => $a0, low => $a1);
      $α-formula = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
      $α-formula ~= "<p>α = a<sub>0</sub> - a<sub>1</sub> = {$a0.value} - {$a1.value} = {$α.value}</p>";
      $α-comparison = "a<sub>1</sub> &lt; a<sub>0</sub>";
      $αβ-sign = 1;
    }
    else {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $α = $sheet.subtraction(high => $a1, low => $a0);
      $α-formula = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
      $α-formula ~= "<p>α = a<sub>1</sub> - a<sub>0</sub> = {$a0.value} - {$a1.value} = {$α.value}</p>";
      $α-comparison = "a<sub>1</sub> &gt; a<sub>0</sub>";
      $αβ-sign = -1;
    }
    if $b1 ☈< $b0 {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $β = $sheet.subtraction(high => $b0, low => $b1);
      $β-formula = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
      $β-formula ~= "<p>β = b<sub>0</sub> - b<sub>1</sub> = {$b0.value} - {$b1.value} = {$β.value}</p>";
      $β-comparison = "b<sub>1</sub> &lt; b<sub>0</sub>";
      $αβ-sign = - $αβ-sign;
    }
    else {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $β = $sheet.subtraction(high => $b1, low => $b0);
      $β-formula = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
      $β-formula ~= "<p>β = b<sub>1</sub> - b<sub>0</sub> = {$b1.value} - {$b0.value} = {$β.value}</p>";
      $β-comparison = "b<sub>1</sub> &gt; b<sub>0</sub>";
    }
    my Str $αβ-operation;
    if $αβ-sign == 1 {
      $αβ-operation = "added because $α-comparison and $β-comparison";
    }
    else {
      $αβ-operation = "subtracted because $α-comparison and $β-comparison";
    }
    my $αβ-value = $unknown;
    if $α.value eq '0' or $β.value eq '0' {
      $αβ-value     = '0';
      $αβ-operation = "";
      $αβ-sign      = 0;
      $α-β          = $zero;
    }

    my Str $links      = format-link(%links, 'b');
    my Str $a1-b1-href = ++$href;
    my Str $a0-b0-href = ++$href;
    my Str $α-β-href   = '';
    if $αβ-sign ne 0 {
      $α-β-href = ++$href;
      $αβ-value = "<a href='#{$α-β-href}-b'>{$unknown}</a>";
    }
    print qq:to/EOF/;
    <h1 id='%links<current>-b'>Karatsuba-Knuth Multiplication {$a.value} × {$b.value}</h1>
    $links
    <p>a = {$a1.value} × 10<sup>{$scale}</sup> + {$a0.value}
    <br />b = {$b1.value} × 10<sup>{$scale}</sup> + {$b0.value}</p>
    $α-formula
    $β-formula
    <p>   a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = <a href='#{$a1-b1-href}-b'>{$unknown}</a>
    <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = <a href='#{$a0-b0-href}-b'>{$unknown}</a>
    <br />α             × β             = {$α.value}  × {$β.value}  = $αβ-value $αβ-operation </p>
    EOF

    $a1-b1 = mult(a     => $a1
                , b     => $b1
                , radix => $radix
                , hw-ln => $hw-ln
                , knuth => $knuth
                , links => %(upper => %links<current>, current => $a1-b1-href)
                );
    $a0-b0 = mult(a     => $a0
                , b     => $b0
                , radix => $radix
                , hw-ln => $hw-ln
                , knuth => $knuth
                , links => %(upper => %links<current>, current => $a0-b0-href)
                );
    my $αβ-val = '0';
    if $αβ-sign != 0 {
      $α-β = mult(a     => $α
                , b     => $β
                , radix => $radix
                , hw-ln => $hw-ln
                , knuth => $knuth
                , links => %(upper => %links<current>, current => $α-β-href)
                );
       $αβ-val = "<a href='#{$α-β-href}-b'>{$α-β.value}</a>";
    }

    my @numbers-to-add = $a1-b1 ☈+< (2 × $scale), $a1-b1 ☈+< $scale ;
    if $αβ-sign == 1 {
      @numbers-to-add.push($α-β ☈+< $scale);
    }
    @numbers-to-add.push($a0-b0 ☈+< $scale);
    @numbers-to-add.push($a0-b0);

    my Arithmetic::PaperAndPencil $sheet .= new;
    $result = $sheet.addition(numbers => @numbers-to-add, skip-zero => True);
    my Str $addition = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));

    my Str $subtraction = '';
    if $αβ-sign == -1 {
      $sheet .= new;
      $result = $sheet.subtraction(high => $result, low => $α-β ☈+< $scale);
      $subtraction = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
    }

    $links = format-link(%links, 'e');

    print qq:to/EOF/;
    <h1 id='%links<current>-e'>Karatsuba-Knuth Multiplication {$a.value} × {$b.value} (continued)</h1>
    $links
    <p>   a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = <a href='#{$a1-b1-href}-b'>{$a1-b1.value}</a> scaled by 10<sup>{2 × $scale}</sup> and 10<sup>{$scale}</sup></a>
    <br />α × β = {$α.value} × {$β.value} = {$αβ-val} scaled by 10<sup>{$scale}</sup>, $αβ-operation
    <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = <a href='#{$a0-b0-href}-b'>{$a0-b0.value}</a> scaled by 10<sup>{$scale}</sup></a> and by 1</p>
    $addition
    $subtraction
    EOF

    return $result;
  }

  my Arithmetic::PaperAndPencil::Number $α;
  my Arithmetic::PaperAndPencil::Number $β;
  my Arithmetic::PaperAndPencil::Number $α0-β0;
  my Arithmetic::PaperAndPencil $sheet .= new;
  $α = $sheet.addition($a1, $a0);
  my Str $addition-α = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
  $sheet .= new;
  $β = $sheet.addition($b1, $b0);
  my Str $addition-β = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));

  my Arithmetic::PaperAndPencil::Number $α1 = $α.carry($scale);
  my Arithmetic::PaperAndPencil::Number $α0 = $α.unit( $scale);
  my Arithmetic::PaperAndPencil::Number $β1 = $β.carry($scale);
  my Arithmetic::PaperAndPencil::Number $β0 = $β.unit( $scale);

  my Str $links = format-link(%links, 'b');
  my Str $a1-b1-href = ++$href;
  my Str $α0-β0-href = ++$href;
  my Str $a0-b0-href = ++$href;
  print qq:to/EOF/;
  <h1 id='%links<current>-b'>Karatsuba Multiplication {$a.value} × {$b.value}</h1>
  $links
  <p>a = {$a1.value} × 10<sup>{$scale}</sup> + {$a0.value}
  <br />b = {$b1.value} × 10<sup>{$scale}</sup> + {$b0.value}</p>
  $addition-α
  $addition-β
  <p>   α = {$a1.value} + {$a0.value} = {$α.value} = {$α1.value} × 10<sup>{$scale}</sup> + {$α0.value}
  <br />β = {$b1.value} + {$b0.value} = {$β.value} = {$β1.value} × 10<sup>{$scale}</sup> + {$β0.value}
  <br />a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = <a href='#{$a1-b1-href}-b'>{$unknown}</a>
  <br />α<sub>0</sub> × β<sub>0</sub> = {$α0.value} × {$β0.value} = <a href='#{$α0-β0-href}-b'>{$unknown}</a>
  <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = <a href='#{$a0-b0-href}-b'>{$unknown}</a> </p>
  EOF

  $a1-b1 = mult(a     => $a1
              , b     => $b1
              , radix => $radix
              , hw-ln => $hw-ln
              , knuth => $knuth
              , links => %(upper => %links<current>, current => $a1-b1-href)
              );
  $α0-β0 = mult(a     => $α0
              , b     => $β0
              , radix => $radix
              , hw-ln => $hw-ln
              , knuth => $knuth
              , links => %(upper => %links<current>, current => $α0-β0-href)
              );
  $a0-b0 = mult(a     => $a0
              , b     => $b0
              , radix => $radix
              , hw-ln => $hw-ln
              , knuth => $knuth
              , links => %(upper => %links<current>, current => $a0-b0-href)
              );

  my Str $show-α1-β1 = '';
  my Str $show-α0    = '';
  my Str $show-β0    = '';
  my @numbers-to-add = ();
  my @numbers-to-sub = $a1-b1 ☈+< $scale, $a0-b0 ☈+< $scale;
  if $α1.value eq '1' and $β1.value eq '1' {
    @numbers-to-add.push(Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => '1' ~ '0' x (3 × $scale)));
    $show-α1-β1 = "α<sub>1</sub> = β<sub>1</sub> = 1 scaled by 10<sup>{3 × $scale}</sup><br />";
  }
  @numbers-to-add.push($a1-b1 ☈+< (2 × $scale));
  if $β1.value eq '1' {
    @numbers-to-add.push($α0 ☈+< (2 × $scale));
    $show-α0 = "<br />α<sub>0</sub> = {$α0.value} scaled by 10<sup>{2 × $scale}</sup> and β<sub>1</sub> = 1";
  }
  if $α1.value eq '1' {
    @numbers-to-add.push($β0 ☈+< (2 × $scale));
    $show-β0 = "<br />β<sub>0</sub> = {$β0.value} scaled by 10<sup>{2 × $scale}</sup> and α<sub>1</sub> = 1";
  }
  @numbers-to-add.push($α0-β0 ☈+< $scale);
  @numbers-to-add.push($a0-b0);
  $sheet .= new;
  my Arithmetic::PaperAndPencil::Number $res1 = $sheet.addition(@numbers-to-add);
  my Str $addition1 = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
  $sheet .= new;
  my Arithmetic::PaperAndPencil::Number $res2 = $sheet.addition(@numbers-to-sub);
  my Str $addition2 = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));
  $sheet .= new;
  my Arithmetic::PaperAndPencil::Number $result = $sheet.subtraction(high => $res1, low => $res2);
  my Str $subtraction = extract-op($sheet.html(level => 0, silent => True, lang=> 'fr'));

  $links = format-link(%links, 'e');

  print qq:to/EOF/;
  <h1 id='%links<current>-e'>Karatsuba Multiplication {$a.value} × {$b.value} (continued)</h1>
  $links
  <p>$show-α1-β1
  a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = <a href='#{$a1-b1-href}-b'>{$a1-b1.value}</a> scaled by 10<sup>{2 × $scale}</sup> in the addition and by 10<sup>{$scale}</sup></a> in the subtraction
  $show-α0
  $show-β0
  <br />α<sub>0</sub> × β<sub>0</sub> = {$α0.value} × {$β0.value} = <a href='#{$α0-β0-href}-b'>{$α0-β0.value}</a> scaled by 10<sup>{$scale}</sup>
  <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = <a href='#{$a0-b0-href}-b'>{$a0-b0.value}</a> scaled by 10<sup>{$scale}</sup></a> in the subtraction and by 1 in the addition</p></p>
  $addition1
  $addition2
  $subtraction
  EOF

  return $result;
}

sub extract-op(Str $in --> Str) {
  my $out = $in;
  $out ~~ s:g/ '<' '/'? 'strong>' //;
  $out ~~ s/.* '<pre>'/<pre>/;
  return $out;
}

sub format-link(%links, Str $type -->Str) {
  my @links = "Upper step  <a href='#%links<upper>-b'>begin</a> <a href='#%links<upper>-e'>end</a>";
  given $type {
    when 'b' { @links.push("current <a href='#%links<current>-e'>end</a>"  ); }
    when 'e' { @links.push("current <a href='#%links<current>-b'>begin</a>"); }
  }
  return "<p>" ~ @links.join(', ') ~ "</p>";
}

=begin POD

=encoding utf8

=head1 NAME

karatsuba.raku --computing a multiplication using Karatsuba's method

=head1 DESCRIPTION

This programme prints an HTML file to the standard output, with
all steps of a multiplication using Karatsuba's method.

=head1 USAGE

  raku karatsuba.raku --radix=10 --hardware-length=1 --n1=123 --n2=456

=head1 Parameters

=head2 n1, n2

The numbers  for the  multiplication. Mandatory.  They are  entered as
strings because they may represent numbers in a radix higher than 10.

=head2 radix

The radix. Allowed values are 2 to 36. Default value is 10.

=head2 hardware-length

The number of digits which the simulated Arithmetic and Logic Unit can
store in its arithmetic registers. Default is 1.

=head2 knuth

Boolean parameter allowing the choice between the Karatsuba's standard
method and Knuth's variant. Default is False (= standard).

=head1 COPYRIGHT and LICENCE

Copyright (C) 2026, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text  of the license  is available in  the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
