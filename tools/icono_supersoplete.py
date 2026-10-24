# El icono del supersoplete (el arma creada con el spray y el mechero): una bombona de gas amarilla abajo a la izquierda, con
# su cuello gris que sube a un cañón corto y grueso de metal gris oscuro que apunta a la derecha y acaba en una boquilla
# acampanada, con una empuñadura negra debajo y un cono ancho de llamas (amarillo, naranja y rojo) que sale de la boca. Se
# distingue del lanzallamas (depósito rojo y un tubo largo y fino con una llamita) y del bate de fuego (un bate con la punta
# ardiendo) por la bombona amarilla, el cañón gordo con la boca acampanada y la llamarada ancha. Con el borde oscuro de un
# píxel, los grises del icono de los clavos y los colores de las gotas de fuego del juego (chorro.gd: amarillo #fff3a0,
# naranja #ff9f1c y rojo #d94a1a). 32×32.
#   py tools/icono_supersoplete.py   → assets/ui/iconos/supersoplete.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # los del icono de los clavos
FILO = (232, 236, 240, 255)       # lo más claro del metal
ACERO = (166, 172, 180, 255)
ACERO_OSCURO = (93, 100, 112, 255)
CABLE = (74, 76, 90, 255)         # la empuñadura: un gris azulado oscuro con un reflejo más claro
CABLE_CLARO = (122, 126, 142, 255)
AMARILLO_BOMBONA = (246, 196, 39, 255)   # la bombona: los amarillos del dibujo de Johnny
AMARILLO_CLARO = (255, 226, 120, 255)
AMARILLO_OSCURO = (205, 147, 20, 255)
AMARILLO_SOMBRA = (150, 100, 24, 255)
AMARILLO = (255, 243, 160, 255)   # los de las gotas de fuego (chorro.gd)
NARANJA = (255, 159, 28, 255)
ROJO_LLAMA = (217, 74, 26, 255)

# La bombona: columnas y filas del cuerpo (los dos extremos incluidos); la fila de arriba es la tapa, más oscura
CUERPO = (3, 13, 16, 28)
# El cuello gris entre la bombona y el cañón (columnas 7 a 9, de la fila 12 a la 15)
CUELLO = (7, 9, 12, 15)
# El cañón: filas 9 a 11, de la columna 5 a la 19; una ruedecita de válvula detrás (columnas 3 y 4, filas 8 a 12)
CANON = (5, 19, 9, 11)
RUEDA = (3, 4, 8, 12)
# La empuñadura negra bajo el cañón (columnas 14 y 15, filas 12 a 18)
EMPUNADURA = (14, 15, 12, 18)
# La boquilla acampanada: de la columna 20 a la 25, el medio alto de cada columna (el eje está en la fila 10)
BOQUILLA_X0 = 20
BOQUILLA = [1, 2, 2, 3, 4, 5]
EJE = 10
# La llamarada: del borde de la boca (columna 26) al borde del icono, un cono que se abre; (medio alto en la columna 26 y en la 31)
LLAMA_X0 = 26
LLAMA_ANCHO = (3.2, 5.6)


def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    solidos = []

    def pinta(x, y, c):
        px[x, y] = c
        solidos.append((x, y))

    # la bombona, con un reflejo claro en la columna de la izquierda, sombra en las de la derecha y un aro oscuro
    x0, x1, y0, y1 = CUERPO
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if (x in (x0, x1)) and y == y1:
                continue                       # las esquinas de abajo, redondeadas
            c = AMARILLO_BOMBONA
            if y == y0:
                c = AMARILLO_OSCURO
            elif x == x0 + 1:
                c = AMARILLO_CLARO
            elif x >= x1 - 1:
                c = AMARILLO_OSCURO
            pinta(x, y, c)
    for x in range(x0, x1 + 1):
        pinta(x, 21, AMARILLO_SOMBRA)
        pinta(x, 22, AMARILLO_OSCURO if x > x0 + 1 else AMARILLO_BOMBONA)
    # el cuello
    a, b, c, d = CUELLO
    for y in range(c, d + 1):
        for x in range(a, b + 1):
            pinta(x, y, ACERO_OSCURO if x > a else ACERO)
    # el cañón: arriba claro, en medio acero, abajo oscuro
    a, b, c, d = CANON
    for x in range(a, b + 1):
        pinta(x, c, FILO if x % 4 else ACERO)
        pinta(x, c + 1, ACERO)
        pinta(x, d, ACERO_OSCURO)
    a, b, c, d = RUEDA
    for y in range(c, d + 1):
        for x in range(a, b + 1):
            pinta(x, y, FILO if x == a else ACERO)
    # la empuñadura, con una franja clara
    a, b, c, d = EMPUNADURA
    for n, y in enumerate(range(c, d + 1)):
        pinta(a, y, CABLE_CLARO if n % 2 == 0 else CABLE)
        pinta(b, y, CABLE)
    # la boquilla acampanada: cada columna es más alta que la anterior; arriba claro, abajo oscuro
    for i, medio in enumerate(BOQUILLA):
        x = BOQUILLA_X0 + i
        for y in range(EJE - medio, EJE + medio + 1):
            c = ACERO
            if y == EJE - medio:
                c = FILO
            elif y >= EJE + medio - 1:
                c = ACERO_OSCURO
            pinta(x, y, c)
    # el aro de la boca: la última columna, más oscura
    x = BOQUILLA_X0 + len(BOQUILLA) - 1
    for y in range(EJE - BOQUILLA[-1], EJE + BOQUILLA[-1] + 1):
        px[x, y] = CABLE if EJE - BOQUILLA[-1] < y < EJE + BOQUILLA[-1] else ACERO_OSCURO
    # el borde oscuro, sin pisar nada pintado
    for x, y in solidos:
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] == 0:
                px[nx, ny] = BORDE
    # la llamarada: un cono que se abre hacia el borde de la derecha; el centro amarillo, luego naranja y el borde rojo; las
    # puntas del borde, algo irregulares (como llamas)
    for x in range(LLAMA_X0, 32):
        t = (x - LLAMA_X0) / (31 - LLAMA_X0)
        medio = LLAMA_ANCHO[0] + (LLAMA_ANCHO[1] - LLAMA_ANCHO[0]) * t
        for y in range(32):
            lado = abs(y - EJE)
            irregular = 0.9 if (x * 7 + y * 3) % 5 == 0 else 0.0   # alguna muesca en el borde
            if lado <= medio - irregular:
                r = lado / medio
                if r < 0.35 and t < 0.95:
                    c = AMARILLO
                elif r < 0.7:
                    c = NARANJA
                else:
                    c = ROJO_LLAMA
                px[x, y] = c
    salida = ICONOS / "supersoplete.png"
    im.save(salida)
    print(salida)


main()
