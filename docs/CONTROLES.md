# Controles y teclas de prueba

## Jugar

Los de serie del mando siguen lo habitual en juegos de dos sticks: los gatillos para atacar (RT) y lanzar
(LT), y esquivar también en LB para no soltar el stick derecho al apuntar.

- **Moverse:** WASD, flechas o stick izquierdo. **Esquivar:** Espacio, Mayús, A o LB.
- **Opciones** (menú principal y pausa): modo de atacar (se guarda), música, sonido, las **Ayudas** (pestaña propia, Sí/No, se guardan en `ajustes` y se notan al momento: *Vida entera*, sin tercios; *Pistola sin fin*, sin gastar balas; *Lanzar apuntando solo*, los lanzables al zombi más cercano a la vista; no cambian récords) y la lista de controles, que se pueden cambiar (pulsar la casilla y luego la tecla o el botón; si ya la usaba otra acción, se intercambian; "Restablecer controles" vuelve a los de serie). **F1**, **C** o la cruceta abajo también cambian el modo de atacar: *asistido* (apunta y ataca solo, como en el JS), *hacia donde mira* (J, clic o
  RT) y *libre* (ratón + clic, o stick derecho).
- **Q** / rueda / Y: cambiar entre las dos armas. **R** / X: recargar (de la munición de su tipo: balas de pistola,
  que también gasta la MP5; cartuchos; gasolina, el lanzallamas; bidones de ácido, el lanza ácido; baterías, la
  pistola eléctrica, y cada una le llena el cargador). La munición va en 8 huecos (en cada uno, dos cargadores; la
  gasolina, el ácido y las baterías, 3): con todos llenos no se coge más. Una caja de munición da un cargador del arma
  a distancia de la mano (si es el lanzallamas, el lanza ácido o la pistola eléctrica, de la de repuesto).
- **E**, clic derecho o LT (mantener para apuntar, soltar para lanzar): lo que lleva a mano para lanzar (3 huecos; al
  empezar, el molotov y la granada); **F** / RB cambia entre ellos. Hay 8 huecos más de repuesto: ahí va lo que no cabe
  en la mano, y cuando se acaba uno de la mano, su hueco lo ocupa el primero de repuesto.
- **Tab**, **I** o Select: inventario «todo a la vista». Johnny grande en medio; a su izquierda las armas de cuerpo a
  cuerpo y a su derecha las de distancia (arriba la de la mano, abajo la de repuesto, con las balas del cargador); debajo,
  los 3 arrojables a mano (**F** cambia el que se lanza, también aquí). En medio, la mochila, la munición y los
  arrojables de repuesto (8 de cada); a la derecha, la ficha de lo elegido con sus botones: **Ponérmela**, **Usar**,
  **A la mano**, **Al repuesto** y **Tirar al suelo** (el arma de la mano solo se tira si llevas otra de repuesto, que
  pasa a la mano). Con las flechas o el mando la ficha sigue a la marca; Intro o A la lleva al botón principal (A dos
  veces y hecho), **X** o **Supr** tira, **Y** hace lo del botón principal y B, Esc o Tab cierran; con el ratón, se
  toca. Johnny
  lleva como mucho dos de cada tipo: la de la mano y una de repuesto. Al comprar o sacar otra, va a la mano y la que
  llevaba pasa al repuesto (o, si ya tiene una, se queda en el suelo); la que coge del suelo va al repuesto si está
  libre. Los
  objetos de curar (el botiquín de la farmacéutica, las vendas de la farmacia y el bocadillo del supermercado) se
  usan desde aquí, con **Usar**.
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
- **Mayús + 7, 8, 9 o P** (en los Apartamentos): derecho a la habitación de ese minijefe (el Glotón, el Gymbro, el jefe
  de bomberos o la portera) para pelear con él sin jugar hasta él: rehace la planta que le tocó en el sorteo de la
  partida y Johnny entra por la puerta; el jefe sale como siempre, con su presentación. Funciona en cualquier momento
  (`ir_al_jefe` en `partida.gd`). Al pulsar Mayús, Johnny rueda (es la tecla de esquivar): no pasa nada.
