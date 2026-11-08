# El fondo y el título del menú de inicio, de dos imágenes de GPT (8 nov), reducidos como los muebles (LANCZOS
# premultiplicado, tools/muebles_gpt.py):
#   assets/sources/menu-fondo-gpt.webp  → assets/ui/menu-fondo.png (480 × 320): el portal de noche con Johnny de espaldas;
#                                         en el menú se ve ×2 (2 unidades por píxel), cubriendo toda la pantalla. GPT le
#                                         dejó el palo de la fregona cortado en la cadera: alargar_palo() lo hace pasar
#                                         por detrás de Johnny y asomar a la izquierda, por detrás del brazo
#   assets/sources/titulo-gpt.webp      → assets/ui/titulo.png (300 × 100): JOHNNY RUSH / ZOMBIE ESCAPE con la fregona;
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


# El palo de la fregona, más largo (en la imagen grande de GPT, 1536 × 1024, antes de reducirla): se copia un corte
# del palo de verdad (la columna x 280, con su contorno) siguiendo su inclinación hacia la izquierda, hasta el borde
# de la imagen, pero solo donde no está el brazo izquierdo de Johnny (desde su piel, 5 px de contorno): así pasa por
# detrás de él
def alargar_palo(im):
    px = im.load()
    X0, ARRIBA, PEND = 280, 794, 0.6   # la columna que se copia (de y 794 a 821) y lo que baja por cada px a la derecha
    corte = [px[X0, y] for y in range(ARRIBA, 822)]
    bordes = {}

    def brazo(y):   # el primer píxel de piel del brazo izquierdo en esa fila (desde x 36, pasada la farola)
        for x in range(36, 200):
            r, g, b = px[x, y]
            if r > 150 and g > 50 and b < 120:
                return x
        return 200

    for x in range(0, 200):
        arriba = round(ARRIBA + PEND * (x - X0))
        for k, c in enumerate(corte):
            y = arriba + k
            if y not in bordes:
                bordes[y] = brazo(y)
            if x < bordes[y] - 5:
                px[x, y] = c
    return im


# el fondo: entero, sin transparencias
alargar_palo(Image.open('assets/sources/menu-fondo-gpt.webp').convert('RGB')).resize((480, 320), Image.LANCZOS).save('assets/ui/menu-fondo.png')
# el título: sin el negro de alrededor, recortado y reducido mezclando colores, con el borde sin medias tintas
t = sin_fondo('assets/sources/titulo-gpt.webp')
t = t.crop(t.getbbox()).convert('RGBa').resize((300, 100), Image.LANCZOS).convert('RGBA')
t.putalpha(t.split()[3].point(lambda v: 255 if v > 110 else 0))
t.save('assets/ui/titulo.png')
print('menu-fondo.png y titulo.png')
