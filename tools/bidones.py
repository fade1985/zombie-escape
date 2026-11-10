# Los bidones de las habitaciones del Glotón (de fuego) y del jefe de bomberos (de ácido) (M16, peligros/bidones.gd):
# cada uno de pie y tumbado (rodando). Si está la imagen de GPT en assets/sources/bidon-<tipo>[-tumbado]-gpt.webp,
# se reduce como los muebles (la función pasar de tools/muebles_gpt.py: quita el negro puro del borde y reduce
# mezclando colores); si no, se dibuja uno provisional a mano, sencillo, para poder jugar mientras tanto.
#   py tools/bidones.py
import os
from collections import deque

from PIL import Image, ImageDraw

RAIZ = os.path.join(os.path.dirname(__file__), "..")
# de pie, 22 de ancho; tumbado, 30 (en píxeles del dibujo); el alto, según la imagen
ANCHO = {"": 22, "-tumbado": 30}
# los colores del provisional: cuerpo, sombra, aros, luz, y lo que lleva en medio (la etiqueta) y lo que chorrea
COLORES = {
    "fuego": {"cuerpo": (176, 38, 34), "sombra": (110, 22, 24), "aro": (82, 18, 20), "luz": (222, 86, 64),
              "etiqueta": (236, 230, 214), "marca": (230, 120, 30), "chorro": None},
    "acido": {"cuerpo": (206, 176, 36), "sombra": (138, 112, 20), "aro": (100, 82, 16), "luz": (240, 214, 92),
              "etiqueta": (236, 230, 214), "marca": (30, 30, 28), "chorro": (120, 232, 70)},
}
CONTORNO = (24, 20, 22)


# Lo de los muebles (la función pasar de tools/muebles_gpt.py, copiada: importarla los pasaría todos): el negro puro
# que se llega desde el borde, fuera; recortar y reducir mezclando colores (LANCZOS premultiplicado), y el borde sin
# medias tintas
def pasar(origen, sprite, ancho, alto):
    im = Image.open(origen).convert("RGBA")
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
    im = im.crop(im.getbbox())
    salida = im.convert("RGBa").resize((ancho, alto), Image.LANCZOS).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    salida.save(sprite)


def alto_de(origen, ancho):
    im = Image.open(origen).convert("RGB")
    caja = im.point(lambda v: 255 if v >= 6 else 0).getbbox()
    return max(1, round(ancho * (caja[3] - caja[1]) / (caja[2] - caja[0])))


# El de pie: un cilindro visto de frente y un poco desde arriba (la tapa, una elipse)
def de_pie(c):
    w, h = 22, 30
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 4, w - 1, h - 4], fill=c["cuerpo"], outline=CONTORNO)
    d.ellipse([0, h - 8, w - 1, h - 1], fill=c["sombra"], outline=CONTORNO)
    d.rectangle([1, 4, w - 2, h - 5], fill=c["cuerpo"])
    d.rectangle([w - 6, 5, w - 2, h - 5], fill=c["sombra"])   # el lado en sombra
    d.rectangle([3, 6, 4, h - 7], fill=c["luz"])              # el brillo
    for y in (10, h - 10):                                       # los aros
        d.line([1, y, w - 2, y], fill=c["aro"])
    d.ellipse([0, 0, w - 1, 8], fill=c["luz"], outline=CONTORNO)  # la tapa
    d.ellipse([4, 2, 7, 4], fill=c["aro"])                       # el tapón
    d.polygon([(11, 13), (15, 17), (11, 21), (7, 17)], fill=c["etiqueta"], outline=CONTORNO)
    d.rectangle([10, 16, 12, 18], fill=c["marca"])
    if c["chorro"]:
        d.line([6, 7, 6, 12], fill=c["chorro"])
        d.line([16, 7, 16, 9], fill=c["chorro"])
    return im


# El tumbado: visto desde arriba, a lo ancho, con las dos tapas en las puntas
def tumbado(c):
    w, h = 30, 20
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([3, 0, w - 4, h - 1], fill=c["cuerpo"], outline=CONTORNO)
    d.rectangle([4, h - 6, w - 5, h - 2], fill=c["sombra"])
    d.rectangle([4, 2, w - 5, 3], fill=c["luz"])
    for x in (9, w - 10):
        d.line([x, 1, x, h - 2], fill=c["aro"])
    d.ellipse([0, 0, 6, h - 1], fill=c["sombra"], outline=CONTORNO)
    d.ellipse([w - 7, 0, w - 1, h - 1], fill=c["luz"], outline=CONTORNO)
    d.polygon([(15, 6), (19, 10), (15, 14), (11, 10)], fill=c["etiqueta"], outline=CONTORNO)
    d.rectangle([14, 9, 16, 11], fill=c["marca"])
    if c["chorro"]:
        d.line([22, 4, 22, 8], fill=c["chorro"])
    return im


for tipo in ("fuego", "acido"):
    for postura in ("", "-tumbado"):
        sprite = os.path.join(RAIZ, "assets", "sprites", "bidon-%s%s.png" % (tipo, postura))
        origen = os.path.join(RAIZ, "assets", "sources", "bidon-%s%s-gpt.webp" % (tipo, postura))
        if os.path.exists(origen):
            pasar(origen, sprite, ANCHO[postura], alto_de(origen, ANCHO[postura]))
            print("de GPT:", sprite)
        else:
            (tumbado if postura else de_pie)(COLORES[tipo]).save(sprite)
            print("provisional:", sprite)
