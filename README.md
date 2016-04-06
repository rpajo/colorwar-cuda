# vojnabarv
V direktoriju kjer se nahaja datoteka programInterval.c ustvarimo direktorij "izhodi",
kamor se bodo shranjevale izhodne slike

Najprej se prevede program Generator.c:
$ gcc -o Generator Generator.c
Ko ga poženemo sledimo navodilom programa:
$ ./Generator
Primer:
$ Vnesi verjetnosti R, G, B, O v % // rdeca, zelena, modra in oranzna
$ 10 20 30 40
$ Vnesi sirino in visino:
$ 200 200
$
Program zgenerira sliko zeljene sirine in visine z izbranimi zastopanostmi barv
random.bmp

Prevedemo programInterval.c
$ gcc -o programInterval programInterval.c
Pozenemo z argumentom vhodne slike random.bmp
$./programInterval random.bmp
(lahko vnesemo koncno stevilo iteracij, ce ne zelimo da se "vojna" odvije do konca)
$ Vneste stevilo korakov, ki jih zelite izvesti
$ 10000
$ Runtime: 22
$

V ustvarjenem direktoriju izhodi/ se nahajajo izhodne datoteke
Ustvari se tudi datoteka z zastopanostjo 4 barv - barve.txt
