DESCRIPTION
===========

This directory contains programmes using the `Arithmetic::PaperAndPencil` module,
beyond the simple display of a single operation.

The programmes  can be  run directly  from this  `examples` directory,
after cloning the Github repo and before installing the module. Or you
can install the  module, move the programmes into  a directory present
in your `$PATH` variable and run them.

PROGRAMMES
==========

* `comparison-Newton-gallows.raku`

This programme  computes √2 using  the Newton method. There  are three
functions, one using `Rat` numbers, the second using `Num` numbers and
the  last   using  `Arithmetic::PaperAndPencil`.  A   fourth  function
computes  √2   using  `Arithmetic::PaperAndPencil`  with   the  direct
"gallows" method.

* `conv-pi.raku`

This programme converts π (with up to 50 decimal digits) from radix 10
to another radix.

* `phi.raku`

This programme computes  the golden ratio φ in any radix from 2 to 36.

AUTHOR
======

Jean Forget <J2N-FORGET@orange.fr>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Jean Forget

This software is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

