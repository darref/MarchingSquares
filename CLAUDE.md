# AbsoluTiles — contexte de travail

## Contexte

Outil desktop de génération de tilesets autotile, écrit en Godot 4 / GDScript.

Principe du produit : l'utilisateur peint un paysage par-dessus un guide fixe affiché en
transparence derrière une grille. L'outil en extrait un tileset autotile complet (blob 47
tuiles) et l'exporte. Aucun pixel n'est composité, miroité ou généré : tout ce qui sort a
été peint à la main. Le guide est un artefact conçu en amont, à la fois lisible comme un
paysage et prouvé mathématiquement complet.

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

## Structure du dépôt

```
core/         logique pure, zéro dépendance UI, utilisable en headless
  blob_index.gd   voisinage 8 bits, canonicalisation, les 47 index
  symmetry.gd     rotations et miroirs, et les conditions qui les rendent licites
  painting.gd     les faux pixels posés dans chaque tuile
  mask_io.gd      lecture / écriture / accès d'un masque de guide (texte)
  coverage.gd     rapport de couverture d'un masque
  height_mask.gd  guide en relief : une hauteur par case, silhouette par étage
  walls.gd        le second vocabulaire : les robes de falaise (3 pans × 4 rangées)
  variants.gd     quelles cases peintes deviennent des tuiles
  modes.gd        catalogue des modes (guide + règles d'exportation)
render/       illustration du guide -- présentation, pas logique
  guide_image.gd  dessine le relief en Image (headless, sans nœud)
  guide_render_job.gd  le même dessin, par étapes, pour pouvoir le regarder avancer
  preview.gd      écrit l'illustration sur disque
ui/           l'éditeur
  editor.tscn     la fenêtre : bandeau, barre d'outils, zone de travail
  editor.gd       câblage ; aucune règle de produit ne vit ici
  work_area.gd    grille, zoom, fond du guide, pose des faux pixels
  sidebar.gd      la barre translucide, pleine sous le curseur
  tool_section.gd une section d'outils repliable
  screenshot.gd   capture la fenêtre, pour se relire
guides/       guides au format texte ('.' plaine, '1'..'9' plateaux ; '#' = étage 1)
  minimal.txt          guide du mode « minimal » : relief 35x28, 47/47 et 12/12
  ample.txt            guide du mode « ample » : relief 66x31, 3 occurrences minimum
  minimal_preview.png  son illustration, régénérable à tout moment
  candidate_01.txt     brouillon plat dessiné à la main, 28/47, conservé comme trace
tests/        tests headless
  run.gd          runner, code de sortie non nul en cas d'échec
exporters/    vide pour l'instant
```

## Conventions

- **GDScript uniquement.** Pas de GDExtension, pas de C++, aucune dépendance externe.
- **Typage statique partout.** Imposé par le moteur : `project.godot` déclare
  `debug/gdscript/warnings/untyped_declaration=2`, donc une déclaration non typée est une
  erreur de parsing, pas un avertissement. Vérifié : un `var x = 3` refuse de charger.
- **snake_case** pour les fichiers, fonctions et variables ; `PascalCase` pour les
  constantes de script préchargées ; `SCREAMING_SNAKE_CASE` pour les constantes.
- **Un fichier = une responsabilité.** `core/` ne connaît ni nœud, ni scène, ni rendu.
- **Indentation par tabulations**, comme le style officiel Godot.
- Membres privés préfixés par `_`.
- Repère de grille : `x` croît vers l'est, `y` croît vers le sud. Toute coordonnée
  hors-grille est vide.

## Tests

```
godot --headless --path . --script res://tests/run.gd
```

Sortie 0 si tout passe, 1 sinon.

Sur cette machine, le binaire n'est pas dans le `PATH` ; la commande exacte est :

```
"C:/Users/jorda/Desktop/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/run.gd
```

Utiliser la variante `_console.exe` sous Windows : l'exécutable normal n'écrit pas sur la
sortie standard du terminal.

Le runner affiche aussi, à titre informatif, la couverture du guide candidat et la liste
des index manquants décomposés en bits (`117 = N+E+S+SW+W`), pour savoir quoi dessiner à
la retouche suivante.

## Lancer l'éditeur

```
godot --path .
```

La scène principale est `ui/editor.tscn`. Pour se relire sans lancer à la main :

```
godot --path . --script res://ui/screenshot.gd -- sortie.png
```

## Illustration du guide

```
godot --headless --path . --script res://render/preview.gd
```

