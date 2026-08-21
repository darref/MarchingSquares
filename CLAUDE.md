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
  corner_index.gd le reseau dual : une tuile a cheval sur quatre cases, 15 index
  symmetry.gd     rotations et miroirs, et les conditions qui les rendent licites
  painting.gd     les faux pixels posés dans chaque tuile
  mask_io.gd      lecture / écriture / accès d'un masque de guide (texte)
  coverage.gd     rapport de couverture d'un masque
  height_mask.gd  guide en relief : une hauteur par case, silhouette par étage
  walls.gd        le second vocabulaire : les robes de falaise (3 pans × 4 rangées)
  variants.gd     quelles cases peintes deviennent des tuiles
  proof_scene.gd  la planche de preuve : un ilot par index, calculee
  work_io.gd      lecture / ecriture du travail en cours (.absolutiles)
  modes.gd        catalogue des modes (guide + règles d'exportation)
render/       illustration du guide -- présentation, pas logique
  guide_image.gd  dessine le relief en Image (headless, sans nœud)
  satyron_tiles.gd  lit le tileset de Satyron chez lui, pour le banc d'essai
  guide_render_job.gd  le même dessin, par étapes, pour pouvoir le regarder avancer
  assembly.gd     le paysage rebâti avec les tuiles peintes, par deux chemins
  preview.gd      écrit l'illustration sur disque
ui/           l'éditeur
  editor.tscn     la fenêtre : bandeau, barre d'outils, zone de travail
  editor.gd       câblage ; aucune règle de produit ne vit ici
  work_area.gd    grille, zoom, fond du guide, pose des faux pixels
  sidebar.gd      la barre translucide, pleine sous le curseur
  tool_section.gd une section d'outils repliable
  preview_panel.gd  l'aperçu en jeu : les tuiles peintes sur un décor ordinaire
  screenshot.gd   capture la fenêtre, pour se relire
guides/       guides au format texte ('.' plaine, '1'..'9' plateaux ; '#' = étage 1)
  minimal.txt          guide du mode « minimal » : relief 35x28, 47/47 et 12/12
  ample.txt            guide du mode « ample » : relief 66x31, 3 occurrences minimum
  minimal_preview.png  son illustration, régénérable à tout moment
  candidate_01.txt     brouillon plat dessiné à la main, 28/47, conservé comme trace
  preview.txt          le décor de l'aperçu en jeu : 24x18, une colline et une butte
tests/        tests headless
  run.gd          runner, code de sortie non nul en cas d'échec
exporters/
  tileset_png.gd  les deux planches, la planche de preuve, et leur manifeste
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

Et pour se relire avec un travail ouvert, remontage compris — les arguments après
`--` viennent dans n'importe quel ordre :

```
godot --path . --script res://ui/screenshot.gd -- sortie.png mon_travail.absolutiles remontage
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

- **La technique `example` : notre guide assemblé avec un VRAI tileset.** Elle lit celui de
  Satyron **depuis son projet**, sur ce disque, et pose ses tuiles sur notre relief. Si nos
  règles sont justes, le paysage se tient ; chaque endroit où il ne se tient pas est une
  erreur — chez nous, ou chez lui. C'est un banc d'essai, pas un fond de travail : le choix
  du **style se ferme** quand elle est active, puisque ce ne sont ni nos aplats ni nos traits.

  ⚠ **On lit, on ne copie pas.** Les images restent chez Satyron. Le pack est acheté, sa
  licence autorise l'usage et interdit la redistribution : sur une machine où le projet
  n'est pas là, la technique reste **fermée** dans la liste (règle 5). Le chemin se règle
  par `absolutiles/satyron_path`.

  ⚠ **Ce que le banc éprouve, et ce qu'il n'éprouve pas.** Mesuré avant d'écrire :
  `icko_tileset.tres` déclare `mode = 1`, c'est-à-dire **Match Corners** — chaque tuile y est
  définie par ses **4 coins**, pas par les 8 voisins d'une case. Satyron n'a donc **aucune
  tuile blob 47** : il n'existe rien en face de « l'index 253 ». Les deux grilles sont
  duales, une de ses tuiles étant à cheval sur quatre des nôtres, et ses sols se posent
  décalés d'une demi-case. Ce n'est pas une approximation, c'est la géométrie de son système.

  Le banc **éprouve** donc notre relief, nos silhouettes par étage, et surtout nos **règles
  de falaise** — chutes, choix du pan par rangée, pied ou pas de pied — qui se posent case
  pour case, sans décalage, puisque c'est à lui qu'on les a prises. Il **n'éprouve pas** la
  correspondance des 47 index.

  ⚠ **Son kit de falaise n'a qu'une rangée de corps** (`body_rows = 1`) là où nous en posons
  deux : sa documentation décrit le kit *desert*, mais le kit vivant est l'*icko*. Nos deux
  corps retombent donc sur la même rangée — on ne montre pas ce qui n'existe pas.

  ⚠ **Un `.tres` d'un autre projet ne se charge pas, il se lit.** Ses textures sont
  référencées en `res://`, qui pointe chez nous : `load()` échouerait sur la première. Piège
  rencontré en l'analysant : chercher `id=` tombe sur celui de `uid=`, qui le contient —
  aucune texture ne se retrouvait, et le rendu sortait vide sans une seule erreur.

  **Première passe** : le paysage se tient. Plateaux herbés, falaises sous leurs bords sud,
  transitions entre étages, pinacle isolé, lacs d'une case. 258 ms.

- **`render/` n'est pas `core/`.** Le rendu est de la présentation, il a sa propre place.
  Mais il ne dépend d'aucun nœud pour autant : `Image` et `Color` sont des ressources, donc
  l'illustration se fabrique en headless et se teste avec le reste. L'interface n'aura qu'à
  en faire une `ImageTexture`.

- **Deux barres : à gauche les options, à droite le travail.** La coupure est la seule
  chose qui rende une barre lisible : à gauche **ce qu'on fabrique** (paysage, taille des
  pixels) et **ce qu'on regarde** (technique et style du fond) ; à droite **tout ce qui
  sert à peindre** — les deux jauges, l'export, le crayon, la grille, le recadrage.
  Mélangées, on cherche ; séparées, on trouve sans lire.

  La barre de gauche garde ses 25 % fixes en haut et ses sections repliables en dessous ;
  la barre de droite est plus fine, et ses sections suivent la même forme.

  ⚠ **Un libellé qui s'allonge impose sa largeur à toute la barre.** Le bouton d'export
  portait le compte des tuiles restantes : il débordait du cadre et rognait tout le reste.
  Le bouton dit ce qu'il fait, le compte est à côté.

  ⚠ **Les quatre bords d'un panneau ancré se posent, pas un seul.** N'en fixer qu'un laisse
  les autres à leur valeur d'avant, et le panneau sort du cadre sans qu'on comprenne
  pourquoi.

