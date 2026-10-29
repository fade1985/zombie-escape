"""Las traducciones del juego (cómo funcionan: docs/IDIOMAS.md).

El español es el idioma de origen: cada texto del código es su propia clave y las traducciones viven en locale/<idioma>.po
(en, pt_BR, de, fr: la lista IDIOMAS de abajo). Esta herramienta recoge los textos del código, pone al día los .po y avisa de
lo que está mal. Sin --idioma trabaja con todos los idiomas; con  --idioma de  (o  en,  pt_BR,  fr) solo con ese:

  py tools/traducciones.py              pone al día los .po (añade los textos nuevos, sin traducción) y cuenta
  py tools/traducciones.py --comprobar  lo mismo sin escribir nada (para mirar antes de subir)
  py tools/traducciones.py --limpiar    además quita del .po los textos que ya no están en el código
  py tools/traducciones.py --faltan     enseña todos los textos sin traducir (por defecto, solo los 15 primeros)
  py tools/traducciones.py --idioma de --rellenar archivo.json   rellena los que están sin traducir con lo que diga el archivo
                                        ({"texto en español": "texto en alemán"}; en los plurales, una lista [uno, varios]).
                                        No toca lo que ya está traducido (con --pisar, sí)
  py tools/traducciones.py --idioma de --exportar lista.json    saca la lista de lo que falta por traducir a ese idioma, para
                                        quien traduce: la clave con la que contestar (los que llevan contexto, «contexto@@texto»),
                                        el texto en español, dónde sale y cómo está en inglés

Qué textos recoge:
  1. Los que van dentro de  Idioma.t("...")  e  Idioma.n("uno", "varios", n)  (con contexto opcional como último
     parámetro). Pueden ir partidos en varias líneas con +.
  2. Los de las tablas de datos (const) que se traducen al enseñarlos: todo texto con letras que haya entre dos líneas
     de comentario  # [traducir]  y  # [/traducir] , o en una línea que acabe en  # [traducir] . Se salta lo que parece
     un id (minúsculas y guiones bajos), las rutas y las claves de diccionario.

Qué se vigila: que ningún texto esté sin traducir, que la traducción lleve los mismos %d / %s que el original, los mismos
saltos de línea y los mismos espacios al principio y al final, y que en los archivos ya pasados (PASADOS) no quede un
texto en español suelto: sin pasar por Idioma.t, sin estar en una tabla marcada y sin  # no-tr  al final de la línea.
Si algo está mal, acaba con el código 1.
"""
import json, os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Los idiomas: código de Godot (el de locale/<código>.po y el de idioma.gd) → su nombre y cómo se forma el plural
IDIOMAS = {
    "en": {"nombre": "inglés", "plural": "nplurals=2; plural=(n != 1);"},
    "pt_BR": {"nombre": "portugués de Brasil", "plural": "nplurals=2; plural=(n > 1);"},
    "de": {"nombre": "alemán", "plural": "nplurals=2; plural=(n != 1);"},
    "fr": {"nombre": "francés", "plural": "nplurals=2; plural=(n > 1);"},
    "ru": {"nombre": "ruso", "formas": 3,
           "plural": "nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);"},
    "zh_CN": {"nombre": "chino simplificado", "formas": 1, "plural": "nplurals=1; plural=0;"},
}


def formas(codigo):
    """Cuántas formas de plural tiene un idioma (el ruso, 3; el chino, 1; los demás, 2)."""
    return IDIOMAS[codigo].get("formas", 2)


def ruta_po(codigo):
    return os.path.join(RAIZ, "locale", codigo + ".po")

# Archivos que no se traducen: herramientas internas (el panel F9 y la sala de pruebas) y las pruebas
EXCLUIDOS = ["scripts/pruebas/", "scripts/ui/panel_pruebas.gd", "scripts/sala_armas.gd"]

