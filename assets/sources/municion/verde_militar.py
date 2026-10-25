# La munición de la MP5: la caja de balas de la pistola (intentos/municion-pistola-A.png) con la caja pintada de verde
# oscuro militar, como las cajas de munición del ejército (lo pidió el dueño el 25 oct). Solo cambian los azules de la
# caja; las balas doradas, la etiqueta amarilla y el contorno se quedan igual.
# Uso, desde la raíz del proyecto: py assets/sources/municion/verde_militar.py
import colorsys
from pathlib import Path
from PIL import Image

AQUI = Path(__file__).parent
TONO = 75 / 360   # verde oliva

im = Image.open(AQUI / "intentos" / "municion-pistola-A.png").convert("RGBA")
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        if a == 0:
            continue
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        # los azules de la caja (no el contorno, casi negro)
        if 0.55 < h < 0.70 and s > 0.2 and v > 0.1:
            s2 = min(0.62, max(0.38, s * 1.1 + 0.08))
            v2 = min(1.0, v * 1.05)
            r2, g2, b2 = colorsys.hsv_to_rgb(TONO, s2, v2)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
im.save(AQUI.parent.parent / "ui" / "iconos" / "municion-mp5.png")
print("hecho: assets/ui/iconos/municion-mp5.png")
