# Dibuja los 2 objetos de la mochila que aún son de 16×16 píxeles: la batería y las vendas (más detalle que los de
# 10×10 de src/objetos.js, que les sirven de modelo): contorno oscuro, luz arriba a la izquierda y sombra abajo a la
# derecha. La batería era del centro comercial (parte 6 de docs/historial/CENTRO_COMERCIAL.md) y las vendas son de curar
# (parte 9). Todos los demás se quitaron o tienen ya dibujo de PixelLab, de 32×32, que este script NO toca: la gasolina
# y el bidón de ácido (assets/pixellab.json → municion-iconos) y las piezas de mejora de las armas (pieza_*, → piezas).
# Los objetos que se quitaron del juego: el mechero, la llave inglesa, el hacha, las cuchillas, el táser, la cuerda,
# las mancuernas, la cadena, las perchas, el hielo seco, el cable, los clavos, el spray de pintura, la lejía, la pistola
# de agua, la cinta americana, la bombona de gas, la jeringuilla, el aceite y el bocadillo (25 oct), y luego los
# explosivos, el despertador, el extintor, el trapo y el alcohol.
# Los saca en assets/ui/iconos/obj-<id>.png (los usan el suelo, la mochila, el baúl y el banco).
#   py tools/objetos16.py            → los iconos
#   py tools/objetos16.py muestra    → además, tools/objetos16.png con todos en grande, para revisarlos
from pathlib import Path
import sys

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ICONOS = RAIZ / "assets" / "ui" / "iconos"

# Una letra = un color (el punto es hueco). Las minúsculas son el tono normal; las mayúsculas, el oscuro
# (y P, L, W, c, l, h, e, s los claros)
PALETA = {
    "o": "#2a1f2e",                                   # contorno
    "k": "#1a1a1a", "K": "#3a3a44",                   # negro y gris muy oscuro
    "d": "#5d6470", "g": "#9aa0a8", "G": "#d0d4da",   # metal: sombra, medio, luz
    "W": "#ffffff",
    "r": "#d0453a", "R": "#8a2a2a", "P": "#ff7a6a",   # rojo
    "y": "#f2c94c", "Y": "#b88a1e", "L": "#fff0a0",   # amarillo
    "b": "#4a7bd0", "B": "#2a4f90", "c": "#8ab4f0",   # azul
    "w": "#f1f1e6", "e": "#c8c8b8",                   # blanco y su sombra
    "m": "#8a5a34", "M": "#5c3a20", "h": "#b07a48",   # madera
    "v": "#5aa05a", "V": "#3a6a3a", "l": "#8ad08a",   # verde
    "n": "#ff9f1c", "N": "#c06a10",                   # naranja
    "p": "#e07be0", "q": "#a04aa0",                   # rosa
    "a": "#c7e04a", "A": "#608028", "s": "#ecf896",   # verde ácido (el del lanza ácido)
}

DIBUJOS = {
    # la batería (era del centro comercial; ahora, la munición de la pistola eléctrica)
    "bateria": [
        "................",
        "...ooo....ooo...",
        "...oPo....oGo...",
        "...oro....odo...",
        ".oooooooooooooo.",
        ".oGGGGGGGGGGGdo.",
        ".oddddddddddddo.",
        ".oKKKKKKKKKKKko.",
        ".oKKrKKKKKKKKko.",
        ".oKrrrKKKKwwwko.",
        ".oKKrKKKKKKKKko.",
        ".oKKKKKKKKKKKko.",
        ".oKKKKKKKKKKKko.",
        ".okkkkkkkkkkkko.",
        ".oooooooooooooo.",
        "................",
    ],
    # las vendas, de curar (parte 9): el rollo de vendas con una tira con su cruz roja
    "vendas": [
        "................",
        "...oooooooo.....",
        "..oWwwwwwwweo...",
        ".oWwwwwwwwwweo..",
        ".owwwwwwwwwweo..",
        ".owwwwwwwwwweo..",
        ".oewwwwwwwwweo..",
        ".oeewwwwwwweeo..",
        "..oeeeeeeeeeo...",
        "...oooooooooo...",
        "......owwwwwwwo.",
        "......owwrwwwwo.",
        "......owrrrwwwo.",
        "......owwrwwwwo.",
        "......oeeeeeeeo.",
        "......ooooooooo.",
    ],
}


def hexa(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def imagen(filas, paleta=PALETA):
    assert len(filas) == 16 and all(len(f) == 16 for f in filas), filas
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for j, fila in enumerate(filas):
        for i, letra in enumerate(fila):
            if letra in paleta:
                img.putpixel((i, j), hexa(paleta[letra]))
    return img


def main():
    todos = {nombre: (filas, PALETA) for nombre, filas in DIBUJOS.items()}
    for nombre, (filas, paleta) in todos.items():
        imagen(filas, paleta).save(ICONOS / f"obj-{nombre}.png")
    if "muestra" in sys.argv:
        ids = sorted(todos)
        hoja = Image.new("RGBA", (len(ids) * 72, 72), (60, 56, 70, 255))
        for i, nombre in enumerate(ids):
            grande = imagen(*todos[nombre]).resize((64, 64), Image.NEAREST)
            hoja.paste(grande, (i * 72 + 4, 4), grande)
        hoja.save(RAIZ / "tools" / "objetos16.png")
    print(len(todos), "objetos")


if __name__ == "__main__":
    main()
