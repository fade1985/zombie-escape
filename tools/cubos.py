"""Saca los dos dibujos de los cubos del suelo del cuarto de la limpieza de la portera (M11).

El cubo de pie lo dibujó PixelLab (16x16, paleta cerrada de grises azulados; ver "cubos-suelo" en
assets/pixellab.json): assets/sources/cubos/intentos/cubo-de-pie-nitido-B.png. De ahí:
  - assets/sprites/cubo-de-pie.png: el cubo de pie, recortado al borde.
  - assets/sprites/cubo-volcado.png: el mismo cubo girado 90° (tumbado, con la boca a la derecha; a la izquierda se
    pinta en espejo), con el agua de dentro quitada (la boca, oscura) y un charquito de agua sucia derramada.

Uso (desde la carpeta del proyecto):
  py tools/cubos.py
"""
from PIL import Image

ORIGEN = 'assets/sources/cubos/intentos/cubo-de-pie-nitido-B.png'
AGUA = {(0x5a, 0x6a, 0x52), (0x7e, 0x8f, 0x72), (0xa9, 0xb8, 0xaa)}   # el agua sucia y su espuma
OSCURO = (0x1d, 0x1b, 0x2c, 255)                                      # el contorno, y el hueco del cubo tumbado
CHARCO = {'d': (0x5a, 0x6a, 0x52, 255), 'm': (0x7e, 0x8f, 0x72, 255)}  # el agua derramada: oscura y media
# el charquito a la derecha de la boca, a ras del suelo (cada letra, un píxel; "." nada)
DERRAMADA = [
    ".dd.",
    "dmmd",
    ".dd.",
]


def main():
    pie = Image.open(ORIGEN).convert('RGBA')
    pie = pie.crop(pie.getbbox())
    pie.save('assets/sprites/cubo-de-pie.png')
    print('cubo-de-pie.png', pie.size)

    tumbado = pie.rotate(-90, expand=True)   # lo de arriba (la boca) pasa a la derecha
    px = tumbado.load()
    for y in range(tumbado.height):
        for x in range(tumbado.width):
            if px[x, y][3] and px[x, y][:3] in AGUA:
                px[x, y] = OSCURO   # dentro de la boca ya no hay agua: está oscuro
    # un lienzo más ancho, con el cubo a la izquierda y el agua derramada a la derecha
    ancho = len(DERRAMADA[0])
    lienzo = Image.new('RGBA', (tumbado.width + ancho, tumbado.height), (0, 0, 0, 0))
    lienzo.paste(tumbado, (0, 0))
    for f, fila in enumerate(DERRAMADA):
        for c, letra in enumerate(fila):
            if letra != '.':
                lienzo.putpixel((tumbado.width + c, tumbado.height - len(DERRAMADA) + f), CHARCO[letra])
    lienzo.save('assets/sprites/cubo-volcado.png')
    print('cubo-volcado.png', lienzo.size)


main()
