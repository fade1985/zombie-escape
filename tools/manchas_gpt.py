# L36: las manchas de sangre sueltas del suelo del pasillo de dentro de los pisos, de dos imágenes de GPT (13 nov), cada
# una con seis manchas en dos filas de tres, sobre fondo BLANCO (no negro, como los muebles: la sangre tiene los bordes
# finos y medio transparentes, y sobre negro le quedaba un borde oscuro). Sangre roja viva y líquida, como las fotos de
# referencia del dueño (la primera tanda, granate y con textura de pelos, se descartó).
#   assets/sources/pasillo/manchas-sangre-a-gpt.webp (charcos y salpicaduras) → assets/sprites/sangre-suelo-1.png ... -6.png
#   assets/sources/pasillo/manchas-sangre-b-gpt.webp (arrastres y restregones) → assets/sprites/sangre-suelo-7.png ... -12.png
# Las reparte mapa.gd (manchas_del_pasillo), con salpicones de gotas alrededor como los de los tiros.
# Primero se quita el blanco (lo que tiene de blanco cada píxel pasa a ser transparencia, como «color a alfa»), así la
# sangre clara de los bordes queda medio transparente y deja ver el suelo; luego, como «lo de los muebles»
# (tools/muebles_gpt.py): recortada y reducida MEZCLANDO colores (LANCZOS premultiplicado). Lo casi transparente, fuera.
#   py tools/manchas_gpt.py   (y luego Godot --headless --path . --import)
from PIL import Image

ORIGENES = ["assets/sources/pasillo/manchas-sangre-a-gpt.webp", "assets/sources/pasillo/manchas-sangre-b-gpt.webp"]
REDUCCION = 7      # cada píxel del dibujo, 7 × 7 de la imagen de GPT
COLUMNAS, FILAS = 3, 2


def sin_blanco(im):
    W, H = im.size
    salida = Image.new("RGBA", (W, H))
    origen, destino = im.load(), salida.load()
    for y in range(H):
        for x in range(W):
            c = origen[x, y]
            falta = max(255 - v for v in c)   # lo lejos que está del blanco
            if falta < 8:
                continue
            a = falta / 255.0
            destino[x, y] = tuple(max(0, min(255, round(255 - (255 - v) / a))) for v in c) + (falta,)
    return salida


n = 0
for origen in ORIGENES:
    im = sin_blanco(Image.open(origen).convert("RGB"))
    W, H = im.size
    for f in range(FILAS):
        for c in range(COLUMNAS):
            n += 1
            celda = im.crop((c * W // COLUMNAS, f * H // FILAS, (c + 1) * W // COLUMNAS, (f + 1) * H // FILAS))
            celda = celda.crop(celda.getbbox())
            tam = (max(1, round(celda.width / REDUCCION)), max(1, round(celda.height / REDUCCION)))
            salida = celda.convert("RGBa").resize(tam, Image.LANCZOS).convert("RGBA")
            salida.putalpha(salida.split()[3].point(lambda v: 0 if v < 50 else min(255, round(v * 1.15))))
            salida.save("assets/sprites/sangre-suelo-%d.png" % n)
            print(f"sangre-suelo-{n}: {celda.size} → {tam[0]}x{tam[1]}")
