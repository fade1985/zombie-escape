"""Las placas de latón de los pisos, rotas (L21 y L28 de PENDIENTES): la letra de cada piso junto a su puerta (mapa/puerta.gd).

Saca dos hojas con las cuatro letras, A, B, C y D, una al lado de otra, hechas píxel a píxel (a este tamaño PixelLab no dibuja):
  assets/sprites/placa-rota-pared.png   gastada, con una esquina arrancada, y torcida en su sitio: las de la pared de arriba
  assets/sprites/placa-rota-suelo.png   arrancada y tirada en el suelo, con el trozo y los tornillos al lado: las de la pared de abajo

Las medidas, en píxeles del dibujo (cada uno, 2 unidades): la placa, 11 × 13, como la de latón que se pintaba antes. Lo gastado va
por el borde, para que la letra se siga leyendo. Usa siempre las mismas semillas: al lanzarlo otra vez salen los mismos dibujos.

  py tools/placas_rotas.py     (y luego, para que Godot las importe: Godot --headless --path . --import)
"""
import random
from PIL import Image

SPRITES = "assets/sprites"
ANCHO, ALTO = 11, 13
LADO_PARED = (16, 17)     # lo que mide cada placa en su hoja, con su sombra
LADO_SUELO = 26
LUZ, MEDIO, SOMBRA, FILO = (190, 160, 88), (150, 118, 54), (96, 74, 32), (46, 32, 16)
LETRA = (40, 27, 15)
OXIDO, VERDIN, MELLA = (112, 66, 32), (92, 116, 88), (226, 206, 146)
LETRAS = {
    "A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    "B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
    "C": [".XXX.", "X...X", "X....", "X....", "X....", "X...X", ".XXX."],
    "D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
}
# Cada placa, a su manera: la esquina arrancada (de qué lado), lo que se tuerce en la pared (píxeles que se corre de arriba abajo)
# y cómo cae al suelo (lo que se corre a lo ancho y a lo alto, y adónde va el trozo que se suelta)
ROTURAS = {
    "A": {"esquina": (1, -1), "tuerce": 2, "cae": (2, 1), "trozo": (6, -6)},
    "B": {"esquina": (-1, 1), "tuerce": -2, "cae": (-2, 1), "trozo": (-6, 6)},
    "C": {"esquina": (1, 1), "tuerce": 2, "cae": (2, -1), "trozo": (7, 5)},
    "D": {"esquina": (-1, -1), "tuerce": -2, "cae": (-2, -1), "trozo": (-7, -5)},
}


