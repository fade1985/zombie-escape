# El suelo y la pared de la sala de venta de la tienda de ropa (18 nov, el dueño, a partir de una foto suya de una
# boutique: tarima de roble claro, pared rosa empolvado y rodapié dorado acanalado), sacados de dos imágenes de GPT:
#   assets/sources/suelos/ropa-suelo-gpt.webp → assets/sprites/suelo-ropa.png  (16 filas de tablas de 8 píxeles, 128 × 128)
#   assets/sources/suelos/ropa-pared-gpt.webp → assets/sprites/pared-ropa.png  (192 × 64: la pared alta, de 4 casillas)
#                                                y techo-ropa.png (el remate de arriba, que con "cajas" no se ve)
# Como tools/galeria_gpt.py: cada trozo de tabla se reduce por dentro MEZCLANDO colores con LANCZOS («como los muebles») y
# las juntas se pintan aparte, de un píxel y con su color de la imagen, así salen rectas y la textura empalma consigo
# misma. Los listones del rodapié, tan finos que al reducirlos se emborronan, se pintan uno claro y uno oscuro sobre el
# color de cada fila del rodapié reducido.
#   py tools/ropa_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

FILAS = 16          # las filas de tablas de la imagen de GPT (de izquierda a derecha)
TAM = 128           # el suelo: 128 × 128 (cada fila, 8 píxeles: 1 de junta y 7 de madera)
PARED = (192, 64)   # la pared: 64 de alto, la pared alta de las tiendas (Tienda.TIPOS "sube": 4)
RODAPIE = 0.866     # dónde empieza el rodapié en la imagen de la pared (de arriba abajo, de 0 a 1)


def guardar(im, nombre):
    im.save(f'assets/sprites/{nombre}.png')
    meta = {'cell': [im.width, im.height], 'pivot': [0, 0], 'scale': 1, 'suavizar': 0,
            'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}
    with open(f'assets/sprites/{nombre}.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f'{nombre}: {im.width}x{im.height}')


def reducir(im, caja, ancho, alto):
    # mezclando colores con LANCZOS, de la caja (x0, y0, x1, y1, en píxeles de la imagen, con decimales)
    return np.asarray(im.resize((ancho, alto), Image.LANCZOS, box=caja)).astype(float)


def suelo():
    im = Image.open('assets/sources/suelos/ropa-suelo-gpt.webp').convert('RGB')
    a = np.asarray(im).astype(float)
    W, H = im.size
    alto = H / FILAS
    tres = Image.fromarray(np.tile(a, (1, 3, 1)).astype(np.uint8))   # repetida a los lados: los trozos que dan la vuelta
    luz = a.mean(axis=2)
    out = np.zeros((TAM, TAM, 3))
    juntas = []   # los píxeles de las juntas, para su color
    for f in range(FILAS):
        y0, y1 = f * alto, (f + 1) * alto
        # la junta larga, arriba de la fila
        juntas.append(a[int(y0):int(y0) + 2].reshape(-1, 3))
        # las juntas cortas de esta fila: las columnas mucho más oscuras que la madera de su fila
        dentro = luz[int(y0) + 6:int(y1) - 4]
        col = dentro.mean(axis=0)
        cortes = [x for x in range(W) if col[x] < np.median(col) - 25]
        # (cada junta son 2 o 3 columnas seguidas: su medio)
        grupos = []
        for x in cortes:
            if grupos and x - grupos[-1][-1] <= 2:
                grupos[-1].append(x)
            else:
                grupos.append([x])
        xs = [sum(g) / len(g) for g in grupos]
        for g in grupos:
            juntas.append(a[int(y0) + 6:int(y1) - 4, g[0]:g[-1] + 1].reshape(-1, 3))
        destino = [round(x * TAM / W) % TAM for x in xs]
        fila = 1 + f * 8   # la primera de madera (la de encima es la junta)
        # cada tabla, de una junta a la siguiente (la última da la vuelta por el borde)
        for i in range(len(xs)):
            xa, xb = xs[i], xs[(i + 1) % len(xs)] + (W if i == len(xs) - 1 else 0)
            da, db = destino[i], destino[(i + 1) % len(xs)] + (TAM if i == len(xs) - 1 else 0)
            ancho = db - da - 1
            if ancho <= 0:
                continue
            trozo = reducir(tres, (W + xa + 2, y0 + 3, W + xb - 2, y1 - 1), ancho, 7)
            for k in range(ancho):
                out[fila:fila + 7, (da + 1 + k) % TAM] = trozo[:, k]
    color_junta = np.median(np.concatenate(juntas), axis=0)
    for f in range(FILAS):
        out[f * 8] = color_junta
    # las juntas cortas, otra vez fila a fila (ya con el color de junta de todas)
    for f in range(FILAS):
        y0, y1 = f * alto, (f + 1) * alto
        col = luz[int(y0) + 6:int(y1) - 4].mean(axis=0)
        xs = [x for x in range(W) if col[x] < np.median(col) - 25]
        for x in xs:
            out[1 + f * 8:8 + f * 8, round(x * TAM / W) % TAM] = color_junta
    guardar(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)), 'suelo-ropa')


def pared():
    im = Image.open('assets/sources/suelos/ropa-pared-gpt.webp').convert('RGB')
    W, H = im.size
    ancho, alto = PARED
    corte = round(RODAPIE * alto)            # la primera fila del rodapié en la pequeña
    y_rod = RODAPIE * H
    out = np.zeros((alto, ancho, 3))
    # el yeso rosa: reducido entero
    out[:corte] = reducir(im, (0, 0, W, y_rod - 3), ancho, corte)
    # el rodapié: el color de cada fila reducido (con su canto de arriba) y los listones, uno claro y uno oscuro
    rod = reducir(im, (0, y_rod, W, H), 1, alto - corte)[:, 0]
    for i in range(alto - corte):
        y = corte + i
        if i == 0:
            out[y] = rod[i] * 1.15   # el canto de arriba, que brilla
            continue
        for x in range(ancho):
            out[y, x] = rod[i] * (1.18 if x % 2 == 0 else 0.78)
    guardar(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)), 'pared-ropa')
    # el remate de arriba (con "cajas" no se ve, pero cada estilo lo lleva): el rosa, un poco más oscuro
    techo = np.tile(out[2:3] * 0.85, (6, 1, 1))
    guardar(Image.fromarray(np.clip(techo, 0, 255).astype(np.uint8)), 'techo-ropa')


suelo()
pared()