# Archivos ya pasados al inglés: aquí no puede quedar ningún texto en español sin traducir. Cada fase añade los suyos
PASADOS = [
    "scripts/idioma.gd",
    "scripts/ui/menu_principal.gd",
    "scripts/ui/opciones.gd",
    "scripts/alerta.gd",
    "scripts/edificios.gd",
    "scripts/reto.gd",
    # fase 2: la interfaz
    "scripts/partida.gd",
    "scripts/ui/menus.gd",
    "scripts/ui/hud.gd",
    "scripts/ui/barra_jefe.gd",
    "scripts/ui/presentacion.gd",
    "scripts/ui/tactil.gd",
    "scripts/ui/tutorial.gd",
    "scripts/ui/inventario.gd",
    "scripts/ui/taquilla.gd",
    "scripts/ui/ordenador.gd",
    "scripts/ui/tele.gd",
    "scripts/mapa/ordenador.gd",
    # fase 3: los datos
    "scripts/armas.gd",
    "scripts/objetos.gd",
    "scripts/lanzables.gd",
    "scripts/mejoras.gd",
    "scripts/armas_creadas.gd",
    "scripts/talentos.gd",
    "scripts/logros.gd",
    "scripts/mutaciones.gd",
    "scripts/skins.gd",
    "scripts/eventos.gd",
    "scripts/averia.gd",
    "scripts/joyeria.gd",
    "scripts/barricada.gd",
    "scripts/controles.gd",
    # fase 4: los textos largos, los personajes y los gritos
    "scripts/tutoriales.gd",
    "scripts/historia.gd",
    "scripts/bestiario.gd",
    "scripts/supervivientes.gd",
    "scripts/escolta.gd",
    "scripts/gerente.gd",
    "scripts/portera.gd",
    "scripts/gymbro.gd",
    "scripts/minijefe.gd",
    "scripts/bombero.gd",
    "scripts/mascota.gd",
    "scripts/cocinero.gd",
    "scripts/modista.gd",
    "scripts/antidisturbios.gd",
    "scripts/gloton.gd",
    "scripts/cientifico_jefe.gd",
    "scripts/aliado.gd",
    "scripts/persona.gd",
    "scripts/zombi.gd",
    "scripts/zombi_dependienta.gd",
    "scripts/zombi_guardia.gd",
    "scripts/johnny.gd",
    # fase 5: el mundo
    "scripts/mapa/tienda.gd",
    "scripts/mapa/planta.gd",
    "scripts/mapa/apartamento.gd",
    "scripts/mapa/cartel_trasteros.gd",
    "scripts/mapa/neon.gd",
    "scripts/mapa/viviendas.gd",
    "scripts/mapa/puerta.gd",
    "scripts/mapa/mapa.gd",
    "scripts/minimapa.gd",
    "scripts/peligros/agua.gd",
    "scripts/peligros/cerco.gd",
    "scripts/peligros/cuadro.gd",
    "scripts/peligros/frio.gd",
    "scripts/peligros/fuego.gd",
    "scripts/peligros/luz_jefe.gd",
    "scripts/peligros/porqueria.gd",
    "scripts/peligros/tropiezos.gd",
]

# Palabras sueltas con mayúscula que no son texto (nombres de nodos, variaciones del tema...)
NO_TEXTO = {"Titulo", "Sub", "Celda", "Pastilla", "BotonGrande", "Button", "Label", "Panel", "Tema"}
ACENTOS = re.compile(r"[áéíóúüñÁÉÍÓÚÑ¿¡]")
LETRAS = re.compile(r"[A-Za-zÁÉÍÓÚáéíóúüñÑ]{2,}")
FORMATO = re.compile(r"%[-+0#]*\d*(?:\.\d+)?[sdfxXcoeEgGu]")


class Texto:
    def __init__(self, uno, varios="", contexto=""):
        self.uno, self.varios, self.contexto = uno, varios, contexto
        self.archivos = []

    @property
    def clave(self):
        return (self.contexto, self.uno)


def desescapar(crudo):
    sal = {"n": "\n", "t": "\t", '"': '"', "'": "'", "\\": "\\"}
    res, i = [], 0
    while i < len(crudo):
        c = crudo[i]
        if c == "\\" and i + 1 < len(crudo):
            d = crudo[i + 1]
            if d == "u" and re.match(r"[0-9a-fA-F]{4}", crudo[i + 2:i + 6]):
                res.append(chr(int(crudo[i + 2:i + 6], 16))); i += 6; continue
            res.append(sal.get(d, "\\" + d)); i += 2; continue
        res.append(c); i += 1
    return "".join(res)


