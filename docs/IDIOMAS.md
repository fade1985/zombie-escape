# Idiomas · cómo se traduce el juego

El juego está en **español** (idioma de origen) y en **inglés** (segundo idioma, `locale/en.po`). Se elige en
Opciones → General (botón «Idioma / Language»), se guarda en `ajustes.idioma` y, si nunca se ha elegido, manda el
idioma del sistema (español si está en español, inglés si no). Otros idiomas, más adelante: ver «Añadir un idioma».

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
py tools/traducciones.py              pone al día el .po y cuenta
py tools/traducciones.py --comprobar  lo mismo sin escribir (antes de subir)
py tools/traducciones.py --faltan     enseña todos los textos sin traducir
py tools/traducciones.py --limpiar    quita del .po los textos que ya no están en el código
py tools/traducciones.py --rellenar archivo.json   rellena los vacíos con {"español": "inglés"} (plural: [uno, varios])
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
  (`prueba_idioma.gd`); con `--ingles`, en inglés. Con `--alerta 3 --reto`, «Elige edificio» sale con la alerta y el reto.
- **Cualquier otra prueba, con `--ingles`**, corre en inglés. Al cerrar, `idioma.gd` escribe `TEXTOS SIN TRADUCIR AL IDIOMA
  «en» (N): …` con los textos que se han pedido en esa prueba y no están en el `.po`. Sin `--ingles`, las pruebas van siempre en
  español, aunque el guardado esté en inglés.
- El idioma se puede cambiar con la pantalla abierta: `Idioma.cambiado` avisa. Opciones y el menú principal ya se rehacen;
  el resto de pantallas (pausa, HUD...) se irán conectando al pasarlas.

## Añadir un idioma

1. En `idioma.gd`, `IDIOMAS`: `["fr", "Français"]`.
2. Copiar `locale/en.po` a `locale/fr.po`, cambiar `"Language: en"` y vaciar los `msgstr`. (`tools/traducciones.py`
   trabaja hoy solo con `locale/en.po`, constante `PO`: con el segundo idioma habrá que hacerla multiidioma.)
3. En `project.godot`, `locale/translations`: añadir `res://locale/fr.po`.
4. Mirar que la fuente (`tema.gd`) tiene las letras de ese idioma (los alfabetos no latinos necesitan otra fuente).

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

**Lo que aún sale en español:** los nombres de planta, de sitio y de tienda (`mapa/planta.gd`, `mapa/tienda.gd`; fase 5, con los carteles del mundo y los dibujados en imágenes:
`cartel-planta-N.png` lleva «PLANTA», y las fotos de `assets/ui/tutorial/` pueden llevar texto del juego dibujado). Cómo se dice cada cosa en inglés: `docs/GLOSARIO_EN.md`.

**Decimales:** `Talentos.decimal(x)` da la coma en español y el punto en inglés (de momento solo lo usa `talentos.gd`).
