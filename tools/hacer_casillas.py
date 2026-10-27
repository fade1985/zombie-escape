# Dibuja los marcos de las casillas del HUD (armas y lanzables) en pixel art, con los colores del marco de la
# barra de vida (barra-vida.png): metal morado oscuro con brillo arriba, óxido, remaches de cobre en las
# esquinas y el hueco de dentro hundido. Salen en assets/ui/casilla-<tamaño>.png (se pintan con escala 2).
#   py tools/hacer_casillas.py
import random
from PIL import Image

CONTORNO = (14, 4, 27)
METAL = (69, 51, 59)
BRILLO = (94, 74, 79)
SOMBRA = (48, 43, 53)
OXIDO = (119, 71, 65)
OXIDO2 = (175, 75, 73)
COBRE = (203, 150, 109)
COBRE_OSCURO = (31, 12, 31)
HUECO = (26, 22, 32)
HUECO_SOMBRA = (14, 10, 20)
HUECO_LUZ = (38, 32, 46)

TAMANOS = {"grande": 22, "mediana": 18}   # en píxeles del dibujo (por dentro, 6 menos)


def casilla(n: int, semilla: int) -> Image.Image:
	rnd = random.Random(semilla)
	im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
	p = im.load()
	for y in range(n):
		for x in range(n):
			borde = min(x, y, n - 1 - x, n - 1 - y)
			if borde == 0:
				# contorno, con las esquinas redondeadas
				if (x in (0, n - 1)) and (y in (0, n - 1)):
					continue
				p[x, y] = CONTORNO + (255,)
			elif borde <= 2:
				# el metal: brillo arriba y a la izquierda, sombra abajo y a la derecha
				if y == 1 or x == 1:
					c = BRILLO
				elif y == n - 2 or x == n - 2:
					c = SOMBRA
				else:
					c = METAL
				if rnd.random() < 0.18:
					c = OXIDO if rnd.random() < 0.8 else OXIDO2
				p[x, y] = c + (255,)
			elif borde == 3:
				p[x, y] = CONTORNO + (255,)   # el filo del hueco
			else:
				# el hueco, hundido: sombra arriba e izquierda, un poco de luz abajo
				c = HUECO
				if y == 4 or x == 4:
					c = HUECO_SOMBRA
				elif y == n - 5:
					c = HUECO_LUZ
				p[x, y] = c + (255,)
	# remaches de cobre en las cuatro esquinas del metal
	for (x, y) in [(1, 1), (n - 3, 1), (1, n - 3), (n - 3, n - 3)]:
		p[x, y] = COBRE + (255,)
		p[x + 1, y] = COBRE + (255,)
		p[x, y + 1] = COBRE + (255,)
		p[x + 1, y + 1] = COBRE_OSCURO + (255,)
	return im


if __name__ == "__main__":
	for i, (nombre, n) in enumerate(TAMANOS.items()):
		casilla(n, 7 + i).save(f"assets/ui/casilla-{nombre}.png")
		print(nombre, n)
