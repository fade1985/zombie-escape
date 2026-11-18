# Zombis de 112 px (el dibujo detallado)

La dependienta (18 nov) fue la primera: un personaje de PixelLab de 112 px, mucho más detallado que los zombis de
48, que en el juego se dibuja a escala 1 (cada píxel del dibujo, 1 unidad; los de 48 van a escala 2). Así queda casi
igual de alta que los demás, pero con el doble de detalle. Esta es la receta para hacer otro.

## 1. El personaje en PixelLab

- Personaje de **112 px** (el de la dependienta: «Dependienta verde 112», id `de59f7de-5243-4d15-a7b3-5b11f9115676`).
  En PixelLab **no se borra nada** sin permiso expreso del dueño.
- Las poses de pie (rotaciones) salen con el personaje: se bajan a `assets/sources/<carpeta>/animaciones/rotaciones/`
  (112×112, los pies en 56,110).
- **Solo cinco direcciones**: `south`, `south-east`, `east`, `north-east` y `north`. Las tres del oeste salen en espejo
  al montar la hoja, así que no se piden (ahorra casi la mitad).
- **Animaciones** (de la dependienta: lo que costó cada dirección, `andar 3 + golpe 3 + muerte 1 + zarpazo 1`, 8
  generaciones):
  - `andar` (8 fotogramas) y `golpe` (8), con el modo v3.
  - `muerte` (12) y `zarpazo` (8), con el modo barato (pixminimax): además del texto lleva la descripción del personaje
    y la pose de partida.
  - Las que son de cara, como el `grito`, solo en `south` (siempre se hace mirando a la pantalla).
- Los textos que se usaron con la dependienta, enteros: `assets/sources/dependienta-96-gpt/textos-pixellab.txt` (los
  de las tres direcciones que faltaban; cada uno dice cómo mira, hacia dónde va y qué no debe hacer, porque si no
  PixelLab gira la cara o la hace caer hacia otro lado).
- **Antes de mandar nada a PixelLab, enseñar al dueño el texto exacto y el coste.** Lanzar las generaciones de golpe y
  comprobar una vez (ver las notas de memoria sobre PixelLab: repetir una animación, andar de lado que se gira...).

## 2. Elegir y limpiar

El dueño elige cada animación. Lo elegido va a `assets/sources/<carpeta>/animaciones/<animación>/<dirección>/frame_NNN.png`
(lienzo de **152×152**, los pies en 76,130). Lo que hubo que limpiar en la dependienta:

- **El andar, centrado** (sin balanceo de lado) y sin los fotogramas que giraban la cara (el `north-east` se quedó en 7).
  Si una dirección tiene menos fotogramas, la herramienta alarga cada uno para que dé el paso al mismo ritmo.
- **La muerte**: sin la sangre suelta y con el fotograma 0 en la pose de pie limpia. La sangre pegada al cuerpo que
  quede se quita con `"sangre"` en la ficha (abajo).
- El fotograma 0 de `zarpazo`, `golpe` y `muerte` es la pose de pie: no se usa (`"desde": 1`), ya está en el quieto.

## 3. Montar la hoja

Cada zombi lleva su ficha, `assets/sources/<carpeta>/hoja.json` (la de la dependienta sirve de ejemplo), y se monta con:

```
py tools/hoja_112.py <carpeta>
```

que hace `assets/sprites/<sprite>.png`, `.json` y `.tres` (llama ella misma a `hacer_frames.py`). Con `--gif carpeta`
guarda además un GIF por animación con las 8 direcciones. Qué va en la ficha, al principio de `tools/hoja_112.py`.

La hoja va **apretada**: cada fotograma recortado a lo que ocupa (con aire arriba y abajo para el fuego y el vómito del
shader de los zombis) y los repetidos una sola vez. La de la dependienta ocupa 10 MB en memoria en vez de 50 (en la
web importa). En Godot cada fotograma sigue midiendo la casilla entera gracias a su `margin`; lo que lee los dibujos
(`cuerpo.gd`, `quemado.gd`, `bestiario.gd` y `tools/recortes_bestiario.py`) ya cuenta con él.

## 4. Meterlo en el juego

- En su escena (`escenas/personajes/zombi_<tipo>.tscn`), en el nodo `Sprite`: `scale = Vector2(1, 1)` y
  `offset = Vector2(-76, -130)`; y `altura` (dónde salen sus números de daño) unos 12 por encima de la cabeza (la
  dependienta, 98).
- En `scripts/bestiario.gd`, su `"escala": 1`, y el recorte con `py tools/recortes_bestiario.py`.
- Si tiene una animación propia (como el `grito`), en `hacer_frames.py` (`ESTADOS`) está el nombre que lleva en el
  juego, y su script la pone con `poner_animacion("grito", true)`.

## 5. Probar

- `-- --captura --dependienta`: de ejemplo. Saca una foto al lado de Johnny y de otros zombis, para ver el tamaño; seis
  andando hacia Johnny (fotos para un GIF); una muerta ardiendo y otra a secas; y su retrato del bestiario. Para otro
  zombi, lo mismo con su tipo.
- El ritmo del andar: con 8 fotogramas a 10 por segundo, el paso del dibujo de la dependienta avanza unos 76 píxeles
  por vuelta, justo su velocidad (95): no patina. Si otro zombi va más rápido o más lento, se ajusta `"fps"` del andar
  para que no resbale.
