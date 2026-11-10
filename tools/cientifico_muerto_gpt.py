"""El científico de Velaria muerto (cientifico.gd), hecho con GPT (M14, 10 nov; antes, de PixelLab con
tools/cientifico_muerto.py, que ya no se usa: pisaría estos dibujos).

Uso:  py tools/cientifico_muerto_gpt.py            (y luego Godot --headless --path . --import)
      py tools/cientifico_muerto_gpt.py muestra    además, capturas/cientifico-gpt-capas.png: las tres capas, en grande

Lee assets/sources/cientifico-muerto-gpt.webp (pedida en pixel art sobre negro puro, con el pelo gris neutro y el
pantalón azul marino para poder separar el pelo) y, reducida como los muebles (tools/muebles_gpt.py: quita el negro
puro que se llega desde el borde, recorta y reduce mezclando colores, LANCZOS premultiplicado), deja en assets/sprites/:
  cientifico-muerto.png        el cuerpo y el charco, sin la piel ni el pelo
  cientifico-muerto-piel.png   la piel (las manos y la oreja) en grises: blanco = el color de la piel tal cual
  cientifico-muerto-pelo.png   el pelo (la nuca), igual
El juego pinta las dos últimas con los colores de cada página (el 'look' de historia.gd), así un solo dibujo vale
para todos. Qué es piel y qué es pelo se mira en la imagen grande (por su color) y luego se reduce igual que el
dibujo: cada píxel pequeño va a la capa de lo que más tiene.
"""
import colorsys
import sys
from collections import deque
from PIL import Image, ImageEnhance

ORIGEN = "assets/sources/cientifico-muerto-gpt.webp"
DESTINO = "assets/sprites/cientifico-muerto"
ANCHO = 62            # como el de PixelLab (lo que ocupa en el suelo); el alto, según la proporción
TONO_PIEL = (12, 45)  # tonos carne, en grados (nada más del dibujo tiene ese color: la sangre es roja, el pantalón azul)
# el retoque de color (contraste, brillo, color), como los zombis de GPT (tools/zombi_gpt.py): salía más apagado que
# el de PixelLab, con la bata gris en vez de blanca
RETOQUE = (1.2, 1.1, 1.1)
CABEZA_X = 0.25       # el pelo está en la cuarta parte izquierda del dibujo (el resto gris es la bata)


def hsv(p):
    return colorsys.rgb_to_hsv(p[0] / 255, p[1] / 255, p[2] / 255)


def es_piel(p):
    h, s, v = hsv(p)
    return TONO_PIEL[0] <= h * 360 <= TONO_PIEL[1] and s > 0.2 and v > 0.45


def es_pelo(p, x, ancho):
    h, s, v = hsv(p)
    return x < ancho * CABEZA_X and s < 0.14 and 0.12 < v < 0.7


def sin_fondo(im):
    W, H = im.size
    px = im.load()
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 6:
            continue
        fondo[y * W + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(H):
        for x in range(W):
            if fondo[y * W + x]:
                px[x, y] = (0, 0, 0, 0)
    return im.crop(im.getbbox())


def gris(v):
    g = round(max(0.0, min(1.0, v)) * 255)
    return (g, g, g, 255)


def main():
    im = sin_fondo(Image.open(ORIGEN).convert("RGBA"))
    W, H = im.size
    alto = round(ANCHO * H / W)
    px = im.load()
    # en grande: qué es piel y qué es pelo (dos máscaras, blanco = sí)
    m_piel = Image.new("L", im.size, 0)
    m_pelo = Image.new("L", im.size, 0)
    for y in range(H):
        for x in range(W):
            p = px[x, y]
            if p[3] < 128:
                continue
            if es_piel(p):
                m_piel.putpixel((x, y), 255)
            elif es_pelo(p, x, W):
                m_pelo.putpixel((x, y), 255)
    # reducido como los muebles: mezclando colores (premultiplicado) y el borde sin medias tintas
    peq = im.convert("RGBa").resize((ANCHO, alto), Image.LANCZOS).convert("RGBA")
    peq.putalpha(peq.split()[3].point(lambda v: 255 if v > 110 else 0))
    alfa = peq.split()[3]
    rgb = peq.convert("RGB")
    for mejora, k in zip((ImageEnhance.Contrast, ImageEnhance.Brightness, ImageEnhance.Color), RETOQUE):
        rgb = mejora(rgb).enhance(k)
    peq = rgb.convert("RGBA")
    peq.putalpha(alfa)
    f_piel = m_piel.resize((ANCHO, alto), Image.BOX)
    f_pelo = m_pelo.resize((ANCHO, alto), Image.BOX)
    cuerpo = peq.copy()
    piel = Image.new("RGBA", peq.size, (0, 0, 0, 0))
    pelo = Image.new("RGBA", peq.size, (0, 0, 0, 0))
    de_piel, de_pelo = [], []
    for y in range(alto):
        for x in range(ANCHO):
            if peq.getpixel((x, y))[3] == 0:
                continue
            if f_piel.getpixel((x, y)) > 90:
                de_piel.append((x, y))
            elif f_pelo.getpixel((x, y)) > 110:
                de_pelo.append((x, y))
            elif f_piel.getpixel((x, y)) > 0 or f_pelo.getpixel((x, y)) > 0:
                # el borde, mezcla de piel (o pelo) y contorno: en gris oscuro, que no quede un cerco color carne
                # alrededor de las manos cuando la página tiene otra piel
                r, g, b, a = peq.getpixel((x, y))
                v = round((r * 0.3 + g * 0.59 + b * 0.11) * 0.55)
                cuerpo.putpixel((x, y), (v, v, v, a))
    # los grises: lo más claro de cada capa = el color de la página tal cual
    for lista, capa in ((de_piel, piel), (de_pelo, pelo)):
        if not lista:
            continue
        tope = max(hsv(peq.getpixel(xy))[2] for xy in lista)
        for xy in lista:
            capa.putpixel(xy, gris(hsv(peq.getpixel(xy))[2] / tope))
            cuerpo.putpixel(xy, (0, 0, 0, 0))
    cuerpo.save(DESTINO + ".png")
    piel.save(DESTINO + "-piel.png")
    pelo.save(DESTINO + "-pelo.png")
    print(f"{DESTINO}.png: {ANCHO}x{alto} · piel {len(de_piel)} píxeles · pelo {len(de_pelo)}")
    if "muestra" in sys.argv:
        hoja = Image.new("RGBA", (ANCHO * 3 + 20, alto), (40, 40, 50, 255))
        for i, capa in enumerate((cuerpo, piel, pelo)):
            hoja.alpha_composite(capa, (i * (ANCHO + 10), 0))
        hoja.resize((hoja.width * 6, hoja.height * 6), Image.NEAREST).save("capturas/cientifico-gpt-capas.png")


main()
