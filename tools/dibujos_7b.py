# Saca los dibujos de la fase 7b (copiados de los dibujos a mano del juego JS):
#   - los 17 objetos de src/objetos.js (10×10 píxeles) → assets/ui/iconos/obj-<id>.png
#   - el baúl y el banco de trabajo de src/props.js → assets/sprites/baul.png y banco-trabajo.png
#   - el armarito del baño con su botiquín (cerrado y abierto) → assets/sprites/armarito.png (2 fotogramas)
# Se lanza con:  py tools/dibujos_7b.py   (y luego importar en Godot)
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
SPRITES = RAIZ / "assets" / "sprites"

# Colores de los objetos (el punto es hueco), como PALETA en objetos.js
PALETA = {
    "o": "#2a1f2e", "k": "#1a1a1a", "g": "#9aa0a8", "G": "#d0d4da", "d": "#5d6470", "r": "#d0453a", "R": "#8a2a2a",
    "y": "#f2c94c", "Y": "#b88a1e", "b": "#4a7bd0", "w": "#f1f1e6", "m": "#8a5a34", "M": "#5c3a20", "v": "#5aa05a",
    "n": "#ff9f1c", "p": "#e07be0",
}

OBJETOS = {
    "clavos": ['..........', '.oo..oo...', '.Go..Go...', '..g...g...', '..g...g.oo',
               '..g...g.Go', '..g...g..g', '..d...d..g', '.........g', '.........d'],
    "gasolina": ['...oooo...', '...odoo...', '.oooooooo.', '.orrrrrro.', '.orRRRRro.',
                 '.orRwwRro.', '.orRwwRro.', '.orRRRRro.', '.orrrrrro.', '.oooooooo.'],
    "cuchillas": ['...o.o....', '..oGGGo...', '.oGgggGo..', 'oGgg.ggGo.', '.Ggo.ogG..',
                  'oGgg.ggGo.', '.oGgggGo..', '..oGGGo...', '...o.o....', '..........'],
    "pistola_agua": ['..........', '.ooooooo..', 'onnnnnnnoo', 'onvvvvvnbo', 'onnnnnnnoo',
                     '.oonno....', '...onno...', '...onno...', '...oooo...', '..........'],
    "spray": ['...oo.....', '..oko.....', '.oooooo...', '.oGGGGo...', '.oppppo...',
              '.oppppo...', '.owwwwo...', '.oppppo...', '.oppppo...', '.oooooo...'],
    "mechero": ['....n.....', '...nyn....', '....o.....', '..oooo....', '..oGGo....',
                '..obbo....', '..obbo....', '..obbo....', '..obbo....', '..oooo....'],
    "lejia": ['...oooo...', '...obbo...', '..oowwoo..', '.owwwwwwo.', '.owbbbbwo.',
              '.owbwwbwo.', '.owbbbbwo.', '.owwwwwwo.', '.owwwwwwo.', '.oooooooo.'],
    "alcohol": ['....oo....', '....oo....', '...ovvo...', '...ovvo...', '..ovvvvo..',
                '..ovGvvo..', '..owwwwo..', '..owRRwo..', '..ovvvvo..', '..oooooo..'],
    "trapo": ['..........', '..........', '.oooooo...', '.owwwwwoo.', '.owGwwwwo.',
              '.owwwGwwo.', 'oowwwwwwo.', 'owwwGwwoo.', 'oooooooo..', '..........'],
    "explosivos": ['.......n..', '......y...', '.....o....', '.oooooooo.', '.orrkrrko.',
                   '.orrkrrko.', '.oRRkRRko.', '.oooooooo.', '..........', '..........'],
    "despertador": ['.o......o.', 'oyo.oo.oyo', '.oowwwwoo.', '.owwkwwwo.', 'owwwkwwwwo',
                    'owwwkkkwwo', 'owwwwwwwwo', '.owwwwwwo.', '..oooooo..', '.o......o.'],
    "extintor": ['...ooo....', '..okkoo...', '..oo.ko...', '.orrro.o..', '.orRro....',
                 '.orwro....', '.orrro....', '.orRro....', '.orrro....', '.ooooo....'],
    "taser": ['..y..y....', '..o..o....', '.oooooo...', '.okkkkko..', '.okyykko..',
              '.okkkkko..', '..okko....', '..okko....', '..okko....', '..oooo....'],
    "llave_inglesa": ['.oo..oo...', '.oGooGo...', '.oGGGGo...', '..oGGo....', '...oGo....',
                      '...ogo....', '...ogo....', '...ogo....', '...odo....', '...ooo....'],
    "hacha": ['..ooooo...', '.oGGGGGo..', 'oGGgggmo..', 'oGggggmo..', '.oGggomo..',
              '..ooo.mo..', '.....omo..', '.....omo..', '.....oMo..', '.....ooo..'],
    "cuerda": ['..........', '..oooooo..', '.oyYyYyYo.', 'oyYoooYyYo', 'oYyo..oYyo',
               'oyYo..oyYo', 'oYyYoooYyo', '.oyYyYyYo.', '..oooooo..', '..........'],
    "mancuernas": ['..........', '.oo....oo.', 'okko..okko', 'okkooookko', 'okkGGGGkko',
                   'okkooookko', 'okko..okko', '.oo....oo.', '..........', '..........'],
}


def hexa(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def objetos():
    for id_, filas in OBJETOS.items():
        img = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
        for j, fila in enumerate(filas):
            for i, letra in enumerate(fila):
                if letra in PALETA:
                    img.putpixel((i, j), hexa(PALETA[letra]))
        img.save(ICONOS / f"obj-{id_}.png")


# Un lienzo donde se pintan rectángulos de píxeles, como el px() de props.js
class Lienzo:
    def __init__(self, ancho, alto):
        self.img = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))

    def px(self, x, y, w, h, color):
        c = hexa(color)
        for i in range(x, x + w):
            for j in range(y, y + h):
                if 0 <= i < self.img.width and 0 <= j < self.img.height:
                    self.img.putpixel((i, j), c)