- **N** (los dos edificios tienen azotea): derecho a la azotea, sin subir planta a planta. En **Elige edificio**, la N abre todos
  los edificios (el centro comercial sin completar los Apartamentos) hasta cerrar el juego; no se guarda.
- **M**: recuadro de mutaciones. **O**: soltar un objeto al azar (de los que salen donde estás). **U**: uno de cada
  objeto al baúl y todas las recetas aprendidas, para probar el banco de trabajo. **F8**: Colecciones al completo
  (todo encontrado, creado y visto), para probar el programa del ordenador. **Y**: soltar a tus pies el
  papel de una receta que aún no tienes (como al morir un jefe). **X**: un científico muerto a tus pies (cada X, el de la
  página siguiente, con su piel y su pelo); su página se coge pero no se guarda. **Z**: la siguiente skin de
  Johnny (`skins.gd`; al final vuelve al conserje), sin guardarla.
- **F9**: sala de exposición (todos los muebles con sus variantes y todos los zombis con sus ropas) y vuelta.
- **F11** (en la planta baja): sala de pruebas de armas (`sala_armas.gd`) y vuelta. En el centro, una diana: un zombi
  normal que no pierde vida (ni sale su barra), no ataca y vuelve a su sitio si lo empujan, para probar desde todas
  las direcciones. Se entra con la pistola; **coma** y **punto** pasan por todas las
  armas de la tienda, también el lanzallamas, el lanza ácido y la pistola eléctrica (las 1-6 y Q también valen). La munición no se acaba, pero hay que recargar (el lanzallamas se llena sin gastar gasolina, y la pistola eléctrica, sin gastar baterías).
  En el suelo, las líneas de ayuda: el alcance (círculo blanco; cuerpo a cuerpo, el abanico del golpe), a quién apunta
  (amarillo), por dónde irá la bala (azul a rayas, desde la boca del arma hasta el zombi que pille la línea de tiro), el círculo de cada zombi donde le da la
  bala (rojo) y el camino de cada bala (verde si da, naranja si pasa por el lado de la diana, roja con una X si choca o
  se le acaba el alcance). Arriba a la izquierda, la ficha del arma (con los talentos puestos) y el recuento:
  disparos, aciertos, por qué falla, daño por segundo y cuántos zombis normales habría matado (con una vida de mentira
  de 30; y en cuánto tiempo y con cuántos golpes el último). **Retroceso** pone el
  recuento a cero (también cambiar de arma); el **guion** esconde el panel. Al salir, Johnny vuelve a llevar las armas
  y las balas con las que entró. En el navegador, F11 es también la pantalla completa.
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
- `--evento X` (`apagon`, `incendio` u `horda`): en vez de la prueba larga, la de ese evento sorpresa en la planta
  baja: dice en la terminal cuántos salen en 2000 partidas sorteadas y lo que pasa (luces apagadas, calambrazos,
  oleadas y premio) y saca `captura-evento-<X>.png` (el cartel) y las suyas (`-piso`, `-cable`, `-premio`). Con uno
  que no existe, lo dice y se cierra. Sin `--evento`, la prueba va sin eventos.
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
- `--skins`: en vez de la prueba larga, la de las skins de Johnny (`skins.gd`), en la sala de mantenimiento y sin
  ninguna: la taquilla no deja ponerse el portero sin tenerlo (`captura-skins-taquilla-sin.png`, todas con «???» y
  su pista); la portera cae y lo desbloquea, con su aviso
  (`captura-skins-desbloqueo.png`), y una segunda vez ya no es nuevo; el Glotón cae y desbloquea el glotón
  (`captura-skins-desbloqueo-gloton.png`), el Gymbro, el gymbro (`captura-skins-desbloqueo-gymbro.png`), y el jefe
  de bomberos, el bombero (`captura-skins-desbloqueo-bombero.png`); en la taquilla se eligen
  (`captura-skins-taquilla.png` y `captura-skins-taquilla-<id>.png` del glotón, el gymbro y el bombero, estas ya
  puestas, para ver que su efecto cabe entero), Johnny cambia de hoja y se guarda; la vuelta de la tecla Z; la cara
  en las 8 direcciones y con las seis armas, al lado del conserje de siempre (`captura-skins-caras.png`, el
  portero, y `captura-skins-caras-<id>.png`, las demás); ponérsela andando no le corta el paso; el daño de la fregona, × 4 con el portero
  (y el del bate, igual), contado y con un golpe de verdad; el del gymbro, × 3 con la fregona, el bate y el cuchillo, y
  × 1 con las de fuego, contado y con un golpe de verdad (con el bate); el
  del bombero, × 3 con el lanzallamas y el molotov, y × 1 con
  las seis de siempre, contado y de verdad a un zombi quieto (el disparo y lo que sigue ardiendo, y un
  molotov de verdad); el bombero, inmune al fuego: pisando fuego, en un charco de molotov (`captura-skins-bombero-fuego.png`),
  con los molotovs, el cono y las bolas del jefe de bomberos, sin la skin pierde vida y sigue ardiendo y con ella no
  (su hachazo, sí le quita); y el poder del glotón: el zombi que le da un zarpazo muere,
  el Gymbro pierde un 10 % con un golpe suyo y con una pesa suya aunque tenga la armadura, y sin la skin, siendo
  invulnerable o con un daño que no es de nadie, nada. Cada línea de la terminal dice lo esperado.
