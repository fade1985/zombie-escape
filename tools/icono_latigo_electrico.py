# El icono del látigo eléctrico (el arma creada con el cable y la batería): una batería de coche gris abajo a la derecha, con
# dos bornes (uno rojo y otro gris), de los que sale un cable negro que sube en un bucle por la izquierda hasta un mango de
# goma, y unos rayos celestes y blancos que saltan del otro borne. Se distingue del látigo escorpión (cuerda trenzada color
# arena con un aguijón) por la batería y el cable negro. Con el borde oscuro de un píxel y los grises del icono de los clavos
# y los celestes de la descarga de la inmovilizadora. 32×32.
#   py tools/icono_latigo_electrico.py   → assets/ui/iconos/latigo_electrico.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
FILO = (232, 236, 240, 255)       # lo más claro del metal
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)
CABLE = (74, 76, 90, 255)         # el cable negro: un gris azulado oscuro con un reflejo más claro
CABLE_CLARO = (122, 126, 142, 255)
ROJO = (214, 64, 64, 255)         # el borne positivo
ROJO_OSCURO = (150, 40, 44, 255)
CELESTE = (159, 232, 255, 255)    # el color de las chispas de la descarga (#9fe8ff)
CELESTE_OSCURO = (52, 160, 224, 255)
BLANCO = (255, 255, 255, 255)

# La batería: columnas y filas del cuerpo (los dos extremos incluidos); la fila de arriba es la tapa, más clara
CUERPO = (12, 28, 21, 29)
# Los bornes, sobre la tapa: (columna, color de la punta, color del cuerpo)
BORNES = [(15, ROJO, ROJO_OSCURO), (24, FILO, ACERO)]
# Por dónde pasa el cable, del borne rojo hacia arriba y a la izquierda, en bucle, hasta el mango
CABLE_PUNTOS = [(15, 18), (15, 14), (13, 9), (9, 6), (5, 7), (3, 11), (4, 16), (7, 20)]
# El mango de goma al final del cable: de (7, 20) a (4, 26)
MANGO = ((7, 21), (3, 27))
# Los rayos celestes que saltan del borne gris: un zigzag de dos píxeles de ancho (el celeste, con el centro blanco) y unas
# chispas sueltas alrededor: (x, y, color)
ZIGZAG = [(25, 18), (24, 16), (26, 14), (24, 12), (26, 10), (24, 8), (26, 6)]
CHISPAS = [(22, 11, CELESTE_OSCURO), (28, 9, CELESTE_OSCURO), (28, 14, CELESTE), (21, 15, CELESTE_OSCURO), (27, 3, CELESTE_OSCURO),
           (23, 5, CELESTE)]
# El rayito de la etiqueta de la batería: (x, y)
ETIQUETA = [(22, 23), (23, 23), (21, 24), (22, 24), (20, 25), (21, 25), (22, 25), (23, 25), (22, 26), (21, 26), (21, 27), (20, 28)]


def linea(a, b):
    """Los píxeles de una línea recta de a a b (los dos incluidos)."""
    n = max(abs(b[0] - a[0]), abs(b[1] - a[1]))
    return [(round(a[0] + (b[0] - a[0]) * i / n), round(a[1] + (b[1] - a[1]) * i / n)) for i in range(n + 1)] if n else [a]


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    solidos = []
    # la batería
    x0, x1, y0, y1 = CUERPO
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = ACERO if y == y0 else ACERO_OSCURO
            solidos.append((x, y))
    # un rayito en el cuerpo, como la etiqueta de las baterías
    for x, y in ETIQUETA:
        px[x, y] = CELESTE
    # los bornes, dos píxeles de alto sobre la tapa
    for cx, punta, cuerpo in BORNES:
        for dx in (0, 1):
            px[cx + dx, y0 - 1] = punta
            px[cx + dx, y0 - 2] = cuerpo if punta != FILO else FILO
            solidos += [(cx + dx, y0 - 1), (cx + dx, y0 - 2)]
        px[cx + 1, y0 - 2] = punta
    # el cable: dos píxeles de ancho (uno oscuro, otro claro), de punto en punto
    camino = []
    for a, b in zip(CABLE_PUNTOS, CABLE_PUNTOS[1:]):
        camino += linea(a, b)
    for n, (x, y) in enumerate(camino):
        px[x, y] = CABLE
        px[x + 1, y] = CABLE_CLARO if n % 3 == 0 else CABLE
        solidos += [(x, y), (x + 1, y)]
    # el mango de goma, más gordo, con una franja clara
    for n, (x, y) in enumerate(linea(*MANGO)):
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1)):
            px[x + dx, y + dy] = CABLE
            solidos.append((x + dx, y + dy))
        px[x, y] = CABLE_CLARO if n % 2 == 0 else CABLE
    # el borde oscuro, sin pisar nada pintado
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    # los rayos, por encima del borde
    for a, b in zip(ZIGZAG, ZIGZAG[1:]):
        for x, y in linea(a, b):
            px[x, y] = CELESTE
            px[x + 1, y] = CELESTE
    for x, y in ZIGZAG[1:-1]:
        px[x, y] = BLANCO
    for x, y, c in CHISPAS:
        px[x, y] = c
    salida = ICONOS / "latigo_electrico.png"
    im.save(salida)
    print(salida)


main()
