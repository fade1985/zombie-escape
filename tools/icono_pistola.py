# El icono de la pistola: una Beretta 92 vista de lado, con la boca a la derecha, como la de la foto que eligió el dueño
# (24 oct). Lo que la distingue de una pistola cualquiera: la corredera larga con el hueco de arriba, por el que asoma el
# cañón de acero claro, y el cañón saliendo un poco por delante; el martillo atrás, las ranuras de la corredera y un
# puntito rojo; el guardamonte redondo con el gatillo dentro (hueco: se ve el fondo); y la empuñadura grande con las
# cachas negras de rombos, el medallón y los dos tornillos. Negro azulado, algo más claro que el del dibujo de Johnny
# para que se lea sobre los paneles oscuros, con el borde oscuro de un píxel. 32×32. También es el icono de la MP5
# (objetos.gd) hasta que tenga el suyo.
#   py tools/icono_pistola.py   → assets/ui/iconos/pistola.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)          # el de los otros iconos
SOMBRA = (36, 38, 48, 255)         # el negro del arma: sombra, cuerpo, luz y brillo
NEGRO = (58, 62, 74, 255)
LUZ = (92, 100, 116, 255)
BRILLO = (128, 140, 156, 255)
ACERO = (119, 142, 155, 255)       # el cañón, el del dibujo de Johnny
ACERO_CLARO = (196, 212, 222, 255)
CACHA = (26, 26, 34, 255)          # las cachas de rombos
CACHA_LUZ = (40, 42, 53, 255)
TORNILLO = (170, 176, 186, 255)
ROJO = (214, 33, 35, 255)

im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
px = im.load()
X, Y = 2, 1   # todo se pinta corrido esto, para que quede centrado


def rect(x0, y0, x1, y1, col):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x + X, y + Y] = col


def punto(x, y, col):
    rect(x, y, x, y, col)


def main():
    # la corredera: atrás entera, con la luz arriba; delante, el hueco por el que asoma el cañón
    rect(3, 7, 13, 7, LUZ)
    rect(3, 8, 13, 10, NEGRO)
    rect(14, 9, 26, 10, NEGRO)
    rect(14, 9, 24, 9, LUZ)
    rect(25, 8, 26, 8, LUZ)
    punto(25, 7, NEGRO)                    # el punto de mira
    rect(3, 11, 26, 11, SOMBRA)
    for x in (4, 6, 8):                    # las ranuras de atrás
        rect(x, 8, x, 10, SOMBRA)
    punto(11, 9, ROJO)
    for x in (15, 17, 19, 21):             # las letras grabadas
        punto(x, 10, LUZ)
    # el cañón: asoma por el hueco y sale un poco por delante
    rect(14, 8, 24, 8, ACERO)
    rect(16, 8, 20, 8, ACERO_CLARO)
    rect(27, 9, 27, 10, ACERO)
    punto(27, 9, ACERO_CLARO)
    # el martillo y el alza
    rect(2, 5, 3, 6, NEGRO)
    punto(2, 5, LUZ)
    punto(6, 6, NEGRO)
    # el armazón bajo la corredera, con la palanca de desmontar
    rect(4, 12, 24, 12, NEGRO)
    rect(14, 12, 16, 12, BRILLO)
    rect(4, 13, 23, 13, NEGRO)
    rect(19, 13, 23, 13, SOMBRA)
    # el guardamonte redondo y el gatillo dentro
    for x, y in ((20, 14), (20, 15), (19, 16), (18, 17)):
        punto(x, y, NEGRO)
    rect(11, 18, 17, 18, SOMBRA)
    for x, y in ((13, 14), (13, 15), (14, 16), (15, 16)):
        punto(x, y, LUZ)
    # la empuñadura, bien inclinada hacia atrás: el borde de metal y las cachas de rombos dentro
    filas = {14: (5, 11), 15: (5, 11), 16: (4, 11), 17: (4, 10), 18: (3, 10), 19: (3, 9), 20: (2, 9), 21: (2, 8),
             22: (1, 8), 23: (1, 7), 24: (0, 7), 25: (0, 7), 26: (0, 7)}
    for y, (a, b) in filas.items():
        rect(a, y, b, y, NEGRO)
        punto(a, y, LUZ)
        if 15 <= y <= 25:
            for x in range(a + 1, b):
                punto(x, y, CACHA_LUZ if (x + y) % 2 else CACHA)
    rect(4, 19, 5, 20, LUZ)                # el medallón
    punto(4, 19, BRILLO)
    punto(8, 16, TORNILLO)
    punto(3, 24, TORNILLO)
    # el pie del cargador
    rect(0, 27, 7, 27, LUZ)
    rect(1, 27, 3, 27, BRILLO)
    # el borde oscuro, solo por fuera: el hueco del guardamonte se queda vacío y se ve el fondo
    fuera, pila = set(), [(0, 0)]
    while pila:
        x, y = pila.pop()
        if (x, y) in fuera or not (0 <= x < 32 and 0 <= y < 32) or px[x, y][3]:
            continue
        fuera.add((x, y))
        pila += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    for x, y in fuera:
        if any(0 <= x + dx < 32 and 0 <= y + dy < 32 and px[x + dx, y + dy][3] and px[x + dx, y + dy] != BORDE
               for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0))):
            px[x, y] = BORDE
    salida = ICONOS / "pistola.png"
    im.save(salida)
    print(salida)


main()
