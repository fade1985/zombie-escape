# El logo de Velaria Corp.: el que eligió el dueño el 7 nov entre seis ideas de GPT (el primero de
# assets/sources/velaria-logos-gpt.png): una luna creciente morada dentro de un círculo azul marino, porque el VD-7 se
# vende para dormir. Inventado: nada de Umbrella ni de Resident Evil.
# Se saca de esa imagen tal cual (dibujado a mano quedaba tosco): se recorta el dibujo y se reduce a LADO x LADO
# píxeles, cada uno con uno de los colores del logo (marino, morado o nada), sin grises ni bordes borrosos.
#   py tools/logo_velaria.py   → assets/ui/velaria-logo.png (y capturas/velaria-logo-grande.png, para mirarlo)
import sys
from PIL import Image

ORIGEN = "assets/sources/velaria-logos-gpt.png"
RECORTE = (136, 43, 413, 317)   # el primer logo (el círculo entero), sin las letras de debajo
LADO = int(sys.argv[1]) if len(sys.argv) > 1 else 24   # (en la hoja, a 2 unidades por píxel: 48)
MARINO = (24, 30, 58)
MORADO = (140, 115, 190)
PAPEL = (250, 246, 238)

hoja = Image.open(ORIGEN).convert("RGB").crop(RECORTE)
w, h = hoja.size
cuadro = Image.new("RGB", (max(w, h),) * 2, PAPEL)   # cuadrado, con papel en lo que sobre
cuadro.paste(hoja, ((max(w, h) - w) // 2, (max(w, h) - h) // 2))
# primero cada píxel de la imagen grande a su color, y luego cada píxel pequeño, el que más tenga de su cuadrito (el
# marino gana con menos, para que el círculo, que es fino, no se corte)
def color_de(r, g, b):
    return min([MARINO, MORADO, PAPEL], key=lambda c: (c[0] - r) ** 2 + (c[1] - g) ** 2 + (c[2] - b) ** 2)
grande = cuadro.load()
lado_grande = cuadro.size[0]
logo = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
for y in range(LADO):
    for x in range(LADO):
        cuenta = {MARINO: 0, MORADO: 0, PAPEL: 0}
        for yy in range(y * lado_grande // LADO, (y + 1) * lado_grande // LADO):
            for xx in range(x * lado_grande // LADO, (x + 1) * lado_grande // LADO):
                cuenta[color_de(*grande[xx, yy])] += 1
        total = sum(cuenta.values())
        if cuenta[MARINO] > total * 0.3:
            logo.putpixel((x, y), MARINO + (255,))
        elif cuenta[MORADO] > total * 0.5:
            logo.putpixel((x, y), MORADO + (255,))
logo.save("assets/ui/velaria-logo.png")
logo.resize((LADO * 8, LADO * 8), Image.NEAREST).save("capturas/velaria-logo-grande.png")
print("assets/ui/velaria-logo.png", LADO)
