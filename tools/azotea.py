"""Las texturas de la azotea del centro comercial, dibujadas con código (gratis, sin PixelLab):

  suelo-hormigon.png   el suelo: losas de hormigón de 64 píxeles con sus juntas, grava, grietas y manchas
                       (128 × 128, se repite sin costura)
  pared-azotea.png     la cara del murete de arriba: abajo el murete (hormigón con su remate) y encima, la ciudad
                       de noche a lo lejos (256 × 48, se repite a lo largo)
  techo-azotea.png     la moldura de encima de la cara (6 píxeles): en la azotea, cielo
  tapa-azotea.png      el murete visto desde arriba (los de los lados y el de abajo): bloques de remate de 32
  helipuerto.png       el helipuerto pintado en el suelo: el círculo amarillo y la H, gastados (160 × 160)

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


def helipuerto():
    rnd = random.Random('helipuerto')
    W = 160
    c = W / 2
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    px = im.load()
    AMARILLO = (196, 160, 52)
    BLANCO = (212, 212, 204)
    for y in range(W):
        for x in range(W):
            d = math.hypot(x + 0.5 - c, y + 0.5 - c)
            color = None
            if 70 <= d < 76:
                color = AMARILLO
            elif 60 <= d < 62:   # el aro fino de dentro
                color = AMARILLO
            # la H: dos palos y el travesaño
            hx, hy = x - c, y - c
            if abs(hy) < 26 and (14 <= abs(hx) < 24 or (abs(hx) < 14 and abs(hy) < 5)):
                color = BLANCO
            if color:
                px[x, y] = color + (230,)
    # gastado: calvas de pintura (a grupos), como si la hubieran pisado y le hubiera dado el sol años
    for i in range(70):
        cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1.0, 4.5)
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                x, y = cx + dx, cy + dy
                if 0 <= x < W and 0 <= y < W and math.hypot(dx, dy) < r and px[x, y][3] > 0 and rnd.random() < 0.8:
                    px[x, y] = px[x, y][:3] + (rnd.choice([0, 0, 90]),)
    for x in range(W):
        for y in range(W):
            if px[x, y][3] > 0 and rnd.random() < 0.12:
                px[x, y] = mezcla(px[x, y][:3], (110, 110, 112), 0.5) + (px[x, y][3],)
    im.save(f'{OUT}/helipuerto.png')


if __name__ == '__main__':
    suelo()
    pared()
    tapa()
    helipuerto()
    print('suelo-hormigon, pared-azotea, techo-azotea, tapa-azotea y helipuerto en', OUT)
