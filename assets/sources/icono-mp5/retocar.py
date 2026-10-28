# El icono de la MP5: la 2 de las que sacó PixelLab el 27 oct (pixellab-2.png, con los iconos de la pistola y la
# escopeta como modelo de estilo), que eligió el dueño. Se retoca para que vaya a juego con la pistola: cada color
# (y algún puntito rosa u oliva suelto) se cambia por el más parecido de los de la pistola (la de antes, dibujada a mano).
# El contorno negro se queda, como el de la escopeta: con el borde morado de la pistola, tan oscura, se apagaba.
# Antes, la MP5 usaba el icono de la pistola.
# Uso, desde la raíz del proyecto: py assets/sources/icono-mp5/retocar.py   → assets/ui/iconos/mp5.png
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).parent
BORDE = (2, 2, 2, 255)
# Los de la pistola, de oscuro a claro (sin el rojo)
COLORES = [(26, 26, 34), (36, 38, 48), (40, 42, 53), (58, 62, 74), (92, 100, 116), (119, 142, 155),
	(128, 140, 156), (170, 176, 186)]


def parecido(c):
	return min(COLORES, key=lambda p: sum((a - b) ** 2 for a, b in zip(p, c[:3]))) + (255,)


im = Image.open(AQUI / "pixellab-2.png").convert("RGBA")
for y in range(im.height):
	for x in range(im.width):
		c = im.getpixel((x, y))
		if c[3] == 0:
			continue
		im.putpixel((x, y), BORDE if sum(c[:3]) < 20 else parecido(c))
im.save(AQUI.parent.parent / "ui" / "iconos" / "mp5.png")
print("hecho: assets/ui/iconos/mp5.png")