# La placa gastada: un diccionario {(x, y): color}, sin torcer, y aparte la esquina que se ha arrancado
def placa(letra):
    dado = random.Random(letra)
    p = {}
    for y in range(ALTO):
        for x in range(ANCHO):
            if x in (0, ANCHO - 1) or y in (0, ALTO - 1):
                p[x, y] = FILO
            elif x == ANCHO - 2 or y == ALTO - 2:
                p[x, y] = SOMBRA
            elif x == 1 or y == 1:
                p[x, y] = LUZ
            else:
                p[x, y] = MEDIO
    # el óxido y el verdín, por el borde
    orilla = [q for q in p if p[q] != FILO and (q[0] in (1, 2, ANCHO - 3, ANCHO - 2) or q[1] in (1, 2, ALTO - 3, ALTO - 2))]
    for q in dado.sample(orilla, 13):
        p[q] = dado.choice([OXIDO, OXIDO, VERDIN, SOMBRA])
    for fila, linea in enumerate(LETRAS[letra]):
        for columna, c in enumerate(linea):
            if c == "X":
                p[3 + columna, 3 + fila] = LETRA
    # la letra, con un par de píxeles saltados
    for q in dado.sample([q for q in p if p[q] == LETRA], 2):
        p[q] = SOMBRA
    # la esquina arrancada, por una línea dentada, con un filo brillante donde se ha roto
    sx, sy = ROTURAS[letra]["esquina"]
    trozo = {}
    for x, y in list(p):
        u = ANCHO - 1 - x if sx > 0 else x
        v = ALTO - 1 - y if sy > 0 else y
        if u + v < 3 + (x + y) % 2:
            trozo[x, y] = p.pop((x, y))
    for x, y in list(p):
        if any((x + dx, y + dy) in trozo for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            p[x, y] = MELLA if p[x, y] != LETRA and dado.random() < 0.4 else FILO
    # los tornillos: uno que queda, y el agujero de los que han saltado
    for i, q in enumerate(((1, 1), (ANCHO - 2, 1), (1, ALTO - 2), (ANCHO - 2, ALTO - 2))):
        if q in p:
            p[q] = MELLA if i == "ABCD".index(letra) else FILO
    return p, trozo


def hoja_pared():
    hoja = Image.new("RGBA", (LADO_PARED[0] * 4, LADO_PARED[1]), (0, 0, 0, 0))
    for k, letra in enumerate(LETRAS):
        p, _ = placa(letra)
        ox = k * LADO_PARED[0] + 2
        tuerce = ROTURAS[letra]["tuerce"]
        corrida = lambda y: round(tuerce * (y / (ALTO - 1) - 0.5))
        for y in range(ALTO):      # la marca que deja en la pared, donde estaba derecha
            for x in range(ANCHO):
                hoja.putpixel((ox + x, 1 + y), (0, 0, 0, 50))
        for (x, y), c in p.items():   # su sombra, y encima ella
            hoja.putpixel((ox + x + corrida(y) + 1, 2 + y), (0, 0, 0, 120))
        for (x, y), c in p.items():
            hoja.putpixel((ox + x + corrida(y), 1 + y), c + (255,))
    hoja.save(SPRITES + "/placa-rota-pared.png")


def hoja_suelo():
    hoja = Image.new("RGBA", (LADO_SUELO * 4, LADO_SUELO), (0, 0, 0, 0))
    for k, letra in enumerate(LETRAS):
        dado = random.Random(letra + "suelo")
        p, trozo = placa(letra)
        r = ROTURAS[letra]
        lienzo = Image.new("RGBA", (LADO_SUELO, LADO_SUELO), (0, 0, 0, 0))
        ox, oy = (LADO_SUELO - ANCHO) // 2, (LADO_SUELO - ALTO) // 2
        for (x, y), c in p.items():
            # tirada de cualquier manera: se corre a lo ancho y a lo alto, y la mitad doblada queda en sombra
            dx = round(r["cae"][0] * (y / (ALTO - 1) - 0.5))
            dy = round(r["cae"][1] * ((x + dx) / (ANCHO - 1) - 0.5))
            k_luz = 0.8 if x + y > (ANCHO + ALTO) * 0.62 else 1.0
            lienzo.putpixel((ox + x + dx, oy + y + dy), tuple(int(v * k_luz) for v in c) + (255,))
        for (x, y), c in trozo.items():   # la esquina arrancada, un poco más allá
            lienzo.putpixel((ox + x + r["trozo"][0], oy + y + r["trozo"][1]), c + (255,))
        for _ in range(2):                # los tornillos sueltos
            lienzo.putpixel((dado.randrange(2, LADO_SUELO - 2), dado.randrange(LADO_SUELO - 7, LADO_SUELO - 2)), MELLA + (255,))
        # la sombra, pegada al suelo: un píxel más abajo
        for y in range(LADO_SUELO - 2, -1, -1):
            for x in range(LADO_SUELO):
                if lienzo.getpixel((x, y))[3] == 255 and lienzo.getpixel((x, y + 1))[3] == 0:
                    lienzo.putpixel((x, y + 1), (0, 0, 0, 130))
        hoja.paste(lienzo, (k * LADO_SUELO, 0))
    hoja.save(SPRITES + "/placa-rota-suelo.png")


if __name__ == "__main__":
    hoja_pared()
    hoja_suelo()
