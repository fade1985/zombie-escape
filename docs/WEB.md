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
