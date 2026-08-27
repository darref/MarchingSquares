"""REGARDER UNE IMAGE DANS LE TERMINAL.

    python3 tools/show.py image.png [colonnes] [ascii]

⚠ ET ON N'EMET UNE COULEUR QUE QUAND ELLE CHANGE. La premiere version posait deux
echappements par pixel : 68 Ko pour une vignette de 60 colonnes, que le terminal tronquait
avant de l'afficher. Ces images sont des APLATS -- quelques teintes, de longues plages --
donc la couleur par plage les ramene a quelques kilo-octets.

Une cellule vaut DEUX pixels, empiles par un demi-bloc : le rapport de forme est garde.
"""
import sys
from PIL import Image

PALETTE = {
	(35, 38, 43): (".", 235),      # le fond hors monde
	(63, 74, 56): (":", 22),       # le decor de contexte, en sourdine
	(195, 217, 143): ("#", 150),   # l herbe
	(214, 186, 154): ("o", 180),   # la roche
	(13, 15, 18): ("@", 232),      # le trait
}


def _near(rgb):
	best = None
	far = None
	for key in PALETTE:
		d = sum((a - b) ** 2 for a, b in zip(key, rgb))
		if far is None or d < far:
			far = d
			best = key
	return PALETTE[best]


def main():
	path = sys.argv[1]
	cols = int(sys.argv[2]) if len(sys.argv) > 2 else 60
	plain = len(sys.argv) > 3 and sys.argv[3] == "ascii"
	im = Image.open(path).convert("RGB")
	rows = max(2, int(im.size[1] * (cols / im.size[0]) * 0.5) * 2)
	im = im.resize((cols, rows), Image.NEAREST)
	px = im.load()
	if plain:
		# UNE LETTRE PAR PIXEL, aucun echappement : ce qui passe partout.
		for y in range(rows):
			print("".join(_near(px[x, y])[0] for x in range(cols)))
		print("  . fond   : contexte   # herbe   o roche   @ trait")
		return
	out = []
	for y in range(0, rows - 1, 2):
		line = []
		last = None
		for x in range(cols):
			top = _near(px[x, y])[1]
			low = _near(px[x, y + 1])[1]
			glyph = " " if top == low else "▀"
			state = (low, top) if top != low else (low, low)
			if state != last:
				line.append("\x1b[48;5;%dm" % low)
				if top != low:
					line.append("\x1b[38;5;%dm" % top)
				last = state
			line.append(glyph)
		out.append("".join(line) + "\x1b[0m")
	print("\n".join(out))


main()
