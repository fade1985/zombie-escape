# Controles y teclas de prueba

## Jugar

Los de serie del mando siguen lo habitual en juegos de dos sticks: los gatillos para atacar (RT) y lanzar
(LT), y esquivar también en LB para no soltar el stick derecho al apuntar.

- **Moverse:** WASD, flechas o stick izquierdo. **Esquivar:** Espacio, Mayús, A o LB.
- **Opciones** (menú principal y pausa): modo de atacar (se guarda), música, sonido, las **Ayudas** (pestaña propia, Sí/No, se guardan en `ajustes` y se notan al momento: *Vida entera*, sin tercios; *Pistola sin fin*, sin gastar balas; *Lanzar apuntando solo*, los lanzables al zombi más cercano a la vista; no cambian récords) y la lista de controles, que se pueden cambiar (pulsar la casilla y luego la tecla o el botón; si ya la usaba otra acción, se intercambian; "Restablecer controles" vuelve a los de serie). **F1**, **C** o la cruceta abajo también cambian el modo de atacar: *asistido* (apunta y ataca solo, como en el JS), *hacia donde mira* (J, clic o
  RT) y *libre* (ratón + clic, o stick derecho).
- **Q** / rueda / Y: cambiar entre las dos armas. **R** / X: recargar.
- **E**, clic derecho o LT (mantener para apuntar, soltar para lanzar): molotov o granada; **F** / RB cambia entre ellos.
- **Tab**, **I** o Select: inventario (las armas, las guardadas y la mochila; ponérselas y tirar al suelo). Los
  objetos de curar (el botiquín de la farmacéutica, las vendas de la farmacia y el bocadillo del supermercado) se
  usan desde aquí: al elegir uno, la marca salta a **Usar** (con el mando, A dos veces).
- **Esc** / Start: pausa. Los menús van con ratón, flechas + Intro o mando (cruceta o stick, A pulsar, B volver).
- **Elige edificio:** debajo de cada tarjeta, **<** y **>** cambian el nivel de alerta (de los abiertos; se
  recuerda el último elegido). Completar el edificio con una alerta abre la siguiente, hasta la 5. Debajo, el botón
  **Reto del día**: ese edificio generado igual para todo el mundo ese día y con la regla rara de hoy (la misma en
  los dos edificios; sale debajo del botón con tu mejor marca de hoy). Va sin alerta, no abre ninguna y no cuenta
  como edificio completado; los dólares, como siempre.

## Teclas de prueba

- **1-6**: poner cualquier arma.
- **F2 a F7**: un zombi de cada tipo (normal, lento, rápido, explosivo, tentáculos, venenoso). **V**: un vigilante y
  **B**: una dependienta (los del centro comercial). **P**: la portera. **K**: el antidisturbios. **G**: el cocinero.
  **T**: la modista. **J**: la mascota (de la Juguetería). **L**: el gerente (el jefe final de la azotea).
  Los minijefes de los Apartamentos (`docs/JEFES_APARTAMENTOS.md`), con los números: **7**, el Glotón; **8**, el Gymbro; **9**, el jefe de bomberos;
  y **0**, el científico jefe (el doctor Salas, el jefe final de su azotea).
- **N** (los dos edificios tienen azotea): derecho a la azotea, sin subir planta a planta. En **Elige edificio**, la N abre todos
  los edificios (el centro comercial sin completar los Apartamentos) hasta cerrar el juego; no se guarda.
- **M**: recuadro de mutaciones. **O**: soltar un objeto al azar (de los que salen donde estás). **U**: uno de cada
  objeto al baúl y todas las recetas aprendidas, para probar el banco de trabajo. **F8**: Colecciones al completo
  (todo encontrado, creado y visto), para probar el programa del ordenador. **Y**: soltar a tus pies el
  papel de una receta que aún no tienes (como al morir un jefe). **X**: un científico muerto a tus pies (cada X, el de la
  página siguiente, con su piel y su pelo); su página se coge pero no se guarda. **Z**: el siguiente traje de
  Johnny (`trajes.gd`; al final vuelve al conserje), sin guardarlo.
