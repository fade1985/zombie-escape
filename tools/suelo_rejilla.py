# El suelo de rejillas de la Cocina central del cocinero (24 nov, el dueño: «baldosas no cuadra con que aparezca fuego de
# repente»): paneles de rejilla de acero, cada uno de 64×64 píxeles (4×4 casillas, lo que mide un cuadro de los fogones en
# damero, fogones_damero.gd), con su marco atornillado y, por los huecos, lo oscuro de debajo con un poco de brasa. El
# dibujo es de 128×128 (2×2 paneles, cada uno un poco distinto) y se repite desde la esquina del mapa, como los cuadros
# del damero: cada cuadro que quema es justo un panel.
# Uso: py tools/suelo_rejilla.py  ->  assets/sprites/suelo-rejilla.png
import random
from PIL import Image

PANEL = 64
LADO = 128
MARCO = 4          # el marco liso de cada panel
PASO = 6           # cada cuánto va una barra
BARRA = 2          # lo que mide la barra

ACERO = [(38, 40, 46), (56, 59, 66), (74, 78, 86), (96, 101, 110), (124, 129, 138)]   # de oscuro a claro
HUECO = [(10, 8, 10), (18, 12, 13), (34, 16, 14), (58, 22, 16)]                      # lo de debajo, con brasa
OXIDO = [(78, 52, 38), (98, 64, 42)]
GRASA = (30, 28, 26)


def panel(im, x0, y0, rnd):
    px = im.load()
    for y in range(PANEL):
        for x in range(PANEL):
            X, Y = x0 + x, y0 + y
            borde = min(x, y, PANEL - 1 - x, PANEL - 1 - y)
            if borde < MARCO:
                # el marco: arriba e izquierda con luz, abajo y derecha en sombra, y la junta oscura con el de al lado
                if borde == 0:
                    c = ACERO[0]
                elif x == borde and y >= borde or y == borde and x >= borde:
                    c = ACERO[4] if borde == 1 else ACERO[3]
                elif PANEL - 1 - x == borde or PANEL - 1 - y == borde:
                    c = ACERO[1]
                else:
                    c = ACERO[2]
            else:
                ix, iy = (x - MARCO) % PASO, (y - MARCO) % PASO
                barra_v, barra_h = ix < BARRA, iy < BARRA
                if barra_v or barra_h:
                    # la barra: su canto de arriba/izquierda con luz, el resto en medio
                    c = ACERO[3] if (barra_h and iy == 0) or (barra_v and ix == 0 and not barra_h) else ACERO[2]
                    if barra_v and barra_h:
                        c = ACERO[3]
                else:
                    # el hueco: sombra de la barra arriba y a la izquierda, y al fondo, a veces, el rojo de la brasa
                    if ix == BARRA or iy == BARRA:
                        c = HUECO[0]
                    else:
                        r = rnd.random()
                        c = HUECO[3] if r < 0.06 else HUECO[2] if r < 0.22 else HUECO[1]
            px[X, Y] = c
    # los tornillos de las esquinas
    for cx, cy in [(1, 1), (PANEL - 3, 1), (1, PANEL - 3), (PANEL - 3, PANEL - 3)]:
        px[x0 + cx, y0 + cy] = ACERO[4]
        px[x0 + cx + 1, y0 + cy] = ACERO[3]
        px[x0 + cx, y0 + cy + 1] = ACERO[3]
        px[x0 + cx + 1, y0 + cy + 1] = ACERO[1]
    # manchas de grasa y algo de óxido en las barras, distintas en cada panel
    for _ in range(rnd.randint(2, 4)):
        mx, my, mr = rnd.randint(8, PANEL - 9), rnd.randint(8, PANEL - 9), rnd.randint(3, 7)
        oxido = rnd.random() < 0.4
        for y in range(-mr, mr + 1):
            for x in range(-mr, mr + 1):
                if x * x + y * y > mr * mr or rnd.random() < 0.35:
                    continue
                X, Y = x0 + mx + x, y0 + my + y
                c = px[X, Y]
                if c in HUECO:
                    continue
                if oxido:
                    px[X, Y] = OXIDO[(x + y) & 1]
                else:
                    px[X, Y] = tuple(int(a * 0.55 + b * 0.45) for a, b in zip(c, GRASA))


def main():
    im = Image.new("RGB", (LADO, LADO))
    rnd = random.Random(24)
    for j in range(LADO // PANEL):
        for i in range(LADO // PANEL):
            panel(im, i * PANEL, j * PANEL, rnd)
    im.save("assets/sprites/suelo-rejilla.png")
    print("assets/sprites/suelo-rejilla.png", im.size)


if __name__ == "__main__":
    main()