- `--baul`: en vez de la prueba larga, la de guardar a mano en el baúl lo de la mochila (`ui/inventario.gd`): con
  gasolina, un trapo, vendas, alcohol y despertadores en la mochila, Johnny se arrima al baúl y comprueba en la terminal que
  se abre, que «Guardar de la mochila» enseña la mochila (`captura-baul-mochila.png`, con la gasolina elegida), que
  «Guardar» mete toda la casilla en el baúl, que las vendas no se guardan, que con el baúl lleno solo caben más de lo
  que ya tiene, y que «Guardar todo» mete lo demás (`captura-baul-guardado.png`, el baúl al volver). Cada línea
  dice lo esperado. Deja el baúl del guardado de prueba como estaba.
- `--repuesto`: en vez de la prueba larga, la de las dos armas de cada tipo (`partida.llevar_arma`): compra en la
  tienda del ordenador un lanza ácido y una pistola eléctrica (el lanza ácido se queda en el suelo), el bate y el
  cuchillo (el bate se queda en el suelo), no deja comprar la pistola que lleva de repuesto, tira la fregona y vuelve a
  coger el bate (al repuesto). Cada línea dice lo esperado; saca `captura-repuesto.png`. Deja los dólares como estaban.
- `--municion`: en vez de la prueba larga, la de la munición por tipos y los arrojables (`Armas.MUNICION`, `johnny.gd`,
  `lanzables.gd`): la MP5 trae y gasta las mismas balas que la pistola, la escopeta trae cartuchos, la gasolina y el
  bidón de ácido ocupan huecos de munición (no de la mochila; en el baúl sí se guardan), con el lanzallamas en la mano
  la caja es para la de repuesto, con el hueco lleno la caja ya no va, y las balas tiradas quedan en una caja que las
  devuelve; los arrojables, 3 a mano y 8 de repuesto (la mano llena manda al repuesto, al acabarse uno entra el primero
  de repuesto, F, **A la mano** y **Al repuesto**, el molotov del suelo con el máximo). Cada línea dice lo esperado.
  Fotos: `captura-municion.png` (el inventario), `captura-municion-arrojables.png` y `captura-municion-hud.png`.
- `--inventario`: en vez de la prueba larga, la de la pantalla del inventario «todo a la vista» (`ui/inventario.gd`),
  con un poco de todo y la skin del bombero: al abrir, la ficha del arma de la mano; la flecha abajo lleva la marca a
  la escopeta de repuesto y la ficha la sigue; Intro salta a **Ponérmela** e Y del mando se la pone; Supr tira un
  trapo; tirar el arma de la mano pone la de repuesto; F cambia el arrojable; **A la mano** con la mano llena; Esc
  cierra. Luego, las otras pruebas que usan el inventario: las vendas y el botiquín de la farmacéutica. Cada línea dice lo esperado. Fotos: `captura-inventario-nuevo.png`, `-escopeta`, `-objeto`,
  `-municion`, `-arrojable`, `-pistola_electrica` y `-lanzallamas` (la ficha más llena y la de depósito).
