# Graba el trailer del juego y lo monta con la música (ver docs/TRAILER.md). Desde la carpeta del juego:
#   py tools/trailer.py              → exportar/trailer/trailer.mp4 (1920×1080, 60 fps) y trailer.gif (corto, para redes)
#   py tools/trailer.py --montar     → solo el montaje, con los fotogramas de la última grabación
#
# 1) Pone un override.cfg (lo lee Godot al arrancar y gana a project.godot) con la pantalla del trailer: 960×540 por
#    dentro y la ventana a 1920×1080, justo por 2. Lo quita al acabar.
# 2) Arranca el juego con el Movie Maker de Godot (--write-movie): graba cada fotograma y el sonido, sin tirones aunque
#    el ordenador vaya lento (va más despacio que de verdad: unos 6 minutos). La prueba --trailer (trailer.gd) juega
#    las escenas y avisa en la terminal del fotograma en que empieza (lo de antes, el menú y la carga, se tira).
# 3) Con ffmpeg: los fotogramas y los efectos de sonido del juego, más la canción «Turno de noche» entrando y saliendo
#    despacio, al mp4. Y un gif de unos segundos de la pelea.
import os
import re
import shutil
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "exportar", "trailer")
FOTOGRAMAS = os.path.join(SALIDA, "fotogramas")
FPS = 60
MUSICA = os.path.join(RAIZ, "assets", "musica", "turno-de-noche.ogg")
GODOTS = [r"C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
	r"C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"]
OVERRIDE = """[display]

window/size/viewport_width=960
window/size/viewport_height=540
window/size/window_width_override=1920
window/size/window_height_override=1080
window/size/mode=0
"""


def grabar() -> int:
	godot = next((g for g in GODOTS if os.path.exists(g)), None)
	if not godot:
		sys.exit("No encuentro Godot (ver CLAUDE.md)")
	shutil.rmtree(FOTOGRAMAS, ignore_errors=True)
	os.makedirs(FOTOGRAMAS)
	override = os.path.join(RAIZ, "override.cfg")
	with open(override, "w", encoding="utf-8") as f:
		f.write(OVERRIDE)
	try:
		salida = subprocess.run([godot, "--path", RAIZ, "--fixed-fps", str(FPS), "--write-movie",
			os.path.join(FOTOGRAMAS, "f.png"), "--", "--captura", "--trailer"],
			capture_output=True, text=True, encoding="utf-8", errors="replace").stdout
	finally:
		os.remove(override)
	for linea in salida.splitlines():
		if "ERROR" in linea or "Movie" in linea or "recorded" in linea:
			print(linea)
	m = re.search(r"TRAILER-EMPIEZA (\d+)", salida)
	if not m:
		sys.exit("El trailer no ha dicho en qué fotograma empieza (¿ha fallado la prueba --trailer?)")
	with open(os.path.join(FOTOGRAMAS, "empieza.txt"), "w") as f:
		f.write(m.group(1))
	return int(m.group(1))


def montar(empieza: int) -> None:
	total = len([n for n in os.listdir(FOTOGRAMAS) if n.endswith(".png")]) - empieza
	dura = total / FPS
	video = os.path.join(SALIDA, "trailer.mp4")
	sonido = os.path.join(FOTOGRAMAS, "f.wav")
	salto = empieza / FPS
	# los efectos del juego, un poco más bajos; la música, entrando en 1 s y saliendo en los 3 últimos
	mezcla = (f"[1:a]atrim=start={salto:.3f},asetpts=PTS-STARTPTS,volume=0.8[efectos];"
		f"[2:a]atrim=0:{dura:.3f},afade=t=in:d=1,afade=t=out:st={max(0.0, dura - 3):.3f}:d=3,volume=0.9[musica];"
		"[efectos][musica]amix=inputs=2:duration=first:normalize=0[a]")
	subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-start_number", str(empieza),
		"-i", os.path.join(FOTOGRAMAS, "f%08d.png"), "-i", sonido, "-i", MUSICA, "-filter_complex", mezcla,
		"-map", "0:v", "-map", "[a]", "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p",
		"-c:a", "aac", "-b:a", "192k", "-t", f"{dura:.3f}", video], check=True)
	# el gif: 6 s de la pelea de la escopeta, a 480 de ancho y 20 fps (para redes y la página de Steam)
	gif = os.path.join(SALIDA, "trailer.gif")
	subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", "9", "-t", "6", "-i", video, "-vf",
		"fps=20,scale=480:-1:flags=neighbor,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=none",
		gif], check=True)
	print(f"Hecho: {video} ({dura:.1f} s) y {gif}")


if __name__ == "__main__":
	if "--montar" in sys.argv:
		with open(os.path.join(FOTOGRAMAS, "empieza.txt")) as f:
			montar(int(f.read()))
	else:
		montar(grabar())
