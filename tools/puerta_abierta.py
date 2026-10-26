"""La puerta de dentro abierta del todo, de frente (scripts/mapa/puerta_bano.gd): nuestra puerta de madera
(assets/sprites/puerta-bano.png) girada hacia quien mira hasta quedarse casi de canto.

Hasta el 26 oct, abierta era la misma puerta cerrada torcida por código (una cuña con rayas) y, al lado, un rectángulo
naranja liso de canto. Ahora es un dibujo suyo, hecho como las cerradas (tools/guias_puertas.py): un boceto con la forma
bien calculada, sobre azul, que PixelLab "viste" (create_image_pixflux con init_image, fuerza 45).

La forma, en la perspectiva del juego (el suelo se ve sin encoger y lo que tiene altura sube): la hoja gira sobre sus
bisagras, a la izquierda, hacia la habitación de abajo. Su borde de arriba y el de abajo bajan al alejarse de la
bisagra: es un paralelogramo de lados verticales. De 28 píxeles de ancho pasa a COLUMNAS, y cada columna baja CAIDA
píxeles (2 a 1: la pendiente limpia del pixel art, unos 63 grados de giro). Al final, el canto de la hoja, con su grosor,
que da hacia quien mira.

Con "lado", la de los tabiques verticales (entre dos habitaciones una al lado de la otra). Hasta el 26 oct, abierta era la
hoja vista desde arriba, como en un plano: una tabla marrón plana con un cuadradito dorado, que no casaba con nada. Ahora
la hoja se queda de pie en la habitación de la derecha, casi pegada a la pared, con la bisagra arriba: la misma forma que
la de frente pero al revés, porque se aleja de quien mira y sus columnas SUBEN (CAIDA, hacia arriba). Lo que se ve es su
cara y, a la izquierda, el canto de la bisagra (el libre queda detrás).

  py tools/puerta_abierta.py guia [lado]    → assets/sources/puertas/guias/bano-abierta[-lado].png (el boceto, sobre azul)
  py tools/guias_centro.py quita <png>…     quita el fondo azul de lo que devuelve PixelLab
  py tools/puerta_abierta.py base [lado]    → assets/sources/puertas/bano-abierta[-lado]-base.png (la forma sola)
  py tools/puerta_abierta.py sprite <png> [lado]
                                            → assets/sprites/puerta-bano-abierta[-lado].png (de un intento ya sin fondo,
                                              a la mitad, con la sombra del suelo); sin <png>, de la base
"""
import colorsys, os, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from guias_centro import S, M, FONDO

SPRITES = 'assets/sprites'
SRC = 'assets/sources/puertas'
OUT = f'{SRC}/guias'
OUTLINE = (29, 27, 44, 255)
CANTO_CLARO = (176, 122, 78, 255)    # el canto de fuera, que da a la luz (el de la hoja de antes)
CANTO_SOMBRA = (140, 94, 60, 255)
ANCHO, ALTO = 28, 43                 # la hoja cerrada, en píxeles del juego
COLUMNAS = 12                        # lo que se ve de su cara al abrirse
CAIDA = 2                            # lo que baja cada columna
CANTO = 2                            # el grueso de la hoja
OSCURECE = 0.86                      # la cara, a la sombra, se ve más oscura que de frente
ANCHO_FINAL = COLUMNAS + CANTO
ALTO_FINAL = ALTO + CAIDA * COLUMNAS


