# La puerta de la ferretería (17 nov, el dueño): de cristal, de una sola hoja, con un cartel «OPEN» colgado por DETRÁS del
# cristal. Junta los dos dibujos de GPT (muebles_gpt.py puerta_ferreteria cartel_open): el cristal oscuro liso, el cartel
# encima y, por encima de todo, los reflejos del cristal (así el cartel se ve detrás). Sale assets/sprites/puerta-ferreteria.png.
#   py tools/muebles_gpt.py puerta_ferreteria cartel_open && py tools/puerta_ferreteria.py   (y luego Godot --headless --path . --import)
import numpy as np
from PIL import Image

BASE = np.array([0, 10, 12], float)       # el oscuro del cristal, sin reflejo
BRILLO = np.array([70, 150, 160], float)  # el color de los reflejos, a tope

puerta = Image.open('assets/sprites/puerta-ferreteria-entera.png').convert('RGBA')
cartel = Image.open('assets/sprites/cartel-open.png').convert('RGBA')
a = np.asarray(puerta).astype(float)
rgb, alfa = a[..., :3], a[..., 3]
# el cristal: lo oscuro y azulado de dentro del marco (el marco, las bisagras y la manilla son grises y más claros)
oscuro = (rgb[..., 0] < 40) & (rgb[..., 2] >= rgb[..., 0]) & (alfa > 0)
filas = np.nonzero(oscuro.sum(axis=1) > oscuro.shape[1] * 0.4)[0]
cols = np.nonzero(oscuro.sum(axis=0) > oscuro.shape[0] * 0.4)[0]
x0, x1, y0, y1 = cols.min(), cols.max() + 1, filas.min(), filas.max() + 1
print(f'cristal: x {x0}-{x1}, y {y0}-{y1}')
dentro = np.zeros(oscuro.shape, bool)
dentro[y0:y1, x0:x1] = oscuro[y0:y1, x0:x1]
cuanto = np.clip(((rgb - BASE) / (BRILLO - BASE)).mean(axis=2), 0.0, 1.0)
cuanto = np.where(dentro & (cuanto > 0.08), cuanto, 0.0)

fondo = a.copy()
fondo[dentro, :3] = BASE
base = Image.fromarray(fondo.astype(np.uint8), 'RGBA')
# el cartel, colgado arriba en medio del cristal
cx = (x0 + x1) // 2 - cartel.width // 2
base.alpha_composite(cartel, (cx, y0 + 3))
# los reflejos, por encima
cristal = np.zeros_like(a)
cristal[..., :3] = BRILLO
cristal[..., 3] = np.clip(cuanto * 1.3, 0.0, 1.0) * 255.0
base.alpha_composite(Image.fromarray(cristal.astype(np.uint8), 'RGBA'))
base.save('assets/sprites/puerta-ferreteria.png')
print('puerta-ferreteria.png', base.size)
