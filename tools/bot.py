"""El jugador automático (el bot, docs/BOT.md): lanza las peleas contra los jefes y hace el resumen.

    py tools/bot.py                          # los tres edificios, 8 peleas por jefe y nivel (~1 hora)
    py tools/bot.py --peleas 3 --edificios apartamentos --jefes portera,gloton
    py tools/bot.py --resumen 1234           # solo el resumen de lo ya jugado con la semilla 1234
    py tools/bot.py --partidas 10 --edificios apartamentos   # fase 2: 10 partidas enteras por nivel

Cada edificio es una partida de prueba aparte (--captura --bot-jefes, scripts/pruebas/prueba_bot.gd), una detrás de
otra (comparten el guardado de prueba: a la vez se pisarían). Va con --fixed-fps 60: cada fotograma es 1/60 s de juego
y no espera al reloj, así que va unas cuatro veces más deprisa que jugando. Las peleas quedan en
capturas/bot/jefes-<edificio>-<semilla>.jsonl y el resumen, en la terminal y en capturas/bot/resumen-<semilla>.md.
"""
import argparse
import glob
import json
import os
import random
import subprocess
import sys
import time
from collections import Counter, defaultdict

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOTS = [r"C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
          r"C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"]
EDIFICIOS = ["apartamentos", "centro", "torre"]
NIVELES = ["novato", "normal", "bueno"]
# Cómo se llama a cada jefe en el resumen
NOMBRES = {"portera": "Portera", "gloton": "Glotón", "gymbro": "Gymbro", "bombero": "Jefe de bomberos",
           "cientifico_jefe": "Doctor Salas (final)", "antidisturbios": "Antidisturbios", "cocinero": "Cocinero",
           "modista": "Modista", "mascota": "Mascota", "gerente": "Gerente (final)", "directora": "Directora",
           "informatico": "Informático", "presentador": "Presentador", "becario": "Becario",
           "sujeto_1": "Sujeto 1 (final)"}


def godot():
    for g in GODOTS:
        if os.path.exists(g):
            return g
    sys.exit("No encuentro Godot 4.7.2 (mira GODOTS en tools/bot.py)")


def jugar(edificio, args, semilla):
    orden = [godot(), "--path", RAIZ, "--fixed-fps", "60", "--", "--captura", "--edificio", edificio, "--bot-jefes",
             "--peleas", str(args.peleas), "--niveles", args.niveles, "--semilla", str(semilla), "--limite", "20000"]
    if args.jefes:
        orden += ["--jefes", args.jefes]
    inicio = time.time()
    print(f"== {edificio} ==", flush=True)
    proceso = subprocess.Popen(orden, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                               errors="replace")
    for linea in proceso.stdout:
        if linea.startswith("BOT") or "ERROR DE LA PRUEBA" in linea or "SCRIPT ERROR" in linea:
            print("  " + linea.rstrip(), flush=True)
    proceso.wait()
    print(f"  ({edificio}: {round(time.time() - inicio)} s, código {proceso.returncode})", flush=True)


def media(lista):
    return sum(lista) / len(lista) if lista else 0.0


def resumen(semilla):
    peleas = []
    for archivo in glob.glob(os.path.join(RAIZ, "capturas", "bot", f"jefes-*-{semilla}.jsonl")):
        with open(archivo, encoding="utf-8") as f:
            peleas += [json.loads(l) for l in f if l.strip()]
    if not peleas:
        sys.exit(f"No hay peleas con la semilla {semilla} en capturas/bot/")
    grupos = defaultdict(list)
    for p in peleas:
        grupos[(p["edificio"], p["jefe"], p["nivel"])].append(p)
    lineas = [f"# Peleas del bot contra los jefes (semilla {semilla})", "",
              "Johnny recién empezado (pistola y fregona, 2 molotovs y 2 granadas, sin talentos ni mutaciones) y munición de "
              "sobra. «Gana»: las que gana. «Tarda»: lo que dura una pelea ganada. «Vida que le queda»: al ganar. «Jefe "
              "queda»: la vida que le queda al jefe cuando pierde. «Le hace más daño»: de quién viene el daño.", ""]
    for ed in EDIFICIOS:
        claves = [k for k in grupos if k[0] == ed]
        if not claves:
            continue
        lineas += [f"## {ed.capitalize()}", "",
                   "| Jefe | Nivel | Gana | Tarda | Vida que le queda | Jefe queda | Le hace más daño |",
                   "|---|---|---|---|---|---|---|"]
        jefes = list(dict.fromkeys(k[1] for k in sorted(claves, key=lambda k: peleas.index(grupos[k][0]))))
        for jefe in jefes:
            for nivel in NIVELES:
                g = grupos.get((ed, jefe, nivel))
                if not g:
                    continue
                buenas = [p for p in g if "error" not in p]
                ganadas = [p for p in buenas if p.get("gana")]
                perdidas = [p for p in buenas if not p.get("gana")]
                danos = Counter()
                for p in buenas:
                    danos.update(p.get("de", {}))
                total = sum(danos.values()) or 1
                peor = ", ".join(f"{k} {round(100 * v / total)} %" for k, v in danos.most_common(3))
                tarda = f"{round(media([p['segundos'] for p in ganadas]))} s" if ganadas else "-"
                queda = f"{round(media([max(0, p['vida_max'] - p['dano']) for p in ganadas]))}" if ganadas else "-"
                jefe_queda = f"{round(100 * media([p['jefe_queda'] for p in perdidas]))} %" if perdidas else "-"
                no_acaba = sum(1 for p in buenas if p.get("no_acaba"))
                errores = len(g) - len(buenas)
                extra = (f" ({no_acaba} sin acabar)" if no_acaba else "") + (f" ({errores} con error)" if errores else "")
                lineas.append(f"| {NOMBRES.get(jefe, jefe)} | {nivel} | {len(ganadas)}/{len(buenas)}{extra} | {tarda} | "
                              f"{queda} | {jefe_queda} | {peor} |")
        lineas.append("")
    texto = "\n".join(lineas)
    print(texto)
    with open(os.path.join(RAIZ, "capturas", "bot", f"resumen-{semilla}.md"), "w", encoding="utf-8") as f:
        f.write(texto + "\n")


