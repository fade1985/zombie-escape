"""Mete en la hoja de Johnny con un arma de golpe la animación de golpear mientras anda.

  py tools/golpe_andando.py conserje-48-guardia            la monta en la hoja y rehace su .tres
  py tools/golpe_andando.py conserje-48-guardia muestra    además, capturas/golpe-andando-<hoja>.png para repasarla

Antes, al golpear andando, Johnny se pintaba partido por la cintura: el cuerpo del dibujo del golpe y las piernas del
dibujo de andar (cintura.gdshader y tools/piernas.py). Se notaba el pegote. Ahora PixelLab dibuja el golpe entero con
las piernas andando (14 nov; PixMiniMax, 12 fotogramas más el de partida, una generación por dirección): el dibujo de
partida y el de llegada es el primero del paso de esa dirección, tal cual está en la hoja (la casilla entera, de 96x96),
para que arranque ya andando y al acabar enlace con el paso. Los dibujos que da están en
assets/sources/<hoja>/golpe-andando/<dirección>-<n>.png; el texto, en assets/pixellab.json (<hoja> → golpe_andando).

Qué hace:
  1. Coloca cada dibujo en su casilla: PixelLab devuelve el lienzo algo más grande y movido; como el dibujo 0 es el de
     partida, se mira cuánto se movió y se deshace. Si algo se saliera de la casilla, avisa.
  2. Elige los dibujos de cada dirección: desde 3 antes de que el arma llegue al suelo (IMPACTO, mirado a ojo) hasta el
     11. Así el golpe llega en el cuarto dibujo en todas, como en el golpe de pie ("hit" 0,333). El 0 es el de partida
     y el 12 casi repite el primero del paso, con el que sigue al acabar: no se usan.
  3. Los pone en filas nuevas al final de la hoja (animación "attackwalk"; en Godot, "ataqueandando_<dirección>") y
     rehace el .tres con tools/hacer_frames.py. Si la hoja ya las tenía, las pisa.
  4. Si la hoja tiene mapa de relieve (<hoja>_n.png, una prueba), lo alarga igual, vacío, para que siga casando.

Después hay que pasar, por este orden: py tools/cara.py <skin> <arma> con cada skin (pega su cabeza en las filas nuevas),
py tools/piernas.py <arma> (su imagen tiene que medir lo mismo que la hoja) e importar en Godot.
"""
import json, os, subprocess, sys
import numpy as np
from PIL import Image

# En qué dibujo de PixelLab llega el arma al suelo, en cada dirección
IMPACTO = {
	"conserje-48-guardia": {"south": 4, "south-east": 5, "east": 4, "north-east": 3, "north": 4, "north-west": 5,
		"west": 4, "south-west": 5},
}
ULTIMO = 11
FPS = 22        # (da igual: johnny.gd lo acompasa a lo que dura el golpe)
HIT = 0.333
DIRECCIONES = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]

nombre = sys.argv[1]
muestra = "muestra" in sys.argv
HOJA = f"assets/sprites/{nombre}"
FUENTE = f"assets/sources/{nombre}/golpe-andando"
meta = json.load(open(f"{HOJA}.json", encoding="utf-8"))
hoja = Image.open(f"{HOJA}.png").convert("RGBA")
cw, ch = meta["cell"]

# Las filas: las que ya tenía la animación o, si es nueva, las siguientes a la última de la hoja
if "attackwalk" in meta["anims"]:
	primera = min(v["row"] for v in meta["anims"]["attackwalk"]["dirs"].values())
else:
	primera = 1 + max(v["row"] for a in meta["anims"].values() for v in a["dirs"].values())
alto = (primera + len(DIRECCIONES)) * ch
if hoja.height < alto:
	mayor = Image.new("RGBA", (hoja.width, alto), (0, 0, 0, 0))
	mayor.paste(hoja, (0, 0))
	hoja = mayor
hoja.paste((0, 0, 0, 0), (0, primera * ch, hoja.width, alto))

dirs = {}
for n, direccion in enumerate(DIRECCIONES):
	paso = meta["anims"]["walk"]["dirs"][direccion]
	x0, y0 = paso.get("col", 0) * cw, paso["row"] * ch
	partida = hoja.crop((x0, y0, x0 + cw, y0 + ch))
	dibujos = [Image.open(f"{FUENTE}/{direccion}-{i}.png").convert("RGBA") for i in range(13)]
	# cuánto movió PixelLab el dibujo: el 0 es el de partida
	a, b = dibujos[0].getbbox(), partida.getbbox()
	dx, dy = b[0] - a[0], b[1] - a[1]
	igual = np.array(dibujos[0].crop(a)).shape == np.array(partida.crop(b)).shape and \
		(np.array(dibujos[0].crop(a)) == np.array(partida.crop(b))).all()
	if not igual:
		print(f"  OJO: en {direccion} el dibujo 0 no es el de partida (¿se ha rehecho el paso de la hoja?)")
	impacto = IMPACTO[nombre][direccion]
	elegidos = list(range(impacto - 3, ULTIMO + 1))
	fila = primera + n
	for k, i in enumerate(elegidos):
		caja = dibujos[i].getbbox()
		if caja[0] + dx < 0 or caja[1] + dy < 0 or caja[2] + dx > cw or caja[3] + dy > ch:
			print(f"  OJO: en {direccion} el dibujo {i} se sale de la casilla")
		casilla = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
		casilla.paste(dibujos[i], (dx, dy))
		hoja.paste(casilla, (k * cw, fila * ch))
	dirs[direccion] = {"row": fila, "frames": len(elegidos)}
	print(f"{direccion}: dibujos {elegidos[0]} a {elegidos[-1]} ({len(elegidos)}), en la fila {fila}")

meta["anims"]["attackwalk"] = {"fps": FPS, "loop": False, "hit": HIT, "dirs": dirs}
hoja.save(f"{HOJA}.png", optimize=True)
with open(f"{HOJA}.json", "w", encoding="utf-8", newline="\n") as f:
	json.dump(meta, f, ensure_ascii=False, indent=2)
	f.write("\n")
subprocess.run([sys.executable, "tools/hacer_frames.py", HOJA], check=True)

# El mapa de relieve, igual de alto (vacío en las filas nuevas)
if os.path.exists(f"{HOJA}_n.png"):
	relieve = Image.open(f"{HOJA}_n.png")
	if relieve.height < hoja.height * relieve.width // hoja.width:
		mayor = Image.new(relieve.mode, (relieve.width, hoja.height * relieve.width // hoja.width))
		mayor.paste(relieve, (0, 0))
		mayor.save(f"{HOJA}_n.png", optimize=True)
		print(f"{HOJA}_n.png: alargado a {mayor.size}")

if muestra:
	os.makedirs("capturas", exist_ok=True)
	ancho = max(v["frames"] for v in dirs.values())
	foto = Image.new("RGBA", (ancho * cw, len(DIRECCIONES) * ch), (120, 95, 75, 255))
	foto.alpha_composite(hoja.crop((0, primera * ch, ancho * cw, alto)))
	foto.save(f"capturas/golpe-andando-{nombre}.png")