def leer_codigo(texto):
    """Devuelve (cadenas, enmascarado): las cadenas [inicio, fin, valor, línea] y el código con las cadenas
    convertidas en "xxx" del mismo largo y los comentarios en blanco (para buscar paréntesis sin liarse)."""
    cadenas, masc, i, n, linea = [], list(texto), 0, len(texto), 1
    while i < n:
        c = texto[i]
        if c == "\n":
            linea += 1; i += 1
        elif c == "#":
            j = i
            while j < n and texto[j] != "\n":
                masc[j] = " "; j += 1
            i = j
        elif c in "\"'":
            if texto.startswith(c * 3, i):   # texto entre tres comillas
                j = texto.find(c * 3, i + 3)
                j = n if j < 0 else j + 3
                cadenas.append([i, j, desescapar(texto[i + 3:j - 3]), linea])
                for k in range(i + 1, j - 1):
                    masc[k] = "x" if texto[k] != "\n" else "\n"
                linea += texto.count("\n", i, j); i = j
                continue
            j = i + 1
            while j < n and texto[j] != c and texto[j] != "\n":
                j += 2 if texto[j] == "\\" else 1
            cadenas.append([i, j + 1, desescapar(texto[i + 1:j]), linea])
            for k in range(i + 1, j):
                masc[k] = "x"
            i = j + 1
        else:
            i += 1
    return cadenas, "".join(masc)


def argumentos(masc, abre):
    """Los rangos (inicio, fin) de cada argumento de la llamada cuyo paréntesis está en masc[abre]."""
    res, prof, ini, i = [], 0, abre + 1, abre
    while i < len(masc):
        c = masc[i]
        if c in "([{":
            prof += 1
        elif c in ")]}":
            prof -= 1
            if prof == 0:
                res.append((ini, i)); return res
        elif c == "," and prof == 1:
            res.append((ini, i)); ini = i + 1
        i += 1
    return res


def solo_literal(masc, rango, cadenas):
    """Si el argumento es solo una cadena (o varias pegadas con +), su valor; si no, None."""
    a, b = rango
    dentro = [c for c in cadenas if c[0] >= a and c[1] <= b]
    if not dentro:
        return None
    esqueleto = masc[a:b]
    for c in sorted(dentro, key=lambda c: -c[0]):
        esqueleto = esqueleto[:c[0] - a] + "S" + esqueleto[c[1] - a:]
    if not re.fullmatch(r"[\s(]*S(\s*\+\s*S)*[\s)]*", esqueleto):
        return None
    return "".join(c[2] for c in sorted(dentro, key=lambda c: c[0]))


def parece_texto(s):
    """¿Una cadena suelta del código parece un texto para el jugador?"""
    if s.startswith(("res://", "user://", "%", "$", "@")) or ("/" in s and " " not in s):
        return False
    if not LETRAS.search(s):
        return False
    if re.fullmatch(r"X+", s):   # una fila de una letra dibujada con X (puerta.gd)
        return False
    if re.fullmatch(r"[a-z0-9_.:\-]+", s):   # un id, una clave
        return False
    if ACENTOS.search(s):
        return True
    palabras = LETRAS.findall(s)
    if len(palabras) >= 2 and " " in s.strip():
        return True
    return bool(re.fullmatch(r"[A-ZÁÉÍÓÚÑ][A-Za-zÁÉÍÓÚáéíóúüñÑ]{2,}", s)) and s not in NO_TEXTO


def es_texto_de_tabla(s):
    """Dentro de una tabla marcada, todo lo que tiene letras es un texto, menos los ids, las rutas y los formatos."""
    if s.startswith(("res://", "user://", "%", "$", "@")) or ("/" in s and " " not in s):
        return False
    return bool(LETRAS.search(s)) and not re.fullmatch(r"[a-z0-9_.:\-]+", s)


