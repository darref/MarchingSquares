# SoluTiles — contexte de travail

## Contexte

Outil desktop de génération de tilesets autotile, écrit en Godot 4 / GDScript.

Principe du produit : l'utilisateur peint un paysage par-dessus un guide fixe affiché en
transparence derrière une grille. L'outil en extrait un tileset autotile complet et l'exporte.
Aucun pixel n'est composité, miroité ou généré : tout ce qui sort a été peint à la main. Le
guide est un artefact conçu en amont, à la fois lisible et prouvé mathématiquement complet.

## Charte du produit

Ces règles arbitrent toutes les décisions techniques.

1. **On dessine, on ne configure pas.** Aucun panneau de réglages, aucun curseur. Si un
   comportement demande un paramètre, c'est qu'on s'y est mal pris.
2. **Un seul passage, du début à la fin.** Pas de boucle essai-export-correction.
3. **Rien n'est fabriqué à la place de l'utilisateur.** Pas de composition de fragments,
   pas de miroir, pas d'IA.
4. **L'exactitude se prouve, elle ne se promet pas.** Couverture vérifiée par programme.
5. **Ce qui n'est pas garanti est interdit.** Le pinceau refuse les configurations non
   couvertes.
6. **Le résultat est visible pendant le travail, pas après.**

## Où vit quoi

- **`PLAN.md` gouverne l'ordre du travail.** Sa **dernière section** — « LE MODÈLE DES
  MASSIFS » — est l'état courant et la liste de ce qui reste. Tout ce qui précède dans ce
  fichier est de l'**histoire** : vrai comme récit, périmé comme spécification.
- **`ARCHIVE.md`** est l'ancien `CLAUDE.md`, gardé entier le jour où il a été compacté
  (2026-09-03). On y va pour retrouver *pourquoi* une règle a été prise et ce qu'elle a
  coûté — jamais pour appliquer une règle telle quelle. En cas de contradiction, ce
  fichier-ci gagne.
- **`CLAUDE.md`** (ici) : la charte, le modèle du jour, les lois qui tiennent, les pièges
  déjà payés, et rien d'autre.

## LE MODÈLE DES MASSIFS

