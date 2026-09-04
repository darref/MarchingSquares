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
3. **LE VOCABULAIRE DOIT ÊTRE SUFFISANT ET SERRÉ.** *Suffisant* : les six invariants ferment,
   sur chaque monde. *Serré* : la borne **haute** — ce que le modèle peut exiger — et le compte
   **rencontré** coïncident. Aucune tuile de la planche n'est là pour rien.

   ⚠ **ET ÇA REMPLACE « MINIMAL, PROUVÉ », QUI N'A JAMAIS MORDU.** Minimal est une borne
   *inférieure* — *rien de plus petit ne marche* — et la prouver demande d'explorer toutes les
   conceptions alternatives : on en a vu le prix, chacune (bit sur la face, bit sur la surface,
   aucun bit, trois états de flanc) demandant d'être implémentée et mesurée en entier. Pendant
   ce temps le vocabulaire est monté 52 → 65 → 92 → 47 → 83, et le critère n'a arrêté aucun
   cran. *Suffisant* seul ne vaut pas mieux : il se satisfait en grossissant.

   ⚠ **CE QUI REND LE COUPLE OPÉRATOIRE, C'EST QUE LES DEUX NOMBRES SE CALCULENT.** Le banc
   donne le rencontré, `tools/closed_form_now.py` donne la borne haute. Leur écart n'est pas
   une note, c'est un **détecteur** : un bit dont les deux valeurs ne sont jamais toutes deux
   réalisées gonfle la borne sans distinguer quoi que ce soit — et l'écart le désigne sans
   qu'on le cherche.

   ⚠ **ET IL CONVERGE PAR LES DEUX BOUTS**, là où la minimalité n'a pas de fin : la borne basse
   monte quand on ajoute des mondes, la haute descend quand on retire une fausse liberté. Quand
   elles se rejoignent, c'est **prouvé** — mot pour mot la façon dont les 27 ont été établis :
   256 fenêtres filtrées d'un côté, ce que les mondes produisent de l'autre, et les deux comptes
   se rencontrent.

   ⚠ **CE QUE ÇA NE PROMET PAS** : serré ne veut pas dire minimal. Un autre modèle pourrait
   faire mieux. Serré garantit qu'aucune tuile n'est là pour rien — une promesse qu'un acheteur
   comprend, là où « minimal » est une promesse qu'on ne peut pas tenir.

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
| **L2/F0** | **✅ acquis** | **46 + 44 = 90 tuiles** · les six verts |
| **L2/F1** | **✅ acquis** | **0 extrémité** — les deux derniers pixels sont fermés · les six verts |
| **L2/F2** | **✅ acquis** | idem, **7 profils dont 34 qui serpentent** |
| **L3/F0** | **✅ acquis, et aveugle** | l'image est **identique au bit près** à L2/F0 — I6 y regarde une fenêtre de **0 pixel** |
| **L3/F1** | **✅ acquis** | `mute` **tranché par I6** · 0 extrémité · **I6 ✅ à travers 5 648 pixels de transparence** |
| **L3/F2** | **✅ acquis** | idem, 7 profils dont 34 qui serpentent · **I6 ✅ à travers 8 191 pixels** |

| **L5/F0** | **✅ acquis** | sur la **planche duale**, 15/15 formes, les six verts — **40 tuiles à cheval + 44 rôles** |
| **L5/F1** | **✅ acquis** | **0 extrémité** — parti de 43 · 1 profil plat déplacé · **40 + 44 = 84 tuiles**, inchangées |
| **L5/F2** | **✅ acquis** | **0 extrémité** — parti de 91 · 6 profils dont 29 qui serpentent · I6 ✅ à travers 35 pixels |
| **L4** | **✅ acquis, à tous les niveaux** | les raccords se recensent depuis le monde **et contraignent le dessin** — 51 bords → **36 classes** à L2/L3, les six verts, et I5 passe de **7 à 22 profils distincts** |
| **L3/F2@guide** | **✅ acquis** | **un second monde**, 104×229 — 63 + 44 = **107 tuiles**, **43 dessins**, les six verts |
| **L2/F2@battue1·2·3** | **✅ acquis** | **L2 est CLOS : les six invariants verts sur les CINQ mondes** |
| **L3/F2@battue1·2·3** | **✅ acquis** | **L3 est CLOS : les six invariants verts sur les CINQ mondes** — partis de 14 · 10 · 4 extrémités |
| **L5/F2@guide** | **✅ acquis** | 104×229 — **55 + 44 = 99 tuiles**, **43 dessins**, les six verts |
| **L5/F2@battue1·2·3** | **✅ acquis** | **L5 est CLOS : les six invariants verts sur les CINQ mondes** — partis de 4 · 0 · 0 extrémités et 19 · 6 · 10 pavés |

⚠ **L'ÉCHELLE EST DONC VERTE SUR VINGT-SIX COUPLES** — les douze de la planche par case à
**90 tuiles** (46 surfaces + 44 rôles), le plus exigeant rejoué sur le **guide** à 107, les six des
trois battues, et **les sept de la famille à cheval**, sur les cinq mondes.

### 34 · LE CRAN 3 : TAIRE UN CÔTÉ, C'EST DESSINER COMME SI LA MATIÈRE Y ÉTAIT

Le critère 3 s'était arrêté sur un mur nommé au dossier : *« il reste 39 clés redondantes après le
serrage, et **aucune paire ne diffère d'un seul bit** : le détecteur ne peut donc pas les
accuser »*. Il est franchi, et la clé du serrage n'était pas un retrait.

```
  69 cles enumerees  ->  36 DESSINS distincts
  CANONISEES : 69 cles distinctes  (0 retirees)      <- aucun bit ne part SEUL
  ECHANGEES  : 36 cles distinctes, 0 qui ne rendent PAS le meme dessin
  APRES L'ECHANGE : 36 dessins pour 36 cles, 0 groupe encore confondu
```

**LE DÉTECTEUR AVAIT RAISON ET NE POUVAIT PAS CONCLURE.** Aucun bit ne se retire seul — mesuré,
zéro sur soixante-neuf — et pourtant quinze groupes se confondaient. Le motif se lit dans le
premier, et il se lit en entier :

```
199(s199)   449(s193+bordE)   519(s7+bordW)   1095(s71+ergot0)
1345(s65+bordE+ergot0)   2245(s197+ergot1)   2565(s5+bordW+ergot1)
```

**Ce ne sont pas des bits inertes : c'est la même tuile écrite de sept façons.** Un silence dit
*« la voisine trace ce côté »* ; du point de vue du **dessin**, c'est exactement ce que dit un
cardinal plein. La réduction n'est donc pas un **retrait** mais un **échange** :

| le bit | ce qui le remplace |
|---|---|
| bord est | le cardinal `E`, plus `NE` si le nord est plein, `SE` si le sud l'est |
| bord ouest | idem à l'ouest |
| nord muet | le cardinal `N`, plus les diagonales des coins qu'il complète |
| ergot d'un coin | la **diagonale** de ce coin |

Les autres bits ne s'échangent pas : ils ne disent pas *« la voisine trace »*, ils changent la
**profondeur** du trait. Rien de plein ne les remplace.

⚠ **ET ON NE REMPLIT PAS TOUTES LES DIAGONALES.** Une silhouette nue dont un coin a ses deux
cardinaux pleins et sa diagonale vide porte un **ergot**, et c'est une tuile à part entière. Seules
les diagonales des coins **silencieux** se remplissent — sans quoi l'échange ferait naître un ergot
que l'original n'avait pas.

⚠ **ET PAS LES DIAGONALES SUD, CE QUI A COÛTÉ HUIT CLÉS.** Ma première version remplissait `SE` et
`SO` comme les autres, et l'échange s'arrêtait à **44 clés pour 36 dessins**. Les six groupes
restants ne différaient que par ces deux bits-là — c'est-à-dire par ce que `§33bis` avait déjà
démontré **inerte dès L2**. L'échange fabriquait donc des silhouettes que la forme ne contient
pas. **44 → 36 en cessant de les remplir.**

⚠ **VÉRIFIÉ DANS LES DEUX SENS, ET C'EST CE QUI EN FAIT UNE RÈGLE.** Chacune des 69 clés est
peinte, échangée, repeinte : **zéro ne change de dessin**. Et les 36 clés échangées sont **une par
dessin** : zéro collision. La bijection est exacte, à F1 comme à F2.

⚠ **CE QUE ÇA FERME, ET CE QUE ÇA NE FERME PAS.** *Aucune tuile de la planche n'est là pour rien* :
la clé et le dessin sont en bijection, il n'y a plus une seule écriture redondante. Mais le compte
**rencontré** sur le guide est de 43, pas 36 — l'écart est celui, déjà écrit à la section 23, des
**classes de raccord** : la forme est peinte à graine nulle, et un monde qui met deux clés dans
deux classes leur impose deux bords. 36 est le vocabulaire de **formes** ; ce que la planche
portera se compte avec les raccords.

⚠ **ET LA MÉTHODE VAUT D'ÊTRE GARDÉE : ON PEINT LA VARIANTE MÊME SI ELLE N'EST PAS DANS LA FORME.**
Le détecteur ne comparait que des paires **déjà énumérées** ; quand une précondition exclut la
variante, la paire n'existe pas et le bit passe inaperçu. La question n'est pas *« ce monde
la produit-il ? »* mais *« ce bit change-t-il le dessin ? »*.

### 33 · LE COMPTE DU PRODUIT EST FAUX, ET LA CIBLE EST 43 DESSINS

Trouvé à l'écran par l'utilisateur : la barre de progression annonce **47 tuiles** (27 surfaces
+ 20 rôles). Ce n'est pas un défaut d'affichage — c'est que **le produit identifie une tuile par
sa silhouette seule** quand le modèle l'identifie par le couple *(silhouette, bord)*.

⚠ **ET LA FORME FERMÉE ÉTAIT PÉRIMÉE, CE QUI CACHAIT L'ÉCART.** `closed_form_now.py` ignorait les
deux bits `LIP_ALONE`, nés du transfert de la crête : elle annonçait la borne d'un modèle qui
n'était plus le modèle. Une borne haute fausse est pire qu'aucune borne — c'est elle qui doit
dire quand le vocabulaire enfle.

```
                        avant       apres
  forme fermee          101 cles    126 cles
  controle              --          70 posees, 0 HORS de la forme
  peinte a F1 et a F2   --          43 DESSINS
```

⚠ **LES DEUX BORNES SE RENCONTRENT SUR LES DESSINS, PAS SUR LES CLÉS.** La borne haute peinte
donne **43** ; le guide en pose **43 à 44**. C'est le nombre que la planche doit porter, et c'est
lui que le compteur doit dire — pas 27.

### 33bis · LES DIAGONALES SUD SONT INERTES, ET C'EST UN THÉORÈME

Le détecteur de bits inertes désigne **8 et 32** — `SE` et `SO` — vingt-deux fois chacun, à F1
comme à F2. Ce ne sont pas des bits de bord : ce sont des bits de **silhouette**.

**L'argument tient en deux pas.** Une diagonale n'est enregistrée que si ses deux cardinaux sont
pleins ; pour `SE`, cela veut dire **`S` plein**. Or *dès L2 le sud ne se trace jamais* — c'est le
théorème de la lèvre, déjà au dossier. Mon bord sud n'est pas dessiné, mon bord est non plus
(`E` plein), donc le coin entre les deux n'existe pas dans mon tracé : **`SE` ne peut rien y
changer.** Miroir au sud-ouest.

```
  27 silhouettes  ->  17 une fois SE et SO retires
     20 <- [20, 28]        209 <- [209, 241]
     23 <- [23, 31]        213 <- [221, 253]
     80 <- [80, 112]       215 <- [223, 247, 255]
     84 <- [92, 116, 124]   87 <- [119, 127]
  forme fermee    :  126 cles  ->  82 cles
  peinte          :   43 dessins  ->  43 dessins   (identique)
```

⚠ **ET ÇA NE VAUT QU'À PARTIR DE L2.** Sans faces, le sud SE TRACE, et les diagonales sud
comptent. Le serrage est donc une propriété du **niveau**, pas de `BlobIndex` : c'est
`surface_open` qui sait que le sud se tait, et c'est lui qui doit le dire.

⚠ **ET IL RESTE 39 CLÉS REDONDANTES APRÈS LE SERRAGE** — 82 clés pour 43 dessins, 18 groupes
confondus sur 9 silhouettes, et **aucune paire ne diffère d'un seul bit** : le détecteur ne peut
donc pas les accuser. C'est la suite du critère 3, et elle n'est pas faite.

### 32 · LE TRANSFERT DE LA CRÊTE EST LE MODÈLE — et les deux défauts qui le bloquaient

Il vivait derrière `LADDER_CREST=surface` depuis qu'il a été décidé, pour une raison écrite le
jour même : *on ne met pas un modèle rouge par défaut, même quand c'est lui la cible*. Il laissait
**35 pavés sur 9 couples**. Il n'en laisse plus aucun, et il est devenu le défaut ;
`LADDER_CREST=crete` rend l'ancien pour les comparer.

⚠ **LE PREMIER CORRECTIF NE TOURNAIT PAS, ET LA MESURE DISAIT « ZÉRO GAGNÉ ».** La variante
enterrée — *une lèvre cachée sous un étage plus haut ne montre pas sa face* — était dérivée chez
**un** appelant, qui la passait en paramètre. Le banc appelle `assemble()` en direct, trois fois,
et ne la passait pas : le paramètre valait `{}`. **Un mécanisme qui dort rend le chiffre d'avant,
exactement comme un mécanisme qui échoue** — les deux se lisent pareil dans un tableau. Deuxième
fois de la session, après le drapeau mangé par une édition.

⚠ **D'OÙ LA RÈGLE : UNE POSE SE DÉRIVE LÀ OÙ ELLE SE POSE.** `assemble()` est le seul endroit qui
sache ce qui est enterré ; un appelant qui le recalcule serait une seconde copie d'une même règle.
`level` remplace `buried` dans la signature — quatre appelants, tous obligés de le dire.

⚠ **UNE COUCHE ENTERRÉE PORTE SA MATIÈRE, JAMAIS SON TRAIT.** Effacer le bandeau ferme les pavés,
et I6 le refuse : **219 pixels de fond** dans une case que le modèle dit pleine — parce que *toute*
la pile s'efface et que la dernière ne laisse rien derrière elle. On le **tait** : son trait
devient sa roche. Zéro matière perdue par construction, et c'est mot pour mot la règle de la pose
arrière — *sa matière sans son contour* — une couche plus haut.

**LE SECOND DÉFAUT : `LIP_ALONE` LISAIT LA SILHOUETTE LÀ OÙ IL FALLAIT LIRE LA SURFACE VISIBLE.**
Le bit dit *ma bande de roche bute sur l'herbe de ma voisine, donc je trace*, et il cherchait cette
voisine **dans ma propre silhouette**. Deux fois faux :

- **une robe la couvre** — ce n'est pas son herbe qu'on voit, c'est de la **roche**, et cette roche
  est une face pleine dont le flanc trace déjà. *La face pleine trace, le liseré se tait* : même
  arbitrage que l'arête interne, où le bloc qui avance porte l'angle ;
- **elle est enterrée sous une lèvre plus haute** — c'est **son** bandeau qu'on voit, de la face
  comme le mien, et un bandeau ne se creuse pas latéralement : il touche la frontière et la trace.

⚠ **ET LE SECOND CRITÈRE N'EST PAS « ELLE EST PLUS HAUTE ».** Se taire dès que la voisine est
enterrée rouvre **20 extrémités, toutes noyées** : une surface ordinaire **creuse** son bord
latéral, son trait n'atteint jamais la frontière, et le mien y était le seul à la fermer. `is_lip`
sépare exactement les deux cas. Essayé aussi et refusé parce qu'il ne séparait rien : demander à
`draws_side` — elle répond pour tout le côté, sans savoir à quelles rangées.

⚠ **TROISIÈME FOIS DE LA SESSION QU'UNE RÈGLE LIT LA SILHOUETTE AU LIEU DE LA SURFACE VISIBLE.**
*On ne voit que le sommet* est au dossier depuis la couverture ; elle vaut aussi pour **qui trace**.

⚠ **ET L'ATTRIBUTION PAR COUCHE A NOMMÉ LES DEUX FAMILLES EN UNE LIGNE.** I2 dit désormais, pour
chacun des quatre pixels d'un pavé, **quelle couche l'a posé** — `surface étage 2 | robe`,
`surface étage 1 | surface étage 3`. Sans elle je raisonnais sur des coordonnées : *trois
hypothèses raisonnées, trois fois faux*, déjà au dossier pour les extrémités.

```
                          avant      apres
  paves (I2)                35          0
  couples rouges             9          0
  tuiles de surface         74         63     (le guide)
  dessins                   44         43
```

### 32bis · DIX TUILES QUE LE PEINTRE DEVAIT FAIRE ET QU'AUCUN MONDE NE POSE

Le banc les comptait depuis le début — *10 JAMAIS POSÉE(S)* sur le guide, 8 sur la planche — sans
qu'on lui demande d'où elles venaient. C'est le **critère 3** en plein : *aucune tuile de la
planche n'est là pour rien*.

**La cause.** Les bits de bord se posent en **plusieurs passes** — l'ergot demande à sa voisine un
bord qu'on vient de lui poser, et l'ordre de calcul compte, ce qui est écrit six fois au dossier.
Chaque état traversé s'inscrivait au vocabulaire **au passage** : une case écrite `s65`, puis
corrigée en `s65 | BORD_E`, laissait `s65` derrière elle.

⚠ **ET C'EST LA MÊME LIGNE QUE `indices`, TROIS LIGNES PLUS HAUT DANS LE MÊME FICHIER** — *la carte
visible se refait depuis les silhouettes, jamais l'inverse ; la garder à jour à la main serait une
seconde source, donc un endroit où mentir*. La règle était écrite, elle n'était appliquée qu'à
moitié.

⚠ **LES FANTÔMES NE COÛTAIENT AUCUN DESSIN** — ils peignaient la même image qu'une clé voisine, et
ne gonflaient que le compte annoncé. C'est précisément pour ça qu'ils pouvaient rester sans se
voir : rien n'était faux à l'écran.

```
                    guide    planche
  annoncees          73        54
  posees             63        46
  fantomes           10 -> 0    8 -> 0
  dessins            43        27      inchanges
```

⚠ **TOUS LES NIVEAUX DE L'ÉCHELLE SONT CLOS.** L0 à L5, aux trois libertés, sur la planche de
preuve de leur famille, sur le **guide**, et sur **trois battues tirées par le geste du pinceau**.
Il ne reste aucun couple rouge.

| famille à cheval, à L5/F2 | clés | **dessins distincts** | + rôles |
|---|---|---|---|
| planche duale | 40 | **31** | 20 |
| guide | 50 | **40** | 20 |
| `@battue1` | 59 | **44** | 20 |
| `@battue2` · `@battue3` | — | **46 · 44** | 20 |

⚠ **ET « CLÉ » N'EST PAS « DESSIN ».** Deux clés qui peignent la même image sont une seule tuile :
le peintre la dessine une fois, la planche en porte une case. C'est le compte de droite qui est le
vocabulaire — voir la section 22.

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

## CE QUI VIENT APRÈS L5

L0 à L5 sont clos. Restent, dans l'ordre où le plan les avait posés :

- **L6 — le contrat et le plugin : la règle portée deux fois.** Le contrôle croisé noyau/plugin
  compare **dans les deux sens**, et le manifeste reste *nécessaire et suffisant*. Rien de ce que
  l'échelle a établi n'y est encore écrit : le vocabulaire du banc n'est pas celui que
  `core/` livre, et c'est exactement le genre d'écart qui se paie chez un acheteur.
- **Le guide, à redessiner** — voir les sections 17 et 17bis. La méthode est arrêtée : *pour chaque
  bit qu'un guide doit exercer, dessiner UN accident qui le force*, et l'ajouter au générateur qui
  existe ; et le dessiner **à la demi-tuile**, seule échelle où la liberté vagabonde se voit.
- **Le serrage** — la borne haute (`tools/closed_form_now.py`) et le compte rencontré doivent se
  rejoindre, famille par famille. À cheval, le banc rencontre **48 tuiles sur la planche, 58 sur le
  guide, 66-67 sur les battues** : l'union n'est pas une forme fermée, et tant qu'elle ne l'est pas
  on ne peut pas dire ce qui manque au guide.

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


### 8 · ÉLARGIR LA FENÊTRE N'AJOUTE RIEN — 531 441 RELIEFS, AVEC DES ÉTAGES EMPILÉS

*La section 7 laissait la vraie question ouverte : le compte tient-il quand la fenêtre s'élargit ?
Le protocole est celui qu'on s'est donné — **on fixe l'alphabet et on fait varier la fenêtre,
jamais les deux à la fois.***

| fenêtre | états | reliefs | **tuiles** |
|---|---|---|---|
| 3×3 blocs | 2 | 512 | 36 + 9 = **45** |
| **4×4 blocs** | 2 | 65 536 | 36 + 9 = **45** |
| 3×3 blocs | 3 | 19 683 | 40 + 15 = **55** |
| **4×3 blocs** | 3 | **531 441** | 40 + 15 = **55** |

⚠ **QUADRUPLER LES BLOCS N'AJOUTE PAS UNE TUILE, À DEUX ÉTATS COMME À TROIS.** Et la seconde
ligne compte plus que la première : à trois états le monde **empile** — il y a des plateaux sur
des plateaux, donc des falaises qui passent devant d'autres — et c'est exactement là que la
dépendance aurait pu déborder. Elle ne déborde pas.

⚠ **C'EST LA CONFIRMATION DIRECTE DU RAYON 2, PAR UN AUTRE CHEMIN.** Le rayon 2 disait : la tuile
est une fonction de moi et de mes quatre voisines. L'élargissement dit : un monde plus large ne
produit rien qu'un monde étroit ne produise déjà. Les deux mesures sont indépendantes — l'une lit
des contextes, l'autre énumère des reliefs — et elles disent la même chose.

⚠ **ET LES SEPT PARTS RENDENT TOUTES LE MÊME VOCABULAIRE, ce qui est un contrôle en soi.** Chacune
a parcouru un septième de l'espace, et les sept listes de rôles sont **identiques au caractère
près** : la saturation n'est pas un effet de l'ordre de parcours.

**Le découpage, mesuré avant d'être utilisé** : sur le témoin à 512 reliefs, l'union de deux parts
redonne exactement les 36 tuiles du parcours entier. *Huit comptes ne s'additionnent pas — les
parts se recouvrent en vocabulaire — mais huit listes s'unissent.*

⚠ **CE QUI RESTE OUVERT, ET C'EST HONNÊTE DE LE DIRE : les poses NON alignées.** Tout ceci
énumère ce que le pinceau fait *aligné sur trois*, parce que le dossier a mesuré qu'une main pose
ainsi. Un geste décalé reste possible, et il n'est pas dans le domaine énuméré.


### 9 · L'ALPHABET NON PLUS N'AJOUTE RIEN — ET LE DOMAINE ÉNUMÉRÉ N'EST PAS LE DOMAINE

**Le dernier axe est fermé.** 3×3 blocs à **quatre** états — un troisième étage de plateau, donc
des chutes de neuf cases et des empilements à trois niveaux — **262 144 reliefs exhaustifs :
40 + 15 = 55**, identique aux trois états. Les deux axes du domaine ont été poussés, aucun ne
produit une tuile de plus. **879 316 reliefs énumérés en tout.**

⚠ **MAIS J'AI APPELÉ ÇA « LE DOMAINE RÉALISABLE », ET C'EST FAUX. C'EST UN SOUS-DOMAINE, ET LA
MESURE LE DIT SANS APPEL :**

| | tuiles posées | **hors du domaine énuméré** |
|---|---|---|
| domaine aligné, exhaustif | **40** | — |
| planche de preuve | 45 | **17** |
| guide | 51 | **17** (dont 15 les mêmes) |
| **union des trois** | **59** | — |

**Dix-neuf tuiles que les mondes livrés portent réellement ne sont produites par aucun des
879 316 reliefs énumérés.** La fermeture à 40 ne ferme donc que la famille des **tampons
alignés sur trois**, pas ce que le modèle peut produire.

⚠ **ET LA FAUTE EST UNE ERREUR DE LECTURE À MOI, PAS UN DÉFAUT DE MESURE.** J'ai pris pour une
règle du produit ce qui n'est qu'une **heuristique d'échantillonnage de la battue** — *« une main
pose aligné, le hasard non ; on tire donc surtout des poses alignées »*. C'est écrit à propos de
la **battue**, pas de SoluPaint : la règle du pinceau est *« un tampon 3×3, et refus de tout geste
qui laisserait une case fine »*, sans un mot sur l'alignement. **Un tampon décalé est légal**, et
c'est exactement ce que les 19 tuiles manquantes exercent — pour l'essentiel des **ergots de coin
rentrant** (bits 272, 340, 544, 680), c'est-à-dire des encoches qu'une grille de blocs alignés ne
sait pas creuser.

**Ce qui reste vrai, et ce n'est pas rien :**

- **la direction FENÊTRE est close** : 4×4 à deux états et 4×3 à trois états ne rendent rien de
  plus que 3×3, empilements compris. Cette mesure-là ne dépend pas de l'alignement ;
- **la direction ALPHABET est close** : quatre états ne rendent rien de plus que trois ;
- **le rayon 2 tient** : 0 contexte éclaté sur 32 596 cases.

⚠ **Ce qui n'est PAS acquis : le compte.** 55 est le compte d'une sous-famille. Le vrai domaine
est au moins à 59, et sa fermeture demande d'énumérer les poses **décalées** — 9 positions par
tampon, donc un espace qu'aucune énumération exhaustive ne couvrira telle quelle. *La fermeture
existe (le rayon 2 le dit) ; le compte, lui, reste à établir.*


### 10 · LES POSES DÉCALÉES — TROIS GÉNÉRATEURS FAUX AVANT LE BON, ET LE COMPTE MONTE À 63

*Le domaine aligné était une sous-famille ; restait à énumérer ce qu'un tampon **décalé**
produit. Plutôt que de modéliser des poses — un espace qu'on ne parcourt pas — on engendre
**tout relief épais** d'une fenêtre : c'est le sur-ensemble de ce que le pinceau peut faire,
puisque sa seule règle est de refuser une case fine.*

⚠ **ET J'AI ÉCRIT LA RÈGLE D'ÉPAISSEUR TROIS FOIS AVANT DE LA LIRE.** Chaque version paraissait
juste et chacune a produit un chiffre crédible :

| version | ce qu'elle imposait | ce que ça a donné |
|---|---|---|
| 1 | courses de même **valeur** ≥ 3 | 172 611 reliefs → **127 tuiles**, et **34 silhouettes** |
| 2 | courses ≥ 3 **par silhouette**, bords libres | 1 058 271 reliefs → 129 tuiles, **34 silhouettes** |
| 3 | idem, mais bords libres **en ligne seulement** | 46 736 reliefs → `Thickness` en refuse **1 862 sur 2 000** |
| **4** | matière ≥ 3 **partout**, vide libre au bord | **6 098 reliefs → 0 refusé** |

⚠ **LE DÉTECTEUR ÉTAIT LE MÊME LES QUATRE FOIS : LE COMPTE DE SILHOUETTES.** 34 rencontrées
pour **27** au vocabulaire — une silhouette hors des 27 *est* une case fine. Sans cet invariant
lisible j'annonçais 127 tuiles avec assurance. *Un compteur qui ne mesure pas ce qu'il prétend
mesurer est pire que pas de compteur*, et cette fois c'est un compteur qui m'a sauvé.

⚠ **LA RÈGLE JUSTE, ET POURQUOI ELLE N'EST PAS SYMÉTRIQUE : la fenêtre est posée dans le VIDE.**
Une course de **matière** qui touche le bord y est **terminée** par la marge, donc elle doit faire
trois ; une course de **vide** qui touche le bord **continue** dehors, donc elle est libre. C'est
la même asymétrie que `window_realizable` pour les 27, vue de l'autre côté.

⚠ **ET LE JUGE FINAL EST `Thickness`, PAS LE GÉNÉRATEUR.** Le banc refuse lui-même tout relief
que le module du dépôt déclare fin, et il dit combien — *on ne réécrit pas une règle du dépôt,
on la relit.* Le compte de refusés est passé de 2 984/3 000 à **0**.

**Ce que l'énumération corrigée donne :**

| famille | reliefs | tuiles de surface | rôles |
|---|---|---|---|
| aligné (blocs 3×3), 5 fenêtres | 879 316 | 40 | **15** |
| **libre 5×5, exhaustif** | **6 098** | **29** | **17** |
| mondes livrés (guide + planche) | — | 53 | 20 |
| **UNION** | — | **63** (27 silhouettes) | **20** |

⚠ **AUCUNE FAMILLE N'EN CONTIENT UNE AUTRE.** 17 tuiles de l'aligné manquent au libre 5×5, 31
des mondes livrés y manquent aussi — et le libre en apporte que ni l'un ni les autres n'ont. **Le
vocabulaire est donc au moins à 63 + 20 = 83**, et « 55 » était le compte d'une tranche.

⚠ **ET LES CINQ RÔLES QUE L'ALIGNÉ NE PRODUISAIT PAS SORTENT DÈS LES 200 PREMIERS RELIEFS
LIBRES.** Ils ne demandaient ni un monde plus grand ni un étage de plus : ils demandaient un
**tampon décalé**. C'est la mesure qui condamne l'hypothèse d'alignement, et elle tient en deux
cents reliefs contre 879 316.

**Ce qui reste : une fenêtre assez large pour porter les 27 silhouettes.** Le libre 5×5 n'en
exerce que 15 — un îlot de cinq cases dans le vide ne peut pas tout montrer. La 7×7 à trois états
est en cours d'engendrement ; c'est elle qui dira si le compte se stabilise ou continue de monter.


### 11 · LA BORNE HAUTE EST 341, ET C'EST ELLE QUI TRANCHE — CONTRE « MINIMAL »

