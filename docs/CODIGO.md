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
  y los minijefes del centro comercial (`antidisturbios.tscn`, `cocinero.tscn`, `modista.tscn`, `mascota.tscn`).
- `armas/`: `bala.tscn` (bala y perdigones), `bala_zombi.tscn` (agua sucia de la portera y alfileres de la modista), `proyectil.tscn`
  (moco, botella de lejía y sartén del cocinero, en parábola), `charco.tscn` y `explosion.tscn`.
- `luces/`: `lampara.tscn` (luz de suelo con sombras, luz de lo demás sin sombras y bombilla), `fuego.tscn` y
  `luz_suave.tres` (el degradado de todas).
- `muebles/`: un mueble por escena, con su choque y su `Sombra`.

## scripts/

**Personajes y combate**
- `johnny.gd`: moverse, vida, apuntar y atacar. `mejoras.gd`: sus atributos (el baseStats del JS).
- `armas.gd`: los números de las armas (las creadas, en `Armas.CREADAS`). `bala.gd`.
- `armas_creadas.gd`: lo que hacen las armas creadas (aturdir, prender, sangrar, descarga, congelar, dejar tirado…);
  `chorro.gd` (gotas de fuego y ácido, chispas de la pistola eléctrica y clavos de la bomba de clavos), `bumeran.gd`
  y `garfio.gd` (engancha a un zombi y lo trae hasta Johnny).
- `lanzables.gd`: molotov, granada y arrojadizas creadas (munición, apuntar, lanzar; `Lanzables.tipos()`).
  `granada.gd`: también la atraedora, la congeladora, la lluvia ácida, la mina despertador, la nube somnífera (que
  suelta `nube.gd`) y la bomba de clavos. La bomba de aceite va como el molotov (`proyectil.gd`).
- `charco.gd` (veneno, lejía, vómito, fuego, ácido, aceite, que al acabar arde, el agua de los aspersores y el
  aceite hirviendo del cocinero, que no quema a quien lo tira) y `estados.gd` (lo que hacen los charcos; también el
  frío y el calambrazo de los peligros, y `frenado`).
- `peligros/`: los peligros de las tiendas del centro comercial. `peligros.gd` (sus números y dónde va cada uno, al
  generar la planta), `frio.gd` (la cámara frigorífica; congela a los zombis: `zombi.gd`), `fuego.gd` (la cocina del
  restaurante, que se extiende por casillas), `agua.gd` (el charco con corriente de la electrónica, su cable, las luces
  de las teles y lo oscura que se queda la tienda: `Luz.extra`; `arreglar()`, cuando el técnico arregla el cable y
  el agua deja de dar calambres) y `cuadro.gd` (el cuadro eléctrico).
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
  vapor, llamar zombis, moverse, recibir golpes con `danar()` para cambiar el daño, morir; y la carrera en línea
  recta, `embestir()` con `pared_chocada()` y `estrellarse()`, con su `franja()` roja de aviso y el estado "atontado"
  con estrellitas). Cada uno hereda y pone sus ataques: `antidisturbios.gd` (escudo por delante y doble por la espalda,
  porrazo, carga que le atonta si se estrella, silbato), `cocinero.gd` (a media distancia: abanico de cuchillos, lluvia
  de cuchillos con su marca en el suelo, sartén de aceite hirviendo y cuchillazo), `modista.gd` (se esconde entre los
  maniquíes de su tienda y se cambia de sitio con uno, alfileres, tijeretazo; enfadada, despierta 3 maniquíes:
  `maniqui_vivo.gd`, que solo se mueven si Johnny no los mira) y `mascota.gd` (embestida con franja roja; enfadada,
  tres seguidas que rebotan en las paredes y solo la marean al estrellarse en la última; salto: se agacha, vuela 0,8 s
  sin poder dársele, con su sombra creciendo en el suelo, y cae quitando 18 en un círculo; el dibujo del salto va por
  fotogramas —`DESPEGUE`, `ATERRIZA`— y la altura la pone el código, `ALTURA_SALTO`; mareada usa el golpe, con
  balanceo). Las explosiones les dan "de lleno" (`explosion.gd`); a Johnny la carga le pone el estado "tirado"
  (`estados.gd`).
- `bala_zombi.gd`, `proyectil.gd` (moco, lejía, ácido, molotov, bomba de aceite y la sartén del cocinero en
  parábola), `cuchillo.gd` (los cuchillos del cocinero, dibujados con código: lanzados en línea recta o cayendo sobre
  su marca; se quedan clavados un rato), `explosion.gd`.
