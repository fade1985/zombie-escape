# Idiomas · cómo se traduce el juego

El juego está en **español** (idioma de origen) y en **inglés, portugués de Brasil, alemán, francés, ruso y chino simplificado**
(`locale/<código>.po`: `en`, `pt_BR`, `de`, `fr`, `ru`, `zh_CN`). Se elige en Opciones → General (una fila de botones «Idioma /
Language»), se guarda en `ajustes.idioma` y, si nunca se ha elegido, manda el idioma del sistema (el suyo, si es uno de ellos y, si
no, inglés). Para añadir otro: ver «Añadir un idioma». Glosarios de cada uno: `GLOSARIO_EN.md`, `GLOSARIO_PT_BR.md`,
`GLOSARIO_DE.md`, `GLOSARIO_FR.md`, `GLOSARIO_RU.md` y `GLOSARIO_ZH_CN.md`.

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
   consola) y las herramientas internas (el panel F9, `sala_armas.gd` y `scripts/pruebas/`).
4. **Números con decimales:** el español usa coma y el inglés punto (`0,5` / `0.5`). El texto de la frase lleva `%s` (nunca `%.1f`) y
   el número se escribe aparte con `Idioma.puntuar("%.1f" % x)`: `Idioma.t("%s ataques por segundo") % Idioma.puntuar("%.1f" % x)`.
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

- `-- --captura --idioma` saca el menú, Opciones (sus cuatro pestañas y las licencias de Créditos), el cambio de idioma en caliente y «Elige edificio»
  (`prueba_idioma.gd`); con `--ingles` (o `--lang pt_BR`, `--lang de`, `--lang fr`), en ese idioma. Con `--alerta 3 --reto`,
  «Elige edificio» sale con la alerta y el reto.
- **Cualquier otra prueba, con `--ingles` o `--lang X`**, corre en ese idioma. Al cerrar, `idioma.gd` escribe `TEXTOS SIN TRADUCIR AL
  IDIOMA «en» (N): …` con los textos que se han pedido en esa prueba y no están en el `.po`. Sin ellos, las pruebas van siempre en
  español, aunque el guardado esté en otro idioma.
- El idioma se puede cambiar con la pantalla abierta: `Idioma.cambiado` avisa. Opciones y el menú principal ya se rehacen;
  el resto de pantallas (pausa, HUD...) se irán conectando al pasarlas.
- **Que el idioma elegido se recuerda** (probado el 29 oct 2026, bien): sin `--captura`, `Idioma.poner` escribe `ajustes.idioma` y manda
  al volver a abrir el juego (también con siete idiomas seguidos); sin elección manda el del sistema (`DEL_SISTEMA`; uno que no está en
  la lista, inglés), y un código guardado que no existe se ignora. Para repetirlo sin tocar el guardado del dueño: un `override.cfg` en
  la raíz con `[application]` → `config/use_custom_user_dir=true` y `config/custom_user_dir_name="ZombieEscape_TestIdioma"` (así
  `user://` es otra carpeta) y, en el mismo archivo, un autoload provisional (`[autoload]` → `Prueba="*res://_tmp.gd"`) que espere un
  segundo, abra `Opciones.abrir(menu, menu.centro)`, pulse el botón del idioma (`b.pressed.emit()`) y cierre; luego se abre otra vez
  y se mira `Idioma.actual`. Se arranca con `--headless --path .` (sin `--captura`) y, **al acabar, se borran `override.cfg`, el
  script y la carpeta `%APPDATA%\ZombieEscape_TestIdioma`**. No sirven `-s` (no carga los autoloads a tiempo) ni `--language` (cambia
  el idioma de Godot, no el que lee `OS.get_locale_language()`).

