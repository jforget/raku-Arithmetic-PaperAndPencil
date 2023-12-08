# -*- encoding: utf-8; indent-tabs-mode: nil -*-

unit class Arithmetic::PaperAndPencil::Number:ver<0.0.1>:auth<cpan:JFORGET>;

my @digits = ('0' .. '9', 'A' .. 'Z').flat;

has Str $.value;
has Int $.radix;

method BUILD(Str:D :$value, Int:D :$radix = 10) {
  self!check-build-args($value, $radix);
  self!build-from-args( $value, $radix);
}

method !check-build-args(Str $value, Int $radix) {
  unless 2 ≤ $radix ≤ 36 {
    X::OutOfRange.new(:what<radix>, :got($radix), :range<2..36>).throw;
  }
  my @radix-digits = @digits[ 0 ..^ $radix ];
  unless $value ~~ /^ @radix-digits + $/ {
    X::Invalid::Value.new(:method<BUILD>, :name<value>, :value($value)).throw;
  }
}

method !build-from-args(Str $value, Int $radix) {
  $!value = $value;
  $!radix = $radix;
  $!value ~~ s/^ 0+ //; # remove leading zeros
  if $!value eq '' {
    # oops! we removed all zero digits, leaving none for number zero
    $!value = '0';
  }
}

method gist {
  $.value;
}

method chars {
  $.value.chars;
}

method unit(Int $len is copy = 1) {
  my Str $s = $.value;
  if $len > $s.chars {
    $len = $s.chars;
  }
  my Arithmetic::PaperAndPencil::Number $unit .= new(value => $s.substr(* - $len, $len), radix => $.radix);
  return $unit;
}

method carry(Int $len = 1) {
  my Str $s = $.value;
  if $s.chars ≤ $len {
    return Arithmetic::PaperAndPencil::Number.new(value => '0', radix => $.radix);
  }
  else {
    return Arithmetic::PaperAndPencil::Number.new(value => $s.substr(0, $s.chars - $len), radix => $.radix);
  }
}

sub max-unit (Int $radix --> Arithmetic::PaperAndPencil::Number) is export {
  unless 2 ≤ $radix ≤ 36 {
    X::OutOfRange.new(:what<radix>, :got($radix), :range<2..36>).throw;
  }
  return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => @digits[$radix - 1]);
}

method !native-int {
  if $.chars > 2 {
    die "Conversion to native allowed only for 1-digit numbers or 2-digit numbers";
  }
  my Int $tens  = @digits.first: * eq $.carry.value, :k;
  my Int $units = @digits.first: * eq $.unit .value, :k;
  return $tens × $.radix + $units;
}

sub infix:<☈+> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y) is export {
  if $x.radix != $y.radix {
    die "Addition not allowed with different bases: {$x.radix} {$y.radix}";
  }
  if $x.chars != 1 and $y.chars != 1 {
    die "Addition allowed only if at least one number has a single digit";
  }
  my Str @long-op;
  my Str $short-op;
  if $x.chars == 1 {
    $short-op = $x.value;
    @long-op  = ('0' ~ $y.value).comb.reverse;
  }
  else {
    $short-op = $y.value;
    @long-op  = ('0' ~ $x.value).comb.reverse;
  }
  my Str $digit-nine = @digits[$x.radix - 1];  # '9' for radix 10, 'F' for radix 16, and so on
  my Int $a = @digits.first: * eq $short-op  , :k;
  my Int $b = @digits.first: * eq @long-op[0], :k;
  if $a + $b < $x.radix {
    # no carry
    @long-op[0] = @digits[$a + $b];
    return Arithmetic::PaperAndPencil::Number.new(value => @long-op.reverse.join('')
                                                , radix => $x.radix);
  }
  @long-op[0] = @digits[$a + $b - $x.radix];
  for 1..@long-op.elems -> $i {
     if @long-op[$i] ne $digit-nine {
       @long-op[$i] = @digits[1 + @digits.first: * eq @long-op[$i], :k];
       last;
     }
     @long-op[$i] = '0';
  }
  return Arithmetic::PaperAndPencil::Number.new(value => @long-op.reverse.join('')
                                              , radix => $x.radix);
}

sub infix:<☈-> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y) is export {
  my Int $radix = $x.radix;
  if $radix != $y.radix {
    die "Subtraction not allowed with different bases: $radix {$y.radix}";
  }
  if $x.chars != 1 or $y.chars != 1 {
    die "Subtraction allowed only for single-digit numbers";
  }
  if $x.value lt $y.value {
    die "The first number must be greater or equal to the second number";
  }
  my Int $x10 = $x!native-int;
  my Int $y10 = $y!native-int;
  my Int $z10 = $x10 - $y10;
  return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => @digits[$z10]);
}