def hoja_abierta(lado=False):
    """La base: nuestra puerta, estrechada y torcida, con su canto y su contorno (píxeles del juego, sin fondo). De lado,
    sus columnas suben a la derecha y el canto con grosor es el de la bisagra, a la izquierda"""
    src = Image.open(f'{SPRITES}/puerta-bano.png').convert('RGBA')
    out = Image.new('RGBA', (ANCHO_FINAL, ALTO_FINAL), (0, 0, 0, 0))
    # la cara: cada columna de ahora, de las de antes que le tocan (la primera y la última tal cual: son el contorno)
    for i in range(COLUMNAS):
        if i == 0:
            a, b = 0, 1
        elif i == COLUMNAS - 1:
            a, b = ANCHO - 1, ANCHO
        else:
            a = 1 + (i - 1) * (ANCHO - 2) // (COLUMNAS - 2)
            b = max(a + 1, 1 + i * (ANCHO - 2) // (COLUMNAS - 2))
        for y in range(ALTO):
            visibles = [src.getpixel((x, y)) for x in range(a, b) if src.getpixel((x, y))[3] > 0]
            if not visibles:
                continue
            r, g, bl = (sum(p[k] for p in visibles) // len(visibles) for k in range(3))
            if (r, g, bl) != OUTLINE[:3]:
                r, g, bl = (int(c * OSCURECE) for c in (r, g, bl))
            if lado:
                out.putpixel((CANTO + i, y + CAIDA * (COLUMNAS - 1 - i)), (r, g, bl, 255))
            else:
                out.putpixel((i, y + CAIDA * i), (r, g, bl, 255))
    # el canto, con su grosor, un poco más abajo que la columna de al lado: de frente, la punta de la hoja; de lado, la
    # bisagra (con sus dos bisagras de metal)
    y0 = CAIDA * COLUMNAS - 1
    for k in range(CANTO):
        for y in range(1, ALTO - 1):
            if lado:
                out.putpixel((k, y0 + y), CANTO_SOMBRA if k == 0 else CANTO_CLARO)
            else:
                out.putpixel((COLUMNAS + k, y0 + y), CANTO_CLARO if k == 0 else CANTO_SOMBRA)
    if lado:
        for y in (7, ALTO - 9):
            for dy in range(3):
                out.putpixel((0, y0 + y + dy), (88, 92, 100, 255))
    # el contorno: cada hueco pegado al dibujo (también por abajo: la hoja se ve sobre el suelo)
    borde = [(x, y) for y in range(ALTO_FINAL) for x in range(ANCHO_FINAL) if out.getpixel((x, y))[3] == 0 and any(
        0 <= x + dx < ANCHO_FINAL and 0 <= y + dy < ALTO_FINAL and out.getpixel((x + dx, y + dy))[3] == 255
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for p in borde:
        out.putpixel(p, OUTLINE)
    return out


def guia(lado=False):
    """El boceto para PixelLab: la base al doble (cada píxel del juego, 2×2), con un margen, sobre azul"""
    base = hoja_abierta(lado)
    im = Image.new('RGBA', (ANCHO_FINAL * S + 2 * M, ALTO_FINAL * S + 2 * M), FONDO + (255,))
    im.alpha_composite(base.resize((ANCHO_FINAL * S, ALTO_FINAL * S), Image.NEAREST), (M, M))
    os.makedirs(OUT, exist_ok=True)
    ruta = f'{OUT}/bano-abierta{"-lado" if lado else ""}.png'
    im.save(ruta)
    print(ruta, im.size)


def a_nuestra_madera(im):
    """PixelLab pinta la hoja granate (nuestra puerta es de un marrón anaranjado) y con azul en el borde de arriba y en el
    contorno. La madera, a nuestro matiz y saturación (los de puerta-bano.png), un poco más clara; el contorno, al de
    siempre; el canto, el latón del pomo y los colores vivos, tal cual"""
    hue = 24 / 360
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = im.getpixel((x, y))
            if a == 0:
                continue
            if max(r, g, b) < 50 and b > r:
                im.putpixel((x, y), OUTLINE)       # el contorno azulado
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if r >= 140 or (0.09 < h < 0.18 and s > 0.5):
                continue                           # el canto, el latón y las manchas vivas
            if b > r:
                s = 0.4                            # el borde de arriba, azulado: madera en sombra
            else:
                s = min(0.52, max(0.42, s * 1.2))  # como la de la cerrada (su saturación ronda 0,5)
            r, g, b = colorsys.hsv_to_rgb(hue, s, min(1.0, v * 1.12))
            im.putpixel((x, y), (round(r * 255), round(g * 255), round(b * 255), 255))
    return im


def pomo_a_la_punta(im):
    """De lado, PixelLab dibujó el pomo junto al canto de la bisagra (el intento 303: en x 3 a 5, y 37 a 40) y va en el
    canto libre, a la derecha. Se borra de ahí (con la madera de al lado) y se pinta el de nuestra puerta (sus tres
    píxeles de latón, de puerta-bano.png) a media altura de la última columna de la cara"""
    madera = im.getpixel((6, 36))
    for y in range(37, 41):
        for x in range(3, 6):
            im.putpixel((x, y), madera)
    arriba = min(y for y in range(im.height) if im.getpixel((11, y))[3] == 255)
    pomo = Image.open(f'{SPRITES}/puerta-bano.png').convert('RGBA')
    for dx, dy in ((0, 0), (0, 1), (1, 1)):
        im.putpixel((11 + dx, arriba + 22 + dy), pomo.getpixel((23 + dx, 21 + dy)))
    return im


def sombra(im):
    """La sombra que echa la hoja en el suelo: una tira oscura y transparente por debajo del borde de abajo"""
    w, h = im.size
    out = Image.new('RGBA', (w, h + 3), (0, 0, 0, 0))
    out.alpha_composite(im, (0, 0))
    for x in range(w):
        # el último píxel con dibujo de la columna
        ys = [y for y in range(h) if im.getpixel((x, y))[3] == 255]
        if not ys:
            continue
        for k in (1, 2):
            if out.getpixel((x, max(ys) + k))[3] == 0:
                out.putpixel((x, max(ys) + k), (0, 0, 0, 90 if k == 1 else 50))
    return out


def sprite(ruta=None, lado=False):
    """De un intento de PixelLab ya sin fondo (o de la base): recortado y a la mitad, como las puertas cerradas"""
    if ruta is None:
        im = hoja_abierta(lado)
    else:
        im = Image.open(ruta).convert('RGBA')
        im = im.crop(im.getbbox())
        # PixelLab lo dibuja al doble: a la mitad exacta (sin estirar: su esquina de arriba a la izquierda es la de la
        # bisagra), con el color medio de cada píxel nuevo
        w, h = round(im.width / S), round(im.height / S)
        color = im.convert('RGBa').resize((w, h), Image.BOX).convert('RGBA')
        lleno = im.getchannel('A').resize((w, h), Image.BOX)
        im = Image.new('RGBA', (w, h))
        for y in range(h):
            for x in range(w):
                if lleno.getpixel((x, y)) > 110:
                    r, g, b, _ = color.getpixel((x, y))
                    im.putpixel((x, y), (r, g, b, 255))
        im = a_nuestra_madera(im)
        if lado:
            im = pomo_a_la_punta(im)
    im = sombra(im)
    nombre = f'puerta-bano-abierta{"-lado" if lado else ""}'
    im.save(f'{SPRITES}/{nombre}.png')
    print(f'{nombre}: {im.width}x{im.height} (con la sombra de abajo)')


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if a != 'lado']
    lado = 'lado' in sys.argv[1:]
    orden = args[0] if args else 'guia'
    if orden == 'guia':
        guia(lado)
    elif orden == 'base':
        os.makedirs(SRC, exist_ok=True)
        ruta = f'{SRC}/bano-abierta{"-lado" if lado else ""}-base.png'
        hoja_abierta(lado).save(ruta)
        print(ruta)
    elif orden == 'sprite':
        sprite(args[1] if len(args) > 1 else None, lado)
