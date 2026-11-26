"""Convierte la carpeta de «Las Tierras del Sueño» (imágenes sueltas) en assets de la app.

Uso: python tools/armar_tierras.py <carpeta_expansion> <proyecto>
Encuentros/: am, as, co, eu (X0 = reverso), om55-60 (Otros Mundos), y el tablero del Sueño:
ts (Tierras del Sueño), be+bs1 (Bosque Encantado), dk (Kadath), lu (Luna), ms (Mundo Subterráneo).
Aventuras/: aventura0 = reverso; misterio1 (etapa I), misterio2* (II), misterio3* (III).
primigenio/Atla y primigenio/Hipnos: e* Investigación, m* Misterios, ee* Especiales de Hypnos.
Si falta una cara de la hoja de Primigenio, se usa la que haya en las dos posiciones.
"""
import sys, os, json, glob
from PIL import Image

src, proj = sys.argv[1:3]
EXP = "tierras_sueno"

def webp(ruta, dest, ancho, calidad=80, giro=0):
    im = (ruta if isinstance(ruta, Image.Image) else Image.open(ruta)).convert("RGB")
    if giro:
        im = im.rotate(giro, expand=True)
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(f"{proj}/{dest}"), exist_ok=True)
    im.save(f"{proj}/{dest}", "WEBP", quality=calidad, method=6)
    return dest

def p(*partes): return os.path.join(src, *partes)

cartas, cuenta = [], {}
def mazo(archivos, deck, back, ao=None, esp=None):
    clave = "_".join(x for x in (deck, ao, esp) if x)
    rev = webp(back, f"assets/cards/{EXP}/reversos/{clave}.webp", 300)
    for f in archivos:
        cuenta[clave] = cuenta.get(clave, 0) + 1
        cid = f"{EXP}_{clave}_{cuenta[clave]:02d}"
        cartas.append({"id": cid, "expansion": EXP, "deck": deck, "ancientOne": ao, "location": None,
                       "special": esp, "image": webp(f, f"assets/cards/{EXP}/{cid}.webp", 600), "back": rev})

E = p("Encuentros")
def num(f): return int("".join(ch for ch in os.path.basename(f) if ch.isdigit()) or 0)
def serie(pre, carpeta=E):
    fs = [f for f in glob.glob(f"{carpeta}/{pre}*.jpg") if os.path.basename(f)[len(pre)].isdigit()]
    return sorted([f for f in fs if num(f) != 0], key=num), f"{carpeta}/{pre}0.jpg"

for pre, deck in (("am", "americas"), ("as", "asia"), ("co", "general"), ("eu", "europa")):
    fs, back = serie(pre)
    mazo(fs, deck, back)
# Otros Mundos: la carpeta no trae su reverso; es el mismo del juego base
REV_OM = Image.open(f"{proj}/" + next(c["back"] for c in json.load(open(f"{proj}/assets/data/cartas_base.json", encoding="utf-8"))["cards"] if c["deck"] == "otros_mundos"))
mazo([f"{E}/om{n}.jpg" for n in range(55, 61)], "otros_mundos", REV_OM)
# Tablero de las Tierras del Sueño
for pre, deck in (("ts", "sueno"), ("dk", "kadath"), ("lu", "luna"), ("ms", "subterraneo")):
    fs, back = serie(pre)
    mazo(fs, deck, back)
fs, back = serie("be")
mazo(fs + [f"{E}/bs1.jpg"], "bosque", back)

# Primigenios
H, A = p("primigenio", "Hipnos"), p("primigenio", "Atla")
for carpeta, ao, pre in ((A, "atlach_nacha", "eatla"), (H, "hypnos", "ehipnos")):
    fs, back = serie(pre, carpeta)
    mazo(fs, "investigacion", back, ao=ao)
for esp, pre, back in (("corona", "eecorona", "eecorona0"), ("oniro", "eeoniro", "eeonironauta0"),
                       ("sueno_en_sueno", "eesueño", "eesueño0")):
    fs, _ = serie(pre, H)
    mazo(fs, "especial", f"{H}/{back}.jpg", ao="hypnos", esp=esp)

