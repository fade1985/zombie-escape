"""Hace la animación hacia el oeste dando la vuelta a la del este (PixMiniMax, de lado hacia el oeste, se gira
hacia la cámara: con el este en espejo se ahorra la generación). Deja west-<n>.png junto a cada east-<n>.png.

Uso (desde la carpeta del proyecto):
  py tools/espejo_oeste.py bombero-72 walk lanzar hachazo golpe muerte
"""
import os
import sys
from PIL import Image, ImageOps

fuente, carpetas = sys.argv[1], sys.argv[2:]
for carpeta in carpetas:
    ruta = f"assets/sources/{fuente}/{carpeta}"
    hechos = 0
    for nombre in sorted(os.listdir(ruta)):
        if not nombre.startswith("east-") or not nombre.endswith(".png"):
            continue
        im = Image.open(f"{ruta}/{nombre}").convert("RGBA")
        ImageOps.mirror(im).save(f"{ruta}/west-{nombre[5:]}")
        hechos += 1
    print(f"{carpeta}: {hechos} fotogramas hacia el oeste (el este en espejo)")
