# La referencia del zombi explosivo nuevo para PixelLab (20 nov): el dibujo de frente de GPT
# (assets/sources/explosivo-112-gpt/frente.webp, sobre fondo magenta porque va de negro), sin el fondo y reducido a
# 112 × 112 como el de la dependienta (referencia-112.png: los pies en la fila 110, centrado en la columna 56, unos
# 106 píxeles de alto). Se reduce mezclando colores, como los muebles (LANCZOS con el color premultiplicado).
# Uso: py tools/explosivo_112.py
from PIL import Image
import numpy as np

CARPETA = "assets/sources/explosivo-112-gpt/"
LADO = 112
PIES = 110          # la fila de los pies
ALTO = 107          # lo que mide de alto (la dependienta, 106; él es un hombretón con sombrero)

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
lienzo.save(CARPETA + "referencia-112.png")
print("recortado", caja, "->", ancho, "x", ALTO, "· caja final", lienzo.getbbox())
