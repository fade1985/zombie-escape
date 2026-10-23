# Zombie Escape · receta y detalles de PixelLab

Sacado de CLAUDE.md el 13 de octubre de 2026 para que ese archivo pese menos. Se lee solo al generar arte con PixelLab.


Los sprites se generan con PixelLab. Desde el 12 de octubre de 2026 está conectado a Claude Code por su
**servidor MCP** (herramientas `mcp__pixellab__*`), que es la vía principal: no hace falta clave ni script.

- **Plan:** Tier 1 (Pixel Apprentice), **2000 generaciones al mes** (se renuevan el día 12) más un bono diario de 20
  que solo se gasta si se agotan las del mes. Para ver cuántas quedan: herramienta `get_balance`.
- **Lo que cuesta cada cosa** (orientativo; la respuesta de cada herramienta dice lo que se ha cobrado):
  - Personaje en modo estándar: 1. En modo `v3`: 2–9. En modo `pro`: 10–25.
  - Animación de plantilla (`walking`, `breathing-idle`...): 1 por dirección.
  - Animación "a medida" en modo `v3` o `pixminimax`: 1–2 por dirección a 64 px o menos. Ya no hay que evitarlas.
  - Estado de un personaje (otra ropa, un arma en la mano): unas 10.
  - Objeto o mueble (`create_1_direction_object`, `create_8_direction_object`): 10–25.
  - Antes de lanzar tandas grandes, calcular el total y **decírselo al dueño**.
- Todo lo generado se apunta en `assets/pixellab.json` (texto, semilla, ids) para poder repetirlo.
- **Muebles y suelos: como imagen suelta (`create_image_pixflux`, 1 generación cada uno), no como "objeto"**
  (10–25). Los 20 muebles y los 7 suelos tienen sprite.
- **El escenario se ve "en tres cuartos"** (decidido por el dueño el 12 de octubre de 2026, al notar que los
  personajes se veían de lado y el escenario desde arriba): el suelo desde arriba, pero las paredes enseñan su
  cara y los muebles su frente, con altura. Los muebles en planta que se hicieron antes se retiraron.
  - Cada mueble va apoyado en su pared: de frente en la de arriba; en las laterales solo los que tienen
    dibujo de lado (`mueble-<tipo>-lado`: sofá, sillón, bañera, váter) o se ven igual desde cualquier sitio
    (lámpara, planta, perchero, mesilla); en la de abajo solo estos últimos (`goesOn` en `furniture.js`).
  - Receta: sin guía y sin fondo, con un lienzo de largo × (fondo + alto) y el texto "..., front view facing
    the viewer, 3/4 top-down RPG perspective, game furniture sprite". Si sale girado en diagonal, con la guía
    de `py tools/muebles3c.py guias` (un bloque del tamaño del mueble) y con fondo. Montaje:
    `py tools/muebles3c.py monta`. El largo de cada mueble en `MUEBLES` (`src/catalogo.js`) es el ancho de su dibujo × 2.
  - Pendiente: dibujos de lado de cama, estantería, armario, encimera, nevera y demás (los tres primeros se
    pidieron y salieron mal), para que las paredes laterales no se queden tan vacías.
  - **Receta que funciona (centro comercial, 21 oct): siempre con guía.** `py tools/guias_centro.py` pinta un boceto
    de cada mueble ya en la perspectiva del juego (tapa vista desde arriba con lo que tiene encima dibujado, y el
    frente debajo; de lado, la tapa tumbada a lo largo de la pared y el costado corto abajo) sobre azul. Se pasa
    como `init_image` con fuerza 45 y `no_background` false, y luego `guias_centro.py quita` le quita el fondo.
    Con fondo transparente PixelLab se come la tapa; con la tapa lisa en la guía, la deja lisa; los muebles altos
    de lado no salen bien (se dejan para la pared del fondo). Para que algo salga destrozado, decirlo en el texto
    ("wrecked, dented, blood splatter, zombie apocalypse").
  - PixelLab solo deja 8 generaciones a la vez. **La clave `PIXELLAB_API_KEY` de este ordenador es de otra
    cuenta, sin saldo**: todo se pide por MCP.
- **Animaciones muy sutiles (reposo): mejor hacerlas a mano que pedirlas.** Las de PixelLab redibujan el
  personaje en cada fotograma y a 48 píxeles la cara "baila". La de reposo de Johnny (`conserje-48`) la hace
  `tools/idle.py` a partir de sus 8 rotaciones: respiración de 1 píxel y parpadeo, sin tocar ningún otro píxel.
  PixelLab sigue siendo lo indicado para animaciones con movimiento de verdad (andar, atacar, morir).
