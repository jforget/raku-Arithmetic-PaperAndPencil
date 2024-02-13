# -*- encoding: utf-8; indent-tabs-mode: nil -*-

unit class Arithmetic::PaperAndPencil::Char:ver<0.0.1>:auth<zef:jforget>;

has Str  $.char      is rw;
has Bool $.underline is rw = False;
has Bool $.strike    is rw = False;
has Bool $.read      is rw = False;
has Bool $.write     is rw = False;

method html(--> Str) {
  my Str $result = $.char;
  if $.write {
    $result = "<write>{$result}</write>";
  }
  elsif $.read {
    # "elsif", because only one of (read|write) will be rendered, and write is more important than read
    $result = "<read>{$result}</read>";
  }
  if $.strike {
    $result = "<strike>{$result}</strike>";
  }
  if $.underline {
    $result = "<underline>{$result}</underline>";
  }
  return $result;
}

sub space-char(--> Arithmetic::PaperAndPencil::Char) is export {
  return Arithmetic::PaperAndPencil::Char.new(char => ' ');
}

sub pipe-char(--> Arithmetic::PaperAndPencil::Char) is export {
  return Arithmetic::PaperAndPencil::Char.new(char => '|');
}

sub slash-char(--> Arithmetic::PaperAndPencil::Char) is export {
  return Arithmetic::PaperAndPencil::Char.new(char => '/');
}

sub backslash-char(--> Arithmetic::PaperAndPencil::Char) is export {
  return Arithmetic::PaperAndPencil::Char.new(char => '\\');
}

=begin pod

=head1 NAME

Arithmetic::PaperAndPencil::Char - individual characters when rendering an arithmetic operation

=head1 SYNOPSIS

=begin code :lang<raku>

use Arithmetic::PaperAndPencil::Char;

=end code

=head1 DESCRIPTION

This class should  not be used directly.  It is meant to  be a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Char> is a  class storing the characters
when rendering  an arithmetic operation. Beside  the character itself,
it stores  information about  the decoration  of the  char: underline,
strike, etc.

=head1 AUTHOR

Jean Forget <J2N-FORGET@orange.fr>

=head1 COPYRIGHT AND LICENSE

Copyright 2023, 2024 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
