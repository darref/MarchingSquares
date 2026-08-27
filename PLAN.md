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

## L'ORDRE DES PRIORITÉS — il tranche tout le reste

Posé par l'utilisateur, et **lexicographique** : on ne descend au critère suivant qu'une fois le
précédent satisfait.

1. **JAMAIS TROUÉ.** La fermeture n'est pas négociable. I1 à zéro, ou ce n'est pas livrable.
2. **LA LIBERTÉ NE SE SACRIFIE QUE SI C'EST DÉMONTRÉ IMPOSSIBLE.** Pas « si c'est plus simple »,
   pas « si ça coûte moins » — *impossible*, et prouvé. C'est la loi du moindre ras, généralisée.
3. **LE NOMBRE DE TUILES DOIT ÊTRE MINIMAL, PAS FORCÉMENT PETIT.** Ce qui est exigé est une
   **preuve de minimalité**, pas un petit chiffre. 248 démontré minimal vaut mieux que 81 dont
   personne ne sait s'il l'est.

⚠ **ET ÇA DISQUALIFIAIT LES DEUX CONCEPTIONS DE J2 EN L'ÉTAT.** Le bit sur la face laissait 34
extrémités, le bit sur la surface 5 : **les deux étaient troués**, donc aucune n'était acceptable.
Le travail n'était pas de choisir entre elles, c'était de **fermer d'abord** — et de ne comparer
les coûts qu'ensuite.

⚠ **C'EST FAIT : le bit sur la surface est à ZÉRO extrémité**, de L2/F0 à L3/F2, et l'ordre des
priorités descend donc au critère 2. Les deux autres conceptions restent rouges là où elles
l'étaient — **32 extrémités** pour le bit sur la face (deux de moins, fermées par la même règle),
**202 doublements** pour l'absence de bit — et sont joignables par `LADDER_J2=face` et
`LADDER_J2=none`.

⚠ **Et l'ordre interdit un raccourci qui tentait :** fermer en figeant. Un dessin sans liberté
ferme toujours (F0 le prouve à chaque niveau) ; c'est le critère 2 qui l'interdit, et I5 qui le
mesure.

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

## Les six invariants

Ils se mesurent, tous, sur l'image assemblée — jamais en redemandant au modèle ce que le
modèle affirme.

| | invariant | mesure |
|---|---|---|
| **I1** | **Fermeture** — le contour de chaque massif est d'un seul morceau | nombre de morceaux du trait = nombre de contours attendus |
| **I2** | **Épaisseur** — le trait fait un pixel partout | **zéro pavé 2×2 entièrement de trait** |
| **I3** | **Unicité** — chaque frontière du monde est tracée par exactement une tuile | zéro frontière à deux revendiquants |
| **I4** | **Matière** — aucun pixel de fond là où le monde a de la matière | zéro case percée |
| **I5** | **Liberté** — le peintre fait ce qu'il veut à l'intérieur | nombre de pixels dont la position est imposée |
| **I6** | **Vérité** — ce qui se voit à travers une transparence est ce que le modèle nomme | zéro pixel de matière inventée, zéro perdue, **et la fenêtre regardée est dite** |

⚠ **I3 EST LE NOUVEAU, ET C'EST CELUI QUI MANQUAIT.** I1, I2 et I4 sont des *conséquences*
qu'on constate ; I3 est la *cause* qu'on peut interdire. Une frontière à deux revendiquants
produit un trait doublé (I2 rouge) ou une lentille (I1 verte **à tort** — deux traits qui se
touchent forment un seul morceau). Le mesurer d'abord, c'est attraper le défaut avant qu'il
ne se déguise.

⚠ **I5 EMPÊCHE LA TRICHE.** Sans lui, tout converge en fermant le dessin : F0 est vert à tous
les niveaux et ne prouve rien. Un niveau n'est acquis qu'à **F2**.

⚠ **I6 EST NÉ D'UN CONSTAT D'IMPUISSANCE, ET C'EST SA MEILLEURE RÉFÉRENCE.** Les cinq premiers
ne distinguaient pas `mute` de `full` à L3 — verts sur les cinq, tous les deux, alors que les
deux images diffèrent à l'œil. Ce qu'une pose arrière garantit n'est pas *de la matière quelque
part* — I4 le dit déjà — mais **la matière que le modèle nomme, à cet endroit-là**. Le banc ne
pouvait donc pas trancher L3 ; il le peut maintenant, et il l'a fait.

⚠ **ET LA FENÊTRE SE DIT, MÊME QUAND LE COMPTE EST À ZÉRO.** Une pose arrière ne se voit qu'à
travers une transparence : à F0 il n'y en a aucune, donc zéro ne prouve rien. C'est la leçon déjà
payée trois fois au dossier — *une mesure doit avoir vu quelque chose*.

⚠ **ET I6 LIT LA CONTRIBUTION DE LA POSE, JAMAIS LA COULEUR DU PIXEL.** Le banc assemble une
seconde fois **sans une seule pose arrière** : la pose a contribué exactement là où les deux
images diffèrent. Classer par la couleur aurait demandé de décider si un pixel de trait vient de
la roche reposée ou du sol d'en dessous — deviner, là où on peut mesurer.

## La règle d'avancement

1. On entre dans un niveau **L** à la liberté **F0**.
2. Les six invariants doivent être verts **pour L et pour tous les niveaux en dessous**, à
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
| **L2/F0** | **✅ acquis** | **57 + 20 = 77 tuiles** · les six verts |
| **L2/F1** | **✅ acquis** | **0 extrémité** — les deux derniers pixels sont fermés · les six verts |
| **L2/F2** | **✅ acquis** | idem, **7 profils dont 34 qui serpentent** |
| **L3/F0** | **✅ acquis, et aveugle** | l'image est **identique au bit près** à L2/F0 — I6 y regarde une fenêtre de **0 pixel** |
| **L3/F1** | **✅ acquis** | `mute` **tranché par I6** · 0 extrémité · **I6 ✅ à travers 5 648 pixels de transparence** |
| **L3/F2** | **✅ acquis** | idem, 7 profils dont 34 qui serpentent · **I6 ✅ à travers 8 191 pixels** |

| **L4** | **✅ acquis, à tous les niveaux** | les raccords se recensent depuis le monde **et contraignent le dessin** — 50 bords → **35 classes** à L2/L3, les six verts, et I5 passe de **7 à 20 profils distincts** |

⚠ **L'ÉCHELLE EST DONC VERTE DE L0/F0 À L3/F2, DOUZE COUPLES, À 77 TUILES** — 57 surfaces et 20
rôles de robe — **raccords compris**.

### L4 : LES RACCORDS SE RECENSENT, ET ILS RENDENT DE LA LIBERTÉ AU LIEU D'EN PRENDRE

Le banc ne décrit plus le dessin, il le **contraint** : chaque classe de raccord reçoit sa graine,
et deux bords qui doivent être le même dessin le sont **par construction**. Ce qui rend la mesure
falsifiable : si la clôture manque un lien, un invariant rougit.

| couple | bords tracés | **classes indépendantes** | liens de superposition | I5 à F2 |
|---|---|---|---|---|
| L0 | 28 | **28** | **0** — un seul étage, rien ne s'empile | 19 profils |
| L1 | 28 | **22** | 365 | 18 profils |
| L2 · L3 | 50 | **35** | 252 | **20 profils, 27 qui serpentent** |

