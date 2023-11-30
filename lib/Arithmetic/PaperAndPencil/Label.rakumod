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
               , 'TIT09' => 'Division de #1# par #2#, procédé standard, base #3#'
               , 'TIT10' => 'Division de #1# par #2#, procédé standard avec triche, base #3#'
               , 'TIT11' => 'Division de #1# par #2#, avec préparation, base #3#'
               , 'TIT12' => 'Division de #1# par #2#, procédé rhombique, base #3#'
               , 'TIT13' => 'Racine carrée de #1#, base #2#'
               , 'TIT14' => 'Conversion de #1#, base #2# vers base #3#'
               , 'TIT15' => 'Soustraction de #1# et #2# par addition du complément à #3#'
               , 'NXP01' => 'Changement de page'
               , 'ADD01' => '#1# et #2#, #3#'
               , 'ADD02' => 'et #1#, #2#'
               , 'WRI01' => "J'écris #1#"
               , 'WRI02' => "Je pose #1# et je retiens #2#"
               , 'WRI03' => "Je pose #1# et je ne retiens rien"
               , 'WRI04' => "Je pose #1#"
               , 'WRI05' => "Je recopie la ligne #1#"
               , 'MUL01' => '#1# fois #2#, #3#'
               , 'MUL02' => 'Fastoche, #1# fois #2#, #3#'
               , 'CNV01' => 'Fastoche, #1# converti de la base #2# vers la base #3# donne #1#'
               , 'CNV02' => 'La conversion de #1# donne #2#'
               , 'CNV03' => 'Déjà converti : #1#, reste à convertir : #2#'
               , 'SUB01' => '#1# et #2#, #3#'
               , 'SUB02' => 'et #1#, #2#'
               , 'SUB03' => 'Le complément à #1# de #2# est #3#'
               , 'SUB04' => "J'élimine le chiffre de gauche et le résultat est #1#"
               , 'DIV01' => 'En #1# combien de fois #2#, il y va #3# fois'
               , 'DIV02' => "C'est trop fort, j'essaie #1#"
               , 'DIV03' => "Je triche, j'essaie directement #1#"
               , 'DIV04' => "J'abaisse le #1#"
               , 'DIV05' => 'Fastoche, #1# divisé par 1 donne #1#, reste 0'
               , 'DIV06' => 'Fastoche, #1# divisé par #2# donne 0, reste #1#'
               )
          , 'en' => %(
                 'TIT01' => 'Addition (radix #1#)'
               , 'TIT02' => 'Subtraction of #1# and #2# (radix #3#)'
               , 'TIT03' => 'Multiplication of #1# and #2#, standard processus, radix #3#'
               , 'TIT04' => 'Multiplication of #1# and #2#, with short-cuts, radix #3#'
               , 'TIT05' => 'Multiplication of #1# and #2#, with preparation, radix #3#'
               , 'TIT06' => 'Multiplication of #1# and #2#, rectangular processus (A), radix #3#'
               , 'TIT07' => 'Multiplication of #1# and #2#, rectangular processus (B), radix #3#'
               , 'TIT08' => 'Multiplication of #1# and #2#, rhombic processus, radix #3#'
               , 'TIT09' => 'Division of #1# by #2#, standard processus, radix #3#'
               , 'TIT10' => 'Division of #1# by #2#, with cheating, radix #3#'
               , 'TIT11' => 'Division of #1# by #2#, with preparation, radix #3#'
               , 'TIT12' => 'Division of #1# by #2#, rhombic processus, radix #3#'
               , 'TIT13' => 'Square root of #1#, radix #2#'
               , 'TIT14' => 'Conversion of #1#, radix #2# to radix #3#'
               , 'TIT15' => 'Subtraction of #1# and #2# by adding the #3#-complement)'
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

The French langage C<"fr"> is  fully implemented. The English language
C<"en"> is partially  implemented. For the moment,  no other languages
are implemented.  If you  are a  native speaker  of English  and other
languages,  and  if  you  remember   how  you  did  paper  and  pencil
computation, you can send me patches or you can contact me to add your
language to this module. Thank you in advance.

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
