# La hoja de Johnny con el lanza rayos: monta con arma.py (el del juego JS) y arregla dos cosas que arma.py no sabe de un
# arma blanca y gris con una franja de luz celeste:
#   1. Los efectos "fx" (lo que se pinta encima del andar al disparar andando). arma.py toma por efecto todo lo blanco
#      puro, y el arma lo es en parte: salían líneas blancas de su contorno y algún punto naranja. Aquí los efectos son
#      solo lo celeste y lo blanco del rayo (destello y chispas), fuera del dibujo quieto de Johnny con su arma, y los
#      trozos pequeños pegados al cuerpo se tiran.
#   2. El parpadeo del reposo: de espaldas no hay ojos, y arma.py da por ojos píxeles blancos del arma. Norte, noreste y
#      noroeste repiten el fotograma de reposo en lugar de parpadear.
# Uso (desde la raíz del proyecto):  PYTHONPATH=tools py tools/hoja_lanza_rayos.py
import json
import os
import subprocess
import sys

from PIL import Image, ImageFilter

from png import guardar_png

SPRITE = 'conserje-48-lanza-rayos'
ARMA_PY = 'C:/Users/angel/Projects/game/tools/arma.py'
MARGEN = 9   # a cuántos píxeles del dibujo quieto cuenta como "lejos del cuerpo" (el margen_efectos de arma.json)
MINIMO = 30  # un trozo de efecto pegado al cuerpo solo vale si tiene al menos estos píxeles

subprocess.run([sys.executable, ARMA_PY, SPRITE], check=True)

meta = json.load(open(f'assets/sprites/{SPRITE}.json', encoding='utf-8'))
CW, CH = meta['cell']
hoja = Image.open(f'assets/sprites/{SPRITE}.png').convert('RGBA')
DIRS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']


def casilla(anim, d, i):
    fila = meta['anims'][anim]['dirs'][d]['row'] if anim != 'still' else 0
    col = i if anim != 'still' else DIRS.index(d)
    return (col * CW, fila * CH, (col + 1) * CW, (fila + 1) * CH)


def celeste(c):
    return c[2] > 150 and c[2] - c[0] > 70 and c[1] - c[0] > 60


def blanco(c):
    return min(c[:3]) > 205 and max(c[:3]) - min(c[:3]) < 40


def efectos(frame, quieto):
    """Solo el rayo: lo celeste y lo blanco que no es el dibujo quieto, en trozos pegados que llegan lejos del cuerpo
    o son grandes."""
    cuerpo = quieto.getchannel('A').point(lambda v: 255 if v else 0)
    cerca = cuerpo.filter(ImageFilter.MaxFilter(2 * MARGEN + 1))
    cp, cc, fp = cuerpo.load(), cerca.load(), frame.load()
    cand = {(x, y) for y in range(CH) for x in range(CW)
            if fp[x, y][3] and not cp[x, y] and (celeste(fp[x, y]) or blanco(fp[x, y]))}
    out = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    dst = out.load()
    borde = set()
    resto = set(cand)
    while resto:
        grupo, pila = set(), [resto.pop()]
        while pila:
            q = pila.pop()
            grupo.add(q)
            for n in ((q[0] + a, q[1] + b) for a in (-1, 0, 1) for b in (-1, 0, 1)):
                if n in resto:
                    resto.discard(n)
                    pila.append(n)
        if len(grupo) >= MINIMO or any(not cc[q] for q in grupo):
            for q in grupo:
                dst[q] = fp[q]
    # el borde oscuro del rayo (un píxel alrededor) no es ni celeste ni blanco: sin él, el rayo sale agujereado
    for y in range(CH):
        for x in range(CW):
            if dst[x, y][3]:
                for n in ((x + a, y + b) for a in (-1, 0, 1) for b in (-1, 0, 1)):
                    if 0 <= n[0] < CW and 0 <= n[1] < CH and fp[n][3] and not dst[n][3] and not cp[n]:
                        borde.add(n)
    for q in borde:
        dst[q] = fp[q]
    return out


# 1. efectos
for d in DIRS:
    quieto = hoja.crop(casilla('still', d, 0))
    a = meta['anims']['fx']['dirs'][d]
    for i in range(a['frames']):
        ataque = hoja.crop(casilla('attack', d, i))
        box = casilla('fx', d, i)
        hoja.paste((0, 0, 0, 0), box)
        hoja.alpha_composite(efectos(ataque, quieto), (box[0], box[1]))
print('efectos rehechos: solo el rayo celeste y blanco')

# 2. parpadeo de espaldas: el fotograma 12 del reposo (el que parpadea) pasa a ser el 10 (el mismo sin parpadear)
for d in ('north', 'north-east', 'north-west'):
    hoja.paste(hoja.crop(casilla('idle', d, 10)), casilla('idle', d, 12)[:2])
print('reposo de espaldas sin parpadeo')

guardar_png(hoja, f'assets/sprites/{SPRITE}.png')
print('hoja guardada:', hoja.size)
