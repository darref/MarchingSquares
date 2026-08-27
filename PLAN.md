# LE PLAN : du plus simple au plus difficile, sans jamais régresser

## Pourquoi

Le vocabulaire a été construit **par correctifs successifs**, chacun juste, aucun conçu
avec les autres. En une journée le compte est monté 52 → 65 → 92 → 47, et à chaque palier
un défaut de dessin apparaissait ailleurs. Ce n'est pas un manque de rigueur : c'est qu'on
attaquait le problème **entier** à chaque fois, donc on ne pouvait jamais savoir si un
défaut venait du modèle, du dessin, ou de leur rencontre.

On reprend donc **par le bas**, et on ne monte d'un cran qu'une fois le cran d'en dessous
vert — et il doit **rester** vert.

⚠ **Le projet actuel ne se jette pas.** Il reste sous les yeux comme **catalogue des
catégories théoriques** : les 27 silhouettes, les 20 rôles, les 15 croisements, les poses
arrière, les classes de raccord, l'épaisseur, le contrat. On sait ce qu'il faudra traiter ;
on ne sait pas encore dans quel ordre chaque chose devient exprimable. C'est ça qu'on
construit.

## Le fil unique : QUI TRACE ?

Une frontière du monde est un endroit où la matière s'arrête. Le seul défaut qu'on n'a
jamais su nommer d'avance est toujours le même :

> **Deux tuiles tracent la même frontière, ou aucune ne la trace.**

Tout le reste — ovales, demi-lentilles, traits doublés, angles noirs, segments ouverts —
en est une conséquence. Le plan est donc ordonné par **le nombre de tuiles qui peuvent
revendiquer une frontière**, et chaque niveau doit répondre à une seule question :
**qui la trace ?**

Si la réponse exige qu'une tuile connaisse sa voisine, alors le vocabulaire doit grandir —
et **de combien se mesure avant de décider**, jamais après.

## Deux échelles, et on monte l'une après l'autre

### L — la complexité du MONDE (boucle extérieure)

| | ce que le niveau ajoute | tuiles qui revendiquent une frontière | qui trace ? |
|---|---|---|---|
| **L0** | un seul masque binaire, un seul étage, pas de falaise | **1** | la seule tuile qui la touche |
| **L1** | plusieurs étages empilés dans la même case | **k**, k = la chute en étages | à établir — le sommet, a priori |
| **L2** | les falaises : de la matière hors du plan, pans × rangées | **2**, de deux familles | à établir |
| **L3** | les poses arrière : sous-pied, pose derrière, chapiteau sous sa lèvre | **2**, dont une cachée | à établir |
| **L4** | les raccords : l'égalité de pixels imposée entre tuiles | — | — |
| **L5** | la famille à cheval : un second vocabulaire de surface | **1**, décalé d'une demi-case | — |
| **L6** | le guide, le contrat, le plugin : la règle portée deux fois | — | — |

### F — la liberté du DESSIN (boucle intérieure, refaite à chaque L)

| | le trait | à quoi ça sert |
|---|---|---|
| **F0** | **au ras du bord de la case**, aucune liberté | **le témoin.** Si ça ne ferme pas à F0, le défaut est dans le MODÈLE, pas dans le dessin. C'est la seule façon de séparer les deux. |
| **F1** | **droit, mais sa position latérale est libre par tuile** | introduit la liberté de POSITION sans celle de FORME. C'est là que la question des joints se pose à l'état pur. |
| **F2** | **libre à l'intérieur de la tuile** | la liberté complète. Elle ne doit rien casser de ce qui tenait à F1. |

⚠ **F0 avant tout, à chaque niveau.** C'est le seul instrument qui dit *« ce défaut n'est
pas de ta main »*. On l'a payé cher : trois fois cette semaine j'ai corrigé un dessin pour
un défaut de modèle, et une fois l'inverse.

## Les cinq invariants

Ils se mesurent, tous, sur l'image assemblée — jamais en redemandant au modèle ce que le
modèle affirme.

