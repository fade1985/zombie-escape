# El icono de la pistola eléctrica (el arma creada con la pistola de agua y la batería): un táser compacto visto de lado, con el
# cuerpo azul marino, una batería gris con un borne rojo y otro gris (y un rayito amarillo) pegada debajo, y dos electrodos
# metálicos en la boca con un arco celeste saltando entre ellos. Se distingue de la pistola de agua (el desintegrador: gris con el
# depósito verde) y de la batería suelta (el icono de antes). Con el borde oscuro de un píxel (menos en las chispas) y los colores
# del dibujo de Johnny con la pistola eléctrica. 32×32.
#   py tools/icono_pistola_electrica.py   → assets/ui/iconos/pistola_electrica.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)          # los de los otros iconos
AZUL = (39, 48, 74, 255)           # el cuerpo del táser
AZUL_CLARO = (66, 84, 122, 255)
AZUL_OSCURO = (22, 28, 46, 255)
GRIS = (143, 142, 152, 255)        # la batería
GRIS_CLARO = (196, 194, 204, 255)
GRIS_SOMBRA = (92, 90, 102, 255)
ROJO = (214, 33, 35, 255)          # el borne
ROJO_CLARO = (246, 110, 96, 255)
AMARILLO = (246, 196, 39, 255)     # el rayito de la batería
METAL = (170, 184, 200, 255)       # los electrodos
METAL_CLARO = (232, 240, 248, 255)
METAL_SOMBRA = (110, 124, 142, 255)
CELESTE = (159, 232, 255, 255)     # las chispas
CELESTE_VIVO = (84, 196, 240, 255)
NUCLEO = (232, 251, 255, 255)

im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
px = im.load()
solidos = []


def rect(x0, y0, x1, y1, col, borde=True):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = col
            if borde:
                solidos.append((x, y))


def punto(x, y, col, borde=True):
    rect(x, y, x, y, col, borde)


def main():
    # el cuerpo (la corredera): luz arriba, sombra abajo, y unas ranuras
    rect(5, 8, 21, 8, AZUL_CLARO)
    rect(4, 9, 22, 12, AZUL)
    rect(4, 9, 22, 9, AZUL_CLARO)
    rect(4, 13, 22, 14, AZUL_OSCURO)
    for x in (8, 9, 10, 13, 14, 15):
        punto(x, 11, AZUL_OSCURO)
    # el soporte de los electrodos, en el morro
    rect(23, 11, 24, 12, AZUL_OSCURO)
    # los dos electrodos: dos púas metálicas, con la punta más clara
    rect(23, 9, 27, 10, METAL)
    rect(23, 10, 27, 10, METAL_SOMBRA)
    punto(27, 9, METAL_CLARO)
    rect(23, 13, 27, 14, METAL)
    rect(23, 14, 27, 14, METAL_SOMBRA)
    punto(27, 13, METAL_CLARO)
    # la empuñadura, un poco inclinada hacia atrás, con luz a la izquierda y sombra a la derecha
    for y, (a, b) in zip(range(15, 25), [(5, 10), (5, 10), (4, 9), (4, 9), (4, 9), (3, 8), (3, 8), (3, 8), (3, 8), (3, 8)]):
        rect(a, y, b, y, AZUL)
        punto(a, y, AZUL_CLARO)
        punto(b, y, AZUL_OSCURO)
    rect(3, 24, 8, 24, AZUL_OSCURO)
    for y in (18, 20, 22):
        for x in range(5 if y < 20 else 4, 9 if y < 20 else 8):
            if 4 <= x <= 8:
                punto(x, y, AZUL_OSCURO)
    # el guardamonte
    rect(11, 15, 11, 18, AZUL_OSCURO)
    punto(12, 18, AZUL_OSCURO)
    # la batería pegada debajo del cañón, con los dos bornes asomando por arriba y un rayito amarillo
    rect(12, 15, 21, 15, AZUL_OSCURO)
    rect(13, 15, 14, 15, ROJO)
    punto(13, 15, ROJO_CLARO)
    rect(19, 15, 20, 15, GRIS_CLARO)
    rect(13, 16, 21, 20, GRIS)
    rect(13, 16, 21, 16, GRIS_CLARO)
    rect(13, 20, 21, 20, GRIS_SOMBRA)
    rect(21, 16, 21, 20, GRIS_SOMBRA)
    for x, y in ((17, 17), (16, 18), (17, 18), (16, 19)):
        punto(x, y, AMARILLO)
    # el borde oscuro, sin pisar nada pintado
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    # el arco entre las dos puntas, en zigzag, y unas chispas sueltas (sin borde: son luz)
    for x, y, col in ((28, 9, CELESTE), (29, 10, CELESTE_VIVO), (28, 11, NUCLEO), (29, 12, CELESTE_VIVO), (28, 13, CELESTE),
                      (29, 11, CELESTE), (28, 10, NUCLEO), (28, 12, NUCLEO),
                      (30, 8, CELESTE), (31, 11, CELESTE_VIVO), (30, 14, CELESTE), (26, 7, CELESTE_VIVO), (27, 15, CELESTE_VIVO)):
        if px[x, y][3] == 0 or px[x, y] == BORDE:
            px[x, y] = col
    salida = ICONOS / "pistola_electrica.png"
    im.save(salida)
    print(salida)


main()