- **Probar en la web** (sin tocar `web/`): exportar a una carpeta temporal con `--headless --path . --export-release "Web"
  <carpeta>/index.html`, servirla con un servidor que no guarde nada en caché (el navegador se queda con el `index.pck` viejo y no se
  entera de lo nuevo: un `py -m http.server` normal no sirve; basta un `SimpleHTTPRequestHandler` que ponga `Cache-Control: no-store`) y
  abrirla en el navegador. El primer clic solo da el foco al lienzo; el segundo funciona. Se cambia de idioma en Opciones. Con los
  `print` del juego se ve algo en la consola del navegador. Hecho el 29 oct 2026: el español, el ruso y el chino se ven con sus letras y el
  chino parte bien las líneas (`AUTOWRAP_ARBITRARY` no hace falta: el servidor de texto de la web lleva ICU).
- **Pasada de tamaños** (29 oct 2026): se miraron en ruso, alemán, francés y portugués las pantallas más llenas (inventario y fichas de
  armas, ordenador entero, tienda, baúl, banco, skins, tutorial, mutaciones, HUD, eventos, tiendas y «Elige edificio») con
  `-- --captura <prueba> --lang X`. Solo fallaron dos cosas, las dos en ruso: «Перезарядка» pegada a sus cuadritos en la ficha de un arma y
  las tarjetas de «Elige edificio» (el último texto se salía de la tarjeta y, al crecer, el botón «Назад» no cabía en pantalla; en chino,
  parecido). `-- --captura --medidas --todo` da la lista de textos cortos que más crecen, por si hay que acortar alguno. Cuando se
  añada una caja de tamaño fijo, mirarla en ruso y chino.

## Las letras (fuentes)

La letra de la interfaz (`zombie-scape-ui.ttf`) y la de los jefes (Jersey 25) solo traen el alfabeto latino. Las letras que no tienen
salen de otras, en una cadena que `Tema.poner_fuentes` pone al arrancar y cada vez que cambia el idioma (`Idioma.poner`): letra del
juego → Jersey 25 (los signos y las vocales con tilde que faltan) → la del idioma que se juega: en ruso, **Ark Pixel de 16 px**
(`ark-pixel-16.woff2`: todo el cirílico, a la medida exacta del juego, 70 KB) y en chino, **Unifont**
(`unifont-16-zh.woff2`: glifos de 16×16 píxeles, justo la cuadrícula del juego; 175 KB, recortada a los 7447 caracteres de los hanzi
comunes de GB2312, sus signos y los de la traducción: para añadir otros, volver a recortar `unifont-18.0.01.otf` de
`ftp.gnu.org/gnu/unifont/` con `fontTools.subset`). Antes se usó Fusion Pixel de 12 px, pero a 16 px no es una cuadrícula entera y los
trazos salían irregulares, y su altura de línea (22) rompía las cajas; Ark Pixel de 16 px no sirve para el chino (solo trae 97 hanzi). En
español, inglés, portugués, alemán y francés no hay más reserva que la Jersey 25. El nombre de cada idioma en el selector de
Opciones («Русский», «简体中文») se escribe con su propia letra (`Tema.fuente_del_idioma`, una `override` del botón), en cualquier
idioma. Las tres fuentes se usan con la OFL 1.1 (Unifont tiene doble licencia, OFL o GPL con excepción de fuentes): sus licencias
(`ark-pixel-OFL.txt`, `unifont-OFL.txt` y `jersey-25-OFL.txt`) van con el juego (se exportan: `include_filter` de `export_presets.cfg`) y se citan en Opciones → Créditos, cuyo botón Licencias
las enseña enteras (`opciones.gd`, `texto_de_licencias`). Las dos de reserva van
sin suavizado (ajustes de su `.import`: `antialiasing=0`, `hinting=0`, `subpixel_positioning=0`). La prueba `-- --captura --letras` (`prueba_letras.gd`) dice, de cada idioma, las letras de sus
traducciones que no tiene ninguna fuente (saldrían como un cuadro) y cuánto mide una línea con la letra de cada idioma.