| | invariant | mesure |
|---|---|---|
| **I1** | **Fermeture** — le contour de chaque massif est d'un seul morceau | nombre de morceaux du trait = nombre de contours attendus |
| **I2** | **Épaisseur** — le trait fait un pixel partout | **zéro pavé 2×2 entièrement de trait** |
| **I3** | **Unicité** — chaque frontière du monde est tracée par exactement une tuile | zéro frontière à deux revendiquants |
| **I4** | **Matière** — aucun pixel de fond là où le monde a de la matière | zéro case percée |
| **I5** | **Liberté** — le peintre fait ce qu'il veut à l'intérieur | nombre de pixels dont la position est imposée |

⚠ **I3 EST LE NOUVEAU, ET C'EST CELUI QUI MANQUAIT.** I1, I2 et I4 sont des *conséquences*
qu'on constate ; I3 est la *cause* qu'on peut interdire. Une frontière à deux revendiquants
produit un trait doublé (I2 rouge) ou une lentille (I1 verte **à tort** — deux traits qui se
touchent forment un seul morceau). Le mesurer d'abord, c'est attraper le défaut avant qu'il
ne se déguise.

⚠ **I5 EMPÊCHE LA TRICHE.** Sans lui, tout converge en fermant le dessin : F0 est vert à tous
les niveaux et ne prouve rien. Un niveau n'est acquis qu'à **F2**.

## La règle d'avancement

1. On entre dans un niveau **L** à la liberté **F0**.
2. Les cinq invariants doivent être verts **pour L et pour tous les niveaux en dessous**, à
   **toutes** les libertés déjà acquises.
3. On monte en F. Si un invariant rougit, **le défaut est dans le dessin** — on le corrige
   là, jamais dans le modèle.
4. À F2 vert, on monte en L. Si un invariant rougit à F0 au niveau suivant, **le défaut est
   dans le modèle** — et c'est là, et seulement là, qu'on a le droit de discuter le
   vocabulaire.
5. **Rien ne régresse** : le banc rejoue tous les couples (L, F) déjà acquis à chaque
   exécution. Un couple acquis qui rougit arrête tout.

⚠ **Et le vocabulaire ne grandit que sur mesure.** Quand un niveau exige qu'une tuile en
sache plus, on chiffre le prix **avant** de le payer — en tuiles, et en reliefs refusés.
C'est exactement ce qui a manqué à la montée 52 → 92.

## Ce que chaque niveau devra trancher

- **L0** — rien à trancher, un seul revendiquant. C'est le socle : si le trait ne se ferme
  pas ici, plus rien n'a de sens. **Toutes les silhouettes du guide, d'un trait, d'épaisseur
  constante, sans interruption.**
- **L1** — *le sommet trace, les enterrés se posent pleins.* Une case appartient
  **entièrement** à chaque silhouette qui la contient : le monde n'y a pas de bord, l'entaille
  est une décoration du bord visible. ⚠ Mesuré aujourd'hui, c'est un **no-op** — mais masqué
  par L3, donc à revérifier une fois L1 isolé.
- **L2** — *la surface, ou le flanc ?* Mesuré : le trait du flanc porte la **connexité** du
  contour de la falaise — le retirer coûte exactement deux tirets par falaise — et il ne borde
  **jamais** de la roche (théorème, 0 sur 5 216 flancs). Aujourd'hui les deux tracent.
- **L3** — *une pose arrière ne doit pas tracer.* Mais c'est **la même tuile** qui sert
  visible ailleurs : conflit frontal avec « une tuile, un dessin ». C'est le nœud connu, et il
  s'aborde **après** que L0..L2 soient verts, jamais avant.
- **L4** — les classes de raccord se recensent **depuis le monde**, jamais depuis une formule.
  La leçon est payée : `Seams` en ignorait 60 sur 109.
- **L5** — la famille à cheval ne s'empile pas : une tuile de croisement se lit du sommet de
  quatre cases.
- **L6** — le contrat reste *nécessaire et suffisant*, et le contrôle croisé noyau/plugin
  compare **dans les deux sens**.

## L'acquis

