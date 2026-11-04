# MarchingSquares — Godot plugin

Lay a 2D world of plateaus and cliffs, of any height, with the tileset you painted in **MarchingSquares**.

## Install

Copy `addons/marching_squares/` into your project, then **Project → Project Settings → Plugins** and enable
*MarchingSquares*.

## Use

1. In MarchingSquares, paint your tiles, then **Export tileset**: you get `marching_squares_planche.png` and
   `marching_squares_planche.json`. Put both in your project, side by side.
2. Add a **MarchingSquaresWorld** node, set its **Tileset** to the `.json`, and its **Columns** / **Rows**.
3. In the 2D view, with the node selected:
   - click: raise the corner you see; right click: lower it;
   - Shift + click: paint the brush material on that corner; Shift + right click: remove it.
   Every click can be undone.

Heights and materials live on the **corners** of the grid. Each height unit is one tile of cliff, drawn one row higher.
Materials (sand on grass, snow on sand…) are ranked: a higher one is drawn over a lower one, with the rounded transitions
you painted. Variants are drawn by a fixed hash of each tile's position, weighted as you set them: the same world looks
the same every time.

`composer()` returns the whole world as an `Image`.

## License

CC0 1.0 (public domain), like the MarchingSquares repository — see its LICENSE.
