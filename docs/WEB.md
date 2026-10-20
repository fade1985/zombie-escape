# Exportar a web y publicar

- Plantillas de exportación (solo las de web): `%APPDATA%\Godot\export_templates\4.7.2.stable`.
- Se exporta a `web/` (lleva un `.gdignore` para que el editor no importe lo exportado). **`web/` sí va en git:
  Vercel publica lo que haya ahí** (https://zombie-escape-two.vercel.app; la cuenta de Vercel la lleva otra
  persona, no el dueño). Para publicar un cambio: exportar, commit de `web/` y push.

  ```
  "<Godot>_console.exe" --headless --path . --export-release "Web" web/index.html
  ```

- Probarla: el servidor `web` de `.claude/launch.json` (`py -m http.server 8060 --directory web`) y abrir
  `http://localhost:8060`.
- Ajustes en `export_presets.cfg` (sin hilos: vale en Vercel sin cabeceras especiales) y `vercel.json` (sirve `web/`).