- `--ascensor`: en vez de la prueba larga, la del ascensor (`partida.gd`, `arreglar_ascensor`): comprueba en la
  terminal que en la planta baja no se arregla, que en la 1ª planta sigue averiado hasta que cae el jefe, que al
  salir al pasillo Johnny dice que lo ha arreglado (`captura-ascensor-arreglado.png`), que baja a la sala de
  mantenimiento (`captura-ascensor-sala.png`), que ahí se guarda en el baúl lo de la mochila
  (`captura-ascensor-baul.png`), que la puerta de la sala devuelve a la 1ª planta delante del ascensor, que en la
  2ª planta vuelve a estar averiado y que la azotea no tiene. Cada línea dice lo esperado. Deja el baúl como estaba.
- `--viviendas`: en vez de la prueba larga, la de las viviendas de los rescatados (`mapa/viviendas.gd`): con el
  policía, el militar, el ferretero y el técnico rescatados, comprueba en la terminal que en la sala de
  mantenimiento no espera nadie y hay una puerta a la derecha (`captura-viviendas-puerta.png`); que por ella se llega
  al pasillo de las viviendas («Planta baja · Viviendas»), con seis placas, cerradas (y a oscuras) las puertas de la
  médica y la farmacéutica y abiertas las demás, cada uno en su habitación (en medio, menos el técnico:
  `captura-viviendas-ferretero.png`) y las cámaras en la del técnico (`captura-viviendas.png` y
  `captura-viviendas-derecha.png`, el pasillo); que andando hacia
  una puerta cerrada no se pasa y hacia una abierta sí (`captura-viviendas-habitacion.png`); que al arrimarse al
  policía te acompaña y al militar también (y el policía vuelve a la suya); que por la puerta de la izquierda se
  vuelve a la sala, junto a su puerta de la derecha, con el militar; y que en la 1ª planta, con el ascensor
  arreglado, también se llega. Luego los seis a la vez (`captura-viviendas-seis.png`), el guiño de la cafetera (la
  cafetera en la habitación de la farmacéutica y no en la sala; desde el pasillo no dice nada, al entrar sí, si sales a
  medias lo vuelve a contar entero y la segunda vez ya no: `captura-cafetera.png`) y las cámaras del técnico
  (`captura-tecnico-*.png`). Cada línea dice lo esperado. Deja el guardado como estaba.
- `--armas`: en vez de la prueba larga, la de la sala de pruebas de armas (`sala_armas.gd`): entra con F11 y cuenta en
  la terminal su tamaño, que la diana está en el centro, que hay luz y que se entra con la pistola; la pistola en modo
  asistido, a 200 de la diana, desde 72 ángulos (cada 5°; 0° = hacia la derecha, 90° = hacia abajo): si la primera bala
  le da o cómo falla y a cuánto pasa del centro, y desde qué ángulos falla; que la diana no ha perdido vida nunca (y
  cuántos zombis normales habría matado), que la munición no se acaba y ha recargado; que el punto pasa a la escopeta (el recuento empieza de cero),
  la coma vuelve y llega a la pistola eléctrica, la última, el guion esconde y saca el panel, y F11 vuelve a la sala de
  mantenimiento con las armas y las balas de antes. Fotos: `captura-armas.png` (tras un fallo por el lado) y
  `captura-armas-escopeta.png`.
- `--sala`: en vez de la prueba larga, la de la sala de mantenimiento (`planta.gd`, sus tres estancias): cuenta en la
  terminal las estancias, sus puertas y en cuál ha quedado cada mueble, si desde el despacho se llega a la puerta del
  pasillo, a la de las viviendas y delante del ordenador, el banco, el baúl y la taquilla, y qué pone arriba en cada
  estancia. Fotos: la sala entera (`captura-sala.png`) y cada estancia de cerca, con Johnny dentro
  (`captura-sala-vestuario.png`, `captura-sala-despacho.png` y `captura-sala-taller.png`). Luego cruza la puerta de
  las viviendas, vuelve (al taller) y sale al pasillo. Cada línea dice lo esperado.