- `persona.gd`: una persona dibujada con formas (drawHuman del JS), para los supervivientes (con lo de su
  oficio para los del centro comercial: chaleco, bata, cascos, moño, bigote, martillo).
- `mutaciones.gd`, `llamas.gd`, `quemado.gd` (el cuerpo que muere ardiendo), `particulas.gd`, `mancha.gd`.

**Partida y progreso**
- `edificios.gd`: la ficha de cada edificio (Apartamentos, Centro comercial) y el elegido en el menú; `MINIJEFES`,
  el nombre de cada minijefe y de su tienda. La partida sortea al empezar qué minijefe va en cada planta
  (`orden_jefes`, `jefe_de()`; si aún no está hecho, la portera) y `planta.gd` lo apunta en `planta.jefe` y `el_jefe`.
- `partida.gd`: la planta en juego (cambiar de sitio, puerta cerrada hasta limpiar el piso, llave o tarjeta y su
  guardia, portera, escaleras, dinero, pausa, fin), teclas de prueba y `--captura` (con `--edificio centro`, en el
  centro comercial, con el antidisturbios en la 1ª planta, u otro minijefe con `--jefe cocinero`, `--jefe modista` o
  `--jefe mascota` (`captura-jefe.png`: la mascota, saltando con su sombra); con `--edificio centro --fotos-tiendas`,
  sin penumbra, una foto de cada tienda y de la galería: `captura-tienda-<tipo>.png`, `captura-galeria-<n>.png`, y
  las de los peligros: `captura-peligro-<...>.png`).
- `alerta.gd`: los niveles de alerta (parte 8): la regla de cada nivel, los números (constantes) y lo que la partida
  le pregunta (`mas_zombis()`, `velocidad()`, `jefe_vida()`, `jefe_enfado()`, `botiquin()`, `guardia()`, `oido()`,
  `dolares_extra()`, `prob_rareza()`). El nivel de la partida, en `Alerta.nivel` (lo pone "Elige edificio"); la más
  alta abierta y la elegida de cada edificio, en el guardado (`alerta_max`, `alerta`). Con la Alerta 5 en los
  Apartamentos la llave la lleva un vecino (`planta.gd` lo apunta con `"llave": true` en sus zombis;
  `partida.gd`, `vecino_de_la_llave()`). La prueba: `--captura --alerta N` (`probar_alerta()`).
- `eventos.gd`: los eventos sorpresa (parte 8): una de cada cuatro plantas (nunca la última ni, dentro, la sala del
  jefe o la de mantenimiento), al pisar su pasillo, con un cartel grande: apagón (`Luz.evento` y las lámparas a
  `fuerza` 0), alarma de incendios (charcos `"agua"` de `charco.gd`, la lluvia y los cables con calambrazos: clases
  `Lluvia` y `Cable` de dentro), horda por las escaleras (tres oleadas por la puerta de las escaleras; los que
  quedan esperan en el pasillo; premio al final) y el vendedor ambulante (`vendedor.gd`: el dibujo con `Persona`,
  la mochila y la manta, y su puesto con el panel de `menus.gd`; paga con los dólares de la partida y luego con los
  ahorrados). Los números, en sus constantes. Lo engancha `partida.gd` en `nueva_planta()`, `montar()` (`recoger()`
  y `al_montar()`) y `poner_lugar()` (`etiqueta()`). La prueba: `--captura --evento X` (`probar()`).
- `talentos.gd` (árbol y compra de puntos), `objetos.gd` (los 26 objetos, los que se usan desde el inventario, `USABLES`: de
  momento el botiquín, que no entra en recetas ni va al baúl; mochila, baúl de 32 casillas, lo que
  sueltan los zombis: en los Apartamentos, los 17 de siempre; en el centro comercial, la lista de la tienda donde cae
  el zombi, `TIENDAS`, y en el pasillo, la de una tienda cualquiera), `recetas.gd` (24 recetas y rarezas: 15 de los
  Apartamentos, 6 que mezclan los dos edificios y 3 solo del centro), `billete.gd`, `minimapa.gd` (con el técnico
  rescatado, `camaras`: un puntito por zombi en cada sala). La prueba
  `--captura` cuenta el reparto de cada sitio (`probar_objetos` de `partida.gd`) y saca `captura-objetos-nuevos.png`,
  `captura-banco-todo.png` y `captura-baul-todo.png`; luego prueba cada arma nueva contra zombis (`probar_recetas`)
  y saca `captura-arma-<receta>.png`.
