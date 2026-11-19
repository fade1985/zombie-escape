"""Monta la hoja de un zombi de 112 px de PixelLab (el dibujo detallado, como la dependienta del 18 nov), a partir de
sus animaciones ya elegidas y limpias. Cada zombi tiene su ficha, hoja.json, en su carpeta de assets/sources/.

Lo que tiene que haber en assets/sources/<carpeta>/animaciones/ (la receta entera, en docs/ZOMBIS_112.md):
  rotaciones/<dirección>.png    las poses de pie (112×112; los pies en 56,110): south, south-east, east, north-east y north
                                (las del oeste, si están, no se usan: salen en espejo)
  <animación>/<dirección>/frame_NNN.png
                                cada animación en esas cinco direcciones (lienzo de 152×152, los pies en 76,130), o
                                solo en south si en la ficha va "solo_de_cara" (el grito: se usa en las 8 direcciones)
Las tres direcciones del oeste son el espejo de las del este (la casilla es simétrica: los pies en el centro).

La ficha (hoja.json), por ejemplo la de la dependienta:
  {"sprite": "zombi-dependienta",                      → assets/sprites/zombi-dependienta.png, .json (y .tres)
   "reposo": {"cintura": 58, "baja": 2},              el reposo: de la cintura (fila de la pose de 112) para arriba,
                                                       "baja" píxeles más abajo, y vuelta
   "animaciones": {
     "walk":   {"de": "andar", "fps": 10},              en bucle, a "fps" fotogramas por segundo
     "attack": {"de": "zarpazo", "desde": 1, "duracion": 0.55, "impacto": 3},
     "hurt":   {"de": "golpe", "desde": 1, "duracion": 0.35},
     "death":  {"de": "muerte", "desde": 1, "duracion": 0.9, "alinear": true},
     "roar":   {"de": "grito", "duracion": 1.2, "solo_de_cara": true}},
   "sangre": {"muerte/south/1": [60, 28, 102, 48]}}   lo rojo dentro de ese recuadro (en el lienzo de 152) se quita
  - Los nombres (walk, attack, hurt, death, roar...) son los de hacer_frames.py (roar = «grito» en el juego).
  - "desde": el primer fotograma que se usa (el 0 de zarpazo, golpe y muerte es la pose de pie: ya está en el quieto).
  - "alinear": mueve la animación entera para que su fotograma 0 caiga encima del dibujo quieto (en la muerte de la
    dependienta la pose de pie quedaba 6 píxeles más arriba y al morir pegaba un salto).
  - "piel": {"tono": 80, "sat": 1.0, "sube": 0.28}: aclara la piel verde en todos los dibujos (ver piel()). La de la
    dependienta salió de PixelLab mucho más oscura que la de los zombis de 48; con esto se parece a la del zombi normal.
  - Si una dirección tiene menos fotogramas que south (el andar north-east de la dependienta, 7 y no 8), cada uno dura
    algo más para que vaya al mismo ritmo.

La hoja va apretada: cada fotograma, recortado a lo que ocupa (con 10 píxeles de aire arriba y abajo, que usan las
llamas y el vómito del shader de los zombis, y 2 a los lados), y los que se repiten, una sola vez. En el .json cada
dirección lleva "rects": [x, y, ancho, alto, x en la casilla, y en la casilla] por fotograma, y hacer_frames.py le
pone a cada uno su "margin" para que en Godot siga midiendo la casilla entera (152×152, los pies en 76,130). Así la
hoja de la dependienta pasa de 50 MB en memoria a unos 10.

En el juego se dibuja a escala 1 (cada píxel del dibujo, 1 unidad; los de 48, a escala 2): en su escena,
scale = Vector2(1, 1) y offset = Vector2(-76, -130).

Uso (desde la carpeta del proyecto; necesita Python con Pillow):
  py tools/hoja_112.py dependienta-96-gpt                 rehace la hoja (y su .tres, con hacer_frames.py)
  py tools/hoja_112.py dependienta-96-gpt --gif carpeta   además guarda GIF de comprobación
"""
import colorsys, glob, json, os, subprocess, sys
from collections import Counter
from PIL import Image, ImageOps
from png import guardar_png
import reducir

CARPETA = sys.argv[1]
SRC = f'assets/sources/{CARPETA}/animaciones'
FICHA = json.load(open(f'assets/sources/{CARPETA}/hoja.json', encoding='utf-8'))
SPRITE = FICHA['sprite']
C = 152                    # casilla (el lienzo de las animaciones)
R = 112                    # lienzo de las poses de pie
PIES = (76, 130)           # los pies dentro de la casilla
DIRS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
ESPEJO = {'north-west': 'north-east', 'west': 'east', 'south-west': 'south-east'}
PROPIAS = [d for d in DIRS if d not in ESPEJO]
AIRE_Y, AIRE_X = 10, 2     # aire alrededor de cada fotograma (lo que mira el shader por encima y por debajo)
ANCHO_HOJA = 2048


