# Los tres neones de la pared de la galería del centro comercial (17 nov): un casete, un radiocasete y un tocadiscos, de
# tres imágenes de GPT (assets/sources/galeria/neon-<nombre>-gpt.webp: tubos cian y magenta sobre negro puro). Se reducen
# «como los muebles» (LANCZOS premultiplicado): el negro pasa a transparente (todo, también el de dentro, para que se vea
# la pared) y se mezclan los colores. Sale cada uno encendido (neon-<nombre>.png) y apagado (neon-<nombre>-apagado.png:
# el tubo de cristal sin luz, gris violáceo, para cuando falla). Los pinta neon_galeria.gd.
# Y los dos de la farmacia, que van en vez de sus escaparates (17 nov, el dueño): la cruz verde de LEDs a la izquierda de la
# puerta y la botella de tubo de neón con su cruz a la derecha (assets/sources/centro/neon-farmacia-<nombre>-gpt.webp). La
# cruz es una chapa entera: lo de dentro (los huecos entre LEDs) no se vacía, y apagada se ven los LEDs muertos sobre la chapa.
#   py tools/neones_galeria.py   (y luego Godot --headless --path . --import)
#   py tools/neones_galeria.py farmacia-cruz farmacia-botella   (solo esos)
import sys

import numpy as np
from PIL import Image, ImageDraw

# nombre -> (alto en píxeles del dibujo (el ancho, según la proporción), imagen de GPT, chapa entera)
NEONES = {'casete': (28, 'galeria/neon-casete-gpt.webp', False),
          'radiocasete': (32, 'galeria/neon-radiocasete-gpt.webp', False),
          'tocadiscos': (28, 'galeria/neon-tocadiscos-gpt.webp', False),
          'farmacia-cruz': (28, 'centro/neon-farmacia-cruz-gpt.webp', True),
          'farmacia-botella': (27, 'centro/neon-farmacia-botella-gpt.webp', False),
          # el letrero de la farmacia, PHARMACY en tubos de neón verdes, con la Y suelta (neon.gd, LETREROS): sale como
          # letrero-farmacia.png y letrero-farmacia-apagado.png (su resplandor, tools/letrero_halo.py farmacia)
          'ferreteria-herramientas': (25, 'centro/neon-ferreteria-herramientas-gpt.webp', False),
          'letrero-ferreteria': (18, 'centro/letrero-ferreteria-gpt.webp', False),
          'electronica-marco': (47, 'centro/marco-electronica-gpt.webp', False),
          'electronica-ordenador': (22, 'centro/neon-electronica-ordenador-gpt.webp', False),
          'electronica-mando': (22, 'centro/neon-electronica-mando-gpt.webp', False),
          'letrero-electronica': (19, 'centro/letrero-electronica-gpt.webp', False),
          'restaurante-hamburguesa': (26, 'centro/neon-restaurante-hamburguesa-gpt.webp', False),
          'restaurante-pizza': (26, 'centro/neon-restaurante-pizza-gpt.webp', False),
          'letrero-restaurante': (20, 'centro/letrero-restaurante-gpt.webp', False),
          'ropa-compras': (27, 'centro/neon-ropa-compras-gpt.webp', False),
          'ropa-sale': (26, 'centro/neon-ropa-sale-gpt.webp', False),
          'letrero-ropa': (21, 'centro/letrero-ropa-gpt.webp', False),
          'letrero-farmacia': (19, 'centro/letrero-farmacia-gpt.webp', False)}
ANCHOS = {'electronica-marco': 44}   # (un ancho fijo, más ancho que su proporción: el marco rodea una puerta de 28)
TUBO = np.array([77, 71, 84], float)   # el tubo apagado (el mismo que las letras fundidas de neon.gd)
LED_MUERTO = np.array([44, 62, 50], float)   # un LED apagado de la cruz: gris verdoso


def pasar(nombre, alto, origen, chapa):
    salida = nombre if nombre.startswith('letrero-') else f'neon-{nombre}'
    a = np.asarray(Image.open(f'assets/sources/{origen}').convert('RGB')).astype(float)
    # transparencia: lo casi negro, nada; desde ahí sube deprisa
    alfa = np.clip((a.max(axis=2) - 24.0) / 70.0, 0.0, 1.0)
    if chapa:
        # la silueta entera: todo lo que no es el negro de fuera (que se llena desde una esquina)
        dentro = Image.fromarray(((a.max(axis=2) > 24) * 255).astype(np.uint8), 'L').copy()   # (copia: si no, no se deja pintar)
        ImageDraw.floodfill(dentro, (0, 0), 128)
        alfa = (np.asarray(dentro) != 128).astype(float)
    ys, xs = np.nonzero(alfa > 0.5)
    caja = (xs.min() - 2, ys.min() - 2, xs.max() + 3, ys.max() + 3)
    ancho = ANCHOS.get(nombre) or round(alto * (caja[2] - caja[0]) / (caja[3] - caja[1]))
    # premultiplicado: así el negro de alrededor no ensucia el borde del tubo al mezclar
    pre = np.dstack([a * alfa[..., None], alfa * 255.0]).astype(np.uint8)
    peq = np.asarray(Image.fromarray(pre, 'RGBA').resize((ancho, alto), Image.LANCZOS, box=caja)).astype(float)
    al = peq[..., 3:4] / 255.0
    color = np.where(al > 0.004, peq[..., :3] / np.maximum(al, 0.004), 0.0)
    al = np.where(al < 0.12, 0.0, np.clip(al * 1.15, 0.0, 1.0))   # sin velos casi invisibles alrededor
    if chapa:
        al = (al > 0.5).astype(float)   # (la chapa, con el borde limpio: sin un filo a medias alrededor)
    encendido = np.dstack([np.clip(color, 0, 255), al * 255.0]).astype(np.uint8)
    Image.fromarray(encendido, 'RGBA').save(f'assets/sprites/{salida}.png')
    # apagado: el mismo tubo, sin color, con un poco del dibujo (lo claro del centro, algo más claro)
    luz = color.mean(axis=2, keepdims=True) / 255.0
    if chapa:
        # (la cruz: la chapa se queda; donde había LED, uno muerto)
        apagado = np.dstack([np.clip(color * (1 - luz) + LED_MUERTO * (0.6 + 0.6 * luz) * luz, 0, 255),
                             al * 255.0]).astype(np.uint8)
    else:
        apagado = np.dstack([np.clip(TUBO * (0.75 + 0.45 * luz), 0, 255), al * 255.0]).astype(np.uint8)
    Image.fromarray(apagado, 'RGBA').save(f'assets/sprites/{salida}-apagado.png')
    # el color medio de la luz que da (para neon_galeria.gd)
    lleno = al[..., 0] > 0.5
    medio = color[lleno].mean(axis=0)
    print(f'{salida}: {ancho}x{alto}, luz media {"#%02x%02x%02x" % tuple(int(v) for v in medio)}')


for n in sys.argv[1:] or NEONES:
    pasar(n, *NEONES[n])