- **Annuler est indispensable ici, pas confortable.** Avec les jumelles, un trait de
  travers ruine une tuile **dans tous ses exemplaires à la fois** — jusqu'à deux cents
  cases d'un geste. Sans retour en arrière il faudrait les reprendre une par une.
  `Ctrl+Z` défait, `Ctrl+Y` refait, et l'unité est la **passe** : du clic au relâchement.

  On journalise les **pixels changés**, pas les images : une passe de dix pixels sur deux
  cents jumelles pèse quelques dizaines de kilo-octets, là où copier les images en
  pèserait cinquante méga à 256 px.

  ⚠ **On rejoue à l'envers en défaisant.** Deux pixels posés au même endroit dans la même
  passe ne se défont correctement que dans l'ordre inverse — dans l'ordre, le second
  écraserait le premier et la case resterait peinte. C'est asserté.

- **La sauvegarde range l'art par TUILE, jamais par case** (`core/work_io.gd`). C'est la
  seule décision du fichier, et elle porte tout le reste. Une case du guide n'est qu'un
  *endroit* où l'on a peint ; ce qui a de la valeur, c'est la **tuile** — l'index de
  surface, ou le rôle de robe. Rangée par case, une sauvegarde mourrait au premier
  retouchage du guide : compacter `minimal.txt` d'une ligne décalerait tout, et l'art
  serait perdu. Rangée par tuile, le guide peut être redessiné, agrandi, compacté,
  remplacé — l'art retombe sur ses pieds, puisqu'il est rangé sous le nom de ce qu'il
  représente. C'est **asserté** : le test repeint un guide entier, recharge le fichier sur
  un paysage qui n'a rien à voir, et vérifie que chaque tuile atterrit au bon endroit.

  Conséquence gratuite et heureuse : **un travail commencé en `minimal` se recharge en
  `ample`**. Les deux modes livrent les mêmes 59 tuiles ; seul le nombre d'exemplaires
  change.

  Une clé nomme une tuile et son rang de variante : `S<index>:<n>` pour une surface,
  `W<pan>,<rangée>:<n>` pour une robe. Le rang est la position de la case dans son groupe,
  **en ordre de lecture** — le seul ordre qui ne dépende que du guide et jamais du
  remplissage d'un dictionnaire.

  ⚠ **Ce qui ne retombe pas sur ses pieds est dit, pas jeté.** Si le nouveau guide offre
  moins d'exemplaires d'une tuile que le fichier n'en portait, les variantes en trop sont
  rendues dans `unplaced`. Même règle que les pixels peints hors du guide.

  ⚠ **Recharger n'est pas un coup de crayon.** `painting.set_image()` ne journalise rien :
  « annuler » juste après une ouverture doit ramener à la passe d'avant la sauvegarde, pas
  vider l'écran.

  Le fichier est un texte : en-tête lisible, puis une ligne par tuile, image en PNG encodé
  en base64. Le PNG compresse — un aplat coûte quelques octets au lieu de soixante-cinq
  mille.

