#!/usr/bin/env raku
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Computing √2 : comparison between Newton's method and the gallows method
#
# Copyright 2024 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.
#

use lib '../lib';
use Arithmetic::PaperAndPencil;

sub MAIN(
         Bool :$rat    #= compute √2 using Raku native Rat's
       , Bool :$num    #= compute √2 using Raku native Num's
       , Bool :$paper  #= compute √2 using Arithmetic::PaperAndPencil and Newton's method
       , Bool :$direct #= compute √2 using Arithmetic::PaperAndPencil and the gallows method
       ) {
  test-rat()     if $rat;
  test-num()     if $num;
  test-pp()      if $paper;
  test-direct()  if $direct;
}

sub test-rat {
  my Rat $x  = 2.Rat;
  my Rat $r1;
  my Num $ε  = 1e-8;
  my Rat $r2 = 1.Rat;
  my Int $n;
  my Int $n-max = 1000;

  for 1 .. $n-max -> $n {
    $r1 = $r2;
    $r2 = 0.5 × ($r1 + $x / $r1);
    say $n, ' ', $r2.Num, ' ', $r2.raku;
    if ($r1 - $r2).abs < $ε {
      last;
    }
  }
}

sub test-num {
  my Num $x  = 2.Num;
  my Num $r1;
  my Num $ε  = 1e-8;
  my Num $r2 = 1.Num;
  my Int $n;
  my Int $n-max = 1000;

  for 1 .. $n-max -> $n {
    $r1 = $r2;
    $r2 = ½ × ($r1 + $x / $r1);
    say $n, ' ', $r2.Num;
    if ($r1 - $r2).abs < $ε {
      last;
    }
  }
}

sub test-pp {
  my Arithmetic::PaperAndPencil $operation  .= new;
  my Int $prec = 8;
  my Str $zero = '0' x $prec;

  my Arithmetic::PaperAndPencil::Number $two .= new(radix => 10, value => '2');
  my Arithmetic::PaperAndPencil::Number $xx  .= new(radix => 10, value => '2' ~ $zero ~ $zero);
  my Arithmetic::PaperAndPencil::Number $rr1;
  my Arithmetic::PaperAndPencil::Number $rr2 .= new(radix => 10, value => '1' ~ $zero);
  my Int $prev  = 0;
  my Int $n-max = 1000;

  for 1 .. $n-max -> $n {
    $rr1 = $rr2;
    $rr2 = $operation.division(dividend => $xx, divisor => $rr1, type => 'cheating');
    my Int $div = $operation.action.elems - $prev;
    $prev = $operation.action.elems;
    $rr2 = $operation.addition($rr1, $rr2);
    my Int $add = $operation.action.elems - $prev;
    $prev = $operation.action.elems;
    $rr2 = $operation.division(dividend => $rr2, divisor => $two, type => 'cheating');
    my Int $hlf = $operation.action.elems - $prev;
    $prev = $operation.action.elems;
    say $n, ' ', $rr2.value, ' ', $operation.action.elems, " division $div addition $add halving $hlf";
    if $rr1.value eq $rr2.value {
      last;
    }
  }
  'Newton.html'.IO.spurt($operation.html(lang => 'fr', silent => True, level => 0));
  'Newton.csv' .IO.spurt($operation.csv);
}

sub test-direct {
  my Arithmetic::PaperAndPencil $operation  .= new;
  my Int $prec = 8;
  my Str $zero = '0' x $prec;

  my Arithmetic::PaperAndPencil::Number $xx  .= new(radix => 10, value => '2' ~ $zero ~ $zero);
  $xx = $operation.square-root($xx);
  say $xx.value, ' ', $operation.action.elems;
  'gallows.csv'.IO.spurt($operation.csv);
}

=begin POD

=head1 NAME

comparison-Newton-gallows.raku -- computing √2 with Newton's method using various implementations

=head1 DESCRIPTION

This programme computes √2 with 8 decimal digits using Newton's method.
The computation can use C<Rat>, C<Num> or C<Arithmetic::PaperAndPencil>.
When using C<Arithmetic::PaperAndPencil>, the programme displays a few
statistics on elementary actions and it stores the generated
CSV and HTML files.

Also, the programme may compute √2 with the gallows method
and C<Arithmetic::PaperAndPencil> values. Statistics are displayed
and the CSV file is generated (but not the HTML file).

=head1 USAGE

  raku conv-pi.raku comparison-Newton-gallows.raku --rat --num --paper --direct

=head1 Parameters

=head2 rat

Boolean parameter triggering the computation with C<Rat> values.

=head2 num

Boolean parameter triggering the computation with C<Num> values.

=head2 paper

Boolean parameter triggering the computation with
C<Arithmetic::PaperAndPencil> values.

=head2 direct

Boolean parameter triggering the computation with
C<Arithmetic::PaperAndPencil> values but with the gallows
method instead of Newton's method.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text  of the license  is available in  the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
