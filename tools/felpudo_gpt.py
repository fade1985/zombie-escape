# El felpudo de las puertas del pasillo de los Apartamentos (los pisos y la sala de mantenimiento), de una imagen de GPT
# (8 nov): fibra de coco con una banda negra en forma de marco, sin letras ni dibujos (se probó uno por puerta con su
# letra y no le gustó al dueño).
#   assets/sources/felpudo-gpt.webp → assets/sprites/felpudo.png (30 × 19; lo pinta mapa.dibujar_fondo delante de cada puerta)
# Como los muebles de GPT (tools/muebles_gpt.py): se quita el negro puro que se llega desde el borde, se recorta y se
# reduce MEZCLANDO colores (LANCZOS premultiplicado), con el borde sin medias tintas.
#   py tools/felpudo_gpt.py   (y luego Godot --headless --path . --import)
from collections import deque
from PIL import Image

ANCHO, ALTO = 30, 19
im = Image.open('assets/sources/felpudo-gpt.webp').convert('RGBA')
W, H = im.size
px = im.load()
fondo = bytearray(W * H)
cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
while cola:
    x, y = cola.popleft()
    if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 12:
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
f.save('assets/sprites/felpudo.png')
print('felpudo', im.size, '→', f.size)
