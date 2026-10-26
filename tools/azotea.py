"""Las texturas de la azotea del centro comercial, dibujadas con código (gratis, sin PixelLab):

  suelo-hormigon.png   el suelo: losas de hormigón de 64 píxeles con sus juntas, grava, grietas y manchas
                       (128 × 128, se repite sin costura)
  pared-azotea.png     la cara del murete de arriba: abajo el murete (hormigón con su remate) y encima, la ciudad
                       de noche a lo lejos (256 × 48, se repite a lo largo)
  techo-azotea.png     la moldura de encima de la cara (6 píxeles): en la azotea, cielo
  tapa-azotea.png      el murete visto desde arriba (los de los lados y el de abajo): bloques de remate de 32
  helipuerto.png       el helipuerto: la plataforma elevada (losas claras, el círculo amarillo y la H gastados, un
                       borde de franjas y la cara de delante) y, a su izquierda, la rampa de chapa con sus
                       barandillas (384 × 271; las medidas, las de planta.gd: PLATAFORMA, RAMPA...)

  py tools/azotea.py   → assets/sprites/
Siempre salen iguales (cada una con su semilla).
"""
import math, random
from PIL import Image, ImageDraw

OUT = 'assets/sprites'


def mezcla(c, d, k):
    return tuple(int(a + (b - a) * k) for a, b in zip(c, d))


def ruido(rnd, c, cuanto):
    n = rnd.randint(-cuanto, cuanto)
    return tuple(max(0, min(255, v + n)) for v in c)


