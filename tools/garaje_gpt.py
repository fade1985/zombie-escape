"""El garaje subterráneo del reto del día (M125, 16 nov), con las imágenes de GPT que trajo el dueño:

- assets/sources/garaje-gpt.webp es TODO el garaje, tal cual (el suelo de resina verdosa con sus plazas, el carril con
  las flechas, la pared de arriba con las tuberías y la banda amarilla y negra, los bordes de los muros y la rampa
  cerrada de la derecha). Mide 1536 × 1024, justo lo que mide el garaje en el juego (48 × 32 casillas de 32 unidades):
  así, un punto de la imagen es el mismo punto del juego, en unidades. Se reduce a la mitad (768 × 512, a 2 unidades
  por píxel) sin recortar nada.
- La columna (garaje-columna-gpt.webp) y los tres coches (garaje-coche-<color>-gpt.webp) son muebles del catálogo
  (catalogo.gd: "garagecolumn", "carsilver", "carblue", "carred"), cada uno con su .json. A la columna le cambia la
  tapa: la franja fina de GPT se quita y se le pone encima su tapa, plana y oscura como lo de arriba de los muros del
  dibujo, del hondo de la columna vista desde arriba (TAPA).

Todo se reduce como los muebles (tools/muebles_gpt.py): el negro puro del borde, fuera; LANCZOS premultiplicado
(mezclando colores) y el borde sin medias tintas. Dónde va cada cosa en el garaje, en planta.gd (GARAJE_*).

La barrera de la rampa (18 nov, lo pidió el dueño): GPT la pintó con el brazo a lo largo de la rampa, que así no cierra
nada. Se borra (girar_barrera: se tapa con lo que hay al lado, siguiendo las rayas del suelo de la rampa) y se pinta
otra con el brazo de arriba abajo, cruzando la boca de la rampa, y su poste naranja abajo.

  py tools/garaje_gpt.py      (y luego Godot --headless --path . --import)
"""
import json
import random
from collections import deque
from PIL import Image

SUELO = ('assets/sources/garaje-gpt.webp', 'assets/sprites/garaje-gpt.png', 768, 512)
# [origen, sprite, ancho, alto]: el ancho, lo que ocupa en el suelo (el "len" del catálogo, a 2 unidades por píxel)
MUEBLES = [
    ('assets/sources/garaje-columna-gpt.webp', 'assets/sprites/mueble-garagecolumn.png', 32, 64),
    ('assets/sources/garaje-coche-plata-gpt.webp', 'assets/sprites/mueble-carsilver.png', 56, 84),
    ('assets/sources/garaje-coche-azul-gpt.webp', 'assets/sprites/mueble-carblue.png', 56, 84),
    ('assets/sources/garaje-coche-rojo-gpt.webp', 'assets/sprites/mueble-carred.png', 52, 78),
]
TAPA = 14                  # lo hondo de la tapa de la columna, en píxeles (la columna mide 32: vista desde arriba, menos de la mitad)
TAPA_CORTE = 0.07          # lo de arriba de la columna de GPT que se quita (su franja fina, oscura)
TAPA_COLOR = (60, 58, 57)  # como lo de arriba de los muros del dibujo del garaje
TAPA_LUZ = (96, 92, 86)    # el filo de arriba, con luz
CONTORNO = (18, 18, 20)    # casi negro, como los contornos de GPT


def sin_fondo(origen):
    """La imagen de GPT sin el negro puro que se llega desde el borde, recortada a lo que queda"""
    im = Image.open(origen).convert('RGBA')
    W, H = im.size
    px = im.load()
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
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
    return im.crop(im.getbbox())


# La barrera de la rampa, en píxeles del dibujo reducido (768 × 512): lo que se borra de la de GPT y la nueva
BORRAR = [(688, 276, 763, 299), (745, 276, 763, 325)]   # [x0, y0, x1, y1): el brazo (y su sombra) y el poste de GPT
RAMPA_X = (697, 750)          # el suelo de la rampa, entre sus dos bordes grises (el de la izquierda y el de la pared)
BRAZO_X = 699                 # dónde empieza el brazo nuevo (11 píxeles de ancho, contorno incluido)
BRAZO_Y = (211, 296)          # de arriba abajo: del borde de arriba de la rampa al poste
POSTE = (697, 290, 711, 327)  # el poste naranja, abajo a la izquierda de la boca de la rampa
AMARILLO = [(236, 184, 22), (224, 167, 0), (248, 206, 52)]   # (el de en medio, el de GPT; el último, la luz)
NEGRO = (34, 31, 27)
CONTORNO_B = (8, 6, 4)
NARANJA = [(176, 78, 2), (214, 116, 18), (128, 54, 3)]       # el de GPT, su luz y su sombra
BISAGRA = [(88, 96, 90), (128, 136, 128), (52, 58, 54)]


