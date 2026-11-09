# Las pruebas antes de cada versión (docs/LANZAMIENTO.md, «Robustez»): antes de exportar el .exe o publicar la web,
# una sola orden que pasa la prueba larga y una tanda de pruebas cortas de las partes importantes, una detrás de otra,
# y dice al final cuáles han ido bien y cuáles no. Desde la carpeta del juego:
#   py tools/antes_de_version.py            todo (unos 5 minutos)
#   py tools/antes_de_version.py --rapida   sin la prueba larga (unos 4 minutos)
#   py tools/antes_de_version.py --solo horda continuar   solo esas (por su nombre de la lista PRUEBAS)
#
# Una prueba va bien si: se cierra sola y sin código de error (Captura.fallar cierra con 1 o 2), no dice «ERROR DE LA
# PRUEBA» ni «SCRIPT ERROR», y el resumen del registro al cerrar (registro.gd) dice «0 errores». Los avisos se cuentan
# pero no la hacen fallar. Además mira que no falte ninguna traducción (tools/traducciones.py --comprobar).
# Lo que imprime cada prueba se queda en capturas/antes_de_version/<nombre>.txt, para leerlo si algo falla; las fotos,
# en capturas/ como siempre. Las pruebas van de una en una porque comparten guardado-prueba.json.
import os
import re
import subprocess
import sys
import time

CARPETA = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDAS = os.path.join(CARPETA, "capturas", "antes_de_version")
GODOTS = [
    r"C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
    r"C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe",
]

# (nombre, argumentos de la prueba, segundos como mucho). La larga recorre un apartamento, los jefes, los menús, el
# ordenador, la azotea... (prueba_larga.gd); las cortas, lo que la larga no toca o lo que más daño haría si se rompe
PRUEBAS = [
    ("larga", [], 900),
    ("centro-azotea", ["--edificio", "centro", "--azotea"], 200),
    ("torre", ["--edificio", "torre", "--torre"], 200),
    ("continuar", ["--continuar"], 200),
    ("huecos", ["--huecos"], 200),
    ("registro", ["--registro"], 200),
    ("horda", ["--evento", "horda"], 200),
    ("incendio", ["--evento", "incendio"], 200),
    ("rescate", ["--rescate"], 250),
    ("derrota", ["--derrota"], 200),
    ("baul", ["--baul"], 200),
    ("tienda-armas", ["--tienda-armas"], 200),
    ("logros", ["--logros"], 250),
    ("reto", ["--reto", "si"], 200),
    ("idioma", ["--idioma"], 200),
    ("mando", ["--mando"], 200),
]


def buscar_godot():
    for g in GODOTS:
        if os.path.exists(g):
            return g
    sys.exit("No encuentro Godot 4.7.2 (mira las rutas de GODOTS en tools/antes_de_version.py y en CLAUDE.md)")


def pasar(godot, nombre, args, limite):
    inicio = time.time()
    try:
        r = subprocess.run([godot, "--path", CARPETA, "--", "--captura", "--limite", str(limite - 20)] + args,
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=limite)
        salida, codigo = r.stdout + r.stderr, r.returncode
    except subprocess.TimeoutExpired as e:
        salida = (e.stdout or b"").decode("utf-8", "replace") if isinstance(e.stdout, bytes) else (e.stdout or "")
        salida, codigo = salida + "\n(no se cerró sola en %d s)" % limite, -1
    with open(os.path.join(SALIDAS, nombre + ".txt"), "w", encoding="utf-8") as f:
        f.write(salida)
    problemas = []
    if codigo != 0:
        problemas.append("se cerró con el código %d" % codigo)
    for linea in salida.splitlines():
        if "ERROR DE LA PRUEBA" in linea or linea.startswith("SCRIPT ERROR"):
            problemas.append(linea.strip())
    resumen = re.search(r"Registro al cerrar: (\d+) errores y (\d+) avisos((?:\n   .*)*)", salida)
    avisos = 0
    if resumen is None:
        problemas.append("no llegó a escribir «Registro al cerrar» (¿se colgó o se cerró a la fuerza?)")
    else:
        errores, avisos = int(resumen.group(1)), int(resumen.group(2))
        if errores:
            problemas.append("%d errores:%s" % (errores, resumen.group(3)))
    return problemas, avisos, time.time() - inicio


def main():
    args = sys.argv[1:]
    lista = PRUEBAS
    if "--rapida" in args:
        lista = [p for p in lista if p[0] != "larga"]
    if "--solo" in args:
        nombres = args[args.index("--solo") + 1:]
        lista = [p for p in PRUEBAS if p[0] in nombres]
        if len(lista) != len(nombres):
            sys.exit("No conozco alguna de estas: %s. Las que hay: %s" % (nombres, [p[0] for p in PRUEBAS]))
    godot = buscar_godot()
    os.makedirs(SALIDAS, exist_ok=True)
    mal = []
    for i, (nombre, pargs, limite) in enumerate(lista, 1):
        print("[%d/%d] %s..." % (i, len(lista), nombre), end=" ", flush=True)
        problemas, avisos, segundos = pasar(godot, nombre, pargs, limite)
        extra = " (%d avisos)" % avisos if avisos else ""
        if problemas:
            print("FALLA en %d s%s" % (segundos, extra))
            for p in problemas[:5]:
                print("     " + p)
            mal.append(nombre)
        else:
            print("bien en %d s%s" % (segundos, extra))
    # las traducciones: que no falte ningún texto por traducir
    print("traducciones...", end=" ", flush=True)
    r = subprocess.run([sys.executable, os.path.join(CARPETA, "tools", "traducciones.py"), "--comprobar"], cwd=CARPETA,
                       capture_output=True, text=True, encoding="utf-8", errors="replace",
                       env=dict(os.environ, PYTHONIOENCODING="utf-8"))
    faltan = [l for l in r.stdout.splitlines() if "sin traducir:" in l and "sin traducir: 0 " not in l]
    if faltan:
        print("FALTAN")
        for l in faltan:
            print("     " + l.strip())
        mal.append("traducciones")
    else:
        print("bien")
    print()
    if mal:
        print("NO ESTÁ LISTA: fallan %s. Lo que dijo cada una, en capturas/antes_de_version/" % ", ".join(mal))
        sys.exit(1)
    print("TODO BIEN: se puede sacar la versión")


if __name__ == "__main__":
    main()
