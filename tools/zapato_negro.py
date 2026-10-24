"""Arregla un zapato que PixelLab ha dibujado relleno de negro y con un borde gris claro, en un fotograma del andar de la hoja.

  py tools/zapato_negro.py conserje-48-supermaza north 8

Es la hoja de assets/sprites/<sprite>.png: la dirección y el número de fotograma (empezando en 0) de su fila de andar.
Se busca el borde gris claro del zapato (los grises sueltos de abajo) y, dentro de ese rectángulo, el relleno negro (los
píxeles negros con dibujo arriba, abajo y a los lados) se pinta de marrón, y el borde gris, de negro. Es lo que hace
tools/andar_arma.py con 'zapatos_negros', pero solo con Pillow (ese pide numpy) y sobre una hoja ya montada: si se
vuelve a montar la hoja con tools/arma.py, hay que pasarlo otra vez. Saca de nuevo el .tres con tools/hacer_frames.py.
Los colores son los de la hoja de la súper maza (paleta de Johnny con colores libres de PixelLab).
"""
import json, subprocess, sys
from PIL import Image

sprite, direccion, columna = sys.argv[1], sys.argv[2], int(sys.argv[3])
BASE = f"assets/sprites/{sprite}"
GRIS, NEGRO, MARRON = (143, 130, 120), (0, 0, 0), (64, 31, 16)

meta = json.load(open(f"{BASE}.json", encoding="utf-8"))
cw, ch = meta["cell"]
fila = meta["anims"]["walk"]["dirs"][direccion]["row"]
hoja = Image.open(f"{BASE}.png").convert("RGBA")
x0, y0 = columna * cw, fila * ch
casilla = hoja.crop((x0, y0, x0 + cw, y0 + ch))
px = casilla.load()

abajo = casilla.getbbox()[3]   # los zapatos están en las últimas filas del dibujo
grises = [(x, y) for y in range(abajo - 9, abajo) for x in range(cw) if px[x, y][3] and px[x, y][:3] == GRIS]
if not grises:
    sys.exit("no hay borde gris claro en ese fotograma: no hay nada que arreglar")
xa, xb = min(x for x, y in grises), max(x for x, y in grises)
ya, yb = min(y for x, y in grises), max(y for x, y in grises)


def con_dibujo(x, y):
    return 0 <= x < cw and 0 <= y < ch and px[x, y][3] > 0


rellenos = [(x, y) for y in range(ya, yb + 1) for x in range(xa, xb + 1)
            if px[x, y][3] and px[x, y][:3] == NEGRO
            and all(con_dibujo(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
for x, y in rellenos:
    px[x, y] = (*MARRON, 255)
for x, y in grises:
    px[x, y] = (*NEGRO, 255)
hoja.paste(casilla, (x0, y0))
hoja.save(f"{BASE}.png", optimize=True)
print(f"{direccion} fotograma {columna}: {len(rellenos)} píxeles negros pintados de marrón y {len(grises)} grises de borde, de negro")
subprocess.run([sys.executable, "tools/hacer_frames.py", BASE], check=True)
