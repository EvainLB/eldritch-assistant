"""Convierte los recortes de «Los hijos de Yuggoth» (expansión fan de Michael Hunter) en assets de la app.

Uso: python tools/armar_yuggoth.py <recortes> <proyecto>
<recortes>: salida de recortar_paginas.py con prefijos inv_, esp_, mis_, ave_, pri_.
Los reversos de estos PDF están volteados en vertical respecto al anverso (impresión a doble cara):
por eso la etapa de cada Aventura se tomó de su reverso con esa correspondencia y se confirmó con su texto.
"""
import sys, os, json
from PIL import Image

src, proj = sys.argv[1:3]
EXP = "hijos_yuggoth"
AO = "mi_go"

def webp(nombre, dest, ancho, calidad=80):
    im = nombre if isinstance(nombre, Image.Image) else Image.open(f"{src}/{nombre}.png")
    im = im.convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(f"{proj}/{dest}"), exist_ok=True)
    im.save(f"{proj}/{dest}", "WEBP", quality=calidad, method=6)
    return dest

cartas = []
def mazo(nombres, deck, back, esp=None):
    clave = "_".join(x for x in (deck, AO, esp) if x)
    rev = webp(back, f"assets/cards/{EXP}/reversos/{clave}.webp", 300)
    for n, nombre in enumerate(nombres, 1):
        cid = f"{EXP}_{clave}_{n:02d}"
        cartas.append({"id": cid, "expansion": EXP, "deck": deck, "ancientOne": AO, "location": None,
                       "special": esp, "image": webp(nombre, f"assets/cards/{EXP}/{cid}.webp", 600), "back": rev})

inv = [f"inv_p{p}_{k}" for p in (1, 3) for k in range(9)] + [f"inv_p5_{k}" for k in range(7)]
mazo(inv, "investigacion", "inv_p2_0")
mazo([f"esp_p2_{k}" for k in range(9)] + ["pri_p1_0"], "especial", "esp_p1_0", esp="susurra")

rev_mis = webp("mis_p2_0", f"assets/cards/{EXP}/misterios/reverso_{AO}.webp", 450)
misterios = [{"id": f"{EXP}_misterio_{AO}_{k + 1:02d}", "expansion": EXP, "ancientOne": AO, "back": rev_mis,
              "image": webp(f"mis_p1_{k}", f"assets/cards/{EXP}/misterios/{EXP}_misterio_{AO}_{k + 1:02d}.webp", 900)}
             for k in range(7)]

# Aventura «Agujero en el Mundo»: etapa de cada anverso
ETAPAS = {1: ["ave_p1_0", "ave_p1_1", "ave_p1_2", "ave_p1_3"],
          2: ["ave_p1_4", "ave_p1_5", "ave_p3_4", "ave_p3_5"],
          3: ["ave_p3_0", "ave_p3_1", "ave_p3_2", "ave_p3_3"]}
REVERSO = {1: "ave_p2_2", 2: "ave_p2_0", 3: "ave_p4_2"}
aventuras = []
for etapa, nombres in ETAPAS.items():
    rev = webp(REVERSO[etapa], f"assets/cards/{EXP}/aventuras/reverso_{etapa}.webp", 450)
    for n, nombre in enumerate(nombres, 1):
        cid = f"{EXP}_aventura_{etapa}_{n:02d}"
        aventuras.append({"id": cid, "expansion": EXP, "ancientOne": AO, "stage": etapa, "back": rev,
                          "image": webp(nombre, f"assets/cards/{EXP}/aventuras/{cid}.webp", 900)})

base = f"assets/primigenios/{EXP}/{AO}"
hoja = Image.open(f"{src}/pri_p1_1.png")
webp(hoja, base + "_hoja.webp", 1000, 82)
webp("pri_p2_0", base + "_reverso.webp", 1000, 82)
w, h = hoja.size
lado = int(w * 0.42); cx, cy = int(w * 0.55), int(h * 0.15)
retrato = hoja.crop((cx - lado // 2, max(0, cy - lado // 2), cx + lado // 2, max(0, cy - lado // 2) + lado))
webp(retrato, base + "_retrato.webp", 320, 82)
# Círculo de la expansión en Preparar partida (no hay caja: se usa el arte del Primigenio)
webp(retrato, f"assets/cajas/{EXP}.webp", 400, 85)

json.dump({"cards": cartas}, open(f"{proj}/assets/data/cartas_{EXP}.json", "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"ancientOnes": [{"id": AO, "expansion": EXP, "sheet": base + "_hoja.webp",
                            "sheetBack": base + "_reverso.webp", "portrait": base + "_retrato.webp"}],
           "mythos": [], "mysteries": misterios, "adventures": aventuras},
          open(f"{proj}/assets/data/extra_{EXP}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(cartas), "cartas;", len(misterios), "misterios;", len(aventuras), "aventuras")
