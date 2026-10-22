# Dibuja los 32 objetos de la mochila a 16×16 píxeles (más detalle que los de 10×10 de src/objetos.js, que
# les sirven de modelo): contorno oscuro, luz arriba a la izquierda y sombra abajo a la derecha. Los 17 de siempre,
# los 9 del centro comercial (parte 6 de docs/CENTRO_COMERCIAL.md), los 2 de curar (parte 9) y, al final, los 4
# trajes de Johnny (parte 11: la misma plantilla, un peto con su camisa colgado de una percha, con los colores de cada
# uno, TRAJES).
# Los saca en assets/ui/iconos/obj-<id>.png (los usan el suelo, la mochila, el baúl y el banco).
#   py tools/objetos16.py            → los iconos
#   py tools/objetos16.py muestra    → además, tools/objetos16.png con todos en grande, para revisarlos
import math
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"

# Una letra = un color (el punto es hueco). Las minúsculas son el tono normal; las mayúsculas, el oscuro
# (y P, L, W, c, l, h, e los claros)
PALETA = {
    "o": "#2a1f2e",                                   # contorno
    "k": "#1a1a1a", "K": "#3a3a44",                   # negro y gris muy oscuro
    "d": "#5d6470", "g": "#9aa0a8", "G": "#d0d4da",   # metal: sombra, medio, luz
    "W": "#ffffff",
    "r": "#d0453a", "R": "#8a2a2a", "P": "#ff7a6a",   # rojo
    "y": "#f2c94c", "Y": "#b88a1e", "L": "#fff0a0",   # amarillo
    "b": "#4a7bd0", "B": "#2a4f90", "c": "#8ab4f0",   # azul
    "w": "#f1f1e6", "e": "#c8c8b8",                   # blanco y su sombra
    "m": "#8a5a34", "M": "#5c3a20", "h": "#b07a48",   # madera
    "v": "#5aa05a", "V": "#3a6a3a", "l": "#8ad08a",   # verde
    "n": "#ff9f1c", "N": "#c06a10",                   # naranja
    "p": "#e07be0", "q": "#a04aa0",                   # rosa
}

