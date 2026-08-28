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

| **L5/F0** | **✅ acquis** | sur la **planche duale**, 15/15 formes, les six verts — **64 tuiles à cheval + 20 rôles** |
| L5/F1 | **43 extrémités**, dont 42 noyées | I2 ✅ · I3 ✅ · I4 ✅ · I5 ✅ · I6 ✅ |
| L5/F2 | **91 extrémités**, dont 90 noyées | I2 ✅ · I3 ✅ · I4 ✅ · I5 ✅ (28 profils qui serpentent) · I6 35 perdues |
| **L4** | **✅ acquis, à tous les niveaux** | les raccords se recensent depuis le monde **et contraignent le dessin** — 51 bords → **36 classes** à L2/L3, les six verts, et I5 passe de **7 à 22 profils distincts** |
| **L3/F2@guide** | **✅ acquis** | **un second monde**, 104×141 — 64 + 20 = **84 tuiles**, 55 bords → 35 classes, les six verts |
| **L2/F2@battue1·2·3** | **✅ acquis** | **L2 est CLOS : les six invariants verts sur les CINQ mondes** |
| **L3/F2@battue1·2·3** | **✅ acquis** | **L3 est CLOS : les six invariants verts sur les CINQ mondes** — partis de 14 · 10 · 4 extrémités |

⚠ **L'ÉCHELLE EST DONC VERTE SUR TREIZE COUPLES** — les douze de la planche à **78 tuiles**
(58 surfaces + 20 rôles), et le plus exigeant rejoué sur le **guide** à 84.

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
porte d'autres, et un relief tiré au sort en porterait d'autres encore.

### ⚠ LA BATTUE MORD : DEUX MONDES BÂTIS À LA MAIN NE SUFFISENT PAS NON PLUS

Le guide avait montré que la planche ne suffit pas. Trois mondes **tirés au sort** montrent que
les deux ensemble ne suffisent pas davantage.

⚠ **ET ILS SONT TIRÉS PAR LE GESTE DU PINCEAU, PAS PAR DES BLOCS AU HASARD.** SoluPaint pose des
tampons 3×3, efface en 3×3, et **refuse tout geste qui laisserait une case fine**. Une battue qui
tire des rectangles cherche donc ailleurs que là où l'acheteur dessine — elle fabrique des
rencontres que personne ne produira jamais, et en manque d'autres. C'est la règle de
`tools/brush_census.gd`, reprise dans le banc. Ce que la battue trouve est donc **peignable**,
donc réel.

| monde | silhouettes exercées | tuiles | I1 | I2 |
|---|---|---|---|---|
| `@battue1` | 16 / 27 | 59 | **14 extrémités** | **4 pavés** |
| `@battue2` | 15 / 27 | 61 | **10 extrémités** | ✅ |
| `@battue3` | 15 / 27 | 53 | **4 extrémités** | **4 pavés** |

**I3, I4, I5 et I6 sont verts sur les trois.** Ce qui casse est donc exclusivement la
**fermeture** et l'**épaisseur** — c'est-à-dire les coins, encore et toujours : *qui trace là où
la frontière tourne ?*

⚠ **ET ELLES N'EXERCENT MÊME PAS TOUT LE VOCABULAIRE** — 15 ou 16 silhouettes sur 27 — et elles
cassent quand même. Un monde plus riche en casserait davantage, pas moins.

⚠ **LA GRAINE EST FIXE, ET C'EST VOULU.** *« Deux exécutions doivent donner la même image, sans
quoi le banc ne dit plus si un correctif a servi »* — déjà écrit au dossier pour le tracé. Un
monde tiré à neuf à chaque exécution trouverait plus de défauts et ne dirait jamais si on en a
corrigé un.

⚠ **CE QUE ÇA CHANGE AU MOT « ACQUIS ».** L2 et L3 sont verts **sur les deux mondes bâtis à la
main** — ils le restent, et le rejeu les tient. Mais ils ne sont **pas clos** : le niveau n'est
fini que quand la battue passe. C'est la même leçon qu'hier, d'un cran plus loin, et il vaut
mieux l'écrire que la découvrir chez un acheteur.

**Le prochain travail est là**, et la distribution dit par où commencer — sur `@battue1` :
10 extrémités au **bord nord** d'une surface, 2 à l'**ouest**, 2 à l'**est**, et les 4 pavés sur
une **robe qui n'a rien en dessous**.

### L5 : LE CONTOUR À CHEVAL SE FERME TOUT SEUL, ET C'EST UN THÉORÈME

**Le témoin est rouge, donc le défaut est dans le modèle** — c'est exactement ce que F0 existe pour
dire. Mais il est vert là où on l'attendait le plus rouge.

⚠ **I1 EST VERT DU PREMIER COUP : ZÉRO EXTRÉMITÉ.** Et ça se démontre avant de le mesurer. Le
quadrant **SE** de la tuile d'un croisement et le quadrant **SO** de sa voisine de l'est désignent
**la même case** : la matière traverse le bord de tuile sans qu'il y ait de frontière. **Le contour
d'une tuile à cheval est donc entièrement INTERNE** — toute frontière qu'elle porte est chez elle,
entre deux de ses propres quadrants. Elle n'a rien à savoir de son voisinage, et *la question « qui
trace ? » ne se pose pas.* C'est ça, les quinze tuiles sans un seul bit de bord.

Et une frontière du monde, qui court sur une case entière, est **partagée entre deux tuiles**,
chacune en traçant sa moitié ; elles se rejoignent à leur bord commun, où toutes deux tracent au
même endroit — l'axe de leur quadrant.

⚠ **CE QUI CASSE EST LA RENCONTRE DES DEUX GRILLES, ET RIEN D'AUTRE.** Les surfaces sont décalées
d'un demi-pas ; les **robes restent sur la case**. Toutes les jonctions surface/falaise sont donc à
cheval, et le témoin les compte : **7 446 pavés et 744 doublements, tous à la falaise.**

**Premier correctif, gratuit : « rien au sud » vaut aussi à cheval.** Une frontière horizontale
interne dont le **haut est plein et le bas vide** est une **lèvre** — la face commence juste
dessous, et c'est son chapiteau qui la porte. Même théorème que dans la famille par case, même
gratuité : **7 446 → 1 573 pavés, 744 → 160 doublements.**

### LES DEUX ISSUES DE LA JONCTION LATÉRALE, CHIFFRÉES

La frontière verticale interne d'une tuile à cheval tombe **exactement sur le bord de case** —
c'est son axe — donc au même endroit que le flanc d'une robe. Deux façons d'en sortir, mesurées :

| issue | tuiles à cheval | I1 | I2 pavés | I3 doubles |
|---|---|---|---|---|
| aucune (le témoin) | 13 | ✅ 0 | 1 573 | 160 |
| **A · la face cède ses flancs** | 13 | **❌ 134 extrémités** | 141 | 9 |
| **B · la tuile à cheval paie des bits** | **62** | ✅ **0** | ✅ **0** | ✅ **0** |

⚠ **L'ISSUE A EST RÉFUTÉE, ET C'EST LA MÊME LEÇON QU'À L2.** Retirer le flanc d'une robe ouvre
**134 extrémités** : *le flanc est ce qui referme le contour de la falaise*, exactement comme
« le bas du pied » l'avait déjà montré — *12 doublements de moins, mais 128 extrémités de plus*.
Le bénéfice espéré était gros — le pan ne servant plus à rien, les vingt rôles seraient tombés
aux cinq rangées — et il ne se réalise pas.

⚠ **L'ISSUE B FERME TOUT, ET ELLE COÛTE QUATRE BITS.** Deux pour la frontière **verticale** — une
par moitié, nord et sud, levée quand cette moitié-là borde de la roche — et deux pour la
frontière **horizontale**, levées sous un **pied**, visible **ou reposé**. Chacun est l'analogue
exact d'un bit déjà payé dans la famille par case (« contre de la roche » et `NORTH_QUIET`) ; ce
que la famille à cheval ajoute est qu'ils se posent **par demi-frontière**, parce qu'une tuile en
porte deux moitiés indépendantes.

