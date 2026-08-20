# AbsoluTiles

> **Paint one landscape. Every edge case covered.**
> *No pixel you didn't paint.*

Outil desktop de génération de tilesets autotile, écrit en Godot 4 / GDScript.

L'utilisateur peint un paysage par-dessus un guide fixe affiché en transparence derrière
une grille. L'outil en extrait un tileset autotile complet (blob 47 tuiles) et l'exporte.
Aucun pixel n'est composité, miroité ou généré : tout ce qui sort a été peint à la main.
Le guide est un artefact conçu en amont, à la fois lisible comme un paysage et prouvé
mathématiquement complet.

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

## État

Noyau logique et tests uniquement. Aucune UI, aucune scène, aucun rendu.
Le noyau est utilisable en headless, sans dépendance à un nœud graphique.

## Tests

```
godot --headless --path . --script res://tests/run.gd
```

Code de sortie 0 si tout passe, 1 sinon. Voir `CLAUDE.md` pour le détail.
