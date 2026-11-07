# Las tuberías de las paredes de los lados del taller de la sala de mantenimiento (debajo de sus puertas), del 7 nov: de
# las cuatro instalaciones que hizo GPT (assets/sources/taller-tuberias-gpt.webp, en una cuadrícula de 2x2) el dueño
# eligió la 1 (tuberías blancas con el volante rojo, el cuadro de botones y la bomba roja) para la pared izquierda y la 3
# (todo rojo, de las de incendios, con su depósito) para la derecha. Las dos están dibujadas pegadas a una pared por la
# izquierda: en la derecha el juego pone la 3 en espejo (mueble.gd).
# Esto recorta cada una y le quita el fondo oscuro (lo que se llega desde el borde sin cruzar el contorno negro) y la deja
# como original de mueble de lado en assets/sources/salas/mantenimiento/. Luego "py tools/importar.py" la pasa a sprite
# (mueble-<tipo>-lado, al fondo "dep" del catálogo).
#   py tools/taller_tuberias.py   (y luego py tools/importar.py y Godot --headless --path . --import)
from collections import deque
from PIL import Image

ORIGEN = "assets/sources/taller-tuberias-gpt.webp"
SALEN = {"tuberias-caldera-lado": (0, 0, 512, 768), "tuberias-incendios-lado": (0, 768, 512, 1536)}

im = Image.open(ORIGEN).convert("RGBA")
for nombre, caja in SALEN.items():
    trozo = im.crop(caja)
    p = trozo.load()
    w, h = trozo.size

    def es_fondo(c):
        r, g, b, _ = c
        return 10 <= max(r, g, b) < 72 and max(r, g, b) - min(r, g, b) < 26   # (oscuro y gris, o con el brillo rojizo)

    vistos = set()
    cola = deque((x, y) for x in range(w) for y in (0, h - 1)) + deque((x, y) for y in range(h) for x in (0, w - 1))
    while cola:
        x, y = cola.popleft()
        if (x, y) in vistos or not (0 <= x < w and 0 <= y < h) or not es_fondo(p[x, y]):
            continue
        vistos.add((x, y))
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for x, y in vistos:
        p[x, y] = (0, 0, 0, 0)
    # lo negro del contorno que queda suelto por fuera, también fuera
    for y in range(h):
        for x in range(w):
            if p[x, y][3] and max(p[x, y][:3]) < 10:
                vecinos = [p[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 <= x + dx < w and 0 <= y + dy < h]
                if sum(1 for v in vecinos if v[3] == 0) >= 2:
                    p[x, y] = (0, 0, 0, 0)
    # y solo la pieza grande (fuera las motitas sueltas de alrededor)
    piezas, hecho = [], set()
    for y in range(h):
        for x in range(w):
            if p[x, y][3] and (x, y) not in hecho:
                pieza, pila = [], [(x, y)]
                hecho.add((x, y))
                while pila:
                    a, b = pila.pop()
                    pieza.append((a, b))
                    for c, d in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
                        if 0 <= c < w and 0 <= d < h and p[c, d][3] and (c, d) not in hecho:
                            hecho.add((c, d))
                            pila.append((c, d))
                piezas.append(pieza)
    piezas.sort(key=len)
    for pieza in piezas[:-1]:
        for x, y in pieza:
            p[x, y] = (0, 0, 0, 0)
    trozo = trozo.crop(trozo.getbbox())
    trozo.save("assets/sources/salas/mantenimiento/%s.png" % nombre)
    print(nombre, trozo.size)
