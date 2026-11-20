"""La piel de un zombi, del mismo verde que la del vecino (el durmiente normal, zombi-normal-gpt).

La usan tools/zombi.py ("piel_verde" en zombi.json) y tools/hoja_112.py ("piel_verde" en hoja.json), sobre cada
dibujo ya terminado (la casilla de la hoja), para que todos los durmientes normales tengan la piel del mismo color
(lo pidió el dueño el 20 nov).

Qué es piel: los colores de un tono, una viveza y una claridad (lo que diga la ficha de cada zombi), y de eso solo
las manchas de bastante tamaño. Lo que no cumple, no se toca: ni la ropa, ni el pelo, ni la boca, ni la sangre.

Cómo queda: el tono del vecino (78 grados) y su viveza, que es poca en las sombras (0,28) y sube en las luces
(como en su dibujo: 0,28 + (claridad - 0,5) × 1,5). La claridad es la de antes, salvo que la ficha diga otra cosa
("luz"), para que un zombi muy pálido no salga verde chillón.

En la ficha, "piel_verde": {...} con:
  "tono": [h0, h1]        tono de la piel de ese zombi, en grados (si h0 > h1, da la vuelta: [340, 30] es rojo)
  "viveza": [s0, s1]      viveza (saturación) de su piel
  "claridad": [l0, l1]    claridad de su piel (lo más oscuro, el contorno, no se toca)
  "mancha": 6             tamaño mínimo de una mancha de piel en píxeles (las sueltas más pequeñas no cambian)
  "grueso": true          y solo las manchas con grosor: por lo menos un píxel con sus cuatro vecinos también de piel
                          (así no se cuelan las rayas finas del color de la piel, como la franja reflectante de los
                          vigilantes; no vale para los de brazos finos, de 2 píxeles, como el oficinista)
  "sombra": {...}         las sombras de la piel, de otro color (las del arrastrado, marrón oscuro como su pelo): los
                          colores que cumplen eso ("tono", "viveza", "claridad") y están pegados a la piel elegida, hasta
                          "pasos" píxeles de distancia (2 si no dice), también son piel
  "huecos": {...}         los huecos de otro color dentro de la piel (las sombras marrones de la cara del arrastrado,
                          alrededor de la boca, del mismo marrón que su cuerpo): los colores que cumplen eso ("tono",
                          "viveza", "claridad") con piel a los dos lados, a "ancho" píxeles o menos (4 si no dice), en su
                          fila o en su columna, también son piel; se repite "pasos" veces (2 si no dice). El cuerpo no
                          entra: queda lejos de los brazos. Lo muy oscuro (el hueco de la boca) se deja fuera con "claridad"
  "barbilla": {...}       la parte de abajo de la cara aunque sea de otro color (la mandíbula del arrastrado, marrón como
                          su cuerpo, que al abrir la boca se veía marrón): debajo de la cara (la mancha de piel más alta,
                          si empieza a "arriba" píxeles o menos de lo alto del dibujo, 8, tiene "ancho" píxeles o más en
                          sus 4 primeras filas, si lo dice, y "alto" filas o menos, 10), hasta "filas" filas más abajo (5) y solo
                          tan ancha como la cara en sus últimas filas, los colores que cumplen eso ("tono", "viveza",
                          "claridad"). Con "lado": {...}, también los colores así pegados a la mitad de abajo de la cara
                          (de perfil, la barbilla y la boca por delante), hasta "pasos" píxeles (2). "sin": [...] las
                          direcciones en las que no (de espaldas, donde la mancha más alta es un trozo de mejilla y
                          debajo está la espalda: solo lo sabe tools/zombi.py)
  "luz": [k, suma]        la claridad nueva es la de antes × k + suma (lo normal, [1, 0])
  "fuera": [[...], ...]   otros colores que no son piel, cada uno como {"tono": [...], "viveza": [...], "claridad": [...]}
                          (por ejemplo, el pelo rubio del crío, que tiene el mismo tono que su piel)
  "a_tono": 78, "a_viveza": 0.28, "a_sube": 1.5   el verde al que va (el del vecino; no hace falta ponerlos)
"""
import colorsys


def _en(v, r):
    a, b = r
    return a <= v <= b if a <= b else (v >= a or v <= b)


