# La respiración de Johnny (el reposo): rehace esa fila en todas sus hojas, las de cada arma y las de cada skin.
# Uso (desde la raíz del proyecto):  py tools/respiracion.py
#
# El reposo que venía del juego JS (tools/idle.py de allí, como el de tools/superviviente.py) tenía 20 dibujos a 5 por
# segundo: dos respiraciones en 4 segundos, y en cada una subía primero el pecho y luego también la cabeza, 1 píxel de
# golpe. Al moverse la cara tan a menudo se veía a saltos. Ahora:
#   - solo sube el pecho (hombros, brazos y arma); la cabeza se queda quieta
#   - más despacio: dos respiraciones en 6 segundos, con más rato abajo, y el parpadeo en la segunda
# Se aprovechan los dibujos que ya tiene la fila (así valen las skins, que llevan su cabeza pegada en cada uno):
#   0 = quieto · 4 = pecho arriba · 12 = quieto con los ojos cerrados
# Se puede pasar otra vez sin miedo: si la fila ya está hecha, la deja como está.
import json
import pathlib
import re
import subprocess
import sys

from PIL import Image, ImageChops

SPRITES = pathlib.Path("assets/sprites")
FPS = 5
# (dibujo de la fila vieja, cuántos quintos de segundo dura): 1,6 s abajo, 1,2 s arriba, 1 s abajo, parpadeo,
# 0,8 s abajo y 1,2 s arriba = 6 s
CICLO = [(0, 8), (4, 6), (0, 5), (12, 1), (0, 4), (4, 6)]
VIEJA = 20   # dibujos que tenía la fila vieja


def igual(a, b):
    return ImageChops.difference(a, b).getbbox() is None


def rehacer(png, meta, comprobar):
    """Rehace la fila del reposo de cada dirección en esa hoja. Si "comprobar", mira antes que sea la vieja."""
    cw, ch = meta["cell"]
    hoja = Image.open(png).convert("RGBA")
    for d, info in meta["anims"]["idle"]["dirs"].items():
        fila = info["row"]
        celda = lambda i: hoja.crop((i * cw, fila * ch, (i + 1) * cw, (fila + 1) * ch))
        dibujos = [celda(i) for i in range(VIEJA)]
        if comprobar:
            q, c = dibujos[0], dibujos[4]
            if not (all(igual(q, dibujos[i]) for i in (1, 2, 3, 9, 10, 19)) and not igual(q, c)
                    and all(igual(dibujos[5], dibujos[i]) for i in (6, 7))):
                sys.exit(f"{png} ({d}): la fila del reposo no es la de siempre, no se toca")
        hoja.paste(Image.new("RGBA", (cw * VIEJA, ch)), (0, fila * ch))   # se vacía la fila
        for n, (i, _) in enumerate(CICLO):
            hoja.paste(dibujos[i], (n * cw, fila * ch))
    hoja.save(png, optimize=True)


for js in sorted(SPRITES.glob("conserje-48-*.json")):
    tres = js.with_suffix(".tres")
    meta = json.load(open(js, encoding="utf-8"))
    if "idle" not in meta["anims"] or not tres.exists():
        continue
    idle = meta["anims"]["idle"]
    if idle["dirs"]["south"]["frames"] == len(CICLO):
        print(f"{js.stem}: ya estaba hecha")
        continue
    filas = {info["row"] for info in idle["dirs"].values()}
    for nombre, anim in meta["anims"].items():   # nadie más puede usar esas filas
        if nombre != "idle" and any(info["row"] in filas for info in anim["dirs"].values()):
            sys.exit(f"{js.stem}: la animación {nombre} comparte fila con el reposo")
    # las skins: misma hoja con otra cabeza (tools/cara.py) y el mismo .tres cambiando el dibujo
    skins = [p for p in SPRITES.glob(js.stem + "-*.png")
             if p.with_suffix(".tres").exists() and not SPRITES.joinpath(p.stem + ".json").exists()]
    for png in [js.with_suffix(".png")] + skins:
        rehacer(png, meta, True)
    idle["fps"] = FPS
    for info in idle["dirs"].values():
        info["frames"] = len(CICLO)
        info["durations"] = [dura for _, dura in CICLO]
    with open(js, "w", encoding="utf-8", newline="\n") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        f.write("\n")
    vieja = tres.read_text(encoding="utf-8")
    subprocess.run([sys.executable, "tools/hacer_frames.py", str(js.with_suffix("")).replace("\\", "/")], check=True)
    base = tres.read_text(encoding="utf-8")
    # el lanza ácido (desintegrador) lleva en el .tres dónde está la boquilla en cada dibujo del reposo
    # (tools/hoja_lanza_acido.py): se queda con las de los dibujos que siguen
    m = re.search(r"^metadata/puntas = (\{.*\})$", vieja, re.M)
    if m:
        partes = []
        for anim, lista in re.findall(r'"(\w+)": \[([^\]]*)\]', m.group(1)):
            puntos = re.findall(r"Vector2\([^)]*\)", lista)
            partes.append(f'"{anim}": [' + ", ".join(puntos[i] for i, _ in CICLO) + "]")
        base += "metadata/puntas = {" + ", ".join(partes) + "}\n"
        tres.write_text(base, encoding="utf-8", newline="\n")
    for png in skins:
        texto = base.replace(f"res://assets/sprites/{js.stem}.png", f"res://assets/sprites/{png.name}")
        png.with_suffix(".tres").write_text(texto, encoding="utf-8", newline="\n")
    print(f"{js.stem}: hecha, con {len(skins)} skins")
