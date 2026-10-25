# La hoja de Johnny con el lanza ácido (por dentro, el desintegrador): la del lanzallamas, con las dos bombonas de la
# espalda en verde ácido en vez de rojo y sin la llamita del piloto en la punta del tubo (la gota de ácido que cuelga de
# la punta la pinta el juego). Sin PixelLab: el lanza ácido es un lanzallamas que echa ácido, con el mismo dibujo.
#   1. Los rojos de las bombonas (solo salen en las bombonas: se pintaron sobre el gris de PixelLab, 8e3966d1) pasan
#      cada uno a su verde, con el verde del ácido del juego (#c7e04a, EFECTOS.acido de armas_creadas.gd) en el medio.
#   2. La llamita: en cada dibujo se busca, cerca de la punta del tubo de su dirección (la boca del lanzallamas en
#      armas.gd), el píxel de color de llama que más sale hacia donde apunta, y se borra con lo que tenga pegado de los
#      colores de la llama (y lo de otro color que esté casi rodeado de llama o de aire: el humo gris de arriba). Luego,
#      las chispitas que queden sueltas en el aire, y los huecos que deja la llama dentro de Johnny (de frente, la llama
#      tapaba las perneras) se rellenan con el color de alrededor. Los colores de la llama también son de la piel y la
#      camisa: por eso solo se mira cerca de la punta.
# Saca assets/sprites/conserje-48-desintegrador.png, su .json y su .tres (los de la hoja del lanzallamas, con su
# imagen). Las skins, después, con tools/cara.py (que mira estos verdes como si fueran los grises de PixelLab, COMO_GRIS):
#   py tools/hoja_lanza_acido.py            → la hoja (y luego, para cada skin, py tools/cara.py <skin> desintegrador)
#   py tools/hoja_lanza_acido.py muestra    → además, captura-lanza-acido.png: la punta del tubo en todos los dibujos,
#                                             antes y después, al cuádruple, para revisarla
import json
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
SPRITES = RAIZ / "assets" / "sprites"
DE = "conserje-48-lanzallamas"
A = "conserje-48-desintegrador"
# Cada rojo de las bombonas por su verde: brillo, medio, medio tostado, sombra tostada y sombra (el brillo, más amarillo;
# las sombras, más azuladas, como en los grises que dibujó PixelLab)
VERDES = {
    (238, 96, 74): (236, 248, 150),
    (200, 58, 40): (199, 224, 74),
    (166, 50, 36): (150, 180, 48),
    (122, 40, 30): (96, 128, 40),
    (78, 36, 34): (48, 80, 44),
}
# Los colores de la llamita del piloto (todos salen también en la piel, la camisa o el pañuelo de Johnny)
LLAMA = {(232, 46, 38), (168, 30, 35), (185, 87, 60), (244, 135, 92), (249, 161, 110), (251, 179, 134), (238, 148, 111),
         (242, 161, 123), (243, 217, 168), (249, 230, 188), (253, 254, 249)}
# La punta del tubo de cada dirección desde los pies (la boca del lanzallamas en armas.gd) y hacia dónde apunta
BOCA = {"south": (2, 1), "south-east": (26, -13), "east": (28, -22), "north-east": (24, -39), "north": (8, -52),
        "north-west": (-25, -40), "west": (-28, -21), "south-west": (-24, -10)}
HACIA = {"south": (0, 1), "south-east": (2, 1), "east": (1, 0), "north-east": (3, -2), "north": (0, -1),
         "north-west": (-3, -2), "west": (-1, 0), "south-west": (-2, 1)}
CERCA = 12     # hasta dónde de la punta del lanzallamas se busca la llama (los dibujos de andar la mueven)
LARGO = 8      # lo más lejos que llega la llama del píxel que más sale
CHISPAS = 10   # y sus chispitas sueltas
VECINOS = [(dx, dy) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dx or dy]
# Los grises del tubo, y los tostados con los que la llama encendía su punta
TUBO = {(52, 63, 76), (119, 142, 155), (143, 130, 120), (163, 184, 199), (8, 8, 9)}
LUZ = {(175, 109, 50), (182, 140, 95)}


