# Zombie Escape (Godot) · notas para continuar

Claude Code lee este archivo en cada sesión: aquí va **solo lo que hace falta siempre**. El detalle de cada
tema está en `docs/` y se lee cuando toca.

## Qué es

Roguelike de zombis, entre *The Binding of Isaac* y *Hotline Miami*: un conserje (Johnny) limpia un edificio
infestado, apartamento a apartamento. Solo pixel art. Se está **pasando a Godot 4.7.2** (GDScript, renderizador
"Compatibilidad", el que vale para web) desde el juego de navegador, fase a fase (tabla de abajo).

## Cómo trabajamos

- El dueño está **aprendiendo a hacer juegos**. Explicaciones en **español**, claras y sin tecnicismos
  innecesarios. Comentarios del código y mensajes de commit, también en español.
- Se avanza **por fases**: al terminar cada una, resumen + captura, commit, push y **esperar su visto bueno**.
- Antes de cambios grandes, **contar el plan y preguntar**. Si dice "no hagas nada, solo dime", solo se responde.
- Se trabaja directamente en `main`. No crear pull requests si no los pide.
- Si hay varias sesiones a la vez, al hacer commit añadir solo los archivos propios (nada de `git add -A`).
- **Borrar en PixelLab no se puede deshacer:** solo con confirmación expresa del dueño.
- **Ahorrar cuota** (cada paso vuelve a leer toda la conversación: lo caro es lo largo y lo que se queda dentro):
  - **Sesiones cortas:** una por fase o tarea; si una pasa de ~80 pasos, proponer seguir en otra con un resumen.
  - **Modelo:** Sonnet para seguir una receta ya rodada o ajustes pequeños; Opus solo para lo nuevo o difícil.
  - **Capturas pequeñas:** reducir con `py` (Pillow) antes de abrirlas con Read; pocas y sin repetir.
  - **Salidas cortas:** filtrar lo que imprime Godot (`grep`), leer archivos por trozos. Los `.tscn` y `.tres`
    grandes (hojas de animación, TileSets) no se leen enteros.
  - **PixelLab:** lanzar las generaciones de golpe y comprobar una sola vez.

## Abrir y probar

- **En el editor:** abrir Godot (`C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`), en el gestor de
  proyectos **Importar** → `project.godot` de esta carpeta, y **F5** para jugar. Johnny anda con **WASD**, las
  **flechas** o el **stick izquierdo** del mando, y esquiva con **Espacio**, **Mayús** o el botón **A**. **F1** cambia el modo de atacar: *asistido* (apunta y ataca
  solo, como en el JS), *hacia donde mira* (J, clic o botón X) y *libre* (ratón + clic, o stick derecho). **Q** /
  rueda / botón Y cambia entre sus dos armas; **E**, clic derecho o RT (mantener para apuntar, soltar para
  lanzar) tira el molotov o la granada, y **F** / LB cambia entre ellos; **1-6** pone cualquiera (solo para probar) y **R** / RB recarga.
  **Tab**, **I** o Select abren el inventario (las armas, las guardadas y la mochila; ponérselas y tirar al suelo).
  Para probar zombis: **F2 a F7** sacan uno de cada tipo (normal, lento, rápido, explosivo, tentáculos y
  venenoso) y **P**, la portera; **M** saca el recuadro de las mutaciones y **O** suelta un objeto al azar. **F9** lleva a la sala de exposición (todos los muebles con sus variantes y
  todos los zombis con sus ropas) y vuelve. **F10** quita y pone la penumbra, para comparar. **H** lleva al
  apartamento del superviviente ya sin zombis (para probar el rescate y la horda sin buscarlo).
  El juego arranca en el menú principal (`escenas/menu_principal.tscn`); JUGAR lleva a la partida
  (`escenas/partida.tscn`), que empieza en la sala de mantenimiento de la planta baja. Arrimándose a la mesa del
  ordenador sale **ConserjeOS** (puntos de talento, árbol de talentos, tienda de armas, **logros**: los retos, que se cobran ahí, el **Dosier VD-7**: las páginas de la historia encontradas, y **Noticias**: las emisiones de Canal 8); a su derecha, el
  **baúl** (de ahí se sacan las armas creadas para la partida), y a su izquierda, el **banco de trabajo** (crear armas con las recetas). Los baños tienen un armarito
  con un botiquín. Los supervivientes rescatados en otras partidas esperan a la derecha del ordenador: arrimarse a
  uno para que te acompañe. **Esc** / Start: pausa.
  Los menús van con ratón, con flechas + Intro o con el mando (cruceta o stick, A pulsar, B volver). El guardado
  está en `%APPDATA%\Godot\app_userdata\Zombie Escape\guardado.json` (borrarlo = empezar de cero); la prueba
  con `--captura` usa `guardado-prueba.json`. El baño de las fases 1-3 sigue
  como sala de pruebas: abrir `escenas/salas/bano.tscn` y **F6** (jugar la escena abierta).
  **En el móvil** (pantallas táctiles: `scripts/ui/tactil.gd`, solo mientras se juega): joystick izquierdo
  (se toca en la mitad izquierda), y abajo a la derecha, según el modo, nada (asistido), botón de atacar (hacia
  donde mira) o joystick derecho (libre); en arco, esquivar, las dos armas (tocar la otra la saca, tocar la de
  fuego en la mano recarga) y lanzar (arrastrar desde él y soltar), con el botoncito de cambiar lanzable; bajo
  el minimapa, modo, inventario y pausa. En los menús el dedo hace de ratón. En táctil la pantalla se agranda
  sin redondear (si no, en móviles con muchos píxeles se quedaría en 1×). Para probarlo en el navegador
  integrado: tamaño de menos de 768 de ancho (p. ej. 740×360) y toques con `TouchEvent` desde JavaScript (los
  clics llegan como ratón).