def girar_barrera(im):
    """Borra la barrera de GPT y pinta la nueva, en vertical"""
    px = im.load()
    viejo = im.copy().load()
    borrar = {(x, y) for x0, y0, x1, y1 in BORRAR for x in range(x0, x1) for y in range(y0, y1)}
    for x, y in sorted(borrar):
        if x < RAMPA_X[0]:
            de = (x, y - 24)                    # el borde gris de la izquierda: igual de arriba abajo
        elif x >= RAMPA_X[1] - 5 and (x >= RAMPA_X[1] or y > BORRAR[0][3]):
            de = (x, y - 52)                    # el borde gris de la pared, la pared y su sombra
        else:
            # el suelo de la rampa: sus rayas van en diagonal (/), así que se copia de la misma raya, justo por encima de
            # lo borrado (arriba a la derecha) o, si allí ya está la sombra de la pared, justo por debajo (abajo a la
            # izquierda; el suelo llega hasta la y 304)
            k = y - BORRAR[0][1] + 2
            if x + k < RAMPA_X[1] - 4:
                de = (x + k, y - k)
            else:
                k = BORRAR[0][3] - y + 1
                de = (x - k, y + k)
        px[x, y] = viejo[de]
    # la sombra del brazo y del poste, en el suelo de la rampa (la luz viene de arriba a la izquierda)
    for y in range(BRAZO_Y[0] + 3, POSTE[3] + 1):
        for x in (BRAZO_X + 11, BRAZO_X + 12):
            c = px[x, y]
            px[x, y] = tuple(int(v * 0.55) for v in c[:3]) + c[3:]
    # el brazo: contorno, rayas amarillas y negras en diagonal y una luz a la izquierda
    for y in range(BRAZO_Y[0], BRAZO_Y[1]):
        for x in range(BRAZO_X, BRAZO_X + 11):
            if x in (BRAZO_X, BRAZO_X + 10) or y == BRAZO_Y[0]:
                c = CONTORNO_B
            elif ((x + y) // 5) % 2 == 0:
                c = AMARILLO[2] if x == BRAZO_X + 1 else AMARILLO[(x + y) % 2]
            else:
                c = NEGRO
            px[x, y] = c + (255,)
    # el poste: contorno, naranja con luz a la izquierda y sombra a la derecha, y la bisagra arriba
    x0, y0, x1, y1 = POSTE
    for y in range(y0, y1):
        for x in range(x0, x1):
            if x in (x0, x1 - 1) or y in (y0, y1 - 1):
                c = CONTORNO_B
            elif y < y0 + 9 and x0 + 2 <= x < x1 - 2:
                c = BISAGRA[1] if y == y0 + 1 else (BISAGRA[2] if x == x1 - 3 else BISAGRA[0])
            elif y < y0 + 9:
                c = NARANJA[0]
            elif x == x0 + 1:
                c = NARANJA[1]
            elif x >= x1 - 3:
                c = NARANJA[2]
            else:
                c = NARANJA[0]
            px[x, y] = c + (255,)
    return im


def reducir(im, ancho, alto):
    """Como los muebles: mezclando colores (premultiplicado) y el borde sin medias tintas"""
    salida = im.convert('RGBa').resize((ancho, alto), Image.LANCZOS).convert('RGBA')
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    return salida


def con_json(sprite, ancho, alto):
    with open(sprite.replace('.png', '.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump({'cell': [ancho, alto], 'pivot': [ancho // 2, alto], 'scale': 1,
                   'anims': {'idle': {'fps': 1, 'dirs': {'south': {'row': 0, 'frames': 1}}}}}, f, indent=2)
        f.write('\n')


# el suelo entero
origen, sprite, ancho, alto = SUELO
girar_barrera(Image.open(origen).convert('RGB').resize((ancho, alto), Image.LANCZOS)).save(sprite)
print(f'{sprite}: {ancho}x{alto}')

for origen, sprite, ancho, alto in MUEBLES:
    im = sin_fondo(origen)
    if 'columna' in origen:
        # sin la franja de arriba de GPT; la cara, a su tamaño, y encima la tapa
        im = im.crop((0, int(im.height * TAPA_CORTE), im.width, im.height))
        cara = reducir(im, ancho, alto)
        total = Image.new('RGBA', (ancho, alto + TAPA), (0, 0, 0, 0))
        total.paste(cara, (0, TAPA))
        azar = random.Random(7)   # (el mismo granito cada vez)
        for y in range(TAPA):
            for x in range(ancho):
                if x in (0, ancho - 1) or y == 0:
                    color = CONTORNO
                elif y == 1:
                    color = TAPA_LUZ
                else:
                    d = azar.randint(-5, 5)
                    color = tuple(c + d for c in TAPA_COLOR)
                total.putpixel((x, y), color + (255,))
        total.save(sprite)
        con_json(sprite, ancho, alto + TAPA)
        print(f'{sprite}: {ancho}x{alto + TAPA} (con su tapa)')
        continue
    reducir(im, ancho, alto).save(sprite)
    con_json(sprite, ancho, alto)
    print(f'{sprite}: {ancho}x{alto}')