- **F9**: sala de exposición (todos los muebles con sus variantes y todos los zombis con sus ropas) y vuelta.
- **F10**: quitar y poner la penumbra. **H**: apartamento del superviviente ya sin zombis (rescate y horda).
  En el centro comercial, cada H trae al siguiente de sus tres (ferretero, farmacéutica, técnico): rehace
  la planta con su tienda y te lleva a ella, ya sin zombis. Con uno ya rescatado en la partida, no hace nada.

**Pruebas sin jugar** (se añaden detrás de `--path . -- --captura`; ver CLAUDE.md):
- `--edificio centro`: en el centro comercial (al final, la azotea: `captura-azotea.png`, `captura-gerente.png`
  —el gerente lanzando contratos—, `-maletinazo` y `-trabajar`, `captura-gerente-jeringa.png` y
  `captura-gerente-muta.png` —se pincha y muta—, `captura-mutado.png` —los latigazos— y
  `captura-mutado-embestida.png`, `captura-azotea-entera.png`, `captura-azotea-incendios.png` y
  `captura-helicoptero.png` —al caer, el helicóptero de Velaria—). `--fotos-tiendas`: una foto de cada tienda y de los peligros
  (la joyería sale siempre en la 1ª planta).
- `--alerta N` (1 a 5): en vez de la prueba larga, la de los niveles de alerta: dice en la terminal los números de
  cada regla (zombis, velocidad, jefe, botiquín, oído, rarezas del banco, guardia o vecino de la llave) y saca
  `captura-alerta.png` (el aviso del principio), `captura-alerta-llave.png` (el guardia o, en los Apartamentos, el
  vecino de la llave) y `captura-alerta-fin.png`; la foto de "Elige edificio" sale con las alertas abiertas.
- `--evento X` (`apagon`, `incendio`, `horda` o `vendedor`): en vez de la prueba larga, la de ese evento sorpresa en
  la planta baja: dice en la terminal cuántos salen en 2000 partidas sorteadas y lo que pasa (luces apagadas,
  calambrazos, oleadas y premio, compras con lo que queda de dólares) y saca `captura-evento-<X>.png` (el cartel) y
  las suyas (`-piso`, `-cable`, `-premio`, `-puesto`, `-comprado`). Sin `--evento`, la prueba va sin eventos.
- `--reto si` (o `--reto oscuras`, `--reto cuerpo`, `--reto curas`, `--reto rapidos`, `--reto cristal`,
  `--reto llena` o `--reto oido`, para forzar esa regla en vez de la de hoy): en vez de la prueba larga, la del reto
  del día: comprueba que la 1ª planta sale igual dos veces con la semilla de hoy, dice en la terminal lo que cambia
  cada regla y cómo queda el primer piso con la que se juega, y saca `captura-reto-tarjeta.png` (la tarjeta con el
  botón y una marca inventada), `captura-reto.png` (el aviso), `captura-reto-piso.png`, `captura-reto-derrota.png`
  y `captura-reto-fin.png` (los carteles del final, con la marca); al final mira el guardado.
- `--joyeria` (con `--edificio centro`): en vez de la prueba larga, la de la cámara acorazada de la joyería, que sale
  en la planta baja: la puerta blindada cerrada (`captura-joyeria-camara.png`), el lector sin tarjeta y la alarma con
  sus zombis (`captura-joyeria-alarma.png`), la cuenta adelantada y la puerta abierta (`captura-joyeria-abierta.png`),
  la vitrina del premio dentro (`captura-joyeria-premio.png`) y lo que pasa al pisarla, el guardia que suelta la
  tarjeta dorada junto a la suya (`captura-joyeria-dorada.png`) y la apertura con ella.
- `--trajes`: en vez de la prueba larga, la de los trajes de Johnny (`trajes.gd`): en la sala de mantenimiento,
  Johnny de conserje y una copia con cada traje, cada una con una hoja distinta (`captura-trajes.png`), y el chándal
  con el bate dando un golpe andando (`captura-trajes-golpe.png`); en la terminal, lo que se guarda y la vuelta de
  la tecla Z. Luego cómo se consiguen: lo que sortea la tienda de ropa (en la terminal), el delantal en el suelo
  (`captura-trajes-suelo.png`), Johnny lo pisa y se lo pone (`captura-trajes-cogido.png`), se arrima a la taquilla
  y elige en su ventanita (`captura-taquilla.png`), y la modista cae y suelta uno que falta
  (`captura-trajes-modista.png`).