PIEL = FICHA.get('piel')
_colores = {}


def piel(f):
    """Aclara la piel verde (como la de los zombis de 48): los píxeles de tono verde (60-150 grados) suben "sube" de
    luz y su saturación se multiplica por "sat", y van al tono "tono". Los muy oscuros (el contorno) apenas cambian,
    así el sombreado y el borde quedan igual. El pelo, el polo, la sangre y los ojos no son verdes: no se tocan."""
    if not PIEL:
        return f
    px = f.load()
    for y in range(f.height):
        for x in range(f.width):
            c = px[x, y]
            if not c[3]:
                continue
            if c not in _colores:
                h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
                h *= 360
                if 60 <= h <= 150 and s >= 0.12 and v >= 0.12:
                    peso = min(1, (v - 0.12) / 0.12)
                    v = min(1, v + PIEL['sube'] * peso)
                    s = min(1, s * (1 + (PIEL['sat'] - 1) * peso))
                    h += (PIEL['tono'] - h) * peso
                    r, g, b = colorsys.hsv_to_rgb(h / 360, s, v)
                    _colores[c] = (round(r * 255), round(g * 255), round(b * 255), c[3])
                else:
                    _colores[c] = c
            px[x, y] = _colores[c]
    return f


def cargar(anim, d):
    fs = [piel(Image.open(p).convert('RGBA')) for p in sorted(glob.glob(f'{SRC}/{anim}/{d}/frame_*.png'))]
    assert fs, f'faltan los fotogramas de {anim}/{d}'
    assert fs[0].size == (C, C), f'{anim}/{d}: el lienzo tiene que ser de {C}×{C} (es {fs[0].size})'
    return fs


def mover(f, dx, dy):
    out = Image.new('RGBA', f.size, (0, 0, 0, 0))
    out.paste(f, (dx, dy), f)
    return out


rojo = lambda c: c[0] >= 90 and c[0] > 1.8 * c[1] and c[0] > 1.8 * c[2]


