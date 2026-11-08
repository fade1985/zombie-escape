"""El arrastrado de GPT, arrastrándose de espaldas: GPT no quiso dibujarlo con el final del cuerpo rojo (lo rechazaba por
violencia), así que se le pidió con una copia de las 5 vistas en la que era marrón (capturas/lento-para-gpt-sin-rojo.png).
Esto se lo vuelve a pintar de rojo, como en sus otras vistas: los 8 píxeles de abajo de cada dibujo que no son piel verde.

Se pasa una vez, después de `py tools/zombi_gpt.py --zombi lento andar north` (si se rehace, otra vez):
  py assets/sources/zombi-lento-gpt/rojo_espalda.py
"""
import glob
from PIL import Image

ALTO = 8   # lo que mide de alto el final del cuerpo, desde abajo (en la vista quieta, 7 de 34)

for ruta in glob.glob("assets/sources/zombi-lento-gpt-48/walk/north-[0-9]*.png"):
    if ruta.endswith("north-0.png"):
        continue   # (el 0 es el dibujo quieto, que ya es rojo)
    im = Image.open(ruta).convert("RGBA")
    px = im.load()
    caja = im.getbbox()
    for y in range(caja[3] - ALTO, caja[3]):
        for x in range(caja[0], caja[2]):
            r, g, b, a = px[x, y]
            if a and g <= r:   # (la piel verde de las manos, no)
                px[x, y] = (min(255, round(r * 1.05)), round(g * 0.32), round(b * 0.32), a)
    im.save(ruta)
    print(ruta)
