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
  print qq:to/EOF/;
  <html>
  <head>
  <title>Multiplication $n1 × {$n2}</title>
  </head>
  <body>
  <p>ALU: {$hardware-length} digit$plural in radix {$radix}</p>
  EOF
  my Arithmetic::PaperAndPencil::Number $result;
  $result = mult(a => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $n1)
               , b => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $n2)
               , radix => $radix
               , hw-ln => $hardware-length
               , knuth => $knuth
               , links => %(current => $href));
  print qq:to/EOF/;
  <h1>Final Result</h1>
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

    my Str $links = '';
    if %links<upper> {
      $links = "Upper step <a href='#%links<upper>-b'>begin</a> <a href='#%links<upper>-e'>end</a>";
    }
    if $links {
      $links = "<p>{$links}</p>";
    }
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

    my $text = $sheet.html(level => 0, silent => True, lang=> 'fr');
    $text ~~ s:g/ '<' '/'? 'strong>' //;
    $text ~~ s/.* '<pre>'/<pre>/;

    my Str $links = '';
    if %links<upper> {
      $links = "Upper step <a href='#%links<upper>-b'>begin</a> <a href='#%links<upper>-e'>end</a>";
    }
    if $links {
      $links = "<p>{$links}</p>";
    }

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
    if %links<upper> {
      $links = "Upper step <a href='#%links<upper>-b'>begin</a> <a href='#%links<upper>-e'>end</a> ";
    }
    if %links<current> {
      $links ~= ", current step <a href='#%links<current>-e'>end</a> ";
    }
    if $links {
      $links ~~ s/^ ', ' (\w)/{ $0.uc }/;
      $links = "<p>{$links}</p>";
    }

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
      $a1-b1 = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $a1.value)
                  , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $b1.value)
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
      $a1-b0 = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $a1.value)
                  , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $b0.value)
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
      $a0-b1 = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $a0.value)
                  , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $b1.value)
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
      $a0-b0 = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $a0.value)
                  , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $b0.value)
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

    my $text = $sheet.html(level => 0, silent => True, lang=> 'fr');
    $text ~~ s:g/ '<' '/'? 'strong>' //;
    $text ~~ s/.* '<pre>'/<pre>/;

    $links = '';
    if %links<upper> {
      $links = "Upper step <a href='#%links<upper>-b'>begin</a> <a href='#%links<upper>-e'>end</a>";
    }
    if %links<current> {
      $links ~= ", current step <a href='#%links<current>-b'>begin</a> ";
    }
    if $links {
      $links ~~ s/^ ', ' (\w)/{ $0.uc }/;
      $links = "<p>{$links}</p>";
    }

    print qq:to/EOF/;
    <h1 id='%links<current>-e'>Naive Multiplication {$a.value} × {$b.value} (continued)</h1>
    $links
    <p>   a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = {$a1-b1.value}
    <br />a<sub>1</sub> × b<sub>0</sub> = {$a1.value} × {$b0.value} = {$a1-b0.value}
    <br />a<sub>0</sub> × b<sub>1</sub> = {$a0.value} × {$b1.value} = {$a0-b1.value}
    <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = {$a0-b0.value}</p>
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
      $α-formula = $sheet.html(level => 0, silent => True, lang=> 'fr');
      $α-formula ~~ s:g/ '<' '/'? 'strong>' //;
      $α-formula ~~ s/.* '<pre>'/<pre>/;
      $α-formula ~= "<p>α = a<sub>0</sub> - a<sub>1</sub> = {$a0.value} - {$a1.value} = {$α.value}</p>";
      $α-comparison = "a<sub>1</sub> &lt; a<sub>0</sub>";
      $αβ-sign = 1;
    }
    else {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $α = $sheet.subtraction(high => $a1, low => $a0);
      $α-formula = $sheet.html(level => 0, silent => True, lang=> 'fr');
      $α-formula ~~ s:g/ '<' '/'? 'strong>' //;
      $α-formula ~~ s/.* '<pre>'/<pre>/;
      $α-formula ~= "<p>α = a<sub>1</sub> - a<sub>0</sub> = {$a0.value} - {$a1.value} = {$α.value}</p>";
      $α-comparison = "a<sub>1</sub> &gt; a<sub>0</sub>";
      $αβ-sign = -1;
    }
    if $b1 ☈< $b0 {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $β = $sheet.subtraction(high => $b0, low => $b1);
      $β-formula = $sheet.html(level => 0, silent => True, lang=> 'fr');
      $β-formula ~~ s:g/ '<' '/'? 'strong>' //;
      $β-formula ~~ s/.* '<pre>'/<pre>/;
      $β-formula ~= "<p>β = b<sub>0</sub> - b<sub>1</sub> = {$b0.value} - {$b1.value} = {$β.value}</p>";
      $β-comparison = "b<sub>1</sub> &lt; b<sub>0</sub>";
      $αβ-sign = - $αβ-sign;
    }
    else {
      my Arithmetic::PaperAndPencil $sheet .= new;
      $β = $sheet.subtraction(high => $b1, low => $b0);
      $β-formula = $sheet.html(level => 0, silent => True, lang=> 'fr');
      $β-formula ~~ s:g/ '<' '/'? 'strong>' //;
      $β-formula ~~ s/.* '<pre>'/<pre>/;
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

    my Str $links = '';
    if %links<upper> {
      $links = "Upper step <a href='#%links<upper>-b'>begin</a> <a href='#%links<upper>-e'>end</a> ";
    }
    if %links<current> {
      $links ~= ", current step <a href='#%links<current>-e'>end</a> ";
    }
    if $links {
      $links ~~ s/^ ', ' (\w)/{ $0.uc }/;
      $links = "<p>{$links}</p>";
    }

    my Str $a1-b1-href = ++$href;
    my Str $a0-b0-href = ++$href;
    my Str $α-β-href   = '';
    if $αβ-sign ne 0 {
      $α-β-href = ++$href;
      $αβ-value = "<a href='#{$α-β-href}-b'>{$unknown}</a>";
    }
    print qq:to/EOF/;
    <h1 id='%links<current>-b'>Multiplication {$a.value} × {$b.value}</h1>
    $links
    <p>a = {$a1.value} × 10<sup>{$scale}</sup> + {$a0.value}
    <br />b = {$b1.value} × 10<sup>{$scale}</sup> + {$b0.value}</p>
    $α-formula
    $β-formula
    <p>   a<sub>1</sub> × b<sub>1</sub> = {$a1.value} × {$b1.value} = <a href='#{$a1-b1-href}-b'>{$unknown}</a>
    <br />a<sub>0</sub> × b<sub>0</sub> = {$a0.value} × {$b0.value} = <a href='#{$a0-b0-href}-b'>{$unknown}</a>
    <br />α             × β             = {$α.value}  × {$β.value}  = $αβ-value $αβ-operation </p>
    EOF

    $a1-b1 = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $a1.value)
                , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $b1.value)
                , radix => $radix
                , hw-ln => $hw-ln
                , knuth => $knuth
                , links => %(upper => %links<current>, current => $a1-b1-href)
                );
    $a0-b0 = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $a0.value)
                , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $b0.value)
                , radix => $radix
                , hw-ln => $hw-ln
                , knuth => $knuth
                , links => %(upper => %links<current>, current => $a0-b0-href)
                );
    if $αβ-sign ne 0 {
      $α-β = mult(a     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $α.value)
                , b     => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $β.value)
                , radix => $radix
                , hw-ln => $hw-ln
                , knuth => $knuth
                , links => %(upper => %links<current>, current => $α-β-href)
                );
    }
  }

  return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => '0');
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
