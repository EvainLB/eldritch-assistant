"""Quita el fondo blanco de las fotos de las cajas y las guarda como WebP con transparencia.
Uso: python tools/preparar_cajas.py <carpeta_con_jpgs> <carpeta_proyecto>
"""
import sys, os
from PIL import Image, ImageDraw

NOMBRES = {
    "BASE": "base",
    "LORE_PERDIDO": "saber_olvidado",
    "MONTAÑAS_LOCURA": "montanas_locura",
    "VESTIGIOS_EXTRAÑOS": "vestigios_extranos",
    "BAJO_PIRAMIDES": "bajo_piramides",
    "SEÑALES_CARCOSA": "senales_carcosa",
    "LAS_TIERRAS_SUEÑO": "tierras_sueno",
    "CIUDADES_RUINAS": "ciudades_ruinas",
    "MASCARAS_NYARLA": "mascaras_nyarlathotep",
}
src, proj = sys.argv[1], sys.argv[2]
MAG = (255, 0, 255)
for nombre, eid in NOMBRES.items():
    im = Image.open(os.path.join(src, nombre + ".jpg")).convert("RGB")
    w, h = im.size
    marcado = im.copy()
    semillas = [(x, y) for x in range(0, w, 25) for y in (0, h - 1)] + \
               [(x, y) for y in range(0, h, 25) for x in (0, w - 1)]
    for s in semillas:
        if marcado.getpixel(s) != MAG and min(marcado.getpixel(s)) > 225:
            ImageDraw.floodfill(marcado, s, MAG, thresh=28)
    alfa = Image.eval(marcado.convert("RGB").point(lambda v: v).split()[1], lambda v: 255)
    px_m, px_a = marcado.load(), alfa.load()
    for y in range(h):
        for x in range(w):
            if px_m[x, y] == MAG:
                px_a[x, y] = 0
    rgba = im.copy(); rgba.putalpha(alfa)
    rgba = rgba.crop(alfa.getbbox())
    rgba.thumbnail((360, 360), Image.LANCZOS)
    rgba.save(os.path.join(proj, "assets", "cajas", eid + ".webp"), "WEBP", quality=85)
    print(eid, rgba.size)
