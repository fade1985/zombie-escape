# M95: lo que se cuelga y se pone en el pasillo de los Apartamentos (la planta baja, la de la sala de mantenimiento),
# de imágenes de GPT (13 nov): la alfombra larga del suelo, la manguera de incendios, el extintor y ocho cuadros.
#   assets/sources/pasillo/<nombre>-gpt.webp → assets/sprites/<nombre>.png
# Como los muebles de GPT (tools/muebles_gpt.py, «lo de los muebles»): se quita el negro puro que se llega desde el
# borde, se recorta y se reduce MEZCLANDO colores (LANCZOS premultiplicado), con el borde sin medias tintas.
# La alfombra, además, se alarga hasta lo que mide el pasillo: sus dos puntas y, en medio, un trozo del dibujo (un
# medallón) repetido las veces que hagan falta, todo antes de reducir para que no se vea la costura.
# M108: y la alfombra se ensucia (ensuciar), que limpia desentonaba con el resto del pasillo: camino pisado más oscuro,
# zonas desteñidas, cercos de mugre, manchas, polvo, calvas y las puntas deshilachadas. Con semilla fija: sale igual.
#   py tools/pasillo_gpt.py            (todo)   ·   py tools/pasillo_gpt.py alfombra   (solo la alfombra)
#   y luego Godot --headless --path . --import
import sys
from collections import deque
import numpy as np
from PIL import Image

ORIGEN = "assets/sources/pasillo/%s-gpt.webp"
SPRITE = "assets/sprites/%s.png"
# nombre: (ancho, alto) del sprite, en píxeles del dibujo (en el juego, el doble)
OBJETOS = {
    "manguera": (24, 24), "extintor": (10, 22),
    "cuadro-bosque": (26, 20), "cuadro-flores": (20, 27), "cuadro-pueblo": (20, 17), "cuadro-lago": (26, 17),
    "cuadro-velero": (26, 19), "cuadro-retrato": (20, 26), "cuadro-bodegon": (27, 20), "cuadro-molino": (26, 17),
}
# la alfombra: lo que mide pintada (mapa.dibujar_fondo, de punta a punta del pasillo menos 28 a cada lado)
ALFOMBRA = (776, 36)


