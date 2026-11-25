# Los muebles del supermercado (25 nov, el dueño; de GPT, desde fotos suyas): imágenes sobre negro puro
# (assets/sources/centro/<imagen>.webp) reducidas a sprite de escala 1 MEZCLANDO colores, como los de la farmacia
# (tools/muebles_farmacia_gpt.py, de donde sale esta). De momento, los de la cámara frigorífica (20 × 12 casillas: medidos
# para que quepan cuatro estanterías en la pared de arriba y, abajo, la burra, el palé y el colgador con el paso de la puerta libre):
#   estanteria-camara-verdura-gpt, -carne-, -lacteos-, -saqueada-  -> camarabalda1..4: la misma estantería de acero inoxidable
#     helada con cajas de verdura y fruta, con bandejas de carne, con leche, yogures y cajas, y saqueada con una balda caída
#   burra-embutidos-gpt  -> camaraburra, un carro burra con ruedas de chorizos, salchichones y jamones colgados
#   pale-verduras-gpt    -> camarapale, un palé con cajas verdes de verdura y fruta apiladas
#   colgador-carne-gpt   -> camaracolgador, un pórtico de acero con piezas de carne colgadas de ganchos
#   evaporador-camara-gpt -> camaraevaporador, el aparato del frío, con sus dos ventiladores: no es un mueble, va colgado arriba en
#     la pared (mapa.gd, PANELES_TIENDA), en el hueco entre dos estanterías
#   py tools/muebles_supermercado_gpt.py [tipo ...]   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (imagen, tipo, largo): el largo en el juego, en unidades (escala 1: un píxel por unidad; una casilla, 32); el alto sale de la
# proporción. Las cuatro estanterías, del mismo largo, para que sean el mismo mueble
MUEBLES = [("estanteria-camara-verdura-gpt", "camarabalda1", 112), ("estanteria-camara-carne-gpt", "camarabalda2", 112),
           ("estanteria-camara-lacteos-gpt", "camarabalda3", 112), ("estanteria-camara-saqueada-gpt", "camarabalda4", 112),
           ("burra-embutidos-gpt", "camaraburra", 88), ("pale-verduras-gpt", "camarapale", 64),
           ("colgador-carne-gpt", "camaracolgador", 160), ("evaporador-camara-gpt", "camaraevaporador", 52),
           # la línea de cajas de la sala de venta: la misma caja con tres destrozos, vista desde el cliente y desde la cajera
           ("caja-super-gpt", "supercaja1", 160), ("caja-super-dentro-gpt", "supercaja1dentro", 160), ("caja-super2-gpt", "supercaja2", 160),
           ("caja-super2-dentro-gpt", "supercaja2dentro", 160), ("caja-super3-gpt", "supercaja3", 160),
           ("caja-super3-dentro-gpt", "supercaja3dentro", 160),
           # el arco antirrobo, a los lados de la entrada
           ("arco-antirrobo-gpt", "superarco", 24)]
# los que llevan huecos cerrados de negro puro que han de verse transparentes (entre las baldas, las barras, las tablas del palé
# y las piezas de carne): se quitan los de más de HUECO_MIN píxeles de GPT (los pequeños son sombras del dibujo)
CON_HUECOS = {"camarabalda1", "camarabalda2", "camarabalda3", "camarabalda4", "camaraburra", "camarapale", "camaracolgador", "superarco"}
HUECO_MIN = 1000
# lo más altas que pueden ser (las estanterías, contra la pared de arriba: lo que pase de 136, como las del almacén, se sale por
# encima de la pared)
ALTO_MAX = {"camarabalda1": 136, "camarabalda2": 136, "camarabalda3": 136, "camarabalda4": 136}
# lo grande que es cada píxel del dibujo (como los muebles de la tienda de ropa: 2, el mismo detalle que el resto del juego)
PIXEL = 2
# los de cosas pequeñas, que con PIXEL 2 se emborronan, con el doble de detalle (un píxel por unidad): todos, como en la farmacia
FINOS = set(CON_HUECOS) | {"camaraevaporador", "supercaja1", "supercaja2", "supercaja2dentro", "supercaja3", "supercaja1dentro",
                                         "supercaja3dentro"}


def quitar_fondo(im):
    """El negro puro que se llega desde el borde, transparente."""
    px = im.load()
    w, h = im.size
    hecho = bytearray(w * h)
    cola = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or hecho[y * w + x] or max(px[x, y][:3]) >= 8:
            continue
        hecho[y * w + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(h):
        for x in range(w):
            if hecho[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
    return im


def quitar_huecos(im):
    """Los huecos cerrados de negro puro de más de HUECO_MIN píxeles, transparentes."""
    px = im.load()
    w, h = im.size
    visto = bytearray(w * h)
    for y0 in range(h):
        for x0 in range(w):
            if visto[y0 * w + x0] or px[x0, y0][3] == 0 or max(px[x0, y0][:3]) >= 8:
                continue
            visto[y0 * w + x0] = 1
            cola = deque([(x0, y0)])
            hueco = []
            while cola:
                x, y = cola.popleft()
                hueco.append((x, y))
                for a, b in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= a < w and 0 <= b < h and not visto[b * w + a] and px[a, b][3] and max(px[a, b][:3]) < 8:
                        visto[b * w + a] = 1
                        cola.append((a, b))
            if len(hueco) > HUECO_MIN:
                for x, y in hueco:
                    px[x, y] = (0, 0, 0, 0)
    return im


import sys
solo = set(sys.argv[1:])   # py tools/muebles_supermercado_gpt.py [tipo ...]: solo esos
for origen, tipo, largo in MUEBLES:
    if solo and tipo not in solo:
        continue
    im = quitar_fondo(Image.open(f"assets/sources/centro/{origen}.webp").convert("RGBA"))
    if tipo in CON_HUECOS:
        im = quitar_huecos(im)
    im = im.crop(im.getbbox())
    alto = round(largo * im.height / im.width)
    if tipo in ALTO_MAX and alto > ALTO_MAX[tipo]:   # más alta de la cuenta: se estrecha para que quepa
        largo, alto = round(largo * ALTO_MAX[tipo] / alto), ALTO_MAX[tipo]
    pixel = 1 if tipo in FINOS else PIXEL
    peq = (round(largo / pixel), round(alto / pixel))
    s = im.convert("RGBa").resize(peq, Image.LANCZOS).convert("RGBA")
    s.putalpha(s.split()[3].point(lambda v: 255 if v > 110 else 0))
    s = s.resize((peq[0] * pixel, peq[1] * pixel), Image.NEAREST)
    ancho, alto = s.size
    ruta = f"assets/sprites/mueble-{tipo}.png"
    s.save(ruta)
    with open(ruta.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [ancho, alto], "pivot": [ancho // 2, alto], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")
    print(f"{tipo}: {ancho}x{alto} (de {im.width}x{im.height})")
