# L36: las manchas de sangre sueltas del suelo del pasillo de dentro de los pisos, de una imagen de GPT (13 nov) con ocho
# manchas distintas en dos filas de cuatro, sobre fondo BLANCO (no negro, como los muebles: la sangre tiene los bordes
# finos y medio transparentes, y sobre negro le quedaba un borde oscuro).
#   assets/sources/pasillo/manchas-sangre-gpt.webp → assets/sprites/sangre-suelo-1.png ... -8.png
# 1 charco con salpicaduras, 2 reguero de gotas, 3 arrastre, 4 mano, 5 salpicón en estrella, 6 gotas sueltas, 7 huellas
# de zapato y 8 mancha vieja y seca. Las reparte mapa.gd (manchas_del_pasillo).
# Primero se quita el blanco (lo que tiene de blanco cada píxel pasa a ser transparencia, como «color a alfa»), así la
# sangre clara de los bordes queda medio transparente y deja ver el suelo; luego, como «lo de los muebles»
# (tools/muebles_gpt.py): recortada y reducida MEZCLANDO colores (LANCZOS premultiplicado). Lo casi transparente, fuera.
#   py tools/manchas_gpt.py   (y luego Godot --headless --path . --import)
from PIL import Image

ORIGEN = "assets/sources/pasillo/manchas-sangre-gpt.webp"
REDUCCION = 6      # cada píxel del dibujo, 6 × 6 de la imagen de GPT
COLUMNAS, FILAS = 4, 2

im = Image.open(ORIGEN).convert("RGB")
W, H = im.size
sin_blanco = Image.new("RGBA", (W, H))
origen, destino = im.load(), sin_blanco.load()
for y in range(H):
    for x in range(W):
        c = origen[x, y]
        falta = max(255 - v for v in c)   # lo lejos que está del blanco
        if falta < 8:
            continue
        a = falta / 255.0
        destino[x, y] = tuple(max(0, min(255, round(255 - (255 - v) / a))) for v in c) + (falta,)
n = 0
for f in range(FILAS):
    for c in range(COLUMNAS):
        n += 1
        celda = sin_blanco.crop((c * W // COLUMNAS, f * H // FILAS, (c + 1) * W // COLUMNAS, (f + 1) * H // FILAS))
        celda = celda.crop(celda.getbbox())
        tam = (max(1, round(celda.width / REDUCCION)), max(1, round(celda.height / REDUCCION)))
        salida = celda.convert("RGBa").resize(tam, Image.LANCZOS).convert("RGBA")
        salida.putalpha(salida.split()[3].point(lambda v: 0 if v < 50 else min(255, round(v * 1.15))))
        salida.save("assets/sprites/sangre-suelo-%d.png" % n)
        print(f"sangre-suelo-{n}: {celda.size} → {tam[0]}x{tam[1]}")
