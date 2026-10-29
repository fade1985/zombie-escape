# Idiomas · cómo se traduce el juego

El juego está en **español** (idioma de origen) y en **inglés, portugués de Brasil, alemán y francés** (`locale/<código>.po`:
`en`, `pt_BR`, `de`, `fr`). Se elige en Opciones → General (una fila de botones «Idioma / Language»), se guarda en
`ajustes.idioma` y, si nunca se ha elegido, manda el idioma del sistema (español, portugués, alemán o francés si el sistema está en
uno de ellos y, si no, inglés). Para añadir otro: ver «Añadir un idioma». Glosarios de cada uno: `GLOSARIO_EN.md`,
`GLOSARIO_PT_BR.md`, `GLOSARIO_DE.md` y `GLOSARIO_FR.md`.

Cómo va la migración (qué archivos ya están pasados y cuáles faltan): ver el apartado «Estado» al final.

## La idea

- Cada texto del código **es su propia clave**: `Idioma.t("Salir")` devuelve «Salir» en español y «Quit» en inglés,
  que es lo que pone `locale/en.po`. Si a un texto le falta su traducción, se ve en español y no se rompe nada.
- El español nunca pasa por la tabla (`Idioma.t` lo devuelve tal cual), así que **no puede cambiar** al traducir.
- `Idioma` es un autoload (`scripts/idioma.gd`): se llama desde cualquier script, también desde los `static`.

## Cómo se escribe un texto (al hacer código nuevo)

Todo texto que vea el jugador pasa por `Idioma`:

```gdscript
label.text = Idioma.t("Opciones")
label.text = Idioma.t("Llevas %d") % cantidad            # primero se traduce y DESPUÉS se pone el número o el nombre
label.text = Idioma.n("%d intento", "%d intentos", n) % n  # singular y plural; el inglés sabe cuál toca
label.text = Idioma.t("Seguir", "pausa")                   # contexto (segundo parámetro): el mismo texto español
                                                           # que se dice distinto según el sitio
```

Reglas:

1. **Una frase entera por texto, nunca trozos pegados.** Mal: `"Has matado " + str(n) + " zombis"`; bien:
   `Idioma.t("Has matado %d zombis") % n`. Cada idioma ordena las palabras como quiere. Los `%s` y `%d` van en el
   mismo orden en los dos idiomas (GDScript no admite otro): si el inglés pide otro orden, se rehace la frase.
2. **Plurales y géneros con `Idioma.n`**, no con `"s" if n > 1 else ""`.
3. **No se traduce lo que no es texto del jugador:** ids, claves, nombres de nodos, rutas, mensajes de `print` (van a la
   consola) y las herramientas internas (el panel F11, `sala_armas.gd` y `scripts/pruebas/`).
4. **Números con decimales:** el español usa coma y el inglés punto (`0,5` / `0.5`). Si un texto lleva uno, se pone con
   `%s` y se formatea según `Idioma.actual` (hoy no hay ninguno pasado; se resuelve al llegar al primero).
5. **Comillas y apóstrofos en inglés: rectos (`"` y `'`)**: a la letra normal le faltan los rizados (`tema.gd`).
6. **Un texto que cabe justo en español** (botones, tarjetas): el inglés suele salir más corto, pero se mira en una
   captura (`--ingles`) antes de darlo por bueno.

### Tablas de datos (`const`)

En una `const` no se puede llamar a `Idioma.t`. Los textos se dejan en español en la tabla, se **marcan** con
comentarios y se traducen al enseñarlos (`Idioma.t(ficha.nombre)`):

```gdscript
# [traducir]
const LISTA := {"bate": {"nombre": "Bate", "desc": "Para dar golpes"}}
# [/traducir]
```

Todo lo que tenga letras entre las dos marcas es un texto (se saltan los ids en minúsculas, las rutas y las claves de
diccionario). Una sola línea se marca con `# [traducir]` al final de la línea. Lo que se vaya a enseñar tiene que pasar
por `Idioma.t(...)` en el sitio donde se muestra (o en una función que lo devuelva ya traducido, como `Alerta.regla()`).

Un texto en español que de verdad no se traduce (el botón «Idioma / Language», los nombres de los idiomas) lleva
`# no-tr` al final de su línea.

## La herramienta: `py tools/traducciones.py`

Recoge los textos del código (los de `Idioma.t`/`Idioma.n` y los de las tablas marcadas), pone al día `locale/en.po`
(añade los nuevos con la traducción vacía) y avisa de lo que está mal:

