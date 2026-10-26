"""La tele de las Noticias del ordenador (scripts/ui/tele.gd), al estilo de los demás dibujos.

Hasta el 26 oct estaba dibujada entera con rectángulos desde el código: el mueble, la reportera (un cuadrado de piel
con dos puntos de ojos) y la ciudad de detrás (siete bloques azules). Ahora sale de PixelLab:
  - el mueble, con la receta de los muebles del centro comercial (tools/guias_centro.py): un boceto de la tele de
    antes, de frente, sobre azul, que PixelLab "viste" (create_image_pixflux con init_image). El boceto va a 1 píxel
    por unidad del juego, que es el doble de los píxeles del juego, como siempre; luego se reduce a la mitad. La
    pantalla se deja hueca (con las esquinas redondeadas de una tele vieja): la emisión se pinta debajo;
  - los dos fondos de la calle (delante del número 14 y delante del centro comercial), a los píxeles del juego;
  - la reportera de medio cuerpo, sin fondo, y las posiciones de su boca para que hable (create_vocal_animation).

  py tools/tele.py guia     → assets/sources/tele/guia.png (el boceto del mueble)
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
  py tools/tele.py          → assets/ui/tele/ (el mueble con la pantalla hueca, los fondos, la reportera y sus bocas)
"""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import FONDO, quita

CARPETA = 'assets/sources/tele'
GUIA = f'{CARPETA}/guia.png'
OUT = 'assets/ui/tele'

# Medidas en unidades del juego (= píxeles del boceto); las mismas que tele.gd
ANCHO, ALTO = 400, 256
MUEBLE = (4, 38, 392, 204)          # x, y, ancho, alto
PANTALLA = (22, 56, 288, 164)       # el hueco de la emisión (PANTALLA de tele.gd)
ESQUINA = 10                        # el redondeo de las esquinas de la pantalla

FONDO_PX = (144, 82)                # los fondos de la calle, en píxeles del juego (la pantalla entera)

# Los intentos elegidos (assets/sources/tele/intentos/)
ELEGIDOS = {'mueble': 2, 'reportera': 1, '14': 1, 'centro': 4}

# La boca y los ojos de la reportera elegida, a mano: los píxeles que cambian (en el dibujo de PixelLab, sin recortar)
REPORTERA_X, REPORTERA_Y = 13, 13   # la esquina de lo que no es transparente (el recorte)
LABIO, ROJO_LABIO, DENTRO, PIEL_SOMBRA = (93, 53, 42), (216, 84, 52), (38, 17, 15), (213, 127, 100)
BOCAS = [
    {},                                                                   # cerrada
    {(27, 31): DENTRO, (28, 31): DENTRO, (27, 32): ROJO_LABIO, (28, 32): ROJO_LABIO},   # entreabierta
    {(29, 30): LABIO, (26, 31): ROJO_LABIO, (27, 31): DENTRO, (28, 31): DENTRO, (29, 31): ROJO_LABIO,
     (27, 32): ROJO_LABIO, (28, 32): ROJO_LABIO},                         # abierta (más ancha: más alta parecía barba)
]
OJOS_CERRADOS = {(24, 25): PIEL_SOMBRA, (25, 25): PIEL_SOMBRA, (30, 25): PIEL_SOMBRA, (31, 25): PIEL_SOMBRA}

CONTORNO = (29, 27, 44)
MADERA = (122, 84, 52)
MADERA_LUZ = (146, 104, 68)
MADERA_OSCURA = (86, 58, 36)
MARCO = (42, 42, 46)
CRISTAL = (16, 20, 28)
CREMA = (220, 200, 150)
ANTENA = (140, 140, 150)


def guia():
    os.makedirs(CARPETA, exist_ok=True)
    im = Image.new('RGB', (ANCHO, ALTO), FONDO)
    d = ImageDraw.Draw(im)
    # la antena en V, con sus bolitas, y su base
    for punta in [(150, 4), (282, 8)]:
        d.line([(214, 34), punta], fill=ANTENA, width=3)
        d.ellipse([punta[0] - 3, punta[1] - 3, punta[0] + 3, punta[1] + 3], fill=ANTENA)
    d.rectangle([198, 30, 230, 40], fill=CONTORNO)
    # las patas
    for x in [34, 336]:
        d.rectangle([x, 238, x + 30, 252], fill=CONTORNO)
    # el mueble: madera con la tapa más clara, la base más oscura y el contorno
    x, y, w, h = MUEBLE
    d.rounded_rectangle([x, y, x + w - 1, y + h - 1], radius=8, fill=MADERA, outline=CONTORNO, width=3)
    d.rectangle([x + 3, y + 3, x + w - 4, y + 8], fill=MADERA_LUZ)
    d.rectangle([x + 3, y + h - 14, x + w - 4, y + h - 4], fill=MADERA_OSCURA)
    # el marco de plástico y el cristal de la pantalla, con las esquinas redondeadas
    px, py, pw, ph = PANTALLA
    d.rounded_rectangle([px - 8, py - 8, px + pw + 7, py + ph + 7], radius=ESQUINA + 4, fill=MARCO, outline=CONTORNO,
                        width=2)
    d.rounded_rectangle([px, py, px + pw - 1, py + ph - 1], radius=ESQUINA, fill=CRISTAL)
    d.line([(px + 14, py + 8), (px + 110, py + 8)], fill=(40, 48, 62), width=3)   # el brillo del cristal
    # el panel de la derecha: dos ruedas y el altavoz
    for cy in [92, 140]:
        d.ellipse([357 - 15, cy - 15, 357 + 15, cy + 15], fill=CONTORNO)
        d.ellipse([357 - 12, cy - 12, 357 + 12, cy + 12], fill=CREMA)
        d.line([(357, cy), (357, cy - 10)], fill=CONTORNO, width=2)
    for yy in range(168, 220, 6):
        d.rectangle([334, yy, 380, yy + 2], fill=MADERA_OSCURA)
    im.save(GUIA)
    print('guía:', GUIA, im.size)


