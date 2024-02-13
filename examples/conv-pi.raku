#!/usr/bin/env raku
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Converting π to some radix
#
# Copyright 2024 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.
#

use lib '../lib';
use Arithmetic::PaperAndPencil;

sub conv-pi(Int $b where 2 ≤ * ≤ 36, Int $scale-b) {
  # https://en.wikipedia.org/wiki/Pi#Approximate_value_and_digits
  # https://oeis.org/A000796
  my Str $pi-alpha = '314159265358979323846264338327950288419716939937510';

  my Int $scale10 = ($scale-b × log($b, 10)).ceiling;
  if $scale10 > $pi-alpha.chars {
    my Int $scale-max = ($pi-alpha.chars / log($b, 10)).floor;
    die "Scale $scale-b to long, maximum allowed value $scale-max";
  }
  my Arithmetic::PaperAndPencil $operation  .= new;
  my Arithmetic::PaperAndPencil::Number $factor-b .= new(:radix(10), :value(($b ** $scale-b).Str));
  my Arithmetic::PaperAndPencil::Number $factor10 .= new(:radix(10), :value('1' ~ '0' x $scale10));
  $factor10 = $operation.conversion(number => $factor10, radix => $b);

  my Arithmetic::PaperAndPencil::Number $pi-x10   .= new(:radix(10), :value($pi-alpha.substr(0, 1 + $scale10)));
  my Arithmetic::PaperAndPencil::Number $pi-x10-xb = $operation.multiplication(multiplicand => $pi-x10, multiplier => $factor-b);
  $pi-x10-xb = $operation.conversion(number => $pi-x10-xb, radix => $b);
  my Arithmetic::PaperAndPencil::Number $pi-xb = $operation.division(dividend => $pi-x10-xb, divisor => $factor10);
  return $pi-xb.value;
}

sub MAIN(
         Int :$radix where 2 ≤ * ≤ 36  #= The destination radix, between 2 and 36
       , Int :$scale = 10              #= scale: the number of digits after the (not displayed) decimal point
       ) {
  say conv-pi($radix, $scale);
}

=begin POD

=encoding utf8

=head1 NAME

conv-pi.raku -- converting π to a radix other than 10

=head1 DESCRIPTION

This programme displays the value of π in any radix (2 to 36)
and with a precision equivalent to 50 radix-10 digits.

Note: the decimal point is not printed.

=head1 USAGE

  raku conv-pi.raku --radix=16 --scale=15

=head1 Parameters

=head2 radix

The destination radix.

This parameter is mandatory. Allowed values are 2 to 36.

=head2 scale

The number of digits to display.  The maximum allowed value depends on
the radix. It is the number of digits for the conversion of a 50-digit
decimal number. For example,  with radix 2 you can ask  for a scale of
169 digits while with radix 36 you can ask for no more than 32 digits.

This parameter is optional. Its default value is 10.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text  of the license  is available in  the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