- **L'export livre DEUX planches, jamais une** (`exporters/tileset_png.gd`). Un terrain
  Wang résout les coins d'un plan ; une falaise sort du plan. Les mêlant dans une seule
  image, on obligerait celui qui la relit à savoir où l'une s'arrête — c'est exactement
  pourquoi Satyron garde `icko_tileset.tres` d'un côté et `cliff_kits.tres` de l'autre.
  Sortent donc `<nom>_surface.png`, `<nom>_walls.png` et `<nom>_tileset.txt`.

  **La disposition est mécanique** : les 47 index en ordre croissant, huit par rangée, six
  rangées, la dernière case vide ; les 12 robes en 3 pans × 4 rangées, c'est-à-dire la
  forme même du vocabulaire. Le manifeste redit quand même la table en clair : le fichier
  dit ce qui est vrai, il n'oblige pas à le redémontrer. Il porte aussi `storey_tiles` et
  `body_rows`, sans quoi on ne remonte pas une falaise.

  ⚠ **Une feuille incomplète est refusée, et rien n'est écrit** (règle 5). Un tileset à
  moitié peint n'est pas un tileset, c'est un piège — des trous transparents qu'on
  découvrirait dans le jeu.

  ⚠ **Mais un refus n'est pas une erreur.** Incomplet est l'état *normal* pendant tout le
  travail : le bouton est grisé, le compte s'affiche, et c'est tout. Le signaler par
  `push_error` remplirait la console de rouge pendant des heures et apprendrait à ignorer
  le rouge.

  ⚠ **Les variantes sont tassées, pas recopiées à leur rang d'origine.** Une tuile peinte à
  sa troisième occurrence sans l'avoir été à la première devient la variante 0 de la
  planche. Sinon un moteur qui tire une variante au hasard tomberait sur du vide — et le
  rang dans le guide ne veut rien dire pour qui relit la feuille.

  **Il n'a jamais fallu peindre tout le guide.** Une occurrence de chaque tuile suffit :
  59 cases sur les 810 peignables. C'est asserté.

