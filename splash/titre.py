# Le splash de MarchingSquares : la plaque sans titre, et le nom en Archivo Black (OFL), herbe sur roche.
from PIL import Image, ImageDraw, ImageFont, ImageFilter
PLAQUE = r"D:\MarchingSquares\splash\MarchingSquares_SPLASH_nu.png"
OUT = r"D:\MarchingSquares\splash\MarchingSquares_SPLASH.png"
FONT = r"D:\SpannerGames\BIBLIOTHEQUE\polices\ArchivoBlack-Regular.ttf"
s = Image.open(PLAQUE).convert("RGBA")
W, H = s.size
texte = "MarchingSquares"
taille = 10
f = ImageFont.truetype(FONT, taille)
while f.getbbox(texte)[2] - f.getbbox(texte)[0] < W * 0.62:
    taille += 4
    f = ImageFont.truetype(FONT, taille)
x0, y0, x1, y1 = f.getbbox(texte)
tw, th = x1 - x0, y1 - y0
px, py = (W - tw) // 2 - x0, (H - th) // 2 - y0
# le cadre sombre arrondi, comme l'ancien
cadre = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(cadre)
m = int(th * 0.55)
d.rounded_rectangle([px + x0 - m, py + y0 - m, px + x1 + m, py + y1 + m], radius=int(th * 0.35), fill=(20, 22, 30, 175))
s = Image.alpha_composite(s, cadre)
# l'épaisseur (la falaise) : le mot répété vers le bas, en roche
ep = int(th * 0.16)
roche = Image.new("RGBA", (W, H), (0, 0, 0, 0))
dr = ImageDraw.Draw(roche)
for k in range(ep, 0, -1):
    t = k / ep
    c = (int(120 - 50 * t), int(100 - 45 * t), int(82 - 40 * t), 255)
    dr.text((px, py + k), texte, font=f, fill=c)
s = Image.alpha_composite(s, roche)
# le dessus : l'herbe, avec un liseré clair (la lèvre)
dessus = Image.new("RGBA", (W, H), (0, 0, 0, 0))
dd = ImageDraw.Draw(dessus)
dd.text((px, py + int(ep * 0.25)), texte, font=f, fill=(232, 210, 150, 255))
dd.text((px, py), texte, font=f, fill=(108, 178, 82, 255))
s = Image.alpha_composite(s, dessus)
s.convert("RGB").save(OUT)
print(OUT, W, H, taille)
