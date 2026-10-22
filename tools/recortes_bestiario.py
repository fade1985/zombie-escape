# Los recortes de los retratos del bestiario (scripts/bestiario.gd): para cada enemigo, el rectángulo con píxeles
# dibujados dentro de la celda de su fotograma de frente, para que el ordenador no tenga que leer la imagen en el
# juego (en la web, leer una textura es lento y no siempre va). Lee la LISTA de bestiario.gd, mira cada hoja (.tres +
# .png) y escribe el campo "recorte" de cada entrada.
#   py tools/recortes_bestiario.py   → cambia scripts/bestiario.gd (repetir si cambia una hoja)
import re
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
GD = RAIZ / "scripts/bestiario.gd"


def ruta(res):
    return RAIZ / res.replace("res://", "")


# La región (x, y, w, h) del primer fotograma de una animación dentro del PNG de una hoja .tres
def celda(tres, animacion):
    texto = tres.read_text(encoding="utf-8")
    m = re.search(r'\{"frames": \[\{"duration": [\d.]+, "texture": SubResource\("(t\d+)"\)[^\]]*\], "loop": \w+, "name": &"%s"'
                  % re.escape(animacion), texto)
    if not m:
        raise SystemExit("%s: no está la animación %s" % (tres.name, animacion))
    sub = re.search(r'\[sub_resource type="AtlasTexture" id="%s"\]\s*atlas = ExtResource\("[^"]+"\)\s*region = Rect2\(([\d., ]+)\)'
                    % m.group(1), texto)
    if not sub:
        raise SystemExit("%s: no encuentro el fotograma %s" % (tres.name, m.group(1)))
    png = re.search(r'\[ext_resource type="Texture2D" path="([^"]+)"', texto).group(1)
    x, y, w, h = [int(float(v)) for v in sub.group(1).split(",")]
    return ruta(png), (x, y, w, h)


# El rectángulo con píxeles (alfa > 0) dentro de la celda, relativo a la celda: (x, y, w, h)
def recorte(png, region):
    im = Image.open(png).convert("RGBA")
    x, y, w, h = region
    caja = im.crop((x, y, x + w, y + h)).getchannel("A").getbbox()
    if not caja:
        raise SystemExit("%s: el fotograma está vacío" % png.name)
    return caja[0], caja[1], caja[2] - caja[0], caja[3] - caja[1]


texto = GD.read_text(encoding="utf-8")
patron = re.compile(r'"hoja": "([^"]+)",\s*(?:"recorte": Rect2i\([^)]*\), )?"retrato": "([^"]*)"')
cambios = []


def reemplazo(m):
    hoja, animacion = m.group(1), m.group(2)
    if hoja.endswith(".tres"):
        png, region = celda(ruta(hoja), animacion)
    else:
        png = ruta(hoja)
        region = (0, 0) + Image.open(png).size
    r = recorte(png, region)
    cambios.append("%-32s %s" % (Path(hoja).name, r))
    return '"hoja": "%s",\n\t\t"recorte": Rect2i(%d, %d, %d, %d), "retrato": "%s"' % ((hoja,) + r + (animacion,))


nuevo = patron.sub(reemplazo, texto)
GD.write_text(nuevo, encoding="utf-8")
print("\n".join(cambios))
print("%d recortes escritos en %s" % (len(cambios), GD.relative_to(RAIZ)))
