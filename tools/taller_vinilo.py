# El suelo y la pared del taller de la sala de mantenimiento (donde están el baúl y el banco), como el de la foto del
# dueño (7 nov): suelo de vinilo gris con motitas y pared blanca con el zócalo redondeado del mismo vinilo. Salen de dos
# imágenes de GPT (assets/sources/taller-suelo-gpt.webp y taller-pared-gpt.webp), que ya vienen repetidas varias veces:
# se busca cada cuánto se repiten, se recorta una vez, se reduce al tamaño del juego y se deja con pocos colores, sin
# grises borrosos.
#   suelo → assets/sprites/suelo-taller.png  (128x128, como suelo-mantenimiento; empalma por los cuatro lados)
#   pared → assets/sprites/pared-taller.png  (480x48, como las demás paredes; empalma a izquierda y derecha)
# Uso: py tools/taller_vinilo.py  (y luego Godot --headless --path . --import)
from PIL import Image

FUENTES = "assets/sources/"
CARPETA = "assets/sprites/"


# Cada cuántos píxeles se repite la imagen a lo ancho (o a lo alto): el desplazamiento entre "desde" y "hasta" con el
# que la imagen se parece más a sí misma
def periodo(im, desde, hasta, vertical=False):
    g = im.convert("L")
    if vertical:
        g = g.transpose(Image.Transpose.TRANSPOSE)
    w, h = g.size
    p = g.load()
    mejor, cual = None, desde
    for d in range(desde, hasta):
        dif = 0
        for y in range(0, h, 7):
            for x in range(0, w - d, 5):
                dif += abs(p[x, y] - p[x + d, y])
        dif /= (w - d)
        if mejor is None or dif < mejor:
            mejor, cual = dif, d
    return cual


# Reducida a ancho x alto tomando un punto de cada cuadrito, sin mezclar (así las motitas no pierden su color), y luego
# con "colores" colores como mucho
def reducir(im, ancho, alto, colores):
    peq = im.convert("RGB").resize((ancho, alto), Image.Resampling.NEAREST)
    return peq.quantize(colors=colores, method=Image.Quantize.MEDIANCUT).convert("RGB")


# El suelo: un trozo que se repite, a 128x128
suelo = Image.open(FUENTES + "taller-suelo-gpt.webp")
w, h = suelo.size
px = periodo(suelo, w // 3, w * 2 // 3)
py_ = periodo(suelo, h // 3, h * 2 // 3, True)
print("suelo: se repite cada", px, "x", py_)
vinilo = reducir(suelo.crop((0, 0, px, py_)), 128, 128, 7)
vinilo.save(CARPETA + "suelo-taller.png")

# La pared: el yeso, de la imagen de GPT (un trozo que se repite, repetido hasta los 480 de ancho), y abajo el zócalo,
# ZOCALO píxeles: una línea clara donde toca la pared, el mismo vinilo del suelo (para que empalmen) y la última fila,
# más oscura, donde se curva hacia el suelo
ZOCALO = 8
pared = Image.open(FUENTES + "taller-pared-gpt.webp")
w, h = pared.size
px = periodo(pared, w // 6, w // 2)
alto_yeso = 48 - ZOCALO
yeso_gpt = pared.crop((0, 0, px, int(h * 0.85)))   # (sin el zócalo de GPT)
ancho = 40
yeso = reducir(yeso_gpt, ancho, alto_yeso, 4)
tira = Image.new("RGB", (480, 48))
for x in range(0, 480, ancho):
    tira.paste(yeso, (x, 0))
oscuro = lambda c, f: tuple(int(v * f) for v in c)
for x in range(480):
    tira.putpixel((x, alto_yeso), (178, 180, 184))   # el borde de arriba del zócalo, con luz
    for y in range(1, ZOCALO - 1):
        tira.putpixel((x, alto_yeso + y), oscuro(vinilo.getpixel((x % 128, y * 7 % 128)), 1.0 if y < 3 else 0.92))
    tira.putpixel((x, 47), oscuro(vinilo.getpixel((x % 128, 60)), 0.72))
tira.save(CARPETA + "pared-taller.png")
print("pared: yeso de", ancho, "repetido", 480 // ancho, "veces, zócalo de", ZOCALO)