Un **MASSIF** est un blob complet et autonome : une **SURFACE** et sa **FALAISE**. Il existe
entièrement, y compris sous ce qui le recouvre — un chevauchement n'est que de l'**occlusion
par ordre de rendu**, donc le voisinage d'une tuile ne dépend jamais de ce qu'on pose dessus.
Les massifs sont **emboîtés** : un massif d'étage L est une composante connexe des cases de
niveau **au moins** L, et la plaine est le massif d'étage 0. Une tuile est le couple
**(silhouette de l'EMPREINTE, BANDE)** — l'empreinte étant surface ∪ falaise, la bande valant
`SURFACE`, `CHAPITEAU`, `CORPS` ou `PIED`. Et il ne reste **qu'un bit de contexte** :
suis-je **AU RAS** ?

Clé d'une tuile : `COVERS | (bande << 8) | silhouette`, `COVERS = 1 << 16` (`Massifs.key`).
Au ras, seuls les quatre cardinaux comptent — la profondeur y est nulle, donc rien ne se
creuse, pas même les coins rentrants.

**Les quatre règles qui ont coûté cher à trouver :**

1. **AU RAS SEULEMENT EN CAS DE CHEVAUCHEMENT.** Un massif entièrement entouré par celui qui
   le porte garde toute sa liberté — son contour ne longe que de la matière. Ce qui force le
   ras, c'est *une partie dedans, une partie dehors* : là, deux contours décrivent le même
   endroit sans pouvoir se concerter, et leur seul rendez-vous commun est la bordure de tuile.
   ⚠ Et **la plaine ne compte pas comme chose recouverte** (décision utilisateur) : sans cette
   clause tout massif recouvrirait quelque chose, donc tout serait au ras, et on perdrait la
   liberté qu'on cherche précisément à montrer.
2. **LA CHUTE VA JUSQU'AU SOL QU'ELLE ATTEINT.** Un étage vaut trois rangées (`FALL = 3`) ;
   la face cherche le premier palier `j` tel que le sol, `3j` rangées plus bas, soit `j`
   étages sous la lèvre. Sans palier elle tombe dans le vide et **ne pose pas son pied**. La
   sonde regarde **sous** le pied, jamais les rangées traversées.
3. **LA MARGE DE PIED.** Aucun PIED ne touche par le sud un CHAPITEAU : les deux tracent à une
   rangée d'écart et leurs traits se collent. Aucune tuile ne peut le rattraper sans un bit de
   contexte, donc on paie en grammaire — une rangée de surface porteuse visible sous le pied.
4. **LA PROFONDEUR ZÉRO EST IMPOSSIBLE POUR UN MASSIF LIBRE.** À zéro, deux massifs voisins
   ont leur contour sur la même ligne et le tracent tous les deux. La liberté n'est pas un
   ornement, c'est ce qui les sépare : F0 vaut un pixel.

**Le vocabulaire livré est celui du GESTE, pas la forme close.** `core/brush_vocabulary.gd`
(généré) porte les **39 tuiles** que le pinceau atteint — 14 surfaces, 25 falaises.
`core/massif_form.gd` reste la **borne haute** : elle garde l'invariant I8, elle n'est plus la
cible. ⚠ **La liste ne peut que croître** : une battue qui ne rencontre pas une tuile prouve
qu'elle est rare, jamais qu'elle est impossible.

**Les invariants du banc** (`proof/massif_ladder.gd`) :

| | |
|---|---|
| **I1 FERMETURE** | aucune extrémité ouverte — rien ne pend dans le vide |
| **I2 ÉPAISSEUR** | aucun pavé 2×2 entièrement de trait |
| **I6 VÉRITÉ** | aucun pixel de fond là où le monde a de la matière |
| **I7 UNICITÉ** | deux tuiles ne rendent jamais la même image |
| **I8 FORME** | toute tuile posée est dans la forme close |

## Structure du dépôt

```
core/            logique pure, zéro dépendance UI, utilisable en headless
  massifs.gd         LE MODELE : les massifs, l'empreinte, les poses, la clé d'une tuile
  massif_form.gd     la forme close : 2^18 fenêtres, leurs témoins, l'îlot étiré
  massif_witnesses.gd  GENERE — les blocs trouvés pour ce que la fenêtre ne porte pas
  brush_vocabulary.gd  GENERE — les tuiles que le geste atteint : ce qu'on livre
  gesture.gd         la règle du geste : ce qu'un relief a le droit d'être, écrit UNE fois
  domain.gd          le domaine : quels reliefs l'acheteur a le droit de bâtir
  blob_index.gd      voisinage 8 bits, canonicalisation, les 47 index
  height_mask.gd     le guide en relief : `~` le vide, `.`/`0` la plaine, `1..9` les plateaux
  mask_io.gd         lecture / écriture d'un masque binaire (texte)
  families.gd        le seul endroit où les vocabulaires de surface se ressemblent
  seams.gd           les pixels que le modèle prouve identiques d'une tuile à l'autre
  painting.gd        les faux pixels posés dans chaque tuile ; UNE image par groupe
  work_io.gd         lecture / écriture du travail en cours (.solutiles, v5)
  proof_scene.gd     la planche de preuve : un îlot par tuile, calculée
  surface_demos.gd / wall_demos.gd   GENERES — les îlots découpés dans le guide
  modes.gd           catalogue des modes (guide + règles d'exportation)
  delivery.gd        quelles cases peintes deviennent des tuiles
  plugin_install.gd  copier SoluPaint dans un projet Godot
  ...                le reste (walls, coverage, corner_index, brink*, thickness, junctions,
                     border_rules, surface_form, symmetry) appartient aux ANCIENS modèles ;
                     encore chargé, plus la cible — voir ARCHIVE.md
render/          illustration — présentation, pas logique, mais headless
  massif_tiles.gd    LE DESSIN d'une tuile : (silhouette, bande, au ras) × liberté
  massif_scene.gd    l'image d'un relief — rien à assembler, l'ordre de pose fait tout
  guide_image.gd, guide_render_job.gd, assembly.gd, contour*.gd   anciens modèles
  preview.gd         écrit l'illustration sur disque
  satyron_tiles.gd   lit le tileset de Satyron chez lui, pour le banc d'essai
ui/              l'éditeur
  editor.tscn, editor.gd   la fenêtre ; aucune règle de produit ne vit dans le .gd
  work_area.gd       grille, zoom, fond du guide, pose des faux pixels
  sidebar.gd, tool_section.gd   la barre translucide et ses sections repliables
  preview_panel.gd   l'aperçu en jeu ; neighbours_panel.gd  la case survolée et ses voisines
  manual.gd          le mode d'emploi à trois niveaux, ouvert par le bandeau
  screenshot.gd      capture la fenêtre, pour se relire
guides/          guides au format texte
  massifs.txt        LE GUIDE LIVRÉ : 152x248, un îlot par tuile
  epais.txt, minimal.txt, ample.txt, candidate_01.txt, preview.txt   anciens, gardés témoins
proof/
  massif_ladder.gd   LE BANC : I1 I2 I6 I7 I8, sur le guide et des reliefs tirés au sort
  ladder.gd          l'ancien banc du contour prouvé
exporters/
  massif_tileset.gd  la planche et le manifeste (v9)
  massif_trial.gd    l'essai : notre propre trace, livrée comme tileset
  packed_png.gd      la planche packed, une seule image, pour la vendre
  tileset_png.gd, trial_tileset.gd   anciens modèles
addons/solupaint/    LE PLUGIN MOTEUR — ce qui part chez l'acheteur
  rules.gd           la copie de la règle de pose, sur un monde NON BORNÉ
  manifest.gd        lecture du `<nom>_tileset.txt`, et ses refus
  tileset.gd, world.gd, dock.gd, plugin.gd, README.md
tests/run.gd     runner headless, code de sortie non nul en cas d'échec
tools/           outils de fabrication, jamais lus par le logiciel
  build_massifs.gd     LE GUIDE : un îlot par tuile, calculé, revérifié dans le guide assemblé
  massif_witnesses.gd  la chasse aux témoins (`PART=i/n`, puis `--fusion`)
  preview_massifs.gd   l'image, pour la regarder (`GUIDE=` `F=` `GRILLE=`)
  brush_census.gd      ce que le geste atteint, et ce qu'il fabrique hors de la forme
  reload_work.gd       relire un vrai fichier de session sans le réécrire
  chain_massifs.gd     LA CHAÎNE ENTIÈRE sur un vrai `.solutiles` : export → plugin → pose
  preview_engine.gd    le monde tel que le moteur le posera, avec VOTRE planche
  check_solupaint.gd   le banc du nœud : couches, contre-geste, fuites
  make_trial_scene.gd  la scène de démonstration, régénérée d'une commande
  ...                  les autres recensements appartiennent aux anciens modèles
```

## Conventions

- **GDScript uniquement.** Pas de GDExtension, pas de C++, aucune dépendance externe.
- **Typage statique partout.** `project.godot` déclare
  `debug/gdscript/warnings/untyped_declaration=2` : une déclaration non typée est une
  **erreur de parsing**, pas un avertissement.
- **snake_case** fichiers / fonctions / variables ; `PascalCase` pour les constantes de
  script préchargées ; `SCREAMING_SNAKE_CASE` pour les constantes.
- **Un fichier = une responsabilité.** `core/` ne connaît ni nœud, ni scène, ni rendu.
- **Indentation par tabulations.** Membres privés préfixés par `_`.
- **Aucun `class_name`, préchargement explicite** (`const X := preload("res://core/x.gd")`).
  Le cache des noms de classe est produit par l'éditeur ; sur un clone frais lancé en
  headless il n'existe pas, et un `class_name` ne se résoudrait pas.
- **Repère de grille** : `x` croît vers l'est, `y` vers le sud. Hors-grille = vide.

## Commandes

Le binaire n'est pas dans le `PATH` sur cette machine, et il faut la variante `_console.exe`
sous Windows — l'exécutable normal n'écrit pas sur la sortie standard du terminal :

```
GODOT="C:/Users/jorda/Desktop/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe"

# la suite (sortie 0 si tout passe)
$GODOT --headless --path . --script res://tests/run.gd

# le banc du modèle
$GODOT --headless --path . --script res://proof/massif_ladder.gd -- 25

# rebâtir le guide (il s'auto-vérifie)
$GODOT --headless --path . --script res://tools/build_massifs.gd -- res://guides/massifs.txt

# le regarder
GUIDE=res://guides/massifs.txt F=1 GRILLE=1 $GODOT --headless --path . \
    --script res://tools/preview_massifs.gd -- sortie.png 2

# la chasse aux témoins, en parts (un processus n'utilise qu'un cœur)
PART=0/4 $GODOT --headless --path . --script res://tools/massif_witnesses.gd -- 250
$GODOT --headless --path . --script res://tools/massif_witnesses.gd -- --fusion

# la chaîne entière, sur un vrai travail peint
$GODOT --headless --path . --script res://tools/chain_massifs.gd -- mon_travail.solutiles

# le monde tel que le moteur le posera, avec la planche exportée
$GODOT --headless --path . --script res://tools/preview_engine.gd -- <manifeste.txt> sortie.png

# le banc du nœud SoluPaint, et la scène de démonstration
$GODOT --headless --path . --script res://tools/check_solupaint.gd
$GODOT --headless --path . --script res://tools/make_trial_scene.gd -- [manifeste.txt]

# l'éditeur
$GODOT --path .

# se relire sans lancer à la main — arguments après `--`, dans n'importe quel ordre :
#   un .solutiles à ouvrir, `massifs`, `remontage`, `fil`, `apercu`, `preuve`, `manuel`,
#   `nu`, `trait`, `survol=x,y`, `zoom=x,y,pas`
$GODOT --path . --script res://ui/screenshot.gd -- sortie.png travail.solutiles zoom=12,12,22
```

## Les lois qui tiennent

### Le guide et le relief

- **Le vide se déclare, `~`, et `HeightMask.VOID` vaut −1.** Le hors-grille est du vide. Tout
  le code qui teste `>= N` avec N ≥ 1 est inchangé — le vide y échoue comme la plaine ; seul
  ce qui teste `>= 0` voit la différence, c'est-à-dire l'étage 0.
- **La plaine est un massif comme les autres** — elle a sa surface et sa falaise, celle du
  **bord du monde**. ⚠ **Chaque relief doit donc déclarer son bord** : une marge de vide
  autour, au moins une chute entière. Sans elle, la falaise du bord tombe hors du cadre et son
  contour se trouve coupé par le cadre de l'image.
- **Le parseur est strict.** Un guide ne peut pas contenir de commentaires : `#` signifie déjà
  « plein ». La documentation d'un guide vit ici, pas dans le guide.
- **On ne voit que le sommet.** La couverture se compte sur la surface **visible**, jamais sur
  l'union des étages : une tuile cachée ne peut ni se viser ni se juger.
- **Le relief se décrit accident par accident, jamais en ASCII.** Dessiner ces formes à la main
  fait se tromper d'une case et d'un étage à chaque essai.
- **⚠ UN ACCIDENT NE SE POSE PAS SOUS UN AUTRE.** Un coude posé juste au sud d'une crête reçoit
  un voisin nord et change d'index : la tuile visée disparaît du guide. C'est le genre de faute
  qu'aucune relecture ne voit et que le compteur attrape en une seconde.
- **⚠ CE QUI COMPTE N'EST PAS LE NOMBRE DE CASES, C'EST LA TAILLE DE LA CASE À L'ÉCRAN.** Un
  guide qui se **couche** (plus large que haut) épouse le cadre de travail et gagne 30 % sur le
  côté de la case. L'acheteur doit voir, d'un coup d'œil et en temps réel, un grand nombre de
  tuiles se remplir sous son crayon — pour comprendre le peu qu'il aura à dessiner.
- **Le guide livré est encore une planche de spécimens, pas un paysage.** Décidé ainsi, et dans
  cet ordre : d'abord la justesse.

### Ce qui se peint

- **Une case n'est retenue que si elle a été peinte.** Quand plusieurs cases portent la même
  tuile, ce sont des **jumelles** ; peindre **est** l'acte de sélection, donc il n'y a rien à
  configurer. Conséquence : un guide complet ne suffit pas à exporter.
- **« Peindre les jumelles » n'est pas une option, c'est le comportement.** Deux jumelles ne
  sont pas deux tuiles qui se ressemblent : c'est **la même** tuile vue à plusieurs endroits,
  donc les remplir ensemble ne peut jamais être faux.
- **UNE TUILE, UNE IMAGE** (`Painting.share()`). Le carnet le sait, pas l'écran : un groupe
  tient **une** image, sous sa première case en ordre de lecture, et toute opération par case y
  passe. L'export, la sauvegarde, l'aperçu et les voisines lisent la bonne image sans rien
  savoir des jumelles ; l'écran, lui, ne fait que **répéter**. Mesuré : le coup de crayon passe
  de 6 ms à 7 µs, et ne dépend plus du nombre de jumelles.
- **LES VARIANTES SONT SUPPRIMÉES. Une tuile, un dessin, une case de planche.** La planche a une
  taille fixe ; peindre mille jumelles différemment n'en sortirait qu'une et jetterait les
  autres **en silence**. Clause au contrat : `sheet fixed_size one_drawing_per_tile no_variants`.
- **L'étage 0 est du DÉCOR : il reçoit le temps réel, il ne prend pas le crayon.** Ni grille
  (la grille ne se trace que sur ce qui se peint), ni pinceau — mais il reste dans les groupes
  de jumelles, et c'est l'argument de vente : le sol du jeu sortira du même tileset, sans rien
  de plus à dessiner.
- **Le crayon refuse ce qui n'est pas une tuile** (règle 5). La case survolée est cerclée de
  blanc si elle se peint, de rouge sinon : le refus se voit avant le clic.
- **Le mode, la taille des faux pixels et la famille se choisissent AVANT de dessiner**, et se
  ferment au premier pixel : en changer rejetterait tout le travail.
- **Annuler est indispensable, pas confortable.** Un trait de travers ruine une tuile dans tous
  ses exemplaires à la fois. `Ctrl+Z` / `Ctrl+Y`, l'unité est la **passe** (du clic au
  relâchement), on journalise les **pixels changés** et **on rejoue à l'envers**.
