"""Monta la hoja de sprites de un zombi a partir de lo que da PixelLab.

Lo saca todo de assets/sources/<fuente>/:
  rotations/<dirección>.png     las 8 posturas quietas (48×48), ya con la piel corregida por tools/piel.py
  walk/<dirección>-<n>.png      andar (PixMiniMax; el lienzo cambia de tamaño según la dirección)
  ataque/, golpe/, muerte/      atacar, recibir un golpe y morir (lienzo de 96×96 con el dibujo quieto en 24, 32)
  rugir/ (opcional)             el rugido, como el ataque pero solo south (el jefe de seguridad): «roar» («grito» en el juego)
  reposo/ (opcional)            reposo de PixMiniMax, con partida y final en el dibujo quieto (el de tentáculos)
  zombi.json (opcional)         qué fotogramas se usan, cuánto dura cada animación, "cintura", "pies", "sangre", "casilla", "origen", "fps_andar", "suave"
                                y "reducir" (un zombi dibujado con el doble de detalle, al tamaño y con el borde negro de los de 48:
                                tools/reducir.py; el de tentáculos, desde el 19 nov)
                                y "cerrar_borde" (el contorno de la figura, todo del color que se le da: el vigilante, desde el 19 nov)
                                y "neon" (el chaleco y las franjas reflectantes, a amarillo neón sin tocar la piel: los vigilantes y
                                el jefe de seguridad, desde el 20 nov)
                                y "heridas_verdes" (las heridas rojas, del verde de la piel del vecino, sin tocar boca ni
                                contorno: el gordo, desde el 20 nov)
En todas las animaciones el fotograma 0 es el dibujo quieto: así se sabe dónde colocar los demás.

Y escribe assets/sprites/<sprite>.png y .json con seis animaciones:
  still   las 8 posturas quietas
  idle    reposo hecho a mano: el tronco baja y sube un píxel, despacio (o el de reposo/, si lo hay)
  walk    andar: solo el tramo que hace ciclo, con los colores igualados a los del dibujo quieto
  attack  el zarpazo ("hit" dice en qué punto llega)
  hurt    recibir un golpe
  death   morir: no se repite, se queda en el último fotograma (tendido en el suelo)

Limpieza: PixelLab mete sangre de un rojo muy vivo y algún destello aunque se le pida que no. En golpe y muerte
la sangre se oscurece (decidido por el dueño: se queda, pero en un rojo apagado que no desentone) y se quita
cualquier otro efecto de un color ajeno al zombi; en el ataque solo se quitan los destellos blancos.
Con "sangre": "quitar" o "viva" en zombi.json se cambia eso.

Uso (desde la carpeta del proyecto; necesita Python con Pillow):
  py tools/zombi.py zombi-normal-48 zombi-normal                 rehace la hoja zombi-normal
  py tools/zombi.py zombi-normal-48 zombi-normal --gif carpeta   además guarda GIF de comprobación
"""
import json, os, sys
from collections import Counter
from PIL import Image, ImageChops
from png import guardar_png  # guarda la hoja comprimida sin perder nada
import reducir  # el dibujo detallado, al tamaño de los de 48 ("reducir" en zombi.json)

SOURCE, SPRITE = sys.argv[1], sys.argv[2]
DIRS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
SRC = f'assets/sources/{SOURCE}'
cfg = json.load(open(f'{SRC}/zombi.json', encoding='utf-8')) if os.path.exists(f'{SRC}/zombi.json') else {}
# Para un zombi más grande que 48×48 (el venenoso, a 72): "casilla" y "origen" en zombi.json
CW, CH = cfg.get('casilla', [96, 96])   # casilla: cabe el zombi tendido en el suelo
OX, OY = cfg.get('origen', [24, 32])    # dónde va el dibujo quieto dentro de la casilla
PX, PY = CW // 2, cfg.get('pies', 78)   # los pies dentro de la casilla (otra altura con "pies" en zombi.json)
WAIST = cfg.get('cintura', 26)   # fila de la cintura en el dibujo quieto (para el reposo); otra con "cintura" en zombi.json

