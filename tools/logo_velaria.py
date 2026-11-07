# El logo de Velaria Corp. (el que eligió el dueño el 7 nov entre seis ideas de GPT): una luna creciente morada dentro
# de un círculo fino azul marino, porque el VD-7 se vende para dormir. Inventado: nada de Umbrella ni de Resident Evil.
# Sale en pixel art de 16x16 (en el juego, a 2 unidades por píxel: 32x32).
#   py tools/logo_velaria.py   → assets/ui/velaria-logo.png (y capturas/velaria-logo-grande.png, para mirarlo)
from PIL import Image

MARINO = (29, 36, 64, 255)      # el círculo
MORADO = (138, 114, 192, 255)   # la luna
LUZ = (168, 148, 214, 255)      # el borde de fuera de la luna, un poco más claro
LADO = 16

# Dibujado a mano, píxel a píxel: # el círculo, M la luna y L su borde de fuera, más claro
DIBUJO = [
    ".....######.....",
    "...##......##...",
    "..#...LMM....#..",
    ".#...LMM......#.",
    ".#..LMM.......#.",
    "#...LMM........#",
    "#..LMMM........#",
    "#..LMMM........#",
    "#..LMMMM.....L.#",
    "#...MMMMM..LMM.#",
    "#...MMMMMMMM...#",
    ".#...MMMMMM...#.",
    ".#.....MMM....#.",
    "..#..........#..",
    "...##......##...",
    ".....######.....",
]
COLORES = {"#": MARINO, "M": MORADO, "L": LUZ}
im = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
for y, fila in enumerate(DIBUJO):
    assert len(fila) == LADO, fila
    for x, letra in enumerate(fila):
        if letra in COLORES:
            im.putpixel((x, y), COLORES[letra])
im.save("assets/ui/velaria-logo.png")
im.resize((LADO * 16, LADO * 16), Image.NEAREST).save("capturas/velaria-logo-grande.png")
print("assets/ui/velaria-logo.png")