⚠ **ET LE PIED REPOSÉ COMPTE AUTANT QUE LE PIED VISIBLE** — il trace son bord bas au même
endroit. Ne pas le voir laissait **47 pavés, tous « robe, pied reposé »**.

**Le prix, dit franchement : 13 tuiles exercées deviennent 62.** Le théorème des quinze tuiles
sans bit **ne survit pas à la rencontre avec les falaises** : il ne vaut que pour la famille à
cheval seule, sur un monde sans face. C'est un résultat, pas une déception — il était annoncé
comme le nœud du niveau, et il est maintenant chiffré au lieu d'être craint.

### I5 ET I6 SAVENT LIRE LA FAMILLE À CHEVAL, ET ILS ONT CHACUN APPRIS UNE CHOSE

**I6 ne demande plus « quelle tuile couvre cette case ».** La question n'a plus de réponse quand
les surfaces sont décalées d'un demi-pas : une case est couverte par **quatre** tuiles à cheval.
Il lit désormais une **assemblée des surfaces seules** — sans robes ni poses arrière — qui répond
pour toutes les familles sans rien redemander au modèle. ⚠ À F0 sa fenêtre vaut **0 pixel** : les
surfaces sont pleines, il n'y a rien à voir. Le vert est donc vrai et ne prouve rien, et la ligne
le dit.

**I5 profile la frontière INTERNE, et il suit la matière, pas le trait.** Chercher le trait trouve
celui de l'autre orientation quand la sienne n'existe pas — et une frontière qu'un bit vient de
faire taire n'a **pas de trait du tout**, alors que sa matière est toujours là. Ce qui a une
position chez une tuile à cheval, c'est l'**axe** entre deux quadrants.

⚠ **ET IL A REFUSÉ UN DESSIN FIGÉ, CE POUR QUOI IL EXISTE.** À F1, avant que la liberté ne soit
écrite, les quatre autres invariants étaient verts et I5 seul disait *« tu promets plusieurs
profils, tu en livres un »*.

⚠ **À CHEVAL, LA LIBERTÉ LATÉRALE EST GLOBALE, PAS PAR TUILE — ET C'EST UN THÉORÈME DE LA
FAMILLE.** Deux tuiles voisines se partagent les deux moitiés d'une même frontière et se
rejoignent à leur bord commun ; un axe plat **déplacé** ne se rejoint que si **toutes** les tuiles
le déplacent pareil. La promesse juste de F1 est donc *« un profil plat, mais déplacé »*, là où la
famille par case en promet plusieurs.

⚠ **ET LA LIBERTÉ SE PAIE CONTRE LES FALAISES : 55 extrémités à F1, 122 à F2**, dont **54 et 121
noyées dans la matière**. La raison est nette : les quatre bits de l'issue B ont été calculés pour
un axe **posé sur le bord de case** ; dès qu'il s'en écarte, la frontière de la tuile à cheval et
le flanc de la robe ne sont plus au même endroit, et le trait meurt dans la roche. **C'est le
travail qui reste à L5.**

### ⚠ LE BANC BÂTISSAIT LA MAUVAISE PLANCHE — ET LE DÉPÔT AVAIT DÉJÀ LA BONNE

13 formes à cheval sur 15, et les deux manquantes étaient **exactement les contacts diagonaux** —
ceux que la canonicalisation du blob **jette**. Ce n'était pas un guide à construire : le dépôt
porte **une planche de preuve par famille**, *« les deux planches sortent de la même fonction »*,
et le banc appelait `ProofScene.relief(BY_CELL)` même à L5.

Sur la planche **duale** : **15/15 formes, les six invariants verts, 64 tuiles à cheval.**
**L5/F0 est acquis**, et il entre au rejeu.

⚠ **UN MONDE BÂTI POUR UN VOCABULAIRE N'EXERCE PAS L'AUTRE**, et c'est écrit au dossier depuis
longtemps — *« un guide complet en blob 47 n'est PAS automatiquement complet en dual, et ne peut
pas l'être »*. Je l'ai redécouvert par la mesure au lieu de le lire.

### CE QUI RESTE À L5 : LA LIBERTÉ CONTRE LES FALAISES

À F1 et F2, tout est vert **sauf I1** : 43 et 91 extrémités, dont **42 et 90 noyées dans la
matière**. La cause est nette : les quatre bits sont calculés pour un axe **posé sur le bord de
case** ; dès que la liberté l'en écarte, la frontière que la robe porte n'est plus celle de la
tuile, et le trait meurt dans la roche.

**QUATRE FAÇONS D'ACCORDER L'AXE AU FLANC, TOUTES MESURÉES, AUCUNE PAYÉE :**

| tentative | I1 à F1 | I1 à F2 | tuiles à cheval |
|---|---|---|---|
| **l'axe reste libre** (l'état gardé) | **43** | 91 | **64** |
| geler l'axe là où la robe trace | 40 | — | 64, mais **I5 ❌** |
| suivre −`_wall_depth`, sans le côté | **123** | — | 64 |
| suivre +`_wall_depth`, sans le côté | **77** | — | 64 |
| **bit dédoublé par côté, et suivre** | **40** | **40** | **105** |

### ET LE RELEVÉ MENTAIT : IL RANGEAIT LES PIXELS PAR CASE

Trois lectures au pixel perdues avant de s'en apercevoir. À cheval, les tuiles sont décalées d'un
demi-pas : `x / RES` désigne **la case**, donc une **autre tuile** que celle qui porte le pixel —
et le relevé accusait une innocente. ⚠ **Mais les robes, elles, restent par case** : les chercher
au croisement les rend toutes invisibles et fait annoncer « surface » partout. Le relevé range
donc désormais **la position par croisement et les robes par case**.

**Et le défaut se nomme alors d'une ligne : les 43 sont le même.** Une tuile à cheval dont le seul
quadrant **nord-ouest** est plein, dont la moitié sud est déjà silencieuse, et dont le trait
vertical **s'arrête là où « rien au sud » commence**. À F0 son bout rencontre la **crête du
chapiteau**, qui est sur la grille des cases ; dès que la liberté déplace l'axe de deux pixels,
il ne la rencontre plus.

⚠ **C'EST DONC ENCORE LA MÊME CAUSE, MAIS PAR LA CRÊTE ET NON PAR LE FLANC** — et elle échappe au
bit, parce que « rien au sud » est **inconditionnel** : le figer là où il s'applique reviendrait à
figer l'axe presque partout, c'est-à-dire à rendre la liberté. L'autre issue est que **la crête
suive l'axe** : les deux sont des lois globales, une robe peut donc la connaître.

**LU AU PIXEL, LE TROU FAIT UN PIXEL DE LARGE.** Le trait vertical est à `x=97` — l'axe déplacé
de deux — et la crête, qui est sur la grille des cases, s'arrête à `x=95`. Entre les deux, `x=96`
est vide.

⚠ **ET RECONNECTER L'AXE AU BORD DE CASE : DEUX ESSAIS, DEUX FOIS PIRE.**

