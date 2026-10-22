"""Monta la hoja de sprites de un superviviente (policía, médica, militar, ferretero, farmacéutica o técnico) con lo que
da PixelLab.

Lo saca todo de assets/sources/superviviente-<id>-48/:
  rotations/<dirección>.png     las 8 posturas quietas (48×48)
  walk/<dirección>-<n>.png      andar (plantilla walking-8-frames: 8 fotogramas, sin el quieto)
  accion/<dirección>-<n>.png    lo suyo (disparo, ráfaga, cura, martillazo o descarga): PixMiniMax, el fotograma 0 es el
                                quieto (lienzo de 96 o más). Opcional: la farmacéutica no tiene (lo suyo no tiene gesto)
  caido/south-<n>.png           se desploma (solo mirando al sur): el fotograma 0 es el quieto y el último, tumbado
  superviviente.json (opcional) ajustes: "cuello" {dirección: fila desde lo alto de la cabeza}, "ojos" [desde, hasta]
                                (filas desde lo alto de la cabeza donde buscar los ojos), "sin_tinte" {dirección: [n...]},
                                "golpe" {dirección: n} (a mano, en qué fotograma de la acción, de 1 a 8, llega lo suyo)

Y escribe assets/sprites/superviviente-<id>.png y .json con cinco animaciones (y hacer_frames.py las pasa a .tres):
  still   las 8 posturas quietas
  idle    reposo a mano, como el de Johnny (tools/idle.py del JS): respiración de 1 píxel y un parpadeo,
          20 fotogramas a 5 por segundo. PixelLab redibuja la cara en cada fotograma y a 48 píxeles "baila".
  walk    andar: colores igualados a los del dibujo quieto y pies a su altura (como tools/walk.py del JS)
  attack  la acción, 8 fotogramas; "hit": en qué punto (de 0 a 1) está el fogonazo (el pinchazo, el martillazo o el
          chispazo de la descarga), y en el JSON
          "muzzle": dónde está la boca del arma en cada dirección (respecto a los pies, en píxeles del dibujo)
  fall    caerse (solo south, que es como el juego los tumba): no se repite, se queda en el último fotograma
Casilla de 96×96 con los pies en (48, 78): el dibujo quieto va en (24, 32), como los zombis (tools/zombi.py).
Las animaciones a medida vienen en lienzos distintos según la dirección (PixelLab lo agranda alrededor del
movimiento): cada tira se coloca por su fotograma 0, que es el dibujo quieto.

Uso (desde la carpeta del proyecto; necesita Python con Pillow):
  py tools/superviviente.py policia                 rehace assets/sprites/superviviente-policia.png y .json
  py tools/superviviente.py policia --gif carpeta   además guarda GIF de comprobación y la vista previa del reposo
"""
import json, os, sys
from PIL import Image, ImageChops
from png import guardar_png  # guarda la hoja comprimida sin perder nada

ID = sys.argv[1]
DIRS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
SRC = f'assets/sources/superviviente-{ID}-48'
OUT = f'assets/sprites/superviviente-{ID}'
cfg = json.load(open(f'{SRC}/superviviente.json', encoding='utf-8')) if os.path.exists(f'{SRC}/superviviente.json') else {}
CW, CH = 96, 96          # la casilla
PX, PY = 48, 78          # los pies dentro de la casilla
FX, FY = 24, 46          # los pies en el dibujo quieto de 48×48 (la última fila con píxeles)
OX, OY = PX - FX, PY - FY   # (24, 32): dónde va el dibujo quieto dentro de la casilla
IDLE_FPS, WALK_FPS, ATK_FPS, FALL_FPS = 5, 12, 15, 12
TIRADOR = ID in ('policia', 'militar')   # lleva un arma de fuego: fogonazo que limpiar y boca que buscar

rot = {d: Image.open(f'{SRC}/rotations/{d}.png').convert('RGBA') for d in DIRS}


def cell(im, x=0, y=0):
    """Una casilla vacía con `im` pegada en (x, y) respecto al sitio del dibujo quieto."""
    c = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    c.paste(im, (OX + x, OY + y), im)   # lo que se salga de la casilla se recorta
    return c