- `--gastro`: en vez de la prueba larga, la del vómito de la mutación Gastroenteritis (`mutaciones.gd`): en un
  apartamento, junto a un tabique con un zombi justo detrás, comprueba en la terminal que el vómito no sale hacia él,
  que su charco pegado al tabique no lo quema (pero sí a uno de este lado) y que, con otro zombi más lejos pero a la
  vista, sale a ese (`captura-gastro-vuelo.png`, `captura-gastro-charco.png`). Cada línea dice lo esperado.
- `--caza`: en vez de la prueba larga, la de la caza del acompañante (`aliado.gd`, `cazar`): en un apartamento, solo el
  ferretero con Johnny quieto; con un zombi en otra habitación (pared en medio) se queda en la fila; con otro a unos 250
  a la vista, deja la fila y va a por él (`captura-caza-va.png`), lo mata a martillazos y vuelve a su puesto
  (`captura-caza-vuelve.png`). Cada línea de la terminal dice lo esperado.
- `--porqueria` (con `--jefe gloton`): en vez de la prueba larga, la de la habitación del Glotón (`peligros/porqueria.gd`):
  la monta sin él y cuenta en la terminal los muebles (ninguno, ni lámparas), la parte del suelo sucia, que donde aparece Johnny y el
  centro están limpios y lo pegado a las paredes sucio (y el grosor de la franja), que en medio queda una elipse limpia
  perfecta, como un ring, que sale igual con otra semilla, que la puerta está en el centro de la pared y de ella se
  llega al centro sin pisar nada por un paso recto de 3 casillas de ancho como poco, lo que pierde sobre la porquería en 1 s y que en una
  casilla limpia no pierde nada, las salpicaduras de las paredes y las luces del resplandor (`captura-porqueria.png`,
  Johnny encima; `captura-porqueria-medio.png`, la elipse limpia desde el medio) y la luz fija blanca de la sala
  (`peligros/luz_jefe.gd`, que se suma al resplandor). Cada línea dice lo esperado.
- `--gimnasio` (con `--jefe gymbro`): en vez de la prueba larga, la del gimnasio del Gymbro (`peligros/tropiezos.gd`):
  lo monta sin él y cuenta en la terminal las máquinas (29) y cuántas de cada tipo hay en cada pared, que no se
  pisan ni tocan un muro, que el fondo es simétrico con una polea justo enfrente de la puerta, que no hay lámparas,
  la parte del suelo que queda libre, que la puerta está abajo, en el centro de la pared y sin nada delante (y lo mismo
  en 40 plantas más, con el piso del jefe en otra puerta), las 5 luces fijas encendidas y las mancuernas (cuántas, lo
  separadas que están, lejos de la puerta y de los muebles); que andando
  por encima de una Johnny se cae, se queda tumbado sin moverse ni atacar aunque se le pida, no pierde vida, se
  levanta a los 2 s y la mancuerna sale rodando; y que rodando se pasa por encima de otra sin caer
  (`captura-gimnasio.png`, la sala entera con la cámara alejada y sin penumbra; `captura-gimnasio-luz.png`, igual pero
  con la penumbra de siempre, para ver lo que alumbran las luces; `captura-gimnasio-caido.png`, Johnny
  en el suelo con las estrellitas). Cada línea dice lo esperado.
- `--cubos` (con `--jefe portera`): en vez de la prueba larga, la del cuarto de la limpieza de la portera
  (`peligros/tropiezos.gd`): lo monta sin ella y cuenta en la terminal cómo se llama la sala, los muebles
  (contenedores, cubos de basura, carros de limpieza y 3 lámparas) y en qué paredes están, que la puerta está en el
  centro de la pared, lo que cuelga de la pared
  de arriba (fregonas y cubos, nada delante de la puerta), los cubos del suelo (10, de pie, separados, lejos de la
  puerta y de los muebles) y el aviso de Johnny al entrar; luego, lo mismo que el gimnasio con un cubo (que además
  vuelca al tropezar) (`captura-cubos.png`, la sala entera; `captura-cubos-pared.png`, la pared de arriba de cerca;
  `captura-cubos-caido.png`, Johnny en el suelo y el cubo volcado) y la luz fija blanca de la sala
  (`peligros/luz_jefe.gd`, que se suma a las lámparas). Cada línea dice lo esperado.