DIBUJOS = {
    "clavos": [
        ".oooo...........",
        "oGGGGo...oooo...",
        "oddddo..oGGGGo..",
        ".oGgo...oddddo..",
        "..oGo....oGgo...",
        "..oGo.....oGo...",
        "..ogo.....ogo...",
        "..ogo.....ogo...",
        "..odo.....odo...",
        "...o.......o....",
        ".oo.............",
        "oGGo............",
        "oGgoooooooooooo.",
        "oGgGGGGGgggggddo",
        "oGgoooooooooooo.",
        ".oo.............",
    ],
    "gasolina": [
        "................",
        "...ooo..........",
        "...odo..ooooo...",
        "..ooooooorrrro..",
        "..oPPrrrroooRo..",
        "..oPrrrrrrrrRo..",
        "..orRRRRRRRRRo..",
        "..orRwwwwwwRRo..",
        "..orRwkkkkwRRo..",
        "..orRwwwwwwRRo..",
        "..orRRRRRRRRRo..",
        "..orrrrrrrrrRo..",
        "..orrrrrrrrrRo..",
        "..oRRRRRRRRRRo..",
        "..oooooooooooo..",
        "................",
    ],
    "pistola_agua": [
        "................",
        ".......ooo......",
        "......ovvvo.....",
        "......olvvo.....",
        "..oooooVVVoooo..",
        ".onLLLLLLLLLnnoo",
        ".onnnnnnnnnnnnbo",
        ".onNNNNNNNNNNnbo",
        ".ooonnnNoooooooo",
        "...onnnNo.ono...",
        "...onnnNo.oo....",
        "...onnnNo.......",
        "...onnnNo.......",
        "...oNNNNo.......",
        "...ooooo........",
        "................",
    ],
    "spray": [
        "................",
        "......ooo..p....",
        "......oKko...p..",
        "......ooo.p.....",
        "....oooooooo....",
        "....oGGGGgdo....",
        "...oooooooooo...",
        "...oWppppppqo...",
        "...oppppppqqo...",
        "...owwwwwwweo...",
        "...owkwkwkweo...",
        "...owwwwwwweo...",
        "...oppppppqqo...",
        "...oppppppqqo...",
        "...oGGGGGgddo...",
        "...oooooooooo...",
    ],
    "mechero": [
        "......o.........",
        ".....ono........",
        ".....onyo.......",
        "....onyLno......",
        "....onLLyo......",
        ".....oyyo.......",
        "....oooooo......",
        "...oGGGgddo.....",
        "...oGoooodo.....",
        "...oooooooo.....",
        "...ocbbbbBo.....",
        "...ocbbbbBo.....",
        "...ocbbbbBo.....",
        "...ocbbbbBo.....",
        "...oBBBBBBo.....",
        "...oooooooo.....",
    ],
    "lejia": [
        "......oooo......",
        "......obbo......",
        "......oBBo......",
        ".....oowwoo.....",
        "....owwwwwweo...",
        "...owwwwwwwweo..",
        "...oWwwwwwwweo..",
        "...obbbbbbbbBo..",
        "...obccbbbbbBo..",
        "...obcbwwbbbBo..",
        "...obbbbbbbbBo..",
        "...owwwwwwwweo..",
        "...oWwwwwwwweo..",
        "...owwwwwwwweo..",
        "...oeeeeeeeeeo..",
        "...ooooooooooo..",
    ],
    "alcohol": [
        ".......oo.......",
        "......oMMo......",
        "......oooo......",
        "......ovlo......",
        "......ovVo......",
        ".....ovvVVo.....",
        "....ovlvvVVo....",
        "...ovlvvvvVVo...",
        "...owwwwwwwwo...",
        "...owRRRRRRwo...",
        "...owwwwwwwwo...",
        "...ovlvvvvVVo...",
        "...ovlvvvvVVo...",
        "...ovvvvvvVVo...",
        "...oVVVVVVVVo...",
        "...oooooooooo...",
    ],
    "trapo": [
        "................",
        "................",
        "...ooooooo......",
        "..owwwwwwwoo....",
        ".owwbwwwwwwwo...",
        ".owwbwwwwweewo..",
        "..owbwwwweeeewo.",
        "..owbbbbbbbbewo.",
        ".owwwwwbwwweewo.",
        "owwwwwwbweewwo..",
        "oewwwwwbeewwwo..",
        ".oeewwwbwwweo...",
        "..ooeeeeeeeo....",
        "....ooooooo.....",
        "................",
        "................",
    ],
    "explosivos": [
        "..........L.....",
        ".........ny.....",
        "........o.......",
        "..ooooooooooooo.",
        "..oPrRoPrRoPrRo.",
        "..oPrRoPrRoPrRo.",
        "..oPrRoPrRoPrRo.",
        "..okkkokkkokkko.",
        "..oKkkoKkkoKkko.",
        "..oPrRoPrRoPrRo.",
        "..oPrRoPrRoPrRo.",
        "..oPrRoPrRoPrRo.",
        "..oPrRoPrRoPrRo.",
        "..oRRRoRRRoRRRo.",
        "..ooooooooooooo.",
        "................",
    ],
    "extintor": [
        "......oooo......",
        "....oooGdooooo..",
        "...okkkkkkkkkko.",
        "....oooGdoooooo.",
        "......oooo.o....",
        ".....oPrrRo.o...",
        "....oPrrrrRoko..",
        "....oPrrrrRoko..",
        "....owwwwwRo.o..",
        "....owkkwwRo.ko.",
        "....owwwwwRo.ko.",
        "....oPrrrrRo..o.",
        "....oPrrrrRo....",
        "....orrrrrRo....",
        "....oRRRRRRo....",
        "....oooooooo....",
    ],
    "taser": [
        "................",
        ".L.L............",
        "..y.y...........",
        ".oGoGooooooo....",
        "..okkkkkkkkko...",
        "..okyyykkKKko...",
        "..okkkkkkkkko...",
        "..ooooookkkko...",
        ".......okkKko...",
        ".......okkKko...",
        ".......okkKko...",
        ".......okyKko...",
        ".......okkKko...",
        ".......oKKKKo...",
        ".......oooooo...",
        "................",
    ],
    "llave_inglesa": [
        "...oo....oo.....",
        "..oGo....oGo....",
        "..oGGo..oGgo....",
        "..oGGGooGggo....",
        "...oGGGGGgo.....",
        "....oGGggo......",
        ".....oGgo.......",
        ".....oGgo.......",
        ".....oGgo.......",
        ".....oGdo.......",
        ".....oGdo.......",
        ".....oGdo.......",
        "....ooGgdoo.....",
        "...oGo...odo....",
        "...oGdo.odo.....",
        "....oooooo......",
    ],
    "hacha": [
        "........ooo.....",
        "..ooooooohMo....",
        ".oWGGGGgohMo....",
        "oGGGggggohMo....",
        "oGGgggggohMo....",
        "oGggggddohMo....",
        ".oGgddooohMo....",
        "..oooo..ohMo....",
        "........ohMo....",
        "........omMo....",
        "........omMo....",
        "........omMo....",
        "........omMo....",
        "........omMo....",
        "........oMMo....",
        "........oooo....",
    ],
    "mancuernas": [
        "................",
        "................",
        "................",
        "................",
        ".ooo........ooo.",
        "oGKKo......oGKKo",
        "oGkKo......oGkKo",
        "oGkKooooooooGkKo",
        "oGkKoGGGggdoGkKo",
        "oGkKogggdddoGkKo",
        "oGkKooooooooGkKo",
        "oGkKo......oGkKo",
        "okkKo......okkKo",
        ".ooo........ooo.",
        "................",
        "................",
    ],
    # ── Los del centro comercial (los demás, con código: ver más abajo) ──
    "bateria": [
        "................",
        "...ooo....ooo...",
        "...oPo....oGo...",
        "...oro....odo...",
        ".oooooooooooooo.",
        ".oGGGGGGGGGGGdo.",
        ".oddddddddddddo.",
        ".oKKKKKKKKKKKko.",
        ".oKKrKKKKKKKKko.",
        ".oKrrrKKKKwwwko.",
        ".oKKrKKKKKKKKko.",
        ".oKKKKKKKKKKKko.",
        ".oKKKKKKKKKKKko.",
        ".okkkkkkkkkkkko.",
        ".oooooooooooooo.",
        "................",
    ],
    "aceite": [
        "................",
        "......oooo......",
        "......ovlo......",
        "......oVVo......",
        ".....oooooo.....",
        "....oLyyyyYo....",
        "...oLyyyyyyYo...",
        "..oLyyyyyyyyYo..",
        "..oLywwwwwwyYo..",
        "..oLywwlvwwyYo..",
        "..oLywvVwwwyYo..",
        "..oLywwwwwwyYo..",
        "..oLyyyyyyyyYo..",
        "..oyyyyyyyyYYo..",
        "..oYYYYYYYYYYo..",
        "..oooooooooooo..",
    ],
    "bombona": [
        "................",
        "....oooooooo....",
        "....oGo..odo....",
        "....oGoKKodo....",
        "...oooooooooo...",
        "..onLLnnnnnnNo..",
        ".onLnnnnnnnnnNo.",
        ".onLnnnnnnnnnNo.",
        ".onnnnnnnnnnnNo.",
        ".oNNNNNNNNNNNNo.",
        ".onnnnnnnnnnnNo.",
        ".onnnnnnnnnnNNo.",
        ".onnnnnnnnnnNNo.",
        "..oNnnnnnnnnNo..",
        "..oKKKKKKKKKKo..",
        "..oooooooooooo..",
    ],
    "hielo_seco": [
        "......c....W....",
        ".....W....W.c...",
        "....W.c....W....",
        ".....W....c.....",
        ".....ooooooooo..",
        "....oWWWWWWWco..",
        "...oWWWWWWWcco..",
        "..ooooooooocco..",
        "..owwwwwwwecco..",
        "..owwwewwwecco..",
        "..owwwwwwwecBo..",
        "..owewwwwwecBo..",
        "..owwwwwwwecBo..",
        "..oeeeeeeeeBo...",
        "..ooooooooooo...",
        "................",
    ],
    # los dos de curar (parte 9): el rollo de vendas con una tira con su cruz roja, y el bocadillo por el lado
    "vendas": [
        "................",
        "...oooooooo.....",
        "..oWwwwwwwweo...",
        ".oWwwwwwwwwweo..",
        ".owwwwwwwwwweo..",
        ".owwwwwwwwwweo..",
        ".oewwwwwwwwweo..",
        ".oeewwwwwwweeo..",
        "..oeeeeeeeeeo...",
        "...oooooooooo...",
        "......owwwwwwwo.",
        "......owwrwwwwo.",
        "......owrrrwwwo.",
        "......owwrwwwwo.",
        "......oeeeeeeeo.",
        "......ooooooooo.",
    ],
    "bocadillo": [
        "................",
        "................",
        "....oooooooo....",
        "..ooLhhhhhhhoo..",
        ".oLhhhhhhhhhhho.",
        ".ohhhhhhhhhhhmo.",
        ".ommmmmmmmmmmmo.",
        ".ovlvvlvvlvvlvo.",
        ".oyyyyyyyyyyyyo.",
        ".oPrrPPrrPPrrPo.",
        ".ohhhhhhhhhhhmo.",
        ".ohhhhhhhhhhmmo.",
        "..oohhhhhhhmoo..",
        "....oooooooo....",
        "................",
        "................",
    ],
}


