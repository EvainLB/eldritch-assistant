"""Convierte las cartas extraídas del PDF del juego base en assets de la app.

Uso: python tools/armar_base.py <carpeta_extraida> <carpeta_proyecto>
La carpeta extraída contiene front/, back/ y cards.json (salida de extraer_pdf.py).
Las cartas se clasifican por su reverso.
"""
import sys, os, json
from PIL import Image

src, proj = sys.argv[1], sys.argv[2]
EXP = "base"
# reverso (xref del PDF) -> (mazo, primigenio, lugar de expedición)
BACKS = {
    149: ("americas", None, None),
    787: ("europa", None, None),
    786: ("asia", None, None),
    788: ("general", None, None),
    785: ("otros_mundos", None, None),
    28: ("expedicion", None, "El corazón de África"),
    29: ("expedicion", None, "El Amazonas"),
    30: ("expedicion", None, "Antártida"),
    44: ("expedicion", None, "El Himalaya"),
    45: ("expedicion", None, "Las pirámides"),
    46: ("expedicion", None, "Tunguska"),
    59: ("investigacion", "azathoth", None),
    72: ("investigacion", "cthulhu", None),
    85: ("investigacion", "shub_niggurath", None),
    98: ("investigacion", "yog_sothoth", None),
    3: ("especial", "cthulhu", None),
    14: ("especial", "yog_sothoth", None),
}

out_dir = os.path.join(proj, "assets", "cards", EXP)
os.makedirs(os.path.join(out_dir, "reversos"), exist_ok=True)

def convert(a, b, width=600):
    im = Image.open(a).convert("RGB")
    if im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(b, "WEBP", quality=80, method=6)

cards = json.load(open(os.path.join(src, "cards.json")))
counter, data, backs_done = {}, [], {}
for c in cards:
    deck, ao, loc = BACKS[c["back"]]
    key = "_".join(x for x in (deck, ao) if x)
    if loc:
        key = key + "_" + loc.lower().replace(" ", "_").replace("á", "a").replace("ó", "o")
    counter[key] = counter.get(key, 0) + 1
    cid = f"{EXP}_{key}_{counter[key]:02d}"
    rel = f"assets/cards/{EXP}/{cid}.webp"
    convert(os.path.join(src, "front", c["file"] + ".jpg"), os.path.join(proj, rel))
    back_rel = f"assets/cards/{EXP}/reversos/{key}.webp"
    if key not in backs_done:
        convert(os.path.join(src, "back", f"b{c['back']}.jpg"), os.path.join(proj, back_rel), 300)
        backs_done[key] = True
    especial = {"cthulhu": "resurgir_rlyeh", "yog_sothoth": "llave_puerta"}.get(ao) if deck == "especial" else None
    data.append({"id": cid, "expansion": EXP, "deck": deck, "ancientOne": ao,
                 "location": loc, "special": especial, "image": rel, "back": back_rel})

os.makedirs(os.path.join(proj, "assets", "data"), exist_ok=True)
json.dump({"cards": data}, open(os.path.join(proj, "assets", "data", f"cartas_{EXP}.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
print(len(data), "cartas;", {k: v for k, v in sorted(counter.items())})
