# Los muebles de la sala de venta de la tienda de ropa (18 nov, el dueño; GPT, ropa de los años 90): 14 imágenes sobre negro puro
# (assets/sources/ropa/venta-<id>-gpt.webp) reducidas a sprite de doble detalle MEZCLANDO colores (LANCZOS, alfa premultiplicado, como tools/muebles_gpt.py):
#   pared:  p1 ropamodulo, p2 ropabarra, p3 ropazapatos, p4 ropavitrina, p5 ropaoval
#   suelo:  s1 ropaperchero1, s2 ropaperchero2, s3 roparuedas, s4 ropamesa, s5 ropatarimas
#   caja: caja ropamostrador (el mostrador con la caja, visto desde el lado del comprador: la caja y el monitor, de espaldas)
#   maniquíes: m1..m4 ropamaniqui1..4
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
           ("caja", "ropamostrador", 92), ("m1", "ropamaniqui1", 106), ("m2", "ropamaniqui2", 106), ("m3", "ropamaniqui3", 106), ("m4", "ropamaniqui4", 106)]


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


# 19 nov, el dueño: el zapatero (p3), dorado como los muebles de pared en vez de metal blanco. El armazón (los dos postes y las cinco
# baldas: columnas y filas casi enteras de gris) se pasa a la rampa de dorado de ropamodulo (p1) según lo claro de cada píxel; los
# zapatos, aunque sean blancos, no se tocan (solo se mira dentro de postes y baldas)
DORADO = [(0, (10, 7, 2)), (30, (44, 31, 11)), (70, (92, 58, 16)), (110, (142, 89, 25)), (150, (191, 115, 26)),
          (180, (219, 145, 36)), (235, (248, 192, 36)), (255, (255, 215, 70))]


def gris(p):
    return max(p[:3]) - min(p[:3]) < 45


def dorado(v):
    for (a, ca), (b, cb) in zip(DORADO, DORADO[1:]):
        if v <= b:
            t = (v - a) / (b - a)
            return tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))
    return DORADO[-1][1]


def a_dorado(im):
    px = im.load()
    w, h = im.size
    def tramos(cuenta, largo, minimo):
        si = [i for i in range(largo) if cuenta[i] > 0.6]
        grupos = []
        for i in si:
            if grupos and i - grupos[-1][1] <= 6:
                grupos[-1][1] = i
            else:
                grupos.append([i, i])
        return [(a - 6, b + 6) for a, b in grupos if b - a + 1 >= minimo]
    claro = lambda p: max(p[:3]) > 110 and gris(p)
    postes = tramos([sum(claro(px[x, y]) for y in range(h)) / h for x in range(w)], w, 6)
    baldas = tramos([sum(claro(px[x, y]) for x in range(w)) / w for y in range(h)], h, 15)
    x0, x1 = postes[0][0], postes[-1][1]
    for y in range(h):
        en_balda = any(a <= y <= b for a, b in baldas)
        for x in range(w):
            if not (any(a <= x <= b for a, b in postes) or (en_balda and x0 <= x <= x1)):
                continue
            p = px[x, y]
            if p[3] == 0 or max(p[:3]) < 12 or not gris(p):
                continue
            px[x, y] = dorado(max(p[:3])) + (p[3],)
    return im


# 19 nov, el dueño: el perchero de ruedas (s3), dorado también. Su armazón (postes, barra de arriba con sus curvas y bandeja de abajo)
# no va en columnas y filas enteras: se pinta todo el metal gris claro unido a los dos postes (rellenando desde un punto de cada poste, a
# media altura), sin pasar por los contornos oscuros, así que la ropa blanca no se toca
def a_dorado_unido(im):
    px = im.load()
    w, h = im.size
    claro = lambda p: p[3] > 0 and max(p[:3]) > 90 and gris(p)
    y = h // 2
    fila = [x for x in range(w) if claro(px[x, y])]
    hecho = bytearray(w * h)
    cola = deque([(fila[0], y), (fila[-1], y)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or hecho[y * w + x] or not claro(px[x, y]):
            continue
        hecho[y * w + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    # y lo gris oscuro pegado (las sombras del metal), una vuelta de 3 píxeles
    for _ in range(3):
        nuevos = [(x, y) for y in range(1, h - 1) for x in range(1, w - 1) if not hecho[y * w + x] and px[x, y][3] > 0
                  and max(px[x, y][:3]) >= 12 and gris(px[x, y]) and (hecho[y * w + x - 1] or hecho[y * w + x + 1]
                  or hecho[(y - 1) * w + x] or hecho[(y + 1) * w + x])]
        for x, y in nuevos:
            hecho[y * w + x] = 2
    for y in range(h):
        for x in range(w):
            if hecho[y * w + x]:
                p = px[x, y]
                px[x, y] = dorado(max(p[:3])) + (p[3],)
    return im


for id_, tipo, alto in MUEBLES:
    im = quitar_fondo(Image.open(f"assets/sources/ropa/venta-{id_}-gpt.webp").convert("RGBA"))
    if id_ == "p3":
        im = a_dorado(im)
    if id_ == "s3":
        im = a_dorado_unido(im)
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