def disco(fn):
    """Un dibujo redondo hecho con código: fn(x, y) da la letra de cada píxel (o '.') y luego se le pone el
    contorno a todo lo que toca un hueco"""
    rejilla = [[fn(x, y) for x in range(16)] for y in range(16)]
    salida = [fila[:] for fila in rejilla]
    for y in range(16):
        for x in range(16):
            if rejilla[y][x] in ".o":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < 16 and 0 <= ny < 16) or rejilla[ny][nx] == ".":
                    salida[y][x] = "o"
    return ["".join(f) for f in salida]


def sierra(x, y):
    # disco de sierra: dientes alrededor, metal con luz arriba a la izquierda y el agujero del centro
    dx, dy = x - 7.5, y - 7.5
    d = math.hypot(dx, dy)
    a = math.atan2(dy, dx)
    diente = 6.0 + 1.6 * ((a / (2 * math.pi) * 10) % 1.0)
    if d > diente:
        return "."
    if d < 1.2:
        return "k"
    if d < 2.2:
        return "o"
    luz = -(dx + dy) / max(d, 0.1)
    if d > 5.6:
        return "G" if luz > 0.2 else "g"
    return "G" if luz > 0.75 else "g" if luz > -0.5 else "d"


def despertador(x, y):
    # campanas, cuerpo rojo con la esfera blanca, agujas y patas
    for cx in (3.0, 12.0):
        if math.hypot(x - cx, y - 2.5) <= 2.3:
            return "L" if x < cx and y < 2.5 else "y"
    if y == 15 and x in (3, 4, 11, 12):
        return "K"
    dx, dy = x - 7.5, y - 8.5
    d = math.hypot(dx, dy)
    if d > 6.6:
        return "."
    if d > 4.6:
        luz = -(dx + dy) / max(d, 0.1)
        return "P" if luz > 0.6 else "r" if luz > -0.6 else "R"
    if (x == 7 and 5 <= y <= 8) or (y == 8 and 7 <= x <= 10):
        return "k"
    if d > 3.6 and (x + y) % 4 == 0:
        return "e"
    return "w"


