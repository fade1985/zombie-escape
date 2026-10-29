# La versión de Windows

El juego también se exporta como programa de Windows (64 bits): un solo `ZombieEscape.exe` (unos 150 MB) con todo
dentro (`binary_format/embed_pck`), sin instalador. Es el que irá a Steam. Es una **foto del juego en el momento de
exportar**: no se actualiza sola. Se sigue trabajando en el juego de siempre (en el editor y en `main`) y, cuando haga
falta una versión nueva, se vuelve a exportar con el mismo comando: no hay que rehacer nada.

## Exportar

El preset **«Windows Desktop»** está en `export_presets.cfg` (junto al de «Web»). Las plantillas de Windows ya vienen con
las de Godot (`%APPDATA%\Godot\export_templates\4.7.2.stable`). Tarda un par de minutos:

```
"<Godot>_console.exe" --headless --path . --export-release "Windows Desktop" exportar/windows/ZombieEscape.exe
```

- Sale a `exportar/windows/`: la carpeta `exportar/` no va en git (solo su `.gdignore`, para que el editor no importe lo
  exportado) y el preset deja fuera `tools/`, `docs/`, `web/`, `exportar/` y las capturas.
- Si se han añadido dibujos nuevos, antes `--headless --path . --import`.
- El robot de GitHub (`.github/workflows/web.yml`) solo publica la web: la de Windows se exporta a mano.

## Probar el `.exe`

- Las pruebas corren dentro del exportado igual que en el editor, pasando el `--` de siempre; con `--log-file` se ve lo
  que imprimen (el `.exe` no tiene consola):
  `ZombieEscape.exe --log-file salida.log -- --captura --guiado`. Las fotos no se guardan (en el exportado `res://` no
  se puede escribir, saldrá «Can't save PNG»: es normal); lo que cuenta es lo que imprimen.
- El guardado va en `%APPDATA%\Godot\app_userdata\Zombie Escape\guardado.json`, el mismo que usa el editor: probar el
  `.exe` toca la partida de verdad (copiarlo antes si importa).
- `SendKeys` y parecidos no llegan a la ventana desde una sesión de Claude (no tiene el foco): las teclas se prueban con
  `-- --captura --pantalla`.

## Qué cambia en el ordenador

- **Pantalla completa:** **F11** o **Alt+Intro**, desde cualquier sitio, y el botón de Opciones y del menú. Se guarda
  (`pantalla_completa` en `ajustes`) y el juego arranca igual la próxima vez (`pantalla.gd`, un autoload;
  `Tactil.pantalla_completa()` cambia y guarda). En la web no se guarda: allí F11 es del navegador. La ventana sale
  maximizada; el dibujo se agranda por números enteros.
- **La sala de pruebas** (antes F11) pasó a **F9**, y solo va al jugar desde el editor o en las pruebas `--captura`
  (`partida.gd`, `OS.is_debug_build() or captura`): el juego exportado no la tiene.

## Lo que falta

- **El icono y los datos del `.exe`** (nombre de la empresa, copyright, versión): hace falta `rcedit` (Godot → Editor
  Settings → Export → Windows) y un `.ico`; hoy `application/modify_resources=false`.
- **Probar el mando** desde el primer menú con un mando físico, y el juego en 1280×800 (Steam Deck).
- **Linux** (solo para el sello de Steam Deck, que ya ejecuta el `.exe` con Proton), **firmar el ejecutable** (evita el
  aviso de Windows si se reparte fuera de Steam) y **Steam** en sí (cuenta, `steamworks`, logros): ver `LANZAMIENTO.md`.