- **Ouvrir, enregistrer, exporter vivent dans la barre de droite**, section « Travail ».
  `Ctrl+S` enregistre, `Ctrl+O` ouvre — un outil de dessin qui ne prend pas `Ctrl+S` se
  fait perdre du travail par la main de l'utilisateur lui-même.

  ⚠ **Ouvrir lit en deux temps.** Le fichier dit dans quel paysage et à quelle taille il a
  été peint ; il faut charger ce paysage **avant** de pouvoir y reposer quoi que ce soit.
  D'où `work_io.peek()`, qui lit l'en-tête et s'arrête à la première ligne de tuile — une
  seule de ces lignes pèse plusieurs kilo-octets.

- **« Masquer le guide » n'est qu'un décrassage de l'écran, et il faut le dire.** J'avais
  d'abord appelé ça « Remontage » en le présentant comme *le contrôle que le programme ne
  peut pas faire*. C'était faux, et l'utilisateur l'a relevé : **la zone de travail dessine
  déjà chaque tuile peinte à sa case, en permanence.** Le paysage assemblé était visible
  depuis le début ; c'était bien à lui de juger, et il jugeait déjà.

  Ce que la case fait est plus petit : elle retire **trois choses posées par-dessus le
  travail** — le guide à 55 % d'opacité qui teinte les couleurs, la grille des tuiles qui
  coupe les traits là même où l'on vérifie qu'ils se rejoignent, et les cercles de repère.
  Même famille que « Afficher la grille », et pour la même raison déjà écrite ici : *une
  grille est une aide à viser, pas un décor.* Rien de plus, et le libellé doit le dire.

  **Leçon** : un nom qui promet une capacité qui n'existe pas coûte plus cher qu'un nom
  terne. Il fait chercher à l'utilisateur ce qu'il ne trouvera pas.

- **L'aperçu en jeu : les mêmes tuiles sur un décor ordinaire** (`ui/preview_panel.gd`,
  `guides/preview.txt`). *Ça*, c'est la capacité qui manquait. Le guide est un banc
  d'épreuve — lacs d'une case, pinacles isolés, encoches partout ; il ne ressemblera jamais
  à une carte de jeu, donc il ne dira jamais si le tileset **rend** bien. Le décor le dit :
  24x18, une colline en terrasses, ses falaises en escalier, une butte à deux étages, un
  rocher isolé et un cordon.

  ⚠ **Il ne fabrique aucune tuile** (règle 3). Chaque case y **emprunte**, par index ou par
  rôle, ce qui est peint dans le guide — `assembly.borrow()`. Rien de neuf n'est inventé :
  c'est le même dessin, vu ailleurs. Et il pioche toujours la variante 0, sinon le décor
  scintillerait à chaque coup de crayon.

  ⚠ **Le décor ne peut rien réclamer que le guide n'ait pas.** C'est la propriété qui
  compte, et elle est assertée : chaque case du décor trouve sa tuile, sans exception. Un
  aperçu qui demanderait une tuile inexistante montrerait un trou permanent.

  ⚠ **Le côté de case est arrondi à l'entier, et le filtrage est au plus proche.** Une
  échelle fractionnaire étalerait chaque tuile sur un nombre non entier de pixels d'écran,
  et un lissage bilinéaire mélangerait les bords voisins : le panneau montrerait des
  coutures que le dessin n'a pas — exactement le défaut qu'il existe pour révéler.

  ⚠ **Et il ne montre pas tout : seize index sur quarante-sept.** C'est la vérité des
  tilesets — une carte ordinaire n'use qu'une poignée de tuiles. Le panneau dit *comment ça
  rend*, pas *si tout est peint* ; les jauges sont là pour ça. En revanche il montre les
  **douze** tuiles de falaise, dont la butte à deux étages qui fait tomber six cases : c'est
  là que le banding se repère.

  Le panneau est **opaque, sans discussion** — on ne juge pas une couleur à travers autre
  chose — et il arrête la souris, sinon on peindrait « à travers » lui sans voir où.

