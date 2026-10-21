# Mapa del código

## Raíz

- `project.godot`: escena de inicio, pantalla, pixel art nítido, teclas de cada acción, capas de choque.
- `default_bus_layout.tres`: buses de audio. `export_presets.cfg` y `vercel.json`: ver `WEB.md`.

## escenas/

- `menu_principal.tscn`: la escena de inicio (`scripts/ui/menu_principal.gd`).
- `partida.tscn`: Johnny y la pantalla (sitio, avisos, fundido). El mapa lo monta `partida.gd`; el HUD,
  `ui/hud.gd`; el minimapa, `minimapa.gd`; la pausa y el final, `ui/menus.gd`.
- `salas/`: la sala de pruebas de las fases 1-3 (`bano.tscn` y `bano_tileset.tres`: las piezas y cuáles chocan).
- `personajes/`: `johnny.tscn`, un `zombi_<tipo>.tscn` por tipo (sus números en el Inspector), `portera.tscn`
  y los minijefes del centro comercial (`antidisturbios.tscn`).
- `armas/`: `bala.tscn` (bala y perdigones), `bala_zombi.tscn` (agua sucia de la portera), `proyectil.tscn`
  (moco y botella de lejía, en parábola), `charco.tscn` y `explosion.tscn`.
- `luces/`: `lampara.tscn` (luz de suelo con sombras, luz de lo demás sin sombras y bombilla), `fuego.tscn` y
  `luz_suave.tres` (el degradado de todas).
- `muebles/`: un mueble por escena, con su choque y su `Sombra`.

## scripts/

**Personajes y combate**
- `johnny.gd`: moverse, vida, apuntar y atacar. `mejoras.gd`: sus atributos (el baseStats del JS).
- `armas.gd`: los números de las armas (las creadas, en `Armas.CREADAS`). `bala.gd`.
- `armas_creadas.gd`: lo que hacen las armas creadas (aturdir, prender, sangrar, descarga…); `chorro.gd` (gotas de
  fuego y ácido) y `bumeran.gd`.
- `lanzables.gd`: molotov, granada y arrojadizas creadas (munición, apuntar, lanzar; `Lanzables.tipos()`).
  `granada.gd`: también la atraedora, la congeladora y la lluvia ácida.
- `charco.gd` (veneno, lejía, vómito, fuego y ácido) y `estados.gd` (lo que hacen los charcos; también el frío y el
  calambrazo de los peligros, y `frenado`).
- `peligros/`: los peligros de las tiendas del centro comercial. `peligros.gd` (sus números y dónde va cada uno, al
  generar la planta), `frio.gd` (la cámara frigorífica; congela a los zombis: `zombi.gd`), `fuego.gd` (la cocina del
  restaurante, que se extiende por casillas), `agua.gd` (el charco con corriente de la electrónica, su cable, las luces
  de las teles y lo oscura que se queda la tienda: `Luz.extra`) y `cuadro.gd` (el cuadro eléctrico).
- `zombi_guardia.gd` (escena `zombi_guardia.tscn`, hereda la del normal): el guardia de seguridad del centro
  comercial, que lleva la tarjeta (ronda, silbato, huye, se cansa). Lleva el dibujo del vigilante.
- Los zombis del centro comercial (parte 4): `zombi_vigilante.tscn` (hereda la del normal; solo cambian números y
  dibujo: vida 45, velocidad 85, porrazo de 12 con más alcance; también son los refuerzos del silbato) y
  `zombi_dependienta.gd`/`.tscn` (vida 20, velocidad 95; al despertar grita «¡OFERTAS!», despierta a toda la tienda
  y les mete prisa 5 s con `meter_prisa` de `zombi.gd`, un 30 % más rápidos; luego guarda las distancias y vuelve a
  gritar cada 8 s; acorralada, chilla en la cara: 6). Salen en las tiendas (`planta.gd`, `horda`).
- `zombi.gd`: la base de todos (perseguir con navegación, zarpazos, golpes); normal, lento y rápido solo cambian
  números. `zombi_explosivo.gd`, `zombi_tentaculos.gd` y `zombi_venenoso.gd` heredan y añaden su ataque.
