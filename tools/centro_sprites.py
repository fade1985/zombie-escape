"""Escaparates y restos sueltos del centro comercial → sprites del juego.

  py tools/centro_sprites.py

Lee assets/sources/centro/ (lo que salió de PixelLab, ver assets/pixellab.json → "centro-comercial"):
  escaparate-<tipo>.png → assets/sprites/escaparate-<tipo>.png, a ALTO_ESCAPARATE píxeles de alto (cabe en la cara
                          del muro, que mide 48, por encima del rodapié). Los pone mapa.gd a los lados de la puerta.
  resto-<nombre>.png    → assets/sprites/resto-<nombre>.png, recortado y a la mitad (como salen de PixelLab, a 64
                          píxeles, una mancha ocupaba 4 casillas). Los reparte mapa.gd por el suelo y las paredes.
Cada pixel, 2 unidades del juego ("scale": 1), y se apuntan en manifest.json.
"""
import json, os
from PIL import Image

SRC = 'assets/sources/centro'
OUT = 'assets/sprites'
ALTO_ESCAPARATE = 38


def guardar(nombre, im):
    im.save(f'{OUT}/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [im.width // 2, im.height], 'scale': 1,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'{OUT}/{nombre}.json', 'w', encoding='utf-8', newline='\n') as f:
        json.dump(meta, f, indent=2); f.write('\n')
    print(f'{nombre}: {im.width}x{im.height}')
    return nombre


hechos = []
for f in sorted(os.listdir(SRC)):
    n, ext = os.path.splitext(f)
    if ext != '.png':
        continue
    if n.startswith('escaparate-'):
        im = Image.open(f'{SRC}/{f}').convert('RGBA')
        im = im.resize((round(im.width * ALTO_ESCAPARATE / im.height), ALTO_ESCAPARATE), Image.BOX)
        hechos.append(guardar(n, im))
    elif n.startswith('resto-'):
        im = Image.open(f'{SRC}/{f}').convert('RGBA')
        im = im.crop(im.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox())
        # la media de color de cada bloque de 2×2 contando solo lo pintado, y transparente lo que era casi todo fondo
        w, h = max(1, round(im.width / 2)), max(1, round(im.height / 2))
        color = im.convert('RGBa').resize((w, h), Image.BOX).convert('RGBA')
        lleno = im.getchannel('A').resize((w, h), Image.BOX)
        out = Image.new('RGBA', (w, h))
        for y in range(h):
            for x in range(w):
                if lleno.getpixel((x, y)) > 100:
                    r, g, b, _ = color.getpixel((x, y))
                    out.putpixel((x, y), (r, g, b, 255))
        hechos.append(guardar(n, out))

ruta = f'{OUT}/manifest.json'
lista = json.load(open(ruta, encoding='utf-8'))
lista += [s for s in hechos if s not in lista]
with open(ruta, 'w', encoding='utf-8', newline='\n') as f:
    json.dump(lista, f, indent=2); f.write('\n')