def load(folder, d):
    """Fotogramas <dirección>-<n>.png con n seguido desde 0."""
    fs = []
    while os.path.exists(f'{SRC}/{folder}/{d}-{len(fs)}.png'):
        fs.append(Image.open(f'{SRC}/{folder}/{d}-{len(fs)}.png').convert('RGBA'))
    return fs


def seen(im):
    """Solo lo que se ve: bajo los píxeles transparentes PixelLab a veces deja otro color."""
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), im)
    return out.tobytes()


def offset(fs, d, folder):
    """El fotograma 0 es el dibujo quieto: comparándolos se sabe cuánto está desplazado todo en ese lienzo."""
    a, b = fs[0].getbbox(), rot[d].getbbox()
    ox, oy = a[0] - b[0], a[1] - b[1]
    same = seen(fs[0].crop((ox, oy, ox + rot[d].width, oy + rot[d].height))) == seen(rot[d])
    assert same, f'el fotograma 0 de {folder}/{d} no coincide con el dibujo quieto'
    return ox, oy


def placed(f, ox, oy, d, n, folder):
    """El fotograma en su casilla (colocado como el quieto), avisando si algo se queda fuera."""
    b = f.getbbox()
    if b and (b[0] - ox + OX < 0 or b[1] - oy + OY < 0 or b[2] - ox + OX > CW or b[3] - oy + OY > CH):
        print(f'  OJO: el fotograma {n} de {folder}/{d} se sale de la casilla')
    return cell(f, -ox, -oy)


def same_colors(im, ref):
    """Pinta el fotograma solo con los colores del dibujo quieto de esa dirección (el más parecido a cada uno).
    PixelLab redibuja al personaje y los tonos se le van un poco; así, al echar a andar no cambia de color."""
    palette = [c[:3] for _, c in ref.getcolors(4096) if c[3]]
    cache = {}
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a < 128:
                px[x, y] = (0, 0, 0, 0)
                continue
            key = (r, g, b)
            if key not in cache:
                cache[key] = min(palette, key=lambda p: 3 * (p[0] - r) ** 2 + 6 * (p[1] - g) ** 2 + (p[2] - b) ** 2)
            px[x, y] = (*cache[key], 255)
    return out


still = {d: cell(rot[d]) for d in DIRS}

# ═════════════ Reposo: respiración de 1 píxel y parpadeo (tools/idle.py y arma.py del JS) ═════════════
HEAD = range(PX - 5, PX + 6)   # columnas del centro de la cabeza (el fusil a la espalda asoma por un lado)


def rows(im):
    return [im.crop((0, y, CW, y + 1)) for y in range(CH)]


def from_rows(rs):
    out = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    for y, r in enumerate(rs[:CH]):
        out.paste(r, (0, y))
    return out


# Fila del cuello contando desde lo más alto de la cabeza: las de Johnny (miden lo mismo que él). De frente la
# barbilla tapa el cuello, así que la fila que se encoge y se estira es la del cuello de la camisa, nunca la cara
NECK = {'south': 13, 'south-east': 13, 'south-west': 13, 'east': 14, 'west': 14,
        'north': 12, 'north-east': 12, 'north-west': 12} | cfg.get('cuello', {})


def anatomy(im, d):
    """Fila más alta de la cabeza (pelo, gorra o casco), fila del cuello y fila de la cintura."""
    px = im.load()
    top = min(y for y in range(CH) for x in HEAD if px[x, y][3])
    neck = top + NECK[d]
    return top, neck, neck + 11


def poses(im, d):
    """Reposo, pecho arriba, todo arriba y pecho abajo con la cabeza aún arriba (cada una mueve un píxel)."""
    _, neck, waist = anatomy(im, d)
    r = rows(im)
    chest = from_rows(r[:neck] + r[neck + 1:waist + 1] + [r[waist]] + r[waist + 1:])
    full = from_rows(r[1:waist + 1] + [r[waist]] + r[waist + 1:])
    out = from_rows(r[1:neck + 1] + [r[neck]] + r[neck + 1:])
    return im, chest, full, out