def sin_sangre(f, caja):
    """Quita lo rojo de dentro de `caja`: lo que asoma al aire se borra y lo que tapa el cuerpo se rellena con el color
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
    for d, de in ESPEJO.items():
        por_dir[d] = [ImageOps.mirror(f) for f in por_dir[de]]
    return por_dir


# ═════════════ Quieto y reposo ═════════════
m = (C - R) // 2   # (los pies de la pose de 112, de 56,110 a 76,130)
quieto = con_oeste({d: [piel(Image.open(f'{SRC}/rotaciones/{d}.png').convert('RGBA').crop((-m, -m, C - m, C - m)))]
                    for d in PROPIAS})
REPOSO = FICHA.get('reposo', {})
cintura, baja = REPOSO.get('cintura', 58) + m, REPOSO.get('baja', 2)
reposo = {}
for d in DIRS:
    q = quieto[d][0]
    abajo = Image.new('RGBA', q.size, (0, 0, 0, 0))
    abajo.paste(q.crop((0, 0, C, cintura)), (0, baja))           # de la cintura para arriba, más abajo
    abajo.paste(q.crop((0, cintura + baja, C, C)), (0, cintura + baja))
    reposo[d] = [q, abajo]

# ═════════════ Las animaciones de la ficha ═════════════
SANGRE = FICHA.get('sangre', {})
bloques = [('still', quieto, {'fps': 1, 'loop': True}), ('idle', reposo, {'fps': REPOSO.get('fps', 1.5), 'loop': True})]
for nombre, a in FICHA['animaciones'].items():
    por_dir = {}
    for d in (['south'] if a.get('solo_de_cara') else PROPIAS):
        fs = cargar(a['de'], d)
        for n in range(len(fs)):
            if f"{a['de']}/{d}/{n}" in SANGRE:
                fs[n] = sin_sangre(fs[n], SANGRE[f"{a['de']}/{d}/{n}"])
        if a.get('alinear'):
            p, q = fs[0].getbbox(), quieto[d][0].getbbox()
            dx, dy = q[0] - p[0], q[3] - p[3]
            if dx or dy:
                print(f'{a["de"]:8s} {d:11s} movida {dx}, {dy} para que la pose de pie quede encima del dibujo quieto')
                fs = [mover(f, dx, dy) for f in fs]
        por_dir[d] = fs[a.get('desde', 0):]
    por_dir = {d: por_dir['south'] for d in DIRS} if a.get('solo_de_cara') else con_oeste(por_dir)
    n = len(por_dir['south'])
    info = {'fps': a['fps'] if 'fps' in a else round(n / a['duracion'], 1), 'loop': a.get('bucle', nombre == 'walk')}
    if 'impacto' in a:
        info['hit'] = round(a['impacto'] / n, 3)
    bloques.append((nombre, por_dir, info))

# ═════════════ Reducida (si la ficha lo pide) ═════════════
# "reducir": {"casilla": 64, "pies": [32, 55], "borde": "#050202"}: cada dibujo, del lienzo de 152 a uno de "casilla" con los
# pies en "pies" y un borde de 1 píxel de ese color (tools/reducir.py). Así sale del tamaño y con el acabado de los de 48
# (y en el juego, a escala 2). La dependienta, desde el 19 nov (lo pidió el dueño): de la altura de Johnny, con su borde negro.
REDUCIR = FICHA.get('reducir')


if REDUCIR:
    hechas = {}   # (cada dibujo distinto se reduce una vez: los repetidos salen iguales y la hoja los junta)
    for _, b, _ in bloques:
        for d in b:
            nuevos = []
            for f in b[d]:
                k = f.tobytes()
                if k not in hechas:
                    hechas[k] = reducir.reducida(f, PIES, REDUCIR)
                nuevos.append(hechas[k])
            b[d] = nuevos
    C, PIES = reducir.casilla(REDUCIR)[0], tuple(REDUCIR['pies'])

# ═════════════ Hoja apretada ═════════════
# cada fotograma distinto, recortado con su aire; los repetidos (el grito en las 8 direcciones...), una sola vez
unicos, trozos = {}, []
for _, b, _ in bloques:
    for fs in b.values():
        for f in fs:
            k = f.tobytes()
            if k not in unicos:
                x0, y0, x1, y1 = f.getbbox() or (PIES[0], PIES[1], PIES[0] + 1, PIES[1] + 1)
                caja = (max(0, x0 - AIRE_X), max(0, y0 - AIRE_Y), min(C, x1 + AIRE_X), min(C, y1 + AIRE_Y))
                unicos[k] = len(trozos)
                trozos.append((f.crop(caja), caja))
# en estantes, de más alto a más bajo, con un hueco entre trozos (para que el shader no lea el de al lado)
orden = sorted(range(len(trozos)), key=lambda i: -trozos[i][0].height)
sitio, x, y, alto_estante = {}, 0, 0, 0
for i in orden:
    w, h = trozos[i][0].size
    if x + w > ANCHO_HOJA:
        x, y, alto_estante = 0, y + alto_estante + AIRE_Y, 0
    sitio[i] = (x, y)
    x += w + AIRE_Y
    alto_estante = max(alto_estante, h)
hoja = Image.new('RGBA', (ANCHO_HOJA, y + alto_estante), (0, 0, 0, 0))
for i, (im, _) in enumerate(trozos):
    hoja.alpha_composite(im, sitio[i])

anims = {}
for nombre, b, info in bloques:
    n_sur = len(b['south'])
    anims[nombre] = dict(info, dirs={})
    for d in DIRS:
        rects = []
        for f in b[d]:
            i = unicos[f.tobytes()]
            (sx, sy), (im, caja) = sitio[i], trozos[i]
            rects.append([sx, sy, im.width, im.height, caja[0], caja[1]])
        dd = {'frames': len(rects), 'rects': rects}
        if len(rects) != n_sur:
            dd['durations'] = [round(n_sur / len(rects), 4)] * len(rects)
        anims[nombre]['dirs'][d] = dd
    print(f'{nombre:7s} {n_sur} fotogramas, {info["fps"]} por segundo')

guardar_png(hoja, f'assets/sprites/{SPRITE}.png')
json.dump({'cell': [C, C], 'pivot': list(PIES), 'anims': anims,
           'source': f'Hecha con tools/hoja_112.py a partir de {SRC}/ (ficha: assets/sources/{CARPETA}/hoja.json)'},
          open(f'assets/sprites/{SPRITE}.json', 'w', encoding='utf-8', newline='\n'), indent=1, ensure_ascii=False)
print(f'hoja: {hoja.size}, {len(trozos)} fotogramas distintos, {hoja.width * hoja.height * 4 / 1e6:.1f} MB en memoria')
subprocess.run([sys.executable, 'tools/hacer_frames.py', f'assets/sprites/{SPRITE}'], check=True)

if '--gif' in sys.argv:
    carpeta = sys.argv[sys.argv.index('--gif') + 1]
    G = 2
    for nombre, b, info in bloques[1:]:
        n = max(len(fs) for fs in b.values())
        gif = []
        for i in range(n):
            im = Image.new('RGBA', (4 * C * G, 2 * C * G), (70, 74, 82, 255))
            for k, d in enumerate(DIRS):
                f = b[d][i % len(b[d])]
                im.alpha_composite(f.resize((C * G, C * G), Image.NEAREST), ((k % 4) * C * G, (k // 4) * C * G))
            gif.append(im.convert('RGB'))
        gif[0].save(f'{carpeta}/{SPRITE}-{nombre}.gif', save_all=True, append_images=gif[1:],
                    duration=int(1000 / info['fps']), loop=0)
    print('GIF guardados en', carpeta)
