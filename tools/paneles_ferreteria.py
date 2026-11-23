# Los paneles de herramientas de la pared de la sala de venta de la ferretería (23 nov, el dueño): cada uno, un panel
# perforado vacío de GPT (assets/sources/centro/panel-vacio*-gpt.webp) con una herramienta de GPT colgada varias veces,
# de varios tamaños, con sus ganchos, su sombra y su etiqueta de precio naranja. Hay huecos vacíos (solo ganchos y
# etiqueta), alguna colgada torcida y sangre por encima. Se monta todo a tamaño de GPT y luego se reduce mezclando
# colores, como tools/muebles_gpt.py, para que las herramientas y el panel queden con el mismo acabado.
# Dónde va cada panel en la pared: mapa.gd, PANELES_TIENDA.
#   py tools/paneles_ferreteria.py              → todos
#   py tools/paneles_ferreteria.py alicates     → solo ese (assets/sprites/panel-alicates.png)
#   (y luego Godot --headless --path . --import)
# Para mirar el montaje grande: capturas/panel-<nombre>-grande.png (capturas/ no va en git)
import math
import os
import random
import sys
from collections import deque
from PIL import Image, ImageDraw

ANCHO, ALTO = 136, 86             # a escala 1: un píxel por unidad
CONTORNO = (26, 26, 26, 255)      # casi negro, como los contornos de GPT
B = 11                            # el tamaño de un «píxel» de GPT en sus imágenes (1536 / 136)

