# -*- encoding: utf-8; indent-tabs-mode: nil -*-

unit class Arithmetic::PaperAndPencil::Action:ver<0.0.1>:auth<cpan:JFORGET>;

has Int	 $.level is rw;
has Str	 $.label;
has Str	 $.val1;
has Str	 $.val2;
has Str	 $.val3;
has Int	 $.r1l;
has Int	 $.r1c;
has Str	 $.r1val;
has Bool $.r1str;
has Int	 $.r2l;
has Int	 $.r2c;
has Str	 $.r2val;
has Bool $.r2str;
has Int	 $.w1l;
has Int	 $.w1c;
has Str	 $.w1val;
has Int	 $.w2l;
has Int	 $.w2c;
has Str	 $.w2val;


multi method BUILD(:$csv) {
  my ($levelx, $label, $val1, $val2, $val3, $r1lx, $r1cx, $r1val, $r1strx
                                          , $r2lx, $r2cx, $r2val, $r2strx
                                          , $w1lx, $w1cx, $w1val
                                          , $w2lx, $w2cx, $w2val) = $csv.split( / \s* ';' \s* / );
  $!level   = $levelx.Int;
  $!label   = $label;
  $!val1    = $val1;
  $!val2    = $val2;
  $!val3    = $val3;
  $!r1l     = $r1lx.Int;
  $!r1c     = $r1cx.Int;
  $!r1val   = $r1val;
  if $r1strx eq 'False' | 'Bool::False' {
    $!r1str = False
  }
  else {
    $!r1str = $r1strx.Bool;
  }
  $!r2l     = $r2lx.Int;
  $!r2c     = $r2cx.Int;
  $!r2val   = $r2val;
  if $r2strx eq 'False' | 'Bool::False' {
    $!r2str = False
  }
  else {
    $!r2str = $r2strx.Bool;
  }
  $!w1l     = $w1lx.Int;
  $!w1c     = $w1cx.Int;
  $!w1val   = $w1val;
  $!w2l     = $w2lx.Int;
  $!w2c     = $w2cx.Int;
  $!w2val   = $w2val;

}

method csv() {
  my Str ($r1str, $r2str);
  if $.r1str { $r1str = 'True'; } else { $r1str = 'False'; }
  if $.r2str { $r2str = 'True'; } else { $r2str = 'False'; }
  return join ';', $.level
                 , $.label
                 , $.val1
                 , $.val2
                 , $.val3
                 , $.r1l
                 , $.r1c
                 , $.r1val
                 , $r1str
                 , $.r2l
                 , $.r2c
                 , $.r2val
                 , $r2str
                 , $.w1l
                 , $.w1c
                 , $.w1val
                 , $.w2l
                 , $.w2c
                 , $.w2val
		 ;
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil::Action - action when computing an arithmetic operation

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil::Action;

=end code

=head1 DESCRIPTION

This lass  should not be  used directly. It is  meant to be  a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Action>  is  a   class  storing  various
actions  when computing  an operation:  writing digits  on the  paper,
drawing lines, reading previously written digits, etc.

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod