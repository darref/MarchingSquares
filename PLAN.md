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
| **L0/F0** | **✅ acquis** | monde 86×174, 1 347 cases, **27/27 silhouettes exercées** · I1 42 contours pour 42 massifs · I2 0 pavé 2×2 · I3 1 086 frontières, 0 double, 0 muette, 0 parasite · I4 0 trou · I5 1 profil, 1 promis |
| L0/F1 | à faire | |
| L0/F2 | à faire | |
| L1/F0… | à faire | |

```
godot --headless --path . --script res://proof/ladder.gd            (tout l'acquis)
godot --headless --path . --script res://proof/ladder.gd -- L0 F0   (un couple)
```

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
