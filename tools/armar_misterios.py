"""Guarda las cartas de Misterio de cada Primigenio en los datos de la app (aún no se usan en pantalla).

Uso: python tools/armar_misterios.py <lista.json> <proyecto>
lista.json: [[origen, archivo, anverso.jpg, reverso.jpg], ...] con origen "base", "so gNN" o "ve"
(base: págs. 31-34 del PDF del juego base; so: grupos 14-18 de Saber olvidado; ve: Misterios de Sicigia).
Las cartas vienen giradas en los PDF: se enderezan para que el texto se lea horizontal.
"""
import sys, os, json
from PIL import Image

items, proj = json.load(open(sys.argv[1])), sys.argv[2]

BASE = ["azathoth"] * 4 + ["cthulhu"] * 4 + ["shub_niggurath"] * 4 + ["yog_sothoth"] * 4  # orden en el PDF
SO = {"so g14": "yig", "so g15": "azathoth", "so g16": "cthulhu", "so g17": "shub_niggurath", "so g18": "yog_sothoth"}
EXP = {"base": "base", "so": "saber_olvidado", "ve": "vestigios_extranos"}

def webp(im, dest, ancho):
    im = im.convert("RGB")
    if im.width > ancho:
        im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    im.save(dest, "WEBP", quality=80, method=6)

por_exp, cuenta, i_base = {}, {}, 0
for origen, archivo, fr, bk in items:
    if origen == "base":
        ao, giro = BASE[i_base], -90; i_base += 1
    elif origen.startswith("so"):
        ao, giro = SO[origen], -90
    else:
        ao, giro = "syzygy", 90
    exp = EXP[origen.split()[0]]
    clave = (exp, ao)
    cuenta[clave] = cuenta.get(clave, 0) + 1
    cid = f"{exp}_misterio_{ao}_{cuenta[clave]:02d}"
    rel = f"assets/cards/{exp}/misterios/{cid}.webp"
    rev = f"assets/cards/{exp}/misterios/reverso_{ao}.webp"
    webp(Image.open(fr).rotate(giro, expand=True), f"{proj}/{rel}", 900)
    if not os.path.exists(f"{proj}/{rev}"):
        webp(Image.open(bk).rotate(giro, expand=True), f"{proj}/{rev}", 450)
    por_exp.setdefault(exp, []).append({"id": cid, "expansion": exp, "ancientOne": ao, "image": rel, "back": rev})

for exp, lista in por_exp.items():
    p = f"{proj}/assets/data/extra_{exp}.json"
    d = json.load(open(p, encoding="utf-8"))
    d["mysteries"] = lista  # Misterios: guardados para más adelante
    json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print({f"{e}/{a}": n for (e, a), n in sorted(cuenta.items())})
