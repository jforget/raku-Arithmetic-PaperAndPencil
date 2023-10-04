# -*- encoding: utf-8; indent-tabs-mode: nil -*-

unit class Arithmetic::PaperAndPencil::Number:ver<0.0.1>:auth<cpan:JFORGET>;

my @digits = ('0' .. '9', 'A' .. 'Z').flat;

has Str $.value;
has Int $.base;

method BUILD(Str:D :$value, Int:D :$base = 10) {
  self!check-build-args($value, $base);
  self!build-from-args( $value, $base);
}

method !check-build-args(Str $value, Int $base) {
  unless 2 ≤ $base ≤ 36 {
    X::OutOfRange.new(:what<base>, :got($base), :range<2..36>).throw;
  }
  my @base-digits = @digits[ 0 ..^ $base ];
  unless $value ~~ /^ @base-digits + $/ {
    X::Invalid::Value.new(:method<BUILD>, :name<value>, :value($value)).throw;
  }
}

method !build-from-args(Str $value, Int $base) {
  $!value = $value;
  $!base  = $base;
  $!value ~~ s/^ 0+ //; # remove leading zeros
  if $!value eq '' {
    # oops! we removed all zero digits, leaving none for number zero
    $!value = '0';
  }
}

method gist {
  $.value;
}

sub infix:<☈+> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y) is export {
  if $x.base ne $y.base {
    die "Addition not allowed with different bases: {$x.base} {$y.base}";
  }
  if $x.value.chars ne 1 and $y.value.chars ne 1 {
    die "Addition allowed only if at least one number has a single digit";
  }
  my Str @long-op;
  my Str $short-op;
  if $x.value.chars == 1 {
    $short-op = $x.value;
    @long-op  = ('0' ~ $y.value).comb.reverse;
  }
  else {
    $short-op = $y.value;
    @long-op  = ('0' ~ $x.value).comb.reverse;
  }
  my Str $digit-nine = @digits[$x.base - 1];  # '9' for base 10, 'F' for base 16, and so on
  my Int $a = @digits.first: * eq $short-op  , :k;
  my Int $b = @digits.first: * eq @long-op[0], :k;
  if $a + $b < $x.base {
    # no carry
    @long-op[0] = @digits[$a + $b];
    return Arithmetic::PaperAndPencil::Number.new(value => @long-op.reverse.join('')
                                                , base  => $x.base);
  }
  @long-op[0] = @digits[$a + $b - $x.base];
  for 1..@long-op.elems -> $i {
     if @long-op[$i] ne $digit-nine {
       @long-op[$i] = @digits[1 + @digits.first: * eq @long-op[$i], :k];
       last;
     }
     @long-op[$i] = '0';
  }
  return Arithmetic::PaperAndPencil::Number.new(value => @long-op.reverse.join('')
					      , base  => $x.base);
}

sub infix:<☈×> (Arithmetic::PaperAndPencil::Number $x, Arithmetic::PaperAndPencil::Number $y) is export {
  if $x.base ne $y.base {
    die "Multiplication not allowed with different bases: {$x.base} {$y.base}";
  }
  if $x.value.chars ne 1 or $y.value.chars ne 1 {
    die "Multiplication allowed only for single-digit factors";
  }
  my Int $x10 = @digits.first: * eq $x.value, :k;
  my Int $y10 = @digits.first: * eq $y.value, :k;
  my Int $z10 = $x10 × $y10;
  my Int $zu  = $z10 % $x.base;
  my Int $zt  = ($z10 / $x.base).floor;
  return Arithmetic::PaperAndPencil::Number.new(value => @digits[$zt] ~ @digits[$zu]
                                              , base  => $x.base);
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil::Number - integer, with elementary operations

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil::Number;
my $x = Arithmetic::PaperAndPencil::Number.new(value => '9', base => 13);
my $y = Arithmetic::PaperAndPencil::Number.new(value => '6', base => 13);
my $sum = $x ☈+ $y;
say $sum;
my $pdt = $x ☈× $y;
say $pdt;

=end code

=head1 DESCRIPTION

This lass  should not be  used directly. It is  meant to be  a utility
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
compute in  base 10 only.  Some gifted humans  may add or  subtract in
base 8 and in base 16, but  they are very few. This module can compute
in any base from 2 to 36.

Another  difference with  normal  human  beaings: a  human  can add  a
single-digit   number  with   a  multi-digit   number,  provided   the
multi-digit number is not too long. E.g. a human can compute C<15678 +
6> and get C<15684>, but  when asked to compute C<18456957562365416378
+  6>, this  human will  fail to  remember all  necessary digits.  The
module has  no such limitations.  Or rather, the  module's limitations
are those of the Raku intrepreter and of the host machine.

=head1 METHODS

=head2 new

An  instance  of  C<Arithmetic::PaperAndPencil::Number>  is  built  by
calling method  C<new> with two  parameters, C<value> and  C<base>. If
omitted, C<base> defaults to 10.

=head2 gist

Just display the value. The base is not displayed.

=head1 FUNCTIONS

=head2 Addition

Infix function  C<☈+>. At  least one argument  must be  a single-digit
number.

=head2 Multiplication

Infix function C<☈×>. Both arguments must be single-digit numbers.

=head1 REMARKS

Why the thunderstorm  symbol? First I cannot use plain  C<+> and plain
C<×>  both  for  C<Arithmetic::PaperAndPencil::Number>  and  for  core
C<Int>.  So  I add  to  adopt  a different  syntax.  And  I chose  the
thunderstorm  symbol to  represent the  cerebral activity  in a  human
brain when computing the results. Do you have a better idea?

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