def cuerda(x, y):
    # un rollo de cuerda: un aro con las vueltas en diagonal
    dx, dy = x - 7.5, (y - 7.5) / 0.85
    d = math.hypot(dx, dy)
    if d > 7.4 or d < 2.6:
        return "."
    if (x + y) % 3 == 0:
        return "Y"
    return "L" if dx + dy < -4 else "y"


def cinta_americana(x, y):
    # un rollo de cinta gris visto un poco desde arriba: la cara de arriba con el cartón marrón y el agujero, el
    # canto por delante y la tira que cuelga por la derecha
    dx = x - 7.5
    arriba = (dx / 7.2) ** 2 + ((y - 5.0) / 4.4) ** 2 <= 1.0
    abajo = (dx / 7.2) ** 2 + ((y - 8.5) / 4.4) ** 2 <= 1.0
    if arriba:
        hueco = (dx / 2.4) ** 2 + ((y - 5.0) / 1.5) ** 2
        if hueco <= 1.0:
            return "K"
        if hueco <= 2.6:
            return "h"
        return "G" if dx < 2 and y < 5 else "g"
    if 10 <= x <= 12 and 9 <= y <= 15:
        if y == 15 and x == 11:
            return "."   # el borde roto
        return "g" if x < 12 else "d"
    if abajo or (abs(dx) <= 7.2 and 5.0 <= y <= 8.5):
        return "d" if y > 9 or dx > 4 else "g"
    return "."