- **Andar de Johnny:** plantilla `walking-8-frames` de PixelLab en las 8 direcciones. Los fotogramas tal cual
  salen se guardan en `assets/sources/conserje-48/walk/` y `tools/walk.py conserje-48` los monta en la hoja
  (iguala los colores a los del dibujo quieto y alinea los pies). En el juego el paso avanza según la distancia
  recorrida (`STEP` en `entities.js`), no según el reloj: así arranca y frena con el personaje.
- **Las plantillas no valen para un personaje con un arma en la mano.** Probado el 12 de octubre de 2026 con
  `walking-8-frames` sobre el estado "Fregona en guardia": en 7 de las 8 direcciones Johnny pierde la fregona y
  sale más grande. Para esos estados, todo con PixMiniMax (el andar también: 1 generación por dirección, las 8
  en una sola llamada, y luego se recorta el tramo que hace ciclo).
- **Los supervivientes (22 oct, `pixellab.json` → `supervivientes-48`):** personaje con las manos vacías y el arma
  guardada (funda o fusil a la espalda), hecho con `create_character_pro_flash` a 48 y el sur de Johnny como estilo
  (6 generaciones; dos intentos y elige el dueño). Con las manos vacías la plantilla `walking-8-frames` va bien a la
  primera en las 8 direcciones. La acción (sacar el arma, disparar y guardarla; la jeringa) con PixMiniMax, 8
  fotogramas y el quieto como partida y llegada, 1 por dirección. Lo aprendido: PixelLab vuelve a medir el lienzo
  alrededor del movimiento (de 96 pasa a 104, 120 o 128 de ancho), así que la hoja se monta alineando cada tira por su
  fotograma 0; el detector automático del tinte amarillo del fogonazo (`tools/superviviente.py`, receta de `arma.py`
  del JS) se confunde si el personaje dobla las rodillas al apuntar (el militar): mejor decirle a mano los fotogramas
  (`superviviente.json`, `sin_tinte`); y estos personajes no tienen blanco en los ojos, así que el parpadeo a mano de
  Johnny no se les puede hacer (solo respiran).
- **Los supervivientes del centro comercial (22 oct, `pixellab.json` → `supervivientes-centro-48`):** la misma
  receta (79 generaciones). El ferretero da un martillazo con chispazo blanco y el técnico suelta un chispazo celeste
  con su aparato; la farmacéutica no tiene acción. En la hoja (`tools/superviviente.py`) no hay fogonazo amarillo ni
  boca del arma: el momento de lo suyo se busca por el chispazo, salvo en el ferretero, que se dice a mano
  (`superviviente.json`, `golpe`: el detector se quedaba con el fotograma de más chispas, que va después del golpe).
  Al noroeste, en el fotograma antes del chispazo, PixelLab tiñó de celeste la cabeza, los brazos y la camisa del
  técnico: se tapó con los colores del fotograma siguiente, que tiene la misma postura (el original, en `intentos/`).