- **Desde la terminal** (comprobar que arranca y sacar una foto `captura.png` sin jugar; se cierra solo):

  ```
  "C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . -- --captura
  ```

  La foto sale al tamaño de la ventana (grande): reducirla antes de mirarla. Si se han añadido sprites nuevos,
  importarlos antes con `... _console.exe --headless --path . --import`.
- **Sonido:** con `--captura` arranca sin sonido (como el `?pruebas` del JS); en la pausa se quita y se pone. Para
  escuchar los efectos sin jugar: `... _console.exe --headless --path . --script tools/probar_sonido.gd` los
  guarda en `tools/efectos/*.wav` (no se suben a git).
- **En el navegador (web):** las plantillas de exportación de web están en
  `%APPDATA%\Godot\export_templates\4.7.2.stable` (solo las de web). Exportar (sale en `web/`, que lleva un `.gdignore`
  para que el editor no importe lo exportado). **`web/` sí va en git: Vercel publica lo que haya en ella** (en https://zombie-escape-two.vercel.app; la
  cuenta de Vercel no es la del dueño: la lleva otra persona), así que
  para publicar un cambio: exportar, commit de `web/` y push:

  ```
  "C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Web" web/index.html
  ```

  Para probarla: en Claude, el servidor `web` de `.claude/launch.json` (`py -m http.server 8060 --directory web`) y
  abrir `http://localhost:8060`. Ajustes en `export_presets.cfg` (sin hilos) y, para Vercel, `vercel.json` (sirve `web/`).
  En la web el guardado va en el navegador (IndexedDB), no en `%APPDATA%`.
- Los errores de Godot salen en la terminal con `ERROR` o `SCRIPT ERROR`: filtrar por ahí.
- Python se llama con `py` (tiene Pillow); poner `PYTHONIOENCODING=utf-8` delante si escribe tildes.

**Medidas** (como en el juego JS): el mundo usa 2 unidades por píxel del dibujo (por eso los sprites y las
cuadrículas tienen escala 2), casillas de 16 píxeles (32 unidades), personajes de 48 píxeles. La pantalla base es
**960×640** y se agranda solo por **números enteros** (como `Camera.pixelPantalla` del JS), con filtro *nearest*
para que el pixel art se vea nítido.

