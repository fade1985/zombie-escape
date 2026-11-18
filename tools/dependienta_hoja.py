"""Monta la hoja de la dependienta nueva (18 nov): el dibujo de 112 px de PixelLab, mucho más detallado que los
zombis de 48. Sustituye a la hoja vieja de tools/zombi.py.

Lo saca de assets/sources/dependienta-96-gpt/animaciones/ (ya elegido y limpio por el dueño):
  rotaciones/<dirección>.png        las 8 poses de pie (112×112, los pies en la fila 110)
  andar/, zarpazo/, golpe/, muerte/ cada una en south, south-east, east, north-east y north (lienzo de 152×152,
                                    los pies en la fila 130), con sus fotogramas frame_NNN.png
  grito/south/                      el grito, solo de frente: siempre grita mirando a la pantalla
Las tres direcciones del oeste son el espejo de las del este. El fotograma 0 de zarpazo, golpe y muerte es la pose de
pie, así que no se usa (ya está en el dibujo quieto).

Y escribe assets/sprites/zombi-dependienta.png y .json (casilla de 152×152, los pies en 76,130), con las animaciones
de siempre (still, idle, walk, attack, hurt, death) y una más, roar, el grito («grito» en el juego), igual en las 8
direcciones. En el juego se dibuja a escala 1 (cada píxel del dibujo, 1 unidad; los de 48, a escala 2).

Arreglos:
  - El andar north-east tiene 7 fotogramas y no 8 (se quitó uno que giraba la cara): cada uno dura 8/7 para que dé
    el paso al mismo ritmo que las demás direcciones.
  - En la muerte south y north la pose de pie quedaba 6 píxeles más arriba que el dibujo quieto: se baja la animación
    entera para que no pegue un salto al morir.
  - En el fotograma 1 de la muerte south, south-east y north aún había sangre pegada a la cabeza: se quita (lo rojo
    dentro de un recuadro alrededor de la cabeza; el polo también es rojo, por eso solo ahí).

Uso (desde la carpeta del proyecto; necesita Python con Pillow):
  py tools/dependienta_hoja.py               rehace la hoja
  py tools/dependienta_hoja.py --gif carpeta además guarda GIF de comprobación
y después  py tools/hacer_frames.py assets/sprites/zombi-dependienta
"""
import glob, json, sys
from collections import Counter
from PIL import Image, ImageOps
from png import guardar_png

SRC = 'assets/sources/dependienta-96-gpt/animaciones'
SPRITE = 'zombi-dependienta'
C = 152                    # casilla
PIES = (76, 130)           # los pies dentro de la casilla
DIRS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
ESPEJO = {'north-west': 'north-east', 'west': 'east', 'south-west': 'south-east'}
CINTURA = 58               # fila de la cintura en la pose de pie (112×112): el reposo baja el tronco desde ahí
BAJA = 2                   # cuánto baja el tronco en el reposo (2 píxeles = 2 unidades, como el píxel de los de 48)
FPS_ANDAR = 10
DURACION = {'attack': 0.55, 'hurt': 0.35, 'death': 0.9, 'roar': 1.2}   # segundos
IMPACTO = 3                # en qué fotograma (de los usados) llega el zarpazo

# Sangre del fotograma 1 de la muerte: recuadro (en el lienzo de 152) alrededor de la cabeza
SANGRE = {'south': (60, 28, 102, 48), 'south-east': (89, 38, 112, 57), 'north': (50, 15, 100, 47)}


def cargar(anim, d):
    fs = [Image.open(p).convert('RGBA') for p in sorted(glob.glob(f'{SRC}/{anim}/{d}/frame_*.png'))]
    assert fs, f'faltan los fotogramas de {anim}/{d}'
    return fs


def mover(f, dx, dy):
    out = Image.new('RGBA', f.size, (0, 0, 0, 0))
    out.paste(f, (dx, dy), f)
    return out


rojo = lambda c: c[0] >= 90 and c[0] > 1.8 * c[1] and c[0] > 1.8 * c[2]


def sin_sangre(f, caja):
    """Quita lo rojo de dentro de `caja`: lo que asoma al aire se borra y lo que tapa la cara se rellena con el color
    de sus vecinos, de fuera hacia dentro (como clean() de tools/zombi.py)."""
    out = f.copy()
    px = out.load()
    x0, y0, x1, y1 = caja
    fx = {(x, y) for y in range(y0, y1) for x in range(x0, x1) if px[x, y][3] and rojo(px[x, y][:3])}
    for _ in range(12):
        hecho = {}
        for (x, y) in fx:
            alrededor = [px[x + i, y + j] for i in (-1, 0, 1) for j in (-1, 0, 1)
                         if (i or j) and (x + i, y + j) not in fx]
            solidos = [c for c in alrededor if c[3]]
            if len(alrededor) >= 3:
                hecho[(x, y)] = Counter(solidos).most_common(1)[0][0] if len(solidos) >= 5 else (0, 0, 0, 0)
        for q, c in hecho.items():
            px[q] = c
        fx -= set(hecho)
        if not fx:
            break
    for q in fx:
        px[q] = (0, 0, 0, 0)
    # y las motas que hayan quedado sueltas dentro del recuadro (grupos de menos de 6 píxeles)
    suelto = {(x, y) for y in range(y0, y1) for x in range(x0, x1) if px[x, y][3]}
    while suelto:
        grupo, pila = set(), [suelto.pop()]
        while pila:
            q = pila.pop()
            grupo.add(q)
            for n in ((q[0] + a, q[1] + b) for a in (-1, 0, 1) for b in (-1, 0, 1)):
                if n in suelto:
                    suelto.discard(n)
                    pila.append(n)
        toca_fuera = any(not (x0 <= q[0] + a < x1 and y0 <= q[1] + b < y1) and px[q[0] + a, q[1] + b][3]
                         for q in grupo for a in (-1, 0, 1) for b in (-1, 0, 1))
        if len(grupo) < 6 and not toca_fuera:
            for q in grupo:
                px[q] = (0, 0, 0, 0)
    return out


