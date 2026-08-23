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
  families.gd     le SEUL endroit ou les deux vocabulaires de surface se ressemblent
  seams.gd        les pixels que le modèle prouve identiques d'une tuile à l'autre
  symmetry.gd     rotations et miroirs, et les conditions qui les rendent licites
  painting.gd     les faux pixels posés dans chaque tuile
  mask_io.gd      lecture / écriture / accès d'un masque de guide (texte)
  coverage.gd     rapport de couverture d'un masque
  height_mask.gd  guide en relief : une hauteur par case, silhouette par étage
  walls.gd        le second vocabulaire : les robes de falaise (3 pans × 4 rangées)
  delivery.gd     quelles cases peintes deviennent des tuiles
  proof_scene.gd  la planche de preuve : un ilot par index, calculee
  work_io.gd      lecture / ecriture du travail en cours (.absolutiles)
  plugin_install.gd  copier AbsoluPaint dans un projet Godot
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
  neighbours_panel.gd  la case survolée et ses voisines, collées
  screenshot.gd   capture la fenêtre, pour se relire
guides/       guides au format texte ('.' plaine, '1'..'9' plateaux ; '#' = étage 1)
  minimal.txt          guide du mode « minimal » : une île 46x27, 47/47, 15/15 et 36/36
  ample.txt            guide du mode « ample » : archipel 84x46, 3 occurrences minimum
  minimal_preview.png  son illustration, régénérable à tout moment
  candidate_01.txt     brouillon plat dessiné à la main, 28/47, conservé comme trace
  preview.txt          le décor de l'aperçu en jeu : 24x18, une colline et une butte
tests/        tests headless
  run.gd          runner, code de sortie non nul en cas d'échec
exporters/
  tileset_png.gd  les deux planches, la planche de preuve, et leur manifeste
  trial_tileset.gd  l'essai : le guide lui-même livré comme tileset, sans peindre
addons/absolupaint/   LE PLUGIN MOTEUR -- ce qui part chez l'acheteur
  rules.gd        la regle de pose, portee du noyau, sur un monde NON BORNE
  manifest.gd     lecture du `<nom>_tileset.txt`, et ses trois refus
  tileset.gd      du manifeste au TileSet Godot : deux sources d'atlas
  world.gd        le noeud `AbsoluPaintWorld` : un relief, deux TileMapLayer
  plugin.gd       l'EditorPlugin, qui ne fait qu'enregistrer le type
  README.md       la notice de l'acheteur
tools/            outils de fabrication, jamais lus par le logiciel
  accidents.py      le vocabulaire de terrain : lacs, crêtes, coudes, escarpements
  build_minimal.py  une île qui porte tout, un exemplaire de chaque accident
  build_ample.py    trois îles, donc trois exemplaires
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
  jumelles, et un compteur sans coordonnées ne permet pas d'aller les chercher.
  `occurrences` reste exposé tel quel pour la lisibilité des tests.

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

- **Une case n'est retenue que si elle a été peinte** (`core/delivery.gd`). Quand
  plusieurs cases du guide portent le même index, ce sont des **jumelles** ; une
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

- **`ample`, second mode : ouvert.** Même complétude que `minimal`, mais volontairement plus
  de répétitions : chaque tuile se voit dans **au moins trois contextes**, ce qui rend le
  geste plus sûr et remplit l'écran plus vite sous le crayon. Le nom existe tel quel en
  français et en anglais, s'oppose proprement à `minimal`, et dit « qui a de la place » sans
  dire « gros ».

  ⚠ **La promesse est chiffrée, donc elle se prouve** (règle 4). `min_variants` vaut 3, et
  la barre porte sur les **trois** vocabulaires : 47 index de surface, 15 croisements,
  36 rôles de robe. La suite refuse le mode si l'un d'eux tombe à deux.

  ⚠ **Ce que ça change pour celui qui peint** : dans `minimal`, 22 tuiles n'ont qu'une seule
  occurrence, donc 22 cases sont **obligatoires** et leur oubli bloque l'export. Dans
  `ample`, **aucune** tuile n'est dans ce cas. C'est ça, le confort qu'on vend.

- **Le mode minimal livre deux familles : 47 + 36 = 83 tuiles.** `coverage.gd` prouve la
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

- **`guides/minimal.txt` : une île côtière 46x27, deux étages, complète sur les trois
  vocabulaires.** 47/47 en surface visible, 15/15 croisements, 36/36 rôles de robe, aucune
  robe hors grille — asserté par le runner, pas affiché (règle 4). **744 surfaces visibles,
  854 croisements et 404 cases de robe** pour 59 tuiles obligatoires par case, 51 à cheval.

  **Chaque famille d'index y est portée par un accident de terrain choisi pour ça**, et
  c'est ce qui permet au guide de rester un paysage au lieu d'un damier :
  - *district lacustre* — le motif des petits lacs est un **tore de de Bruijn 4x4**, dont
    les seize fenêtres 2x2 sont toutes distinctes. Chaque case entre quatre lacs voit donc
    une combinaison différente d'encoches : les **seize** index « tous cardinaux » tombent
    d'un seul district de 11x11, là où les disperser en aurait demandé le triple ;
  - *crêtes à rameaux, dressées et couchées* — une arête droite bordée d'un épaulement
    discontinu. Le motif de l'épaulement porte les quatre voisinages utiles, ce qui donne
    les seize index « trois cardinaux », les pointes et les crêtes étroites.
    ⚠ **Il faut les deux orientations** : une crête dressée ne donne que les voisinages
    nord-sud, une couchée que ceux est-ouest ;
  - *chaos rocheux* — les quatre **coudes** (deux cardinaux adjacents sans diagonale) et les
    quatre **fourches** (trois cardinaux sans diagonale), qu'on n'obtient d'aucune masse
    pleine ;
  - *rivage sud en deux escarpements à contreforts* — les 36 rôles de robe ;
  - *écueils et contacts diagonaux* — l'index 0, une seule case sans voisin, et les deux
    croisements que la canonicalisation du blob jette.

  ⚠ **Deux étages suffisent, et le troisième a été retiré.** Il existait pour les chutes
  profondes ; celles-ci viennent désormais de l'escarpement côtier, qui plonge de l'étage 2
  droit dans la plaine — six cases, donc les quatre rangées de robe. Rien ne demande neuf.
  L'empilement, lui, se voit toujours : étage 2 sur étage 1 sur la plaine.

  ⚠ **UN ACCIDENT NE SE POSE PAS SOUS UN AUTRE.** Le coude E+S du chaos rocheux était
  tombé juste au sud d'une crête dressée, qui lui donnait un voisin nord : il devenait
  N+E+S, et l'index E+S **disparaissait du guide**. Une rangée de terre les sépare. C'est
  le genre de faute qu'aucune relecture ne voit et que le compteur attrape en une seconde.

- **CE QUI COMPTE N'EST PAS LE NOMBRE DE CASES, C'EST LA TAILLE DE LA CASE À L'ÉCRAN.** Le
  guide est passé de 60x28 à 46x27 — **26 % de cases en moins** — mais le vrai gain n'est
  pas là. Ce qu'on a retiré, c'est de la **plaine** : l'ancien guide était vide aux deux
  tiers, le nouveau porte **744 surfaces peignables contre 627**, sur moins de place.

  ⚠ **ET IL SE COUCHE, IL NE SE DRESSE PAS.** Mon premier essai compact faisait 28x36 :
  1008 cases, la version la plus petite à laquelle je sois arrivé. À l'écran elle était
  **pire** — haute et étroite dans une zone de travail large, elle laissait la moitié du
  cadre vide et la case ne grandissait pas. Les accidents se posent donc **côte à côte**, en
  une bande d'ouest en est, et le guide épouse la forme du cadre. La case passe d'environ
  20 à 26 pixels d'écran, soit **+30 %**.

  C'est l'argument commercial qui tranche : l'acheteur doit voir, d'un coup d'œil et en
  temps réel, un grand nombre de tuiles se remplir sous son crayon — pour comprendre le peu
  qu'il aura à dessiner. Une case trop petite pour qu'on y distingue les faux pixels ne
  montre rien.

  ⚠ **La taille n'est toujours pas prouvée minimale**, et elle ne le sera pas : « minimal »
  ne veut pas dire « le plus petit », mais « le plus petit qui reste un paysage ».

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

  Une clé nomme une tuile et son rang d'occurrence : `S<index>:<n>` pour une surface,
  `W<pan>,<rangée>:<n>` pour une robe. Le rang est la position de la case dans son groupe,
  **en ordre de lecture** — le seul ordre qui ne dépende que du guide et jamais du
  remplissage d'un dictionnaire.

  ⚠ **Ce qui ne retombe pas sur ses pieds est dit, pas jeté.** Si le nouveau guide offre
  moins d'exemplaires d'une tuile que le fichier n'en portait, les occurrences en trop sont
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

  ⚠ **C'est la PREMIÈRE OCCURRENCE PEINTE qui sort, quel que soit son rang.** Une tuile
  peinte à sa troisième occurrence sans l'avoir été à la première sort quand même : le rang
  dans le guide ne veut rien dire pour qui relit la feuille. Et on garde le plus petit rang
  plutôt que le premier rencontré, parce qu'un dictionnaire ne promet aucun ordre — un
  export qui changerait d'une fois sur l'autre serait indéfendable.

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
  c'est le même dessin, vu ailleurs. Et il pioche toujours la première occurrence, sinon le décor
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

- **LES VARIANTES SONT SUPPRIMÉES. Une tuile, un dessin, une case de planche.** Le mot
  faisait **deux métiers** : les **occurrences** d'une tuile dans le guide — ses jumelles,
  un même endroit vu plusieurs fois — et les **dessins distincts** qu'on empilait en
  rangées supplémentaires dans la planche exportée. Deux choses sans rapport sous un seul
  nom, et `min_variants` comptait en fait les premières. Il s'appelle `min_occurrences`.

  ⚠ **Le second système était déjà dormant.** « Peindre les jumelles » est coché d'emblée,
  donc toutes les jumelles portent le même dessin, le dédoublonnage les réduisait à un, et
  `variants` valait **toujours 1** en usage normal. Il ne servait qu'à qui décoche et peint
  différemment — ce que personne ne fait au premier passage (charte, règle 2).

  ⚠ **Ce que les jumelles apportent n'est pas « plusieurs dessins ».** C'est que **peindre
  une tuile en remplit des dizaines sous les yeux, en temps réel** : l'acheteur voit d'un
  coup d'œil le peu qu'il aura à dessiner. C'est un argument de vente, pas une donnée
  d'export. Confondre les deux faisait payer à la feuille le prix d'une démonstration.

  **Ce qu'on y gagne** : les deux planches ont une **taille fixe** — 8x6 et 9x4 — qui ne
  dépend ni du guide ni de ce qui a été peint. Le lecteur qu'on écrira deux fois, pour
  Godot et pour Unity, calcule la case d'une tuile sans rien lire d'autre que le manifeste.
  La clause `sheet fixed_size one_drawing_per_tile no_variants` est au contrat.

  ⚠ **C'était la dernière fenêtre où c'était gratuit** — la même que pour les neuf pans.
  Aucun lecteur n'existe encore ; demain, en changer périmerait un moteur.

  Un système de variantes digne de ce nom viendra plus tard, et il sera conçu **pour
  lui-même** plutôt que déduit d'un effet de bord du dessin.

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

  **Correctif** : le **contact diagonal** est devenu un accident de terrain à part entière
  (`accidents.contact_diagonal`), posé dans les deux guides. Ils couvrent désormais
  **15/15 croisements en surface visible**. Asserté.

  ⚠ **La couverture duale fait partie de ce qu'un mode ouvert garantit**, et c'est asserté
  pour **tous** les modes livrés, plus seulement pour `minimal` : `ample` couvre lui aussi
  15/15, trois fois chacun. Un guide qui ne couvrirait pas les quinze ne pourrait pas offrir
  la famille à cheval, donc son mode ne se choisirait pas (règle 5).

  ⚠ **Le décor de l'aperçu, lui, reste à 13/15, et c'est sans conséquence.** Il n'a rien à
  prouver : il montre *comment ça rend*, pas *si tout est peint*. Une carte ordinaire n'use
  qu'une poignée de tuiles — c'est même la vérité qu'il existe pour dire.

  ⚠ **On ne voit que le sommet, ici aussi.** Un croisement touche quatre cases qui peuvent
  être à quatre étages ; la tuile visible est celle de l'étage le plus haut des quatre. La
  couverture se compte là-dessus, jamais sur l'union — même raison que pour le blob : une
  tuile cachée ne peut ni se viser ni se juger.

  **Ouvert de bout en bout** : liste « Réseau » dans la barre de gauche, clés `C<index>`
  au carnet, zone de travail décalée d'une demi-case, remontage, planche de preuve et
  export. La famille se choisit **avant** de dessiner et se ferme au premier pixel, comme
  la taille : ce ne sont pas les mêmes tuiles, en changer rejetterait tout le travail.

