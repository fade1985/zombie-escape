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
  Las versiones de prueba se exportan **de desarrollo** (`--export-debug`): tienen **F9** y la sala de pruebas; la de
  `production`, terminada (`--export-release`), sin ella.
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

## Lo que pesa la web y la pantalla de carga

- Al abrir la página se descarga el motor (`index.wasm`, unos 9,5 MB comprimido) y el juego entero (`index.pck`) antes de poder
  jugar. Medido el 3 nov (M47): el juego bajaba **39 MB**; tras quitar el relleno de los dibujos, unos **28 MB**.
- **Los dibujos** son lo que más pesa (los jefes sobre todo: la criatura, el gerente mutado...). Godot rellenaba lo transparente
  de cada dibujo con el color del borde (`fix_alpha_border`, que solo sirve para dibujos suavizados, y el juego va píxel a píxel):
  no se ve, pero estropea la compresión. Desde el 3 nov se importan sin ese relleno (también los nuevos: `[importer_defaults]` de
  `project.godot`) y con la compresión sin pérdida al máximo (`rendering/textures/webp_compression`). Se comprobó que los 661
  dibujos se ven idénticos, píxel a píxel; pasaron de 31 a 20 MB. Lo malo: importarlos todos de cero tarda unos 2 minutos y medio.
- **No se toca** `icudt_godot.dat` (4,8 MB): son los datos para partir bien las líneas en chino (ver `docs/IDIOMAS.md`).
- **Para medir:** lo que baja de verdad, con
  `curl -s -H "Accept-Encoding: br, gzip" -o /dev/null -w "%{size_download}" https://zombie-escape-two.vercel.app/index.pck`;
  y lo que va dentro del `.pck`, leyendo su lista de archivos con `py` (empieza por `GDPC`).
- **Idea pendiente:** cargar los jefes en un segundo paquete mientras se juega (ahorraría unos 10 MB al empezar): partir el juego
  en dos `.pck` sin que salga ningún jefe antes de que llegue el suyo. Es más delicado y se dejó para ver antes cómo va esto.

### La pantalla de carga

- Es `assets/web/carga.html` (`html/custom_html_shell` en `export_presets.cfg`): la plantilla de Godot 4.7.2 con el logo, una
  barra, el tanto por ciento y frases del conserje que cambian cada 3 s, en el idioma del navegador (de los siete del juego; si
  no es ninguno, en inglés). Va en tanto por ciento y no en megas porque Godot cuenta los archivos sin comprimir (unos 75 MB), el
  doble de lo que se descarga.
- Las frases están en `TEXTOS`, dentro de la página: no pasan por `Idioma.t` (el juego aún no ha arrancado), así que si se cambia
  una, se cambia ahí en los siete idiomas.
- El logo va **metido dentro** de la página (una copia de `assets/ui/logo.png` en base64): si se rehace el logo, cambiar lo que va
  tras `data:image/png;base64,` por el nuevo (con `py` y su módulo `base64`).
- Para verla sin que cargue de golpe: exportar a una carpeta temporal y servirla despacio (un servidor de `py` que mande los
  archivos a trozos, con una pausa entre uno y otro).

## Pantalla completa y Esc

- **Esc es del navegador:** con la pantalla completa puesta, la quita en vez de llegar al juego (en el `.exe` no pasa, ver
  `docs/ESCRITORIO.md`). Por eso, al entrar en pantalla completa, `pantalla.gd` le pide que deje Esc para el juego
  (`navigator.keyboard.lock(['Escape'])`, en el aviso `fullscreenchange`) y lo suelta al salir.
- **Cómo se sale con el bloqueo:** manteniendo Esc pulsado un par de segundos (el navegador lo avisa con su cartel al entrar),
  con F11, o con el botón «Pantalla completa» del menú y de Opciones. Un Esc corto abre la pausa, y mantenerlo la abre una sola
  vez. En el móvil, el botón también está en la pausa.
- **Dónde funciona:** en Chrome y Edge de ordenador (probados en la versión 156, el 31 oct, sin que salga ningún permiso:
  Google anunció uno para Chrome 131 y luego no lo sacó). Opera lleva el mismo motor, pero no se ha probado. Hace falta https o
  localhost.
- **Dónde no funciona:** en Firefox y Safari no existe, y Esc sigue quitando la pantalla completa, como antes y sin errores
  (se probó en Chrome quitándole la función; Firefox y Safari de verdad, no). Dentro de un marco (`iframe`), como el reproductor
  de itch.io, el navegador lo rechaza (probado) y pasa lo mismo: para vender allí, habría que abrir el juego en su propia pestaña.
- **Probarlo:** un Esc simulado dentro de Godot no pasa por el navegador, así que no demuestra nada. Vale el protocolo de
  depuración del navegador (`--remote-debugging-port`, `Page.addScriptToEvaluateOnNewDocument` para espiar y
  `Input.dispatchKeyEvent` con `rawKeyDown`, que sí llega a la parte del navegador que quita la pantalla completa). Comprobar
  siempre también sin el bloqueo: si ahí no se sale, la prueba no vale. `-- --captura --pantalla` solo cubre el ordenador.

