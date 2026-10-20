# Dibuja los 17 objetos de la mochila a 16×16 píxeles (más detalle que los de 10×10 de src/objetos.js, que
# les sirven de modelo): contorno oscuro, luz arriba a la izquierda y sombra abajo a la derecha.
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


DIBUJOS["cuchillas"] = disco(sierra)
DIBUJOS["despertador"] = disco(despertador)
DIBUJOS["cuerda"] = disco(cuerda)


def hexa(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def imagen(filas):
    assert len(filas) == 16 and all(len(f) == 16 for f in filas), filas
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for j, fila in enumerate(filas):
        for i, letra in enumerate(fila):
            if letra in PALETA:
                img.putpixel((i, j), hexa(PALETA[letra]))
    return img


def main():
    for nombre, filas in DIBUJOS.items():
        imagen(filas).save(ICONOS / f"obj-{nombre}.png")
    if "muestra" in sys.argv:
        ids = sorted(DIBUJOS)
        hoja = Image.new("RGBA", (len(ids) * 72, 72), (60, 56, 70, 255))
        for i, nombre in enumerate(ids):
            hoja.paste(imagen(DIBUJOS[nombre]).resize((64, 64), Image.NEAREST), (i * 72 + 4, 4),
                       imagen(DIBUJOS[nombre]).resize((64, 64), Image.NEAREST))
        hoja.save(RAIZ / "tools" / "objetos16.png")
    print(len(DIBUJOS), "objetos")


if __name__ == "__main__":
    main()
