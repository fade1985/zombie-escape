# Los muebles de la sala de venta de la tienda de ropa (18 nov, el dueño; GPT, ropa de los años 90): 14 imágenes sobre negro puro
# (assets/sources/ropa/venta-<id>-gpt.webp) reducidas a sprite de doble detalle MEZCLANDO colores (LANCZOS, alfa premultiplicado, como tools/muebles_gpt.py):
#   pared:  p1 ropamodulo, p2 ropabarra, p3 ropazapatos, p4 ropavitrina, p5 ropaoval
#   suelo:  s1 ropaperchero1, s2 ropaperchero2, s3 roparuedas, s4 ropamesa, s5 ropatarimas
#   maniquíes: m1..m4 ropamaniqui1..4 (48 de alto)
# -> assets/sprites/mueble-<tipo>.png (+ .json), a escala 1
#   py tools/venta_ropa_gpt.py   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (id, tipo, alto): el alto en píxeles, que en el juego son unidades (escala 1, como la dependienta de 112 px, de 105 de alto: el
# dibujo tiene el doble de detalle que los muebles a escala 2, "escala": 1 en catalogo.gd); el ancho sale de la proporción de la imagen
# recortada. Las alturas, pensadas para la dependienta: los maniquíes un poco más altos que ella, los muebles de pared casi hasta lo
# alto de la pared (128), los percheros del suelo algo más bajos que ella
MUEBLES = [("p1", "ropamodulo", 104), ("p2", "ropabarra", 108), ("p3", "ropazapatos", 112), ("p4", "ropavitrina", 108),
           ("p5", "ropaoval", 116), ("s1", "ropaperchero1", 96), ("s2", "ropaperchero2", 96), ("s3", "roparuedas", 92),
           ("s4", "ropamesa", 64), ("s5", "ropatarimas", 56),
           ("m1", "ropamaniqui1", 106), ("m2", "ropamaniqui2", 106), ("m3", "ropamaniqui3", 106), ("m4", "ropamaniqui4", 106)]


def quitar_fondo(im):
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


for id_, tipo, alto in MUEBLES:
    im = quitar_fondo(Image.open(f"assets/sources/ropa/venta-{id_}-gpt.webp").convert("RGBA"))
    im = im.crop(im.getbbox())
    ancho = max(1, round(alto * im.width / im.height))
    s = im.convert("RGBa").resize((ancho, alto), Image.LANCZOS).convert("RGBA")
    s.putalpha(s.split()[3].point(lambda v: 255 if v > 110 else 0))
    ruta = f"assets/sprites/mueble-{tipo}.png"
    s.save(ruta)
    with open(ruta.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [ancho, alto], "pivot": [ancho // 2, alto], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")
    print(f"{tipo}: {ancho}x{alto}")