def recoger(rel, textos, sueltos):
    """Mira un archivo: apunta sus textos en 'textos' y, si está pasado, los que se han quedado sueltos en 'sueltos'."""
    texto = open(os.path.join(RAIZ, rel), encoding="utf-8").read()
    cadenas, masc = leer_codigo(texto)
    lineas = texto.split("\n")
    usadas = set()   # las cadenas que ya son un texto traducido (o dentro de una tabla marcada)

    def apuntar(uno, varios="", contexto=""):
        t = textos.setdefault((contexto, uno), Texto(uno, varios, contexto))
        if varios and not t.varios:
            t.varios = varios
        if rel not in t.archivos:
            t.archivos.append(rel)

    # 1. Idioma.t(...) e Idioma.n(...)
    for m in re.finditer(r"\bIdioma\s*\.\s*([tn])\s*\(", masc):
        args = argumentos(masc, m.end() - 1)
        lit = [solo_literal(masc, r, cadenas) for r in args]
        for r in args:
            for c in cadenas:
                if c[0] >= r[0] and c[1] <= r[1]:
                    usadas.add(c[0])
        if m.group(1) == "t" and lit and lit[0] is not None:
            apuntar(lit[0], contexto=(lit[1] or "") if len(lit) > 1 else "")
        elif m.group(1) == "n" and len(lit) >= 2 and lit[0] is not None and lit[1] is not None:
            apuntar(lit[0], lit[1], (lit[3] or "") if len(lit) > 3 else "")
        elif lit and lit[0] is None and rel in PASADOS:
            pass   # un texto que viene de una variable: lo cubre la tabla de datos de donde salga
    # 2. las tablas marcadas con # [traducir]
    marcadas, dentro = set(), False
    for k, l in enumerate(lineas, 1):
        s = l.strip()
        if s.startswith("#"):
            if "[/traducir]" in s:
                dentro = False
            elif "[traducir]" in s:
                dentro = True
            continue
        if dentro or re.search(r"#\s*\[traducir\]\s*$", l):
            marcadas.add(k)
    for c in cadenas:
        if c[3] not in marcadas or not es_texto_de_tabla(c[2]):
            continue
        despues = masc[c[1]:c[1] + 8].lstrip()
        if despues.startswith(":"):   # la clave de un diccionario
            continue
        usadas.add(c[0]); apuntar(c[2])
    # 3. lo que se ha quedado suelto
    if rel in PASADOS:
        for c in cadenas:
            if c[0] in usadas or not parece_texto(c[2]):
                continue
            linea = lineas[c[3] - 1]
            if re.search(r"#\s*no-tr\b", linea) or linea.lstrip().startswith(("print", "push_", "assert")):
                continue
            if re.search(r"\b(print|printerr|push_error|push_warning|assert|preload|load|theme_type_variation|"
                         r"get_node|has_node|find_child|add_to_group|is_in_group|call_group|get_nodes_in_group|"
                         r"set_name|\.name|montar|add_theme_[a-z_]+)\b", linea[:c[0] - (texto.rfind("\n", 0, c[0]) + 1)]):
                continue
            despues = masc[c[1]:c[1] + 8].lstrip()
            if despues.startswith(":"):
                continue
            sueltos.append((rel, c[3], c[2]))


def archivos_de_codigo():
    res = []
    for carpeta, _, nombres in os.walk(os.path.join(RAIZ, "scripts")):
        for f in nombres:
            if f.endswith(".gd"):
                rel = os.path.relpath(os.path.join(carpeta, f), RAIZ).replace("\\", "/")
                if not any(rel.startswith(x) for x in EXCLUIDOS):
                    res.append(rel)
    return sorted(res)


# ── El archivo .po ──

