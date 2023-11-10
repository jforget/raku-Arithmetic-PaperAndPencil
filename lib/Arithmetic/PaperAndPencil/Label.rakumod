# -*- encoding: utf-8; indent-tabs-mode: nil -*-

unit module Arithmetic::PaperAndPencil::Label:ver<0.0.1>:auth<cpan:JFORGET>;

my %label = 'fr' => %(
                 'TIT01' => 'Addition (base #1#)'
               , 'TIT02' => 'Soustraction de #1# et #2# (base #3#)'
               , 'TIT03' => 'Multiplication de #1# et #2#, procédé standard, base #3#'
               , 'TIT04' => 'Multiplication de #1# et #2#, procédé avec raccourci, base #3#'
               , 'TIT05' => 'Multiplication de #1# et #2#, avec préparation, base #3#'
               , 'TIT06' => 'Multiplication de #1# et #2#, procédé rectangulaire (A), base #3#'
               , 'TIT07' => 'Multiplication de #1# et #2#, procédé rectangulaire (B), base #3#'
               , 'TIT08' => 'Multiplication de #1# et #2#, procédé rhombique, base #3#'
               , 'ADD01' => '#1# et #2#, #3#'
               , 'ADD02' => 'et #1#, #2#'
               , 'WRI01' => "J'écris #1#"
               , 'WRI02' => "Je pose #1# et je retiens #2#"
               , 'WRI03' => "Je pose #1# et je ne retiens rien"
               , 'WRI04' => "Je pose #1#"
               , 'MUL01' => '#1# fois #2#, #3#'
               , 'MUL02' => 'Fastoche, #1# fois #2#, #3#'
               )
          , 'en' => %(
                 'TIT01' => 'Addition (base #1#)'
               , 'TIT02' => 'Subtraction of #1# and #2# (base #3#)'
               , 'TIT03' => 'Multiplication of #1# and #2#, standard processus, base #3#'
               , 'TIT04' => 'Multiplication of #1# and #2#, with short-cuts, base #3#'
               , 'TIT05' => 'Multiplication of #1# and #2#, with preparation, base #3#'
               , 'TIT06' => 'Multiplication of #1# and #2#, rectangular processus (A), base #3#'
               , 'TIT07' => 'Multiplication of #1# and #2#, rectangular processus (B), base #3#'
               , 'TIT08' => 'Multiplication of #1# and #2#, rhombic processus, base #3#'
               , 'MUL01' => '#1# times #2#, #3#'    # guesswork
               )
               ;

our sub full-label($label, $val1, $val2, $val3, $ln) is export {
  my $result;
  if %label{$ln}{$label} {
    $result = %label{$ln}{$label};
  }
  else {
    return Nil;
  }
  $result ~~ s:g/'#1#'/$val1/;
  $result ~~ s:g/'#2#'/$val2/;
  $result ~~ s:g/'#3#'/$val3/;
  return $result;
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil::Label - voicing a computation or action

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil::Label;

=end code

=head1 DESCRIPTION

This lass  should not be  used directly. It is  meant to be  a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Label>  is a  class storing  the phrases
that a human computer says (or thinks) when doing a computation.

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
