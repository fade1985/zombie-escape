# El suelo y la pared de la galería del centro comercial (el pasillo de las tiendas, un centro comercial de los 80
# abandonado), sacados de dos imágenes de GPT (17 nov), como el portal de los Apartamentos (tools/portal_gpt.py):
#   assets/sources/suelos/galeria-suelo-gpt.webp → assets/sprites/suelo-galeria.png  (16 × 16 baldosas pastel, 128 × 128)
#   assets/sources/suelos/galeria-pared-gpt.webp → assets/sprites/pared-galeria.png  (8 paneles rosa malva, 152 × 48)
#                                                 y techo-galeria.png (el remate de arriba, 6 de alto)
# Cada baldosa y cada panel se reduce por dentro MEZCLANDO colores con LANCZOS («como los muebles») y la junta se pinta
# aparte, de un píxel y con su color de la imagen: así salen rectas y nítidas, y la textura empalma consigo misma.
#   py tools/galeria_gpt.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

OSCURO = 0.8   # cuánto se oscurece el suelo (1 = como lo dibujó GPT), para que se distinga de la pared


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


def reducir_corrido(im, caja, ancho, alto):
    # lo mismo, pero con la imagen repetida a los lados: en los bordes LANCZOS mira lo que viene al repetirse y empalma
    a = np.asarray(im)
    W = im.width
    x0, y0, x1, y1 = caja
    return reducir(Image.fromarray(np.tile(a, (1, 3, 1))), (x0 + W, y0, x1 + W, y1), ancho, alto)


def color_de(a, zona):
    # el color mediano de un trozo de la imagen (las juntas)
    return np.median(a[zona].reshape(-1, 3), axis=0)


# --- Suelo: 1254 × 1254, 16 × 16 baldosas de 78,375 con la junta (unos 4 píxeles) centrada en cada múltiplo, y media
# junta en los bordes. Cada baldosa: 7 × 7 píxeles de dentro y la junta en el último (8 × 8).
# GPT repartió los colores al azar; el dueño lo quiere en mosaico, como su foto: un escocés (tartán) EN DIAGONAL que se
# repite cada 10 baldosas (así caben justas las 11 filas de mosaico de la galería: mapa.gd lo corre para que empiece y acabe
# en una fila de cruces y los rombos queden enteros; MOSAICO_GALERIA = 80 píxeles). Cada diagonal (las que bajan a la derecha y las que suben) es oscura (a), media (b) o clara (c),
# y el color de la baldosa sale de cruzar sus dos diagonales (MOSAICO). De la baldosa de GPT solo se queda su dibujo
# (grietas, rayas, motas: lo que se aparta de su color medio).
# Y aparte, suelo-galeria-marco: las mismas baldosas, todas del color claro (MARCO), para el marco que pinta mapa.gd
# arriba (4 filas de baldosas) y abajo (1) de la galería, como el borde liso que rodea el mosaico en la foto
COLORES = {'O': (115, 82, 120), 'M': (167, 126, 163), 'L': (154, 137, 166), 'R': (201, 154, 171), 'G': (166, 162, 171),
           'C': (219, 187, 171)}   # morado oscuro, malva, lila, rosa, gris y crema (los de las baldosas de GPT)
MARCO = (206, 201, 210)   # gris lila muy claro
MOSAICO = {('a', 'a'): 'O', ('a', 'b'): 'M', ('a', 'c'): 'M', ('b', 'b'): 'R', ('b', 'c'): 'R', ('c', 'c'): 'C'}
TIRAS = 'aabccccccb'   # las 10 diagonales que se repiten: dos oscuras, una media, seis claras y otra media
img = Image.open('assets/sources/suelos/galeria-suelo-gpt.webp').convert('RGB')
a = np.asarray(img)
PASO, JUNTA, N = 1254 / 16, 3.0, 16
junta = np.median(np.concatenate([a[:, int(PASO * k) - 1:int(PASO * k) + 2].reshape(-1, 3) for k in range(1, N)]), axis=0)