def con_oeste(por_dir):
    """Las tres direcciones del oeste, en espejo (la casilla es simétrica: los pies en el centro)."""
    for d, de in ESPEJO.items():
        por_dir[d] = [ImageOps.mirror(f) for f in por_dir[de]]
    return por_dir


PROPIAS = [d for d in DIRS if d not in ESPEJO]

# ═════════════ Quieta y reposo ═════════════
rot = {d: Image.open(f'{SRC}/rotaciones/{d}.png').convert('RGBA') for d in PROPIAS}
quieta = {d: [mover(rot[d].crop((-20, -20, C - 20, C - 20)), 0, 0)] for d in PROPIAS}   # (los pies de 56,110 a 76,130)
quieta = con_oeste(quieta)

reposo = {}
for d in DIRS:
    q = quieta[d][0]
    c = CINTURA + PIES[1] - 110
    baja = Image.new('RGBA', q.size, (0, 0, 0, 0))
    baja.paste(q.crop((0, 0, C, c)), (0, BAJA))                 # de la cintura para arriba, BAJA píxeles más abajo
    baja.paste(q.crop((0, c + BAJA, C, C)), (0, c + BAJA))
    reposo[d] = [q, baja]

# ═════════════ Andar, zarpazo, golpe, muerte y grito ═════════════
andar = con_oeste({d: cargar('andar', d) for d in PROPIAS})
zarpazo = con_oeste({d: cargar('zarpazo', d)[1:] for d in PROPIAS})
golpe = con_oeste({d: cargar('golpe', d)[1:] for d in PROPIAS})

muerte = {}
for d in PROPIAS:
    fs = cargar('muerte', d)
    if d in SANGRE:
        fs[1] = sin_sangre(fs[1], SANGRE[d])
    # la pose de pie (fotograma 0), encima del dibujo quieto: si no coincide, se mueve la animación entera
    a, b = fs[0].getbbox(), quieta[d][0].getbbox()
    dx, dy = b[0] - a[0], b[3] - a[3]
    if dx or dy:
        print(f'muerte {d:11s} movida {dx}, {dy} para que la pose de pie quede encima del dibujo quieto')
        fs = [mover(f, dx, dy) for f in fs]
    muerte[d] = fs[1:]
muerte = con_oeste(muerte)

grito_s = cargar('grito', 'south')
grito = {d: grito_s for d in DIRS}      # siempre grita de cara

# ═════════════ Hoja y JSON ═════════════
bloques = [('still', quieta), ('idle', reposo), ('walk', andar), ('attack', zarpazo), ('hurt', golpe),
           ('death', muerte), ('roar', grito)]
cols = max(len(fs) for _, b in bloques for fs in b.values())
filas = 1 + 8 * (len(bloques) - 1)
hoja = Image.new('RGBA', (max(cols, 8) * C, filas * C), (0, 0, 0, 0))
anims = {'still': {'fps': 1, 'loop': True, 'dirs': {}}}
for i, d in enumerate(DIRS):
    hoja.alpha_composite(quieta[d][0], (i * C, 0))
    anims['still']['dirs'][d] = {'row': 0, 'col': i, 'frames': 1}
fila = 1
for nombre, b in bloques[1:]:
    n_sur = len(b['south'])
    fps = {'idle': 1.5, 'walk': FPS_ANDAR}.get(nombre) or round(n_sur / DURACION[nombre], 1)
    anims[nombre] = {'fps': fps, 'loop': nombre in ('idle', 'walk'), 'dirs': {}}
    for d in DIRS:
        for i, f in enumerate(b[d]):
            hoja.alpha_composite(f, (i * C, fila * C))
        info = {'row': fila, 'frames': len(b[d])}
        if len(b[d]) != n_sur:
            # (el andar north-east: 7 fotogramas en vez de 8, cada uno algo más largo para ir al mismo ritmo)
            info['durations'] = [round(n_sur / len(b[d]), 4)] * len(b[d])
        anims[nombre]['dirs'][d] = info
        fila += 1
    print(f'{nombre:7s} {n_sur} fotogramas, {fps} por segundo')
anims['attack']['hit'] = round(IMPACTO / len(zarpazo['south']), 3)

guardar_png(hoja, f'assets/sprites/{SPRITE}.png')
json.dump({'cell': [C, C], 'pivot': list(PIES), 'anims': anims,
           'source': f'Hecha con tools/dependienta_hoja.py a partir de {SRC}/'},
          open(f'assets/sprites/{SPRITE}.json', 'w', encoding='utf-8', newline='\n'), indent=2, ensure_ascii=False)
print('hoja:', hoja.size)

if '--gif' in sys.argv:
    carpeta = sys.argv[sys.argv.index('--gif') + 1]
    G = 2
    for nombre, b in bloques[1:]:
        n = max(len(fs) for fs in b.values())
        gif = []
        for i in range(n):
            im = Image.new('RGBA', (4 * C * G, 2 * C * G), (70, 74, 82, 255))
            for k, d in enumerate(DIRS):
                f = b[d][i % len(b[d])]
                im.alpha_composite(f.resize((C * G, C * G), Image.NEAREST), ((k % 4) * C * G, (k // 4) * C * G))
            gif.append(im.convert('RGB'))
        gif[0].save(f'{carpeta}/{SPRITE}-{nombre}.gif', save_all=True, append_images=gif[1:],
                    duration=int(1000 / anims[nombre]['fps']), loop=0)
    print('GIF guardados en', carpeta)
