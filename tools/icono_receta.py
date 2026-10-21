# Dibuja assets/ui/iconos/receta.png (16×16): la hoja de una receta del banco de trabajo, la que sueltan los
# jefes al morir (partida.gd, soltar_receta). Papel amarillento con la esquina doblada, unas rayas de letra y un
# sello rojo. Se ejecuta con:  py tools/icono_receta.py
from PIL import Image

PAPEL = (232, 220, 188, 255)
SOMBRA = (176, 160, 124, 255)
BORDE = (58, 50, 38, 255)
TINTA = (90, 78, 64, 255)
ROJO = (192, 57, 43, 255)

im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
px = im.load()
# la hoja: de x 2 a 13, de y 1 a 14, con la esquina de arriba a la derecha doblada
for y in range(1, 15):
	for x in range(2, 14):
		if x - 9 > y - 1:   # la esquina cortada
			continue
		borde = x in (2, 13) or y in (1, 14) or x - 9 == y - 1
		px[x, y] = BORDE if borde else PAPEL
# el pico doblado
for y in range(2, 5):
	for x in range(10, 13):
		if x - 9 <= y - 1:
			px[x, y] = SOMBRA
px[10, 5] = BORDE
px[11, 5] = BORDE
px[12, 5] = BORDE
px[10, 1] = BORDE
# las rayas de letra
for y in (4, 6):
	for x in range(4, 9):
		px[x, y] = TINTA
for y in (9, 11):
	for x in range(4, 12):
		px[x, y] = TINTA
# un sello rojo abajo a la derecha
for (x, y) in [(10, 12), (11, 12), (10, 13), (11, 13)]:
	px[x, y] = ROJO
im.save("assets/ui/iconos/receta.png")
print("assets/ui/iconos/receta.png")