- `--llamas` (con `--jefe bombero`): en vez de la prueba larga, la de la habitación del jefe de bomberos
  (`peligros/cerco.gd`) y su giro con el lanzallamas (`bombero.gd`): la monta sin él y cuenta en la terminal cómo se
  llama la sala, que no tiene muebles, cómo arde (entre un 35 y un 55 % del suelo, el centro no, todo lo pegado a la
  pared sí menos el pasillo de la puerta, en medio una elipse limpia perfecta, como un ring, que sale igual con otra
  semilla, que la puerta está en el centro de la pared y de ella se llega al centro sin pisar el fuego por un paso
  recto y holgado, y en el medio queda sitio para el giro), el aviso de Johnny al entrar, las luces del fuego y lo que quema quedarse 1 s en el borde. Luego
  mete al bombero en el medio y le hace girar con Johnny moviéndose como con el mando (`vuelta_de_giro`): el sentido
  sale a los dos lados, el cono se abre 40 grados (a 200 del jefe pilla lo que está a 17 grados del medio y no lo que
  está a 23), llega hasta la pared en todo su ancho, corriendo delante de él en su sentido Johnny no se quema, en
  contra sí, rodando a través de él también; su burbuja de fuego (`burbuja_de_fuego`): en el aviso aún no está y un
  golpe le quita vida, girando ni un golpe, ni una explosión (que tampoco le corta el giro) ni una bala le quitan nada
  y brilla donde le dan, y acabado el giro baja y los golpes vuelven a quitarle; y, enfadado, corriendo por el hueco
  entre los dos conos a su paso, no (`captura-llamas.png`, la sala entera; `captura-llamas-aviso.png`, el cono rojo y
  las flechas del aviso; `captura-llamas-giro.png`, Johnny corriendo delante del cono; `captura-llamas-burbuja.png`, la
  burbuja de cerca; `captura-llamas-enfadado.png`, los dos conos) y la luz fija blanca de la sala
  (`peligros/luz_jefe.gd`, que se suma al fuego). Cada línea dice lo esperado.
- `--ir-jefe`: en vez de la prueba larga, la de Mayús + 7, 8, P y 9 (`probar_ir_jefe`): desde la sala de
  mantenimiento pulsa cada una y cuenta en la terminal que Johnny está en la habitación de ese jefe, junto a la puerta,
  en la planta que le tocó en el sorteo, y que el jefe que sale es ese (`captura-ir-jefe.png`, el jefe de bomberos en su
  habitación). Cada línea dice lo esperado.
- `--presentacion` (con `--jefe X`, si se quiere): en vez de la prueba larga, la de la presentación del jefe
  (`ui/presentacion.gd`): entra en su piso y, al gritar el jefe, comprueba que no sale ninguna frase escrita y que
  Johnny está callado (`captura-presentacion-grito.png`); a mitad de la presentación, el zoom de la cámara sobre él,
  que Johnny está quieto y sin poder recibir daño, que el jefe grita, el nombre en pantalla y la barra oculta, y
  el foco que lo alumbra (uno, menos al Gymbro, que no lleva ninguno) (`captura-presentacion.png`); al acabar, que todo ha vuelto y Johnny dice lo que se había callado (lo de la
  habitación). Johnny lleva la Gastroenteritis,
  Tentacular, Locura y Flatulento, con un zombi quieto al lado: ninguna actúa mientras dura y cada una lo hace 1 s
  después de acabar (`captura-presentacion-vomito.png`); el acompañante que ataca (el policía), con su arma lista,
  tampoco ataca hasta 1 s después. Cada línea dice lo esperado. (En el juego, mientras dura la presentación no
  responden la pausa, el inventario ni las teclas de prueba, y las mutaciones no actúan; al acabar, ellas y los
  acompañantes que atacan esperan 1 s.)
