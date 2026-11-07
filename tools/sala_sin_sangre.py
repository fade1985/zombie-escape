# La sala de mantenimiento, sin sangre (L20 de PENDIENTES): es el sitio seguro del juego. Antes sacaba de aquí también sus
# suelos y paredes (copias limpias de los de los pisos), pero ya no: el taller, de vinilo (tools/taller_vinilo.py, 7 nov); el
# despacho, de ladrillo y tarima (tools/despacho_ladrillo.py, 7 nov); y el vestuario, de azulejo blanco y baldosa beis
# (tools/vestuario_azulejo.py, 8 nov). Lo que queda: limpia los muebles que
# la llevan pintada (mueble(), al final), en su mismo archivo: si alguno se vuelve a generar (tools/baul_mantenimiento.py,
# tools/banco_mantenimiento.py...), hay que pasar esto después. Usa siempre la misma semilla, así que al lanzarla otra vez salen
# los mismos dibujos. Uso: py tools/sala_sin_sangre.py  (y luego, para que Godot importe los
# nuevos: Godot --headless --path . --import)
import random
from PIL import Image

CARPETA = "assets/sprites/"
LADO = 19.2   # lo que mide una baldosa de suelo-bano-b (10 por lado, de junta a junta)


def luz(c):
    return (c[0] * 3 + c[1] * 6 + c[2]) / 10.0


def rojo(c):
    return c[0] - c[1]


