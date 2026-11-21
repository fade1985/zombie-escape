# Borra las lenguas dibujadas por PixelLab que sobresalen del cuerpo en los fotogramas del golpe de las lenguas de la
# criatura del científico (3 a 8, las 8 direcciones), porque las pinta el código (lengua.gd) y se veían las dos a la
# vez. Las del aviso (0 a 2, enroscadas) y las que cuelgan por delante del cuerpo (dentro de la boca del pecho) se
# quedan: son parte del dibujo. Cómo sabe qué es lengua:
#   1. el cuerpo es lo que queda al «abrir» la silueta (comerle R píxeles por todos lados y devolvérselos): lo fino
#      que sobresale (lenguas, pero también dedos y llamas) desaparece;
#   2. de lo fino, se borra lo rojizo y su contorno oscuro, menos las llamas (también son naranjas, pero siempre
#      van unidas a algo amarillo), y los brillos que quedan rodeados de lengua borrada;
#   3. luego, los trocitos sueltos que quedan.
# YA SE HA PASADO (21 nov): no volver a pasarlo con «guardar» (borraría más).
# Uso: py tools/criatura_sin_lengua.py [guardar] [vista.png]   (la vista: antes y después de cada fotograma)
import re, sys
from collections import deque
from PIL import Image, ImageFilter

GUARDAR = len(sys.argv) > 1 and sys.argv[1] == "guardar"
VISTA = next((a for a in sys.argv[1:] if a.endswith(".png")), None)
R = 6                       # lo que se le come a la silueta para quedarse con el cuerpo
PRIMERO = 3                 # el fotograma del golpe (GOLPE.lenguas de cientifico_jefe.gd)

tres = open("assets/sprites/jefe-criatura.tres", encoding="utf-8").read()
reg = {m[0]: tuple(map(int, m[1:])) for m in re.findall(
    r'id="(t\d+)"\]\natlas = ExtResource\("hoja"\)\nregion = Rect2\((\d+), (\d+), (\d+), (\d+)\)', tres)}
anims = {m[2]: re.findall(r'SubResource\("(t\d+)"\)', m[1]) for m in re.finditer(
    r'\{"frames": \[(.*?)\], "loop": \w+, "name": &"(\w+)"', tres)}
hoja = Image.open("assets/sprites/jefe-criatura.png").convert("RGBA")
DIRS = ["s", "se", "e", "ne", "n", "no", "o", "so"]
V8 = [(a, b) for a in (-1, 0, 1) for b in (-1, 0, 1) if a or b]


def rojo(c):
    r, g, b, a = c
    return a > 0 and r >= g * 1.5 + 8 and r >= b * 1.4 + 8


def amarillo(c):   # (el de las llamas, no el brillo claro de las lenguas)
    return c[3] > 0 and c[0] > 200 and c[1] >= 125 and c[2] < 110


def oscuro(c):
    return c[3] > 0 and 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2] < 75


