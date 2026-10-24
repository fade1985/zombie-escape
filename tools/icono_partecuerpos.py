# El icono del partecuerpos (el arma creada con el bate y las cuchillas): el icono del bate (bate.png) con cuatro
# cuchillas planas clavadas de canto en la punta gorda, el filo (arriba, claro) hacia fuera por los dos lados, con los
# grises del icono de los clavos pero más anchas y más largas que los clavos del aplastacabezas, y sangre: en la punta
# de cada cuchilla, goteando, y unas manchas en la madera. Con el borde oscuro de un píxel. 32×32.
#   py tools/icono_partecuerpos.py   → assets/ui/iconos/partecuerpos.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
FILO = (232, 236, 240, 255)       # el filo, la fila de arriba de la cuchilla
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)
SANGRE = (192, 57, 43, 255)
SANGRE_OSCURA = (128, 28, 28, 255)

# Cada cuchilla: la fila del medio, la columna del borde del bate por donde sale y hacia qué lado (-1 izquierda, 1 derecha)
CUCHILLAS = [(4, 12, -1), (10, 12, -1), (7, 18, 1), (13, 18, 1)]
LARGO = 5   # cuánto sale del bate (la punta de la del medio)
# Qué filas ocupa la cuchilla a cada distancia del bate (1 a 5): una hoja que se afila hacia fuera
FILAS = {1: (-1, 0, 1), 2: (-1, 0, 1), 3: (-1, 0), 4: (0,), 5: (0,)}
# Manchas de sangre en la madera de la punta gorda: (x, y, oscura)
MANCHAS = [(14, 6, False), (15, 6, True), (14, 8, True), (16, 9, False), (15, 12, False), (14, 13, True), (16, 4, True)]


def main():
    im = Image.open(ICONOS / "bate.png").convert("RGBA")
    px = im.load()
    for x, y, oscura in MANCHAS:
        if px[x, y][3] and max(px[x, y][:3]) >= 70:   # solo sobre la madera, no sobre el borde
            px[x, y] = SANGRE_OSCURA if oscura else SANGRE
    puntos = []
    for y, x0, lado in CUCHILLAS:
        px[x0, y] = ACERO   # atraviesa el borde del bate
        puntos.append((x0, y))
        for dist, filas in FILAS.items():
            x = x0 + lado * dist
            for f in filas:
                c = FILO if f == -1 else (ACERO_OSCURO if f == 1 else ACERO)
                if f == 0 and dist == LARGO:
                    c = SANGRE                          # la punta, roja
                elif f == 0 and dist == LARGO - 1:
                    c = SANGRE_OSCURA
                px[x, y + f] = c
                puntos.append((x, y + f))
        px[x0 + lado * 2, y + 2] = SANGRE               # la gota que cuelga de la cuchilla
        puntos.append((x0 + lado * 2, y + 2))
    # el borde: alrededor de cada cuchilla, sin pisar nada pintado
    for x, y in puntos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < 32 and 0 <= n[1] < 32 and px[n][3] == 0:
                px[n] = BORDE
    salida = ICONOS / "partecuerpos.png"
    im.save(salida)
    print(salida)


main()
