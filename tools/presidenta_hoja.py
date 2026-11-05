"""La hoja de la presidenta de Velaria (el laboratorio de la planta 40 de la torre, laboratorio.gd): dos filas de 9
fotogramas, cada uno en su celda, todas del mismo tamaño y con los pies alineados abajo y en medio.
  fila 0: tableta (de frente; el 0 es la vista quieta)
  fila 1: huir (corriendo hacia la derecha; el juego la voltea para que corra hacia la izquierda)
Se recorta el margen transparente que sobra a todas por igual.
  py tools/presidenta_hoja.py   → assets/sprites/presidenta.png"""
from PIL import Image

FUENTE = 'assets/sources/presidenta-72'
FILAS = [('tableta', 'south'), ('huir', 'east')]
N = 9
fotos = [[Image.open(f'{FUENTE}/{a}/{d}-{i}.png').convert('RGBA') for i in range(N)] for a, d in FILAS]
W = max(f.width for fila in fotos for f in fila)
H = max(f.height for fila in fotos for f in fila)
# cada fotograma, en una celda W x H con su lienzo centrado abajo
celdas = []
for fila in fotos:
    c = []
    for f in fila:
        cel = Image.new('RGBA', (W, H))
        cel.paste(f, ((W - f.width) // 2, H - f.height))
        c.append(cel)
    celdas.append(c)
# lo que ocupan de verdad todas juntas
caja = None
for fila in celdas:
    for cel in fila:
        b = cel.getbbox()
        if b:
            caja = b if caja is None else (min(caja[0], b[0]), min(caja[1], b[1]), max(caja[2], b[2]), max(caja[3], b[3]))
x0, y0, x1, y1 = caja
# (simétrico a lo ancho, para que al voltearla no se mueva)
m = max(W // 2 - x0, x1 - W // 2)
x0, x1 = W // 2 - m, W // 2 + m
cw, ch = x1 - x0, y1 - y0
hoja = Image.new('RGBA', (cw * N, ch * len(FILAS)))
for r, fila in enumerate(celdas):
    for i, cel in enumerate(fila):
        hoja.paste(cel.crop((x0, y0, x1, y1)), (i * cw, r * ch))
hoja.save('assets/sprites/presidenta.png')
print('presidenta.png', hoja.size, 'celda', (cw, ch))