| le petit bout horizontal posé… | I1 à F1 |
|---|---|
| à **chaque** rangée où la matière s'arrête | **12 500**, en 5 926 morceaux |
| à la **seule** rangée où le trait vertical finit | **354** |
| (rien — l'état gardé) | **43** |

*Un remède juste appliqué trop largement fabrique mille fois le défaut qu'il répare* — c'est la
même leçon que le bit de bord posé « en gros » le matin même, qui coûtait +5 tuiles là où il en
coûte zéro au bon endroit.

⚠ **ET LE SECOND ÉCHOUE POUR UNE RAISON PRÉCISE, QUI EST LA CLÉ DU RESTE : la rangée où la
MATIÈRE s'arrête est déjà SOUS LA ROBE, donc invisible** — la robe se pose par-dessus. Le dernier
pixel **visible** du trait vertical est une rangée plus haut, au bord de case. **Le raccord doit
se poser là, et pas où la tuile croit finir.** C'est la prochaine mesure, et elle est d'un pixel.

⚠ **LE DÉDOUBLEMENT EST LE SEUL QUI MORDE VRAIMENT — ET IL NE FERME PAS.** Il divise F2 par plus
de deux (91 → 40) et confirme la géométrie : robe à l'**ouest**, l'axe recule de son flanc est ;
robe à l'**est**, il avance de son flanc ouest. Mais **quarante extrémités restent, et ce sont les
mêmes à F1 et à F2** — une autre cause est devenue dominante, et elle ne dépend plus de la
liberté. **Payer 41 tuiles pour une fermeture partielle contredit les deux premières priorités du
plan** : on garde la mesure, on ne paie pas, et on cherche la cause qui reste.

⚠ **LA GELÉE REND TROIS PIXELS ET COÛTE LA LIBERTÉ ANNONCÉE.** Un axe figé d'un côté et libre de
l'autre fait une **marche** au milieu du profil : plusieurs profils, dont onze qui ondulent là où
F1 les promet plats. On ne paie pas trois pixels avec ça.

⚠ **ET LES DEUX SUIVIS ÉCHOUENT POUR LA MÊME RAISON : LE SIGNE DÉPEND DU CÔTÉ OÙ SE TROUVE LA
ROBE, et le bit ne le dit pas** — il se lève quand **l'une ou l'autre** des deux cases est
couverte. Le dédoubler par côté coûte des tuiles ; **c'est la prochaine mesure, et elle se
chiffre avant d'être payée.** Les trois essais restent en commentaire, avec leurs chiffres.

⚠ **Et la planche de preuve n'exerce que 13 des 15 tuiles à cheval** : elle a été bâtie pour la
famille par case. Un guide dual reste à construire.

### L3 EST CLOS : LA POSE ARRIÈRE NE DÉBORDE PAS AU NORD DE SA LÈVRE

Le dernier pixel est fermé, et **ce n'était pas la muteté**. Cinq conceptions de pose arrière ont
été mesurées avec le code du jour, sur les cinq mondes :

| conception | planche | guide | b1 | b2 | b3 | pavés | I6 |
|---|---|---|---|---|---|---|---|
| **`mute`** — la matière sans le contour | 0 | 0 | **1** | 0 | 0 | 0 partout | ✅ |
| `full` — la roche pleine | 0 | 0 | **1** | 0 | 0 | 0 partout | ❌ jusqu'à 1 500 inventés |
| `trace` — elle dessine son contour | 1 | 3 | 7 | 5 | 7 | 0/7/7/3/0 | ❌ 6 perdues |
| `flanc` — ses flancs seulement | 90 | 63 | 18 | 18 | 18 | — | ❌ |
| `bout` — sa crête et son pied seulement | 489 | 356 | 98 | — | — | — | ❌ |

⚠ **`full` LAISSE EXACTEMENT LA MÊME EXTRÉMITÉ QUE `mute`**, et ça disqualifie l'hypothèse d'un
coup : le pixel ne vient pas de ce que la pose *ne trace pas*. Et toute conception qui n'en trace
qu'une part est catastrophique — un trait partiel pend par ses deux bouts.

⚠ **ET IL FALLAIT MESURER SI C'ÉTAIT UN TROU OU UNE OCCULTATION.** I1 dit désormais, pour chaque
extrémité, si elle est **au bord du vide** ou **noyée dans la matière** — un trait qui s'arrête
contre de la roche est occulté, la terrasse passe derrière la falaise. Mesuré : celle de `mute`
est **au bord du vide**, donc un vrai trou. Celles de `trace`, à l'inverse, sont **toutes
noyées**. Sans ce compteur j'aurais tranché à l'envers.

**La cause, une fois le pixel regardé : le chapiteau reposé remplit la case ENTIÈRE de sa lèvre**,
y compris derrière son encoche **nord**. Or la face d'une lèvre est **au sud** — c'est le
théorème. Derrière l'encoche nord il n'y a pas de roche : il y a ce que le monde a là, le sol plus
au nord ou le vide. La roche y sortait donc avec un bord que **personne ne trace**, et le trait de
la terrasse voisine venait mourir dessus.

**La pose arrière est donc recadrée sous la matière de la case qui la couvre, au nord seulement.**
⚠ **C'est une POSE, pas une tuile** : zéro dessin de plus — on ne fait que ne pas poser ce que le
modèle ne met pas là.

⚠ **ET I6 A DÛ SUIVRE, CE QUI EST LE POINT DÉLICAT DE LA JOURNÉE.** Il exigeait la matière du rôle
nommé sur **toute** la transparence du couvercle, encoche nord comprise — donc il comptait le
recadrage comme 3 806 matières *perdues*. Sa fenêtre exclut désormais l'encoche nord, pour la
raison qui vient d'être dite. **Affaiblir un invariant pour accepter un correctif est le geste le
plus dangereux du dossier**, alors il a été vérifié dans les deux sens :
- il **voit encore** — 2 442 pixels de fenêtre sur la planche, contre 7 610 (−68 %) ;
- il **attrape encore `full`** — 138 matières inventées sur la planche, 108 sur le guide.
⚠ Mais il ne l'attrape plus sur les battues, où la fenêtre tombe à 513 pixels. **La mesure est
plus étroite qu'hier, et il faut le dire.**

### L2 EST CLOS, ET LA DERNIÈRE EXTRÉMITÉ DE L3 ÉTAIT LE PRIX DE `mute` — CORRIGÉ CI-DESSUS

**L2/F2 est vert sur les cinq mondes, sur les six invariants** — planche, guide et les trois
battues. Le niveau est clos, et le rejeu le tient : les trois battues entrent à l'acquis à L2, et
deux des trois à L3.

⚠ **ET LA DERNIÈRE EXTRÉMITÉ DE L3 EST MESURÉE, PAS SUPPOSÉE.** Sur `@battue1` :

| conception | I1 | I2 |
|---|---|---|
| **L2** — aucune pose arrière | **0 extrémité** | 0 |
| L3 · `mute` — la matière sans le contour | **1** | 0 |
| L3 · `trace` — la pose dessine son contour | **7** | **7 pavés** |

Le même monde sans poses arrière ferme parfaitement. Le pixel vient donc **entièrement de la pose
arrière**, et pas d'une règle de surface ou de falaise.

**Ce qui se passe, lu au pixel** : le bord nord d'une terrasse meurt contre la **roche d'un
chapiteau reposé**, vu à travers l'encoche latérale de la lèvre qui le couvre. La roche est bien
là — I4 est vert, il n'y a pas de trou — mais elle est **muette par décision**, donc le trait qui
arrive n'a rien à rejoindre et s'arrête.

⚠ **C'EST LE PRIX DE `mute`, ET IL EST ENFIN CHIFFRÉ.** I6 avait tranché contre `full`, qui
inventait 1 506 pixels de roche ; `trace` reste refusée, qui double le trait. `mute` était la
seule verte sur les six — elle l'est encore, et elle coûte **une extrémité sur trois battues**.
Le choix ne change pas : un pixel de contour ouvert se paie moins cher que de la matière
inventée. Mais il n'est plus gratuit, et le dossier ne doit pas laisser croire qu'il l'était.

⚠ **ET LA COMPLÉTUDE DU VOCABULAIRE EST UNE EXIGENCE DE SPÉCIMEN, PAS DE MONDE.** La planche et
le guide sont bâtis **pour** porter les 27 silhouettes, et un manque y est un défaut ; une battue
n'a pas à les porter — elle éprouve les **rencontres**. Le compte reste imprimé (*une battue qui
ne rencontre pas le vocabulaire ne prouve pas qu'il est sain, elle prouve qu'elle n'a rien
regardé*), il ne juge plus.