## Mapa de carpetas

| Carpeta | Qué hay |
|---|---|
| `project.godot` | Ajustes: escena de inicio, pantalla, pixel art nítido, teclas de cada acción, capas de choque |
| `escenas/menu_principal.tscn` | La escena de inicio: el menú principal (`scripts/ui/menu_principal.gd`) |
| `escenas/partida.tscn` | La partida: Johnny y la pantalla (sitio, avisos, fundido). El mapa lo monta `partida.gd`; el HUD, `ui/hud.gd`; el minimapa, `minimapa.gd`; la pausa y el final, `ui/menus.gd` |
| `escenas/salas/` | La sala de pruebas de las fases 1-3: `bano.tscn` y `bano_tileset.tres` (las piezas con las que se pinta y cuáles chocan) |
| `escenas/personajes/` | `johnny.tscn`, un `zombi_<tipo>.tscn` por tipo (sus números van en el Inspector) y `portera.tscn` |
| `escenas/armas/` | `bala.tscn` (la bala y los perdigones), `bala_zombi.tscn` (agua sucia de la portera), `proyectil.tscn` (moco y botella de lejía, en parábola), `charco.tscn` y `explosion.tscn` |
| `escenas/luces/` | `lampara.tscn` (aplique, lámpara o mesilla: luz de suelo con sombras, luz de lo demás sin sombras y bombilla), `fuego.tscn` (luz de fuego, lista para la fase 7) y `luz_suave.tres` (el degradado de todas) |
| `escenas/muebles/` | Un mueble por escena (bañera, váter, lavabo, lavadora), con su choque y su `Sombra` para la fase de luz |
| `scripts/` | El código: `johnny.gd` (moverse, vida, apuntar y atacar), `armas.gd` (los números de las armas), `bala.gd`, `zombi.gd` (la base de todos los zombis: perseguir con navegación, zarpazos, golpes; el normal, el lento y el rápido solo cambian números), `zombi_explosivo.gd`, `zombi_tentaculos.gd` y `zombi_venenoso.gd` (heredan de la base y añaden su ataque), `portera.gd` (la jefa, por estados), `partida.gd` (la planta en juego: cambiar de sitio por las puertas, puerta que se cierra hasta limpiar el piso, llave, portera, escaleras, dinero, pausa, fin de partida, teclas de prueba y `--captura`), `talentos.gd` (el árbol de talentos y la compra de puntos), `objetos.gd` (los 17 objetos, la mochila, el baúl y lo que sueltan los zombis), `recetas.gd` (las 15 recetas y las rarezas), `armas_creadas.gd` (lo que hacen las armas creadas: aturdir, prender, sangrar, descarga…; sus números en `Armas.CREADAS`), `chorro.gd` (gotas de fuego y ácido) y `bumeran.gd`, `lanzables.gd` (molotov, granada y arrojadizas creadas: munición, apuntar, lanzar), `granada.gd` (también la atraedora, la congeladora y la lluvia ácida), `charco.gd` (veneno, lejía, vómito y fuego), `estados.gd` (lo que hacen los charcos), `mutaciones.gd`, `llamas.gd`, `particulas.gd`, `mancha.gd`, `minimapa.gd`, `guardado.gd` (el guardado entre partidas), `logros.gd` (los logros: su lista y los avisos que da la partida al cumplirlos), `historia.gd` (la historia: el texto de las páginas del dosier de cada edificio, la hoja de papel y las noticias de Canal 8 con cuándo sale cada una; para cambiar la historia se edita aquí, sin tocar los `id`), `mejoras.gd` (los atributos de Johnny: el baseStats del JS), `billete.gd`, `sonido.gd` (los efectos de sonido, sintetizados como en `src/sfx.js`, y la música; es un autoload: `Sonido.tocar("compra")`, `Sonido.musica("jefe")`; buses en `default_bus_layout.tres`), `supervivientes.gd` (el superviviente de la partida: encerrado en su baño, la horda, los vecinos de mantenimiento) y `aliado.gd` (cada superviviente: sigue a Johnny, dispara o cura, fuerza la cerradura), `ui/` (`tema.gd` el aspecto de menús y HUD, `hud.gd`, `menus.gd`, `menu_principal.gd`, `tactil.gd` los controles del móvil, `ordenador.gd` la pantalla de ConserjeOS, `inventario.gd` las pantallas del inventario, el baúl y el banco, `tele.gd` la tele de las noticias, dibujada con código), `mapa/` (`apartamento.gd` genera un apartamento como el `apartment.js` del JS, `planta.gd` la planta, sus zombis, la sala de mantenimiento y la de exposición, `catalogo.gd` los muebles de cada sala, `muebles.gd` dónde va cada uno, `mueble.gd` monta uno, `ordenador.gd` la mesa del ordenador, `arrimable.gd` el baúl y el banco, `armarito.gd` el botiquín de los baños, `cientifico.gd` el científico muerto con su página, `mapa.gd` monta un sitio: suelos, tapas, caras de pared, choques, muebles, niebla, navegación; `cara_pared.gd`, `puerta.gd` y `puerta_bano.gd`, la del baño del superviviente), `luz/` (`luz.gd` la penumbra de cada sitio, la luz de Johnny y los fogonazos; `lampara.gd`, `fuego.gd`), `sala.gd` (la sala de pruebas: hornea la navegación, la pantalla, tandas mezcladas, teclas de prueba F2-F7 y P, y la prueba con `--captura`) |
| `assets/sprites/` | Copia de los sprites del juego JS (`.png` + `.json` + `manifest.json`). Los `.tres` de al lado son sus animaciones para Godot |
| `assets/musica/` | Tramos de la música de fondo (`menu-*`, `explorar-*`, `jefe-*`.ogg), grabados del JS con `node tools/grabar_musica.mjs` (necesita el JS y ffmpeg). Si se graban más, cambiar `TRAMOS` en `sonido.gd` |
| `assets/ui/`, `assets/fuentes/` | HUD y menús, copiados del JS: barra de vida, panel, botón, iconos, la fuente pixel art (nítida a 16 y 32) y el logo |
| `assets/tiles/` | Texturas preparadas para los TileSets (`py tools/texturas_bano.py`) |
| `assets/sources/` | Originales (muebles, texturas…). Lleva `.gdignore`: Godot no los importa |
| `assets/pixellab.json` | Todo lo generado en PixelLab |
| `docs/` | Pixel art, PixelLab, zombis, fondos y mapa. **Hablan del juego JS** (`src/…`): valen para las ideas y los números |
| `tools/` | `hacer_frames.py` (hoja → animaciones de Godot), `texturas_bano.py`, `importar.py` (muebles nuevos → sprites; lee `scripts/mapa/catalogo.gd`) y `despixelar.py` (de PixelLab y Gemini) y `dibujos_7b.py` (baúl, banco y armarito, dibujados a mano en el JS), `objetos16.py` (los 17 objetos a 16×16), `icono_dosier.py` y `icono_noticias.py` (los iconos del dosier y de la tele) y `ver_dibujos.tscn` (foto de los dibujos hechos con código) |