rot = {d: Image.open(f'{SRC}/rotations/{d}.png').convert('RGBA') for d in DIRS}
# Sangre: "oscura" (rojo apagado, lo normal), "quitar" (sin sangre) o "viva" (el rojo chillón de PixelLab)
SANGRE = cfg.get('sangre', 'oscura')
BLOOD = [(134, 20, 12), (104, 12, 6), (74, 8, 4)]   # de más clara a más oscura
# todos los colores del zombi, de sus 8 vistas (más los de la sangre, si se queda)
PALETTE = sorted({c[:3] for d in DIRS for _, c in rot[d].getcolors(4096) if c[3]} | set(BLOOD if SANGRE == 'oscura' else []))


def cell(im, x=0, y=0):
    c = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    c.paste(im, (OX + x, OY + y), im)
    return c


def load(folder, d):
    fs = []
    while os.path.exists(f'{SRC}/{folder}/{d}-{len(fs)}.png'):
        fs.append(Image.open(f'{SRC}/{folder}/{d}-{len(fs)}.png').convert('RGBA'))
    assert fs, f'faltan los fotogramas de {folder} de {d}'
    return fs


def offset(fs, d, folder):
    """El fotograma 0 es el dibujo quieto: comparándolos se sabe cuánto está desplazado todo."""
    a, b = fs[0].getbbox(), rot[d].getbbox()
    ox, oy = a[0] - b[0], a[1] - b[1]
    # solo cuenta lo que se ve: bajo los píxeles transparentes PixelLab a veces deja otro color
    def seen(im):
        out = Image.new('RGBA', im.size, (0, 0, 0, 0))
        out.paste(im, (0, 0), im)
        return out.tobytes()
    same = seen(fs[0].crop((ox, oy, ox + rot[d].width, oy + rot[d].height))) == seen(rot[d])
    assert same, f'el fotograma 0 de {folder}/{d} no coincide con el dibujo quieto'
    return ox, oy


def placed(f, ox, oy, d, n, folder):
    b = f.getbbox()
    if b and (b[0] - ox + OX < 0 or b[1] - oy + OY < 0 or b[2] - ox + OX > CW or b[3] - oy + OY > CH):
        print(f'  OJO: el fotograma {n} de {folder}/{d} se sale de la casilla')
    return cell(f, -ox, -oy)


_near = {}
_pal = set(PALETTE)


def nearest(c):
    """El color del zombi más parecido a `c` y lo lejos que queda."""
    if c not in _near:
        # los que ya son del zombi, sin buscar (el de tentáculos tiene miles de colores y buscar uno a uno es lento)
        _near[c] = (0, c) if c in _pal else min(((p[0] - c[0]) ** 2 + (p[1] - c[1]) ** 2 + (p[2] - c[2]) ** 2, p)
                                                for p in PALETTE)
    return _near[c]


def clean(f, is_fx):
    """Quita los píxeles de efecto (los que cumplen `is_fx`): los sueltos se borran y los que quedan dentro
    del cuerpo se rellenan con el color de sus vecinos."""
    out = f.copy()
    px = out.load()
    w, h = out.size
    fx = {(x, y) for y in range(h) for x in range(w) if px[x, y][3] and is_fx(px[x, y][:3])}
    for (x, y) in list(fx):
        if px[x, y][3] < 128:
            px[x, y] = (0, 0, 0, 0)
    for _ in range(6):   # de fuera hacia dentro
        done = {}
        for (x, y) in fx:
            around = [px[x + i, y + j] for i in (-1, 0, 1) for j in (-1, 0, 1)
                      if (i or j) and 0 <= x + i < w and 0 <= y + j < h and (x + i, y + j) not in fx]
            solid = [c for c in around if c[3]]
            if len(around) >= 3:
                # rodeado de cuerpo: se rellena; asomando al aire: se borra
                done[(x, y)] = Counter(solid).most_common(1)[0][0] if len(solid) >= 5 else (0, 0, 0, 0)
        for q, c in done.items():
            px[q] = c
        fx -= set(done)
        if not fx:
            break
    for q in fx:
        px[q] = (0, 0, 0, 0)
    return out


