# El escaparate de la farmacia, vacío (17 nov, el dueño): dentro, por detrás del cristal, va uno de sus neones (la cruz o
# la botella: neon_galeria.gd). Para que el neón se vea DETRÁS del cristal, el escaparate se parte en dos:
#   escaparate-farmacia-fondo.png: el marco, el alféizar y el cristal oscuro liso, sin reflejos (se pinta debajo del neón)
#   escaparate-farmacia-cristal.png: solo los reflejos y la grieta del cristal, medio transparentes (se pinta encima)
# Sale de assets/sprites/escaparate-farmacia-vacio.png (de GPT, reducido con tools/muebles_gpt.py escaparate_farmacia).
# Dice también dónde está el hueco del cristal, en píxeles del dibujo (para poner el neón en medio: mapa.gd).
#   py tools/muebles_gpt.py escaparate_farmacia && py tools/escaparate_farmacia.py   (y luego Godot --headless --path . --import)
import sys
import numpy as np
from PIL import Image

TIENDA = sys.argv[1] if len(sys.argv) > 1 else 'farmacia'   # (la ferretería usa el mismo escaparate vacío: py tools/escaparate_farmacia.py ferreteria)
BASE = np.array([0, 19, 24], float)       # el oscuro del cristal, sin reflejo
BRILLO = np.array([70, 150, 160], float)  # el color de los reflejos, a tope (sobre el neón se ven como un velo azulado)

a = np.asarray(Image.open('assets/sprites/escaparate-farmacia-vacio.png').convert('RGBA')).astype(float)
rgb, alfa = a[..., :3], a[..., 3]
# el cristal: lo oscuro y azulado de dentro del marco (el marco y el alféizar son grises y más claros)
oscuro = (rgb[..., 0] < 14) & (rgb[..., 2] > rgb[..., 0] + 4) & (alfa > 0)
filas = np.nonzero(oscuro.sum(axis=1) > oscuro.shape[1] * 0.5)[0]
cols = np.nonzero(oscuro.sum(axis=0) > oscuro.shape[0] * 0.5)[0]
x0, x1, y0, y1 = cols.min(), cols.max() + 1, filas.min(), filas.max() + 1
print(f'cristal: x {x0}-{x1}, y {y0}-{y1} ({x1 - x0}x{y1 - y0}), medio ({(x0 + x1) / 2}, {(y0 + y1) / 2})')

# cuánto reflejo tiene cada píxel del cristal: lo que se aparta del oscuro hacia el color de los reflejos
dentro = np.zeros(oscuro.shape, bool)
dentro[y0:y1, x0:x1] = True
cuanto = np.clip(((rgb - BASE) / (BRILLO - BASE)).mean(axis=2), 0.0, 1.0)
cuanto = np.where(dentro & (cuanto > 0.04), cuanto, 0.0)

fondo = a.copy()
fondo[dentro, :3] = BASE
Image.fromarray(fondo.astype(np.uint8), 'RGBA').save(f'assets/sprites/escaparate-{TIENDA}-fondo.png')

# (el reflejo, algo más fuerte que en el dibujo: sobre lo oscuro apenas se notaba, y encima del neón es lo que lo pone detrás)
cristal = np.zeros_like(a)
cristal[..., :3] = BRILLO
cristal[..., 3] = np.clip(cuanto * 1.3, 0.0, 1.0) * 255.0
Image.fromarray(cristal.astype(np.uint8), 'RGBA').save(f'assets/sprites/escaparate-{TIENDA}-cristal.png')
print(f'escaparate-{TIENDA}-fondo.png y escaparate-{TIENDA}-cristal.png')