sub infix:<☈×> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y) is export {
  if $x.radix != $y.radix {
    die "Multiplication not allowed with different bases: {$x.radix} {$y.radix}";
  }
  if $x.chars != 1 or $y.chars != 1 {
    die "Multiplication allowed only for single-digit factors";
  }
  my Int $x10 = $x!native-int;
  my Int $y10 = $y!native-int;
  my Int $z10 = $x10 × $y10;
  my Int $zu  = $z10 % $x.radix;
  my Int $zt  = ($z10 / $x.radix).floor;
  return Arithmetic::PaperAndPencil::Number.new(value => @digits[$zt] ~ @digits[$zu]
                                              , radix => $x.radix);
}

sub infix:<☈÷> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y) is export {
  my Int $radix = $x.radix;
  if $radix != $y.radix {
    die "Division not allowed with different bases: $radix {$y.radix}";
  }
  if $x.chars > 2 {
    die "The dividend must be a 1- or 2-digit number";
  }
  if $y.chars > 1 {
    die "The divisor must be a single-digit number";
  }
  if $y.value eq '0' {
    die "Division by 0 not allowed";
  }
  my Int $xx = $x!native-int;
  my Int $yy = $y!native-int;
  my Int $qq = ($xx / $yy).floor;
  if $qq ≥ $radix {
    my @qq = $qq.polymod($radix);
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => @digits[@qq[1]] ~ @digits[@qq[0]]);
  }
  else {
    return Arithmetic::PaperAndPencil::Number.new(radix => $radix, value => @digits[$qq]);
  }
}

sub infix:«☈<=>» (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y --> Order) is export {
  if $x.radix != $y.radix {
    die "Comparison not allowed with different bases: {$x.radix} {$y.radix}";
  }
  return $x.chars <=> $y.chars
                   ||
         $x.value leg $y.value;
}

sub infix:<☈leg> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y --> Order) is export {
  if $x.radix != $y.radix {
    die "Comparison not allowed with different bases: {$x.radix} {$y.radix}";
  }
  return $x.value leg $y.value;
}

sub infix:«☈<» (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y --> Bool) is export {
  if $x.radix != $y.radix {
    die "Comparison not allowed with different bases: {$x.radix} {$y.radix}";
  }
  return ($x ☈<=> $y) == Order::Less;
}

sub infix:«☈≤» (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y --> Bool) is export {
  if $x.radix != $y.radix {
    die "Comparison not allowed with different bases: {$x.radix} {$y.radix}";
  }
  return True if $x ☈< $y;
  return ($x ☈<=> $y) == Order::Same;
}

sub infix:<☈lt> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y --> Bool) is export {
  if $x.radix != $y.radix {
    die "Comparison not allowed with different bases: {$x.radix} {$y.radix}";
  }
  return ($x ☈leg $y) == Order::Less;
}

method complement(Int $len) {
  my Str $s     = $.value;
  my Int $radix = $.radix;
  if $s.chars > $len {
    die "Parameter length $len should be greater than or equal to number's length {$s.chars}";
  }
  $s = '0' x ($len - $s.chars) ~ $s;
  my @before = @digits[0 ..^ $radix];
  my @after  = @before.reverse;
  $s .= trans(@before => @after);
  return Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value($s))
      ☈+ Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value<1>);
}

