# El icono de la lanza (el arma creada con la fregona y el cuchillo): el palo de la fregona en diagonal, de abajo a la
# izquierda hacia arriba a la derecha, con el cuchillo de cocina atado en la punta con cinta gris. 32×32, con los
# colores de los iconos de la fregona y del cuchillo (fregona.png, cuchillo.png) y su borde oscuro de un píxel.
#   py tools/icono_lanza.py   → assets/ui/iconos/lanza.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
BORDE = (70, 40, 53, 255)        # el del icono de la fregona
PALO = (197, 113, 62, 255)       # la madera del palo de la fregona
PALO_SOMBRA = (155, 88, 52, 255)
CINTA = (114, 97, 99, 255)       # la cinta gris (los grises de la mopa), más oscura que la hoja para que se vea
CINTA_SOMBRA = (155, 140, 133, 255)
HOJA_LUZ = (210, 211, 216, 255)  # los grises del cuchillo
HOJA = (191, 191, 200, 255)
HOJA_SOMBRA = (137, 136, 146, 255)

# Todo va por la diagonal x + y = 32. "a" dice cuánto se aparta un píxel de ella (x + y - 32) y "x" por dónde va
PALO_X = range(4, 17)        # del extremo de abajo hasta la cinta
CINTA_X = range(16, 19)
HOJA_X = range(19, 28)       # la hoja, de la cinta a la punta


def color(x, y):
    a = x + y - 32
    if x in PALO_X and a in (-1, 0):
        return PALO if a == -1 else PALO_SOMBRA
    if x in CINTA_X and -2 <= a <= 1:
        return CINTA_SOMBRA if (x + a) % 3 == 0 else CINTA   # unas rayitas, como si diera vueltas
    if x in HOJA_X:
        ancho = 2 if x < 23 else (1 if x < 26 else 0)          # se estrecha hasta la punta
        if -ancho - 1 <= a <= ancho:
            if a == -ancho - 1:
                return HOJA_LUZ                                 # el filo de arriba, con brillo
            return HOJA_SOMBRA if a == ancho and ancho > 0 else HOJA
    return None


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    dentro = {(x, y) for y in range(32) for x in range(32) if color(x, y)}
    for x, y in dentro:
        px[x, y] = color(x, y)
    # el borde: los píxeles vacíos pegados a lo dibujado (también en diagonal, como en los otros iconos)
    for x, y in dentro:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                n = (x + dx, y + dy)
                if 0 <= n[0] < 32 and 0 <= n[1] < 32 and n not in dentro:
                    px[n] = BORDE
    salida = RAIZ / "assets" / "ui" / "iconos" / "lanza.png"
    im.save(salida)
    print(salida)


main()
