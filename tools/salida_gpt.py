# La salida de incendios del fondo del pasillo y su cartel EXIT, de dos imágenes de GPT (8 nov), en vez de los dibujados a
# mano de tools/puerta_salida.py:
#   assets/sources/cartel-salida-gpt.webp  → cartel-salida-apagado.png y cartel-salida-encendido.png (36 × 13): el de arriba
#                                            de la imagen, apagado, y el de abajo, encendido (cartel_salida.gd)
#   assets/sources/puerta-salida-gpt.webp  → puerta-salida.png (36 × 36): desde arriba, el suelo con la barra antipánico, la
#                                            hoja roja de canto y las escaleras bajando (puerta.gd)
# Como los muebles de GPT (tools/muebles_gpt.py): se quita el negro puro que se llega desde el borde, se recorta cada
# dibujo y se reduce MEZCLANDO colores (LANCZOS premultiplicado), con el borde sin medias tintas.
#   py tools/salida_gpt.py   (y luego Godot --headless --path . --import)
from collections import deque
from PIL import Image

SPRITES = 'assets/sprites'


def sin_fondo(ruta):
    im = Image.open(ruta).convert('RGBA')
    W, H = im.size
    px = im.load()
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 8:
            continue
        fondo[y * W + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(H):
        for x in range(W):
            if fondo[y * W + x]:
                px[x, y] = (0, 0, 0, 0)
    return im


def reducir(im, ancho, alto, ruta):
    f = im.crop(im.getbbox()).convert('RGBa').resize((ancho, alto), Image.LANCZOS).convert('RGBA')
    f.putalpha(f.split()[3].point(lambda v: 255 if v > 110 else 0))
    f.save(ruta)
    print(ruta, f.size)


# el cartel: arriba el apagado y abajo el encendido, separados por una franja negra en medio
carteles = sin_fondo('assets/sources/cartel-salida-gpt.webp')
W, H = carteles.size
reducir(carteles.crop((0, 0, W, H // 2)), 36, 13, f'{SPRITES}/cartel-salida-apagado.png')
reducir(carteles.crop((0, H // 2, W, H)), 36, 13, f'{SPRITES}/cartel-salida-encendido.png')
# la puerta: lo de dentro del marco negro, entero (sin transparencias: es un trozo de suelo, la hoja y las escaleras)
puerta = sin_fondo('assets/sources/puerta-salida-gpt.webp')
reducir(puerta, 36, 36, f'{SPRITES}/puerta-salida.png')
