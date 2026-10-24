# El icono del desintegrador (el arma creada con la pistola de agua y la lejía): una pistola de agua de plástico gris claro que apunta
# a la derecha, con un depósito redondo de ácido verde lima encima (con su reflejo y su sombra), una boquilla ancha y blanca en la
# punta, la empuñadura oscura abajo y un chorrito fino de ácido verde pálido que sale de la boca. Se distingue de la pistola (negra y
# corta), del lanzallamas (depósito rojo, tubo largo y llamita) y del supersoplete (bombona amarilla, cañón corto y una llamarada
# ancha) por el depósito verde y la boquilla blanca. Con el borde oscuro de un píxel, los grises del icono de los clavos y los verdes
# del dibujo de Johnny con el desintegrador (el depósito #c7e04a y el chorro verde pálido). 32×32.
#   py tools/icono_desintegrador.py   → assets/ui/iconos/desintegrador.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
PLASTICO = (200, 204, 210, 255)   # el cuerpo de la pistola: plástico gris claro
PLASTICO_CLARO = (232, 236, 240, 255)
PLASTICO_SOMBRA = (150, 156, 166, 255)
PLASTICO_OSCURO = (100, 106, 118, 255)
EMPUNADURA = (74, 76, 90, 255)    # la empuñadura: un gris azulado oscuro con un reflejo más claro
EMPUNADURA_CLARA = (122, 126, 142, 255)
BLANCO = (240, 246, 240, 255)     # la boquilla
BLANCO_SOMBRA = (184, 196, 192, 255)
LIMA = (199, 224, 74, 255)        # el depósito: el verde de la receta (#c7e04a)
LIMA_CLARO = (236, 250, 150, 255)
LIMA_OSCURO = (130, 168, 40, 255)
LIMA_SOMBRA = (84, 118, 32, 255)
CHORRO = (167, 240, 136, 255)     # el chorro del dibujo de Johnny
CHORRO_CLARO = (230, 252, 230, 255)

# El depósito: un círculo de este radio, centrado aquí
DEPOSITO = (12.0, 9.0, 5.6)
# El cuerpo de la pistola: columnas y filas (los dos extremos incluidos)
CUERPO = (4, 22, 15, 19)
# La boquilla: de la columna 23 a la 27, el medio alto de cada columna (el eje está en la fila 17)
BOQUILLA_X0 = 23
BOQUILLA = [2, 2, 3, 3, 4]
EJE = 17


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    solidos = []

    def pinta(x, y, c):
        px[x, y] = c
        solidos.append((x, y))

    # la empuñadura, algo inclinada hacia atrás, con una franja clara
    for y in range(20, 28):
        x0 = 8 - (y - 20) // 3
        for x in range(x0, x0 + 4):
            pinta(x, y, EMPUNADURA_CLARA if (x == x0 and y % 2 == 0) else EMPUNADURA)
    # el guardamonte: un arquito debajo del cuerpo, delante de la empuñadura
    for x, y in ((13, 20), (14, 20), (14, 21), (13, 22), (12, 22)):
        pinta(x, y, PLASTICO_OSCURO)
    # el cuello del depósito: un cuellito gris entre el depósito y el cuerpo
    for y in (14, 15):
        for x in (10, 11, 12, 13):
            pinta(x, y, PLASTICO_SOMBRA if x > 10 else PLASTICO)
    # el cuerpo: arriba claro, en medio plástico, abajo con sombra; las esquinas de atrás, redondeadas
    a, b, c, d = CUERPO
    for y in range(c, d + 1):
        for x in range(a, b + 1):
            if x == a and y in (c, d):
                continue
            col = PLASTICO
            if y == c:
                col = PLASTICO_CLARO
            elif y == d:
                col = PLASTICO_OSCURO
            elif y == d - 1:
                col = PLASTICO_SOMBRA
            pinta(x, y, col)
    # una ranura del cargador y un tornillo, para que no sea un bloque liso
    for y in range(c + 1, d):
        px[16, y] = PLASTICO_SOMBRA
    px[7, 16] = PLASTICO_OSCURO
    # el depósito de ácido, redondo, con el reflejo arriba a la izquierda y la sombra abajo a la derecha
    cx, cy, r = DEPOSITO
    for y in range(32):
        for x in range(32):
            dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if dist <= r:
                col = LIMA
                if dist >= r - 1.2 and (x - cx) + (y - cy) > 1.5:
                    col = LIMA_SOMBRA
                elif (x - cx) + (y - cy) > 2.5:
                    col = LIMA_OSCURO
                if ((x - (cx - 2.2)) ** 2 + (y - (cy - 2.2)) ** 2) ** 0.5 <= 1.7:
                    col = LIMA_CLARO
                pinta(x, y, col)
    # la boquilla: más alta cada columna (se ensancha); arriba blanca, abajo con sombra
    for i, medio in enumerate(BOQUILLA):
        x = BOQUILLA_X0 + i
        for y in range(EJE - medio, EJE + medio + 1):
            col = BLANCO
            if y >= EJE + medio - 1:
                col = BLANCO_SOMBRA
            pinta(x, y, col)
    # el aro de la boca: la última columna, más oscura por dentro
    x = BOQUILLA_X0 + len(BOQUILLA) - 1
    for y in range(EJE - BOQUILLA[-1], EJE + BOQUILLA[-1] + 1):
        px[x, y] = PLASTICO_SOMBRA if EJE - BOQUILLA[-1] < y < EJE + BOQUILLA[-1] else BLANCO_SOMBRA
    # el borde oscuro, sin pisar nada pintado
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    # el chorro: una línea fina de ácido que sale de la boca (después del borde, que no lo rodea), con una punta más clara y dos
    # gotitas sueltas
    for x in range(29, 32):
        px[x, EJE] = CHORRO_CLARO if x == 31 else CHORRO
        if x < 31:
            px[x, EJE - 1] = CHORRO
    px[30, EJE - 4] = CHORRO
    px[31, EJE + 3] = CHORRO
    px[29, EJE + 5] = CHORRO
    salida = ICONOS / "desintegrador.png"
    im.save(salida)
    print(salida)


main()
