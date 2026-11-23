# La referencia del durmiente de las uñas para PixelLab (23 nov, copia de explosivo_112.py): el dibujo de frente de GPT
# (assets/sources/unas-gpt/frente.webp, sobre fondo magenta), sin el fondo y reducido a
# 112 × 112 como el de la dependienta (referencia-112.png: los pies en la fila 110, centrado en la columna 56, unos
# 106 píxeles de alto). Se reduce mezclando colores, como los muebles (LANCZOS con el color premultiplicado).
# Se hizo primero a 112 y luego, con más detalle, a 160 (lo pidió el dueño): se le pasa el lado.
# Uso: py tools/unas_referencia.py 160   (sale referencia-160.png)
import sys
from PIL import Image
import numpy as np

CARPETA = "assets/sources/unas-gpt/"
LADO = int(sys.argv[1]) if len(sys.argv) > 1 else 112
PIES = LADO - 2     # la fila de los pies
ALTO = round(LADO * 107 / 112)   # lo que mide de alto (a 112, 107: la dependienta, 106)

im = Image.open(CARPETA + "frente.webp").convert("RGBA")
a = np.array(im).astype(np.int32)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
# el fondo: magenta (rojo y azul altos, verde bajo); también el borde que se mezcla con él
fondo = (r - g > 60) & (b - g > 60)
a[..., 3] = np.where(fondo, 0, 255)
limpio = Image.fromarray(a.astype(np.uint8), "RGBA")
caja = limpio.getbbox()
limpio = limpio.crop(caja)
escala = ALTO / limpio.height
ancho = max(1, round(limpio.width * escala))
peque = limpio.convert("RGBa").resize((ancho, ALTO), Image.LANCZOS).convert("RGBA")
# lo casi transparente, fuera; lo demás, opaco (pixel art: cada píxel o está o no está)
p = np.array(peque)
p[..., 3] = np.where(p[..., 3] < 110, 0, 255)
peque = Image.fromarray(p, "RGBA")
lienzo = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
lienzo.alpha_composite(peque, (LADO // 2 - ancho // 2, PIES - ALTO))
lienzo.save(CARPETA + "referencia-%d.png" % LADO)
print("recortado", caja, "->", ancho, "x", ALTO, "· caja final", lienzo.getbbox())
