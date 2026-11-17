# Los tres neones de la pared de la galería del centro comercial (17 nov): un casete, un radiocasete y un tocadiscos, de
# tres imágenes de GPT (assets/sources/galeria/neon-<nombre>-gpt.webp: tubos cian y magenta sobre negro puro). Se reducen
# «como los muebles» (LANCZOS premultiplicado): el negro pasa a transparente (todo, también el de dentro, para que se vea
# la pared) y se mezclan los colores. Sale cada uno encendido (neon-<nombre>.png) y apagado (neon-<nombre>-apagado.png:
# el tubo de cristal sin luz, gris violáceo, para cuando falla). Los pinta neon_galeria.gd.
#   py tools/neones_galeria.py   (y luego Godot --headless --path . --import)
import numpy as np
from PIL import Image

# nombre -> alto en píxeles del dibujo (el ancho, según la proporción)
NEONES = {'casete': 28, 'radiocasete': 32, 'tocadiscos': 28}
TUBO = np.array([77, 71, 84], float)   # el tubo apagado (el mismo que las letras fundidas de neon.gd)


def pasar(nombre, alto):
    a = np.asarray(Image.open(f'assets/sources/galeria/neon-{nombre}-gpt.webp').convert('RGB')).astype(float)
    # transparencia: lo casi negro, nada; desde ahí sube deprisa
    alfa = np.clip((a.max(axis=2) - 24.0) / 70.0, 0.0, 1.0)
    ys, xs = np.nonzero(alfa > 0.5)
    caja = (xs.min() - 2, ys.min() - 2, xs.max() + 3, ys.max() + 3)
    ancho = round(alto * (caja[2] - caja[0]) / (caja[3] - caja[1]))
    # premultiplicado: así el negro de alrededor no ensucia el borde del tubo al mezclar
    pre = np.dstack([a * alfa[..., None], alfa * 255.0]).astype(np.uint8)
    peq = np.asarray(Image.fromarray(pre, 'RGBA').resize((ancho, alto), Image.LANCZOS, box=caja)).astype(float)
    al = peq[..., 3:4] / 255.0
    color = np.where(al > 0.004, peq[..., :3] / np.maximum(al, 0.004), 0.0)
    al = np.where(al < 0.12, 0.0, np.clip(al * 1.15, 0.0, 1.0))   # sin velos casi invisibles alrededor
    encendido = np.dstack([np.clip(color, 0, 255), al * 255.0]).astype(np.uint8)
    Image.fromarray(encendido, 'RGBA').save(f'assets/sprites/neon-{nombre}.png')
    # apagado: el mismo tubo, sin color, con un poco del dibujo (lo claro del centro, algo más claro)
    luz = color.mean(axis=2, keepdims=True) / 255.0
    apagado = np.dstack([np.clip(TUBO * (0.75 + 0.45 * luz), 0, 255), al * 255.0]).astype(np.uint8)
    Image.fromarray(apagado, 'RGBA').save(f'assets/sprites/neon-{nombre}-apagado.png')
    # el color medio de la luz que da (para neon_galeria.gd)
    lleno = al[..., 0] > 0.5
    medio = color[lleno].mean(axis=0)
    print(f'neon-{nombre}: {ancho}x{alto}, luz media {"#%02x%02x%02x" % tuple(int(v) for v in medio)}')


for n, h in NEONES.items():
    pasar(n, h)