Écrit `guides/minimal_preview.png`. Accepte trois arguments après `--` : le guide à rendre,
le fichier de sortie, et le style (`usable` pour l'autre).

Et pour se relire dans l'éditeur, style compris :

```
godot --path . --script res://ui/screenshot.gd -- sortie.png usable
```

## Décisions prises

Chaque entrée note le choix et sa raison, pour ne pas le rejouer plus tard.

- **Voisinage et canonicalisation** — bits dans le sens horaire depuis le nord
  (N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128). Un bit de coin n'est conservé que si
  les deux cardinaux adjacents sont pleins. Raison : un coin diagonal isolé ne change pas
  la silhouette de la tuile, il ne doit donc pas produire une tuile de plus à peindre.
  Les 256 voisinages bruts se réduisent ainsi à exactement 47 index.

- **Les 47 index sont calculés, jamais écrits en dur** — `BlobIndex.CANONICAL_INDICES`
  est rempli par `_static_init()` au chargement de la classe. Raison : une liste écrite à
  la main est une donnée à maintenir et un endroit où mentir ; ici la liste est une
  conséquence de `canonicalize()`. GDScript n'accepte pas d'expression calculée dans un
  `const`, d'où le `static var` + `_static_init()` (Godot 4.1+).

- **Aucun `class_name`, préchargement explicite** — les scripts de `core/` sont référencés
  par `const X := preload("res://core/x.gd")`. Raison : le cache global des noms de classe
  est produit par l'éditeur ; sur un clone frais lancé directement en headless il n'existe
  pas, et un `class_name` ne se résoudrait pas. Le préchargement fonctionne toujours.

- **Un masque est une `PackedStringArray`**, une ligne par rangée, pas une classe dédiée.
  Raisons : c'est exactement le format du fichier, donc rien à traduire ; comparable et
  copiable par valeur, ce qui rend les tests directs ; et sans `class_name` une classe ne
  pourrait pas se typer elle-même en valeur de retour. Le hors-grille est vide, ce qui
  rend le complément des lignes courtes équivalent à l'absence de ligne.

- **Le parseur de masque est strict** — seuls `#` et `.` sont acceptés ; tout autre
  caractère déclenche un `push_error` situé (ligne, colonne) et est lu comme vide. Les
  lignes vides sont ignorées. Conséquence assumée : **un fichier de guide ne peut pas
  contenir de commentaires**, puisque `#` signifie déjà « plein ». La documentation d'un
  guide vit ici, pas dans le guide.

- **Le rapport de couverture contient aussi les positions** de chaque index, en plus du
  nombre d'occurrences demandé. Raison : les occurrences multiples doivent servir de
  variantes plus tard, et un compteur sans coordonnées ne permet pas d'aller chercher la
  variante. `occurrences` reste exposé tel quel pour la lisibilité des tests.

- **`mask_io.with_cell()`** retourne une copie du masque avec une case changée. Ajout
  délibéré au-delà du strict nécessaire de cette session : l'écriture d'« un masque
  modifié » suppose de savoir le modifier, et le pinceau en aura besoin. Trois lignes,
  sans état.

- **`blob_index.is_canonical()`** — prédicat direct de la règle 5 de la charte : le
  pinceau devra refuser toute configuration non couverte, et cette question doit avoir une
  réponse en une fonction, pas en une recherche dans une liste.

- **La couverture du guide candidat est affichée, pas assertée** — le guide est un travail
  en cours ; en faire un test rendrait la suite rouge en permanence. Quand le guide
  définitif sera figé, sa complétude deviendra une assertion (règle 4).

- **Le candidat 12x12 est lisible avant d'être complet** — `guides/candidate_01.txt` est
  dessiné à la main (promontoire avec lagune, cordon de sable, croisement, îlot) et couvre
  **28/47**. Mesure faite pendant cette session, avec un chercheur local jeté après usage :
  47/47 **est** atteignable en 12x12, mais tous les masques complets trouvés à cette taille
  sont denses et bruités — ils ne se lisent plus comme un paysage. Autrement dit, à 12x12
  la contrainte de complétude et la contrainte de lisibilité se disputent la place. Si
  l'itération à la main bute, agrandir le guide est le bon levier, pas le bruiter.
  Ce fichier reste un brouillon : le guide du mode « minimal » est `guides/minimal.txt`.

- **Un mode = un guide + des règles d'exportation** (`core/modes.gd`). L'interface en fera
  une liste déroulante ; le noyau ne tient que la table. Un seul mode pour l'instant,
  `minimal`, le blob 47. Le choix du mode se fait une fois, avant de dessiner : c'est le
  choix de ce qu'on fabrique, pas un réglage à ajuster en cours de route (règle 1).
  Les règles d'exportation ne sont **pas** dans la table pour l'instant : `exporters/` est
  vide, et les inventer maintenant reviendrait à décider à la place de l'usage.

- **Une variante n'est retenue que si elle a été peinte** (`core/variants.gd`). Quand
  plusieurs cases du guide portent le même index, ce sont des variantes *possibles* ; une
  case sur laquelle l'utilisateur a posé au moins un pixel est prise, une case laissée
  vierge n'est simplement pas utilisée. Rien n'est fabriqué à sa place (règle 3), et
  peindre **est** l'acte de sélection, donc il n'y a rien à configurer (règle 1).
  Conséquence importante : **un guide complet ne suffit pas à exporter.** La complétude se
  juge sur ce qui a été peint, pas sur le guide. Il faut au moins une occurrence peinte
  par index — d'où `is_exportable` dans le rapport de `variants.resolve()`.
  Le noyau ne connaît pas les pixels : la couche de dessin répond « cette case porte-t-elle
  au moins un pixel ? » et transmet la liste des cases. C'est toute l'interface.
  Peindre hors du guide est signalé (`outside`) plutôt que jeté en silence — le pinceau
  est censé l'avoir refusé (règle 5), et on ne perd pas du travail sans le dire.

- **`guides/minimal.txt` fait 16x16 et couvre 47/47** — vérifié par le runner, qui en fait
  une assertion et non un affichage (règle 4). Construction : un promontoire dessiné à la
  main a été **gelé** (coin haut-gauche, 7x8), et seule la zone restante a été optimisée
  par recherche locale jusqu'à la couverture complète, avec une pénalité de périmètre pour
  limiter le bruit. Raison de ce découpage : un guide blob-47 complet contient forcément
  toutes les configurations exotiques — lac d'une case, isthme d'une case, îlot isolé,
  chaque combinaison d'encoches diagonales. Aucune optimisation ne rend ça calme partout.
  Le compromis tenable est donc : un littoral lisible d'un côté, un haut-fond dense de
  l'autre. Si la zone dense se révèle pénible à peindre, le levier est d'agrandir le guide,
  pas de retirer des tuiles.

- **Ce que « minimal » veut dire ici** — le plus petit paysage qui *sonne naturel à
  regarder*, tout en couvrant tous les cas : plateaux de toute forme, de toute taille, à
  cheval les uns sur les autres de n'importe quelle façon, et murs répétables de hauteur N
  — un paysage de montagnes séparées qui supporte tout cela. Le marché fabrique le tileset
  ultra-compact ; ici s'ajoute une **seconde injonction**, rester un paysage lisible.
  Minimal n'est donc pas « le plus petit », c'est « le plus petit qui tienne les deux ».

- **Le guide porte une hauteur par case** (`core/height_mask.gd`). `.` ou `0` = la plaine,
  `1..9` = les plateaux. La silhouette de l'étage N est l'ensemble des cases de hauteur
  >= N, et **c'est un masque binaire** : le blob 47 s'applique donc étage par étage, sans
  une ligne de code de plus. Un plateau haut repose sur tous ceux d'en dessous sans qu'on
  ait rien à déclarer — l'étage N−1 continue sous la robe de l'étage N, il est masqué.
  Conséquence pratique pour dessiner un guide : **élever une case déjà pleine ne change pas
  la silhouette des étages inférieurs**, donc on peut ajouter du relief à un guide qui
  couvre déjà 47/47 sans rien perdre.

- **Un second vocabulaire : les robes** (`core/walls.gd`). Un terrain Wang résout les coins
  d'un *plan* ; une falaise sort du plan, sa face occupe des cases qui, vues de dessus,
  appartiennent au sol d'en bas, et aucun système de terrain ne peut la poser. Le
  vocabulaire est donc autre : **3 pans (gauche, courant, droit) × 4 rangées (chapiteau,
  corps 0, corps 1, pied) = 12 tuiles**. Règles reprises telles quelles :
  - un plateau n'a de face **qu'au sud** ;
  - **la hauteur se déduit, elle ne se déclare pas** : on cherche l'étage le plus haut
    réellement atteint sous la lèvre, la chute vaut `STOREY_TILES × (N − M)` ;
  - **le pan se choisit par rangée, jamais par colonne** — c'est ce qui habille les
    escaliers sans une seule tuile d'angle ;
  - **une robe raccourcie ou qui n'atterrit pas ne pose pas son pied** ;
  - **deux rangées de corps**, pour que l'œil ne lise pas la répétition avant la falaise.
    C'est ce qui permet une hauteur N quelconque avec une feuille finie.

- **`ample`, second mode : décidé et nommé, fermé jusqu'à preuve.** Même complétude que
  `minimal`, mais volontairement plus de répétitions : peindre une tuile en remplira
  plusieurs, ce qui rend le geste plus intuitif. Le nom existe tel quel en français et en
  anglais, s'oppose proprement à `minimal`, et dit « qui a de la place » sans dire « gros ».
  Il figure au catalogue et à la liste déroulante, **grisé**, tant que son guide n'existe
  pas : ce qui n'est pas garanti ne se choisit pas (règle 5). `Modes.is_available()` tranche.

- **Le mode minimal livre deux familles : 47 + 12 = 59 tuiles.** `coverage.gd` prouve la
  première, `walls.analyse()` la seconde.

- **La plaine est le niveau 0, il n'y a pas de gouffre.** Toute case est à la plaine ou
  au-dessus, donc une robe finit toujours par atterrir. Conséquence assumée : le cas
  « robe au bord d'un gouffre, qui ne pose pas son pied faute de sol » n'est pas
  exprimable. Il demandera un marqueur de vide distinct de `.` le jour où un puits sans
  fond sera voulu. Le cas voisin — robe raccourcie par un morceau de son propre étage —
  est, lui, exprimable et testé.

- **La couverture se compte sur la surface VISIBLE, jamais sur l'union des étages.** Une
  case sous un plateau plus haut est masquée : vue de dessus on ne voit que le sommet. La
  tuile qu'une case porte est donc celle de **son propre étage**, lue dans la silhouette de
  cet étage — `coverage.visible_index_at()`. Compter l'union de toutes les silhouettes
  gonflerait le rapport avec des tuiles que personne ne pourra jamais peindre. Vérifié sur
  le guide livré : les deux comptes donnent 47/47, mais c'est une coïncidence heureuse, pas
  une équivalence.

- **Une robe qui tombe hors de la grille est une tuile impeignable** — le runner l'assure à
  zéro. Un guide en relief doit garder de la plaine sous ses falaises, sur toute la hauteur
  de la chute.

- **`guides/minimal.txt` : relief 35x28, trois étages, complet sur les deux familles.**
  47/47 en surface visible, 12/12 en vocabulaire de mur, aucune robe hors grille — asserté
  par le runner, pas affiché (règle 4). 534 surfaces visibles et 336 cases de robe, soit
  autant de variantes possibles pour 59 tuiles obligatoires.

  **Chaque famille d'index y est portée par un accident de terrain choisi pour ça**, et
  c'est ce qui permet au guide de rester un paysage au lieu d'un damier :
  - *montagne en terrasses avec cirque au sommet* — les masses pleines, les angles, les
    encoches diagonales ; et ses trois étages donnent les chutes profondes ;
  - *plateau aux lacs* — le motif des petits lacs est un **tore de de Bruijn 4x4**, dont
    les seize fenêtres 2x2 sont toutes distinctes. Chaque case entre quatre lacs voit donc
    une combinaison différente d'encoches : les **seize** index « tous cardinaux » tombent
    d'un seul plateau de 11x11, là où les disperser en aurait demandé le triple ;
  - *quatre systèmes de crêtes à rameaux* — une arête droite bordée d'un épaulement
    discontinu. Le motif de l'épaulement porte les quatre voisinages utiles, ce qui donne
    les seize index « trois cardinaux », les pointes et les crêtes étroites. Les quatre
    crêtes ont **quatre motifs différents** : la même séquence répétée se voyait à l'œil ;
  - *quatre coudes d'arête* — les quatre « deux cardinaux adjacents sans diagonale », qu'on
    n'obtient d'aucune masse pleine ;
  - *éperon à cheval sur le bord du massif* — sa robe descend de six cases le long du
    flanc, seule façon d'obtenir le corps 1 en pan courant ;
  - *pinacle isolé au troisième étage* — l'index 0, une seule case sans voisin.

- **La taille n'est pas prouvée minimale.** 35x28 est le plus petit auquel je sois arrivé
  en gardant chaque famille portée par un vrai accident de terrain. Le gras restant est
  identifiable : l'épaulement des crêtes est large, et le plateau aux lacs pourrait
  peut-être se poser sur un massif existant plutôt que sur le sien.

- **L'usage et le style du fond sont deux axes orthogonaux**, et aucun des deux n'est le
  mode.
  - **`representative` / `usable` qualifie le FOND** : ce qu'on regarde en peignant. Ça ne
    change rien à ce qui sort.
  - **`painted` / `wireframe` qualifie le STYLE DU FOND** : de quoi le dessin de référence
    est fait. C'est un outil, pas un mode.

  Les quatre combinaisons ont un sens. On peut peindre un tileset éclairé sur un fond
  `usable` — c'est même le cas courant : on veut le trait sous la main, pas le résultat.

  ⚠ **Il n'y a aucun lien entre eux.** Les huit combinaisons sont légitimes, et le test
  vérifie qu'elles donnent huit dessins différents deux à deux. `usable`, lui, ne porte de lumière dans aucun cas :
  la distinction qu'il trace entre bord nord et bord sud est **géométrique** — où est la
  lèvre, où commence la face. Dans un mode éclairé, cette géométrie dit accessoirement où
  le jour se prend ; dans un mode `unlit`, elle ne dit plus que la géométrie, et reste
  aussi utile.

- **L'illustration se calcule depuis le relief, elle ne se dessine pas à côté**
  (`render/guide_image.gd`). Aucune image n'est lue, aucun pixel n'est emprunté : les 47
  silhouettes et les 12 robes suffisent. Deux conséquences, et la seconde vaut la première.
  D'abord elle **ne peut pas mentir** sur ce que le guide contient — si le relief change,
  elle change avec, et il n'existe pas d'état où le dessin de fond et la preuve divergent.
  Ensuite elle est **entièrement à nous**, ce qui règle la question des droits : un pack
  d'assets acheté autorise l'usage dans un projet mais interdit la redistribution, et un
  guide à décalquer fait d'assets tiers serait exactement ce qu'aucune licence n'autorise.

- **Le rendu se fait étage par étage, du bas vers le haut.** Chaque couche recouvre la
  précédente, si bien que les coins arrondis découpés laissent voir l'étage d'en dessous
  sans qu'on ait à calculer quoi que ce soit. Puis les robes, du bas vers le haut aussi :
  la plus haute passe devant. C'est la même règle que la couverture — on ne voit que le
  sommet.

- **Chaque tuile est dessinée trois fois trop grand puis réduite.** Il n'y a que 47
  silhouettes par étage et 12 robes, donc on les fabrique une fois et on les tamponne :
  980 cases coûtent 153 dessins. ⚠ Et le **dehors** d'une tuile porte sa propre couleur en
  transparent, jamais du noir : à la réduction les pixels de bord se mélangent à leurs
  voisins, et un dehors noir cernerait chaque tuile d'un liseré sombre.

- **La lumière vient du nord-ouest.** La lèvre nord et le flanc ouest sont éclairés, le sud
  et l'est reculent. L'ombre de contact ne se pose **qu'à l'est** : au sud, c'est déjà une
  robe qui couvre la case.

- **`render/` n'est pas `core/`.** Le rendu est de la présentation, il a sa propre place.
  Mais il ne dépend d'aucun nœud pour autant : `Image` et `Color` sont des ressources, donc
  l'illustration se fabrique en headless et se teste avec le reste. L'interface n'aura qu'à
  en faire une `ImageTexture`.

- **L'éditeur : bandeau, barre, zone de travail.** La fenêtre fait 95 % de l'écran,
  centrée. En haut un bandeau fin porte le nom, le slogan, et une ligne qui déroule la
  charte — la seule fantaisie du logiciel, et chaque phrase y est vraie. À gauche une barre
  coupée en deux : **25 % en haut** pour les boutons globaux, sans défilement (mode,
  taille des pixels, les deux jauges, l'export) ; **75 % en bas** pour les sections
  d'outils repliables, dans un `ScrollContainer` pour qu'on puisse en empiler autant qu'on
  voudra.

- **Les rotations sont une case à cocher, et l'outil ne peut pas trancher à votre place.**
  J'avais d'abord fait des symétries une propriété du mode, en pariant qu'un mode « sans
  lumière » déciderait pour l'utilisateur. C'était faux à deux titres : un mode est un
  **paysage**, pas un style de dessin ; et surtout **l'outil ne sait pas ce que vous
  dessinez**. Il ne peut pas savoir si vos tuiles portent une direction d'éclairage.

  Donc : deux cases dans la section Crayon. « Peindre les jumelles » ne fabrique rien —
  deux jumelles sont la même tuile. « Peindre les rotations » **fabrique** une tuile dans
  une orientation que personne n'a peinte : correct si votre dessin n'a pas de lumière,
  visiblement faux s'il en a. L'infobulle le dit, et le choix reste celui du dessinateur.
  Quand elle est cochée, la case « jumelles » devient sans objet : les jumelles sont déjà
  comprises dans l'orbite.

  Ce que ça rapporte, mesuré : **47 index → 15 orbites** sous la rotation, **12 rôles → 8**
  sous le miroir est-ouest, soit **23 tuiles au lieu de 59**. Pas 22 : le 22 serait le
  compte du groupe complet, miroirs de surface compris — écartés, puisqu'ils n'y gagnent
  qu'une tuile (15 → 14) pour tout un mécanisme de plus. Les robes n'ont **que** le
  miroir : la rotation n'y a aucun sens, un plateau n'a de face qu'au sud, et le miroir
  vertical non plus, le pied reposant sur le sol.

  ⚠ **Le voisinage et les pixels doivent tourner dans le MÊME sens**, sans quoi la tuile
  posée contredirait sa propre silhouette et aucun compte ne le dirait. C'est asserté :
  un quart de tour envoie le nord du voisinage sur l'est, et la rangée du haut de l'image
  sur la colonne de droite.

- **`guides/ample.txt` : relief 66x31, et sa promesse est chiffrée.** Même complétude que
  `minimal` — 47/47 et 12/12 — mais **chaque index y est vu au moins trois fois**, contre
  une seule pour vingt d'entre eux dans `minimal`. Ce n'est pas une impression : la table
  des modes déclare `min_variants`, et la suite de tests le vérifie pour tout mode ouvert.
  Ajouter un mode au catalogue, c'est désormais s'engager à ce que son guide passe la
  preuve.

  Construction : les mêmes accidents de terrain que `minimal`, mais **trois régions**
  portant chacune son plateau aux lacs, ses quatre crêtes, ses quatre coudes, son pinacle
  et son éperon — avec une phase de tore, des motifs d'épaulement et une orientation
  différents à chaque fois, pour que ce ne soit pas trois copies.

  ⚠ **Deux pièges appris en le dessinant, tous deux sur le plateau aux lacs.** Depuis
  l'origine du plateau, les lacs occupent les décalages **impairs** et les seize cases
  utiles les décalages **pairs**. Un pinacle posé sur un lac le comble et fait disparaître
  quatre fenêtres du tore ; posé sur une case utile, il lui **vole son index** — la surface
  visible d'une case est celle de *son* étage, et une case montée à l'étage 3 ne compte
  plus pour l'étage 2. Le pinacle va donc sur le **bord** du plateau, dont l'index est un
  coin, et les coins ne manquent jamais.

- **Le fond du guide se calcule par étapes, et la barre dit la vérité.** ⚠ Mesuré :
  dessiner le fond coûte **2 à 5 secondes** (3,1 s pour `minimal` en représentatif, 5,2 s
  en utilisable). En un seul appel, l'écran gèle. `render/guide_render_job.gd` fait le même
  travail par tranches, `ui/work_area.gd` l'avance de 12 ms par image, et l'unité de
  progression est la **tuile distincte dessinée** — quand la barre est à la moitié, la
  moitié des tuiles est faite. Pas un compte à rebours, pas une animation qui tourne.

  Le résultat est **gardé en cache**, la clé portant le contenu du relief : revenir à un
  style déjà vu est instantané, et un guide modifié ne ressort jamais une vieille image.
  `guide_image.render()` reste le chemin d'un seul bloc, pour les tests et l'écriture sur
  disque, où personne ne regarde l'écran — même code, deux façons de l'appeler.

- **Tous les scripts du dépôt sont chargés par la suite de tests.** ⚠ Découvert en dur : la
  suite ne touchait aucun script d'interface, et un `PackedStringArray.hash()` — qui
  n'existe pas — est passé au travers jusqu'au lancement. Charger chaque `.gd` suffit à le
  faire analyser par le moteur, et coûte quelques millisecondes.

- **Trois axes indépendants, donc huit dessins.** Les avoir mélangés une fois a suffi à
  rendre l'un à la place de l'autre, alors ils sont séparés pour de bon :
  - **Paysage** (`minimal` | `ample`) — quel relief. C'est le **mode**, et c'est tout ce
    qu'un mode est. Il change ce qu'on peint.
  - **Technique** (`usable` | `representative`) — `usable` : rien qui paraisse irréel,
    rien qu'on regarde ; le dessin seul, tel que le tileset le montrera assemblé.
    `representative` : le même dessin **appuyé** — trait plus gras, marque franche aux
    coins rentrants, code de rangée bien lisible — pour savoir d'un coup ce qu'on attend
    de la tuile en cours.
  - **Style** (`painted` | `wireframe`) — de quoi le fond est fait : des aplats, ou des
    traits.

  ⚠ **Technique et style sont des outils, pas des modes.** Ce sont des aides à la vue :
  rien de ce qui sort n'en dépend. Les avoir rangés dans le catalogue des modes avait
  pour conséquence directe que choisir « utilisable » tirait son encre du mode et rendait
  un fond peint.

  ⚠ **Une marque n'est pas un trait du dessin** : les pastilles de coin rentrant et les
  tirets de rangée de robe sont d'une autre couleur, pour qu'on ne puisse jamais les
  prendre pour une côte.

- **⚠ AUCUNE DISCONTINUITÉ — et j'avais tiré la mauvaise conclusion la première fois.**
  Chaque trait est tiré à l'intérieur de sa propre tuile. À un coin rentrant — trois cases
  pleines autour d'un vide — les traits des deux voisines se croisent donc **sans se
  rejoindre**, et laissent un carré vide de la largeur du trait. C'était ça, la
  discontinuité visible.

  J'en avais conclu que personne ne pouvait la combler, puisque les deux voisines ne
  savent rien de ce coin. **C'est faux** : le carré manquant tombe chez la TROISIÈME, celle
  dont les deux cardinaux sont pleins et la diagonale vide — et elle, elle le sait, ce
  bit-là étant justement le seul bit de coin que la canonicalisation **conserve**. C'est
  donc elle qui ferme le coude, et le trait devient continu de bout en bout.

  ⚠ Ce qui reste vrai de l'ancien raisonnement : **on n'arrondit pas la terre à cet
  endroit**. Les deux voisines tracent leur côte droit jusqu'au coin et ne peuvent pas
  savoir qu'il faudrait la courber — une case dont le sud est ouvert porte le même index
  que son voisin du sud-ouest soit plein ou vide. Courber là, ce serait poser un arc que
  personne ne rejoint. Seuls les coins **sortants** s'arrondissent.

- **Le littoral est plus appuyé que les courbes de niveau.** Un dessin où tous les traits
  pèsent pareil se lit comme un plan de cuisine ; en allégeant à mesure qu'on monte,
  l'œil trouve tout de suite le bord de la terre et lit les étages comme un relief.
  `LEVEL_WEIGHTS` porte ces poids.

- **On arrondit les canaux, on ne les tronque pas.** Tronquer décale chaque canal d'un
  demi-pas vers le sombre : invisible à l'œil, mais la teinte rendue n'est alors plus
  exactement celle qu'on a demandée — et un test qui compare les deux échoue pour une
  raison qui n'a rien à voir avec le dessin. C'est arrivé.

- **La barre est posée SUR la zone de travail, et translucide au repos.** Elle laisse voir
  le guide à travers elle : c'est ce qui donne l'air d'un calque plutôt que d'un panneau.
  Dès que le curseur entre, elle redevient pleine — on ne travaille pas à travers une
  vitre. Trois conséquences techniques, toutes apprises à la dure :
  - la zone de travail occupe **toute** la largeur ; la barre ne lui réserve que son
    cadrage initial (`reserved_left`), pas son dessin. Le guide passe sous la barre quand
    on zoome, et c'est le but ;
  - on teinte `self_modulate`, **pas** `modulate` : le second aurait délavé le texte avec
    le fond, et une barre dont on ne lit plus les libellés n'est pas jolie, elle est cassée ;
  - le survol se teste sur le **rectangle**, pas avec `mouse_entered` : ce signal se
    déclenche à l'envers dès qu'on passe sur un enfant, et la barre clignoterait.
  Les en-têtes de section sont donc **plats, sans fond** : un fond opaque de plus poserait
  des bandes pleines par-dessus et crèverait l'effet.

- **La fenêtre se repose une seconde fois après la première image**, et imprime la taille
  obtenue. ⚠ Lancée **depuis l'éditeur Godot**, la fenêtre de jeu est *incrustée* dans un
  dock depuis la 4.4 (« Embed Game Window », actif par défaut) : elle subit alors la taille
  du dock et ignore tout redimensionnement. Pour voir les 95 %, lancer depuis un terminal
  ou désactiver l'incrustation.

- **Clic droit pose, clic gauche efface.** C'est l'inverse de l'habitude, et c'est voulu :
  la main droite pose la matière, la gauche la retire.

- **Le crayon refuse ce qui n'est pas une tuile** (règle 5). Seules les cases qui portent
  quelque chose — surface visible ou case de robe — se peignent ; la plaine n'est pas une
  tuile du tileset. La case survolée est cerclée de blanc si elle se peint, de rouge sinon :
  le refus se voit avant le clic.

- **Les deux jauges se recalculent à chaque coup de crayon** (règle 6), depuis les mêmes
  fonctions que la suite de tests. Ce que l'écran affiche est ce que les tests prouvent.
  Le bouton d'export reste fermé tant qu'il manque une tuile, et dit combien il en manque.

- **Pas de remplissage par rotation. Décision prise, et son prix est chiffré.**
  Tourner un voisinage d'un quart de tour est une permutation de bits (N→E→S→W→N,
  NE→SE→SW→NW→NE), et sous cette rotation les 47 index se rangent en **15 orbites** : trois
  fixes (0, 85, 255), deux de taille 2, dix de taille 4. Remplir les rotations ferait donc
  tomber le travail de surface de **47 tuiles à 15**, et le total de 59 à 27. Le gain est
  réel et il est gros. Il est refusé quand même, pour trois raisons dont la première suffit.

  **La lumière.** Un tileset vu de dessus est éclairé d'une direction — ici le nord-ouest,
  et c'est ce que dessine déjà `guide_image.gd`. Tourner une tuile tourne ses hautes
  lumières avec elle : une lèvre nord qui accroche le jour devient une lèvre est éclairée du
  mauvais côté. Le cas le plus parlant est l'orbite `[7, 28, 112, 193]`, les quatre coins
  d'une masse pleine — précisément les tuiles où l'éclairage compte le plus. Les obtenir par
  rotation les rend toutes les quatre identiquement éclairées, ce qui donne exactement l'air
  plat et sans relief que cet outil existe pour éviter. Le gain se paierait donc en
  repeignant les tuiles fautives : une économie qui se rembourse en travail.

  **La charte.** La règle 3 interdit le miroir nommément ; la rotation est du même
  ensemble. Et « No pixel you didn't paint » deviendrait faux, ou demanderait un astérisque.

  **Le besoin est déjà servi ailleurs.** Ce que la rotation vise — ne pas redessiner
  quarante-sept fois — c'est ce que font les jumelles, sans rien fabriquer, et ce que fera
  mieux le mode `ample`, conçu pour ça.

  ⚠ **La porte par laquelle elles reviennent : un mode sans lumière.** Si un mode livre des
  tuiles sans direction d'éclairage — matière ambiante, texture de dessus sans relief —,
  alors rotations **et miroirs** y sont *corrects*, pas seulement pratiques : rien n'y
  contredit la logique du dessin. C'est une **propriété du mode**, décidée une fois avec
  lui, jamais une case à cocher offerte au milieu du dessin : c'est le mode qui dit ce qu'on
  fabrique (règle 1), et on n'autorise que ce qui est garanti (règle 5). Voir la fiche du
  mode `unlit` dans les questions ouvertes.

- **« Peindre les jumelles ».** Deux cases qui portent le même index de surface — ou le
  même rôle de robe — sont **la même tuile**. Les peindre ensemble n'invente rien : ça
  évite de refaire le même dessin autant de fois qu'il y a de variantes. Le noyau désigne
  les groupes (`coverage.cells_by_index()`, `walls.cells_by_role()`), l'interface ne fait
  que les suivre. ⚠ C'est une **aide au geste, pas un réglage du produit** : ce qui sort
  est identique, seul le nombre de gestes change. La distinction compte pour la règle 1.
  Conséquence technique : un coup de crayon peut salir cent cases d'un coup, d'où le
  téléversement **limité à ce qui est à l'écran** ; les autres attendent d'entrer dans le
  cadre.

- **Pas de surbrillance du pixel sous la souris.** Essayée, retirée : suivre le pixel
  obligeait à redessiner la zone de travail à chaque micro-mouvement de souris, pour un
  repérage dont on n'a pas voulu. Le survol se suit **à la case**.

- **La taille des faux pixels se choisit avant de dessiner.** Le choix se ferme au premier
  pixel posé : en changer rejetterait tout le travail. Même statut que le mode — c'est ce
  qu'on fabrique, pas un réglage.

- **Performances : trois pièges, tous mesurés.** Sur le guide minimal, 810 cases sont
  peignables (534 surfaces, 276 robes).
  - *La grille des faux pixels* était tracée en entier : à 256 px par tuile, seize mille
    traits dont la quasi-totalité hors cadre. Elle est désormais **découpée au cadre**.
  - *Les textures* remontaient au GPU à chaque pixel posé — un quart de mégaoctet par pixel
    à 256. Elles ne remontent plus qu'**une fois par image**, les cases touchées étant
    marquées sales.
  - *Les compteurs* relisaient tout le relief à chaque coup de crayon : **5,05 ms par
    image**, un tiers du budget. La carte case → index et les rôles de robe sont calculés
    **une fois au chargement**, et les tris ont quitté le chemin chaud : **0,54 ms** dans
    le pire cas, celui où les 810 cases sont peintes.

  Mémoire, si l'on peint **toutes** les cases (jamais nécessaire : 59 tuiles suffisent) :
  0,8 Mo à 16 px, 12,7 Mo à 64, **202 Mo à 256** — et le double en comptant le GPU. Coût
  d'un pixel une fois la tuile créée : 1,1 µs à 64 px, 1,9 µs à 256. La première pose dans
  une tuile neuve coûte 112 µs à 256 px, le temps d'allouer son image : une fois par tuile,
  pas par pixel.

## Références

- **Satyron** (`D:\Satyron`) — le jeu où ce modèle a été établi empiriquement puis éprouvé
  sur une vraie carte. AbsoluTiles en fait un outil universaliste. À lire quand un doute
  survient sur le comportement d'une falaise :
  - `WORLD/cliffs.gd` — `assemble_walls`, `_fall_at`, `_trim`, `_column_at` ;
  - `WORLD/tiles/cliff_kit.gd` — le bloc 3 pans × 4 rangées et `atlas_row` ;
  - `DEV_TOOLS/make_cliff_kits.py` — comment la feuille de robes est composée ;
  - `CLAUDE.md`, section « Les colonnes — la seule verticalité qu'on automatise ».

## Questions ouvertes

- **Compacter le guide minimal** sans perdre la lisibilité : voir « la taille n'est pas
  prouvée minimale » ci-dessus.
- Règles d'exportation du mode minimal : format de sortie, ordre des tuiles, taille de
  tuile. Rien n'est décidé, `exporters/` est vide exprès.
- Les index à occurrence unique n'ont aucune variante : ce sont des cases obligatoires.
  Faut-il les signaler pendant le dessin (règle 6) ?
