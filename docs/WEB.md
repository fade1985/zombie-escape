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

## Lo que suena distinto en la web

- Se quita todo el sonido cuando la página se oculta (otra pestaña, móvil bloqueado) **y también cuando pierde el
  foco** (otra ventana delante, otro programa, el panel del navegador de la app de Claude): con la ventana detrás de
  otra o en otra pantalla, la página no cuenta como oculta y la música seguía sonando (29 oct). Lo hace `_visibilidad`
  de `sonido.gd`, con los avisos `visibilitychange`, `blur` y `focus` del navegador.
- En la web, Godot hace sonar cada sonido directamente en el navegador. Al llegar al final de una canción en bucle,
  no vuelve al principio sino al punto donde se empezó a tocar. Por eso, en la web la música empieza siempre al
  principio (`poner_cancion` de `sonido.gd`); en el ordenador, en un compás al azar. Antes, en la web se repetía
  sin parar solo el último trozo de la canción (el 29 oct, 9 segundos de la del menú).
- Para ver qué suena en una exportación de prueba sin oírla: un script en el `<head>` de su `index.html` que envuelva
  `AudioBufferSourceNode.prototype.start` y `stop` (cada canción que empieza y para, con su punto de inicio) y conecte
  un `AnalyserNode` a la salida (cuánto suena). Así se encontró esto.
