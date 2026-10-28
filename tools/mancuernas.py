"""Saca el dibujo de la mancuerna del suelo del gimnasio del Gymbro (M21).

La dibujó PixelLab (16x16, paleta cerrada de grises azulados; ver "mancuernas-suelo" en assets/pixellab.json):
assets/sources/mancuernas/intentos/mancuerna-D.png. De ahí, recortada al borde:
  - assets/sprites/mancuerna.png: la mancuerna tumbada, de 14 x 9 píxeles. La pintan peligros/tropiezos.gd (las del
    suelo) y pesa.gd (las que lanza el Gymbro), que la giran si hace falta.

Uso (desde la carpeta del proyecto):
  py tools/mancuernas.py
"""
from PIL import Image

ORIGEN = 'assets/sources/mancuernas/intentos/mancuerna-D.png'


def main():
    dibujo = Image.open(ORIGEN).convert('RGBA')
    dibujo = dibujo.crop(dibujo.getbbox())
    dibujo.save('assets/sprites/mancuerna.png')
    print('mancuerna.png', dibujo.size)


main()
