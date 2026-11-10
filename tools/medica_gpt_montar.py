"""Prepara las carpetas de la médica con GPT (tools/zombi_gpt.py --zombi medica ...) como las espera tools/superviviente.py:
copia el dibujo quieto, el andar (sin el quieto: del 1 al 8), el pinchazo (accion), la caída (caido) y el forzar la
cerradura (solo de frente y de espaldas) a assets/sources/superviviente-medicagpt-48/. Luego:
  py tools/medica_gpt_montar.py
  py tools/superviviente.py medicagpt
  py tools/hacer_frames.py assets/sprites/superviviente-medicagpt
La hoja nueva va aparte (superviviente-medicagpt) hasta que el dueño la elija en vez de la de PixelLab."""
import json, os, shutil
DE = "assets/sources/superviviente-medica-gpt-48"
A = "assets/sources/superviviente-medicagpt-48"
shutil.rmtree(A, ignore_errors=True)
for c in ("rotations", "walk", "accion", "caido", "forzar"):
    os.makedirs(f"{A}/{c}")
dirs = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
for d in dirs:
    shutil.copy(f"{DE}/rotations/{d}.png", f"{A}/rotations/{d}.png")
    for n in range(8):   # el andar sin el quieto: del fotograma 1 al 8 → del 0 al 7
        shutil.copy(f"{DE}/walk/{d}-{n + 1}.png", f"{A}/walk/{d}-{n}.png")
    for n in range(9):
        shutil.copy(f"{DE}/ataque/{d}-{n}.png", f"{A}/accion/{d}-{n}.png")
for n in range(9):
    shutil.copy(f"{DE}/muerte/south-{n}.png", f"{A}/caido/south-{n}.png")
    for d in ("south", "north"):
        shutil.copy(f"{DE}/forzar/{d}-{n}.png", f"{A}/forzar/{d}-{n}.png")
# el pinchazo cae en el fotograma 4 de 8 de frente y de perfil, y en el 5 en las otras (se ve en el dibujo)
json.dump({"golpe": {d: 4 for d in dirs}}, open(f"{A}/superviviente.json", "w"), indent=2)
print("listo:", A)
