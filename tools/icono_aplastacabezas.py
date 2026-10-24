# El icono del aplastacabezas (el arma creada con el bate y los clavos): el icono del bate (bate.png) con clavos que
# atraviesan la punta gorda y asoman por los dos lados, con los grises del icono de los clavos (obj-clavos.png) y el
# borde oscuro de un píxel. 32×32.
#   py tools/icono_aplastacabezas.py   → assets/ui/iconos/aplastacabezas.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)        # los del icono de los clavos
CLAVO_LUZ = (208, 212, 218, 255)
CLAVO = (154, 160, 168, 255)
CLAVO_PUNTA = (93, 100, 112, 255)

# Cada clavo: la fila, la columna del borde del bate por donde sale y hacia qué lado (-1 izquierda, 1 derecha).
# Sale 3 píxeles y se afila hacia la punta
CLAVOS = [(4, 12, -1), (9, 12, -1), (14, 13, -1), (6, 18, 1), (11, 18, 1)]


def main():
    im = Image.open(ICONOS / "bate.png").convert("RGBA")
    px = im.load()
    puntas = []
    for y, x0, lado in CLAVOS:
        px[x0, y] = CLAVO   # atraviesa el borde del bate
        for i, c in enumerate([CLAVO_LUZ, CLAVO, CLAVO_PUNTA]):
            x = x0 + lado * (i + 1)
            px[x, y] = c
            puntas.append((x, y))
        puntas.append((x0, y))
    # el borde: arriba y abajo de cada clavo, y pasada la punta
    for x, y in puntas:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < 32 and 0 <= n[1] < 32 and px[n][3] == 0:
                px[n] = BORDE
    salida = ICONOS / "aplastacabezas.png"
    im.save(salida)
    print(salida)


main()