alien = lambda c: nearest(c)[0] > 60 ** 2                      # nada que ver con los colores del zombi
red = lambda c: c[0] > 150 and c[1] < 90 and c[2] < 90         # el rojo vivo de la sangre de PixelLab


def darken(f):
    """La sangre roja viva, a rojo apagado (el borde de cada mancha, un tono más oscuro que el centro)."""
    f = f.copy()
    px = f.load()
    for y in range(f.height):
        for x in range(f.width):
            r, g, b, a = px[x, y]
            if a >= 128 and red((r, g, b)):
                edge = any(not (0 <= x + i < f.width and 0 <= y + j < f.height) or px[x + i, y + j][3] < 128
                           for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                px[x, y] = (*BLOOD[2 if edge else 1 if r < 235 else 0], 255)
    return f


def gore(f):
    """Golpe y muerte: deja la sangre como diga SANGRE, quita los demás efectos e iguala los colores."""
    if SANGRE == 'viva':
        return clean(f, lambda c: alien(c) and not red(c))
    if SANGRE == 'oscura':
        return same_colors(clean(darken(f), alien))
    return specks(same_colors(clean(f, alien)), cfg.get('sueltos', False))
spark = lambda c: min(c) > 215 and nearest(c)[0] > 40 ** 2     # destello blanco


def suavizar(im, brillo):
    """Contorno suave y retoque de color (ver "suave" más abajo)"""
    from PIL import ImageEnhance
    px = im.load()
    w, h = im.size
    v4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
    v8 = v4 + ((1, 1), (-1, 1), (1, -1), (-1, -1))
    borde = {(x, y) for y in range(h) for x in range(w) if px[x, y][3] and any(
        not (0 <= x + i < w and 0 <= y + j < h) or not px[x + i, y + j][3] for i, j in v4)}
    nuevo = {}
    for x, y in borde:
        r, g, b, a = px[x, y]
        if r + g + b < 120:   # el contorno oscuro: el color de dentro
            dentro = [px[x + i, y + j] for i, j in v8 if 0 <= x + i < w and 0 <= y + j < h
                      and px[x + i, y + j][3] and (x + i, y + j) not in borde]
            if dentro:
                r, g, b = (sum(c[k] for c in dentro) / len(dentro) for k in range(3))
        nuevo[(x, y)] = (round(r * brillo * 0.6), round(g * brillo * 0.6), round(b * brillo * 0.6), a)
    alfa = im.split()[3]
    rgb = ImageEnhance.Contrast(im.convert('RGB')).enhance(1.2)
    rgb = ImageEnhance.Brightness(rgb).enhance(brillo)
    rgb = ImageEnhance.Color(rgb).enhance(1.1).convert('RGBA')
    rgb.putalpha(alfa)
    q = rgb.load()
    for p, c in nuevo.items():
        q[p] = c
    return rgb


def same_colors(im):
    """Pinta el fotograma solo con los colores del zombi (el más parecido a cada uno)."""
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            px[x, y] = (*nearest((r, g, b))[1], 255) if a >= 128 else (0, 0, 0, 0)
    return out


def specks(im, sueltos=False):
    """Quita las motas sueltas (grupos de menos de 4 píxeles separados del resto). Con `sueltos` ("sueltos": true
    en zombi.json) quita todo lo que no esté pegado al cuerpo: la dependienta lleva un polo rojo, así que la sangre
    no se puede buscar por el color, pero los chorros que salen volando sí se pueden quitar."""
    px = im.load()
    left = {(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3]}
    groups = []
    while left:
        group, todo = set(), [left.pop()]
        while todo:
            q = todo.pop()
            group.add(q)
            for n in ((q[0] + a, q[1] + b) for a in (-1, 0, 1) for b in (-1, 0, 1)):
                if n in left:
                    left.discard(n)
                    todo.append(n)
        groups.append(group)
    big = max(groups, key=len) if groups else set()
    for group in groups:
        if len(group) < 4 or (sueltos and group is not big):
            for q in group:
                px[q] = (0, 0, 0, 0)
    return im


still = {d: cell(rot[d]) for d in DIRS}

# ═════════════ Reposo: el tronco baja un píxel y vuelve ═════════════
# Si hay carpeta reposo/, el de PixelLab: del 0 al penúltimo en bucle (el último vuelve a ser el 0); "reposo": {"fps"}
# en zombi.json, a qué ritmo
REPOSO = os.path.isdir(f'{SRC}/reposo')
idle = {}
for d in DIRS:
    if REPOSO:
        fs = load('reposo', d)
        ox, oy = offset(fs, d, 'reposo')
        idle[d] = [placed(specks(same_colors(f)), ox, oy, d, n, 'reposo') for n, f in enumerate(fs[:-1])]
        continue
    r = rot[d]
    low = Image.new('RGBA', r.size, (0, 0, 0, 0))
    low.paste(r.crop((0, 0, r.width, WAIST)), (0, 1))            # de la cintura para arriba, un píxel más abajo
    low.paste(r.crop((0, WAIST + 1, r.width, r.height)), (0, WAIST + 1))
    idle[d] = [still[d], cell(low)]

# ═════════════ Andar ═════════════
def differ(a, b):
    return sum(1 for p in ImageChops.difference(a, b).get_flattened_data() if max(p) > 24)


def find_loop(fs):
    """El tramo que mejor hace ciclo: el fotograma que viene justo después es casi igual al primero."""
    best = min((differ(fs[a], fs[a + n]), a, n) for a in range(2, len(fs)) for n in range(6, 11) if a + n < len(fs))
    return best[1], best[2], best[0]


LOOP = cfg.get('andar', {})
walk = {}
for d in DIRS:
    fs = load('walk', d)
    ox, oy = offset(fs, d, 'walk')
    if d in LOOP:
        (a, n), how = LOOP[d], 'de zombi.json'
    else:
        a, n, dif = find_loop(fs)
        how = f'elegidos solos; al cerrar el ciclo cambian {dif} píxeles' + (' ← OJO, es mucho' if dif > 150 else '')
    walk[d] = [placed(specks(same_colors(fs[i])), ox, oy, d, i, 'walk') for i in range(a, a + n)]
    print(f'andar  {d:11s} lienzo {fs[0].size}, fotogramas {a} a {a + n - 1} ({how})')

# ═════════════ Atacar, recibir golpe y morir ═════════════
def block(folder, key, default, fix, dirs=DIRS):
    pick = cfg.get(key, {}).get('fotogramas')
    out = {}
    for d in dirs:
        fs = load(folder, d)
        ox, oy = offset(fs, d, folder)
        ns = pick or list(range(default[0], min(default[1], len(fs) - 1) + 1))
        # "cambiar": {"south": {"5": 6}} (en "ataque", "golpe"...): en esa dirección, el fotograma 5 de PixelLab se
        # cambia por el 6. El gordo, desde el 20 nov: escupiendo hacia abajo, el 5 pintaba un chorro hasta el suelo
        # que acababa en una raya recta (en las otras direcciones solo sale de la boca); el moco lo lanza el juego
        cambio = cfg.get(key, {}).get('cambiar', {}).get(d, {})
        ns = [cambio.get(str(n), n) for n in ns]
        out[d] = [placed(fix(fs[n]), ox, oy, d, n, folder) for n in ns]
    n = len(out['south'])
    assert all(len(v) == n for v in out.values()), f'{folder}: todas las direcciones deben tener los mismos fotogramas'
    print(f'{folder:7s} {n} fotogramas por dirección')
    return out


SLIME = [(143, 209, 63), (110, 170, 45), (79, 119, 45)]   # el verde del moco del juego, de claro a oscuro


def slime(f):
    """El venenoso: PixelLab pinta lo que escupe de un rojo puro. Se pasa al verde del moco del juego."""
    f = f.copy()
    px = f.load()
    for y in range(f.height):
        for x in range(f.width):
            r, g, b, a = px[x, y]
            if a >= 128 and r >= 120 and g <= 70 and b <= 70 and r - g >= 110 and nearest((r, g, b))[0] > 35 ** 2:
                px[x, y] = (*SLIME[0 if r >= 235 else 1 if r >= 200 else 2], 255)
    return specks(clean(f, spark))


# en "ataque" de zombi.json: "sangre": true trata la sangre como en golpe y muerte; "moco": true tiñe de verde
# el chorro rojo que PixelLab le pinta al venenoso al escupir
ATK = cfg.get('ataque', {})
attack = block('ataque', 'ataque', (1, 7),
               gore if ATK.get('sangre') else slime if ATK.get('moco') else lambda f: specks(clean(f, spark)))
hurt = block('golpe', 'golpe', (1, 6), gore)
death = block('muerte', 'muerte', (1, 12), gore)
DUR = {'attack': cfg.get('ataque', {}).get('duracion', 0.55), 'hurt': cfg.get('golpe', {}).get('duracion', 0.35),
       'death': cfg.get('muerte', {}).get('duracion', 0.9)}
HIT = cfg.get('ataque', {}).get('impacto', 3)   # en qué fotograma (de los elegidos) llega el zarpazo
# Y, si tiene carpeta rugir/, el rugido (17 nov, el jefe de seguridad: «grito» en el juego), de 1,4 s si no dice otra cosa
# "rugir" en zombi.json. Solo de frente (south): siempre ruge mirando a la pantalla (lo pidió el dueño)
roar = block('rugir', 'rugir', (1, 12), gore, ['south']) if os.path.isdir(f'{SRC}/rugir') else None
DUR['roar'] = cfg.get('rugir', {}).get('duracion', 1.4)

# ═════════════ Hoja y JSON ═════════════
blocks = [('idle', idle), ('walk', walk), ('attack', attack), ('hurt', hurt), ('death', death)]
if roar:
    blocks.append(('roar', roar))
cols = max(len(DIRS), *(len(fs) for _, b in blocks for fs in b.values()))
sheet = Image.new('RGBA', (cols * CW, (1 + sum(len(b) for _, b in blocks)) * CH), (0, 0, 0, 0))
for i, d in enumerate(DIRS):
    sheet.alpha_composite(still[d], (i * CW, 0))
anims = {'still': {'fps': 1, 'loop': True, 'dirs': {d: {'row': 0, 'col': i, 'frames': 1} for i, d in enumerate(DIRS)}}}
row = 1
for name, b in blocks:
    ds = [d for d in DIRS if d in b]   # (el rugido, solo de frente)
    for r, d in enumerate(ds):
        for i, f in enumerate(b[d]):
            sheet.alpha_composite(f, (i * CW, (row + r) * CH))
    # andar, a 10 fotogramas por segundo; otro ritmo con "fps_andar" (el vecino de GPT, a 7: lo eligió el dueño)
    fps = {'idle': cfg.get('reposo', {}).get('fps', 1.5), 'walk': cfg.get('fps_andar', 10)}.get(name) or round(len(b['south']) / DUR[name], 1)
    anims[name] = {'fps': fps, 'loop': name in ('idle', 'walk'),
                   'dirs': {d: {'row': row + r, 'frames': len(b[d])} for r, d in enumerate(ds)}}
    row += len(ds)
anims['attack']['hit'] = round(HIT / len(attack['south']), 3)
# "heridas_verdes" en zombi.json (el gordo, desde el 20 nov): las fístulas del cuerpo y lo que le cuelga de la barriga,
# del verde de la piel del vecino (el durmiente normal) en vez de rojo. Es herida lo rojo (lo casi negro no) salvo:
#   - cerca de los dientes y los ojos (lo blanco puro, a 5 píxeles o menos): la boca y los labios se quedan rojos;
#   - en el borde de la figura, el rojo oscuro: es el contorno (las tiras que cuelgan, más claras, sí cambian).
# Y lo rojo casi negro de dentro de la herida, si tiene al lado 3 o más píxeles ya verdes, pasa a verde oscuro.
# El verde lleva la claridad de lo que había (un poco más claro) y, como la piel del vecino, es más vivo en las luces.
# Ojo, la pierna de detrás: al andar (y en otras animaciones) PixelLab la pinta en sombra de un rojo oscuro casi liso,
# del mismo rojo que las heridas, y salía verde. Se pasa a carne en sombra (lo pidió el dueño): en el último 38 % de
# la figura (las piernas), las manchas de herida de 12 píxeles o más con un color que es el 40 % o más de la mancha
# (las heridas tienen muchos tonos; la pierna, uno), y de ellas solo lo oscuro (las tiras de la barriga que caen
# delante son más claras y siguen verdes).
#   "heridas_verdes": {}  o con "tono": 78 (grados)
def heridas_verdes(sheet, opc):
    import colorsys
    tono = opc.get('tono', 78) / 360
    hls = {}
    def col(c):
        if c not in hls:
            h, l, s = colorsys.rgb_to_hls(*[v / 255 for v in c])
            hls[c] = (h * 360, l, s)
        return hls[c]
    def rojo(c):   # 0: no es herida, 1: herida, 2: rojo casi negro (solo si está rodeado de herida)
        h, l, s = col(c)
        if not (h >= 340 or h <= 14) or s < 0.3:
            return 0
        if l < 0.18:
            return 2 if l >= 0.08 and (h >= 340 or h <= 12) else 0
        return 1 if (h >= 340 or h <= 9 or s >= 0.45) else 0
    def verde(c):
        h, l, s = col(c)
        l2 = min(0.72, l * 1.15 + 0.03)
        return tuple(round(v * 255) for v in colorsys.hls_to_rgb(tono, l2, min(0.65, 0.30 + max(0, l2 - 0.5) * 1.4)))
    def carne(c):   # la piel en sombra (como la de sus muslos: tono 19, viveza 0,45)
        h, l, s = col(c)
        return tuple(round(v * 255) for v in colorsys.hls_to_rgb(19 / 360, min(0.45, l * 1.1 + 0.04), 0.45))
    for fy in range(sheet.height // CH):
        for fx in range(sheet.width // CW):
            caja = (fx * CW, fy * CH, (fx + 1) * CW, (fy + 1) * CH)
            c = sheet.crop(caja)
            if not c.getbbox():
                continue
            cp = c.load()
            def borde(x, y):
                return any(not (0 <= x + i < CW and 0 <= y + j < CH) or cp[x + i, y + j][3] == 0
                           for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            cerca = set()   # lo de alrededor de dientes y ojos
            for y in range(CH):
                for x in range(CW):
                    if cp[x, y][3] and col(cp[x, y][:3])[1] > 0.85 and col(cp[x, y][:3])[2] < 0.35:
                        cerca.update((x + i, y + j) for i in range(-5, 6) for j in range(-5, 6))
            herida, oscuro = set(), []
            for y in range(CH):
                for x in range(CW):
                    p = cp[x, y]
                    if not p[3] or (x, y) in cerca:
                        continue
                    r = rojo(p[:3])
                    if r == 1 and not (borde(x, y) and col(p[:3])[1] < 0.26):
                        herida.add((x, y))
                    elif r == 2 and not borde(x, y):
                        oscuro.append((x, y))
            arriba, abajo = c.getbbox()[1], c.getbbox()[3]
            linea = arriba + 0.62 * (abajo - arriba)
            piernas = {q for q in herida if q[1] >= linea}
            pierna, vistos = set(), set()
            for q in piernas:
                if q in vistos:
                    continue
                mancha, i = [q], 0
                vistos.add(q)
                while i < len(mancha):
                    x, y = mancha[i]
                    i += 1
                    for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if r in piernas and r not in vistos:
                            vistos.add(r)
                            mancha.append(r)
                if len(mancha) >= 12 and Counter(cp[r][:3] for r in mancha).most_common(1)[0][1] >= 0.4 * len(mancha):
                    pierna.update(r for r in mancha if col(cp[r][:3])[1] < 0.34)
            herida -= pierna
            for q in oscuro:
                cerca_de = lambda zona: sum((q[0] + i, q[1] + j) in zona for i in (-1, 0, 1) for j in (-1, 0, 1)) >= 3
                if cerca_de(herida):
                    herida.add(q)
                elif cerca_de(pierna):
                    pierna.add(q)
            for q in herida:
                cp[q] = verde(cp[q][:3]) + (cp[q][3],)
            for q in pierna:
                cp[q] = carne(cp[q][:3]) + (cp[q][3],)
            sheet.paste(c, caja[:2])
    return sheet
if 'heridas_verdes' in cfg:
    sheet = heridas_verdes(sheet, cfg['heridas_verdes'])
# "sangre_en_todo": true en zombi.json, para cuando el dibujo quieto ya trae sangre roja viva (el vigilante): se
# oscurece en toda la hoja, no solo en golpe y muerte, para que no cambie de color al andar
if cfg.get('sangre_en_todo') and SANGRE == 'oscura':
    sheet = darken(sheet)
# "suave" en zombi.json (el crío, 0.8): más real, como los zombis de GPT. El contorno casi negro de PixelLab, que lo
# deja plano, de cómic, pasa a ser el color de dentro al 60 %, y algo más de contraste y color; el número es el brillo
# (lo eligió el dueño el 8 nov: el crío, a 0,8, más oscuro que el vecino de GPT)
if cfg.get('suave'):
    sheet = suavizar(sheet, cfg['suave'])
# "reducir" en zombi.json: cada casilla, más pequeña y con su borde negro (tools/reducir.py); en su escena, a escala 2
if cfg.get('reducir'):
    nw, nh = reducir.casilla(cfg['reducir'])
    pequena = Image.new('RGBA', (sheet.width // CW * nw, sheet.height // CH * nh), (0, 0, 0, 0))
    for fy in range(sheet.height // CH):
        for fx in range(sheet.width // CW):
            c = sheet.crop((fx * CW, fy * CH, (fx + 1) * CW, (fy + 1) * CH))
            if c.getbbox():
                pequena.alpha_composite(reducir.reducida(c, (PX, PY), cfg['reducir']), (fx * nw, fy * nh))
    sheet, CW, CH = pequena, nw, nh
    PX, PY = cfg['reducir']['pies']
# "neon" en zombi.json (los vigilantes y el jefe de seguridad, desde el 20 nov): el chaleco y las franjas reflectantes,
# de un amarillo neón de verdad (GPT los dejó amarillo verdoso y en el juego parecían verdes). La piel del zombi tiene
# el mismo tono, así que se separan por lo vivo que es el color: es chaleco lo bastante vivo para su claridad ("alto";
# a más claro, más vivo tiene que ser, porque los brillos de la piel son claros y algo vivos) y, pegado a eso, lo un
# poco menos vivo ("bajo": el borde de la franja del jefe), pero solo si la zona tiene por lo menos 3 píxeles seguros
# (así no se cuelan los bordes de las manos y los brazos). Lo elegido pasa a amarillo: las sombras, hacia el naranja
# ("tono" de la sombra) y las luces, a amarillo puro ("tono" de la luz), más vivo y un poco más claro.
#   "neon": {}  con lo de siempre, o con alguno de: "alto": 0.5, "bajo": 0.3, "tono": [50, 60]
def neon(sheet, opc):
    import colorsys
    alto, bajo = opc.get('alto', 0.5), opc.get('bajo', 0.3)
    t0, t1 = opc.get('tono', [50, 60])
    def viveza(c):   # cuánto más vivo es el color de lo que hace falta para ser chaleco (o None si no es de su tono)
        h, l, s = colorsys.rgb_to_hls(*[v / 255 for v in c])
        if not (50 <= h * 360 <= 82) or l < 0.18:   # (lo casi negro, el contorno, no)
            return None
        return s - max(0, l - 0.5) * 1.5
    def amarillo(c):
        h, l, s = colorsys.rgb_to_hls(*[v / 255 for v in c])
        t = min(1, max(0, (l - 0.25) / 0.4))
        return tuple(round(v * 255) for v in colorsys.hls_to_rgb((t0 + (t1 - t0) * t) / 360, min(0.68, l * 1.12), min(1, s * 1.25 + 0.1)))
    vivo = {}
    for fy in range(sheet.height // CH):
        for fx in range(sheet.width // CW):
            caja = (fx * CW, fy * CH, (fx + 1) * CW, (fy + 1) * CH)
            c = sheet.crop(caja)
            if not c.getbbox():
                continue
            cp = c.load()
            cand = set()
            for y in range(CH):
                for x in range(CW):
                    p = cp[x, y]
                    if p[3]:
                        if p[:3] not in vivo:
                            vivo[p[:3]] = viveza(p[:3])
                        v = vivo[p[:3]]
                        if v is not None and v >= bajo:
                            cand.add((x, y))
            vistos = set()
            for q in cand:
                if q in vistos:
                    continue
                zona, i = [q], 0
                vistos.add(q)
                while i < len(zona):
                    x, y = zona[i]
                    i += 1
                    for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if r in cand and r not in vistos:
                            vistos.add(r)
                            zona.append(r)
                if sum(1 for r in zona if vivo[cp[r][:3]] >= alto) >= 3:
                    for r in zona:
                        cp[r] = amarillo(cp[r][:3]) + (cp[r][3],)
            sheet.paste(c, caja[:2])
    return sheet
if 'neon' in cfg:
    sheet = neon(sheet, cfg['neon'])
# "cerrar_borde": "#050202" en zombi.json (el vigilante): el contorno de la figura, entero de ese color (el del de
# Johnny). PixelLab lo deja casi siempre negro, pero con huecos del color de al lado (el chaleco, la piel); el dueño lo
# quiso cerrado el 19 nov. Se pintan los píxeles de la figura que tocan el vacío, sin hacerla más grande.
if cfg.get('cerrar_borde'):
    color = tuple(int(cfg['cerrar_borde'][i:i + 2], 16) for i in (1, 3, 5)) + (255,)
    for fy in range(sheet.height // CH):
        for fx in range(sheet.width // CW):
            caja = (fx * CW, fy * CH, (fx + 1) * CW, (fy + 1) * CH)
            c = sheet.crop(caja)
            if not c.getbbox():
                continue
            cp = c.load()
            pintar = [(x, y) for y in range(CH) for x in range(CW) if cp[x, y][3] and max(cp[x, y][:3]) >= 40 and any(
                not (0 <= x + i < CW and 0 <= y + j < CH) or cp[x + i, y + j][3] == 0
                for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
            for q in pintar:
                cp[q] = color
            sheet.paste(c, caja[:2])
guardar_png(sheet, f'assets/sprites/{SPRITE}.png')
json.dump({'cell': [CW, CH], 'pivot': [PX, PY], 'anims': anims,
           'source': f'Hecha con tools/zombi.py a partir de {SRC}/'},
          open(f'assets/sprites/{SPRITE}.json', 'w', encoding='utf-8', newline='\n'), indent=2, ensure_ascii=False)
print('hoja:', sheet.size)

if '--gif' in sys.argv:
    folder = sys.argv[sys.argv.index('--gif') + 1]
    G = 3
    for name, b in blocks:
        n = max(len(fs) for fs in b.values())
        gif = []
        for i in range(n):
            im = Image.new('RGBA', (4 * CW * G, 2 * CH * G), (70, 74, 82, 255))
            for k, d in enumerate(d for d in DIRS if d in b):
                f = b[d][i % len(b[d])]
                im.alpha_composite(f.resize((CW * G, CH * G), Image.NEAREST), ((k % 4) * CW * G, (k // 4) * CH * G))
            gif.append(im.convert('RGB'))
        gif[0].save(f'{folder}/{SPRITE}-{name}.gif', save_all=True, append_images=gif[1:],
                    duration=int(1000 / anims[name]['fps']), loop=0)
    print('GIF guardados en', folder)
