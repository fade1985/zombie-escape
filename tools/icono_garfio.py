# El icono del garfio (el arma creada con la cuerda y las perchas): un gancho de acero gris hecho de perchas, como un ancla pequeña
# (una anilla arriba, el mango recto y tres uñas: dos curvadas hacia arriba a los lados y una recta abajo), atado con una cuerda
# trenzada color paja que baja hasta un rollo enrollado en la esquina. Se distingue del icono de las perchas y de la cuerda sueltas
# (los de antes) y del de los demás ganchos y armas. Con el borde oscuro de un píxel y los colores del dibujo de Johnny con el garfio
# (el acero #a3b8c7 y la paja del rollo). 32×32.
#   py tools/icono_garfio.py   → assets/ui/iconos/garfio.png
import math
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los de los otros iconos
ACERO = (163, 184, 199, 255)      # el acero del dibujo de Johnny
ACERO_CLARO = (206, 220, 230, 255)
ACERO_SOMBRA = (118, 138, 156, 255)
PAJA = (216, 178, 90, 255)        # la cuerda
PAJA_CLARA = (240, 214, 150, 255)
PAJA_SOMBRA = (152, 117, 78, 255)
PAJA_OSCURA = (138, 76, 36, 255)

im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
px = im.load()
metal = set()     # píxeles del gancho (para sombrearlos)
cuerda = set()
solidos = set()


def punto(x, y, grupo):
    if 0 <= x < 32 and 0 <= y < 32:
        grupo.add((x, y))
        solidos.add((x, y))


def disco(cx, cy, r, grupo):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                punto(x, y, grupo)


def arco(cx, cy, radio, a0, a1, grosor, grupo):
    """Un arco de circunferencia (ángulos en grados, y hacia abajo)."""
    pasos = 60
    for i in range(pasos + 1):
        a = math.radians(a0 + (a1 - a0) * i / pasos)
        disco(cx + radio * math.cos(a), cy + radio * math.sin(a), grosor / 2, grupo)


def linea(p0, p1, grosor, grupo):
    n = int(max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1])) * 2) + 1
    for i in range(n + 1):
        t = i / n
        disco(p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t, grosor / 2, grupo)


def main():
    cx = 11.0
    # la anilla de arriba, donde va atada la cuerda
    arco(cx, 4.5, 2.4, 0, 360, 1.3, metal)
    # el mango recto y la uña de abajo, que acaba en punta
    linea((cx, 7.0), (cx, 22.0), 2.8, metal)
    linea((cx, 22.0), (cx, 25.5), 1.8, metal)
    # las dos uñas curvadas hacia arriba, como un ancla
    arco(cx, 16.0, 7.2, 92, 200, 2.4, metal)
    arco(cx, 16.0, 7.2, -20, 88, 2.4, metal)
    # la cuerda: sale de la anilla, baja por la derecha y acaba en el rollo
    p0, p1, p2 = (13.5, 4.0), (28.0, 1.0), (28.5, 18.0)
    for i in range(61):
        t = i / 60
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        disco(x, y, 0.9, cuerda)
    # el rollo: dos vueltas de cuerda una dentro de otra
    rx, ry = 25.5, 24.5
    arco(rx, ry, 5.0, 0, 360, 1.7, cuerda)
    arco(rx, ry, 2.7, 0, 360, 1.5, cuerda)
    # colores del acero: luz arriba/izquierda, sombra abajo/derecha
    for (x, y) in metal:
        arriba = (x, y - 1) not in metal
        izq = (x - 1, y) not in metal
        abajo = (x, y + 1) not in metal
        der = (x + 1, y) not in metal
        px[x, y] = ACERO_CLARO if (arriba or izq) and not (abajo and der) else ACERO_SOMBRA if (abajo or der) else ACERO
    # la cuerda: paja con trenzado (una raya clara y otra oscura alternas) y sombra abajo/derecha
    for (x, y) in cuerda:
        if (x, y) in metal:
            continue
        if (x, y + 1) not in cuerda and (x, y + 1) not in metal:
            col = PAJA_SOMBRA
        elif (x + y) % 3 == 0:
            col = PAJA_CLARA
        elif (x + y) % 3 == 1:
            col = PAJA
        else:
            col = PAJA_SOMBRA if (x - y) % 2 else PAJA
        px[x, y] = col
    # el borde oscuro de un píxel, sin pisar nada pintado
    for x, y in list(solidos):
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    salida = ICONOS / "garfio.png"
    im.save(salida)
    print(salida)


main()
