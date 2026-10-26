# El icono del lanza rayos (antes la pistola eléctrica; el id del arma y el archivo siguen siendo pistola_electrica): el arma
# de tamaño escopeta de Johnny, vista de lado y apuntando a la derecha, blanca y gris con la franja de luz celeste, la
# culata oscura y la empuñadura debajo. Con el borde oscuro de un píxel (el de los otros iconos) y los colores del dibujo de
# Johnny con el lanza rayos (assets/sources/conserje-48-lanza-rayos/rotations/east.png). 32×32.
#   py tools/icono_lanza_rayos.py   → assets/ui/iconos/pistola_electrica.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)          # los de los otros iconos
BLANCO = (245, 249, 250, 255)      # el cuerpo del arma
CLARO = (197, 202, 209, 255)
MEDIO = (148, 145, 144, 255)
OSCURO = (54, 59, 72, 255)         # la culata y la empuñadura
OSCURO_CLARO = (90, 90, 96, 255)
MARCO = (59, 92, 117, 255)         # el marco de la franja de luz
CELESTE = (44, 242, 240, 255)      # la franja
CELESTE_OSCURO = (10, 160, 162, 255)

im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
px = im.load()


def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = c


# el cuerpo: blanco arriba, gris claro y un poco más oscuro abajo
rect(7, 11, 29, 11, BLANCO)
rect(7, 12, 29, 16, CLARO)
rect(7, 17, 29, 18, MEDIO)
# la franja de luz, con su marco azul grisáceo
rect(10, 12, 28, 15, MARCO)
rect(11, 13, 27, 13, CELESTE)
rect(11, 14, 27, 14, CELESTE_OSCURO)
# el remate de delante, más blanco
rect(29, 11, 29, 16, BLANCO)
# la culata, oscura, y un escalón debajo
rect(2, 12, 6, 17, OSCURO)
rect(2, 12, 6, 12, OSCURO_CLARO)
rect(4, 18, 8, 18, OSCURO)
# la empuñadura, algo inclinada, con el guardamonte
for y, (x0, x1) in zip(range(19, 26), [(11, 16), (11, 16), (12, 16), (12, 16), (13, 17), (13, 17), (13, 17)]):
    rect(x0, y, x1, y, OSCURO)
    px[x0, y] = OSCURO_CLARO
rect(17, 19, 19, 19, OSCURO)
rect(18, 20, 19, 21, OSCURO)
# la parte de abajo del cañón
rect(20, 19, 29, 19, OSCURO)

# el borde oscuro: todo lo transparente pegado al arma
borde = [(x, y) for y in range(32) for x in range(32) if not px[x, y][3]
         and any(0 <= x + a < 32 and 0 <= y + b < 32 and px[x + a, y + b][3] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
for q in borde:
    px[q] = BORDE

# centrado en vertical
caja = im.getbbox()
salida = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
salida.paste(im.crop(caja), (caja[0], (32 - (caja[3] - caja[1])) // 2))
salida.save(ICONOS / "pistola_electrica.png")
print("icono guardado:", ICONOS / "pistola_electrica.png", "caja", caja)
