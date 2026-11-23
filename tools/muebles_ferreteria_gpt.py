# El mostrador de cobro de la ferretería (24 nov, el dueño; de GPT, desde una foto suya): dos imágenes sobre negro puro, el mismo
# mostrador por los dos lados, reducidas a sprite de doble detalle (escala 1) MEZCLANDO colores, como la caja de la tienda de ropa
# (tools/venta_ropa_gpt.py):
#   mostrador-ferreteria-gpt.webp         -> ferremostrador, visto desde el lado del cliente (la tienda normal: se entra por abajo)
#   mostrador-ferreteria-dentro-gpt.webp  -> ferremostrador2, visto desde el lado del dependiente (la inversa: se entra por arriba)
# Los dos con el mismo largo de encimera, para que sean el mismo mueble.
#   py tools/mostrador_ferreteria_gpt.py   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (imagen, tipo); el largo del mostrador en el juego, en unidades (escala 1: un píxel por unidad)
MOSTRADORES = [("mostrador-ferreteria-gpt", "ferremostrador"), ("mostrador-ferreteria-dentro-gpt", "ferremostrador2")]
LARGO = 164
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


for origen, tipo in MOSTRADORES:
    im = quitar_fondo(Image.open(f"assets/sources/centro/{origen}.webp").convert("RGBA"))
    im = im.crop(im.getbbox())
    alto = round(LARGO * im.height / im.width)
    peq = (round(LARGO / PIXEL), round(alto / PIXEL))
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
