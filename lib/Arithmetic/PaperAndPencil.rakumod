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
  my Bool $talkative = not $silent; # "silent" better for API, "talkative" better for programming
  my Str  $result    = '';
  my      @sheet     = ();
  my Int  %vertical-lines;
  my Int  %cache-l2p-col;
  my Int  $c-min     = 0;
  my Int  $l-min     = 0;

  # checking the line minimum number
  sub check-l-min(Int $l) {
    if $l < $l-min {
      # inserting new empty lines before the existing ones
      for $l ..^ $l-min {
        unshift @sheet, Nil;
      }
      # updating the line minimum number
      $l-min = $l;
    }
  }
  # logical to physical line number
  sub l2p-lin(Int $logl --> Int) {
    my Int $result = $logl - $l-min;
    return $result;
  }

  # checking the column minimum number
  sub check-c-min(Int $c) {
    if $c < $c-min {
      my Int $delta-c = $c-min - $c;
      for @sheet <-> $line {
        prepend $line, ' ' xx $delta-c;
      }
      $c-min = $c;
      %cache-l2p-col  = %();
    }
  }
  # logical to physical column number
  sub l2p-col(Int $logc --> Int) {
    if %cache-l2p-col{$logc} {
      return %cache-l2p-col{$logc};
    }
    my Int $result = $logc - $c-min;
    for %vertical-lines.keys -> $col {
      if $logc > $col {
        ++$result;
      }
    }
    %cache-l2p-col{$logc} = $result;
    return $result;
  }

  sub filling-spaces(Int $l, Int $c) {
    # putting spaces into all uninitialised boxes
    for 0 .. l2p-lin($l) -> $l1 {
       @sheet[$l1; 0] //= ' ';
    }
    for 0 .. l2p-col($c) -> $c1 {
       @sheet[l2p-lin($l); $c1] //= ' ';
    }
  }

  for @.action -> $action {
    if $action.label.starts-with('TIT') {
      @sheet          =  ();
      %vertical-lines = %();
      %cache-l2p-col  = %();
    }

    # Drawing a vertical line
    if $action.label eq 'DRA01' {
      if  $action.w1c != $action.w2c {
        die "The line is not vertical, starting at column {$action.w1c} and ending at column {$action.w2c}";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-l-min($action.w2l);
      check-c-min($action.w1c);
      # making some clear space for the vertical line
      unless %vertical-lines{$action.w1c} {
        %vertical-lines{$action.w1c} = 1;
        # clearing the cache
        %cache-l2p-col  = %();

        # shifting characters past the new vertical line's column
        for @sheet.keys -> $l {
          for 0 .. l2p-col($action.w1c) -> $c {
             @sheet[$l; $c] //= ' ';
          }
          my $line = @sheet[$l];
          splice($line, l2p-col($action.w1c), 0, ' ');
          @sheet[$l] = $line;
        }
      }
      # making the vertical line
      for $action.w1l .. $action.w2l -> $l {
        filling-spaces($l, $action.w1c);
        @sheet[l2p-lin($l); l2p-col($action.w1c) + 1] = '|';
      }
    }

    # Drawing an oblique line
    if $action.label eq 'DRA03' {
      if $action.w2c - $action.w1c != $action.w2l - $action.w1l {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-l-min($action.w2l);
      check-c-min($action.w1c);
      check-c-min($action.w2c);
      # drawing the line
      for 0 .. $action.w2l - $action.w1l -> $i {
        filling-spaces($action.w1l + $i, $action.w1c + $i);
        my $l1 = l2p-lin($action.w1l + $i);
        my $c1 = l2p-col($action.w1c + $i);
        @sheet[$l1; $c1] = '\\';
      }
    }
    
    # Writing some digits (or other characters)
    if $action.w1val ne '' {
      # checking the line and column minimum numbers
      check-l-min($action.w1l);
      check-c-min($action.w1c - $action.w1val.chars + 1);
      # putting spaces into all uninitialised boxes
      filling-spaces($action.w1l, $action.w1c);
      # putting each char separately into its designated box
      for $action.w1val.comb('').kv -> $i, $str {
         @sheet[l2p-lin($action.w1l); l2p-col($action.w1c - $action.w1val.chars + $i + 1)] = $str;
      }
    }
    if $action.w2val ne '' {
      # checking the line and column minimum numbers
      check-l-min($action.w2l);
      check-c-min($action.w2c - $action.w2val.chars + 1);
      # putting spaces into all uninitialised boxes
      filling-spaces($action.w2l, $action.w2c);
      # putting each char separately into its designated box
      for $action.w2val.comb('').kv -> $i, $str {
         @sheet[l2p-lin($action.w2l); l2p-col($action.w2c - $action.w2val.chars + $i + 1)] = $str;
      }
    }

    # Talking
    if $talkative or $action.label.starts-with('TIT') {
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

    # Showing the operation
    if $action.level ≤ $level {
      my Str $op = '';
      for @sheet.kv -> $l, $line {
        my $line1 = $line.join('');
        $op ~= $line1 ~ "\n";
      }
      if $op ne '' {
        $result ~= "<pre>\n{$op}</pre>\n";
      }
    }
  }
  # changing pseudo-HTML into proper HTML
  $result ~~ s:g/"operation>"/h1>/;
  $result ~~ s:g/"talk>"/p>/;
  $result ~~ s:g/\h + $$//;

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
