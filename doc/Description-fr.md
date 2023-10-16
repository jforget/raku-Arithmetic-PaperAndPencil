-*- encoding: utf-8; indent-tabs-mode: nil -*-

Introduction
============

Le module  a pour but de  simuler les opérations arithmétiques  par un
humain qui ne dispose pas de calculatrice, mais simplement de quelques
feuilles de papier et d'un crayon.

Historique
==========

Pendant les  années 1960, j'ai  appris les quatre opérations  de base,
addition, soustraction, multiplication et division.

En 1976,  j'ai appris également  à extraire des racines  carrées, avec
une méthode très proche de la division en « potence » apprise quelques
années plus tôt.

```
200000000|14142
100      |-----
 0400    |24
  11900  | 4
   060400|---
    03936|281
         |  1
         |----
         |2824
         |   4
         |-----
         |28282
         |    2
         |
```

En 1979,  mon père a  reçu des photocopies d'un  cahier d'arithmétique
datant de 1822. Ce cahier  contient des divisions assez différentes de
ce que  mon père  et moi  connaissons. J'ai  fait un  peu d'ingéniérie
inverse sur ce cahier et je  pense avoir retrouvé la méthode utilisée.
Néanmoins, c'est toujours hypothétique.

![Exemple de calcul](calcul-1822.jpeg)

Voici les  deux premières divisions  de la page  présentée ci-dessus :
24696000 divisé par 25882 donne 954, reste 4572 et 34048000 divisé par
25882 donne 1315, reste 13170.  Ces divisions correspondent aux règles
de trois (7000 ×  3528) / 25882 et (7000 × 4864)  / 25882. Vous pouvez
d'ailleurs  voir  les  multiplications   correspondantes  à  côté  des
divisions. La transcription  ci-dessous ne montre pas  que de nombreux
chiffres sont  barrés et que les  restes 4572 et 13170  sont soulignés
par un trait oblique.

```
   04         	      13
  1085        	     1421
 140217       	    040187
24696202      	   08166480
24696000      	   34048000
--------{0954 	   --------{1315
25882222      	   25882222
 258888       	    258888
  2588        	     2588
   25         	      25
```

En 1982, pour un projet d'histoire des sciences, j'ai emprunté _Number
Words  and Number  Symbols, A  Cultural History  of Numbers_,  de Karl
Menninger, je l'ai lu et je l'ai rendu à la bibliothèque.

En 1996,  j'ai acheté et lu  _Histoire d'Algorithmes, du caillou  à la
puce_.

En 2000  ou 2001, j'ai  écrit un programme Perl  permettant d'extraire
des racines  carrées avec  la méthode  de la  potence. Ce  programme a
disparu de la circulation et je ne m'en porte pas plus mal.