| couple | état | mesuré |
|---|---|---|
| **L0/F0** | **✅ acquis** | 27/27 silhouettes · 42 contours pour 42 massifs, **0 extrémité** · 0 pavé 2×2 · 1 086 frontières, 0 double, 0 muette, 0 parasite · 0 trou · 1 profil |
| **L0/F1** | **✅ acquis** | idem, **3 profils de bord distincts** — la liberté latérale est réelle. Prix : **aucune tuile**, 27 |
| **L0/F2** | **✅ acquis** | idem, **17 profils distincts dont 16 qui serpentent** — le trait est libre à l'intérieur. Prix : **aucune tuile** |
| **L1/F0** | **✅ acquis** | monde 86×174, **4 étages**, 13 200 cases visibles · 0 extrémité · 0 pavé 2×2 · **1 595 frontières, pile max 3**, 0 double, 0 muette, 0 parasite · 0 trou · **27 tuiles** |
| **L1/F1** | **✅ acquis** | 4 étages · 0 extrémité · 0 pavé 2×2 · 1 595 frontières, pile max 3, 0 double · 0 trou · 27 tuiles |
| **L1/F2** | **✅ acquis** | 4 étages, trait libre à l'intérieur · 0 extrémité · 0 pavé 2×2 · 1 595 frontières, pile max 3, 0 double · 0 trou · **10 profils dont 25 qui serpentent** · 27 tuiles |
| L2/F0 | **en cours** | **20/20 rôles de robe** exercés, 1 404 cases de falaise · I1 2 extrémités · I2 1 526 pavés · **I3 196 doubles** · I4 0 trou |
| L2/F1 | **en cours** | **I2 propre (0 pavé)** · I1 213 extrémités · I3 196 doubles |
| L2/F2 | **en cours** | idem, 7 profils dont 21 qui serpentent |
| L3/F0… | à faire | |

### L2 : le témoin accuse le MODÈLE, et c'est la première fois

⚠ **L2/F0 est rouge, et F0 est le témoin** — donc le défaut n'est pas dans la main. La question
que L2 pose est celle que le plan annonçait : *qui trace la frontière entre une surface et une
falaise ?* Sans réponse, **780 frontières portent deux traits**.

**Première réponse, et c'est un théorème déjà écrit au dossier : rien au sud d'une surface.**
Une case dont le sud est vide est une **lèvre** — sa propre falaise commence juste dessous,
toujours. Le bord sud d'une surface et la **crête** du chapiteau sont donc la même frontière, et
c'est le chapiteau qui la porte : lui seul sait de quelle face il s'agit. **780 → 196.**

⚠ **MAIS ELLE NE VAUT PAS À L0 NI À L1**, dont les mondes n'ont pas de falaise : un sud vide y
est une vraie frontière libre, que personne d'autre ne tracera. L'appliquer partout a fait
rougir **les six couples acquis d'un coup** — c'est le rejeu qui l'a dit, pas moi. *Une règle
juste à un niveau peut être fausse au niveau d'en dessous.*