- **Recharger n'est pas un coup de crayon** : `Painting.set_image()` ne journalise rien, sinon
  « annuler » juste après une ouverture viderait l'écran.
- **Les huit outils passent tous par le même pixel.** Crayon, brosse, aérographe, pot, ligne,
  rectangle, pipette, gomme (P B A G L R I E, crochets pour la taille). ⚠ **Tout geste se fait
  en pixels GLOBAUX, pas en cases** : un point d'écran devient un faux pixel du plan entier, et
  c'est lui qui dit quelle tuile il touche et où il tombe dedans. Une seule résolution sert les
  huit outils. « Contraindre à la tuile » **ignore** ce qui déborde, sans le ramener au bord.

### Le dessin

- **L'illustration se calcule depuis le relief, elle ne se dessine pas à côté.** Deux
  conséquences, et la seconde vaut la première : elle **ne peut pas mentir** sur ce que le guide
  contient, et elle est **entièrement à nous** — donc redistribuable, ce qu'un guide fait
  d'assets tiers ne serait jamais.
- **Le rendu va du bas vers le haut**, chaque couche recouvrant la précédente : les coins
  arrondis laissent voir ce qui est dessous sans qu'on ait rien à calculer.
- **Chaque tuile est dessinée trois fois trop grand puis réduite**, et tamponnée. ⚠ Le
  **dehors** d'une tuile porte sa propre couleur en transparent, jamais du noir : à la réduction
  un dehors noir cernerait chaque tuile d'un liseré sombre.
