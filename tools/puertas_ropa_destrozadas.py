# Las puertas metálicas de la tienda de ropa, destrozadas (19 nov, el dueño; imágenes de GPT sobre negro puro):
#   assets/sources/ropa/puerta-almacen-destrozada-gpt.webp         → puerta-almacen-ropa.png              (28 × 43, la del almacén de frente)
#   assets/sources/ropa/puerta-almacen-abierta-destrozada-gpt.webp → puerta-almacen-ropa-abierta.png      (14 × 67, abierta y torcida)
#   assets/sources/ropa/puerta-aseo-destrozada-gpt.webp            → puerta-aseo-ropa-lado-cerrada.png    (16 × 32, la izquierda: de canto)
#                                                                  → puerta-aseo-ropa-abierta-lado.png    (14 × 67, la derecha: abierta y torcida)
# Con la MISMA forma que las de antes (puerta-trastero-metal, puerta-trastero-metal-abierta, puerta-metal-lado-cerrada y
# puerta-metal-abierta-lado, que siguen en la sala de mantenimiento): cada columna del dibujo de antes toma su columna de la
# imagen de GPT, de su borde de arriba al de abajo, estirada a lo que mide; y luego se reduce MEZCLANDO colores (LANCZOS, alfa
# premultiplicado, como tools/muebles_gpt.py). El contorno es el de antes (también la sombra del suelo de las abiertas).
# (La cerrada de canto también: las columnas del pomo, que sobresale, toman las del pomo de GPT y se estiran a lo que medía el de antes.)
# puerta_bano.gd: METAL_ROPA y TRASTERO_METALIZADA (mapa.gd, poner_hojas, solo en la tienda de ropa)
#   py tools/puertas_ropa_destrozadas.py   (y luego Godot --headless --path . --import)
from collections import deque
import numpy as np
from PIL import Image

S = "assets/sources/ropa/"
D = "assets/sprites/"
K = 16   # cada píxel del dibujo, K × K de la imagen estirada antes de reducir


def sin_fondo(im):
    # el negro puro que se llega desde el borde, transparente
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    fondo = bytearray(w * h)
    cola = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or fondo[y * w + x] or max(px[x, y][:3]) >= 6:
            continue
        fondo[y * w + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    a = np.asarray(im).copy()
    a[..., 3] = np.where(np.frombuffer(bytes(fondo), np.uint8).reshape(h, w) == 1, 0, 255)
    im = Image.fromarray(a, "RGBA")
    return im.crop(im.getbbox())


def reducir(hi, tam):
    # mezclando colores, con el alfa premultiplicado (el fondo transparente no tiñe los bordes)
    return hi.convert("RGBa").resize(tam, Image.LANCZOS).convert("RGBA")


def con_forma(gpt, viejo, salida):
    """La imagen de GPT metida en la forma del dibujo viejo, columna a columna"""
    g = np.asarray(gpt)
    gh, gw = g.shape[:2]
    entero = Image.open(D + viejo).convert("RGBA")
    caja = entero.getbbox()   # (solo lo que ocupa: la cerrada de canto tiene una columna vacía a cada lado)
    v = np.asarray(entero.crop(caja))
    h, w = v.shape[:2]
    hi = np.zeros((h * K, w * K, 4), np.uint8)
    for x in range(w):
        filas = np.where(v[:, x, 3] == 255)[0]
        if not len(filas):
            continue
        arriba, abajo = filas[0], filas[-1] + 1
        for s in range(K):
            gx = min(gw - 1, int((x + (s + 0.5) / K) * gw / w))
            lleno = np.where(g[:, gx, 3] > 0)[0]
            if not len(lleno):
                continue
            g0, g1 = lleno[0], lleno[-1] + 1
            for Y in range(arriba * K, abajo * K):
                gy = int(g0 + (Y - arriba * K + 0.5) * (g1 - g0) / ((abajo - arriba) * K))
                hi[Y, x * K + s] = g[min(g1 - 1, gy), gx]
    r = np.asarray(reducir(Image.fromarray(hi, "RGBA"), (w, h))).copy()
    # el contorno, el de antes: lo opaco de antes, opaco; y la sombra del suelo (lo medio transparente), la de antes
    r[..., 3] = np.where(v[..., 3] == 255, 255, 0)
    medias = (v[..., 3] > 0) & (v[..., 3] < 255)
    r[medias] = v[medias]
    # y la línea oscura de alrededor, la de antes (los píxeles oscuros del borde de lo opaco), para que se lea igual sobre el suelo
    lleno = np.pad(v[..., 3] == 255, 1)
    borde = (v[..., 3] == 255) & ~(lleno[:-2, 1:-1] & lleno[2:, 1:-1] & lleno[1:-1, :-2] & lleno[1:-1, 2:])
    linea = borde & (v[..., :3].max(axis=2) < 50)
    r[linea] = v[linea]
    sale = Image.new("RGBA", entero.size, (0, 0, 0, 0))
    sale.paste(Image.fromarray(r, "RGBA"), caja[:2])
    sale.save(D + salida)
    print(salida, sale.size)


con_forma(sin_fondo(Image.open(S + "puerta-almacen-destrozada-gpt.webp")), "puerta-trastero-metal.png", "puerta-almacen-ropa.png")
con_forma(sin_fondo(Image.open(S + "puerta-almacen-abierta-destrozada-gpt.webp")), "puerta-trastero-metal-abierta.png",
          "puerta-almacen-ropa-abierta.png")
aseo = Image.open(S + "puerta-aseo-destrozada-gpt.webp")
con_forma(sin_fondo(aseo.crop((aseo.width // 2, 0, aseo.width, aseo.height))), "puerta-metal-abierta-lado.png",
          "puerta-aseo-ropa-abierta-lado.png")

con_forma(sin_fondo(aseo.crop((0, 0, aseo.width // 2, aseo.height))), "puerta-metal-lado-cerrada.png",
          "puerta-aseo-ropa-lado-cerrada.png")
