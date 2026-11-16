"""El garaje subterráneo del reto del día (M125, 16 nov), con las imágenes de GPT que trajo el dueño:

- assets/sources/garaje-gpt.webp es TODO el garaje, tal cual (el suelo de resina verdosa con sus plazas, el carril con
  las flechas, la pared de arriba con las tuberías y la banda amarilla y negra, los bordes de los muros y la rampa
  cerrada de la derecha). Mide 1536 × 1024, justo lo que mide el garaje en el juego (48 × 32 casillas de 32 unidades):
  así, un punto de la imagen es el mismo punto del juego, en unidades. Se reduce a la mitad (768 × 512, a 2 unidades
  por píxel) sin recortar nada.
- La columna (garaje-columna-gpt.webp) y los tres coches (garaje-coche-<color>-gpt.webp) son muebles del catálogo
  (catalogo.gd: "garagecolumn", "carsilver", "carblue", "carred"), cada uno con su .json. A la columna le cambia la
  tapa: la franja fina de GPT se quita y se le pone encima su tapa, plana y oscura como lo de arriba de los muros del
  dibujo, del hondo de la columna vista desde arriba (TAPA).

Todo se reduce como los muebles (tools/muebles_gpt.py): el negro puro del borde, fuera; LANCZOS premultiplicado
(mezclando colores) y el borde sin medias tintas. Dónde va cada cosa en el garaje, en planta.gd (GARAJE_*).

  py tools/garaje_gpt.py      (y luego Godot --headless --path . --import)
"""
import json
import random
from collections import deque
from PIL import Image

SUELO = ('assets/sources/garaje-gpt.webp', 'assets/sprites/garaje-gpt.png', 768, 512)
# [origen, sprite, ancho, alto]: el ancho, lo que ocupa en el suelo (el "len" del catálogo, a 2 unidades por píxel)
MUEBLES = [
    ('assets/sources/garaje-columna-gpt.webp', 'assets/sprites/mueble-garagecolumn.png', 32, 64),
    ('assets/sources/garaje-coche-plata-gpt.webp', 'assets/sprites/mueble-carsilver.png', 56, 84),
    ('assets/sources/garaje-coche-azul-gpt.webp', 'assets/sprites/mueble-carblue.png', 56, 84),
    ('assets/sources/garaje-coche-rojo-gpt.webp', 'assets/sprites/mueble-carred.png', 52, 78),
]
TAPA = 14                  # lo hondo de la tapa de la columna, en píxeles (la columna mide 32: vista desde arriba, menos de la mitad)
TAPA_CORTE = 0.07          # lo de arriba de la columna de GPT que se quita (su franja fina, oscura)
TAPA_COLOR = (60, 58, 57)  # como lo de arriba de los muros del dibujo del garaje
TAPA_LUZ = (96, 92, 86)    # el filo de arriba, con luz
CONTORNO = (18, 18, 20)    # casi negro, como los contornos de GPT


def sin_fondo(origen):
    """La imagen de GPT sin el negro puro que se llega desde el borde, recortada a lo que queda"""
    im = Image.open(origen).convert('RGBA')
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
    return im.crop(im.getbbox())


def reducir(im, ancho, alto):
    """Como los muebles: mezclando colores (premultiplicado) y el borde sin medias tintas"""
    salida = im.convert('RGBa').resize((ancho, alto), Image.LANCZOS).convert('RGBA')
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    return salida


def con_json(sprite, ancho, alto):
    with open(sprite.replace('.png', '.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump({'cell': [ancho, alto], 'pivot': [ancho // 2, alto], 'scale': 1,
                   'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}, f, indent=2)
        f.write('\n')


# el suelo entero
origen, sprite, ancho, alto = SUELO
Image.open(origen).convert('RGB').resize((ancho, alto), Image.LANCZOS).save(sprite)
print(f'{sprite}: {ancho}x{alto}')

for origen, sprite, ancho, alto in MUEBLES:
    im = sin_fondo(origen)
    if 'columna' in origen:
        # sin la franja de arriba de GPT; la cara, a su tamaño, y encima la tapa
        im = im.crop((0, int(im.height * TAPA_CORTE), im.width, im.height))
        cara = reducir(im, ancho, alto)
        total = Image.new('RGBA', (ancho, alto + TAPA), (0, 0, 0, 0))
        total.paste(cara, (0, TAPA))
        azar = random.Random(7)   # (el mismo granito cada vez)
        for y in range(TAPA):
            for x in range(ancho):
                if x in (0, ancho - 1) or y == 0:
                    color = CONTORNO
                elif y == 1:
                    color = TAPA_LUZ
                else:
                    d = azar.randint(-5, 5)
                    color = tuple(c + d for c in TAPA_COLOR)
                total.putpixel((x, y), color + (255,))
        total.save(sprite)
        con_json(sprite, ancho, alto + TAPA)
        print(f'{sprite}: {ancho}x{alto + TAPA} (con su tapa)')
        continue
    reducir(im, ancho, alto).save(sprite)
    con_json(sprite, ancho, alto)
    print(f'{sprite}: {ancho}x{alto}')
