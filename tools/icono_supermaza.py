# El icono de la súper maza (el arma creada con la fregona y las mancuernas): el palo de madera subiendo en diagonal
# desde abajo a la izquierda y, atada con cuerda en la punta, una mancuerna de hierro enorme puesta de través, como la
# cabeza de un martillo: una barra con un disco redondo de hierro a cada lado. Con el borde
# oscuro de un píxel y los colores de los iconos del bate (la madera) y de los clavos (el acero). 32×32.
#   py tools/icono_supermaza.py   → assets/ui/iconos/supermaza.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
MADERA = (199, 121, 67, 255)      # la madera del bate
MADERA_CLARA = (215, 129, 64, 255)
MADERA_OSCURA = (150, 85, 45, 255)
CUERDA = (226, 188, 120, 255)     # la cuerda que ata la mancuerna: dos arena que se alternan
CUERDA_OSCURA = (178, 132, 76, 255)
HIERRO = (62, 66, 78, 255)        # el hierro de los discos: gris carbón con un brillo y una sombra
HIERRO_CLARO = (122, 128, 142, 255)
HIERRO_BRILLO = (178, 184, 196, 255)
HIERRO_OSCURO = (48, 51, 60, 255)

CENTRO = (16.5, 11.5)             # donde el palo se ata a la barra
DIR = (0.7071, -0.7071)           # hacia donde apunta el palo (arriba a la derecha)
EJE = (0.7071, 0.7071)            # el eje de la mancuerna, de través al palo
LARGO_PALO = 19.0                 # cuánto baja el palo desde la barra
SEPARACION = 7.6                  # de la barra al centro de cada disco
RADIO = 5.5                       # el radio de cada disco


def disco(x, y, c):
    """El color del píxel (x, y) si cae en el disco de centro c (un disco de hierro redondo: brillo arriba a la izquierda,
    sombra abajo a la derecha y un buje claro en el medio), o None."""
    dx, dy = x + 0.5 - c[0], y + 0.5 - c[1]
    r = (dx * dx + dy * dy) ** 0.5
    if r > RADIO:
        return None
    if r <= 1.7:
        return HIERRO_BRILLO if dx + dy < 0.6 else HIERRO_CLARO   # el buje
    if r > RADIO - 1.2:
        return HIERRO_OSCURO if dx + dy > 0 else HIERRO_CLARO   # el canto del disco
    if dx + dy < -RADIO * 0.7:
        return HIERRO_CLARO
    return HIERRO


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    cx, cy = CENTRO
    c1 = (cx + SEPARACION * EJE[0], cy + SEPARACION * EJE[1])
    c2 = (cx - SEPARACION * EJE[0], cy - SEPARACION * EJE[1])
    for y in range(32):
        for x in range(32):
            rx, ry = x + 0.5 - cx, y + 0.5 - cy
            u = rx * EJE[0] + ry * EJE[1]       # a lo largo del eje de la mancuerna
            v = rx * DIR[0] + ry * DIR[1]       # a lo largo del palo (+: hacia la punta)
            color = disco(x, y, c1) or disco(x, y, c2)
            if color is None and abs(u) <= SEPARACION and abs(v) <= 1.5:
                color = HIERRO_CLARO if v > 0 else HIERRO      # la barra, entre los dos discos
            # el palo, por delante de la barra
            if -LARGO_PALO <= v <= 0.5 and abs(u) <= 1.6:
                color = MADERA_CLARA if u < -0.5 else (MADERA_OSCURA if u > 0.7 else MADERA)
            # la cuerda que lo ata, dos vueltas en diagonal
            if -3.4 <= v <= 1.8 and abs(u) <= 2.5:
                color = CUERDA if int(v + 10) % 2 == 0 else CUERDA_OSCURA
            if color:
                px[x, y] = color
    # el borde oscuro, sin pisar nada pintado
    solidos = [(x, y) for y in range(32) for x in range(32) if px[x, y][3]]
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    salida = ICONOS / "supermaza.png"
    im.save(salida)
    print(salida)


main()