def fotogramas(datos):
    """[(animación, dirección, fila, columna)] de todos los dibujos de la hoja (como en cara.py)."""
    lista = []
    for anim, v in datos["anims"].items():
        for direc, dv in v["dirs"].items():
            for i in range(dv["frames"]):
                lista.append((anim, direc, dv["row"], dv.get("col", 0) + i))
    return lista


def quitar_llama(px, x0, y0, cw, ch, pivote, direc):
    """Borra la llamita del dibujo de la casilla (x0, y0). Devuelve cuántos píxeles ha borrado."""
    bx, by = pivote[0] + BOCA[direc][0], pivote[1] + BOCA[direc][1]
    hx, hy = HACIA[direc]

    def color(x, y):
        return px[x0 + x, y0 + y] if 0 <= x < cw and 0 <= y < ch else (0, 0, 0, 0)

    def de_llama(c):
        return c[3] and c[:3] in LLAMA

    def rodeado(x, y):
        """Si casi todo lo de alrededor es llama o aire (el humo y las chispas de otro color)."""
        return sum(color(x + dx, y + dy)[3] == 0 or de_llama(color(x + dx, y + dy)) for dx, dy in VECINOS) >= 6

    zona = [(x, y) for y in range(max(0, by - CERCA), min(ch, by + CERCA + 1))
            for x in range(max(0, bx - CERCA), min(cw, bx + CERCA + 1))]
    llama = [(x, y) for x, y in zona if de_llama(color(x, y))]
    if not llama:
        return 0
    # el que más sale hacia donde apunta, mejor con más llama al lado (si no, podría ser una chispa suelta)
    juntos = [(x, y) for x, y in llama if sum(de_llama(color(x + dx, y + dy)) for dx, dy in VECINOS) >= 2]
    sx, sy = max(juntos or llama, key=lambda p: p[0] * hx + p[1] * hy)
    # lo que va pegado a ese píxel con colores de llama (o casi rodeado de llama o de aire)
    borrar, cola = {(sx, sy)}, [(sx, sy)]
    while cola:
        x, y = cola.pop()
        for dx, dy in VECINOS:
            n = (x + dx, y + dy)
            if n in borrar or max(abs(n[0] - sx), abs(n[1] - sy)) > LARGO or not color(*n)[3]:
                continue
            if de_llama(color(*n)) or rodeado(*n):
                borrar.add(n)
                cola.append(n)
    # las chispitas: colores de llama sueltos en el aire (sin nada más alrededor)
    for x, y in llama:
        if (x, y) not in borrar and max(abs(x - sx), abs(y - sy)) <= CHISPAS and all(
                color(x + dx, y + dy)[3] == 0 or de_llama(color(x + dx, y + dy)) for dx, dy in VECINOS):
            borrar.add((x, y))
    for x, y in borrar:
        px[x0 + x, y0 + y] = (0, 0, 0, 0)
    # lo que haya quedado suelto en el aire cerca de la llama (manchitas de hasta 3 píxeles, de cualquier color)
    vistos = set()
    for x, y in zona:
        if (x, y) in vistos or not color(x, y)[3] or max(abs(x - sx), abs(y - sy)) > CHISPAS:
            continue
        mancha, cola = {(x, y)}, [(x, y)]
        while cola and len(mancha) <= 3:
            a, b = cola.pop()
            for dx, dy in VECINOS:
                n = (a + dx, b + dy)
                if n not in mancha and color(*n)[3]:
                    mancha.add(n)
                    cola.append(n)
        vistos |= mancha
        if len(mancha) <= 3:
            for a, b in mancha:
                px[x0 + a, y0 + b] = (0, 0, 0, 0)
                borrar.add((a, b))
    # los huecos que deja dentro de Johnny: se rellenan con el color que más hay alrededor (varias pasadas, de fuera a dentro).
    # De frente la llama tapaba las perneras y las botas: ahí se rellena también lo que tenga medio alrededor lleno
    for _ in range(6):
        rellenos = {}
        for x, y in borrar:
            if color(x, y)[3]:
                continue
            alrededor = [color(x + dx, y + dy) for dx, dy in VECINOS if color(x + dx, y + dy)[3]]
            if len(alrededor) >= (4 if direc == "south" else 5):
                rellenos[(x, y)] = max(alrededor, key=alrededor.count)
        if not rellenos:
            break
        for (x, y), c in rellenos.items():
            px[x0 + x, y0 + y] = c
    # la punta del tubo, que la llama iluminaba de naranja: cada píxel encendido junto a lo borrado, al gris del tubo de al
    # lado (de frente no: ahí lo de al lado de la llama son las botas)
    if direc != "south":
        luces = {}
        for x, y in borrar:
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    c = color(x + dx, y + dy)
                    if c[3] and (c[:3] in LUZ or c[:3] in LLAMA):
                        grises = [color(x + dx + a, y + dy + b)[:3] for a, b in VECINOS
                                  if color(x + dx + a, y + dy + b)[3] and color(x + dx + a, y + dy + b)[:3] in TUBO]
                        if grises:
                            luces[(x + dx, y + dy)] = max(grises, key=grises.count) + (c[3],)
        for (x, y), c in luces.items():
            px[x0 + x, y0 + y] = c
    return len(borrar)