- **Une variante est un DESSIN différent, pas une case différente.** « Peindre les jumelles »
  est coché d'emblée : les cent cases qui portent le même index portent alors le même dessin.
  L'exportateur compare donc le **contenu** et ne garde que ce qui diffère vraiment — sans
  quoi la planche ferait cent blocs identiques. La comparaison est exacte, octet pour octet,
  jamais par empreinte : une empreinte qui se cognerait ferait disparaître un dessin en
  silence.

- **Un travail relu doit marquer ses cases sales.** Défaut trouvé en regardant l'écran, pas
  en lisant les tests : après un chargement, les compteurs disaient 47/47 et la zone de
  travail restait **vide**. Les textures ne remontent au GPU que pour les cases *salies*, et
  un fichier relu n'a jamais été peint devant nous. Les tests ne pouvaient pas le voir : ils
  ne montent aucune texture.

  ⚠ **Et le téléversement se plafonne par image.** Un guide entièrement peint compte sept
  cents cases ; à 256 pixels de côté, les remonter d'un coup ferait cent quatre-vingts
  méga-octets en une seule image. Quarante-huit par image suffisent : tout apparaît en
  quelques dixièmes de seconde et rien ne gèle.

- **Ce qui est prouvé, ce qui est cherché, et la différence entre les deux.** C'est le cœur
  du logiciel, donc la formulation doit être exacte.

  **Les surfaces sont démontrées, exhaustivement.** L'index d'une case ne dépend **que** de
  sa fenêtre 3x3 ; il n'en existe que **512**, et le test les fait toutes. Aucune n'en sort
  autre chose qu'un des 47, et à elles seules elles les donnent tous les 47 — il n'y a ni
  48ᵉ ni 46ᵉ. Et comme la silhouette d'un étage **est** un masque binaire, ces 512 couvrent
  le relief entier, quel que soit le nombre d'étages. C'est un théorème, pas un sondage.

  **Les robes, elles, ne se démontrent pas : elles se cherchent.** `row_for()` et `pan_at()`
  sont *notre* modèle, repris de Satyron empiriquement. Rien ne démontre qu'aucun relief au
  monde ne réclame un 13ᵉ rôle. On fait donc ce qu'on peut faire honnêtement — on cherche un
  contre-exemple :
  - **exhaustivement** sur les 32 768 reliefs binaires 3x5 ;
  - **au hasard** sur 2 000 reliefs 8x8 à quatre étages, à chaque exécution de la suite ;
  - et une fois, hors suite, sur **100 000 reliefs** de 3x3 à 14x14 et jusqu'à quatre étages :
    **4 899 121 cases de surface et 8 248 365 cases de robe examinées, 47/47 index et 12/12
    rôles rencontrés, ZÉRO contre-exemple.**

  ⚠ **La battue doit avoir vraiment cherché.** Une recherche qui ne rencontre aucun des douze
  rôles ne prouve rien : elle prouve qu'elle n'a rien regardé. C'est donc **asserté** aussi.

  La formule juste, celle qu'on peut dire à un acheteur : *les 47 sont démontrés ; les 12
  n'ont pas de contre-exemple sur treize millions de cases, et voici le programme qui les
  cherche.*