- **Las skins de Johnny (24 oct, `pixellab.json` → `skin-portero`): otra cara sin rehacer ninguna animación.**
  Una sola petición de `edit_image` (modo texto, 10 generaciones) con las 8 rotaciones de Johnny quieto: «conviértelo
  en...», manteniendo ropa, postura y tamaño. Los 8 dibujos van a `assets/sources/skin-<id>/quietos/` y
  `py tools/cara.py <id>` pega la cabeza nueva en los ~1.700 dibujos de las seis hojas de armas (busca la cabeza por el
  pañuelo rojo; con `muestra`, el antes y el después en `captura-cara-<arma>.png`). Lo aprendido: PixelLab movió el
  cuerpo de lado hasta 7 píxeles en algunas direcciones (la herramienta lo alinea mirando el cuerpo); la madera de las
  armas tiene los mismos colores que el pelo, así que donde el palo pasa justo por delante de la cara, la cabeza nueva
  lo tapa un poco; y los cartuchos rojos de la escopeta despistan al buscar el pañuelo (se prueban todas las manchas
  rojas cercanas y gana la que mejor encaja). Para una skin que cambie el cuerpo, no solo la cabeza, esto no basta.
  - **La segunda, el glotón (24 oct, `skin-gloton`)**, igual: una petición, 10 generaciones, a la primera (esa vez
    PixelLab tardó unos 15 minutos). El texto pide quitar el pelo y el pañuelo, la cara hecha una boca enorme con
    colmillos, encías rojas y la garganta oscura, y dos ojillos encima; de lado, la boca de perfil, y de espaldas, la
    calva. Lo aprendido al pegarla: con una cabeza calva lo que sobra del pelo y del pañuelo de siempre alrededor no
    se tiñe, se quita (`SOBRA` en `cara.py`): los trozos que tocan el aire se borran con su contorno y los metidos
    entre otras cosas se pintan de piel; las puntas del pañuelo vuelan lejos en los golpes (para el rojo se mira más
    lejos de la cabeza) y en algunos golpes PixelLab pintó el pañuelo de un rojo más vivo que el de la paleta de
    Johnny; y quedan motas negras sueltas del contorno de las puntas del pelo, que también se quitan. En un par de
    dibujos del golpe con el bate Johnny se gira y se le pone la cabeza de espaldas: le pasa igual al portero.
  - **La tercera, el gymbro (24 oct, `skin-gymbro`)**, igual: una petición, 10 generaciones, a la primera (unos 6
    minutos). El texto pide quitar el pelo castaño (calva lisa del color de la piel) y dejar el pañuelo rojo tal cual,
    con su nudo y sus puntas, y una barba negra tupida con bigote y cejas negras; de lado, la barba de perfil, y de
    espaldas, la calva con el nudo del pañuelo. Lo aprendido al pegarla: calvo pero con pañuelo pide un tercer modo
    (`SOBRA` = "calvo"): se quita lo que sobre del pelo como con el glotón, pero el pañuelo, sus puntas al viento y su
    contorno se respetan (tampoco se borran las islitas sueltas que tengan rojo); y los rojos más vivos que no son de
    la paleta, dentro de la cabeza, se tapan con la cabeza nueva, como en el glotón. La barba se pega con el trozo de
    contorno del cuello que la rodea: en algún golpe en que el hombro se mueve, asoma una rayita oscura junto a la barba
    (al portero le pasa igual). Las hojas del portero y del glotón salen iguales al volver a sacarlas.
- **Receta para animar un personaje nuevo:** probar 3 o 4 plantillas en una sola dirección (de perfil, `east`),
  elegir la mejor y lanzar las otras 7 direcciones en el mismo grupo (`animation_group_id`).
- **Animaciones a medida (sin plantilla): usar el modo `pixminimax`, no `v3`.** Probados los dos con Johnny el
  12 de octubre de 2026: PixMiniMax mantiene la cara, la ropa y el tamaño; v3 le cambió la cara en el reposo y
  le quitó la camisa en el ataque. Cuesta 1 generación por dirección con 8 o 12 fotogramas a 64 píxeles.
  - El texto, largo y por partes, como en los ejemplos de la web de PixelLab: qué hace el cuerpo, qué se mueve
    detrás (pelo, tela, la mopa), el efecto, cómo vuelve a la postura inicial, y al final "Static camera,
    completely locked-off shot. Maintain the crisp 2D pixel art aesthetic...". El texto usado para el ataque de
    la fregona está entero en `assets/pixellab.json` (`conserje-48-guardia` → `ataque_pruebas`).
  - Para que la animación acabe donde empieza, pasar el dibujo quieto de esa dirección también como fotograma
    final (`end_frame_base64`). Obliga a lanzar las direcciones de una en una.
  - Si el movimiento se sale del lienzo (un arma larga), dar como fotograma de partida y de llegada el dibujo
    quieto centrado en un lienzo mayor. Para el ataque de la fregona: el de 64×64 pegado en uno de 96×96 en la
    posición (16, 20).
  - No pedir parpadeos: los hace largos y repetidos. Se añaden a mano después.
- **Un arma en la mano es un "estado" del personaje** (`create_character_state`, unas 10 generaciones): una copia
  con las 8 rotaciones cambiadas. Las animaciones se hacen sobre cada estado por separado, así que cada arma
  necesita su estado y sus propias animaciones de andar y de atacar (unas 30–45 generaciones por arma).
- **Vía antigua (sigue valiendo):** `tools/pixellab.mjs` llama a la API directamente
  (`balance`, `character`, `animate`, `animate-text`, `export`, `image`; uso en la cabecera del archivo).
  Necesita la clave en la variable de entorno **`PIXELLAB_API_KEY`**. **Nunca** pegarla en el chat, en el código ni
  en un commit. En Windows (PowerShell): `$env:PIXELLAB_API_KEY = "..."` para la sesión actual, o
  `setx PIXELLAB_API_KEY "..."` para siempre (hay que abrir una terminal nueva después).
  `export` descomprime con `python3`; en Windows puede que haya que cambiarlo a `python` o `py`.

