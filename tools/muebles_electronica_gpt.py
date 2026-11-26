# Los muebles de la electrónica (27 nov, el dueño; de GPT, desde fotos suyas de un local de juegos en red): imágenes sobre negro puro
# (assets/sources/centro/<imagen>.webp) reducidas a sprite de escala 1 MEZCLANDO colores, como los del supermercado
# (tools/muebles_supermercado_gpt.py, de donde sale esta). De momento, los de la sala de juegos en red (20 × 12 casillas, en el sitio del
# taller; de momento con el uso "taquillas"), recortados de dos imágenes con tres cada una (puestos-juegos-gpt.webp y sillas-juegos-gpt.webp):
#   puesto-juegos1..3-gpt -> juegospuesto1..3: una mesa negra de dos jugadores con sus dos monitores, teclados, ratones y auriculares, las
#     dos torres de luces en el estante de arriba y sus dos sillas gamer delante (abandonada, destrozada y saqueada)
#   silla-juegos1..3-gpt  -> juegossilla1..3: una silla gamer negra y roja suelta, de espaldas, rajada y volcada
#   py tools/muebles_electronica_gpt.py [tipo ...]   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (imagen, tipo, largo): el largo en el juego, en unidades (escala 1: un píxel por unidad; una casilla, 32); el alto sale de la
# proporción. Los tres puestos, del mismo largo (4 casillas: dos jugadores), para que sean el mismo mueble
MUEBLES = [("puesto-juegos1-gpt", "juegospuesto1", 128), ("puesto-juegos2-gpt", "juegospuesto2", 128),
           ("puesto-juegos3-gpt", "juegospuesto3", 128),
           ("silla-juegos1-gpt", "juegossilla1", 36), ("silla-juegos2-gpt", "juegossilla2", 36), ("silla-juegos3-gpt", "juegossilla3", 48)]
# los que llevan huecos cerrados de negro puro que han de verse transparentes (bajo la mesa, entre las patas y las sillas, y entre las
# ruedas de las sillas): se quitan los de más de HUECO_MIN píxeles de GPT (los pequeños son sombras del dibujo)
CON_HUECOS = {"juegospuesto1", "juegospuesto2", "juegospuesto3", "juegossilla1", "juegossilla2", "juegossilla3"}
HUECO_MIN = 1000
ALTO_MAX = {}
# lo grande que es cada píxel del dibujo (como los muebles de la tienda de ropa: 2, el mismo detalle que el resto del juego)
PIXEL = 2
# todos con el doble de detalle (un píxel por unidad), como en el súper
FINOS = set(CON_HUECOS)


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


# (27 nov, el dueño: que las torres y las pantallas encendidas den luz como los neones) Lo que luce de los puestos, en otro dibujo
# (mueble-<tipo>-luz.png, transparente en lo demás), que el juego pinta encima sin que le afecte la oscuridad (mueble.gd): los píxeles
# claros y de color vivo (los ventiladores de las torres, las pantallas encendidas y los teclados de luces), solo por encima de las sillas
# (LUZ_HASTA: las franjas rojas de las sillas no lucen), con un resplandor alrededor
LUZ = {"juegospuesto1", "juegospuesto2", "juegospuesto3"}
LUZ_HASTA = 0.6   # hasta qué parte del alto (de arriba abajo): lo de debajo son las sillas


def capa_luz(s):
    from PIL import ImageFilter
    w, h = s.size
    px = s.load()
    nucleo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    nx = nucleo.load()
    for y in range(int(h * LUZ_HASTA)):
        for x in range(w):
            r, g, b, a = px[x, y]
            alto, bajo = max(r, g, b), min(r, g, b)
            if a and alto >= 110 and (alto - bajo) >= 0.38 * alto and not (r > 1.6 * max(g, b)):   # (de color vivo, y no rojo: la sangre)
                k = min(1.25, 255 / alto)
                nx[x, y] = (int(r * k), int(g * k), int(b * k), 255)
    halo = nucleo.filter(ImageFilter.GaussianBlur(2.2))
    halo.putalpha(halo.split()[3].point(lambda v: min(150, int(v * 1.8))))
    return Image.alpha_composite(halo, nucleo)


import sys
solo = set(sys.argv[1:])   # py tools/muebles_electronica_gpt.py [tipo ...]: solo esos
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
    if tipo in LUZ:
        capa_luz(s).save(ruta.replace(".png", "-luz.png"))
    print(f"{tipo}: {ancho}x{alto} (de {im.width}x{im.height})")
