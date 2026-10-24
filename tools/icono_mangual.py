# El icono del mangual (el arma creada con las mancuernas y la cadena): el palo de madera abajo a la izquierda, subiendo
# en diagonal, y de su punta sale una cadena de eslabones de hierro que sube en arco y vuelve a bajar a la derecha hasta
# una mancuerna pequeña de hierro colgada de través (una barra con un disco redondo a cada lado). Con el borde oscuro
# de un píxel y los colores de los iconos del bate (la madera) y de los clavos (el acero), y el hierro de la súper
# maza. 32×32.
#   py tools/icono_mangual.py   → assets/ui/iconos/mangual.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
MADERA = (199, 121, 67, 255)      # la madera del bate
MADERA_CLARA = (215, 129, 64, 255)
MADERA_OSCURA = (150, 85, 45, 255)
ACERO = (166, 172, 180, 255)      # la cadena y el aro del palo: el acero de los clavos
ACERO_BRILLO = (232, 236, 240, 255)
ACERO_OSCURO = (93, 100, 112, 255)
HIERRO = (62, 66, 78, 255)        # el hierro de los discos (el de la súper maza)
HIERRO_CLARO = (122, 128, 142, 255)
HIERRO_BRILLO = (178, 184, 196, 255)
HIERRO_OSCURO = (48, 51, 60, 255)

PALO = ((3.5, 28.0), (12.5, 18.5))     # del extremo de abajo a la punta del palo
ANCHO_PALO = 1.5                       # distancia máxima al eje del palo
# La cadena: una curva (Bézier cúbica) desde la punta del palo, por arriba, hasta el centro de la barra de la mancuerna
CADENA = ((13.0, 17.5), (6.0, 0.0), (29.0, -2.0), (23.5, 22.0))
PASO = 2.0                             # la distancia entre un eslabón y el siguiente
MANC = (23.5, 25.0)                    # el centro de la mancuerna
SEPARACION = 4.6                       # de la barra al centro de cada disco
RADIO = 3.9                            # el radio de cada disco


def bezier(t):
    a, b, c, d = CADENA
    u = 1 - t
    return (u ** 3 * a[0] + 3 * u * u * t * b[0] + 3 * u * t * t * c[0] + t ** 3 * d[0],
            u ** 3 * a[1] + 3 * u * u * t * b[1] + 3 * u * t * t * c[1] + t ** 3 * d[1])


def disco(x, y, c):
    """El color del píxel (x, y) si cae en el disco de centro c (hierro redondo: brillo arriba a la izquierda, sombra
    abajo a la derecha y un buje claro en el medio), o None."""
    dx, dy = x + 0.5 - c[0], y + 0.5 - c[1]
    r = (dx * dx + dy * dy) ** 0.5
    if r > RADIO:
        return None
    if r <= 1.2:
        return HIERRO_BRILLO if dx + dy < 0.4 else HIERRO_CLARO
    if r > RADIO - 1.0:
        return HIERRO_OSCURO if dx + dy > 0 else HIERRO_CLARO
    if dx + dy < -RADIO * 0.6:
        return HIERRO_CLARO
    return HIERRO


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()

    # la mancuerna: una barra y un disco a cada lado
    cx, cy = MANC
    for y in range(32):
        for x in range(32):
            color = disco(x, y, (cx - SEPARACION, cy)) or disco(x, y, (cx + SEPARACION, cy))
            if color is None and abs(x + 0.5 - cx) <= SEPARACION and abs(y + 0.5 - cy) <= 1.0:
                color = HIERRO_CLARO if y + 0.5 < cy else HIERRO
            if color:
                px[x, y] = color

    # la cadena: eslabones de 2×2, a un paso fijo a lo largo de la curva, que alternan un acero claro con brillo y un acero oscuro
    curva = [bezier(i / 400) for i in range(401)]
    puestos, acumulado = [curva[0]], 0.0
    for a, b in zip(curva, curva[1:]):
        acumulado += ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5
        if acumulado >= PASO:
            puestos.append(b)
            acumulado = 0.0
    for k, (x, y) in enumerate(puestos):
        ix, iy = int(x), int(y)
        claro = k % 2 == 0
        for dx in (0, 1):
            for dy in (0, 1):
                if 0 <= ix + dx < 32 and 0 <= iy + dy < 32:
                    if dx == 0 and dy == 0:
                        c = ACERO_BRILLO if claro else ACERO
                    else:
                        c = ACERO if claro else ACERO_OSCURO
                    px[ix + dx, iy + dy] = c

    # el palo de madera, con un aro de acero en la punta
    (x0, y0), (x1, y1) = PALO
    vx, vy = x1 - x0, y1 - y0
    largo2 = vx * vx + vy * vy
    for y in range(32):
        for x in range(32):
            rx, ry = x + 0.5 - x0, y + 0.5 - y0
            t = (rx * vx + ry * vy) / largo2
            if t < -0.02 or t > 1.0:
                continue
            ex, ey = rx - t * vx, ry - t * vy
            lado = (ex * -vy + ey * vx) / (largo2 ** 0.5)     # de qué lado del eje cae (+: abajo a la derecha)
            if abs(lado) <= ANCHO_PALO:
                color = MADERA_CLARA if lado < -0.6 else (MADERA_OSCURA if lado > 0.6 else MADERA)
                if t > 0.86:
                    color = ACERO if lado < 0.4 else ACERO_OSCURO    # el aro donde engancha la cadena
                px[x, y] = color

    # el borde oscuro, sin pisar nada pintado
    solidos = [(x, y) for y in range(32) for x in range(32) if px[x, y][3]]
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    salida = ICONOS / "mangual.png"
    im.save(salida)
    print(salida)


main()