⚠ **UNE SEULE DES DEUX RELATIONS EST REQUISE, ET C'EST L'EXPÉRIENCE QUI L'A DIT.**
- **La superposition l'est** : deux tuiles empilées dans une même case tracent le même bord, et
  si elles ne le tracent pas pareil le trait se dédouble. C'est exactement le défaut mesuré à
  L1/F2 — *« deux silhouettes d'étages différents peuvent s'arrêter au MÊME endroit, jusqu'à
  trois sur la planche »*, six pavés. Il est maintenant **nommé et interdit**, au lieu d'être
  évité par un dessin uniforme. À L1 elle soude 28 bords en 22 ; à L0, où rien ne s'empile, elle
  ne soude **rien du tout**.
- **La continuation ne l'est pas.** Deux bords colinéaires dans deux cases voisines se
  rencontrent à leur frontière commune parce que **la traversée les y ramène tous les deux**,
  quelle que soit leur classe. La joindre coûterait **trois fois la liberté** — 35 classes → 11 —
  pour rien.

⚠ **ET J'AI COMMENCÉ PAR LA JOINDRE, EN CROYANT LA MESURER.** Le premier recensement donnait 11
classes et mettait `S ouest` et `W ouest` dans la **même** classe — alors que les deux familles
ont des lois de traversée différentes et que I1 était vert. Le lien croisé existait bien (161
occurrences, toutes verticales : le bord ouest d'une lèvre au-dessus du flanc ouest de sa propre
face) mais il ne prouvait pas une égalité : les deux traits se rejoignent **par le chapiteau**,
pas en étant la même ligne. Une relation observée n'est pas une contrainte.

⚠ **ET SUR-JOINDRE EST SÛR, SOUS-JOINDRE EST SILENCIEUX.** C'est pourquoi la seule preuve
acceptable est de **peindre par classe et de mesurer** : une clôture trop large ne rend jamais un
tileset faux, seulement plus contraint ; une clôture trop étroite laisse le dessin se casser sans
que rien ne le dise. Les six invariants restent verts aux douze couples.

⚠ **DEUX FAUTES DE COMPTEUR, MÊME ESPÈCE.** Le recensement n'incrémentait que quand l'union
**changeait** quelque chose : le compte dépendait donc de l'ordre des cases, et la superposition
annonçait **zéro lien** sur un monde à quatre étages qui en est plein. On compte les relations
observées, pas les fusions effectuées.

### ⚠ LA PLANCHE NE SUFFIT PAS : LE GUIDE EST ROUGE, ET IL L'ÉTAIT DÉJÀ

`LADDER_WORLD=guide` fait tourner le même banc sur le **guide** au lieu de la planche de preuve.
Résultat à L3/F2 : monde 104×141, **61 + 20 = 81 tuiles**, 52 bords → 34 classes… et **I1 rouge,
13 extrémités**.

⚠ **Elles n'ont rien à voir avec L4** : la liste est **identique au pixel près** avant et après le
recensement — vérifié en rejouant la version d'avant sur le même monde. C'est un défaut du dessin
que la planche n'exerce pas.

**Ce qu'elles sont, lu au pixel** : toutes en `(15,3)`, `(0,3)`, `(15,4)`, `(0,4)` — le bout d'un
bord nord contre le bord latéral de la case d'à côté, là où le frontière **tourne**. C'est la
famille de l'**ergot de coin rentrant**, et plus précisément de la règle qui le fait taire :
*« l'ergot se tait quand ce qu'il devait rejoindre s'est tu »*. Sur la planche cette conjonction
n'arrive jamais ; sur le guide, treize fois.

⚠ **ET C'EST LE RÉSULTAT LE PLUS UTILE DE LA JOURNÉE**, parce qu'il porte sur la méthode : **un
banc qui ne connaît qu'un monde ne prouve que ce monde**. La planche de preuve est bâtie pour
exercer le *vocabulaire* — elle porte les 27 silhouettes — mais pas les *rencontres*. Le guide en
porte d'autres, et un relief tiré au sort en porterait d'autres encore. **Le prochain travail est
là**, et il est double : fermer les treize, et faire tourner les six invariants sur plus d'un
monde.

### L3 : LE TÉMOIN EST AVEUGLE, ET C'EST UN RÉSULTAT

⚠ **L3/F0 N'EST PAS UN CRAN, C'EST UN ANGLE MORT.** Le banc pose les 763 poses arrière de la
planche — 372 chapiteaux sous leur lèvre, 387 pieds d'atterrissage, 4 corps d'écrêtage — et rend
une image **identique au bit près** à celle de L2/F0 (même md5). La raison est structurelle :
*une pose arrière ne se voit qu'à travers une transparence*, et à F0 le trait est au ras, donc la
tuile de surface est **pleine** et ne laisse rien voir.

**Conséquence sur la méthode, et elle est sérieuse.** La règle d'avancement dit : *« si un
invariant rougit à F0 au niveau suivant, le défaut est dans le modèle ; s'il rougit en montant en
F, il est dans le dessin »*. À L3 cette séparation **ne tient plus** : le niveau n'existe qu'à
partir de F1, donc un rouge à L3/F1 peut être de la règle comme de la main. L3 n'est pas un
niveau du **monde**, c'est un niveau de la **liberté du dessin** — le premier de l'échelle.

### L3 : TROIS CONCEPTIONS, MESURÉES SUR LE MÊME MONDE (L3/F1)

Une pose arrière repose une tuile de robe sous une case de surface. La question du niveau est
donc : **cette tuile cachée a-t-elle le droit de tracer ?**

| conception | tuiles | dessins | I1 extrémités | I2 pavés | **I6 matière inventée** |
|---|---|---|---|---|---|
| `trace` — elle pose **sa** tuile, contour compris | 76 | 76 | 2 — dont **une nouvelle** | **300** | 0 |
| `full` — la **roche pleine** (rôle continue/continue, un corps) | 76 | 76 | 2, celles de L2 | 0 | **1 506** |
| **`mute`** — sa matière **sans** son contour | 76 | **+20** | 2, celles de L2 | 0 | **0** |

⚠ **LA PREMIÈRE EST REFUSÉE, ET LE DÉFAUT EST EXACTEMENT CELUI QUE J2 A DÉJÀ TRANCHÉ.** Les 300
pavés sont **282 sous un chapiteau reposé, 15 sous un pied, 3 sous un corps**, tous sur la
**bande de flanc** au milieu du côté (`3,7` `3,8` `3,9` à l'ouest, `12,7…` à l'est). La surface
trace son bord latéral à sa traversée, la roche reposée trace son flanc à la sienne : deux traits
à un pixel l'un de l'autre. C'est *sommet contre face*, mais **empilé dans une seule case** au
lieu d'être côte à côte.

⚠ **ET I3 NE LE VOIT PAS — C'EST I2 QUI L'ATTRAPE.** La sonde de I3 compte les *passages* de fond
à trait ; les deux traits étant collés, elle n'en compte qu'un. Déjà écrit au dossier pour les
lentilles, et vrai ici pour la raison inverse : *ce qui se touche ne se compte pas deux fois.*

