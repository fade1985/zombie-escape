# El icono de la inmovilizadora (el arma creada con el táser y el bate): el icono del bate (bate.png) con una caja de
# metal gris atada a la punta gorda, con dos púas a cada lado (los electrodos) y chispazos celestes y blancos que saltan
# entre ellas, unas chispas sueltas por encima y un cable fino que cuelga por el lado del bate. Con el borde oscuro de
# un píxel y los grises del icono de los clavos. 32×32.
#   py tools/icono_inmovilizadora.py   → assets/ui/iconos/inmovilizadora.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
FILO = (232, 236, 240, 255)       # lo más claro del metal: la fila de arriba de la caja y la punta de las púas
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)
CELESTE = (159, 232, 255, 255)    # el color de las chispas de la descarga (#9fe8ff)
CELESTE_OSCURO = (52, 160, 224, 255)
BLANCO = (255, 255, 255, 255)

# La caja del táser, sobre la punta gorda del bate: columnas y filas (los dos extremos incluidos)
CAJA = (11, 19, 3, 8)
# Las púas de cada lado salen por la fila de arriba y la de abajo de la caja, tres píxeles hacia fuera
PUAS = (3, 8)
# Las chispas que saltan entre las dos púas de cada lado: (cuántos píxeles hacia fuera de la punta de las púas, fila, color)
ARCO = [(0, 4, CELESTE), (1, 5, BLANCO), (0, 6, CELESTE), (1, 7, BLANCO)]
EXTRAS = [(2, 5, CELESTE_OSCURO), (2, 7, CELESTE_OSCURO)]      # chispas sueltas a los lados
# Chispas por encima de la punta del bate: (x, y, color)
ARRIBA = [(11, 0, CELESTE), (12, 1, CELESTE), (13, 0, BLANCO), (17, 0, BLANCO), (18, 1, CELESTE), (19, 0, CELESTE)]
# El cable que cuelga: (x, y), un píxel de ancho, por la izquierda del bate
CABLE = [(11, 9), (10, 10), (10, 11), (10, 12), (11, 13), (11, 14), (10, 15), (10, 16), (11, 17), (11, 18)]


def main():
    im = Image.open(ICONOS / "bate.png").convert("RGBA")
    px = im.load()
    solidos = []
    x0, x1, y0, y1 = CAJA
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            c = FILO if y == y0 else (ACERO if y < y1 - 1 else ACERO_OSCURO)
            if x == x1 and y != y0:
                c = ACERO_OSCURO
            px[x, y] = c
            solidos.append((x, y))
    px[15, 5] = CELESTE                      # la lucecita de la caja
    # las púas: a la izquierda, de la caja hacia fuera (la punta, clara, a 3 píxeles del borde); a la derecha, igual
    for fila in PUAS:
        for k in range(1, 4):
            for x in (x0 - k, x1 + k):
                px[x, fila] = FILO if k == 3 else ACERO
                solidos.append((x, fila))
    # el borde de las púas y de la caja, sin pisar nada pintado
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < 32 and 0 <= n[1] < 32 and px[n][3] == 0:
                px[n] = BORDE
    # las chispas entre las púas (por encima del borde) y las de arriba
    for lado, punta in ((-1, x0 - 3), (1, x1 + 3)):
        for fuera, y, c in ARCO + EXTRAS:
            px[punta + lado * fuera, y] = c
    for x, y, c in ARRIBA:
        px[x, y] = c
    for x, y in CABLE:
        px[x, y] = ACERO_OSCURO
    salida = ICONOS / "inmovilizadora.png"
    im.save(salida)
    print(salida)


main()
