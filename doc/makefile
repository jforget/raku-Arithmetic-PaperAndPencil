# -*- encoding: utf-8 -*-

SHELL = /bin/sh

MD2HTML = /home/jf/.local/bin/grip
MD2HTMLOPT = --export --no-inline

.SUFFIXES:
.SUFFIXES: .md .html

.md.html:
	$(MD2HTML) $< $(MD2HTMLOPT)
	perl -i -p -e 's/\<table\>/<table border="1">/; s/\xc2\xa0/\&nbsp;/g' $@

target: Description-fr.html

mult1: rect-mult.png
	display rect-mult.png

rect-mult.png: rect-mult.pdf
	pdftoppm -png -f 1 -l 1 -x 240 -y 225 -W 1500 -H 300 rect-mult.pdf rect-mult
	mv rect-mult-1.png rect-mult.png

rect-mult.pdf: rect-mult.tex
	lualatex rect-mult.tex

