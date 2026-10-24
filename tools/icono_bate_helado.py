# El icono del bate helado (el arma creada con el bate y el hielo seco): el icono del bate (bate.png) con la punta gorda
# convertida en un racimo de tres cristales de hielo (uno grande en medio y otros dos inclinados a los lados, cada uno
# con su punta, su cara clara a la izquierda y su cara oscura a la derecha), un poco de escarcha en la base y unos
# carámbanos que cuelgan, con copos y vaho sueltos alrededor. Con el borde oscuro de un píxel (el de los demás iconos).
# Nada de naranja ni de celeste eléctrico: se distingue del bate de fuego y de la inmovilizadora. 32×32.
#   py tools/icono_bate_helado.py   → assets/ui/iconos/bate_helado.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # el borde de los demás iconos
SOMBRA = (70, 128, 192, 255)      # los tonos del hielo, del más oscuro al más claro
OSCURO = (108, 172, 224, 255)
HIELO = (156, 212, 244, 255)
CLARO = (208, 238, 255, 255)
BLANCO = (255, 255, 255, 255)
VAHO = (190, 224, 246, 255)

# Los cristales, de atrás hacia delante: (columna del centro en la base, ancho, fila de la punta, fila donde acaba la punta
# y empieza el cuerpo, fila de abajo, cuánto se inclina: columnas que se corre el centro por cada fila que sube; negativo, hacia la izquierda)
CRISTALES = [
    (10.5, 3, 4, 7, 12, -0.40),    # el de la izquierda, inclinado hacia fuera
    (20.5, 3, 3, 7, 12, 0.40),   # el de la derecha
    (15.5, 6, 1, 5, 14, 0.0),     # el grande, de frente, delante de los otros
]
# Escarcha en la base de los cristales: filas y columnas (inclusive)
BASE = {13: (12, 19), 14: (13, 18)}
# Carámbanos que cuelgan por debajo: (columna, fila de arranque, largo)
CARAMBANOS = [(12, 15, 3), (19, 15, 2)]
# Vaho y copos sueltos fuera del bate: (x, y, color)
SUELTOS = [(5, 4, VAHO), (6, 3, VAHO), (5, 2, VAHO), (6, 1, VAHO),
           (26, 6, CLARO), (25, 5, BLANCO), (27, 5, HIELO), (26, 4, BLANCO), (26, 7, HIELO),
           (3, 12, CLARO), (2, 12, HIELO), (3, 11, BLANCO), (3, 13, HIELO), (4, 12, BLANCO),
           (24, 17, VAHO), (25, 18, VAHO), (24, 19, VAHO)]


def cristal(cx, ancho, punta, hombro, fondo, inclina) -> dict:
    """Un cristal: una pirámide sobre un prisma. Cara clara a la izquierda, oscura a la derecha, un brillo blanco arriba."""
    pix = {}
    for y in range(punta, fondo + 1):
        if y < hombro:
            w = max(2, round(ancho * (y - punta + 1) / (hombro - punta + 1)))
        else:
            w = ancho
        c = cx + inclina * (fondo - y)                 # el centro de esta fila
        izq = round(c - w / 2 + 0.5)
        for k in range(w):
            x = izq + k
            u = k / max(w - 1, 1)
            if y == fondo:
                col = SOMBRA
            elif u < 0.34:
                col = CLARO
            elif u < 0.67:
                col = HIELO
            else:
                col = OSCURO
            pix[(x, y)] = col
        if y == punta + 1 or y == punta + 2:           # el brillo de la cara clara
            pix[(izq, y)] = BLANCO
    return pix


def con_borde(im: Image.Image, pix: dict) -> None:
    """Pinta el borde oscuro de un píxel alrededor de `pix` y luego `pix` encima."""
    px = im.load()
    for (x, y) in pix:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            n = (x + dx, y + dy)
            if n not in pix and 0 <= n[0] < 32 and 0 <= n[1] < 32:
                px[n] = BORDE
    for (x, y), c in pix.items():
        if 0 <= x < 32 and 0 <= y < 32:
            px[x, y] = c


def main():
    im = Image.open(ICONOS / "bate.png").convert("RGBA")
    px = im.load()
    for y in range(0, 12):                        # fuera la punta de madera: se tapa con el hielo
        for x in range(32):
            px[x, y] = (0, 0, 0, 0)
    for args in CRISTALES:
        con_borde(im, cristal(*args))
    base = {}
    for y, (a, b) in BASE.items():
        for x in range(a, b + 1):
            base[(x, y)] = OSCURO if (x - a) * 2 > (b - a) else HIELO
    for x, y, largo in CARAMBANOS:
        for k in range(largo):
            base[(x, y + k)] = BLANCO if k == largo - 1 else CLARO
    con_borde(im, base)
    for x, y, c in SUELTOS:
        if px[x, y][3] == 0:
            px[x, y] = c
    salida = ICONOS / "bate_helado.png"
    im.save(salida)
    print(salida)


main()