def mitad(valores):
    return sorted(valores)[len(valores) // 2]


def ensanchar(marca, ancho, alto, veces):
    for _ in range(veces):
        nueva = set(marca)
        for x, y in marca:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if 0 <= y + dy < alto:
                    nueva.add(((x + dx) % ancho, y + dy))
        marca = nueva
    return marca


# Los grupos de píxeles marcados que se tocan entre sí
def grupos(marca):
    quedan = set(marca)
    lista = []
    while quedan:
        pila = [quedan.pop()]
        grupo = []
        while pila:
            x, y = pila.pop()
            grupo.append((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    p = (x + dx, y + dy)
                    if p in quedan:
                        quedan.remove(p)
                        pila.append(p)
        lista.append(grupo)
    return lista


# Una pared: se compara cada píxel con los de su fila alrededor (la pared va por franjas). Se marca lo que es más rojo o más
# oscuro que ellos (hasta la fila "hasta": debajo puede ir el friso de madera) y se rellena con otro píxel limpio de su fila,
# a un múltiplo de "paso" (lo que hay de una línea a otra de la cuadrícula: 1 si no tiene)
def pared(origen, destino, de_rojo, de_luz, hasta, paso, ensanche, ventana=30):
    im = Image.open(CARPETA + origen + ".png").convert("RGB")
    ancho, alto = im.size
    p = im.load()
    marca = set()
    for y in range(hasta):
        fila = [p[x, y] for x in range(ancho)]
        for x in range(ancho):
            cerca = fila[max(0, x - ventana):x + ventana + 1]
            if rojo(fila[x]) - mitad([rojo(c) for c in cerca]) > de_rojo or mitad([luz(c) for c in cerca]) - luz(fila[x]) > de_luz:
                marca.add((x, y))
    marca = ensanchar(marca, ancho, hasta, ensanche)
    for x, y in marca:
        limpios = []
        k = 1
        while len(limpios) < 6 and k * paso < ancho:
            for lado in (-1, 1):
                otro = x + lado * round(k * paso)
                if 0 <= otro < ancho and (otro, y) not in marca:
                    limpios.append(p[otro, y])
            k += 1
        if limpios:
            p[x, y] = tuple(mitad([c[i] for c in limpios]) for i in range(3))
    im.save(CARPETA + destino + ".png")
    print(destino, "de", origen, "· píxeles limpiados:", len(marca))


# Un suelo de baldosas (el verde menta tiene menos rojo que verde): se marca lo que tiene más rojo que eso, con más margen en
# las juntas, que son grises. Cada baldosa manchada toma los píxeles marcados de la baldosa limpia que más se le parece en los que
# no lo están
def baldosas(origen, destino, de_rojo, en_junta, ensanche):
    im = Image.open(CARPETA + origen + ".png").convert("RGB")
    ancho, alto = im.size
    p = im.load()
    filas = round(ancho / LADO)
    inicio = lambda i: round(i * LADO)
    junta = lambda v: min((v - inicio(i)) ** 2 for i in range(filas + 1)) <= 1
    marca = set()
    for y in range(alto):
        for x in range(ancho):
            if rojo(p[x, y]) > (en_junta if junta(x) or junta(y) else de_rojo):
                marca.add((x, y))
    marca = ensanchar(marca, ancho, alto, ensanche)
    casilla = lambda c, f: [(u, v) for v in range(inicio(f + 1) - inicio(f)) for u in range(inicio(c + 1) - inicio(c))]
    en = lambda c, f, q: (inicio(c) + q[0], inicio(f) + q[1])
    limpias = [(c, f) for f in range(filas) for c in range(filas) if not any(en(c, f, q) in marca for q in casilla(c, f))]
    print(destino, "de", origen, "· baldosas limpias:", len(limpias), "de", filas * filas)
    for f in range(filas):
        for c in range(filas):
            sucios = [q for q in casilla(c, f) if en(c, f, q) in marca]
            if not sucios:
                continue
            sanos = [q for q in casilla(c, f) if en(c, f, q) not in marca]

            def parecido(l):
                suma = 0
                for q in sanos:
                    a, b = p[en(c, f, q)], p[min(en(*l, q)[0], ancho - 1), min(en(*l, q)[1], alto - 1)]
                    suma += sum(abs(a[i] - b[i]) for i in range(3))
                return suma / max(1, len(sanos))
            donante = min(limpias, key=parecido)
            for q in sucios:
                x, y = en(*donante, q)
                p[en(c, f, q)] = p[min(x, ancho - 1), min(y, alto - 1)]
    im.save(CARPETA + destino + ".png")


# Un suelo de tablones (van de arriba abajo): se compara cada píxel con los de su columna. Se marcan las motas más oscuras o más
# rojas y se rellenan con un píxel limpio de su columna, que sigue la veta. Lo marcado ancho y de 1 o 2 píxeles de alto no es
# sangre, es la raya que separa dos tablones: se deja
def tablones(origen, destino, de_rojo, de_luz, raya, ensanche, ventana=9):
    dado = random.Random(destino)
    im = Image.open(CARPETA + origen + ".png").convert("RGB")
    ancho, alto = im.size
    p = im.load()
    marca = set()
    for x in range(ancho):
        columna = [p[x, y] for y in range(alto)]
        for y in range(alto):
            cerca = [columna[(y + d) % alto] for d in range(-ventana, ventana + 1)]
            if rojo(columna[y]) - mitad([rojo(c) for c in cerca]) > de_rojo or mitad([luz(c) for c in cerca]) - luz(columna[y]) > de_luz:
                marca.add((x, y))
    for g in grupos(marca):
        if max(q[0] for q in g) - min(q[0] for q in g) >= raya and max(q[1] for q in g) - min(q[1] for q in g) < 2:
            marca.difference_update(g)
    marca = ensanchar(marca, ancho, alto, ensanche)
    for x, y in marca:
        limpios = [d for d in range(-14, 15) if d != 0 and (x, (y + d) % alto) not in marca]
        if limpios:
            p[x, y] = p[x, (y + dado.choice(sorted(limpios, key=abs)[:6])) % alto]
    im.save(CARPETA + destino + ".png")
    print(destino, "de", origen, "· píxeles limpiados:", len(marca))


# Las manchas de un mueble (se queda en su mismo archivo: fuera de esta sala no se nota): dentro de las "cajas" [x0, y0, x1, y1]
# se marca lo que cumple "es_sangre" y cada píxel marcado toma la mediana de los limpios que tiene alrededor
def mueble(nombre, cajas, es_sangre):
    im = Image.open(CARPETA + nombre + ".png").convert("RGBA")
    ancho, alto = im.size
    p = im.load()
    marca = set()
    for x0, y0, x1, y1 in cajas:
        for y in range(y0, min(y1, alto)):
            for x in range(x0, min(x1, ancho)):
                if p[x, y][3] > 0 and es_sangre(p[x, y]):
                    marca.add((x, y))
    # de fuera hacia dentro: cada pasada rellena lo que ya tiene algún vecino limpio
    pendientes = set(marca)
    while pendientes:
        hechos = {}
        for x, y in pendientes:
            vecinos = [p[x + dx, y + dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                if 0 <= x + dx < ancho and 0 <= y + dy < alto and (x + dx, y + dy) not in pendientes and p[x + dx, y + dy][3] > 0]
            if vecinos:
                hechos[x, y] = tuple(mitad([c[i] for c in vecinos]) for i in range(3)) + (p[x, y][3],)
        if not hechos:
            break
        for q, c in hechos.items():
            p[q] = c
            pendientes.discard(q)
    if marca:
        im.save(CARPETA + nombre + ".png")
    print(nombre, "· píxeles limpiados:", len(marca))


# (el suelo y la pared del vestuario ya no: desde el 8 nov, tools/vestuario_azulejo.py)
# (el suelo y la pared del despacho ya no: desde el 7 nov, tools/despacho_ladrillo.py)
# (el baúl ya no: desde el 7 nov es de plástico negro, tools/baul_plastico.py)
# (ni el banco de trabajo, la ducha, el váter y la estantería: desde el 7 nov salen de imágenes de GPT sin sangre,
# tools/muebles_gpt.py; limpiarlos aquí los estropearía)
# la mancha del marco de las puertas de dentro (las de los pisos, con su sangre, salen de aquí con tools/puertas_sucias.py)
mueble("puerta-bano", [[21, 6, 26, 19]], lambda c: c[1] < c[0] * 0.62)