```
py tools/traducciones.py              pone al día los .po de todos los idiomas (añade los nuevos, sin traducción) y cuenta
py tools/traducciones.py --comprobar  lo mismo sin escribir (antes de subir)
py tools/traducciones.py --faltan     enseña todos los textos sin traducir
py tools/traducciones.py --limpiar    quita de los .po los textos que ya no están en el código
py tools/traducciones.py --idioma de  solo con ese idioma (en, pt_BR, de, fr); con --rellenar y --exportar es obligatorio
py tools/traducciones.py --idioma de --rellenar archivo.json   rellena los vacíos con {"español": "alemán"} (plural: [uno, varios];
                                      un texto con contexto: «contexto@@español»)
py tools/traducciones.py --idioma de --exportar lista.json     saca lo que falta por traducir, para quien traduce: la clave con la
                                      que contestar, el español, el inglés de referencia y dónde sale
```

Acaba con el código 1 si hay textos **sin traducir**, traducciones con **otros `%d`/`%s`**, otros saltos de línea u otros
espacios al principio o al final, o **textos en español sueltos** en un archivo ya pasado (lista `PASADOS` de la herramienta). Hay que
pasarla **antes de cada commit** que toque textos.

Cada entrada del `.po` es así (a mano solo se escribe el `msgstr`):

```
#: scripts/ui/menu_principal.gd
msgid "Salir"
msgstr "Quit"
```

## Probar

- `-- --captura --idioma` saca el menú, Opciones (sus tres pestañas), el cambio de idioma en caliente y «Elige edificio»
  (`prueba_idioma.gd`); con `--ingles` (o `--lang pt_BR`, `--lang de`, `--lang fr`), en ese idioma. Con `--alerta 3 --reto`,
  «Elige edificio» sale con la alerta y el reto.
- **Cualquier otra prueba, con `--ingles` o `--lang X`**, corre en ese idioma. Al cerrar, `idioma.gd` escribe `TEXTOS SIN TRADUCIR AL
  IDIOMA «en» (N): …` con los textos que se han pedido en esa prueba y no están en el `.po`. Sin ellos, las pruebas van siempre en
  español, aunque el guardado esté en otro idioma.
- El idioma se puede cambiar con la pantalla abierta: `Idioma.cambiado` avisa. Opciones y el menú principal ya se rehacen;
  el resto de pantallas (pausa, HUD...) se irán conectando al pasarlas.

## Añadir un idioma

1. En `tools/traducciones.py`, `IDIOMAS`: su código de Godot, su nombre y su regla de plural; `py tools/traducciones.py` crea
   `locale/<código>.po` vacío y `--exportar` saca la lista para quien traduce (con el encargo y las reglas que se dieron a las
   traducciones de pt_BR, de y fr, que valen de modelo: nombres propios fijos, `%d`/`%s` en el mismo orden, tamaños de las cajas,
   trato al jugador, glosario del idioma).
2. En `idioma.gd`: `IDIOMAS` (código y cómo se escribe en su idioma) y `DEL_SISTEMA` (el idioma del sistema que le corresponde).
3. En `project.godot`, `locale/translations`: añadir `res://locale/<código>.po`.
4. Mirar que la fuente (`tema.gd`) tiene las letras de ese idioma: la letra de la interfaz no tiene todas las vocales con tilde, pero la
   de los jefes, que le sirve de respaldo, sí; los alfabetos no latinos (ruso, chino...) necesitan otra fuente. Si cambia la
   gramática (el género, `de` + artículo, mayúsculas de los nombres), mirar los sitios que arman frases con nombres traducidos:
   `Idioma.minusculas()` ya deja los nombres alemanes con su mayúscula.
5. Lo dibujado en imágenes: la palabra del cartel de planta en `tools/cartel_planta_idiomas.py` (`PALABRAS`) y su juego de carteles en
   `mapa/puerta.gd` (`CARTELES_POR_IDIOMA`); las fotos de los tutoriales, con `--lang <código>` y `py tools/fotos_tutorial.py <código>`.
6. Probar el idioma con la prueba larga y con las pantallas más llenas (inventario, ordenador, tutorial, tiendas) mirando que cabe.

## Estado

Pasados (lista `PASADOS` de `tools/traducciones.py`):
- **Fase 1:** `idioma.gd`, `ui/menu_principal.gd`, `ui/opciones.gd`, `alerta.gd`, `edificios.gd`, `reto.gd` y el nombre de
  los modos de atacar (`johnny.gd`, `MODOS`).
- **Fase 2 (la interfaz):** `partida.gd` (avisos, carteles y fin de partida), `ui/menus.gd` (pausa y resumen),
  `ui/hud.gd`, `ui/tactil.gd`, `ui/tutorial.gd` (la ventana, no el texto de cada tutorial), `ui/inventario.gd` (mochila,
  baúl, tienda y banco), `ui/taquilla.gd`, `ui/ordenador.gd` y `ui/tele.gd`.