- `--fotos-luz`: en el apartamento con más habitaciones, todo descubierto y sin zombis, una foto por habitación
  con Johnny mirando un tabique que tiene otra habitación detrás (`captura-luz-<n>.png`): la linterna y las
  lámparas no tienen que alumbrar el suelo del otro lado.
- `--fotos-ayudas`: pone en Sí las ayudas de Opciones (`captura-ayudas-opciones.png`), prueba la vida y la pistola
  y adónde caería un lanzable, sin ayudas y con ellas (lo cuenta en la terminal), y saca el HUD (`captura-ayudas-hud.png`)
  y un molotov volando al zombi (`captura-ayudas-lanzar.png`). Las deja en No.
- `--fotos-supervivientes`: los tres supervivientes del edificio con su hoja de PixelLab (con `--edificio centro`, el
  ferretero, la farmacéutica y el técnico): de vecinos, cada uno en su habitación de las viviendas
  (`captura-supervivientes-sala.png`) y, en un piso,
  andando tras Johnny (`-andar`), haciendo lo suyo (`-accion`: disparo, jeringa, martillazo, descarga) y el último
  caído (`-caido`).
- La prueba larga saca también las de Colecciones: `captura-escritorio-nuevo.png` (el icono con el aviso de
  «¡NUEVO!»), `captura-colecciones.png` (los objetos del edificio), `captura-bestiario.png` (la ficha del vecino) y
  `captura-bestiario-falta.png` (la del gerente, sin ver), y cuenta en la terminal lo encontrado, creado y visto.
  También `captura-vendas.png` (el inventario con las vendas elegidas) y, en la terminal, lo que curan las vendas y
  el bocadillo al usarlos.

## La sala de mantenimiento

La partida (`escenas/partida.tscn`) empieza ahí, tras el menú principal (`escenas/menu_principal.tscn`).
Se puede volver a mitad de partida: al caer el jefe de una planta (de la 1ª en adelante), Johnny arregla el
**ascensor** del pasillo (luz verde, sin las cintas, y lo dice al salir al pasillo). Solo baja a esta sala y, por su
puerta, vuelve a la planta de la que venías, delante del ascensor; nunca lleva a otra planta. La planta queda como
la dejaste. En la planta baja sigue averiado (la sala está ahí mismo) y la azotea no tiene.
La sala tiene tres estancias de 10 × 10 casillas, una al lado de otra (algo más ancha que la pantalla: la cámara se
mueve un poco al andar). Arriba sale en cuál estás («Planta baja · Mantenimiento · Taller»). Del despacho salen dos
puertas sin hoja, como las de dentro de los pisos: a la izquierda al vestuario y a la derecha al taller.
- **Despacho** (en medio, con tarima y la pared beis con friso de madera): por su puerta de abajo se sale al pasillo y
  aquí empieza la partida. En medio de la pared de arriba, la mesa del ordenador; a su izquierda, un corcho con el
  plano del edificio y papeles clavados, y a su derecha, una papelera.
- **Vestuario** (a la izquierda, de azulejo): el plato de ducha en la esquina de arriba, la taquilla en medio de lo que
  queda de esa pared, el lavabo con su espejo y el váter de lado en la pared de la izquierda y el banco largo para
  ponerse los zapatos, abajo. La ducha, el váter y el lavabo son de adorno.
- **Taller** (a la derecha, con el cemento y la pared de siempre): en la pared de arriba, una estantería metálica con
  botes, el banco de trabajo y el baúl; en la de la derecha, la puerta de las viviendas y, debajo, el carrito del
  conserje.
En el suelo, manchas de sangre.
- En el taller, el **banco de trabajo**: todas las recetas en hojas de papel (las que aún no tienes,
  con un «?»). Se toca una y, si tienes lo que pide (en la mochila, el baúl o la mano), se crea el arma. Quedan dos,
  la atraedora y la congeladora; ninguna viene aprendida (el cóctel molotov, que venía, se quitó el 25 oct): las
  suelta cada jefe al morir (los de planta y el de la azotea), en un papel que hay que recoger. Lo aprendido no se
  pierde nunca. El lanzallamas, el lanza ácido y la pistola eléctrica ya no se crean: se compran en la tienda de armas
  del ordenador.
