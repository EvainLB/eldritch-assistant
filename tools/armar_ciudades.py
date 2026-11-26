"""Convierte la carpeta de «Ciudades en ruinas» (imágenes sueltas, una por carta) en assets de la app.

Uso: python tools/armar_ciudades.py <carpeta_expansion> <proyecto>
Estructura (preparada a mano): encuentros - COMPLETO/ (am, as, co, eu 37-40 con XX00 de reverso; om61-66 Otros Mundos
con om00; londres/sanfran/shangai 1-2 = Expedición con su 0 de reverso), desastres - COMPLETO/, devastacion - COMPLETO/,
mitos - COMPLETO/ (am=amarillo, az=azul, ve=verde), preludios - COMPLETO/, primigenio/ (1-24 Investigación de Shudde M'ell,
eg = especial «Explorando G'harne», misterio = Misterios, shuddemella/b = hoja). «NO USAR» se ignora.
"""
import sys, os, json
from PIL import Image

src, proj = sys.argv[1:3]
EXP = "ciudades_ruinas"
AO = "shudde_mell"

def webp(ruta_o_img, dest, ancho, calidad=80, giro=0):
    im = ruta_o_img if isinstance(ruta_o_img, Image.Image) else Image.open(ruta_o_img)
    im = im.convert("RGB")
    if giro:
        im = im.rotate(giro, expand=True)
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

E = "encuentros - COMPLETO"
for pre, mazo in (("am", "americas"), ("as", "asia"), ("co", "general"), ("eu", "europa")):
    for n in range(37, 41):
        agregar(p(E, f"{pre}{n}.jpg"), mazo, p(E, f"{pre}00.jpg"))
for n in range(61, 67):
    agregar(p(E, f"om{n}.jpg"), "otros_mundos", p(E, "om00.png"))
for archivo, lugar in (("londres", "Londres"), ("sanfran", "San Francisco"), ("shangai", "Shanghái")):
    for n in (1, 2):
        agregar(p(E, f"{archivo}{n}.jpg"), "expedicion", p(E, f"{archivo}0.jpg"), lugar=lugar)
for carpeta, mazo in (("desastres - COMPLETO", "desastres"), ("devastacion - COMPLETO", "devastacion")):
    for n in range(1, 17):
        agregar(p(carpeta, f"{n}.jpg"), mazo, p(carpeta, "00back.jpg"))
for n in range(1, 25):
    agregar(p("primigenio", f"{n}.jpg"), "investigacion", p("primigenio", "00back.jpg"), ao=AO)
for n in range(1, 9):
    agregar(p("primigenio", f"eg{n}.jpg"), "especial", p("primigenio", "eg0.jpg"), ao=AO, esp="gharne")

M = "mitos - COMPLETO"
rev_mitos = webp(p(M, "00back.jpg"), f"assets/cards/{EXP}/mitos/reverso.webp", 300)
mitos = []
for pre, color, total in (("ve", "verde", 9), ("am", "amarillo", 12), ("az", "azul", 3)):
    for n in range(1, total + 1):
        cid = f"{EXP}_mitos_{color}_{n:02d}"
        mitos.append({"id": cid, "expansion": EXP, "color": color, "back": rev_mitos,
                      "image": webp(p(M, f"{pre}{n}.jpg"), f"assets/cards/{EXP}/mitos/{cid}.webp", 600)})

P = "preludios - COMPLETO"
rev_pre = webp(p(P, "preludio.jpg"), f"assets/cards/{EXP}/preludios/reverso.webp", 300)
preludios = [{"id": f"{EXP}_preludio_{n:02d}", "expansion": EXP, "back": rev_pre,
              "image": webp(p(P, f"pre{n}.jpg"), f"assets/cards/{EXP}/preludios/{EXP}_preludio_{n:02d}.webp", 600)}
             for n in range(1, 5)]

# Los Misterios vienen de lado: se enderezan
rev_mis = webp(p("primigenio", "misterio0.jpg"), f"assets/cards/{EXP}/misterios/reverso_{AO}.webp", 450, giro=90)
misterios = [{"id": f"{EXP}_misterio_{AO}_{n:02d}", "expansion": EXP, "ancientOne": AO, "back": rev_mis,
              "image": webp(p("primigenio", f"misterio{n}.jpg"),
                            f"assets/cards/{EXP}/misterios/{EXP}_misterio_{AO}_{n:02d}.webp", 900, giro=90)}
             for n in range(1, 7)]

base = f"assets/primigenios/{EXP}/{AO}"
fr = Image.open(p("primigenio", "shuddemella.jpg"))
webp(fr, base + "_hoja.webp", 1000, 82)
webp(p("primigenio", "shuddemellb.jpg"), base + "_reverso.webp", 1000, 82)
w, h = fr.size
lado = int(w * 0.42); cx, cy = int(w * 0.5), int(h * 0.17)
webp(fr.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado)),
     base + "_retrato.webp", 320, 82)

json.dump({"cards": cartas}, open(f"{proj}/assets/data/cartas_{EXP}.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"ancientOnes": [{"id": AO, "expansion": EXP, "sheet": base + "_hoja.webp",
                            "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"}],
           "mythos": mitos, "preludes": preludios, "mysteries": misterios},
          open(f"{proj}/assets/data/extra_{EXP}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(cartas), "cartas;", len(mitos), "mitos;", len(preludios), "preludios;", len(misterios), "misterios;",
      dict(sorted(cuenta.items())))
