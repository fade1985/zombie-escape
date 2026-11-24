# Los muebles de la sala de venta de la ferretería (24 nov, el dueño; de GPT, desde fotos suyas): imágenes sobre negro puro
# (assets/sources/centro/<imagen>.webp) reducidas a sprite de doble detalle (escala 1) MEZCLANDO colores, como los de la tienda de
# ropa (tools/venta_ropa_gpt.py):
#   mostrador-ferreteria-gpt         -> ferremostrador, el mostrador de cobro desde el lado del cliente (la tienda normal: se entra por abajo)
#   mostrador-ferreteria-dentro-gpt  -> ferremostrador2, el mismo desde el lado del dependiente (la inversa: se entra por arriba)
#   pale-cemento-gpt, -cemento2-, -cemento3-  -> ferrepale1..3, palés de sacos de cemento: lleno, a medio gastar y con el plástico roto
#   latas-pintura-gpt, latas-pintura2-gpt  -> ferrelatas1, 2: montones de latas de pintura, uno alto y otro bajo y ancho
#   transpaleta-gpt  -> ferretranspaleta, una transpaleta naranja de lado (las horquillas, a la izquierda)
#   escalera-gpt  -> ferreescalera, una escalera de tijera de aluminio, abierta y vista en diagonal
#   py tools/muebles_ferreteria_gpt.py   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (imagen, tipo, largo): el largo en el juego, en unidades (escala 1: un píxel por unidad); el alto sale de la proporción. Los dos
# mostradores, con el mismo largo de encimera, para que sean el mismo mueble; los tres palés, del mismo ancho; los dos montones de
# latas, con las latas del mismo tamaño (en las dos imágenes de GPT miden igual: el ancho de cada una, 8 unidades por cada 100 píxeles)
MUEBLES = [("mostrador-ferreteria-gpt", "ferremostrador", 164), ("mostrador-ferreteria-dentro-gpt", "ferremostrador2", 164),
           ("pale-cemento-gpt", "ferrepale1", 80), ("pale-cemento2-gpt", "ferrepale2", 80), ("pale-cemento3-gpt", "ferrepale3", 80),
           ("latas-pintura-gpt", "ferrelatas1", 94), ("latas-pintura2-gpt", "ferrelatas2", 116),
           ("transpaleta-gpt", "ferretranspaleta", 110), ("escalera-gpt", "ferreescalera", 72)]
# los que llevan huecos cerrados de negro puro que han de verse transparentes (el asa de la transpaleta, la rendija entre sus
# horquillas, entre los peldaños de la escalera): se quitan los de más de HUECO_MIN píxeles de GPT (los pequeños son sombras del dibujo)
CON_HUECOS = {"ferretranspaleta", "ferreescalera"}
HUECO_MIN = 1000
# lo grande que es cada píxel del dibujo (como los muebles de la tienda de ropa: 2, el mismo detalle que el resto del juego)
PIXEL = 2
# los de barras finas, que con PIXEL 2 se emborronan, con el doble de detalle (un píxel por unidad, como los paneles de la pared)
FINOS = {"ferreescalera"}


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


for origen, tipo, largo in MUEBLES:
    im = quitar_fondo(Image.open(f"assets/sources/centro/{origen}.webp").convert("RGBA"))
    if tipo in CON_HUECOS:
        im = quitar_huecos(im)
    im = im.crop(im.getbbox())
    alto = round(largo * im.height / im.width)
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