def baul():
    g = Lienzo(30, 24)
    borde, oscura, madera, clara = "#24150d", "#5a3820", "#8a5a32", "#b07a44"
    hierro, brillo, oro, oro_oscuro = "#5e6670", "#a3acb6", "#e3b341", "#9c7322"
    g.px(1, 0, 28, 1, borde); g.px(0, 1, 30, 23, borde)
    g.px(1, 1, 28, 9, madera); g.px(2, 1, 26, 2, clara)
    g.px(1, 8, 28, 1, oscura); g.px(1, 9, 28, 1, hierro)
    g.px(1, 10, 28, 1, borde)
    g.px(1, 11, 28, 12, madera)
    g.px(1, 15, 28, 1, oscura); g.px(1, 19, 28, 1, oscura)
    g.px(1, 21, 28, 2, oscura)
    for bx in (4, 23):
        g.px(bx, 1, 3, 22, hierro); g.px(bx, 1, 1, 22, brillo)
    g.px(12, 7, 6, 8, borde); g.px(13, 8, 4, 6, oro); g.px(13, 13, 4, 1, oro_oscuro)
    g.px(14, 10, 2, 2, borde)
    g.img.save(SPRITES / "baul.png")


def banco():
    g = Lienzo(38, 32)
    borde, oscura, madera, clara = "#24150d", "#5a3820", "#8a5a32", "#b07a44"
    hierro, brillo, rojo, corcho, punto = "#5e6670", "#a3acb6", "#b8433a", "#6b5a44", "#4a3d2e"
    g.px(3, 0, 32, 13, borde); g.px(4, 1, 30, 11, corcho)
    for i in range(6, 33, 4):
        for j in range(3, 11, 4):
            g.px(i, j, 1, 1, punto)
    g.px(7, 2, 1, 8, borde); g.px(6, 2, 3, 2, hierro); g.px(7, 4, 1, 6, hierro)
    g.px(7, 7, 1, 3, rojo)
    g.px(13, 2, 5, 2, hierro); g.px(13, 2, 5, 1, brillo); g.px(15, 4, 1, 7, oscura)
    g.px(21, 2, 2, 9, hierro); g.px(21, 2, 1, 9, brillo); g.px(20, 2, 4, 2, hierro)
    g.px(27, 3, 4, 4, rojo); g.px(28, 4, 2, 2, corcho); g.px(28, 7, 2, 4, oscura)
    g.px(0, 13, 38, 6, borde); g.px(1, 14, 36, 4, madera); g.px(1, 14, 36, 1, clara); g.px(1, 17, 36, 1, oscura)
    g.px(3, 10, 8, 4, borde); g.px(4, 11, 6, 3, hierro); g.px(4, 11, 6, 1, brillo); g.px(10, 12, 3, 1, hierro)
    g.px(1, 19, 4, 13, borde); g.px(2, 19, 2, 12, oscura)
    g.px(33, 19, 4, 13, borde); g.px(34, 19, 2, 12, oscura)
    g.px(5, 25, 28, 3, borde); g.px(5, 26, 28, 1, madera)
    g.px(14, 19, 12, 5, borde); g.px(15, 19, 10, 4, madera); g.px(19, 21, 2, 1, hierro)
    g.img.save(SPRITES / "banco-trabajo.png")


# El armarito del baño (Armarito en props.js, que se dibujaba con rectángulos de 36×40): aquí a 2 unidades por
# píxel, 26×22 con hueco para las puertas abiertas. Fotograma 0 cerrado (con la cruz roja), 1 abierto y vacío
def armarito():
    hoja = Image.new("RGBA", (52, 22), (0, 0, 0, 0))
    linea, caja, balda, tornillo = "#1d1a24", "#e9edf1", "#c9d1da", "#5c6470"
    for f in range(2):
        g = Lienzo(26, 22)
        l = 4   # la caja va de 4 a 22 (18 de ancho)
        g.px(l + 2, 3, 18, 18, "#0b0812")        # sombra en la pared
        g.px(l, 0, 18, 20, linea); g.px(l + 1, 1, 16, 18, caja)
        g.px(l - 1, 17, 20, 4, linea); g.px(l, 18, 18, 2, balda)   # la balda de abajo, más ancha
        if f == 0:
            g.px(l + 8, 1, 1, 16, linea)                # la raja entre las dos puertas
            g.px(l + 5, 5, 8, 3, "#e63946"); g.px(l + 7, 3, 4, 7, "#e63946")   # la cruz roja
            g.px(l + 6, 12, 1, 2, "#8d99ae"); g.px(l + 11, 12, 1, 2, "#8d99ae")   # tiradores
        else:
            g.px(l + 1, 1, 16, 16, "#4a5568")           # el hueco oscuro
            g.px(l + 1, 8, 16, 1, balda)                # una balda
            g.px(0, 0, 4, 18, linea); g.px(1, 1, 2, 16, caja)       # las puertas abiertas, a los lados
            g.px(22, 0, 4, 18, linea); g.px(23, 1, 2, 16, caja)
        g.px(l + 2, 1, 1, 1, tornillo); g.px(l + 15, 1, 1, 1, tornillo)
        hoja.paste(g.img, (f * 26, 0))
    hoja.save(SPRITES / "armarito.png")


if __name__ == "__main__":
    objetos()
    baul()
    banco()
    armarito()
    print("Hecho: 17 objetos, baúl, banco y armarito")
