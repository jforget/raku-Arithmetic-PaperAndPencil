# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Number;
use Arithmetic::PaperAndPencil::Label;

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

method html(Str :$lang, Bool :$silent, Int :$level) {
  my Bool $talkative = not $silent;
  my Str  $result    = '';
  for @.action -> $action {
    if $talkative or $action.label.starts-with('TIT') {
      #my $line = Arithmetic::PaperAndPencil::Label::full-label($action.label, $action.val1, $action.val2, $action.val3, $lang);
      my $line = full-label($action.label, $action.val1, $action.val2, $action.val3, $lang);
      if $line {
        if  $action.label.starts-with('TIT') {
          $line = "<operation>{$line}</operation>\n";
        }
	else {
          $line = "<talk>{$line}</talk>\n";
        }
        $result ~= $line;
      }
    }
  }
  # changing pseudo-HTML into proper HTML
  $result ~~ s:g/"operation>"/h1>/;
  $result ~~ s:g/"talk>"/p>/;

  return $result;
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
