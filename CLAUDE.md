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

- **`PLAN.md` gouverne l'ordre du travail.** Sa **dernière section** — « LE PLAN DE LA SECONDE
  PARTIE », arrêté le 2026-09-06 — est **l'ORDRE** : les sept chantiers demandés (fluides, trous,
  grottes, animation, rooms, cascades, room de test) y sont ramenés à **trois mécanismes** — la
  room, la couche, le creux — chacun disant ce qu'il coûte au format, à la clé et au vocabulaire.
  ⚠ **Elle remplace la précédente comme ordre, PAS comme spécification** : « LA SECONDE PARTIE DU
  PROJET » (2026-09-05) garde les **décisions utilisateur** en long — les fluides surtout — et
  n'est pas recopiée. La section « LE CISAILLEMENT, ET CE QU'IL A RÉVÉLÉ » est l'état du modèle au
  05/09. Tout ce qui précède encore est de l'**histoire** : vrai comme récit, périmé comme
  spécification.
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

Clé d'une tuile : `CUT | COVERS | (bande << 8) | silhouette` (`Massifs.key`) — `COVERS = 1 << 16`,
`CUT_WEST = 1 << 17`, `CUT_EAST = 1 << 18`. Au ras, seuls les quatre cardinaux comptent — la
profondeur y est nulle, donc rien ne se creuse, pas même les coins rentrants.

**LE CISAILLEMENT — de l'herbe et de la roche du MÊME massif, côte à côte.** La bande encode déjà
la transition **verticale** (surface → chapiteau → corps → pied : c'est pour ça que la lèvre porte
son trait). Rien n'encodait l'**horizontale** : la silhouette se lit sur l'empreinte, donc une case
d'herbe dont la voisine est la falaise de son propre massif avait ce bit mis, se croyait pleine, et
rendait la tuile d'intérieur qui se répète partout. La roche s'arrêtait **net**. Le bit se lit sur
l'**empreinte du massif**, jamais sur ce qui se voit — sinon l'identité d'une tuile dépendrait de
ce qu'on pose dessus. ⚠ **Jamais les deux côtés à la fois** : min trois l'interdit, et
l'énumération exhaustive le confirme (zéro fenêtre sur 2^18).

**Et un seul côté trace.** La roche marque sa fin (loi de la lèvre, couchée sur le côté), l'herbe
prend une **ombre** — deux traits dos à dos feraient le pavé 2×2 qu'I2 refuse. ⚠ Et **la lumière
tranche** : un cisaillement est un corps d'angle, l'arête s'éclaire à l'ouest et s'ombre à l'est,
sans quoi `CORPS 255 cisaillé ouest` rendait exactement `CORPS 21 au ras`.

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
(généré) porte les **55 tuiles** que le pinceau atteint.
`core/massif_form.gd` reste la **borne haute** : elle garde l'invariant I8, elle n'est plus la
cible. ⚠ **La liste ne peut que croître — À MODÈLE CONSTANT.** C'est la précision qui manquait, et
elle a coûté un cycle entier. Quand la **clé change de sens**, une entrée d'avant ne désigne plus
rien ; quand une **battue était fausse**, elle a inscrit ce qu'aucun geste n'atteint. Dans les deux
cas la liste se **redérive** (`brush_census --refaire`), elle ne se cumule pas.

⚠ **ET `Gesture.mend` N'A RIEN À FAIRE DANS UNE BATTUE.** Il retouche **case par case** — abaisser
une case fine, combler un gouffre — ce qui n'est pas un tampon : le monde qui en sort est *légal*
sans être *reconstructible au pinceau*. Le recenseur l'appelait après chaque coup jusqu'au
05/09/2026 : **six tuiles fantômes** en sont sorties, qu'aucun geste n'atteint. `mend` sert au
pinceau, qui répare le geste de l'artiste. Jamais à une battue.

