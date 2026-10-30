# El logo del menú principal (menu_principal.gd) y del final del trailer (pruebas/trailer.gd): «JOHNNY RUSH» grande y
# «ZOMBIE ESCAPE» más pequeño debajo. No está dibujado a mano: lo genera este programa, que es el de src/titulo.js del juego
# JS pasado a Python (el logo de antes, «ZOMBIE ESCAPE», salía de ahí). Cada letra es una cuadrícula de 5×7 que se amplía y se
# engorda un píxel; luego se le pone relieve (luz arriba y a la izquierda, sombra abajo y a la derecha, y franjas de color de
# arriba abajo), brillitos, goteos de baba o sangre, un borde oscuro con volumen y un filo crema alrededor de todo.
#   py tools/logo.py                → assets/ui/logo.png con los colores elegidos (VARIANTE)
#   py tools/logo.py <variante>     → capturas/logo-<variante>.png, para ver otro reparto de colores sin tocar el del juego
#   py tools/logo.py todas          → una muestra con todos los repartos, sobre el fondo del menú (capturas/logo-todas.png)
#   py tools/logo.py viejo          → capturas/logo-viejo.png: «ZOMBIE ESCAPE» como era (para comprobar que este programa
#                                     sigue haciendo lo mismo que el original: es idéntico al logo de antes)
# Para cambiar una letra se toca LETRAS; para otro tamaño, el estilo (Estilo) de cada línea; para otros colores, REPARTOS.
import sys
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
TINTA = (29, 27, 44)      # el borde oscuro de las letras
FILO = (255, 244, 214)    # el filo crema de todo el contorno
BLANCO = (255, 255, 255)

# Los colores de cada letra, por franjas (de arriba abajo: luz, base, sombra y borde de abajo) y el de los goteos
VERDE = {"hi": (216, 255, 107), "base": (126, 211, 33), "mid": (79, 168, 26), "low": (47, 111, 28), "drip": (126, 211, 33)}
ROJO = {"hi": (255, 154, 138), "base": (238, 59, 59), "mid": (184, 31, 43), "low": (122, 20, 36), "drip": (214, 42, 51)}
# El hueso (para un nombre que no pelee con el verde y el rojo): la misma idea, en grises cálidos
HUESO = {"hi": (255, 250, 232), "base": (226, 214, 184), "mid": (170, 156, 128), "low": (104, 94, 80), "drip": (200, 186, 156)}

# Cada letra, en una cuadrícula de 5 de ancho por 7 de alto ("1" = hay pintura). Las que no están en «ZOMBIE ESCAPE» (J, H, N,
# Y, R y U) siguen el mismo estilo: trazos de un solo punto, esquinas redondeadas y diagonales que se tocan por la esquina
LETRAS = {
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10101", "10101", "10011", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
}


class Estilo:
    # s: cada punto de la letra ocupa s×s píxeles del dibujo · hueco: entre una letra y otra · margen: para el borde y el filo ·
    # grosor: lo que baja el borde oscuro (el "canto" de la letra) · goteo: el largo máximo de un goteo
    def __init__(self, s, hueco, margen, grosor, goteo):
        self.s, self.hueco, self.margen, self.grosor, self.goteo = s, hueco, margen, grosor, goteo
        self.ancho_letra = 5 * s + 1   # el +1 es el engorde
        self.alto_letra = 7 * s + 1


VIEJO = Estilo(3, 3, 4, 3, 10)     # el de «ZOMBIE ESCAPE» de antes
GRANDE = Estilo(3, 3, 4, 3, 10)    # «JOHNNY RUSH»
PEQUENO = Estilo(2, 3, 3, 2, 6)    # «ZOMBIE ESCAPE»

# Qué colores lleva cada línea: (palabras de la línea, estilo, colores de cada palabra, semillas de los goteos)
REPARTOS = {
    # el título en verde (zombi) y debajo, el nombre del juego en rojo (sangre): como el logo de antes, verde arriba y rojo abajo
    "verde-rojo": (VERDE, ROJO),
    # el título en rojo (sangre) y debajo, en verde (zombi)
    "rojo-verde": (ROJO, VERDE),
    # JOHNNY en verde y RUSH en rojo; debajo, en hueso para que no pelee
    "mixto": ((VERDE, ROJO), HUESO),
}
VARIANTE = "verde-rojo"   # la que lleva el juego


