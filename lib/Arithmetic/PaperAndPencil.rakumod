# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Number;
use Arithmetic::PaperAndPencil::Label;

unit class Arithmetic::PaperAndPencil:ver<0.0.1>:auth<cpan:JFORGET>;

has Arithmetic::PaperAndPencil::Action @.action is rw;
has Int %.vertical-lines;
has Int %.cache-l2p-col;
has Array @.sheet;

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
  @!sheet     = ();

  for @.action -> $action {
    if $action.label.starts-with('TIT') {
      @!sheet = ();
      %!vertical-lines = %();
      %!cache-l2p-col  = %();
    }

    # Drawing a vertical line
    if $action.label.starts-with('DRA') and $action.w1c == $action.w2c {
      # marking the vertical line
      unless %!vertical-lines{$action.w1c} {
        %!vertical-lines{$action.w1c} = 1;
        # clearing the cache
        %!cache-l2p-col  = %();

        $.filling-spaces($action.w1l, $action.w1c);
        $.filling-spaces($action.w2l, $action.w1c);

        # shifting characters past the new vertical line's column
        for @!sheet.keys -> $l {
          for 0 .. $.l2p-col($action.w1c) -> $c {
             @!sheet[$l; $c] //= ' ';
          }
          my $line = @!sheet[$l];
          splice($line, $.l2p-col($action.w1c), 0, ' ');
          @!sheet[$l] = $line;
        }
      }
      for $action.w1l .. $action.w2l -> $l {
        $.filling-spaces($l, $action.w1c);
        @.sheet[$l; $.l2p-col($action.w1c) + 1] = '|';
      }
    }
    # Writing some digits (or other characters)
    if $action.w1val != '' {
      # putting spaces into all uninitialised boxes
      $.filling-spaces($action.w1l, $action.w1c);
      # putting each char separately into its designated box
      for $action.w1val.comb('').kv -> $i, $str {
         @.sheet[$action.w1l; $.l2p-col($action.w1c - $action.w1val.chars + $i + 1)] = $str;
      }
    }
    if $action.w2val != '' {
      # putting spaces into all uninitialised boxes
      $.filling-spaces($action.w2l, $action.w2c);
      # putting each char separately into its designated box
      for $action.w2val.comb('').kv -> $i, $str {
         @!sheet[$action.w2l; $.l2p-col($action.w2c - $action.w2val.chars + $i + 1)] = $str;
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
      for @!sheet.kv -> $l, $line {
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

method l2p-col(Int $logc --> Int) {
  if %!cache-l2p-col{$logc} {
    return %!cache-l2p-col{$logc};
  }
  my Int $result = $logc;
  for %!vertical-lines.keys -> $col {
    if $logc > $col {
      ++$result;
    }
  }
  %!cache-l2p-col{$logc} = $result;
  return $result;
}

method filling-spaces(Int $l, Int $c) {
  # putting spaces into all uninitialised boxes
  for 0 .. $l -> $l1 {
     @!sheet[$l1; 0] //= ' ';
  }
  for 0 ..^ $.l2p-col($c) -> $c1 {
     @!sheet[$l; $c1] //= ' ';
  }
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
