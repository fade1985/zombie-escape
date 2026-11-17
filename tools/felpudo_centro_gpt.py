# El felpudo de la entrada del centro comercial (delante de la puerta de la calle de acero, la de la izquierda de la planta
# baja), de una imagen de GPT (17 nov): rejilla de moqueta gris oscura con perfiles y marco de aluminio.
#   assets/sources/felpudo-centro-gpt.webp → assets/sprites/felpudo-centro.png (lo pinta mapa.dibujar_fondo)
# Se reduce como los muebles (LANCZOS premultiplicado, tools/muebles_gpt.py), pero TROZO A TROZO: el marco, cada tira de
# moqueta y cada perfil de aluminio por separado, cada uno a su número justo de píxeles (el marco a 2, las tiras a 3 y los
# perfiles a 1). Reducido de golpe, los perfiles (más finos que un píxel del sprite) se emborronaban con la moqueta.
# Luego se gira un cuarto de vuelta, como el del portal (tools/felpudo_portal_gpt.py): de pie, a lo largo de la puerta,
# con las tiras atravesadas al paso de quien entra. Sale de 35 × 64 (70 × 128 unidades: tan largo como el hueco de la puerta).
#   py tools/felpudo_centro_gpt.py   (y luego Godot --headless --path . --import)
# (si se cambia la imagen de GPT, hay que volver a medir dónde empieza y acaba cada trozo: FILAS y COLUMNAS)
from PIL import Image

ORIGEN = 'assets/sources/felpudo-centro-gpt.webp'
SALIDA = 'assets/sprites/felpudo-centro.png'
# (desde, hasta, píxeles del sprite): de arriba abajo, el marco, las 8 tiras con los 7 perfiles entre ellas y el marco
FILAS = [(114, 150, 2),
         (150, 218, 3), (218, 234, 1), (234, 300, 3), (300, 317, 1), (317, 382, 3), (382, 399, 1), (399, 463, 3),
         (463, 481, 1), (481, 545, 3), (545, 562, 1), (562, 627, 3), (627, 644, 1), (644, 709, 3), (709, 726, 1),
         (726, 791, 3), (791, 828, 2)]
# y de izquierda a derecha: el marco, la moqueta y el marco
COLUMNAS = [(110, 145, 2), (145, 1527, 60), (1527, 1563, 2)]

im = Image.open(ORIGEN).convert('RGBa')
salida = Image.new('RGBa', (sum(c[2] for c in COLUMNAS), sum(f[2] for f in FILAS)))
y = 0
for y0, y1, alto in FILAS:
    x = 0
    for x0, x1, ancho in COLUMNAS:
        salida.paste(im.crop((x0, y0, x1, y1)).resize((ancho, alto), Image.LANCZOS), (x, y))
        x += ancho
    y += alto
salida = salida.convert('RGBA')
salida.putalpha(255)
salida = salida.transpose(Image.Transpose.ROTATE_90)   # (sin mezclar: un cuarto de vuelta exacto)
salida.save(SALIDA)
print(SALIDA, salida.size)
