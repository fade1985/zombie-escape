# M95: lo que se cuelga y se pone en el pasillo de los Apartamentos (la planta baja, la de la sala de mantenimiento),
# de imágenes de GPT (13 nov): la alfombra larga del suelo, la manguera de incendios, el extintor y ocho cuadros.
#   assets/sources/pasillo/<nombre>-gpt.webp → assets/sprites/<nombre>.png
# Como los muebles de GPT (tools/muebles_gpt.py, «lo de los muebles»): se quita el negro puro que se llega desde el
# borde, se recorta y se reduce MEZCLANDO colores (LANCZOS premultiplicado), con el borde sin medias tintas.
# La alfombra, además, se alarga hasta lo que mide el pasillo: sus dos puntas y, en medio, un trozo del dibujo (un
# medallón) repetido las veces que hagan falta, todo antes de reducir para que no se vea la costura.
#   py tools/pasillo_gpt.py   (y luego Godot --headless --path . --import)
from collections import deque
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
    reducir(tira, *ALFOMBRA).save(SPRITE % "alfombra-baja")
    print(f"alfombra: {W}x{H}, se repite cada {p}, {veces} veces → {ALFOMBRA[0]}x{ALFOMBRA[1]}")


for nombre, tam in OBJETOS.items():
    im = sin_fondo(Image.open(ORIGEN % nombre).convert("RGBA"))
    reducir(im, *tam).save(SPRITE % nombre)
    print(f"{nombre}: {im.size} → {tam[0]}x{tam[1]}")
alfombra()