- `--gastro`: en vez de la prueba larga, la del vómito de la mutación Gastroenteritis (`mutaciones.gd`): en un
  apartamento, junto a un tabique con un zombi justo detrás, comprueba en la terminal que el vómito no sale hacia él,
  que su charco pegado al tabique no lo quema (pero sí a uno de este lado) y que, con otro zombi más lejos pero a la
  vista, sale a ese (`captura-gastro-vuelo.png`, `captura-gastro-charco.png`). Cada línea dice lo esperado.
- `--caza`: en vez de la prueba larga, la de la caza del acompañante (`aliado.gd`, `cazar`): en un apartamento, solo el
  ferretero con Johnny quieto; con un zombi en otra habitación (pared en medio) se queda en la fila; con otro a unos 250
  a la vista, deja la fila y va a por él (`captura-caza-va.png`), lo mata a martillazos y vuelve a su puesto
  (`captura-caza-vuelve.png`). Cada línea de la terminal dice lo esperado.
- `--porqueria` (con `--jefe gloton`): en vez de la prueba larga, la de la habitación del Glotón (`peligros/porqueria.gd`):
  la monta sin él y cuenta en la terminal los muebles (solo lámparas), la parte del suelo sucia, que donde aparece Johnny y el
  centro están limpios y lo pegado a las paredes sucio (y el grosor de la franja), lo que pierde sobre la porquería en
  1 s y que en una casilla limpia no pierde nada, las salpicaduras de las paredes y las luces del resplandor
  (`captura-porqueria.png`, Johnny encima; `captura-porqueria-medio.png`, el óvalo limpio desde el medio). Cada línea
  dice lo esperado.
- `--presentacion` (con `--jefe X`, si se quiere): en vez de la prueba larga, la de la presentación del jefe
  (`ui/presentacion.gd`): entra en su piso y, a mitad de la presentación, comprueba en la terminal el zoom de la
  cámara sobre él, que Johnny está quieto y sin poder recibir daño, que el jefe grita, el nombre en pantalla y la
  barra oculta (`captura-presentacion.png`); al acabar, que todo ha vuelto. Cada línea dice lo esperado. (En el
  juego, mientras dura la presentación no responden la pausa, el inventario ni las teclas de prueba.)
- `--fotos-luz`: en el apartamento con más habitaciones, todo descubierto y sin zombis, una foto por habitación
  con Johnny mirando un tabique que tiene otra habitación detrás (`captura-luz-<n>.png`): la linterna y las
  lámparas no tienen que alumbrar el suelo del otro lado.
- `--fotos-ayudas`: pone en Sí las ayudas de Opciones (`captura-ayudas-opciones.png`), prueba la vida y la pistola
  y adónde caería un lanzable, sin ayudas y con ellas (lo cuenta en la terminal), y saca el HUD (`captura-ayudas-hud.png`)
  y un molotov volando al zombi (`captura-ayudas-lanzar.png`). Las deja en No.
- `--fotos-supervivientes`: los tres supervivientes del edificio con su hoja de PixelLab (con `--edificio centro`, el
  ferretero, la farmacéutica y el técnico): de vecinos en la sala (`captura-supervivientes-sala.png`) y, en un piso,
  andando tras Johnny (`-andar`), haciendo lo suyo (`-accion`: disparo, jeringa, martillazo, descarga) y el último
  caído (`-caido`).
- La prueba larga saca también las de Colecciones: `captura-escritorio-nuevo.png` (el icono con el aviso de
  «¡NUEVO!»), `captura-colecciones.png` (los objetos del edificio), `captura-bestiario.png` (la ficha del vecino) y
  `captura-bestiario-falta.png` (la del gerente, sin ver), y cuenta en la terminal lo encontrado, creado y visto.
  También `captura-vendas.png` (el inventario con las vendas elegidas) y, en la terminal, lo que curan las vendas y
  el bocadillo al usarlos.