def baldosas(color_de_baldosa, corrida=(0, 0), n=N):
    # n × n baldosas (las 16 × 16 de GPT, repetidas si hacen falta más) con su dibujo y el color que diga color_de_baldosa(fx, fy); corrida cambia qué
    # baldosa de GPT va en cada sitio (para que el marco no tenga las grietas en los mismos sitios que el mosaico)
    suelo = np.zeros((n * 8, n * 8, 3))
    suelo[:, :] = junta
    for fy in range(n):
        for fx in range(n):
            gx, gy = (fx + corrida[0]) % N, (fy + corrida[1]) % N
            caja = (gx * PASO + JUNTA, gy * PASO + JUNTA, (gx + 1) * PASO - JUNTA, (gy + 1) * PASO - JUNTA)
            baldosa = reducir(img, caja, 7, 7)
            suelo[fy * 8:fy * 8 + 7, fx * 8:fx * 8 + 7] = baldosa - baldosa.mean(axis=(0, 1)) + color_de_baldosa(fx, fy)
    return Image.fromarray(np.clip(suelo * OSCURO, 0, 255).astype(np.uint8))


guardar(baldosas(lambda fx, fy: COLORES[MOSAICO[tuple(sorted((TIRAS[(fx + fy) % 10], TIRAS[(fx - fy) % 10])))]], n=20),
        'suelo-galeria')   # 160 × 160: dos veces el mosaico
guardar(baldosas(lambda fx, fy: MARCO, (5, 3)), 'suelo-galeria-marco')

# --- Pared: la franja va de y 263 a 759; 8 paneles de 191,5 de ancho con la junta (unos 5 píxeles) en cada múltiplo.
# De arriba abajo (en píxeles de la imagen → del juego): moldura cromada 264-279 → 2, raya oscura 280-284 → 1,
# paneles 285-711 → 39, junta 712-716 → 1, canto del rodapié 717-720 → 1, rodapié 721-753 → 3, su borde 754-759 → 1.
# Cada panel: 18 píxeles de dentro y la junta en el último (19): 152 de ancho
img = Image.open('assets/sources/suelos/galeria-pared-gpt.webp').convert('RGB')
a = np.asarray(img)
PANEL, PANELES, ANCHO = 1536 / 8, 8, 19
W = PANELES * ANCHO
pared = np.zeros((48, W, 3))
pared[0:2] = reducir_corrido(img, (0, 264, 1536, 279), W, 2)
pared[2:3] = reducir_corrido(img, (0, 280, 1536, 285), W, 1)
junta = color_de(a, (slice(400, 600), slice(190, 195)))
for p in range(PANELES):
    caja = (p * PANEL + 5, 285, (p + 1) * PANEL - 3, 712)
    pared[3:42, p * ANCHO:p * ANCHO + ANCHO - 1] = reducir(img, caja, ANCHO - 1, 39)
    pared[3:42, p * ANCHO + ANCHO - 1] = junta
pared[42:43] = reducir_corrido(img, (0, 712, 1536, 717), W, 1)
pared[43:44] = reducir_corrido(img, (0, 717, 1536, 721), W, 1)
pared[44:47] = reducir_corrido(img, (0, 721, 1536, 754), W, 3)
pared[47:48] = reducir_corrido(img, (0, 754, 1536, 759), W, 1)
guardar(Image.fromarray(np.clip(pared, 0, 255).astype(np.uint8)), 'pared-galeria')

# --- Techo: el remate de arriba de la pared (la cara del muro, 6 píxeles): un canto malva grisáceo, oscureciéndose
# hacia arriba como en el portal, y abajo la raya oscura de encima de la moldura
canto = np.array([128, 108, 124], float)
techo = np.zeros((6, W, 3))
for f in range(6):
    techo[f] = canto * (0.62 + 0.07 * f)
techo[5] = reducir_corrido(img, (0, 258, 1536, 264), W, 1)[0] * 0.5 + canto * 0.4
guardar(Image.fromarray(np.clip(techo, 0, 255).astype(np.uint8)), 'techo-galeria')
