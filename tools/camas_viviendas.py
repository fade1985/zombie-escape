"""Las camas de las habitaciones de los supervivientes (viviendas.gd), que son trasteros: un colchón en el suelo, con la
almohada descolocada y la colcha del color de cada uno (el mismo de Supervivientes.DATOS en scripts/supervivientes.gd),
para que se distinga de quién es cada habitación.

  py tools/muebles_gpt.py colchon_trastero   (el colchón de GPT, reducido)
  py tools/camas_viviendas.py                → assets/sprites/mueble-mattress_<id>.png y su .json (y luego Godot --import)

Desde el 10 nov (M8) parte del colchón de GPT (assets/sources/viviendas/colchon-gpt.png, con la colcha mostaza, ya
reducido como los muebles) y deja los sprites directamente (no pasa por importar.py: los originales de PixelLab de antes
están en assets/sources/salas/descartes/). Solo toca los píxeles de la colcha (la mostaza: tono naranja y saturados, que
en ese dibujo son solo la colcha; las sábanas y la almohada no). A cada uno le cambia el tono y deja la luminosidad, así
que las sombras y los pliegues quedan como en el original.
"""
import colorsys, json, os
from collections import Counter
from PIL import Image

ORIGEN = 'assets/sources/viviendas/colchon-gpt.png'
CAMA = 'assets/sources/salas/dormitorio/cama.png'   # la cama de siempre, de la que sale la guía del colchón
SALIDA = 'assets/sprites'
# el color de cada superviviente (Supervivientes.DATOS)
COLORES = {'policia': '#6fa8ff', 'medico': '#80ed99', 'militar': '#c9e265',
           'ferretero': '#ff9a3c', 'farmaceutica': '#3ddc84', 'tecnico': '#4fe3ff',
           'programador': '#b48cff', 'recepcionista': '#ff6fae', 'limpiadora': '#ffd23c'}
SAT_MIN, SAT_MAX = 0.45, 0.68   # la colcha no ha de quedar ni grisácea ni chillona (la de GPT, más clara: 0,68)
OSCURECER = 0.88   # (y algo más oscura que la mostaza, que es un color claro: si no, las demás salen fosforito)
# los colores de la sangre de la cama de siempre (la mancha de la almohada y el reguero de la sábana, y un píxel suelto de su
# borde): tools/guias_trasteros.py la quita antes de hacer la guía del colchón
SANGRE = {(113, 48, 49), (87, 14, 30), (134, 93, 73)}
CABECERO = 36   # de aquí hacia arriba es el cabecero (su madera no se toca)


def es_colcha(h, s, l=0.5):
    return 0.05 <= h <= 0.15 and s > 0.5 and l < 0.75   # (las sábanas y la almohada, crema muy claro, no)


def tono(hexa):
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hls(r, g, b)[0]


def sin_sangre(im):
    px = im.load()
    return rellenar(im, {(x, y) for y in range(CABECERO, im.height) for x in range(im.width) if px[x, y][:3] in SANGRE})


def rellenar(im, manchas, evitar=()):
    """Cada píxel de "manchas" (un conjunto de (x, y): sangre, arañazos...) pasa a ser el color que más se repite entre
    sus vecinos que no lo son (sábana, almohada, madera), de fuera hacia dentro, hasta que no queda ninguno. Los colores
    de "evitar" (los oscuros del borde de un dibujo) solo se usan cuando ya no queda ningún píxel con otro vecino que
    rellenar"""
    px = im.load()
    while manchas:
        limpios = {}
        con_oscuros = {}
        for x, y in manchas:
            vecinos = Counter(px[x + dx, y + dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                              if (dx or dy) and 0 <= x + dx < im.width and 0 <= y + dy < im.height
                              and (x + dx, y + dy) not in manchas and px[x + dx, y + dy][3] > 0)
            claros = Counter({c: n for c, n in vecinos.items() if c[:3] not in evitar})
            if claros:
                limpios[(x, y)] = claros.most_common(1)[0][0]
            elif vecinos:
                con_oscuros[(x, y)] = vecinos.most_common(1)[0][0]
        limpios = limpios or con_oscuros
        if not limpios:
            break
        for q, color in limpios.items():
            px[q] = color
            manchas.discard(q)
    return im


def main():
    original = Image.open(ORIGEN).convert('RGBA')
    os.makedirs(SALIDA, exist_ok=True)
    for id, hexa in COLORES.items():
        th = tono(hexa)
        im = original.copy()
        px = im.load()
        cambiados = 0
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
                if not es_colcha(h, s, l):
                    continue
                s = min(SAT_MAX, max(SAT_MIN, s))
                r, g, b = (round(c * 255) for c in colorsys.hls_to_rgb(th, l * OSCURECER, s))
                px[x, y] = (r, g, b, a)
                cambiados += 1
        sprite = f'{SALIDA}/mueble-mattress_{id}'
        im.save(sprite + '.png')
        with open(sprite + '.json', 'w', encoding='utf-8', newline='\n') as f:   # (como los de tools/muebles_gpt.py)
            json.dump({"cell": [im.width, im.height], "pivot": [im.width // 2, im.height], "scale": 1,
                       "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
            f.write('\n')
        print(f'  mueble-mattress_{id}.png: {cambiados} píxeles de colcha')


if __name__ == '__main__':
    main()
