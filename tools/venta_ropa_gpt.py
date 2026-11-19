# Los muebles de la sala de venta de la tienda de ropa (18 nov, el dueño; GPT, ropa de los años 90): 14 imágenes sobre negro puro
# (assets/sources/ropa/venta-<id>-gpt.webp) reducidas a sprite de doble detalle MEZCLANDO colores (LANCZOS, alfa premultiplicado, como tools/muebles_gpt.py):
#   pared:  p1 ropamodulo, p2 ropabarra, p3 ropazapatos, p4 ropavitrina, p5 ropaoval
#   suelo:  s1 ropaperchero1, s2 ropaperchero2, s3 roparuedas, s4 ropamesa, s5 ropatarimas
#   caja: caja ropamostrador (el mostrador con la caja, visto desde el lado del comprador: la caja y el monitor, de espaldas)
#   maniquíes: m1..m4 ropamaniqui1..4
# Desde el 19 nov, el módulo (p1), el zapatero (p3) y la caja salen de sus imágenes destrozadas (venta-<id>-destrozado-gpt.webp, también
# de GPT, a partir de las limpias; el dueño): la tienda ya es del apocalipsis
# -> assets/sprites/mueble-<tipo>.png (+ .json), a escala 1
#   py tools/venta_ropa_gpt.py   (y luego Godot --headless --path . --import)
import json
from collections import deque
from PIL import Image

# (id, tipo, alto): el alto en píxeles, que en el juego son unidades (escala 1, como la dependienta de 112 px, de 105 de alto: el
# dibujo tiene el doble de detalle que los muebles a escala 2, "escala": 1 en catalogo.gd); el ancho sale de la proporción de la imagen
# recortada. Las alturas, pensadas para la dependienta: los maniquíes un poco más altos que ella, los muebles de pared casi hasta lo
# alto de la pared (128), los percheros del suelo algo más bajos que ella
MUEBLES = [("p1-destrozado", "ropamodulo", 104), ("p2", "ropabarra", 108), ("p3-destrozado", "ropazapatos", 112), ("p4", "ropavitrina", 108),
           ("p5", "ropaoval", 116), ("s1", "ropaperchero1", 96), ("s2", "ropaperchero2", 96), ("s3", "roparuedas", 92),
           ("s4", "ropamesa", 64), ("s5", "ropatarimas", 56),
           ("caja-destrozado", "ropamostrador", 92), ("m1", "ropamaniqui1", 106), ("m2", "ropamaniqui2", 106), ("m3", "ropamaniqui3", 106), ("m4", "ropamaniqui4", 106)]


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


# 19 nov, el dueño: los muebles de metal blanco, dorados como los de pared. La rampa de dorado de ropamodulo (p1): cada píxel gris pasa al
# dorado de lo claro que sea
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


# El zapatero destrozado (p3-destrozado, 19 nov, el dueño: de GPT, en blanco sucio): sus dos postes, sus baldas rectas y la del medio, rota y
# hundida en diagonal, se pasan a dorado (dentro de esos trozos, en píxeles de la imagen de GPT, solo lo gris: los zapatos no se tocan,
# aunque alguna suela blanca que toca una balda coge algo de dorado)
def a_dorado_zapatero_roto(im):
    from PIL import ImageDraw
    mascara = Image.new("L", im.size, 0)
    d = ImageDraw.Draw(mascara)
    for x0, x1 in ((58, 130), (1068, 1142)):
        d.rectangle((x0, 0, x1, im.height), fill=255)
    for y0, y1 in ((248, 302), (455, 515), (905, 977), (1105, 1192)):
        d.rectangle((100, y0, 1100, y1), fill=255)
    d.polygon([(100, 662), (625, 727), (1075, 835), (1075, 905), (620, 800), (100, 728)], fill=255)
    m = mascara.load()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            q = px[x, y]
            if m[x, y] and q[3] > 0 and max(q[:3]) >= 12 and gris(q):
                px[x, y] = dorado(max(q[:3])) + (q[3],)
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


# 19 nov, el dueño: las patas de la mesa de los accesorios (s4), doradas (los soportes de encima, de metal como estaban): todo lo gris
# por debajo del canto de madera del tablero (la última fila con más de la mitad de color que no es gris)
def a_dorado_patas(im):
    px = im.load()
    w, h = im.size
    canto = max(y for y in range(h) if sum(1 for x in range(w) if px[x, y][3] > 0 and not gris(px[x, y])) > w / 2)
    for y in range(canto + 1, h):
        for x in range(w):
            p = px[x, y]
            if p[3] > 0 and max(p[:3]) >= 12 and gris(p):
                px[x, y] = dorado(max(p[:3])) + (p[3],)
    return im


for id_, tipo, alto in MUEBLES:
    im = quitar_fondo(Image.open(f"assets/sources/ropa/venta-{id_}-gpt.webp").convert("RGBA"))
    if id_ == "p3-destrozado":
        im = a_dorado_zapatero_roto(im)
    if id_ == "s3":
        im = a_dorado_unido(im)
    if id_ == "s4":
        im = a_dorado_patas(im)
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
