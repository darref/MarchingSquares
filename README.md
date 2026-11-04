# MarchingSquares

> **Paint one guide. Every junction covered.**

MarchingSquares is a desktop tool for making 2D tilesets of **plateaus and cliffs of any height**, and a Godot plugin
that lays whole worlds with them. It is the 2D sibling of [MarchingBlocks](https://github.com/darref/MarchingBlocks).

## How it works

- **Heights live on the corners of the grid.** Each height unit is a layer drawn one tile higher; a cliff unit spans two
  tiles. Plateaus can be stacked to any height and hide one another: the drawing order *is* the occlusion.
- **A closed set of 35 tiles** (15 tops, 10 cliff tops, 10 cliff bottoms) covers all 79 ways a tile can be placed.
  Shapes are rounded; they always meet in the middle of a tile edge.
- **One guide** holds all 35 tiles and all 261 junctions. You paint on it: every pixel shows at once wherever that tile
  appears, so every seam is in front of you while you paint.
- **Proven, not promised**: the tile placement is compared, pixel by pixel, with an exact ray cast of the true relief —
  200 random worlds, 6,523,200 pixels, no difference.
- **Variants** (drawn by a fixed hash of the position, weighted) and **materials** (sand on grass, snow on sand: up to
  three, with rounded, soft transitions).

## The editor

- **Draw**: the guide. Pencil, brush, airbrush, fill, line, rectangle, picker, eraser; junction points; variants (V).
- **Test**: your own world, drawn with your tiles. *Sculpt plateaus* (S) raises and lowers corners; any painting tool
  paints the tile you see, and the change is everywhere.
- **Export tileset**: one sheet (PNG) and its manifest (JSON). **Install the Godot plugin** copies the plugin into a
  project, with your tileset (or a computed trial while yours is incomplete).

Run it: open the project in Godot 4.7 and press F5, or export the *Windows Desktop* preset.

## The Godot plugin

`addons/marching_squares/`: add a **MarchingSquaresWorld** node, point it at the manifest, and sculpt the relief in the
2D view (click raises a corner, right click lowers it, Shift paints a material). It draws exactly what the editor shows
in Test — measured pixel for pixel.

## Support

MarchingSquares is free and made by one developer. If it helps you build your worlds, a donation keeps it going:

- **Ko-fi** — https://ko-fi.com/darref
- **GitHub Sponsors** — https://github.com/sponsors/darref

## License

CC0 1.0 — public domain. See [LICENSE](LICENSE).

More from the studio: [spannergames.com](https://spannergames.com/games/marchingsquares/).
