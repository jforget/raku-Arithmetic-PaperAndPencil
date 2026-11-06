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

sub MAIN(
         Str  :$n1                           #= The first number
       , Str  :$n2                           #= The second number
       , Int  :$radix where 2 ≤ * ≤ 36 = 10  #= The radix, between 2 and 36
       , Int  :$hardware-length = 1          #= hardware length: the number of digits in an arithmetic register of the ALU
       , Bool :$knuth = False                #= The second number
       ) {
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
  $result = mult(n1 => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $n1)
               , n2 => Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => $n2)
               , radix => $radix
               , hw-ln => $hardware-length
               , knuth => $knuth);
  print qq:to/EOF/;
  <h1>Final Result</h1>
  $n1 × $n2 = {$result.value}
  </body>
  </html>
  EOF
}

sub mult(Arithmetic::PaperAndPencil::Number :$n1
       , Arithmetic::PaperAndPencil::Number :$n2
       , Int  :$radix
       , Int  :$hw-ln
       , Bool :$knuth
       --> Arithmetic::PaperAndPencil::Number
       ) {

  if $n1.chars == 1 && $n2.chars == 1 {
    my Arithmetic::PaperAndPencil::Number $result = $n1 ☈× $n2;
    print qq:to/EOF/;
    <h1>Mental Multiplication</h1>
    n1 × n2 = {$n1.value} × {$n2.value} = {$result.value}
    EOF
    return $result;
  }

  if $n1.chars ≤ $hw-ln && $n2.chars ≤ $hw-ln {
    my Arithmetic::PaperAndPencil::Number $result;
    my Arithmetic::PaperAndPencil         $sheet .= new;
    $result = $sheet.multiplication(multiplicand => $n1, multiplier => $n2);

    my $text = $sheet.html(level => 0, silent => True, lang=> 'fr');
    $text ~~ s:g/ '<' '/'? 'strong>' //;
    $text ~~ s/.* '<pre>'/<pre>/;

    print qq:to/EOF/;
    <h1>Hardware Multiplication</h1>
    $text
    EOF

    return $result;
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