def tamano(palabra: str, e: Estilo) -> tuple[int, int]:
    return (len(palabra) * (e.ancho_letra + e.hueco) - e.hueco + e.margen * 2,
            e.alto_letra + e.goteo + e.grosor + e.margen * 2)


def dibujar_palabra(palabra: str, pal: dict, semilla: int, e: Estilo) -> dict:
    """La palabra dibujada: {(x, y): color} con su esquina de arriba a la izquierda en (0, 0)."""
    w, h = tamano(palabra, e)
    mascara = [[0] * w for _ in range(h)]   # 1 = pintura de letra
    col: dict = {}                            # el color final de cada píxel (lo que no está, es aire)

    def hay(x, y):
        return 0 <= x < w and 0 <= y < h and mascara[y][x] == 1

    def relleno(x, y):
        return (x, y) in col

    def cerca(x, y, r):
        return any(relleno(x + i, y + j) for j in range(-r, r + 1) for i in range(-r, r + 1))

    # 1) la forma de las letras, engordada un píxel hacia la derecha y hacia abajo
    for i, letra in enumerate(palabra):
        for ry, fila in enumerate(LETRAS[letra]):
            for rx, v in enumerate(fila):
                if v != "1":
                    continue
                for dy in range(e.s + 1):
                    for dx in range(e.s + 1):
                        mascara[e.margen + ry * e.s + dy][e.margen + i * (e.ancho_letra + e.hueco) + rx * e.s + dx] = 1

    # 2) el cuerpo: franjas de color de arriba abajo y relieve en los bordes
    for y in range(h):
        for x in range(w):
            if not hay(x, y):
                continue
            f = (y - e.margen) / e.alto_letra
            c = pal["hi"] if f < 0.14 else pal["base"] if f < 0.5 else pal["mid"] if f < 0.78 else pal["low"]
            if not hay(x, y - 1) or not hay(x - 1, y):
                c = pal["hi"]      # el borde iluminado (arriba y a la izquierda)
            elif not hay(x, y + 1) or not hay(x + 1, y):
                c = pal["low"]     # el borde en sombra (abajo y a la derecha)
            col[(x, y)] = c

    # 3) brillitos sueltos (destellos blancos)
    interior = w - e.margen * 2
    for sx, sy in [(2, 2), (interior - 4, 2), (interior // 2, 2)]:
        if hay(e.margen + sx, e.margen + sy):
            col[(e.margen + sx, e.margen + sy)] = BLANCO

    # 4) goteos que cuelgan de la parte baja de las letras, con su gota al final
    estado = [semilla]

    def azar():
        estado[0] = (estado[0] * 1664525 + 1013904223) & 0xFFFFFFFF
        return estado[0] / 4294967296

    fondo = e.margen + e.alto_letra - 1
    for x in range(e.margen, w - e.margen - 1, 4):
        if not hay(x, fondo) or not hay(x + 1, fondo) or azar() < 0.4:
            continue
        largo = 2 + int(azar() * (e.goteo - 3))
        for k in range(1, largo + 1):
            col[(x, fondo + k)] = pal["drip"]
            col[(x + 1, fondo + k)] = pal["low"] if k == largo else pal["mid"]
        col[(x, fondo + largo + 1)] = pal["mid"]

    # 5) el borde oscuro con volumen: rodea la letra y además baja "grosor" píxeles
    tinta = set()
    for y in range(h):
        for x in range(w):
            if relleno(x, y):
                continue
            if any(cerca(x, y - d, 1) for d in range(e.grosor + 1)):
                tinta.add((x, y))
    for p in tinta:
        col[p] = TINTA

    # 6) el filo crema alrededor de todo, para que el logo se lea sobre cualquier fondo
    filo = {(x, y) for y in range(h) for x in range(w) if not relleno(x, y) and cerca(x, y, 1)}
    for p in filo:
        col[p] = FILO
    return col


def poner(lienzo: Image.Image, palabra: dict, x0: int, y0: int) -> None:
    """Pinta la palabra en el lienzo con su esquina en (x0, y0): lo que es aire no tapa lo que ya había."""
    for (x, y), c in palabra.items():
        if 0 <= x0 + x < lienzo.width and 0 <= y0 + y < lienzo.height:
            lienzo.putpixel((x0 + x, y0 + y), (*c, 255))


def linea(palabras: list, colores, semillas: list, e: Estilo, espacio: int):
    """Varias palabras en una línea, separadas por "espacio" píxeles entre sus letras. Devuelve (ancho, alto, [(palabra, x)])."""
    if isinstance(colores, dict):
        colores = [colores] * len(palabras)
    x, puestas = 0, []
    for p, c, s in zip(palabras, colores, semillas):
        w, h = tamano(p, e)
        puestas.append((dibujar_palabra(p, c, s, e), x))
        x += w - e.margen * 2 + espacio   # el hueco se cuenta entre letras, sin los márgenes de cada palabra
    ancho = x - espacio + e.margen * 2
    return ancho, tamano(palabras[0], e)[1], puestas


def logo_viejo() -> Image.Image:
    """«ZOMBIE» y «ESCAPE», una debajo de la otra, como el logo de antes (para comprobar que esto sigue igual que el original)."""
    a, b = tamano("ZOMBIE", VIEJO), tamano("ESCAPE", VIEJO)
    w = max(a[0], b[0])
    y2 = VIEJO.alto_letra + VIEJO.margen + 6   # la segunda palabra tapa un poco los goteos de la primera
    lienzo = Image.new("RGBA", (w, y2 + b[1]), (0, 0, 0, 0))
    poner(lienzo, dibujar_palabra("ZOMBIE", VERDE, 7, VIEJO), (w - a[0]) // 2, 0)
    poner(lienzo, dibujar_palabra("ESCAPE", ROJO, 21, VIEJO), (w - b[0]) // 2, y2)
    return lienzo


def logo(variante: str = VARIANTE) -> Image.Image:
    """«JOHNNY RUSH» grande y «ZOMBIE ESCAPE» pequeño debajo, centrados, con los colores del reparto."""
    titulo_col, nombre_col = REPARTOS[variante]
    aw, ah, titulo = linea(["JOHNNY", "RUSH"], titulo_col, [11, 5], GRANDE, 9)
    bw, bh, nombre = linea(["ZOMBIE", "ESCAPE"], nombre_col, [7, 21], PEQUENO, 8)
    y2 = GRANDE.margen + GRANDE.alto_letra + 7   # debajo de los goteos del título
    w = max(aw, bw)
    lienzo = Image.new("RGBA", (w, y2 + bh), (0, 0, 0, 0))
    for p, x in titulo:
        poner(lienzo, p, (w - aw) // 2 + x, 0)
    for p, x in nombre:
        poner(lienzo, p, (w - bw) // 2 + x, y2)
    return lienzo.crop(lienzo.getbbox())


def con_margen(im: Image.Image, margen: int) -> Image.Image:
    """El dibujo con un poco de aire transparente alrededor (como llevaba el logo de antes)."""
    sal = Image.new("RGBA", (im.width + margen * 2, im.height + margen * 2), (0, 0, 0, 0))
    sal.paste(im, (margen, margen))
    return sal


def muestra(imagenes: dict, escala: int, ruta: Path) -> None:
    """Todos los dibujos juntos sobre el fondo del menú, ampliados sin suavizar, para compararlos."""
    ancho = max(im.width for im in imagenes.values()) * escala + 40
    alto = sum(im.height * escala + 40 for im in imagenes.values())
    fondo = Image.new("RGBA", (ancho, alto), (13, 10, 15, 255))
    y = 20
    for im in imagenes.values():
        g = im.resize((im.width * escala, im.height * escala), Image.NEAREST)
        fondo.alpha_composite(g, ((ancho - g.width) // 2, y))
        y += g.height + 40
    fondo.save(ruta)


if __name__ == "__main__":
    pedido = sys.argv[1] if len(sys.argv) > 1 else ""
    salidas = RAIZ / "capturas"
    salidas.mkdir(exist_ok=True)
    if pedido == "":
        con_margen(logo(), 2).save(RAIZ / "assets" / "ui" / "logo.png")
        print("assets/ui/logo.png")
    elif pedido == "viejo":
        logo_viejo().save(salidas / "logo-viejo.png")
    elif pedido == "todas":
        muestra({v: logo(v) for v in REPARTOS}, 3, salidas / "logo-todas.png")
    else:
        con_margen(logo(pedido), 2).save(salidas / f"logo-{pedido}.png")