sub adjust-sub(Arithmetic::PaperAndPencil::Number $high, Arithmetic::PaperAndPencil::Number $low) is export {
  my Int $radix = $high.radix;
  if $low.radix != $radix {
    die "Subtraction not allowed with different bases: $radix {$low.radix}";
  }
  if $high.chars != 1 {
    die "The high number must be a single-digit number";
  }
  if $low.chars > 2 {
    die "The low number must be a single-digit number or a 2-digit number";
  }
  my Arithmetic::PaperAndPencil::Number $adjusted-carry .= new(radix => $radix, value => $low.carry.value);
  my Arithmetic::PaperAndPencil::Number $low-unit        = $low.unit;
  my Int $native-high     = $high!native-int;
  my Int $native-low-unit = $low-unit!native-int;
  if $high ☈< $low-unit {
    $adjusted-carry ☈+=  Arithmetic::PaperAndPencil::Number.new(:radix($radix), :value<1>);
    $native-high     += $radix;
  }
  my Arithmetic::PaperAndPencil::Number $adjusted-high .= new(radix => $radix, value => $adjusted-carry.value ~ $high.value);
  my Arithmetic::PaperAndPencil::Number $result        .= new(radix => $radix, value => @digits[$native-high - $native-low-unit]);
  return $adjusted-high, $result;
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil::Number - integer, with elementary operations

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil::Number;
my $x = Arithmetic::PaperAndPencil::Number.new(value => '9', radix => 13);
my $y = Arithmetic::PaperAndPencil::Number.new(value => '6', radix => 13);
my $sum = $x ☈+ $y;
say $sum;
my $pdt = $x ☈× $y;
say $pdt;

=end code

=head1 DESCRIPTION

This class should  not be used directly.  It is meant to  be a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Number>  is  a   class  storing  integer
numbers and  simulating elementary operations  that a pupil  learns at
school. The simulated  operations are the operations  an average human
being can do in  his head, without outside help such as  a paper and a
pencil.

So,  operations are  implemented with  only very  simple numbers.  For
example, when adding two numbers, at  least one of them must have only
one  digit. And  when multiplying  numbers, both  numbers must  have a
single  digit.  Attempting  to  multiply, or  add,  two  numbers  with
multiple digits triggers an exception.

An important difference with the  average human being: most humans can
compute in  radix 10 only. Some  gifted humans may add  or subtract in
radix  8 and  in radix  16, but  they are  very few.  This module  can
compute in any radix from 2 to 36.

Another  difference  with normal  human  beings:  a  human can  add  a
single-digit   number  with   a  multi-digit   number,  provided   the
multi-digit number is not too long. E.g. a human can compute C<15678 +
6> and get C<15684>, but  when asked to compute C<18456957562365416378
+  6>, this  human will  fail to  remember all  necessary digits.  The
module has  no such limitations.  Or rather, the  module's limitations
are those of the Raku interpreter and of the host machine.

=head1 METHODS

=head2 new

An  instance  of  C<Arithmetic::PaperAndPencil::Number>  is  built  by
calling method C<new>  with two parameters, C<value>  and C<radix>. If
omitted, C<radix> defaults to 10.

=head2 gist

Just display the value. The radix is not displayed.

=head2 chars

The number of chars in the C<value> attribute.

=head2 unit

Builds a  number (instance  of C<Arithmetic::PaperAndPencil::Number>),
using the last digit of the input number. For example, when applied to
number C<1234>, the C<unit> method gives C<4>.

Extended  usage:  given  a C<$len>  parameter  (positional,  optional,
default 1), builds a number using the last C<$len> digits of the input
number. For  example, when  applied to  number C<1234>  with parameter
C<2>, the C<unit>  method gives C<34>. When applied  to number C<1234>
with parameter C<3>, the C<unit> method gives C<234>.

=head2 carry

Builds a  number (instance  of C<Arithmetic::PaperAndPencil::Number>),
using  the input  number without  its  last digit.  For example,  when
applied to number C<1234>, the C<carry> method gives C<123>.

Extended  usage:  given  a C<$len>  parameter  (positional,  optional,
default 1), builds  a number, using the input number  without its last
C<$len>  digits. For  example,  when applied  to  number C<1234>  with
parameter C<2>, the C<carry> method  gives C<12> by removing 2 digits,
C<34>.  When  applied  to  number C<1234>  with  parameter  C<3>,  the
C<carry> method gives C<1>.

=head2 complement

Returns the  10-complement, 2-complement, 16-complement,  whatever, of
the number. Which complement is returned is determined by the number's
radix. The method requires another  parameter, to choose the number of
digits  in  the  computed  complement.  This  length  parameter  is  a
positional parameter.

Example

  radix  = 16     |
  number = BABE   | → complement = FFFF5652
  length = 8      |

=head1 FUNCTIONS

=head2 C<max-unit>

The input  parameter is the  radix (positional). The  function returns
the  highest   single-digit  number  for  this   radix.  For  example,
C<max-unit(10)> returns C<9> and C<max-unit(16)> returns C<F>.

The returned value is an instance  of C<Arithmetic::PaperAndPencil::Number>),

=head2 Addition

Infix function  C<☈+>. At  least one argument  must be  a single-digit
number.

=head2 Subtraction C<adjust-sub>

Actually, this is not the  plain subtraction. This function receives a
1-digit high number and  a 1- or 2-digit low number.  It sends back an
adjusted   high-number  and   a  subtraction   result.  The   adjusted
high-number is  the first number  greater than  the low number  and in
which the unit is the parameter high number.

For example (radix 10):

  high = 1, low = 54 → adjusted-high = 61, result = 7
  high = 8, low = 54 → adjusted-high = 58, result = 4

The parameters are positional.

=head2 Subtraction, C<☈->

Infix  function C<☈->.  Both arguments  must be  single-digit numbers.
This is the plain subtraction.

=head2 Multiplication

Infix function C<☈×>. Both arguments must be single-digit numbers.

=head2 Division

Infix function  C<☈÷>. The  first argument must  be a  single-digit or
double-digit number  and the  second argument  must be  a single-digit
number (and greater than zero, of course).

=head2 Comparisons

Infix function C<< ☈<=> >> 3-way numerical comparison or right-aligned comparison.

Infix function C<☈leg> 3-way alphabetical comparison or left-aligned comparison.

Infix functions C<< ☈< >> and C<< ☈≤ >> numerical comparisons or right-aligned comparisons.

Infix function C<☈lt> alphabetical comparison or left-aligned comparison.

The arguments can have any length.

=head1 REMARKS

Why the thunderstorm  symbol? First I cannot use plain  C<+> and plain
C<×>  both  for  C<Arithmetic::PaperAndPencil::Number>  and  for  core
C<Int>.  So  I had  to  adopt  a different  syntax.  And  I chose  the
thunderstorm  symbol to  represent the  cerebral activity  in a  human
brain when computing the results. Do  you have a better idea? Dingbats
accepted, emojis rejected.

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