- **Fase 3 (los datos):** `armas.gd` (armas, calidades, munición), `objetos.gd`, `lanzables.gd`, `talentos.gd`, `logros.gd`,
  `mutaciones.gd`, `skins.gd`, `eventos.gd`, `averia.gd`, `joyeria.gd`, `barricada.gd`. Sus textos están en tablas
  `# [traducir]` y **sus funciones devuelven el texto ya traducido**: quien lo enseñe usa `Armas.nombre(id)`,
  `Objetos.nombre(id)`, `Lanzables.uno(tipo)`, `Talentos.nombre_de(id)` / `desc_de(id)` / `nombre_rama(id)`,
  `Logros.nombre_de(id)` / `desc_de(id)` / `nombre_tema(tema)`, `Skins.nombre(id)` / `como(id)` / `efecto(id)`,
  `Mutaciones.mutacion(id)`..., no la tabla directa (y sin volver a envolverlo en `Idioma.t`).

- **Fase 4 (la voz del juego):** `historia.gd` (dosier y noticias: `titulo_de`, `cuerpo_de`, `titular_de`, `texto_de`, `hoja`...),
  `tutoriales.gd` (`titulo_de`, `texto`, `nombre_grupo`; las `{teclas}` se sustituyen DESPUÉS de traducir), `bestiario.gd`
  (`nombre`, `frase`), `supervivientes.gd` (`nombre_de`, `desc_de`; los nombres van **sin artículo**: las frases ponen el suyo),
  `escolta.gd` y los gritos de los jefes, de los zombis y de Johnny (`gerente.gd`, `portera.gd`, `gymbro.gd`, `johnny.gd`...).
  Los gritos se adaptan con ingenio, no se traducen literalmente.

- **Fase 5 (el mundo):** `mapa/planta.gd`, `mapa/tienda.gd`, `mapa/apartamento.gd`, `mapa/viviendas.gd`, `mapa/neon.gd`,
  `mapa/cartel_trasteros.gd`, `mapa/puerta.gd`, `minimapa.gd` y los avisos de `peligros/`. Los nombres de planta, de sitio y de tienda se
  **guardan en español al generar la planta** (también sirven de clave: `nombre_puerta`) y se traducen solo al enseñarlos, con
  `Planta.nombre_planta(num)`, `Planta.nombre_de(planta)`, `Planta.nombre_de_sitio(sitio)`, `Planta.aviso_de(salida)`,
  `Tienda.nombre(tipo)` y `Tienda.neon(tipo)`.

**Lo dibujado en imágenes** (no sale en `locale/*.po`; hay una versión por idioma y el código elige según `Idioma.actual`):
- `assets/sprites/cartel-planta-N.png` lleva «PLANTA»: `py tools/cartel_planta_idiomas.py` hace `cartel-planta-N-<idioma>.png` («FLOOR»,
  «ANDAR», «ETAGE»), que `mapa/puerta.gd` (`CARTELES_POR_IDIOMA`) usa según el idioma.
- `assets/ui/tutorial/<id>.png` son recortes de capturas con el texto del juego dibujado: las de cada idioma van en
  `assets/ui/tutorial/<idioma>/<id>.png` (`ui/tutorial.gd` las prefiere y, si no hay, usa la de español). Se rehacen con las
  capturas sacadas con `--lang <idioma>` y `py tools/fotos_tutorial.py <idioma>`; las ocho que no llevan ningún texto (apagón, curas,
  horda, incendio, jugar, lanzables, munición, peligros) valen para todos los idiomas y no se rehacen. Cuando cambie lo que se ve en el
  juego, hay que repetir las fotos en cada idioma (la lista de pruebas que las sacan está en `tools/fotos_tutorial.py`).
- Sin texto dibujado: `EXIT` de la salida de incendios (ya es inglés), la «H» del helipuerto y los escaparates (garabatos). El logo
  (`assets/ui/logo.png`) lleva el nombre del juego, que aún no está decidido (`docs/LANZAMIENTO.md`).

**Lo que falta:** la revisión de cada idioma por una persona nativa (sobre todo el humor y los gritos). Cómo se dice cada cosa:
`docs/GLOSARIO_EN.md`, `GLOSARIO_PT_BR.md`, `GLOSARIO_DE.md` y `GLOSARIO_FR.md`.

**Decimales:** `Talentos.decimal(x)` da la coma en español, portugués, alemán y francés y el punto en inglés (de momento solo lo
usa `talentos.gd`; los `%.1f` de otras pantallas salen con punto en todos los idiomas, como en español).