def cadena(x, y):
    # tres eslabones un poco en diagonal: el primero y el último de cara (con su agujero) y el del medio de canto
    ax, ay = 0.866, -0.5
    for i in (1, 0, 2):
        cx, cy = 7.5 + (i - 1) * 5.0 * ax, 7.5 + (i - 1) * 5.0 * ay
        dx, dy = x - cx, y - cy
        u = dx * ax + dy * ay      # a lo largo de la cadena
        v = -dx * ay + dy * ax     # de lado (positivo, hacia abajo)
        if i == 1:
            if abs(v) <= 1.3 and abs(u) <= 4.0:
                return "G" if v < 0.3 else "g"
            continue
        if (u / 4.0) ** 2 + (v / 3.3) ** 2 <= 1.0 and (u / 2.0) ** 2 + (v / 1.2) ** 2 > 1.0:
            return "G" if v < -0.6 else "d" if v > 1.8 else "g"
    return "."


def cable(x, y):
    # un alargador naranja que baja del enchufe blanco, da la vuelta y acaba en los hilos de cobre
    if y <= 1 and x in (11, 13):
        return "G"
    if 10 <= x <= 14 and 2 <= y <= 6:
        return "w" if x < 14 and y < 6 else "e"
    p = [(12.0, 7.0), (13.0, 16.0), (0.0, 15.0), (2.5, 4.5)]   # una curva de Bézier
    mejor, cual = 9.0, 0.0
    for i in range(121):
        t = i / 120
        a = [(1 - t) ** 3, 3 * t * (1 - t) ** 2, 3 * t * t * (1 - t), t ** 3]
        px = sum(a[k] * p[k][0] for k in range(4))
        py = sum(a[k] * p[k][1] for k in range(4))
        d = math.hypot(x - px, y - py)
        if d < mejor:
            mejor, cual = d, t
    if mejor > 1.45:
        return "."
    if cual > 0.93:
        return "L" if mejor < 0.7 else "y"
    return "n" if mejor < 0.8 else "N"


def jeringuilla(x, y):
    # en diagonal: el émbolo abajo a la izquierda, el cuerpo con el líquido azul y la aguja arriba a la derecha
    dx, dy = x - 7.5, y - 7.5
    u = (dx - dy) / math.sqrt(2)   # hacia arriba a la derecha
    v = (dx + dy) / math.sqrt(2)
    if 3.2 < u <= 8.2 and abs(v) <= 0.4:
        return "G"   # la aguja
    if 2.4 < u <= 3.2 and abs(v) <= 1.0:
        return "g"
    if -3.6 <= u <= 2.4 and abs(v) <= 2.0:
        if u > -1.2 and abs(v) <= 1.1:
            return "c"   # el líquido
        return "w" if v < 0.8 else "e"
    if -4.4 <= u < -3.6 and abs(v) <= 3.2:
        return "e"   # las aletas
    if -7.6 <= u < -4.4 and abs(v) <= 0.9:
        return "g"   # el émbolo
    if -8.4 <= u < -7.6 and abs(v) <= 2.4:
        return "G"
    return "."


