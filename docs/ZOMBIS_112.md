# Zombis de 112 px (el dibujo detallado)

La dependienta (18 nov) fue la primera: un personaje de PixelLab de 112 px, mucho más detallado que los zombis de
48, que en el juego se dibuja a escala 1 (cada píxel del dibujo, 1 unidad; los de 48 van a escala 2). Así queda casi
igual de alta que los demás, pero con el doble de detalle. Esta es la receta para hacer otro.

**Reducido a la altura de Johnny (19 nov):** con `"reducir": {"casilla": 64, "pies": [32, 55], "borde": "#050202"}` en la
ficha, `tools/hoja_112.py` reduce cada dibujo a una casilla de 64 (mezclando colores, como los muebles) y le pone un borde
de 1 píxel del color del de Johnny; en su escena, `scale = Vector2(2, 2)` y `offset = Vector2(-32, -55)`, como los de 48.
Así va la dependienta desde el 19 nov (lo pidió el dueño): mide lo mismo que Johnny y tiene su acabado, a costa del detalle.
Lo hace `tools/reducir.py`, que también usa `tools/zombi.py` para los de hoja en cuadrícula (el de tentáculos, con
`"casilla": [80, 88]`). Si el dibujo tiene muchas rayas negras finas y reducido sale casi negro, `"realce": true` lo deja
más nítido y algo más claro.

**El explosivo (20 nov)** se hizo igual: el dibujo de frente lo hizo GPT (fondo magenta, porque va de negro), y
`tools/explosivo_112.py` lo deja en la referencia de 112 para PixelLab («Explosivo gabardina 112», id
`bdee687d-8c1c-4375-8a37-4e256db3fea0`; los textos, en `assets/sources/explosivo-112-gpt/textos-pixellab.txt`). Solo
lleva andar, golpe y abrir la gabardina (`attack`): no tiene muerte, revienta. Reducido salía casi negro (gabardina negra
y cara gris verdosa): lleva `"realce": true` y `"piel"` con `"sat_max": 0.35`, para aclarar solo la piel y no la cinta
de la dinamita. Del alto de Johnny se veía flaco y con la cabeza diminuta (proporciones de persona de verdad): va en
una casilla de 80 (`"pies": [40, 69]`, `offset = Vector2(-40, -69)`), un cuarto más grande, y con
`"cabeza": {"cuello": 20, "agranda": 1.15}` la cabeza (lo que hay por encima de la fila 20 de la pose de 112) sale
otro 15 % más grande, desde el cuello. Aun así era una masa negra: `"luz"` aclara la ropa con una curva (los pliegues se
ven) y la tiñe de azul marino (que se separe del suelo, que es pardo), del cuello para abajo (y por encima, con `"arriba_v"`, solo
lo oscuro que no tira a verde: el sombrero sí, la cara no); y `"parche"` quita de debajo del cuello todo lo verde y el caqui (los galones de la manga y la
cinta de la dinamita). La cara, reducida a unos 6 píxeles, salía con puntos sueltos de colores (los ojos, la boca y la
sangre mezclados, y sombras moradas): `"cara"` la deja ya reducida en tres verdes (los de la dependienta) con los ojos y
la boca en un verde muy oscuro. Se prueba con `--captura --explosivo-nuevo`.

**El de las uñas (23 nov)**, un durmiente flaquísimo que dispara las uñas, se hizo **a 160** en vez de a 112 (el dueño lo
quería con más detalle): frente de GPT en magenta, `py tools/unas_referencia.py 160` (sale `referencia-160.png`),
«Durmiente uñas 160» (id `17f80a9c-aee4-479f-83cd-3d9d9e59c49d`; carpeta `assets/sources/unas-gpt/`, con sus textos). A
160 cuesta más: personaje 4, golpe en v3 6 por dirección; el andar (esqueleto, 3) y el modo barato (1) igual. En total,
60 generaciones. La muerte salió con un chorro de sangre aunque se pidió sin ella: lo quita `tools/unas_sin_sangre.py`
(los originales, en `capturas/unas-muerte-con-sangre/`). En la ficha, `"lienzo": {"casilla": 220, "pose": 160}` (las
animaciones salen de 212 a 224 y se ponen en el centro) y reducido a la altura del gordo, 67 píxeles
(`"casilla": 94, "pies": [47, 84]`). Su piel es más amarilla que la de los demás: `"piel_verde"` lleva su tono y deja
fuera los calzoncillos (menos vivos) y las puntas de las uñas (más claras). El andar de frente y de espaldas cruzaba
las piernas: se rehízo con el mismo esqueleto y `"posture": 1` (los pies separados); con texto no daba el segundo paso.

## 1. El personaje en PixelLab

- Personaje de **112 px** (el de la dependienta: «Dependienta verde 112», id `de59f7de-5243-4d15-a7b3-5b11f9115676`).
  En PixelLab **no se borra nada** sin permiso expreso del dueño. El 18 nov, con su permiso, se borró todo lo que no
  se usa: las dependientas de 48 px, la «Dependienta dormida 112» (la prueba con los ojos cerrados) y las tomas que no
  se eligieron. En «Dependienta verde 112» solo quedan sus 8 poses y las 21 animaciones del juego (copia de cómo
  estaba antes, fuera de git: `capturas/pixellab-dependienta-verde-112-copia.zip` y `...-dormida-112-copia.zip`).
- Las poses de pie (rotaciones) salen con el personaje: se bajan a `assets/sources/<carpeta>/animaciones/rotaciones/`
  (112×112, los pies en 56,110).
- **Solo cinco direcciones**: `south`, `south-east`, `east`, `north-east` y `north`. Las tres del oeste salen en espejo
  al montar la hoja, así que no se piden (ahorra casi la mitad).
- **Animaciones** (de la dependienta: lo que costó cada dirección, `andar 3 + golpe 3 + muerte 1 + zarpazo 1`, 8
  generaciones):
  - `andar` (8 fotogramas) y `golpe` (8), con el modo v3. Comprobar que los dos pasos de la vuelta son iguales y que
    el último enlaza con el primero: el primer andar de perfil y el de abajo a la derecha de la dependienta cojeaban
    y pegaban un salto. Se rehicieron el 18 nov (15 generaciones con las pruebas) con el **modo esqueleto**, que es
    lo que dio un andar fluido sin cambiar el dibujo: `mode: skeleton-v3`, plantilla `walking-8-frames`,
    `motion_adjustments: {"stride": 1.15, "arm_swing": 0.6}`, una dirección por llamada, 3 generaciones cada una
    («andar perfil esqueleto» y «andar abajo dcha esqueleto medio»). Lo que no valió: v3 con texto (de perfil la
    cabeza seguía subiendo y bajando 5 píxeles al final de cada paso; en diagonal el paso seguía corto) y la zancada
    a 1,5 (larguísima). Sale en un lienzo de 160: se coloca en la casilla de 152 con la cabeza a la altura de la del
    dibujo quieto (a la dependienta, 6 píxeles a la izquierda y 5 arriba). Si otro zombi cojea o da saltitos al
    andar, probar esto primero.
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
- **La piel**, del mismo verde que los zombis de 48: la de la dependienta salió de PixelLab mucho más oscura y se
  aclara al montar la hoja con `"piel": {"tono": 80, "sat": 1.0, "sube": 0.28}` en la ficha (los dibujos de
  `animaciones/` no se tocan). Se comprueba en la foto de tamaño de `--captura --dependienta`: en el juego su piel
  tiene que medir lo mismo que la del zombi normal (tono unos 83 grados, saturación unos 0,65, luz unos 0,5).
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
