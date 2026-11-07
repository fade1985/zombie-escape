# La pared del pasillo de los Apartamentos (assets/sprites/pared-pasillo.png), pintada píxel a píxel: lisa y de color
# crema, como la de un pasillo de hotel, con algún desconchón (se ve el yeso gris de debajo), un poco de sangre seca
# (salpicaduras con chorretes, una mano y un arrastrón) y un rodapié fino de madera oscura abajo.
# Mide lo mismo que la de antes (201×48: 48 píxeles = 3 casillas, lo que mide la cara de los muros) y se repite a lo
# ancho sin costura: todo lo que se sale por un lado entra por el otro. Usa siempre la misma semilla, así que al
# lanzarla otra vez sale el mismo dibujo; para cambiarlo, tocar los números de aquí arriba.
# Uso: py tools/pared_pasillo.py  (y luego, para que Godot lo importe: Godot --headless --path . --import)
import random
from PIL import Image

ANCHO, ALTO = 201, 48
RODAPIE = 6            # filas de madera abajo
CREMA = (200, 180, 140)
YESO = (158, 150, 136)
SANGRE = [(84, 24, 18), (100, 30, 22), (66, 20, 14), (78, 30, 20)]   # roja oscura y seca
MADERA = (58, 40, 28)
DESCONCHONES = 5       # pequeños, repartidos
DESCONCHONES_GRANDES = 2   # cerca del suelo
SALPICADURAS = 2

rng = random.Random(20261107)
img = Image.new('RGB', (ANCHO, ALTO))
px = img.load()
pared = ALTO - RODAPIE


def mezcla(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def mas(c, d):
    return tuple(max(0, min(255, v + d)) for v in c)


# Las manchas suaves de suciedad: unas cuantas nubes grandes que oscurecen un poco la pared (repetidas a lo ancho)
nubes = [(rng.uniform(0, ANCHO), rng.uniform(0, pared), rng.uniform(10, 26), rng.uniform(4, 10)) for _ in range(9)]


def sucio(x, y):
    s = 0.0
    for cx, cy, r, f in nubes:
        dx = min(abs(x - cx), ANCHO - abs(x - cx))
        d2 = (dx * dx + (y - cy) ** 2) / (r * r)
        if d2 < 1:
            s += f * (1 - d2)
    return s


# La pared lisa: crema, algo más oscura arriba (la sombra del techo) y abajo (la del rodapié), con un grano finito
for y in range(pared):
    for x in range(ANCHO):
        d = -int(10 * max(0, 1 - y / 8)) - int(8 * max(0, 1 - (pared - 1 - y) / 4))
        d += rng.randint(-3, 3) - int(sucio(x, y))
        px[x, y] = mas(CREMA, d)

# El rodapié: un canto claro arriba, la madera con su veta y la última fila más oscura
for y in range(pared, ALTO):
    for x in range(ANCHO):
        f = y - pared
        c = mas(MADERA, 22) if f == 0 else mas(MADERA, -14) if f == RODAPIE - 1 else mas(MADERA, rng.randint(-4, 4))
        if 0 < f < RODAPIE - 1 and (x * 7 + f * 3) % 23 == 0:
            c = mas(c, -8)
        px[x, y] = c


def mancha(cx, cy, tam):
    """Un borrón irregular de unos tam píxeles de ancho: varios círculos pequeños juntos, dentro de la pared."""
    puntos = set()
    for _ in range(max(2, tam // 2)):
        ox, oy = rng.uniform(-tam / 2, tam / 2), rng.uniform(-tam / 3, tam / 3)
        r = rng.uniform(1.0, max(1.5, tam / 3.5))
        for y in range(int(cy + oy - r) - 1, int(cy + oy + r) + 2):
            for x in range(int(cx + ox - r) - 1, int(cx + ox + r) + 2):
                if (x - cx - ox) ** 2 + (y - cy - oy) ** 2 <= r * r and 2 <= y < pared - 1:
                    puntos.add((x % ANCHO, y))
    return puntos


def desconchon(cx, cy, pasos):
    puntos = mancha(cx, cy, pasos)
    for x, y in puntos:
        # el yeso de debajo, más oscuro por arriba (el borde de la pintura le hace sombra)
        sombra = (x, y - 1) not in puntos
        px[x, y] = mas(YESO, -22 if sombra else rng.randint(-6, 6))
    for x, y in puntos:
        # el borde de la pintura que queda: un poco levantado y claro abajo, más oscuro alrededor
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            v = ((x + dx) % ANCHO, y + dy)
            if v not in puntos and 0 <= v[1] < pared:
                px[v] = mas(px[v], 12 if dy == 1 else -14)


for _ in range(DESCONCHONES):
    desconchon(rng.randrange(ANCHO), rng.randint(6, pared - 10), rng.randint(3, 7))
for i in range(DESCONCHONES_GRANDES):
    desconchon(int(ANCHO * (0.3 + 0.45 * i)) + rng.randint(-10, 10), pared - rng.randint(4, 7), rng.randint(9, 13))


def sangre(x, y, t=1.0, c=None):
    x %= ANCHO
    if 0 <= y < pared:
        px[x, y] = mezcla(px[x, y], c or rng.choice(SANGRE), t)


def chorrete(x, y, largo):
    for i in range(largo):
        sangre(x, y + i, 0.9 - 0.4 * i / largo)
    sangre(x, y + largo, 0.9)   # la gota del final, más gorda
    sangre(x + 1, y + largo, 0.6)


def salpicadura(cx, cy):
    for x, y in mancha(cx, cy, rng.randint(9, 12)):
        sangre(x, y, rng.uniform(0.75, 0.95))
    for _ in range(rng.randint(8, 14)):   # las gotitas que saltan alrededor
        a, r = rng.uniform(0, 6.28), rng.uniform(4, 10)
        import math
        sangre(int(cx + math.cos(a) * r * 1.6), int(cy + math.sin(a) * r * 0.8), rng.uniform(0.5, 0.85))
    for _ in range(rng.randint(2, 4)):
        chorrete(cx + rng.randint(-3, 3), cy + 1, rng.randint(5, min(16, pared - cy - 3)))


def mano(cx, cy):
    # la palma, de 5×4, cuatro dedos hacia arriba algo abiertos y el pulgar de lado
    for y in range(4):
        for x in range(5):
            sangre(cx + x, cy + y, 0.85 if (x + y) % 3 else 0.65)
    for dx, largo in ((-1, 3), (1, 4), (3, 4), (5, 3)):
        for k in range(largo):
            sangre(cx + dx + (1 if dx > 2 and k > 1 else -1 if dx < 0 and k > 1 else 0), cy - 1 - k, 0.8)
    sangre(cx - 1, cy + 2, 0.75)
    sangre(cx - 2, cy + 1, 0.7)
    chorrete(cx + 2, cy + 4, 6)


def arrastron(cx, cy, largo):
    # alguien que se apoyó sangrando y fue andando: una franja que se va aclarando
    for i in range(largo):
        t = 0.95 * (1 - 0.7 * i / largo)
        for dy in range(3):
            if rng.random() < 0.95:
                sangre(cx + i, cy + dy + (i // 9), t * rng.uniform(0.6, 1.0))


salpicadura(28, 14)
salpicadura(122, 20)
mano(84, 24)
arrastron(150, 30, 30)

img.save('assets/sprites/pared-pasillo.png')
print('pared-pasillo:', img.size)
