"""Convierte las cartas extraídas de «Vestigios extraños» en assets de la app.

Uso: python tools/armar_vestigios.py <extraido> <hoja_png> <reverso_png> <proyecto>
- extraido: carpeta de extraer_pdf.py con los PDF juntos (prefijos enc_, mit_, por_, rui_, sic_, sicb_)
  y el campo "grupo" para enc_/por_/rui_ (reversos agrupados por parecido).
- hoja_png / reverso_png: hoja de Sicigia recortada del escaneo de página completa.
"""
import sys, os, json, colorsys
from PIL import Image, ImageStat

src, hoja_png, rev_png, proj = sys.argv[1:5]
EXP = "vestigios_extranos"

def webp(im, dest, ancho, calidad=80):
    im = im.convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    im.save(dest, "WEBP", quality=calidad, method=6)

def color_mitos(im):
    w, h = im.size
    r, g, b = [v / 255 for v in ImageStat.Stat(im.convert("RGB").crop((0, int(h * .6), int(w * .06), int(h * .95)))).mean]
    hue = colorsys.rgb_to_hsv(r, g, b)[0] * 360
    # Este escaneo es más cálido que el del juego base: amarillas ~42°, verdes ~55-75°, azules >200°
    return "azul" if hue > 150 else "verde" if hue > 50 else "amarillo"

ENC = {0: "americas", 1: "asia", 2: "europa", 3: "general"}
RUINAS = {15: "Chichén Itzá", 16: "Estatuas Moai", 17: "Gran Muralla China", 18: "Stonehenge"}

def clasificar(c):
    """-> (tipo, mazo, primigenio, lugar, especial) o None si la app no lo usa (Misterios)."""
    f, b = c["file"], c["back"]
    if f.startswith("enc_"): return ("carta", ENC[c["grupo"]], None, None, None)
    if f.startswith("por_"): return ("carta", "otros_mundos", None, None, None)
    if f.startswith("rui_"): return ("carta", "ruinas", None, RUINAS[c["grupo"]], None)
    if f.startswith("mit_"): return ("preludio",) if b == "mit_b68" else ("mitos",)
    if f.startswith("sic_"): return ("carta", "investigacion", "syzygy", None, None)
    if f.startswith("sicb_"):
        if b == "sicb_b190": return None  # Misterios de Sicigia
        return ("carta", "especial", "syzygy", None, "barrera" if f.startswith("sicb_p07") else "sellar_portal")
    raise ValueError(f)

def slug(t):
    for a, b in (("á", "a"), ("é", "e"), ("í", "i"), ("ó", "o"), ("ú", "u"), (" ", "_")):
        t = t.lower().replace(a, b)
    return t

cartas, mitos, preludios, cuenta, hechos = [], [], [], {}, set()
for c in json.load(open(f"{src}/cards.json")):
    cl = clasificar(c)
    if cl is None:
        continue
    fr = Image.open(f"{src}/front/{c['file']}.jpg")
    back = Image.open(f"{src}/back/{c['back']}.jpg")
    if cl[0] in ("mitos", "preludio"):
        tipo = cl[0]
        clave = color_mitos(fr) if tipo == "mitos" else "preludio"
        cuenta[clave] = cuenta.get(clave, 0) + 1
        carpeta = "mitos" if tipo == "mitos" else "preludios"
        cid = f"{EXP}_{carpeta}_{clave}_{cuenta[clave]:02d}" if tipo == "mitos" else f"{EXP}_preludio_{cuenta[clave]:02d}"
        rel = f"assets/cards/{EXP}/{carpeta}/{cid}.webp"
        rev = f"assets/cards/{EXP}/{carpeta}/reverso.webp"
        webp(fr, f"{proj}/{rel}", 600)
        if rev not in hechos:
            webp(back, f"{proj}/{rev}", 300); hechos.add(rev)
        if tipo == "mitos":
            mitos.append({"id": cid, "expansion": EXP, "color": clave, "image": rel, "back": rev})
        else:
            preludios.append({"id": cid, "expansion": EXP, "image": rel, "back": rev})
        continue
    _, mazo, ao, lugar, esp = cl
    clave = "_".join(x for x in (mazo, ao, esp, slug(lugar) if lugar else None) if x)
    cuenta[clave] = cuenta.get(clave, 0) + 1
    cid = f"{EXP}_{clave}_{cuenta[clave]:02d}"
    rel = f"assets/cards/{EXP}/{cid}.webp"
    rev = f"assets/cards/{EXP}/reversos/{clave}.webp"
    webp(fr, f"{proj}/{rel}", 600)
    if rev not in hechos:
        webp(back, f"{proj}/{rev}", 300); hechos.add(rev)
    cartas.append({"id": cid, "expansion": EXP, "deck": mazo, "ancientOne": ao, "location": lugar,
                   "special": esp, "image": rel, "back": rev})

# Hoja de Sicigia
fr, bk = Image.open(hoja_png), Image.open(rev_png)
base = f"assets/primigenios/{EXP}/syzygy"
webp(fr, f"{proj}/{base}_hoja.webp", 1000, 82)
webp(bk, f"{proj}/{base}_reverso.webp", 1000, 82)
w, h = fr.size
lado = int(w * 0.42); cx, cy = int(w * 0.5), int(h * 0.17)
webp(fr.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado)),
     f"{proj}/{base}_retrato.webp", 320, 82)

json.dump({"cards": cartas}, open(f"{proj}/assets/data/cartas_{EXP}.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"ancientOnes": [{"id": "syzygy", "expansion": EXP, "sheet": base + "_hoja.webp",
                            "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"}],
           "mythos": mitos,
           "preludes": preludios},  # Preludios: guardados para más adelante, la app aún no los usa
          open(f"{proj}/assets/data/extra_{EXP}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(cartas), "cartas;", len(mitos), "mitos;", len(preludios), "preludios;", dict(sorted(cuenta.items())))
