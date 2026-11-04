extends "res://ui/manual.gd"

## LE MODE D'EMPLOI DU MODÈLE PAR LES COINS — la même fenêtre que l'ancien (`ui/manual.gd`), ses pages réécrites : ce
## qui y était dit des massifs n'est plus vrai. Textes à l'écran : anglais.


func _hands_on() -> String:
	return _titre("Draw") + """
The centre shows the [b]guide[/b]: one landscape that holds every tile of the set ([b]35[/b]) and every way two tiles
can meet ([b]261[/b] junctions). Paint on it. The pencil only reaches the tile you see under it, and only inside its
shape: the hatched part of the tile panel is not yours to paint.
Every pixel you place shows at once wherever that tile appears. All the seams are in front of you while you paint.

[b]Outside a tile's shape, leave it to the others.[/b] A tile is transparent beyond its shape: there, the drawing
order shows what lies behind it (a lower plateau, a cliff, the plain). If you go on painting past the edge, you are
painting ANOTHER tile, the one you see there, and it is shared elsewhere: your colour would show up in places where it
does not belong. So a stroke stays in the tile where it started ([i]Keep inside the tile[/i], ticked by default); the
hovered tile shows its shape, the rest is darkened. Draw the plateau's rim inside the top, the overhang in the cliff's
lip, the rubble in the cliff's foot.
[b]Left click[/b] paints, [b]right click[/b] erases. [b]Ctrl+Z[/b] undoes a whole stroke.
Tools: [b]P[/b] pencil, [b]B[/b] brush, [b]A[/b] airbrush, [b]G[/b] fill (it stays inside the shape), [b]L[/b] line,
[b]R[/b] rectangle, [b]I[/b] picker, [b]E[/b] eraser. [b][[/b] and [b]][/b] change the size.
""" + _titre("Junctions") + """
The pink points mark where a band (top, lip, cliff body, foot) reaches the edge of its tile: the drawing must carry on
in the neighbour at that very place. [i]View > Hide the grid[/i] hides them.
""" + _titre("Variants") + """
Hover a tile in the guide and press [b]V[/b]: a variant is made from it, and that spot shows it, among its real
neighbours. [b]C[/b] switches which variant this spot shows, [b]X[/b] removes it, [b]+[/b] / [b]-[/b] set its weight.
In the game, variants are drawn by a fixed hash of the position: the same world looks the same every time.
""" + _titre("Materials") + """
Choose [i]Paint: Material 1[/i] (up to 3): the guide carries that material's field, and you paint its 13 top shapes
where they live. A material is a floor without cliffs: sand on grass, snow on sand. Paint its edge as a soft
transition: the shapes are rounded and meet in the middle of each tile edge, never in steps.
""" + _titre("Test") + """
The [b]Test[/b] room shows a world of your own, drawn with your tiles. [b]Sculpt plateaus[/b] ([b]S[/b]): click raises
the corner you see, right click lowers it, [b]Shift[/b] + click paints the brush material, Shift + right click removes
it. With any painting tool, you paint the tile you see, and the change is everywhere. Your world does not hold every
junction: go back to Draw to check them.
"""


func _how_it_works() -> String:
	return _titre("Heights on corners") + """
The relief is one height per [b]corner[/b] of the grid. Each height unit is a layer, drawn one tile higher; a cliff unit
spans two tiles (its top under the plateau's edge, its bottom in the tile below). A tile only depends on its four
corners, and on the layer above or below for its lip and its foot.

The tiles are placed layer by layer, row by row, from the back to the front. [b]The drawing order is the whole
occlusion[/b]: nothing is cut, nothing is composed.
""" + _titre("Proven, not hoped") + """
Every tile placement was compared, pixel by pixel, with an exact ray cast of the true relief: 200 random worlds,
6,523,200 pixels, [b]no difference[/b]. The set is closed: 57 placements, 33 different tiles; two plateaus never meet by a single corner. The guide is generated
and refuses to be written if it misses a single tile or junction.
"""


func _the_contract() -> String:
	return _titre("What you deliver") + """
[b]Export tileset[/b] writes one sheet (PNG) and its manifest (JSON): the tile size, the table from each placement to
its tile, and every image (tile, material, variant, weight, place on the sheet). It is refused while a base tile is
left unpainted: a sheet with holes would show them in the game.
""" + _titre("The Godot plugin") + """
[b]Install the plugin[/b] copies [code]addons/marching_squares/[/code] into a Godot project, with your tileset if it is
complete, or the trial otherwise. Add a [b]MarchingSquaresWorld[/b] node, give it the manifest, and paint the relief
in the 2D view: click raises a corner, right click lowers it, Shift paints a material. What you saw in Test is what the
game draws.
"""
