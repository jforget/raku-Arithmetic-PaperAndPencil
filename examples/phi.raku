#!/usr/bin/env raku
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Computing the golden ratio φ with some radix
#
# Copyright 2024 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.
#

use lib '../lib';
use Arithmetic::PaperAndPencil;

sub phi(Int $radix, Int $scale) {
  my $zero = '0' x $scale;

  my @five = <101 12 11 10>;
  my Str $x5 = '5';
  if $radix < 6 {
    $x5 = @five[$radix - 2];
  }

  my Str $x2 = '2';
  if $radix == 2 {
    $x2 = '10';
  }

  my Arithmetic::PaperAndPencil $op .= new;
  my Arithmetic::PaperAndPencil::Number $five .= new(:radix($radix), :value($x5 ~ $zero ~ $zero));
  my Arithmetic::PaperAndPencil::Number $one  .= new(:radix($radix), :value('1' ~ $zero));
  my Arithmetic::PaperAndPencil::Number $two  .= new(:radix($radix), :value($x2));
  my Arithmetic::PaperAndPencil::Number $x = $op.square-root($five);
  $x = $op.addition($one, $x);
  $x = $op.division(dividend => $x, divisor => $two);
  return $x.value;
}

sub MAIN(
         Int :$radix where 2 ≤ * ≤ 36  #= The radix, between 2 and 36
       , Int :$scale = 10              #= scale: the number of digits after the (not displayed) decimal point
       ) {
  say phi($radix, $scale);
}

=begin POD

=encoding utf8

=head1 NAME

phi.raku --computing the golden ratio φ with some radix

=head1 DESCRIPTION

This programme displays the value of φ in any radix (2 to 36).

Note: the decimal point is not printed.

=head1 USAGE

  raku phi.raku --radix=16 --scale=15

=head1 Parameters

=head2 radix

The radix. This parameter is mandatory. Allowed values are 2 to 36.

=head2 scale

The  number of  digits to  display.  This parameter  is optional.  Its
default value is 10.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text  of the license  is available in  the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