class PielVerde:
    def __init__(self, opc, no_tocar=()):
        self.o = opc
        self.no_tocar = set(no_tocar)   # colores que ya ha puesto otro paso (el chaleco neón) y no se tocan
        self.cache = {}
        self.cache_f = {}

    def es_piel(self, c):
        if c in self.no_tocar:
            return False
        h, l, s = colorsys.rgb_to_hls(*[v / 255 for v in c])
        h *= 360
        o = self.o
        if not (_en(h, o.get('tono', [55, 110])) and _en(s, o.get('viveza', [0.08, 1]))
                and _en(l, o.get('claridad', [0.1, 0.9]))):
            return False
        for f in o.get('fuera', []):
            if (_en(h, f.get('tono', [0, 360])) and _en(s, f.get('viveza', [0, 1]))
                    and _en(l, f.get('claridad', [0, 1]))):
                return False
        return True

    def verde(self, c):
        o = self.o
        h, l, s = colorsys.rgb_to_hls(*[v / 255 for v in c])
        k, suma = o.get('luz', [1, 0])
        l2 = max(0.0, min(0.76, l * k + suma))
        s2 = min(0.7, o.get('a_viveza', 0.28) + max(0, l2 - 0.5) * o.get('a_sube', 1.5))
        return tuple(round(v * 255) for v in colorsys.hls_to_rgb(o.get('a_tono', 78) / 360, l2, s2))

    def elegir(self, im, mira=None):
        """Los píxeles de piel de un dibujo (una casilla), como conjunto de (x, y). `mira`: hacia dónde mira ese
        dibujo ('south', 'north-east'...), si se sabe (para "barbilla" y su "sin")."""
        px = im.load()
        w, h = im.size
        cand = set()
        for y in range(h):
            for x in range(w):
                p = px[x, y]
                if p[3] >= 128:
                    c = p[:3]
                    if c not in self.cache:
                        self.cache[c] = self.verde(c) if self.es_piel(c) else None
                    if self.cache[c]:
                        cand.add((x, y))
        minimo, grueso = self.o.get('mancha', 6), self.o.get('grueso', False)
        piel, vistos = set(), set()
        for q in cand:
            if q in vistos:
                continue
            zona, i = [q], 0
            vistos.add(q)
            while i < len(zona):
                x, y = zona[i]
                i += 1
                for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if r in cand and r not in vistos:
                        vistos.add(r)
                        zona.append(r)
            if len(zona) >= minimo and (not grueso or any(
                    all(r in cand for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))) for x, y in zona)):
                piel.update(zona)
        sombra = self.o.get('sombra')
        if sombra:
            borde = set(piel)
            for _ in range(sombra.get('pasos', 2)):
                nuevo = set()
                for x, y in borde:
                    for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if (r not in piel and 0 <= r[0] < w and 0 <= r[1] < h and px[r][3] >= 128
                                and self._cumple(px[r][:3], sombra)):
                            nuevo.add(r)
                piel |= nuevo
                borde = nuevo
        huecos = self.o.get('huecos')
        if huecos:
            ancho = huecos.get('ancho', 4)
            for _ in range(huecos.get('pasos', 2)):
                nuevo = set()
                for y in range(h):
                    for x in range(w):
                        if (x, y) in piel or px[x, y][3] < 128 or not self._cumple(px[x, y][:3], huecos):
                            continue
                        lados = [any((x + i * dx, y + i * dy) in piel for i in range(1, ancho + 1))
                                 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                        if (lados[0] and lados[1]) or (lados[2] and lados[3]):
                            nuevo.add((x, y))
                if not nuevo:
                    break
                piel |= nuevo
        barbilla = self.o.get('barbilla')
        if barbilla and piel and mira not in barbilla.get('sin', []):
            piel |= self._barbilla(px, w, h, piel, barbilla)
        return piel

    def _barbilla(self, px, w, h, piel, b):
        """La parte de abajo de la cara (la mandíbula, alrededor de la boca), aunque sea de otro color: debajo de la
        mancha de piel más alta (la cara), hasta "filas" filas más abajo y solo tan ancho como la cara en sus últimas
        filas; los colores que cumplen la regla, también son piel."""
        # la cara: la mancha de piel (con 4 vecinos) que empieza más arriba
        resto, cara = set(piel), None
        while resto:
            q = resto.pop()
            zona, i = [q], 0
            while i < len(zona):
                x, y = zona[i]
                i += 1
                for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if r in resto:
                        resto.discard(r)
                        zona.append(r)
            if len(zona) >= b.get('minimo', 12) and (cara is None or min(y for _, y in zona) < min(y for _, y in cara)):
                cara = zona
        if not cara:
            return set()
        # y solo si es la cara de verdad: empieza arriba del todo (de espaldas, la mancha más alta es un brazo o un
        # trozo de mejilla, mucho más abajo, y debajo está la espalda)
        arriba = next(y for y in range(h) if any(px[x, y][3] >= 128 for x in range(w)))
        y0 = min(y for _, y in cara)
        if y0 - arriba > b.get('arriba', 8):
            return set()
        # y, si la ficha lo pide, ancha por arriba (de tres cuartos por detrás asoma una tira de mejilla de 2 píxeles;
        # el arrastrado no lo usa: de perfil, andando, su cara es de 3 y la espalda la quita "sin")
        if max(sum(1 for _, y in cara if y == yy) for yy in range(y0, y0 + 4)) < b.get('ancho', 0):
            return set()
        fondo = max(y for _, y in cara)
        # y no muy alta: más de "alto" filas (10) es que enseña el cuello (la cabeza echada atrás) o que va pegada a
        # un brazo, y debajo ya no está la mandíbula sino la camisa
        if fondo - y0 + 1 > b.get('alto', 10):
            return set()
        bajos = [x for x, y in cara if y >= fondo - 2]
        xa, xb = min(bajos) + b.get('margen', 0), max(bajos) - b.get('margen', 0)
        nuevo = set()
        for y in range(fondo - 3, min(h, fondo + 1 + b.get('filas', 5))):
            for x in range(max(0, xa), min(w, xb + 1)):
                if ((x, y) not in piel and px[x, y][3] >= 128 and self._cumple(px[x, y][:3], b)
                        and any((x, yy) in piel for yy in range(y - 1, y - 8, -1))):
                    nuevo.add((x, y))
        # y el borde de la cara (de perfil, la barbilla y la boca por delante son de un oliva y un marrón oscuros):
        # los colores de "lado" pegados a la cara, hasta "pasos" píxeles (2); solo desde la cara, no desde los brazos
        lado = b.get('lado')
        if lado:
            mitad = y0 + (fondo - y0) * lado.get('desde', 0.5)   # solo la mitad de abajo (arriba está el pelo)
            hecho, borde = set(cara) | nuevo, set(cara)
            for _ in range(lado.get('pasos', 2)):
                sig = set()
                for x, y in borde:
                    for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if (r not in hecho and r not in piel and r[1] >= mitad and 0 <= r[0] < w and r[1] < h
                                and px[r][3] >= 128 and self._cumple(px[r][:3], lado)):
                            sig.add(r)
                hecho |= sig
                nuevo |= sig
                borde = sig
        return nuevo

    def _cumple(self, c, f):
        k = (c, id(f))
        if k not in self.cache_f:
            h, l, s = colorsys.rgb_to_hls(*[v / 255 for v in c])
            self.cache_f[k] = (c not in self.no_tocar and _en(h * 360, f.get('tono', [0, 360]))
                               and _en(s, f.get('viveza', [0, 1])) and _en(l, f.get('claridad', [0, 1])))
        return self.cache_f[k]

    def pintar(self, im, mascara=None, mira=None):
        """Pasa la piel al verde del vecino (o, con `mascara`, la pinta de ese color para comprobar lo elegido)."""
        px = im.load()
        for q in self.elegir(im, mira):
            c = px[q][:3]
            px[q] = (mascara or self.cache.get(c) or self.verde(c)) + (px[q][3],)
        return im


def en_hoja(sheet, cw, ch, opc, no_tocar=(), mascara=None, miran=None):
    """Lo mismo, casilla a casilla en una hoja de casillas iguales (la de tools/zombi.py). `miran`: {(columna, fila):
    hacia dónde mira}, para "barbilla"."""
    pv = PielVerde(opc, no_tocar)
    for fy in range(sheet.height // ch):
        for fx in range(sheet.width // cw):
            caja = (fx * cw, fy * ch, (fx + 1) * cw, (fy + 1) * ch)
            c = sheet.crop(caja)
            if c.getbbox():
                sheet.paste(pv.pintar(c, mascara, (miran or {}).get((fx, fy))), caja[:2])
    return sheet
