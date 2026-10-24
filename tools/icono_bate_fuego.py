# El icono del bate de fuego (el arma creada con el bate y la gasolina): el icono del bate (bate.png) con la punta gorda
# más baja y envuelta en trapos chamuscados, y una llama encima (naranja y amarilla, con borde oscuro de un píxel).
# Para hacer sitio a la llama arriba se quitan 4 filas del medio de la parte gorda y se baja la punta. 32×32.
#   py tools/icono_bate_fuego.py   → assets/ui/iconos/bate_fuego.png
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"
BORDE = (42, 31, 46, 255)         # el borde de los demás iconos
TRAPO_A = (92, 58, 40, 255)       # trapos chamuscados: dos tonos que se alternan
TRAPO_B = (60, 38, 30, 255)
ATADO = (140, 104, 70, 255)       # la cuerda que ata los trapos
BRASA = (255, 159, 28, 255)
LLAMA_ROJA = (214, 69, 18, 255)
LLAMA_NARANJA = (255, 159, 28, 255)
LLAMA_AMARILLA = (255, 214, 64, 255)
LLAMA_NUCLEO = (255, 244, 176, 255)

BAJA = 4   # cuántas filas se baja la punta (y se quitan del medio de la parte gorda)
PUNTA = 6  # filas de arriba del bate original que bajan; el resto de la parte gorda (de la 12 en adelante) se queda


def bate_bajado() -> Image.Image:
    bate = Image.open(ICONOS / "bate.png").convert("RGBA")
    nuevo = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    nuevo.paste(bate.crop((0, 0, 32, PUNTA)), (0, BAJA))          # la punta, más abajo
    nuevo.paste(bate.crop((0, PUNTA + BAJA, 32, 32)), (0, PUNTA + BAJA))   # de ahí hacia abajo, igual
    return nuevo


def trapos(im: Image.Image) -> None:
    """La punta gorda (las filas 5 a 10), de trapos chamuscados atados con una cuerda (la fila 11)."""
    px = im.load()
    for y in range(5, 11):
        for x in range(32):
            c = px[x, y]
            if not c[3] or max(c[:3]) < 70:   # sin nada, o el borde oscuro: se respeta
                continue
            px[x, y] = TRAPO_A if (y + x // 3) % 2 == 0 else TRAPO_B
    for x in range(32):                         # la cuerda, en la fila 11
        if px[x, 11][3] and max(px[x, 11][:3]) >= 70:
            px[x, 11] = ATADO
    for x, y in ((13, 8), (17, 9), (14, 10), (18, 7)):   # unas brasas entre los trapos
        if px[x, y][3]:
            px[x, y] = BRASA


def llama(im: Image.Image) -> None:
    """Tres lenguas de fuego que salen de la punta: una grande en medio y dos más pequeñas a los lados."""
    px = im.load()
    lenguas = [(15.0, 6, 6.0, 2.4), (12.3, 6, 3.5, 1.4), (18.0, 6, 4.8, 1.5)]   # centro x, fila de la base, alto, medio ancho
    pintado = {}
    for cx, base, alto, mitad in lenguas:
        for y in range(base, base - int(alto) - 1, -1):
            t = (base - y) / alto                       # 0 en la base, 1 en la punta
            m = mitad * (1 - t) ** 0.8 + (0.5 if t < 1 else 0.0)
            for x in range(32):
                d = abs(x - (cx + 0.6 * t))             # la llama se tuerce un poco hacia la derecha
                if d <= m:
                    k = d / max(m, 0.5)                  # 0 en el eje, 1 en el borde
                    if k < 0.28 and t < 0.55:
                        c = LLAMA_NUCLEO
                    elif k < 0.6 and t < 0.8:
                        c = LLAMA_AMARILLA
                    elif k < 0.85 and t < 0.92:
                        c = LLAMA_NARANJA
                    else:
                        c = LLAMA_ROJA
                    # donde se juntan dos lenguas gana la más clara
                    previo = pintado.get((x, y))
                    if previo is None or sum(c[:3]) > sum(previo[:3]):
                        pintado[(x, y)] = c
    for (x, y), c in pintado.items():
        px[x, y] = c
    for x, y in ((10, 2), (20, 1), (21, 4)):              # chispas sueltas
        if not px[x, y][3]:
            px[x, y] = BRASA


def borde(im: Image.Image, desde: int) -> None:
    """El borde oscuro de un píxel alrededor de la llama (solo de la fila `desde` hacia arriba, sin tocar la fila `desde`)."""
    px = im.load()
    marcar = []
    for y in range(desde):
        for x in range(32):
            if px[x, y][3] == 0:
                continue
            for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
                n = (x + dx, y + dy)
                if 0 <= n[0] < 32 and 0 <= n[1] < 32 and px[n][3] == 0:
                    marcar.append(n)
    for n in marcar:
        px[n] = BORDE


def main():
    im = bate_bajado()
    trapos(im)
    llama(im)
    borde(im, 7)
    salida = ICONOS / "bate_fuego.png"
    im.save(salida)
    print(salida)


main()