- `guardado.gd`: el guardado entre partidas.
- `logros.gd`: la lista de logros (añadir uno = una línea en `LISTA`) y sus avisos.
- `historia.gd`: el texto del dosier de cada edificio (`DOSIERES`: Apartamentos y centro comercial), la hoja de
  papel y las noticias de Canal 8 (`NOTICIAS`, con cuándo sale cada una; las vistas en `noticias_vistas` del
  guardado). La última página del centro no la lleva un muerto: la suelta el gerente al caer (`del_jefe`; la
  partida la enseña con `pagina_del_jefe()`). También el guiño de la cafetera (`CAFETERA`: lo dice la farmacéutica,
  `supervivientes.gd`). Para cambiar la historia se edita aquí, sin tocar los `id`.
- `supervivientes.gd` (el superviviente encerrado en su baño, la horda, los vecinos de mantenimiento) y
  `aliado.gd` (cada superviviente: sigue a Johnny, dispara o cura, fuerza la cerradura). En `DATOS`, los seis:
  los tres de los Apartamentos y los tres del centro comercial, con su tienda y su habitación (`planta.gd` pone
  su tienda en su planta: `Planta.tienda_fija`), sus gritos, su sitio en la sala (`casa`) y su mejora. La de la
  farmacéutica: `botiquin_al_empezar()` (lo llama `partida.gd` al empezar) mete un botiquín en la mochila, que se
  usa desde el inventario (`partida.usar_objeto`). El guiño de la cafetera (`guino_cafetera`: la primera vez que la farmacéutica está en la sala; `cafetera` en el
  guardado). Lo suyo al acompañarte: disparar, curar, martillazos, descarga que aturde y charcos a
  medias (`johnny.gd` pregunta a `Aliado.charcos_a_medias`).
- `escolta.gd`: el rescate propio de la farmacéutica (llevarla herida hasta las escaleras, con zombis saliendo por
  las puertas del pasillo); la cuelga `supervivientes.gd` y `partida.gd` le pregunta antes de cruzar una puerta.
- `averia.gd`: el rescate propio del técnico (bajar la palanca del cuadro y aguantar a oscuras, con zombis entrando
  por las habitaciones de la tienda, mientras arregla el cable del agua); igual que la escolta. Su prueba también
  prueba su mejora (el minimapa con los zombis y las pantallas de la sala).
- `barricada.gd`: el rescate propio del ferretero (la puerta de su almacén con tablas; al limpiar la tienda se
  cierra la entrada y hay que defender la puerta mientras las quita, con zombis entrando por las habitaciones o la
  entrada). Lo que aporrean los zombis es un punto invisible delante de la puerta (`Diana`, en el grupo "presa").
  La cuelga `supervivientes.gd`, que también pone su puesto en la sala (`poner_puesto`).
- `sonido.gd` (autoload): efectos sintetizados como en `src/sfx.js` y la música (`Sonido.tocar("compra")`,
  `Sonido.musica("jefe")`).
- `sala.gd`: la sala de pruebas (hornea la navegación, tandas mezcladas, F2-F7 y P, su `--captura`).

