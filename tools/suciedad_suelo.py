# La suciedad del suelo del pasillo del ascensor de los Apartamentos (suelo-pasillo.png: baldosa de gres con grietas, huecos, arañazos y
# manchas granate, tools/portal_gpt.py) sacada a una capa transparente, para ponerla encima del suelo de las salas destrozadas de la tienda
# de ropa (18 nov, el dueño: «ensucia el suelo como en el pasillo del ascensor»): assets/sprites/suciedad-suelo.png, 128 × 128, que se
# repite sin cortes. De cada baldosa (16 × 16, con la junta en el borde) se quita el color liso y solo se queda lo que se aparta de él:
# lo oscuro (grietas, huecos, manchas) en negro con su transparencia, y lo rojizo (las manchas granate) en su color; las juntas no se
# copian (cada suelo trae las suyas)
#   py tools/suciedad_suelo.py   (y luego Godot --headless --path . --import)
import json
import numpy as np
from PIL import Image

src = np.asarray(Image.open("assets/sprites/suelo-pasillo.png").convert("RGB")).astype(float)
H, W, _ = src.shape
sal = np.zeros((H, W, 4))
luz = src @ np.array([0.3, 0.59, 0.11])
for ty in range(H // 16):
    for tx in range(W // 16):
        y0, x0 = ty * 16, tx * 16
        dentro = (slice(y0 + 2, y0 + 14), slice(x0 + 2, x0 + 14))
        media = np.median(luz[dentro])
        for y in range(y0 + 2, y0 + 14):
            for x in range(x0 + 2, x0 + 14):
                dev = luz[y, x] - media
                r, g, b = src[y, x]
                if r > g + 22 and r > b + 18:   # lo granate, en su color
                    sal[y, x] = [r * 1.15, g, b, 235]
                elif dev < -7:                   # lo oscuro, en negro
                    sal[y, x] = [10, 8, 10, min(190, -dev * 5.5)]
im = Image.fromarray(np.clip(sal, 0, 255).astype(np.uint8), "RGBA")
im.save("assets/sprites/suciedad-suelo.png")
with open("assets/sprites/suciedad-suelo.json", "w", encoding="utf-8", newline="\n") as f:
    json.dump({"cell": [W, H], "pivot": [0, 0], "scale": 1, "suavizar": 0,
               "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
    f.write("\n")
print(im.size, int((sal[..., 3] > 0).sum()), "píxeles")
