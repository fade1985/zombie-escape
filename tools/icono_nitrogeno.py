# El icono de la bombona de nitrógeno (la munición del lanza hielo, Objetos.NOMBRES.nitrogeno): una bombona de pie, azul
# hielo, con la cúpula de arriba redondeada, la válvula de metal gris con su rueda, una franja azul oscuro con un
# copo de nieve blanco en medio y un poco de escarcha en la base. Con luz de la izquierda (el brillo en la segunda
# columna, la sombra en las dos últimas), el borde oscuro de un píxel de los demás iconos y los azules de las bombonas de
# Johnny con el lanza hielo (tools/hoja_lanza_hielo.py). 32×32.
#   py tools/icono_nitrogeno.py   → assets/ui/iconos/obj-nitrogeno.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)
BLANCO = (255, 255, 255, 255)
CLARO = (236, 250, 255, 255)
HIELO = (198, 236, 252, 255)
MEDIO = (158, 222, 248, 255)
AZUL = (102, 178, 228, 255)
OSCURO = (58, 118, 182, 255)
NOCHE = (34, 62, 112, 255)
FILO = (232, 236, 240, 255)
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)

X0, X1 = 10, 21          # las columnas del cuerpo
ARRIBA, ABAJO = 9, 28    # sus filas
FRANJA = (14, 22)        # la franja oscura (filas)
# el copo de la franja: centro y sus brazos
COPO = (15, 18)


def tono(x, y):
    """El color del cuerpo en (x, y): claro con brillo a la izquierda y sombra a la derecha (la franja, en azules)."""
    en_franja = FRANJA[0] <= y <= FRANJA[1]
    if x == X0:
        return OSCURO if en_franja else MEDIO
    if x == X0 + 1:
        return AZUL if en_franja else CLARO
    if x >= X1 - 1:
        return NOCHE if en_franja else (OSCURO if x == X1 else AZUL)
    if en_franja:
        return NOCHE
    return HIELO if x < X0 + 5 else MEDIO


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    solidos = []

    def pon(x, y, c):
        px[x, y] = c
        solidos.append((x, y))

    # el cuerpo
    for y in range(ARRIBA, ABAJO + 1):
        for x in range(X0, X1 + 1):
            pon(x, y, tono(x, y))
    # la cúpula: dos filas que se van estrechando
    for y, (a, b) in ((ARRIBA - 1, (X0 + 1, X1 - 1)), (ARRIBA - 2, (X0 + 3, X1 - 3))):
        for x in range(a, b + 1):
            pon(x, y, CLARO if x <= a + 1 else (AZUL if x >= b - 1 else HIELO))
    # el pie: una fila más oscura
    for x in range(X0, X1 + 1):
        pon(x, ABAJO, OSCURO if x > X0 + 1 else AZUL)
    # la válvula: el cuello y la rueda de arriba
    for y in (ARRIBA - 3, ARRIBA - 4):
        for x in (14, 15, 16, 17):
            pon(x, y, ACERO if x < 16 else ACERO_OSCURO)
    for x in range(12, 20):
        pon(x, ARRIBA - 5, FILO if x < 16 else ACERO)
    pon(18, ARRIBA - 3, ACERO_OSCURO)
    pon(19, ARRIBA - 3, ACERO)   # la boquilla de un lado
    # el copo de la franja: seis brazos (el de arriba, el de abajo y las cuatro diagonales), sin los de los lados, para
    # que no parezca la cruz de un botiquín
    cx, cy = COPO
    for dx, dy in ((0, 0), (0, 1), (0, -1), (0, 2), (0, -2), (1, 1), (-1, -1), (1, -1), (-1, 1), (2, 2), (-2, -2), (2, -2), (-2, 2)):
        px[cx + dx, cy + dy] = BLANCO if abs(dx) < 2 else MEDIO
    # una raya de brillo en la cúpula
    px[X0 + 2, ARRIBA] = BLANCO
    px[X0 + 2, ARRIBA + 1] = BLANCO
    # el borde oscuro, sin pisar nada pintado
    for x, y in list(solidos):
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    # la escarcha de la base: unos cristalitos blancos y celestes sobre el borde de abajo y los lados
    for x, y, c in ((X0 - 1, ABAJO - 1, CLARO), (X0 - 1, ABAJO - 3, MEDIO), (X1 + 1, ABAJO - 2, CLARO), (X0 + 3, ABAJO + 1, BLANCO),
                    (X0 + 7, ABAJO + 1, MEDIO), (X1 - 1, ABAJO + 1, CLARO), (X1 + 2, ABAJO - 1, MEDIO)):
        px[x, y] = c
    salida = ICONOS / "obj-nitrogeno.png"
    im.save(salida)
    print(salida)


main()
