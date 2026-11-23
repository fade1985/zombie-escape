# El panel de martillos de la ferretería (23 nov, el dueño): el panel perforado vacío de GPT
# (assets/sources/centro/panel-vacio-gpt.webp, el mismo estilo que el de llaves) y, encima, el martillo de GPT
# (assets/sources/centro/martillo-gpt.webp) colgado varias veces, de varios tamaños, con sus dos ganchos debajo de la
# cabeza, su sombra y su etiqueta de precio naranja. Hay huecos vacíos (solo ganchos y etiqueta) y uno colgado torcido
# de un solo gancho. Se monta todo a tamaño de GPT y luego se reduce mezclando colores, como tools/muebles_gpt.py,
# para que los martillos y el panel queden con el mismo acabado.
#   py tools/panel_martillos.py           → assets/sprites/panel-martillos.png (136x86, a escala 1, como panel-llaves.png)
#   (y luego Godot --headless --path . --import)
import os
from collections import deque
from PIL import Image, ImageDraw

PANEL = "assets/sources/centro/panel-vacio-gpt.webp"
MARTILLO = "assets/sources/centro/martillo-gpt.webp"
SALIDA = "assets/sprites/panel-martillos.png"
ANCHO, ALTO = 136, 86

CONTORNO = (26, 26, 26, 255)      # casi negro, como los contornos de GPT
B = 11                            # el tamaño de un «píxel» de GPT en sus imágenes (1536 / 136)

# Cada martillo: (centro x, alto de la cabeza y, alto del martillo, giro en grados, qué hay)
#   "martillo": colgado de sus dos ganchos; "vacio": solo los ganchos y la etiqueta; "torcido": colgado de un gancho
# (en píxeles del panel de GPT ya recortado, unos 1387x876)
FILA_1, FILA_2 = 120, 505
HUECOS = [
    (175, FILA_1, 310, 0, "martillo"),
    (400, FILA_1, 310, 0, "vacio"),
    (625, FILA_1, 290, 0, "martillo"),
    (850, FILA_1, 310, 9, "torcido"),
    (1075, FILA_1, 290, 0, "martillo"),
    (160, FILA_2, 255, 0, "martillo"),
    (355, FILA_2, 215, 0, "martillo"),
    (550, FILA_2, 255, 0, "vacio"),
    (745, FILA_2, 215, 0, "martillo"),
    (940, FILA_2, 255, 0, "martillo"),
    (1140, FILA_2, 215, 0, "martillo"),
]


def sin_fondo(ruta):
    """La imagen de GPT sin el negro puro que se llega desde el borde, recortada (como muebles_gpt.pasar)."""
    im = Image.open(ruta).convert("RGBA")
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


def gancho(d, x, y):
    """Un gancho del panel visto de frente: la punta de metal gris con su brillo y su contorno (x, y: arriba en medio)."""
    d.rounded_rectangle((x - 3 * B // 2, y, x + 3 * B // 2, y + 3 * B), radius=B // 2, fill=CONTORNO)
    d.rectangle((x - B // 2, y + B // 2, x + B // 2, y + 2 * B), fill=(118, 120, 126, 255))
    d.rectangle((x - B // 2, y + B // 2, x + B // 2, y + B), fill=(160, 162, 168, 255))


def etiqueta(d, x, y):
    """La etiqueta de precio naranja, lisa (x, y: arriba en medio)."""
    d.rectangle((x - 4 * B, y, x + 4 * B - 1, y + 3 * B - 1), fill=(70, 30, 10, 255))
    d.rectangle((x - 3 * B, y + B, x + 3 * B - 1, y + 2 * B - 1), fill=(255, 130, 30, 255))
    d.rectangle((x - 3 * B, y + B, x + 3 * B - 1, y + B + 4), fill=(255, 175, 80, 255))


panel = sin_fondo(PANEL)
martillo = sin_fondo(MARTILLO)
mw, mh = martillo.size
CABEZA = 0.17      # dónde acaba la cabeza del martillo (en tanto por uno de su alto)

capa = Image.new("RGBA", panel.size, (0, 0, 0, 0))     # los ganchos y las etiquetas
sombras = Image.new("RGBA", panel.size, (0, 0, 0, 0))
martillos = Image.new("RGBA", panel.size, (0, 0, 0, 0))
d = ImageDraw.Draw(capa)

for cx, y, alto, giro, que in HUECOS:
    ancho = round(mw * alto / mh)
    m = martillo.resize((ancho, alto), Image.LANCZOS)
    # el mango: su centro en el dibujo (el martillo no es simétrico: la uña sobresale más que la boca)
    col = m.crop((0, int(alto * 0.6), ancho, int(alto * 0.6) + 1)).split()[3].load()
    xs = [x for x in range(ancho) if col[x, 0] > 0]
    mango_c = (xs[0] + xs[-1]) // 2
    mango_w = xs[-1] - xs[0]
    cabeza_y = round(alto * CABEZA)
    # los dos ganchos, a los lados del mango, justo debajo de la cabeza (la cabeza se apoya en ellos: tapa su parte de arriba)
    gy = y + round(alto * 0.15)
    izq, der = cx - mango_w // 2 - 3 * B // 2, cx + mango_w // 2 + 3 * B // 2
    if que == "torcido":
        gancho(d, izq, gy)
        gancho(d, der, gy)
        m = m.rotate(-giro, resample=Image.BICUBIC, expand=True, center=(mango_c, cabeza_y))
        x0, y0 = cx - m.width // 2 + 2 * B, y - B
    else:
        gancho(d, izq, gy)
        gancho(d, der, gy)
        x0, y0 = cx - mango_c, y
    etiqueta(d, cx, y + alto + 2 * B)
    if que == "vacio":
        continue
    martillos.alpha_composite(m, (x0, y0))
    sombra = Image.new("RGBA", m.size, (0, 0, 0, 0))
    sombra.putalpha(m.split()[3].point(lambda v: 95 if v > 110 else 0))
    sombras.alpha_composite(sombra, (x0 + B, y0 + B))

junto = panel.copy()
junto.alpha_composite(sombras)
junto.alpha_composite(capa)
junto.alpha_composite(martillos)
os.makedirs("capturas", exist_ok=True)
junto.save("capturas/panel-martillos-grande.png")     # el montaje a tamaño de GPT, para mirarlo (capturas/ no va en git)
# reducido mezclando colores (premultiplicado) y el borde sin medias tintas, como muebles_gpt.pasar
salida = junto.convert("RGBa").resize((ANCHO, ALTO), Image.LANCZOS).convert("RGBA")
salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
salida.save(SALIDA)
print(f"{SALIDA}: {ANCHO}x{ALTO} (de {panel.size[0]}x{panel.size[1]})")
