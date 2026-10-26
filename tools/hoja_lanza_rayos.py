# La hoja de Johnny con el lanza rayos: monta con arma.py (el del juego JS) y arregla una cosa que arma.py no sabe de un
# arma blanca y gris: el parpadeo del reposo. De espaldas no hay ojos, y arma.py da por ojos píxeles blancos del arma:
# norte, noreste y noroeste repiten el fotograma de reposo en lugar de parpadear.
# (Hasta la primera versión del 26 oct la hoja llevaba el disparo y unos efectos "fx" rehechos aquí solo con el rayo; el
# lanza rayos echa un rayo continuo dibujado a código —llamarada.gd— y todo eso se quitó. Está en git.)
# Uso (desde la raíz del proyecto):  PYTHONPATH=tools py tools/hoja_lanza_rayos.py
import json
import subprocess
import sys

from PIL import Image

from png import guardar_png

SPRITE = 'conserje-48-lanza-rayos'
ARMA_PY = 'C:/Users/angel/Projects/game/tools/arma.py'

subprocess.run([sys.executable, ARMA_PY, SPRITE], check=True)

meta = json.load(open(f'assets/sprites/{SPRITE}.json', encoding='utf-8'))
CW, CH = meta['cell']
hoja = Image.open(f'assets/sprites/{SPRITE}.png').convert('RGBA')


def casilla(d, i):
    fila = meta['anims']['idle']['dirs'][d]['row']
    return (i * CW, fila * CH, (i + 1) * CW, (fila + 1) * CH)


# el fotograma 12 del reposo (el que parpadea) pasa a ser el 10 (el mismo sin parpadear)
for d in ('north', 'north-east', 'north-west'):
    hoja.paste(hoja.crop(casilla(d, 10)), casilla(d, 12)[:2])
print('reposo de espaldas sin parpadeo')

guardar_png(hoja, f'assets/sprites/{SPRITE}.png')
print('hoja guardada:', hoja.size)
