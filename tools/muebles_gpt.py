# Los muebles sacados de imágenes de GPT (pedidas en pixel art sobre fondo negro puro), pasados a sprite como las
# tuberías del taller (tools/taller_tuberias.py + importar.py): se quita el fondo (solo el negro puro que se llega desde
# el borde: los contornos y los huecos, casi negros, se quedan), se recorta y se reduce MEZCLANDO colores (cada píxel,
# la media de su trozo). Así se quedan las sombras suaves, los brillos y el volumen de la imagen, como las tuberías.
# (Del 7 nov: antes se probó reducir sin mezclar, que salía dentado, y redibujarlos a mano con pocos colores planos, que
# salía limpio pero plano, de dibujo animado, al lado de las tuberías.)
# Cada mueble: su imagen de GPT, su sprite, su tamaño en píxeles (a 2 unidades por píxel) y, si es del catálogo
# (catalogo.gd; no pasa por importar.py, que lo pisaría), su .json.
#   py tools/muebles_gpt.py            → todos
#   py tools/muebles_gpt.py banco      → solo ese
#   (y luego Godot --headless --path . --import)
import json
import sys
from collections import deque
from PIL import Image

MUEBLES = {
    # el banco de trabajo del taller (arrimable.gd, mapa.gd): acero gris con el tablero perforado naranja
    "banco": ("assets/sources/banco-trabajo-gpt.webp", "assets/sprites/banco-trabajo.png", 48, 58, False),
    # la estantería del taller, entre el banco y el baúl (el "canshelf" del catálogo): de acero galvanizado con cajas
    "estanteria": ("assets/sources/estanteria-metal-gpt.webp", "assets/sprites/mueble-canshelf.png", 40, 68, True),
    # la mesa del ordenador del despacho (ordenador.gd): de nogal, con el monitor y la torre beige de los 90
    "mesa_ordenador": ("assets/sources/mesa-ordenador-gpt.webp", "assets/sprites/mesa-ordenador.png", 48, 49, False),
    # el corcho colgado en la pared del despacho, a la izquierda de la mesa (mapa.gd): sin marco, con papeles crema
    # y chinchetas doradas (antes, de tools/guias_mantenimiento.py, que ya no se usa para él)
    "corcho": ("assets/sources/corcho-gpt.webp", "assets/sprites/corcho.png", 44, 29, False),
    # la papelera del despacho, a la derecha de la mesa (el "wastebasket" del catálogo): de rejilla gris oscura con
    # papeles blancos dentro; a 14 de ancho (la vieja, 12), que a 12 la rejilla casi no se leía
    "papelera": ("assets/sources/papelera-gpt.webp", "assets/sprites/mueble-wastebasket.png", 14, 21, True,
                 [(0, 7), (13, 7)]),   # (dos píxeles negros que sobresalían a los lados, debajo del aro)
    # la ducha del vestuario y de los baños de los pisos (el "showertray" del catálogo): mampara de cristal azulado de
    # frente, con perfiles de aluminio, sobre su plato blanco
    "ducha": ("assets/sources/ducha-gpt.webp", "assets/sprites/mueble-showertray.png", 36, 66, True),
    # el lavabo de pie con su espejo, de lado (el "staffsink" del catálogo, que solo tiene dibujo de lado): para la pared
    # de la izquierda; en la de la derecha, el juego le da la vuelta
    "lavabo": ("assets/sources/lavabo-gpt.webp", "assets/sprites/mueble-staffsink-lado.png", 20, 66, True),
    # la taquilla de las skins, en el vestuario (mapa.gd, partida.abrir_taquilla): gris claro con tres puertas azules;
    # mismo ancho que la vieja (28), más alta que Johnny como una de verdad (antes, de tools/taquilla.py)
    "taquilla": ("assets/sources/taquilla-gpt.webp", "assets/sprites/taquilla.png", 28, 56, False),
}


def pasar(origen, sprite, ancho, alto, con_json, quitar=()):
    im = Image.open(origen).convert("RGBA")
    W, H = im.size
    px = im.load()
    # el fondo: el negro puro que se llega desde el borde
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
    # mezclando colores (premultiplicado: el fondo transparente no tiñe los bordes), y el borde, sin medias tintas
    salida = im.convert("RGBa").resize((ancho, alto), Image.LANCZOS).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    for xy in quitar:   # los píxeles sueltos que sobran, a mano
        salida.putpixel(xy, (0, 0, 0, 0))
    salida.save(sprite)
    if con_json:
        with open(sprite.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump({"cell": [ancho, alto], "pivot": [ancho // 2, alto], "scale": 1,
                       "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
            f.write("\n")
    print(f"{sprite}: {ancho}x{alto}")


for nombre in sys.argv[1:] or list(MUEBLES):
    pasar(*MUEBLES[nombre])
