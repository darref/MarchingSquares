import numpy as np
from PIL import Image, ImageDraw, ImageFilter

TITLE  = r"C:\Users\jorda\Downloads\upscaled_74e8550e-c3d7-4e4a-99b3-10c18858ddd8.jpeg"
PLAQUE = r"D:\AbsoluTiles\splash\SoluTiles_SPLASH_nu.png"
OUT    = r"D:\AbsoluTiles\splash\SoluTiles_SPLASH.png"

LARGEUR = 0.32     # part de la largeur du splash occupee par le mot
MARGE_X = 75       # respiration du cadre autour du mot
MARGE_Y = 60
RAYON   = 55       # arrondi des coins
FORCE   = 0.72     # fondu du cadre vers l'ardoise
FONDU   = 4        # adoucissement du bord
LISERE  = 0.12     # filet clair sur le pourtour ; 0 pour l'enlever
BG      = np.array([33.0, 36.0, 46.0])
LO, HI  = 10.0, 34.0

t = Image.open(TITLE).convert("RGB")
rgb = np.asarray(t).astype(np.float32)
alpha = np.clip((np.sqrt(((rgb - BG) ** 2).sum(axis=2)) - LO) / (HI - LO), 0.0, 1.0)

ys, xs = np.where(alpha > 0.5)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
mw, mh = x1 - x0 + 1, y1 - y0 + 1
m = int(0.05 * mw)
cx0, cy0 = max(0, x0 - m), max(0, y0 - m)
cx1, cy1 = min(t.width, x1 + 1 + m), min(t.height, y1 + 1 + m)
titre = Image.fromarray(np.dstack([rgb, alpha * 255.0]).astype(np.uint8), "RGBA") \
             .crop((cx0, cy0, cx1, cy1))

s = Image.open(PLAQUE).convert("RGB")
SW, SH = s.size
k = (LARGEUR * SW) / mw
titre = titre.resize((int(round(titre.width * k)), int(round(titre.height * k))), Image.LANCZOS)
px = int(round(SW / 2.0 - ((x0 + x1) / 2.0 - cx0) * k))
py = int(round(SH / 2.0 - ((y0 + y1) / 2.0 - cy0) * k))

plaque = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
plaque.paste(titre, (px, py))
pa = np.asarray(plaque).astype(np.float32) / 255.0
a = pa[:, :, 3]

bw, bh = mw * k, mh * k
box = [SW / 2 - bw / 2 - MARGE_X, SH / 2 - bh / 2 - MARGE_Y,
       SW / 2 + bw / 2 + MARGE_X, SH / 2 + bh / 2 + MARGE_Y]
print("cadre", [int(v) for v in box], " soit", int(box[2] - box[0]), "x", int(box[3] - box[1]))

def masque(dessin, flou):
    im = Image.new("L", (SW, SH), 0)
    dessin(ImageDraw.Draw(im))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(flou))).astype(np.float32) / 255.0

fond = masque(lambda d: d.rounded_rectangle(box, radius=RAYON, fill=255), FONDU) * FORCE
filet = masque(lambda d: d.rounded_rectangle(box, radius=RAYON, outline=255, width=2), 1.6) * LISERE
contact = np.asarray(Image.fromarray((np.roll(np.roll(a, 8, 0), 4, 1) * 255).astype(np.uint8))
                     .filter(ImageFilter.GaussianBlur(10))).astype(np.float32) / 255.0 * 0.45

base = np.asarray(s).astype(np.float32) / 255.0
base = base * (1 - fond)[:, :, None] + (BG / 255.0)[None, None, :] * fond[:, :, None]
base = base * (1 - filet)[:, :, None] + filet[:, :, None]          # le filet eclaircit
base *= (1 - np.clip(contact, 0, 0.6))[:, :, None]

out = base * (1 - a[:, :, None]) + pa[:, :, :3] * a[:, :, None]
Image.fromarray(np.clip(out * 255, 0, 255).astype(np.uint8)).save(OUT)
print("ecrit", OUT)