def eyes(im, d):
    """Píxeles blancos de los ojos: solo en la cara (la bata, el fonendo y las vendas también son blancos) y solo
    si hay al menos dos en la misma fila (los dos ojos). A estos tres PixelLab no les pintó blanco en los ojos,
    así que no parpadean: su reposo es solo la respiración."""
    top = anatomy(im, d)[0]
    a, b = cfg.get('ojos', [4, 10])
    px = im.load()
    found = []
    for y in range(top + a, top + b + 1):
        for x in range(PX - 8, PX + 9):
            r, g, b_, a_ = px[x, y]
            if a_ and min(r, g, b_) > 190 and max(r, g, b_) - min(r, g, b_) < 45:
                found.append((x, y))
    filas = {y for _, y in found}
    return [p for p in found if sum(1 for q in found if q[1] == p[1]) >= 2 and p[1] in filas]


def blink(im, d):
    """Ojos cerrados: el blanco se tapa con el párpado (piel algo más oscura) y el iris de al lado queda en una
    rayita oscura, como las pestañas."""
    out = im.copy()
    src, px = im.load(), out.load()
    luma = lambda c: (c[0] * 3 + c[1] * 6 + c[2]) / 10
    for x, y in eyes(im, d):
        sy = y + 1   # la piel más cercana por debajo del ojo
        while sy < CH - 1 and (src[x, sy][3] == 0 or min(src[x, sy][:3]) > 190 or luma(src[x, sy]) < 120):
            sy += 1
        r, g, b, a = src[x, sy]
        px[x, y] = (int(r * 0.84), int(g * 0.78), int(b * 0.76), 255)
        for nx in (x - 1, x + 1):
            if 30 < luma(src[nx, y]) < 120 and src[nx, y][3]:
                px[nx, y] = (int(r * 0.45), int(g * 0.36), int(b * 0.34), 255)
    return out


# 20 fotogramas a 5 por segundo: dos respiraciones y un parpadeo en la segunda
#   R reposo · C pecho arriba · F todo arriba · O soltando aire · en minúscula, con los ojos cerrados
CYCLE = 'RRRRCFFFOR' + 'RRrRCFFFOR'
idle = {}
for d in DIRS:
    R, C, F, O = poses(still[d], d)
    table = {'R': R, 'C': C, 'F': F, 'O': O, 'r': blink(R, d)}
    idle[d] = [table[c] for c in CYCLE]
    top, neck, waist = anatomy(still[d], d)
    ojos = eyes(still[d], d)
    print(f'reposo {d:11s} cabeza en la fila {top}, cuello {neck}, cintura {waist}, píxeles de ojo {len(ojos)}'
          + (f' en filas {sorted({y - top for _, y in ojos})}' if ojos else ''))

# ═════════════ Andar: la plantilla da 8 fotogramas de 48×48 (sin el quieto) ═════════════
walk = {}
for d in DIRS:
    fs = [same_colors(f, rot[d]) for f in load('walk', d)]
    assert len(fs) == 8, f'faltan fotogramas de andar en {d}'
    # pies al nivel del dibujo quieto y centrado en horizontal según el primer fotograma (tools/walk.py del JS)
    ref, b0 = rot[d].getbbox(), fs[0].getbbox()
    feet = max(f.getbbox()[3] for f in fs)
    dx = round(((ref[0] + ref[2]) - (b0[0] + b0[2])) / 2)
    dy = ref[3] - feet
    walk[d] = [cell(f, dx, dy) for f in fs]
    print(f'andar  {d:11s} {len(fs)} fotogramas, desplazados ({dx}, {dy})')

# ═════════════ Acción: el fotograma 0 es el quieto; se usan los 8 siguientes ═════════════
fire = lambda p: p[3] and p[0] > 200 and p[2] < 130 and p[0] - p[2] > 90   # amarillo y naranja del fogonazo


