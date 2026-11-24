# Los muebles de la sala de venta de la ferretería (24 nov, el dueño; de GPT, desde fotos suyas): imágenes sobre negro puro
# (assets/sources/centro/<imagen>.webp) reducidas a sprite de doble detalle (escala 1) MEZCLANDO colores, como los de la tienda de
# ropa (tools/venta_ropa_gpt.py):
#   mostrador-ferreteria-gpt         -> ferremostrador, el mostrador de cobro desde el lado del cliente (la tienda normal: se entra por abajo)
#   mostrador-ferreteria-dentro-gpt  -> ferremostrador2, el mismo desde el lado del dependiente (la inversa: se entra por arriba)
#   pale-cemento-gpt, -cemento2-, -cemento3-  -> ferrepale1..3, palés de sacos de cemento: lleno, a medio gastar y con el plástico roto
#   latas-pintura-gpt, latas-pintura2-gpt  -> ferrelatas1, 2: montones de latas de pintura, uno alto y otro bajo y ancho
#   py tools/muebles_ferreteria_gpt.py   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (imagen, tipo, largo): el largo en el juego, en unidades (escala 1: un píxel por unidad); el alto sale de la proporción. Los dos
# mostradores, con el mismo largo de encimera, para que sean el mismo mueble; los tres palés, del mismo ancho; los dos montones de
# latas, con las latas del mismo tamaño (en las dos imágenes de GPT miden igual: el ancho de cada una, 8 unidades por cada 100 píxeles)
MUEBLES = [("mostrador-ferreteria-gpt", "ferremostrador", 164), ("mostrador-ferreteria-dentro-gpt", "ferremostrador2", 164),
           ("pale-cemento-gpt", "ferrepale1", 80), ("pale-cemento2-gpt", "ferrepale2", 80), ("pale-cemento3-gpt", "ferrepale3", 80),
           ("latas-pintura-gpt", "ferrelatas1", 94), ("latas-pintura2-gpt", "ferrelatas2", 116)]
# lo grande que es cada píxel del dibujo (como los muebles de la tienda de ropa: 2, el mismo detalle que el resto del juego)
PIXEL = 2


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


for origen, tipo, largo in MUEBLES:
    im = quitar_fondo(Image.open(f"assets/sources/centro/{origen}.webp").convert("RGBA"))
    im = im.crop(im.getbbox())
    alto = round(largo * im.height / im.width)
    peq = (round(largo / PIXEL), round(alto / PIXEL))
    s = im.convert("RGBa").resize(peq, Image.LANCZOS).convert("RGBA")
    s.putalpha(s.split()[3].point(lambda v: 255 if v > 110 else 0))
    s = s.resize((peq[0] * PIXEL, peq[1] * PIXEL), Image.NEAREST)
    ancho, alto = s.size
    ruta = f"assets/sprites/mueble-{tipo}.png"
    s.save(ruta)
    with open(ruta.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [ancho, alto], "pivot": [ancho // 2, alto], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")
    print(f"{tipo}: {ancho}x{alto} (de {im.width}x{im.height})")
