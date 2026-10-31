"""El número grande de la planta, roto y desgastado (L21 de PENDIENTES): el edificio está destrozado y el cartel se veía demasiado entero.

De cada cartel limpio (assets/sources/cartel/limpios/, los que dejan guias_cartel.py y cartel_planta_idiomas.py) sale el del juego
(assets/sprites/cartel-planta-*.png), con la pintura pelada, un desconchón en la pared, grietas, arañazos y mugre. Cada archivo
lleva su propia semilla, así que al lanzarlo otra vez salen los mismos dibujos. La palabra de arriba se pela menos, para que se lea.

  py tools/cartel_roto.py     (y luego, para que Godot los importe: Godot --headless --path . --import)
"""
import glob
import math
import os
import random
from PIL import Image

LIMPIOS = "assets/sources/cartel/limpios"
SPRITES = "assets/sprites"
FIN_PALABRA = 8           # las filas de la palabra («PLANTA») acaban aquí; debajo va el número
GRIETA = (24, 18, 13, 215)
FILO = (24, 19, 14, 215)  # el borde del desconchón
YESO = (72, 64, 48, 170)  # lo que se ve dentro: la pared sin pintura


# Manchas suaves al azar, entre 0 y 1: una malla de valores y, entre uno y otro, una mezcla
def ruido(dado, ancho, alto, paso):
    malla = [[dado.random() for _ in range(ancho // paso + 2)] for _ in range(alto // paso + 2)]

    def valor(x, y):
        c, f = x // paso, y // paso
        tx, ty = (x % paso) / paso, (y % paso) / paso
        arriba = malla[f][c] * (1 - tx) + malla[f][c + 1] * tx
        abajo = malla[f + 1][c] * (1 - tx) + malla[f + 1][c + 1] * tx
        return arriba * (1 - ty) + abajo * ty
    return valor


# Una grieta en zigzag: de "x, y" hacia "rumbo" (en grados), con píxeles sueltos de un punto a otro. Devuelve por dónde ha pasado
def grieta(dado, p, ancho, alto, x, y, rumbo, largo):
    camino = []
    for _ in range(largo):
        rumbo += dado.uniform(-45, 45)
        x += math.cos(math.radians(rumbo)) * 1.4
        y += math.sin(math.radians(rumbo)) * 1.4
        if not (0 <= int(x) < ancho and FIN_PALABRA <= int(y) < alto):   # (se para en la palabra, para que se lea)
            break
        p[int(x), int(y)] = GRIETA
        camino.append((int(x), int(y)))
    return camino


def romper(nombre, intento):
    dado = random.Random(nombre + str(intento))
    im = Image.open(os.path.join(LIMPIOS, nombre)).convert("RGBA")
    ancho, alto = im.size
    p = im.load()
    grande = ruido(dado, ancho, alto, 7)
    fino = ruido(dado, ancho, alto, 3)
    mugre = ruido(dado, ancho, alto, 5)
    pintura = [(x, y) for y in range(FIN_PALABRA, alto) for x in range(ancho) if p[x, y][3] > 0]

    # lo hondo que está cada píxel de pintura: lo pelado se come los bordes del trazo, y el alma queda para que se lea
    hondo = {}
    borde = {(x, y) for x, y in pintura}
    for capa in range(1, 4):
        for x, y in borde:
            if any((x + dx, y + dy) not in borde for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                hondo[x, y] = capa
        borde = {q for q in borde if q not in hondo}

    # la pintura pelada y la mugre sobre la que queda
    for y in range(alto):
        for x in range(ancho):
            c = p[x, y]
            if c[3] == 0:
                continue
            n = grande(x, y) * 0.45 + fino(x, y) * 0.55
            limite = 0.9 if y < FIN_PALABRA else {1: 0.58, 2: 0.66}.get(hondo.get((x, y)), 0.8)
            if n > limite:
                p[x, y] = (0, 0, 0, 0)
                continue
            m = mugre(x, y)
            k = 1.0 if m < 0.45 else (0.8 if m < 0.62 else 0.62)   # tres tonos, como lo demás del juego
            if y < FIN_PALABRA:
                k = max(k, 0.85)                                   # en la palabra, sin el más oscuro: se fundiría con la pared
            p[x, y] = (int(c[0] * k), int(c[1] * k), int(c[2] * k), c[3])

    # arañazos: rayas finas en diagonal que se llevan la pintura
    for _ in range(3):
        x, y = dado.randrange(ancho), dado.randrange(FIN_PALABRA, alto)
        paso = dado.choice([-1, 1])
        for i in range(dado.randrange(7, 15)):
            xr, yr = x + i * paso, y + i // 2
            if 0 <= xr < ancho and yr < alto:
                p[xr, yr] = (0, 0, 0, 0)

    # el desconchón: un trozo de pared caído, con su borde
    if pintura:
        cx, cy = dado.choice(pintura)
        cy = max(cy, FIN_PALABRA + 9)
        radio = dado.uniform(2.8, 4.0)
        fases = [dado.uniform(0, math.tau) for _ in range(3)]

        def dentro(x, y):
            a = math.atan2(y - cy, x - cx)
            r = radio * (1 + 0.28 * math.sin(a * 2 + fases[0]) + 0.2 * math.sin(a * 3 + fases[1]) + 0.12 * math.sin(a * 7 + fases[2]))
            return math.hypot(x - cx, y - cy) < r
        for y in range(alto):
            for x in range(ancho):
                if dentro(x, y):
                    borde = not all(dentro(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    p[x, y] = FILO if borde else YESO
        # y las grietas que salen de él
        for rumbo in (dado.uniform(-70, 20), dado.uniform(100, 200)):
            a = math.radians(rumbo)
            camino = grieta(dado, p, ancho, alto, cx + math.cos(a) * radio, cy + math.sin(a) * radio, rumbo, dado.randrange(8, 15))
            if len(camino) > 5:
                x, y = camino[len(camino) // 2]
                grieta(dado, p, ancho, alto, x, y, rumbo + dado.choice([-55, 55]), dado.randrange(3, 7))
    return im


# Lo que queda de pintura en el trozo más grande del número: si la grieta o el desconchón lo parten en dos, no se lee
def trozo_mayor(im):
    ancho, alto = im.size
    p = im.load()
    quedan = {(x, y) for y in range(FIN_PALABRA, alto) for x in range(ancho) if p[x, y][3] > 0 and p[x, y][0] > 100}
    mayor = 0
    while quedan:
        pila = [quedan.pop()]
        n = 0
        while pila:
            x, y = pila.pop()
            n += 1
            for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if q in quedan:
                    quedan.remove(q)
                    pila.append(q)
        mayor = max(mayor, n)
    return mayor


if __name__ == "__main__":
    for ruta in sorted(glob.glob(os.path.join(LIMPIOS, "cartel-planta-*.png"))):
        nombre = os.path.basename(ruta)
        # de unos cuantos intentos, el que deja el número más entero (sigue roto: el desconchón y lo pelado van siempre)
        mejor = max((romper(nombre, i) for i in range(40)), key=trozo_mayor)
        mejor.save(os.path.join(SPRITES, nombre))
        print(nombre)