- **La planche de preuve des quinze : l'îlot EST la tuile.** Pour le blob, un îlot 3x3 doit
  porter huit voisins autour d'un centre, parce que c'est le voisinage qui désigne la tuile.
  À cheval, non : une tuile de croisement ne dépend **que des quatre cases qu'elle
  chevauche**. L'îlot est donc un simple bloc 2x2 rempli selon les quatre bits de l'index,
  cinq par rangée — quinze îlots, trois rangées, puis les deux peignes de falaise en
  dessous. Les deux planches sortent de la même fonction, `ProofScene.relief(famille)`.

- **⚠ UNE TUILE N'EST LIVRÉE QUE SI SA LISTE PORTE UN DESSIN**, pas du seul fait que sa clé
  existe au rapport. Le dédoublonnage peut **vider** une liste — clé irrésolue, image
  absente — et le compte, qui ne testait que la présence, annonçait alors « exportable »
  pour une case blanche. C'est arrivé en famille à cheval : le rapport disait 15/15, la
  planche sortait **vide**, et rien ne le signalait. Le défaut de fond était ailleurs — la
  composition posait encore la lettre `"S"` en dur, donc aucune clé `C` ne se retrouvait —
  mais **le compte l'a couvert au lieu de le dénoncer**, et c'est ça qui a coûté le temps.
  Un compteur qui ne mesure pas ce qu'il prétend mesurer est pire que pas de compteur
  (charte, règle 4). D'où `_delivered()`, et un test qui lit les pixels de la planche
  composée au lieu de croire le rapport.

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

- **NEUF PANS, PAS TROIS : l'arête appartient à celui qui est devant.** C'est le changement
  le plus lourd du projet, et il vient d'un défaut que l'utilisateur a su nommer : *« 1, 2, 3
  dessinent bien une manière de voir quelle falaise est devant laquelle, alors que 4 et 5 ne
  le font pas »*.

  **La cause.** `assemble()` notait `covered[case] = true` — un simple « il y a une robe
  ici ». Donc une robe voisine comptait comme « la même face continue », **quelle que soit
  la lèvre qui l'avait lancée**. Deux faces mitoyennes issues de lèvres décalées recevaient
  toutes deux `courant` — une tuile **muette sur ses flancs par définition**. On demandait à
  une seule tuile d'être juste dans une situation qu'elle ne peut pas exprimer, et aucun
  talent de peintre ne rattrape ça.

  **La règle.** Trois états par flanc — `vide` (ma roche s'arrête) · `muet` (même face, **ou**
  mon voisin est devant : c'est lui qui tracera) · `devant` (mon voisin est en retrait, je
  porte mon angle). Le pan est le couple (ouest, est) : **9 pans × 4 rangées = 36 tuiles de
  mur. 47 + 36 = 83.**

  ⚠ **La dissymétrie est le tout.** Si les deux faces traçaient leur arête, on saurait qu'il
  y a une frontière sans savoir laquelle est proche. En donnant l'angle au seul bloc qui
  avance, **le côté qui le porte dit lequel est devant.** Et l'angle ouest est éclairci
  quand l'angle est est assombri — lumière du nord-ouest — ce qui redouble la lecture.

  ⚠ **Ce qui n'a PAS bougé : `row_for`, `fall_at`, `_trim`.** La chute et ses rangées
  tiennent déjà sur un monde réellement joué (Satyron). Seule la lecture des flancs change.

  **Le prix, mesuré avant de décider** : 150 des 342 cases de robe du guide (**44 %**) ont un
  flanc contre une autre face. Ce n'est pas un cas de coin. Et la version *pleinement*
  directionnelle — où la face en retrait marquerait aussi son flanc — demandait **16 pans =
  64 tuiles = 111 au total**. Refusée : c'est du raffinement, pas de l'information ; le coin
  du bloc qui avance suffit à l'œil. **+28 tuiles pour une ombre.**

- **Le rivage sud : DEUX ESCARPEMENTS À CONTREFORTS.** Un contrefort est une
  colonne dont le bord sud **avance** sur ses voisines : elle est donc *devant*, et porte son
  angle. Cinq éperons suffisent à porter les cinq pans à angle — bout ouest, éperon large
  (deux colonnes), éperon seul, bout est.

  ⚠ **UN CONTREFORT TOUS LES DEUX PAS N'EST PAS UN MASSIF, C'EST UN RÂTEAU.** Ma première
  version dentait une colonne sur deux : géométriquement juste, illisible comme terrain. Une
  falaise se lit d'abord comme une **paroi** ; l'éperon est l'accident, pas la règle. Le bord
  sud est donc plat sur la plus grande part et n'avance qu'à quelques endroits choisis.

  ⚠ **Et il en faut DEUX, pour une raison de terrain et non de mécanique.** Les contreforts
  du premier **atterrissent sur une terrasse** d'étage 1 : ils posent leur pied pendant que
  la paroi voisine tombe encore, ce qui donne les cinq *pieds* à angle — sans ça, au pied de
  l'éperon la robe d'à côté s'est déjà arrêtée et le flanc redevient `vide`. Ceux du second
  **descendent jusqu'à la plaine** : leur chute de six cases passe par le **corps 1**, ce
  qu'une chute de trois ne fait jamais. Un massif dont les éperons s'arrêtent à mi-hauteur et
  un autre qui plonge d'un trait : c'est du relief.

  ⚠ **La terrasse est QUATRE rangées sous la lèvre, pas trois.** `fall_at` sonde la case
  *juste sous le pied*, jamais celles que la robe traverse — une terrasse posée sur le trajet
  ne l'arrête pas. Et elle est d'**étage 1** : à l'étage 2 la robe rencontrerait son propre
  niveau, s'écrêterait, et ne poserait aucun pied.

  ⚠ **Le relief se décrit accident par accident, jamais en ASCII.** Dessiner ces formes à
  la main faisait se tromper d'une case et d'un étage à chaque essai. Le vocabulaire vit
  dans `tools/accidents.py` ; les deux guides n'en sont que des assemblages, et c'est le
  seul endroit où la géométrie d'un accident est écrite.

  ⚠ **ET IL FAUT TROIS COLONNES PLATES CONSÉCUTIVES quelque part**, sinon le pan
  (muet, muet) n'existe pas : c'est celui d'une colonne dont les deux voisines sont sur la
  même lèvre. Cinq éperons dans un bloc de huit ne laissent aucun triplet plat.

  Vérifié : **47/47 surfaces, 36/36 rôles VISIBLES, 15/15 croisements, zéro robe hors grille.**

- **Le guide d'`ample` : un archipel de trois îles, 84x46** (`tools/build_ample.py`). Chaque
  île porte **tous** les accidents — district lacustre, crêtes à rameaux dressées et
  couchées, chaos rocheux de coudes et de fourches, et un rivage sud en deux escarpements à
  contreforts, l'un à banquette, l'autre plongeant droit dans la plaine. Trois îles, donc
  trois occurrences, **par construction et non par retouche**.

  ⚠ **PREMIÈRE VERSION REFUSÉE : un damier de spécimens.** J'avais posé chaque accident sur
  sa propre dalle, alignés en grille. C'était complet du premier coup — et ça ne se lisait
  pas comme un paysage mais comme une planche d'échantillons. **Les accidents se posent sur
  une terre continue**, avec des côtes découpées ; le guide est un paysage, sinon il n'est
  qu'un tableau.

  ⚠ **DEUXIÈME VERSION REFUSÉE : la même île trois fois.** Même largeur, même lèvre, même
  disposition intérieure — la répétition se voyait d'un coup d'œil. C'est exactement la
  leçon des quatre crêtes de `minimal`, et elle vaut à toutes les échelles. Les trois îles
  ont donc chacune leur largeur (26, 24, 28), leur lèvre côtière (26, 29, 25), leur
  disposition intérieure et leur jeu d'éperons.

  ⚠ **Mais un jeu d'éperons ne se varie pas librement** : il doit porter les cinq
  configurations — bout ouest, paire mitoyenne, éperon seul, bout est — sinon il manque des
  pans à angle. **La forme se varie, la grammaire non.**

  ⚠ **Le générateur est gardé au dépôt**, contrairement à celui de `minimal` qui s'est
  perdu. Sans lui, `guides/ample.txt` n'est qu'un tapis de chiffres : on ne saurait plus
  quel accident porte quelle famille, ni comment le retoucher sans tout casser. C'est un
  outil de fabrication, jamais lu par le logiciel — lui ne lit que le guide.

- **La sauvegarde passe en version 2, et les robes v1 sont RENDUES, pas reposées.** Un pan v1
  valait 0..2 ; un pan v2 vaut 0..8. Les reposer les mettrait de travers **en silence** —
  exactement ce que `work_io` existe pour éviter. Les clés `S` de surface, elles, n'ont pas
  bougé et se relisent sans rien perdre.

  ⚠ **C'est la ligne « le sens d'une tuile change → cette tuile est perdue » de la table des
  risques.** Elle ne coûte rien aujourd'hui puisque rien n'est encore peint. C'était le
  dernier moment où c'était gratuit.

- **Le manifeste devient un CONTRAT, pas une notice.** Une seconde moitié du projet posera le
  monde dans Godot et Unity, en autotiling complet — comme Satyron, mais exact. C'est donc
  **nous** qui écrirons le lecteur du manifeste, deux fois. Il doit porter la **règle de
  pose**, pas seulement la table des cases : placer trois pans était trivial, placer neuf
  demande de connaître la lèvre de son voisin.

  **Le but final** : l'artiste peint une fois, bien guidé ; l'export est toujours exact ; le
  game dev peint son monde sans penser à rien d'autre.

- **⚠ UNE CASE DE FALAISE EST UNE CASE DE ROCHE.** Le flanc `vide` rentrait de 10 % — un
  retrait décoratif, hérité du temps où il servait à laisser voir l'étage du dessous. Il
  était faux deux fois. D'abord parce qu'il **fait disparaître de la matière que le modèle
  affirme** : la case voisine dessine déjà la plaine, la falaise n'a pas à s'amincir pour
  lui faire place. Ensuite et surtout : dès qu'une colonne descend plus bas que ses voisines
  — ce qui arrive dès que deux chutes n'ont pas la même hauteur, donc **partout** — ses
  flancs passent de `muet` à `vide` en cours de route, et **la face changeait d'épaisseur en
  descendant**. L'utilisateur l'a repéré sur dix-huit cases ; c'était un seul défaut.

  Le vide se dit désormais par **l'ombre du bord**, jamais en mangeant la roche.

