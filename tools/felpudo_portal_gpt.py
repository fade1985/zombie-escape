# El felpudo del portal de los Apartamentos (delante de la puerta de la calle, la de la izquierda de la planta baja), de
# una imagen de GPT (10 nov): un felpudo de rejilla metálica, con marco de aluminio claro y siete tiras de goma oscuras.
#   assets/sources/felpudo-portal-gpt.webp → assets/sprites/felpudo-portal.png (lo pinta mapa.dibujar_fondo)
# Como los muebles de GPT (tools/muebles_gpt.py): se quita el negro puro que se llega desde el borde, se recorta y se
# reduce MEZCLANDO colores (LANCZOS premultiplicado), con el borde sin medias tintas. Luego se gira un cuarto de vuelta
# (lo de arriba del dibujo queda a la izquierda, contra la puerta): la puerta está en la pared de la izquierda, así que el
# felpudo va de pie, a lo largo de ella, y las tiras quedan atravesadas al paso de quien entra.
#   py tools/felpudo_portal_gpt.py   (y luego Godot --headless --path . --import)
#   py tools/felpudo_portal_gpt.py 36 18 ruta.png   → otro tamaño (antes de girar), para probar
import sys
from collections import deque
from PIL import Image

ANCHO, ALTO = 30, 15   # antes de girar: de pie mide 15 × 30 (30 × 60 unidades, tan largo como los de los pisos; la puerta
                       # tiene 72 de alto). Más grande, las tiras se mezclan y salen desiguales
SALIDA = 'assets/sprites/felpudo-portal.png'
if len(sys.argv) > 2:
    ANCHO, ALTO = int(sys.argv[1]), int(sys.argv[2])
if len(sys.argv) > 3:
    SALIDA = sys.argv[3]
im = Image.open('assets/sources/felpudo-portal-gpt.webp').convert('RGBA')
W, H = im.size
px = im.load()
fondo = bytearray(W * H)
cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
while cola:
    x, y = cola.popleft()
    if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 6:
        continue
    fondo[y * W + x] = 1
    cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
for y in range(H):
    for x in range(W):
        if fondo[y * W + x]:
            px[x, y] = (0, 0, 0, 0)
im = im.crop(im.getbbox())
f = im.convert('RGBa').resize((ANCHO, ALTO), Image.LANCZOS).convert('RGBA')
f.putalpha(f.split()[3].point(lambda v: 255 if v > 110 else 0))
f = f.transpose(Image.Transpose.ROTATE_90)   # (sin mezclar: un cuarto de vuelta exacto)
f.save(SALIDA)
print('felpudo del portal', im.size, '→', f.size)
