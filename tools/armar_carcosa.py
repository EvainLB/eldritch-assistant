"""Convierte la carpeta de «Señales de Carcosa» (imágenes sueltas, una por carta) en assets de la app.

Uso: python tools/armar_carcosa.py <carpeta_expansion> <proyecto>
Estructura esperada (preparada a mano): encuentros/ (a=Asia, am=Américas, c=Generales, e=Europa; X0 = reverso),
mitos/ (am=amarillo, az=azul, ve=verde, reverso.jpg), portales y expedicion/ (49-54 Otros Mundos, 61-66 Expedición,
e_* reversos de expedición, portalb = reverso), preludios/, Misterios/, primigenio/ (1-24 Investigación de Hastur,
ciu/in/rey = sus tres mazos especiales con su *back, hastur.png / hasturb.png = hoja).
La carpeta «NO USAR» se ignora.
"""
import sys, os, json
from PIL import Image

src, proj = sys.argv[1:3]
EXP = "senales_carcosa"

def webp(ruta_o_img, dest, ancho, calidad=80):
    im = ruta_o_img if isinstance(ruta_o_img, Image.Image) else Image.open(ruta_o_img)
    im = im.convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(f"{proj}/{dest}"), exist_ok=True)
    im.save(f"{proj}/{dest}", "WEBP", quality=calidad, method=6)
    return dest

def p(*partes): return os.path.join(src, *partes)

def slug(t):
    for a, b in (("á", "a"), ("é", "e"), ("í", "i"), ("ó", "o"), ("ú", "u"), (" ", "_")):
        t = t.lower().replace(a, b)
    return t

cartas, cuenta = [], {}
def agregar(img, mazo, back_img, ao=None, lugar=None, esp=None):
    clave = "_".join(x for x in (mazo, ao, esp, lugar and slug(lugar)) if x)
    cuenta[clave] = cuenta.get(clave, 0) + 1
    cid = f"{EXP}_{clave}_{cuenta[clave]:02d}"
    rel = webp(img, f"assets/cards/{EXP}/{cid}.webp", 600)
    rev = f"assets/cards/{EXP}/reversos/{clave}.webp"
    if not os.path.exists(f"{proj}/{rev}"):
        webp(back_img, rev, 300)
    cartas.append({"id": cid, "expansion": EXP, "deck": mazo, "ancientOne": ao, "location": lugar,
                   "special": esp, "image": rel, "back": rev})

for pre, mazo in (("a", "asia"), ("am", "americas"), ("c", "general"), ("e", "europa")):
    for n in range(29, 33):
        agregar(p("encuentros", f"{pre}{n}.png"), mazo, p("encuentros", f"{pre}0.jpg"))

for n in range(49, 55):
    agregar(p("portales y expedicion", f"{n}.png"), "otros_mundos", p("portales y expedicion", "portalb.png"))
EXPED = {61: ("Tunguska", "tunguska"), 62: ("Las pirámides", "piramides"), 63: ("El Himalaya", "himalaya"),
         64: ("El Amazonas", "amazonas"), 65: ("Antártida", "antartida"), 66: ("El corazón de África", "africa")}
for n, (lugar, archivo) in EXPED.items():
    agregar(p("portales y expedicion", f"{n}.png"), "expedicion", p("portales y expedicion", f"e_{archivo}.png"),
            lugar=lugar)

for n in range(1, 25):
    agregar(p("primigenio", f"{n}.png"), "investigacion", p("primigenio", "back.png"), ao="hastur")
for pre, esp, total in (("ciu", "ciudades_lago", 12), ("in", "innombrable", 8), ("rey", "rey_amarillo", 12)):
    for n in range(1, total + 1):
        agregar(p("primigenio", f"{pre}{n}.png"), "especial", p("primigenio", f"{pre}back.png"), ao="hastur", esp=esp)

mitos = []
rev_mitos = webp(p("mitos", "reverso.jpg"), f"assets/cards/{EXP}/mitos/reverso.webp", 300)
for pre, color, total in (("ve", "verde", 8), ("am", "amarillo", 10), ("az", "azul", 6)):
    for n in range(1, total + 1):
        cid = f"{EXP}_mitos_{color}_{n:02d}"
        rel = webp(p("mitos", f"{pre}{n}.png"), f"assets/cards/{EXP}/mitos/{cid}.webp", 600)
        mitos.append({"id": cid, "expansion": EXP, "color": color, "image": rel, "back": rev_mitos})

rev_pre = webp(p("preludios", "preludio.jpg"), f"assets/cards/{EXP}/preludios/reverso.webp", 300)
preludios = [{"id": f"{EXP}_preludio_{n:02d}", "expansion": EXP,
              "image": webp(p("preludios", f"{n}.png"), f"assets/cards/{EXP}/preludios/{EXP}_preludio_{n:02d}.webp", 600),
              "back": rev_pre} for n in range(1, 5)]

rev_mis = webp(p("Misterios", "back.png"), f"assets/cards/{EXP}/misterios/reverso_hastur.webp", 450)
misterios = [{"id": f"{EXP}_misterio_hastur_{n:02d}", "expansion": EXP, "ancientOne": "hastur",
              "image": webp(p("Misterios", f"{n}.png"), f"assets/cards/{EXP}/misterios/{EXP}_misterio_hastur_{n:02d}.webp", 900),
              "back": rev_mis} for n in range(1, 9)]

base = f"assets/primigenios/{EXP}/hastur"
fr = Image.open(p("primigenio", "hastur.png"))
webp(fr, base + "_hoja.webp", 1000, 82)
webp(p("primigenio", "hasturb.png"), base + "_reverso.webp", 1000, 82)
w, h = fr.size
lado = int(w * 0.42); cx, cy = int(w * 0.5), int(h * 0.17)
webp(fr.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado)),
     base + "_retrato.webp", 320, 82)

json.dump({"cards": cartas}, open(f"{proj}/assets/data/cartas_{EXP}.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"ancientOnes": [{"id": "hastur", "expansion": EXP, "sheet": base + "_hoja.webp",
                            "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"}],
           "mythos": mitos, "preludes": preludios, "mysteries": misterios},
          open(f"{proj}/assets/data/extra_{EXP}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(cartas), "cartas;", len(mitos), "mitos;", len(preludios), "preludios;", len(misterios), "misterios;",
      dict(sorted(cuenta.items())))