⚠ **LA POSE ARRIÈRE NE FERME AUCUNE DES DEUX EXTRÉMITÉS DE L2, et le dossier annonçait le
contraire.** Il était écrit que les deux derniers pixels de L2 « appartiennent à L3 » et que la
pose derrière les fermerait. Mesuré : elle ne les ferme que dans la conception qui **trace** — et
celle-là en rouvre une autre (20,157) et coûte 300 pavés. Muette ou pleine, les deux extrémités
de L2 sont **toujours là**. Fermer demande un trait ; une pose arrière qui ne trace pas ne peut
rien fermer. **Le renvoi à L3 était une hypothèse, pas une mesure.**

⚠ **ET LES CINQ INVARIANTS NE DISTINGUAIENT PAS `mute` DE `full`.** Ils étaient identiques sur
les cinq, et pourtant les deux images diffèrent à l'œil : `mute` montre le **vrai flanc** de la
vraie face (renflement compris, creux compris), `full` affirme de la roche **jusqu'au bord de la
case**, y compris là où le flanc s'arrête. C'était le manque de l'échelle à ce cran : *ce qu'une
pose arrière garantit — la bonne matière derrière une transparence — n'était lu par aucun des
cinq.* **D'où I6, écrit pour ça** — et il a tranché.

**Le prix, dit franchement :** `full` ne coûte **aucun dessin** — le rôle (continue, continue)
d'un corps n'a aucun côté ouvert, c'est un carré de roche sans trait, et le peintre l'a déjà fait.
`mute` coûte **un second dessin par rôle**, c'est-à-dire une seconde feuille ou un trait effacé à
l'exécution : ça contredit « une tuile, un dessin » et ça se paierait au contrat.

### L3 EST TRANCHÉ : `mute`, ET C'EST I6 QUI L'A DIT

Le banc n'avait pas d'arbitre ; il en a un. **`full` affirme 1 506 pixels de roche que le modèle
n'a pas**, à travers les 5 828 pixels de transparence par lesquels les 763 poses arrière se
voient — soit **26 % de la fenêtre**. `mute` en invente **zéro**, et n'en perd aucun.

⚠ **LE CHIFFRE EST GROS, ET C'EST CE QUI SURPREND.** L'argument de `full` était qu'on ne voit
d'une pose arrière qu'un liseré de coin découpé, où la roche est de toute façon là. Mesuré, c'est
faux d'un quart. Et **où** ces pixels tombent se compte plutôt que se devine :

```
  828  bande ouest, sous un chapiteau (sous sa levre)
  576  bande est,   sous un chapiteau (sous sa levre)
   90  bande ouest, sous un pied (atterrissage)
   12  bande est,   sous un corps (ecretage)
```

⚠ **TOUT EST LATÉRAL, ET RIEN AU NORD NI AU SUD** — 1 404 sur 1 506, soit 93 %, sous un chapiteau
reposé. C'est la superposition de **deux transparences du même côté** : le flanc du chapiteau
rentre là où son pan dit qu'il s'arrête, et la surface au-dessus rentre au même bord. Le nord ne
donne rien parce qu'une lèvre a sa voisine du nord pleine ; le sud non plus, parce que le sud
d'une surface se tait dès L2. Par ce trou-là le modèle dit qu'il n'y a **rien** — et `full` y met
de la roche.

⚠ **ET C'EST LA RÈGLE 3 DE LA CHARTE, PAS UNE PRÉFÉRENCE DE DESSIN.** *Rien n'est fabriqué à la
place de l'utilisateur.* Une pose arrière qui affirme de la matière jusqu'au bord de sa case
fabrique — et le pire est qu'elle le fait **sans une seule erreur**, verte sur les cinq premiers
invariants. C'est exactement l'espèce de défaut que ce plan existe pour attraper.

⚠ **LE PRIX RESTE DÛ, ET IL EST ÉCRIT.** `mute` demande un **second dessin par rôle** — 20 de
plus — et contredit « une tuile, un dessin ». Ce n'est pas une tuile de plus au vocabulaire : la
tuile est la même, c'est sa version *sans trait* qu'il faut poser dessous. Un moteur la produit
soit d'une seconde feuille, soit en effaçant le trait à l'exécution. **Ça se paiera au contrat**,
et le jour venu c'est une clause, pas une surprise.

⚠ **`trace` RESTE REFUSÉE, ET POUR UNE AUTRE RAISON QUE `full`.** Elle est juste sur I6 — elle
pose la vraie tuile — mais elle **trace deux fois la même frontière**, ce qui est le défaut que
tout le plan poursuit. Les deux refusées restent joignables par `LADDER_BACKING=trace` et
`LADDER_BACKING=full`, comme trace de la mesure ; `mute` est le défaut du banc.

⚠ **ET L3/F0 EST ACQUIS SANS RIEN PROUVER.** Les six sont verts, mais **I6 y regarde une fenêtre
de zéro pixel** : à F0 la surface est pleine, il n'y a aucune transparence par où voir une pose
arrière. C'est écrit dans la ligne de sortie, à côté du zéro, pour qu'on ne prenne jamais ce
vert-là pour une preuve.

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

**B est adopté.** Le vocabulaire de L2 est donc **37 silhouettes + 20 rôles = 57 tuiles**, et il
reste trois défauts à L2, tous chiffrés : 222 extrémités (F1/F2), 94 pavés (F0 seulement), et
12 doublements.

### Les 222 extrémités : ce que c'est, et ce qui ne marche pas

Le bord latéral d'une **lèvre** meurt à son bas, faute de retrouver la **crête** du chapiteau
qui la porte. Les deux sont dans des tuiles différentes : le bord latéral franchit la frontière
horizontale à la profondeur `dW`, la crête franchit les frontières verticales à la profondeur
`dN`. Aucune des deux ne passe par le **coin** que les deux cases partagent, donc elles se
manquent. Au ras (F0) elles se touchaient, d'où les 2 extrémités seulement.

⚠ **ET LE PINCEMENT AU SUD NE MARCHE PAS : 222 → 848, plus 61 pavés.** L'idée était de ramener
le bord latéral au ras à son dernier pixel, pour qu'il touche au moins le coin. Mais **la loi de
la traversée ne se plie pas** : un bord latéral doit franchir la frontière horizontale à la
profondeur **commune**, et le pincer d'un côté le brouille avec la case du dessus comme avec
celle du dessous.

### LA RÈGLE DE LA CASCADE, TROUVÉE : les bords d'une FACE sont les bords de sa case

⚠ **UNE FACE OCCUPE SA CASE ENTIÈRE, ET LE PLATEAU AU-DESSUS AUSSI.** La frontière entre les
deux — la **crête** — ne peut donc pas flotter librement : elle doit **toucher le bord** là où
les perpendiculaires la rejoignent. *(Première formulation : « c'est le bord de case lui-même ».
Trop fort — voir la loi du moindre ras : le pincement aux deux traversées suffit, et rend la
liberté du milieu.)* Idem pour le pied (contre l'atterrissage) et pour les flancs (contre ce qu'il y a
à côté). Une crête rentrée est une ligne qui ne peut retrouver **aucune** des perpendiculaires
qui arrivent au bord — d'où la cascade, et d'où l'échec de tout ergot de longueur fixe.

**Mesuré : 222 → 43 extrémités.** Les bords d'une robe sont désormais au ras de sa case.