### LE RECENSEMENT DES JONCTIONS : L'ESPACE EST FINI, ET IL EST PETIT

Le vocabulaire ne grossit pas à cause du **trait** — il grossit d'un bit à chaque **jonction** que
le modèle sait produire et qu'une tuile ne sait pas reconnaître. La question juste n'était donc
pas « faut-il un contour » mais **« combien de jonctions distinctes le monde peut-il produire ? »**

**L'alphabet, lu du monde et non supposé** — pour un côté donné, ce qu'il peut avoir en face :

```
vide                                                          1
sol   { meme etage, plus bas, plus haut }  x  { , + pose }     6
face  { chapiteau, corps, pied }           x  { , + pose }     6
                                                             ---
                                                              13  par cote,  52 en tout
```

| monde | espèces observées | adjacences | couples (silhouette, côté) | **en voient plusieurs** | le pire |
|---|---|---|---|---|---|
| planche | **47** | 52 800 | 108 | **48** | 10 |
| guide | **48** | 52 496 | 108 | **48** | 10 |
| `@battue1·2·3` | 40 · 42 · 42 | ~2 000 | 64 · 60 · 60 | 49 · 54 · 51 | 8 · 7 · 8 |

⚠ **L'ESPACE DES JONCTIONS EST DONC FINI, PETIT, ET DÉJÀ PRESQUE ÉPUISÉ : 48 observées sur un
plafond de 52.** Le vocabulaire, lui, est à **≥ 116 et croît**. La croissance ne vient donc **pas**
d'un espace de rencontres illimité — elle vient des **combinaisons** : une tuile a quatre côtés,
et un vocabulaire qui distinguerait tout ferait 27 × 13⁴.

⚠ **ET LE NOMBRE QUI COMPTE EST L'AUTRE : 48 COUPLES (SILHOUETTE, CÔTÉ) SUR 108 VOIENT PLUSIEURS
ESPÈCES**, et le pire en voit **dix**. Ce sont exactement ceux qui réclament un bit ou une règle —
*un côté qui ne voit jamais qu'une seule chose n'a rien à savoir.* Les bits payés aujourd'hui
(nu/roche, `NORTH_QUIET`, `ABOVE`/`BELOW_QUIET`, `NORTH_FLUSH`) sont des **regroupements** de ces
treize espèces en deux ou trois classes. **La forme fermée du vocabulaire est donc calculable** :
c'est le produit, sur les quatre côtés, du nombre de classes que chacun doit distinguer — et ce
nombre-là se mesure, espèce par espèce, au lieu de se découvrir un bit à la fois.

⚠ **ET LA MESURE CONFIRME UN THÉORÈME AU PASSAGE, SANS QU'ON LE LUI DEMANDE : « sud : sol, plus
bas » N'EXISTE PAS.** Zéro occurrence sur 52 800. C'est la règle de la lèvre — *une case dont le
sud est vide a toujours sa propre face en face* — non plus supposée, mais **comptée**.

⚠ **Et la clause de grammaire qui mordrait vraiment n'est pas sur la FORME du relief, mais sur les
RENCONTRES.** Les trois clauses mesurées portaient toutes sur la forme, et elles ont rendu cinq
tuiles. Interdire une **espèce de jonction** retirerait, elle, une distinction à un côté — donc un
facteur, pas un terme.

### ⚠ LE GUIDE PROUVE LES SILHOUETTES, PAS LES TUILES — MESURÉ

Question posée en cours de route : *le guide affiche-t-il tous les cas types ?* La réponse dépend
de **quel vocabulaire** on parle, et les deux réponses sont vraies en même temps.

**Pour ce qui est livré aujourd'hui — oui, et c'est asserté.** Le produit est à 27 silhouettes +
20 rôles + 15 croisements, et `tests/run.gd` (`_test_mode_guides_are_complete`) refuse un mode
dont le guide ne les porte pas toutes. *Entrer un mode au catalogue, c'est s'engager à ce que son
guide passe là.*

**Pour ce que le banc est en train de bâtir — non.** Depuis que le bord entre dans l'identité
d'une tuile, une tuile est un couple (silhouette, bord), et le compte se mesure par monde :

| monde | tuiles de surface exercées | lui manque, sur l'union |
|---|---|---|
| **guide** | **65** | **12** |
| planche de preuve | 59 | 18 |
| `@battue2` | 49 | 28 |
| `@battue1` | 46 | 31 |
| `@battue3` | 42 | 35 |
| **union des cinq** | **77** | — |

⚠ **LES 27 SILHOUETTES, ELLES, SONT DANS TOUS LES MONDES** — c'est bien un théorème, et il tient.
Ce qui manque n'est jamais une silhouette, c'est un **bord** : la même forme vue dans un voisinage
que ce monde-là ne produit pas.

⚠ **ET 8 TUILES SONT DANS LE GUIDE SANS ÊTRE DANS LA PLANCHE, 2 L'INVERSE, ET 10 NE SONT QUE DANS
LES BATTUES.** Aucun des deux mondes bâtis à la main ne contient l'autre. **Une tuile absente du
guide est une tuile que l'acheteur ne peut pas peindre** — c'est exactement le mode de panne déjà
écrit au dossier, celui qui ne se signale pas.

⚠ **ET 77 N'EST PAS UN COMPTE, C'EST UNE UNION DE CINQ MONDES.** La forme fermée du vocabulaire
étendu n'est pas calculée ; tant qu'elle ne l'est pas, on ne peut pas dire ce qui manque au guide,
seulement qu'il manque **au moins douze**. C'est le travail qui vient après la fermeture :
*calculer la forme, puis bâtir le guide depuis elle* — comme les îlots de preuve, qui se
cherchent et se jugent au lieu de se dessiner.

### LA CLAUSE DES TROIS COLONNES EST CHIFFRÉE, ET LE PARI DE LA FICHE EST REPROCHÉ

`CLAUDE.md`, fiche « LE SWEET SPOT », posait trois clauses de grammaire candidates et un pari :
*« (1) et (2) ensemble ramènent autour de 60-65 tuiles »*. Voici (1), mesurée.

**La clause** : aucune paroi plus étroite que trois colonnes. Une paroi est un *segment de face* —
une suite de cases de robe, sur une même rangée, jointes par des flancs qui **continuent**. Elle
est donnée au **pinceau** comme un refus de plus : un geste qui laisserait une paroi fine ne se
pose pas, exactement comme un geste qui laisserait une case fine.

| | sans clause | **sous clause** |
|---|---|---|
| gestes refusés sur 400 | ~93 | **102** |
| parois étroites au monde fini | 1 · 0 · 9 | **0 · 0 · 0** |
| **rôles de robe** | **20** | **15  (−25 %)** |
| tuiles de surface, à 60 mondes | 86 | **89 — aucune réduction** |
| tuiles de surface, à 160 mondes | **96**, et ça monte encore | — |
| silhouettes rencontrées | 26 / 27 | 24 / 27 |

⚠ **CE QU'ELLE SUPPRIME EST EXACTEMENT UN PAN, ET C'EST UN THÉORÈME.** Une paroi de trois colonnes
ou plus a un **bout ouest** (arrêt|continue), un **milieu** (continue|continue) et un **bout est**
(continue|arrêt) ; une paroi d'une seule colonne **est** le pan (arrêt|arrêt). Interdire les
segments de moins de trois supprime donc ce pan-là et lui seul — avec ses cinq rangées. Vérifié
par la battue : les quinze rôles survivants sont exactement les trois autres pans × cinq rangées.

