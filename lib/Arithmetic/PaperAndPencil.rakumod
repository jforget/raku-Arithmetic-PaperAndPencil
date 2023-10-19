# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Number;

unit class Arithmetic::PaperAndPencil:ver<0.0.1>:auth<cpan:JFORGET>;

has Arithmetic::PaperAndPencil::Action @.action is rw;

multi method BUILD () {
}

multi method BUILD(:$csv) {
  my $fh = $csv.IO.open(:r);
  @.action = $fh.lines.map( { Arithmetic::PaperAndPencil::Action.new(csv => $_) } );
}

method csv() {
 join '', @!action.map( { $_.csv ~ "\n" } ); 
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil;

=end code

=head1 DESCRIPTION

Arithmetic::PaperAndPencil is ...

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