**Deuxième réponse, essayée et REFUSÉE : rien sous le pied.** Le raisonnement était symétrique —
un pied **atterrit** toujours (une chute dans le vide n'en pose pas), la case d'atterrissage a
forcément son nord vide, donc le bas du pied et ce bord nord sont la même frontière. Essayé :
**12 doublements de moins, mais 128 extrémités de plus.** Le bas du pied est ce qui **referme le
contour de la falaise à sa base** ; sans lui les deux flancs s'arrêtent dans le vide.

Reste **196 doublements** : le flanc d'une falaise contre le bord latéral de la surface voisine
— exactement le défaut vu à l'œil ce matin, que le banc nomme maintenant avant qu'on le voie.

**Et il n'y a pas de théorème pour trancher, cette fois.** Mesuré ce matin : un flanc qui
s'arrête ne borde **jamais** de la roche (0 sur 5 216) — mais il borde de la **terre** 35,5 % du
temps et du **vide** 64,5 %. Quand c'est de la terre *plus haute*, cette terre trace son propre
bord latéral, et les deux traits se rencontrent. Quand c'est du vide, personne d'autre ne trace.
La tuile de robe ne peut pas distinguer les deux, et la surface non plus.

⚠ **C'EST LE PREMIER ENDROIT OÙ LE VOCABULAIRE DOIT GRANDIR**, et les deux prix sont déjà
mesurés :

C'est le même arbitrage que celui de la 9.0.0, revenu par l'autre bout — et cette fois il est
mesuré **avant** d'être payé. Voir le tableau ci-dessous.

### Les deux options, MESURÉES sur le même monde (L2/F1)

| option | tuiles | extrémités (I1) | doublements (I3) |
|---|---|---|---|
| aucune | 27 + 20 = **47** | 213 | 196 |
| **A** — un troisième état de flanc sur la robe | 27 + 32 = **59** | **720** | **1450** |
| **B** — le bord (`nu`/`roche`) sur la surface | 37 + 20 = **57** | 222 | **12** |

⚠ **NI L'UNE NI L'AUTRE NE FERME LES 213 EXTRÉMITÉS** — c'est la réponse à la question posée, et
elle est nette. Le défaut des extrémités est **d'une autre espèce** que le doublement : il vient
de ce que le bord latéral d'une lèvre et le flanc de la falaise ne se retrouvent pas quand ce
flanc dit `continue`. Aucun des deux bits ne parle de ce cas-là.

⚠ **B FERME LE DOUBLEMENT, ET PRESQUE ENTIÈREMENT : 196 → 12.** Le bord de la surface est donc
le bon endroit où mettre l'information — celui des deux qui peut se taire sans rien casser.

⚠ **A EST UNE CATASTROPHE, ET LA RAISON ÉTAIT DÉJÀ MESURÉE CE MATIN.** Faire taire le flanc
contre du sol lui retire ce qui **porte la connexité du contour de la falaise** — 720 extrémités,
et les doublements **explosent à 1 450** parce que le contour se fragmente. C'est exactement la
mesure de ce matin : retirer le trait de flanc coûte deux tirets par falaise. On ne peut pas
faire taire le flanc ; on peut faire taire la surface.

⚠ **Et B est moins cher que A** : 57 tuiles contre 59, pour un résultat sans commune mesure.

### Ce que F1 et F2 disent en plus

⚠ **À F1 ET F2, I2 EST PROPRE : zéro pavé.** Les deux traits sont chacun rentrés d'une traversée
dans leur propre case, donc écartés de deux — ils ne se collent plus. Le défaut **visuel** de ce
matin disparaît donc de lui-même dès que le trait rentre ; ce qui reste est structurel, et c'est
I3 qui le dit.

⚠ **Mais I1 ouvre 213 extrémités** : le bord latéral d'une **lèvre** et le flanc de la falaise
qui la porte ne se retrouvent plus. Au ras ils se touchaient ; rentrés, ils se manquent quand le
flanc du chapiteau dit `continue` — la roche y va jusqu'au bord sans trait, et le bord de la
lèvre meurt dessus. Il faudrait un **ergot de coin rentrant sur la robe**, et une robe ne porte
pas la diagonale qui le déclenche.

### La forme d'un bord ne dépend que de ce bord-là

⚠ **C'est ce qui ferme L1/F2, et c'est une loi déjà écrite au dossier pour les falaises.** Deux
silhouettes d'étages différents peuvent s'arrêter au **même endroit** — c'est la « pile », jusqu'à
trois sur la planche — et chacune y trace son bord. Si elles serpentent différemment, le même
trait se **dédouble** : deux courbes qui se croisent et s'écartent, et là où elles passent à un
pixel l'une de l'autre, un pavé. Mesuré : **6 à L1/F2**, tous dans une seule case, invisibles à
F0 et F1 où les bords sont droits donc confondus.

Tirées du seul **côté**, les deux courbes sont la **même** : elles se superposent au pixel près,
et il ne reste qu'un trait.

⚠ **Et la liberté ne s'en trouve pas amputée, seulement déplacée** : ce n'est plus « chaque
tuile dessine son bord comme elle veut » mais « **chaque bord a sa forme**, et toutes les tuiles
la respectent ». Mesuré : 10 profils distincts dont 25 qui serpentent, contre 22 quand chaque
tuile tirait le sien — et surtout, **zéro pavé** au lieu de six.

### « Le sommet trace, les enterrés se posent pleins » : essayé, RÉFUTÉ

⚠ C'était la réponse que ce plan prônait pour L1, et elle se défend : une case appartient
**entièrement** à chaque silhouette qui la contient, donc le monde n'y a pas de bord et
l'entaille n'est qu'une décoration du bord visible. Poser la tuile pleine sous le sommet efface
bien les pavés — **6 à L1/F2, zéro après**.

**Mais elle en ouvre 26 ailleurs.** Le bord d'un étage qui passe **sous** un plateau voisin
cesse d'être tracé, et le contour de la terrasse s'arrête net au pied du plateau au lieu d'y
rejoindre le sien. Ce que l'étage enterré dessine n'est donc **pas** une décoration : c'est ce
qui **raccorde deux terrasses de niveaux différents**. 26 extrémités contre 6 pavés — on garde
l'empilement complet.

⚠ **Et c'est le premier pari du plan que la mesure refuse.** Il était écrit avant d'être
vérifié ; il est corrigé après l'avoir été. C'est exactement pour ça que chaque cran se mesure.

### La traversée vaut au moins DEUX

⚠ L'ergot de coin rentrant se pose **au ras du bord** — il marque une marche sur un côté dont
le cardinal est plein, il n'a nulle part ailleurs où aller. Si un bord traverse à la profondeur
**un**, les deux traits sont voisins d'un pixel et forment un pavé : deux terrasses collées,
l'une par son ergot, l'autre par son bord. Invisible à L0, où les deux ne se rencontrent jamais
dans la même case ; flagrant dès que les étages s'empilent — **5 pavés à L1/F1, 12 à L1/F2**,
zéro une fois la traversée portée à deux.

### I3 compte les traits, il ne les constate plus

⚠ Première version : *« y a-t-il du trait ? »*. Elle répond **oui** aussi bien pour un trait que
pour deux, donc elle laisse passer exactement ce que I3 existe pour attraper. On compte
désormais les passages de fond à trait, en partant du bord vers le milieu.

### Ce que L1/F0 dit, et c'est un résultat en soi

⚠ **À F0, L'EMPILEMENT EST INVISIBLE.** Jusqu'à **trois** silhouettes s'arrêtent au même bord
— c'est la « pile » — et pourtant **un seul trait** s'y voit : au ras du bord, les trois
coïncident au pixel près. Le témoin dit donc que le **modèle** est sain à L1 ; tout ce qui
cassera à L1/F1 sera de la main, pas du modèle. C'est exactement ce que F0 existe pour dire.

⚠ **Et le vocabulaire ne bouge pas : 27 tuiles, comme L0.**

### Ce que L0/F1 a coûté : RIEN — et je me suis trompé une fois là-dessus

⚠ **LA LIBERTÉ LATÉRALE NE COÛTE AUCUNE TUILE.** Quand le trait rentre, deux cases voisines
dont les bords ne rentrent pas pareil laissent une **marche** à leur frontière. La marche est du
côté de celle **qui a de la matière** — l'autre n'a que du fond à cet endroit, et on ne trace
pas dans le vide. Cette case-là se reconnaît à une signature et une seule : ses **deux cardinaux
du coin sont pleins et sa diagonale est vide**.

⚠ **ET L'INDEX CANONIQUE PORTE DÉJÀ CETTE SIGNATURE, C'EST UN THÉORÈME.** J'ai d'abord conclu
l'inverse — « la canonicalisation jette une diagonale, donc elle jette le coin rentrant » — et
payé 44 tuiles pour rien. C'est le contraire : elle **conserve** un bit de coin exactement quand
ses deux cardinaux sont pleins, et un bit de diagonale ne sert au dessin dans **aucun** autre
cas. Le voisinage brut n'ajoute donc rien.

Mesuré (`tools/raw_census.gd`) : **51 voisinages bruts** réalisables en épais pour **27
silhouettes** — et les cinq invariants restent verts **à l'identique** avec 27 tuiles au lieu
de 45.

⚠ **Conséquence directe : le guide n'est pas à refaire.** Il porte les 27, et 27 suffisent.

⚠ **Et une seule des deux cases trace.** La voisine d'en face a son cardinal ouvert et n'a pas
de matière à cet endroit ; si elle traçait aussi, les deux traits seraient collés de part et
d'autre de la frontière — un pavé 2×2, I2 rouge. Ils se rejoignent **en diagonale**, ce qui
suffit à fermer.

⚠ **La profondeur est commune au CÔTÉ, pas à la tuile.** Tirée par tuile, le trait saute à
chaque changement d'index le long d'un même bord : **168 morceaux pour 42 massifs**, exactement
quatre par massif. Commune au côté : 73. Avec les coins rentrants : 42.

### Ce que L0/F2 a coûté : rien de plus que F1

⚠ **LA TRAVERSEE RESTE COMMUNE, ET C'EST LA SEULE CHOSE QUI NE SE NEGOCIE PAS.** Deux tuiles
qui se suivent le long d'un bord se retrouvent à leur frontière ; si elles n'y arrivent pas à
la même profondeur, le trait se rompt. **Entre ces deux points la ligne fait ce qu'elle veut**
— et c'est ça, la liberté de F2, entière. Aucune tuile de plus que les 44 de F1.

⚠ **ET LA MATIÈRE N'A PAS D'AIGUILLE.** Là où deux courbes libres se rencontrent — un coin
saillant dont les deux côtés serpentent — il reste parfois une **pointe d'un seul pixel**,
accrochée par un coin. Son trait n'a alors qu'un voisin : une extrémité, donc une
interruption. Mesuré : **deux, sur toute la planche**, dans la tuile 120. C'est la règle
d'épaisseur d'un cran plus bas, et pour la même raison — une aiguille d'un pixel n'est pas une
silhouette. La tuile se relit elle-même et la retire ; rien là-dedans ne demande de connaître
la voisine.

⚠ **Et le trait se DÉDUIT de la matière, il ne se trace pas à part.** Tracé à part, il faut le
découper à la main partout où deux côtés se rencontrent — et c'est exactement là qu'il
dépassait, en ergot, à chaque coin saillant. Déduit, il épouse la matière par construction.
Tout ce qu'il faut savoir en plus est **local** : au-delà d'un cardinal plein il y a de la
matière, au-delà d'un cardinal vide il n'y a rien.

### Deux définitions du banc que L1 a périmées

⚠ **UNE FRONTIÈRE EST UNE MARCHE ENTRE DEUX ÉTAGES**, pas « de la matière contre rien ». À L0
il n'y a qu'un étage, donc les deux définitions coïncident et la première suffisait. Dès L1,
deux cases voisines de niveaux différents sont **toutes deux** de la matière vue de dessus, et
pourtant la silhouette du haut s'arrête là : c'est une vraie frontière, et le bord du plateau
doit s'y tracer. L'ancienne définition en faisait **1 105 « parasites »** sur un monde
parfaitement juste.

⚠ **ET LE COMPTE DE CONTOURS N'EST PLUS UN CRITÈRE**, seulement un renseignement. Dès L1 le
monde est d'un **seul tenant** avec des plateaux dedans : chaque bord de plateau est un contour
fermé de plus, à l'intérieur — 38 morceaux pour 1 massif, et c'est juste. Les compter
reviendrait à compter les marches du relief. Ce qui reste vrai à tous les niveaux est le mot
demandé : **sans interruption**, c'est-à-dire zéro extrémité.

### Trois défauts de mesure, tous dans le banc

⚠ **I1 « le bon nombre de morceaux » NE SUFFIT PAS** — un contour fermé **avec un ergot** reste
d'un seul morceau. Mesuré : 42 morceaux pour 42 massifs, et **332 extrémités** quand même. Un
trait d'un pixel qui se referme n'en a aucune. I1 exige donc les deux, et c'est le compte
d'extrémités qui a trouvé le vrai défaut : `_edge` traçait sur toute la hauteur de la tuile, y
compris dans la bande que l'autre côté venait de creuser.

⚠ **I4 a été faux deux fois, et aurait condamné F1 à tort.** « Aucun pixel de fond dans une case
de matière » : faux dès que le trait rentre, l'entaille étant de la transparence **voulue** —
28 290 faux trous. Puis « la ligne de bord d'un cardinal plein est opaque » : faux au **coin**,
une case dont l'ouest rentre ayant forcément sa ligne nord entamée, exactement comme sa voisine
du nord — 3 046 de plus. Ce qui reste vrai à toute liberté : **une case sans aucun bord est
entièrement opaque**.

⚠ **Le profil se lit LOIN DES COINS.** Près d'un coin saillant, la rangée n'a pas de matière
du tout — l'autre côté l'a creusée — et la sonde y rencontre le trait **perpendiculaire**, à
une profondeur qui n'a rien à voir. Elle annonçait 24 profils « qui serpentent » sur un F1
parfaitement droit. On lit donc le quart central, là où le côté est seul.

⚠ **I3 se sonde perpendiculairement, au milieu du côté.** Au ras, la ligne du bord suffisait ;
dès que le trait rentre, elle ne trouve plus rien et toutes les frontières se disent muettes.
Et au **milieu**, pas partout : balayer toute la bande ferait prendre le trait du nord — qui
traverse la tuile — pour une revendication de l'ouest.

```
godot --headless --path . --script res://proof/ladder.gd            (tout l'acquis)
godot --headless --path . --script res://proof/ladder.gd -- L0 F0   (un couple)

# et pour le REGARDER plutot que le croire -- la planche entiere, puis un gros
# plan decoupe en CASES suivi du zoom :
... -- L0 F1 sortie.png
... -- L0 F1 sortie.png 0 6 16 14 40
```

⚠ **Le zoom est au plus proche**, jamais lissé : un lissage inventerait des coutures que le
dessin n'a pas. Même raison que pour l'aperçu en jeu et pour les voisines.

⚠ **Trois défauts trouvés en écrivant le banc, tous dans le banc.** C'est le prix d'un
instrument neuf, et ils valent d'être notés :

- **le pixel de coin ne décide de rien.** Il appartient à *deux* arêtes : le trait d'un flanc
  ouest y pose son premier pixel, qui tombe aussi sur la ligne du bord nord. Sans l'exclure,
  chaque case semblait revendiquer des côtés qu'elle ne trace pas — **516 faux parasites sur
  un monde parfaitement juste** ;
- **`index_map` prend un relief, `index_at` prend un masque.** Le premier calcule les robes
  au passage — c'est L2, pas L0 — et lu sur un masque il rend une case par case du cadre,
  vide comprise : 3 339 cases de « matière » sur un monde qui en compte 1 347 ;
- **l'îlot « étiré » ne suffit pas à faire épais.** La colonne du milieu d'une fenêtre ne
  s'étire pas : l'index 5 (N+E) devient une équerre d'un pixel de large, donc fine, et l'îlot
  fabrique des silhouettes hors vocabulaire — 33 exercées pour 27 annoncées. La construction
  du dépôt, elle, **cherche** une position et la juge.

## Le premier pas

Un banc `proof/ladder.gd` qui prend **(L, F)** et rend les cinq invariants. Il commence avec
L0/F0 seulement, et il grandit avec le plan. Tant qu'il ne sait mesurer qu'un couple, il
mesure déjà mieux que tout ce qu'on a : il dit **où** est le défaut, pas seulement qu'il y en
a un.

⚠ **Et il ne redérive jamais le calcul qu'il contrôle.** C'est la faute la plus chère du
projet : `_check_wall_seams` recalculait ses enchaînements avec la formule même qu'il
vérifiait — donc la même erreur, donc rien de vérifié, et la suite était verte pendant que le
dessin cassait aux deux tiers de ses jonctions. Le banc **rend l'image et regarde les
pixels**.