# Cada panel:
#   panel, herramienta: las imágenes de GPT; recorte: la caja del panel en su imagen (si algo se sale del marco, como el
#     chorretón de sangre del azul), o None para recortar por todo lo que no es fondo
#   colgar: "cabeza", de dos ganchos debajo de la cabeza, a los lados del mango (el martillo); "medio", de un gancho
#     entre los dos mangos, justo debajo de donde se juntan (los alicates); "agujero", boca abajo, de un gancho metido
#     en el agujero del final del mango (la llave inglesa); "rollo", de un gancho metido por el agujero del centro (la cinta);
#     "hueco", de un gancho metido por un hueco cerrado de arriba (el del mango del serrucho); "cuerpo", tumbada, con el
#     cuerpo apoyado en dos ganchos ("apoyos": dónde, en tanto por uno del ancho; la radial)
#   girar: (si hace falta) los grados que se gira la herramienta de GPT antes de colgarla, al revés que las agujas del reloj
#   apoyo: con "cabeza", a qué alto (en tanto por uno) van los ganchos; por defecto, 0.15 (debajo de la cabeza del martillo)
#   oscurecer: la parte de arriba (en tanto por uno del alto) cuyos grises se oscurecen, o 0; oscuro: cuánto (por defecto, a la mitad)
#   huecos: (centro x, alto de arriba y, alto de la herramienta, giro en grados, qué hay), en píxeles del panel ya
#     recortado (unos 1396x885): "colgada", "vacio" (solo ganchos y etiqueta) o "torcido" (girada)
#   colores: (si la herramienta se tiñe, la cinta) el color de cada hueco, de COLORES_CINTA
#   sangre: (x, y, tamaño, chorretones), encima de todo
PANELES = {
    "martillos": {
        "panel": "assets/sources/centro/panel-vacio-gpt.webp",
        "herramienta": "assets/sources/centro/martillo-gpt.webp",
        "recorte": None,
        "colgar": "cabeza",
        # la cabeza, más oscura (23 nov, el dueño: gris claro sobre la chapa gris no destacaba)
        "oscurecer": 0.3,
        "huecos": [
            (175, 120, 310, 0, "colgada"), (400, 120, 310, 0, "vacio"), (625, 120, 290, 0, "colgada"),
            (850, 120, 310, 9, "torcido"), (1075, 120, 290, 0, "colgada"),
            (160, 505, 255, 0, "colgada"), (355, 505, 215, 0, "colgada"), (550, 505, 255, 0, "vacio"),
            (745, 505, 215, 0, "colgada"), (940, 505, 255, 0, "colgada"), (1140, 505, 215, 0, "colgada"),
        ],
        "sangre": [
            (190, 165, 4, 3),      # en la cabeza del primero
            (630, 330, 3, 2),      # en el mango del de en medio
            (470, 450, 5, 3),      # en la chapa, entre las dos filas
            (870, 230, 3, 2),      # en el torcido
            (745, 590, 4, 3),      # en la cabeza de uno de abajo
            (1150, 640, 3, 2),     # en el pequeño de la derecha
        ],
    },
    # el panel azul (con los tres tiros arriba a la derecha: ahí no va nada) con los alicates de mango naranja
    "alicates": {
        "panel": "assets/sources/centro/panel-vacio-azul-gpt.webp",
        "herramienta": "assets/sources/centro/alicates-gpt.webp",
        "recorte": (71, 72, 1467, 956),
        "colgar": "medio",
        "oscurecer": 0,
        "huecos": [
            (150, 110, 300, 0, "colgada"), (350, 110, 260, 0, "colgada"), (550, 110, 300, 0, "vacio"),
            (750, 110, 260, 0, "colgada"), (950, 110, 300, -10, "torcido"), (1150, 110, 260, 0, "colgada"),
            (160, 500, 235, 0, "colgada"), (370, 500, 270, 0, "colgada"), (580, 500, 235, 0, "colgada"),
            (790, 500, 270, 0, "vacio"), (1000, 500, 235, 0, "colgada"), (1210, 500, 270, 0, "colgada"),
        ],
        "sangre": [
            (350, 200, 4, 3),      # en la cabeza del segundo
            (960, 330, 3, 2),      # en el torcido
            (560, 440, 5, 3),      # en la chapa, entre las dos filas
            (370, 680, 3, 2),      # en los mangos de uno de abajo
            (1210, 600, 4, 2),     # en el de la derecha de abajo
        ],
    },
    # el segundo panel azul (con el marco doblado arriba a la izquierda, sangre y tornillos oxidados arriba a la derecha,
    # pintura amarilla abajo a la derecha y un desgarro abajo en medio: ahí no va nada) con las llaves inglesas, boca abajo y
    # con su cromado de siempre (23 nov, el dueño: oscurecidas, en el panel gris, le gustaban menos)
    "llaves": {
        "panel": "assets/sources/centro/panel-vacio-azul2-gpt.webp",
        "herramienta": "assets/sources/centro/llave-inglesa-gpt.webp",
        "recorte": (70, 79, 1468, 954),
        "colgar": "agujero",
        "oscurecer": 0,
        "huecos": [
            (170, 125, 300, 0, "colgada"), (390, 125, 260, 0, "colgada"), (610, 125, 300, 0, "vacio"),
            (830, 125, 260, 0, "colgada"), (1050, 125, 300, 8, "torcido"),
            (175, 510, 270, 0, "colgada"), (380, 510, 235, 0, "colgada"), (560, 510, 270, 0, "colgada"),
            (830, 510, 235, 0, "vacio"), (1010, 510, 270, 0, "colgada"),
        ],
        "sangre": [
            (390, 300, 4, 3),      # en el mango del segundo
            (1060, 380, 3, 2),     # en la cabeza del torcido
            (700, 450, 5, 3),      # en la chapa, entre las dos filas
            (175, 700, 3, 2),      # en el de abajo a la izquierda
            (1010, 640, 4, 2),     # en el de abajo a la derecha
        ],
    },
    # el panel gris con remaches (sin nada delante de la abolladura de la izquierda, del tornillo arrancado de arriba
    # ni de los zarpazos de abajo a la derecha) con los taladros, de lado, con el cuerpo apoyado en dos ganchos
    "taladros": {
        "panel": "assets/sources/centro/panel-vacio-remaches-gpt.webp",
        "herramienta": "assets/sources/centro/taladro-gpt.webp",
        "recorte": None,
        "colgar": "cabeza",
        "apoyo": 0.43,        # (los ganchos, debajo del cuerpo, a los lados de la empuñadura)
        "oscurecer": 0,
        "huecos": [
            (290, 115, 280, 0, "colgada"), (590, 115, 250, 0, "colgada"), (890, 115, 280, 0, "vacio"),
            (1190, 115, 250, 6, "torcido"),
            (290, 500, 270, 0, "colgada"), (590, 500, 240, 0, "colgada"), (890, 500, 270, 0, "colgada"),
        ],
        "sangre": [
            (300, 200, 4, 3),      # en el cuerpo del primero
            (1190, 250, 3, 2),     # en el torcido
            (760, 455, 5, 3),      # en la chapa, entre las dos filas
            (600, 600, 3, 2),      # en el pequeño de abajo
            (890, 560, 4, 2),      # en el de abajo a la derecha
        ],
    },
    # el panel gris con cinta americana (sin nada delante de la grieta, la sangre de arriba, las telarañas, el óxido de la
    # derecha, la cinta de abajo a la izquierda ni la huella de grasa) con rollos de cinta aislante de varios colores (el rollo
    # de GPT es blanco y se tiñe: COLORES_CINTA)
    "cinta": {
        "panel": "assets/sources/centro/panel-vacio-cinta-gpt.webp",
        "herramienta": "assets/sources/centro/cinta-aislante-gpt.webp",
        "recorte": None,
        "colgar": "rollo",
        "oscurecer": 0,
        "huecos": [
            (270, 200, 200, 0, "colgada"), (500, 200, 180, 0, "colgada"), (730, 200, 200, 0, "colgada"),
            (960, 200, 180, 0, "vacio"), (1190, 200, 200, 0, "colgada"),
            (330, 500, 180, 0, "colgada"), (550, 500, 200, 0, "colgada"), (770, 500, 180, 0, "colgada"),
            (990, 500, 200, 0, "colgada"),
        ],
        "colores": ["negro", "rojo", "azul", "negro", "amarillo", "verde", "negro", "blanco", "rojo"],
        "sangre": [
            (1190, 250, 3, 2),     # en el amarillo (en los oscuros no se vería)
            (860, 450, 4, 3),      # en la chapa, entre las dos filas
            (780, 560, 3, 2),      # en el blanco
        ],
    },
    # el tercer panel azul, el del marco negro (sin nada delante del golpe de arriba, la mancha de humedad de la derecha,
    # los arañazos de abajo a la izquierda ni el rastro de sangre de abajo) con serruchos, de pie: del hueco del mango, la
    # hoja hacia abajo (el serrucho de GPT, en horizontal, se gira)
    "serruchos": {
        "panel": "assets/sources/centro/panel-vacio-azul3-gpt.webp",
        "herramienta": "assets/sources/centro/serrucho-gpt.webp",
        "recorte": None,
        "colgar": "hueco",
        "girar": 90,
        "oscurecer": 0,
        "huecos": [
            (150, 110, 330, 0, "colgada"), (330, 110, 290, 0, "colgada"), (510, 110, 330, 0, "vacio"),
            (690, 110, 290, 0, "colgada"), (870, 110, 330, 7, "torcido"), (1050, 110, 290, 0, "colgada"),
            (270, 520, 265, 0, "colgada"), (450, 520, 230, 0, "colgada"), (630, 520, 265, 0, "vacio"),
            (810, 520, 230, 0, "colgada"), (990, 520, 210, 0, "colgada"),
        ],
        "sangre": [
            (330, 330, 4, 3),      # en la hoja del segundo
            (880, 250, 3, 2),      # en el torcido
            (560, 470, 5, 3),      # en la chapa, entre las dos filas
            (450, 660, 3, 2),      # en uno de abajo
        ],
    },
    # el cuarto panel gris, el del marco de aluminio (sin nada delante de la cinta de precaución, el corte de hacha, la
    # quemadura ni la sangre de abajo a la derecha) con radiales, tumbadas, con el cuerpo en dos ganchos
    "radiales": {
        "panel": "assets/sources/centro/panel-vacio-aluminio-gpt.webp",
        "herramienta": "assets/sources/centro/radial-gpt.webp",
        "recorte": None,
        "colgar": "cuerpo",
        "apoyos": [0.48, 0.78],
        "oscurecer": 0,
        "huecos": [
            (250, 200, 210, 0, "colgada"), (705, 200, 190, 0, "colgada"), (1160, 200, 210, 0, "colgada"),
            (560, 505, 210, -10, "torcido"), (1000, 505, 190, 0, "colgada"),
        ],
        "sangre": [
            (300, 330, 4, 3),      # en el disco de la primera
            (1150, 310, 3, 2),     # en el cuerpo de la de la derecha
            (800, 470, 4, 3),      # en la chapa, entre las dos filas
            (980, 600, 3, 2),      # en la de abajo
        ],
    },
}