⚠ **ET LES BATTUES PARTAGENT UN SEUL VIVIER** (`Lab.ground()`). Le recenseur tirait ses mondes, le
bâtisseur les siens : le premier écrivait au vocabulaire ce que le second ne savait pas porter, et
le guide sortait avec des tuiles absentes. Quatre sources **construites**, donc reproductibles —
les marches (qui fabriquent le cisaillement), les terrasses, les sols étagés, le hasard — plus **les
mondes gardés** : *un monde qui porte une tuile EST son témoin*, et la battue les jetait. ⚠ **Et le
guide n'est PAS dans le vivier** : il en est bâti, l'y remettre ferait converger le cycle vers le
BAS (mesuré : 55 tuiles, puis 50 au tour suivant).

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
  signing.gd         le sceau : ce qu'on scelle, et pourquoi ce n'est pas une serrure
  found_worlds.gd    GENERE — les mondes gardés, témoins de ce qu'aucun vivier n'atteint
  weld_witnesses.gd  GENERE — les témoins qui tiennent une fois soudés à la plaine
  domain.gd          le domaine : quels reliefs l'acheteur a le droit de bâtir
  blob_index.gd      voisinage 8 bits, canonicalisation, les 47 index
  height_mask.gd     le guide en relief : `~` le vide, `.`/`0` la plaine, `1..9` les plateaux
  mask_io.gd         lecture / écriture d'un masque binaire (texte)
  families.gd        le seul endroit où les vocabulaires de surface se ressemblent
  seams.gd           les pixels que le modèle prouve identiques d'une tuile à l'autre
  painting.gd        les faux pixels posés dans chaque tuile ; UNE image par groupe
  work_io.gd         lecture / écriture du travail en cours (.solutiles, v5)
  proof_scene.gd     la planche de preuve : un îlot par tuile — encore lue par le banc et
                     l'ANCIEN export ; le produit ne la montre plus, le guide EST la planche
  surface_demos.gd / wall_demos.gd   GENERES — les îlots découpés dans le guide
  modes.gd           catalogue des modes (guide + règles d'exportation)
  examples.gd        les exemples livrés : nos tilesets peints à la main, montrés en fond
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
  neighbours_panel.gd  la case survolée et ses voisines
  manual.gd          le mode d'emploi à trois niveaux, ouvert par le bandeau
  screenshot.gd      capture la fenêtre, pour se relire
examples/        LES EXEMPLES LIVRÉS — des `.solutiles` complets, à nous, redistribuables
  low_res.solutiles  le tileset peint à la main, 16 px, 55/55 (revu le 06/09/2026)
guides/          guides au format texte
  massifs.txt        LE DAMIER LIVRÉ : 152x248, un îlot par tuile
  terrain.txt        LE PAYSAGE LIVRÉ : 249x159, les 55 tuiles, soudées sur une plaine
  epais.txt, minimal.txt, ample.txt, candidate_01.txt, preview.txt   anciens, gardés témoins
proof/
  massif_ladder.gd   LE BANC : I1 I2 I6 I7 I8, sur le guide et des reliefs tirés au sort
  ladder.gd          l'ancien banc du contour prouvé
exporters/
  massif_tileset.gd  la planche et le manifeste (v10, allégé)
  massif_trial.gd    l'essai : notre propre trace, livrée comme tileset
  packed_png.gd      la planche packed, une seule image, pour la vendre
  tileset_png.gd, trial_tileset.gd   anciens modèles
addons/solupaint/    LE PLUGIN MOTEUR — ce qui part chez l'acheteur
  rules.gd           la copie de la règle de pose, sur un monde NON BORNÉ
  signature.gd       le sceau vérifié chez l'acheteur — il DIT, il ne bloque pas
  manifest.gd        lecture du `<nom>_tileset.txt`, et ses refus
  tileset.gd, world.gd, dock.gd, plugin.gd, README.md
tests/run.gd     runner headless, code de sortie non nul en cas d'échec
tools/           outils de fabrication, jamais lus par le logiciel
  build_massifs.gd     LE GUIDE DU DAMIER : un îlot par tuile, revérifié dans le guide assemblé
  build_terrain.gd     LE GUIDE DU PAYSAGE : les mêmes témoins, SOUDÉS sur une plaine continue
  weld_witnesses.gd    la chasse aux témoins qui SUPPORTENT la soudure — construits, pas tirés
  massif_witnesses.gd  la chasse aux témoins (`PART=i/n`, puis `--fusion`)
  preview_massifs.gd   l'image, pour la regarder (`GUIDE=` `F=` `GRILLE=`)
  brush_census.gd      ce que le geste atteint, et ce qu'il fabrique hors de la forme
  reload_work.gd       relire un vrai fichier de session sans le réécrire — le paysage se lit
                       dans l'en-tête, et le compte est celui du bouton « Exporter »
  shear.gd             le cisaillement : plancher, plafond, et ce qu'il coûterait
  find_worlds.gd       les mondes qui portent ce que le vivier n'atteint pas (jalonné)
  make_key.gd          la paire de clés de signature — la privée reste HORS du dépôt
  blind_spots.gd / tile_situations.gd / find_massif.gd   regarder plutôt que déduire
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

# rebâtir le damier (il s'auto-vérifie)
$GODOT --headless --path . --script res://tools/build_massifs.gd -- res://guides/massifs.txt

# rebâtir le paysage — arguments : sortie, écart latéral, écart vertical, tirages du vivier
$GODOT --headless --path . --script res://tools/build_terrain.gd -- res://guides/terrain.txt

# et la chasse dont il dépend, quand une tuile n'a pas de témoin soudable
$GODOT --headless --path . --script res://tools/weld_witnesses.gd

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
- **LE MODE PAYSAGE EST COMMENCÉ, ET IL N'Y AVAIT RIEN À CHERCHER.** Le damier a déjà résolu la
  question dure : chaque tuile du geste a son **témoin** — un relief calculé qui la porte à une
  case connue, 53 blocs chassés dans `core/massif_witnesses.gd`. Un paysage n'est donc pas un
  problème de couverture à résoudre, c'est le **même jeu de pièces posé autrement** : collées sur
  une plaine continue au lieu d'être isolées chacune dans son liseré de vide.
- **⚠ ET LES TROIS ÉCARTS SE MESURENT, ILS NE SE DÉDUISENT PAS.** Chacun a coûté un essai :
  · **latéral 3** — à deux, le relief devient illégal alors que les témoins sont intacts : c'est
  **min trois**, lu au compteur.
  · **vertical 12** — une falaise descend *sous* son bloc, et le PIED réclame trois rangées de
  surface porteuse visible. Sans rab, **19 témoins sur 53** rendent un relief illégal ; à douze,
  aucun.
  · **le bord du monde est un voisin comme un autre** — collé contre le liseré de vide, un témoin
  changeait de tuile (`CHAPITEAU 241 libre` devenait `CHAPITEAU 81 au ras`). ⚠ Il a fallu poser
  **le bloc SEUL dans la carte entière** pour le voir : ni le voisinage, ni la réparation, ni la
  distance à la plaine n'y étaient pour rien.
- **⚠ ET ON VISE LA TAILLE DE LA CASE, PAS LE RAPPORT DU GUIDE.** Ce sont deux grandeurs
  différentes et s'y tromper coûte : 245×151 affiche un rapport de 1,62, plus proche du cadre que
  209×151 et son 1,38 — et pourtant la case y est **plus petite**, parce que c'est
  `min(largeur/colonnes, hauteur/rangées)` qui décide. Mesuré : **6,2 px la case** contre **3,8**
  pour le damier, soit **+63 %**, dans un guide qui a 16 % de cases en moins.
- **⚠ ET LES DEUX DERNIÈRES TUILES ONT DEMANDÉ UNE AUTRE CHASSE.** `PIED 21 au ras` et `PIED 69
  au ras, cisaillé à l'ouest` n'avaient aucun témoin qui **supporte la soudure** — et la raison
  est dans le modèle, pas dans le hasard : « au ras » décrit un massif **vis-à-vis de son
  porteur**, et dans un monde tiré au sort ce porteur est souvent **le bord du monde**. Combler
  ce vide de plaine lui retire précisément ce qui le rendait au ras. ⚠ **Chercher plus longtemps
  dans le vivier ne pouvait pas aider** : c'est la forme du monde qui était en cause, pas le
  nombre de tirages. `tools/weld_witnesses.gd` **construit** donc au lieu de tirer — un vrai
  plateau porteur d'étage 1, un massif d'étage 2 qui le chevauche — et l'épreuve est celle du
  bâtisseur, pas une approximation : le monde est reposé dans le cadre exact qu'il recevra.
- **⚠ ET LA FORME DU MASSIF SE LIT DANS LA SILHOUETTE.** Les rectangles rencontraient quatorze
  tuiles au ras — donc la battue cherchait au bon endroit — et **aucune des deux visées**. Le L a
  donné `PIED 69 cisaillé ouest` ; `PIED 21` vaut **N+E+S sans W**, donc une **poche fermée sur
  trois côtés**, donc un **C**. Une famille qui demanderait une forme par tuile ne serait pas une
  famille, ce serait une liste : les deux sortent de la même pièce.
- **LE PAYSAGE PORTE LES 55 TUILES ET LE MODE EST OUVERT.** `guides/terrain.txt`, 249×159, légal,
  chaque témoin à sa case, vérifié au banc. ⚠ **Même vocabulaire, même modèle, autre
  disposition** — rien de ce qui sort à l'export n'en dépend, et un travail commencé sur l'un se
  recharge sur l'autre, puisque le carnet range par **tuile**. **Ce qui reste, c'est l'œil** : le
  paysage se lit encore comme des accidents éparpillés sur une pelouse, pas comme une carte — et
  ça ne se prouve pas, ça se regarde.
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
- **« NOUVEAU PROJET » NE DEMANDE RIEN QUAND IL N'Y A RIEN À PERDRE.** Peint **et** non
  enregistré depuis : on demande. Vierge, ou déjà enregistré : on repart, sans un mot — le
  fichier est sur le disque et se rouvre. ⚠ **Une confirmation qui ne protège de rien n'est pas
  une sécurité, c'est une gêne** : elle apprend à cliquer « oui » sans lire, et le jour où la
  question compte vraiment, elle est déjà devenue un réflexe. La boîte offre **trois** issues,
  la plus sûre en premier — *enregistrer puis recommencer* · *recommencer sans enregistrer* ·
  *annuler* — et elle **dit combien de cases** sont en jeu : un nombre se pèse, « des
  modifications » se lit sans rien apprendre. ⚠ **Et la règle vit dans une fonction à part**
  (`must_confirm`) : aucun banc ne monte l'éditeur entier, alors qu'elle, elle se mesure sans
  rien monter — et elle peut régresser **dans les deux sens**.
- **⚠ ET C'EST LE SEUL MOYEN DE ROUVRIR LES CHOIX FERMÉS.** La taille des faux pixels et le
  réseau se ferment au premier pixel ; sans « Nouveau projet », en changer d'avis demandait de
  relancer le logiciel.
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
- **⚠ ET C'EST POUR ÇA QU'UN EXEMPLE N'EST PAS UN STYLE, MAIS UNE PREUVE.** Le dessin calculé est
  la **spécification** : il a donc toujours l'air juste. Un exemple est du **vrai trait remonté en
  paysage**, et c'est la seule vue où l'on voit ce que l'outil rend vraiment — le cisaillement du
  massif 21 a été relevé comme ça, et par aucun autre moyen. ⚠ **Il se relit contre le guide DU
  JOUR** (`core/examples.gd` passe par `WorkIO.read`, comme l'ouverture d'un travail) : un exemple
  peint hier retombe sur ses pieds aujourd'hui, et ce qui ne retombe pas est **dit**, jamais jeté.
  ⚠ **Le remplacer, c'est copier le `.solutiles` puis le relire** — `tools/reload_work.gd` dit en
  une ligne combien de tuiles retombent, combien sont rendues, et si le compte est exportable ;
  un exemple incomplet montrerait des trous en fond de guide sans qu'aucun test ne s'en plaigne.
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
- **Toutes les vues empilent** — remontage, voisines, et la zone de travail dès
  qu'une tuile est commencée. Le fond découvert se laisse en **transparence** : le jeu montrera
  le vrai sol d'en dessous, et la complétude ne compte que des **tuiles** (≥ 1 pixel), jamais
  des pixels.
- **⚠ L'APERÇU EN JEU A ÉTÉ SUPPRIMÉ** (décision utilisateur du 05/09/2026), et la raison
  tient en une ligne : **le guide livré EST déjà une planche de spécimens**, montrée en
  permanence, peinte en temps réel. Un petit panneau qui reposait les mêmes tuiles sur une
  colline disait donc ce que l'écran disait déjà. ⚠ **Et la planche de preuve part avec lui** :
  elle vivait dans le même panneau. Ce qu'elle garantissait — *l'acheteur voit N tuiles, il ne
  voit pas l'absence d'une N+1ᵉ* — est tenu par le guide lui-même (un îlot par tuile) et par
  les **deux jauges**, qui comptent ce qui manque plutôt que de le faire chercher.
- **La planche de preuve est calculée, jamais dessinée** — un îlot par tuile, à une place
  connue d'avance, dans l'ordre de la planche exportée. ⚠ **Elle n'est plus montrée dans le
  produit** (voir ci-dessus) : `core/proof_scene.gd` reste lu par le banc, par l'ancien export
  et par une dizaine d'outils, et c'est là qu'elle a sa valeur.
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
- **⚠ LE MANIFESTE NE PORTE PLUS LA RÈGLE DE POSE** (décision utilisateur du 04/09/2026). Il dit
  **où sont les tuiles**, pas **comment les poser**. Et ça n'affaiblit **aucune** garantie : ce qui
  garantit que deux moteurs s'accordent est le **contrôle croisé** — reliefs exhaustifs comparés
  dans les deux sens à chaque exécution — jamais la prose du fichier, qui n'était que de la
  documentation, utile à qui veut *réimplémenter*. La règle vit dans `placement_rules()`, que le
  niveau 3 du mode d'emploi lit à la source, et se fournit **sous licence**.
- **⚠ MAIS IL GARDE DE QUOI REFUSER** : `fall_rows` et `tiles`, les deux constantes que le lecteur
  compare aux siennes. Sans elles il ne peut plus distinguer un tileset qui n'est pas le sien, et
  un monde faux qui ne se signale pas est le pire des défauts.
- **LE SCEAU PORTE LES PIXELS, PAS LE TEXTE** (`core/signing.gd`, `addons/solupaint/signature.gd`).
  Le condensé couvre les **octets de la planche** + la table triée + la version : re-découper,
  ré-empaqueter ou échanger l'image le casse. ⚠ **Et c'est une AFFIRMATION, pas une serrure** — le
  plugin part en GDScript en clair, un refus sauterait en trente secondes, et la charte interdit de
  maquiller un verrou. Il **dit** la provenance (`provenance`, une troisième variable distincte de
  `last_error` et `last_warning`). ⚠ **La clé privée ne part jamais** : `SOLUTILES_KEY`, hors du
  dépôt, `*.pem` au `.gitignore`. Sans elle l'export sort **non signé et le dit** — c'est l'état
  normal du build d'essai, et la seule asymétrie qui compte : un cloneur peut fabriquer des
  tilesets, pas des **signés**.
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
  et **une couche par étage** remplace les trois de l'ancien modèle. Manifeste **v10** (le
  cisaillement est entré dans la clé), les versions antérieures refusées nommément ; une seule
  planche, une seule source d'atlas.
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