## La sala de mantenimiento

La partida (`escenas/partida.tscn`) empieza ahí, tras el menú principal (`escenas/menu_principal.tscn`).
- Mesa del ordenador: **ConserjeOS** (puntos de talento, árbol de talentos, tienda de armas, logros, Dosier VD-7,
  Noticias de Canal 8 y Colecciones: lo encontrado, creado y leído de cada edificio, y el bestiario).
- A la derecha del baúl, la **taquilla** de Johnny: arrimarse para elegir el traje (los de la tienda de ropa del
  centro comercial que ya tengas; se queda puesto). Con el ratón o el dedo, flechas e Intro (o 1 a 5) o el mando
  (cruceta y A); Esc o B cierra.
- A su derecha, el **baúl** (las armas creadas para la partida); a su izquierda, el **banco de trabajo**: todas
  las recetas en hojas de papel (las que aún no tienes, con un «?»). Se toca una y, si tienes lo que pide (en la
  mochila, el baúl o la mano), se crea el arma. El molotov viene aprendido; las demás las suelta cada jefe al morir
  (los de planta y el de la azotea), en un papel que hay que recoger. Lo aprendido no se pierde nunca.
- Los baños tienen un armarito con botiquín. Los supervivientes rescatados esperan a la derecha del ordenador (los
  del centro comercial, en una segunda fila, debajo): arrimarse a uno para que te acompañe. Detrás del técnico,
  cuando ya vive ahí, las pantallas de las cámaras de seguridad: desde entonces el minimapa enseña los zombis.
- El **puesto del ferretero** (cuando ya vive ahí): arrimarse a su mostrador por delante para comprar munición
  ($2), molotovs ($3) y granadas ($4) con los dólares ahorrados. Con el ratón o el dedo; con flechas e Intro o
  las teclas 1, 2 y 3; con el mando, la cruceta y A. Esc o B cierra. Para que te acompañe, rodear el mostrador.
- La sala de pruebas de las fases 1-3: abrir `escenas/salas/bano.tscn` y **F6**.

## Móvil (táctil)

`scripts/ui/tactil.gd`, solo mientras se juega. Joystick izquierdo (se toca en la mitad izquierda); abajo a la
derecha, según el modo: esquivar, más grande (asistido; las armas y lanzar, más cerca a su alrededor), botón de
atacar (hacia donde mira) o joystick derecho (libre). En arco: esquivar (salvo en asistido), las dos armas (tocar la otra la saca; tocar la de fuego en la mano recarga) y lanzar (arrastrar y soltar),
con el botoncito de cambiar lanzable. Bajo el minimapa: modo, inventario y pausa. En los menús el dedo hace de
ratón. En táctil la pantalla se agranda sin redondear (si no, en móviles con muchos píxeles se quedaría en 1×).

En Opciones → General, solo en táctil, apartado **Móvil** (se guarda en `ajustes` y se nota al momento, también
al volver de la pausa):
- **Tamaño de los botones:** Pequeño 0,8 · Normal 1 · Grande 1,2 · Muy grande 1,4. Cambia el dibujo y la zona de
  toque de los joysticks, el arco y los botones de bajo el minimapa (más de 1,4 choca con el minimapa).
- **Transparencia:** 100 %, 75 %, 50 % o 30 % (fondos, bordes e iconos; el "gira el móvil" no).
- **Vibración:** Sí/No. Una vibración de 35 ms al recibir un golpe y al esquivar (`Input.vibrate_handheld`; en la
  web usa la del navegador, que en iPhone no hay).

Probarlo en el navegador integrado: menos de 768 de ancho (p. ej. 740×360) y toques con `TouchEvent` desde
JavaScript (los clics llegan como ratón).

## Guardado

`%APPDATA%\Godot\app_userdata\Zombie Escape\guardado.json` (borrarlo = empezar de cero); la prueba con `--captura`
usa `guardado-prueba.json`. En la web va en el navegador (IndexedDB).