- `portera.gd`: la jefa, por estados (charcos de ácido, embestida, grito "¡VECINOS!"; números en sus constantes).
- `minijefe.gd`: lo común de los cuatro minijefes del centro comercial (vida y barra, enfadarse a media vida con
  vapor, llamar zombis, moverse, recibir golpes con `danar()` para cambiar el daño, morir). Cada uno hereda y pone
  sus ataques: `antidisturbios.gd` (escudo por delante y doble por la espalda, porrazo, carga que le atonta si se
  estrella, silbato). Las explosiones les dan "de lleno" (`explosion.gd`); a Johnny la carga le pone el estado
  "tirado" (`estados.gd`).
- `bala_zombi.gd`, `proyectil.gd` (moco, lejía y ácido en parábola), `explosion.gd`.
- `persona.gd`: una persona dibujada con formas (drawHuman del JS), para los supervivientes.
- `mutaciones.gd`, `llamas.gd`, `quemado.gd` (el cuerpo que muere ardiendo), `particulas.gd`, `mancha.gd`.

**Partida y progreso**
- `edificios.gd`: la ficha de cada edificio (Apartamentos, Centro comercial) y el elegido en el menú; `MINIJEFES`,
  el nombre de cada minijefe y de su tienda. La partida sortea al empezar qué minijefe va en cada planta
  (`orden_jefes`, `jefe_de()`; si aún no está hecho, la portera) y `planta.gd` lo apunta en `planta.jefe` y `el_jefe`.
- `partida.gd`: la planta en juego (cambiar de sitio, puerta cerrada hasta limpiar el piso, llave o tarjeta y su
  guardia, portera, escaleras, dinero, pausa, fin), teclas de prueba y `--captura` (con `--edificio centro`, en el
  centro comercial; con `--edificio centro --fotos-tiendas`, sin penumbra, una foto de cada tienda y de la galería:
  `captura-tienda-<tipo>.png`, `captura-galeria-<n>.png`, y las de los peligros: `captura-peligro-<...>.png`).
- `talentos.gd` (árbol y compra de puntos), `objetos.gd` (los 17 objetos, mochila, baúl, lo que sueltan los
  zombis), `recetas.gd` (15 recetas y rarezas), `billete.gd`, `minimapa.gd`.
- `guardado.gd`: el guardado entre partidas.
- `logros.gd`: la lista de logros (añadir uno = una línea en `LISTA`) y sus avisos.
- `historia.gd`: el texto del dosier, la hoja de papel y las noticias de Canal 8 (`NOTICIAS`, con cuándo sale
  cada una; las vistas en `noticias_vistas` del guardado). Para cambiar la historia se edita aquí, sin tocar los `id`.
- `supervivientes.gd` (el superviviente encerrado en su baño, la horda, los vecinos de mantenimiento) y
  `aliado.gd` (cada superviviente: sigue a Johnny, dispara o cura, fuerza la cerradura).
- `sonido.gd` (autoload): efectos sintetizados como en `src/sfx.js` y la música (`Sonido.tocar("compra")`,
  `Sonido.musica("jefe")`).
- `sala.gd`: la sala de pruebas (hornea la navegación, tandas mezcladas, F2-F7 y P, su `--captura`).

