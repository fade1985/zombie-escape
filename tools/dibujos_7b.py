# Saca los dibujos de la fase 7b (copiados de los dibujos a mano del juego JS):
#   - los 17 objetos de src/objetos.js (10×10 píxeles): ya no se usan, los saca a 16×16 tools/objetos16.py
#   - el baúl y el banco de trabajo de src/props.js también salían de aquí; desde el 23 oct son de PixelLab, al estilo
#     de los muebles: tools/baul_mantenimiento.py y tools/banco_mantenimiento.py
#   - el armarito del baño con su botiquín también salía de aquí; desde el 26 oct es de PixelLab, al estilo de los
#     muebles: tools/botiquin.py
# Ya no saca nada (el último, el armarito, se fue a PixelLab): quedan los colores, hexa() y el Lienzo, que se copió en
# tools/taquilla.py
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