def hueco(im):
    """La pantalla del mueble (a 1 píxel por unidad): lo oscuro unido al centro. Devuelve su máscara y su caja"""
    W, H = im.size
    px = im.load()
    oscuro = lambda c: c[3] > 0 and sum(c[:3]) < 120
    pila, dentro = [(W * 2 // 5, H // 2)], set()
    while pila:
        x, y = pila.pop()
        if (x, y) in dentro or not (0 <= x < W and 0 <= y < H) or not oscuro(px[x, y]):
            continue
        dentro.add((x, y))
        pila += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    mascara = Image.new('L', im.size, 0)
    for p in dentro:
        mascara.putpixel(p, 255)
    return mascara, mascara.getbbox()


def mueble(origen, destino):
    """El mueble elegido (ya sin fondo) a 2 unidades por píxel y con la pantalla hueca: un rectángulo de esquinas
    redondeadas del tamaño de los fondos (FONDO_PX), centrado en la pantalla que dibujó PixelLab; lo que sobra de
    esa pantalla alrededor se pinta de cristal oscuro. Dice dónde cae el hueco (PANTALLA de tele.gd, en unidades)"""
    im = Image.open(origen).convert('RGBA')
    mascara, caja = hueco(im)
    W, H = im.size[0] // 2, im.size[1] // 2
    color = im.convert('RGBa').resize((W, H), Image.BOX).convert('RGBA')
    alfa = im.getchannel('A').resize((W, H), Image.BOX)
    pantalla = mascara.resize((W, H), Image.BOX)
    fw, fh = FONDO_PX
    hx = (caja[0] + caja[2]) // 4 - fw // 2
    hy = (caja[1] + caja[3]) // 4 - fh // 2
    agujero = Image.new('L', (W, H), 0)
    ImageDraw.Draw(agujero).rounded_rectangle([hx, hy, hx + fw - 1, hy + fh - 1], radius=ESQUINA // 2, fill=255)
    out = Image.new('RGBA', (W, H))
    for y in range(H):
        for x in range(W):
            if agujero.getpixel((x, y)):
                continue
            if pantalla.getpixel((x, y)) >= 128:
                out.putpixel((x, y), CRISTAL + (255,))
            elif alfa.getpixel((x, y)) > 110:
                out.putpixel((x, y), color.getpixel((x, y))[:3] + (255,))
    out.save(destino)
    print('mueble:', destino, out.size, '· PANTALLA = Rect2(%d, %d, %d, %d)' % (hx * 2, hy * 2, fw * 2, fh * 2))


def reportera(origen, destino):
    """La reportera elegida, recortada, en una tira de 4 dibujos: la boca cerrada (el de PixelLab), entreabierta y
    abierta, y los ojos cerrados (para parpadear). La boca y los ojos, a mano: en una cara de 12 píxeles la boca mide
    2, y PixelLab redibujaría la cara entera en cada uno"""
    im = Image.open(origen).convert('RGBA')
    im = im.crop(im.getbbox())
    w, h = im.size
    tira = Image.new('RGBA', (w * 4, h))
    for i, pinta in enumerate(BOCAS + [OJOS_CERRADOS]):
        d = im.copy()
        for (x, y), c in pinta.items():
            d.putpixel((x - REPORTERA_X, y - REPORTERA_Y), c + (255,))
        tira.paste(d, (i * w, 0))
    tira.save(destino)
    print('reportera:', destino, '· cada dibujo de %d × %d' % (w, h))


def todo():
    os.makedirs(OUT, exist_ok=True)
    original = f'{CARPETA}/intentos/mueble-{ELEGIDOS["mueble"]}.png'
    sin_fondo = f'{CARPETA}/mueble-sin-fondo.png'
    Image.open(original).save(sin_fondo)
    quita(sin_fondo)
    mueble(sin_fondo, f'{OUT}/mueble.png')
    for sitio in ['14', 'centro']:
        Image.open(f'{CARPETA}/intentos/calle-{sitio}-{ELEGIDOS[sitio]}.png').convert('RGB').save(f'{OUT}/calle-{sitio}.png')
    reportera(f'{CARPETA}/intentos/reportera-{ELEGIDOS["reportera"]}.png', f'{OUT}/reportera.png')


if __name__ == '__main__':
    if sys.argv[1:] == ['guia']:
        guia()
    elif sys.argv[1:2] == ['mueble']:   # py tools/tele.py mueble <original sin fondo> <destino>: para probar
        mueble(sys.argv[2], sys.argv[3])
    else:
        todo()