- **La planche de preuve : chaque cas, isolé, à une place connue d'avance**
  (`core/proof_scene.gd`, `<nom>_preuve.png`). Un acheteur qui reçoit une feuille de 47
  dessins ne peut pas vérifier que ce sont **tous** les cas : il voit 47 tuiles, il ne voit
  pas l'absence d'une 48ᵉ. La planche le lui montre — un îlot de 3x3 par index, et le centre
  de chaque îlot porte exactement la tuile annoncée. On peut pointer du doigt : « là, c'est
  l'index 117, N+E+S+SW+W ».

  ⚠ **Elle est calculée, jamais dessinée.** Même raison que `CANONICAL_INDICES` : un relief
  écrit à la main serait une donnée à maintenir et un endroit où mentir. Ici, si la règle de
  canonicalisation changeait, la planche changerait avec elle — il n'existe aucun état où la
  preuve et la règle divergent.

  ⚠ **Les îlots suivent l'ordre de la planche exportée** — index croissant, huit par rangée.
  Poser la feuille de tuiles à côté de la preuve fait correspondre les cases une à une.

  ⚠ **Un îlot ne doit pas déborder sur son voisin.** Un voisinage porte à une case : une
  colonne de garde suffit à l'horizontale. À la verticale il en faut **quatre** — trois pour
  laisser tomber la robe de l'îlot, une pour respirer.

  En bas, une **butte à deux étages**, cinq de large : sa chute de six cases fait passer les
  deux rangées de corps, et c'est le seul moyen d'obtenir les douze rôles d'un seul bloc.

  ⚠ **Piège rencontré : un `PackedByteArray` se copie quand on l'affecte.** Modifier la copie
  locale ne touchait pas la rangée rangée dans le tableau, et la planche sortait vierge
  **sans une seule erreur**.

  Le décor de travail et la planche de preuve répondent à **deux questions différentes** —
  « comment ça rend » et « est-ce que rien ne manque ». D'où la liste « Décor », posée sous
  la case « Aperçu en jeu » à laquelle elle appartient.

- **Seize pixels par défaut, et c'est un argument de vente avant d'être un réglage.** À
  l'ouverture, l'acheteur doit voir d'un coup d'œil qu'il y a **peu** de faux pixels à
  peindre. Seize est aussi la taille du marché. Monter est un choix, et il se fait avant de
  dessiner.

- **Le réseau dual livre QUINZE tuiles, pas seize** (`core/corner_index.gd`). Une tuile « à
  cheval » n'est pas posée sur une case, elle est posée sur le **croisement** de quatre
  cases, et son dessin ne dépend que de ces quatre-là. Quatre cases, deux états : seize
  combinaisons — mais le **croisement vide ne dessine rien**, exactement comme la plaine
  n'est pas une tuile du blob. Donc **15 tuiles**, et avec les douze robes : **27 pour un
  tileset complet**, contre 59.

  ⚠ **LES DEUX VOCABULAIRES DIVERGENT, ET J'AI TROUVÉ OÙ.** La canonicalisation du blob
  **jette** le contact diagonal isolé — « un coin diagonal isolé ne change pas la silhouette
  de la tuile ». Le réseau dual, lui, **a une tuile pour ça** : deux quadrants opposés
  pleins, les deux autres vides. Mesuré avant d'écrire une ligne : `minimal` couvrait
  **15/16** configurations de coin et `ample` **14/16**, et les manquantes étaient
  exactement les deux diagonales. Ce n'est pas un oubli de dessin, c'est structurel — un
  guide complet en blob 47 n'est **pas** automatiquement complet en dual, et ne peut pas
  l'être.

  La divergence est **assertée en code** : sur un relief à contact diagonal, `Coverage` voit
  deux cases isolées (index 0 chacune) là où `CornerIndex` voit sa tuile `NO+SE`.

  **Correctif** : deux cases en diagonale ajoutées au guide minimal en (13,13) et (14,14),
  choisies par recherche parmi les emplacements qui gardent 47/47, 12/12 et zéro robe hors
  grille. Le guide couvre désormais **15/15 croisements en surface visible**, sur 665
  croisements peignables. Asserté.

  ⚠ **Et les autres reliefs ne suivent pas encore** : `ample`, le décor de l'aperçu et la
  planche de preuve sont à 13/15, les deux diagonales manquantes. Le réseau dual reste donc
  **fermé** partout sauf sur `minimal` (règle 5). C'est affiché par le runner, pas asserté :
  ce sont des travaux en cours, et une assertion les rendrait rouges en permanence.

  ⚠ **On ne voit que le sommet, ici aussi.** Un croisement touche quatre cases qui peuvent
  être à quatre étages ; la tuile visible est celle de l'étage le plus haut des quatre. La
  couverture se compte là-dessus, jamais sur l'union — même raison que pour le blob : une
  tuile cachée ne peut ni se viser ni se juger.

  **Reste à faire pour l'ouvrir** : le champ `famille` dans la table des modes, la zone de
  travail décalée d'une demi-case, la clé `C<index>` dans `work_io`, et l'exportateur.