⚠ **Et ça ne coûte rien du tout : 57 tuiles, inchangé.** Ce n'est pas un bit de plus, c'est une
liberté qu'on **n'avait pas le droit de prendre**. La robe garde ses 20 rôles ; ce qu'elle perd
est une ondulation que la géométrie interdisait.

⚠ **Ce que la surface, elle, conserve.** Un bord de surface contre le **vide** est une vraie
frontière de matière, libre de serpenter — et c'est tout L0 et L1. Contre une **face**, non :
les deux ont de la matière, la frontière est un pli, et un pli est au bord.

**Restent 43**, dont **30 « surface, bord sud, en face : surface »** et **9 au nord** : plus une
seule falaise dedans. C'est l'exception de la règle de la lèvre — dans 30 cas la case d'en
dessous porte une surface, pas une robe, et personne ne trace.

⚠ **ET RENDRE LE SUD NE MARCHE PAS : 222 → 669, 288 doublements, 11 388 parasites.** Le bord
sud d'une case et le bord **nord** de celle d'en dessous sont **la même frontière** : l'une des
deux doit se taire, et c'est le sud — la voisine du nord existe toujours, alors que la crête,
elle, peut manquer.

⚠ **ET LE NORD D'UNE SURFACE NE SE MET PAS AU RAS.** Le raisonnement était celui de la crête —
mon sol occupe ma case entière, le sol plus bas occupe la sienne, la frontière est le bord — et
il est **faux** ici. La différence : sous une crête il y a une **face**, qui occupe sa case et
dont le haut *est* le bord ; au nord il n'y a qu'un sol plus bas, dont le bord à lui est libre,
et mettre le mien au ras l'empêche de le retrouver. **43 → 65, plus 94 pavés.**

### J2 : TROIS CONCEPTIONS, ET LE VRAI CHOIX EST UN CHOIX DE DESSIN

| | **aucun bit** | bit sur la **face** | bit sur la **surface** |
|---|---|---|---|
| tuiles rencontrées | **47** | 60 | 76 |
| **forme fermée** | **47** | 81 | 248 |
| extrémités (F1/F2) | **2** (L3) | 32 | **2** (L3) |
| pavés (F1/F2) | **0** | **0** | **0** |
| I3 doublements | 196 | 0 | **0** |
| à l'œil | **les ovales** | — | un seul trait |

⚠ **ET LA TROISIÈME COLONNE N'ÉTAIT PAS PRÉVUE : SANS AUCUN BIT, ÇA FERME.** I1 à 2 extrémités
(celles de L3), I2 à zéro pavé — la fermeture et l'épaisseur sont **aussi bonnes qu'à 76
tuiles**, pour **47**. Ce que J2 payait n'était donc jamais la fermeture.

⚠ **CE QUE J2 PAIE, C'EST LES OVALES.** Sans bit, la face et la surface tracent chacune son
bord, séparés par une bande de sol qui se **referme aux traversées** — la chaîne de lentilles
signalée le 27 août au matin. C'est exactement ce que I3 compte, et c'est pour ça qu'il existe :
**I1 et I2 sont verts pendant que l'œil voit le défaut.**

**LE CHOIX EST FAIT : c'est la surface qui se tait, 76 tuiles.**

⚠ **Et le compte est passé à 77 depuis**, d'une tuile et pour fermer les deux dernières
extrémités de L2 — voir *« une chute qui s'arrête doit se fermer »*. Le choix, lui, n'a pas
bougé.

⚠ **La règle qui tranche est celle du projet depuis le début : traits continus SIMPLES, jamais
doublés.** C'est elle qui garantit la **liberté maximale** et l'**exhaustivité** de ce qu'on
pourra dessiner — un trait doublé n'est pas seulement laid, il retire à l'artiste la moitié de
ce qu'il pouvait exprimer à cette frontière. Elle élimine la conception sans bit (196
doublements) ; l'ordre des priorités élimine celle sur la face (trouée). Reste la troisième.

⚠ **Et sa minimalité n'est pas prouvée : 248 est une BORNE, pas une preuve.** C'est le travail
qui reste, et il a une contrainte ferme — **toute réduction doit garder I3 à zéro et I1 à zéro.**

*Ce qui suit est la comparaison qui a mené là.*

- **47 tuiles**, un vocabulaire minimal *démontré* (aucun bit, donc la forme fermée EST le compte),
  au prix des ovales à chaque jonction surface/falaise ;
- **76 tuiles**, un trait unique partout, au prix d'une forme fermée à 248 non prouvée minimale.

⚠ **LA QUATRIÈME PISTE EST MESURÉE, ET ELLE EST MORTE.** Elle était écrite ainsi : garder les
deux traits mais **empêcher la bande de se refermer**, en décalant les traversées des deux
familles — même contenu, autre lecture, zéro bit. Implémentée derrière `LADDER_SHIFT` (le
pincement de la face se fait aux traversées de la surface : il suffit de les décaler), mesurée à
L2/F1 sans aucun bit :

```
SHIFT = 2   47 tuiles   I3 : 196 doublements
SHIFT = 4   47 tuiles   I3 : 196 doublements   (et les 80 trous de I1 tombent a 0)
```

⚠ **Pas un doublement de moins, et c'était démontrable sans mesurer : I3 compte les
REVENDIQUANTS, pas la forme du sliver.** Décaler les traversées change *où* les deux traits
touchent le bord de case, jamais le fait qu'ils sont **deux**. La piste ne pouvait donc jouer que
sur la lecture à l'œil, pas sur la règle qui a tranché J2 — *traits continus simples, jamais
doublés*. Le code est retiré ; la mesure reste ici pour ne pas la refaire.

### L'ancienne comparaison à deux conceptions

| | bit sur la **surface** | bit sur la **face** |
|---|---|---|
| tuiles rencontrées | 76 | **60** |
| **forme fermée** | 228 + 20 = **248** | 27 + 54 = **81** |
| **extrémités** | **2** (et elles relèvent de L3) | 32 |
| I2 · I3 · I4 · I5 | ✅ | ✅ |

⚠ **ET LES 32 SONT TOUTES AUX COINS D'UNE ROBE.** Quand la face **cède** un flanc, sa crête et
son pied finissent au coin de la case et ne trouvent personne : le bord de la surface d'à côté
est rentré de `d`. C'est le théorème de la traversée, qui exige que **l'un des deux touche le
bord au point où l'autre le traverse** — et ici aucun des deux ne le fait.

⚠ **MESURE QUI TUE LA SORTIE FACILE : 1 212 bords ouverts d'une surface, dont 1 095 (90,3 %)
n'ont AUCUNE face en face.** L'idée « la face trace tout, la surface se tait toujours » est donc
morte : dans neuf cas sur dix il n'y a pas de face, la surface doit tracer, et le monde perdrait
90 % de ses bords. **La face est l'exception, pas la règle.**

**Donc, selon l'ordre des priorités** : le bit sur la **surface** est la seule conception qui
satisfait le critère 1 (jamais troué). Le bit sur la face reste **trois fois moins cher en
borne** et c'est lui qu'il faut faire fermer — mais tant qu'il ne ferme pas, il ne compte pas.

### L2/F0 EST ACQUIS — le témoin est clos

⚠ **Zéro extrémité, zéro pavé, zéro doublement, zéro trou, la liberté promise tenue.** Le modèle
de L2 est donc **sain** : tout ce qui reste à F1 et F2 est de la main, pas de la règle. C'est
exactement ce que F0 existe pour dire, et c'est la première fois qu'il le dit à L2.