En 2005, aux
[Journées Perl à Marseille](https://journeesperl.fr/fpw2005/)
j'ai présenté une communication éclair sur
[comment extraire une racine carrée](https://journeesperl.fr/fpw2005/talk/201).
La démonstration était uniquement avec  un feutre (émulant un crayon),
un transparent et un rétro-projecteur (émulant une feuille de papier).
Il n'y  avait pas de  programme informatique. C'était prévu  pour « un
jour ou l'autre ». Voici le transparent de cet exposé, montrant que la
racine carrée de 65549,00 est 256,0, avec un reste de 13,00.

![calcul de racine carrée](racine-carree.jpeg)

```
6554900|256,0
255    |-----
 3049  |45
  01300| 5
       |--
       |506
       |  6
       |---
       |5120
       |   0
```

En  2009,  j'ai acheté  un  exemplaire  de  _Number Words  and  Number
Symbols, A  Cultural History  of Numbers_  et j'ai  pu le  consulter à
loisir, sans être contraint de le rapporter à la bibliothèque

En 2023, je  commence à écrire ce  programme en Raku et  sous la forme
d'un module.

But
===

Le calcul se fait à deux niveaux. Prenons le cas de la multiplication.
Il  y  a  d'abord  le  calcul mental,  où  l'écolier  est  capable  de
multiplier deux nombres à  un chiffre pour obtenir un nombre  à 1 ou 2
chiffres. Il y  a ensuite le calcul sur papier,  où l'écolier enchaîne
les opérations  élémentaires pour  obtenir la  multiplication complète
d'un nombre à _n_ chiffres par un nombre à _n'_ chiffres.

Le module  contient donc deux classes.  La première est la  classe des
nombres, où les opérations sont très limitées, correspondant au calcul
mental  sans  papier.  Par  exemple,  la  multiplication  est  définie
uniquement pour deux facteurs à un seul chiffre.

La  deuxième classe  représente  une feuille  de  papier (ou  quelques
feuilles).  Le  principal  attribut  de cette  classe  est  une  liste
d'actions, représentant  l'écolier lisant des chiffres  déjà inscrits,
effectuant un calcul élémentaire et  écrivant le résultat de ce calcul
sur la  feuille de papier,  tout en prononçant les  phrases convenues,
telles que :

```
  6 fois 8, 48
  je pose 8 et je retiens 4
```

La  classe comporte  plusieurs méthodes  correspondant aux  opérations
arithmétiques,  addition,  soustraction, multiplication,  division  et
racine  carrée.   Ces  méthodes  alimentent  l'attribut   « liste  des
actions ». Une autre méthode affiche ces actions au format HTML. Selon
les paramètres, l'affichage ne comporte que les chiffres mis en forme,
ou  bien l'affichage  énumère en  plus les  phrases prononcées  par la
personne censée effectuer le calcul.

On peut envisager d'autres méthodes d'affichage pour d'autres formats,
comme  le  texte  pur  ou  le  format  L<sup>A</sup>T<sub>E</sub>X  +
Metapost. Mais ce n'est pas une priorité.

Ce que le module ne fera pas
----------------------------

Il y a  des choses que je savais  faire à 10 ans mais que  je n'ai pas
prévu  de reprendre  dans le  module. Notamment,  je savais  faire des
opérations avec  des nombres à  virgule. Le  module ne traite  que des
nombres entiers. Tenir  compte de la virgule dans  les nombres traités
nécessiterait  l'ajout  de très  nombreuses  lignes  de code  pour  un
intérêt assez limité.  Donc en fait ma démo des  Journées Perl de 2005
ne pourra pas être reprise telle  quelle. Il faudra calculer la racine
carrée de 6554900 avec le module,  puis, après avoir quitté ce module,
insérer la virgule à l'endroit nécessaire. Ou alors, pour calculer une
valeur  approchée de  π à  6 décimales  avec la  fraction 355/113,  il
faudra à la place calculer la division 355_000_000 / 113 et insérer la
virgule juste après le premier chiffre.

Un  autre point.  Dans les  divisions, la  détermination des  chiffres
successifs du  quotient est  un processus  d'essais et  d'erreurs. Par
exemple, pour diviser  65400 par 1852, on commence  par se restreindre
au premier  chiffre du  dividende et au  premier chiffre  du diviseur,
soit `6`  et `1`,  ce qui donne  pour le quotient  le chiffre  `6`. En
voulant  calculer le  reste intermédiaire,  on voit  que `6`  est trop
fort, donc on recommence avec `5`. `5` est lui-même trop fort, donc on
recommence avec  `4` puis `3`  qui convient finalement.  Cela, c'était
l'apprentissage  basique.  Ultérieurement,  j'ai   appris  que  si  le
deuxième chiffre du  diviseur était `9` ou même `8`,  on pouvait assez
souvent évaluer le  chiffre du diviseur en prenant  le premier chiffre
du diviseur, _plus `1`_, avec le premier chiffre du du dividende, pour
déterminer le chiffre du quotient. Dans le cas de 65400 et de 1852, le
premier chiffre du quotient aurait été  évalué avec la division de `6`
par `2`, donc directement `3`. Mon module ne fait pas cela. Toutefois,
il est prévu une option « triche » où le module élimine les tentatives
ratées de `6` puis de `5` et de `4`. Cela donne dans le module

```
  En 6, combien de fois 1, il y va 6 fois.
  Mais je triche et j'essaie directement 3.
```

En fait,  cela revient  presque au  même, si ce  n'est que  mon module
passe plus de temps à faire des calculs qu'il abandonnera ensuite. Une
autre différence est que pour la division 74500 par 1852, l'évaluation
initiale 7/2 donne 3, alors que  le premier chiffre du quotient est 4.
Avec ma  méthode, j'essaie directement 4  sans essayer 3 qui  est trop
faible.

Un  dernier point  où,  en fait,  je suis  d'accord  avec mon  module.
Lorsque l'on m'a enseigné les  opérations arithmétiques, j'ai appris à
ne  pas écrire  les retenues,  mais à  les conserver  en mémoire.  Mon
module fera pareil, il n'écrira pas les retenues.

Ce que le module fera
---------------------

Lorsque j'avais 10  ans, je ne savais pas encore  extraire des racines
carrées, je ne connaissais pas la « variante 1822 » de la division, ni
certaines autres variantes de la  multiplication et de la division. Le
module contiendra ces opérations et ces variantes.

La plupart  des êtres humains  savent calculer en base  10 uniquement.
Certains  ont une  connaissance limitée  des  calculs en  octal et  en
hexadécimal,  Mon  module  sera  capable de  faire  des  calculs  dans
n'importe quelle  base de 2  à 36. Ainsi,  la classe de  calcul mental
sait qu'en base  36, `Z × Z = Y1`  (équivalent en base 10 : 35  × 35 =
1225 = 36 × 34 + 1).

Lorsque j'ai appris  les bases de numération, j'ai  appris à convertir
les  nombres de  base 10  en  base _b_  en effectuant  une cascade  de
divisions  et à  convertir  les nombres  de  base _b_  en  base 10  en
effectuant  un calcul  de polynôme  avec le  schéma de  Horner (je  ne
savais pas que cela s'appelait le  schéma de Horner, je ne savais même
pas ce  qu'était un  polynôme, mais  peu importe,  je savais  faire le
calcul).  Mais je  n'ai pas appris à convertir  directement d'une base
_b_ à une  base _b'_. Ultérieurement, j'ai découvert  que certains cas
particuliers, comme  la conversion  de base 2  en base 4,  8 ou  16 ou
inversement,  peuvent donner  lieu à  un  calcul très  simple et  très
rapide. Mais je  n'étais toujours pas en mesure de  conertir un nombre
directement de  la base  _b_ à la  base _b'_ dans  le cas  général. Le
module permettra de convertir un nombre  de base _b_ en base _b'_ pour
n'importe quelles bases entre 2 et 36.

Les nombres implémentés par le module  ne sont pas limités. Ou plutôt,
la limitation  est imposée par  l'interpréteur Raku et par  la machine
sur laquelle il est installé. Ainsi, il sera possible de reproduire la
multiplication de
[Frank Nelson Cole](https://fr.wikipedia.org/wiki/Frank_Nelson_Cole),
lorsqu'il a montré les diviseurs du
[67<sup>e</sup> nombre de Mersenne](https://fr.wikipedia.org/wiki/147_573_952_589_676_412_927)
en 1903.  Lorsque j'avais 10  ans, j'avais qualitativement  toutes les
connaissances nécessaires  pour effectuer  la même  multiplication que
Cole, mais  quantitativement cela  m'aurait demandé  trop de  temps et
trop d'efforts.

Lorsque j'ai appris à effectuer  des multiplications et des divisions,
j'ai appris les phrases qui vont avec (« En 6, combien de fois 1, il y
va 6 fois. »). Ces phrases sont, bien entendu, en français. Toutefois,
le module prévoit un mécanisme  de multi-linguisme. Donc, si je reçois
l'aide de  personnes anglophones,  germanophones ou autres,  le module
pourra écrire ces phrases en anglais, en allemand etc.


Bibliographie
=============

_Zahlwort  und Ziffer:  Eine  Kulturgeschichte  der Zahlen_,  éditions
Vanderhoeck & Ruprecht Publishing Company,  je ne peux pas vous donner
l'ISBN.

_Number Words and Number Symbols, A Cultural History of Numbers_, Karl
Menninger, éditions Dover, ISBN  0-486-27096-3, traduction anglaise du
précédent

_Histoire d'Algorithmes,  du caillou à  la puce_, Jean-Luc  Chabert et
al, éditions Belin, ISBN 2-7011-1346-6
 
Licence
=======

Texte  diffusé sous  la licence  CC-BY-NC-ND :  Creative Commons  avec
clause de paternité, excluant l'utilisation commerciale et excluant la
modification.