- **La lumière vient du nord-ouest.**
- **LA PLAINE NE SE DESSINE PAS. Le logiciel n'a aucun fond.** Dans le jeu, le sol sera un étage
  plat du même tileset, posé par le moteur sur sa propre couche. En peindre un ici reviendrait à
  livrer un fond que le tileset ne contient pas.
- **On ne peint dans une tuile que ce qui est CONSTANT.** C'est le critère, et il tranche : sous
  un bord sud il y a **toujours** une falaise, donc l'épaule est légitime ; au nord, non.
- **UN FLANC QUI S'ARRÊTE NE SE CREUSE PAS, IL SE TRAIT.** La roche va jusqu'au bord de sa case
  et l'artiste marque sa fin d'un trait. Creuser retire de la matière que le modèle affirme, et
  découvre la couche du dessous, qui y trace son propre bord : les deux traits se collent.
- **Le contour se juge à deux nombres, pas à l'œil** : le nombre de **morceaux** du trait, et le
  nombre de **pavés 2×2 entièrement de trait**. ⚠ Le second est celui qui attrape le défaut —
  deux traits qui se touchent forment **un seul** morceau, donc le compte de morceaux est content
  pendant que l'œil voit un renflement.
- **Cerner sur QUATRE voisins plutôt que huit est gratuit** — mesuré, 1583 → 1145 pavés sans un
  morceau de plus.
- **⚠ DERRIÈRE LA TRANSPARENCE D'UNE TUILE COMMENCÉE : la matière peinte d'en dessous, jamais
  le guide** (décision utilisateur — le peintre se guide sur la matière réelle). Une tuile
  **vierge** garde sa consigne du guide, sans quoi l'herbe pleine d'en dessous effacerait le
  dessin de ce qu'il reste à faire. ⚠ **Et là où il n'y a rien dessous, c'est le VIDE** : sur le
  guide livré, **12 903 cases posées sur 19 492 n'ont qu'une pose** — toute la plaine et sa jupe
  de bord du monde, dont 3 384 tuiles de bord — et elles montraient le guide au lieu du vide.
  `VOID` est déclaré une fois dans `work_area.gd` et sert **à la fois** de fond de la zone et
  d'effacement sous les tuiles : deux endroits pour une couleur, c'est deux endroits pour
  diverger. ⚠ **Et l'efface n'est pas un tablier** — l'aplat de plaine qui débordait du guide a
  disparu en 4.0.0 et ne revient pas : ici on ne pose aucune matière, seulement ce qu'on voit
  déjà à côté du monde.
- **Toutes les vues empilent** — remontage, aperçu en jeu, voisines, et la zone de travail dès
  qu'une tuile est commencée. Le fond découvert se laisse en **transparence** : le jeu montrera
  le vrai sol d'en dessous, et la complétude ne compte que des **tuiles** (≥ 1 pixel), jamais
  des pixels.
- **L'aperçu en jeu ne fabrique aucune tuile** : chaque case y **emprunte**, par identité, ce
  qui est peint dans le guide, et toujours la première occurrence, sinon le décor scintillerait
  à chaque coup de crayon. Il dit *comment ça rend*, pas *si tout est peint* — les jauges sont
  là pour ça.
- **La planche de preuve est calculée, jamais dessinée** — un îlot par tuile, à une place connue
  d'avance, dans l'ordre de la planche exportée. Un acheteur voit N tuiles, il ne voit pas
  l'absence d'une N+1ᵉ ; la planche le lui montre.
- **Les îlots et les spécimens se CHERCHENT, ils ne se déduisent pas** : on balaie les positions
  et on **juge** (épais ? la case porte-t-elle la tuile annoncée ? reste-t-elle peignable ?), au
  milieu du contexte où le témoin servira. Un témoin cherché sur le vide et posé sur la plaine
  n'est pas le même témoin.
- **Un trou est noir, pas couleur de sol.** Peint à la teinte de l'étage 0, un panneau vide
  ressemble à du terrain, et on croit trois essais de suite qu'il marche.

### La sauvegarde et l'export

- **La sauvegarde range l'art par TUILE, jamais par case** (`core/work_io.gd`, v5). C'est la
  seule décision du fichier, et elle porte tout le reste : le guide peut être redessiné,
  agrandi, compacté, remplacé — l'art retombe sur ses pieds, puisqu'il est rangé sous le nom de
  ce qu'il représente. ⚠ **Ce qui ne retombe pas est DIT, pas jeté** (`unplaced`). ⚠ **Et un
  vocabulaire qui change de sens se TRADUIT quand on sait le replacer, et ne se rend que quand
  on ne sait pas** : rendre un travail qu'on sait replacer, ce serait le perdre pour rien.