misterios = []
for carpeta, ao, pre in ((A, "atlach_nacha", "matla"), (H, "hypnos", "mhipnos")):
    fs, back = serie(pre, carpeta)
    rev = webp(back, f"assets/cards/{EXP}/misterios/reverso_{ao}.webp", 450, giro=90)
    for n, f in enumerate(fs, 1):
        cid = f"{EXP}_misterio_{ao}_{n:02d}"
        misterios.append({"id": cid, "expansion": EXP, "ancientOne": ao, "back": rev,
                          "image": webp(f, f"assets/cards/{EXP}/misterios/{cid}.webp", 900, giro=90)})

AV = p("Aventuras")
aventuras = []
rev_av = webp(f"{AV}/aventura0.jpg", f"assets/cards/{EXP}/aventuras/reverso.webp", 450, giro=90)
for f in sorted(glob.glob(f"{AV}/misterio*.jpg")):
    etapa = int(os.path.basename(f)[8])
    n = sum(1 for a in aventuras if a["stage"] == etapa) + 1
    cid = f"{EXP}_aventura_{etapa}_{n:02d}"
    aventuras.append({"id": cid, "expansion": EXP, "ancientOne": "sueno", "stage": etapa, "back": rev_av,
                      "image": webp(f, f"assets/cards/{EXP}/aventuras/{cid}.webp", 900, giro=90)})

M = p("mitos")
rev_m = webp(f"{M}/reverso.jpg", f"assets/cards/{EXP}/mitos/reverso.webp", 300)
mitos = []
for pre, color in (("v", "verde"), ("am", "amarillo"), ("a", "azul")):
    fs = sorted([f for f in glob.glob(f"{M}/{pre}[0-9]*.jpg")], key=num)
    for n, f in enumerate(fs, 1):
        cid = f"{EXP}_mitos_{color}_{n:02d}"
        mitos.append({"id": cid, "expansion": EXP, "color": color, "back": rev_m,
                      "image": webp(f, f"assets/cards/{EXP}/mitos/{cid}.webp", 600)})

P = p("preludios")
rev_p = webp(f"{P}/preludio.jpg", f"assets/cards/{EXP}/preludios/reverso.webp", 300)
preludios = []
for n in range(1, 7):
    cid = f"{EXP}_preludio_suenos" if n == 3 else f"{EXP}_preludio_{n:02d}"  # pr3: «Sueños de otros mundos»
    preludios.append({"id": cid, "expansion": EXP, "back": rev_p,
                      "image": webp(f"{P}/pr{n}.jpg", f"assets/cards/{EXP}/preludios/{cid}.webp", 600)})

hojas = []
# Las caras que faltaban en la carpeta llegaron aparte, en inglés (el usuario pidió usarlas así)
for ao, frente, dorso in (("hypnos", f"{H}/hipnos.jpg", f"{H}/hipnos_reverso_en.webp"),
                          ("atlach_nacha", f"{A}/atlachnacha_frente_en.webp", f"{A}/atlachnachab.jpg")):
    base = f"assets/primigenios/{EXP}/{ao}"
    fr = Image.open(frente)
    webp(fr, base + "_hoja.webp", 1000, 82)
    webp(dorso, base + "_reverso.webp", 1000, 82)
    w, h = fr.size
    lado = int(w * 0.42); cx, cy = int(w * 0.5), int(h * 0.17)
    webp(fr.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado)),
         base + "_retrato.webp", 320, 82)
    hojas.append({"id": ao, "expansion": EXP, "sheet": base + "_hoja.webp",
                  "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"})

json.dump({"cards": cartas}, open(f"{proj}/assets/data/cartas_{EXP}.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"ancientOnes": hojas, "mythos": mitos, "preludes": preludios, "mysteries": misterios,
           "adventures": aventuras},
          open(f"{proj}/assets/data/extra_{EXP}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(cartas), "cartas;", len(mitos), "mitos;", len(preludios), "preludios;", len(misterios), "misterios;",
      len(aventuras), "aventuras;", dict(sorted(cuenta.items())))