- **Le test des raccords : tous les bords partagés, vérifiés un par un** (`_test_seams`).
  Chercher les coutures à l'œil ne dit **jamais** si on les a toutes — l'utilisateur en
  avait coché 22 et le programme en a trouvé bien d'autres. Pour chaque paire d'index qui
  peut *réellement* se toucher — 169 est-ouest, 169 nord-sud, **énumérées depuis les
  reliefs** et non devinées depuis les bits, puisque la canonicalisation jette des bits de
  coin — il compare la dernière colonne de pixels de l'une à la première colonne de l'autre.

  **Ce qu'il assère :**
  - **la matière est continue** : zéro trou, dans les trois styles ;
  - **une falaise est UNE face** : entre deux rangées d'une même chute, les deux profils
    doivent être **identiques**. Quinze enchaînements, tolérance quasi nulle.

  ⚠ **Ce qu'il n'assère PAS, et pourquoi j'ai eu tort de vouloir l'asserter.** J'avais
  ajouté « aucun saut de teinte au-delà de 4 % » entre deux surfaces voisines. C'est faux :
  à la frontière entre une case dont le nord est plein et une case dont le nord est vide, la
  lèvre éclairée s'arrête **net**, et elle a raison — le terrain fait une marche là. Exiger
  la continuité de teinte accuserait le dessin d'être **fidèle**. Le saut reste relevé, il
  n'est plus jugé.

  ⚠ **UNE LIGNE BRISÉE SE VOIT BIEN MIEUX QU'UN DÉGRADÉ.** Le vrai défaut ne pesait que
  **2,4 %** d'écart de teinte, là où des marches parfaitement légitimes en pesaient 18 %.
  C'est pour ça que la tolérance des rangées de robe est quasi nulle et celle des surfaces
  inexistante : ce qui compte n'est pas l'amplitude, c'est qu'une **structure** se casse.

  ⚠ **Le test avait lui-même un bug, et il a inventé un défaut.** `row_for()` compte les pas
  **à partir de 1** ; j'itérais depuis 0, et la suite fabriquait un enchaînement
  « corps 0 → chapiteau » que la chute ne produit jamais. Un test faux coûte plus cher qu'un
  test absent : il envoie corriger ce qui va bien.

- **La striure d'une falaise ne se décale plus d'une rangée à l'autre.** Elle le faisait
  — `phase = 0.0 if role.y == 1 else 0.37`, « même teinte, autre grain » — et cassait
  **chaque rainure à chaque cran** : sur une chute de six cases, la paroi se lisait comme
  une pile de tuiles au lieu d'une face. C'est exactement l'ensemble de rôles que
  l'utilisateur avait coché : 21 de ses 22 marques étaient sur des robes.

  Ce qui distingue désormais les deux rangées de corps est une **assise** — une bande
  horizontale légère, tenue à distance des deux bords, donc **incapable de se voir au
  raccord**, quelle que soit la rangée qui suit. Le grain varie sans que la roche se brise.

- **L'éditeur : bandeau, deux barres, zone de travail.** La fenêtre fait 95 % de l'écran,
  centrée. En haut un bandeau fin porte le nom, la version, le slogan, et une ligne qui
  déroule la charte — la seule fantaisie du logiciel, et chaque phrase y est vraie.

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

