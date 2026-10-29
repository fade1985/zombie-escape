# Exportar a web y publicar

## Publicar: subir main a la rama production

- **Los commits a `main` ya no se publican.** Se publica lo que se sube a la rama **`production`**, en
  https://zombie-escape-two.vercel.app (la cuenta de Vercel es del dueño). Para publicar lo que hay en `main`:

  ```
  git push origin main:production
  ```

  Lo hace un robot de GitHub, `.github/workflows/web.yml`: descarga Godot, exporta el juego y lo sube a Vercel. Tarda
  unos minutos; se ve en la pestaña **Actions** del repositorio (y ahí está el botón **Run workflow** para publicar a
  mano). Si el push solo cambia notas (`docs/` o archivos `.md`), no publica.
- **Versión de prueba de una rama:** al subir cualquier otra rama (menos `main`), el mismo robot exporta el juego y lo
  sube a Vercel como versión de prueba, con su propio enlace, sin tocar la web de siempre. El enlace sale al final del
  robot en **Actions** (el resumen, «Publicado (preview, rama …)») y en Vercel → el proyecto → **Deployments**. Las
  versiones de prueba de Vercel piden entrar con la cuenta de Vercel (Settings → Deployment Protection). `main` no
  publica nada, para no gastar minutos de GitHub con cada commit.
- **`web/` no va en git** (solo su `.gdignore`): antes cada exportación guardaba otros 20 MB en el historial.
- El robot necesita tres **secretos** del repositorio (GitHub → Settings → Secrets and variables → Actions):
  - `VERCEL_TOKEN`: una llave de Vercel (Account Settings → Tokens).
  - `VERCEL_ORG_ID` y `VERCEL_PROJECT_ID`: los códigos del proyecto (Vercel → el proyecto → Settings → General).
- Vercel **no publica por su cuenta** desde git (`"git": { "deploymentEnabled": false }` en `vercel.json`): no tiene
  Godot y publicaría la carpeta `web/` vacía (pasó el 27 oct y la web dio 404). Lo publica siempre el robot.

## Exportar en el ordenador, para probar

- Plantillas de exportación (solo las de web): `%APPDATA%\Godot\export_templates\4.7.2.stable`.
- Se exporta a `web/` (lleva un `.gdignore` para que el editor no importe lo exportado):

  ```
  "<Godot>_console.exe" --headless --path . --export-release "Web" web/index.html
  ```

- Probarla: el servidor `web` de `.claude/launch.json` (`py -m http.server 8060 --directory web`) y abrir
  `http://localhost:8060`.
- Ajustes en `export_presets.cfg` (sin hilos: vale en Vercel sin cabeceras especiales) y `vercel.json` (sirve `web/`).
- Para probar un cambio sin pisar `web/` (por ejemplo, las letras de otro idioma), exportar a una carpeta temporal y servirla sin caché: ver
  «Probar en la web» en `docs/IDIOMAS.md`. Lo que se ve bien en el ordenador puede fallar en la web, que no trae letras del sistema.

## Lo que se atasca en la web

- **`draw_circle` (y los polígonos) en cantidad.** En la web cada `draw_circle` es un polígono con sus propios buffers
  de dibujo, y unos cientos por fotograma la ahogan: el latigazo del Glotón (6 lenguas × unos 290 dibujos) tardaba más
  de **un segundo por fotograma** (5 fotogramas seguidos: el juego «se ralentizaba y se paraba»; en el ordenador, 7 ms).
  Las líneas, los rectángulos y `draw_primitive` (que son «primitivas») aguantan miles. Por eso `Tentaculo.pintar`
  (lenguas y tentáculos) pinta cada trozo con un solo `draw_primitive` (`Tentaculo.trozos`) y las ventosas con
  `Tentaculo.disco` (dos cuadrados). Si algo se atasca solo en la web, mirar primero cuántos `draw_circle` o
  `draw_colored_polygon` hace por fotograma.
- **Medirlo:** `-- --captura --rendimiento` (`prueba_varias.gd`, `probar_rendimiento`) imprime cuánto tarda cada
  fotograma durante el latigazo del Glotón (media y peor, en ms; vale 16 ms a 60 fps, y con más de 50 el juego se
  nota parado). En la web se pone en `"args"` de `GODOT_CONFIG` del `index.html` exportado (`["--", "--captura",
  "--rendimiento"]`) y se lee en la consola del navegador. Ojo: el `index.html` se pisa al exportar; y el navegador de
  la app de Claude no tiene el foco de la ventana pero sí sirve para medir.

## Lo que suena distinto en la web

- Se quita todo el sonido cuando la página se oculta (otra pestaña, móvil bloqueado) **y también cuando pierde el
  foco** (otra ventana delante, otro programa, el panel del navegador de la app de Claude): con la ventana detrás de
  otra o en otra pantalla, la página no cuenta como oculta y la música seguía sonando (29 oct). Lo hace `_visibilidad`
  de `sonido.gd`, con los avisos `visibilitychange`, `blur` y `focus` del navegador.
- En la web, Godot hace sonar cada sonido directamente en el navegador. Al llegar al final de una canción en bucle,
  no vuelve al principio sino al punto donde se empezó a tocar. Por eso, en la web la música empieza siempre al
  principio (`poner_cancion` de `sonido.gd`); en el ordenador, en un compás al azar. Antes, en la web se repetía
  sin parar solo el último trozo de la canción (el 29 oct, 9 segundos de la del menú).
- La música va por capas (dos `.ogg` por canción que suenan a la vez, ver `sonido.gd`). En la web, Godot guarda cada
  sonido descomprimido y hace otra copia entera cada vez que empieza a sonar: con tres capas por canción se llegaba a
  unos 420 MB solo de música. Por eso son dos capas y no tres, y el sonido de la web va a 32 000 muestras por segundo
  (`audio/driver/mix_rate.web` en `project.godot`; sin él, el navegador pone 48 000), sin perder nada: los `.ogg` ya van
  a 32 000 y los efectos se hacen a 22 050. Cada capa ocupa 23 MB en vez de 35: unos 140 MB de música con las dos
  canciones cargadas y unos 185 MB mientras una entra y la otra se va (antes de las capas, unos 105 y 140).
  Medido el 29 oct: las dos capas empiezan en el mismo instante y desde el principio, y `--musica` sale bien también
  en la web.
- Para ver qué suena en una exportación de prueba sin oírla: un script en el `<head>` de su `index.html` que envuelva
  `AudioBufferSourceNode.prototype.start` y `stop` (cada canción que empieza y para, con su punto de inicio) y conecte
  un `AnalyserNode` a la salida (cuánto suena). Así se encontró esto. Para la memoria, envolver también
  `AudioContext.prototype.createBuffer` (canales × muestras × 4 bytes cada sonido). Una prueba (`-- --captura --musica`)
  también corre en la web poniéndola en `"args"` de `GODOT_CONFIG` en el `index.html`, con el panel del navegador a la
  vista (escondido, el juego no avanza).
