# El icono del bumerán segador (el arma creada con la llave inglesa y el hacha): un bumerán grande de acero, curvo como una hoja de hacha
# y doblado en V, con el filo exterior blanco y brillante, el acero medio por dentro con una sombra en el lado de dentro, y el mango de
# la llave inglesa envuelto en rojo en el codo de la V, con una tuerca gris asomando por fuera. Se distingue del icono del hacha y del
# de la llave inglesa por la forma en V y el mango rojo. Con el borde oscuro de un píxel, los grises azulados del acero del dibujo de
# Johnny con el bumerán (#a3b8c7 y el filo casi blanco) y sus rojos. 32×32.
#   py tools/icono_bumeran.py   → assets/ui/iconos/bumeran.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los de los otros iconos
ACERO = (163, 184, 199, 255)      # el acero del dibujo de Johnny
ACERO_FILO = (253, 254, 249, 255) # el filo casi blanco
ACERO_CLARO = (206, 220, 230, 255)
ACERO_SOMBRA = (118, 138, 156, 255)
ACERO_OSCURO = (84, 98, 118, 255)
ROJO = (214, 33, 35, 255)         # el mango envuelto
ROJO_CLARO = (246, 110, 96, 255)
ROJO_OSCURO = (168, 30, 35, 255)
ROJO_SOMBRA = (96, 16, 24, 255)
TUERCA = (143, 130, 120, 255)     # la tuerca de la llave: el gris pardo de las herramientas de Johnny
TUERCA_CLARA = (200, 192, 180, 255)

# Una curva de Bézier (punta, control, punta): se hunde hacia abajo a la izquierda, como la V de un bumerán
A, C, B = (8.0, 2.0), (1.0, 32.0), (30.0, 24.0)
PASOS = 160
CODO = 0.5   # por dónde pasa el mango (t de la curva)


def punto(t):
    x = (1 - t) ** 2 * A[0] + 2 * (1 - t) * t * C[0] + t ** 2 * B[0]
    y = (1 - t) ** 2 * A[1] + 2 * (1 - t) * t * C[1] + t ** 2 * B[1]
    return x, y


def ancho(t):
    # grueso en el codo, afilado en las dos puntas
    return 2.6 + 6.0 * (1 - abs(2 * t - 1) ** 1.3)


def main():
    muestras = [(i / PASOS, *punto(i / PASOS)) for i in range(PASOS + 1)]
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    solidos = []
    codo = punto(CODO)
    for y in range(32):
        for x in range(32):
            cx, cy = x + 0.5, y + 0.5
            t, d = min(((m[0], ((cx - m[1]) ** 2 + (cy - m[2]) ** 2) ** 0.5) for m in muestras), key=lambda q: q[1])
            w = ancho(t) / 2
            if d > w:
                continue
            # de qué lado de la curva está el píxel: fuera (el lado convexo, hacia abajo a la izquierda) o dentro
            px0, py0 = punto(min(1.0, t + 0.01))
            qx, qy = punto(max(0.0, t - 0.01))
            tx, ty = px0 - qx, py0 - qy
            lado = tx * (cy - punto(t)[1]) - ty * (cx - punto(t)[0])   # > 0: a la derecha de la marcha (según la imagen)
            fuera = lado > 0
            # el acero: filo blanco por fuera, acero en medio, sombra por dentro
            if fuera:
                col = ACERO_FILO if d > w - 1.3 else (ACERO_CLARO if d > w - 2.4 else ACERO)
            else:
                col = ACERO_OSCURO if d > w - 1.0 else (ACERO_SOMBRA if d > w - 2.2 else ACERO)
            # el mango envuelto en rojo, en el codo
            if abs(t - CODO) < 0.075:
                col = ROJO
                if fuera and d > w - 1.4:
                    col = ROJO_CLARO
                elif not fuera and d > w - 1.6:
                    col = ROJO_SOMBRA
                if int(round(t * PASOS)) % 5 == 0:
                    col = ROJO_OSCURO   # las vueltas de la cinta
            px[x, y] = col
            solidos.append((x, y))
    # la tuerca de la llave: asoma por fuera del codo, abajo a la izquierda, con la boca abierta (una muesca)
    tx0, ty0 = int(codo[0]) - 4, int(codo[1]) + 1
    for dy in range(4):
        for dx in range(4):
            if (dx, dy) in ((0, 0), (3, 3)):
                continue
            x, y = tx0 + dx, ty0 + dy
            if 0 <= x < 32 and 0 <= y < 32:
                px[x, y] = TUERCA_CLARA if (dx + dy) <= 2 else TUERCA
                solidos.append((x, y))
    # el borde oscuro, sin pisar nada pintado
    for x, y in solidos:
        for ddx, ddy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + ddx, y + ddy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    salida = ICONOS / "bumeran.png"
    im.save(salida)
    print(salida)


main()
