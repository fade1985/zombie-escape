# El icono de la casilla del cuchillo (assets/ui/tienda/cuchillo.png, 48x48) sacado del dibujo grande de la ficha
# (cuchillo-grande.png, de PixelLab): el mismo cuchillo girado 45 grados y más pequeño. Como girar y encoger un dibujo de
# píxeles lo emborrona, se hace como el RotSprite: se agranda 8 veces sin suavizar, se gira, y se vuelve a encoger
# quedándose en cada píxel con el color que más sale en su trozo (nada de mezclas). Después se le pone el contorno
# oscuro alrededor, como el resto de dibujos. Uso: py cuchillo_diagonal.py [escala]
import sys
from collections import Counter
from PIL import Image

ESCALA = float(sys.argv[1]) if len(sys.argv) > 1 else 0.66
GRANDE = 8
LADO = 48

origen = Image.open("../../ui/tienda/cuchillo-grande.png").convert("RGBA")
origen = origen.crop(origen.getbbox())
grande = origen.resize((origen.width * GRANDE, origen.height * GRANDE), Image.NEAREST)
girado = grande.rotate(45, resample=Image.NEAREST, expand=True)
girado = girado.crop(girado.getbbox())

# cada píxel del dibujo final es un trozo de "paso" x "paso" del girado: el color que más sale (si hay más lleno que vacío)
paso = GRANDE / ESCALA
ancho, alto = int(girado.width / paso), int(girado.height / paso)
px = girado.load()
final = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
for y in range(alto):
    for x in range(ancho):
        cuenta = Counter()
        vacios = 0
        for yy in range(int(y * paso), int((y + 1) * paso)):
            for xx in range(int(x * paso), int((x + 1) * paso)):
                c = px[min(xx, girado.width - 1), min(yy, girado.height - 1)]
                if c[3] == 0:
                    vacios += 1
                else:
                    cuenta[c] += 1
        if cuenta and sum(cuenta.values()) >= vacios:
            final.putpixel((x, y), cuenta.most_common(1)[0][0])

# el contorno: el color más oscuro del dibujo, en los píxeles del borde que tocan lo vacío (sin esquinas)
colores = Counter(c for c in origen.getdata() if c[3] > 0)
oscuro = min(colores, key=lambda c: sum(c[:3]))
borde = final.copy()
fp = final.load()
for y in range(final.height):
    for x in range(final.width):
        if fp[x, y][3] == 0:
            continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < final.width and 0 <= ny < final.height) or fp[nx, ny][3] == 0:
                borde.putpixel((x, y), oscuro)
                break

lienzo = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
lienzo.paste(borde, ((LADO - borde.width) // 2, (LADO - borde.height) // 2), borde)
lienzo.save("intentos/cuchillo-mano.png")
print("tamaño del dibujo:", borde.size)