⚠ **ET ELLE NE TOUCHE PAS AUX SURFACES.** À nombre de mondes égal, la battue sous clause en trouve
**plus** (89 contre 86) — elle explore autrement, pas moins. Le gain est donc **5 tuiles sur ~116**
(96 + 20), soit **4 %**. Le pari annonçait 60-65 pour les deux clauses ensemble ; la première en
rend cinq. **Il est reproché, et c'était sa raison d'être.**

⚠ **ET SON PRIX N'EST PAS OÙ LA FICHE L'ANNONÇAIT.** Ce n'est pas la liberté du geste — la clause
ne refuse presque rien de plus que l'épaisseur du relief, déjà en place. C'est que **nos deux
mondes livrés la violent** : la planche de preuve porte **18** parois de moins de trois colonnes,
le guide **21**. L'adopter, c'est les rebâtir tous les deux — et pour la planche c'est structurel,
ses îlots de spécimens sont petits par construction.

**Verdict : cinq tuiles pour deux mondes à refaire.** À garder en réserve, pas à payer seule ; elle
ne vaut le coup que si (2) ou (3) rapportent gros et qu'on rebâtit de toute façon.

### LES TROIS CLAUSES, CÔTE À CÔTE — ET AUCUNE NE TOUCHE LES SURFACES

Chacune est donnée au **pinceau** comme un refus de plus, et battue sur **60 mondes** :

| clause | gestes refusés / 400 | silhouettes rencontrées | tuiles de surface | **rôles de robe** |
|---|---|---|---|---|
| **aucune** | ~93 | 22 | 86 | **20** |
| **1** · paroi ≥ 3 colonnes | 102 | 24 | 89 | **15  (−5)** |
| **2** · pas de contact d'étages | **205** | 25 | 87 | **20  (−0)** |
| **3** · lèvre par blocs de 3 | 112 | 23 | 85 | **19  (−1)** |
| **1 + 2** | **209** | 22 | 73 | **15  (−5)** |

⚠ **LA CLAUSE 2 NE REND RIEN, ET ELLE COÛTE PLUS DE LA MOITIÉ DES GESTES.** Vingt rôles sur vingt
survivent. Et la raison s'explique : elle avait été écrite pour le cas *« qui a ressuscité
(devant, devant) »* — un état de flanc qui **n'existe plus** depuis la décomposition en couches,
laquelle a ramené les flancs de **trois états à deux**. *La clause a survécu à sa justification.*
C'est une leçon de dossier autant que de mesure : **une clause candidate se relit contre le
vocabulaire du jour, pas contre celui qui l'a fait naître.**

⚠ **LA CLAUSE 3 REND UN RÔLE, ET ON SAIT LEQUEL.** `(arrêt|arrêt)` disparaît **à la rangée 0
seulement** — le chapiteau — et survit aux rangées 1 à 4. C'est exact et c'était prévisible : la
clause ne contraint que la **lèvre**, alors que le flanc d'une face **change en descendant**. Elle
est donc strictement plus faible que la clause 1, pour un coût plus élevé.

⚠ **ET « 1 + 2 » DONNE EXACTEMENT « 1 ».** Quinze rôles, les mêmes. La clause 2 n'ajoute rien à la
clause 1 — elle ne fait qu'ajouter son prix.

⚠ **LE COMPTE DE SURFACES NE SE COMPARE PAS D'UNE LIGNE À L'AUTRE, ET IL FAUT LE DIRE.** 73 sous
« 1+2 » n'est pas une réduction : c'est une **borne basse dégradée** — avec 209 gestes refusés sur
400, la battue explore moins et ne rencontre que 22 silhouettes sur 27. À qualité de battue égale,
**aucune clause ne retire une seule tuile de surface**.

**Le pari est reproché, et de loin.** Il annonçait *« (1) et (2) ensemble ramènent autour de
60-65 tuiles »* ; mesuré, elles en rendent **cinq**, et toutes les cinq sont des rôles de robe.
Le total reste à **~96 + 15 = 111** au lieu de 116.

⚠ **ET C'EST LE RÉSULTAT QUI COMPTE, PARCE QU'IL DÉPLACE LA QUESTION.** L'explosion n'est **pas
dans les falaises** — 20 rôles, dont une clause en retire 5. Elle est dans les **surfaces** :
**96 tuiles pour 27 silhouettes**, soit ×3,5, et ce facteur est fait de **bits de bord** — ce
qu'une tuile doit savoir de son voisinage pour que le contour se ferme. Aucune clause sur *ce que
le monde a le droit d'être* ne touche à ça. Le levier est ailleurs : **ce qu'une tuile de surface
a le droit de savoir** — et il se paie en contours ouverts, pas en reliefs refusés.

⚠ **ET LE CHIFFRE QUI DOIT RESTER EN TÊTE EST L'AUTRE : le vocabulaire du banc est à AU MOINS
96 + 20 = 116 tuiles, et il croît encore à 160 mondes** (+3 au dernier relevé), contre **27 + 20 =
47** dans le produit livré. C'est ça, le problème du *sweet spot* — et une clause à 4 % ne le
résout pas.

### UN BIT DE BORD EST UNE QUESTION DE CASE, PAS D'ÉTAGE — ET IL COÛTE ZÉRO TUILE

Le banc sait désormais **dire pourquoi** (`LADDER_WHY=1`) : pour chaque extrémité, ce que la case
trace et ce que ses quatre voisines tracent, lu par `_surface_open` et `_wall_open` — jamais par
un test refait à la main. C'est ce qui a nommé le défaut en une lecture au lieu de trois
reconstitutions au pixel.

**Le trait fautif était le bord EST d'un étage ENTERRÉ**, à `x=12`, visible à travers l'encoche
nord de la tuile du dessus. Les bits de bord n'étaient écrits que sur l'étage propre de la case :
l'étage enterré gardait son bord ouvert et le traçait, alors que **la face qui couvre ma voisine
la couvre pour tous mes étages à la fois**.

| monde | avant | après |
|---|---|---|
| `@battue1` | 14 ext, 4 pavés | **7 ext, 0 pavé** |
| `@battue2` | 10 ext, 0 | **3 → 2 ext, 0** |
| `@battue3` | 4 ext, 4 pavés | **1 ext, 4 pavés** |
| planche · guide | 0, 0 | 0, 0 — **78 et 84 tuiles, inchangées** |

⚠ **ET CHAQUE ÉTAGE RÉPOND DEPUIS SA PROPRE SILHOUETTE, CE QUI REND LE CORRECTIF GRATUIT.** Posé
en gros — le bit de la case visible recopié sur tous ses étages — il coûtait **+5 tuiles** sur la
planche et **+17** sur la battue : sur un étage où le cardinal est déjà plein, le bit est inerte,
mais il change la clé, donc il fabrique des tuiles qui ne diffèrent par rien de visible.
Recalculé depuis la silhouette de chaque étage : **+0 partout**. Même discipline que pour
`NORTH_FLUSH`, même gain.

### L'ERGOT SE TAIT PARTOUT, ET CE QU'IL DÉCOUVRE ÉTAIT UNE FERMETURE ACCIDENTELLE

*(Ce qui suit corrige la fiche ci-dessous, écrite une heure plus tôt.)* J'avais laissé les étages
enterrés **ne pas** faire taire leur ergot, parce que le faire rouvrait une extrémité sur la
planche et une sur le guide. En regardant **ce que la planche perdait** — le banc sait désormais
dire la pile d'une case — la réponse était nette : le stub enterré qui fermait ce contour ne
rejoignait rien de particulier, **il passait par là**. Une fermeture accidentelle masquait un
défaut réel.

**La règle s'applique donc à tous les étages**, et le défaut qu'elle découvre se répare pour ce
qu'il est : le **symétrique exact d'`ABOVE_QUIET`, vers le bas**. Celui-là fait mourir mon bord
latéral à son **nord** quand la case du dessus s'est tue de ce côté ; `BELOW_QUIET_*` le fait
mourir à son **sud** quand c'est celle du dessous. Elle s'est tue parce qu'une robe la longe : la
frontière y est portée par le flanc de cette robe, une case plus bas et une colonne plus loin.

