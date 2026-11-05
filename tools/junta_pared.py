"""Busca dos juntas de una pared (de frente) para que la tira empalme a lo ancho: las dos columnas x0 y x1 que más
se parecen (y la columna anterior a x1 con la anterior a x0), con un ancho entre min y max.
  py tools/junta_pared.py <imagen> <y0> <y1> <ancho mínimo> <ancho máximo>"""
import sys
from PIL import Image
import numpy as np
im = np.asarray(Image.open(sys.argv[1]).convert('RGB')).astype(int)
y0, y1, mn, mx = map(int, sys.argv[2:6])
c = im[y0:y1]
W = c.shape[1]
res = []
for a in range(W):
    for b in range(a + mn, min(W, a + mx + 1)):
        d = abs(c[:, a] - c[:, b]).mean() + abs(c[:, max(a - 1, 0)] - c[:, b - 1]).mean()
        res.append((d, a, b))
res.sort()
for d, a, b in res[:6]:
    print(f'x0={a} x1={b} (ancho {b - a}) diferencia {d:.1f}')
