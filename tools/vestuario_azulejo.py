# El suelo y la pared del vestuario de la sala de mantenimiento, como los de la foto del dueño (8 nov): azulejo blanco
# cuadrado en la pared, de suelo a techo, y baldosa cuadrada beis en el suelo, los dos con su junta. Dibujados aquí, píxel a
# píxel (una cuadrícula limpia: reducida de una imagen, las juntas, de un píxel, saldrían a trozos), con los colores de la foto.
# Para que no parezcan de plástico (la primera versión, de colores planos y juntas muy marcadas, «poco real»): la junta,
# casi del color de la pieza; cada pieza con su tono, grano y un brillo suave en diagonal (el esmalte); y por encima, manchas
# grandes y suaves de suciedad y desgaste que pasan de una pieza a otra (y en la pared, más sucia abajo, junto al suelo).
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


# Manchas suaves que empalman por los bordes: un puñado de valores al azar, agrandados con suavidad. Devuelve f(x, y) → 0..1
def manchas(ancho, alto, celdas_x, celdas_y):
    peq = Image.new("L", (celdas_x, celdas_y))
    for y in range(celdas_y):
        for x in range(celdas_x):
            peq.putpixel((x, y), azar.randrange(256))
    # tres veces repetida en cada sentido y agrandada: se coge la del medio, así los bordes empalman
    tres = Image.new("L", (celdas_x * 3, celdas_y * 3))
    for j in range(3):
        for i in range(3):
            tres.paste(peq, (i * celdas_x, j * celdas_y))
    grande = tres.resize((ancho * 3, alto * 3), Image.Resampling.BICUBIC).crop((ancho, alto, ancho * 2, alto * 2))
    return lambda x, y: grande.getpixel((x, y)) / 255.0


# Una cuadrícula de piezas de "lado" píxeles (la junta, en su última fila y columna)
def cuadricula(ancho, alto, lado, pieza, junta, variacion, grano, sucio, desgaste):
    im = Image.new("RGB", (ancho, alto))
    mancha = manchas(ancho, alto, max(2, ancho // 24), max(2, alto // 24))
    fina = manchas(ancho, alto, max(2, ancho // 6), max(2, alto // 6))
    for py in range(0, alto, lado):
        for px in range(0, ancho, lado):
            base = tono(pieza, azar.uniform(1 - variacion, 1 + variacion))
            for y in range(lado):
                for x in range(lado):
                    X, Y = px + x, py + y
                    if x == lado - 1 or y == lado - 1:
                        c = tono(junta, azar.uniform(0.95, 1.03))
                    else:
                        k = azar.uniform(1 - grano, 1 + grano)
                        # el brillo del esmalte: una franja suave en diagonal, más clara arriba a la izquierda
                        d = (x + y) / (2 * (lado - 2))
                        k *= 1.0 + 0.035 * (1 - d) - 0.02 * d
                        c = tono(base, k)
                    # la suciedad (oscurece y amarillea un poco) y el desgaste (aclara)
                    s = max(0.0, mancha(X, Y) - 0.45) * sucio + max(0.0, fina(X, Y) - 0.7) * sucio * 0.6
                    g = max(0.0, 0.25 - mancha(X, Y)) * desgaste
                    c = (c[0] * (1 - s * 0.9) + g * 40, c[1] * (1 - s) + g * 40, c[2] * (1 - s * 1.25) + g * 40)
                    im.putpixel((X, Y), tono(c, 1.0))
    return im


# La pared: azulejo blanco roto, junta gris muy claro; más sucia abajo, y la última fila, en sombra, donde toca el suelo
pared = cuadricula(480, 48, 8, (222, 222, 216), (196, 195, 188), 0.012, 0.018, 0.16, 0.0)
for x in range(480):
    for y in range(48):
        k = 1.0 - max(0, y - 30) * 0.006
        pared.putpixel((x, y), tono(pared.getpixel((x, y)), k * (0.8 if y == 47 else 1.0)))
pared.save(CARPETA + "pared-vestuario.png")

# El suelo: baldosa beis rosado, junta un poco más oscura, alguna motita, suciedad y zonas gastadas por las pisadas
suelo = cuadricula(128, 128, 16, (192, 172, 148), (164, 146, 124), 0.02, 0.025, 0.28, 0.35)
for _ in range(90):
    x, y = azar.randrange(128), azar.randrange(128)
    if x % 16 != 15 and y % 16 != 15:
        suelo.putpixel((x, y), tono(suelo.getpixel((x, y)), azar.choice((0.88, 0.92, 1.05))))
suelo.save(CARPETA + "suelo-vestuario.png")
print("pared-vestuario.png 480x48 · suelo-vestuario.png 128x128")