**La cadena va plana, y esto costó un día de errores (29 oct 2026).** Hasta entonces la cadena era letra del juego → Jersey 25 → (las
reservas colgando de la Jersey 25). Una reserva que cuelga de otra reserva **no se alcanza**: la Jersey 25 como reserva solo aporta su
propia letra. En el ordenador parecía que sí, porque Windows pone una letra del sistema para lo que falta (el ruso y el chino se veían
con la del sistema, lisa, no la pixelada), pero **en la web, que no trae letras del sistema, el ruso y el chino salían como cuadros con
su código dentro**. Ahora las reservas van todas directamente en `FUENTE.fallbacks` (y la de los nombres de jefes, en
`FUENTE_JEFE.fallbacks`). Un `FontVariation` como reserva solo aporta su letra, nunca las reservas de su base. **Para probar una letra
nueva o un idioma nuevo, mirarlo siempre en la web** (ver «Probar en la web» abajo): en el ordenador no se nota si falla.

**La altura de las líneas.** Las letras de reserva miden más de alto que la del juego (a 16 px, por encima y por debajo de la línea: la
del juego, 13 y 4; Ark Pixel, 17 y 5; Unifont, 14 y 2). Se les ajusta con un `FontVariation` (`spacing_top`/`spacing_bottom`, en
`Tema.fuente_del_idioma`), y así una línea escrita mide lo mismo que con la del juego (17). Pero `Font.get_height()` de la letra del
juego, que usan los botones y las etiquetas, es el máximo de las reservas sin ajuste: **22 en ruso** (Ark Pixel) y 17 en chino (Unifont,
que no pasa de la del juego) y en los demás. En ruso, las líneas de varias líneas ocupan 25 px cada una en vez de 20 y una caja de tamaño
fijo hecha para el español se queda corta.
Solo hay una, las tarjetas de «Elige edificio» (`menu_principal.gd`: `medir_tarjetas` cuenta las líneas de cada texto con una etiqueta
de verdad y la tarjeta crece lo que haga falta; en español, alemán y francés queda como estaba). Las barras de la ficha de un arma
(`barra()` de `inventario.gd`) ensanchan su nombre si no cabe en 96 px («Перезарядка»). No se puede igualar `get_height()`: se probó con
variaciones y con el espaciado del propio `FontFile` y no se mueve.

**Plurales:** cada idioma lleva en `tools/traducciones.py` (`IDIOMAS`) su regla y cuántas formas tiene: dos (los demás), tres (ruso: 1 /
2-4 / 5+) o ninguna (chino). Un texto con plural se entrega como lista de tantas formas (o como una cadena en chino).

## Añadir un idioma

1. En `tools/traducciones.py`, `IDIOMAS`: su código de Godot, su nombre, su regla de plural y cuántas formas («formas», si no son dos); `py tools/traducciones.py` crea
   `locale/<código>.po` vacío y `--exportar` saca la lista para quien traduce (con el encargo y las reglas que se dieron a las
   traducciones de pt_BR, de y fr, que valen de modelo: nombres propios fijos, `%d`/`%s` en el mismo orden, tamaños de las cajas,
   trato al jugador, glosario del idioma).
2. En `idioma.gd`: `IDIOMAS` (código y cómo se escribe en su idioma) y `DEL_SISTEMA` (el idioma del sistema que le corresponde).
3. En `project.godot`, `locale/translations`: añadir `res://locale/<código>.po`.
4. Mirar que alguna fuente tiene las letras de ese idioma (`--letras`): la letra de la interfaz no tiene todas las vocales con tilde, pero la
   de los jefes, que le sirve de respaldo, sí; el cirílico y el chino, las de reserva (ver «Las letras»); otros alfabetos (japonés, coreano,
   árabe...) necesitan otra fuente en `Tema`. Si cambia la
   gramática (el género, `de` + artículo, mayúsculas de los nombres), mirar los sitios que arman frases con nombres traducidos:
   `Idioma.minusculas()` ya deja los nombres alemanes con su mayúscula.