## Lo que se atasca en la web

- **Polígonos en cantidad (`draw_circle`, `draw_arc`, `draw_colored_polygon`, `draw_polyline`).** En la web cada uno es un
  polígono con sus propios buffers: unos 100-130 por fotograma cuestan 23 ms, pero con **200 o más cada fotograma tarda
  más de un segundo**. Así pasaba con el latigazo del Glotón (6 lenguas × unos 290 dibujos, casi todo círculos): el juego
  «se ralentizaba y se paraba» (5 fotogramas seguidos de 1 s; en el ordenador, 7 ms). Los rectángulos, las líneas y
  `draw_primitive` aguantan muchísimo más (12 800 rectángulos: 17 ms; un anillo o un abanico de triángulos, hasta
  unos 10 000 trozos). Por eso `scripts/formas.gd` (`Formas.disco`, `arco`, `poligono`, `polilinea`) pinta esas
  cuatro formas con primitivas, y `Tentaculo.pintar` (lenguas y tentáculos) pinta cada trozo con un solo
  `draw_primitive` (`Tentaculo.trozos`). **Con una forma nueva, usar `Formas`, no las funciones de CanvasItem.**
  Pintan igual que antes: `-- --captura --formas` compara los dos modos píxel a píxel (0,13 % de píxeles distintos, todos
  de borde).
- **Shaders que se montan a mitad de partida.** La primera vez que se dibuja con un shader, la tarjeta lo monta y el juego se
  para hasta que acaba. En el ordenador casi ni se nota, pero en la web (Windows, con ANGLE) cada uno de los grandes tarda de
  100 a 300 ms, y cada forma de dibujarlo (con luz, sin luz) se monta aparte. Así, el primer zombi que ardía dejaba el juego
  parado casi 2 s (F17). Por eso `scripts/calentador.gd` los monta al abrir el menú. **Con un shader grande nuevo, añadirlo a
  su lista.** `py tools/medir_web.py` dice qué shaders tardan y cuándo.
- **Leer una imagen de la tarjeta gráfica (`get_image`).** En la web, unos 18 ms cada lectura, y en un `AtlasTexture` lee la hoja
  entera. Con varios zombis muriendo ardiendo a la vez, el juego se paraba en cada molotov (F17). `quemado.gd` lee cada hoja una
  sola vez, y `cuerpo.gd` igual, solo si el enemigo muere junto a una pared: **nada de `get_image` repetido durante la partida.**
- **Medirlo:** `py tools/medir_web.py 45 --captura --molotov-carga --zombis 12` abre Edge sin ventana, con la tarjeta gráfica y un
  perfil nuevo (como quien entra por primera vez), saca la consola del juego y un espía de WebGL con los fotogramas lentos y
  los shaders que tardan. Es lo más fiable: **en el panel del navegador de la app no se mide**, porque a ratos va a un
  fotograma por segundo aunque diga «visible» (30 oct: parecía que el molotov dejaba fotogramas de 1 s y era el panel; seguía
  a 1 fps con el juego ya cerrado). También valen `-- --captura --dibujos` (cuánto cuesta cada tipo de dibujo según cuántos), `-- --captura --rendimiento`
  (el latigazo del Glotón, fotograma a fotograma), `--molotov-carga` (un molotov entre muchos zombis) y `--lentos`, que se añade
  a cualquier prueba y avisa de cada fotograma de más de 60 ms (con sus llamadas de dibujo y triángulos) y da un resumen al
  acabar. Se corren en la web
  poniendo los argumentos en `"args"` de `GODOT_CONFIG` del `index.html` exportado (`["--", "--captura", "--dibujos",
  "--lentos"]`; el `index.html` se pisa al exportar) y se leen en la consola del navegador.
- **¡Cuidado con medir con la página oculta!** Una página oculta (otra pestaña, o el panel del navegador de la app de
  Claude escondido) va a **un fotograma por segundo**: sale un «atasco» de 1 s en cualquier escena y las medidas no
  valen. Pasó el 29 oct: el Bombero con llamas parecía atascado y no lo estaba. Las líneas de `--lentos`, `--dibujos` y
  `--rendimiento` dicen «página visible» u «oculta»: si pone `hidden`, repetir. Hay que dejar el panel a la vista
  mientras se mide.

## Lo que suena distinto en la web

- **Salir** (menú principal): el navegador no deja que una página cierre su propia pestaña, así que sale una despedida
  («¡Gracias por jugar!», que la partida está guardada y que ya se puede cerrar la pestaña), con la música apagada y sin la
  pantalla completa; «Volver al menú» o Esc la quitan (M46; se ve con `-- --captura --despedida`).
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
