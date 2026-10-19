# Convierte una hoja de sprites del juego de navegador (<id>.png + <id>.json) en un SpriteFrames de Godot (.tres).
# Uso (desde la raíz del proyecto):  py tools/hacer_frames.py assets/sprites/conserje-48
# Saca assets/sprites/conserje-48.tres con una animación por cada estado y dirección: "andar_se", "reposo_n"...
# Vale para cualquier hoja del juego (Johnny, Johnny con la fregona, zombis): pasa los estados que tenga.
# Se hace con un script porque son 8 direcciones × muchos fotogramas: a mano en el editor sería eterno.
import json
import sys

# Nombre de cada estado del juego en español (los que no estén aquí, o no estén en la hoja, no se pasan)
ESTADOS = {"walk": "andar", "idle": "reposo", "attack": "ataque", "hurt": "golpe", "death": "muerte",
           "fx": "efectos",   # "efectos": fogonazo, humo y casquillo del disparo, para pintarlos encima al andar
           "still": "quieto", "throw": "lanzar", "roar": "grito"}   # estos tres, de la portera
# Direcciones: sur, sureste, este, noreste, norte, noroeste, oeste, suroeste
DIRS = {"south": "s", "south-east": "se", "east": "e", "north-east": "ne",
        "north": "n", "north-west": "no", "west": "o", "south-west": "so"}

base = sys.argv[1]
meta = json.load(open(base + ".json", encoding="utf-8"))
cw, ch = meta["cell"]
ruta_png = "res://" + base.replace("\\", "/") + ".png"   # cómo la llama Godot

subs = []   # un recorte (AtlasTexture) por fotograma
anims = []
for estado, es in ESTADOS.items():
    if estado not in meta["anims"]:
        continue
    a = meta["anims"][estado]
    for d, dd in DIRS.items():
        if d not in a["dirs"]:
            continue   # hay animaciones dibujadas solo en alguna dirección (el grito de la portera, solo al sur)
        info = a["dirs"][d]
        frames = []
        for f in range(info["frames"]):
            col = info.get("col", 0) + f
            sid = f"t{len(subs)}"
            subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("hoja")\n'
                        f'region = Rect2({col * cw}, {info["row"] * ch}, {cw}, {ch})\n')
            frames.append(f'{{"duration": 1.0, "texture": SubResource("{sid}")}}')
        anims.append(f'{{"frames": [{", ".join(frames)}], "loop": {str(a.get("loop", True)).lower()}, '
                     f'"name": &"{es}_{dd}", "speed": {float(a.get("fps", 8))}}}')

with open(base + ".tres", "w", encoding="utf-8", newline="\n") as out:
    out.write(f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n')
    out.write(f'[ext_resource type="Texture2D" path="{ruta_png}" id="hoja"]\n\n')
    out.write("\n".join(subs))
    out.write("\n[resource]\nanimations = [" + ", ".join(anims) + "]\n")
print(f"{base}.tres: {len(anims)} animaciones, {len(subs)} fotogramas")