### LE NORD NE SE TAIT QUE SOUS UN VRAI PIED

⚠ La surface se taisait au nord dès qu'une **robe** la couvrait — en supposant que cette robe
tracerait son bas. **Faux pour une chute écrêtée** : elle s'arrête sur une rangée de **corps**,
qui n'a pas de bord bas. La frontière restait alors sans personne, et la roche butait sur
l'herbe **sans un trait**. Vu au pixel.

La condition se resserre à *« et seulement si c'est un PIED »*. **3 → 2 extrémités, +1 tuile**,
et surtout **F0 passe à zéro**.

### LES DEUX DERNIÈRES ÉTAIENT À L2, ET J'AI RENVOYÉ DEUX FOIS AU MAUVAIS ENDROIT

⚠ **Elles sont la même configuration : une chute ÉCRÊTÉE.** En (19,152) la robe est sur de la
plaine et juste dessous se trouve un bloc d'étage **2** qui arrête la chute ; en (16,153) idem,
un cran plus haut. La roche s'arrête donc **contre un bloc**, et son bas n'est ni un pied ni une
frontière avec du vide. *Ça*, c'était juste.

**Ce qui suivait ne l'était pas, deux fois de suite.** D'abord : *« le dossier a déjà la pièce qui
ferme ça, la pose derrière — c'est du L3, pas du L2 »*. Mesuré au cran suivant : la pose derrière
ne ferme **rien**, parce qu'elle ne trace pas — et une pose qui ne trace pas ne peut fermer aucun
contour. Puis, ce renvoi corrigé, le dossier a laissé les deux pixels sans propriétaire.

⚠ **ILS ÉTAIENT À L2, ET LA PIÈCE QUI LES FERME Y ÉTAIT DÉJÀ ÉCRITE** — voir la section suivante.
Le renvoi au cran d'après était confortable : il donnait un défaut « expliqué » sans avoir à le
résoudre. **Un défaut renvoyé n'est pas un défaut clos**, et l'échelle ne sert à rien si on s'en
sert pour déménager les rouges.

### CHAQUE FAMILLE GARDE SA TRAVERSÉE — deux tentatives, deux refus

Les deux dernières extrémités sont un désaccord de profondeur : la **face** pince à zéro, la
**surface** traverse à `d`. Les deux façons de les mettre d'accord ont été mesurées, et refusées :

| tentative | résultat |
|---|---|
| la face pince à la profondeur canonique | **2 → 186 extrémités** — elle perd le contact avec les perpendiculaires **de sa propre famille**, qui se rejoignent au coin |
| la surface traverse au ras | 2 → 6 extrémités et **57 pavés** — elle perd ses propres ergots, posés au bord |

⚠ **Chaque famille a sa traversée, et c'est LEUR RENCONTRE qu'il faut régler** — pas l'une des
deux qui doit céder. **Et la rencontre s'est réglée sans toucher à aucune des deux traversées** :
en donnant un bord bas à la rangée écrêtée, la frontière horizontale revient au bord de la case,
là où le flanc l'attendait. Les deux tentatives ci-dessus cherchaient à déplacer un trait ; ce
qu'il fallait, c'était **désigner qui le trace**. C'est le fil du plan, et je l'avais lâché.

### UNE CHUTE QUI S'ARRÊTE DOIT SE FERMER — ET C'ÉTAIT LA MOITIÉ DE LA RÈGLE

⚠ **LE PIED FERMAIT LE VIDE ET PAS L'ÉCRÊTAGE, ALORS QUE C'EST LE MÊME FAIT.** La règle écrite
plus bas substituait le PIED à la dernière rangée d'une chute **quand la case du dessous est du
vide**. Or il y a deux façons pour une chute de ne pas atterrir — tomber dans le vide, et **buter
contre un bloc de son propre étage** — et dans les deux la roche *visible* a une fin, qu'une
rangée de corps ne sait pas tracer. La condition juste n'est donc pas « du vide en dessous »,
c'est **« aucune robe en dessous »** : un atterrissage a déjà son pied, la substitution y est un
no-op, et ce qu'elle attrape est exactement ce qui s'arrêtait sans bord.

**Ce que ça ferme : les deux dernières extrémités de L2, et rien d'autre. 2 → 0.**

⚠ **Et le défaut n'était pas un trait manquant, c'était un trait TROP LONG.** Regardé au pixel
sur (16,153) : le flanc est de la robe descend à ras du bord (colonne 15) sur toute la hauteur,
tandis que la surface voisine (17,153) trace son bord nord **à sa traversée, quatre pixels plus
bas**. Les deux se rejoignent bien — en diagonale, à la traversée — mais le flanc **dépasse de
quatre pixels au-dessus**, et son bout pend. Une barbe de la longueur exacte de la traversée.

Le pied la supprime des deux côtés à la fois : il donne à la rangée écrêtée un **bord bas**, à ras
du bord de sa case, qui rencontre le flanc au coin ; et il fait taire le nord de la surface d'en
dessous, puisque `NORTH_QUIET` ne demande qu'une chose — *que la robe au-dessus trace vraiment son
bas*. Une frontière, un revendiquant, au bord de la case.

⚠ **LE PRIX EST D'UNE TUILE DE SURFACE, ET ELLE SE NOMME.** 56 → **57**. La nouvelle est la
silhouette **112 (S+SW+W) au nord muet** — le coin d'un plateau sous une face qui s'arrête ; elle
n'existait pas parce qu'aucun pied ne s'était jamais arrêté là. Aucune tuile ne disparaît, et les
20 rôles de robe ne bougent pas. **Zéro tuile de robe** : le pied est déjà au vocabulaire.

⚠ **ET LA SUBSTITUTION SE FAIT AVANT LES BITS DE BORD, JAMAIS APRÈS.** C'est `_foot_above` qui
fait taire le nord de la surface d'en dessous ; calculée après, elle arrive trop tard et la moitié
de la règle ne s'applique pas — la barbe reste. **Sixième fois qu'un ordre de calcul me coûte une
mesure**, et la seule qui se voie est celle où le résultat change.

### LE VIDE, PREMIÈRE MOITIÉ DE LA MÊME RÈGLE

⚠ Le modèle dit *« une robe qui tombe dans le vide ne pose pas son pied — on ne touche pas le
fond d'un gouffre »*, et c'est juste **tant qu'on parle du sous-pied**. Mais la dernière rangée,
elle, s'arrête contre le vide : **sa roche a une fin, et personne ne la traçait.** Vu à l'écran :
le fond de la falaise du bord du monde entièrement nu, la roche butant sur le vide sans un trait.

**On y pose le pied**, qui est exactement la tuile « bas de falaise ». **Coût : zéro tuile.** Ce
qui change est le **sens** du pied — il ne prouve plus un atterrissage, il **ferme une chute**.

**Mesuré : 5 → 3 extrémités.**

