# El suelo y la pared del vestuario de la sala de mantenimiento, como los de la foto del dueño (8 nov): azulejo blanco
# cuadrado en la pared, de suelo a techo, y baldosa cuadrada beis en el suelo, los dos con su junta. Dibujados aquí, píxel a
# píxel (una cuadrícula limpia: reducida de una imagen, las juntas, de un píxel, saldrían a trozos), con los colores de la foto,
# un poco de diferencia entre piezas y grano dentro de cada una, para que no parezcan de plástico.
#   pared → assets/sprites/pared-vestuario.png  (480x48: 6 filas de azulejos de 8; empalma a izquierda y derecha)
#   suelo → assets/sprites/suelo-vestuario.png  (128x128: baldosas de 16, una casilla; empalma por los cuatro lados)
# (Antes salían de tools/sala_sin_sangre.py, del azulejo verde de los baños de los pisos sin sangre: ya no.)
# Uso: py tools/vestuario_azulejo.py  (y luego Godot --headless --path . --import)
import random
from PIL import Image

CARPETA = "assets/sprites/"
azar = random.Random(8)


def tono(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


# Una cuadrícula de piezas de "lado" píxeles (con la junta en su última fila y columna): cada pieza con su tono, grano dentro,
# su borde de arriba y de la izquierda con algo de luz y el de abajo y la derecha con algo de sombra
def cuadricula(ancho, alto, lado, pieza, junta, variacion, grano, brillo):
    im = Image.new("RGB", (ancho, alto))
    for py in range(0, alto, lado):
        for px in range(0, ancho, lado):
            base = tono(pieza, azar.uniform(1 - variacion, 1 + variacion))
            for y in range(lado):
                for x in range(lado):
                    if x == lado - 1 or y == lado - 1:
                        c = tono(junta, azar.uniform(0.94, 1.03))
                    else:
                        k = azar.uniform(1 - grano, 1 + grano)
                        if x == 0 or y == 0:
                            k *= 1 + brillo
                        elif x == lado - 2 or y == lado - 2:
                            k *= 1 - brillo
                        c = tono(base, k)
                    im.putpixel((px + x, py + y), c)
    return im


# La pared: azulejo blanco roto, junta gris claro; la última fila, en sombra, donde toca el suelo
pared = cuadricula(480, 48, 8, (226, 226, 222), (176, 176, 172), 0.015, 0.012, 0.03)
for x in range(480):
    pared.putpixel((x, 47), tono(pared.getpixel((x, 47)), 0.78))
pared.save(CARPETA + "pared-vestuario.png")

# El suelo: baldosa beis rosado, junta más oscura, alguna motita
suelo = cuadricula(128, 128, 16, (198, 178, 152), (150, 132, 112), 0.025, 0.02, 0.025)
for _ in range(60):
    x, y = azar.randrange(128), azar.randrange(128)
    if x % 16 != 15 and y % 16 != 15:
        suelo.putpixel((x, y), tono(suelo.getpixel((x, y)), azar.choice((0.9, 1.06))))
suelo.save(CARPETA + "suelo-vestuario.png")
print("pared-vestuario.png 480x48 · suelo-vestuario.png 128x128")