- **Clic gauche pose, clic droit efface.** Éprouvé à la main : l'inverse se trompait de
  réflexe à chaque geste. L'effacement suit les mêmes règles de remplissage que la pose —
  effacer une case efface ses jumelles, sinon l'état divergerait.

- **Le crayon refuse ce qui n'est pas une tuile** (règle 5). Seules les cases qui portent
  quelque chose — surface visible ou case de robe — se peignent ; la plaine n'est pas une
  tuile du tileset. La case survolée est cerclée de blanc si elle se peint, de rouge sinon :
  le refus se voit avant le clic.

- **⚠ EN VUE D'ENSEMBLE, UN FAUX PIXEL MESURE MOINS D'UN PIXEL D'ÉCRAN**, et l'on croit
  alors que rien ne se passe. À la taille qui montre tout le guide, une case fait une
  trentaine de pixels et en porte soixante-quatre : ce qu'on pose est littéralement
  invisible. Le symptôme est trompeur — « la fonction ne marche pas » — alors que la
  mesure disait le contraire : un seul trait peignait **204 cases** par les jumelles et
  faisait monter les jauges. En dessous du seuil, les cases qui portent de la peinture
  sont donc **cerclées**, et le travail se voit.

- **« Peindre les jumelles » est coché d'emblée.** Deux jumelles ne sont pas deux tuiles
  qui se ressemblent : c'est la même tuile, vue à plusieurs endroits. Les remplir ensemble
  ne peut donc jamais être faux, et l'avoir à zéro par défaut donnait l'impression que la
  fonction n'existait pas.

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

## Version

Elle vit dans `project.godot` (`application/config/version`) et **nulle part ailleurs** :
le bandeau de l'éditeur la lit là. Deux endroits finiraient toujours par se contredire.

À **1.1.0** : noyau prouvé, deux paysages complets, quatre fonds, l'éditeur qui peint,
le travail qui s'enregistre et se rouvre, le tileset qui s'exporte, et le paysage qui se
remonte sous les yeux.

Quand la monter, et je le proposerai le moment venu :
- **correctif** — un défaut réparé, rien de neuf à l'écran ;
- **mineure** — une capacité de plus que l'utilisateur voit : un paysage, un outil, un
  exporteur ;
- **majeure** — ce qui périme l'existant : un format de guide qui change, un export dont
  la sortie n'est plus la même.

## Références

- **Satyron** (`D:\Satyron`) — le jeu où ce modèle a été établi empiriquement puis éprouvé
  sur une vraie carte. AbsoluTiles en fait un outil universaliste. À lire quand un doute
  survient sur le comportement d'une falaise :
  - `WORLD/cliffs.gd` — `assemble_walls`, `_fall_at`, `_trim`, `_column_at` ;
  - `WORLD/tiles/cliff_kit.gd` — le bloc 3 pans × 4 rangées et `atlas_row` ;
  - `DEV_TOOLS/make_cliff_kits.py` — comment la feuille de robes est composée ;
  - `CLAUDE.md`, section « Les colonnes — la seule verticalité qu'on automatise ».

## Questions ouvertes

- **Ouvrir le réseau dual dans l'interface.** Le noyau est là et prouvé (voir la décision
  ci-dessus) ; il manque la plomberie : le champ `famille` dans la table des modes, la zone
  de travail décalée d'une demi-case, la clé `C<index>` dans `work_io`, l'exportateur des 15,
  et les diagonales dans `ample`, le décor et la planche de preuve.
- **Compacter le guide minimal** sans perdre la lisibilité : voir « la taille n'est pas
  prouvée minimale » ci-dessus.
- Les index à occurrence unique n'ont aucune variante : ce sont des cases obligatoires.
  Faut-il les signaler pendant le dessin (règle 6) ?
