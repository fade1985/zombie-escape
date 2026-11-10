"""Los mensajes de «Contáctanos» (docs/MENSAJES.md): cada uno es un aviso (issue) en el repositorio privado
fade1985/zombie-escape-mensajes. Esto lo usa Claude para enterarse de los nuevos; necesita `gh` con acceso a ese repositorio.

  py tools/mensajes.py              lista los abiertos: los nuevos (sin analizar) y los ya analizados que esperan
  py tools/mensajes.py --aviso      una línea si hay alguno abierto, y nada si no (para el arranque de cada sesión de Claude:
                                    .claude/settings.local.json, SessionStart); si no hay `gh` o no llega, tampoco dice nada
  py tools/mensajes.py --analizado N   le pone la etiqueta «analizado» al aviso N (la crea si no está)

Un mensaje nuevo es un aviso abierto sin la etiqueta «analizado». Analizado: Claude ha dejado en él un comentario con lo que
pasa y un plan, y espera a que el dueño diga «abordémoslo». Hecho: se cierra el aviso.
"""
import json
import subprocess
import sys

REPO = "fade1985/zombie-escape-mensajes"
ETIQUETA = "analizado"


def gh(*args, tiempo=20):
    r = subprocess.run(["gh", *args], capture_output=True, text=True, encoding="utf-8", timeout=tiempo)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or "gh ha fallado")
    return r.stdout


def abiertos():
    datos = gh("issue", "list", "-R", REPO, "--state", "open", "--limit", "100",
               "--json", "number,title,labels,createdAt")
    lista = json.loads(datos)
    nuevos = [m for m in lista if ETIQUETA not in [e["name"] for e in m["labels"]]]
    analizados = [m for m in lista if m not in nuevos]
    return nuevos, analizados


def main():
    sys.stdout.reconfigure(encoding="utf-8")   # (las tildes, también en la consola de Windows)
    args = sys.argv[1:]
    if "--analizado" in args:
        numero = args[args.index("--analizado") + 1]
        etiquetas = json.loads(gh("label", "list", "-R", REPO, "--json", "name"))
        if ETIQUETA not in [e["name"] for e in etiquetas]:
            gh("label", "create", ETIQUETA, "-R", REPO, "--color", "80ed99",
               "--description", "Claude ha dejado el análisis y un plan")
        gh("issue", "edit", numero, "-R", REPO, "--add-label", ETIQUETA)
        print(f"Aviso {numero}: analizado")
        return
    if "--aviso" in args:
        try:
            nuevos, analizados = abiertos()
        except Exception:
            return   # sin gh, sin red o sin acceso: no se molesta al empezar
        if nuevos or analizados:
            print(f"Mensajes de jugadores («Contáctanos», docs/MENSAJES.md): {len(nuevos)} nuevos sin analizar y "
                  f"{len(analizados)} analizados esperando al dueño. Avísale al empezar.")
        return
    nuevos, analizados = abiertos()
    for titulo, lista in (("NUEVOS (sin analizar)", nuevos), ("ANALIZADOS (esperan al dueño)", analizados)):
        print(f"{titulo}: {len(lista)}")
        for m in lista:
            print(f"  #{m['number']}  {m['createdAt'][:10]}  {m['title']}")


if __name__ == "__main__":
    main()