- **LES ROOMS SONT BÂTIES — `ui/rooms.gd`, et la grille « ATELIER » en haut de la barre de
  GAUCHE.** Une room est un **endroit**, pas un réglage : le travail — carnet, guide, mode,
  résolution — est **partagé**, et seule change la part de l'écran qu'on a sous la main.
  `Dessin` et `Test` sont ouvertes, `Animation` attend l'axe des frames. ⚠ **Le catalogue ne
  connaît ni nœud ni scène, seulement des NOMS** : c'est ce qui le rend mesurable sans monter
  l'éditeur — et le banc vérifie **contre `editor.tscn`, sans l'instancier** (`get_state()`)
  qu'aucune room ne nomme une section fantôme, **et dans les deux sens** qu'aucune section n'est
  orpheline. ⚠ **Et la grille s'efface tant qu'il n'y a qu'une room** : une liste à une seule
  entrée n'est pas un choix, c'est un décor — la règle était déjà écrite pour le réseau.
- **LA ROOM DE TEST EST BÂTIE — `ui/test_room.gd`.** On y pose un vrai relief au **tampon 3×3**
  (clic gauche monte, clic droit abaisse jusqu'au vide) et on le voit rendu **avec ses propres
  tuiles**. ⚠ **Elle pose avec `addons/solupaint/rules.gd`, jamais avec `core/massifs.gd`** :
  c'est un contrôle croisé **vivant**, sur le trait de l'artiste, avant livraison — et le refus
  affiché est celui du moteur (`stamp_refused` : case fine **et** pincement diagonal).
  ⚠ **L'aire se montre** (un liseré), sinon son refus se lit comme une panne. ⚠ **Filtrage au
  plus proche**, sinon le pixel art bave. ⚠ **Et elle s'ouvre vide, en disant quoi faire** : une
  colline posée d'office serait exactement l'aperçu supprimé le 05/09. Ce qui **reste** : ni
  annulation, ni zoom, et la carte d'essai ne survit pas à la fermeture (elle ira dans `user://`).
- **⚠ ET UNE TROISIÈME BANDE VIENDRA, AU-DESSUS DE LA ZONE : LES ENSEMBLES** (décision utilisateur
  du 06/09). Les **rooms** sont fixes et vivent à gauche — elles font partie du logiciel ; les
  **ensembles** s'ajoutent et se suppriment, et leur nom est du **texte libre**. ⚠ **C'est
  exactement pourquoi ils ne peuvent pas vivre dans une barre latérale** : *un libellé qui
  s'allonge impose sa largeur à toute la barre*, payé deux fois. Horizontalement, un nom qui
  s'allonge ne pousse rien. La bande reprend le pattern des deux autres : posée **sur** la zone,
  translucide au repos, `self_modulate` et non `modulate`, survol testé sur le **rectangle**, les
  **quatre** bords de l'ancre posés.
- **Deux barres : à gauche les options, à droite le travail.** ⚠ **Et « Projet » — ouvrir,
  enregistrer — comme « Moteur » — installer le plugin, bâtir l'essai — vivent à GAUCHE**
  (décision utilisateur) : ni l'un ni l'autre n'est peindre. Ouvrir un travail, c'est décider
  *sur quoi* on peint ; installer le moteur, c'est ce qu'on fait *une fois le tileset fini*.
  À droite il ne reste que ce dont la main se sert pendant qu'elle dessine — les deux jauges et
  l'export, les outils, les voisines, la vue.
  ⚠ **Et la liste des raccourcis y vit aussi, tout en bas** : la barre de droite est pleine — jauges, export, huit outils,
  palette, voisines, vue, travail, moteur — pendant que la gauche a de la place sous « Fond du
  guide ». Une aide qu'on ne lit qu'une fois n'a pas à disputer sa place à ce qu'on utilise
  cent fois. À gauche **ce qu'on fabrique** et
  **ce qu'on regarde** ; à droite **tout ce qui sert à peindre**. Mélangées, on cherche ;
  séparées, on trouve sans lire.
- **La barre est posée SUR la zone de travail, et translucide au repos** — c'est ce qui donne
  l'air d'un calque plutôt que d'un panneau. Trois conséquences apprises à la dure : la zone de
  travail occupe **toute** la largeur (la barre ne lui réserve que son cadrage initial) ; on
  teinte `self_modulate`, pas `modulate` ; le survol se teste sur le **rectangle**, pas avec
  `mouse_entered`, qui se déclenche à l'envers dès qu'on passe sur un enfant.
- **⚠ UN LIBELLÉ QUI S'ALLONGE IMPOSE SA LARGEUR À TOUTE LA BARRE.** Payé deux fois.
- **⚠ LES QUATRE BORDS D'UN PANNEAU ANCRÉ SE POSENT, PAS UN SEUL.**
- **⚠ ET DEUX CASES DE VUE ONT ÉTÉ RETIRÉES : « masquer les marques » et « masquer les
  ombres »** (décision utilisateur du 05/09/2026), parce qu'elles ne masquaient plus rien. Les
  deux appartenaient à l'ancien modèle : le dessin des massifs ne pose ni marqueur de coin ni
  tiret de rangée, et il n'a **pas de lumière portée** à éteindre — `_background_flat` y **est**
  `_background`. Une case qui ne change rien à l'écran est pire qu'absente : on la coche, on ne
  voit aucun effet, et l'on cherche la panne.
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
- **⚠ ET AU-DESSUS DU SEUIL, LE ZOOM SE CALE SUR UN MULTIPLE ENTIER DE LA RÉSOLUTION.** Un faux
  pixel qui vaut 1,42 pixel d'écran en occupe **un ici et deux là**, au hasard de l'arrondi : le
  dessin **bave** à l'intérieur des tuiles pendant que leur bordure, elle, reste franche — et
  c'est ce **contraste** qu'on prend pour une couture dès qu'on masque la grille. ⚠ **Aucun
  filtrage ne répare ça** : lisser étalerait la faute et montrerait des dégradés que la peinture
  n'a pas. Le seul remède est l'échelle entière, comme dans tout éditeur de pixel art. On monte
  vers l'entier supérieur et on descend vers l'inférieur, sinon un cran aller-retour ne revient
  pas au même endroit ; **on borne les crans, jamais le produit** — écrêter 32 × 63 à 2000 rendrait
  baveux le zoom le plus profond, celui où la faute se voit le mieux. Le **cadrage** garde sa
  liberté : il vise la vue d'ensemble, où rien ne peut être net de toute façon.
- **⚠ « MASQUER LA GRILLE » FAIT DEUX CHOSES, ET LA SECONDE N'ÉTAIT PAS FAITE.** Retirer les
  traits ne suffit pas à montrer le rendu : sous un pixel d'écran par faux pixel, l'échelle
  libre **recoupe la tuile** — `_cell_box` arrondit chaque case, donc la grille des faux pixels
  se remet d'aplomb à chaque bordure — et l'on croyait voir des coutures **apparaître** en
  masquant la grille, alors qu'elles étaient là avant et que la grille les cachait. Grille
  masquée, l'échelle se cale donc à **tous** les crans : multiples entiers de la résolution en
  montant, **diviseurs** entiers en descendant. ⚠ **Et c'est l'exposant qu'on borne, pas le
  diviseur** — écrêter D à 3 rendrait 5,33 pixels par case, et la couture rentrerait par la
  porte qu'on vient de fermer.
- **⚠ ET LE CRAYON RESTE EN MAIN.** Un mode « aperçu » qui rangeait le crayon a été bâti puis
  **supprimé le jour même** (décision utilisateur) : si la netteté ne coûte pas la peinture,
  elle n'a pas à se payer d'un mode où l'on ne peut plus rien faire. Une case à cocher qui
  retire une gêne, et rien d'autre. C'est la règle 1 de la charte, appliquée à une vue.
- **⚠ ET LE PARTAGE DES BORDS N'ÉTAIT PAS LA CAUSE.** `core/seams.gd` — les pixels que le modèle
  prouve identiques d'une tuile à l'autre — repose sur `Walls`, donc sur l'**ancien** modèle :
  dans la famille des massifs `_wall_roles` est vide et `_echo_seams` rend `false` au premier
  test. Il n'y a **plus rien à débrancher** ; ce qu'on voyait était l'échelle libre, et c'est
  elle que l'aperçu cale.
- **⚠ ET LE « BANC SATYRON » A QUITTÉ LA LISTE DES FONDS** (décision utilisateur du 05/09/2026) :
  le libellé ne dit rien à personne. Une entrée grisée ne dit « ceci viendra » que si l'on sait
  ce qu'est « ceci » ; ici l'acheteur lisait un nom propre qui ne le concerne pas. Le code de
  rendu reste (`render/guide_render_job.gd`, `render/satyron_tiles.gd`) — il sert de référence
  quand un doute survient sur une falaise, et se rappelle d'un outil.
- **⚠ ET LA BOÎTE D'UNE CASE SE POSE SUR DES PIXELS ENTIERS, pas à la fraction.** Les deux bords
  se calculent par la même formule puis s'arrondissent : la frontière droite d'une case **est** la
  frontière gauche de sa voisine, par construction et à tout zoom. Sans ça l'efface du vide et la
  tuile posée par-dessus ne couvrent pas les mêmes pixels, et un liseré de fond dépasse d'un côté.
  ⚠ **Mais on ne fige pas `_tile_px` : c'est le TRACÉ qui se cale, pas l'échelle** — et la grille
  se cale avec, sinon elle flotte à côté des tuiles et cesse de dire où sont les bordures.
- **Clic gauche pose, clic droit efface** — éprouvé à la main, l'inverse se trompait de réflexe.
- **TOUTE ATTENTE IMPOSÉE SE DIT, ET SOUS SON NOM.** Sept l'ignoraient : nouveau projet,
  enregistrement, changement de technique, de style, de taille des faux pixels, installation du
  plugin, export de l'essai. ⚠ **Deux causes distinctes, et la seconde est la traîtresse** —
  quatre n'annonçaient rien du tout, trois **annonçaient sans être peintes** (voir le piège
  `process_frame` ci-dessous). Un défaut qui ne se voit pas à la lecture du code : l'appel est
  bien là.
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
- **⚠ `await get_tree().process_frame` NE GARANTIT PAS QUE L'ÉCRAN A PEINT.** Le signal est émis
  au **début** du traitement d'une image ; attendu depuis un clic ou un signal, on reprend la
  main dans la **même** image, avant son dessin. Un panneau d'attente posé puis suivi d'un
  travail bloquant n'était donc **jamais peint une seule fois** — et la moitié des barres de
  progression étaient invisibles alors qu'elles étaient écrites (relevé par l'utilisateur sur
  l'installation du plugin et l'export de l'essai). La preuve qu'une image est **dessinée**,
  c'est `RenderingServer.frame_post_draw`. On attend les deux : `process_frame` pour que la mise
  en page soit faite, `frame_post_draw` pour qu'elle soit à l'écran.