| monde | avant | après | tuiles |
|---|---|---|---|
| planche | 0 | **0** | 78 → **79** |
| guide | 0 | **0** | 84 → **85** |
| `@battue1` | 7 | **1** | 59 → 61 |
| `@battue2` | 2 | **0** ✅ | 61 → 64 |
| `@battue3` | 1 + 4 pavés | **0, 0** ✅ | 57 |

⚠ **+1 TUILE, ET DEUX BATTUES SUR TROIS PASSENT AU VERT.** C'est le meilleur rapport de la
journée, et il vient d'avoir regardé *ce que le correctif détruit* plutôt que *ce qu'il répare*.

### ET « LE SOMMET TRACE, LES ENTERRÉS SE POSENT PLEINS » EST RÉFUTÉ UNE SECONDE FOIS

Le plan laissait la question ouverte à L1 — *« mesuré aujourd'hui, c'est un no-op, mais masqué par
L3, donc à revérifier une fois L1 isolé »*. Remise sur le banc à L3, avec toute la machinerie :

| monde | étages enterrés tracés | **posés pleins** |
|---|---|---|
| planche | 0 extrémité | **14** |
| guide | 0 | **9** |
| `@battue1` | 7 | 14 |
| `@battue2` | 2 | 14 |
| `@battue3` | 1 | 9 |

Et **aucune tuile économisée** — 58 dans les deux cas. Les traits des étages enterrés sont
**porteurs** : ce sont eux qui raccordent deux terrasses de niveaux différents, et l'entaille du
sommet n'est pas une décoration, c'est par où on les voit. La question est close.

⚠ **UN ÉTAGE ENTERRÉ NE FAISAIT PAS TAIRE SON ERGOT — CORRIGÉ CI-DESSUS, GARDÉ POUR LA MESURE.** La règle du silence
demande *« ma voisine trace-t-elle de ce côté ? »* — une question qu'une tuile **enterrée ne peut
pas poser** : ce qui se voit à côté d'elle est le **sommet** de sa voisine, qui n'est pas son
étage. La question est mal posée, et le défaut par défaut doit être le moins dangereux des deux —
un ergot de trop risque un doublement (I2), un ergot de moins laisse un trou (I1).

Mesure : la faire taire ferme **3** extrémités sur `@battue1`, **1** sur `@battue2` et **3 + les
4 pavés** sur `@battue3` — mais elle en **rouvre une sur la planche et une sur le guide**, tous
deux acquis. *Un couple acquis qui rougit arrête tout.* Et I2 reste vert à ne pas la taire : le
risque de doublement ne se réalise pas. On ne tait donc que l'étage visible, et **les quatre
qu'on n'a pas fermées attendent leur propre diagnostic** — elles ne se rachètent pas par une
régression.

### LES TREIZE SONT FERMÉES, ET C'ÉTAIT DEUX DÉFAUTS, PAS UN

**Huit d'entre elles étaient une TROISIÈME COPIE de « qui trace de quel côté ».** `_draws_side` —
la fonction qui décide si l'ergot du voisin doit être tracé — testait le bit *contre-la-roche* à
l'est et à l'ouest, testait le sud, et **ne testait jamais `NORTH_QUIET`**. Une case dont le nord
s'était tu sous un pied s'y annonçait donc traçante ; l'ergot du voisin se posait pour la
rejoindre, et il ne rejoignait rien.

⚠ **MÊME ESPÈCE QUE LES DEUX FAUTES LES PLUS CHÈRES DU DOSSIER** — `_check_wall_seams` qui
redérivait `row_for`, et les deux vocabulaires de surface avant `core/families.gd`. *Deux copies
d'une même règle finissent toujours par se contredire, et celle qui se tait est celle qu'on ne
regarde pas.* Elle demande désormais à `_surface_open`, la seule source. **13 → 5, coût zéro.**

**Les cinq restantes étaient un vrai manque, et il se paie.** Un bord nord tracé à sa traversée,
contre un voisin dont le nord s'est tu sous un pied : le bas de ce pied porte la frontière **au
ras** du bord de sa case, une rangée plus haut, quand mon bord la trace quatre pixels plus bas.
Deux hauteurs pour une seule frontière horizontale, et rien au coin.

Mon bord nord **remonte donc au ras à ce bout-là** — `NORTH_FLUSH_EAST` / `NORTH_FLUSH_WEST`,
symétriques exacts de `ABOVE_QUIET_*`, qui font déjà mourir un bord latéral à son nord.

⚠ **LE PRIX SE MESURE, ET IL A ÉTÉ DIVISÉ PAR SIX EN RESSERRANT LA CONDITION.** Posé dès que la
voisine est muette : **+6 tuiles** sur la planche, **+10** sur le guide. Posé seulement quand je
trace *vraiment* mon nord — `_surface_open`, pas un test refait à la main — et quand le cardinal
vers elle est **plein**, sans quoi nos deux bords nord ne sont pas la même frontière :
**+1 et +3**. La plupart des tuiles qu'il fabriquait ne différaient par rien de visible.

⚠ **ET LE GUIDE ENTRE DANS L'ACQUIS**, au seul couple le plus exigeant : vingt secondes de plus,
et le trou de méthode est fermé. Un banc qui ne connaît qu'un monde ne prouve que ce monde — la
leçon se paie en la mettant dans le rejeu, pas en l'écrivant.

⚠ **Une option qui échoue en silence vaut moins que pas d'option.** `-- L3 F2@guide` en ligne de
commande demandait le monde « GUIDE » — les arguments sont mis en majuscules — donc le banc
rendait **la planche en annonçant le guide**. Deux mesures fausses avant de le voir.

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


## MESURÉ EN PARALLÈLE (session mobile) — TROIS RÉSULTATS SUR LES CINQ MONDES

*Fait pendant que le PC travaillait, sur la question laissée ouverte par le recensement des
jonctions : **quelle restriction serait gratuite ?** Les trois tiennent en une phrase chacune.*

### 1 · LE COMPTE ANNONCÉ N'EST PAS LE VOCABULAIRE — 59 PEINTES, 45 POSÉES

⚠ **`vocabulary` est nourri À CHAQUE PASSE, et rien ne l'y retire.** Silhouette nue (ligne 440),
puis les bits de bord (617, 645), puis les ergots (724) : une clé ajoutée avant d'être affinée y
**reste**, alors que plus aucune case ne la porte. Le banc peignait donc des tuiles que
l'assemblage ne pose nulle part.

| monde | annoncées | **posées** | fantômes |
|---|---|---|---|
| planche | 59 | **45** | **14** |
| guide | 65 | **51** | **14** |
| `@battue1` | 46 | 40 | 6 |
| `@battue2` | 49 | 41 | 8 |
| `@battue3` | 42 | 38 | 4 |

⚠ **ET C'EST LE CHIFFRE SUR LEQUEL TOUTE LA DISCUSSION DU *SWEET SPOT* REPOSE.** « 96 tuiles pour
27 silhouettes », « au moins 116 et ça croît » — tous viennent de ce compteur-là. Le vocabulaire
réel est plus petit, et de **24 % sur la planche**. Les cinq invariants, eux, ne bougent pas : ils
mesurent l'image, et une tuile jamais posée n'y est pas. *Un compteur qui ne mesure pas ce qu'il
prétend mesurer est pire que pas de compteur* — la ligne est déjà au dossier, et elle vient de se
vérifier sur le nombre le plus cité du projet.

### 2 · LE PRODUIT SUR LES QUATRE CÔTÉS NE TIENT PAS — MAIS À DIX CONTEXTES PRÈS SUR 1 370

