"""Baja los fotogramas de una animación de PixelLab uno a uno (cuando el zip de tools/bajar_zip.py da HTTP 423
porque aún hay trabajos en marcha), con las URL que da get_character, y monta una tira para mirarla.

Uso (desde la carpeta del proyecto):
  py tools/bajar_fotogramas.py <fuente> <carpeta> <dirección> <url con {i}> <n>
  (la url tal cual la da get_character, con "{i}" donde va el número; n = último fotograma)
Deja assets/sources/<fuente>/<carpeta>/<dirección>-<i>.png y, en tiras/, <carpeta>-<dirección>.png (a x2).
"""
import os
import subprocess
import sys
from PIL import Image

fuente, carpeta, direccion, url, n = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
ruta = f"assets/sources/{fuente}/{carpeta}"
os.makedirs(ruta, exist_ok=True)
os.makedirs(f"assets/sources/{fuente}/tiras", exist_ok=True)
imagenes = []
for i in range(n + 1):
    destino = f"{ruta}/{direccion}-{i}.png"
    # con curl: PixelLab rechaza las descargas hechas directamente desde Python
    subprocess.run(["curl", "-sSf", "-o", destino, url.replace("{i}", str(i))], check=True)
    imagenes.append(Image.open(destino).convert("RGBA"))
w, h = max(im.width for im in imagenes), max(im.height for im in imagenes)
tira = Image.new("RGBA", (w * len(imagenes), h), (40, 36, 52, 255))
for i, im in enumerate(imagenes):
    tira.alpha_composite(im, (i * w, h - im.height))
tira = tira.resize((tira.width * 2, tira.height * 2), Image.NEAREST)
tira.save(f"assets/sources/{fuente}/tiras/{carpeta}-{direccion}.png")
print(f"{carpeta}/{direccion}: {n + 1} fotogramas de {w}x{h}")
