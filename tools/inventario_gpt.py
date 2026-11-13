# Las imágenes de GPT del inventario (M100, 13 nov), reducidas «como los muebles» (tools/muebles_gpt.py): se quita
# el negro puro que se llega desde el borde y se reduce MEZCLANDO colores (LANCZOS premultiplicado), con el borde sin
# medias tintas. Las fuentes, en assets/sources/inventario/; los dibujos, en assets/ui/ (se pintan a 2: cada píxel del
# dibujo, 2 de la pantalla).
#   - mochila: el fondo, la mochila de lona abierta. Su forro tiene que llenar el sitio de las casillas (FORRO_EN, en
#     la pantalla), así que se reduce a que el forro mida de alto justo eso y, si hace falta, se ensancha (o se
#     estrecha) repitiendo (o quitando) una franja limpia del medio, sin asa, hebillas ni manchas. inventario.gd la
#     pone donde dice MOCHILA_EN (lo escribe esta herramienta al acabar).
#   - papel: la hoja cuadriculada de la ficha, con su clip (el papel, 238 × 434 de la pantalla, como FICHA).
#   - cinta: la tira de cinta de los títulos (inventario.gd la estira al largo del texto: NinePatch, los extremos rotos
#     quietos).
#   - etiqueta: la etiqueta de cartón de la llave, con su ojal y su cordel.
#   py tools/inventario_gpt.py            → todas
#   py tools/inventario_gpt.py papel      → solo esa
#   (y luego Godot --headless --path . --import)
import sys
from collections import deque
from PIL import Image

FUENTES = "assets/sources/inventario/"


def sin_fondo(im):
    """El negro puro (< 6) que se llega desde el borde, transparente."""
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
    return im


def reducir(im, ancho, alto):
    salida = im.convert("RGBa").resize((ancho, alto), Image.LANCZOS).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    return salida


def simple(nombre, ancho, alto=0):
    """Recortada a lo que tiene y reducida a "ancho" (y "alto"; si no se dice, según su proporción)."""
    im = sin_fondo(Image.open(FUENTES + nombre + "-gpt.webp").convert("RGBA"))
    im = im.crop(im.getbbox())
    alto = alto or round(im.height * ancho / im.width)
    reducir(im, ancho, alto).save("assets/ui/inventario-%s.png" % nombre)
    print(f"assets/ui/inventario-{nombre}.png: {ancho}x{alto}")


# La mochila: el forro (en la imagen de GPT, de 228,262 a 1212,890) tiene que ir de FORRO_EN[0],[1] a FORRO_EN[2],[3] de
# la pantalla (inventario.gd: las casillas y la ficha van ahí dentro)
FORRO = (228, 262, 1212, 890)
FORRO_EN = (100, 140, 860, 584)
FRANJA = (660, 780)   # las columnas limpias que se repiten para ensancharla (se meten detrás de la 780) o se quitan
ASA = 0               # las filas de arriba con un asa que no se debe ensanchar (esta no tiene: la tapa llega al borde)


def mochila():
    im = sin_fondo(Image.open(FUENTES + "mochila-gpt.webp").convert("RGBA"))
    escala = (FORRO_EN[3] - FORRO_EN[1]) / (FORRO[3] - FORRO[1]) / 2.0   # píxeles del dibujo por píxel de GPT
    falta = round((FORRO_EN[2] - FORRO_EN[0]) / 2.0 / escala) - (FORRO[2] - FORRO[0])   # columnas de GPT que meter (o quitar)
    ancha = Image.new("RGBA", (im.width + falta, im.height))
    if falta >= 0:
        ancha.paste(im.crop((0, 0, FRANJA[1], im.height)), (0, 0))
        franja = im.crop((FRANJA[0], 0, FRANJA[1], im.height))
        x = FRANJA[1]
        while x < FRANJA[1] + falta:
            ancha.paste(franja, (x, 0))
            x += franja.width
        ancha.paste(im.crop((FRANJA[1], 0, im.width, im.height)), (FRANJA[1] + falta, 0))
    else:   # (sobra: se quitan columnas de la franja)
        ancha.paste(im.crop((0, 0, FRANJA[0], im.height)), (0, 0))
        ancha.paste(im.crop((FRANJA[0] - falta, 0, im.width, im.height)), (FRANJA[0], 0))
    # el asa, encima de la mochila, no se ensancha (repetida salía rota): se pone entera en el medio
    if ASA:
        ancha.paste((0, 0, 0, 0), (0, 0, ancha.width, ASA))
        ancha.paste(im.crop((0, 0, im.width, ASA)), (falta // 2, 0))
    ancho, alto = round(ancha.width * escala), round(ancha.height * escala)
    reducir(ancha, ancho, alto).save("assets/ui/inventario-mochila.png")
    # dónde va su esquina en la pantalla (MOCHILA_EN de inventario.gd)
    x0 = FORRO_EN[0] - 2 * FORRO[0] * ancho / ancha.width
    y0 = FORRO_EN[1] - 2 * FORRO[1] * alto / ancha.height
    print(f"assets/ui/inventario-mochila.png: {ancho}x{alto}; MOCHILA_EN := Vector2({round(x0)}, {round(y0)})")


TODAS = {"mochila": mochila, "papel": lambda: simple("papel", 119, 223), "cinta": lambda: simple("cinta", 60),
         "etiqueta": lambda: simple("etiqueta", 68)}
for nombre in sys.argv[1:] or list(TODAS):
    TODAS[nombre]()
