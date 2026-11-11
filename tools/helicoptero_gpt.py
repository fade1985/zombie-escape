"""El helicóptero de Velaria con la imagen de GPT (11 nov, bloque M): assets/sources/helicoptero-gpt.webp, un
helicóptero ejecutivo azul marino casi negro con líneas color crema y la luna morada de Velaria en la puerta.

En el juego (scripts/helicoptero.gd) el rotor grande y el de la cola los pinta el código, girando, así que aquí se le
quitan al dibujo: las palas del rotor grande (todo lo que queda por encima del techo, menos el buje) y la hélice de
la cola (sus palas grises y sus puntas amarillas; donde pasaban por encima de la cola, se pinta la cola). Luego se
le da la vuelta (llega volando por la derecha, con el morro a la izquierda), se quita el fondo negro y se reduce como
los muebles (LANCZOS premultiplicado, tools/muebles_gpt.py) a ANCHO píxeles de largo, a 2 unidades por píxel.

  py tools/helicoptero_gpt.py   → assets/sprites/helicoptero.png (y luego importar en Godot); dice dónde caen el
                                  centro de la cabina, el buje, el rotor de la cola y la luz de la aleta, y lo largo
                                  de cada pala, que van en helicoptero.gd (ORIGEN, BUJE, COLA, LUZ_ROJA y ROTOR)
"""
from collections import deque
from PIL import Image

ORIGEN_GPT = 'assets/sources/helicoptero-gpt.webp'
SPRITE = 'assets/sprites/helicoptero.png'
ANCHO = 156                          # de largo, como el de antes (de PixelLab, 155)
# Sitios de la imagen de GPT (1536 × 1024, con el morro a la derecha)
TECHO = 345                          # por encima, el rotor grande (sus palas), menos el buje y la aleta de la cola
BUJE_X = (870, 950)                  # lo que se deja del buje y el mástil
ALETA_X = 245                        # a la izquierda, la aleta de la cola, que sube más: ahí las palas, solo por encima de
ALETA_ARRIBA = 292
HELICE = (0, 480, 178, 680)          # la hélice de la cola (x0, y0, x1, y1)
COLA_Y = (484, 556)                  # la cola (el tubo), donde la tapaba la hélice
COLA_COLOR = (24, 28, 58)
SITIOS = {                           # en la imagen de GPT; los da en píxeles del dibujo
    'ORIGEN': (1040, 570),           # el centro de la cabina
    'BUJE': (910, 275),              # la punta del mástil, donde gira el rotor grande
    'COLA': (115, 560),              # el centro de la hélice de la cola
    'LUZ_ROJA': (64, 300),           # en lo alto de la aleta
}
PALAS = (230, 1520)                  # de punta a punta del rotor grande de la imagen

im = Image.open(ORIGEN_GPT).convert('RGB')
W, H = im.size
px = im.load()
quitar = bytearray(W * H)            # lo que se vuelve transparente


def de_la_helice(c):
    # lo que no es azul marino (las palas grises, sus puntas amarillas y su contorno oscuro): la cola es azul
    r, g, b = c
    return b - r < 12


for y in range(H):
    for x in range(W):
        if (y < TECHO and x >= ALETA_X and not BUJE_X[0] <= x <= BUJE_X[1]) or (y < ALETA_ARRIBA and x < ALETA_X):
            quitar[y * W + x] = 1
        elif HELICE[0] <= x < HELICE[2] and HELICE[1] <= y < HELICE[3] and de_la_helice(px[x, y]):
            if COLA_Y[0] <= y <= COLA_Y[1] and x > 60:
                px[x, y] = COLA_COLOR
            else:
                quitar[y * W + x] = 1
# el fondo: el negro puro que se llega desde el borde (y lo que se ha quitado). Puro: las ruedas y la panza son casi
# negras (de 13 a 28) y con más margen se las comía
cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
while cola:
    x, y = cola.popleft()
    if x < 0 or y < 0 or x >= W or y >= H or quitar[y * W + x] == 2:
        continue
    if not quitar[y * W + x] and max(px[x, y]) >= 6:
        continue
    quitar[y * W + x] = 2
    cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
rgba = im.convert('RGBA')
pa = rgba.load()
for y in range(H):
    for x in range(W):
        if quitar[y * W + x]:
            pa[x, y] = (0, 0, 0, 0)
rgba = rgba.transpose(Image.FLIP_LEFT_RIGHT)
caja = rgba.getbbox()
rgba = rgba.crop(caja)
escala = ANCHO / rgba.width
alto = round(rgba.height * escala)
salida = rgba.convert('RGBa').resize((ANCHO, alto), Image.LANCZOS).convert('RGBA')
salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
# y los puntitos sueltos que quedan de la hélice (trozos de menos de MOTA píxeles, separados del helicóptero)
MOTA = 8
ps = salida.load()
visto = set()
for y0 in range(alto):
    for x0 in range(ANCHO):
        if ps[x0, y0][3] == 0 or (x0, y0) in visto:
            continue
        trozo, pila = [], [(x0, y0)]
        visto.add((x0, y0))
        while pila:
            x, y = pila.pop()
            trozo.append((x, y))
            for v in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= v[0] < ANCHO and 0 <= v[1] < alto and v not in visto and ps[v][3]:
                    visto.add(v)
                    pila.append(v)
        if len(trozo) < MOTA:
            for xy in trozo:
                ps[xy] = (0, 0, 0, 0)
salida.save(SPRITE)
print(f'{SPRITE}: {ANCHO}x{alto}')
ex = ANCHO / (caja[2] - caja[0])
ey = alto / (caja[3] - caja[1])
for nombre, (x, y) in SITIOS.items():
    print(f'  {nombre} := Vector2({((W - 1 - x) - caja[0]) * ex:.1f}, {(y - caja[1]) * ey:.1f})')
print(f'  ROTOR := {(PALAS[1] - PALAS[0]) / 2 * ex * 2:.0f} unidades')