def sin_fondo(im):
    """El negro puro que se llega desde el borde, transparente; y recortado."""
    W, H = im.size
    px = im.load()
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 6:
            continue
        fondo[y * W + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(H):
        for x in range(W):
            if fondo[y * W + x]:
                px[x, y] = (0, 0, 0, 0)
    return im.crop(im.getbbox())


def reducir(im, ancho, alto):
    """Mezclando colores (premultiplicado: el fondo transparente no tiñe los bordes), y el borde, sin medias tintas."""
    salida = im.convert("RGBa").resize((ancho, alto), Image.LANCZOS).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    return salida


def periodo(im):
    """Cada cuántos píxeles se repite el dibujo de la alfombra (el que más se parece a sí mismo corrido)."""
    W, H = im.size
    filas = [list(im.crop((0, y, W, y + 1)).convert("L").getdata()) for y in range(H // 4, H * 3 // 4, 4)]
    mejor, cual = None, 0
    for p in range(W // 12, W // 3):
        dif = sum(abs(f[x] - f[x + p]) for f in filas for x in range(W // 6, W - W // 6 - p, 2))
        dif /= max(1, len(range(W // 6, W - W // 6 - p, 2)))
        if mejor is None or dif < mejor:
            mejor, cual = dif, p
    return cual


SEMILLA = 108          # la suciedad sale siempre igual
FLECOS = 3             # lo que salen los hilos por cada punta: el sprite crece eso a cada lado (y sigue centrado)
# tramado de 4x4 (Bayer): para que los degradados de la suciedad salgan a puntitos, como en pixel art, y no lisos
BAYER = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16


def ruido(rng, alto, ancho, paso):
    """Ruido suave (0 a 1): números al azar cada `paso` píxeles, mezclados de unos a otros."""
    rejilla = rng.random((alto // paso + 2, ancho // paso + 2))
    ys, xs = np.arange(alto) / paso, np.arange(ancho) / paso
    y0, x0 = ys.astype(int), xs.astype(int)
    fy, fx = ys - y0, xs - x0
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    arriba = rejilla[y0][:, x0] + (rejilla[y0][:, x0 + 1] - rejilla[y0][:, x0]) * fx
    abajo = rejilla[y0 + 1][:, x0] + (rejilla[y0 + 1][:, x0 + 1] - rejilla[y0 + 1][:, x0]) * fx
    return arriba + (abajo - arriba) * fy[:, None]


def tramar(valor, pasos=4):
    """Un valor de 0 a 1 por píxel, en `pasos` escalones repartidos a puntitos (tramado)."""
    alto, ancho = valor.shape
    umbral = np.tile(BAYER, (alto // 4 + 1, ancho // 4 + 1))[:alto, :ancho]
    return np.floor(np.clip(valor, 0, 1) * pasos + umbral) / pasos


def mancha(rng, alto, ancho, cx, cy, radio):
    """Una mancha de borde irregular: unos cuantos círculos juntos alrededor de (cx, cy)."""
    yy, xx = np.mgrid[0:alto, 0:ancho]
    forma = np.zeros((alto, ancho), bool)
    for _ in range(rng.integers(3, 6)):
        r = radio * rng.uniform(0.5, 1.0)
        ox, oy = cx + rng.uniform(-radio, radio) * 0.8, cy + rng.uniform(-radio, radio) * 0.6
        forma |= (xx - ox) ** 2 + ((yy - oy) * 1.2) ** 2 <= r * r
    return forma


def ensuciar(im):
    """M108: la alfombra, gastada y sucia como el resto del pasillo, sin perder su dibujo."""
    rng = np.random.default_rng(SEMILLA)
    rgba = np.asarray(im, dtype=float)
    col, alfa = rgba[..., :3].copy(), rgba[..., 3].copy()
    alto, ancho = alfa.shape
    gris = lambda c: (c @ np.array([0.30, 0.59, 0.11]))[..., None]
    ys = np.arange(alto)[:, None]

    # 1. el camino pisado: por el centro y a lo largo, más gris y más oscuro, con tramos más gastados (delante de
    # las puertas, donde más se pisa) y otros menos
    pisado = np.exp(-((ys - (alto - 1) / 2) / (alto * 0.24)) ** 2) * (0.35 + 0.75 * ruido(rng, alto, ancho, 46))
    xs = np.arange(ancho)[None, :]
    for cx in rng.uniform(40, ancho - 40, 7):
        pisado += 0.45 * np.exp(-((xs - cx) / 22) ** 2) * np.exp(-((ys - (alto - 1) / 2) / (alto * 0.3)) ** 2)
    pisado = tramar(pisado)[..., None]
    col += (gris(col) - col) * 0.5 * pisado
    col *= 1 - 0.24 * pisado

    # 2. desteñido: manchones más claros y sin color (lejía, sol, fregados)
    destenido = tramar(np.clip((ruido(rng, alto, ancho, 58) - 0.58) * 3.5, 0, 1), 3)[..., None]
    col += (gris(col) * 1.12 + np.array([10, 6, 0]) - col) * 0.55 * destenido

    # 3. cercos de mugre: zonas parduscas de borde duro, más oscuras por dentro
    mugre = 0.65 * ruido(rng, alto, ancho, 13) + 0.35 * ruido(rng, alto, ancho, 4)
    col[mugre > 0.62] *= np.array([0.84, 0.80, 0.74])
    col[mugre > 0.71] *= np.array([0.86, 0.82, 0.76])

    # 4. manchas sueltas: café, grasa y alguna de sangre vieja; con el cerco del borde más oscuro (mancha seca)
    tintes = [np.array([0.66, 0.54, 0.42])] * 4 + [np.array([0.56, 0.56, 0.58])] * 2 + [np.array([0.58, 0.34, 0.30])] * 3
    for tinte in tintes:
        cx, cy = rng.uniform(30, ancho - 30), rng.uniform(7, alto - 8)
        forma = mancha(rng, alto, ancho, cx, cy, rng.uniform(2.0, 4.2))
        borde = forma & ~(np.roll(forma, 1, 0) & np.roll(forma, -1, 0) & np.roll(forma, 1, 1) & np.roll(forma, -1, 1))
        col[forma] *= tinte
        col[borde] *= 0.86
        for _ in range(rng.integers(1, 4)):   # salpicaduras alrededor
            px, py = int(cx + rng.uniform(-7, 7)), int(cy + rng.uniform(-4, 4))
            if 0 <= px < ancho and 0 <= py < alto:
                col[py, px] *= tinte

    # 5. calvas: donde se ha gastado el pelo y asoma la trama de debajo (pardo grisáceo)
    for _ in range(4):
        cx, cy = rng.uniform(40, ancho - 40), rng.uniform(alto * 0.35, alto * 0.65)
        forma = mancha(rng, alto, ancho, cx, cy, rng.uniform(1.2, 2.2))
        col[forma] += (np.array([122, 108, 90]) - col[forma]) * 0.65

    # 6. polvo y migas: puntitos claros y oscuros, muchos más por los bordes largos (junto a la pared)
    junto_borde = (ys < 3) | (ys >= alto - 3)
    azar = rng.random((alto, ancho))
    polvo = azar < np.where(junto_borde, 0.16, 0.03)
    col[polvo] += (np.array([150, 142, 128]) - col[polvo]) * 0.4
    migas = (azar > 1 - np.where(junto_borde, 0.06, 0.015))
    col[migas] *= 0.7

    # 7. bordes largos mordidos: algún hueco de uno a tres píxeles
    for fila in (0, alto - 1):
        x = 0
        while x < ancho:
            if rng.random() < 0.035:
                largo = rng.integers(1, 4)
                alfa[fila, x:x + largo] = 0
                x += largo + 4
            x += 1

    # 8. las puntas, deshilachadas: hilos de 1 a FLECOS píxeles hacia fuera (alguno se ha caído) y algún mordisco
    salida = np.zeros((alto, ancho + 2 * FLECOS, 4))
    salida[:, FLECOS:FLECOS + ancho, :3], salida[:, FLECOS:FLECOS + ancho, 3] = col, alfa
    hilo = np.array([168, 152, 122])
    for y in range(1, alto - 1):
        for lado, x_borde, paso in ((0, FLECOS, -1), (1, FLECOS + ancho - 1, 1)):
            if rng.random() < 0.18:   # mordisco: la punta se ha comido un píxel
                salida[y, x_borde, 3] = 0
                continue
            if y % 2 and rng.random() < 0.6:
                continue
            for i in range(1, rng.integers(0, FLECOS + 1) + 1):
                tono = hilo * (0.92 - 0.12 * i) * rng.uniform(0.85, 1.0)
                salida[y, x_borde + paso * i] = [*tono, 255]
    salida[..., :3] = np.clip(salida[..., :3], 0, 255)
    return Image.fromarray(salida.round().astype(np.uint8), "RGBA")


def alfombra():
    im = sin_fondo(Image.open(ORIGEN % "alfombra").convert("RGBA"))
    W, H = im.size
    p = periodo(im)
    # la punta de la izquierda hasta el primer trozo entero y la de la derecha desde el último (dejando en cada una
    # algo más de un medallón, para que se vea el remate de la cenefa)
    corte_i = W // 2 - p * ((W // 2) // p - 1)
    corte_d = corte_i + p * ((W - corte_i) // p - 1)
    izquierda = im.crop((0, 0, corte_i, H))
    medio = im.crop((corte_i, 0, corte_i + p, H))
    derecha = im.crop((corte_d, 0, W, H))
    largo = round(ALFOMBRA[0] * H / ALFOMBRA[1])   # lo que tiene que medir antes de reducir
    veces = max(1, round((largo - izquierda.width - derecha.width) / p))
    tira = Image.new("RGBA", (izquierda.width + p * veces + derecha.width, H))
    tira.paste(izquierda, (0, 0))
    for i in range(veces):
        tira.paste(medio, (izquierda.width + p * i, 0))
    tira.paste(derecha, (izquierda.width + p * veces, 0))
    ensuciar(reducir(tira, *ALFOMBRA)).save(SPRITE % "alfombra-baja")
    print(f"alfombra: {W}x{H}, se repite cada {p}, {veces} veces → {ALFOMBRA[0]}x{ALFOMBRA[1]}, sucia y con flecos "
          f"({ALFOMBRA[0] + 2 * FLECOS}x{ALFOMBRA[1]})")


if sys.argv[1:] != ["alfombra"]:
    for nombre, tam in OBJETOS.items():
        im = sin_fondo(Image.open(ORIGEN % nombre).convert("RGBA"))
        reducir(im, *tam).save(SPRITE % nombre)
        print(f"{nombre}: {im.size} → {tam[0]}x{tam[1]}")
alfombra()