def sin_fondo(ruta, recorte=None, todo_negro=False):
    """La imagen de GPT sin el negro puro que se llega desde el borde, recortada (como muebles_gpt.pasar). Con todo_negro,
    también el de los huecos encerrados (el agujero del rollo de cinta)."""
    im = Image.open(ruta).convert("RGBA")
    W, H = im.size
    px = im.load()
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    if todo_negro:
        cola.extend((x, y) for y in range(H) for x in range(W) if max(px[x, y][:3]) < 6)
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
    return im.crop(recorte or im.getbbox())


def gancho(d, x, y):
    """Un gancho del panel visto de frente: la punta de metal gris con su brillo y su contorno (x, y: arriba en medio)."""
    d.rounded_rectangle((x - 3 * B // 2, y, x + 3 * B // 2, y + 3 * B), radius=B // 2, fill=CONTORNO)
    d.rectangle((x - B // 2, y + B // 2, x + B // 2, y + 2 * B), fill=(118, 120, 126, 255))
    d.rectangle((x - B // 2, y + B // 2, x + B // 2, y + B), fill=(160, 162, 168, 255))


def etiqueta(d, x, y):
    """La etiqueta de precio naranja, lisa (x, y: arriba en medio)."""
    d.rectangle((x - 4 * B, y, x + 4 * B - 1, y + 3 * B - 1), fill=(70, 30, 10, 255))
    d.rectangle((x - 3 * B, y + B, x + 3 * B - 1, y + 2 * B - 1), fill=(255, 130, 30, 255))
    d.rectangle((x - 3 * B, y + B, x + 3 * B - 1, y + B + 4), fill=(255, 175, 80, 255))


def sangre(d, x, y, tam, semilla, gotas=2):
    """Una salpicadura de sangre a cuadrados de GPT: una mancha, gotitas alrededor y unos chorretones que caen."""
    r = random.Random(semilla)
    rojos = [(115, 12, 12, 255), (150, 22, 20, 255), (85, 8, 8, 255), (175, 32, 26, 255)]
    for _ in range(tam * 7):          # la mancha
        dx, dy = r.gauss(0, tam * B / 2.2), r.gauss(0, tam * B / 2.6)
        px, py = x + int(dx) // B * B, y + int(dy) // B * B
        d.rectangle((px, py, px + B - 1, py + B - 1), fill=r.choice(rojos))
    for _ in range(tam * 2):          # las gotitas
        px = x + int(r.uniform(-tam * B * 1.4, tam * B * 1.4)) // B * B
        py = y + int(r.uniform(-tam * B, tam * B)) // B * B
        d.rectangle((px, py, px + B - 1, py + B - 1), fill=rojos[2])
    for _ in range(gotas):            # los chorretones, hacia abajo, con su gota al final
        px = x + int(r.uniform(-tam * B / 2, tam * B / 2)) // B * B
        largo = r.randint(2, 2 + tam) * B
        d.rectangle((px, y, px + B - 1, y + largo), fill=rojos[0])
        d.rectangle((px - B // 2, y + largo, px + B + B // 2 - 1, y + largo + B + B // 2), fill=rojos[2])


# Los colores de la cinta aislante (los de siempre), para teñir el rollo blanco de GPT: lo gris (la cinta), multiplicado
# por su color y con su brillo; el cartón del centro (marrón: tiene color), igual
COLORES_CINTA = {
    "negro": (58, 58, 64), "rojo": (205, 30, 28), "azul": (35, 75, 190), "amarillo": (240, 200, 30),
    "verde": (40, 150, 60), "blanco": (240, 240, 236),
}


def tenir(m, color):
    m = m.copy()
    pm = m.load()
    for yy in range(m.height):
        for xx in range(m.width):
            r_, g_, b_, a_ = pm[xx, yy]
            if not a_ or max(r_, g_, b_) - min(r_, g_, b_) > 30:
                continue
            luz = max(r_, g_, b_) / 235.0
            brillo = max(0.0, luz - 0.92) / 0.08 * 90
            pm[xx, yy] = tuple(min(255, int(c * min(luz, 1.0) + brillo)) for c in color) + (a_,)
    return m


def huecos_cerrados(m, hasta):
    """Los píxeles transparentes de m que no se llegan desde el borde (los huecos cerrados), de las filas de arriba (hasta "hasta")."""
    a = m.split()[3].load()
    W, H = m.size
    fuera = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or fuera[y * W + x] or a[x, y] > 0:
            continue
        fuera[y * W + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return [(x, y) for y in range(hasta) for x in range(W) if a[x, y] == 0 and not fuera[y * W + x]]


def montar(nombre, p):
    panel = sin_fondo(p["panel"], p["recorte"])
    herramienta = sin_fondo(p["herramienta"], todo_negro=p["colgar"] in ("rollo", "hueco"))
    if p.get("girar"):
        herramienta = herramienta.rotate(p["girar"], expand=True)   # (en grados, al revés que las agujas del reloj)
    hw, hh = herramienta.size
    if p["oscurecer"]:
        # los grises de arriba (la cabeza), más negros
        ph = herramienta.load()
        for y in range(int(hh * p["oscurecer"])):
            for x in range(hw):
                r_, g_, b_, a_ = ph[x, y]
                if a_ and max(r_, g_, b_) - min(r_, g_, b_) < 40 and max(r_, g_, b_) > 45:
                    k = p.get("oscuro", 0.5)
                    ph[x, y] = (int(r_ * k), int(g_ * k), int(b_ * min(1.0, k * 1.1)), a_)

    capa = Image.new("RGBA", panel.size, (0, 0, 0, 0))     # los ganchos y las etiquetas
    sombras = Image.new("RGBA", panel.size, (0, 0, 0, 0))
    colgadas = Image.new("RGBA", panel.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    puntas = []       # los ganchos que se ven por delante de la herramienta (los del agujero de la llave)

    for i, (cx, y, alto, giro, que) in enumerate(p["huecos"]):
        ancho = round(hw * alto / hh)
        m = herramienta.resize((ancho, alto), Image.LANCZOS)
        if p.get("colores"):
            m = tenir(m, COLORES_CINTA[p["colores"][i]])
        a = m.split()[3].load()
        if p["colgar"] == "cabeza":
            # el mango: su centro en el dibujo (el martillo no es simétrico: la uña sobresale más que la boca)
            xs = [x for x in range(ancho) if a[x, int(alto * 0.6)] > 0]
            centro = (xs[0] + xs[-1]) // 2
            mango_w = xs[-1] - xs[0]
            # los dos ganchos, a los lados del mango, justo debajo de la cabeza (la cabeza se apoya en ellos)
            apoyo = p.get("apoyo", 0.15)
            gy = y + round(alto * apoyo)
            gancho(d, cx - mango_w // 2 - 3 * B // 2, gy)
            gancho(d, cx + mango_w // 2 + 3 * B // 2, gy)
            eje = (centro, round(alto * (apoyo + 0.02)))
        elif p["colgar"] == "rollo":
            # de un gancho metido por el agujero: el rollo se apoya en él por arriba (el gancho se ve por el agujero)
            centro = ancho // 2
            arriba = next(yy for yy in range(alto // 2, 0, -1) if a[centro, yy] > 0)
            gancho(d, cx, y + arriba + 1)
            eje = (centro, alto // 2)
        elif p["colgar"] == "cuerpo":
            # tumbada, con el cuerpo apoyado en dos ganchos (en "apoyos", en tanto por uno del ancho), justo debajo de él
            centro = ancho // 2
            puntos = []
            for fx in p["apoyos"]:
                col = int(fx * ancho)
                abajo = max(yy for yy in range(alto) if a[col, yy] > 0)
                puntos.append((col, abajo))
                if que != "torcido" or fx == p["apoyos"][0]:
                    gancho(d, cx - centro + col, y + abajo - B)
            if que == "torcido":   # (colgada solo del primero: el otro gancho, vacío)
                gancho(d, cx - centro + puntos[1][0], y + puntos[1][1] - B)
            eje = puntos[0]
        elif p["colgar"] == "hueco":
            # de un gancho metido por un hueco cerrado de la parte de arriba (el del mango del serrucho), apoyado en él por
            # arriba; el gancho se ve por el hueco
            dentro = huecos_cerrados(m, int(alto * 0.45))
            centro = sum(q[0] for q in dentro) // len(dentro)
            arriba = min(q[1] for q in dentro)
            gancho(d, cx, y + arriba + 1)
            eje = (centro, arriba + B)
        elif p["colgar"] == "agujero":
            # boca abajo: el agujero del mango, arriba; el gancho sale del panel por él (se ve dentro del agujero)
            m = m.rotate(180)
            a = m.split()[3].load()
            pm = m.load()
            hueco = [(xx, yy) for yy in range(int(alto * 0.15)) for xx in range(ancho) if a[xx, yy] > 0 and max(pm[xx, yy][:3]) < 20]
            centro = sum(q[0] for q in hueco) // len(hueco)
            eje = (centro, sum(q[1] for q in hueco) // len(hueco))
            gy = y + eje[1] - 3 * B // 2
            if que == "vacio":
                gancho(d, cx, gy)
            else:
                puntas.append((cx, gy, giro))
        else:
            # un gancho entre los dos mangos, donde empiezan a separarse (los alicates se apoyan en él por la unión)
            centro = ancho // 2
            abre = next(yy for yy in range(int(alto * 0.35), alto) if a[centro, yy] == 0 and a[centro, yy + B // 2] == 0)
            gy = y + abre - B
            gancho(d, cx, gy)
            eje = (centro, abre)
        if que == "torcido" and p["colgar"] in ("agujero", "hueco", "cuerpo"):
            # girada alrededor del agujero, que se queda en su gancho
            w0, h0 = m.size
            m = m.rotate(-giro, resample=Image.BICUBIC, expand=True)
            t = math.radians(-giro)
            dx, dy = eje[0] - w0 / 2, eje[1] - h0 / 2
            ex = dx * math.cos(t) + dy * math.sin(t) + m.width / 2
            ey = -dx * math.sin(t) + dy * math.cos(t) + m.height / 2
            x0, y0 = round(cx - ex), round(y + eje[1] - ey)
        elif que == "torcido":
            m = m.rotate(-giro, resample=Image.BICUBIC, expand=True, center=eje)
            # (al girar con expand, el eje se mueve: se vuelve a poner en su sitio)
            x0, y0 = cx - m.width // 2 + (2 * B if giro > 0 else -2 * B), y - B
        else:
            x0, y0 = cx - centro, y
        etiqueta(d, cx, y + alto + 2 * B)
        if que == "vacio":
            continue
        colgadas.alpha_composite(m, (x0, y0))
        sombra = Image.new("RGBA", m.size, (0, 0, 0, 0))
        sombra.putalpha(m.split()[3].point(lambda v: 95 if v > 110 else 0))
        sombras.alpha_composite(sombra, (x0 + B, y0 + B))

    junto = panel.copy()
    junto.alpha_composite(sombras)
    junto.alpha_composite(capa)
    junto.alpha_composite(colgadas)
    if puntas:
        delante = Image.new("RGBA", panel.size, (0, 0, 0, 0))
        dd = ImageDraw.Draw(delante)
        for cx, gy, _giro in puntas:
            gancho(dd, cx, gy)
        junto.alpha_composite(delante)
    manchas = Image.new("RGBA", panel.size, (0, 0, 0, 0))
    dm = ImageDraw.Draw(manchas)
    for i, (x, y, tam, gotas) in enumerate(p["sangre"]):
        sangre(dm, x, y, tam, i, gotas)
    # la sangre, solo dentro del panel (no por fuera del marco)
    alfa = Image.composite(manchas.split()[3], Image.new("L", panel.size, 0), panel.split()[3].point(lambda v: 255 if v > 0 else 0))
    manchas.putalpha(alfa)
    junto.alpha_composite(manchas)
    os.makedirs("capturas", exist_ok=True)
    junto.save(f"capturas/panel-{nombre}-grande.png")
    # reducido mezclando colores (premultiplicado) y el borde sin medias tintas, como muebles_gpt.pasar
    salida = junto.convert("RGBa").resize((ANCHO, ALTO), Image.LANCZOS).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    ruta = f"assets/sprites/panel-{nombre}.png"
    salida.save(ruta)
    print(f"{ruta}: {ANCHO}x{ALTO} (de {panel.size[0]}x{panel.size[1]})")


for nombre in sys.argv[1:] or list(PANELES):
    montar(nombre, PANELES[nombre])
