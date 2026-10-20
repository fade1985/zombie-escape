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

- **En el editor:** abrir Godot (`C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe`), en el gestor de
  proyectos **Importar** → `project.godot` de esta carpeta, y **F5** para jugar. Johnny anda con **WASD**, las
  **flechas** o el **stick izquierdo** del mando, y esquiva con **Espacio**, **Mayús** o el botón **A**. **F1** cambia el modo de atacar: *asistido* (apunta y ataca
  solo, como en el JS), *hacia donde mira* (J, clic o botón X) y *libre* (ratón + clic, o stick derecho). **Q** /
  rueda / botón Y cambia entre sus dos armas; **E**, clic derecho o RT (mantener para apuntar, soltar para
  lanzar) tira el molotov o la granada, y **F** / LB cambia entre ellos; **1-6** pone cualquiera (solo para probar) y **R** / RB recarga.
  Para probar zombis: **F2 a F7** sacan uno de cada tipo (normal, lento, rápido, explosivo, tentáculos y
  venenoso) y **P**, la portera; **M** saca el recuadro de las mutaciones. **F9** lleva a la sala de exposición (todos los muebles con sus variantes y
  todos los zombis con sus ropas) y vuelve. **F10** quita y pone la penumbra, para comparar.
  El juego arranca en el menú principal (`escenas/menu_principal.tscn`); JUGAR lleva a la partida
  (`escenas/partida.tscn`), que empieza en la sala de mantenimiento de la planta baja. Arrimándose a la mesa del
  ordenador sale **ConserjeOS** (puntos de talento, árbol de talentos y tienda de armas). **Esc** / Start: pausa.
  Los menús van con ratón, con flechas + Intro o con el mando (cruceta o stick, A pulsar, B volver). El guardado
  está en `%APPDATA%\Godot\app_userdata\Zombie Escape\guardado.json` (borrarlo = empezar de cero); la prueba
  con `--captura` usa `guardado-prueba.json`. El baño de las fases 1-3 sigue
  como sala de pruebas: abrir `escenas/salas/bano.tscn` y **F6** (jugar la escena abierta).
  En el móvil los tres modos irán con controles táctiles (joystick izquierdo, joystick derecho y botón de
  ataque), en la fase 8.
- **Desde la terminal** (comprobar que arranca y sacar una foto `captura.png` sin jugar; se cierra solo):

  ```
  "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -- --captura
  ```

  La foto sale al tamaño de la ventana (grande): reducirla antes de mirarla. Si se han añadido sprites nuevos,
  importarlos antes con `... _console.exe --headless --path . --import`.
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
| `scripts/` | El código: `johnny.gd` (moverse, vida, apuntar y atacar), `armas.gd` (los números de las armas), `bala.gd`, `zombi.gd` (la base de todos los zombis: perseguir con navegación, zarpazos, golpes; el normal, el lento y el rápido solo cambian números), `zombi_explosivo.gd`, `zombi_tentaculos.gd` y `zombi_venenoso.gd` (heredan de la base y añaden su ataque), `portera.gd` (la jefa, por estados), `partida.gd` (la planta en juego: cambiar de sitio por las puertas, puerta que se cierra hasta limpiar el piso, llave, portera, escaleras, dinero, pausa, fin de partida, teclas de prueba y `--captura`), `talentos.gd` (el árbol de talentos y la compra de puntos), `lanzables.gd` (molotov y granada: munición, apuntar, lanzar), `granada.gd`, `charco.gd` (veneno, lejía, vómito y fuego), `estados.gd` (lo que hacen los charcos), `mutaciones.gd`, `llamas.gd`, `particulas.gd`, `mancha.gd`, `minimapa.gd`, `guardado.gd` (el guardado entre partidas), `mejoras.gd` (los atributos de Johnny: el baseStats del JS), `billete.gd`, `ui/` (`tema.gd` el aspecto de menús y HUD, `hud.gd`, `menus.gd`, `menu_principal.gd`, `ordenador.gd` la pantalla de ConserjeOS), `mapa/` (`apartamento.gd` genera un apartamento como el `apartment.js` del JS, `planta.gd` la planta, sus zombis, la sala de mantenimiento y la de exposición, `catalogo.gd` los muebles de cada sala, `muebles.gd` dónde va cada uno, `mueble.gd` monta uno, `ordenador.gd` la mesa del ordenador, `mapa.gd` monta un sitio: suelos, tapas, caras de pared, choques, muebles, niebla, navegación; `cara_pared.gd` y `puerta.gd`), `luz/` (`luz.gd` la penumbra de cada sitio, la luz de Johnny y los fogonazos; `lampara.gd`, `fuego.gd`), `sala.gd` (la sala de pruebas: hornea la navegación, la pantalla, tandas mezcladas, teclas de prueba F2-F7 y P, y la prueba con `--captura`) |
| `assets/sprites/` | Copia de los sprites del juego JS (`.png` + `.json` + `manifest.json`). Los `.tres` de al lado son sus animaciones para Godot |
| `assets/ui/`, `assets/fuentes/` | HUD y menús, copiados del JS: barra de vida, panel, botón, iconos, la fuente pixel art (nítida a 16 y 32) y el logo |
| `assets/tiles/` | Texturas preparadas para los TileSets (`py tools/texturas_bano.py`) |
| `assets/sources/` | Originales (muebles, texturas…). Lleva `.gdignore`: Godot no los importa |
| `assets/pixellab.json` | Todo lo generado en PixelLab |
| `docs/` | Pixel art, PixelLab, zombis, fondos y mapa. **Hablan del juego JS** (`src/…`): valen para las ideas y los números |
| `tools/` | `hacer_frames.py` (hoja → animaciones de Godot), `texturas_bano.py`, `importar.py` (muebles nuevos → sprites; lee `scripts/mapa/catalogo.gd`) y `despixelar.py` (de PixelLab y Gemini) |

Para pasar una hoja nueva a Godot: `py tools/hacer_frames.py assets/sprites/zombi-normal` (saca el `.tres` al lado).

## Referencias

- **Juego JS viejo:** `D:\Personal\Proyectos\game` (su `CLAUDE.md` explica el código). Sigue publicado en Vercel
  sin tocar hasta que esta versión lo alcance. Se mira para copiar números y comportamientos, no se cambia.
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
| 7a | Molotov y granada (apuntar y lanzar), fuego y zombis ardiendo, charcos con estados, mutaciones | hecha, pendiente de visto bueno |
| 7b | Objetos, mochila, baúl, banco de trabajo, recetas y armas creadas (arrojadizas en `Lanzables.tipos()`) | |
| 7c | Superviviente | |
| 8 | Música, sonido, exportar a web (Vercel) y retirar la versión JS | |