Para pasar una hoja nueva a Godot: `py tools/hacer_frames.py assets/sprites/zombi-normal` (saca el `.tres` al lado).

## Referencias

- **Juego JS viejo:** `C:\Users\angel\Projects\game` (su `CLAUDE.md` explica el código). Retirado de Vercel en la
  fase 8d; el código sigue en GitHub (`fade1985/game`). Se mira para copiar números y comportamientos, no se cambia.
- **Prueba en Godot:** `D:\Personal\Proyectos\zombie-godot-poc` (su `README.md`). Ya resuelto allí: zombi que
  persigue con NavigationAgent2D y fregonazos (fase 3), lámparas, penumbra y sombras (fase 4). Copiar de ahí
  al llegar a esas fases.

## Fases de la migración

| Fase | Qué | Estado |
|---|---|---|
| 1 | Base: proyecto, recursos copiados, Johnny andando por el baño | hecha, con visto bueno (19 oct) |
| 2 | Combate: armas, balas, zombi normal, 3 modos de atacar | hecha, con visto bueno (19 oct) |
| 3 | Los 6 zombis y la portera | hecha, con visto bueno (19 oct) |
| 4a | Mapa: planta al azar con pasillo y apartamentos, salas, puertas, zombis dormidos por sala, llave, portera y escaleras (5 plantas) | hecha, con visto bueno (20 oct) |
| 4b | Catálogo de muebles e `importar.py`, niebla (habitaciones a oscuras), minimapa, sala de mantenimiento y sala de exposición (F9) | hecha, con visto bueno (20 oct) |
| 5 | Luz y penumbra: oscuridad por sitio, apliques que parpadean, lámparas y mesillas, sombras de muebles y muros, fogonazos y explosiones | hecha, con visto bueno (20 oct) |
| 6a | Menús (principal, pausa, derrota, victoria) con mando, HUD, guardado, atributos de Johnny y billetes | hecha, con visto bueno (20 oct) |
| 6b | Ordenador ConserjeOS: compra de puntos, árbol de talentos (Militar y Superviviente), tienda de armas y esquiva | hecha, con visto bueno (20 oct) |
| 7a | Molotov y granada (apuntar y lanzar), fuego y zombis ardiendo, charcos con estados, mutaciones | hecha, con visto bueno (20 oct) |
| 7b1 | Objetos que sueltan los zombis, mochila e inventario, baúl, banco de trabajo con recetas y rarezas, botiquines y Sanitario | hecha, con visto bueno (20 oct) |
| 7b2 | Armas creadas: sacarlas del baúl y usarlas (cuerpo a cuerpo, a distancia y arrojadizas en `Lanzables.tipos()`) | hecha, con visto bueno (20 oct) |
| 7c | Superviviente: encerrado en un baño, la horda mientras fuerza la cerradura, rescatados y acompañante | hecha, con visto bueno (20 oct) |
| 8a | Sonido: los efectos del JS sintetizados (`sonido.gd`, sin archivos), buses de audio, quitar sonido en la pausa | hecha, con visto bueno (20 oct) |
| 8b | Música: tramos grabados de la del JS (`tools/grabar_musica.mjs`) que se encadenan al azar con fundidos; jingles de ganar y perder | hecha, con visto bueno (20 oct) |
| 8c | Exportar a web (sin hilos: vale en Vercel sin cabeceras especiales), probada en el navegador; `vercel.json` preparado | hecha, con visto bueno (20 oct) |
| 8e | Controles táctiles para el móvil (los tres modos, lanzar arrastrando, pantalla completa en la pausa), probados en el navegador con tamaño de móvil | hecha, con visto bueno (20 oct) |
| 8d | Publicar y retirar la versión JS: se juega en https://zombie-escape-two.vercel.app | hecha, con visto bueno (20 oct) |

## Lo nuevo (después de la migración)

| Qué | Estado |
|---|---|
| Logros: programa LOGROS.EXE en ConserjeOS, 10 retos con premio en dólares (`scripts/logros.gd`; añadir más = una línea en `LISTA`) | hecho, con visto bueno y publicado (20 oct) |
| Historia A: el "Proyecto VD-7" (`historia.gd`). Un científico de Velaria muerto por planta con una página del dosier (solo si falta por encontrar), la página al cogerla y el programa Dosier en ConserjeOS | hecho, con visto bueno y publicado (20 oct) |
| Historia B: el programa Noticias (`ui/tele.gd`: tele dibujada con código, Marta Ruiz de Canal 8 contando la versión de Velaria letra a letra). 5 emisiones en `Historia.NOTICIAS`: al empezar, al encontrar páginas 1, 3 y 4, y al completar el edificio; las vistas en el guardado (`noticias_vistas`) y aviso en la partida si hay nuevas | hecho, falta el visto bueno (20 oct) |
