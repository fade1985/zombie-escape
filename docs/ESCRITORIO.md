# La versión de Windows

El juego también se exporta como programa de Windows (64 bits): un solo `JohnnyRush.exe` (unos 150 MB) con todo
dentro (`binary_format/embed_pck`), sin instalador. Es el que irá a Steam. Es una **foto del juego en el momento de
exportar**: no se actualiza sola. Se sigue trabajando en el juego de siempre (en el editor y en `main`) y, cuando haga
falta una versión nueva, se vuelve a exportar con el mismo comando: no hay que rehacer nada.

## Exportar

El preset **«Windows Desktop»** está en `export_presets.cfg` (junto al de «Web»). Las plantillas de Windows ya vienen con
las de Godot (`%APPDATA%\Godot\export_templates\4.7.2.stable`). Tarda un par de minutos:

```
"<Godot>_console.exe" --headless --path . --export-release "Windows Desktop" exportar/windows/JohnnyRush.exe
```

- Sale a `exportar/windows/`: la carpeta `exportar/` no va en git (solo su `.gdignore`, para que el editor no importe lo
  exportado) y el preset deja fuera `tools/`, `docs/`, `web/`, `exportar/` y las capturas.
- Si se han añadido dibujos nuevos, antes `--headless --path . --import`.
- El robot de GitHub (`.github/workflows/web.yml`) solo publica la web: la de Windows se exporta a mano.

## El icono y los datos del `.exe`

El `.exe` lleva el icono de Johnny (`assets/icono.ico`, hecho de `assets/icono.png`, que también es el icono del
proyecto: ventana, barra de tareas y pestaña de la web) y su nombre, descripción y versión (`application/*` del preset).
Para meterlos Godot usa **`rcedit`** (`rcedit-x64.exe`, versión 2.0.0 de https://github.com/electron/rcedit/releases,
unos 1,3 MB). Es una configuración **de cada equipo**, no va en git: bajarlo a una carpeta (aquí,
`C:\Users\angel\Tools\rcedit\`) y apuntar su ruta en Godot → Editor → Editor Settings → Export → Windows → Rcedit (o en
`%APPDATA%\Godot\editor_settings-4.7.tres`, la línea `export/windows/rcedit = "C:/.../rcedit-x64.exe"`, con el editor
cerrado). Sin él, el preset (`application/modify_resources=true`) falla al exportar: si falla, es esto. Para cambiar el
icono: nuevo PNG cuadrado → `.ico` con los tamaños 16–256 (Pillow: `Image.save("icono.ico", sizes=[...])`) y exportar
otra vez. Quedan vacíos la empresa y el copyright (`company_name`, `copyright`): rellenarlos si se quiere. Se comprueba
con `(Get-Item JohnnyRush.exe).VersionInfo` y extrayendo el icono con `ExtractAssociatedIcon`.

## Probar el `.exe`

- Las pruebas corren dentro del exportado igual que en el editor, pasando el `--` de siempre; con `--log-file` se ve lo
  que imprimen (el `.exe` no tiene consola):
  `JohnnyRush.exe --log-file salida.log -- --captura --guiado`. Las fotos no se guardan (en el exportado `res://` no
  se puede escribir, saldrá «Can't save PNG»: es normal); lo que cuenta es lo que imprimen.
- El guardado va en `%APPDATA%\Johnny Rush\guardado.json`, el mismo que usa el editor: probar el
  `.exe` toca la partida de verdad (copiarlo antes si importa).
- `SendKeys` y parecidos no llegan a la ventana desde una sesión de Claude (no tiene el foco): las teclas se prueban con
  `-- --captura --pantalla`.

## Qué cambia en el ordenador

- **Pantalla completa:** **F11** o **Alt+Intro**, desde cualquier sitio, y el botón de Opciones y del menú. Se guarda
  (`pantalla_completa` en `ajustes`) y el juego arranca igual la próxima vez (`pantalla.gd`, un autoload;
  `Tactil.pantalla_completa()` cambia y guarda). En la web no se guarda: allí F11 es del navegador. La ventana sale
  maximizada.
- **Sin bordes negros:** la imagen llena la ventana (también en la web; lo hace `pantalla.gd`). En Full HD, 2K y 4K cada píxel
  del dibujo mide 3, 4 y 6 de pantalla justos y se ve 1280×720. En tamaños que no encajan (una ventana de navegador de
  900 de alto) se agranda lo justo para ver 960×640: llena igual, pero algún píxel sale un poco más ancho que otro.
- **La sala de pruebas** (antes F11) pasó a **F9**, y solo va al jugar desde el editor o en las pruebas `--captura`
  (`partida.gd`, `OS.is_debug_build() or captura`): el juego exportado no la tiene.

## Lo que falta

- **La empresa y el copyright** de las propiedades del `.exe` (vacíos hoy).
- **Probar el mando** desde el primer menú con un mando físico, y el juego en 1280×800 (Steam Deck).
- **Linux** (solo para el sello de Steam Deck, que ya ejecuta el `.exe` con Proton), **firmar el ejecutable** (evita el
  aviso de Windows si se reparte fuera de Steam) y **Steam** en sí (cuenta, `steamworks`, logros): ver `LANZAMIENTO.md`.
