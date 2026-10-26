"""La salida de incendios del fondo del pasillo (scripts/mapa/puerta.gd y cartel_salida.gd): la puerta roja de las
escaleras y su cartel verde EXIT, dibujados a mano, sin PixelLab.

La puerta está en el muro de la derecha, que se ve desde arriba y plano, así que (como la puerta de dentro cerrada de los
tabiques verticales, tools/puerta_lado_cerrada.py) se ve de canto: una hoja de chapa roja, fina, metida en el hueco del
muro, con su barra antipánico larga de aluminio sobresaliendo hacia el pasillo, como el pomo de aquella. Detrás, las escaleras
(peldaños que bajan hacia el fondo). Un tablón de 5 píxeles de ancho no se puede pedir a PixelLab (sale un color por
columna), así que se dibuja aquí con los colores de lo que ya hay: el contorno oscuro de todo el juego y el aluminio
del ascensor y de la puerta de servicio.

El cartel, de 36 × 13 píxeles, va en la pared de arriba, al final del pasillo: el muñequito corriendo y EXIT en una caja
de chapa. Dos dibujos: apagado (verde oscuro, el que se ve mientras la planta no está pasada) y encendido (verde vivo
con las letras blancas; lo dibuja cartel_salida.gd sin que le afecte la penumbra, y con su luz).

  py tools/puerta_salida.py     → assets/sprites/puerta-salida.png (36 × 36),
                                  cartel-salida-apagado.png y cartel-salida-encendido.png (36 × 13)
"""
import random
from PIL import Image

SPRITES = 'assets/sprites'
LINEA = (29, 27, 44, 255)

# ── La puerta (36 × 36 píxeles del juego: 72 × 72 unidades) ──
# Columnas: 0 a 3, el suelo del pasillo (por donde sobresale la barra, con su sombrita); 4 a 8, la hoja (5 píxeles = 10
# unidades de grosor); 9 a 35, el hueco del muro con las escaleras. Filas: 0 y 35, el borde del marco; 1 y 34, su cara
# de arriba; 2 a 33, el hueco entero (32 píxeles, 64 unidades)
W, H = 36, 36
HOJA_X = 4
ROJO = {'luz': (244, 100, 76, 255), 'medio': (220, 48, 42, 255), 'sombra': (164, 30, 36, 255), 'oscuro': (110, 18, 26, 255),
        'chispa': (255, 140, 112, 255)}
MARCO = (176, 36, 40, 255)     # la cara de arriba del marco: chapa roja, un punto más oscura que la hoja
# el aluminio de la barra (la puerta de servicio y el ascensor, un poco más claro)
ALU = {'luz': (214, 220, 222, 255), 'medio': (150, 158, 162, 255), 'sombra': (96, 104, 110, 255)}
HIERRO = (74, 80, 86, 255)     # los soportes de la barra y la caja del cierre


def puerta():
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = im.putpixel
    rng = random.Random(11)
    # el marco: arriba y abajo del hueco, de chapa roja con su contorno por fuera
    for x in range(HOJA_X, W):
        px((x, 0), LINEA)
        px((x, 1), MARCO)
        px((x, 34), MARCO)
        px((x, 35), LINEA)
    # las escaleras, detrás de la hoja: seis peldaños de 4 píxeles que bajan hacia el fondo (más oscuros cuanto más
    # abajo), cada uno con su borde claro delante y su sombra detrás
    for k in range(6):
        x0 = HOJA_X + 5 + k * 4
        base = 100 - k * 9
        for y in range(2, 34):
            for dx in range(4):
                x = x0 + dx
                if x >= W - 1:
                    continue
                c = base + (16 if dx == 0 else -10 if dx == 3 else 0)
                px((x, y), (c, c, c + 6, 255))
    for y in range(2, 34):   # el fondo del hueco: un borde oscuro (el muro de al lado)
        px((W - 1, y), LINEA)
    # la sombra que echa la hoja sobre los peldaños
    for y in range(2, 34):
        px((HOJA_X + 5, y), (36, 34, 44, 255))
        px((HOJA_X + 6, y), (62, 60, 68, 255))
    # la hoja: contorno, la luz del pasillo en la cara de fuera, el tono medio, la sombra de dentro y el contorno
    for y in range(2, 34):
        px((HOJA_X, y), LINEA)
        px((HOJA_X + 1, y), ROJO['luz'])
        px((HOJA_X + 2, y), ROJO['medio'])
        px((HOJA_X + 3, y), ROJO['sombra'])
        px((HOJA_X + 4, y), LINEA)
    for x in range(HOJA_X, HOJA_X + 5):   # los dos cantos
        px((x, 1), LINEA)
        px((x, 34), LINEA)
    # chapa gastada: algún rayón oscuro y alguna chispa clara en la cara de fuera
    for _ in range(7):
        px((HOJA_X + rng.randint(1, 3), rng.randint(3, 32)), ROJO['oscuro'])
    for _ in range(4):
        px((HOJA_X + 1, rng.randint(3, 32)), ROJO['chispa'])
    # la barra antipánico: larga (casi todo el ancho de la hoja), de aluminio, sobresaliendo 3 píxeles hacia el pasillo
    # (columnas 1 a 3: contorno, luz, tono medio), con un soporte en cada punta y la caja del cierre abajo
    y0, y1 = 7, 30
    for y in range(y0, y1 + 1):
        px((1, y), LINEA)
        px((2, y), ALU['luz'])
        px((3, y), ALU['medio'])
    for x in (1, 2, 3):   # las puntas de la barra
        px((x, y0 - 1), LINEA)
        px((x, y1 + 1), LINEA)
    for y in (y0 + 1, y0 + 2):   # el soporte de arriba (de la bisagra)
        for x in (1, 2, 3):
            px((x, y), HIERRO)
    for y in range(y1 - 3, y1 + 1):   # la caja del cierre, abajo, un poco más grande
        for x in (1, 2, 3):
            px((x, y), HIERRO)
    px((2, y1 - 2), ALU['medio'])   # su brillo
    # la sombrita de la barra en el suelo, fina y transparente
    for y in range(y0 + 1, y1 + 2):
        px((0, y), (0, 0, 0, 70))
    return im