`tools/closed_form_now.py` compte, silhouette par silhouette, les assignations de bits que le
modèle **peut** exiger : chaque bit a une précondition lisible dans la silhouette (et, pour
quatre d'entre eux, dans les bits déjà posés), et sa valeur dépend de cases **hors** de la
fenêtre — donc, l'extérieur étant libre, les deux valeurs sont réalisables dès que la
précondition tient.

| | tuiles de surface |
|---|---|
| borne **basse** mesurée (union de toutes les familles) | **63** |
| borne **haute** calculée | **341** |

⚠ **CES DEUX NOMBRES SONT PÉRIMÉS — voir la section 23.** Le jeu de bits a bougé depuis (l'ergot
par la diagonale, les diagonales sud devenues des constantes), et surtout le compte de **clés**
n'est pas le compte de **dessins**. Au jeu d'aujourd'hui : **125 clés → 31 dessins**.

⚠ **CONTRÔLE PASSÉ : les 60 tuiles rencontrées tombent toutes dans la forme.** Une seule dehors
aurait condamné la transcription — c'est la seule façon honnête d'écrire une borne haute à la
main.

⚠ **ET L'EN-TÊTE DE L'OUTIL DIT DÉJÀ QUOI EN FAIRE : « si ce nombre est énorme, ce n'est pas le
compte qu'il faut accepter, c'est le MODÈLE qu'il faut reprendre ».** 341 pour 63 rencontrées,
c'est un facteur **5,4** : le modèle autorise cinq fois plus de distinctions qu'aucun monde n'en
produit. Ce n'est pas la signature d'un vocabulaire riche, c'est celle de **bits qui ne décrivent
pas une distinction du monde mais une rustine locale**.

### LA CLAUSE RAISONNABLE, À LA PLACE DE « MINIMAL »

**Pourquoi « minimal, prouvé » a échoué comme critère**, et il faut le dire franchement : il
demande une forme fermée ; la forme fermée demande soit d'énumérer un domaine non borné —
10,5 millions de reliefs pour une fenêtre 7×7, et ce n'est pas la plus grande — soit une borne
analytique, qui vaut 341 et que personne n'accepterait de peindre. **Le critère n'a jamais mordu :
il a fait mesurer au lieu de faire décider.** En une journée le vocabulaire est monté 52 → 65 →
92 → 47 → 83, chaque cran justifié localement, et « minimal » n'a arrêté aucun.

⚠ **ET LE PROJET A DÉJÀ FERMÉ DEUX FOIS — JAMAIS PAR UNE PREUVE DE MINIMALITÉ.** *Min trois* est
une **décision**, pas un théorème, et elle a retiré 40 % du vocabulaire. *La décomposition en
couches* est une **responsabilité retirée** — « une tuile ne répond que d'elle-même » — et elle a
fait 92 → 47. Les deux fermetures du chantier sont des clauses raisonnables, pas des minimalités
démontrées.

**Trois clauses candidates, de la plus forte à la plus souple :**

- **A · le vocabulaire est DÉCLARÉ, pas découvert.** Une tuile est (silhouette, classe de chaque
  côté), le nombre de classes par côté étant **fixé d'avance** — mesuré : 3 ou 4. Le compte
  devient une formule, ∑ ∏ classes, close par construction : aucun monde ne peut y ajouter.
  Ce qui n'entre pas dans les classes n'est **pas** une tuile de plus, c'est un défaut à régler
  autrement — une pose, une règle de préséance, un ourlet. *Mesure à l'appui : 97 % des contextes
  sont déjà une fonction des classes, et les 3 % restants sont les quatre bits de second ordre.*

- **B · un bit ne se paie que s'il ferme une JONCTION ENTIÈRE.** Déjà écrite au plan, jamais
  appliquée. Le test opératoire : **un bit dont la précondition ne se lit pas dans la silhouette
  seule n'est pas un bit, c'est un symptôme.** Les ergots, `ABOVE_QUIET`, `BELOW_QUIET` et
  `NORTH_FLUSH` échouent tous à ce test — ils demandent ce que la voisine a *décidé*.

- **C · le budget.** Un plafond **décidé**, chiffré, par exemple ≤ 64 tuiles par case, rôles
  compris. Toute règle qui le dépasse est refusée, et on cherche une préséance à la place. C'est
  le pendant exact de min trois : une décision de produit qui tranche, au lieu d'une mesure qui
  constate.

⚠ **ET LES TROIS SE MESURENT AVANT D'ÊTRE ADOPTÉES**, comme les trois clauses de grammaire : ce
qu'elles retirent au vocabulaire, et ce qu'elles coûtent en contours ouverts. La différence avec
« minimal », c'est qu'elles sont **applicables** — on peut dire si une règle les respecte, tout
de suite, sans énumérer un domaine.


### 12 · LA CLAUSE B, CHIFFRÉE — LE TARIF DE CHAQUE BIT

*« Un bit ne se paie que s'il ferme une jonction entière » était au plan depuis longtemps et
n'avait jamais été appliquée, faute d'un tarif. Le voici : on retire un bit (`LADDER_DROP`), on
regarde ce qui s'ouvre et ce qu'on économise — dans les deux monnaies, les tuiles **posées** et
la **borne haute**.*

| bit retiré | posées (planche / guide) | extrémités | doublements | **borne haute** |
|---|---|---|---|---|
| — | 45 / 51 | 0 | 0 | **341** |
| `bord` (nu/roche) | −11 / −13 | 0 | **184 / 194** | 255 |
| `nq` (NORTH_QUIET) | −5 / −8 | 0 | **18 / 68** | 302 |
| **`ergot`** (8 bits) | **−0 / −2** | **30 / 50** | 0 | **113** |
| `above` | −6 / −7 | 9 / 8 | 0 | 267 |
| `flush` | −1 / −3 | 0 / 5 | 0 | 284 |
| `below` | −1 / −1 | 1 / 1 | 0 | 275 |
| `flush` + `below` | −2 / −4 | 1 / 6 | 0 | 228 |
| `ergot`+`flush`+`below` | −2 / −6 | 30 / 55 | 0 | **72** |
| … + `above` | — | — | — | **52** |

⚠ **DEUX FAMILLES SE SÉPARENT NETTEMENT, ET CE N'EST PAS CELLE QU'ON CROYAIT.**

- **`bord` et `nq` sont des RÈGLES.** Ils n'ouvrent **aucune** extrémité — la fermeture tient
  sans eux — mais ils achètent l'**unicité** : 184 et 18 doublements sur la planche, 194 et 68
  sur le guide. Ils servent la règle qui a tranché J2, *traits continus simples, jamais doublés*,
  et ils la servent pour 11 et 5 tuiles. C'est un bon prix.
- **`ergot`, `above`, `flush`, `below` sont des RUSTINES DE FERMETURE.** Ils n'achètent aucun
  doublement ; ils bouchent des **extrémités**, une par une.

⚠ **ET L'ERGOT EST LE CAS EXTRÊME, DANS LES DEUX SENS À LA FOIS : il ne coûte QUE 0 à 2 tuiles
posées, et il coûte 228 tuiles de borne haute — les deux tiers du total.** Huit bits qui ne se
déclenchent presque jamais, mais qui **multiplient** le vocabulaire potentiel par trois. C'est
exactement la forme d'un bit qui devrait être une **règle** : il ferme 30 à 50 extrémités, donc
il porte quelque chose de réel, mais il le porte de la manière la plus chère possible.

⚠ **LE TEST DE LA CLAUSE B DOIT DONC SE DIRE SUR LA VALEUR, PAS SUR LA PRÉCONDITION.** Écrit
« un bit dont la *précondition* ne se lit pas dans la silhouette », il innocente l'ergot — dont
la précondition (deux cardinaux pleins, diagonale vide) est bien dans la silhouette. Écrit
**« un bit dont la VALEUR demande ce que la voisine a DÉCIDÉ »**, il accuse les quatre, et les
chiffres suivent : à eux quatre ils font passer la borne de **341 à 52**, soit **85 % de la
borne haute**, pour **2 à 6 tuiles posées** et 55 extrémités.

`bord` et `nq`, eux, demandent un **fait du monde** — « ma voisine est-elle couverte par une
face ? » — pas une décision. Ils passent le test, et le tarif leur donne raison.

**Ce que ça désigne comme prochain travail, et c'est précis : l'ergot de coin rentrant.** Trouver
une règle qui ferme ces 30 à 50 extrémités sans demander à la voisine ce qu'elle trace ferait
tomber la borne de **341 à 113** pour un coût observé **nul**. Aucun autre bit n'a ce profil.


### 13 · L'ERGOT, PREMIER COUP — LA MOITIÉ DE SON SILENCE ÉTAIT UNE CONSTANTE

*Le tarif désignait l'ergot : 228 tuiles de borne haute pour 0 à 2 tuiles posées. Avant de le
redessiner, on regarde **pourquoi** il se tait.*

| raison du silence | planche | guide |
|---|---|---|
| **c'est le SUD** — lisible dans ma silhouette | **47** | **57** |
| le BORD l'a fait taire — de la roche à ma diagonale | 43 | 67 |
| la voisine porte une robe | 4 | 6 |

⚠ **LA MOITIÉ N'ÉTAIT PAS UNE QUESTION, C'ÉTAIT UNE CONSTANTE.** Depuis L2 le sud ne se trace
**jamais** — c'est le théorème de la lèvre, déjà au dossier. Pour les deux ergots dont le
partenaire est au sud, le bit valait donc **toujours 1** : il ne nommait rien. Le dessin le sait
sans qu'on le lui dise ; la clé n'en parle plus.

| | avant | après |
|---|---|---|
| tuiles posées (planche / guide) | 45 / 51 | **45 / 51** — inchangées |
| I1 · I2 · I3 | ✅ | ✅ |
| **borne haute** | 341 | **241** |
| **serrage** | 18 % | **26 %** |

⚠ **CENT TUILES DE BORNE POUR ZÉRO PIXEL CHANGÉ**, et c'est la démonstration du nouveau critère
dans le même mouvement où il est écrit : *une constante déguisée en bit ne distingue rien dans le
monde réel, mais la forme fermée compte ses deux valeurs comme réalisables.* Le serrage est le
détecteur qui l'a rendue visible.

**Ce qui reste de l'ergot, et c'est la suite immédiate :** les 43 à 67 silences dus au bord
signifient exactement *« de la roche couvre ma diagonale »* — un **fait du monde**, pas une
décision de la voisine. Reformulé ainsi il passe le test de la clause B, et il pourrait ne coûter
**qu'un bit par coin au lieu de deux**.


### 14 · LE BIT DE DIAGONALE — LA QUESTION SE RETOURNE, ET ELLE COÛTE MOITIÉ MOINS

L'ergot demandait *« ma voisine trace-t-elle ce côté ? »* — une **décision**, ce que la clause B
interdit. Le diagnostic disait pourquoi elle ne trace pas : dans **43 à 67 cas sur 47 à 73**, une
**face couvre ma diagonale**. La question se retourne donc en un **fait du monde**, que la case
pose elle-même — et **un seul bit par coin au lieu de deux**.

| | départ | après l'ergot-sud | **après la diagonale** |
|---|---|---|---|
| tuiles posées (planche / guide) | 45 / 51 | 45 / 51 | **45 / 51** |
| I1 · I2 · I3 | ✅ | ✅ | **✅** |
| **borne haute** | **341** | 241 | **185** |
| **serrage** (53 tuiles vues) | 16 % | 22 % | **29 %** |

⚠ **ZÉRO PIXEL CHANGÉ, ZÉRO TUILE PERDUE, ET LA BORNE DESCEND DE 156 EN DEUX COUPS.** Les deux
corrections sont de la même espèce, et c'est ce qui en fait une méthode plutôt qu'une chance :
*l'identité de la tuile portait une information que le monde ne fait pas varier* — une
**constante** d'abord (le sud), une **décision redondante** ensuite (ce que la voisine trace).

⚠ **ET LES 4 À 6 CAS « LA VOISINE PORTE UNE ROBE » NE COÛTENT RIEN.** Je m'attendais à ce qu'ils
rouvrent des extrémités — la diagonale ne les couvre pas en théorie. Mesure : **zéro**. Rejeu des
vingt couples acquis : l'échelle tient.

⚠ **CORRECTION D'UN CHIFFRE À MOI** : j'avais annoncé « serrage 18 % → 26 % » en mélangeant deux
bases — l'union de toutes les familles, mesurée sous l'ancien jeu de bits. Sur une base constante,
les 53 tuiles de la planche et du guide, c'est **16 % → 22 % → 29 %**.

**Ce que le serrage désigne maintenant.** Les silhouettes les plus chargées sont **20 et 80, à 18
tuiles chacune** ; le reste suit à 12. Tant que la borne reste à cinq fois ce qu'un monde produit,
il reste des bits qui ne varient pas — et le détecteur les nommera un à un, comme il vient de le
faire deux fois.


### 15 · LES DIAGONALES SUD SONT DES CONSTANTES — LA RÈGLE DE LA LÈVRE, UN CRAN PLUS BAS

*Le serrage désignait les silhouettes 20 et 80, à 18 tuiles chacune. On regarde ce qu'elles
portent vraiment.*

⚠ **UNE SEULE COMBINAISON SUR DIX-HUIT, POUR L'UNE COMME POUR L'AUTRE** — et c'est le bit de
diagonale, toujours **mis**. Vérifié ensuite sur toutes les silhouettes :

| coin rentrant | bit mis | **pas mis** |
|---|---|---|
| NO | 2 | 5 |
| NE | 2 | 5 |
| **SE** | **6** | **0** |
| **SO** | **6** | **0** |

**Et c'est un théorème, pas une coïncidence de deux mondes.** Au coin SE, ma cardinale **est** est
pleine et ma diagonale SE est vide : cette voisine a donc **son sud vide**, c'est une **lèvre**, et
sa face couvre ma diagonale. Toujours. Idem au SO par la voisine ouest. C'est la règle de la lèvre
— *une case dont le sud est vide a sa propre falaise juste dessous* — appliquée à la diagonale.

| | tuiles posées | peintes | **borne haute** | serrage |
|---|---|---|---|---|
| départ de la soirée | 45 / 51 | 59 / 65 | **341** | 16 % |
| ergot-sud (constante) | 45 / 51 | 59 / 65 | 241 | 22 % |
| bit de diagonale (fait, pas décision) | 45 / 51 | 59 / 65 | 185 | 29 % |
| **diagonales sud (constante)** | **45 / 51** | **49 / 57** | **139** | **38 %** |

⚠ **ET CETTE FOIS LE NOMBRE DE TUILES PEINTES POUR RIEN TOMBE AUSSI — de 14 à 4.** Les trois coups
précédents ne touchaient que la borne ; celui-ci retire des tuiles que le banc **fabriquait** et
que l'assemblage ne posait nulle part. Rejeu des vingt couples : l'échelle tient.

⚠ **TROIS FOIS LE MÊME DÉFAUT, TROIS FOIS LE MÊME DÉTECTEUR.** Le sud de l'ergot, puis la décision
de la voisine, puis les diagonales sud : à chaque fois *l'identité de la tuile portait une
information que le monde ne fait pas varier*, et à chaque fois c'est l'écart entre la borne et le
rencontré qui l'a nommée. **341 → 139 en une soirée, sans changer un pixel ni perdre une tuile.**

### CE QUE LE SERRAGE VEUT DIRE POUR L'ACHETEUR — ET CE N'EST PAS QUE DE L'ÉLÉGANCE

Question posée en cours de route : *le but, pour le soft, c'est d'avoir le plus de jumelage
possible ?* Presque — et la nuance est exactement ce que « serré » sert à dire.

- **Le compte rencontré est le travail de l'acheteur.** Moins de tuiles distinctes = plus de
  jumelles = plus de cases remplies par coup de crayon. Sur la planche : **45 tuiles de surface
  pour 13 200 cases visibles**, près de trois cents jumelles par tuile.
- **Mais maximiser le jumelage n'est pas le but** : on l'obtiendrait en fusionnant des tuiles qui
  doivent différer, et le prix serait des trous. C'est ce que les six invariants interdisent.
- **La borne haute, elle, est ce que SON monde pourrait un jour réclamer.** Et le dossier l'écrit
  déjà : *« une tuile absente du guide est une tuile que l'acheteur ne peut pas peindre »*.
  L'écart entre les deux n'est donc pas une inélégance, c'est un **risque de trou** — des tuiles
  qu'un monde peut exiger et qu'aucun guide n'exerce.

⚠ **D'où la formulation exacte de la promesse : tout ce qu'il peint sert, et tout ce dont il aura
besoin est peint.** Les deux à la fois — c'est pourquoi les deux nombres doivent se **rejoindre**,
et non l'un être petit. Chaque bit retiré ce soir retire du risque, pas seulement de la borne.


### 16 · 29 ET 113 : LE DÉTECTEUR ATTEINT SA LIMITE, ET CE N'EST PAS UN DÉFAUT DU MODÈLE

Le serrage désignait 29 et 113, à 12 tuiles chacune. Elles ne portent **qu'une** combinaison sur
la planche et le guide — de quoi conclure « encore une constante ». **Compté avant de conclure :
elles n'apparaissent que QUATRE fois** (et 20 et 80, seulement **deux**).

⚠ **UNE CONSTANTE SUR QUATRE OCCURRENCES NE PROUVE RIEN**, et c'est exactement le piège que le
dossier reproche aux battues : *une rencontre qui n'a pas eu lieu ne prouve rien.* J'ai donc
cherché des occurrences ailleurs — douze battues de plus, au jeu de bits du jour :

| silhouette | sur planche + guide | **sur quatorze mondes** |
|---|---|---|
| 29 | 1 combinaison | **2** — `bordW`, `bordW+diagNE` |
| 113 | 1 | **2** — miroir exact |
| 20 · 80 | 1 | 1 — `nu` |
| 5 · 65 | 1 | 1 |

**Le `diag` variait donc bien ; c'est l'échantillon qui était muet.** Et le `bord`, lui, reste mis
partout — mais cette fois je ne conclus pas : aucun théorème ne le force, contrairement aux
diagonales sud dont la règle de la lèvre garantissait la valeur. *La différence entre les deux
cas est tout ce qui sépare une mesure d'une preuve.*

⚠ **CE QUE ÇA APPREND SUR LE DÉTECTEUR LUI-MÊME : le serrage ne diagnostique que ce que les
mondes exercent.** Là où une silhouette n'apparaît que deux fois, l'écart entre borne et
rencontré ne dit pas si un bit est constant ou simplement pas encore vu. **La limite du
détecteur est la couverture du guide**, et c'est la même ligne que le dossier écrit déjà :
*« une tuile absente du guide est une tuile que l'acheteur ne peut pas peindre ».*

**État après quatorze mondes : 67 tuiles rencontrées pour 139 en borne — serrage 48 %.**

⚠ **Et la suite n'est donc plus dans les bits, elle est dans le GUIDE.** Tant que 255 occupe
23 699 cases sur 26 324 et que six silhouettes en occupent deux ou quatre, le serrage ne peut
plus descendre par la mesure : il descendra quand un guide exercera le vocabulaire au lieu de
l'effleurer. Le plan le note déjà — *« le guide n'est plus un paysage, c'est une planche de
spécimens, et le redessiner reste à faire »*.


### 27 · LA FACE ÉTAIT COLLÉE AU BORD — UNE MOITIÉ EST UN THÉORÈME, L'AUTRE ÉTAIT UN OUBLI

*Trouvé par l'utilisateur, en regardant l'écran : « les robes ne sont pas libres, elles sont
collées au bord et c'est leur seule manière d'être ». Mesuré aussitôt, et il avait raison deux
fois.*

```
                 bord d'une face, 16 pixels              au ras
  avant        : 0 0 0 0 0 1 2 3 3 3 2 1 0 0 0 0         36/64  (56 %)
  une surface  : 4 4 5 5 6 6 7 7 7 7 7 6 6 5 5 4          0/64
```

⚠ **ET UN SECOND FAIT, PIRE QUE LE PREMIER : `wall_depth` NE LIT `freedom` QUE POUR LE TEST
`== 0`.** F1 et F2 rendaient donc **exactement le même bord de falaise**. Le style *ondulated*
annoncé comme gratuit n'aurait rien changé aux robes.

**LA LOI DU MOINDRE RAS EXIGEAIT LA MESURE, ET PERSONNE NE L'AVAIT FAITE.** Le théorème parle
de **deux traversées** — deux *points* — et le code aplatit **deux intervalles entiers**. Le
dossier note bien un essai voisin (réduire le pincement aux colonnes du bord, qui casse L5),
mais entre « deux points » et « dix colonnes plates » l'entre-deux n'avait jamais été mesuré.

**Essayé — liberté rendue partout sauf aux quatre points (deux coins, deux traversées) :**

```
  apres        : 0 2 3 2 0 1 2 3 3 3 2 1 0 3 3 0         18/64  (28 %)

  I1 fermeture  ECHEC 13 extremites   I2 ECHEC 555 paves
  I1 fermeture  ECHEC 35 extremites   I2 ECHEC   1 pave
  I1 fermeture  ECHEC 21 extremites   I2 ECHEC   2 paves
```

⚠ **REFUSÉ — ET LES COORDONNÉES DISENT POURQUOI, ce qui vaut mieux que le compte.** Elles
tombent aux **coins** (`0,0` · `15,0` · `0,15` · `15,15`) et aux **traversées** (`4,15` ·
`12,15` · `0,4`), et les tuiles nommées sont des **surfaces** (`7`, `193`, `540`, `112`) : ce
qui casse est la jonction **face ↔ surface**. Le bord d'une surface arrive **n'importe où dans
`[4, 7]`** selon sa propre liberté — il serpente. La face doit donc être plate sur **tout
l'intervalle où une perpendiculaire peut se présenter**, pas au seul point canonique.

**« Collées au bord » est donc un THÉORÈME, plus une négligence** — et c'est ce que la mesure
apporte : le dossier avait une supposition à cet endroit, il a maintenant une démonstration.
Route refusée gardée joignable : `LADDER_WALLFREE=points`.

### 27bis · MAIS L'AMPLITUDE, ELLE, N'AVAIT JAMAIS ÉTÉ INTERROGÉE — 3 → 6, GRATUIT

Le ras des intervalles démontré, il restait **un** axe de liberté à la face : la **profondeur**
de sa bosse entre les deux traversées. Elle valait `1 + graine % 3` — **trois pixels** sur une
portée libre de sept — quand une surface en prend **quatre à sept**. Personne ne l'avait
mesurée ; c'était un chiffre posé, pas un chiffre trouvé.

```
  amplitude <= 3 : 0 0 0 0 0 1 2 3 3 3 2 1 0 0 0 0
  amplitude <= 6 : 0 0 0 0 0 2 4 6 6 6 4 2 0 0 0 0

                          reference   amplitude 6
  profils de face          12      ->     24
  (mondes les plus riches)  8      ->     22
                           10      ->     24
```

**Les six invariants restent verts sur les vingt-six couples.** La liberté est rendue, elle ne
coûte **ni une tuile, ni une extrémité, ni un pavé**. `LADDER_WALLREACH` la fait varier, pour
que le chiffre reste reproductible.

⚠ **ET C'EST EXACTEMENT CE QUE LA LOI DU MOINDRE RAS EXISTE POUR ATTRAPER**, une fois de plus :
*« le ras n'est pas une simplicité, c'est une liberté confisquée »*. Ici la confiscation ne se
lisait même pas comme un ras — elle se lisait comme une constante anodine.

⚠ **ET LE LEVIER DES DEUX STYLES EST TROUVÉ EN CHEMIN.** `wall_depth` ignore `freedom` : c'est
là que *straight* et *ondulated* doivent se séparer pour les falaises — bosse plate d'un côté,
bosse qui serpente de l'autre. À faire avec les styles, et noté aux questions ouvertes.

### 31 · LA DÉRIVATION : ce que la liberté des SURFACES laisse aux FACES

*Question de l'utilisateur, et c'est elle qui a débloqué la nuit : « maintenant qu'on a un guide
fermé, tout le reste est du calcul de jumelage en fonction des libertés possibles des
silhouettes — dérouler l'algo de la main de l'artiste est-il bien la manière de chercher le
formalisme ? »* Oui, et ça explique pourquoi les heures précédentes ont pataugé : **je résolvais
dans le mauvais ordre.**

⚠ **LA DÉPENDANCE EST ORIENTÉE, SANS RETOUR : `silhouettes → surfaces → faces`.** Mesuré deux
fois — la face est plate **là où le bord perpendiculaire d'une surface peut arriver**, et
libérer la face n'a jamais rien changé aux surfaces. Traiter les deux ensemble, c'était casser
trois choses pour en bouger une : le diagnostic d'un essai raté le montre en clair — *23 surface
contre surface, 18 robe contre robe, 5 surface contre robe*.

**D'où `core/border_rules.gd` : les contraintes d'un bord de face, ÉCRITES ET NOMMÉES** au lieu
d'un profil codé à la main. Il ne dessine pas, il contraint — un autre dessin pourrait en
fabriquer un autre, du moment qu'il passe par les mêmes points.

### 31bis · LES TROIS ALIGNEMENTS, ET POURQUOI ILS NE PEUVENT PAS L'ÊTRE

*« Les coins de surface, les jonctions en T et les coins de falaise sont-ils alignés
verticalement ? »* Mesuré :

```
  coin de surface  (4, 4)   constante, MEME a F2
  jonction en T     4       le bord d une surface atteint son bord de case a 4
  coin de falaise   0       au ras  <- le seul desaligne
```

⚠ **ET LES ALIGNER NE FERME PAS : 1 702 DOUBLEMENTS.** Le désalignement n'est pas un oubli, c'est
ce qui garde **un seul traçant par frontière**. Deux surfaces voisines décrivent **deux
frontières distinctes** qui se relaient bout à bout — d'où le rendez-vous à 4, qui leur permet de
se retrouver sans jamais se parler. Une face et la surface qu'elle borde décrivent **la même**
frontière : les mettre à la même profondeur, c'est les faire se revendiquer toutes les deux.

**La règle, en une phrase, et elle porte tout le reste :**

> **Une frontière RELAYÉE se place où la famille veut ; une frontière PARTAGÉE est le bord
> lui-même.**

### 31ter · CE QUI DÉRIVE DU CHOIX DE L'ARTISTE, ET CE QUI N'EN DÉRIVE PAS

*Correction de l'utilisateur, et elle est plus vraie que ma formulation : « pas imposés, plutôt
dérivant des propres choix qu'il a faits ».* Le modèle n'impose **aucune valeur** — il impose une
**cohérence**. Toutes les lignes d'une même famille sont des morceaux d'une seule frontière vus
dans des tuiles différentes.

```
  traversee 2, 3, 4, 5, 6  ->  bout du flanc a 0 : TOUJOURS ok
  bout du flanc a 1 ou 2   ->  TOUJOURS en echec
```

⚠ **LE 4 DE NOTRE DESSIN N'EST QU'UN TIRAGE** : la traversée marche de 2 à 6. ⚠ **MAIS LE BOUT
D'UN FLANC VAUT ZÉRO QUOI QU'ON CHOISISSE** — et c'est la règle ci-dessus, appliquée. J'avais
affirmé ce zéro sans preuve ; l'utilisateur l'a refusé, l'expérience isolée l'a confirmé. *Une
explication inventée après la mesure n'est pas une dérivation.*

⚠ **ET MON PREMIER ESSAI NE RÉPONDAIT À RIEN** : il changeait **trois choses à la fois** — la
valeur des bouts, la longueur du plat et la profondeur de rencontre. Isoler la question a coûté
une ligne et rendu la réponse en un run.

### 31quater · LE TROC, CHIFFRÉ — et l'image que ça donne du modèle

```
  traversee   profondeur libre de la surface   portee libre des lignes de falaise
      2                6 crans                          10 positions
      4                4 crans                           6 positions
      6                2 crans                           2 positions
```

**Chaque cran gagné sur la profondeur du cadre coûte deux positions aux lignes de falaise** —
`RES − 2c − 2`, la zone plate s'allongeant des deux côtés. Formulation de l'utilisateur, exacte :
*« chaque liberté prise en réduit une autre »*.

⚠ **Une correction : le sud des falaises n'y échappe pas.** Le pied et le flanc suivent la même
formule. Ce qui reste libre quoi qu'il arrive est leur **amplitude**, pas leur **portée** — deux
libertés différentes, et seule la seconde se paie.

> **L'image juste : un cadre orthogonal irrégulier — droit à ses bouts, serpentant en son
> milieu — FLOTTANT EN ÉCHELLE. L'artiste choisit une fois à quelle profondeur son cadre
> s'enfonce, et ce seul choix fixe les rendez-vous de toutes ses tuiles.**

### 31quinquies · I3 ÉLARGI AUX COUCHES — et il accuse aussi le modèle actuel

L'ancien I3 marche de case en case et juge l'arête **partagée par deux cases**. Depuis que la
tuile de lèvre porte le haut de sa face, deux **couches** se rencontrent **dans** la même case, et
cette frontière-là n'avait aucun juge : I2 la compte quand elle double, sans pouvoir dire entre
qui. L'assemblage rend donc, en option, **qui a posé quel pixel** — et le banc s'en sert.

```
                          doubles entre couches
  drapeau baisse (livre)   L2/F1  116   L3/F2@guide 153   L5/F2  64
  avec le transfert        L2/F1  264
```

⚠ **LE DOUBLEMENT ENTRE COUCHES PRÉEXISTAIT, ET PERSONNE NE LE REGARDAIT.** Le transfert aggrave,
il n'invente pas. Et le couple dominant est `surface | robe` — 191 sur 264 — c'est-à-dire
exactement le débord du bandeau.

⚠ **ET C'EST L'ASSEMBLAGE QUI REND LES IDENTITÉS, PAS LE BANC QUI LES REDEVINE.** Redériver
l'ordre d'empilement dans l'instrument serait une seconde copie d'une même règle — la faute la
plus chère du dépôt. Le paramètre est optionnel : le produit ne le passe pas, et ne paie rien.

**La dette, ventilée sur le modèle LIVRÉ — c'est-à-dire sans le transfert :**

```
  surface etage 1 | robe                 68          surface etage 2 | robe                 20         |  95 des 116 : une SURFACE
  surface etage 3 | robe                  8         |  contre une ROBE
  surface etage 0 | robe                  7        /
  surface etage 0 | surface etage 1       4          surface etage 2 | surface etage 3       4         |  21 : deux SURFACES
  surface etage 1 | surface etage 3       3         |  d etages differents
  ... et cinq autres couples a 1 ou 2              /
```

⚠ **QUATRE-VINGT-QUINZE SUR CENT SEIZE SONT `surface | robe`.** Ce n'est donc pas une poussière
répartie : c'est **une seule jonction** — le bord d'une surface contre la roche d'une face qui
la longe, vues à travers la transparence de l'une ou de l'autre. Le transfert la porte de 95 à
191 parce qu'il met de la face *dans* la tuile de surface, mais il ne la crée pas.

⚠ **ET ELLE EST AFFICHÉE, PAS ASSERTÉE — pour l'instant, et la raison compte.** La mettre au
verdict rendrait les **vingt-six couples rouges d'un coup**, y compris ceux qui n'ont pas bougé
(mesuré : 23 échecs). *Une échelle toujours rouge ne dit plus si un correctif a servi.* C'est le
statut qu'a eu la couverture du guide tant qu'elle était un travail en cours — « affiché, pas
asserté » — et ça redevient une assertion le jour où la dette est payée.

### 30 · LE TRANSFERT DE LA CRÊTE DEVIENT LA SPÉCIFICATION — et ce qu'il en coûte

*Décision utilisateur, prise en connaissance du prix : « on change de modèle, tant pis si on a
fait tout ça pour rien, continue de réutiliser tout ce que tu peux, c'est maintenant la vraie
spécification ».*

**La règle, en une phrase :** la frontière lèvre / falaise appartient à la **tuile de surface à
bord sud**, qui porte le haut de sa propre face ; le chapiteau se tait.

⚠ **ET LA LICENCE EST UN THÉORÈME DÉJÀ AU DOSSIER** : *« une case dont le sud est vide est une
LÈVRE, sa propre face couvre la case d'en dessous, TOUJOURS »*. Constant, donc peignable dans la
tuile — mot pour mot l'argument de l'épaule.

⚠ **CE N'EST PAS « RENDRE LE SUD », REFUSÉ EN SON TEMPS (222 → 669 extrémités).** Celui-là était
une **addition** — la surface rouvrait son sud pendant que la crête traçait encore. Ici c'est un
**échange**, et I3 le confirme : 0 double, 0 muette, 0 parasite.

**Ce que le modèle a réutilisé : tout.** Les 27 silhouettes, les bits de bord, les classes de
raccord, les 44 rôles avec l'arête interne, le guide, l'échelle, le recensement. Le transfert ne
remplace rien — il **déplace un propriétaire**. Une seule chose est jetée : la crête du
chapiteau.

**Trois formulations ont remplacé autant de rustines :**

1. ⚠ **« Sous une lèvre, ce qui est en dessous de la tuile EST la face. »** Une seule règle à
   toutes les libertés. À **F0** le bandeau a une profondeur nulle : l'herbe touche la face et
   son trait tombe sur la rangée du bas. À F1/F2 le bandeau est là, la roche continue chez la
   robe, rien ne se trace. J'avais commencé à écrire deux cas — c'était le signe que je n'avais
   pas la bonne règle, et F0 est le **témoin** : sans lui le modèle n'a plus de plancher.
2. ⚠ **Le transfert ne vaut que pour la famille PAR CASE.** À cheval, une tuile de surface est
   posée sur le **croisement de quatre cases** : elle chevauche la lèvre *et* sa face, donc le
   bandeau tomberait en son milieu. Le chapiteau y garde sa crête, et L5 repasse au vert.
3. ⚠ **C'est la RANGÉE qui décide où la coupe latérale s'arrête, pas la colonne.** Le bandeau
   varie par colonne, la coupe par rangée : entrelacés, ils laissaient un **îlot de roche de
   deux pixels**, détaché donc cerné donc épais.

**Le compte :**

```
                      avant      apres
  extremites (I1)       0          0     partout, F0 et L5 compris
  tuiles de surface    64         74
  dessins              36         44
  roles de robe        44         44
  couples rouges       0          9      tous I2, 35 paves
```

### 30bis · CE QUI RESTE, ET C'EST UNE CLASSE NOUVELLE

⚠ **LE BANDEAU DOIT DÉBORDER, ET C'EST FORCÉ.** La face en dessous occupe **toute la colonne**,
et son flanc est pincé à zéro au coin — mesuré et démontré à la 8.x. Le bandeau doit donc
atteindre le bord de case, alors que la surface, elle, est coupée à sa propre profondeur (4 à
7). Son bord haut borde donc du transparent — et dans l'image assemblée, **ce transparent laisse
voir l'étage enterré, qui y a son propre trait**. Les deux se touchent : un pavé.

```
   13   ....############   la surface est coupee a x<4, l herbe tracee (roche dessous)
   14   ####rrrrrrrrrrrr   le bandeau DEBORDE, et son bord haut se trace
```

⚠ **C'EST UNE COLLISION ENTRE DEUX COUCHES, PAS ENTRE DEUX CÔTÉS D'UNE TUILE.** I3 ne peut pas
la voir — il ne juge que les frontières d'une même case. I2 la voit sans pouvoir dire entre qui.
C'est le prix d'un modèle qui met de la **face dans une tuile de surface** : les couches se
rencontrent désormais **à l'intérieur** d'une case, et aucun invariant n'a été conçu pour ça.

⚠ **ET L'AMPLITUDE 6 N'Y SURVIT PAS.** Gratuite dans l'ancien modèle — *0 pavé* — elle creuse
dans le nouveau jusqu'à découvrir la couche du dessous : **22 pavés**. Ramenée à 3, il en reste
**3**. Une liberté gagnée la veille se repaie le lendemain, et c'est exactement ce qu'un
changement de modèle révèle.

```
  sans transfert, amplitude 6 :  0 pave
  avec transfert, amplitude 6 : 22 paves
  avec transfert, amplitude 3 :  3 paves
```

**État livré : le transfert vit derrière `LADDER_CREST=surface`, l'échelle par défaut reste
verte sur les vingt-six couples.** On ne met pas un modèle rouge par défaut, même quand c'est
lui la cible — la règle du dépôt tient : *ce qui n'est pas garanti est interdit*.

**Le reste à faire, nommé** : décider **qui trace le haut du débord** — le bandeau, ou l'étage
enterré qu'on voit à travers. C'est la même question que partout, à un endroit que le modèle
n'avait jamais eu : entre deux **couches** d'une même case.

⚠ **Et il faudra un septième regard**, ou étendre I3 : tant qu'aucun invariant ne sait nommer
une frontière **entre couches**, ce défaut-là se compte mais ne se diagnostique pas.

### 29 · LE RECENSEMENT NETTOYÉ — ET IL DÉSIGNE UNE SEULE MUETTE STRUCTURELLE

Le premier relevé portait **quinze espèces mal étiquetées**. La cause est instructive : je
décidais « frontière ou arête intérieure » en **lisant la matière sur l'image**, des deux côtés.

⚠ **ET L'IMAGE EST ASSEMBLÉE, DONC ELLE MENT SUR CE QUI EST À MOI.** Là où une tuile est
coupée, on voit **la couche du dessous** : de part et d'autre d'une frontière sommet/face, le
pixel visible au bord est la même herbe enterrée. La matière ne peut donc pas trancher — c'est
au **modèle** de dire où le monde a un bord. Quatre cas, et ils suffisent :

```
  robe | robe    la roche est continue -> interieur   (sauf levres differentes : ARETE)
  robe | sommet  la roche s arrete      -> FRONTIERE
  sommet|sommet  frontiere si les etages different, interieur sinon
  quoi que ce soit | vide                -> FRONTIERE
```

**Résultat : 54 espèces de frontière, 18 intérieures, zéro fausse étiquette, et ZÉRO arête
intérieure portant un trait sur 147 994 occurrences.**

⚠ **ET LA SONDE A ÉTÉ ÉLARGIE PUIS REFUSÉE, PAR SA PROPRE MESURE.** Le banc sonde au **milieu**
du côté, et son commentaire dit pourquoi : le trait du nord traverse la tuile de part en part,
donc une sonde qui longe le bord ouest le prend pour une revendication de l'ouest. Essayé quand
même :

| sonde | muettes | dont la lèvre | ailleurs | fausses sur intérieures |
|---|---|---|---|---|
| milieu seul | 1 728 | 1 571 | **157** | **0** |
| milieu ± 1 | 1 696 | 1 539 | **157** | 3 144 |
| aux quarts | 1 570 | 1 413 | **157** | 12 050 |

⚠ **LES 157 NE BOUGENT D'AUCUNE DES TROIS.** Élargir n'en récupère aucune — ça ne déplace que
des occurrences de la lèvre, précisément celles que le trait perpendiculaire contamine. **Les
157 ne sont donc pas un artefact de sonde : ce sont de vraies frontières que personne ne
trace.** Et la sonde reste au milieu seul, celle du banc, pour sa raison.

### 29bis · UNE SEULE MUETTE STRUCTURELLE, ET C'EST LA LÈVRE

```
  sommet sud face:chapiteau  ->  1 571 muettes sur 3 060   (51 %)
```

**La lèvre au-dessus de sa propre falaise est muette une fois sur deux.** C'est la seule espèce
dont la muette soit structurelle, et c'est **exactement la frontière dont l'utilisateur avait
proposé le transfert** — *« la fermeture nord des robes se retrouve dans les tuiles de bord sud
des surfaces »*. Le recensement valide l'intuition par un chiffre : ce n'était pas une
préférence de dessin, c'était le seul défaut de propriété du modèle.

**Le reste, rangé et nommé :**

```
  LES 157 MUETTES HORS DE LA LEVRE
    32 / 2654   sommet est vide                   1,2 %
    48 / 3317   sommet contre sommet, marche      1,4 %
    71 / 3196   sommet contre face, laterale      2,2 %
     6 /   77   arete interne                     7,8 %
```

⚠ **Aucune espèce n'est muette PAR NATURE** — chacune est tracée dans 92 à 99 % de ses
occurrences. Ce ne sont donc pas des trous de conception mais des **cas particuliers à
l'intérieur d'espèces saines** : la forme d'un défaut qu'on trouve au pixel, pas à la règle. Ça
vaut mieux que l'inverse, et ça se traite séparément de la lèvre.

### 28 · LE RECENSEMENT DES FRONTIERES — ET L'ARÊTE INTERNE, QU'AUCUN INVARIANT NE RÉCLAME

*Né d'une question de méthode de l'utilisateur : « on ne risque pas de devoir refaire des
choses qui demanderont à leur tour de refaire des choses ? »* La réponse était **oui**, et elle
était en train de se produire sous mes doigts.

**Le cliquet, chiffré au moment où il repartait :**

| | tuiles de surface | dessins | I1 |
|---|---|---|---|
| crête au chapiteau | 64 | 36 | **0 extrémité** |
| crête transférée + bande de roche + 1 bit | **74** | **44** | **241 extrémités** |

Chaque déplacement de propriété créait une orpheline qu'on découvrait **une par une**, et
chacune se payait en tuiles. ⚠ **Deux tâtonnements ne se valent pas** : le ras et l'amplitude ne
déplacent **aucune propriété** — tâtonner là est réversible et ça a rendu un théorème plus une
liberté gratuite. Déplacer *qui trace* ne se tâtonne pas.

**D'où `tools/border_census.gd`** : pour chaque espèce de frontière que le modèle pose, combien
de tuiles la revendiquent.

⚠ **ET SON PREMIER RÉSULTAT EST DANS L'INSTRUMENT, PAS DANS LE DESSIN.** `_claims` fait
`continue` dès qu'une robe est en jeu, et son commentaire l'assume : *« tant que le banc ne sait
pas nommer les frontières d'une face, on n'y juge que le doublement »*. **Les 1 274 frontières
que I3 compte excluent toutes celles qui touchent une falaise** — exactement la famille qu'on
cherchait à réattribuer. C'est pour ça qu'il restait vert pendant que I1 explosait : il ne
regardait pas là.

⚠ **UNE ADJACENCE N'EST PAS UNE FRONTIÈRE**, et la première table le prouve par l'absurde :
elle comptait 788 « muettes » entre deux chapiteaux voisins, là où la roche est **continue** et
où zéro trait est la bonne réponse. On lit donc la **matière** sur l'image, au milieu du côté,
là où la sonde regarde. Une arête intérieure veut **zéro**, une frontière veut **un**.

### 28bis · L'ARÊTE INTERNE : 248 occurrences, 0 tracée, et tous les invariants verts

*Imposée à l'ordre du jour par l'utilisateur avant qu'on fixe quoi que ce soit : « il faut tout
de suite penser au tracé de l'arête interne qui descend des sommets, qui est moins formelle que
les autres et qui sera responsable de donner l'impression de relief ».*

Deux cases de face côte à côte qui ne pendent **pas de la même lèvre** ont de la roche des deux
côtés. Le recensement les nomme, et le compte est net :

```
  ARETE INTERNE : 25 especes, 248 occurrences, 0 TRACEE
  meme levre    : 16 especes, 6107 occurrences   (roche continue, rien a tracer)
```

⚠ **C'EST LA SEULE ESPÈCE QU'AUCUN INVARIANT NE RÉCLAMERA JAMAIS.** I1 ne voit pas de trou, I3
pas de frontière, I2 pas de pavé. **Tous verts, et le relief absent.** Les 34 autres espèces se
jugent seules ; celle-là ne peut être décidée qu'à l'œil — donc **avant** de figer, sans quoi on
la découvre à la fin et le cliquet repart.

⚠ **ET SANS ELLE, L'ARTISTE NE PEUT PAS LA DESSINER — pas « mal », pas du tout.** Une tuile de
robe est posée à des dizaines d'endroits : si le modèle ne distingue pas « j'ai une autre face à
ma droite » de « ma roche continue », l'arête qu'il trace apparaît **partout**, y compris au
milieu d'une paroi seule. C'est la loi du fragment, appliquée à lui.

**Qui porte l'angle — mesuré, pas supposé.** *« La face devant n'est-elle pas celle dont la
lèvre est à l'étage le plus haut ? »* Non :

```
  meme etage, levres decalees          190   52 %   l etage ne dit RIEN
  sud CONTRE haut                       81   22 %   les deux criteres se CONTREDISENT
  sud ET haut d accord                  26    7 %
  meme rangee, etages differents        66   18 %   la rangee ne dit RIEN
```

Là où les deux se prononcent, **ils se contredisent trois fois sur quatre**. Ce qui sépare est
la **rangée de la lèvre** : celle qui est plus au sud avance vers le regard, son bloc saille.
C'est déjà ce que disait la 9.0.0 — *« c'est la plus haute qu'on voit, dont la lèvre est plus au
nord : elle est en retrait, je suis devant »*.

⚠ **ET À ÉGALITÉ DE RANGÉE, C'EST LE PLUS HAUT — décision utilisateur, et elle corrige un
premier choix pris à l'écran.** Vu sur deux rendus, `personne` semblait mieux ; le raisonnement
a tranché autrement : *même rangée et étage différent, ce sont deux hauteurs 3D différentes,
donc il faut marquer l'arête à celle du haut.* L'image ne montrait pas la marche, elle existe.
Les deux conventions coûtent **exactement 44 rôles** — le choix est de lecture, jamais de prix.

⚠ **« PAS DE DOUBLE ARÊTE » EST UN INVARIANT, PAS UN GOÛT.** Faire tracer les deux voisines
donnerait un trait de deux pixels — ce que I2 compte comme pavé. Un seul trace, et c'est celui
qui avance.

⚠ **ET UNE DISTINCTION QUE L'ARTISTE NE VOIT PAS DANS SA TUILE N'EST PAS DESSINABLE.** J'avais
proposé une arête « au ras » qui aurait rendu le même dessin qu'un flanc `arrêt` : refusée par
l'utilisateur, et à raison — il les aurait peintes identiques, et la différence serait devenue
un mensonge. L'arête **ne coupe donc pas la matière, elle la marque** : la roche continue chez
la voisine et je pose seulement mon angle. Les deux se distinguent dans la tuile.

**Le prix, assumé : 20 → 44 rôles de robe**, sur 45 possibles. Et la famille cesse d'être
**fermée par construction** — le bit dit « ma voisine est en retrait », que je ne peux pas
déduire seul, donc c'est le modèle qui le pose et le vocabulaire redevient *cherché*, gardé par
la battue.

⚠ **Trois pièges payés, tous de la même espèce : une clé qui change de type.** Le banc
construisait encore la clé d'une robe à l'ancienne et demandait une tuile inexistante
(`get_width` sur null) ; `node()` faisait `Vector2i(key)` sur un `Vector3i` — **170 erreurs non
fatales, l'échelle verte quand même**, le genre de rouge qu'on apprend à ignorer ; et le nom
d'un nœud de raccord **doit porter l'arête**, un nœud désignant *un côté de tuile* et deux
tuiles qui ne diffèrent que par leur angle n'ayant pas le même bord là.

### 26 · L'ÉPAISSEUR CONTRAINT AUSSI LE DEHORS — LA BORNE HAUTE TOMBE DE 31 À 23

*Le cahier des charges du redessin nommait dix-huit dessins que le guide n'exerce pas. Huit
d'entre eux ne sont pas un manque du guide : ce sont des tuiles que le monde **ne peut pas
produire**. Trouvé en cherchant leurs témoins, pas en relisant.*

⚠ **LA PRÉMISSE DE `closed_form_now.py` ÉTAIT FAUSSE, ET ELLE ÉTAIT ÉCRITE EN TOUTES LETTRES**
dans son en-tête : *« l'extérieur étant libre sur un plan non borné, les deux valeurs sont
réalisables dès que la précondition tient »*. Vrai d'un plan quelconque. **Faux sous min
trois**, où l'épaisseur contraint aussi le dehors de la fenêtre.

**L'argument tient en trois pas, et il ne vaut qu'aux diagonales NORD :**

1. `NE` vide — donc, la canonicalisation l'enregistrant, `N` **et** `E` pleins — oblige la
   course de la rangée du nord à s'étendre vers l'**ouest**, faute de pouvoir aller à l'est.
   Donc **`NO` est plein** ;
2. un `NO` plein au-dessus d'un ouest **vide** est une **lèvre** : sa face couvre mon ouest ;
3. donc **`BORD_W` vaut un, toujours**. Et `ABOVE_W` comme `BELOW_W` exigent que je trace
   vraiment ce côté-là — ils tombent avec.

Le miroir vaut à l'est. ⚠ **Et aucun autre coin ne force** : une diagonale **sud** pleine ne
met aucune lèvre au-dessus de ma cardinale vide — une robe se pose *sous* une lèvre, jamais
au-dessus. La clause ne touche donc que quatre silhouettes : `s5` et `s29` à l'ouest, `s65` et
`s113` à l'est.

```
                                   avant     apres
  cles enumerees (borne haute)       125  ->   101
  DESSINS distincts                   31  ->    23
  ce que le guide n'exerce pas         18  ->    10
```

⚠ **ET C'EST CONTRÔLÉ DANS LE BON SENS, comme l'en-tête de l'outil l'exige.** Les **55 clés
réellement posées** par les cinq mondes — guide, planche, trois battues — tombent **toutes**
dans la forme resserrée : **0 hors**. *Une seule dehors, et c'est la transcription qui est
fausse, pas le monde.*

**Les huit qui tombent, nommés** : `s5,b0` · `s65,b0` · `s5,ABOVE_W` · `s65,ABOVE_E` ·
`s29,BELOW_W` · `s29,BELOW_W+ABOVE_W` · `s113,BELOW_E` · `s113,BELOW_E+ABOVE_E`.

⚠ **ET LA RECHERCHE SEULE N'AURAIT PAS SUFFI À LES RETIRER.** Quatre parts de battue ne les
ont jamais rencontrés — mais *une battue qui ne rencontre pas une tuile prouve qu'elle est
rare, jamais qu'elle est impossible*, et le dossier l'a déjà payé. Ce qui les retire est
l'**argument** ; la battue ne fait que le corroborer.

⚠ **UN DESSIN N'EST PAS UNE CLÉ, C'EST UN GROUPE DE CLÉS — et c'est ce qui décide.** Le
représentant affiché est la plus **petite** clé du groupe, pas la plus facile à produire :
conclure « impossible » sur lui seul condamnerait un dessin que l'une de ses autres clés rend
banal. Mesuré : `6291548` se lit `s92` — pour lequel `FLUSH_W` est impossible — mais son
groupe contient `s124`, où il ne l'est pas. Les huit retirés sont ceux dont **tout** le
groupe tombe.

**C'est le critère 3 du plan qui mord pour la première fois**, et par le bout qu'on n'avait
jamais fait bouger : *« il converge par les deux bouts — la borne basse monte quand on ajoute
des mondes, la haute descend quand on retire une fausse liberté »*. Jusqu'ici seule la basse
avait bougé.

⚠ **ET LE VOCABULAIRE PROUVÉ DEVIENT PLUS PETIT QUE CELUI QU'ON LIVRE : 23 dessins contre 27
silhouettes.** Le modèle qui *sait* ce que ses voisines tracent porte **moins** de tuiles que
celui qui l'ignore — parce que les bits de bord **fusionnent** autant de silhouettes qu'ils
en séparent (les trois bits sud, `8`, `16`, `32`, ne distinguent rien : 22, 6 et 22 fois).

### 26bis · LES TÉMOINS DE BORD : TROUVÉS, PAS DESSINÉS

Les dix qui restent ne naissent d'aucun accident nommé. `tools/brink_witnesses.gd` les
cherche, les découpe, et les **revérifie au milieu d'un champ de plaine** — le contexte où ils
seront posés, pas le vide où on les a coupés.

⚠ **LA FAMILLE ALIGNÉE NE LES PRODUIT PAS, ET C'EST MESURÉ : ses 19 683 reliefs, parcourus en
entier, n'en rendent AUCUN.** La raison est géométrique : ce qui manque demande une banquette
qui s'arrête **une** rangée au-dessus d'un bord, et un monde aligné sur trois ne s'arrête
qu'aux multiples de trois. **Les poses décalées sont indispensables** — le pinceau les pose,
donc elles sont du domaine — et ce sont elles, et elles seules, qui rendent les témoins.

⚠ **ET LA BATTUE DENSE DU BANC NE VAUT RIEN ICI.** Quatre cents gestes sur un cadre de vide
font un monde où presque tout est couvert par une robe : les bits de bord y sont partout, et
aucun agencement **net** n'y survit. Trois battues denses : **un** témoin sur dix-huit. Des
**terrasses** — des rectangles de trois à douze, posés sur de la plaine, l'étage zéro creusant
les ravins — les rendent par poignées.

⚠ **ET UN PROCESSUS N'UTILISE QU'UN CŒUR.** `PART=i/n`, comme `LADDER_SHARD` au banc : chaque
part cherche *les mêmes* dessins dans *sa* tranche de graines, une passe de fusion relit tous
les blocs, **recalcule ce qu'ils portent** — on ne croit pas une part sur parole — et fait le
recouvrement. Cinq parts sur six cœurs.

**Résultat : huit blocs portent les dix dessins**, le plus petit fait 8x23, le plus grand
20x26.

```
  avant les temoins : res://guides/epais.txt  ->  13 dessin(s) sur 23
  apres             : res://guides/epais.txt  ->  23 dessin(s) sur 23
```

### 26ter · LES TÉMOINS ENTRENT DANS LE GUIDE — décision utilisateur, et elle a été rectifiée

**Premier essai, refusé :** un guide à part, `guides/temoins.txt`, invisible du soft, pour ne
pas payer l'écran. L'utilisateur a tranché autrement, et l'argument porte plus loin que ce
guide-ci : *« le but du soft est de tout avoir en face de soi en même temps ; ce que je vends,
c'est la simplicité et l'intuitivité »*, puis *« ce que je veux, c'est le guide fini dans le
soft, et la possibilité pour l'acheteur de dessiner n'importe quel monde avec toute la liberté
qu'on a calculée, sans erreurs »*.

Les huit blocs entrent donc dans `epais.txt`, en **seconde réserve**, exactement comme les huit
témoins de rôle de robe. `guides/temoins.txt` et son bâtisseur sont **supprimés** : un seul
guide.

⚠ **ET LA SECONDE RÉSERVE N'EST PAS UN PAYSAGE, ELLE NE PRÉTEND PAS L'ÊTRE** — même statut, mot
pour mot, que la première : *« le paysage sert à juger le rendu ; la réserve sert à ce
qu'aucune tuile ne manque. Confondre les deux, c'était demander à un seul dessin d'être à la
fois beau et exhaustif. »*

⚠ **ET ELLE SE VÉRIFIE LÀ OÙ ELLE POSE, pas seulement là où elle a été trouvée.** Chaque clé
déclarée est retrouvée à la case où son bloc est stampé : un témoin découpé est juste dans
*son* contexte — au milieu d'un champ de plaine — et le guide en est un autre, où il a des
voisins à quatre cases. *La découpe ment* : on revérifie.

**Le prix, dit franchement** : le guide passe de **104x141 à 104x229**, donc la case rétrécit à
l'écran. C'est le prix de l'exhaustivité, et il est assumé — *un outil parfait ne peut pas ne
pas montrer une tuile*.

⚠ **ET C'EST CE PRIX QUI OUVRE LA QUESTION SUIVANTE, POSÉE PAR L'UTILISATEUR : deux MODES DE
DISPOSITION.** Un mode **paysage** — les accidents fondus dans des îles, pour juger le rendu —
et un mode **damier de spécimens** — un îlot par tuile, calculé, compact et exhaustif. C'est la
résolution de la double injonction qui déforme le guide depuis le début : *« demander à un seul
dessin d'être à la fois beau et exhaustif »*. Chacun ferait une chose, et bien.

⚠ **ET DEUX STYLES DE TRAIT, DEMANDÉS AVEC** : *straight lines* et *ondulated lines*. Ils
existent déjà dans le modèle — ce sont **F1** et **F2** — et le compte de dessins **ne bouge pas
entre les deux** : 31 dans les deux cas, mesuré. C'est donc un vrai style, gratuit en
vocabulaire ; il ne reste qu'à l'exposer dans la liste des encres, à côté de *Peint* et *Fil de
fer*.

**Mesuré sur le guide fini, un seul fichier :**

```
  res://guides/epais.txt : 23 dessin(s) sur 23   -- RIEN NE MANQUE
  contour : I1 fermeture ok (0 extremite), I2 epaisseur ok (0 pave)
  batisseur : 0 probleme -- epaisseur, 27/27 surfaces, 25/25 roles,
              15/15 croisements, zero robe hors grille, tout hors plaine,
              et chaque cle de bord retrouvee a la case ou son bloc est stampe
```


### 25 · LE PORTAGE : LE BANC REND SON MODÈLE ET SON PINCEAU AU PRODUIT

Deux déplacements, aucun changement de pixel — c'est même la définition de l'opération, et le
rejeu en est la preuve.

| | avant | après |
|---|---|---|
| `proof/ladder.gd` | 3 785 | **2 864** |
| `render/contour_tiles.gd` — le **dessin** | — | **691** |
| `core/brink.gd` — le **modèle** | — | **435** |

**LA COUPURE EST CELLE QUE LE PORTAGE A SERVI À TRACER**, et elle vaut plus que les lignes
déplacées :

- **`core/brink.gd` — ce qu'une tuile doit SAVOIR.** Les sept bits de bord et leurs constantes,
  `surface_open` (quels côtés une clé trace), `closed_roles` (une chute qui s'arrête pose son
  pied), `foot_above`, `draws_side`, et `mark()` — les clés de tout un relief, étage par étage.
- **`render/contour_tiles.gd` — ce qu'elle DESSINE.** Les profondeurs, les pinçages, `shape`,
  l'ergot, et les deux rendez-vous de la famille à cheval.
- **`proof/ladder.gd` — ce qu'on MESURE.** Les mondes, l'assemblage, les six invariants, les
  battues, la forme fermée.

⚠ **ET `core/` NE DOIT RIEN À `render/`, DANS CE SENS-LÀ SEULEMENT.** `surface_open` et les bits
étaient partis avec le pinceau au premier déplacement ; c'était faux, ce sont des questions de
**modèle**. Ils sont redescendus dans `core/`, et le rendu les lit — l'inverse aurait mis une
règle du modèle dans un fichier de rendu.

⚠ **CE QUI A RENDU LES DEUX DÉPLACEMENTS SÛRS EST UNE MESURE FAITE AVANT D'Y TOUCHER** : les blocs
du pinceau n'appelaient **aucune** autre fonction du banc et ne lisaient que six variables de
réglage. Le modèle, lui, en dépendait de dix — toutes nommées, toutes parties avec lui.

⚠ **ET LES ROUTES REFUSÉES RESTENT JOIGNABLES**, dans les deux modules : `meet`, `half_axis`,
`ergot_diag`, `j2_on_face`, `astride`. *Un chiffre qu'on ne peut plus reproduire n'est plus un
chiffre.* Le banc les pose, le produit les laisse à leur défaut.

**La preuve** : rejeu des vingt-six couples, trois parts en parallèle, `l'échelle tient` sur les
trois — deux fois, une par déplacement. Et la suite du produit passe ses **665 vérifications**,
dont celle qui refuse un script qui ne s'analyse pas.

⚠ **TROIS PIÈGES DE LANGAGE PAYÉS, TOUS À LA POSE :** une déclaration `static var _level` renommée
en `static var Contour.level` — le renommage avait suivi jusque dans la déclaration ; une
dédentation de deux tabulations là où le corps en voulait une, qui rendait les commentaires du
corps non indentés ; et deux constantes de modèle (`STEPS`, puis les préchargements de `Walls` et
`HeightMask`) restées derrière. Aucun n'a survécu au premier chargement — **le compilateur est ici
le meilleur des rejeux, et il coûte deux secondes.**

### L'ÉCRAN EST LÀ : LE PRODUIT DESSINE LE CONTOUR PROUVÉ, ET IL EST FERMÉ

Troisième et dernier morceau sorti du banc : **l'assemblage** — les classes de raccord, les tuiles
de surface, les robes, les poses arrière, l'empilement étage par étage. `render/contour.gd`, 461
lignes, avec une entrée que le produit appelle : `compose(relief, 3, 1)`.

| | avant | après |
|---|---|---|
| `proof/ladder.gd` | 3 785 | **2 535** |
| `core/brink.gd` — le **modèle** | — | 435 |
| `render/contour_tiles.gd` — le **dessin** | — | 691 |
| `render/contour.gd` — l'**assemblage** | — | **461** |

**Et il produit l'image, sans une ligne de `proof/`** :

```
=== LE CONTOUR PROUVE, PAR LE PRODUIT ===
  guide epais.txt  ->  1664 x 2256 px, F1, 1304 ms
  13124 cases visibles, 53 tuiles de surface, 1394 cases de falaise

  I1 fermeture   ok    0 extremite(s)
  I2 epaisseur   ok    0 pave(s) 2x2
```

⚠ **LES 53 TUILES SONT EXACTEMENT LE COMPTE DU BANC SUR LE MÊME MONDE**, et c'est le seul contrôle
qui rende la seconde orchestration sûre. Deux chemins d'une même chaîne finissent toujours par
diverger ; celui-ci est mesuré, pas supposé.

⚠ **`compose()` NE SERT QUE LA FAMILLE PAR CASE.** La famille à cheval pose ses surfaces sur le
croisement de quatre cases : c'est un autre monde de tuiles, et le banc le mesure encore seul. Ce
qui est chez le produit est ce que le logiciel livre.

**Ce qui reste** : le branchement dans l'éditeur — le fond du guide, l'export, le plugin — et le
redessin du guide, dont le cahier des charges est nommé à la section 23.

### 24 · MESURER LE PRODUIT, PAS LE BANC — ET CE QU'ON APPREND EN ESSAYANT

`proof/ladder.gd` prouve un **modèle** : il peint ses propres tuiles avec son propre pinceau.
**Rien de ce qu'il établit n'est vrai du logiciel tant qu'on ne l'a pas mesuré SUR le logiciel.**
D'où `tools/soft_invariants.gd`, qui rend l'illustration de `render/guide_image.gd` — celle que
l'acheteur regarde en peignant, et celle dont l'essai tire son tileset — et lui pose les deux
questions qui ne dépendent d'aucun modèle : I1 fermeture, I2 épaisseur.

⚠ **ET LA PREMIÈRE RÉPONSE EST QUE LA QUESTION NE SE POSE PAS ENCORE.** Le fil de fer du produit
n'est **pas un tracé d'un pixel** :

```
encre WIRE_EDGE :  12 167 px,  5 616 paves de son propre 2x2   ⚠ BANDE
encre WIRE_LIP  :  10 069 px,      1 pave
encre WIRE_FACE :   8 410 px,      0 pave
```

`WIRE_EDGE` est une **bande de deux pixels** — le flanc de la falaise — et non un contour. Compter
ses pavés reprocherait au dessin d'être ce qu'il est : les 5 617 pavés du premier relevé étaient
un artefact de ma définition, **pas un défaut du produit**. L'outil déclare donc chaque encre
avant de compter, et **refuse** quand l'une est posée en bande.

**C'est le résultat utile** : le logiciel ne pourra pas être validé par ces invariants tant qu'il
ne dessinera pas un contour d'un pixel — et c'est exactement ce que le portage du modèle apporte.
L'instrument existe maintenant, et il dira le jour où ça bascule.

⚠ **DEUX PIÈGES DE MESURE PAYÉS, TOUS DEUX SUR LA MÊME LIGNE DE CODE.**
- `is_equal_approx` compare à 1e-5 près, or une constante écrite `0.588` ressort d'un PNG à
  `150/255 = 0,58824` — **vingt fois l'epsilon**. Le compteur annonçait **zéro** pixel de trait sur
  une image qui en porte trente mille ;
- puis `Image.set_pixel` **tronque** au lieu d'arrondir — `0,588 × 255 = 149,94` devient **149** —
  alors que le rendu du produit, qui passe par une réduction, écrit **150**. Une même couleur
  s'écrit à un pas près selon le chemin qui la pose.

La comparaison se fait donc **à un pas près**, et la tolérance est justifiée par la mesure : la
paire la plus proche des neuf couleurs diffère de **sept** sur un canal. *Une tolérance qu'on n'a
pas vérifiée là-dessus est un compteur de plus à qui l'on fait confiance sans raison.*

⚠ **ET LA COPIE DU PRÉDICAT SE CONTRÔLE, PARCE QUE C'EN EST UNE.** `--verifier <png>` transcrit une
image **du banc** dans la palette du produit et la fait compter par ce compteur-ci. Sur une image
que le banc dit fermée : **0 et 0**. Sur une image que le banc disait à **4 extrémités et 19
pavés** : **4 et 19**, aux mêmes pixels. *Deux copies d'une même règle finissent toujours par se
contredire — sauf si on les confronte.*

⚠ **ET LES DEUX FOIS OÙ LE COMPTEUR S'EST TU, C'EST LA GARDE DE NON-VACUITÉ QUI A PARLÉ.** « Aucun
trait : la palette a changé, la mesure ne veut rien dire » — sans elle, les deux pièges ci-dessus
auraient rendu **zéro extrémité, zéro pavé**, c'est-à-dire un logiciel déclaré parfait par un
instrument aveugle.

### 23 · LA FORME FERMÉE, PEINTE : 125 CLÉS, **31 DESSINS**

C'est le nombre qu'on cherchait depuis le début du serrage, et il se calcule en deux temps —
chacun avec l'outil qui existe déjà, sans en écrire un troisième :

1. `tools/closed_form_now.py --liste` **énumère** les clés que le modèle peut exiger ;
2. `LADDER_FORM=<liste> proof/ladder.gd -- L3 F1` les **peint** et compte les images distinctes.

| | |
|---|---|
| clés énumérées (borne haute du modèle) | **125** |
| **dessins distincts** (ce que la planche doit porter) | **31** |
| rencontrés sur le guide | 24 |
| rencontrés sur la planche de preuve | 19 |

⚠ **ET LE COMPTE NE BOUGE PAS ENTRE F1 ET F2** : 31 dans les deux cas. Le trait droit et le trait
qui serpente distinguent exactement les mêmes tuiles — la liberté du peintre n'ajoute pas de
vocabulaire, ce qui est précisément ce que I5 promettait et qu'aucun chiffre n'avait encore dit.

**LES 31, NOMMÉS.** Dix sont des silhouettes nues, vingt et une portent des bits :

```
   nues       5  7  20  65  71  80  92  193  197  199
   ABOVE      s65 s193                          (est)   s5 s7      (ouest)
   FLUSH      s20 s92   (est)   s80 s92 (ouest)   s92   (les deux)
   BELOW      s80 s113 s209 (est)   s20 s23 s29 (ouest)   s80 (les deux)
              s113 s209 (est + above)   s23 s29 (ouest + above)   s20 (ouest + flush)
```

⚠ **ET LES 27 SILHOUETTES NE FONT QUE DIX DESSINS.** C'est le résultat qui surprend, et il se
démontre : depuis L2, `open[2]` est faux **inconditionnellement** — *rien au sud* — et `_reentrant`
saute les deux coins sud. Le cardinal **S** et les diagonales **SE** et **SO** sont donc absents du
dessin, et les 27 index canoniques, quotientés par ces trois bits, tombent à **dix formes** :
`{4, 5, 7, 64, 65, 68, 71, 193, 197, 199}`. Vérifié dans les deux sens — la sonde du banc désigne
exactement ces trois bits (`8 ×22, 16 ×6, 32 ×22`) et rien d'autre.

⚠ **ET UN BIT S'EST RESSERRÉ EN CHEMIN, DÉSIGNÉ PAR LA MESURE : `ABOVE_*`.** Il ne fait qu'une
chose — ramener le bord latéral au ras à son premier pixel — donc si le **bord** a déjà fait taire
ce côté-là, il ne change plus rien. Sa précondition rejoint celle de `BELOW_*`, qui est la même un
cran plus bas et qui, elle, l'avait toujours. **139 → 125 clés, 31 dessins inchangés**, et le guide
perd 4 clés posées (51 → 47) sans perdre un dessin.

⚠ **ET LE CONTRÔLE A ATTRAPÉ MA PREMIÈRE VERSION, DANS LE BON SENS.** J'avais resserré
l'**énumération** — ajouter la précondition à `closed_form_now.py` — et quatre clés posées par le
guide sont aussitôt tombées **hors de la forme**. C'est le monde qui avait raison : la règle
appartient au **banc**, l'énumération ne fait que la transcrire. *« Une seule dehors, et c'est la
transcription qui est fausse, pas le monde »* — la ligne était dans l'en-tête de l'outil, et elle
a servi le jour même.

### CE QUE LE GUIDE EXERCE : TREIZE DESSINS SUR TRENTE ET UN

`LADDER_SEEN=<sortie de LADDER_VOCAB=1>` croise un monde avec la forme, et rend **les dessins que
ce monde ne touche nulle part**. Sur le guide livré :

```
47 cles posees,  13 dessins sur 31 touches
LUI MANQUE (18) :
   5(s5,b0)         65(s65,b0)                       -- deux silhouettes NUES
   524353(s65,ABOVE_E)     1048581(s5,ABOVE_W)
   2097172(s20,FLUSH_E)    4194384(s80,FLUSH_W)      6291548(s92,FLUSH_E+W)
   8388688(s80,BELOW_E)    8388721(s113,BELOW_E)     8388817(s209,BELOW_E)
   8913009(s113,BELOW_E+ABOVE_E)  8913105(s209,BELOW_E+ABOVE_E)
   12582992(s80,BELOW_E+W)
   16777236(s20,BELOW_W)   16777245(s29,BELOW_W)
   17825815(s23,BELOW_W+ABOVE_W)  17825821(s29,BELOW_W+ABOVE_W)
   18874388(s20,BELOW_W+FLUSH_E)
```

⚠ **ET DEUX D'ENTRE ELLES SONT DES SILHOUETTES NUES.** Le guide porte bien les 27 index — la suite
du produit l'assère — mais il ne les porte jamais **sans bit** : `s5` et `s65` n'y apparaissent
qu'accompagnées. *Porter une silhouette n'est pas porter la tuile.*

**C'est le cahier des charges du redessin**, nommé tuile par tuile au lieu d'être deviné : dix-huit
accidents à composer, et la liste dit exactement lequel force quel bit.



⚠ **ET LES GRAINES DE RACCORD VALENT ZÉRO DANS CE COMPTE, IL FAUT LE DIRE.** Les classes de L4
sont une propriété du **monde** — l'union-find se calcule des adjacences observées — alors que la
forme fermée est une propriété du **modèle**. Deux clés qui rendent la même image ici peuvent
différer dans un monde qui les met dans deux classes. **31 est donc le vocabulaire de FORMES**, pas
le nombre de cases d'une planche donnée.

### 22 · « POSÉE » N'EST PAS « DISTINCTE » — LE COMPTE ANNONCÉ TOMBE ENCORE D'UN TIERS

Le plan avait déjà corrigé un compteur une fois : *« `vocabulary` est nourri à chaque passe, et
rien ne l'y retire — 59 peintes pour 45 posées »*. Il en restait un cran : **deux clés qui peignent
la même image sont une seule tuile.** Le peintre la dessine une fois, la planche en porte une case.

⚠ **ET ON COMPARE LES PIXELS, PAS LES BITS.** Chercher les bits inertes demanderait de redémontrer,
bit par bit, quand la précondition tient — c'est-à-dire de redériver le calcul qu'on contrôle. Le
banc rend les images et les compare, comme tout le reste.

| monde | peintes | posées | **dessins** |
|---|---|---|---|
| **par case** (L3/F2) | | | |
| planche | 49 | 45 | **19** |
| guide | 57 | 51 | **24** |
| `@battue1` · `2` · `3` | 42 · 45 · 37 | 40 · 41 · 36 | **18 · 16 · 14** |
| **à cheval** (L5/F2) | | | |
| planche duale | 40 | 40 | **31** |
| guide | 50 | 50 | **40** |
| `@battue1` · `2` · `3` | 59 · — · — | 59 | **44 · 46 · 44** |

⚠ **ET C'EST LE NOMBRE LE PLUS CITÉ DU PROJET QUI BOUGE.** « 58 surfaces + 20 rôles » est un compte
de **clés** ; le compte de **dessins** est 24 au plus haut sur les cinq mondes. Le facteur n'est pas
un détail de comptage : c'est la différence entre ce que la planche porte et ce que le modèle
distingue.

⚠ **ET LA SONDE A ÉTÉ FAUSSE DEUX FOIS AVANT D'ÊTRE JUSTE**, ce qui vaut d'être écrit :
- elle accusait **tous** les bits d'une paire, alors que trois bits qui se compensent ne prouvent
  rien sur chacun — seule une paire qui ne diffère **que** par un bit le prouve ;
- puis elle comparait les clés **sans la silhouette**, et annonçait « le bit 2 ne distingue rien »
  sur la paire `255 / 543` — deux silhouettes différentes. Le fait est vrai et intéressant (*une
  silhouette dont on tait le seul côté ouvert devient la tuile pleine*), mais ce n'est pas un bit
  inerte : c'est une **collision**, et les confondre envoie retirer un bit qui sert.

### CE QUI EST RÉDUCTIBLE, ET OÙ LA DÉMONSTRATION S'ARRÊTE

**Acquis, et démontré : l'aplat.** Une tuile à cheval dont les quatre quadrants sont pleins est un
carré de matière — aucun pixel n'y a de voisin vide, il n'y a pas un trait, et ni l'axe ni les
silences n'y changent quoi que ce soit. Les garder dans la clé fabriquait **jusqu'à trente-deux
tuiles pour un seul aplat**. **48 → 40 clés sur la planche, 58 → 50 sur le guide, 67 → 59 sur la
battue**, les six invariants verts.

**Refusé, et c'est la mesure qui a tranché : l'étendue asymétrique.** `vx >= half - 1` et
`hy >= half - 1` toujours, donc les colonnes `0..half-1` sont **toujours** à l'ouest et les rangées
`0..half-1` **toujours** au nord — d'où, *pour la matière* : bit 1 inerte si NO == NE, bit 4 si
NO == SO, les deux autres sous les deux conditions. **40 → 34 clés sur la planche, dessins
inchangés… et I2 passe de 0 à 9 pavés.**

⚠ **LA RAISON BORNE TOUTE RÉDUCTION FUTURE : un bit ne décide pas que la matière, il décide aussi
SI LE RENDEZ-VOUS EXISTE.** `steps` vaut *« exactement une des deux moitiés se tait »* : retirer un
bit inerte pour la matière fait **apparaître** une marche là où il n'y en avait pas. **Un bit n'est
retirable que s'il est inerte pour TOUT ce que la tuile en fait** — et l'aplat est le seul cas où
on sait le démontrer.

⚠ **ET UN MASQUAGE ENCORE PLUS NAÏF — « un silence ne se pose que là où SA demi-frontière
existe » — est pire** : 48 → 31 clés, mais **37 extrémités et 35 pavés**. C'est exactement
l'étendue que le raisonnement oubliait.

⚠ **ET J'AI MESURÉ DEUX FOIS LE MÊME CODE.** Le correctif de l'étendue a échoué sur une assertion
de son script de pose, et j'ai lu les chiffres d'avant en croyant lire ceux d'après — *« un
correctif qui ne change RIEN n'est pas un correctif faible, c'est un correctif qui n'a pas été
appliqué »*, la ligne était au dossier depuis la veille. Ce qui l'a attrapé est la relecture du
fichier, pas la lecture du chiffre.

### 21 · L5 EST CLOS — CINQ MONDES, SIX INVARIANTS, ET LE RENDEZ-VOUS N'EST PLUS QU'UNE RÈGLE

**Les six invariants sont verts sur les cinq mondes, aux trois libertés.** Il ne reste aucun
couple rouge sur l'échelle.

| à L5/F2 | tuiles de croisement | I1 | I2 | I3 |
|---|---|---|---|---|
| planche duale | 84 → **48** | ✅ | ✅ | ✅ |
| guide | 84 → **58** | 6 → ✅ | 8 → ✅ | 42 → ✅ |
| `@battue1` | 81 → **67** | 4 → ✅ | 19 → ✅ | 40 → ✅ |
| `@battue2` | — → **66** | ✅ | 6 → ✅ | ✅ |
| `@battue3` | — → **66** | ✅ | 10 → ✅ | ✅ |

**1. IL N'Y A PLUS QU'UN RENDEZ-VOUS, ET IL LIT LES PIXELS AU LIEU DE LA SILHOUETTE.** Les deux
blocs — l'original et son miroir — étaient la même règle vue de deux côtés, chacun avec sa
condition tirée de la silhouette : `north_split` pour l'un, `south_split` pour l'autre. Le second
laissait passer la **forme 14**, dont le pinçage creuse un **trou de 3×3 au milieu de la tuile** :
ses deux moitiés sud sont pleines, donc `south_split` est faux, et pourtant la marche est là.

**La règle juste ne parle pas de silhouette du tout** : *le pinçage remet la moitié muette sur le
bord de case et laisse l'autre libre, donc la matière de la rangée `half - 1` surplombe le vide de
la rangée `half`* — et un surplomb, ça se trace. On demande donc à la tuile ce qu'elle a **peint** :
de la matière ici, du vide juste dessous. **4 extrémités sur le guide et 2 sur `@battue1`,
fermées ; I1 et I3 verts sur les cinq mondes.**

⚠ **DEUX CONDITIONS TIRÉES DE LA SILHOUETTE, DEUX FOIS FAUSSES — ET LA TROISIÈME NE LA REGARDE
PLUS.** C'est la même leçon que l'ergot qui redérivait « qui trace de quel côté » : *ce qu'on peut
lire dans le résultat ne se déduit pas une seconde fois de l'entrée.*

**2. LE CINQUIÈME BIT : DE QUEL CÔTÉ EST LE CHAPITEAU. +3 TUILES, ET LES 26 PAVÉS TOMBENT.**
Il restait 10 · 6 · 10 pavés sur les trois battues, tous de la même signature — la marche longe la
**crête au ras** du chapiteau d'en dessous, une rangée plus bas. Quatre routes mesurées avant de
payer :

| tentative | I1 | I2 |
|---|---|---|
| la marche s'arrête une colonne plus tôt | ✅ 0 | 10 |
| la marche seulement dans le cas miroir | **36** (planche) | ✅ 0 |
| resserrer le pincement de la crête à cheval | **25** | 8 |
| **le bit : le chapiteau est-il à l'EST ?** | ✅ **0** | ✅ **0** |

⚠ **ET LE BIT DIT EXACTEMENT CE QUI MANQUAIT, NI PLUS.** Quand le chapiteau est à l'**est**, sa
crête au ras couvre déjà les colonnes de la marche : le contact est direct, il n'y a **rien à
marcher**. Quand il est à l'**ouest**, sa crête ne couvre pas ces colonnes-là et la marche doit
aller jusqu'au bord de case toucher son coin en diagonale. Le bit de silence, lui, est un **OU**
— une robe sur l'une **ou** l'autre — et ne pouvait pas trancher.

⚠ **ET IL NE SE POSE QUE LÀ OÙ IL CHANGE QUELQUE CHOSE** : seulement quand exactement une des deux
moitiés verticales se tait, c'est-à-dire quand le rendez-vous existe. **Prix : +3 tuiles** sur
chacun des cinq mondes. Posé partout il aurait doublé la clé pour rien — la leçon déjà payée deux
fois (*+5 tuiles à poser un bit en gros, +0 au bon endroit*).

⚠ **ET LE RESSERREMENT DU PINCEMENT EST RÉFUTÉ, CE QUI APPREND QUELQUE CHOSE.** L'idée était juste
sur le papier : `first = _depth(3, 0)` vaut 4, c'est la traversée de la famille **par case**, qui
n'existe pas à L5 — donc la crête est plate sur cinq colonnes pour rien. Réduite aux deux colonnes
du bord, `@battue1` passe de 0 extrémité à **25**. *Le plat de la crête est ce sur quoi retombent
les bords latéraux des tuiles à cheval*, et il en porte bien plus qu'une marche.

### 20 · CLORE L5 : LA CARTE DES ROBES ÉTAIT ÉCRITE DEUX FOIS, ET LA SONDE REGARDAIT DE BIAIS

La planche duale est verte aux trois libertés ; le **guide** et **`@battue1`** ne le sont pas.
Ce qui suit est le premier tour de la clôture, sur `@battue1` — 40×45, une minute par mesure,
donc le monde où l'on itère.

| sur `@battue1` | I1 | I2 | I3 |
|---|---|---|---|
| départ | 4 extrémités | 19 pavés | **14 doubles, 26 muettes** |
| + la sonde qui regarde chez la voisine hors du monde | 4 | 19 | **26 doubles**, 2 muettes |
| + la carte des robes à une seule source | 4 | 14 | **0 double**, 2 muettes |
| + le rendez-vous s'arrête une colonne plus tôt | **4** | **10** | 0 · 2 |

Et le même jeu de correctifs sur le **guide**, qui n'a servi à aucun réglage :

| sur le **guide** (104×141, 84 tuiles à cheval) | I1 | I2 | I3 |
|---|---|---|---|
| départ | 6 extrémités | 8 pavés | 29 doubles, 13 muettes |
| après les trois | **6** | ✅ **0** | ✅ **0 double**, 9 muettes |

⚠ **I2 EST VERT SUR LE GUIDE, ET LES DOUBLEMENTS ONT DISPARU DES DEUX MONDES.** Ce qui reste est
d'une seule espèce : des frontières que **personne** ne trace, et les extrémités qui vont avec —
neuf muettes sur le guide dont **huit d'affilée sur une même rangée**, deux sur la battue.

**6. UN PIED REPOSÉ NE TRACE RIEN, ET LE BIT AFFIRMAIT LE CONTRAIRE.** La sonde a nommé les deux
muettes de la battue en une lecture : le croisement se taisait au nord parce qu'un **pied reposé**
occupe la case du dessus. Or `mute` — la conception que I6 a choisie à L3 — c'est *la matière SANS
son contour*. **Un bit de silence dit « quelqu'un d'autre trace » ; posé sur une pose arrière, il
énonce une chose fausse.** Le dossier portait pourtant la note inverse — *« un pied reposé compte
autant qu'un pied visible, il trace son bord bas au même endroit »* — écrite avant que L3 ne
tranche, et jamais relue depuis. *Une règle survit à sa justification*, la troisième fois cette
semaine.

| | tuiles à cheval | I1 | I2 | I3 |
|---|---|---|---|---|
| **planche** | 64 → **45** | ✅ 0 | ✅ 0 | ✅ 0 · 0 |
| **guide** | 84 → **55** | 6 → **4** | ✅ 0 | 9 muettes → ✅ **0** |
| **`@battue1`** | 79 → **64** | 4 → **2** | 10 | ✅ 0 · 0 |

⚠ **I3 EST VERT SUR LES TROIS MONDES, ET LE VOCABULAIRE TOMBE D'UN TIERS.** C'est le critère 3 du
plan qui se vérifie tout seul : *un bit dont les deux valeurs ne sont pas toutes deux réalisées
gonfle la borne sans distinguer quoi que ce soit.* Celui-là ne distinguait pas — il mentait — et il
coûtait **19 tuiles sur la planche**. La famille à cheval y livre désormais **45 + 20 = 65** tuiles
là où elle en demandait 84.

Joignable par `LADDER_UNDERFOOT=trace`, comme trace de la mesure.

**1. LA CARTE DES ROBES ÉTAIT ÉCRITE DEUX FOIS, ET C'EST LA FAUTE QUE LE DOSSIER RÉPÈTE À
CHAQUE PAGE.** Une chute qui s'arrête pose son PIED, quelle qu'en soit la raison — c'est la
substitution qui ferme ce qu'on voit de la face. Elle était appliquée à la carte qui **dessine**
les robes… et pas à celle que lisent les **bits de silence à cheval**, qui repartait de
`Walls.visible()`. La tuile de robe posait donc son bas — pied substitué — pendant que la tuile
à cheval, croyant avoir un **corps** au-dessus, traçait la même frontière. **26 doublements, tous
étiquetés `falaise`, et ils tombent tous les vingt-six.**

⚠ **MÊME ESPÈCE QUE `_check_wall_seams` QUI REDÉRIVAIT `row_for`, ET QUE LES DEUX VOCABULAIRES DE
SURFACE AVANT `core/families.gd`.** *Deux copies d'une même règle finissent toujours par se
contredire, et celle qui se tait est celle qu'on ne regarde pas.* Il y a maintenant une fonction,
`_closed_roles`, et deux appelants.

**2. LA SONDE D'I3 NE REGARDAIT PAS CHEZ UNE VOISINE HORS DU MONDE.** « Pas de case là » n'est pas
« pas de pixels là » : l'image, elle, couvre toute la grille. Le garde `beyond >= 0` confondait les
deux — et **à cheval ça se paie**, parce que l'axe d'une tuile de croisement se déplace **au-delà**
du bord de case : le trait d'une frontière contre le vide est peint DANS le carré de la case vide.
**26 fausses muettes**, pour un trait parfaitement présent à deux pixels de là.

⚠ **ET ÉLARGIR UNE SONDE NE PEUT QUE RENDRE LA MESURE PLUS SÉVÈRE, JAMAIS PLUS COMPLAISANTE.** On
ajoute un revendiquant possible : une muette peut devenir juste, et une juste peut devenir
**double**. C'est exactement ce qui s'est passé — 14 doubles annoncés, 26 réels — et c'est ce qui a
mis la faute n° 1 sous les yeux. *Corriger l'instrument avant de corriger le dessin*, sans quoi on
corrige au juge. Le rejeu des vingt-deux couples reste vert : dans la famille par case, où le trait
ne rentre que chez lui, la sonde élargie ne trouve rien de plus.

**3. LA CLASSIFICATION DES MOITIÉS DEPUIS L'AXE EST RÉFUTÉE UNE SECONDE FOIS**, et cette fois sur un
monde réel, avec le pinçage et le rendez-vous en place — c'est-à-dire dans les conditions où le
premier refus pouvait être caduc. Elle ne l'est pas :

| sur `@battue1` | I1 | I2 |
|---|---|---|
| moitiés au milieu de la tuile (gardé) | **4** | **10** |
| moitiés depuis l'axe, sans rendez-vous | 20 | 18 |
| moitiés depuis l'axe, avec | 14 | 33 |

L'idée était bonne à énoncer : les rangées 8 et 9 d'une tuile dont le quadrant nord descend
jusqu'à `hy = 9` appartiennent encore au **nord**, et se taisent sur le bit du **sud**. Elle reste
fausse à la mesure. Joignable par `LADDER_HALF=axe`.

**4. LE RENDEZ-VOUS S'ARRÊTE UNE COLONNE AVANT LE BORD DE CASE.** Lu au pixel : la marche est peinte
à la rangée `half - 1`, et **le chapiteau d'en dessous trace sa crête au ras** aux colonnes qui
bordent la case — `_wall_depth` s'y pince à zéro. Les deux traits se retrouvent donc collés,
rangée contre rangée. Le raccord n'a jamais eu besoin d'aller jusqu'au bord : le contact **en
diagonale** avec le coin du chapiteau suffit. **14 → 10 pavés, et la planche ne bouge pas.**

⚠ **ET CE QUI RESTE EST LA MÊME COLLISION, UNE COLONNE PLUS LOIN.** Le pinçage de la crête n'est pas
« les deux colonnes du bord » mais `along <= first`, avec `first` tiré de… `_depth(3, 0)`,
c'est-à-dire de la **famille par case, qui n'existe pas à L5**. Le prochain coup est là : les points
de pincement d'une robe doivent être les traversées de la famille de surface **du niveau**, et à
cheval ce ne sont pas les mêmes. C'est la loi déjà écrite pour `_wall_depth` — *« un bord de face
touche le bord de sa case aux deux traversées canoniques de la famille perpendiculaire »* — jamais
relue depuis que la famille a changé.

**5. LE ROBINET, PARCE QU'UN CORRECTIF DONT ON NE SAIT PAS CE QU'IL COÛTE N'EST PAS MESURÉ.**
`LADDER_MEET=none|orig|miroir|both` débranche les deux rendez-vous. Sur `@battue1`, avant les
correctifs ci-dessus :

| | I1 | I2 |
|---|---|---|
| `none` | 12 | 5 |
| `orig` | 5 | 19 |
| `miroir` | 11 | 5 |
| `both` | 4 | 19 |

**Le miroir ferme une extrémité et ne coûte aucun pavé ; c'est l'original qui en coûte quatorze.**
Sans ce robinet on aurait accusé le miroir, qui venait d'être écrit.

⚠ **ET UNE SONDE DE CROISEMENT, `LADDER_PROBE=i,j`**, qui dit les quatre cases, leur étage, la robe
qui les couvre et sa lèvre, puis la clé à cheval de chaque étage avec ses quatre silences en clair.
Trois hypothèses de suite avaient été fausses sur le même pixel — lire l'image dit **où** le trait
est, la sonde dit **pourquoi**. C'est elle qui a nommé la faute n° 1 en une lecture.

### 19 · LES QUATRE SONT FERMÉES : LE RENDEZ-VOUS AVAIT UN MIROIR, POSÉ À LA MAUVAISE RANGÉE

**L5 est vert sur la planche duale, aux trois libertés, et ça ne coûte AUCUNE tuile** — 64
croisements + 20 rôles, exactement comme avant.

| | I1 | I2 | I3 | I4 | I5 | I6 |
|---|---|---|---|---|---|---|
| **L5/F0** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **L5/F1** | ✅ **0** (parti de 43) | ✅ | ✅ | ✅ | ✅ 1 profil plat déplacé | ✅ |
| **L5/F2** | ✅ **0** (parti de 91) | ✅ | ✅ | ✅ | ✅ 6 profils, 29 qui serpentent | ✅ 35 px |

**Ce qui manquait, et c'était une ligne.** Le rendez-vous avec la crête n'existait que dans un
sens — *la moitié nord trace, la sud se tait*. Le sens inverse avait été posé, mesuré à
« **il ne peint aucun pixel** », et abandonné sur cette mesure. **Le chiffre était juste et la
conclusion fausse** : le miroir avait été posé à la rangée `half`, la **première de la moitié
qui trace**, où les colonnes du bord sont effectivement vides. La marche, elle, est une rangée
plus haut.

⚠ **ET LA MARCHE EST TOUJOURS À LA MÊME RANGÉE, C'EST UN THÉORÈME ET NON UNE COÏNCIDENCE.** Le
déplacement de l'axe est **signé** — vers l'est, toujours — et le pinçage remet la moitié muette
sur le bord de case. Donc :

```
matiere a l OUEST, moitie libre au NORD    rangee 7 : x <= 9      rangee 8 : x <= 7
matiere a l EST,   moitie libre au SUD     rangee 7 : x >= 8      rangee 8 : x >= 10
```

Dans les deux cas la matière qui **n'a plus rien sous elle** est aux colonnes 8 et 9 de la
rangée **`half - 1`** — les deux mêmes pixels. On trace le bord de la matière, jamais le vide :
le miroir se pose donc exactement où se pose l'original, et la seule chose qui change est de
quel côté de l'axe la matière se trouve.

**Lu au pixel avant d'écrire une ligne**, sur `L5 F1 … 3 46 5 5 160` — le même cadrage que la
veille, et le PNG est **identique à l'octet** d'une exécution à l'autre :

```
        7777777777888888888
        3456789012345678901
   766  RRRRRRR#ggggggggggg     le flanc de la robe s arrete a x=79
   767  ##RRRR#####gggggggg     sa derniere rangee : le trait est au ras, x=79
   768  gggggggggggg#gggggg     le trait de la tuile a cheval commence a x=82  <-- extremite
   769  gggggggggggg#gggggg
```

Les colonnes 80 et 81 de la rangée 767 portent la matière de la tuile ; **rien ne les traçait**,
et les trois pixels d'écart se lisaient comme un trait qui meurt. Après le miroir, la même
lecture au même cadrage :

```
   766  RRRRRRR#ggggggggggg
   767  ##RRRR#########gggg     +2 pixels, et le contour descend en escalier
   768  gggggggggggg#gggggg
```

**Deux pixels par occurrence, quatre occurrences, zéro tuile.** Le contour passe du flanc de la
robe à `x=79`, marche à `80–81`, puis `x=82` : c'est la frontière du monde, dessinée par les deux
familles chacune sur sa grille, et raccordée là où l'une passe la main à l'autre.

⚠ **ET C'EST LA MÊME LEÇON QUE CELLE DÉJÀ ÉCRITE POUR L'ERGOT ENTERRÉ : IL FAUT REGARDER CE QUE
LE CORRECTIF NE FAIT PAS.** « Il ne peint aucun pixel » aurait dû faire chercher *pourquoi il n'a
rien trouvé à peindre*, pas conclure que la géométrie l'interdit. Un correctif qui ne peint rien
est un correctif **mal posé** avant d'être un correctif impossible — c'est le jumeau exact du
piège noté la veille au même endroit : *« un correctif qui ne change RIEN n'est pas un correctif
faible, c'est un correctif qui n'a pas été appliqué »*.

⚠ **ET L'ARGUMENT QUI L'AVAIT ENTERRÉ ÉTAIT VRAI, MAIS D'UNE AUTRE RANGÉE.** Le dossier disait :
*« quand la matière est à l'est, les colonnes du bord sont VIDES dans la tuile — il n'y a rien
sur quoi peindre »*. C'est exact **à la rangée 8**, et faux à la rangée 7. Une observation juste
attachée au mauvais endroit ferme une piste aussi bien qu'une observation fausse.

### CE QUE LA SECTION 18 DISAIT — l'état d'où l'on est parti

Départ : **43 à F1, 91 à F2**, I6 rouge (35 matières perdues), I5 non tenu. **Zéro tuile
ajoutée** — 64 croisements + 20 rôles, comme avant.

**Les quatre corrections gardées, dans l'ordre où elles ont mordu :**

1. **LE RENDEZ-VOUS AVEC LA CRÊTE** (43 → 7). Le trait vertical d'une tuile à cheval descend
   à l'axe déplacé ; la crête du chapiteau qui doit le fermer vit sur la grille des CASES.
   Lu au pixel : trait à x=97, crête à x=95. Le raccord se pose à la dernière rangée
   **visible** — pas là où la matière s'arrête, qui est déjà sous la robe.
2. **LE PINÇAGE** (7 → 4 à F1, 91 → 4 à F2). *Décision utilisateur : c'est une RÈGLE.* Une
   tuile à cheval déplace librement une frontière qu'elle porte SEULE ; elle n'a jamais eu le
   droit de déplacer celle qu'elle PARTAGE avec une autre famille, qui vit sur la grille des
   cases et ne peut pas suivre.
3. **I5 RELU EN CONSÉQUENCE** — le profil ne mesure que l'axe que la tuile POSSÈDE, il est
   REPLIÉ (suite des positions distinctes, pas une par rangée), et une ligne qui change de
   côté de l'axe perpendiculaire ne se profile pas. ⚠ Le garde-fou est intact : la part
   possédée doit rester UN profil, PLAT, et DÉPLACÉ.
4. **LE ROGNAGE DE LA POSE ARRIÈRE À CHEVAL** (I6 : 35 perdues → 0, fenêtre toujours à 35).
   `_clip_north` rognait contre `tiles[storeys[cell]]` — or à L5 `storeys` est indexé par
   CROISEMENT. Les deux familles partagent le type `Vector2i`, donc la clé existait et la
   roche était rognée contre une tuile décalée d'une demi-case. `_astride_cover` reconstruit
   ce qui couvre vraiment la case : les quatre quarts des quatre tuiles de croisement.

**LES QUATRE QUI RESTENT, entièrement caractérisées.** Tuile **86** = index 6 (les deux
quadrants EST pleins) + silences vertical-nord et horizontal-ouest. Pixel `(10,8)` en repère
de croisement, aux quatre mêmes endroits, **identique à F1 et à F2** — donc structurel, pas un
accident du dessin. Le trait est le bord OUEST de la matière EST ; il commence à la coupe
`RES/2` et rien ne l'y rejoint.

⚠ **Et le rendez-vous ne peut pas les atteindre, c'est démontré et non supposé.** Le
déplacement de l'axe est SIGNÉ (+2) : quand la matière est à l'ouest, le trait a de la matière
sous lui et peut revenir au bord de case ; quand elle est à l'est, les colonnes du bord sont
VIDES dans la tuile — il n'y a rien sur quoi peindre. Le miroir a été posé et mesuré : il ne
peint aucun pixel, 7 avant, 7 après.

**Trois pistes essayées et refusées par la mesure, à ne pas rejouer :**

| | |
|---|---|
| classification des moitiés depuis l'AXE | 46 à F1 — elle ANNULE le rendez-vous |
| la même, PAR-DESSUS le rendez-vous | 46 — idem |
| la RANGÉE DE PASSAGE pincée du côté libre | **53** à F1, 35 pavés, I5 rouge |

⚠ **Et `RES / 2` est juste, ce que trois mesures ont fini par dire ensemble** : ce n'est pas
« le milieu de la tuile », c'est **le bord de case en repère de tuile**. La moitié qui se tait
passe la main à une ROBE, qui vit sur la grille des cases : la coupe doit être sur cette
grille-là. **Une frontière partagée avec une autre famille se coupe ET se pose sur la grille
de cette famille.**

**DEUX PIÈGES DE MÉTHODE PAYÉS DEUX FOIS CHACUN, ce soir :**

⚠ **Un correctif qui ne change RIEN n'est pas un correctif faible : c'est un correctif qui
n'a pas été appliqué.** Deux fois j'ai mesuré 4 extrémités aux mêmes pixels après un
changement, et deux fois j'ai cherché la cause dans la logique au lieu de vérifier que le code
tournait. Les causes étaient (a) deux copies de la formule de l'axe, dont une seule modifiée,
et (b) une réécriture qui a **effacé** l'édition précédente.

⚠ **Remplacer un intervalle entre deux ancres supprime tout ce qui est au milieu.** Vérifier
que les ancres sont uniques ne dit RIEN de ce que l'intervalle contient. C'est comme ça que
l'extension de `_corner_axis` a disparu sans un message d'erreur.

**Ce qu'il restait à faire sur L5** : fermer les quatre — fait, voir la section 19. La consigne
d'alors s'est vérifiée mot pour mot : *« la prochaine idée devra venir de l'image, pas du
raisonnement »*. `proof/ladder.gd -- L5 F1 <png> 3 46 5 5 160` régénère le cadrage.

**Ce qu'il restait à faire sur L5** : le **clore**, c'est-à-dire le rejouer sur les autres
mondes, comme L2 et L3 l'ont été — **fait, voir la section 21**. La planche duale est bâtie pour exercer le
*vocabulaire* à cheval ; elle n'exerce pas les *rencontres*. **Mesuré aussitôt, et c'est rouge :**

| monde à L5/F2 | tuiles à cheval | I1 | I2 | I3 |
|---|---|---|---|---|
| **planche duale** | 64 | ✅ 0 | ✅ 0 | ✅ 0 double, 0 muette |
| **guide** (104×141) | **84** | **6 extrémités**, toutes noyées | **8 pavés** | **29 doubles, 13 muettes** |
| **`@battue1`** (40×45) | **81** | **4 extrémités** | **19 pavés** | **14 doubles, 26 muettes** |

⚠ **ET LA DISTRIBUTION DIT DÉJÀ OÙ CHERCHER, SANS AVOIR RIEN OUVERT.** Les huit pavés du guide
sont **tous** « robe, rien dessous », et **tous** au pixel `(0,15)` ou `(1,15)` — le coin
**bas-gauche** d'une tuile de robe. Les vingt-neuf doublements y sont tous étiquetés
`double (falaise)`. Sur la battue, quatorze des dix-neuf pavés sont « surface, chapiteau
reposé », les cinq autres « robe, rien dessous », aux coins `(15,15)` et `(0,15)`.

**C'est la rencontre des deux grilles, et elle était annoncée** : *« les surfaces sont décalées
d'un demi-pas ; les robes restent sur la case, donc toutes les jonctions surface/falaise sont à
cheval »*. La planche duale ne la met presque jamais en scène ; le guide et la battue, si.

⚠ **ET LE VOCABULAIRE À CHEVAL N'EST PAS LE MÊME D'UN MONDE À L'AUTRE — 64, 81, 84.** Les quatre
bits de l'issue B se combinent avec les quinze formes ; ce que chaque monde exerce dépend de ses
rencontres, pas de son vocabulaire de formes (15/15 partout). C'est la même leçon que pour les
surfaces par case, où l'union de cinq mondes donnait 77 sans être une forme fermée.

### 17bis · LE GUIDE REDESSINÉ SERA À MI-TUILE — décision utilisateur

⚠ **Le guide doit se dessiner à la DEMI-TUILE, parce que c'est la seule échelle où la liberté
vagabonde se voit.** L'axe d'une tuile à cheval est posé sur le croisement de quatre cases ;
sa liberté est un déplacement latéral de cet axe. Un guide calé sur la grille des cases ne
montre donc jamais où l'axe a le droit d'aller — il montre les cases, pas les frontières
qu'elles se partagent. À mi-tuile, le vagabondage de l'arête est visible dans le guide
lui-même, donc dessinable et jugeable.

C'est à porter au cahier des charges du redessin, avec les accidents à composer un par bit.

### 17 · REDESSINER LE GUIDE : TROIS ROUTES, TROIS ÉCHECS, ET LA MÊME CAUSE

| route | ce qu'elle produit | verdict |
|---|---|---|
| famille **alignée** (blocs 3×3) — 879 316 reliefs | 40 tuiles | sous-domaine : 19 tuiles des mondes livrés n'en sortent pas |
| **vivier 7×5** exhaustif — 297 340 reliefs | 29 tuiles | fenêtre trop étroite : moins que le guide actuel |
| **témoins découpés** dans le guide — 51 fenêtres 9×15 | 40 / 51 visées | **25 découpes sur 51 refusées comme FINES** |

⚠ **ET LES TROIS ÉCHOUENT POUR LA MÊME RAISON : je bâtis le guide DE L'EXTÉRIEUR** — en
énumérant des reliefs ou en découpant des fenêtres — alors que la méthode du dépôt, celle qui
marche, le bâtit **par accidents**. `tools/build_epais.gd` compose des formes nommées — district
lacustre, sablier, moulins, défilé, gorge décalée, tour du cap, éperons doubles — et
**s'auto-vérifie** : épaisseur, 27/27, 23/23, 15/15, zéro robe hors grille.

⚠ **LA DÉCOUPE MENT, ET LE CHIFFRE LE DIT : 11 des 51 tuiles visées DISPARAISSENT** quand on
coupe autour d'elles, et 4 autres apparaissent. Le bord de la fenêtre devient du vide : le
voisinage change, donc la tuile change. C'était écrit dans l'en-tête de l'outil avant d'être
mesuré — *« le contrôle n'est pas optionnel, il EST la mesure »* — et il a mordu du premier coup.

**Ce qu'il faut faire à la place, et c'est petit :** pour chaque bit qu'un guide doit exercer —
`bordE/W`, `NQ`, `diagNO/NE`, `aboveE/W`, `flushE/W`, `belowE/W` — **dessiner UN accident qui le
force**, et l'ajouter au générateur qui existe. C'est exactement ce qui a été fait quand la
famille duale a réclamé le **contact diagonal** : un accident de plus, nommé, vérifié, et le
guide couvrait 15/15.

⚠ **Et c'est la leçon de méthode de la soirée** : *le vocabulaire se réduit par la mesure, le
guide se construit par le dessin.* Les deux moitiés du chantier ne se traitent pas avec les mêmes
outils, et j'ai passé trois routes à essayer de mesurer ce qu'il fallait dessiner.

---

# LE MODÈLE DES MASSIFS — l'état au 2026-09-02, et par où reprendre

⚠ **Ce qui suit remplace le modèle du contour prouvé.** Tout ce qui précède dans ce fichier reste
vrai *comme histoire* — les six invariants, les échelles L/F, les mesures — mais le vocabulaire
décrit plus haut (bits de bord, pans, rangées de corps, poses arrière) n'est plus celui du
produit. Le nouveau modèle vit **à côté** de l'ancien : rien du produit n'est encore branché
dessus, et l'ancienne suite reste verte.

## Le modèle, en cinq phrases

Un **MASSIF** est un blob complet et autonome : une **SURFACE** et sa **FALAISE**. Il existe
entièrement, y compris sous ce qui le recouvre — un chevauchement n'est que de l'**occlusion par
ordre de rendu**, donc le voisinage d'une tuile ne dépend jamais de ce qu'on pose dessus. Les
massifs sont **emboîtés** : un massif d'étage L est une composante connexe des cases de niveau
**au moins** L, et la plaine est le massif d'étage 0. Une tuile est le couple **(silhouette de
l'EMPREINTE, BANDE)** — l'empreinte étant surface ∪ falaise, la bande valant SURFACE, CHAPITEAU,
CORPS ou PIED. Et il ne reste **qu'un bit de contexte** : suis-je **AU RAS** ?

## Les quatre règles qui ont coûté cher à trouver

1. **AU RAS SEULEMENT EN CAS DE CHEVAUCHEMENT.** Un massif entièrement entouré par celui qui le
   porte garde toute sa liberté — son contour ne longe que de la matière. Ce qui force le ras,
   c'est *une partie dedans, une partie dehors* : là, deux contours décrivent le même endroit
   sans pouvoir se concerter, et leur seul rendez-vous commun est la bordure de tuile.
2. **LA CHUTE VA JUSQU'AU SOL QU'ELLE ATTEINT.** Un étage vaut trois rangées ; la face cherche le
   premier palier `j` tel que le sol, `3j` rangées plus bas, soit `j` étages sous la lèvre. Sans
   palier elle tombe dans le vide et **ne pose pas son pied**. La sonde regarde **sous** le pied,
   jamais les rangées traversées.
3. **LA MARGE DE PIED.** Aucun PIED ne touche par le sud un CHAPITEAU : les deux tracent à une
   rangée d'écart et leurs traits se collent. Aucune tuile ne peut le rattraper sans un bit de
   contexte, donc on paie en grammaire — une rangée de surface porteuse visible sous le pied.
4. **LA PROFONDEUR ZÉRO EST IMPOSSIBLE POUR UN MASSIF LIBRE.** À zéro, deux massifs voisins ont
   leur contour sur la même ligne et le tracent tous les deux. La liberté n'est pas un ornement,
   c'est ce qui les sépare : F0 vaut un pixel.

## Les fichiers

```
core/massifs.gd            les massifs, l empreinte, les poses, la cle d une tuile, la marge de pied
core/massif_form.gd        la forme close : 2^18 fenetres, leurs temoins, l ilot etire
core/massif_witnesses.gd   GENERE -- les blocs trouves pour ce que la fenetre ne porte pas
render/massif_tiles.gd     le dessin d une tuile : (silhouette, bande, au ras) x liberte
render/massif_scene.gd     l image d un relief -- rien a assembler, l ordre de pose fait tout
proof/massif_ladder.gd     LE BANC : I1 I2 I6 I7 I8, sur le guide et des reliefs tires au sort
tools/build_massifs.gd     LE GUIDE : un ilot par tuile, calcule, reverifie dans le guide assemble
tools/massif_witnesses.gd  la chasse aux temoins (PART=i/n, puis --fusion)
tools/preview_massifs.gd   l image, pour la regarder (GUIDE= F= GRILLE=)
guides/massifs.txt         le guide, 160x176, 52 ilots
```

## Les commandes

```
godot --headless --path . --script res://proof/massif_ladder.gd -- 25
godot --headless --path . --script res://tools/build_massifs.gd -- res://guides/massifs.txt
GUIDE=res://guides/massifs.txt F=1 GRILLE=1 godot --headless --path . --script res://tools/preview_massifs.gd -- sortie.png 2
PART=0/4 godot --headless --path . --script res://tools/massif_witnesses.gd -- 250
godot --headless --path . --script res://tools/massif_witnesses.gd -- --fusion
```

## Les cinq invariants du banc

| | |
|---|---|
| **I1 FERMETURE** | aucune extrémité ouverte — rien ne pend dans le vide |
| **I2 ÉPAISSEUR** | aucun pavé 2×2 entièrement de trait |
| **I6 VÉRITÉ** | aucun pixel de fond là où le monde a de la matière (cases dont les **huit** voisines sont de la matière) |
| **I7 UNICITÉ** | deux tuiles ne rendent jamais la même image |
| **I8 FORME** | toute tuile posée est dans la forme close |

**Vert au 2026-09-02** : F0/F1/F2 à 0/0/0 sur 37 436 poses ; I7 54 tuiles pour 54 dessins ; I8
zéro hors forme ; guide 160×176 avec **52/52 tuiles peignables**, 0 case fine, 0 faute de marge
de pied, 0 îlot qui ne porte pas sa tuile.

## CE QUI RESTE, DANS L'ORDRE — et c'est l'ordre que l'utilisateur a fixé

1. **La grammaire** — chiffrer les clauses candidates avant de bâtir quoi que ce soit. Elle n'a
   **pas** été faite : les 79 → 52 viennent de ce qu'on sait *porter*, pas d'une clause.
   Candidate la plus prometteuse : *une jupe ne retombe jamais sur le massif qui la lance*, qui
   tuerait une bonne part des silhouettes de PIED.
2. **Les îlots** — fait. Le guide porte 52/52, calculé, revérifié dans le guide assemblé.
3. **Le dessin** — l'utilisateur regarde et valide. C'est le cran où on en est.
4. **LE PORTAGE — FAIT (2026-09-03).** L'éditeur, `work_io` (v5), `Families`, l'export
   (`exporters/massif_tileset.gd`, manifeste **v9**), l'essai (`exporters/massif_trial.gd`), la
   planche packed, le mode d'emploi (dont le niveau 3, lu à la source du nouveau contrat), et
   **le plugin SoluPaint**. `Walls`, `Coverage`, `CornerIndex`, `Brink*`, `Thickness` ne sont
   plus lus par le produit : ils vivent comme **témoins**, avec `guides/epais.txt`, jusqu'au
   démontage.

## LE PLUGIN, PORTÉ — ce qu'il est devenu et ce qu'il a coûté

- **`addons/solupaint/rules.gd`** est la copie du modèle des massifs sur un monde **non borné**
  (`Dictionary` case → étage, l'absence valant le VIDE) : composantes emboîtées, empreinte,
  chute qui cherche son palier, le seul bit de ras, plus l'épaisseur et le pincement pour le
  pinceau. Les 683 lignes de l'ancien vocabulaire sont parties avec lui.
- **UNE COUCHE PAR ÉTAGE** remplace les trois de l'ancien modèle (sous-pied, surface, falaises).
  Deux poses d'une même case ont forcément des étages différents — à un étage donné une case
  n'appartient qu'à une composante — donc empiler par étage croissant rend exactement ce que
  rend la liste triée. Il n'y a plus de couche de falaises à part : la jupe d'un massif est sur
  la même couche que sa surface, **parce que c'est le même massif**.
- **UNE SEULE PLANCHE, UNE SEULE SOURCE D'ATLAS.** Manifeste **v9** ; la v8 est refusée
  nommément. Deux constantes lisibles par programme y entrent — `fall_rows` et `tiles` — parce
  qu'un moteur doit pouvoir REFUSER sans lire de la prose.
- ⚠ **LA ZONE À REFAIRE N'EST PLUS SOUTENABLE, et c'est le vrai prix du modèle.** Un massif est
  une composante connexe, et « au ras » est une propriété du massif **entier** : poser une case
  peut réunir deux massifs ou faire déborder un porté, et alors tout son contour change de règle
  d'un bout du monde à l'autre. Une zone bornée laisserait le monde faux pendant qu'on le
  dessine, sans rien signaler. On repose donc tout — **3 ms sur 16x16, 14 sur 32x32, 75 sur
  64x64, 209 sur 96x96**. Un calcul incrémental est possible ; il n'est pas écrit.
- ⚠ **UNE POSE PERDUE SE DIT** (`last_warning`, distinct de `last_error`). « Une case n'a qu'une
  pose par étage » est un théorème **sous min trois** ; l'inspecteur peut le violer.
- **Le contrôle croisé, dans les deux sens** : 256 voisinages, **4 096** reliefs binaires 3x4,
  **19 683** reliefs 3x3 à trois états — le vide en est, et c'est lui qui distingue les
  modèles —, le guide livré, et **400** reliefs 9x9 troués tirés au sort. Zéro divergence, et la
  battue rencontre les 39 tuiles.
- **La chaîne entière, sur le vrai travail peint** (`tools/chain_massifs.gd`) : 39 tuiles relues,
  0 rendues, 39/39 livrées, export, relu par le lecteur DU PLUGIN, **29 109 poses, 0 sans tuile**.
- **Suite : 685 vérifications, 0 échec.** Elle en portait 13 rouges depuis le portage du noyau.

## Les pièges déjà payés, pour ne pas les repayer

- **`COVERS` valait 256, c'est-à-dire exactement `CHAPITEAU << 8`** : le bit de contexte et la
  bande se mélangeaient dans la même clé, et le rapport annonçait deux fois la même tuile pour
  deux tuiles différentes.
- **Un générateur qui jette tout relief fin ne rendait que 15 mondes sur 1 500.** On répare, on
  ne refuse pas — comme le pinceau : 245.
- **Une tuile EST son dessin.** Au ras la profondeur est nulle, donc rien ne se creuse, pas même
  les coins rentrants : une tuile au ras ne dépend que de ses quatre cardinaux. 13 tuiles sur 55
  rendaient une image déjà rendue.
- **Le rendez-vous libre n'est pas pile à la moitié** — à `RES/2` la coupe d'un côté et le
  creusement d'un coin rentrant se complètent exactement ; à `RES/2 − 1` une jupe d'une colonne
  ne garde que deux pixels. Il en faut trois : bord, centre, bord.
- **Le rendez-vous est un segment plat, pas un point**, sinon la discrétisation isole le pixel du
  coin, et un pixel de trait isolé est une extrémité.
- **Le vide d'un bloc témoin est du vide, pas de la plaine** : sept témoins sont des corps de
  chute qui n'atterrit pas, et les combler leur rend un sol.
- **`get_string_from_ascii()` s'arrête au premier octet nul** — et un pixel transparent en est
  un. Une sonde d'unicité annonçait 27 scènes distinctes sur 42 en ne comparant qu'un préfixe
  vide. Comparer en base64.
- **Le socle d'un îlot au ras ne doit PAS l'entourer**, sinon l'îlot devient un massif entièrement
  entouré — donc libre — et les tuiles au ras disparaissent du guide en silence.

## Les 27 tuiles hors de portée

La forme close en énumère 79 ; 52 sont portées par le guide. Les 27 autres demandent qu'un massif
**s'entrelace avec lui-même à une colonne près** — une anse ouverte au nord rencontrant une anse
ouverte au sud. Ni 450 reliefs épais tirés au sort, ni la construction par échine ne les
produisent. ⚠ **« Rare » ne veut pas dire « impossible »** et on ne les jette pas sur ce motif ;
mais la règle 5 tranche l'autre sens — une tuile sans îlot est une tuile que personne ne pourra
peindre, donc un trou dans le jeu. Elles restent au fichier avec leurs fenêtres, refusées au
pinceau tant qu'un témoin ne sera pas trouvé. C'est réversible ; livrer 79 tuiles dont 27
impeignables ne le serait pas.


---

# LE CISAILLEMENT — l'état au 2026-09-04, et par où reprendre

⚠ **LA SUITE EST ROUGE : 681 vérifications, 30 échecs, et ils ont TOUS la même cause.** Le
vocabulaire compte **62 tuiles**, le guide n'en porte que **54** : l'export refuse donc une
feuille incomplète (c'est la règle), et manifeste, TileSet, essai et découverte tombent en
cascade derrière. Ce n'est pas trente défauts, c'en est **un**.

## Ce qui a été fait

**LE CISAILLEMENT EST DANS LE MODÈLE.** Relevé par l'utilisateur sur le **massif 21** du guide,
en regardant SON trait remonté — pas le dessin calculé, qui est la spécification et a donc
toujours l'air juste. De l'herbe et de la roche du **même massif**, côte à côte : la silhouette
se lit sur l'EMPREINTE, donc chacune avait son bit mis, se croyait pleine, et rendait la tuile
d'intérieur qui se répète partout. Personne ne traçait la frontière — la roche s'arrêtait NET.

- **`Massifs.CUT_WEST` (bit 17) et `CUT_EAST` (bit 18)**, lus sur l'**empreinte du massif**,
  jamais sur la carte visible : un massif se dessine entier, son identité ne peut pas dépendre
  de ce qu'on pose dessus. ⚠ Jamais les deux à la fois — min trois l'interdit, et l'énumération
  exhaustive le confirme (zéro fenêtre sur 2^18).
- **Le dessin** : la roche trace son trait (loi de la lèvre, couchée sur le côté), l'herbe prend
  une **ombre**. ⚠ Un seul des deux trace, sinon deux traits dos à dos font le pavé 2×2 qu'I2
  refuse. Et **la lumière tranche** : un cisaillement est un corps d'angle, l'arête s'éclaire à
  l'ouest et s'ombre à l'est — sans quoi `CORPS 255 cisaillé ouest` rendait exactement
  `CORPS 21 au ras`, et I7 le disait.
- **Le plugin suit**, contrôle croisé vert. **Manifeste v10**, la v9 refusée nommément.
- **Le banc est VERT** : I1 I2 I6 I7 I8 I9, 50 dessins pour 50 tuiles.
- **Le guide rebâti** : 152×278, 274/274 jonctions, 0 îlot qui ment, LEGAL.

## ⚠ ET LA VRAIE LEÇON N'EST PAS LE CISAILLEMENT, C'EST LA BATTUE

Le recenseur ne battait **qu'au hasard**, et le hasard ne fabrique presque pas de bords sud en
marches — la forme qui produit un cisaillement. En lui donnant le guide et une famille de
marches, **9 tuiles de base sont apparues** qui existaient depuis toujours. *Une battue qui ne
cherche pas là où ça se trouve n'a pas cherché.*

## CE QUI RESTE, ET C'EST UNE SEULE CHOSE

**Huit tuiles sont dans le vocabulaire et absentes du guide** — elles n'ont ni fenêtre
d'énumération ni témoin :

    SURFACE 223 libre · CORPS 1 libre · CORPS 7 libre · CORPS 17 libre
    CORPS 193 libre · CORPS 199 libre · CORPS 209 libre · PIED 21 au ras

Ce sont toutes des tuiles **de base**, pas des cisaillées. La chasse (`tools/massif_witnesses.gd`,
`PART=i/n` puis `--fusion`) est passée de 41 à 58 témoins sur 128 sans les attraper.

⚠ **ET LA CAUSE EST CONNUE : deux battues qui ne partagent pas leur vivier.** Le recenseur les a
rencontrées dans SES mondes ; le bâtisseur tire les SIENS. Deux copies d'une même recherche
finissent par diverger, exactement comme deux copies d'une règle. **Le prochain cycle est de leur
donner la même source de mondes** — ou de faire écrire au recenseur ce que le bâtisseur sait
porter, jamais plus.

⚠ **Et la fusion de la chasse ne relit pas le fichier existant** : elle réécrit à partir des
seules parts. Elle a crû cette fois (41 → 58), mais rien ne le garantit — c'est la même faute que
le recenseur a déjà corrigée chez lui (« la liste ne peut que croître »). À réparer.

## Ensuite, et seulement ensuite

- **Le second mode de guide : un vrai paysage** plutôt qu'une planche de spécimens. Il est
  **borné à sa propre recherche** — il ne touche ni le modèle, ni la clé, ni le dessin, ni le
  plugin, et le carnet range par TUILE donc un travail se recharge d'un mode à l'autre. ⚠ **À une
  condition, et c'est toute la raison de ce cycle** : le vocabulaire doit être CLOS avant. Sinon
  un paysage révélerait de nouvelles tuiles — c'est précisément ce qui vient d'arriver avec les
  marches — et le cycle repartirait.
- **La version : 11.0.0**, majeure. Le sens de la clé a changé.
