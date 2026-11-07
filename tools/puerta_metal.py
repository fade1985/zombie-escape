# La puerta metálica de la sala de mantenimiento (la del despacho al taller, en un tabique de lado), del 7 nov. Sale tal
# cual de las imágenes de GPT que trajo el dueño, pedidas ya con las medidas y la forma de las de madera para que gire
# igual (puerta_bano.gd):
#   assets/sources/puerta-metal-gpt-2.webp      a la izquierda la cerrada, vista desde arriba (la tira de canto, con el
#                                               pomo redondo cerca de la punta de abajo, la que abre), y a la derecha la
#                                               abierta, de pie y torcida, con su pomo redondo. Sobre negro, con un brillo
#   assets/sources/puerta-metal-gpt-frente.webp la de frente, la que se ve mientras gira. Sobre transparente
# Se quita el fondo (en la primera, lo negro y gris que se llega desde el borde; el contorno, algo morado, se queda), se
# recorta cada una y se reduce a su tamaño tomando el píxel del centro de cada cuadrito (sin mezclar colores):
#   puerta-metal-lado-cerrada  16x32, como puerta-bano-lado-cerrada
#   puerta-metal-abierta-lado  14x67, como puerta-bano-abierta-lado
#   puerta-metal               28x43, como puerta-bano
# Antes salía de otra imagen de GPT (puerta-metal-gpt.webp) retocada; y se probó una verde a mano (puerta-metal-foto.webp).
#   py tools/puerta_metal.py   (y luego Godot --headless --path . --import)
from collections import deque
from PIL import Image

CARPETA = "assets/sprites/"
LINEA = (29, 27, 44)
DOS = Image.open("assets/sources/puerta-metal-gpt-2.webp").convert("RGBA")
FRENTE = Image.open("assets/sources/puerta-metal-gpt-frente.webp").convert("RGBA")
SALEN = [("puerta-metal-lado-cerrada", DOS, (300, 0, 640, 1024), (14, 32)),   # (y luego, el contorno a los lados: 16)
         ("puerta-metal", FRENTE, (0, 0, FRENTE.width, FRENTE.height), (28, 43))]


def es_fondo(c):
    r, g, b, a = c
    return a < 128 or max(r, g, b) <= 30 and b - g < 6   # (negro, o el brillo gris de alrededor; el contorno tira a morado)


for nombre, imagen, caja, tam in SALEN:
    trozo = imagen.crop(caja)
    p = trozo.load()
    w, h = trozo.size
    vistos = set()
    cola = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while cola:
        x, y = cola.popleft()
        if (x, y) in vistos or not (0 <= x < w and 0 <= y < h) or not es_fondo(p[x, y]):
            continue
        vistos.add((x, y))
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for x, y in vistos:
        p[x, y] = (0, 0, 0, 0)
    trozo = trozo.crop(trozo.getbbox())
    # el píxel del centro de cada cuadrito; lo que queda muy oscuro, el contorno de siempre
    sale = Image.new("RGBA", tam, (0, 0, 0, 0))
    for y in range(tam[1]):
        for x in range(tam[0]):
            c = trozo.getpixel((int((x + 0.5) * trozo.width / tam[0]), int((y + 0.5) * trozo.height / tam[1])))
            if c[3] >= 128:
                sale.putpixel((x, y), (LINEA + (255,)) if max(c[:3]) < 40 else c[:3] + (255,))
    if nombre == "puerta-metal-lado-cerrada":
        # al quitar el negro de alrededor se va también su contorno, casi del mismo color: se le vuelve a poner
        ancha = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
        ancha.paste(sale, (1, 0))
        borde = [(x, y) for y in range(32) for x in range(16) if not ancha.getpixel((x, y))[3] and any(
            0 <= x + d < 16 and ancha.getpixel((x + d, y))[3] == 255 and ancha.getpixel((x + d, y))[:3] != LINEA
            for d in (-1, 1))]
        for q in borde:
            ancha.putpixel(q, LINEA + (255,))
        sale = ancha
    sale.save(CARPETA + nombre + ".png")
    print(nombre, sale.size, "· recorte de GPT:", trozo.size)

# La abierta, en la forma exacta de la de madera (puerta-bano-abierta-lado: así el juego la pone y la gira igual): cada
# columna toma su columna de la puerta de GPT, desde su borde de arriba hasta el contorno de abajo (lo de debajo es el
# brillo del fondo), estirada a lo que mide la de madera; el contorno y la sombra del suelo, los de la madera
X0, X1 = 873, 1160   # la abierta, de punta a punta, en la imagen de GPT
madera = Image.open(CARPETA + "puerta-bano-abierta-lado.png").convert("RGBA")
abierta = Image.new("RGBA", madera.size, (0, 0, 0, 0))
w, h = madera.size


def es_contorno(c):
    return max(c[:3]) < 45 and c[2] - c[1] >= 5


for x in range(w):
    filas = [y for y in range(h) if madera.getpixel((x, y))[3]]
    if not filas:
        continue
    arriba, abajo = filas[0], filas[-1]
    gx = int(X0 + (x + 0.5) * (X1 - X0) / w)
    columna = [DOS.getpixel((gx, y)) for y in range(DOS.height)]
    lleno = [y for y, c in enumerate(columna) if max(c[:3]) > 45 or es_contorno(c)]
    g_arriba = lleno[0]
    g_abajo = max(y for y, c in enumerate(columna) if es_contorno(c))
    for y in filas:
        c = madera.getpixel((x, y))
        if c[3] < 255 or y > abajo - 3 and x > 1:
            abierta.putpixel((x, y), c)   # (la sombra del suelo)
        elif y == arriba or x == w - 1 or y == abajo - 3 and x > 1:
            abierta.putpixel((x, y), LINEA + (255,))
        else:
            gy = int(g_arriba + 1 + (y - arriba - 0.5) * (g_abajo - g_arriba - 1) / max(1, abajo - 3 - arriba))
            g = columna[min(g_abajo - 1, max(g_arriba + 1, gy))]
            abierta.putpixel((x, y), (LINEA + (255,)) if max(g[:3]) < 40 else g[:3] + (255,))
abierta.save(CARPETA + "puerta-metal-abierta-lado.png")
print("puerta-metal-abierta-lado", abierta.size)
