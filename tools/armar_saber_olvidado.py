"""Convierte las cartas extraídas de «Saber olvidado» en assets de la app.

Uso: python tools/armar_saber_olvidado.py <extraido_cartas> <extraido_primigenio> <cards_base_back> <proyecto>
- extraido_cartas: salida de extraer_pdf.py (págs. 1-37) con el campo "grupo" (reversos agrupados por parecido).
- extraido_primigenio: salida de extraer_pdf.py de la pág. 47 (hoja de Yig).
- cards_base_back: reversos del juego base, para distinguir la Investigación de cada Primigenio.
"""
import sys, os, json, colorsys
from PIL import Image, ImageChops, ImageStat

src, prim_src, base_back, proj = sys.argv[1:5]
EXP = "saber_olvidado"

def webp(im, dest, ancho, calidad=80):
    im = im.convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    im.save(dest, "WEBP", quality=calidad, method=6)

def parte_alta(p):
    im = Image.open(p).convert("RGB"); w, h = im.size
    return im.crop((int(w * .1), int(h * .04), int(w * .9), int(h * .42))).resize((40, 24))

REF = {k: parte_alta(f"{base_back}/b{x}.jpg")
       for k, x in {"azathoth": 59, "cthulhu": 72, "shub_niggurath": 85, "yog_sothoth": 98}.items()}

def primigenio_investigacion(back_path):
    t = parte_alta(back_path)
    d, k = min((sum(ImageStat.Stat(ImageChops.difference(t, r)).mean) / 3, k) for k, r in REF.items())
    return k if d < 5 else "yig"

def color_mitos(im):
    w, h = im.size
    r, g, b = [v / 255 for v in ImageStat.Stat(im.convert("RGB").crop((0, int(h * .6), int(w * .06), int(h * .95)))).mean]
    hue = colorsys.rgb_to_hsv(r, g, b)[0] * 360
    return "azul" if hue > 175 else "verde" if hue > 80 else "amarillo"

LUGARES = {4: "Antártida", 5: "El Himalaya", 6: "Las pirámides", 7: "Tunguska"}
SIMPLES = {8: "americas", 9: "asia", 10: "europa", 11: "otros_mundos", 19: "general"}

def clasificar(c):
    """-> (mazo, primigenio, lugar, especial) o None para lo que aún no usa la app (Misterios)."""
    g, f = c["grupo"], c["file"]
    if g == 0: return ("especial", "yig", None, "knyan")
    if g == 1: return ("especial", "cthulhu", None, "resurgir_rlyeh")
    if g == 2:
        return ("especial", "yog_sothoth", None, "llave_puerta" if f.startswith("p05") else "vacio_mundos")
    if g == 3: return ("expedicion", None, "El corazón de África" if f == "p05_2" else "El Amazonas", None)
    if g in LUGARES: return ("expedicion", None, LUGARES[g], None)
    if g in SIMPLES: return (SIMPLES[g], None, None, None)
    if g == 12: return ("mitos", None, None, None)
    if g == 13: return ("investigacion", primigenio_investigacion(f"{src}/back/b{c['back']}.jpg"), None, None)
    return None  # 14-18: Misterios

def slug(t):
    for a, b in (("á", "a"), ("é", "e"), ("í", "i"), ("ó", "o"), ("ú", "u"), (" ", "_")):
        t = t.lower().replace(a, b)
    return t

cartas, mitos, cuenta, reversos = [], [], {}, set()
for c in json.load(open(f"{src}/cards.json")):
    cl = clasificar(c)
    if cl is None:
        continue
    mazo, ao, lugar, esp = cl
    fr = Image.open(f"{src}/front/{c['file']}.jpg")
    if mazo == "mitos":
        col = color_mitos(fr)
        cuenta[col] = cuenta.get(col, 0) + 1
        cid = f"{EXP}_mitos_{col}_{cuenta[col]:02d}"
        rel = f"assets/cards/{EXP}/mitos/{cid}.webp"
        rev = f"assets/cards/{EXP}/mitos/reverso.webp"
        webp(fr, f"{proj}/{rel}", 600)
        if rev not in reversos:
            webp(Image.open(f"{src}/back/b{c['back']}.jpg"), f"{proj}/{rev}", 300); reversos.add(rev)
        mitos.append({"id": cid, "expansion": EXP, "color": col, "image": rel, "back": rev})
        continue
    clave = "_".join(x for x in (mazo, ao, esp, slug(lugar) if lugar else None) if x)
    cuenta[clave] = cuenta.get(clave, 0) + 1
    cid = f"{EXP}_{clave}_{cuenta[clave]:02d}"
    rel = f"assets/cards/{EXP}/{cid}.webp"
    rev = f"assets/cards/{EXP}/reversos/{clave}.webp"
    webp(fr, f"{proj}/{rel}", 600)
    if rev not in reversos:
        webp(Image.open(f"{src}/back/b{c['back']}.jpg"), f"{proj}/{rev}", 300); reversos.add(rev)
    cartas.append({"id": cid, "expansion": EXP, "deck": mazo, "ancientOne": ao, "location": lugar,
                   "special": esp, "image": rel, "back": rev})

# Hoja de Yig
c = json.load(open(f"{prim_src}/cards.json"))[0]
fr = Image.open(f"{prim_src}/front/{c['file']}.jpg"); bk = Image.open(f"{prim_src}/back/b{c['back']}.jpg")
base = f"assets/primigenios/{EXP}/yig"
webp(fr, f"{proj}/{base}_hoja.webp", 1000, 82)
webp(bk, f"{proj}/{base}_reverso.webp", 1000, 82)
w, h = fr.size
lado = int(w * 0.42); cx, cy = int(w * 0.66), int(h * 0.17)
webp(fr.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado)),
     f"{proj}/{base}_retrato.webp", 320, 82)
prim = [{"id": "yig", "expansion": EXP, "sheet": base + "_hoja.webp",
         "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"}]

os.makedirs(f"{proj}/assets/data", exist_ok=True)
json.dump({"cards": cartas}, open(f"{proj}/assets/data/cartas_{EXP}.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"ancientOnes": prim, "mythos": mitos},
          open(f"{proj}/assets/data/extra_{EXP}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(cartas), "cartas;", len(mitos), "mitos;", dict(sorted(cuenta.items())))