**ui/**
- `tema.gd` (aspecto de menús y HUD), `hud.gd`, `menus.gd`, `menu_principal.gd` (menú y "Elige edificio"), `opciones.gd` (pantalla de Opciones: modo de atacar, música, sonido, ajustes del móvil y tabla de controles para cambiarlos; los cambios los pone y guarda `scripts/controles.gd`), `tactil.gd` (controles del móvil; su tamaño, transparencia y vibración se leen de `ajustes` con `Tactil.ajustar()`).
- `ordenador.gd`: la pantalla de ConserjeOS. `inventario.gd`: inventario (ponerse, usar y tirar), baúl y banco. `puesto.gd`: la ventanita
  del puesto del ferretero (munición, molotovs y granadas por dólares ahorrados).
- `tele.gd`: la tele de las noticias, dibujada con código. `ambiente.gd`: viñeteado, pantalla roja con poca vida y escarcha con frío.
- `botones.gd` (autoload): el saltito de los botones.

**mapa/**
- `apartamento.gd` (genera un apartamento como `apartment.js`), `tienda.gd` (genera una tienda del centro
  comercial, con el mismo tipo de plano), `planta.gd` (la planta, sus zombis, la sala de mantenimiento y la de
  exposición), `catalogo.gd` (muebles de cada sala; en las tiendas, por tipo: "tienda-<tipo>"; la tienda de un minijefe, si
  tiene la suya: "jefe-modista"), `muebles.gd`
  (dónde va cada uno; en las salas de venta, también filas en medio: `islas`), `mueble.gd` (monta uno).
- `mapa.gd`: monta un sitio (suelos, tapas, caras de pared, choques, muebles, peligros, niebla, navegación). Los suelos y
  paredes de cada sala salen de `ESTILO_DE` (pisos), `ESTILO_TIENDA` (tiendas) y `PASILLOS` (el pasillo de cada
  edificio); en el centro comercial pone además los escaparates, los neones y los restos sueltos.
  `cara_pared.gd`, `puerta.gd`, `puerta_bano.gd` (la del superviviente), `neon.gd` (el letrero de neón de una tienda).
- `ordenador.gd` (la mesa), `arrimable.gd` (baúl y banco), `armarito.gd` (botiquín), `cientifico.gd` (el
  científico muerto con su página; con bata o, si no es científico, con su ropa), `cafetera.gd` (la de la sala de
  mantenimiento, dibujada con código), `camaras.gd` (las pantallas de las cámaras de seguridad, detrás del técnico,
  cuando ya vive en la sala), `mostrador.gd` (el del puesto del ferretero, dibujado con código; al arrimarse por
  delante abre `ui/puesto.gd`).

**luz/**: `luz.gd` (penumbra de cada sitio, con lo de más de la tienda de electrónica y del apagón; luz de Johnny, fogonazos), `lampara.gd`, `fuego.gd`.

## assets/

- `sprites/`: copia de los sprites del JS (`.png` + `.json` + `manifest.json`); los `.tres` de al lado son sus
  animaciones. Hoja nueva → `py tools/hacer_frames.py assets/sprites/zombi-normal`.
- `musica/`: tramos (`menu-*`, `explorar-*`, `jefe-*`.ogg) grabados del JS con `node tools/grabar_musica.mjs`
  (necesita el JS y ffmpeg). Si se graban más, cambiar `TRAMOS` en `sonido.gd`.
- `ui/`, `fuentes/`: HUD y menús del JS (la fuente es nítida a 16 y 32). `tiles/`: texturas para los TileSets.
- `sources/`: originales (lleva `.gdignore`). `pixellab.json`: todo lo generado en PixelLab.

## tools/

`hacer_frames.py` (hoja → animaciones); para los zombis nuevos, las herramientas del JS copiadas aquí: `piel.py`
(la piel a verde; admite otro tono de origen, la fila de los zapatos y la saturación máxima), `bajar_zip.py` y `bajar.py` (bajar de PixelLab), `hoja.py` (hoja de
revisión) y `zombi.py` (+ `png.py`: monta la hoja del zombi; con `"sangre_en_todo"` oscurece la sangre también en
el dibujo quieto y con `"sueltos"` quita los chorros que salen volando, en `assets/sources/<zombi>/zombi.json`); `jefe_hoja.py` (las vistas y animaciones de PixelLab de un minijefe de 72 → hoja y `.tres`:
`py tools/jefe_hoja.py antidisturbios-72 jefe-antidisturbios`, `cocinero-72 jefe-cocinero`, `modista-72 jefe-modista` o
`mascota-72 jefe-mascota`; las animaciones de cada uno, en su ficha `JEFES` (con la lista y los fotogramas por
segundo; la embestida de la mascota lleva un 5.º dato: quitar el primer fotograma); alinea por los pies los lienzos
de PixelLab, borra las motas sueltas, oscurece la sangre si la ficha lo pide y dice el `offset` del Sprite; lo que
falte, con la vista quieta), `texturas_bano.py`, `importar.py` (muebles nuevos → sprites; lee
`catalogo.gd`), `textura_suelo.py`, `textura_pared.py` y `textura_tapa.py` (suelos, paredes y tapas: ver `FONDOS.md`),
`icono_alerta.py` (el triángulo de los niveles de alerta), `guias_centro.py` (bocetos para pedir a PixelLab muebles rectos, y quitarles el fondo), `centro_sprites.py`
(escaparates y restos del centro comercial → sprites), `despixelar.py` (de PixelLab y Gemini), `dibujos_7b.py` (baúl, banco y armarito), `objetos16.py`
(los 26 objetos a 16×16), `icono_dosier.py`, `icono_noticias.py`, `hacer_casillas.py` (marcos de las casillas del HUD), `ver_dibujos.tscn` (foto de los dibujos hechos con
código) y `probar_sonido.gd` (guarda los efectos en `tools/efectos/*.wav`, no van a git).

## docs/ (del juego JS)

`PIXEL_ART.md`, `PIXELLAB.md`, `ZOMBIS.md`, `FONDOS.md`, `MAPA.md`: hablan del JS (`src/…`); valen para las ideas y
los números.