- **⚠ `gui_input.emit()` N'APPELLE PAS LA VIRTUELLE `_gui_input`.** Le signal et la méthode
  reçoivent les mêmes événements quand c'est la souris qui parle, mais émettre le signal à la
  main ne déclenche que ses **branchements**. Une relecture qui pose ses clics ainsi capture
  donc un écran vide **sans une seule erreur**. On branche : `gui_input.connect(...)`, comme le
  bandeau du mode d'emploi.
- **⚠ OUVRIR UN TRAVAIL EST ASYNCHRONE, ET CE QUI LIT LE CARNET JUSTE APRÈS LIT DU VIDE.**
  `_on_open_chosen` attend trois fois (l'en-tête, le paysage, les tuiles) ; une vue montée
  entre-temps affiche un monde sans une seule tuile, et rien ne le signale. Ce qui dépend du
  carnet se rafraîchit donc **à la fin de l'ouverture**, pas au moment où on la demande.
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
  licence autorise l'usage et interdit la redistribution — et c'est pour ça qu'il a quitté la
  liste des fonds le 05/09/2026. Les exemples livrés sont **les nôtres**, donc ils s'ouvrent
  partout ; le code de rendu Satyron reste, comme référence quand un doute survient.
- **`ARCHIVE.md`** — le dossier long des modèles antérieurs, et le détail de tout ce qui est
  résumé ici.

## Questions ouvertes

Les fiches détaillées (sweet spot de la grammaire, niveau 0 du mode d'emploi, motifs carrés) sont
dans `ARCHIVE.md` ; les chantiers de la seconde partie sont spécifiés en long dans la dernière
section de `PLAN.md`, et résumés ici. Ce qui reste vif :

- **CE QUI RESTE, DANS L'ORDRE — et c'est l'ordre que l'utilisateur a fixé** (PLAN.md, dernière
  section). La **première partie est bâtie** : le modèle, le guide, l'éditeur, `work_io` (v5),
  l'export (`massif_tileset`, manifeste v10), l'essai, la planche packed, le mode d'emploi et le
  plugin SoluPaint. Ce qui reste de l'ancien noyau (`Walls`, `Coverage`, `CornerIndex`, `Brink*`,
  `Thickness`) n'est plus lu par le produit : il vit comme **témoin**, avec le guide `epais.txt`,
  jusqu'au démontage. Reste donc :
  1. **le cadre des rooms** — une grille de boutons en haut de la barre de gauche ; ⚠ **il ne
     coûte ni version de fichier, ni tuile, ni bit dans la clé** ;
  2. **la room de test** — poser un vrai relief au pinceau du moteur et le voir rendu avec SES
     tuiles ; ⚠ **elle pose avec `addons/solupaint/rules.gd`, jamais avec `core/massifs.gd`**,
     sinon elle prouve que le noyau s'accorde avec lui-même. Elle ne coûte rien non plus, elle
     devient le **banc de recette** de tout ce qui suit, et ⚠ **c'est elle qui débloque le
     solde** — le coin haut se regarde sur du trait remonté, au clic ;
  3. **solder la première partie** — le **coin haut du cisaillement** (relevé puis différé par
     l'utilisateur : là où le trait du cisaillement croise celui de la lèvre, une tuile reste
     fausse ; ⚠ **à regarder sur SON trait remonté, jamais sur le dessin calculé**, qui est la
     spécification et a toujours l'air juste) ; la **version 11.0.0**, majeure, puisque le sens de
     la clé a changé ; `PIED 21 au ras` ; la fusion de la chasse, qui **ne relit pas l'existant** ;
     et la tuile `132095`, que le pinceau livré atteint et que la planche ne porte pas.
     ⚠ **Il passe APRÈS les deux rooms** — décision utilisateur du 2026-09-06, qui renverse
     l'ordre du 05/09. ⚠ **Et c'est TOUT ce qui reste du terrain** : rien de ce qui suit ne
     l'agrandit ;
  4. **l'axe** — ⚠ **une SEULE refonte du carnet, tranchée le 2026-09-06** : la frame, le calque
     **et l'ensemble** d'un coup (`work_io` v6, manifeste v11) — le **bassin d'eau** demande déjà
     les deux premiers (c'est un calque, et ses trois zones sont animées), et le troisième coûte
     quelques lignes maintenant contre une migration plus tard ;
  5. **l'animation par frame** — décidée et spécifiée par l'utilisateur ;
  6. **les ensembles** — un tileset complet par art, plusieurs dans le même monde ; ⚠ **avant le
     patch**, pour que « un patch de type A ne va que dans un massif de type A » s'écrive une fois ;
  7. **le patch** — le mécanisme (placement **propre à chaque type**, vocabulaire propre), et le
     premier d'entre eux : les **bassins d'eau**, dont la bordure est dans l'empreinte ;
  8. **les trous** — un patch, pas un creux, et **collables au bord** ;
  9. **les matières de surface** — ⚠ **ce que les « chemins » sont vraiment** : n'importe quel
     art, n'importe quelle forme, largeur minimale 3 ;
  10. **les grottes** — le premier patch de **façade**, en deux types (au pied ; en hauteur avec
      balcon) ;
  11. **le paysage** — la seconde disposition ;
  12. **les cascades et les rivières** — ⚠ **les seuls patchs qui TRAVERSENT**, donc les plus
      compliqués, et ils demandent le paysage ;
  13. **plus loin** : l'Exemple High Res, le plugin Unity, la suite de la signature.
- **Le sweet spot de la grammaire.** Le vocabulaire est calculé comme *tout ce que le modèle peut
  produire*, jamais comme *ce qu'on accepte de construire*. Les trois clauses candidates ont été
  chiffrées et rendent peu ; le levier n'est pas *ce que le monde a le droit d'être* mais *ce
  qu'une tuile a le droit de savoir* — et il se paie en contours ouverts. ⚠ **Les chutes de
  plusieurs étages sont non négociables** (décision utilisateur) : toute clause qui les
  limiterait est écartée d'office.
- **LA ROOM DE TEST** — *demandée par l'utilisateur le 2026-09-06*. On pose un vrai relief au
  **pinceau du moteur** (le tampon 3×3 de `core/gesture.gd`) et on le voit rendu avec **ses
  propres tuiles**. ⚠ **ELLE POSE AVEC `addons/solupaint/rules.gd`, JAMAIS AVEC
  `core/massifs.gd`** : branchée sur le noyau, elle prouverait que le noyau s'accorde avec
  lui-même ; branchée sur la copie qui part chez l'acheteur, elle est un **contrôle croisé
  vivant**, sur le trait de l'artiste, avant livraison. ⚠ **Ce n'est PAS l'aperçu supprimé le
  05/09** — celui-là reposait tout seul les mêmes tuiles sur une colline fixe, et disait ce que le
  guide dit déjà ; ici l'artiste pose le relief, et il voit ses tuiles **voisines**, dans des
  combinaisons que le damier juxtapose sans les composer. ⚠ **Le cisaillement du massif 21 a été
  relevé exactement comme ça.** Elle ne coûte ni version, ni tuile, ni bit : elle vient donc tôt,
  et elle devient le banc de recette des fluides, des cascades, des grottes et des trous.
- **L'ANIMATION PAR FRAME.** Des **rooms** en haut de la barre de gauche (Dessin, Animation), un
  nombre de frames **global au guide** mais utilisé par les seules tuiles *déclenchées*, et un
  outil « Frame List » sous « Voisines ». ⚠ **Elle rouvre la décision la plus structurante du
  carnet** : `Painting` ne tient qu'**une** image par tuile, il en faudra N. La frame devient un
  **second axe**, jamais une variante déguisée — « les variantes sont supprimées » reste vrai, N
  frames sont N instants du **même** dessin, et la règle des jumelles doit continuer de tenir.
  Elle coûte `work_io` **v6** (les v5 se traduisent : non animée = une frame) et manifeste **v11**
  (⚠ le lecteur doit pouvoir **refuser**, donc le nombre de frames en clair, comme `fall_rows`).
- **L'exemple, peint à la main. LE LOW RES EST LIVRÉ** — `examples/low_res.solutiles`, 16 px,
  **55 tuiles sur 55**, et il se reprend au fil des passes de peinture. Reste l'**Exemple High Res**,
  dont la place est déjà tenue et grisée, et le passage en conditions réelles dans l'addon, par
  tâtonnements successifs. Le banc où chaque itération se regarde : `tools/make_trial_scene.gd`.
- **Deux modes de disposition : paysage et damier de spécimens.** La résolution de la double
  injonction — *demander à un seul dessin d'être à la fois beau et exhaustif*. C'est l'axe du
  **mode**, pas un réglage, et c'est **gratuit pour le travail en cours** : le carnet range par
  tuile, donc un travail commencé sur l'un se recharge sur l'autre. ⚠ **Borné à sa propre
  recherche**, à la condition que le vocabulaire soit clos — il l'est bien plus depuis le vivier
  commun. Les fluides comme les grottes en dépendent : ils demandent tous deux « et en paysage,
  comment ? ».
- **⚠ ET LA RUBRIQUE « STYLE » EST SUPPRIMÉE EN ENTIER** (décision utilisateur du 05/09/2026).
  Le fond n'a plus qu'une encre : le dessin **peint**, celui qu'on regardait par défaut. Les
  deux autres vues — *fil de fer*, *contour prouvé* — appartenaient à l'ancien modèle et
  vivaient dans la même liste pour qu'on puisse comparer **deux modèles** à l'écran ; il n'y en
  a plus qu'un. La technique s'appelle désormais **« Contour de base »**.
- **⚠ LE LIBELLÉ D'UN MODE N'EST PAS SON IDENTIFIANT.** « Massifs » se lit désormais
  **« Damier »** — c'est ce que l'artiste voit, et c'en est un : un îlot par tuile, pas encore
  un paysage. L'identifiant `massifs`, lui, **ne bouge pas** : il est écrit dans l'en-tête de
  chaque `.solutiles` et dans le chemin du guide, le renommer rendrait illisible tout travail
  déjà enregistré. Les deux se vérifient **séparément** au banc.
- **⚠ LES DEUX STYLES DE TRAIT SONT RETIRÉS** (décision utilisateur du 05/09/2026). F2 — le trait
  qui ondule entre deux rendez-vous — est supprimé. Il ne coûtait aucune tuile, c'était le même
  vocabulaire ; mais **le dessin calculé ne sert que d'aperçu**, l'artiste peint par-dessus et son
  trait remplace le nôtre. Soigner un aperçu que personne ne livre est du travail pour rien.
  **F0 reste** : ce n'est pas un style, c'est le plancher — la profondeur d'un pixel — et le banc
  doit prouver que les invariants y tiennent aussi.
- **L'arbre des fonds de guide** : « Contour de base » — notre dessin calculé, une seule encre
  depuis la suppression de la rubrique « Style » — puis **un exemple par résolution**, listés par
  `core/examples.gd`. ⚠ **Plus de `wireframe`, plus de `straight | ondulated`** : les deux
  appartenaient à l'ancien modèle, voir les lignes ci-dessus. ⚠ **Et tout doit montrer la
  liberté dès qu'elle est disponible** : le fond n'est pas une décoration,
  c'est la spécification, et une liberté qu'on ne montre pas est une liberté que personne
  n'utilisera.
- **LE TERRAIN EST FINI : TOUT CE QUI SUIT EST UN PATCH** (décision utilisateur du 2026-09-06, et
  c'est le cadre de toute la seconde partie). Le modèle ne gagne plus une tuile. Un **patch** est
  une matière posée **SUR** la surface d'un étage : il a son **vocabulaire propre**, il ne touche
  jamais à celui du terrain (occlusion par ordre de rendu), et la seule question qu'il pose est
  celle du **PLACEMENT**. ⚠ **ET IL N'Y A PAS DE MARGE UNIVERSELLE** : chaque type a **sa** règle,
  décidée avec lui — le bassin porte sa **bordure dans son empreinte**, le trou peut être **collé
  au bord**, la matière de surface a une **largeur minimale de 3**, la grotte demande **assez de
  roche** (un refus, pas un calcul). ⚠ **Et le carnet le disait déjà** (ARCHIVE, « LES MATIÈRES
  BORDÉES ») : *une matière est un étage sans falaise* — les étages s'**empilent**, les matières
  sont **côte à côte**, donc **aucune tuile de façade en plus**, et `BlobIndex.canonicalize` s'y
  applique sans une ligne de code. ⚠ **TOUT EST PENSÉ POUR ÊTRE DESSINÉ DE N'IMPORTE QUELLE
  MANIÈRE**, et le carnet dit comment on paie ça : **en RÉSERVANT** — *« c'est le “strictement
  réservé” qui rend le geste possible »*. **En damier**, un patch se montre par des **témoins
  réservés** ; **en paysage** il faut l'**incorporer**, et c'est le difficile. L'ordre décidé :
  **bassins d'eau → trous → matières de surface → grottes → le paysage → les cascades et les
  rivières.**
- **LES ENSEMBLES — un tileset complet par ART, plusieurs dans le même monde** (décision
  utilisateur du 2026-09-06). Un **ensemble** est le terrain **et** tous ses patchs, peints dans un
  art à eux : un massif d'herbe à côté d'un massif de désert. ⚠ **Ça ne coûte pas une tuile au
  modèle** — tous les ensembles partagent les mêmes clés, seul l'art diffère : c'est un carnet de
  plus, jamais un vocabulaire de plus. ⚠ **Et ça sépare enfin deux choses que `core/modes.gd`
  mélange** : le **MODE** est une *disposition* (Damier, Paysage), l'**ENSEMBLE** est un *art*.
  ⚠ **ROOMS FIXES À GAUCHE, ENSEMBLES DANS UNE BANDE FLOTTANTE AU-DESSUS DE LA ZONE** : les rooms
  (Dessin, Animation, Test) font partie du logiciel ; les ensembles s'ajoutent, se suppriment et se
  renomment. La raison est mesurable — le nom d'un ensemble est du **texte libre**, et *un libellé
  qui s'allonge impose sa largeur à toute la barre* ; horizontalement, il ne pousse rien. ⚠ **Et la
  même bande sert deux fois** : en room Dessin elle dit *sur quel ensemble je peins*, en room Test
  *quel ensemble je pose*. **Un patch de type A ne se pose que dans un massif de type A** — une
  condition dans la fonction de placement, donc gratuite, et c'est pourquoi les ensembles passent
  **avant** le patch. **Supprimer un ensemble jette du travail** : c'est la règle de « Nouveau
  projet », telle quelle, avec le nombre de cases en jeu et sa fonction à part. **Le nom se donne à
  la création et nulle part ailleurs** (règle 1). ⚠ **La v6 porte donc TROIS axes** :
  `<ensemble>/<calque> M<tuile>:<rang>@<frame>`, valeurs par défaut telles que la relecture d'un v5
  reste l'identité.
- **⚠ LES COUTURES ENTRE ENSEMBLES SONT L'AFFAIRE DE L'ARTISTE, ET LE MODÈLE DOIT LES LUI LAISSER**
  (décision utilisateur du 06/09). Deux ajustements, tous deux petits. ⚠ **`footprint()` doit
  tester le NIVEAU du voisin sud, pas son appartenance au massif** : aujourd'hui
  `if surface.has(at + Vector2i.DOWN): continue` ; coupez les composantes par type et le massif du
  nord pose **deux rangées de roche sans pied** sur le terrain plat de son voisin (vérifié en
  déroulant la boucle de chute : `bottom = level`, `ground = level`, aucun `break` avant `k = 3`).
  Aucune peinture ne rattrape ça. ⚠ **Et le correctif est un NO-OP aujourd'hui** — les trois cas
  (vide, niveau inférieur, niveau supérieur) donnent le même résultat tant qu'il n'y a pas de type.
  ⚠ **Puis UN SEUL CÔTÉ TRACE, et l'ordre des ensembles le dit** : deux bords adjacents qui tracent
  tous les deux font le pavé 2×2 que I2 refuse, et l'artiste ne choisit pas son voisin. La loi est
  déjà écrite pour le cisaillement — *la roche marque sa fin, l'herbe prend une ombre* — et l'ordre
  est celui des matières, **l'ordre de création**. Le reste est bien de l'artiste : la même tuile de
  bord sert déjà contre du vide et contre autre chose. ⚠ **Et les cascades ne traversent qu'entre
  massifs du MÊME ensemble** — plus généralement, tout patch qui traverse reste dans un ensemble.
- **LES BASSINS D'EAU** — le premier patch, et ⚠ **SA BORDURE D'UNE TUILE FAIT PARTIE DE SON
  EMPREINTE** (décision du 06/09). C'est **la même loi que la falaise** : l'empreinte d'un massif
  est *surface ∪ falaise* et la silhouette se lit dessus ; celle d'un bassin est *eau ∪ bordure*.
  Deux conséquences gratuites — les **trois zones réservées** pour l'animation (herbe → bordure,
  bordure → eau, eau pleine) **sont** les trois anneaux de cette empreinte, pas trois tuiles
  ajoutées ; et ⚠ **« pas d'océan » cesse d'être une interdiction pour devenir une conséquence** :
  le bassin ne touche pas le bord parce que sa bordure doit tenir dans la surface. Le reste tient :
  **une seule matière** (la couleur appartient au peintre), **de l'eau sur la plaine** (jumelle,
  donc gratuite), **l'eau au pied d'une falaise gratuite** — le pied se pose après la couche d'en
  dessous. ⚠ **Et la bordure sera PERCÉE par les rivières**, seul endroit où l'anneau s'ouvre.
- **LES TROUS** — un patch, **pas un creux dans le relief**, et ⚠ **ILS PEUVENT ÊTRE COLLÉS AU
  BORD** (décision du 06/09). C'est leur seul coût, et il est réel : une case de terrain au bord
  porte le trait de sa lèvre, un trou posé dessus le **remplace**, donc **le trou est le seul patch
  dont le vocabulaire connaît le bord** — à mesurer avant de dessiner. ⚠ **L'autre voie a été
  mesurée avant d'être fermée** (`tools/hole_probe.gd`) : un trou *creusé* ne coûterait rien non
  plus — zéro tuile absente sur une cuvette 5×5, un trou de deux étages, un puits jusqu'au vide ;
  une seule sur 21 reliefs troués. Le patch est retenu **pas pour le coût** mais parce que creuser
  rouvrirait `Gesture.chasms()`, la grammaire de profondeur (`FALL = 3` impose un trou *court ou
  franc*) et le pinceau du moteur. ⚠ **La dette qu'a laissée la mesure est du TERRAIN** : la battue
  ne creuse jamais jusqu'à la plaine (`Gesture.walk` tire l'effacement dans `randi_range(1, …)`,
  `_where` exige un centre d'étage ≥ 1) alors que le pinceau livré offre **0..N** *et* « Vide » —
  la tuile `132095` manque donc à la planche. Réparation au **solde de la première partie**.
- **LES MATIÈRES DE SURFACE** — ⚠ **ET CE NE SONT PAS DES « CHEMINS »** (correction utilisateur du
  06/09) : elles **modifient la surface**, avec n'importe quel art, n'importe quelle forme et
  n'importe quelle étendue, là où il y a la place. Un chemin est une matière **étroite qui
  serpente** ; une tache, du sable, de la neige, une clairière : le même vocabulaire. **Largeur
  minimale 3** — la tuile pleine et ses deux bords ; en dessous il n'y a plus de tuile pleine, donc
  plus une matière mais une *direction*, et c'est un autre objet. ⚠ **Le vocabulaire prévoit
  TOUT** : serpentements, **coudes**, **bouts**, **embranchements** — c'est une exigence de
  complétude, donc la battue doit les atteindre tous les quatre et l'assertion doit le dire. Borne
  haute connue : **27 index** (théorème des 256 fenêtres sous min trois). ⚠ **Les matières restent
  ORDONNÉES** (sable sur herbe, eau sur sable), sinon un jeu de transition **par paire** ; l'ordre
  est l'ordre de création. ⚠ **Et les MOTIFS CARRÉS attendent ici** : une matière étendue répète son
  intérieur pur, exactement là où le carnet avait noté le motif `N × N` indexé par
  `(x mod N, y mod N)` — ce n'est pas une variante, la position décide.
- **Les escaliers et les pentes douces** : un **troisième** vocabulaire, pas un patch — ils
  touchent au relief, et ça se **déclare**, comme `~` l'a été pour le vide.
- **LES GROTTES — DEUX TYPES** (précision utilisateur du 06/09), et la fiche du 31/08 tient
  entière : **la grotte de PIED**, au pied d'une falaise avec assez de place à droite et à gauche
  dans la falaise ; et **la grotte EN HAUTEUR**, dans la hauteur de la falaise, avec un **petit
  BALCON au perron**. ⚠ **LE NEUF-TRANCHES : 4 coins + 4 côtés + 1 milieu = 9 tuiles quelle que
  soit la taille** — le plafond est la tranche du haut, le **perron** celle du bas. ⚠ **L'anneau est
  STRICTEMENT RÉSERVÉ, et c'est ce qui autorise à peindre un plafond** : partagé avec les corps
  ordinaires, il apparaîtrait sur toutes les parois du monde. La place se calcule (des rangées de
  **CORPS** consécutives : une chute de trois n'en a qu'une, donc une grotte en hauteur demande
  **deux étages** de falaise ; trois colonnes de la **même face**, jamais à cheval sur deux lèvres),
  et ⚠ **« assez de place » est un REFUS, pas un calcul**, dit au relâchement. Dedans : **un trou
  noir est gratuit**, un intérieur qui laisse voir est une matière. ⚠ **À trancher : le balcon
  est-il une tranche de plus, ou le perron qui change de dessin ?** — la seconde garde le
  neuf-tranches intact. ⚠ **Et le PASSAGE est hors sujet** : SoluTiles livre une façade, pas un jeu.
- **LES CASCADES ET LES RIVIÈRES** — *les plus compliquées, donc à la fin* (décision du 06/09 : les
  cascades quittent les fluides pour rejoindre les rivières). ⚠ **CE SONT LES SEULS PATCHS QUI
  TRAVERSENT** : une cascade franchit la lèvre, descend la falaise et rejoint le bassin d'en bas ;
  une rivière traverse le paysage au lieu de s'y poser. ⚠ **Le premier article de leur règle de
  continuité est donné : LA RIVIÈRE PERCE LA BORDURE DU BASSIN** — l'anneau, fermé partout
  ailleurs, s'ouvre là, et le vocabulaire du bassin gagne ses tuiles de **percée**. Déjà acquis :
  la cascade **emprunte la bande du terrain**, donc une chute de plusieurs étages est gratuite et
  une cascade qui tombe dans le vide ne pose pas son pied ; le bassin au pied est un patch d'eau
  ordinaire ; ⚠ **une cascade fixe est morte**, elle demande l'axe des frames. ⚠ **Et le reste ne se
  mesure pas tant que le paysage n'est pas là** : une rivière sans paysage n'a rien à traverser.
- **La signature, suite.** Le sceau **existe** (`core/signing.gd`, `addons/solupaint/signature.gd`,
  manifeste v10) : il porte les pixels et **dit** la provenance, il ne bloque pas. Ce qui reste :
  poser la **clé publique définitive**, et sauvegarder la privée **ailleurs que sur la machine**.
  ⚠ **Un verrou dans l'addon ne protège de rien** — il part en GDScript en clair, et la charte
  interdit de maquiller un contrôle qui saute en trente secondes. Ce que la signature sépare, c'est « lire
  un fichier texte » de « craquer un binaire ». La pièce la plus forte : le build d'essai **n'a
  pas de clé privée du tout**.
- **Le plugin Unity.** Rien de commencé. Le contrôle croisé du plugin Godot est le modèle à
  reprendre : c'est lui qui empêche les deux lecteurs de diverger.