Le recensement pose que *« la forme fermée est le produit, sur les quatre côtés, du nombre de
classes que chacun doit distinguer »*. C'est falsifiable, et ça se teste sans rien redériver : le
produit n'a de sens que si la tuile posée est une **fonction** de (silhouette, les quatre espèces
en face). On range donc chaque case sous son contexte et on compte les tuiles qu'il reçoit.

| monde | contextes | qui reçoivent plusieurs tuiles |
|---|---|---|
| planche | 335 | **1** |
| guide | 408 | **3** |
| `@battue1` · `2` · `3` | 216 · 214 · 197 | 1 · 4 · 1 |

**1 360 contextes sur 1 370 tiennent** — le produit est vrai à 99,3 %, ce qui n'est pas « vrai »
mais dit exactement où regarder.

### 3 · LES DIX EXCEPTIONS SONT TOUJOURS LES MÊMES QUATRE BITS, ET ON SAIT POURQUOI

Les tuiles qui se disputent un contexte ne diffèrent jamais par `nu/roche` ni par `NORTH_QUIET` :
**uniquement** par `ABOVE_QUIET_EAST/WEST`, `BELOW_QUIET_WEST`, `NORTH_FLUSH_WEST`.

⚠ **ET LA COUPURE EST NETTE : CES QUATRE-LÀ NE DEMANDENT PAS *CE QU'IL Y A EN FACE*, ILS
DEMANDENT *CE QUE MA VOISINE A DÉCIDÉ DE TRACER*.** C'est une information du **second ordre** —
elle n'est pas dans l'alphabet des treize espèces, donc aucun produit sur les côtés ne peut la
compter. Les autres bits, eux, sont bien une fonction de l'espèce : le produit les compte.

**Conséquence directe sur la question posée** — *quelle restriction serait gratuite ?* :

- interdire une **espèce de jonction** retire un facteur au produit, et le produit couvre
  99,3 % des contextes : le levier est réel, et il est chiffrable espèce par espèce ;
- mais il **ne touche pas** aux quatre bits de second ordre, qui sont les « rustines du
  silence » — ils existent pour rattraper une voisine qui s'est tue.

⚠ **ET LEUR PRIX EST PETIT, MESURÉ : 0 à 3 tuiles par monde.** Les effacer du vocabulaire ne rend
que 0 · 1 · 1 · 1 · 3 tuiles. Ce ne sont donc **pas** eux qui font le facteur 3,5 entre 27
silhouettes et le vocabulaire ; ils ne font que casser la formule. Le facteur est ailleurs, et il
est dans les bits de **premier** ordre — ceux que le produit compte, donc ceux qu'une clause sur
les espèces peut mordre.


### 4 · LES TREIZE ESPÈCES SE RÉDUISENT À TROIS OU QUATRE CLASSES PAR CÔTÉ — MESURÉ

*C'est la réponse à « quelle restriction serait gratuite ». Elle ne se raisonne pas : deux
espèces qui donnent **toujours** la même tuile sont interchangeables, et les fusionner ne coûte
rien.* Le banc sort la table brute (`LADDER_DUMP`), l'analyse se fait à côté
(`tools/side_classes.py`) — **27 793 cases sur les cinq mondes**.

⚠ **ON NE CONCLUT QUE DE CE QU'ON A COMPARÉ.** Deux espèces qu'aucun monde n'a mises dans le même
contexte ne sont pas « fusionnables », elles sont **non éprouvées** — et il y en a 18 à 40 par
côté. Même règle que pour les battues.

| côté | espèces vues | **classes** | paires séparées / comparées | jamais comparées |
|---|---|---|---|---|
| nord | 12 | **4** | 10 / 26 | 40 |
| est | 13 | **4** | 30 / 60 | 18 |
| sud | 10 | **3** | 3 / 22 | 23 |
| ouest | 13 | **3** | 31 / 55 | 23 |

**Et les classes sont lisibles, ce qui est le meilleur signe qu'elles sont réelles :**

- **nord** et **est** : *tout ce qui est matière à mon niveau ou au-dessus* | `sol, plus bas` |
  `sol, plus bas + pose` | `vide` ;
- **sud** : *tout le reste* | `face, chapiteau` | `face, chapiteau + pose` — c'est la **règle de
  la lèvre**, retrouvée par la mesure et non supposée ;
- **ouest** : *tout le reste* | `sol, plus bas` **=** `vide` | `sol, plus bas + pose`.

⚠ **LA RESTRICTION GRATUITE EST TROUVÉE, ET C'EST LE « + POSE ».** Il est fusionné **partout**,
sauf quatre créneaux : `sol, plus bas + pose` au nord, à l'est et à l'ouest, `face, chapiteau +
pose` au sud. Autrement dit **19 des 23 « + pose » observés ne servent à rien** — l'alphabet tombe de 13 espèces par côté à 7, et le plafond du
recensement de 52 à 28.

⚠ **ET « SOL, PLUS HAUT » N'EXISTE PAS AU NORD**, sur aucun des cinq mondes : un voisin du nord
plus haut porte **toujours** une pose. C'est le chapiteau sous sa lèvre, retrouvé lui aussi par le
compte plutôt que par la règle.

**LA BORNE, ENFIN — 86 TUILES, PAS 228.** La forme fermée sous ce modèle est la **somme, sur les
silhouettes, du produit des classes de leurs côtés ouverts** — un côté dont le cardinal est plein
n'a rien à distinguer. Mesurée : **86**, contre **45 posées** sur la planche et **51** sur le
guide, et contre 13⁴ = 28 561 pour l'alphabet brut.

⚠ **CE N'EST PAS UN THÉORÈME, ET IL NE FAUT PAS LE VENDRE COMME TEL.** Trois réserves, toutes
chiffrées plus haut : les paires jamais comparées peuvent encore scinder une classe ; les dix
contextes éclatés disent que la tuile n'est pas *exactement* une fonction du voisinage par côté ;
et les silhouettes non vues à un côté donné ne contribuent que ce qu'on a vu. **86 est une borne
mesurée sur cinq mondes**, à confronter à un sixième.


### 5 · CONFRONTÉ À DIX MONDES DE PLUS : UNE FUSION SUR CINQ TOMBE, LA PRINCIPALE TIENT

*La section 4 disait « borne mesurée sur cinq mondes, à confronter à un sixième ». Dix ont été
tirés — `@battue4` à `@battue13`, graines neuves, 4 803 cases de plus.*

| | 5 mondes | **15 mondes** |
|---|---|---|
| cases lues | 27 793 | **32 596** |
| contextes | 659, dont **10** éclatés | 1 007, dont **30** éclatés |
| classes nord · est · sud · ouest | 4 · 4 · 3 · **3** | 4 · 4 · 3 · **4** |
| produit | 144 | **192** |
| **borne par silhouette** | **86** | **97** |

⚠ **UNE SEULE FUSION EST RÉFUTÉE, ET C'ÉTAIT LA PLUS SUSPECTE : `sol, plus bas` = `vide` à
l'ouest.** Les dix nouveaux mondes les séparent. Le signe était là et je ne l'ai pas lu :
**l'ouest annonçait 3 classes quand l'est en annonçait 4**, alors que rien dans le modèle ne
distingue les deux flancs à ce niveau. *Une asymétrie sans cause est un défaut d'échantillon,
pas un résultat.* À quinze mondes, est et ouest sont **identiques**, et c'est le meilleur signe
de convergence qu'on ait ici.

⚠ **LA RÉDUCTION PRINCIPALE, ELLE, TIENT SANS BOUGER D'UN POUCE.** Le « + pose » reste fusionné
dans la grande classe des quatre côtés, sur 32 596 cases, et n'est distingué que dans les **mêmes
quatre créneaux** qu'à cinq mondes. C'est ce qu'on demandait à la confrontation : elle a cassé ce
qui devait casser et laissé debout ce qui tenait.

