"""Extrae anverso y reverso de cada carta de un PDF de hojas para imprimir.
Uso: python tools/extraer_pdf.py <pdf> <carpeta_salida> <pag_inicial> <pag_final>
     [prefijo] [salto]
Requiere pymupdf. Por defecto las paginas impares son anversos y la siguiente es su reverso (en espejo).
Con salto=N (N>1) cada pagina de anversos usa como reversos la pagina N despues (p. ej. 1-3 -> 4-6).
"""
import sys, os, json, pymupdf
pdf, out, first, last = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
prefijo = sys.argv[5] if len(sys.argv) > 5 else ''  # para juntar varios PDF en una carpeta
salto = int(sys.argv[6]) if len(sys.argv) > 6 else 1
prev = json.load(open(f'{out}/cards.json')) if prefijo and os.path.exists(f'{out}/cards.json') else []
d = pymupdf.open(pdf)
def save(xref, path):
    pix = pymupdf.Pixmap(d, xref)
    if pix.alpha: pix = pymupdf.Pixmap(pix, 0)
    if pix.colorspace and pix.colorspace.n != 3: pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
    pix.save(path, jpg_quality=85) if path.endswith('.jpg') else pix.save(path)
W = d[0].rect.width
cards=list(prev); backs={}
for pn in range(first, last+1, 2 if salto == 1 else 1):
    fr=[i for i in d[pn-1].get_image_info(xrefs=True) if i['width']>600]
    # Huecos de relleno: la misma imagen repetida varias veces en una página de anversos
    rep={}
    for i in fr: rep[i['xref']]=rep.get(i['xref'],0)+1
    fr=[i for i in fr if rep[i['xref']]==1]
    bk=[i for i in d[pn-1+salto].get_image_info(xrefs=True) if i['width']>600]
    for i in fr:
        x0,y0,x1,y1=i['bbox']
        m=[b for b in bk if abs(b['bbox'][0]-(W-x1))<3 and abs(b['bbox'][1]-y0)<3]
        bx=m[0]['xref'] if m else None
        name=f"{prefijo}p{pn:02d}_{len([c for c in cards if c['page']==pn and c['file'].startswith(prefijo)])}"
        save(i['xref'], f"{out}/front/{name}.jpg")
        if bx and bx not in backs:
            save(bx, f"{out}/back/{prefijo}b{bx}.jpg"); backs[bx]=0
        if bx: backs[bx]+=1
        cards.append(dict(file=name, page=pn, back=f'{prefijo}b{bx}', pdf=os.path.basename(pdf)))
json.dump(cards, open(f"{out}/cards.json","w"), indent=1)
print(len(cards), backs)
