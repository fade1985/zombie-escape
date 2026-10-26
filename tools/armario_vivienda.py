"""El armario de las habitaciones de los supervivientes (viviendas.gd): el armario de siempre, pero limpio: sin la sangre de
las puertas y de la maleta de arriba ni los arañazos de las puertas (el de los pisos, con ellos, no se toca).

  py tools/armario_vivienda.py   → assets/sources/salas/viviendas/armario-limpio.png (y luego: py tools/importar.py)

Parte de assets/sources/salas/dormitorio/armario.png. Cada píxel de sangre o de arañazo pasa a ser el color que más se
repite entre sus vecinos (la madera), como en tools/camas_viviendas.py; los tiradores y el resto no se tocan.
"""
from PIL import Image
from camas_viviendas import rellenar

ORIGEN = 'assets/sources/salas/dormitorio/armario.png'
SALIDA = 'assets/sources/salas/viviendas/armario-limpio.png'
# los rojos de la sangre (en las puertas y en la maleta de arriba)
SANGRE = {(118, 22, 30), (76, 12, 20), (168, 30, 38), (119, 21, 16)}
# los arañazos de las puertas: las rayas claras y su sombra oscura (no en lo de arriba ni en los tiradores, que son del
# mismo tono claro)
ARANAZOS = {(192, 142, 88), (72, 42, 26)}
PUERTAS = (46, 142)         # de qué fila a qué fila están las puertas (de arriba, la tapa y la maleta)
TIRADORES = (42, 84, 60, 106)   # el recuadro (x0, y0, x1, y1) de los dos tiradores
# los oscuros del borde de las puertas y las bisagras: no se rellena con ellos (la sangre pegada al borde dejaba manchas)
OSCUROS = {(53, 23, 4), (39, 12, 9), (22, 18, 12), (38, 35, 32)}


def main():
    im = Image.open(ORIGEN).convert('RGBA')
    px = im.load()
    x0, y0, x1, y1 = TIRADORES
    manchas = set()
    for y in range(im.height):
        for x in range(im.width):
            color = px[x, y][:3]
            en_tirador = x0 <= x < x1 and y0 <= y < y1
            if color in SANGRE or (color in ARANAZOS and PUERTAS[0] <= y < PUERTAS[1] and not en_tirador):
                manchas.add((x, y))
    cuantas = len(manchas)   # (rellenar las va vaciando)
    rellenar(im, manchas, OSCUROS)
    im.save(SALIDA)
    print(f'  armario-limpio.png: {cuantas} píxeles de sangre y arañazos quitados')


if __name__ == '__main__':
    main()
