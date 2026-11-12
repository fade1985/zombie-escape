# Recorta Noto Sans SC (el chino liso que acompaña a Rubik, la letra de los tutoriales y del aviso de fotosensibilidad) a los
# caracteres que usa la traducción china (locale/zh_CN.po) y unos signos, y la guarda en assets/fuentes/noto-sans-sc-recortada.woff2.
# La entera pesa 17 MB; recortada, unos 400 KB (sigue siendo variable: tiene todos los grosores, para los títulos en negrita).
# Hay que lanzarlo otra vez cuando la traducción china traiga caracteres nuevos (si no, esos salen con Unifont, pixelados).
# Uso: py tools/recortar_noto_sc.py <ruta de NotoSansSC[wght].ttf>   (se baja de Google Fonts, fonts.google.com/noto/specimen/Noto+Sans+SC,
# o del repositorio github.com/google/fonts, ofl/notosanssc; licencia OFL 1.1: assets/fuentes/noto-sans-sc-OFL.txt)
# y luego, para que Godot la vuelva a importar: Godot --headless --path . --import
import re
import sys
from fontTools import subset
from fontTools.ttLib import TTFont

DESTINO = "assets/fuentes/noto-sans-sc-recortada.woff2"
# signos que pueden salir aunque no estén en la traducción (flechas, comillas y signos chinos de ancho completo, cifras anchas)
SIGNOS = "→←↑↓·×…—“”‘’（）！？：；，。、「」《》％０１２３４５６７８９"


def letras_de_la_traduccion(ruta: str) -> str:
    texto = open(ruta, encoding="utf-8").read()
    letras = set()
    for trozo in re.findall(r'^msgstr\s+((?:"(?:[^"\\]|\\.)*"\s*)+)', texto, re.M):
        for linea in re.findall(r'"((?:[^"\\]|\\.)*)"', trozo):
            letras |= set(linea)
    return "".join(sorted(letras))


if len(sys.argv) != 2:
    sys.exit("Uso: py tools/recortar_noto_sc.py <ruta de NotoSansSC[wght].ttf>")
fuente = TTFont(sys.argv[1])
opciones = subset.Options()
opciones.flavor = "woff2"
opciones.layout_features = ["*"]
opciones.name_IDs = ["*"]
opciones.notdef_outline = True
recorte = subset.Subsetter(opciones)
recorte.populate(text=letras_de_la_traduccion("locale/zh_CN.po") + SIGNOS)
recorte.subset(fuente)
subset.save_font(fuente, DESTINO, opciones)
print("Guardada", DESTINO, "con", len(fuente.getBestCmap()), "caracteres")
