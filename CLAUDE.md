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
  **flechas** o el **stick izquierdo** del mando.
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
| `escenas/salas/` | Las salas. `bano.tscn` (la de inicio) y `bano_tileset.tres`, las piezas con las que se pinta y cuáles chocan |
| `escenas/personajes/` | `johnny.tscn` (y luego zombis, portera…) |
| `escenas/muebles/` | Un mueble por escena (bañera, váter, lavabo, lavadora), con su choque y su `Sombra` para la fase de luz |
| `scripts/` | El código: `johnny.gd` (moverse y animarse), `sala.gd` (la prueba con `--captura`) |
| `assets/sprites/` | Copia de los sprites del juego JS (`.png` + `.json` + `manifest.json`). Los `.tres` de al lado son sus animaciones para Godot |
| `assets/tiles/` | Texturas preparadas para los TileSets (`py tools/texturas_bano.py`) |
| `assets/sources/` | Originales (muebles, texturas…). Lleva `.gdignore`: Godot no los importa |
| `assets/pixellab.json` | Todo lo generado en PixelLab |
| `docs/` | Pixel art, PixelLab, zombis, fondos y mapa. **Hablan del juego JS** (`src/…`): valen para las ideas y los números |
| `tools/` | `hacer_frames.py` (hoja → animaciones de Godot), `texturas_bano.py`, `importar.py` y `despixelar.py` (de PixelLab y Gemini). `importar.py` aún lee el catálogo de muebles del juego JS (`src/catalogo.js`): hay que adaptarlo cuando el catálogo pase a Godot (fase 4) |

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
| 1 | Base: proyecto, recursos copiados, Johnny andando por el baño | hecha, pendiente de visto bueno |
| 2 | Combate: armas, balas, zombi normal | |
| 3 | Los 6 zombis y la portera | |
| 4 | Mapa: planta, apartamentos, puertas, muebles del catálogo, niebla | |
| 5 | Luz y penumbra | |
| 6 | Menús, HUD, guardado, mejoras y talentos | |
| 7 | Molotov, granada, objetos, banco de trabajo, mutaciones y superviviente | |
| 8 | Música, sonido, exportar a web (Vercel) y retirar la versión JS | |
