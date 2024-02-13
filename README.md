NAME
====

Arithmetic::PaperAndPencil - simulating paper and pencil techniques for basic arithmetic operations

SYNOPSIS
========

```raku
use Arithmetic::PaperAndPencil;

my Arithmetic::PaperAndPencil $paper-sheet .= new;
my Arithmetic::PaperAndPencil::Number $x .= new(value => '355000000');
my Arithmetic::PaperAndPencil::Number $y .= new(value => '113');

$paper-sheet.division(dividend => $x, divisor => $y);
my Str $html = $paper-sheet.html(lang => 'fr', silent => False, level => 3);
'division.html'.IO.spurt($html);

$paper-sheet .= new; # emptying previous content
my Arithmetic::PaperAndPencil::Number $dead .= new(value => 'DEAD', radix => 16);
my Arithmetic::PaperAndPencil::Number $beef .= new(value => 'BEEF', radix => 16);

$paper-sheet.addition($dead, $beef);
$html = $paper-sheet.html(lang => 'fr', silent => False, level => 3);
'addition.html'.IO.spurt($html);
```

The first HTML file ends with

```
 355000000|113
 0160     |---
  0470    |3141592
   0180   |
    0670  |
     1050 |
      0330|
       104|
```

and the second one with

```
  DEAD
  BEEF
 -----
 19D9C

```

DESCRIPTION
===========

Arithmetic::PaperAndPencil  is a  module which  allows simulating  the
paper  and  pencil  techniques  for  basic  arithmetic  operations  on
integers: addition, subtraction, multiplication and division, but also
square root extraction and conversion from a radix to another.

PATCHES WELCOME
===============

When rendering an operation as HTML, the module displays spoken French
sentences. If you  know the equivalent sentences  in another language,
you can contact  me to add the other language  to the distribution, or
you can even send me a patch. Thank you in advance.

AUTHOR
======

Jean Forget <J2N-FORGET@orange.fr>

DEDICATION
==========

This module is dedicated to my  primary school teachers, who taught me
the basics of arithmetics, and even  some advanced features, and to my
secondary  school math  teachers, who  taught me  other advanced  math
concepts and features.

COPYRIGHT AND LICENSE
=====================

Copyright 2023, 2024 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