- A su derecha, el **baúl**: las armas creadas (se sacan para la partida) y los objetos guardados. Con
  «Guardar de la mochila» se ve la mochila: se toca una casilla y «Guardar» mete en el baúl todos los de esa
  casilla, o «Guardar todo»; así ya no se pierden si Johnny cae (lo que quede en la mochila pasa solo al completar
  el edificio). Lo de curar no se guarda, y con el baúl lleno (32 casillas) solo caben más de lo que ya tiene. Con
  el ratón o el dedo, flechas e Intro o el mando (A elige, y la marca salta a «Guardar»: A dos veces); Esc o B
  cierra.
- En el despacho, la mesa del ordenador: **ConserjeOS** (puntos de talento, árbol de talentos, tienda de
  armas, logros, Dosier VD-7, Noticias de Canal 8 y Colecciones: lo encontrado, creado y leído de cada edificio, y el
  bestiario).
- En el vestuario, la **taquilla** de Johnny: arrimarse para elegir la skin (las que ya hayas desbloqueado, cada una
  con lo que hace puesta; las demás salen con «???» y cómo se consiguen; la que te pongas se queda puesta). **El portero**: se desbloquea la
  primera vez que matas a la portera; pelo largo blanco con coleta y barba, y la fregona hace un 300 % más de daño.
  **El glotón**: se desbloquea la primera vez que matas al Glotón; calvo y con la cara hecha una boca llena de
  dientes, y quien te hace daño lo paga («¡ÑAM!»): un zombi muere al momento y un jefe pierde un 10 % de su vida
  máxima (también si te da con algo que lanza; la armadura y los escudos no lo paran). No cuenta si eres invulnerable
  o lo esquivas, ni lo que no es de nadie (charcos, fuego del suelo, agua con corriente, explosiones). **El gymbro**:
  se desbloquea la primera vez que matas al Gymbro; calvo, con el pañuelo rojo y barba negra, y las armas cuerpo a
  cuerpo hacen un 200 % más de daño (el triple: la fregona, el bate y el cuchillo; el golpe de Ninja
  al acabar la esquiva y los martillazos del ferretero, no). **El bombero**: se desbloquea la primera vez que matas al
  jefe de bomberos; un casco de bombero negro con la raya amarilla, y las armas que queman (el
  lanzallamas y el molotov) hacen un 200 % más de daño, también lo que siguen
  ardiendo los zombis que prenden; y el fuego no te hace nada: el del suelo, los charcos de fuego, el aceite hirviendo
  del cocinero, el seguir ardiendo, y el cono, las bolas, el aro y los molotovs del jefe de bomberos (su hachazo y las
  explosiones, sí). Con el ratón o el dedo, flechas e Intro (o 1 a 5) o el mando
  (cruceta y A); Esc o B cierra.
- Los baños tienen un armarito con botiquín.
- Por la **puerta de la derecha** del taller, las **viviendas** de los supervivientes rescatados (`mapa/viviendas.gd`): un
  pasillo largo con seis habitaciones, una para cada uno, con su placa junto a la puerta. Arriba, las de los
  Apartamentos (policía, médica, militar); abajo, las del centro comercial (ferretero, farmacéutica, técnico). Las de
  quien aún no has rescatado están cerradas y a oscuras; las de los rescatados, abiertas y con él dentro: arrimarse a
  uno para que te acompañe (solo uno a la vez; el que te acompañaba vuelve a la suya). Detrás del técnico, las
  pantallas de las cámaras de seguridad: desde que está rescatado el minimapa enseña los zombis. Junto a la
  farmacéutica, la **cafetera** de Johnny: la primera vez que entras en su habitación (con ella rescatada), te
  cuenta que le ha encontrado el doble fondo. Las habitaciones, de momento, sin más muebles. Se llega también desde el ascensor (la sala tiene la misma puerta).
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