def limpiar(im):
    w, h = im.size
    px = im.load()
    silueta = im.getchannel("A").point(lambda a: 255 if a else 0)
    cuerpo = silueta.filter(ImageFilter.MinFilter(2 * R + 1)).filter(ImageFilter.MaxFilter(2 * R + 1)).load()
    # las llamas: lo naranja y amarillo a menos de 4 píxeles de algo amarillo (las lenguas, aunque sean naranjas, no
    # tienen amarillo; y si tocan una llama, se protege solo su arranque)
    calido = lambda c: c[3] > 0 and c[0] > 190 and c[1] >= 60 and c[2] < 120
    llama = {(u, v): 0 for u in range(w) for v in range(h) if amarillo(px[u, v])}
    q = deque(llama)
    while q:
        a, b = q.popleft()
        if llama[(a, b)] >= 4:
            continue
        for da, db in V8:
            n = (a + da, b + db)
            if 0 <= n[0] < w and 0 <= n[1] < h and n not in llama and calido(px[n]):
                llama[n] = llama[(a, b)] + 1
                q.append(n)
    fino = {(u, v) for u in range(w) for v in range(h) if px[u, v][3] and not cuerpo[u, v] and (u, v) not in llama}
    borrar = set()
    vistos = set()
    for p in fino:
        if p in vistos:
            continue
        grupo, q = [], deque([p])
        vistos.add(p)
        while q:
            a, b = q.popleft()
            grupo.append((a, b))
            for da, db in V8:
                n = (a + da, b + db)
                if n in fino and n not in vistos:
                    vistos.add(n)
                    q.append(n)
        rojos = {g for g in grupo if rojo(px[g])}
        if len(rojos) < 4:
            continue
        borrar |= rojos
        borrar |= {(a, b) for (a, b) in grupo if (a, b) not in rojos and oscuro(px[a, b])
                   and any((a + da, b + db) in rojos for da, db in V8)}
        # y lo que queda dentro de la lengua sin ser rojizo (brillos): lo de ese grupo rodeado de lo que se borra
        resto = set(grupo) - borrar
        for _ in range(3):
            mas = {(a, b) for (a, b) in resto if sum((a + da, b + db) in borrar for da, db in V8) >= 4}
            borrar |= mas
            resto -= mas
    for p in borrar:
        px[p] = (0, 0, 0, 0)
    # los hilos de un píxel que quedan cerca de lo borrado (a menos de 12 píxeles; de lo fino, que no tengan más de
    # un vecino), desde la punta hacia dentro
    marca = Image.new("L", (w, h), 0)
    for p in borrar:
        marca.putpixel(p, 255)
    cerca = marca.filter(ImageFilter.MaxFilter(25)).load()
    while True:
        hilo = {(a, b) for (a, b) in fino if px[a, b][3] and cerca[a, b] and sum(
            1 for da, db in V8 if 0 <= a + da < w and 0 <= b + db < h and px[a + da, b + db][3]) <= 1}
        if not hilo:
            break
        for p in hilo:
            px[p] = (0, 0, 0, 0)
        borrar |= hilo
    # trocitos sueltos (menos de 20 píxeles)
    vistos = set()
    sueltos = 0
    for u in range(w):
        for v in range(h):
            if (u, v) in vistos or not px[u, v][3]:
                continue
            grupo, q = [], deque([(u, v)])
            vistos.add((u, v))
            while q:
                a, b = q.popleft()
                grupo.append((a, b))
                for da, db in V8:
                    n = (a + da, b + db)
                    if 0 <= n[0] < w and 0 <= n[1] < h and n not in vistos and px[n][3]:
                        vistos.add(n)
                        q.append(n)
            if len(grupo) < 20:
                for g in grupo:
                    px[g] = (0, 0, 0, 0)
                sueltos += len(grupo)
    return len(borrar) + sueltos


x, y, W, H = reg[anims["lenguas_s"][0]]
FOTOS = 9 - PRIMERO
vista = Image.new("RGBA", (W * FOTOS, H * 16), (40, 140, 60, 255)) if VISTA else None
for fila, d in enumerate(DIRS):
    for col, f in enumerate(range(PRIMERO, 9)):
        x, y, w, h = reg[anims["lenguas_" + d][f]]
        antes = hoja.crop((x, y, x + w, y + h))
        despues = antes.copy()
        n = limpiar(despues)
        print(f"{d} f{f}: {n} píxeles")
        if GUARDAR:
            hoja.paste(despues, (x, y))
        if vista:
            vista.alpha_composite(antes, (col * w, fila * 2 * h))
            vista.alpha_composite(despues, (col * w, (fila * 2 + 1) * h))
if GUARDAR:
    hoja.save("assets/sprites/jefe-criatura.png")
    print("guardada assets/sprites/jefe-criatura.png")
if vista:
    vista.save(VISTA)
