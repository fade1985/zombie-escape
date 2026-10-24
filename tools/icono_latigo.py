# El icono del látigo escorpión (el arma creada con la cuerda y el cuchillo): un látigo con el asa de madera abajo a la
# izquierda, la cuerda trenzada enrollada en dos vueltas y la cola de la cuerda subiendo hacia arriba a la derecha hasta
# un aguijón de acero curvo, como el de un escorpión, con gotas verdes de veneno. Con el borde oscuro de un píxel y los
# colores de los iconos del bate (la madera) y de los clavos (el acero). 32×32.
#   py tools/icono_latigo.py   → assets/ui/iconos/latigo.png
import math
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
MADERA = (199, 121, 67, 255)      # la madera del bate
MADERA_CLARA = (215, 129, 64, 255)
MADERA_OSCURA = (150, 85, 45, 255)
CUERDA = (226, 188, 120, 255)     # la cuerda trenzada: dos arena que se alternan
CUERDA_OSCURA = (178, 132, 76, 255)
FILO = (232, 236, 240, 255)       # el acero del aguijón, como el de los clavos
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)
VENENO = (155, 229, 100, 255)     # el verde del arma (#9be564)
VENENO_OSCURO = (86, 168, 62, 255)

CENTRO = (13.0, 17.0)             # el centro de las vueltas de la cuerda
VUELTAS = [(8.5, 7.0), (4.8, 3.6)]   # radios (ancho, alto) de cada vuelta
# La cola de la cuerda: por dónde pasa (de la primera vuelta hacia el aguijón)
COLA = [(20.0, 15.0), (22.5, 11.5), (22.5, 8.0), (24.0, 5.5)]
# El aguijón: un gancho de acero curvo hacia dentro, con la punta hacia abajo a la izquierda: (x, y, color)
AGUIJON = [(24, 5, ACERO), (25, 4, ACERO), (26, 3, FILO), (27, 3, FILO), (28, 4, FILO), (28, 5, ACERO), (28, 6, ACERO),
           (27, 7, FILO), (23, 6, ACERO_OSCURO), (24, 6, ACERO)]
# El asa: de la esquina de abajo a la izquierda hacia el centro de las vueltas
ASA = ((3, 27), (9, 21))
# Gotas de veneno que caen de la punta del aguijón: (x, y, color)
GOTAS = [(27, 9, VENENO), (27, 11, VENENO_OSCURO), (29, 8, VENENO), (26, 13, VENENO)]


def trenzada(px, puntos):
    """Pinta una línea de cuerda de dos píxeles de ancho por los puntos dados, alternando los dos colores."""
    for n, (x, y) in enumerate(puntos):
        c = CUERDA if (n // 2) % 2 == 0 else CUERDA_OSCURA
        for dx, dy in ((0, 0), (1, 0), (0, 1)):
            px[int(x) + dx, int(y) + dy] = c


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    cx, cy = CENTRO
    # las vueltas: dos óvalos, la de dentro abierta por arriba a la derecha (por ahí sale la cola)
    for k, (rx, ry) in enumerate(VUELTAS):
        puntos = []
        for i in range(0, 360, 4):
            a = math.radians(i)
            if k == 1 and 300 < i < 360:
                continue
            p = (round(cx + rx * math.cos(a)), round(cy + ry * math.sin(a)))
            if not puntos or puntos[-1] != p:
                puntos.append(p)
        trenzada(px, puntos)
    # la cola: de la vuelta de fuera al aguijón
    cola = []
    a = (cx + VUELTAS[0][0], cy)
    for b in COLA:
        for t in range(0, 11):
            cola.append((round(a[0] + (b[0] - a[0]) * t / 10), round(a[1] + (b[1] - a[1]) * t / 10)))
        a = b
    trenzada(px, cola)
    # el asa de madera, de tres píxeles de ancho, con un remate oscuro en el extremo
    (x0, y0), (x1, y1) = ASA
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n)
        y = round(y0 + (y1 - y0) * i / n)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1)):
            px[x + dx, y + dy] = MADERA
        px[x, y] = MADERA_CLARA
        px[x + 1, y + 1] = MADERA_OSCURA
    for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, 1)):
        px[x0 + dx, y0 + dy] = MADERA_OSCURA
    # el aguijón
    for x, y, c in AGUIJON:
        px[x, y] = c
    # el borde oscuro, sin pisar nada pintado
    solidos = [(x, y) for y in range(32) for x in range(32) if px[x, y][3]]
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    # el veneno, por encima del borde
    for x, y, c in GOTAS:
        px[x, y] = c
    salida = ICONOS / "latigo.png"
    im.save(salida)
    print(salida)


main()