def untint(f, d, ox, oy, force=None):
    """A veces PixelLab pinta al personaje entero de amarillo en el fotograma del fogonazo, como si lo iluminara.
    Si pasa, se deja el dibujo quieto y solo se conserva el fogonazo (los píxeles de color fuego pegados a su
    punta). Lo detecta mirando las piernas, que al disparar no se mueven; `force` lo manda a mano."""
    r = rot[d]
    fp, rp = f.load(), r.load()
    body = lambda x, y: 0 <= x - ox < r.width and 0 <= y - oy < r.height and rp[x - ox, y - oy][3]
    legs = [(fp[x, y], rp[x - ox, y - oy]) for y in range(oy + FY - 14, min(f.height, oy + FY + 1))
            for x in range(f.width) if fp[x, y][3] and body(x, y)]
    changed = sum(1 for a, b in legs if sum(abs(a[i] - b[i]) for i in range(3)) > 90)
    if force is False or not legs or (force is None and changed < 0.5 * len(legs)):
        return f, False
    cand = {(x, y) for y in range(f.height) for x in range(f.width)
            if not body(x, y) and (fire(fp[x, y]) or (fp[x, y][3] and min(fp[x, y][:3]) > 225))}
    if not cand:
        return f, False
    cx, cy = ox + FX, oy + FY - 24
    tip = max(cand, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
    keep, todo = {tip}, [tip]
    while todo:
        x, y = todo.pop()
        for n in ((x + i, y + j) for i in (-1, 0, 1) for j in (-1, 0, 1)):
            if n in cand and n not in keep and (n[0] - tip[0]) ** 2 + (n[1] - tip[1]) ** 2 <= 16 ** 2:
                keep.add(n)
                todo.append(n)
    out = Image.new('RGBA', f.size, (0, 0, 0, 0))
    out.paste(r, (ox, oy), r)
    px = out.load()
    for p in keep:
        px[p] = fp[p]
    return out, True


def flash(f, d):
    """Píxeles de fogonazo fuera de la silueta quieta (a veces el fogonazo tiñe al personaje entero)."""
    px, body = f.load(), still[d].load()
    return [(x, y) for y in range(CH) for x in range(CW) if px[x, y][3] and not body[x, y][3] and fire(px[x, y])]


def green(f, d):
    """Las chispas verdes de la jeringa de la médica, fuera de la silueta quieta."""
    px, body = f.load(), still[d].load()
    return [(x, y) for y in range(CH) for x in range(CW)
            if px[x, y][3] and not body[x, y][3] and px[x, y][1] > 170 and px[x, y][1] - max(px[x, y][0], px[x, y][2]) > 60]


def spark(f, d):
    """El chispazo blanco del martillazo o el celeste del aparato del técnico, fuera de la silueta quieta."""
    px, body = f.load(), still[d].load()
    return [(x, y) for y in range(CH) for x in range(CW)
            if px[x, y][3] and not body[x, y][3] and min(px[x, y][1:3]) > 200 and px[x, y][2] >= px[x, y][0] - 10]


TINT = cfg.get('sin_tinte')   # a mano: en qué fotogramas de cada dirección se quita el tinte amarillo
attack, muzzle, hits = {}, {}, {}
for d in (DIRS if os.path.isdir(f'{SRC}/accion') else []):
    fs = load('accion', d)
    assert len(fs) == 9, f'la acción de {d} debería tener 9 fotogramas (el quieto y 8 más)'
    ox, oy = offset(fs, d, 'accion')
    fixed = []
    if TIRADOR:
        for n in range(1, 9):
            fs[n], touched = untint(fs[n], d, ox, oy, None if TINT is None else n in TINT.get(d, []))
            if touched:
                fixed.append(n)
    attack[d] = [placed(fs[n], ox, oy, d, n, 'accion') for n in range(1, 9)]
    # en qué fotograma (de los 8 usados) se ve el fogonazo (o las chispas): ahí sale la bala (o cura)
    marks = [flash(f, d) if TIRADOR else green(f, d) if ID == 'medica' else spark(f, d) for f in attack[d]]
    hits[d] = cfg['golpe'][d] - 1 if d in cfg.get('golpe', {}) else max(range(8), key=lambda i: len(marks[i]))
    if TIRADOR:
        pts = marks[hits[d]]
        assert len(pts) >= 6, f'no encuentro el fogonazo de {d}'
        # de esos píxeles, la mitad más alejada del cuerpo: la punta del fogonazo, no lo que roza las manos
        pts.sort(key=lambda p: -((p[0] - PX) ** 2 + (p[1] - (PY - 24)) ** 2))
        pts = pts[:max(6, len(pts) // 2)]
        muzzle[d] = [round(sum(p[0] for p in pts) / len(pts)) - PX, round(sum(p[1] for p in pts) / len(pts)) - PY]
    print(f'accion {d:11s} lienzo {fs[0].size}, desplazado ({ox}, {oy}), fogonazo en el fotograma {hits[d] + 1} de 8'
          + (f', boca en {muzzle[d]}' if TIRADOR else '') + (f'; sin el tinte amarillo: {fixed}' if fixed else ''))

# ═════════════ Caído: solo mirando al sur; el fotograma 0 es el quieto ═════════════
fs = load('caido', 'south')
assert len(fs) == 9, 'el caído debería tener 9 fotogramas (el quieto y 8 más)'
ox, oy = offset(fs, 'south', 'caido')
fall = {'south': [placed(fs[n], ox, oy, 'south', n, 'caido') for n in range(1, 9)]}
print(f'caido  south       lienzo {fs[0].size}, desplazado ({ox}, {oy}), 8 fotogramas; se queda en el último')

# ═════════════ Hoja y JSON ═════════════
blocks = [(n, b) for n, b in [('idle', idle), ('walk', walk), ('attack', attack), ('fall', fall)] if b]
cols = max(len(DIRS), *(len(fs) for _, b in blocks for fs in b.values()))
rows_total = 1 + sum(len(b) for _, b in blocks)
sheet = Image.new('RGBA', (cols * CW, rows_total * CH), (0, 0, 0, 0))
for i, d in enumerate(DIRS):
    sheet.alpha_composite(still[d], (i * CW, 0))
anims = {'still': {'fps': 1, 'loop': True, 'dirs': {d: {'row': 0, 'col': i, 'frames': 1} for i, d in enumerate(DIRS)}}}
row = 1
for name, b in blocks:
    dirs = {}
    for d in [x for x in DIRS if x in b]:
        for i, f in enumerate(b[d]):
            sheet.alpha_composite(f, (i * CW, row * CH))
        dirs[d] = {'row': row, 'frames': len(b[d])}
        row += 1
    fps = {'idle': IDLE_FPS, 'walk': WALK_FPS, 'attack': ATK_FPS, 'fall': FALL_FPS}[name]
    anims[name] = {'fps': fps, 'loop': name in ('idle', 'walk'), 'dirs': dirs}
# en qué punto de la acción (de 0 a 1) llega el fogonazo o el pinchazo (el juego saca la bala o cura ahí)
if attack:
    anims['attack']['hit'] = round(hits['east'] / 8, 3)
    anims['attack']['hits'] = {d: hits[d] + 1 for d in DIRS}
guardar_png(sheet, f'{OUT}.png')
meta = {'cell': [CW, CH], 'pivot': [PX, PY], 'anims': anims,
        'source': f'Hecha con tools/superviviente.py a partir de {SRC}/'}
if muzzle:
    meta['muzzle'] = muzzle
json.dump(meta, open(f'{OUT}.json', 'w', encoding='utf-8', newline='\n'), indent=2, ensure_ascii=False)
print('hoja:', sheet.size, '→', f'{OUT}.png')
if muzzle:
    print('bocas (para aliado.gd):', ', '.join(f'"{d}": Vector2({x}, {y})' for d, (x, y) in muzzle.items()))

if '--gif' in sys.argv:
    folder = sys.argv[sys.argv.index('--gif') + 1]
    G = 3
    # las posturas del reposo, ampliadas, para ver que respira por el cuello y parpadea con los ojos
    keys = ['R', 'C', 'F', 'O', 'r']
    prev = Image.new('RGBA', (len(keys) * CW * G, len(DIRS) * CH * G), (70, 74, 82, 255))
    for r, d in enumerate(DIRS):
        for c, k in enumerate(keys):
            f = idle[d][CYCLE.index(k)]
            prev.alpha_composite(f.resize((CW * G, CH * G), Image.NEAREST), (c * CW * G, r * CH * G))
    prev.save(f'{folder}/superviviente-{ID}-reposo.png')
    for name, b in blocks:
        ds = [d for d in DIRS if d in b]
        n = max(len(b[d]) for d in ds)
        gif = []
        for i in range(n):
            im = Image.new('RGBA', (min(4, len(ds)) * CW * G, -(-len(ds) // 4) * CH * G), (70, 74, 82, 255))
            for k, d in enumerate(ds):
                f = b[d][min(i, len(b[d]) - 1)]
                im.alpha_composite(f.resize((CW * G, CH * G), Image.NEAREST), ((k % 4) * CW * G, (k // 4) * CH * G))
            gif.append(im.convert('RGB'))
        gif[0].save(f'{folder}/superviviente-{ID}-{name}.gif', save_all=True, append_images=gif[1:],
                    duration=int(1000 / anims[name]['fps']), loop=0)
    print('GIF y vista previa del reposo guardados en', folder)
