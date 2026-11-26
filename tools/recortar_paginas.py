"""Recorta cartas de PDFs maquetados (Publisher/Word) donde cada carta es un montaje de capas.
Uso: python recortar_paginas.py <pdf> <salida> <prefijo> <pag1,pag2,...> [dpi]
Renderiza cada página y detecta las cartas por proyecciones de píxeles no blancos (cuadrícula).
Guarda <prefijo>p<pag>_<n>.png y un cajas.json con las posiciones."""
import sys, os, json
import pymupdf
from PIL import Image

pdf, out, pre, pags = sys.argv[1], sys.argv[2], sys.argv[3], [int(x) for x in sys.argv[4].split(',')]
dpi = int(sys.argv[5]) if len(sys.argv) > 5 else 250
os.makedirs(out, exist_ok=True)
d = pymupdf.open(pdf)

def tramos(vals, umbral, minimo):
    r, ini = [], None
    for i, v in enumerate(vals + [0]):
        if v > umbral and ini is None: ini = i
        elif v <= umbral and ini is not None:
            if i - ini >= minimo: r.append((ini, i))
            ini = None
    return r

res = json.load(open(f"{out}/cajas.json")) if os.path.exists(f"{out}/cajas.json") else {}
for pn in pags:
    pix = d[pn - 1].get_pixmap(dpi=dpi)
    im = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    g = im.convert("L").point(lambda v: 255 if v < 232 else 0)
    W, H = g.size
    px = g.load()
    cols = [sum(1 for y in range(0, H, 4) if px[x, y]) for x in range(W)]
    cajas = []
    for x0, x1 in tramos(cols, 6, int(dpi * 0.8)):
        filas = [sum(1 for x in range(x0, x1, 4) if px[x, y]) for y in range(H)]
        for y0, y1 in tramos(filas, 3, int(dpi * 0.8)):
            cajas.append((x0, y0, x1, y1))
    cajas.sort(key=lambda c: (round(c[1] / (dpi * 0.5)), c[0]))
    for k, c in enumerate(cajas):
        im.crop(c).save(f"{out}/{pre}p{pn}_{k}.png")
    res[f"{pre}p{pn}"] = cajas
    print(pre, pn, len(cajas), [(c[2]-c[0], c[3]-c[1]) for c in cajas])
json.dump(res, open(f"{out}/cajas.json", "w"), indent=1)
