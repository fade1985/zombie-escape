# Zombie Escape (Godot) · notas para continuar

Aquí va **solo lo que hace falta siempre**. El detalle está en `docs/` y se lee cuando toca:

| Archivo | Cuándo leerlo |
|---|---|
| `docs/CODIGO.md` | Qué hace cada escena, script, asset y herramienta |
| `docs/CONTROLES.md` | Teclas, mando, móvil, la sala de pruebas (F11 y su panel), sala de mantenimiento, guardado |
| `docs/WEB.md` | Exportar a web y publicar en Vercel (se publica al subir main a la rama `production`) |
| `docs/historial/` | Planes ya terminados (centro comercial, jefes de los Apartamentos): solo para saber por qué se decidió algo |
| `docs/LANZAMIENTO.md` | Lo que le falta al juego para venderlo (versión de Windows, inglés, nombre, pruebas, Steam, legal): se lee cuando el juego esté pulido y toque pensar en sacarlo |
| `docs/TRAILER.md` | El trailer: cómo se graba (`py tools/trailer.py`) y su guion de escenas y textos |
| `PENDIENTES.md` (raíz) | Lista del dueño de fallos, mejoras y cosas por limar: solo se toca un punto cuando él lo pide |
| `docs/PIXEL_ART.md`, `PIXELLAB.md`, `ZOMBIS.md`, `FONDOS.md`, `MAPA.md` | Del juego JS: ideas y números |

## Qué es

Roguelike de zombis pixel art, entre *The Binding of Isaac* y *Hotline Miami*: el conserje Johnny limpia un
edificio infestado, apartamento a apartamento. **Godot 4.7.2** (GDScript, renderizador "Compatibilidad", el que
vale para web). La migración desde el juego JS está terminada (20 oct); lo hecho después está en git.

## Cómo trabajamos

- El dueño está **aprendiendo a hacer juegos**: explicaciones en **español**, claras y sin tecnicismos
  innecesarios. Comentarios del código y commits, también en español.
- Por tareas: al terminar, resumen + captura, commit, push y **esperar su visto bueno**.
- Antes de cambios grandes, **contar el plan y preguntar**. Si dice "no hagas nada, solo dime", solo se responde.
- Directamente en `main`, sin pull requests salvo que los pida. El juego lo hacen **dos personas**, el dueño y un
  amigo, cada uno en su equipo y los dos en `main`: `git pull` antes de empezar y otra vez antes de subir, por si el
  otro ha subido algo.
- **`PENDIENTES.md`** (en la raíz) es la lista del dueño de fallos, mejoras y cosas por limar: él dicta los
  puntos y Claude solo los apunta. **No se trabaja en ningún punto hasta que él lo pida**; al terminar uno con
  visto bueno, se borra de la lista en el mismo commit.
- Si hay varias sesiones a la vez, en el commit solo los archivos propios (nada de `git add -A`).
- **Borrar en PixelLab no se puede deshacer:** solo con confirmación expresa del dueño.
- **Ahorrar cuota:** sesiones cortas (si pasa de ~80 pasos, proponer seguir en otra con un resumen); **Sonnet**
  para lo que ya sabemos hacer y **Opus** para lo nuevo o difícil, también en subagentes y sesiones nuevas. Una
  sesión no puede cambiarse su propio modelo: **cada vez que llegue una tarea y el modelo de la sesión no sea el que
  toca, avisar al dueño antes de empezar** («esto es rutina, cambia a Sonnet» o al revés) y él lo cambia a mano en
  el menú de modelos. Nada de enjambres de agentes en tareas sencillas; capturas reducidas con `py` (Pillow) antes
  de abrirlas; filtrar lo que imprime Godot (`grep`); leer por trozos los `docs/` y los archivos grandes (`.gd`,
  `.tscn`, `.tres`): buscar el apartado o la función con `grep` y leer solo eso; en PixelLab, lanzar las
  generaciones de golpe y comprobar una vez.

## Probar

- **Godot** (una ruta en cada equipo, el del dueño y el de su amigo; si no existe ninguna, buscar
  `Godot_v4.7.2-stable_win64_console.exe`):
  `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` o
  `C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe`.
- **Arranca y saca fotos sin jugar** (se cierra solo, sin sonido, usa `guardado-prueba.json`):
  `"<Godot>_console.exe" --path . -- --captura`. Las fotos salen grandes: reducirlas antes de mirarlas.
  Sprites nuevos: importar antes con `--headless --path . --import`.
- **Probar solo lo que se ha tocado.** `-- --captura` a secas es la **prueba larga**: recorre medio juego (sala,
  exposición, un apartamento, todos los jefes, menús, ordenador…) y deja decenas de fotos. Para un cambio concreto,
  lanzar **solo su parte** (`-- --captura --jefe bombero --llamas`, `--evento X`, `--skins`, `--sala`…; la lista
  entera, al principio de `scripts/pruebas/partida_prueba.gd`, con el archivo `prueba_<tema>.gd` donde está cada una;
  `--jefe X` **solo elige el jefe**: sin otra opción detrás arranca la prueba larga). Si lo
  tocado no tiene parte, añadirle una pequeña en el archivo de su tema y apuntarla en esa lista. **La larga, solo si
  el dueño la pide.** Mirar solo las fotos de lo que se ha tocado.
- Errores: filtrar la salida por `ERROR` o `SCRIPT ERROR`.
- Python es `py` (con Pillow); `PYTHONIOENCODING=utf-8` delante si escribe tildes.

## Medidas

2 unidades por píxel del dibujo (sprites y cuadrículas con escala 2), casillas de 16 px (32 unidades), personajes
de 48 px. Pantalla base **960×640**, agrandada por **números enteros** con filtro *nearest*.

## Referencias

- **Juego JS viejo:** `C:\Users\angel\Projects\game` (GitHub `fade1985/game`; su `CLAUDE.md` explica el código).
  Se mira para copiar números y comportamientos, no se cambia.
- **Prueba en Godot:** `D:\Personal\Proyectos\zombie-godot-poc` (navegación, lámparas, penumbra y sombras).
- **Web publicada:** https://zombie-escape-two.vercel.app, se publica al subir `main` a la rama `production`; `web/` no va
  en git (ver `docs/WEB.md`).
