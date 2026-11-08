# El suelo y la pared del pasillo de los Apartamentos (el portal del edificio, abandonado), sacados de dos imágenes de
# GPT (8 nov): baldosa de gres gris y azulejo crema con grietas, huecos, arañazos y manchas granate.
#   assets/sources/suelos/pasillo-suelo-gpt.webp  → assets/sprites/suelo-pasillo.png  (8 × 8 baldosas, 128 × 128)
#   assets/sources/suelos/pasillo-pared-gpt.webp  → assets/sprites/pared-pasillo.png  (11 azulejos × 5 filas, 154 × 48)
#                                                  y techo-pasillo.png (el remate de arriba, 6 de alto)
# Se reduce MEZCLANDO colores con LANCZOS, como los muebles de GPT, y cada baldosa o azulejo
# cae justo en su cuadro de píxeles con la junta en el último: así las juntas salen de un píxel, rectas, y la textura
# empalma consigo misma al repetirse. El suelo se oscurece un poco (OSCURO) para que se distinga de la pared.
#   py tools/portal_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

OSCURO = 0.58   # cuánto se oscurece el suelo (1 = como lo dibujó GPT): tan oscuro como el rodapié de la pared, como pidió el dueño


def guardar(im, nombre):
    im.save(f'assets/sprites/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [0, 0], 'scale': 1, 'suavizar': 0,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'assets/sprites/{nombre}.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f'{nombre}: {im.width}x{im.height}')


def reducir(im, caja, ancho, alto, repite_y=False):
    # como los muebles (tools/muebles_gpt.py): mezclando colores con LANCZOS, de la caja (x0, y0, x1, y1, en píxeles de
    # la imagen, con decimales). LANCZOS mira también un poco fuera de cada trozo, así que la imagen se pone repetida
    # alrededor (a lo ancho y, en el suelo, también a lo alto): en los bordes mira lo que viene al repetirse y empalma
    # sin costura. (Hasta el 8 nov iba con BOX, la media de cada trozo, algo más borroso)
    a = np.asarray(im)
    W, H = im.size
    a = np.tile(a, (3 if repite_y else 1, 3, 1))
    dy = H if repite_y else 0
    x0, y0, x1, y1 = caja
    return Image.fromarray(a).resize((ancho, alto), Image.LANCZOS, box=(x0 + W, y0 + dy, x1 + W, y1 + dy))


# --- Suelo: 1254 × 1254, 8 × 8 baldosas de 156,75 con media junta en cada borde. Se corre 4,4 píxeles para que la
# junta caiga en el último píxel de cada baldosa y se reduce a 16 píxeles por baldosa
img = Image.open('assets/sources/suelos/pasillo-suelo-gpt.webp').convert('RGB')
a = np.asarray(img)
a = np.roll(a, (-4, -4), axis=(0, 1))
suelo = reducir(Image.fromarray(a), (0, 0, 1254, 1254), 128, 128, True)
suelo = Image.fromarray(np.clip(np.asarray(suelo).astype(float) * OSCURO, 0, 255).astype(np.uint8))
guardar(suelo, 'suelo-pasillo')

# --- Pared: la franja va de y 281 (junta de arriba) a 745; 11 azulejos de 139,6 de ancho con media junta en cada
# borde, 5 filas de 86,6 y el rodapié gris debajo (de 718 a 745). Azulejo: 14 × 9 píxeles; rodapié: 3
img = Image.open('assets/sources/suelos/pasillo-pared-gpt.webp').convert('RGB')
a = np.roll(np.asarray(img), -5, axis=1)
img = Image.fromarray(a)
azulejos = reducir(img, (0, 285.5, 1536, 718.5), 154, 45)
rodapie = reducir(img, (0, 718.5, 1536, 743), 154, 3)
pared = Image.new('RGB', (154, 48))
pared.paste(azulejos, (0, 0))
pared.paste(rodapie, (0, 45))
guardar(pared, 'pared-pasillo')

# --- Techo: el remate de arriba de la pared (la cara del muro, 6 píxeles): la junta de arriba de la franja y un
# canto de yeso gris claro, oscureciéndose hacia arriba como la moldura de siempre
canto = np.array([150, 144, 134], float)
techo = np.zeros((6, 154, 3))
for f in range(6):
    techo[f] = canto * (0.62 + 0.07 * f)
techo[5] = np.asarray(reducir(img, (0, 276, 1536, 286), 154, 1))[0]   # la junta de arriba del alicatado
guardar(Image.fromarray(techo.astype(np.uint8)), 'techo-pasillo')
