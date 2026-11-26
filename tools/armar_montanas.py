"""Convierte las cartas extraídas de «Las montañas de la locura» en assets de la app.

Uso: python tools/armar_montanas.py <extraido> <proyecto>
<extraido>: salida de extraer_pdf.py (págs. 1-51) con el campo "grupo" (reversos agrupados) y las hojas
de Primigenio hoja_1062/1063 (anversos) y hoja_1095/1096 (reversos) sacadas de las págs. 71-72.
"""
import sys, os, json, colorsys
from PIL import Image, ImageStat

src, proj = sys.argv[1:3]
EXP = "montanas_locura"

def webp(im, dest, ancho, calidad=80):
    im = (im if isinstance(im, Image.Image) else Image.open(im)).convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(f"{proj}/{dest}"), exist_ok=True)
    im.save(f"{proj}/{dest}", "WEBP", quality=calidad, method=6)
    return dest

def color_mitos(im):
    w, h = im.size
    r, g, b = [v / 255 for v in ImageStat.Stat(im.convert("RGB").crop((0, int(h * .6), int(w * .06), int(h * .95)))).mean]
    hue = colorsys.rgb_to_hsv(r, g, b)[0] * 360
    return "azul" if hue > 175 else "verde" if hue > 80 else "amarillo"

ENC = {6: "otros_mundos", 7: "americas", 8: "asia", 9: "europa", 10: "general",
       11: "montanas", 12: "puesto_avanzado", 13: "inv_antartida"}
EXPED = {2: "Arkham", 3: "Roma", 4: "Sídney"}
ANTIGUOS_INV = {"b170", "b198", "b220"}
AVENTURA_ETAPA = {"p49_1": 1, "p49_2": 1, "p49_3": 1, "p49_4": 1,
                  "p49_0": 2, "p49_5": 2, "p49_6": 2, "p49_7": 2,
                  "p49_8": 3, "p51_0": 3, "p51_1": 3, "p51_2": 3}
PRELUDIO_ANTARTIDA = "p51_7"

def slug(t):
    for a, b in (("á", "a"), ("é", "e"), ("í", "i"), ("ó", "o"), ("ú", "u"), (" ", "_")):
        t = t.lower().replace(a, b)
    return t

cartas, mitos, preludios, misterios, aventuras, cuenta, hechos = [], [], [], [], [], {}, set()

def una(fr, back, mazo, ao=None, lugar=None, esp=None):
    clave = "_".join(x for x in (mazo, ao, esp, lugar and slug(lugar)) if x)
    cuenta[clave] = cuenta.get(clave, 0) + 1
    cid = f"{EXP}_{clave}_{cuenta[clave]:02d}"
    rev = f"assets/cards/{EXP}/reversos/{clave}.webp"
    if rev not in hechos:
        webp(back, rev, 300); hechos.add(rev)
    cartas.append({"id": cid, "expansion": EXP, "deck": mazo, "ancientOne": ao, "location": lugar,
                   "special": esp, "image": webp(fr, f"assets/cards/{EXP}/{cid}.webp", 600), "back": rev})

for c in json.load(open(f"{src}/cards.json")):
    g, f, b = c["grupo"], c["file"], c["back"]
    fr, back = Image.open(f"{src}/front/{f}.jpg"), Image.open(f"{src}/back/{b}.jpg")
    if g == 0:
        una(fr, back, "especial", "antiguos", esp="desapariciones" if b == "b68" else "dios_oscuro")
    elif g == 1:
        una(fr, back, "especial", "ithaqua", esp="hiperborea")
    elif g in EXPED:
        una(fr, back, "expedicion", lugar=EXPED[g])
    elif g == 5:
        una(fr, back, "investigacion", "antiguos" if b in ANTIGUOS_INV else "ithaqua")
    elif g in ENC:
        una(fr, back, ENC[g])
    elif g == 14:
        col = color_mitos(fr)
        cuenta[col] = cuenta.get(col, 0) + 1
        cid = f"{EXP}_mitos_{col}_{cuenta[col]:02d}"
        rev = f"assets/cards/{EXP}/mitos/reverso.webp"
        if rev not in hechos:
            webp(back, rev, 300); hechos.add(rev)
        mitos.append({"id": cid, "expansion": EXP, "color": col, "back": rev,
                      "image": webp(fr, f"assets/cards/{EXP}/mitos/{cid}.webp", 600)})
    elif g in (15, 16):
        ao = "antiguos" if g == 15 else "ithaqua"
        n = sum(1 for m in misterios if m["ancientOne"] == ao) + 1
        cid = f"{EXP}_misterio_{ao}_{n:02d}"
        rev = f"assets/cards/{EXP}/misterios/reverso_{ao}.webp"
        if rev not in hechos:
            webp(back, rev, 450); hechos.add(rev)
        misterios.append({"id": cid, "expansion": EXP, "ancientOne": ao, "back": rev,
                          "image": webp(fr, f"assets/cards/{EXP}/misterios/{cid}.webp", 900)})
    elif g == 17:
        etapa = AVENTURA_ETAPA[f]
        n = sum(1 for a in aventuras if a["stage"] == etapa) + 1
        cid = f"{EXP}_aventura_{etapa}_{n:02d}"
        rev = f"assets/cards/{EXP}/aventuras/reverso_{etapa}.webp"
        if rev not in hechos:
            webp(back, rev, 450); hechos.add(rev)
        aventuras.append({"id": cid, "expansion": EXP, "ancientOne": "antartida", "stage": etapa, "back": rev,
                          "image": webp(fr, f"assets/cards/{EXP}/aventuras/{cid}.webp", 900)})
    elif g == 18:
        n = len(preludios) + 1
        cid = f"{EXP}_preludio_antartida" if f == PRELUDIO_ANTARTIDA else f"{EXP}_preludio_{n:02d}"
        rev = f"assets/cards/{EXP}/preludios/reverso.webp"
        if rev not in hechos:
            webp(back, rev, 300); hechos.add(rev)
        preludios.append({"id": cid, "expansion": EXP, "back": rev,
                          "image": webp(fr, f"assets/cards/{EXP}/preludios/{cid}.webp", 600)})

hojas = []
for ao, anv, rev in (("antiguos", 1062, 1096), ("ithaqua", 1063, 1095)):
    base = f"assets/primigenios/{EXP}/{ao}"
    fr = Image.open(f"{src}/hoja_{anv}.png")
    webp(fr, base + "_hoja.webp", 1000, 82)
    webp(f"{src}/hoja_{rev}.png", base + "_reverso.webp", 1000, 82)
    w, h = fr.size
    lado = int(w * 0.42); cx, cy = int(w * 0.55), int(h * 0.17)
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
