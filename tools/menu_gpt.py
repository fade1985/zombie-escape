# El fondo y el título del menú de inicio, de dos imágenes de GPT (8 nov), reducidos como los muebles (LANCZOS
# premultiplicado, tools/muebles_gpt.py):
#   assets/sources/menu-fondo-gpt.webp  → assets/ui/menu-fondo.png (480 × 320): el portal de noche con Johnny de espaldas;
#                                         en el menú se ve ×2 (2 unidades por píxel), cubriendo toda la pantalla
#   assets/sources/titulo-gpt.webp      → assets/ui/titulo.png (300 × 100): JOHNNY RUSH / ZOMBIE ESCAPE (el de la fregona, con ella borrada a mano);
#                                         se le quita el negro puro que se llega desde el borde y se ve ×2
#   py tools/menu_gpt.py   (y luego Godot --headless --path . --import)
from collections import deque
from PIL import Image


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


# el fondo: entero, sin transparencias
Image.open('assets/sources/menu-fondo-gpt.webp').convert('RGB').resize((480, 320), Image.LANCZOS).save('assets/ui/menu-fondo.png')
# el título: sin el negro de alrededor, recortado y reducido mezclando colores, con el borde sin medias tintas
t = sin_fondo('assets/sources/titulo-gpt.webp')
# sin estirarlo: 300 de ancho con su proporción, abajo en un lienzo de 300 × 100 (así el menú no se mueve)
t = t.crop(t.getbbox())
alto = min(100, round(300 * t.height / t.width))
t = t.convert('RGBa').resize((300, alto), Image.LANCZOS).convert('RGBA')
t.putalpha(t.split()[3].point(lambda v: 255 if v > 110 else 0))
lienzo = Image.new('RGBA', (300, 100), (0, 0, 0, 0))
lienzo.paste(t, (0, 100 - alto))
lienzo.save('assets/ui/titulo.png')
print('menu-fondo.png y titulo.png')