- **Le fichier est un texte** : en-tête lisible, puis une ligne par tuile, image en PNG base64.
  ⚠ **Ouvrir lit en deux temps** (`peek()`) : le fichier dit dans quel paysage et à quelle taille
  il a été peint, et il faut charger ce paysage **avant** de pouvoir y reposer quoi que ce soit
  — une seule ligne de tuile pèse plusieurs kilo-octets.
- **Une feuille incomplète est refusée, et rien n'est écrit** (règle 5) — mais **un refus n'est
  pas une erreur** : incomplet est l'état normal pendant tout le travail. Le bouton est grisé,
  le compte s'affiche, et c'est tout. Le signaler par `push_error` apprendrait à ignorer le rouge.
- **C'est la PREMIÈRE OCCURRENCE PEINTE qui sort, quel que soit son rang**, et on garde le plus
  petit rang plutôt que le premier rencontré : un dictionnaire ne promet aucun ordre, et un
  export qui changerait d'une fois sur l'autre serait indéfendable.
- **⚠ UNE TUILE N'EST LIVRÉE QUE SI SA LISTE PORTE UN DESSIN**, pas du seul fait que sa clé
  existe au rapport. Un compteur qui ne mesure pas ce qu'il prétend mesurer est pire que pas de
  compteur.
- **Le manifeste est un CONTRAT, pas une notice** — et il doit être **nécessaire et suffisant** :
  quelqu'un qui n'a *que* ce fichier et la planche doit pouvoir poser un monde correct. La règle
  de pose y vit en clair, une seule fois, avec des commentaires `#` qui disent *pourquoi*. Si une
  règle manque, elle vivra dans la tête de celui qui a écrit le premier moteur, et le second
  divergera sans que rien ne le dise.
- **⚠ UN GARDE-FOU QUI NE REGARDE QUE D'UN CÔTÉ NE GARDE RIEN.** Le lecteur porte **deux
  bornes**, `READS_FROM` autant que `READS_UP_TO` : la haute dit « je ne connais pas encore cette
  règle », la basse « je ne connais plus celle-là ». Et **la version bouge dès que le SENS
  bouge**, sinon deux fichiers de même version décrivent deux mondes différents.

### Le plugin SoluPaint

- **Il part chez l'acheteur, dans SON projet, où `res://core/` n'existe pas** : il emporte donc
  **sa propre copie** de la règle de pose. Ce n'est pas un choix, c'est la contrainte.
- **⚠ LA QUESTION N'EST DONC PAS « COMMENT ÉVITER LA COPIE » MAIS « COMMENT PROUVER QUE LES DEUX
  DISENT LA MÊME CHOSE ».** Réponse : un **contrôle croisé** — reliefs exhaustifs, guides livrés,
  planche de preuve, et des reliefs tirés au sort à chaque exécution. Une seule case qui
  divergerait fait échouer la suite. ⚠ **ON COMPARE DANS LES DEUX SENS** : un plugin qui ne
  poserait rien du tout passerait un test qui se contente de vérifier que ce qu'il pose est juste.
- **Le monde du plugin n'est PAS borné** — un `Dictionary` case → étage. C'est une simplification,
  pas une extension : le cas « robe hors grille » n'existe pas côté moteur.
- **Il REFUSE plutôt que de deviner** : fichier qui ne s'annonce pas, version hors bornes,
  constantes de falaise qui ne sont pas les siennes. Un tileset dont l'étage descend de quatre
  cases, posé par un moteur qui en compte trois, donnerait un monde faux **sans une seule
  erreur** — le pire des défauts, celui qui ne se signale pas.