⚠ **MAIS LA BORNE A BOUGÉ DE 13 % QUAND ON A TRIPLÉ LES MONDES — DONC CE N'EST PAS UNE FORME
FERMÉE, ET IL NE FAUT PAS L'APPELER AINSI.** 86 puis 97 : c'est une **borne basse qui monte**,
exactement comme le compte de tuiles qu'elle prétend expliquer. Ce qu'elle apporte n'est pas le
chiffre, c'est la **structure** : trois ou quatre classes par côté, lisibles, dont une qui absorbe
les deux tiers de l'alphabet.

⚠ **Et les contextes éclatés passent de 1,5 % à 3,0 %.** La tuile est un peu moins une fonction du
voisinage par côté qu'on ne le croyait à cinq mondes — ce sont toujours les mêmes bits de second
ordre, et leur part grandit avec la variété des reliefs.

**Au passage, et gratuitement : les dix mondes neufs sont VERTS à L3/F2** — zéro extrémité,
I1 comme le reste. L3 ne tenait que sur cinq mondes ; il en tient quinze.


### 6 · LA DÉPENDANCE EST BORNÉE AU RAYON 2 — ET C'EST LA RÉPONSE À « POURQUOI ÇA FERMERAIT »

*La question posée : qu'est-ce qui nous fait croire que ça converge vers une fermeture ? Les
trois fermetures qu'on possède ont toutes la même forme — la tuile ne dépend que d'une **fenêtre
bornée** (3×3 pour les 47, un flanc binaire pour les 20, quatre quadrants pour les 15). Le
vocabulaire d'aujourd'hui ne fermait pas parce que ses bits de second ordre demandent **ce que la
voisine a décidé de tracer**, et sa décision dépend de **sa** voisine : une chaîne, pas une
fenêtre. Le test est donc : les contextes éclatés se résolvent-ils en regardant une case plus
loin ?*

| | contextes | **éclatés** | cases concernées |
|---|---|---|---|
| **rayon 1** — moi seul | 1 007 | **30** | 1 566 (4,8 %) |
| **rayon 2** — moi + mes quatre voisines | 5 546 | **0** | **0** |

**Zéro, sur les quinze mondes et 32 596 cases** (`tools/dependency_radius.py`, table brute par
`LADDER_DUMP`). La chaîne ne cascade donc pas : elle a **une longueur, et cette longueur est
un**. La tuile posée est une fonction de (mon contexte, celui de mes quatre voisines).

⚠ **CE QUE ÇA AUTORISE À DIRE : LA FERMETURE EXISTE, ET ON SAIT PAR QUELLE MÉTHODE L'OBTENIR.**
C'est exactement celle qui a donné les 27 — énumérer les fenêtres **réalisables**, prendre
l'image. Ici : énumérer les contextes de rayon 2 que le modèle peut produire, et compter les
tuiles distinctes qu'ils donnent. Le vocabulaire n'est plus une borne basse qui monte à chaque
monde, c'est l'**image d'une fonction sur un domaine fini**.

⚠ **ET LA FONCTION EST MASSIVEMENT NON INJECTIVE, CE QUI EST LA BONNE NOUVELLE** : 5 546
contextes observés pour ~97 tuiles. Ce n'est pas le domaine qu'il faut réduire, c'est l'image
qu'il faut compter — et elle est petite.

⚠ **TROIS RÉSERVES, ET ELLES COMPTENT :**

1. **C'est une mesure, pas un théorème.** Quinze mondes, dont douze tirés au sort ; un seizième
   pourrait éclater un contexte. Ce qui change, c'est qu'on sait maintenant **quoi** énumérer
   pour en faire un théorème.
2. **« Rayon 2 » est borné EN ESPÈCES, pas en cases.** Une espèce comme `face, pied` est le
   résultat d'une chute qui peut faire vingt-sept cases : l'information est déjà non locale
   quand elle entre dans le contexte. La fermeture du dessin s'appuie donc sur celle du modèle
   — les 20 rôles — qui, elle, est close par construction. La chaîne tient : relief → 20 rôles
   → 13 espèces → tuile.
3. **Le domaine réalisable n'est pas énuméré**, seulement échantillonné. C'est le travail qui
   reste, et c'est un travail fini.

⚠ **ET LA CONSÉQUENCE DE MÉTHODE EST IMMÉDIATE : LES BATTUES NE FERMERONT JAMAIS RIEN.** Elles
donnent une borne basse qui monte — 86 puis 97 — et elles monteront encore. La fermeture ne
viendra pas d'un monde de plus, elle viendra de l'énumération du domaine. *Une battue qui ne
rencontre pas une tuile prouve qu'elle est rare, jamais qu'elle est impossible* — la ligne est
au dossier depuis longtemps, et elle vient de désigner sa propre sortie.


### 7 · LE DOMAINE RÉALISABLE S'ÉNUMÈRE — 19 683 RELIEFS, EXHAUSTIVEMENT, ET IL SATURE

⚠ **CE QUI REND L'ÉNUMÉRATION POSSIBLE ÉTAIT DÉJÀ AU DOSSIER : le domaine n'est pas « tout relief
épais », c'est CE QUE LE PINCEAU PEUT FAIRE.** SoluPaint pose des tampons **3×3** et refuse tout
geste qui laisserait une case fine ; et *une main pose aligné, le hasard non*. Le domaine est donc
l'ensemble des reliefs faits de **blocs 3×3 alignés**, un étage par bloc — et celui-là s'énumère,
là où l'espace des reliefs quelconques ne s'énumère pas (5²⁵ pour une simple fenêtre 5×5).

⚠ **ET L'ÉPAISSEUR Y EST GRATUITE, PAR CONSTRUCTION.** Une silhouette d'étage est une union de
blocs alignés sur trois : toute course y fait un multiple de trois, donc jamais moins de trois.
Le pinceau n'a rien à refuser — c'est exactement pour ça qu'il pose des tampons.

**Mesure, `LADDER_EXHAUSTIVE=3` — les 19 683 reliefs de 3×3 blocs à deux étages plus le vide :**

```
       1 / 19683 reliefs :  0 tuiles
     985 / 19683 reliefs : 32 tuiles   (+32)
    2953 / 19683 reliefs : 38 tuiles   (+6)
    3937 / 19683 reliefs : 40 tuiles   (+2)
    ... plus rien pendant 15 746 reliefs ...
   19683 / 19683 reliefs : 40 tuiles de surface, 15 roles   -- TOTAL 55
```

⚠ **CE N'EST PLUS UNE BORNE BASSE, C'EST UN COMPTE.** Sur cette famille-là, il n'existe **aucun**
seizième rôle ni quarante-et-unième silhouette : les 19 683 reliefs ont tous été faits, pas
échantillonnés. C'est la première fois du chantier qu'un nombre de tuiles est **fermé** et non
« rencontré ».

⚠ **ET LA SATURATION EST FRANCHE : plus rien après 3 937 reliefs, soit 20 % du parcours.** Les
80 % restants n'apportent pas une tuile. C'est le contraire exact de la courbe des battues, qui
montait encore à 160 mondes.

⚠ **CE QUE ÇA N'ÉNUMÈRE PAS, ET IL FAUT LE DIRE AUSSI :** les poses **non alignées**, les fenêtres
plus larges que trois blocs, et les étages au-delà de l'alphabet demandé. C'est une **famille
close**, pas le monde entier. Les deux directions restantes se chiffrent :

| direction | reliefs | coût à 21 ms |
|---|---|---|
| un étage de plus (`=4`) | 262 144 | ~90 min — **lancé** |
| une fenêtre 4×4 blocs | 43 046 721 | 10 jours — **hors de portée telle quelle** |

⚠ **La seconde direction est celle qui compte, et c'est elle qu'on ne sait pas encore payer.** Si
le compte est stable en largeur de fenêtre, la fermeture est acquise ; s'il monte, c'est que la
dépendance déborde la fenêtre — ce que le rayon 2 rend improbable, mais improbable n'est pas
mesuré.
