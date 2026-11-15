# El icono del lanza hielo: el del lanza ácido (tools/icono_desintegrador.py, que sale del del lanzallamas) con el depósito
# en azul hielo y, en vez de las gotas de ácido, una bocanada de vaho helado delante de la boquilla y un copo de nieve.
# Con el borde oscuro de un píxel y los azules de las bombonas de Johnny con el lanza hielo. 32×32.
#   py tools/icono_lanza_hielo.py   → assets/ui/iconos/lanza_hielo.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
FILO = (232, 236, 240, 255)       # lo más claro del metal
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)
CABLE = (74, 76, 90, 255)         # la manguera negra: un gris azulado oscuro con un reflejo más claro
CABLE_CLARO = (122, 126, 142, 255)
VERDE = (158, 222, 248, 255)      # el depósito: el azul hielo de las bombonas de Johnny (tools/hoja_lanza_hielo.py)
VERDE_OSCURO = (58, 118, 182, 255)
VERDE_CLARO = (236, 250, 255, 255)
BLANCO = (255, 255, 255, 255)

# El depósito: columnas y filas del cuerpo (los dos extremos incluidos); la fila de arriba es la tapa, más oscura
CUERPO = (5, 14, 16, 29)
# La válvula, sobre la tapa: el cuello (columnas 8 a 11, filas 13 y 14) y la rueda de arriba (columnas 7 a 12, fila 12)
CUELLO = (8, 11, 13, 14)
RUEDA = (7, 12, 12, 12)
# El tubo, de la válvula a la punta (dos píxeles de ancho: de arriba abajo, el claro y el oscuro), y su boquilla (la punta, más gruesa)
TUBO = [(11, 13), (26, 6)]
BOQUILLA = [(24, 6), (26, 6)]
# La empuñadura negra bajo el tubo: de (19, 11) a (19, 17)
EMPUNADURA = ((19, 12), (19, 18))
# Por dónde pasa la manguera, del lado del depósito a la empuñadura
MANGUERA = [(15, 25), (18, 27), (22, 26), (24, 22), (22, 19), (20, 18)]
# Las gotas de ácido, bajo la boca de la boquilla: la que cuelga (el cuello pegado a la boca y la gota redonda, con su brillo
# arriba a la izquierda y su sombra abajo a la derecha) y la que cae, más abajo: (x, y, color)
# En vez de las gotas: una bocanada de vaho helado delante de la boquilla (claro arriba, azul abajo) y un copo de nieve en
# cruz más allá: (x, y, color)
GOTAS = [(27, 5, VERDE_CLARO), (28, 5, BLANCO), (28, 4, VERDE_CLARO),
         (27, 6, VERDE), (28, 6, VERDE_CLARO), (29, 6, BLANCO), (29, 5, VERDE_CLARO),
         (28, 7, VERDE), (29, 7, VERDE), (30, 7, VERDE_CLARO), (30, 6, VERDE_CLARO),
         (29, 8, VERDE_OSCURO), (30, 8, VERDE),
         (27, 13, BLANCO), (26, 14, VERDE_CLARO), (27, 14, BLANCO), (28, 14, VERDE_CLARO), (27, 15, BLANCO),
         (25, 13, VERDE), (29, 13, VERDE), (25, 15, VERDE), (29, 15, VERDE)]


def linea(a, b):
    """Los píxeles de una línea recta de a a b (los dos incluidos)."""
    n = max(abs(b[0] - a[0]), abs(b[1] - a[1]))
    return [(round(a[0] + (b[0] - a[0]) * i / n), round(a[1] + (b[1] - a[1]) * i / n)) for i in range(n + 1)] if n else [a]


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    solidos = []
    # el depósito, con un reflejo claro en la columna de la izquierda y sombra en la de la derecha
    x0, x1, y0, y1 = CUERPO
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            c = VERDE
            if y == y0:
                c = VERDE_OSCURO
            elif x == x0 + 1:
                c = VERDE_CLARO
            elif x >= x1 - 1:
                c = VERDE_OSCURO
            px[x, y] = c
            solidos.append((x, y))
    # una franja oscura en el medio, como el aro de un extintor
    for x in range(x0, x1 + 1):
        px[x, 22] = VERDE_OSCURO
    # la válvula
    a, b, c, d = CUELLO
    for y in range(c, d + 1):
        for x in range(a, b + 1):
            px[x, y] = ACERO_OSCURO if x > a else ACERO
            solidos.append((x, y))
    a, b, c, d = RUEDA
    for x in range(a, b + 1):
        px[x, c] = FILO if x < b else ACERO
        solidos.append((x, c))
    # el tubo: dos píxeles de ancho, el de arriba claro y el de abajo oscuro
    for x, y in linea(*TUBO):
        px[x, y] = ACERO
        px[x, y + 1] = ACERO_OSCURO
        solidos += [(x, y), (x, y + 1)]
    for x, y in linea(*BOQUILLA):
        px[x, y] = ACERO_OSCURO
        px[x, y + 1] = CABLE
        px[x, y - 1] = ACERO
        solidos += [(x, y), (x, y + 1), (x, y - 1)]
    # la empuñadura, más gorda, con una franja clara
    for n, (x, y) in enumerate(linea(*EMPUNADURA)):
        for dx in (0, 1):
            px[x + dx, y] = CABLE_CLARO if (dx == 0 and n % 2 == 0) else CABLE
            solidos.append((x + dx, y))
    # la manguera: dos píxeles de ancho, de punto en punto
    camino = []
    for p, q in zip(MANGUERA, MANGUERA[1:]):
        camino += linea(p, q)
    for n, (x, y) in enumerate(camino):
        px[x, y] = CABLE
        px[x, y + 1] = CABLE_CLARO if n % 3 == 0 else CABLE
        solidos += [(x, y), (x, y + 1)]
    # las gotas (con su borde, como lo demás)
    for x, y, c in GOTAS:
        px[x, y] = c
        solidos.append((x, y))
    # el borde oscuro, sin pisar nada pintado
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    salida = ICONOS / "lanza_hielo.png"
    im.save(salida)
    print(salida)


main()