def suelo():
    rnd = random.Random('hormigon')
    W = 128
    base = (126, 128, 132)
    im = Image.new('RGB', (W, W), base)
    px = im.load()
    # cada losa, de un tono algo distinto
    tonos = {(i, j): rnd.randint(-6, 6) for i in range(2) for j in range(2)}
    for y in range(W):
        for x in range(W):
            t = tonos[(x // 64, y // 64)]
            c = tuple(v + t for v in base)
            px[x, y] = ruido(rnd, c, 4)
    # grava: puntitos sueltos más claros y más oscuros
    for i in range(420):
        x, y = rnd.randrange(W), rnd.randrange(W)
        px[x, y] = ruido(rnd, (150, 151, 154) if rnd.random() < 0.5 else (98, 100, 104), 6)
    # manchas de humedad (se dibujan también desplazadas para que casen en los bordes)
    for i in range(7):
        cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.randint(5, 14)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                d = math.hypot(dx, dy * 1.3) / r
                if d < 1 and rnd.random() < 1.1 - d:
                    x, y = (cx + dx) % W, (cy + dy) % W
                    px[x, y] = mezcla(px[x, y], (92, 94, 98), 0.35)
    # grietas: caminos finos que van torciéndose
    for i in range(4):
        x, y = rnd.randrange(W), rnd.randrange(W)
        a = rnd.uniform(0, math.tau)
        for k in range(rnd.randint(10, 26)):
            px[int(x) % W, int(y) % W] = (72, 73, 78)
            a += rnd.uniform(-0.6, 0.6)
            x += math.cos(a)
            y += math.sin(a)
    # las juntas de las losas: raya oscura y, debajo y a la derecha, un filo de luz
    for k in range(0, W, 64):
        for i in range(W):
            px[i, k] = (88, 90, 96)
            px[k, i] = (88, 90, 96)
            px[i, (k + 1) % W] = mezcla(px[i, (k + 1) % W], (160, 162, 166), 0.4)
            px[(k + 1) % W, i] = mezcla(px[(k + 1) % W, i], (160, 162, 166), 0.4)
    im.save(f'{OUT}/suelo-hormigon.png')


def cielo(y, alto):
    """El color del cielo de noche a esa altura (arriba más oscuro)"""
    return mezcla((14, 18, 34), (34, 40, 64), y / alto)


def pared():
    rnd = random.Random('murete')
    W, H = 256, 48
    MURETE = 18   # lo que mide el murete (abajo)
    im = Image.new('RGB', (W, H))
    px = im.load()
    cielo_h = H - MURETE
    for y in range(cielo_h):
        for x in range(W):
            px[x, y] = cielo(y + 6, cielo_h + 6)
    for i in range(14):   # estrellas
        px[rnd.randrange(W), rnd.randrange(0, cielo_h - 12)] = rnd.choice([(150, 150, 170), (110, 112, 140)])
    dr = ImageDraw.Draw(im)
    # la ciudad a lo lejos: dos filas de edificios (los de detrás, más claros por la bruma), con ventanas
    for fila, (color, alto_max, luz) in enumerate([((30, 34, 54), 20, 0.10), ((18, 20, 34), 14, 0.16)]):
        x = -rnd.randint(0, 10)
        while x < W:
            ancho = rnd.randint(10, 26)
            alto = rnd.randint(5, alto_max)
            y0 = cielo_h - alto
            dr.rectangle((x, y0, x + ancho - 1, cielo_h - 1), fill=color)
            if rnd.random() < 0.25 and fila == 0:   # una antena
                dr.line((x + ancho // 2, y0 - rnd.randint(3, 6), x + ancho // 2, y0), fill=color)
            for wy in range(y0 + 2, cielo_h - 1, 3):
                for wx in range(x + 2, x + ancho - 2, 3):
                    if rnd.random() < luz and 0 <= wx < W:
                        px[wx, wy] = rnd.choice([(196, 170, 96), (170, 150, 90), (120, 140, 160)])
            x += ancho + rnd.randint(0, 3)
    # el murete: el remate (más claro, con su filo) y la cara, con juntas cada 32 y churretes de agua
    y0 = cielo_h
    for y in range(y0, H):
        for x in range(W):
            if y < y0 + 3:
                c = (150, 151, 154) if y == y0 else (128, 129, 132)
            else:
                c = mezcla((108, 110, 114), (84, 86, 90), (y - y0) / MURETE)
            px[x, y] = ruido(rnd, c, 4)
    for x in range(W):
        px[x, y0 + 3] = (70, 72, 78)   # la sombra debajo del remate
    for x in range(0, W, 32):
        for y in range(y0 + 4, H):
            px[x, y] = (78, 80, 86)
    for i in range(10):
        x = rnd.randrange(W)
        for y in range(y0 + 4, y0 + 4 + rnd.randint(4, 12)):
            if y < H:
                px[x, y] = mezcla(px[x, y], (60, 62, 66), 0.5)
    im.save(f'{OUT}/pared-azotea.png')
    # la moldura de encima: el cielo de más arriba
    techo = Image.new('RGB', (W, 6))
    for y in range(6):
        for x in range(W):
            techo.putpixel((x, y), cielo(y, cielo_h + 6))
    for i in range(3):
        techo.putpixel((rnd.randrange(W), rnd.randrange(6)), (120, 122, 150))
    techo.save(f'{OUT}/techo-azotea.png')


def tapa():
    rnd = random.Random('remate')
    W = 128
    im = Image.new('RGB', (W, W))
    px = im.load()
    for y in range(W):
        for x in range(W):
            bloque = (x // 32) * 7 + (y // 32) * 3
            c = tuple(v + (bloque % 5) * 2 - 4 for v in (138, 139, 142))
            px[x, y] = ruido(rnd, c, 4)
    for i in range(240):
        px[rnd.randrange(W), rnd.randrange(W)] = rnd.choice([(110, 112, 116), (158, 160, 162), (96, 106, 88)])
    for k in range(0, W, 32):
        for i in range(W):
            px[i, k] = (96, 98, 104)
            px[k, i] = (96, 98, 104)
    im.save(f'{OUT}/tapa-azotea.png')


# Las medidas del helipuerto, en píxeles del dibujo (la mitad de las unidades de planta.gd: PLATAFORMA, RAMPA...)
RAMPA_LARGO, RAMPA_ANCHO = 64, 48
ARRIBA_ANCHO, ARRIBA_ALTO = 320, 256
CARA = 12          # lo que se eleva: la cara de delante
SOMBRA = 3
BORDE = 4          # el borde de franjas de arriba
BARANDILLA = 3
HORMIGON_CARA = ((114, 116, 122), (72, 74, 80))   # la cara, de arriba abajo


def helipuerto():
    rnd = random.Random('helipuerto')
    R = RAMPA_LARGO
    W, H = R + ARRIBA_ANCHO, ARRIBA_ALTO + CARA + SOMBRA
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = im.load()
    ry0 = ARRIBA_ALTO // 2 - RAMPA_ANCHO // 2
    ry1 = ry0 + RAMPA_ANCHO

    # lo de arriba: losas de hormigón de 32, más claras que el suelo de la azotea, con sus juntas y grava
    for y in range(ARRIBA_ALTO):
        for x in range(R, W):
            lx = x - R
            t = ((lx // 32) * 5 + (y // 32) * 3) % 5 - 2
            c = tuple(v + t * 2 for v in (98, 108, 106))
            if lx % 32 == 0 or y % 32 == 0:
                c = mezcla(c, (70, 78, 78), 0.55)
            px[x, y] = ruido(rnd, c, 3) + (255,)
    for i in range(830):
        x, y = rnd.randrange(R, W), rnd.randrange(ARRIBA_ALTO)
        px[x, y] = ruido(rnd, (116, 126, 124) if rnd.random() < 0.5 else (80, 90, 88), 5) + (255,)

    # el círculo amarillo y la H blanca, en medio, gastados (calvas de pintura a grupos, como de años de sol)
    cx, cy = R + ARRIBA_ANCHO / 2, ARRIBA_ALTO / 2
    pintura = {}
    for y in range(ARRIBA_ALTO):
        for x in range(R, W):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            hx, hy = x + 0.5 - cx, y + 0.5 - cy
            if 70 <= d < 76 or 60 <= d < 62:   # el aro gordo y el fino de dentro
                pintura[(x, y)] = (204, 166, 54)
            if abs(hy) < 26 and (14 <= abs(hx) < 24 or (abs(hx) < 14 and abs(hy) < 5)):
                pintura[(x, y)] = (222, 222, 214)
    calvas = set()
    for i in range(133):
        ox, oy, r = rnd.uniform(R, W), rnd.uniform(0, ARRIBA_ALTO), rnd.uniform(1.0, 4.5)
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                if math.hypot(dx, dy) < r and rnd.random() < 0.8:
                    calvas.add((int(ox) + dx, int(oy) + dy))
    for (x, y), c in pintura.items():
        if (x, y) in calvas:
            if rnd.random() < 0.3:
                px[x, y] = mezcla(px[x, y][:3], c, 0.35) + (255,)
            continue
        if rnd.random() < 0.12:
            c = mezcla(c, (98, 108, 106), 0.45)
        px[x, y] = ruido(rnd, c, 4) + (255,)

    # el borde: franjas amarillas y negras en diagonal (menos en la boca de la rampa), con el canto de fuera oscuro
    for y in range(ARRIBA_ALTO):
        for x in range(R, W):
            lx = x - R
            if not (lx < BORDE or lx >= ARRIBA_ANCHO - BORDE or y < BORDE or y >= ARRIBA_ALTO - BORDE):
                continue
            if lx < BORDE and ry0 <= y < ry1:
                continue
            c = (206, 170, 58) if ((x + y) // 4) % 2 == 0 else (44, 44, 48)
            if lx == 0 or lx == ARRIBA_ANCHO - 1 or y == 0 or y == ARRIBA_ALTO - 1:
                c = mezcla(c, (28, 28, 32), 0.5)
            if rnd.random() < 0.1:
                c = mezcla(c, (120, 120, 122), 0.4)
            px[x, y] = ruido(rnd, c, 3) + (255,)
    # luces de balizamiento: en las esquinas y en medio de cada lado (menos el de la rampa), verdes
    for bx, by in [(R + 6, 6), (W - 7, 6), (R + 6, ARRIBA_ALTO - 7), (W - 7, ARRIBA_ALTO - 7),
                   (int(cx) - 1, 6), (int(cx) - 1, ARRIBA_ALTO - 7), (W - 7, int(cy) - 1)]:
        for dx in range(2):
            for dy in range(2):
                px[bx + dx, by + dy] = ((150, 236, 150) if dx == 0 and dy == 0 else (70, 170, 90)) + (255,)

    # la cara de delante: hormigón más oscuro hacia abajo, el canto de arriba claro y una junta cada 32
    for j in range(CARA):
        y = ARRIBA_ALTO + j
        for x in range(R, W):
            c = mezcla(*HORMIGON_CARA, j / (CARA - 1))
            if j == 0:
                c = (170, 172, 176)
            elif (x - R) % 32 == 0:
                c = mezcla(c, (56, 58, 62), 0.6)
            px[x, y] = ruido(rnd, c, 3) + (255,)
    for i in range(30):   # desconchones
        x, y = rnd.randrange(R, W), rnd.randrange(ARRIBA_ALTO + 2, ARRIBA_ALTO + CARA)
        px[x, y] = (62, 64, 70, 255)
    # la sombra que echa en el suelo
    for i in range(SOMBRA):
        for x in range(R + 1, W):
            px[x, ARRIBA_ALTO + CARA + i] = (0, 0, 0, [90, 55, 25][i])

    # la rampa: chapa de lágrimas, más oscura abajo y más clara arriba (así se ve que sube); entra en el borde
    for y in range(ry0 + BARANDILLA, ry1 - BARANDILLA):
        for x in range(R + BORDE):
            c = mezcla((88, 94, 102), (140, 146, 152), min(1.0, x / R))
            ox, oy = x % 4, (y - ry0) % 4
            celda = (x // 4 + (y - ry0) // 4) % 2
            if (celda == 0 and ox == oy and ox in (1, 2)) or (celda == 1 and ox + oy == 3 and ox in (1, 2)):
                c = mezcla(c, (196, 200, 204), 0.45)
            elif (celda == 0 and ox == oy + 1 and ox in (2, 3)) or (celda == 1 and ox + oy == 4 and ox in (2, 3)):
                c = mezcla(c, (50, 54, 60), 0.4)
            if x == 0:
                c = mezcla(c, (40, 42, 46), 0.5)   # el canto de abajo, contra el suelo
            px[x, y] = ruido(rnd, c, 2) + (255,)
    # las barandillas, amarillas, a los dos lados de la rampa (con un poste cada 16)
    for x in range(R):
        for j in range(BARANDILLA):
            for y in (ry0 + j, ry1 - 1 - j):
                c = [(150, 120, 40), (226, 190, 70), (120, 96, 34)][j if y < cy else BARANDILLA - 1 - j]
                if x % 16 == 0:
                    c = mezcla(c, (60, 60, 64), 0.5)
                px[x, y] = c + (255,)
    # la cara de la rampa: un triángulo debajo, que crece de nada (contra el suelo) a lo que se eleva la plataforma
    for x in range(R):
        alto = round(CARA * (x + 1) / R)
        for j in range(alto):
            c = mezcla(*HORMIGON_CARA, j / (CARA - 1))
            px[x, ry1 + j] = ruido(rnd, c, 3) + (255,)
        for i in range(SOMBRA if x > 2 else 0):
            if px[x, ry1 + alto + i][3] == 0:
                px[x, ry1 + alto + i] = (0, 0, 0, [90, 55, 25][i])
    im.save(f'{OUT}/helipuerto.png')


if __name__ == '__main__':
    suelo()
    pared()
    tapa()
    helipuerto()
    print('suelo-hormigon, pared-azotea, techo-azotea, tapa-azotea y helipuerto en', OUT)