- **Le pinceau s'arme à la main**, et c'est un bouton plutôt qu'un raccourci : un outil qui
  intercepte la souris sans qu'on l'ait demandé fait perdre le glisser-déposer. Il **sélectionne
  le monde** en s'armant (sans sélection il serait armé et **muet**), **comble la ligne**
  (Bresenham borné — il tourne dans l'éditeur), et pose son annulation **au relâchement, d'un
  seul bloc**.
- **UN REFUS MUET EST LE PIRE DES REFUS.** Chaque condition dit **ce qui manque** puis **ce qu'il
  faut faire**, dans une fenêtre qu'on ne peut pas rater, et **dans l'ordre où on les remplit** :
  annoncer « aucun tileset » à quelqu'un qui n'a pas de scène ouverte l'envoie résoudre le
  mauvais problème.
- **La zone à refaire est bornée, et la portée se déduit du modèle.** Poser une case change bien
  plus que sa tuile ; `rebuild()` complet est juste et intenable (456 ms sur 256×192, **par
  case**). ⚠ **Une borne qu'on franchit à la lecture n'est pas une borne** : on parcourt la zone,
  pas le dictionnaire. Résultat : le coût ne dépend plus de la carte. ⚠ **Un `top` trop grand
  n'est jamais faux, seulement un peu lent** — c'est la bonne direction pour une approximation ;
  l'inverse laisserait le monde faux **pendant qu'on le dessine**, et rien ne le signalerait.
- **⚠ UNE COUCHE QU'ON POSE SANS LA NETTOYER EST UNE FUITE.**
- **Ce qu'on peut trouver ne se demande pas** : le panneau fouille le projet et propose ce qu'il
  trouve ; il ne choisit à la place de personne que quand il n'y a pas de choix. On regarde le
  **nom**, pas le contenu. Et l'installation dépose **de quoi peindre** — le vôtre s'il est
  complet, l'essai sinon, **et on le dit**. Elle refuse un dossier sans `project.godot`, copie
  **en octets** et ne touche pas au `project.godot` de l'acheteur : une phrase à lire vaut mieux
  qu'un fichier abîmé.
- **LE PORTAGE EST FAIT : le plugin pose des MASSIFS.** `rules.gd` est la copie du modèle —
  composantes connexes emboîtées, empreinte, chute qui cherche son palier, le seul bit de ras —
  et **une couche par étage** remplace les trois de l'ancien modèle. Manifeste **v9**, la v8
  refusée nommément ; une seule planche, une seule source d'atlas.
- **⚠ ET IL N'Y A PLUS DE ZONE À REFAIRE, PARCE QU'ELLE N'EST PLUS SOUTENABLE.** Un massif est
  une **composante connexe**, et le bit « au ras » est une propriété du massif **entier** : poser
  une case peut réunir deux massifs, ou faire déborder un massif de son porteur — et alors tout
  son contour change de règle, d'un bout du monde à l'autre. Une zone bornée laisserait le monde
  faux pendant qu'on le dessine, et rien ne le signalerait. On repose donc tout : **3 ms sur
  16x16, 14 sur 32x32, 75 sur 64x64, 209 sur 96x96**. Une carte plus grande demandera un calcul
  incrémental — il est possible, il n'est pas écrit, et il ne se devine pas.
- **⚠ UNE POSE PERDUE SE DIT.** « Une case n'a qu'une pose par étage » est un théorème **sous min
  trois** ; un relief posé à l'inspecteur peut le violer, et alors une jupe retombe sur la
  surface d'un voisin. Une couche ne porte qu'une tuile par case : `last_warning` compte ce qui a
  été recouvert, et ce qui n'a pas trouvé sa tuile. ⚠ **Et c'est une variable à part de
  `last_error`** : un manifeste qui se lit très bien peut poser un monde imparfait, et confondre
  les deux enverrait l'acheteur résoudre le mauvais problème.
- **⚠ ET LE PINCEAU REFUSE AUSSI LE PINCEMENT DIAGONAL, pas seulement la case fine.** Min trois
  ne le couvre pas : deux massifs reliés par un seul coin sont reliés par une bande d'épaisseur
  un. Le refus se dit au relâchement, jamais tu.

### L'écran

- **Deux barres : à gauche les options, à droite le travail.** À gauche **ce qu'on fabrique** et
  **ce qu'on regarde** ; à droite **tout ce qui sert à peindre**. Mélangées, on cherche ;
  séparées, on trouve sans lire.
- **La barre est posée SUR la zone de travail, et translucide au repos** — c'est ce qui donne
  l'air d'un calque plutôt que d'un panneau. Trois conséquences apprises à la dure : la zone de
  travail occupe **toute** la largeur (la barre ne lui réserve que son cadrage initial) ; on
  teinte `self_modulate`, pas `modulate` ; le survol se teste sur le **rectangle**, pas avec
  `mouse_entered`, qui se déclenche à l'envers dès qu'on passe sur un enfant.
- **⚠ UN LIBELLÉ QUI S'ALLONGE IMPOSE SA LARGEUR À TOUTE LA BARRE.** Payé deux fois.
- **⚠ LES QUATRE BORDS D'UN PANNEAU ANCRÉ SE POSENT, PAS UN SEUL.**
- **Les cases de vue disent « masquer », pas « afficher »**, et partent décochées : une case qui
  commence cochée donne à croire qu'on ajoute alors qu'on retire. « Masquer le guide » n'est
  qu'un décrassage de l'écran — la zone de travail montre **déjà** le paysage assemblé en
  permanence. ⚠ **Un nom qui promet une capacité qui n'existe pas coûte plus cher qu'un nom
  terne** : il fait chercher ce qu'on ne trouvera pas.
- **Quatre marques, quatre sens** : blanc le survol, cyan les identiques, violet les bords liés,
  ambre les cases sans jumelle — celles-là portent leur contour **entier**, sinon les voisines le
  rongent et la marque ne se lit pas.
- **⚠ EN VUE D'ENSEMBLE, UN FAUX PIXEL MESURE MOINS D'UN PIXEL D'ÉCRAN**, et l'on croit que rien
  ne se passe alors qu'un seul trait peint deux cents cases. En dessous du seuil, les cases qui
  portent de la peinture sont **cerclées**.
- **Clic gauche pose, clic droit efface** — éprouvé à la main, l'inverse se trompait de réflexe.
- **Les jauges se recalculent à chaque coup de crayon** (règle 6), depuis les mêmes fonctions que
  la suite : ce que l'écran affiche est ce que les tests prouvent.
- **Le mode d'emploi vit DANS le logiciel, à trois niveaux** — prise en main, comment ça marche,
  la règle de pose. ⚠ **Le niveau 3 n'est pas recopié, il est LU À LA SOURCE** : un mode d'emploi
  qui paraphraserait le contrat serait un second endroit où mentir.
- **La première ouverture ne montre que ce qu'il faut.** Une promesse n'est pas un outil.
- **Pas de surbrillance du pixel sous la souris** : suivre le pixel obligeait à redessiner la
  zone à chaque micro-mouvement, pour un repérage dont on n'a pas voulu. Le survol se suit à la
  case.
- **Les textures ne remontent au GPU qu'une fois par image, et par paquets** — un guide
  entièrement peint à 256 px ferait cent quatre-vingts méga-octets d'un coup. Et **un travail
  relu doit marquer ses cases sales**, sinon les compteurs disent tout et l'écran reste vide.
- **Pas de remplissage par rotation ni par miroir** (règle 3). Le gain serait réel — 47 index →
  15 orbites — mais tourner une tuile tourne ses hautes lumières avec elle, et une lèvre nord
  éclairée devient une lèvre est éclairée du mauvais côté. ⚠ **La porte par laquelle elles
  reviendraient : un mode sans lumière**, où elles seraient *correctes* et non seulement
  pratiques — donc une propriété du mode, décidée une fois avec lui, jamais une case à cocher
  offerte au milieu du dessin.

## Les pièges déjà payés

### Godot

- **`const` typé `Array[PackedStringArray]` ne se résout pas** : le membre cesse d'exister, tout
  ce qui le précharge tombe avec lui, et le programme tourne sans fin sans erreur claire. Écrire
  les données générées en tableaux simples, envelopper à la lecture.
- **Ne pas nommer une méthode `_set`** : `Object._set(StringName, Variant)` existe, en redéfinir
  la signature est une erreur d'analyse et le script ne charge plus du tout.
- **« Charge » ne veut pas dire « compile ».** Un script dont l'analyse échoue rend quand même une
  ressource, vide de ses fonctions : la suite perdait quinze vérifications en silence.
  `can_instantiate()` tranche. Et **on ne relit pas hors cache** — `CACHE_MODE_IGNORE` sur un
  script en cours d'usage fait planter le moteur.
- **Un `PackedByteArray` se copie quand on l'affecte.** Modifier la copie locale ne touche pas la
  rangée rangée dans le tableau, et la planche sort vierge **sans une seule erreur**.
- **`String.find("")` rend −1** en Godot là où Python rend 0.
- **`get_string_from_ascii()` s'arrête au premier octet nul** — et un pixel transparent en est un.
  Comparer des images en base64.
- **`set_anchors_preset()` conserve la taille courante** ; appelé dans `_ready()` où elle vaut
  zéro, il laisse le panneau minuscule en haut à gauche. C'est `set_anchors_and_offsets_preset()`.
- **`%` se lie au dernier fragment d'une concaténation**, pas à la chaîne entière. Bâtir la
  chaîne dans une variable d'abord.
- **En script `SceneTree`, `quit()` part avant la première itération** : le `_ready()` d'un nœud
  qu'on vient d'ajouter n'a pas encore tourné. Rejouer son geste avant de mesurer.
- **`user://` survit d'une exécution à l'autre** : un test qui écrit doit d'abord faire le vide,
  sinon il passe le jour de son écriture et rougit le lendemain.
- **Un greffon se rafraîchit en DIFFÉRÉ d'une image**, et à chaque changement de scène : il entre
  dans l'arbre **avant** que l'éditeur n'ait restauré la scène ouverte.
- **`add_control_to_dock` EMBALLE le contrôle** dans un `EditorDock` : chercher un `TabContainer`
  comme parent direct ne trouve rien et **ne fait rien du tout, sans une erreur**. Chercher
  l'onglet par son **nom** ; la remonte des parents ne sert que de filet. Et un panneau fermé se
  recrée **à neuf** — le même contrôle rendu à `add_control_to_dock` ne rentre jamais dans l'arbre.
- **Lancé depuis l'éditeur Godot, la fenêtre de jeu est INCRUSTÉE** dans un dock depuis la 4.4 :
  elle subit la taille du dock et ignore tout redimensionnement.
- **`TaskStop` tue le shell, pas le Godot dessous.**

### Méthode

- **⚠ ON COMPARE DANS LES DEUX SENS.** Un garde-fou qui ne regarde que d'un côté ne garde rien —
  payé sur le contrôle croisé du plugin, puis **repayé** sur les raccords, où l'on vérifiait que
  `Seams` ne lie pas trop et jamais qu'il lie assez : **60 jonctions sur 109** manquaient.
- **⚠ UN TEST QUI REDÉRIVE LA FORMULE QU'IL CONTRÔLE NE CONTRÔLE RIEN — il la certifie.** Le
  vert d'alors était le pire de tous les verts : la suite passait pendant que le dessin cassait
  aux deux tiers de ses jonctions.
- **Un test faux coûte plus cher qu'un test absent : il envoie corriger ce qui va bien.**
- **Un compteur qui ne mesure pas ce qu'il prétend mesurer est pire que pas de compteur.**
- **⚠ UNE MARQUE ABSENTE NE SE REMARQUE PAS.** Rien ne clignote, rien n'est de travers, il ne se
  passe simplement rien — et aucun test ne le voit, la suite ne montant pas l'interface.
- **Une battue qui ne rencontre pas une tuile prouve qu'elle est RARE, jamais qu'elle est
  impossible.** Et **une battue doit avoir vraiment cherché** : qu'elle rencontre bien tout le
  vocabulaire est **asserté** aussi.
- **Trois forces d'argument, et il faut dire laquelle on emploie** : *exhaustif sur la fenêtre de
  la tuile* (un théorème, aucun monde nécessaire) · *exhaustif sur une famille bornée de mondes*
  (qui sature) · *échantillonnage* (prouve la présence, jamais l'absence).
- **Mesurer avant d'écrire**, et publier le pari pour qu'il soit reprochable. Plusieurs paris ont
  été **reprochés** par la mesure, et c'est ce qui les rendait utiles.
- **Une clause candidate se relit contre le vocabulaire DU JOUR, pas contre celui qui l'a fait
  naître.**
- **⚠ UNE CARTE COÛTEUSE NE SE RECALCULE PAS À CHAQUE TOUR DE BOUCLE.** `for x in cher().keys():
  ... cher()[x] ...` — l'en-tête ne s'évalue qu'une fois, le **corps** rappelle la fonction à
  chaque itération. Sept fois la même faute ; la suite est passée de 5 min 11 à 1 min 20.
  ⚠ **Et aucun test ne pouvait le voir : la suite mesure la justesse, pas la durée.**
- **⚠ UN TEST QUADRATIQUE NE BLOQUE PAS, IL RAMPE — et on croit à un blocage.**
- **⚠ UNE INSERTION QUI SE TROMPE DE FIN DE FONCTION NE SE VOIT NULLE PART.** Le fichier se
  charge, la suite passe, et le fond ne se dessine plus. Quand une édition déplace du code, la
  relire à l'œil **et** regarder l'écran.
- **Chercher la cause avant de décorer le symptôme.** Une barre de progression aurait *montré*
  l'attente au lieu de la supprimer, et rendu le défaut acceptable.
- **Un correctif qui masque un symptôme des deux côtés empêche de voir la cause.**
- **Une règle posée puis retirée en une heure est à noter** : elle répondait au symptôme, elle
  aura servi à trouver la vraie cause.
- **On ne coupe jamais sans revérifier, et dans le CONTEXTE où le témoin sera posé.** La découpe
  ment : onze tuiles sur cinquante et une avaient disparu au découpage.
- **Ce que le pinceau ne peut pas peindre n'a rien à faire dans le vocabulaire** — mais on
  **construit** ce que la battue n'atteint pas au lieu de le jeter.

## Version

Elle vit dans `project.godot` (`application/config/version`) et **nulle part ailleurs** : le
bandeau de l'éditeur la lit là. Deux endroits finiraient toujours par se contredire.

**10.0.0** — LA DÉCOMPOSITION EN COUCHES : une tuile ne répond que d'elle-même ; elle remplit sa
case, ce qui est à côté appartient à la couche du voisin, et l'ordre de dessin tranche qui est
devant. C'est de là que sort le **modèle des massifs**, qui vit désormais dans le produit — un
paysage, un réseau, deux jauges — sans que la version ait encore bougé. **L'historique des
versions 6 à 10 est dans `ARCHIVE.md`.**

Quand la monter, et je le proposerai le moment venu :

- **correctif** — un défaut réparé, rien de neuf à l'écran ;
- **mineure** — une capacité de plus que l'utilisateur voit ;
- **majeure** — ce qui périme l'existant : un format de guide qui change, un export dont la
  sortie n'est plus la même.

## Références

- **Satyron** (`D:\Satyron`) — le jeu où le modèle de falaise a été établi empiriquement puis
  éprouvé sur une vraie carte. À lire quand un doute survient sur le comportement d'une falaise :
  `WORLD/cliffs.gd`, `WORLD/tiles/cliff_kit.gd`, `DEV_TOOLS/make_cliff_kits.py`, et la section
  « Les colonnes » de son `CLAUDE.md`. ⚠ **On lit, on ne copie pas** : le pack est acheté, sa
  licence autorise l'usage et interdit la redistribution — sur une machine où le projet n'est pas
  là, la technique `example` reste **fermée** dans la liste (règle 5).
- **`ARCHIVE.md`** — le dossier long des modèles antérieurs, et le détail de tout ce qui est
  résumé ici.

## Questions ouvertes

Les fiches détaillées (matières bordées, signature du manifeste, sweet spot de la grammaire,
niveau 0 du mode d'emploi, entrée de grotte, motifs carrés, tuiles animées) sont dans
`ARCHIVE.md`. Ce qui reste vif :

- **CE QUI RESTE, DANS L'ORDRE — et c'est l'ordre que l'utilisateur a fixé** (PLAN.md) :
  1. **la grammaire** — chiffrer les clauses candidates avant de bâtir quoi que ce soit ;
  2. les îlots — fait ;
  3. **le dessin** — l'utilisateur regarde et valide. C'est le cran où on en est : *« le choix
     des tuiles n'est pas parfait partout, l'apparence globale est déjà satisfaisante »*, donc le
     guide sera **redessiné**, et le carnet rangé par tuile rend ce redessin gratuit ;
  4. **le portage — fait.** L'éditeur, `work_io` (v5), l'export (`massif_tileset`, manifeste v9),
     l'essai, la planche packed, le mode d'emploi, et **le plugin SoluPaint**. Ce qui reste de
     l'ancien noyau (`Walls`, `Coverage`, `CornerIndex`, `Brink*`, `Thickness`) n'est plus lu par
     le produit : il vit comme **témoin**, avec le guide `epais.txt`, jusqu'au démontage.
- **Le sweet spot de la grammaire.** Le vocabulaire est calculé comme *tout ce que le modèle peut
  produire*, jamais comme *ce qu'on accepte de construire*. Les trois clauses candidates ont été
  chiffrées et rendent peu ; le levier n'est pas *ce que le monde a le droit d'être* mais *ce
  qu'une tuile a le droit de savoir* — et il se paie en contours ouverts. ⚠ **Les chutes de
  plusieurs étages sont non négociables** (décision utilisateur) : toute clause qui les
  limiterait est écartée d'office.
- **L'exemple, peint à la main.** L'utilisateur peint lui-même un tileset, qui deviendra le choix
  « Example » et devra passer en conditions réelles dans le soft **et** dans l'addon, par
  tâtonnements successifs. Le banc où chaque itération se regarde : `tools/make_trial_scene.gd`.
- **Deux modes de disposition : paysage et damier de spécimens.** La résolution de la double
  injonction — *demander à un seul dessin d'être à la fois beau et exhaustif*. C'est l'axe du
  **mode**, pas un réglage, et c'est **gratuit pour le travail en cours** : le carnet range par
  tuile, donc un travail commencé sur l'un se recharge sur l'autre.
- **Deux styles de trait : `straight` et `ondulated`** — ce sont F1 et F2 du modèle, gratuits en
  vocabulaire. ⚠ **Mais pas encore pour les falaises** : `wall_depth` ne lit `freedom` que pour
  le test `== 0`, donc les deux rendent aujourd'hui le même bord de face.
- **L'arbre des fonds de guide** : `Technique = computed | example`, `computed = wireframe |
  painted`, `painted = straight | ondulated`. ⚠ **Et tout doit montrer la liberté dès qu'elle est
  disponible** : le fond n'est pas une décoration, c'est la spécification, et une liberté qu'on
  ne montre pas est une liberté que personne n'utilisera.
- **Les matières bordées** (eau, sable) : un masque binaire, donc une couche posée comme un étage
  mais **sans falaise**. +47 tuiles par matière, à deux conditions qui sont des décisions — les
  matières sont **ordonnées** (sable sur herbe, eau sur sable), et une matière **ne touche ni la
  lèvre ni le bord** de son étage, sinon c'est une cascade. ⚠ Et le guide se compose **par
  combinaison**, pas en un guide géant grisé : à 14,6 px la case, le guide cesse de montrer ce
  qu'il existe pour montrer.
- **Les escaliers et les pentes douces** : un **troisième** vocabulaire, pas une matière — et il
  ne se déduit pas, il se **déclare**, comme `~` l'a été pour le vide.
- **La signature du manifeste** : que l'addon ne pose que ce que le logiciel a produit. ⚠ **Un
  verrou dans l'addon ne protège de rien** — il part en GDScript en clair, et la charte interdit
  de maquiller un contrôle qui saute en trente secondes. Ce que la signature sépare, c'est « lire
  un fichier texte » de « craquer un binaire ». La pièce la plus forte : le build d'essai **n'a
  pas de clé privée du tout**.
- **Le plugin Unity.** Rien de commencé. Le contrôle croisé du plugin Godot est le modèle à
  reprendre : c'est lui qui empêche les deux lecteurs de diverger.
