"""Las piezas sueltas del zombi explosivo (piezas.webp, de GPT, 19 nov) al tamaño del juego, y el último fotograma de su
muerte nueva (reventar en cachos) montado con ellas: los cachos tirados en el suelo. Ese fotograma va a PixelLab como
pose final (end_frame) de la animación, que empieza con él de pie con la gabardina abierta (ataque/south-8.png).

GPT las dibujó a la escala de la referencia (su dibujo del juego ×10): se reducen a la décima parte mezclando colores,
como los muebles (LANCZOS premultiplicado), sin medias tintas en el borde y con el borde negro de Johnny.

    py assets/sources/zombi-explosivo-gpt/piezas.py
Saca piezas/<n>.png (las 12 piezas) y final-south.png (96×96, el fotograma final).
"""
import os
import random
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
BORDE = (5, 2, 2, 255)
NOMBRES = ['cabeza', 'brazo-d', 'brazo-i', 'tronco', 'piernas', 'faldon', 'faldon-2', 'cinturon',
           'trapo-1', 'trapo-2', 'trapo-3', 'trapo-4']


def con_borde(im):
    px = im.load()
    w, h = im.size
    poner = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] == 0 and any(
        0 <= x + a < w and 0 <= y + b < h and px[x + a, y + b][3] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for q in poner:
        px[q] = BORDE
    return im


def cajas(hoja):
    """Dónde está cada pieza: manchas que no son fondo negro, juntando lo que está a menos de ~30 px (la mano y su manga
    van separadas), en el orden de la hoja (por filas, de izquierda a derecha)."""
    k = 4
    peq = hoja.convert('L').resize((hoja.width // k, hoja.height // k), Image.BOX)
    w, h = peq.size
    m = peq.load()
    lleno = {(x, y) for y in range(h) for x in range(w) if m[x, y] > 25}
    R = 8   # (30 px de la hoja)
    visto, grupos = set(), []
    for p in lleno:
        if p in visto:
            continue
        pila, grupo = [p], []
        visto.add(p)
        while pila:
            x, y = pila.pop()
            grupo.append((x, y))
            for dx in range(-R, R + 1):
                for dy in range(-R, R + 1):
                    q = (x + dx, y + dy)
                    if q in lleno and q not in visto:
                        visto.add(q)
                        pila.append(q)
        grupos.append(grupo)
    grupos = sorted(grupos, key=len, reverse=True)[:12]
    res = []
    for g in grupos:
        xs, ys = [q[0] for q in g], [q[1] for q in g]
        res.append((min(xs) * k - 4, min(ys) * k - 4, (max(xs) + 1) * k + 4, (max(ys) + 1) * k + 4))
    fila = lambda c: round((c[1] + c[3]) / 2 / (hoja.height / 3) - 0.5)
    return sorted(res, key=lambda c: (fila(c), c[0]))


def pieza(celda):
    # fondo negro fuera: lo que no es casi negro es pieza
    rgb = celda.convert('RGB')
    alfa = rgb.convert('L').point(lambda v: 255 if v > 14 else 0)
    im = rgb.convert('RGBA')
    im.putalpha(alfa)
    caja = alfa.getbbox()
    im = im.crop(caja)
    w, h = max(1, round(im.width / 10)), max(1, round(im.height / 10))
    peq = im.convert('RGBa').resize((w, h), Image.LANCZOS).convert('RGBA')
    peq.putalpha(peq.split()[3].point(lambda v: 255 if v > 110 else 0))
    lienzo = Image.new('RGBA', (w + 2, h + 2), (0, 0, 0, 0))
    lienzo.alpha_composite(peq, (1, 1))
    return con_borde(lienzo)


def main():
    hoja = Image.open(os.path.join(AQUI, 'piezas.webp'))
    os.makedirs(os.path.join(AQUI, 'piezas'), exist_ok=True)
    piezas = {}
    for nombre, caja in zip(NOMBRES, cajas(hoja)):
        p = pieza(hoja.crop(caja))
        p.save(os.path.join(AQUI, 'piezas', f'{nombre}.png'))
        piezas[nombre] = p
        print(nombre, p.size)
    # El fotograma final: los cachos tirados en el suelo alrededor de donde estaba (sus pies, en 48, 82 del lienzo de
    # 96 de la animación), vistos un poco desde arriba: todo entre las líneas 60 y 90, con manchas de sangre debajo
    random.seed(7)
    final = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
    sangre = [(92, 14, 14, 255), (120, 20, 18, 255)]
    # (no caben todas: los faldones pequeños y dos trapos han salido volando fuera)
    sitio = {   # centro de cada pieza y su giro (grados)
        'tronco': ((19, 70), -10), 'piernas': ((50, 76), 90), 'faldon': ((79, 66), 15),
        'cabeza': ((82, 86), 35), 'brazo-d': ((22, 89), 75), 'brazo-i': ((60, 90), -80),
        'cinturon': ((40, 60), 20), 'trapo-2': ((6, 86), 30), 'trapo-4': ((92, 76), -20),
    }
    # manchas de sangre primero (debajo)
    for (cx, cy), _ in sitio.values():
        cy -= 8
        for _ in range(3):
            x, y = cx + random.randint(-5, 5), cy + random.randint(-2, 3)
            for dx in range(-2, 3):
                for dy in range(-1, 2):
                    if abs(dx) + abs(dy) < 3 and 0 <= x + dx < 96 and 0 <= y + dy < 96:
                        final.putpixel((x + dx, y + dy), random.choice(sangre))
    for nombre in ['cinturon', 'faldon', 'tronco', 'piernas', 'trapo-2', 'trapo-4', 'brazo-d', 'brazo-i', 'cabeza']:
        (cx, cy), giro = sitio[nombre]
        cy -= 8   # (todo un poco más arriba: que no se salga por abajo)
        p = piezas[nombre].rotate(giro, resample=Image.NEAREST, expand=True)
        final.alpha_composite(p, (cx - p.width // 2, cy - p.height // 2))
    final.save(os.path.join(AQUI, 'final-south.png'))
    ver = Image.new('RGBA', (96, 96), (96, 90, 84, 255))
    ver.alpha_composite(final)
    ver.resize((480, 480), Image.NEAREST).save(os.path.join(AQUI, 'final-south-ver.png'))


if __name__ == '__main__':
    main()
