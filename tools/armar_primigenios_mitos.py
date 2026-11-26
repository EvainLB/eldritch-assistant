"""Hojas de Primigenio (pág. 67-68) y cartas de Mitos (pág. 35-46) del juego base.

Uso: python tools/armar_primigenios_mitos.py <extraido_primigenios> <extraido_mitos> <carpeta_proyecto>
Las carpetas extraídas son la salida de extraer_pdf.py (front/, back/, cards.json).
Los Mitos se separan por el color de la carta (verde, amarillo, azul).
"""
import sys, os, json, colorsys
from PIL import Image, ImageStat

prim_src, mitos_src, proj = sys.argv[1:4]
EXP = "base"
ORDEN_PRIM = ["yog_sothoth", "shub_niggurath", "cthulhu", "azathoth"]  # orden en la pág. 67

def webp(im, dest, ancho):
    im = im.convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    im.save(dest, "WEBP", quality=82, method=6)

# --- Primigenios ---
prim = []
cartas = json.load(open(os.path.join(prim_src, "cards.json")))
for c, pid in zip(cartas, ORDEN_PRIM):
    fr = Image.open(os.path.join(prim_src, "front", c["file"] + ".jpg"))
    bk = Image.open(os.path.join(prim_src, "back", f"b{c['back']}.jpg"))
    base = f"assets/primigenios/{EXP}/{pid}"
    webp(fr, os.path.join(proj, base + "_hoja.webp"), 1000)
    webp(bk, os.path.join(proj, base + "_reverso.webp"), 1000)
    # Retrato: cuadrado sobre la ilustración (parte superior de la hoja)
    w, h = fr.size
    lado = int(w * 0.42)
    cx, cy = int(w * 0.5), int(h * 0.17)
    ret = fr.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado))
    webp(ret, os.path.join(proj, base + "_retrato.webp"), 320)
    prim.append({"id": pid, "expansion": EXP, "sheet": base + "_hoja.webp",
                 "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"})

# --- Mitos ---
def color(im):
    w, h = im.size
    r, g, b = [v / 255 for v in ImageStat.Stat(im.convert("RGB").crop((0, int(h * .6), int(w * .06), int(h * .95)))).mean]
    hue = colorsys.rgb_to_hsv(r, g, b)[0] * 360
    return "azul" if hue > 175 else "verde" if hue > 80 else "amarillo"

mitos, cuenta = [], {}
cartas = json.load(open(os.path.join(mitos_src, "cards.json")))
rev = f"assets/cards/{EXP}/mitos/reverso.webp"
webp(Image.open(os.path.join(mitos_src, "back", f"b{cartas[0]['back']}.jpg")), os.path.join(proj, rev), 300)
for c in cartas:
    im = Image.open(os.path.join(mitos_src, "front", c["file"] + ".jpg"))
    col = color(im)
    cuenta[col] = cuenta.get(col, 0) + 1
    cid = f"{EXP}_mitos_{col}_{cuenta[col]:02d}"
    rel = f"assets/cards/{EXP}/mitos/{cid}.webp"
    webp(im, os.path.join(proj, rel), 600)
    mitos.append({"id": cid, "expansion": EXP, "color": col, "image": rel, "back": rev})

json.dump({"ancientOnes": prim, "mythos": mitos},
          open(os.path.join(proj, "assets", "data", f"extra_{EXP}.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
print("primigenios", len(prim), "mitos", cuenta)