def revisar(antes, despues, lista, cw, ch, pivote, salida):
    """La punta del tubo de cada dibujo, antes (arriba) y después (abajo), una fila por dirección, al cuádruple."""
    lado = 2 * CERCA + 1
    por_dir = {d: [f for f in lista if f[1] == d] for d in BOCA}
    cols = max(len(v) for v in por_dir.values())
    img = Image.new("RGBA", (cols * lado, len(BOCA) * lado * 2), (190, 190, 200, 255))
    for i, (direc, fs) in enumerate(por_dir.items()):
        bx, by = pivote[0] + BOCA[direc][0], pivote[1] + BOCA[direc][1]
        for k, (_, _, fila, col) in enumerate(fs):
            caja = (col * cw + bx - CERCA, fila * ch + by - CERCA, col * cw + bx + CERCA + 1, fila * ch + by + CERCA + 1)
            img.alpha_composite(antes.crop(caja), (k * lado, i * lado * 2))
            img.alpha_composite(despues.crop(caja), (k * lado, i * lado * 2 + lado))
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(salida)


def main():
    datos = json.load(open(SPRITES / f"{DE}.json", encoding="utf-8"))
    cw, ch = datos["cell"]
    pivote = datos["pivot"]
    hoja = Image.open(SPRITES / f"{DE}.png").convert("RGBA")
    antes = hoja.copy()
    px = hoja.load()
    verdes = 0
    for y in range(hoja.height):
        for x in range(hoja.width):
            c = px[x, y]
            if c[3] and c[:3] in VERDES:
                px[x, y] = VERDES[c[:3]] + (c[3],)
                verdes += 1
    lista = fotogramas(datos)
    sin_llama = []
    borrados = 0
    for _, direc, fila, col in lista:
        n = quitar_llama(px, col * cw, fila * ch, cw, ch, pivote, direc)
        borrados += n
        if not n:
            sin_llama.append(f"{direc} {fila},{col}")
    hoja.save(SPRITES / f"{A}.png", optimize=True)
    datos["source"] = f"Hecha con tools/hoja_lanza_acido.py a partir de {DE}.png (la del lanzallamas)"
    with open(SPRITES / f"{A}.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
        f.write("\n")
    tres = (SPRITES / f"{DE}.tres").read_text(encoding="utf-8")
    (SPRITES / f"{A}.tres").write_text(tres.replace(f"{DE}.png", f"{A}.png"), encoding="utf-8", newline="\n")
    print(f"{A}: {verdes} píxeles de las bombonas en verde; {len(lista)} dibujos, {borrados} píxeles de llama borrados",
          f"(sin llama que borrar: {', '.join(sin_llama)})" if sin_llama else "")
    if "muestra" in sys.argv:
        revisar(antes, hoja, lista, cw, ch, pivote, RAIZ / "captura-lanza-acido.png")


if __name__ == "__main__":
    main()