⚠ **Et mon premier diagnostic était faux** : j'avais conclu « manque de marge », et donné six
rangées de vide de plus au monde. Aucun effet — la chute n'était pas coupée, elle était
**finie**. La marge reste (elle ne coûte rien et le modèle l'exige), mais ce n'était pas la cause.

### L2 : cinq règles, et il ne reste que cinq pixels

| | au départ | maintenant |
|---|---|---|
| extrémités | 222 | **5** (3 à F0) |
| doublements | 196 | **0** |
| pavés | 7 399 | **0** |
| tuiles | 47 | **75** |

**Cinq décisions, dont une gratuite :**

1. **la règle de la lèvre** — rien au sud d'une surface, la crête porte cette frontière. 780 → 196.
2. **B** — le bord `nu`/`roche` de la surface, à l'est et à l'ouest. +10 tuiles, 196 → 12 doubles.
3. **la règle de la cascade** — les bords d'une face sont les bords de sa case. **Gratuite**,
   222 → 43 extrémités.
4. **D** — l'ergot se tait quand ce qu'il devait rejoindre s'est tu. +10 tuiles, 43 → 13.
5. **le nord sous une face** — le bas du **pied** et le bord nord de l'atterrissage sont la même
   frontière, et c'est le pied qui la porte. +2 tuiles, et **I2 comme I3 passent au vert**.
6. **la traversée au ras sous une voisine silenciée** — quand la case du dessus s'est tue de mon
   côté, c'est le flanc d'une robe qui porte la frontière, une case plus haut et une colonne plus
   loin : mon bord latéral traverse sa frontière nord **au ras** pour aller le toucher au coin.
   +6 tuiles, 14 → 5.
7. **une chute qui s'arrête se ferme, quelle que soit la raison** — le pied ne fermait que le
   vide ; il ferme aussi l'**écrêtage**, qui est le même fait avec du sol derrière au lieu du
   néant. **+1 tuile**, 2 → **0**. C'est celle qui clôt L2.

⚠ **UNE COLLISION DE BITS SILENCIEUSE, TROUVÉE EN CHERCHANT OÙ LOGER LES SUIVANTS.** Le bit du
nord valait 8 — exactement le bit du coin 1 de l'ergot (`4 << coin` couvre 4, 8, 16, 32). Les
deux se marchaient dessus sans que rien ne le dise. Les bits du bord sont désormais rangés
au-dessus de tous ceux de l'ergot.

**Restent 5 extrémités**, et la vérification (`tools/edge_cases.gd`) donne **deux réponses**,
pas une :

⚠ **DEUX SONT DES CAS DE BORDURE, et d'une espèce précise.** Aux **coins bas du monde**, une
falaise tombe dans le **vide** — donc elle ne pose pas son pied, le modèle le dit — et la
planche n'a que **six rangées de marge** là où une chute de trois étages en demande **neuf**.
La falaise est **coupée par le cadre**. C'est un relief qui manque de place, pas une règle qui
manque : le dossier écrit déjà qu'*une robe hors grille est une tuile impeignable* et que la
marge vaut une chute entière. À corriger dans la planche, pas dans le dessin.

⚠ **TROIS NE LE SONT PAS.** Cases (19,152), (16,153), (19,153) — **quinze rangées** au-dessus
de la fin de la matière, treize à seize colonnes du bord. La configuration : un plateau d'étage
**2** avec, juste au nord, des cases d'étage **0 couvertes par une robe** — une falaise qui
passe au ras d'un plateau plus haut. C'est un vrai défaut, et il reste à le nommer.

⚠ **Et « ça sent le bord du monde » n'était pas une mesure.** Les cinq tombaient toutes dans le
tiers bas de la planche, ce qui rendait la conclusion tentante ; trois d'entre elles sont en
plein milieu.

## LA LOI DU MOINDRE RAS

⚠ **ON NE MET AU RAS QUE CE QU'ON NE PEUT PAS LAISSER LIBRE.** Le ras n'est pas une simplicité,
c'est une **liberté confisquée** — et I5 est là pour compter ce qu'on confisque. Chaque fois
qu'une règle demande « au ras », il faut d'abord démontrer qu'aucun **pincement ponctuel** ne
suffirait.

**Et la règle de la cascade était posée trop fort.** Ce que la géométrie oblige, ce n'est pas
que la crête soit au ras **partout** : c'est qu'elle **touche le bord aux deux colonnes où un
bord latéral peut la rejoindre** — les deux traversées canoniques, `d` et `RES-1-d`, qui sont
globales donc connues de toutes les tuiles. **Entre ces deux points, elle reste libre.**

Le théorème sous-jacent, lui, ne bouge pas :

> **Deux lignes perpendiculaires qui vivent dans des tuiles différentes ne peuvent se rejoindre
> qu'à leur frontière commune.**

Donc l'une des deux doit toucher le bord **au point où l'autre le traverse** — et rien de plus.
C'est un pincement en deux points, pas un aplatissement.

⚠ **Ça vaut pour les trois bords d'une face** : la crête, le bas du pied, et les flancs. Chacun
se pince aux traversées de la famille perpendiculaire, et serpente ailleurs.

**Implémenté et mesuré — la liberté est rendue à coût nul :**

| | au ras | au pincement |
|---|---|---|
| profils de face distincts | 1 | **8** |
| profils qui serpentent | 0 | **46** |
| extrémités (F0 / F1 / F2) | 3 / 5 / 5 | **3 / 5 / 5** |
| I2 · I3 | ✅ | **✅** |
| tuiles | 75 | **75** |

⚠ **Pas une extrémité de plus, pas une tuile de plus.** Le ras confisquait donc toute la liberté
du dessin de falaise **pour rien** — et c'est exactement ce que la loi du moindre ras existe
pour attraper. Sans I5 pour compter ce qui est confisqué, la perte serait passée inaperçue :
tous les autres invariants étaient au vert.

## L2, REFAIT DEPUIS LES QUATRE JONCTIONS

À 3/4 depuis le haut il n'existe que **quatre jonctions visibles**. La question n'est pas
« comment rattraper ce défaut-ci » mais **qui trace chacune des quatre, une fois** — et ce que
ça coûte, calculé avant d'être payé.

| | la jonction | qui trace | coût |
|---|---|---|---|
| **J1** | sommet contre sommet, même étage | **personne** — la matière continue | **0** |
| **J2** | sommet contre **face** | *un des deux doit se taire* | **voir ci-dessous** |
| **J3** | face contre face | le **pan**, déjà là | **0** |
| **J4** | sommet **au-dessus de** sa face | la **crête**, et la lèvre se tait au sud | **0** |

**Trois des quatre sont gratuites.** J1 est portée par la silhouette, J3 par le pan qui existe
déjà, J4 par une règle inconditionnelle. **Tout le prix de L2 est dans J2** — et c'est là que la
première tentative a dérapé, en la rattrapant cas par cas au lieu de la trancher une fois.

### J2 : le même bit, et il coûte trois fois moins cher de l'autre côté

Un des deux doit se taire, donc il faut un **bit**. Mais il ne coûte pas le même prix selon la
famille qui le porte, parce qu'il **multiplie** le vocabulaire de cette famille :

| où l'on pose le bit | surfaces | faces | **total** |
|---|---|---|---|
| sur la **surface** (l'actuel) — 3 bits : est, ouest, nord | **228** | 20 | **248** |
| sur la **face** — 3 états de flanc, et le pied à 2 variantes | 27 | **54** | **81** |

⚠ **27 × 8 contre 20 × 2,7. C'est tout le calcul, et il aurait dû être fait le premier jour.**
Chaque bit posé sur la surface double 27 silhouettes ; posé sur la face il ne touche que les
rôles, qui sont moins nombreux et déjà structurés en pans × rangées.

**Implémenté derrière `LADDER_J2=face`, et mesuré :**

| | bit sur la **surface** | bit sur la **face** |
|---|---|---|
| surfaces rencontrées | 55 | **37** |
| rôles rencontrés | 20 | 33 |
| total rencontré | 75 | **70** |
| **forme fermée** | **248** | **81** |
| extrémités | **5** | 34 |
| I2 · I3 | ✅ | ✅ |

⚠ **LA FACE EST TROIS FOIS MOINS CHÈRE EN BORNE, ET ELLE FERME MOINS BIEN.** 34 extrémités
contre 5 — et ce sont exactement celles que j'avais prévues : **quand la face cède, son bord est
pincé aux traversées et celui de la surface est rentré ; ils ne se retrouvent pas.**

C'est donc le prochain travail, et il est borné : fermer ces 34 sans reposer un bit sur la
surface. Si on y arrive, L2 passe de 248 à **81 en forme fermée** — ce qui est le chiffre que le
critère accepte. Si on n'y arrive pas, il faut choisir entre 248 fermé et 81 troué.

⚠ **ET LES 37 NE SONT PAS 27** : les bits de l'ergot et de la voisine silenciée sont encore
posés sur la surface. Ils existaient pour rattraper le silence de la surface — qui n'a plus
lieu. À retirer avant de conclure, ce qui devrait ramener les surfaces à 27 et le total
rencontré à 60.

⚠ **ET IL RESTE UNE CHOSE À VÉRIFIER AVANT DE PAYER LES 81**, honnêtement : quand la face
**cède** le trait à la surface, la face est au ras (règle de la cascade) et le bord de la
surface, lui, est rentré. Ils doivent quand même se retrouver. Si ça demande que la surface
soit au ras de ce côté-là, c'est un bit **sur la surface**, et le compte de 81 s'effondre.
C'est la première mesure du L2 refait — pas la dernière.

### ⚠ LA FORME FERMÉE DE L'ANCIEN L2 ÉTAIT 228, PAS 81

Le critère posé est le bon : *peu importe la quantité si elle est mathématiquement minimale.*
Calculée (`tools/closed_form.gd`), elle ne l'est pas, et de loin.

Chaque bit a une **précondition lisible dans la silhouette seule**, et sa valeur dépend de cases
**hors** de la fenêtre 3×3 — donc, l'extérieur étant libre sur un plan non borné, les deux
valeurs sont réalisables dès que la précondition tient :

```
      2 silhouettes à 0 bit libre   ->   1 tuile chacune
      1 silhouette  à 1 bit         ->   2
     12 silhouettes à 2 bits        ->   4
      2 silhouettes à 3 bits        ->   8
     10 silhouettes à 4 bits        ->  16
                                    -------
                          TOTAL :   228 tuiles de surface  (+ 20 rôles = 248)
```

**55 sur la planche, 61 sur le guide, 228 en borne.** Les deux premiers sont des *rencontres* :
ce que deux reliefs produisent. Un troisième relief en produirait d'autres.

⚠ **DONC LE DESSIN DE L2 N'EST PAS MINIMAL, ET IL N'EN EST PAS PRÈS.** Chacune des six règles a
été adoptée pour fermer un défaut précis, sans jamais demander si le **même** défaut se fermait
avec moins de bits. C'est exactement le cliquet que ce plan existe pour empêcher, et il s'est
reformé sous une autre forme : plus dans le nombre de rôles, mais dans le nombre de **bits par
tuile**.

⚠ **ET LE VRAI COUPABLE EST IDENTIFIABLE : les bits parlent tous du VOISIN.** Le bord, le nord
sous une face, la voisine silenciée, les ergots — six informations sur ce qu'il y a à côté,
c'est-à-dire exactement ce que la décomposition en couches avait supprimé en tombant de 92 à 47.
On l'a remis, morceau par morceau, sans le voir.

**Ce qu'il faut faire avant tout le reste**, et l'ordre compte :

1. **reprendre L2 depuis la question, pas depuis les correctifs.** Il n'y a que quatre jonctions
   visibles à 3/4 (sommet/sommet, sommet/face, face/face, sommet au-dessus de sa face) : la
   question est *qui trace chacune*, une fois, et non *comment rattraper chaque cas* ;
2. n'accepter un bit que s'il **ferme une jonction entière**, jamais un cas particulier ;
3. et recalculer la forme fermée **à chaque bit**, pas à la fin.

### Ce que L2 a coûté en tuiles

Avant, **27 était un théorème** : les 256 fenêtres 3×3, filtrées par l'épaisseur, point. Depuis
que la tuile est *silhouette + bits sur le voisinage*, personne n'a calculé la forme fermée —
et les comptes qu'on manipule sont des **rencontres**, pas des bornes :

```
la planche de preuve :  55 tuiles de surface + 20 rôles = 75
le guide épais       :  61 tuiles de surface + 20 rôles = 81
```

⚠ **LE GUIDE EN EXERCE SIX DE PLUS QUE LA PLANCHE.** Ce n'est donc pas le guide qui est périmé :
c'est **la planche de preuve**, qui existe précisément pour porter *tout* le vocabulaire et ne
le fait plus. Et rien ne dit que 61 soit le maximum — un autre relief pourrait en produire un
62ᵉ.

**Ce qu'il faut faire avant de monter à L3**, et dans cet ordre :

1. **calculer la forme fermée** des nouveaux bits — comme `window_realizable` le fait pour les
   27 — sinon on ne sait plus ce qu'on vend ;
2. **regénérer la planche de preuve** pour qu'elle les porte tous ;
3. **puis seulement** juger le prix : 47 → 81 est peut-être le vrai chiffre, et il est lourd.

⚠ **C'est exactement la faute que la fiche du *sweet spot* décrit** : le vocabulaire est calculé
comme *tout ce que le modèle peut produire*, et personne ne demande *ce qu'on accepte de
construire*. Sauf qu'ici, cette fois, on ne sait même plus ce que le modèle peut produire.

### Ce que L2 a coûté en tuiles

⚠ **47 → 75.** C'est le prix de la première rencontre entre deux familles, et il est lourd. Il
faudra le regarder en face avant de monter à L3 : la fiche du *sweet spot* dit que la grammaire
est une monnaie, et on vient d'en dépenser 28.

### Ce que les 43 étaient vraiment, vu au pixel

| | au départ | maintenant |
|---|---|---|
| extrémités | 222 | **14** (3 à F0) |
| doublements | 196 | **0** |
| pavés | 7 399 | **0** |
| tuiles | 47 | **69** |

**Trois décisions payées, et une gratuite :**

1. **B** — le bord `nu`/`roche` de la surface, à l'est et à l'ouest. +10 tuiles, 196 → 12 doubles.
2. **la règle de la cascade** — les bords d'une face sont les bords de sa case. **Gratuite**, et
   c'est elle qui a fait 222 → 43.
3. **D** — l'ergot se tait quand ce qu'il devait rejoindre s'est tu. +10 tuiles, 43 → 13.
4. **le nord sous une face** — symétrique exact de B : le bas du **pied** et le bord nord de
   l'atterrissage sont la même frontière, et **c'est le pied qui la porte**, parce que son bas
   referme le contour de la falaise et que rien d'autre ne le peut. +2 tuiles, et **I2 et I3
   passent au vert d'un coup**.

⚠ **ET LE SENS DE (4) A ÉTÉ TROUVÉ EN L'ESSAYANT À L'ENVERS.** Faire taire le pied ferme aussi
les doublements — mais ouvre **128 extrémités aux coins bas de chaque robe**. Mettre le bord
nord au ras au lieu de le taire n'en ferme que 5. C'est la troisième fois qu'une paire
« qui des deux se tait » ne se devine pas et se mesure.

**Restent 14 extrémités**, dont **9 d'une seule famille** : le bord latéral d'une surface meurt
à son **nord** quand la case au-dessus est silenciée par B de ce côté-là. C'est la même espèce
que les 30 que D a fermées — une transition dans *qui trace* — mais sur un bord ordinaire, pas
sur un ergot. Elle demandera son propre bit.

### Ce que les 43 étaient vraiment, vu au pixel

Tous au **bord sud d'une case**, à `x = 3` ou `x = 13` — c'est-à-dire au bout d'un **ergot de
coin rentrant**, pas au bout d'un bord. L'ergot part du coin, court le long du bord sud, et son
extrémité libre devait rejoindre le bord latéral de la case d'en dessous. Ce bord-là est
**silencié par B** quand il longe de la roche : l'ergot tombe dans le vide.

C'était donc bien l'option D — mais elle mesurait faux pour **trois** raisons successives, et
chacune donnait un chiffre crédible :

1. **la paire était inversée.** L'ergot posé le long de `a` rejoint la voisine *à travers `a`*,
   sur son côté `b` ; j'interrogeais la voisine d'à travers `b`, donc une autre case et une
   autre arête ;
2. **un garde parasite** d'une édition antérieure supprimait les *deux* ergots au lieu du bon —
   d'où les « 11 fermées » que j'avais annoncées ;
3. **l'ordre de calcul.** Les bits de l'ergot demandent si la voisine trace son bord, ce qui
   dépend du bord qu'on vient de lui poser. Calculés dans la même boucle, ils interrogent une
   case pas encore traitée : la voisine du **sud**, en ordre de lecture, n'a jamais encore le
   sien. Deux passes, et le chiffre devient **43 → 13**.

⚠ **CINQ FOIS LE MÊME PIÈGE M'A COÛTÉ UNE MESURE** : un remplacement dont l'ancrage rate **en
silence**, et je lis un chiffre qui ne mesure pas ce que je crois. Le bit posé sur la carte
visible mais pas sur la silhouette ; le bloc D jamais inséré ; puis un garde parasite laissé par
une édition antérieure, qui supprimait les *deux* ergots au lieu du bon — et faisait croire que
D fermait onze extrémités. Un `assert` à chaque ancrage coûte une ligne.

### LA DISTRIBUTION DES 222 — et elle vaut mieux que quatre hypothèses

```
  87  surface, bord sud, en face : robe
  30  surface, bord sud, en face : surface
  25  robe, bord nord, en face : robe
  23  robe, bord ouest, en face : robe
  21  robe, bord est, en face : robe
  20  robe, bord sud, en face : robe
   9  surface, bord nord, en face : surface
   6  le reste
```

⚠ **DEUX FAMILLES, ET ELLES PÈSENT PRESQUE AUTANT L'UNE QUE L'AUTRE** : **117** sur le bord
d'une surface (87 + 30), **89** sur un bord de robe face à une autre robe. Toutes ont la même
forme — *un trait meurt là où la case suivante ne trace pas de son côté*.

⚠ **ET LES 30 CONDAMNENT LA RÈGLE DE LA LÈVRE TELLE QU'ELLE EST ÉCRITE.** « Une case dont le sud
est vide est une lèvre, sa falaise commence juste dessous » — mais dans 30 cas la case d'en
dessous porte une **surface**, pas une robe. Le théorème a une exception que je n'ai pas
cherchée, et le bord sud n'y est alors tracé par personne.

⚠ **C refaite sur la bonne condition : 20 → 28 rôles, et 222 → 222.** Le bit se déclenche
enfin, l'ergot se pose — et le compte ne bouge **pas d'une unité** : 20 extrémités fermées au
bord sud d'une robe, 20 rouvertes à son bord nord. **L'ergot déplace le bout, il ne le ferme
pas** : son extrémité de coin pend à son tour, parce que la frontière continue chez la voisine
dont le flanc dit lui aussi `continue`. C'est une **cascade**, pas un cas local — et un ergot de
longueur fixe ne peut pas la suivre.

### Les hypothèses mesurées, toutes insuffisantes

| hypothèse | ce qu'elle ferme | ce qu'elle coûte |
|---|---|---|
| **pincer le bord latéral au sud** | rien — **222 → 848**, +61 pavés | 0 tuile |
| **C** — un bit sur la robe : « la case au-dessus trace de ce côté » | **rien**, le bit ne se déclenche qu'**une fois** | +1 tuile |
| **D** — l'ergot se tait quand ce qu'il devait rejoindre s'est tu | **43 → 13** | **+10 tuiles** (57 → 67) |
| **C** refaite — l'ergot se pose quand la case du dessus trace | **rien** — 222 → 222 | +8 tuiles |
| **le nord d'une surface au ras** | **43 → 65**, +94 pavés | 0 tuile |

⚠ **ET C'EST D QUI DIT LA CAUSE, EN ÉCHOUANT.** Les ergots qui pendent ne font que **onze** des
222. Le reste est ailleurs. Trois hypothèses raisonnées, trois fois faux : il faut **regarder**
un échantillon large d'extrémités, pas en deviner une de plus.

⚠ **Et deux fautes de méthode à moi, dans le même mouvement.** Le bit de D interrogeait d'abord
la case **diagonale**, alors que l'ergot traverse une frontière et va rejoindre le bord de la
case **d'à côté**. Puis le remplacement du bloc a échoué **en silence**, faute d'un ancrage
juste — et j'ai lu « aucun effet » pendant que le code n'était pas là. Un `assert` à l'ancrage
aurait coûté une ligne.

⚠ **Ce cas n'arrive que quand le flanc du chapiteau dit `continue`.** S'il dit `arrêt`, il trace
son propre bord à `dW` et le bord de la lèvre le retrouve exactement. Il faudrait donc que le
chapiteau sache que **la lèvre au-dessus a son côté ouvert** — une information qu'un rôle de
robe (deux flancs, une rangée) ne porte pas. C'est le prochain bit à chiffrer, et il est de la
même famille que le bord.

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

Un banc `proof/ladder.gd` qui prend **(L, F)** et rend les six invariants. Il commence avec
L0/F0 seulement, et il grandit avec le plan. Tant qu'il ne sait mesurer qu'un couple, il
mesure déjà mieux que tout ce qu'on a : il dit **où** est le défaut, pas seulement qu'il y en
a un.

⚠ **Et il ne redérive jamais le calcul qu'il contrôle.** C'est la faute la plus chère du
projet : `_check_wall_seams` recalculait ses enchaînements avec la formule même qu'il
vérifiait — donc la même erreur, donc rien de vérifié, et la suite était verte pendant que le
dessin cassait aux deux tiers de ses jonctions. Le banc **rend l'image et regarde les
pixels**.