- **⚠ UNE SEULE LARGEUR DE BANDE, ET C'EST LA TEINTE QUI PARLE.** Le liseré du `vide` faisait
  0,10 de tuile et l'angle du `devant` 0,055 — et comme **l'état d'un flanc change en
  descendant** (le voisin est en retrait sur trois rangées, puis sa robe s'arrête), la bande
  passait de large à étroite **en cours de colonne**. Elle pulsait, ce qui se lit comme une
  négligence. Pire : les deux largeurs ne dérivaient pas de la même source — l'une était une
  fraction fixe, l'autre héritait du facteur d'exagération du mode Représentatif — si bien
  que **leur rapport s'inversait d'une technique à l'autre**. Deux accidents, aucune
  intention.

  Une seule largeur désormais, et la teinte dit ce qui se passe : le **vide est doux** — la
  plaine à côté fait déjà tout le contraste — l'**arête est franche**, puisqu'elle a de la
  roche des deux côtés. La bande descend d'un trait, seule sa couleur bouge.

- **Les trois cases de vue disent « masquer », pas « afficher ».** Masquer la grille · le
  guide · le travail. Une case à cocher qui **commence cochée** est un mensonge d'ergonomie :
  elle donne à croire qu'on ajoute quelque chose alors qu'on en retire. Les trois retirent
  une couche et partent toutes décochées, l'écran complet. « Masquer le travail » est
  l'inverse exact de « Masquer le guide » : il sert à comparer ce qu'on a peint à ce qu'il
  fallait peindre.

- **Le manifeste porte la RÈGLE DE POSE, pas seulement la table des cases**
  (`<nom>_tileset.txt`, version 2). Une seconde moitié du projet posera le monde dans Godot
  et dans Unity : **c'est nous qui écrirons le lecteur, deux fois**, et deux lecteurs qui se
  fient à leur mémoire finissent toujours par diverger. La règle vit donc dans le fichier,
  une seule fois.

  ⚠ **Nécessaire et suffisant.** Quelqu'un qui n'a *que* ce fichier et les planches doit
  pouvoir poser un monde correct. Si une règle manque, elle vivra dans la tête de celui qui
  a écrit le premier moteur — et le second divergera sans que rien ne le dise. Le test
  vérifie que **chaque clause y est** : le relief par silhouettes, l'ordre de dessin, les
  huit bits et leur canonicalisation, la surface visible, la face au sud seulement, la
  chute et sa sonde sous le pied, l'écrêtage sans pied, la rangée par pas, et le pan comme
  couple de flancs comparés à la lèvre.

  La forme : des lignes `clé valeur` lisibles par un programme, et des commentaires `#` qui
  disent *pourquoi*. Un lecteur n'a besoin que des premières ; un humain qui doit
  réimplémenter a besoin des secondes.

- **L'EXAGÉRATION EST ELLE-MÊME UNE MARQUE DE TRAVAIL, et « Utilisable » a donc disparu de
  la liste des techniques.** Il n'était rien d'autre que Représentatif **sans ses marques** :
  ni marqueurs de coin rentrant, ni tirets de rangée, **ni traits épaissis** (lèvre ×1,7,
  trait ×1,9, bandes de flanc ×1,6). Or la lèvre grossie et le trait large n'existent pas
  pour être beaux — ils existent pour rendre la **spécification** lisible d'un coup d'œil,
  exactement comme les tirets. Les masquer tous ensemble redonne exactement l'ancien
  « Utilisable ».

  Une entrée de liste est donc devenue une **case à cocher**, qui rejoint la famille des
  « Masquer ». Rien n'est perdu, et il reste deux techniques : **Notre dessin** et
  **Example**. La seconde question — *d'où vient le fond* — est la seule qui reste, et c'est
  la bonne : notre dessin, ou un vrai tileset.

- **La lumière portée est une couche à part, et elle DOIT l'être.** Les ombres tombent sur
  des cases de **plaine** — or la plaine n'est pas une tuile du tileset : **aucune tuile
  exportée ne peut les porter**. L'illustration montrait donc un paysage plus beau que ce que
  le tileset sait produire, c'est-à-dire qu'elle mentait, ce qu'on lui interdit. « Masquer
  les ombres » n'est pas une coquetterie : c'est un **outil de vérité**.

  ⚠ **Et ce n'est pas un simple calque par-dessus.** L'ombre de contact se pose **après** les
  sommets et **avant** les faces : une falaise la recouvre. Posée en dernier, elle noircirait
  la roche. Le rendu tamponne donc **deux images en parallèle**, l'une recevant les ombres et
  l'autre non.

  **Le soleil est au nord-ouest**, et les deux ombres portées sont ses deux composantes
  posées séparément : l'ombre de contact part vers l'**est**, l'ombre au sol vers le **sud**.
  Aucune n'est jamais diagonale, et les deux ne se rejoignent pas dans un angle. C'est une
  stylisation assumée, pas une géométrie exacte.

  ⚠ **Une falaise porte ombre à l'est, et elle ne le faisait pas.** Le test de contact lisait
  `level_at` — or **une case de robe EST une case de plaine sur la carte** : une falaise ne
  se voyait donc jamais comme « du haut ». Elle se dresse pourtant au-dessus du sol.

- **L'épaule : le coin de roche sous la lèvre sud.** Les coins sortants sont découpés, et
  sous un bord sud il y a **toujours** une falaise — la case montrait donc le fond à travers
  la roche, dans le petit angle entre l'arrondi et le haut de la face. On le remplit d'un
  aplat de pierre, volontairement distinct du corps juste en dessous : c'est le chanfrein du
  rocher, pas la face.

  ⚠ **Et celui-là est légitime là où les ombres portées ne l'étaient pas** : il vit **dans**
  la tuile de surface, donc une tuile exportée peut le porter.

- **LA PLAINE NE SE DESSINE PAS. Le logiciel n'a aucun fond.** Elle ne nous appartient pas :
  dans le jeu, le sol sous les plateaux sera **un étage plat du même tileset**, posé par le
  moteur sur sa propre couche. En peindre un ici reviendrait à livrer un fond que le tileset
  ne contient pas — exactement la faute des ombres portées, en beaucoup plus large. Le guide
  laisse donc le vide, et la zone de travail y montre son propre fond.

  ⚠ **Conséquence sur les ombres portées** : elles tombent désormais sur un sol qu'on ne
  dessine plus. Elles restent, parce qu'elles aident à lire le relief — un plateau qui
  surplombe se voit à son ombre — mais leur statut est clair : **pure aide à la lecture**,
  toujours masquable, et jamais quelque chose que le tileset livre.

- **LE VIDE, ET LA PLAINE QUI DEVIENT UN PLATEAU.** C'était la première pièce qui manquait
  côté moteur, et elle en a débloqué trois.

  Le modèle ne savait pas distinguer **« case à l'étage 0 »** de **« case hors du monde »**.
  Il ne pouvait donc pas dire où le sol s'arrête, et AbsoluPaint ne posait aucun étage 0 :
  le sol du jeu restait à la charge de l'acheteur.

  **`~` est le vide**, `HeightMask.VOID` vaut −1, et **le hors-grille est du vide**. Côté
  plugin la même inversion : une case **absente du dictionnaire n'est plus de la plaine mais
  du hors-monde**. La plaine, elle, se déclare.

  ⚠ **`level_at` REND −1, PAS 0, ET C'EST CE QUI REND LE CHANGEMENT SÛR.** Tout le code qui
  teste `>= N` avec N ≥ 1 est inchangé — le vide y échoue exactement comme la plaine. Seul
  ce qui teste `>= 0` voit la différence, et c'est précisément l'étage 0.

  **Conséquence : la plaine est un plateau comme les autres.** Elle a sa silhouette — tout
  ce qui n'est pas le vide — ses **47 index**, et ses **falaises** là où elle borde le vide.
  C'est le bord du monde. **Aucune tuile nouvelle** : ce sont les mêmes 47 et les mêmes 36.

  ⚠ **UNE ROBE QUI NE TROUVE RIEN SOUS ELLE TOMBE D'UN ÉTAGE DE PLUS.** `fall_at` partait de
  `STOREY_TILES × niveau`, ce qui donnait zéro pour la plaine : elle n'aurait jamais eu de
  falaise. Elle part de `STOREY_TILES × (niveau + 1)` et **ne pose pas son pied** — on ne
  touche pas le fond d'un gouffre.

  ⚠ **CHAQUE RELIEF DOIT DÉSORMAIS DÉCLARER SON BORD**, et la marge vaut **une chute
  entière** : trois rangées de vide autour. Sans elle, la falaise du bord du monde tombe
  hors du cadre — et une robe hors du cadre est une tuile impeignable. Les deux guides, le
  décor de l'aperçu et la planche de preuve s'entourent donc de `~`.

  ⚠ **ET LE TABLIER DE SOL DE L'ÉDITEUR A DISPARU.** Il dessinait une plaine décorative
  autour du guide ; le guide porte maintenant la sienne, avec sa falaise. Garder les deux
  aurait étendu la plaine **au-delà de la falaise que le guide venait de déclarer** —
  c'est-à-dire contredit le guide. Hors du monde, c'est le fond du programme, et c'est
  désormais une vérité du guide, pas une décoration.

  ⚠ **Le corps 1 apparaît donc dès l'étage 1**, sur la falaise du bord du monde : elle tombe
  de trois cases **sans atterrir**, donc sa dernière case est du corps. Le fait qu'on mesure
  est plus étroit qu'avant : *une chute QUI ATTERRIT de trois cases* ne montre pas le corps 1.

- **L'ÉTAGE 0 A RETROUVÉ SON STATUT DE DÉCOR : IL REÇOIT LE TEMPS RÉEL, IL NE PREND PAS LE
  CRAYON.** Défaut vu à l'écran : depuis la suppression du tablier, la plaine du guide
  portait la grille et acceptait le pinceau. C'est cohérent avec « la plaine est un plateau
  comme les autres » — et c'est quand même faux dans l'éditeur.

  **La bonne formulation** : la 4.0.0 a corrigé la **géométrie** du décor — il s'arrête
  maintenant à la falaise que le guide déclare, au lieu de déborder de quatre cases — mais
  elle lui a fait perdre son **statut**. On rend le statut, on garde la géométrie.

  L'étage 0 sort donc de `_paintable` : ni crayon, ni grille, puisque *la grille ne se trace
  que sur ce qui se peint*. ⚠ **Mais il reste dans les groupes de jumelles**, et c'est tout
  l'intérêt : peindre une tuile le remplit d'un coup, sous les yeux. C'est l'argument de
  vente que le tablier portait — le sol du jeu sortira du même tileset, sans rien de plus à
  dessiner.

  ⚠ **ET ÇA NE COÛTE AUCUNE TUILE, C'EST MESURÉ AVANT D'ÊTRE ÉCRIT.** Sur les deux guides
  livrés, les **47** index, les **15** croisements et les **36** rôles se trouvent tous hors
  de la plaine — et `ample` y tient même ses **trois** occurrences. La plaine ne portait que
  9 index et 9 rôles, tous présents ailleurs.

  ⚠ **Un guide retouché demain pourrait poser un accident sur la plaine sans que personne y
  pense**, et la tuile deviendrait impeignable **sans que rien ne le signale** — le rapport
  de couverture, lui, la compterait. D'où l'assertion : chaque mode doit trouver tout son
  vocabulaire hors de la plaine, au nombre d'occurrences qu'il promet.

  `Walls.visible()` rend désormais les rôles **et l'étage de la lèvre**. Il fallait ça pour
  distinguer la falaise d'un plateau de celle de la plaine : ⚠ **une case de robe est, sur
  la carte, une case du sol d'en bas** — demander *son* étage ne dit rien de la falaise qui
  la couvre.

- **⚠ `_lonely` LISAIT LES GROUPES DU GUIDE PRÉCÉDENT.** Trouvé en déplaçant le bloc, pas à
  l'écran. Le calcul des cases sans jumelle se faisait **treize lignes avant** l'affectation
  de `_by_index` : au tout premier chargement le dictionnaire est vide, donc **aucun contour
  ambre ne se dessinait du tout**, et aux chargements suivants les marques étaient celles
  d'un autre paysage.

  ⚠ **UNE MARQUE ABSENTE NE SE REMARQUE PAS.** C'est ce qui rend ce défaut plus vicieux
  qu'un dessin faux : rien ne clignote, rien n'est de travers, il ne se passe simplement
  rien. Et aucun test ne pouvait le voir — la suite ne monte pas l'interface.

  Au passage, le compte se fait maintenant sur **ce qui se peint**, pas sur le guide entier :
  une tuile vue trois fois dont deux sur la plaine n'a en vérité qu'**un** endroit où on
  puisse la faire, et laisser croire au choix serait mentir sur ce qui est obligatoire.

- **⚠ UNE INSERTION QUI SE TROMPE DE FIN DE FONCTION NE SE VOIT NULLE PART.** En ajoutant
  `_build_ground()` j'ai ancré sur la boucle des jumelles, en croyant qu'elle terminait
  `show_guide`. Toute la queue de la fonction — dont **`_redraw_background()`** — s'est
  retrouvée orpheline dans la fonction suivante. Le fichier se chargeait, la suite passait
  à 289 vérifications sans un échec, et **le fond du guide ne se dessinait plus du tout**.
  C'est la capture d'écran qui l'a montré, pas les tests : aucun d'eux ne monte l'interface.
  Quand une édition déplace du code, la relire à l'œil **et** regarder l'écran.

- **LE SOUS-PIED, ET POURQUOI IL NE COÛTE AUCUNE TUILE.** Une case d'atterrissage a ses
  coins nord **découpés** — son voisin du nord est plus bas, c'est la face de la falaise —
  et par ces coins on voyait **le sol au lieu de la roche qui continue derrière**. Le défaut
  sautait aux yeux sur les banquettes des contreforts : une petite dalle verte arrondie
  collée sous une paroi.

  **On repose donc le PIED une case plus bas, SOUS la surface.** La case d'atterrissage le
  recouvre entièrement sauf par ses coins — et c'est exactement là qu'il manquait.

  ⚠ **CE N'EST PAS UNE TUILE DE PLUS, C'EST UNE POSE DE PLUS.** J'avais d'abord conçu une
  cinquième rangée de mur : **+9 tuiles**, planche 9x5. Elle butait sur un mur infranchissable
  — **toute tuile à peindre a besoin d'une case du guide pour la porter**, et la case
  d'atterrissage est **déjà une case de surface**. La déclarer case de robe l'aurait rendue
  peignable deux fois, et l'éditeur n'aurait plus su quelle tuile elle porte. Reposer le
  pied règle tout : zéro tuile, zéro case, une clause au contrat.

  ⚠ **Le pan est celui du pied, sans rien recalculer.** C'est la même face, une case plus
  bas. Lui redemander ses flancs reviendrait à l'interroger sur une rangée qu'aucune robe
  n'occupe, et la réponse n'aurait pas de sens.

  ⚠ **ET IL SORT À PART DE `roles`.** Le mettre dedans aurait fait de la case d'atterrissage
  une case de robe : `visible_roles` l'aurait revendiquée, elle serait devenue peignable, et
  le compte des tuiles obligatoires aurait basculé. `assemble()` rend donc `underfoot`
  séparément.

  ⚠ **L'ORDRE EST LE PIÈGE, ET JE SUIS TOMBÉ DEDANS.** J'avais posé tous les sous-pieds
  **avant toutes les surfaces**. L'illustration dessine **tous les étages**, du bas vers le
  haut : la plaine recouvrait donc le sous-pied avant même que la banquette n'arrive, et les
  coins montraient de nouveau le sol. Le sous-pied se pose **juste avant la surface de
  l'étage où il atterrit**. Mesuré à l'écran, pas au test — et la suite était verte pendant
  ce temps-là.

  ⚠ **Le test lit un PIXEL, pas une intention** : sur une case d'atterrissage isolée du
  guide, le coin nord-ouest doit être chaud (roche) et le milieu vert (herbe).

- **LA BATTUE CONNAÎT LE VIDE, MAINTENANT QU'IL EXISTE.** Un relief binaire n'a que deux
  états ; le monde en a **trois** depuis que le hors-monde se déclare. Une battue qui ne pose
  jamais de vide ne cherche plus dans tous les cas : elle ne verrait jamais la falaise du
  bord du monde, ni une robe qui n'atterrit pas.

  Ajouté : **19 683 reliefs 3x3 à trois états**, exhaustifs, plus les tirages aléatoires
  retroués de vide. Zéro contre-exemple.

  ⚠ **Le 3x4 — 531 441 reliefs — a été passé UNE FOIS, hors suite : zéro contre-exemple.**
  Il faisait passer la suite de une à **sept minutes**, et *une suite qu'on n'ose plus
  lancer ne prouve plus rien*.

  ⚠ **La suite dure maintenant ~5 minutes** : les guides ont grossi (marge de vide) et la
  plaine est devenue peignable, donc les tests de couverture et de raccord portent sur
  presque le double de cases. C'est un coût à surveiller.

- **UN GARDE-FOU QUI NE REGARDE QUE D'UN CÔTÉ NE GARDE RIEN.** Le lecteur du manifeste
  refusait une version **plus récente** que celle qu'il sait lire — et rien d'autre. Or
  entre deux livraisons le **sens** de la règle a bougé deux fois sans que la version
  bouge : le hors-carte est passé de la plaine au **vide** (4.0.0), puis le **sous-pied**
  est apparu (4.1.0). Un manifeste v3 d'avant-hier et un v3 de ce soir décrivaient **deux
  mondes différents**, et le plugin les posait tous les deux sans broncher.

  Le manifeste passe donc en **version 4**, et le lecteur porte **deux bornes** :
  `READS_FROM` autant que `READS_UP_TO`. La haute dit « je ne connais pas encore cette
  règle », la basse « je ne connais plus celle-là ». La v3 est refusée nommément, avec le
  conseil de réexporter.

  ⚠ **Une version qui ne bouge pas quand le sens bouge ne protège de rien**, et c'est pire
  que pas de version du tout : elle donne l'air d'un contrôle. Le test vérifie désormais
  les deux refus, et que **le plugin lit exactement ce que l'exportateur écrit**.

- **« PEINDRE LES JUMELLES » N'EST PLUS UNE OPTION : c'est le comportement.** Deux jumelles
  ne sont pas deux tuiles qui se ressemblent, c'est **la même** tuile vue à plusieurs
  endroits ; les remplir ensemble ne peut donc jamais être faux.

  ⚠ **ET DEPUIS QUE LES VARIANTES ONT DISPARU, LA DÉCOCHER NE POUVAIT PLUS QUE FAIRE PERDRE
  DU TRAVAIL.** La planche a une taille fixe : une tuile, un dessin. Peindre mille jumelles
  différemment n'en sortait **qu'une** — la première — et jetait les autres **en silence**.
  La charte l'interdit deux fois : on ne perd pas du travail sans le dire (règle 4), et ce
  qui n'est pas garanti ne se propose pas (règle 5). La case est retirée ; elle reviendra
  avec un vrai système de variantes, conçu pour lui-même.

  ⚠ « Peindre les rotations » reste, et c'est une autre affaire : elle **fabrique**
  délibérément, elle part décochée, et son infobulle dit ce qu'elle fait.

- **L'ESSAI : LE GUIDE LUI-MÊME, LIVRÉ COMME TILESET** (`exporters/trial_tileset.gd`).
  Le logiciel prouve que les tuiles sont complètes, le plugin s'en sert — et entre les deux
  il manquait de quoi **essayer**. Tant qu'aucun pixel n'est peint, l'export refuse, à juste
  titre : le game dev n'a rien à poser et doit croire sur parole.

  Or nous avons déjà un dessin complet de chaque tuile : **l'illustration du guide**. Elle
  est calculée depuis le relief, n'emprunte aucun pixel, et couvre par construction tout ce
  que le guide couvre. On la verse dans un carnet de peinture comme si elle avait été peinte
  à la main, et on la fait sortir **par le chemin normal**.

  ⚠ **PAS DE CHEMIN DE TRAVERSE, ET C'EST TOUT L'INTÉRÊT.** `TilesetPNG.write` ne sait pas
  qu'il exporte un essai : le manifeste est le vrai, les planches sont les vraies, et le
  refus d'une feuille incomplète s'applique. **Si l'essai sort, c'est que la chaîne entière
  marche** ; s'il ne sort pas, elle est cassée pour tout le monde.

  ⚠ **UN SEUL TEST PARCOURT LA CHAÎNE ENTIÈRE**, et c'est celui-là. Tous les autres en
  éprouvent un maillon. Celui-ci part de l'illustration, exporte, **relit le manifeste avec
  le lecteur DU PLUGIN**, en fabrique un `TileSet`, et pose un monde : **618 tuiles, aucun
  trou**.

  ⚠ **Elle est entièrement à nous.** Aucune licence à lire, rien à redistribuer qui ne
  soit notre propre tracé — celui-là même qu'on efface en peignant par-dessus. Le banc
  `example`, lui, lit le tileset de Satyron et ne peut **rien** livrer.

  ⚠ **CE N'EST PAS DE L'ART, ET IL NE FAUT PAS FAIRE SEMBLANT.** C'est un dessin de
  **spécification** : des aplats, des arrondis, une striure. Il sert à poser un monde qui se
  tient et à juger l'outil, pas à habiller un jeu. L'infobulle du bouton le dit.

  ⚠ **Un tileset n'a qu'un jeu de 47**, donc l'essai fige **un seul étage** de teinte. Le
  monde posé montre ses plateaux dans la même herbe — exactement comme un vrai tileset, là
  où l'illustration teinte chaque étage pour faire lire l'altitude.

  ⚠ **Et il reste PAR CASE.** L'illustration calcule les 47 index du blob, pas les 15
  croisements : elle dessine le relief, et le relief se lit par case. On ne fabrique pas un
  dessin qu'on n'a pas (règle 5) — la famille à cheval n'a donc pas encore d'essai.

  Un bouton **« Exporter l'essai »** à côté de celui qui installe le plugin, et la ligne de
  commande pour le lot :

  ```
  godot --headless --path . --script res://exporters/trial_tileset.gd -- dossier [taille]
  ```

- **⚠ UNE CARTE COÛTEUSE NE SE RECALCULE PAS À CHAQUE TOUR DE BOUCLE — sept fois la même
  faute, toutes de moi.** Le motif : `for x in cher().keys(): ... cher()[x] ...`. L'en-tête
  de boucle ne s'évalue qu'une fois, mais le **corps** rappelle la fonction à chaque
  itération — et ces fonctions-là parcourent tout le relief.

  Mesuré avant / après :

  | | avant | après |
  |---|---|---|
  | `Trial.paint` (minimal) | 36 500 ms | **1 185 ms** |
  | `Trial.paint` (ample) | 303 300 ms | **1 230 ms** |
  | `Assembly.from_painting` | 13 490 ms | **43 ms** |
  | planche de preuve remontée | 74 744 ms | **161 ms** |
  | la suite entière | 5 min 11 | **1 min 20** |

  ⚠ **C'ÉTAIT ÇA, « LE SOFT RAME » — pas une barre de progression manquante.** Une barre
  aurait *montré* l'attente au lieu de la supprimer, et rendu le défaut acceptable. Chercher
  la cause avant de décorer le symptôme : la plus longue opération du logiciel tient
  désormais en une seconde, et le fond du guide garde sa barre parce qu'il en a une vraie
  raison — il dessine cent tuiles.

  ⚠ **Et aucun test ne pouvait le voir** : la suite mesure la justesse, pas la durée. Elle
  était verte à cinq minutes comme à une minute.

- **L'ÉTAGE 0 EST DU DÉCOR, DONC IL NE PORTE AUCUNE MARQUE.** Le trait grossi, le marqueur
  de coin rentrant et le tiret de rangée existent pour rendre la **spécification** lisible
  en peignant. La plaine ne se peint pas : l'y marquer désignerait un travail qui n'existe
  pas, et ferait crier le fond plus fort que l'ouvrage.

- **ET IL LUI FAUT UN VRAI RIVAGE : épais, et qui ondule.** Une seule case d'épaisseur ne
  montrait rien — ni masse pleine, ni vrai coin, ni falaise de bord du monde. Le rôle de la
  plaine est précisément de montrer que **dans le jeu, l'étage 0 sera bordé de falaises
  comme les autres**. Le rivage fait donc **4 à 6 cases**.

  ⚠ **ET IL NE DOIT PAS ÊTRE RECTANGULAIRE.** Le cadre du fichier est un artefact ; un
  rivage droit le donne à voir et fait ressembler le monde à une découpe. La profondeur
  ondule donc le long de la côte — **deux sinus lents, jamais du bruit case par case**, qui
  donnerait une dentelure au lieu d'une côte.

  ⚠ **ON N'ENLÈVE JAMAIS DE PLAINE, ON EN AJOUTE.** Le rectangle du bâtisseur reste plein :
  les robes y tombent et y atterrissent, et raboter dessous les ferait toutes changer de
  rôle. Le rivage se pose **autour**.

  ⚠ **La vague se plafonne à l'amplitude annoncée**, et le cadre la réserve. Sans ce
  plafond elle creusait trois cases là où le cadre n'en gardait que deux : la falaise du
  rivage tombait hors du cadre et seize robes devenaient impeignables.

  **Le prix, dit franchement** : `minimal` passe de 52x33 à **64x45**, donc la case à
  l'écran de ~26 à ~20 pixels. C'est l'inverse de la compaction de la 2.2.0, et c'est un
  arbitrage à revoir si l'écran devient plus important que la démonstration.

- **LES RACCORDS OBLIGATOIRES : le même pixel, vu dans deux tuiles** (`core/seams.gd`).
  Deux cases de robe qui se touchent ne se *ressemblent* pas : par endroits, elles **sont la
  même paroi**. Le pixel qui borde l'une borde l'autre, et il n'y a aucune liberté à prendre
  — c'est un seul point de roche, vu deux fois.

  ⚠ **C'EST LA RÈGLE DES JUMELLES, D'UN CRAN PLUS FIN.** Une jumelle est la même *tuile*
  vue ailleurs ; ici c'est le même *pixel* vu ailleurs. Rien n'est fabriqué (règle 3) :
  l'artiste peint, on recopie là où l'égalité est **démontrée**. Et comme elle l'est, ne
  pas recopier ne produirait qu'un tileset faux — **donc pas de case à cocher** (règle 5).

  **Deux familles de contraintes, toutes deux déjà assertées par `_test_seams` :**
  - *verticalement*, deux rangées qui se suivent dans une même chute sont la même face ;
  - *horizontalement*, deux flancs `muet` face à face signifient la même lèvre.

  ⚠ **ET LA CHAÎNE BOUCLE, CE QUI VA PLUS LOIN QU'IL N'Y PARAÎT.** Une chute de trois donne
  « chapiteau, corps 0, pied », une de six « chapiteau, corps 0, corps 1, corps 0, corps 1,
  pied » : par transitivité, **tous les raccords internes d'un pan portent le même profil**.
  Le haut et le bas d'une tuile de corps sont donc identiques — exactement ce qu'on attend
  d'une tuile qui se répète verticalement.

  **Mesuré** : 144 bords de pixels, **78 liés** (54 %), 13 classes indépendantes. Soit
  **65 bords à peindre en moins**.

  ⚠ **LES COINS ONT COÛTÉ TRENTE DÉSACCORDS.** Un pixel de coin appartient à **deux** bords
  — il est partagé avec la voisine de l'est *et* avec celle du sud — donc à deux classes,
  qui doivent se rejoindre **là**. Sans ça, les milliers de pixels de bord tombaient juste
  et seuls les coins se contredisaient. ⚠ **Mais la fusion ne vaut qu'au coin** : on ne
  marie pas les deux classes entières, une ligne et une colonne n'ont aucune raison d'être
  égales sur toute leur longueur.

  ⚠ **LES SURFACES N'EN SONT PAS**, et c'est le point qu'il fallait avoir compris pour ne
  pas se tromper de fonctionnalité. Le modèle n'y exige que l'absence de **trou**, jamais
  l'égalité : à la frontière entre une case dont le nord est plein et une case dont il est
  vide, la lèvre éclairée s'arrête **net**, et elle a raison. Y forcer les pixels
  accuserait le dessin d'être fidèle. Ni les **arêtes** : là où un flanc dit `devant`, une
  arête est *attendue*.

  ⚠ **Le test ne vérifie pas que le dessin est juste, il vérifie qu'il ne PEUT PAS être
  faux.** `_test_seams` mesure les raccords d'une illustration déjà faite ;
  `_test_seam_propagation` peint **n'importe quoi** — une teinte tirée de la position, qui
  ne doit rien à la structure — et exige que les raccords sortent exacts quand même. C'est
  la différence entre contrôler et garantir.

  ⚠ **On propage depuis la tuile RÉELLEMENT peinte**, pas depuis la case survolée : avec
  les rotations, le crayon pose son pixel ailleurs et autrement.

- **LE PINCEAU D'ABSOLUPAINT, ET LES TROIS LEÇONS PRISES À SATYRON.** Le plugin posait un
  monde mais on remplissait `heights` à l'inspecteur. Un panneau à droite donne désormais
  l'étage (0 à 9, plus **Vide**), un bouton d'armement, et le clic gauche pose / le clic
  droit retire.

  ⚠ **LE PINCEAU S'ARME À LA MAIN, ET C'EST UN BOUTON PLUTÔT QU'UN RACCOURCI.** Tant qu'il
  est armé, la souris peint au lieu de déplacer les nœuds. Un outil qui intercepte la souris
  sans qu'on l'ait demandé fait perdre le glisser-déposer, et on met dix minutes à
  comprendre pourquoi l'éditeur ne répond plus.

  ⚠ **ON SÉLECTIONNE LE MONDE EN S'ARMANT.** `_forward_canvas_gui_input` n'est appelé que
  si `_handles` a dit oui de l'objet **sélectionné** : sans sélection, le pinceau serait
  armé et **muet** — le mode de panne le plus déroutant qu'un outil d'éditeur puisse avoir.

  ⚠ **ON COMBLE LA LIGNE.** Une souris rapide ne rapporte qu'une position tous les cinq ou
  six pixels : sans Bresenham, un trait franc laisse des trous tous les deux centimètres.
  Et le Bresenham porte une **borne** — il tourne dans l'éditeur, où une boucle infinie fige
  tout sans qu'on puisse même enregistrer.

  ⚠ **L'ANNULATION SE POSE AU RELÂCHEMENT, D'UN SEUL BLOC.** Une action par case ferait
  défaire un trait de cent cases en cent Ctrl+Z. On photographie `heights` avant le trait et
  on rend les deux états à `EditorUndoRedoManager` ; comme la propriété a un setter qui
  repose le monde, les deux sens se redessinent seuls.

  ⚠ **Et « Vide » est un choix d'étage, pas une absence de choix.** L'étage 0 est du
  **sol** — il porte une tuile et une falaise là où il borde le vide. Retirer une case est
  un autre geste, et les confondre faisait disparaître le sol au lieu de l'aplanir.

- **LA ZONE À REFAIRE : le pinceau ne repose plus la carte entière.** Poser une case change
  bien plus que sa tuile — les huit voisines changent d'index, une falaise peut s'allonger de
  trente rangées, et le pan des colonnes d'à côté bascule. `rebuild()` refaisait donc tout,
  ce qui est **juste et intenable** : mesuré, **7 ms sur 32x24 mais 456 ms sur 256x192** —
  et c'est **par case peinte**.

  **La portée se déduit du modèle, elle ne se devine pas.** Trois raisons, chacune donnant
  sa marge :
  - l'index ne dépend que d'une fenêtre 3x3, un croisement ne touche que quatre cases →
    **deux cases** de tous les côtés ;
  - une lèvre **plus haut** peut tomber à travers la case changée → vers le haut,
    `STOREY_TILES x (étage le plus haut + 1)` ;
  - la case peut elle-même devenir une lèvre → autant vers le bas, **plus le sous-pied**.

  ⚠ **LE PAN SE COMPARE À LA VOISINE, ET LA CASCADE S'ARRÊTE LÀ.** Changer une colonne
  change le pan de celles d'à côté, jamais plus loin — un pan ne modifie aucune lèvre.

  ⚠ **ON RAMASSE LES LÈVRES PLUS LARGE QU'ON NE POSE.** Le pan d'une case se lit de ce que
  les robes **voisines** couvrent à cette hauteur : en n'assemblant que la zone, les colonnes
  du bord auraient un pan faux. On assemble sur une zone élargie, on ne garde que le dedans.

  ⚠ **UNE BORNE QU'ON FRANCHIT À LA LECTURE N'EST PAS UNE BORNE.** Première version : la
  zone était bornée mais le filtrage parcourait tout le dictionnaire, et `top_level` aussi.
  Le coût suivait donc encore la carte — 1,4 ms à 32x24, 9,8 à 256x192, pour une zone qui ne
  bougeait pas d'une case. On parcourt la **zone**, et `top` se passe en paramètre.

  **Résultat : le coût ne dépend plus de la carte.** 1,3 ms à 768 cases, **2,0 ms à 196 608**.

  ⚠ **Un `top` trop grand n'est jamais faux, seulement un peu lent** — la zone est alors
  plus large que nécessaire, donc elle contient toujours ce qu'il fallait refaire. C'est la
  bonne direction pour une approximation ; l'inverse laisserait le monde faux.

  ⚠ **Deux fautes possibles, une seule se voit.** Une zone trop grande coûte du temps ; une
  zone trop petite laisse le monde faux **pendant qu'on le dessine**, et rien ne le signale.
  Le test mesure donc la seconde : sur soixante reliefs, **tout** ce qu'une retouche change
  tombe dans la zone, et le calcul borné dit **exactement** ce que dirait le complet.

- **⚠ UNE COUCHE QU'ON POSE SANS LA NETTOYER EST UNE FUITE.** `rebuild()` effaçait la couche
  des surfaces et celle des falaises — **mais pas celle du sous-pied**. Ses tuiles
  s'accumulaient à chaque coup de crayon et ne disparaissaient jamais : retirer un plateau
  laissait la roche de sa falaise sous le sol, et **le monde devenait faux pendant qu'on le
  dessinait**. Trouvé en cherchant la complexité, pas la justesse.

- **La grille ne se trace que sur ce qui se peint.** Tracée sur tout le rectangle, elle
  quadrillait surtout **ce qui n'est pas le travail** : la plaine occupe la plus grande part
  du cadre et ne se peint pas, si bien que la grille y dessinait une feuille de calcul et que
  le relief s'y noyait. Posée sur les seules cases peignables, elle dessine au contraire la
  **silhouette de ce qu'il y a à faire** — on voit d'un coup d'œil où l'on a le droit de
  poser un pixel.

  ⚠ **Chaque arête n'est tracée qu'une fois** : on pose toujours le haut et la gauche, et le
  bas ou la droite seulement au bord du peignable. Une arête intérieure appartient ainsi à la
  case du dessous ou de droite, jamais aux deux.

- **Les voisines : le raccord se juge PENDANT le geste** (`ui/neighbours_panel.gd`, section
  Crayon). Trente-six tuiles de robe dont beaucoup ne diffèrent que par une arête de deux ou
  trois pixels : c'est répétitif, et la répétition est exactement là où une main diverge. Le
  test des raccords attrape la divergence — mais l'attraper veut dire du rouge et des
  retouches, soit le va-et-vient que cet outil existe pour supprimer. Le panneau montre donc
  la case survolée entourée de ses **voisines réelles**, celles du guide, à la même échelle.

  ⚠ **Aucun écart entre les cases, jamais.** Un panneau qui espacerait ses tuiles pour faire
  joli ne montrerait plus rien du tout : c'est précisément la ligne de contact qu'on vient
  regarder. Le repérage de la case centrale se fait donc par des marques posées **dehors**.

  ⚠ **L'échelle est un entier**, comme pour l'aperçu en jeu : un demi-pixel d'écran par faux
  pixel inventerait des coutures que le dessin n'a pas.

  ⚠ **Un trou est noir, pas couleur de sol.** Je l'avais peint à la teinte de l'étage 0 : un
  panneau entièrement vide ressemblait alors à du terrain, et j'ai cru pendant trois essais
  que le panneau marchait. Un trou n'est pas du terrain, c'est ce qu'il reste à faire.

  ⚠ **Et le piège de l'outil de capture, qui vaut d'être noté** : `screenshot.gd` posait le
  survol au troisième frame, puis la **vraie souris** — garée quelque part sur l'écran —
  émettait le sien et l'écrasait. On a cru un panneau cassé alors qu'il suivait fidèlement un
  curseur qu'on ne voyait pas. Le survol se pose désormais juste avant la capture.

- **Les raccords de flanc, et la subtilité qu'il faut avoir comprise pour ne pas exiger
  l'impossible.** Deux cases de robe côte à côte décrivent la même frontière — mais elles ne
  doivent pas toujours y dire la même chose, et c'est tout l'intérêt du vocabulaire à neuf
  pans.

  ⚠ **Deux flancs `muet` face à face signifient la MÊME LÈVRE** — donc la même face, donc le
  même pas de chute, donc **la même rangée**. C'est le seul cas où l'on exige des profils
  identiques. Un chapiteau à côté d'un pied n'a aucune raison d'avoir la même teinte, et
  l'exiger accuserait le dessin d'être fidèle.

  ⚠ **Là où un flanc dit `devant`, une arête est ATTENDUE.** On n'y exige donc que l'absence
  de **trou** : de la matière d'un côté, de la matière de l'autre.

  ⚠ **Et `(devant, devant)` n'existe pas.** Si je suis devant mon voisin, il n'est pas devant
  moi. Le tester serait tester une situation que le modèle ne peut pas produire — le genre de
  faux test qui envoie corriger ce qui va bien.

  Mesuré : **36 raccords de paroi continue à 0,0 % d'écart, 288 au droit d'une arête sans un
  seul trou**, dans les trois styles.

- **Les cases sans jumelle portent un contour ambre.** Quand une tuile n'apparaît qu'**une
  fois** dans le guide, sa case est obligatoire : personne d'autre ne la portera, et
  l'oublier bloque l'export. Mesuré sur `minimal` : **25 tuiles sur 83** sont dans ce
  cas (et **zéro** sur `ample`, c'est tout ce que ce mode vend) — 14 index de surface et 8 rôles de robe — soit 22 cases obligatoires sur 1023
  peignables. Assez peu pour que les marquer se voie, assez pour que les oublier coûte.

  ⚠ **Une case sans jumelle porte son contour ENTIER.** Les arêtes partagées appartiennent
  d'ordinaire à une seule des deux cases voisines ; ici on redessine les quatre, sinon la
  marque serait rongée par les voisines et ne se lirait pas.

  Le relevé de survol le dit aussi, en toutes lettres : `[SEULE OCCURRENCE]`.

  ⚠ **Le compte est affiché par le runner, pas asserté.** Il dépend du guide, et le figer
  interdirait de retoucher celui-ci.

- **`core/families.gd` : le seul endroit où les deux vocabulaires de surface se
  ressemblent.** Sans lui, chaque compteur, chaque exportateur et chaque test se
  dédoublerait — et deux copies d'une même règle finissent toujours par se contredire. Une
  famille répond à cinq questions : quels index elle livre, quelle carte *ce-qu'on-peint →
  index* elle produit, comment elle se compte, comment se groupent ses jumelles, et par
  quelle lettre elle se nomme dans les clés.

  ⚠ **La famille n'est pas le paysage.** Le même guide sert les deux : ce sont deux axes
  indépendants, comme la taille des faux pixels. On choisit une fois, avant de dessiner.

  ⚠ **Les robes ne changent pas.** Une falaise sort du plan ; elle se pose case pour case,
  quel que soit le réseau du sol. Les 36 rôles valent pour les deux familles. Donc **83
  tuiles par case, 51 à cheval** (15 + 36).

  ⚠ **LES DEUX CARNETS NE SE MÉLANGENT JAMAIS, et c'est asserté.** Un croisement et une case
  sont tous deux des `Vector2i` mais ne désignent pas la même chose : sur le guide livré,
  **520 coordonnées sont communes aux deux familles** — les mélanger ferait se marcher dessus
  la tuile du croisement (3,4) et la robe de la case (3,4). Deux familles, deux carnets, deux
  lettres de clé (`S` et `C`), et la collision devient impossible par construction.

  Vérifié : le guide minimal couvre les **deux** familles, et offre **854 croisements**
  peignables.

  ⚠ **Une silhouette par étage, pas une par croisement.** `CornerIndex.visible_index_at` en
  reconstruisait une à chaque appel : sur soixante colonnes cela refaisait mille sept cents
  fois un masque entier, et une simple battue dépassait les dix minutes. Elles se bâtissent
  une fois.

- **UN SEUL CARNET DE PEINTURE, ET LES DEUX FAMILLES NE S'Y RENCONTRENT JAMAIS.** Un
  croisement `(i, j)` se range à la clé `(i, -1 - j)` : les cases occupent les *y* positifs
  ou nuls, les croisements les *y* strictement négatifs.

  ⚠ **Un seul carnet, pas deux, parce que tout le reste en dépend** : un seul historique
  d'annulation — `Ctrl+Z` n'a pas à deviner de quel carnet il parle —, une seule taille de
  faux pixel, un seul fichier. Deux carnets séparés rendraient l'un ou l'autre faux ou lourd.

  ⚠ **Un carnet « à cheval » contient AUSSI les robes, et elles restent sur les cases.** Une
  falaise sort du plan : elle se pose case pour case quel que soit le réseau du sol. Ce qui
  doit être disjoint, ce sont les **surfaces** des deux familles — et c'est asserté : les 813
  croisements du guide tombent tous dans les *y* négatifs et n'y rencontrent aucune case.

  ⚠ **La famille voyage dans l'en-tête du fichier**, et elle se lit **avant** les tuiles :
  elle décide de l'annuaire où l'on repose ce qu'on relit. La deviner après coup mettrait
  chaque croisement à la place d'une case. Et la lecture s'arrête à la première ligne de
  tuile — une seule pèse plusieurs kilo-octets.

  ⚠ **Piège tombé dedans** : la ligne `famille` se faisait décoder comme du base64 par la
  boucle des tuiles. Un en-tête qui n'est pas reconnu comme tel devient une donnée corrompue.

- **La zone de travail travaille en CLÉS DE CARNET, pas en cases.** Dans la famille à
  cheval, un croisement et une case peuvent avoir les **mêmes coordonnées** — 520 en commun
  sur le guide livré. La clé de carnet, elle, est disjointe par construction. En la prenant
  pour identité interne, la collision **cesse d'exister** au lieu d'être évitée au cas par
  cas : `_paintable`, `_textures`, `_stale`, `_lonely`, les jumelles, tout est keyé par elle.

  ⚠ **Un croisement se dessine décalé d'une demi-case.** Sa tuile est à cheval sur quatre
  cases : sa boîte va de (i−0,5 ; j−0,5) à (i+0,5 ; j+0,5). C'est ce décalage, et lui seul,
  qui met le guide sous la bonne tuile — **le fond ne bouge pas**.

  ⚠ **« En dessous » s'inverse pour un croisement.** Sa clé porte un *y* négatif : descendre
  d'une rangée à l'écran, c'est **décrémenter** la clé. Sans ça la grille dessine ses bords à
  l'envers.

  ⚠ **`Vector2i(-1, -1)` n'est plus « nulle part »** : c'est la clé valide du croisement
  (0, 0). Il a fallu une sentinelle explicite.

- **Quand les deux grilles se chevauchent, LA ROBE GAGNE.** Une tuile de croisement est
  décalée d'une demi-case, une robe est sur la case : leurs boîtes partagent un quart, et le
  clic serait ambigu. La robe est dessinée devant, donc c'est elle qu'on voit sous le
  curseur, donc c'est elle qu'on peint.

  **Mesuré avant de choisir la règle** : quelques dizaines de croisements deviennent inatteignables au
  clic — mais **les quinze index gardent chacun un croisement libre**, et les jumelles
  remplissent le reste. **Aucune tuile n'est perdue.** C'est la garantie qui compte, et c'est
  celle-là qu'il fallait mesurer, pas le nombre de cases.

- **Le réseau se ferme au premier pixel, comme la taille.** En changer rejetterait tout ce
  qui est peint : ce ne sont plus les mêmes tuiles.

- **⚠ « CHARGE » NE VEUT PAS DIRE « COMPILE ».** Un script dont l'analyse échoue rend malgré
  tout une ressource — vide de ses fonctions. Le test disait donc « aucun script en erreur »
  pendant que la suite perdait **quinze vérifications en silence**, les appels tombant sur
  des fonctions inexistantes, sans qu'aucune assertion n'échoue. `can_instantiate()` tranche.
  Vérifié en cassant un script exprès.

  ⚠ **Et on ne relit pas hors cache** : `CACHE_MODE_IGNORE` sur un script en cours d'usage
  fait planter le moteur, pile de C++ à l'appui.

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
  évite de refaire le même dessin autant de fois qu'il y a de jumelles. Le noyau désigne
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

- **Performances : trois pièges, tous mesurés.** Sur le guide minimal, 1148 cases sont
  peignables (744 surfaces, 404 robes).
  - *La grille des faux pixels* était tracée en entier : à 256 px par tuile, seize mille
    traits dont la quasi-totalité hors cadre. Elle est désormais **découpée au cadre**.
  - *Les textures* remontaient au GPU à chaque pixel posé — un quart de mégaoctet par pixel
    à 256. Elles ne remontent plus qu'**une fois par image**, les cases touchées étant
    marquées sales.
  - *Les compteurs* relisaient tout le relief à chaque coup de crayon : **5,05 ms par
    image**, un tiers du budget. La carte case → index et les rôles de robe sont calculés
    **une fois au chargement**, et les tris ont quitté le chemin chaud : **0,54 ms** dans
    le pire cas, celui où toutes les cases sont peintes.

  Mémoire, si l'on peint **toutes** les cases (jamais nécessaire : 59 tuiles suffisent) :
  0,8 Mo à 16 px, 12,7 Mo à 64, **202 Mo à 256** — et le double en comptant le GPU. Coût
  d'un pixel une fois la tuile créée : 1,1 µs à 64 px, 1,9 µs à 256. La première pose dans
  une tuile neuve coûte 112 µs à 256 px, le temps d'allouer son image : une fois par tuile,
  pas par pixel.

- **ABSOLUPAINT : LE PLUGIN MOTEUR, ET LA SEULE FACON HONNETE DE PORTER LA REGLE DEUX FOIS.**
  Le logiciel fabrique un tileset ; le plugin le pose dans un jeu. Il part chez l'acheteur,
  dans **son** projet, ou `res://core/` n'existe pas : il emporte donc **sa propre copie**
  de la regle de pose. Ce n'est pas un choix, c'est la contrainte.

  ⚠ **LA QUESTION N'EST DONC PAS « COMMENT EVITER LA COPIE » MAIS « COMMENT PROUVER QUE LES
  DEUX DISENT LA MEME CHOSE ».** Deux lecteurs qui se fient a leur memoire finissent
  toujours par diverger — c'est exactement pour ca que le manifeste est devenu un contrat.
  La reponse est un **controle croise** : sur les 4096 reliefs binaires 3x4 **exhaustivement**,
  sur les guides livres et la planche de preuve, et sur 400 reliefs 9x9 a quatre etages
  tires au sort a chaque execution, **chaque case** doit recevoir du plugin exactement ce que
  le noyau lui donne — meme index de surface, meme croisement, meme role de robe. Une seule
  case qui divergerait fait echouer la suite (regle 4).

  ⚠ **ON COMPARE DANS LES DEUX SENS.** Un plugin qui ne poserait rien du tout passerait un
  test qui se contente de verifier que ce qu'il pose est juste.

  ⚠ **ET LA BATTUE AU HASARD NE SUFFIT PAS : elle rencontrait 35 des 36 roles.** Les plus
  rares demandent un **contrefort**, c'est-a-dire une forme voulue, pas un accident. Ce sont
  donc les **guides livres** qui font de cette battue une vraie battue — le hasard seul
  prouvait moins qu'il n'en avait l'air.

- **LE MONDE DU PLUGIN N'EST PAS BORNE, ET C'EST UNE SIMPLIFICATION, PAS UNE EXTENSION.** Le
  logiciel travaille sur un guide rectangulaire, ou une robe peut « tomber hors de la
  grille » ; un monde de jeu n'a pas de bord. Le relief y est donc un `Dictionary`
  case -> etage, l'absence valant la plaine. Consequence gratuite : le cas « robe hors
  grille » n'existe pas cote moteur, il n'y a rien a signaler.

- **⚠ ET ABSOLUPAINT NE POSE PAS DE SOL.** La plaine n'est pas une tuile du tileset, et le
  modele ne distingue pas encore « case a l'etage 0 » de « case hors du monde » — il n'y a
  pas de gouffre. Le plugin ne peut donc pas savoir **ou le sol s'arrete**, et en inventer la
  frontiere serait decider a la place de l'acheteur (regle 3). Le sol reste a sa charge, sur
  sa propre couche, tant que le modele n'a pas de marqueur de vide distinct de la plaine.
  C'est la premiere question a trancher pour la suite.

- **Le plugin REFUSE plutot que de deviner, et il refuse trois choses** (regle 5) : un
  fichier qui ne s'annonce pas comme un manifeste ; une version plus recente que celle qu'il
  sait lire ; et surtout des **constantes de falaise** qui ne sont pas les siennes. Un
  tileset dont l'etage descend de quatre cases, pose par un moteur qui en compte trois,
  donnerait un monde faux **sans une seule erreur** — c'est le pire des defauts, celui qui
  ne se signale pas.

- **La famille a cheval decale la COUCHE d'une demi-case, jamais la tuile.** Une tuile duale
  est posee sur le **croisement** de quatre cases ; le croisement (i, j) est leur coin commun,
  donc la tuile qui s'y centre commence une demi-case au nord-ouest. Le decalage vaut pour la
  couche entiere — un `TileMapLayer` ne sait pas decaler une case a la fois, et il n'a pas a
  le savoir.

- **LE BOUTON « INSTALLER LE PLUGIN GODOT » EST POUR L'ACHETEUR, PAS POUR NOUS.** Il ferme le
  seul geste manuel qui restait entre « j'ai peint mon tileset » et « je pose mon monde » :
  trouver le dossier `addons/` d'un projet et n'y rien oublier. Il vit dans une section
  **« Moteur »** de la barre de droite, parce que ce n'est ni du travail en cours ni un
  reglage de vue : c'est la sortie vers le jeu.

  ⚠ **IL REFUSE UN DOSSIER SANS `project.godot`.** Ecrire six fichiers dans les documents de
  quelqu'un sans que rien ne les lise jamais serait pire qu'un refus : **ca ressemblerait a
  une reussite.**

  ⚠ **ET IL NE TOUCHE PAS AU `project.godot` DE L'ACHETEUR.** Cocher l'extension a sa place
  demanderait de le reecrire ; un fichier de projet reecrit par un tiers perd ses
  commentaires, et peut perdre bien pire. On copie, et on dit la seule chose qui reste a
  faire. **Une phrase a lire vaut mieux qu'un fichier abime.**

  ⚠ **ON COPIE EN OCTETS, PAS EN TEXTE.** Un `.gd` relu comme texte puis reecrit changerait
  ses fins de ligne selon la plateforme : le plugin doit arriver identique a celui qu'on
  vient de tester. C'est asserte, fichier par fichier.

  ⚠ **LA LISTE DES FICHIERS DU PLUGIN EST UNE DONNEE, DONC UN ENDROIT OU MENTIR.** Lister le
  dossier a l'execution marcherait en developpement et se casserait dans un binaire exporte,
  ou `res://` n'est plus un dossier mais une archive. La liste est donc ecrite — et **la
  suite la compare au dossier reel**, sans quoi un fichier ajoute au plugin et oublie dans la
  liste ne partirait jamais, et le plugin arriverait casse en silence.

  ⚠ **A VERIFIER AVANT DE VENDRE** : que le preset d'export du logiciel embarque bien
  `addons/absolupaint/**` — les `.gd` en clair (pas en jetons binaires) et les fichiers non
  ressources (`.cfg`, `.md`) via le filtre d'inclusion. Aucun test ne peut le prouver depuis
  l'interieur du projet.

- **⚠ `user://` SURVIT D'UNE EXECUTION A L'AUTRE, et un test qui ecrit doit d'abord faire le
  vide.** Le test d'installation verifiait « la premiere fois, il ne remplace rien » : il
  passait au vert le jour de son ecriture et rougissait le lendemain, le faux projet etant
  toujours la. Ecrit, mais pas encore appris ailleurs dans la suite.

- **LES CHUTES PROFONDES SONT MAINTENANT EPROUVEES, ET ELLES NE L'ETAIENT PAS.** La question
  venait de l'usage : *« ca ne me derange pas qu'une falaise soit un multiple de 3, si on
  peut faire n'importe quelle valeur dedans »*. C'est vrai — **3 a 27 cases**, un multiple
  de 3 par etage jusqu'a `MAX_LEVEL`, avec **les memes 36 tuiles** — mais rien ne le
  verifiait : les reliefs tires au sort plafonnent a quatre etages, donc a des chutes de
  neuf, et le guide `minimal` monte a trois. **Les longueurs 12 a 27 n'etaient eprouvees
  nulle part.** Elles passaient, par chance.

  C'est la promesse meme des **deux rangees de corps** : `1 + (step - 2) modulo body_rows`
  fait tourner le corps sur lui-meme, ce qui permet une hauteur quelconque avec une feuille
  **finie**. Si l'assertion tombe un jour, c'est que la feuille a cesse d'etre suffisante.

  ⚠ **DEUX REGIMES, ET IL FAUT LES DIRE ENSEMBLE. Atterrir est quantifie par trois ;
  descendre ne l'est pas.** Une robe **ecretee** — qui bute contre un morceau de son propre
  etage — fait n'importe quelle longueur, et **ne pose pas son pied**. Les deux sont
  assertes.

  ⚠ **ET LE TEST AVAIT TORT AVANT LE CODE.** J'assertais « aucune tuile de pied » sur le
  relief entier d'un cas ecrete ; or le **second** bloc y lance sa propre robe, qui elle
  atterrit normalement. Le test accusait la regle d'un defaut qu'elle n'a pas. On regarde
  desormais les cases de CETTE robe-la. Meme lecon que le bug de `row_for` : **un test faux
  coute plus cher qu'un test absent, il envoie corriger ce qui va bien.**

- **LES DEUX DERNIERS TROUS DE `_test_seams` SONT BOUCHES.** La suite verifiait surface
  contre surface, et robe contre robe. Il manquait deux jonctions, trouvees en relisant le
  test plutot qu'en regardant l'ecran.

  **1. La bande de flanc ne bouge plus quand le pan change dans une colonne.**
  `_check_wall_seams` compare bien deux rangees qui se suivent — mais toujours **a pan
  constant**. Or l'etat d'un flanc **change en descendant** : le voisin est en retrait sur
  trois rangees, puis sa robe s'arrete et le flanc passe de `devant` a `vide`. Les deux
  tracent une bande **au meme bord** ; si elles n'ont pas la meme geometrie, la marque saute
  lateralement **en plein milieu de la falaise**. Ce defaut a deja eu lieu — 0,10 de tuile
  pour le lisere, 0,055 pour l'arete, « elle pulsait ». La correction fut une largeur unique ;
  c'etait une **convention du rendu**, c'est desormais une **assertion**.

  ⚠ **ON COMPARE LA GEOMETRIE, PAS LES PIXELS.** Le vide est doux et l'arete est franche :
  leurs couleurs **doivent** differer, c'est ce qui dit lequel des deux blocs est devant. Ce
  qui ne doit pas differer, c'est **ou** la bande se trouve. Mesure : colonnes `[0,1,2]`,
  identiques pour les deux etats sur les quatre rangees.

  **2. La levre : le bord sud d'un plateau contre le haut de sa propre falaise.** C'est la
  couture **la plus visible du tileset** — l'endroit ou le plateau bascule dans le vide — et
  elle n'avait aucun garde-fou. Les 13 surfaces sans voisin sud et les 9 chapiteaux sont
  desormais verifies pleins a leur bord commun : c'est exactement ce que **l'epaule** existe
  pour garantir.

  ⚠ **ET LA MESURE DOIT AVOIR VU QUELQUE CHOSE.** Deux bandes vides sont trivialement egales :
  sans controle de non-vacuite, un rendu qui cesserait de tracer la bande passerait au vert.

- **L'EPAULE SE FERME DANS LES DEUX STYLES, CHACUN DANS SA PALETTE.** Elle ne l'etait qu'en
  peint : le fil de fer laissait voir le fond sous **8 des 13 levres**, jusqu'a la moitie du
  bord pour l'index 0 dont les deux coins bas sont decoupes. Trouve en ecrivant l'assertion
  de levre, pas en regardant l'ecran.

  ⚠ **C'ETAIT UN VRAI MENSONGE, PAS UNE COQUETTERIE DE STYLE.** Les deux styles decrivent
  **la meme geometrie** — « sous un bord sud il y a toujours une falaise ». Si l'un montre de
  la roche et l'autre un trou au meme endroit, l'un des deux se trompe, et le guide perd le
  droit de dire qu'il ne peut pas mentir sur ce qu'il contient.

  Le choix de la couleur suit le style plutot que de le contredire : en peint, l'epaule est
  le **chanfrein du rocher**, volontairement distinct du corps. En fil de fer, c'est
  `WIRE_WALL` — **la roche du trait, exactement celle des tuiles de robe** — donc l'epaule y
  est *continue* avec la face juste en dessous. Un aplat de pierre aurait contredit un style
  fait de traits ; le noir de la roche y est deja le vocabulaire.

  Asserte desormais dans les **trois** styles.

- **LE CONTRAT DECRIT LA FAMILLE QU'IL EXPORTE, ET LE VIDE QU'IL SUPPOSE.** Deux trous dans
  `_spec()`, tous deux de la meme espece : une regle que le plugin applique **de memoire**,
  parce que c'est nous qui l'avons ecrit — c'est-a-dire exactement la dependance que le
  contrat existe pour supprimer.

  **1. La famille a cheval n'avait pas de regle de pose.** Un export `corner` annoncait bien
  `famille corner` et ses quinze index, au-dessus d'une section qui ne decrivait que le blob.
  La section de surface se choisit desormais avec la famille — `corner_bits`, `corner_cells`,
  `corner_visible`, `corner_empty`, `surface_offset`, `walls_offset`.

  ⚠ **ET C'EST L'UNE OU L'AUTRE, JAMAIS LES DEUX.** Un manifeste a cheval qui porterait
  `canonicalise corner_needs_both_cardinals` serait faux deux fois : il enonce une regle que
  ses tuiles n'emploient pas, et un croisement **ne se canonicalise pas** — ses quatre bits
  sont tous significatifs, et le contact diagonal, que le blob *jette*, est precisement l'une
  de ses quinze tuiles. Une regle fausse ecrite noir sur blanc coute plus cher qu'un oubli.
  L'absence est assertee dans les deux sens.

  **2. Le vide n'etait ecrit nulle part.** La 4.0.0 a donne trois etats au modele ; le
  contrat en decrivait toujours deux — « 0 la plaine, 1..9 les plateaux ». Trois clauses
  ajoutees : `void -1 out_of_map_is_void`, `plain level_like_any_other`, et
  `fall_into_void one_storey_more no_foot`.

  ⚠ **C'EST LA CLAUSE QUI PORTE LE PLUS DE TOUT LE FICHIER.** Un second moteur qui lirait
  l'absence comme de la plaine — l'ancien modele — etendrait le sol a l'infini, ne poserait
  **aucune falaise de bord du monde**, et poserait des pieds au fond du gouffre. Le tout sans
  une seule erreur : le pire des defauts, celui qui ne se signale pas.

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

- **Un mode d'emploi plein ecran**, ouvert en cliquant le bandeau haut-droit, qui ferait
  aussi defiler des conseils au lieu des seules phrases de la charte. ⚠ **Rien n'en est
  specifie** : ni contenu, ni decoupage, ni maquette. Ces deux lignes sont tout ce qui
  existe.
- **LES MATIERES BORDEES : eau, sable, ce qui se pose DANS un plateau plat.** Une matiere
  est un **masque binaire**, donc une couche posee comme un etage, mais **sans falaise** :
  le blob 47 s'y applique sans une ligne de code de plus, et les coins arrondis laissent
  voir ce qui est dessous par le mecanisme qui existe deja. Coût : **+47 tuiles par matiere
  par case, +15 a cheval**, et rien d'autre — a deux conditions qui sont des decisions :
  les matieres sont **ordonnees** (sable sur herbe, eau sur sable) sinon il faut un jeu par
  *paire* ; et une matiere **ne touche ni la levre ni le bord de son etage**, sinon c'est
  une cascade (+36) et on ne sait plus ce qu'il y a dessous. Voir la fiche detaillee en fin
  de section.
- **Les escaliers et les pentes douces : un TROISIEME vocabulaire, pas une matiere.** Une
  rampe casse deux regles d'un coup — « un plateau n'a de face qu'au sud » (on marche sur
  celle-la) et « on ne voit que le sommet » (elle occupe des cases a des hauteurs qui ne
  sont l'etage de personne). ⚠ Et surtout **elle ne se deduit pas** : deux etages adjacents
  sont une falaise par definition, rien dans une carte de hauteurs ne l'en distingue. Il
  faut donc un **marqueur declare**, exactement comme `~` l'a ete pour le vide en 4.0.0.
  Coût : un troisieme `walls.gd`, sa regle au contrat, sa copie dans `rules.gd`, son
  controle croise, et 12 a 36 tuiles selon que la question « qui est devant » revienne sur
  ses flancs. Chantier du calibre de la 4.0.0.
- **LA SIGNATURE DU MANIFESTE : que l'addon ne pose que ce que le logiciel a produit.**
  Décidé : l'essai **n'exporte pas**, un **tileset de démo** part dans l'addon pour qu'on
  puisse l'éprouver sans acheter, et **rien ne fonctionne sans manifeste** — ce dernier point
  étant déjà vrai dans le code. Reste à écrire la signature et les deux refus qui vont avec.
  Voir la fiche détaillée en fin de fichier.
- **Le plugin Unity.** Rien de commence. Le controle croise du plugin Godot est le modele a
  reprendre : c'est lui qui empeche les deux lecteurs de diverger.

### Fiche : LES MATIÈRES BORDÉES

**Ce qu'une matière est, en une phrase : un étage sans falaise.**

Une région d'eau dans un plateau plat est un **masque binaire**, exactement comme la
silhouette d'un étage. `BlobIndex.canonicalize` s'y applique donc **sans une ligne de code
de plus** — le même argument, mot pour mot, que celui déjà écrit pour le relief. Et le
rendu sait déjà empiler : *« chaque couche recouvre la précédente, si bien que les coins
arrondis découpés laissent voir l'étage d'en dessous »*. Le coin arrondi d'une tuile d'eau
laissera voir l'herbe par ce mécanisme-là, pas par un nouveau.

⚠ **Ce qui distingue une matière d'un étage, et qui décide de tout : les étages
s'EMPILENT, les matières sont CÔTE À CÔTE.** Un étage cache celui d'en dessous et la
transition sort du plan — c'est une falaise, d'où `walls.gd`. Une matière reste dans le
plan, et sa transition est son propre bord. **Donc aucune tuile de robe supplémentaire.**

**Le coût, chiffré :** +47 tuiles par matière par case, +15 à cheval. Rien d'autre — **à
deux conditions, qui sont des décisions à prendre, pas des détails.**

⚠ **1. LES MATIÈRES SONT ORDONNÉES.** Sable sur herbe, eau sur sable ; chaque matière ne
borde que ce qui est dessous. Sinon il faut un jeu de transition par **paire** : trois
matières qui se touchent librement, ce sont six jeux, pas trois. L'ordre est une propriété
du mode, décidée avec lui.

⚠ **2. UNE MATIÈRE NE TOUCHE NI LA LÈVRE NI LE BORD DE SON ÉTAGE.** Une nappe qui atteint
le bord sud d'un plateau est une **cascade** — une face hors du plan, donc un vocabulaire
entier de robes, +36 tuiles. Et une matière qui touche le bord rend indécidable *ce qu'il
y a dessous* au coin découpé. Avec la restriction, la réponse est toujours la même : la
tuile pleine de l'hôte, l'index 255. Le guide l'interdit, le pinceau le refuse (règle 5).

⚠ **UNE CASE PORTE TOUJOURS UNE SEULE TUILE, ET LE CARNET NE BOUGE PAS.** C'est le point
qui rend le chantier petit. Une case d'eau se peint en eau ; l'herbe dessous est l'index
255, qui se peint dans mille autres cases. Donc **aucune nouvelle dimension au carnet** :
c'est le *nom* de la tuile qui gagne sa matière, pas la clé de rangement. Et comme
`work_io` range l'art **par tuile**, un travail de base se recharge tel quel dans un mode
à matières — exactement comme `minimal` se recharge en `ample`.

**Ce que ça coûte en GUIDE**, mesuré sur les emprises réelles de `tools/accidents.py` — et
seuls les accidents de *surface* comptent, l'escarpement porte les robes et une matière
n'en a pas :

```
district lacustre (11x11)     121 cases      les 16 index « tous cardinaux »
crete dressee (5x10)           50 cases  \   les 16 « trois cardinaux »,
crete couchee (9x7)            63 cases  /   pointes et cretes etroites
chaos rocheux (12x9)          108 cases      les 4 coudes et les 4 fourches
ecueil + contact diagonal      20 cases      l index 0 et les deux diagonales
                              ---------
                              362 cases d accidents, ~524 avec marges et bordure d hote
```

⚠ **ET C'EST POUR ÇA QU'UN GUIDE GÉANT GRISÉ EST UN MAUVAIS ÉCHANGE.** Le dépôt porte déjà
la mesure qui tranche : *« ce qui compte n'est pas le nombre de cases, c'est la taille de
la case à l'écran »*. Sur le guide livré (52x33) et un cadre de travail ordinaire :

```
base seule         guide 52x33  ->  case a l ecran 23,0 px
base + 1 matiere   guide 74x33  ->  18,9 px   (-18 %)
base + 2 matieres  guide 96x33  ->  14,6 px   (-37 %)
```

À 14,6 pixels d'écran on ne distingue plus un dessin de 16 faux pixels : le guide cesse de
montrer ce qu'il existe pour montrer. On avait gagné +30 % en **couchant** le guide ; on
les reperdrait, et davantage. Et un paysage dont les trois quarts refusent le crayon ment
sur ce qu'il est.

**Donc : un guide ENGENDRÉ PAR COMBINAISON, pas un guide unique grisé.** `tools/` compose
déjà les guides à partir d'accidents ; un mode « base + eau » compose les siens. On ne paie
que les matières qu'on fabrique, et rien dans le cadre ne refuse le crayon sans raison. La
peur derrière « tout dans le guide » — perdre le travail en changeant — est déjà réglée
par le carnet rangé par tuile.

⚠ **Piste mesurée, à vérifier en engendrant vraiment un guide** : `minimal` porte **498
cases de plaine**, pour ~524 nécessaires à une matière. La première matière pourrait donc
être presque gratuite en surface de guide **si la plaine était disposée en étendue
utilisable au lieu d'un liseré de bord du monde**. À prouver, pas à promettre.

**Où ça touche, fichier par fichier** — et la liste est courte, c'est l'argument :

- `core/height_mask.gd` — **inchangé**. La matière est une seconde carte, pas un alphabet
  surchargé : le parseur est strict et `#` est déjà pris.
- le format de guide — un **second bloc** dans le même fichier, mêmes dimensions.
- `core/families.gd` — la matière entre dans le nom de la tuile ; une lettre de clé de plus.
- `core/modes.gd` — le mode déclare sa liste ordonnée de matières ; `surface_tiles` devient
  47 × (1 + matières).
- `exporters/tileset_png.gd` — **une planche de surface par matière**, nommée au manifeste.
  La clause `sheet fixed_size` reste vraie, c'est ce qui compte.
- `render/guide_image.gd`, `render/assembly.gd` — une couche de plus à empiler, dans
  l'ordre des matières.
- `core/proof_scene.gd` — une planche de preuve par matière.
- `addons/absolupaint/` — un `TileMapLayer` par matière, et le contrôle croisé étendu.

⚠ **ET LES DEUX RESTRICTIONS S'ASSERTENT, ELLES NE SE DOCUMENTENT PAS** (règles 4 et 5).
Une matière qui touche une lèvre, ou deux matières non ordonnées qui se rencontrent, doivent
faire **échouer la suite** sur les guides livrés. Sans quoi ce sont deux promesses, et le
projet n'en fait pas.

### Fiche : LA SIGNATURE DU MANIFESTE

**À dire avant tout le reste : un verrou dans l'addon ne protège de rien.**
`addons/absolupaint/` part en GDScript **en clair** dans le projet de l'acheteur. Toute
vérification qu'on y met s'efface en supprimant une ligne. Dans cette forme le problème
**est insoluble**, et la charte interdit de le maquiller : un contrôle qui saute en trente
secondes n'est pas une protection, c'est un décor qui *donne l'air* d'un contrôle — la même
faute que la version du manifeste figée à 3.

Ce qui suit ne prétend donc pas arrêter un logiciel craqué. Il sépare **« il faut lire un
fichier texte »** de **« il faut craquer un binaire »**, ce qui est une vraie marche.

**1. « Rien ne fonctionne sans manifeste » est DÉJÀ vrai.** `world.gd` sort à chaque étape
sans manifeste valide et complet : pas de `tile_set`, pas de source d'atlas, `rebuild()`
retourne immédiatement. Rien à construire.

**2. Ce qui manque : le manifeste doit LIER ses planches.** Aujourd'hui il les *nomme* — donc
on peut garder un manifeste légitime et mettre ses propres images à la place. Il porte donc
l'**empreinte SHA-256 de chacune**. Dès lors il ne décrit plus « un tileset », il décrit
**ces deux images-là**.

**3. La signature.** `Crypto` / `CryptoKey` sont dans Godot, en GDScript : **aucune
dépendance, la convention « GDScript uniquement » tient.** Le logiciel signe à l'export, clé
privée embarquée ; l'addon vérifie, clé publique embarquée.

⚠ **On signe un CONDENSÉ CANONIQUE, jamais les octets du fichier** : version, mode,
`tile_size`, famille, les deux noms de planche, les deux empreintes, et la table des cases
triée. Commentaires, lignes vides et fins de ligne exclus — sinon la signature saute au
premier outil qui normalise une fin de ligne.

⚠ **ET ÇA N'ENTAME PAS LA CLAUSE « NÉCESSAIRE ET SUFFISANT ».** La règle de pose reste en
clair, lisible, réimplémentable — c'est ce qui permettra d'écrire le lecteur Unity. La
signature ne contrôle pas le **savoir**, elle contrôle la **provenance acceptée par notre
moteur**. Deux choses différentes, et `_spec()` doit le dire pour que ce ne soit pas une
surprise.

⚠ **LA PIÈCE LA PLUS FORTE : LE BUILD D'ESSAI N'A PAS DE CLÉ PRIVÉE DU TOUT.** Pas un
drapeau `is_trial`, pas de branche à retourner — la clé n'est **pas dans le binaire**. Même
quelqu'un qui force le bouton d'export obtient des planches non signées, que l'addon refuse.
Deux verrous indépendants, **dans deux binaires différents** : forcer le premier ne donne
rien sans le second.

**4. Le tileset de démo** part signé, empreintes comprises : on ne peut pas garder son
manifeste et y glisser son propre art. Sa seule limite doit être **son contenu** — assez
pour éprouver la pose, pas assez pour livrer un jeu. Une limite dans l'art se contourne en
repeignant, c'est-à-dire en achetant le logiciel.

**Ce que ça arrête, et ce que ça n'arrête pas :**

```
recuperer l addon et ecrire son manifeste a la main   REFUSE  (pas de signature)
garder un manifeste signe, changer les PNG            REFUSE  (empreintes)
forcer l export de la version d essai                 REFUSE  (rien a signer avec)
se servir du tileset de demo                          ACCEPTE (c est voulu)
remplacer la cle publique dans manifest.gd            PASSE   (une ligne)
craquer le logiciel complet                           PASSE   (concede d avance)
```

⚠ **L'avant-dernière ligne est la seule qui reste ouverte côté addon**, et c'est
exactement — et uniquement — là qu'une **GDExtension compilée** aurait un sens : déplacer la
vérification hors du texte éditable. Le prix n'est pas mince : **l'export HTML5 meurt**
(GDExtension n'existe pas en web), un binaire par plateforme et par architecture, l'ABI qui
suit les versions de Godot, et le contrôle croisé à faire tourner contre un binaire. Question
étroite, donc tranchable : *accepte-t-on que l'acheteur ne puisse plus livrer en navigateur ?*

**Ce qu'il y a à écrire :**

- `exporters/tileset_png.gd` — les deux empreintes, le condensé canonique, la ligne
  `signature`, et la clause correspondante dans `_spec()` ;
- `addons/absolupaint/manifest.gd` — **un quatrième et un cinquième refus** : signature
  absente ou invalide, planches qui ne sont pas celles que le manifeste signe. Ils rejoignent
  les trois qui existent ;
- le tileset de démo dans l'addon, signé ;
- la suite vérifie les deux refus **et** qu'un export frais se relit — sinon on découvre à la
  vente que la signature ne passe pas.