# ── El cartel (36 × 13 píxeles: 72 × 26 unidades) ──
CW, CH = 36, 13
LETRAS = {   # 5 × 7, "X" = píxel (E y T, como las de puerta.gd; la I, con sus rayitas)
    'E': ['XXXXX', 'X....', 'X....', 'XXXX.', 'X....', 'X....', 'XXXXX'],
    'X': ['X...X', 'X...X', '.X.X.', '..X..', '.X.X.', 'X...X', 'X...X'],
    'I': ['XXX', '.X.', '.X.', '.X.', '.X.', '.X.', 'XXX'],
    'T': ['XXXXX', '..X..', '..X..', '..X..', '..X..', '..X..', '..X..'],
}
MUNECO = [   # el que corre (8 × 7): cabeza, un brazo adelante y otro atrás, y las piernas en zancada
    '...XX...',
    '...XX...',
    '..XXXXX.',
    '.X.XX..X',
    'X..XXX..',
    '..XX.X..',
    '.XX..XX.',
]
CAJA = {'luz': (118, 126, 130, 255), 'medio': (74, 80, 86, 255), 'sombra': (46, 50, 56, 255)}
PANEL = {'apagado': (20, 58, 30, 255), 'encendido': (44, 200, 56, 255)}
PANEL_LUZ = {'apagado': (26, 70, 38, 255), 'encendido': (96, 226, 100, 255)}   # la fila de arriba del panel
TINTA = {'apagado': (46, 98, 60, 255), 'encendido': (244, 255, 244, 255)}


def cartel(estado):
    im = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    px = im.putpixel
    # la caja de chapa: contorno, y dentro el borde de metal (con su luz arriba y su sombra abajo)
    for x in range(1, CW - 1):
        px((x, 0), LINEA)
        px((x, CH - 1), LINEA)
    for y in range(1, CH - 1):
        px((0, y), LINEA)
        px((CW - 1, y), LINEA)
    for x in range(1, CW - 1):
        px((x, 1), CAJA['luz'])
        px((x, CH - 2), CAJA['sombra'])
    for y in range(2, CH - 2):
        px((1, y), CAJA['medio'])
        px((CW - 2, y), CAJA['sombra'])
    # el panel verde, con su fila de luz arriba
    for y in range(2, CH - 2):
        for x in range(2, CW - 2):
            px((x, y), PANEL_LUZ[estado] if y == 2 else PANEL[estado])
    # el muñequito y las letras
    def poner(filas, x0, y0):
        for f, fila in enumerate(filas):
            for c, ch in enumerate(fila):
                if ch == 'X':
                    px((x0 + c, y0 + f), TINTA[estado])
    poner(MUNECO, 3, 3)
    x = 12
    for letra in 'EXIT':
        poner(LETRAS[letra], x, 3)
        x += len(LETRAS[letra][0]) + 1
    return im


if __name__ == '__main__':
    p = puerta()
    p.save(f'{SPRITES}/puerta-salida.png')
    print(f'puerta-salida: {p.width}x{p.height}')
    for estado in ('apagado', 'encendido'):
        c = cartel(estado)
        c.save(f'{SPRITES}/cartel-salida-{estado}.png')
        print(f'cartel-salida-{estado}: {c.width}x{c.height}')