5. Lo dibujado en imágenes: la palabra del cartel de planta en `tools/cartel_planta_idiomas.py` (`PALABRAS`) y su juego de carteles en
   `mapa/puerta.gd` (`CARTELES_POR_IDIOMA`); las fotos de los tutoriales, con `--lang <código>` y `py tools/fotos_tutorial.py <código>`.
6. **Cómo cuenta las plantas:** en España (y en Alemania, Francia o Brasil) la de la calle es la «planta baja» y la de encima, la 1ª; en
   Estados Unidos, Rusia o China la de la calle ya es la 1ª. Si cuenta como estos, su código va en `Planta.CALLE_ES_LA_PRIMERA` (y en la
   lista igual de `tools/cartel_planta_idiomas.py`): sus plantas y sus puertas suben un número («1ª planta» es *2nd floor*, «1ºD» es
   *2D*), los carteles pintados van del 1 al 4 y las traducciones de «Planta baja», «1ª planta»… se escriben ya con un número más.
7. Probar el idioma con la prueba larga y con las pantallas más llenas (inventario, ordenador, tutorial, tiendas) mirando que cabe.
   `--pasillo --lang <código>` escribe cómo se llaman las plantas y sus puertas, y saca el cartel de cada una.

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
  «ANDAR», «ETAGE»), que `mapa/puerta.gd` (`CARTELES_POR_IDIOMA`) usa según el idioma. En inglés, ruso y chino, donde la planta de la
  calle ya es la 1ª, el cartel de la planta N lleva el número N + 1 (el 4, `cartel-planta-4.png`, solo lo usan ellos).
- `assets/ui/tutorial/<id>.png` son recortes de capturas con el texto del juego dibujado: las de cada idioma van en
  `assets/ui/tutorial/<idioma>/<id>.png` (`ui/tutorial.gd` las prefiere y, si no hay, usa la de español). Se rehacen con las
  capturas sacadas con `--lang <idioma>` y `py tools/fotos_tutorial.py <idioma>`; las ocho que no llevan ningún texto (apagón, curas,
  horda, incendio, jugar, lanzables, munición, peligros) valen para todos los idiomas y no se rehacen. Cuando cambie lo que se ve en el
  juego, hay que repetir las fotos en cada idioma (la lista de pruebas que las sacan está en `tools/fotos_tutorial.py`).
- Sin texto dibujado: `EXIT` de la salida de incendios (ya es inglés), la «H» del helipuerto y los escaparates (garabatos). El logo
  (`assets/ui/logo.png`) lleva el nombre del juego, que aún no está decidido (`docs/LANZAMIENTO.md`).

**Revisión:** no hay nadie nativo que revise ningún idioma (decisión del dueño, 30 oct 2026): se sale con lo traducido y se corrige con los avisos
de los jugadores (sobre todo el humor y los gritos). Cómo se dice cada cosa:
`docs/GLOSARIO_EN.md`, `GLOSARIO_PT_BR.md`, `GLOSARIO_DE.md` y `GLOSARIO_FR.md`.

**Decimales:** `Idioma.puntuar(texto)` cambia el punto de un número ya escrito: coma en español, portugués, alemán, francés y ruso, y
punto en inglés y chino. Lo usan los talentos (`Talentos.decimal`), el ordenador (los ataques por segundo de las armas) y la pausa
(`menus.gd`: «x1,50» y los ataques por segundo). Hasta el 29 oct 2026 estos últimos salían con punto en todos los idiomas, también en
español («1.6 ataques/s»); ahora el español también escribe «1,6». Las frases que llevaban `%.1f` (`"%.1f ataques por segundo"`,
`"%s · daño %d · %.1f/s"`) llevan `%s` en el .po de cada idioma. Al escribir un texto con un decimal, usar siempre `puntuar`.
