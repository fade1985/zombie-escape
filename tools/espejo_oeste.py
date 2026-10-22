"""Hace la animación hacia el oeste dando la vuelta a la del este (PixMiniMax, de lado hacia el oeste, se gira
hacia la cámara: con el este en espejo se ahorra la generación). Deja west-<n>.png junto a cada east-<n>.png.

Uso (desde la carpeta del proyecto):
  py tools/espejo_oeste.py bombero-72 walk lanzar hachazo golpe muerte
  py tools/espejo_oeste.py --lado cientifico-jefe-128 rotations walk probetas
    (con --lado, también south-west y north-west a partir de south-east y north-east: todo el lado izquierdo
    en espejo, y en "rotations" las vistas quietas west.png, south-west.png y north-west.png, para que casen)
"""
import os
import sys
from PIL import Image, ImageOps

args = sys.argv[1:]
lado = "--lado" in args
if lado:
    args.remove("--lado")
fuente, carpetas = args[0], args[1:]
PARES = {"east": "west"}
if lado:
    PARES.update({"south-east": "south-west", "north-east": "north-west"})
for carpeta in carpetas:
    ruta = f"assets/sources/{fuente}/{carpeta}"
    hechos = 0
    for nombre in sorted(os.listdir(ruta)):
        for de, a in PARES.items():
            if nombre == f"{de}.png" or nombre.startswith(f"{de}-") and nombre.endswith(".png"):
                im = Image.open(f"{ruta}/{nombre}").convert("RGBA")
                ImageOps.mirror(im).save(f"{ruta}/{a}{nombre[len(de):]}")
                hechos += 1
    print(f"{carpeta}: {hechos} fotogramas hacia el oeste (el este en espejo)")