def percha(x, y):
    # una percha de madera con su gancho de alambre
    gancho = {(8, 0), (9, 0), (7, 1), (10, 1), (10, 2), (9, 3), (8, 4), (8, 5)}
    if (x, y) in gancho:
        return "G" if y <= 1 or x == 10 else "g"
    if y == 13 and 1 <= x <= 14:
        return "G" if x < 8 else "g"   # la barra de abajo
    alto = 5.0 + abs(x - 7.5) * 0.8
    if alto - 0.6 <= y <= alto + 1.4:
        return "h"
    if alto + 1.4 < y <= alto + 2.5 or (y == 12 and x in (0, 1, 14, 15)):
        return "m"
    return "."

DIBUJOS["cuchillas"] = disco(sierra)
DIBUJOS["despertador"] = disco(despertador)
DIBUJOS["cuerda"] = disco(cuerda)
DIBUJOS["cinta_americana"] = disco(cinta_americana)
DIBUJOS["cadena"] = disco(cadena)
DIBUJOS["cable"] = disco(cable)
DIBUJOS["jeringuilla"] = disco(jeringuilla)
DIBUJOS["perchas"] = disco(percha)


# Los trajes de Johnny (scripts/trajes.gd): la misma plantilla para los cuatro, un peto con su camisa colgado de
# una percha, y los colores de cada uno: P el peto, p su luz y Q su sombra; C la camisa y c su luz (parecidos a
# los que saca el shader del juego)
PLANTILLA_TRAJE = [
    "................",
    ".......oo.......",
    "......o..o......",
    ".......oo.......",
    "....okkkkkkko...",
    "..ooCCCPPCCCoo..",
    ".oCcCCCPPCCCCCo.",
    ".oCCCCCPPCCCCCo.",
    ".ooCCCPPPPCCCoo.",
    "...oPpPPPPPPo...",
    "...oPpPPPPPPo...",
    "...oPPPPPPPPo...",
    "...oPPPPPPQQo...",
    "...oPPPPPPQQo...",
    "...oooooooooo...",
    "................",
]
TRAJES = {
    "vigilante": {"P": "#1e2a4a", "p": "#2f3f66", "Q": "#121a30", "C": "#7fb4e8", "c": "#a8d0f5"},
    "farmacia": {"P": "#e8ece8", "p": "#ffffff", "Q": "#b8c0bc", "C": "#7fd8a8", "c": "#a8ecc8"},
    "cocinero": {"P": "#9a2a2a", "p": "#c04040", "Q": "#5e1818", "C": "#f4f4ec", "c": "#ffffff"},
    "chandal": {"P": "#8a3ab0", "p": "#b060d8", "Q": "#5a2078", "C": "#f2d44c", "c": "#fff0a0"},
}


def hexa(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def imagen(filas, paleta=PALETA):
    assert len(filas) == 16 and all(len(f) == 16 for f in filas), filas
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for j, fila in enumerate(filas):
        for i, letra in enumerate(fila):
            if letra in paleta:
                img.putpixel((i, j), hexa(paleta[letra]))
    return img


def trajes():
    """Los iconos de los trajes: {nombre: (filas, paleta)}, con la plantilla y los colores de cada uno."""
    return {f"traje_{id}": (PLANTILLA_TRAJE, {**PALETA, **colores}) for id, colores in TRAJES.items()}


def main():
    todos = {nombre: (filas, PALETA) for nombre, filas in DIBUJOS.items()}
    todos.update(trajes())
    for nombre, (filas, paleta) in todos.items():
        imagen(filas, paleta).save(ICONOS / f"obj-{nombre}.png")
    if "muestra" in sys.argv:
        ids = sorted(todos)
        hoja = Image.new("RGBA", (len(ids) * 72, 72), (60, 56, 70, 255))
        for i, nombre in enumerate(ids):
            grande = imagen(*todos[nombre]).resize((64, 64), Image.NEAREST)
            hoja.paste(grande, (i * 72 + 4, 4), grande)
        hoja.save(RAIZ / "tools" / "objetos16.png")
    print(len(todos), "objetos")


if __name__ == "__main__":
    main()