# ── Fase 2: partidas enteras (--bot-partida) ──

def jugar_partida(edificio, nivel, semilla):
    orden = [godot(), "--path", RAIZ, "--fixed-fps", "60", "--", "--captura", "--edificio", edificio, "--bot-partida",
             "--nivel", nivel, "--semilla", str(semilla), "--limite", "3000"]
    salida = subprocess.run(orden, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                            errors="replace").stdout
    for linea in salida.splitlines():
        if linea.startswith("BOT: PARTIDA") or linea.startswith("BOT: ATASCO") or "ERROR DE LA PRUEBA" in linea:
            print("  " + linea.rstrip(), flush=True)


def resumen_partidas(edificios, niveles, semillas):
    lineas = ["# Partidas enteras del bot", "",
              "Johnny recién empezado (la pistola y la fregona, 2 molotovs y 2 granadas), sin talentos, con su munición y "
              "su vida de verdad. Cada fila: cuántas partidas, hasta qué planta llega cada una, cuántas gana, lo que tarda "
              "de media cada planta (de entrar a matar al jefe), la vida con la que llega al jefe y de qué muere.", ""]
    for ed in edificios:
        for nivel in niveles:
            partidas = []
            for s in semillas:
                ruta = os.path.join(RAIZ, "capturas", "bot", f"partida-{ed}-{nivel}-{s}.jsonl")
                if os.path.exists(ruta):
                    with open(ruta, encoding="utf-8") as f:
                        partidas += [json.loads(l) for l in f if l.strip()]
            if not partidas:
                continue
            finales = Counter(p["final"] for p in partidas)
            plantas = Counter(p["planta_max"] for p in partidas)
            tiempos = [pl["jefe_muerto"] - pl["entra"] for p in partidas for pl in p["plantas"] if "jefe_muerto" in pl]
            vidas = [pl["vida_al_jefe"] for p in partidas for pl in p["plantas"] if "vida_al_jefe" in pl]
            muertes = Counter(f"{p['muere']['de']} ({p['muere']['sitio']}, planta {p['muere']['planta']})"
                              for p in partidas if p.get("muere"))
            atascos = sum(len(p.get("atascos", [])) for p in partidas)
            lineas += [f"## {ed.capitalize()} · {nivel} ({len(partidas)} partidas)", "",
                       f"- Final: " + ", ".join(f"{k} {v}" for k, v in finales.most_common()),
                       f"- Hasta la planta: " + ", ".join(f"{k}: {v}" for k, v in sorted(plantas.items())),
                       f"- Cada planta, de entrar a matar al jefe: {round(media(tiempos))} s de media" if tiempos else
                       "- Ninguna planta pasada",
                       f"- Llega al jefe con {round(media(vidas))} de vida de media" if vidas else "- No llega a ningún jefe",
                       f"- Muere por: " + "; ".join(f"{k} ×{v}" for k, v in muertes.most_common(5)) if muertes else "- No muere",
                       f"- Atascos: {atascos}", ""]
    texto = "\n".join(lineas)
    print(texto)
    with open(os.path.join(RAIZ, "capturas", "bot", f"resumen-partidas-{semillas[0]}.md"), "w", encoding="utf-8") as f:
        f.write(texto + "\n")


def main():
    a = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    a.add_argument("--partidas", type=int, default=0,
                   help="fase 2: tantas partidas enteras por edificio y nivel (en vez de las peleas contra los jefes)")
    a.add_argument("--peleas", type=int, default=8)
    a.add_argument("--niveles", default=",".join(NIVELES))
    a.add_argument("--edificios", default=",".join(EDIFICIOS))
    a.add_argument("--jefes", default="")
    a.add_argument("--semilla", type=int, default=None)
    a.add_argument("--resumen", type=int, default=None, help="solo el resumen de esa semilla")
    args = a.parse_args()
    if args.resumen is not None:
        resumen(args.resumen)
        return
    semilla = args.semilla if args.semilla is not None else random.randint(1000, 99999)
    print(f"Semilla {semilla}", flush=True)
    if args.partidas:
        semillas = [semilla + i for i in range(args.partidas)]
        for ed in args.edificios.split(","):
            for nivel in args.niveles.split(","):
                print(f"== {ed} · {nivel} ==", flush=True)
                for s in semillas:
                    jugar_partida(ed, nivel, s)
        resumen_partidas(args.edificios.split(","), args.niveles.split(","), semillas)
        return
    for ed in args.edificios.split(","):
        jugar(ed, args, semilla)
    resumen(semilla)


if __name__ == "__main__":
    main()
