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
  painting.gd     les faux pixels posés dans chaque tuile
  mask_io.gd      lecture / écriture / accès d'un masque de guide (texte)
  coverage.gd     rapport de couverture d'un masque
  height_mask.gd  guide en relief : une hauteur par case, silhouette par étage
  walls.gd        le second vocabulaire : les robes de falaise (3 pans × 4 rangées)
  variants.gd     quelles cases peintes deviennent des tuiles
  modes.gd        catalogue des modes (guide + règles d'exportation)
render/       illustration du guide -- présentation, pas logique
  guide_image.gd  dessine le relief en Image (headless, sans nœud)
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

Écrit `guides/minimal_preview.png`. Accepte deux arguments après `--` : le guide à rendre,
et le fichier de sortie.

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

- **Liste déroulante « guide background style » : `representative` ou `usable`.**
  Le fond actuel est *representative* : il montre le paysage **tel qu'il sera une fois
  peint**, avec ses couleurs, ses falaises et ses ombres. C'est ce qu'il faut pour
  comprendre le guide d'un coup d'œil — mais c'est un mauvais support pour peindre dessus,
  et deux défauts déjà observés le disent :
  - ses teintes contaminent la lecture des siennes. On ne juge pas une couleur posée sur un
    aplat vert soutenu comme on la juge sur un fond neutre ;
  - un lac d'une case y rend comme une fosse de pierre — fidèle au modèle, mais ça ne dit
    pas ce qu'il y a à dessiner.

  *usable* reste **à dessiner**, et c'est un travail de conception, pas de rendu. Intention :
  montrer la **structure** plutôt que le résultat. Ce qu'il faut voir pendant qu'on peint,
  c'est où passent les bords de tuile, quel côté est la lèvre éclairée et quel côté est la
  face, et à quelle rangée de robe on se trouve (chapiteau, corps, pied). Donc : trait
  plutôt qu'aplat, teinte neutre et contraste bas pour que n'importe quelle couleur de
  crayon ressorte, et rien qui attire l'œil ailleurs que sur ce qu'on pose.

  ⚠ Les deux styles doivent sortir de **la même fonction et du même relief** — un paramètre
  de `guide_image.render()`, pas un second dessinateur. Sinon les deux fonds finiront par
  raconter deux guides différents, et c'est exactement ce que ce fichier existe pour
  empêcher.

  Le choix est une **aide à la vue, pas un réglage du produit** (rien de ce qui sort n'en
  dépend) : sa place est donc dans une section d'outils, à côté de « Recadrer le guide »,
  pas dans les boutons globaux.

- **Mode « peindre les rotations ».** Une seconde case à cocher : toutes les tuiles qu'on
  obtiendrait **en tournant** celle qu'on dessine se remplissent aussi, en temps réel.
  Techniquement c'est prêt à écrire : tourner un voisinage d'un quart de tour est une
  permutation de bits (N→E→S→W→N et NE→SE→SW→NW→NE), donc les 47 index se rangent en
  orbites calculables, exactement comme `cells_by_index()` range les jumelles. Deux
  remarques avant de s'y mettre :
  - ça ne concerne **que les surfaces**. Un plateau n'a de face qu'au sud : le vocabulaire
    de mur n'a pas de rotation.
  - ⚠ **c'est une entorse à la règle 3**, et une plus grande que les jumelles. Deux
    jumelles sont la *même* tuile : rien n'est transformé, on évite juste de refaire le
    même dessin. Une rotation, elle, **fabrique** une tuile dans une orientation que
    personne n'a dessinée — c'est le frère du miroir, que la charte interdit nommément, et
    « No pixel you didn't paint » demanderait alors une nuance. À assumer explicitement,
    pas à laisser passer.
- **Dessiner le guide du mode `ample`.** Le mode est décidé, nommé, et déjà au catalogue —
  mais fermé tant que `guides/ample.txt` n'existe pas.
- **Compacter le guide minimal** sans perdre la lisibilité : voir « la taille n'est pas
  prouvée minimale » ci-dessus.
- **Les variantes ne couvrent pas encore les murs.** `variants.resolve_relief()` traite la
  surface visible ; la même règle devra s'appliquer aux cases de robe, qui ont elles aussi
  des occurrences multiples.
- Règles d'exportation du mode minimal : format de sortie, ordre des tuiles, taille de
  tuile. Rien n'est décidé, `exporters/` est vide exprès.
- Les index à occurrence unique n'ont aucune variante : ce sont des cases obligatoires.
  Faut-il les signaler pendant le dessin (règle 6) ?