**ui/**
- `tema.gd` (aspecto de menús y HUD), `hud.gd`, `menus.gd`, `menu_principal.gd` (menú y "Elige edificio"), `opciones.gd` (pantalla de Opciones: modo de atacar, música, sonido, ajustes del móvil y tabla de controles para cambiarlos; los cambios los pone y guarda `scripts/controles.gd`), `tactil.gd` (controles del móvil; su tamaño, transparencia y vibración se leen de `ajustes` con `Tactil.ajustar()`).
- `ordenador.gd`: la pantalla de ConserjeOS. `inventario.gd`: inventario, baúl y banco.
- `tele.gd`: la tele de las noticias, dibujada con código. `ambiente.gd`: viñeteado, pantalla roja con poca vida y escarcha con frío.
- `botones.gd` (autoload): el saltito de los botones.

**mapa/**
- `apartamento.gd` (genera un apartamento como `apartment.js`), `tienda.gd` (genera una tienda del centro
  comercial, con el mismo tipo de plano), `planta.gd` (la planta, sus zombis, la sala de mantenimiento y la de
  exposición), `catalogo.gd` (muebles de cada sala; en las tiendas, por tipo: "tienda-<tipo>"), `muebles.gd`
  (dónde va cada uno; en las salas de venta, también filas en medio: `islas`), `mueble.gd` (monta uno).
- `mapa.gd`: monta un sitio (suelos, tapas, caras de pared, choques, muebles, peligros, niebla, navegación). Los suelos y
  paredes de cada sala salen de `ESTILO_DE` (pisos), `ESTILO_TIENDA` (tiendas) y `PASILLOS` (el pasillo de cada
  edificio); en el centro comercial pone además los escaparates, los neones y los restos sueltos.
  `cara_pared.gd`, `puerta.gd`, `puerta_bano.gd` (la del superviviente), `neon.gd` (el letrero de neón de una tienda).
- `ordenador.gd` (la mesa), `arrimable.gd` (baúl y banco), `armarito.gd` (botiquín), `cientifico.gd` (el
  científico muerto con su página).

**luz/**: `luz.gd` (penumbra de cada sitio, luz de Johnny, fogonazos), `lampara.gd`, `fuego.gd`.

## assets/

- `sprites/`: copia de los sprites del JS (`.png` + `.json` + `manifest.json`); los `.tres` de al lado son sus
  animaciones. Hoja nueva → `py tools/hacer_frames.py assets/sprites/zombi-normal`.
- `musica/`: tramos (`menu-*`, `explorar-*`, `jefe-*`.ogg) grabados del JS con `node tools/grabar_musica.mjs`
  (necesita el JS y ffmpeg). Si se graban más, cambiar `TRAMOS` en `sonido.gd`.
- `ui/`, `fuentes/`: HUD y menús del JS (la fuente es nítida a 16 y 32). `tiles/`: texturas para los TileSets.
- `sources/`: originales (lleva `.gdignore`). `pixellab.json`: todo lo generado en PixelLab.

## tools/

`hacer_frames.py` (hoja → animaciones); para los zombis nuevos, las herramientas del JS copiadas aquí: `piel.py`
(la piel a verde; admite otro tono de origen), `bajar_zip.py` y `bajar.py` (bajar de PixelLab), `hoja.py` (hoja de
revisión) y `zombi.py` (+ `png.py`: monta la hoja del zombi; con `"sangre_en_todo"` oscurece la sangre también en
el dibujo quieto y con `"sueltos"` quita los chorros que salen volando, en `assets/sources/<zombi>/zombi.json`); `jefe_hoja.py` (las vistas y animaciones de PixelLab de un minijefe de 72 → hoja y `.tres`:
`py tools/jefe_hoja.py antidisturbios-72 jefe-antidisturbios`; lo que falte, con la vista quieta), `texturas_bano.py`, `importar.py` (muebles nuevos → sprites; lee
`catalogo.gd`), `textura_suelo.py`, `textura_pared.py` y `textura_tapa.py` (suelos, paredes y tapas: ver `FONDOS.md`),
`guias_centro.py` (bocetos para pedir a PixelLab muebles rectos, y quitarles el fondo), `centro_sprites.py`
(escaparates y restos del centro comercial → sprites), `despixelar.py` (de PixelLab y Gemini), `dibujos_7b.py` (baúl, banco y armarito), `objetos16.py`
(objetos a 16×16), `icono_dosier.py`, `icono_noticias.py`, `hacer_casillas.py` (marcos de las casillas del HUD), `ver_dibujos.tscn` (foto de los dibujos hechos con
código) y `probar_sonido.gd` (guarda los efectos en `tools/efectos/*.wav`, no van a git).

## docs/ (del juego JS)

`PIXEL_ART.md`, `PIXELLAB.md`, `ZOMBIS.md`, `FONDOS.md`, `MAPA.md`: hablan del JS (`src/…`); valen para las ideas y
los números.