def escapar(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def linea_po(clave, s):
    if "\n" in s[:-1]:   # varias líneas: una por cada salto, que se lee mejor
        trozos = re.findall(r"[^\n]*\n|[^\n]+", s)
        return clave + ' ""\n' + "\n".join('"%s"' % escapar(t) for t in trozos)
    return '%s "%s"' % (clave, escapar(s))


def leer_po(codigo="en"):
    """Las traducciones del .po de un idioma: {(contexto, original): {"varios": ..., "tr": [formas]}}"""
    res, actual, campo = {}, None, None
    if not os.path.exists(ruta_po(codigo)):
        return res
    def cerrar():
        if actual is not None and actual["uno"] != "":
            res[(actual["ctx"], actual["uno"])] = actual
    for l in open(ruta_po(codigo), encoding="utf-8").read().split("\n"):
        l = l.rstrip()
        if l.startswith("#") or l == "":
            if l == "":
                cerrar(); actual = None; campo = None
            continue
        m = re.match(r'(msgctxt|msgid_plural|msgid|msgstr(?:\[(\d+)\])?)\s+"(.*)"$', l)
        if m:
            nombre = m.group(1)
            if nombre == "msgctxt":
                cerrar(); actual = {"ctx": "", "uno": "", "varios": "", "tr": {}}; campo = "ctx"
            elif nombre == "msgid":
                if actual is None or actual["uno"] != "" or campo == "tr":
                    cerrar(); actual = {"ctx": actual["ctx"] if actual and campo == "ctx" else "", "uno": "", "varios": "", "tr": {}}
                campo = "uno"
            elif nombre == "msgid_plural":
                campo = "varios"
            else:
                campo = ("tr", int(m.group(2) or 0))
            valor = desescapar(m.group(3))
            if isinstance(campo, tuple):
                actual["tr"][campo[1]] = valor
            else:
                actual[campo] = valor
            continue
        m = re.match(r'"(.*)"$', l)
        if m and actual is not None and campo is not None:
            valor = desescapar(m.group(1))
            if isinstance(campo, tuple):
                actual["tr"][campo[1]] = actual["tr"].get(campo[1], "") + valor
            else:
                actual[campo] += valor
    cerrar()
    return res


def cabecera(codigo):
    i = IDIOMAS[codigo]
    return ('# Traducción al %s de Zombie Escape. El español es el idioma de origen: cada «msgid» es el texto tal como está en el\n'
            '# código. Los pone al día  py tools/traducciones.py  (cómo se escribe: docs/IDIOMAS.md y docs/GLOSARIO_EN.md); lo que se\n'
            '# escribe a mano es cada «msgstr». Un msgstr vacío = sin traducir (en el juego se ve el español).\n'
            'msgid ""\nmsgstr ""\n'
            '"Project-Id-Version: Zombie Escape\\n"\n'
            '"Language: %s\\n"\n'
            '"MIME-Version: 1.0\\n"\n'
            '"Content-Type: text/plain; charset=UTF-8\\n"\n'
            '"Content-Transfer-Encoding: 8bit\\n"\n'
            '"Plural-Forms: %s\\n"\n') % (i["nombre"], codigo, i["plural"])


def escribir_po(codigo, textos, previas, conservar):
    salida = [cabecera(codigo)]
    n_formas = formas(codigo)
    def entrada(t, prev):
        l = []
        if t.archivos:
            l.append("#: " + " ".join(t.archivos))
        if t.contexto:
            l.append(linea_po("msgctxt", t.contexto))
        l.append(linea_po("msgid", t.uno))
        if t.varios:
            l.append(linea_po("msgid_plural", t.varios))
            formas_tr = prev["tr"] if prev else {}
            for i in range(n_formas):
                l.append(linea_po("msgstr[%d]" % i, formas_tr.get(i, "")))
        else:
            l.append(linea_po("msgstr", (prev["tr"].get(0, "") if prev else "")))
        return "\n".join(l)
    for t in sorted(textos.values(), key=lambda t: (t.archivos[0], 0)):   # estable: por archivo; dentro, el orden de lectura
        salida.append(entrada(t, previas.get(t.clave)))
    for clave, prev in conservar.items():
        t = Texto(prev["uno"], prev["varios"], prev["ctx"])
        salida.append("#, sin-usar\n" + entrada(t, prev))
    return "\n\n".join(salida) + "\n"


def trabajar(codigo, textos, sueltos, args):
    """Pone al día y comprueba el .po de un idioma. Devuelve si hay algo mal (textos sin traducir o errores)."""
    solo_mirar, limpiar, todas = "--comprobar" in args, "--limpiar" in args, "--faltan" in args
    po = ruta_po(codigo)
    previas = leer_po(codigo)
    if "--rellenar" in args:
        datos = json.load(open(args[args.index("--rellenar") + 1], encoding="utf-8"))
        for original, nuevo in datos.items():
            ctx, texto = original.split("@@", 1) if ("@@" in original and (original.split("@@", 1)[0], original.split("@@", 1)[1]) in textos) else ("", original)
            for clave in [k for k in textos if k == (ctx, texto)]:
                valores = [nuevo] if isinstance(nuevo, str) else list(nuevo)
                prev = previas.setdefault(clave, {"ctx": clave[0], "uno": clave[1], "varios": textos[clave].varios, "tr": {}})
                for i, f in enumerate(valores):
                    if not prev["tr"].get(i) or "--pisar" in args:
                        prev["tr"][i] = f
    sin_usar = {k: v for k, v in previas.items() if k not in textos}
    errores, faltan = [], []
    for t in textos.values():
        prev = previas.get(t.clave)
        formas_tr = prev["tr"] if prev else {}
        usadas = tuple(range(formas(codigo))) if t.varios else (0,)
        if any(not formas_tr.get(i, "") for i in usadas):
            faltan.append(t); continue
        for i in usadas:
            orig = t.uno if i == 0 else t.varios
            tr = formas_tr[i]
            fo, ft = FORMATO.findall(orig.replace("%%", "")), FORMATO.findall(tr.replace("%%", ""))
            if sorted(fo) != sorted(ft) and not (t.varios and i == 0 and not ft):   # (el singular a veces dice "un": sin número)
                errores.append("formato distinto (%s → %s): «%s»" % (" ".join(fo) or "-", " ".join(ft) or "-", orig))
            if orig.count("%%") != tr.count("%%"):
                errores.append("los %% no coinciden: «%s»" % orig)
            if orig.count("\n") != tr.count("\n"):
                errores.append("saltos de línea distintos: «%s»" % orig)
            if (len(orig) - len(orig.lstrip())) != (len(tr) - len(tr.lstrip())) or (len(orig) - len(orig.rstrip())) != (len(tr) - len(tr.rstrip())):
                errores.append("espacios distintos al principio o al final: «%s»" % orig)
    if "--exportar" in args:
        en = leer_po("en") if codigo != "en" else {}
        lista = []
        for t in faltan:
            ref = en.get(t.clave, {"tr": {}})["tr"]
            e = {"clave": (t.contexto + "@@" + t.uno) if t.contexto else t.uno, "es": t.uno}
            if t.varios:
                e["es_plural"] = t.varios
            if t.contexto:
                e["contexto"] = t.contexto
            e["en"] = ref.get(0, "")
            if t.varios:
                e["en_plural"] = ref.get(1, "")
            e["donde"] = os.path.basename(t.archivos[0])
            lista.append(e)
        json.dump(lista, open(args[args.index("--exportar") + 1], "w", encoding="utf-8"), ensure_ascii=False, indent=0)
        print("%s: %d textos por traducir exportados" % (codigo, len(lista)))
    if not solo_mirar:
        conservar = {} if limpiar else sin_usar
        nuevo = escribir_po(codigo, textos, previas, conservar)
        antes = open(po, encoding="utf-8").read() if os.path.exists(po) else ""
        if nuevo != antes:
            os.makedirs(os.path.dirname(po), exist_ok=True)
            open(po, "w", encoding="utf-8", newline="\n").write(nuevo)
            print("locale/%s.po puesto al día" % codigo)
    nuevos = [t for t in textos.values() if t.clave not in previas]
    print("[%s] Textos: %d · traducidos: %d · sin traducir: %d · nuevos desde la última vez: %d · sin usar en el código: %d"
          % (codigo, len(textos), len(textos) - len(faltan), len(faltan), len(nuevos), len(sin_usar)))
    if faltan:
        print("\nSIN TRADUCIR AL %s:" % IDIOMAS[codigo]["nombre"].upper())
        for t in faltan if todas else faltan[:15]:
            print("  ·", t.uno.replace("\n", "\\n"), "  (%s)" % t.archivos[0])
        if not todas and len(faltan) > 15:
            print("  … y %d más (--faltan los enseña todos)" % (len(faltan) - 15))
    if errores:
        print("\nERRORES EN LAS TRADUCCIONES (%s):" % codigo)
        for e in errores:
            print("  ·", e)
    if sin_usar and not limpiar:
        print("\nSin usar (--limpiar los quita): %s" % ", ".join("«%s»" % k[1].replace("\n", "\\n") for k in list(sin_usar)[:8]))
    return bool(faltan or errores)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    args = sys.argv[1:]
    codigos = list(IDIOMAS)
    if "--idioma" in args:
        codigos = [args[args.index("--idioma") + 1]]
        if codigos[0] not in IDIOMAS:
            sys.exit("idioma desconocido: %s (los hay: %s)" % (codigos[0], ", ".join(IDIOMAS)))
    elif "--rellenar" in args or "--exportar" in args:
        sys.exit("--rellenar y --exportar necesitan --idioma <código>")
    textos, sueltos = {}, []
    for rel in archivos_de_codigo():   # el orden de lectura de cada archivo se respeta (dict conserva el orden)
        recoger(rel, textos, sueltos)
    mal = False
    for codigo in codigos:
        mal = trabajar(codigo, textos, sueltos, args) or mal
        print()
    if sueltos:
        print("TEXTOS EN ESPAÑOL SUELTOS en archivos ya pasados (ponerlos en Idioma.t(), en una tabla # [traducir] o, si de verdad no se traducen, # no-tr):")
        for rel, linea, s in sueltos:
            print("  · %s:%d  «%s»" % (rel, linea, s.replace("\n", "\\n")))
    sys.exit(1 if (mal or sueltos) else 0)


if __name__ == "__main__":
    main()
