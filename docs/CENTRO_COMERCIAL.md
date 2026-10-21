# Segundo edificio: el centro comercial

Decidido con el dueño el 21 de octubre de 2026. Es el plan entero; se hace por partes, cada una con su visto
bueno. Cuando una parte esté hecha, se marca aquí con ✅ y lo que haya cambiado respecto al plan.

## Lo que no cambia

- **La sala de mantenimiento** sigue siendo la misma, en la planta baja, y **cada edificio empieza desde allí**.
- **Los supervivientes rescatados** se quedan para siempre, se rescaten en el edificio que sea.
- **5 plantas como hasta ahora**: planta baja (con la entrada principal), tres más, y la azotea con el jefe
  final. En cada planta, el pasillo con el ascensor averiado y las escaleras de incendio.

## Cómo se elige

- Después de pulsar JUGAR sale **"Elige edificio"**, con una tarjeta por edificio, como en el juego JS
  (`showBuildings` de `src/ui.js` y `BUILDINGS` de `src/config.js`): nombre, descripción, plantas, intentos y
  progreso ("¡Sin explorar!", "Has llegado a la planta N", "Completado ×N · mejor tiempo").
- **El centro comercial se desbloquea al completar Apartamentos.** Hasta entonces, su tarjeta sale con candado.
- Por dentro: `partida.gd` deja de tener `EDIFICIO := "apartamentos"` fijo; el edificio elegido dice qué
  generador de estancias, qué aspecto, qué zombis, qué objetos y qué dosier tocan. El guardado ya lleva el
  progreso de cada edificio por separado (`Guardado.edificio`) y el dosier ya va por edificio (`historia.gd`).

## Las tiendas

En vez de apartamentos, **tiendas**, cada una con sus habitaciones de dentro (almacén, aseo, taquillas de los
trabajadores...). Cada tipo de tienda tiene su peligro y sus objetos, para que al entrar ya sepas qué te espera:

| Tienda | Habitaciones de dentro | Peligro | Qué se encuentra |
|---|---|---|---|
| Supermercado | almacén, cámara frigorífica, aseo | frío | comida, botiquines |
| Ferretería | almacén, taller | — | materiales para el banco de trabajo |
| Electrónica | almacén, taquillas | agua con electricidad | baterías, piezas |
| Restaurante / zona de comidas | cocina, cámara, aseo | incendio | aceite, cosas para molotov |
| Tienda de ropa | probadores, almacén | — | ropa para las taquillas (skins) |
| Farmacia | rebotica | — | objetos de curar |

- **El del minijefe está cerrado con una tarjeta de acceso** (en lugar de la llave). La lleva **un zombi
  guardia de seguridad** que ronda la planta: hay que cazarlo.
- **Salas opcionales con riesgo:** por ejemplo, la cámara acorazada de la joyería, que pide una tarjeta especial
  o aguantar una horda a cambio de un objeto muy bueno.

## Los peligros

**También les hacen daño a los zombis**, para que se puedan usar (atraer una horda al agua, encerrarla en la
cámara frigorífica):
- **Cámara frigorífica:** el frío hace daño poco a poco y frena.
- **Incendio en una habitación:** fuego que hay que esquivar (y que se puede extender).
- **Agua con electricidad:** electrocuta. Se puede apagar en el cuadro eléctrico de la tienda (con su riesgo).

Se parecen a los estados de los charcos que ya hay (`estados.gd`, `charco.gd`): partir de ahí.

## Zombis

- Zombis nuevos de centro comercial (dependientes, guardias de seguridad, clientes...).
- **Minijefes**, uno por planta:
  - El guardia jefe con escudo antidisturbios (hay que pegarle por la espalda).
  - El cocinero, que lanza cuchillos.
  - La mascota del centro comercial: un zombi dentro del disfraz, rápido y que embiste.
- **Jefe final en la azotea:** el gerente, que trabajaba con Velaria (la historia sigue).

### Decidido con el dueño (21 oct, para la parte 4)

Números de partida (para comparar: Johnny anda a 210; el zombi normal, 30 de vida y 80 de velocidad; la portera, 600).
Todos con dibujo propio de PixelLab; los modelos (8 vistas) ya están hechos y con su visto bueno (y el de un amigo
suyo): `assets/pixellab.json` → `centro-comercial-parte4`, vistas en `assets/sources/<nombre>/rotations/`.

- **Zombis nuevos** (48 px, como Johnny):
  - **Vigilante** (gorra, uniforme azul marino, porra y radio): vida 45, velocidad 85, porrazo de 12 con algo más
    de alcance. Son los refuerzos que llegan al silbato y salen en las tiendas desde la 1ª planta (coste 1,5). **El
    guardia de la tarjeta** pasa a usar su dibujo (adiós al tinte azul); su comportamiento no cambia.
  - **Dependienta** (polo rojo, coleta, acreditación): vida 20, velocidad 95, daño 6. Al despertar grita
    «¡OFERTAS!»: despierta a toda la tienda y durante 5 s todos van un 30 % más rápido; luego se aparta de Johnny y
    vuelve a gritar cada 8 s. En las tiendas desde la planta baja, una por tienda como mucho (coste 1,5).
  - **Clientes:** los zombis de siempre.
- **Cuatro minijefes distintos**, uno por planta (baja, 1ª, 2ª y 3ª), **en orden al azar en cada partida y sin
  repetir** (lo pidió el dueño). Todos del tamaño de un zombi grande (lienzo de 72, unos 71 px de alto; el dueño pidió
  que **la mascota y la portera también** pasen a ese tamaño). Como la portera: aparecen al entrar en su tienda, barra
  grande, +25 % de vida por planta, avisan cada ataque, a media vida se enfadan, al caer billetes, munición, objetos y
  mutación. La tienda del jefe se llama según quién esté (Oficina de seguridad, Cocina central, Taller de costura,
  Juguetería).
  - **Antidisturbios** (vida 500, velocidad 70, gira despacio): el escudo para balas y golpes de frente («¡CLONC!»
    y chispas); de lado, daño normal; por la espalda, el doble; granadas y molotov le dan por cualquier lado.
    Porrazo de cerca (aviso 0,5 s, 18 y empuja); carga con el escudo (franja roja, corre a 400; si te pilla, 20 y te
    tira; si se estrella contra una pared, aturdido 2 s); silbato: 2 vigilantes. Enfadado: gira más rápido, carga
    dos veces seguidas y llama a 3.
  - **Cocinero** (vida 450, velocidad 60, prefiere la media distancia): abanico de 3 cuchillos que giran (12 cada
    uno; 5 enfadado); lluvia de 5 cuchillos alrededor de Johnny con marca antes (el primero, donde vas a estar);
    aceite hirviendo (charco que quema como el molotov, 6 s); cuchillazo de cerca (20).
  - **Modista** (la encargada de la tienda de ropa; vida 420, velocidad 90; su tienda, llena de maniquíes): se
    esconde entre los maniquíes, quieta como uno más, y cambia de sitio con otro (se le ven brillar los ojos un
    instante); ráfagas de alfileres en línea recta (8 cada uno); tijeretazo de cerca (aviso 0,5 s, 22 y empuja).
    Enfadada: 3 maniquíes (con el dibujo del mueble) cobran vida y solo se mueven cuando no los miras.
  - **Mascota** (un oso de peluche gigante, amarillo y sucio, con la cara del zombi dentro de la cabeza; vida 420,
    velocidad 140): embestida (franja roja 0,6 s, sale a 520; si te pilla, 22; si se estrella, mareada 1,8 s con
    estrellitas); salto encima de Johnny (sombra 0,8 s antes, 18 en un círculo). Enfadada: 3 embestidas seguidas
    rebotando en las paredes y con menos aviso.
- **La azotea:** el centro comercial pasa a tener 4 plantas con tiendas y la azotea (los Apartamentos no cambian).
  Un espacio grande y abierto (como en el juego JS), con suelo de hormigón, murete alrededor, aparatos de aire
  acondicionado, chimeneas y un helipuerto pintado. Se llega por las escaleras y no se vuelve; al caer el gerente se
  abre la escalera de incendios y por ahí se acaba el edificio.
- **El gerente** (jefe final, grande como la portera ahora: unos 117 px; vida 1400): contratos que cortan en abanico
  (10 cada uno), maletinazo de cerca (20) y «¡A TRABAJAR!» (2 dependientas y 1 vigilante). A media vida se inyecta
  VD-7, el somnífero de Velaria, y **muta (con su propio dibujo)**: más rápido, latigazos de tentáculo (como el zombi
  de tentáculos, más largos) y embestida. Su historia, en la parte 7.
- **Por trozos**, cada uno con su visto bueno: 1) ✅ vigilante y dependienta; 2) antidisturbios y lo común de los
  minijefes (y la portera a su nuevo tamaño); 3) ✅ cocinero; 4) modista; 5) mascota (rehecha a 72); 6) azotea y
  gerente.
  Coste previsto: unas 415 generaciones en total (54 ya gastadas en los 8 modelos).

## Supervivientes

### Decidido con el dueño (21 oct, para la parte 5)

- **Tres supervivientes nuevos, solo del centro comercial** (eran cuatro; el dueño quitó a la camarera el 21 oct:
  **tres por edificio**), cada uno en un tipo de tienda con trastienda. **Uno por
  partida, como ahora**: sale uno de los que aún no tienes, en una planta al azar (nunca la azotea); en los
  Apartamentos siguen saliendo el policía, la médica y el militar. Al rescatarlo se queda a vivir en la sala de
  mantenimiento para siempre y **la hace crecer** con algo suyo; como ahora, puede acompañarte (uno a la vez).
- **Cada uno con su propio rescate** (no la horda de siempre para todos), y **dibujados con código** (`persona.gd`),
  como los tres de ahora: gratis y con el mismo aspecto.
- Números provisionales (los puso Claude; se ajustan al probar):

| Quién | Dónde y cómo se le rescata | En la sala | Si te acompaña |
|---|---|---|---|
| **Ferretero** | Atrincherado en el almacén de la ferretería: la horda de siempre mientras quita la barricada (más corta, unos 2 min) | Monta su puesto: vende munición, molotovs y granadas por dólares | Martillazos de cerca (8) |
| **Farmacéutica** | Herida en la rebotica de la farmacia: escoltarla hasta las escaleras; anda despacio y van saliendo zombis; si la tumban, hay que levantarla (como ahora) | Cada partida empieza con un botiquín en la mochila | Los charcos de veneno y ácido te hacen la mitad |
| **Técnico** | En la tienda de electrónica con el agua electrificada: bajar la palanca del cuadro (la tienda a oscuras) y aguantar la horda a oscuras unos 90 s mientras arregla algo | Arregla las cámaras de seguridad: el minimapa enseña los zombis | Descarga cada 4 s: aturde 1 s al zombi más cercano |

- ✅ **Guiño para la historia (parte 7; hecho el 21 oct):** según el dosier, la cafetera de la sala se la regaló
  Velaria a Johnny y por ahí le metían el VD-7. La arreglaba la camarera, que ya no está: **lo descubre la
  farmacéutica** (decidido con el dueño el 21 oct, en la parte 7).
  - La cafetera, dibujada con código (`scripts/mapa/cafetera.gd`): sobre una mesita, con su jarra, la taza de
    Johnny y vapor, entre la farmacéutica y el técnico (`Mapa.CAFETERA_EN`). Está siempre en la sala.
  - La primera vez que la farmacéutica, ya rescatada, está en la sala (en su sitio o acompañándote), al segundo y
    medio dice las tres frases de `Historia.CAFETERA` en su bocadillo, una detrás de otra
    (`Supervivientes.guino_cafetera`). Con la última se apunta en el guardado (`cafetera`) y no lo vuelve a decir;
    si Johnny se va antes de acabar, lo cuenta entero la próxima vez.
  - `--captura` saca `captura-cafetera.png` (la primera frase) y comprueba en la terminal que la segunda vez ya no
    dice nada.
  - El rescate propio de la farmacéutica y su mejora (el botiquín al empezar) siguen pendientes.
- Se hace por trozos, cada uno con su visto bueno: lo común (que salgan los nuevos en el centro y su sitio en la
  sala) y luego un superviviente por trozo.
- ✅ **Lo común** (21 oct):
  - Los tres, en `supervivientes.gd` (`DATOS`), dibujados con código (`persona.gd`): el ferretero con chaleco naranja
    de raya brillante, gorra y bigote, y su martillo; la farmacéutica con bata blanca, cruz verde y moño; el técnico con polo azul, cascos rojos, tarjeta colgada y un
    aparato con lucecita en el cinturón.
  - En el centro comercial sale uno de los tres que aún no tengas (en los Apartamentos, los tres de siempre, sin
    cambios). Su tienda sale siempre en su planta (`Planta.tienda_fija`) y se esconde en su trastienda, cerrada y sin
    zombis: el ferretero en el almacén de la ferretería, la
    farmacéutica en la rebotica (sin zombis tampoco en el aseo que tiene dentro) y el técnico en el almacén de la
    tienda de electrónica. Cada uno grita lo suyo («¡No toquéis el agua!»).
  - De momento se rescatan como los de siempre (encerrados, gritando y con la horda forzando la cerradura); cada trozo
    siguiente cambia solo su rescate y hace su mejora de la sala.
  - Lo suyo al acompañarte, ya hecho (lo pidió el dueño): martillazos a los que se le acercan (8, cada 0,9 s), charcos de veneno y ácido a la mitad, y una descarga cada 4 s que deja quieto 1 s
    al zombi más cercano (hasta 260 de distancia).
  - En la sala de mantenimiento, los tres de siempre donde estaban y los tres nuevos en una fila debajo, cada uno
    con un hueco libre detrás para su mejora (`Planta.SITIO_CENTRO`; el texto de cada mejora, en `DATOS`, "mejora").
    Lo que no decía el plan: con seis en la sala, solo dice «¿Te acompaño?» el que tienes más cerca (si no, se
    pisaban los bocadillos).
  - Tecla **H** en el centro: cada vez, el siguiente de los tres (rehace la planta con su tienda).
    `--captura` saca además `captura-sala-seis.png` (los seis en la sala).
- ✅ **El rescate propio de la farmacéutica** (21 oct; `scripts/escolta.gd`; números provisionales):
  - Grita desde la rebotica, cerrada, como antes; al limpiar la farmacia se abre y dice «¡Me han mordido la pierna!
    No puedo correr». Al arrimarte se une y empieza **la escolta** (no hay horda): llevarla hasta la puerta de las
    escaleras de su planta. Arriba, «Lleva a la Farmacéutica a las escaleras», y una flecha en el borde hacia las
    escaleras (o hacia la salida, dentro de una tienda). Suena la música tensa.
  - Va detrás de Johnny cojeando (90 de velocidad; Johnny, 210), con su vida encima, y se queja de vez en cuando.
    Si Johnny se aleja más de 300, los zombis van a por ella; si cae, quedarse 2 s a su lado para levantarla
    (vuelve con media vida), como en la horda.
  - Los zombis: a los 2 s entran 3 por la puerta de la farmacia; en el pasillo salen grupos por las puertas de las
    tiendas lejos de los dos (de 1 a 3, cada 6 s al principio y cada 3 s al cabo de un minuto; 14 a la vez como
    mucho; lentos y normales y, más adelante, también rápidos y venenosos).
  - No se puede cruzar una puerta si está a más de 140 de Johnny («Espera a la Farmacéutica: va herida») o en el
    suelo.
  - A menos de 160 de la puerta de las escaleras (aunque sigan cerradas) está a salvo: «Aquí ya estamos a salvo. Me
    vendo la pierna y sigo contigo». Sigue en el equipo como los demás, cuenta para el logro «Buen vecino» y deja
    de haber horda para ella. Para que viva en la sala, como siempre, hay que terminar el edificio con ella.
  - `--captura --edificio centro` prueba la escolta entera (lo escribe en la terminal) y saca `captura-escolta.png`.
  - Falta su mejora de la sala (empezar con un botiquín en la mochila): no hay botiquín que se lleve en la
    mochila; va con los objetos de curar de la farmacia (ver «Objetos»).
- ✅ **El rescate propio del técnico y su mejora** (21 oct; `scripts/averia.gd`; números provisionales):
  - Grita desde el almacén de la tienda de electrónica, cerrado, como antes; al limpiar la tienda se abre y dice
    «¡Gracias! Antes de irnos tengo que arreglar ese cable pelado». Al arrimarte se une y pide que bajes la palanca
    del cuadro eléctrico: arriba, «Baja la palanca del cuadro eléctrico», y una flecha en el borde hacia el cuadro.
    Mientras no la bajes no se va de la tienda («El Técnico no se va sin arreglar el cable…»). Si ya estaba bajada,
    empieza directamente.
  - Al bajarla (la tienda a oscuras, solo la linterna) se va donde el cable sale de la pared y lo arregla de
    espaldas, con una lucecita de trabajo y chispas; la puerta de la tienda se cierra y van entrando zombis por las
    habitaciones de la tienda, y él avisa de por dónde. Arriba, la barra «El Técnico arregla el cable · 1:30».
  - **90 s de trabajo**; grupos cada 6 s al principio y cada 3,5 s al final, de 2 a 5 zombis, 24 a la vez como
    mucho; el primer minuto lentos, normales y dependientas, y luego también rápidos, vigilantes y algún explosivo.
    Como en la horda: si Johnny se aleja van a por él, si cae hay que quedarse 2 s a su lado y a mitad suelta un
    molotov, una granada y munición.
  - Lo que no decía el plan: **si Johnny vuelve a subir la palanca**, vuelve la luz y el agua da calambres a los
    zombis que la pisen (sirve de trampa), pero él deja de trabajar («¡Eh, que hay corriente! ¡Baja la palanca!»)
    y la barra se para. **No se puede salir** de la tienda mientras arregla («Aguanta: el Técnico está arreglando
    el cable»).
  - Al acabar: «¡Arreglado! Ya puedes dar la luz». El cable queda empalmado con cinta aislante y **el agua de esa
    tienda ya no da calambres nunca más** (lo decidió el dueño); la palanca sigue abajo y, si la subes, vuelve la
    luz. Se abre la puerta, cuenta para «Buen vecino» y él sigue en el equipo como los demás. Si su tienda no
    tuviera agua con corriente (no debería pasar), sale la horda de siempre.
  - **Su mejora**: cuando ya vive en la sala, detrás de él hay una mesa con cuatro pantallas de las cámaras de
    seguridad (`scripts/mapa/camaras.gd`, dibujadas con código) y, **en los dos edificios** (lo decidió el dueño),
    el minimapa enseña los zombis: un puntito rojo por zombi en cada sala, también en las que no has visitado;
    donde está Johnny, cada puntito va donde está su zombi y se mueve con él.
  - `--captura --edificio centro` prueba el rescate entero (lo escribe en la terminal) y saca
    `captura-tecnico-palanca.png`, `captura-tecnico-horda.png`, `captura-tecnico-fin.png`,
    `captura-tecnico-minimapa.png` y `captura-tecnico-sala.png`.

## Objetos

- Objetos nuevos y objetos que ya existen, **repartidos por edificio**: algunos solo salen en los apartamentos y
  otros solo en el centro comercial, para que valga la pena volver a un edificio completado.
- **Recetas del banco de trabajo que piden objetos de los dos edificios** ("me falta X de los apartamentos para
  fabricar Y"). Quien juegue solo uno no se queda bloqueado.

### Decidido con el dueño (21 oct, para la parte 6)

- **Apartamentos:** siguen saliendo los 17 objetos de siempre, como ahora (las 15 recetas de ahora se pueden hacer
  jugando solo ahí).
- **Centro comercial: cada tienda, lo suyo.** El zombi que cae suelta (con la misma probabilidad de ahora) un objeto
  de la lista de la tienda donde está; si te falta algo, sabes a qué tienda ir. Las listas mezclan objetos de
  siempre que pegan con la tienda (en la ferretería clavos, hacha, llave inglesa y cuchillas; en el restaurante
  alcohol y gasolina; en la electrónica el táser...) y los nuevos. Los zombis del pasillo, de cualquier lista.
- **Solo en los Apartamentos** (cosas de casa): despertador, mancuernas, pistola de agua, trapo y cuerda.
- **Nueve objetos nuevos, solo del centro comercial** (iconos de 16×16 dibujados con código, `tools/objetos16.py`;
  el plan decía «ocho», pero eran nueve nombres y el dueño se quedó con los nueve):

| Tienda | Objetos nuevos |
|---|---|
| Ferretería | Cinta americana, Cadena |
| Electrónica | Batería, Cable |
| Restaurante | Aceite, Bombona de gas |
| Supermercado | Hielo seco |
| Farmacia | Jeringuilla |
| Tienda de ropa | Perchas |

- **Seis recetas nuevas que mezclan los dos edificios** (un objeto de casa y otro del centro; los números, al
  hacerlas, parecidos a los de las recetas de ahora):

| Arma | Ingredientes | Qué hace |
|---|---|---|
| Pistola eléctrica | Pistola de agua + Batería | Chorro que electrocuta y salta a los zombis de al lado |
| Bomba de aceite | Trapo + Aceite | Charco que resbala y luego arde |
| Mangual | Mancuernas + Cadena | Golpe girando que empuja a todos alrededor |
| Mina despertador | Despertador + Bombona de gas | Se queda en el suelo y explota cuando pasa un zombi |
| Nube somnífera | Spray + Jeringuilla | Gas que duerme a los zombis unos segundos (guiño al VD-7, que es un somnífero) |
| Garfio | Cuerda + Perchas | Engancha a un zombi y lo arrastra hacia ti |

- Para que se usen todos los nuevos, alguna receta más **solo del centro** si hace falta (cinta americana, cable e
  hielo seco no entran en las seis): por ejemplo, un **bate helado** (bate + hielo seco) que congela.
- **Más adelante, como parte aparte** (lo decidió el dueño): los objetos de curar de la farmacia y el súper
  (vendas, comida que cura desde la mochila) y la ropa de la tienda de ropa para cambiar el aspecto de Johnny en las
  taquillas. Necesitan cosas que aún no existen (objetos que se usan, trajes).

## Historia

Dosier y noticias del centro comercial (`historia.gd`: una entrada más en `DOSIERES` y noticias nuevas).

### Decidido con el dueño (21 oct, para la parte 7): «Turno infinito»

- **La idea** (le encantó al dueño): tras el edificio, Velaria vende el VD-7 rebajado y sin receta («Velaria Noche»).
  El gerente del centro firma con Velaria un programa secreto, **«Turno infinito»**: VD-7 en el café de la sala de
  descanso de los empleados para que trabajen sin parar (turnos de 20 horas), sin que ellos lo sepan. Por eso los
  zombis del centro **siguen haciendo su trabajo**: la dependienta grita ofertas, el vigilante hace la ronda, el
  cocinero cocina...
- **Es una trampa:** Johnny va buscando respuestas, y el gerente sabe que viene. Quiere retenerlo para entregárselo
  a Velaria a cambio de «la dosis buena». A media vida se inyecta VD-7 para no parar nunca, y por eso muta.
- **El final, con gancho:** al caer el gerente llega un helicóptero de Velaria a por el Sujeto 0; Johnny escapa por la
  escalera de incendios. La última página nombra **la sede de Velaria**: el siguiente edificio (**Torre Velaria**, decidido en la parte 7).
- **Dosier del centro comercial** (5 páginas, una por planta; como en los Apartamentos, cada una en un muerto):

| Planta | Quién la lleva | Qué es | Lo que cuenta |
|---|---|---|---|
| Baja | Farmacéutico de Velaria | Albarán de la farmacia | 10.000 cajas de «Velaria Noche» sin receta. Nota: «¿Sin receta? ¿En serio?» |
| 1ª | Técnica de Velaria | Contrato «Turno infinito» | VD-7 en el café de los empleados para turnos de 20 horas; ellos no lo saben |
| 2ª | Jefe de seguridad del centro | Parte de incidencias | De noche siguen trabajando con los ojos cerrados. «Rinden más que nunca» |
| 3ª | Secretaria del gerente | Correo del gerente a Velaria | «El conserje del 14 está en el centro. Lo retengo hasta que llegue vuestro equipo. A cambio, quiero la dosis buena» |
| Azotea | El gerente, al caer | Orden de recogida | Un helicóptero de Velaria viene a por el Sujeto 0 al helipuerto; da el nombre de la sede |

- **Noticias nuevas de Canal 8** (unas 5, con la misma reportera): el centro cierra de noche «por reformas» (sale al
  completar los Apartamentos, que es cuando se abre el centro), Velaria saca su somnífero a la venta, trabajadores
  que no vuelven a casa, un audio del gerente, y al completar el centro: «un helicóptero de Velaria aterriza en la
  azotea... vacío». Como en las de ahora, Velaria va cambiando su versión para taparlo.
- ✅ **El guiño de la cafetera** (con la camarera de la parte 5): al arreglar la cafetera de la sala encuentra un doble
  fondo con cápsulas de VD-7 y te lo dice; desde entonces el café es solo café. La camarera ya no está (tres
  supervivientes por edificio): **lo descubre la farmacéutica** (decidido el 21 oct, en la parte 7).
- Los textos los escribe Claude y el dueño los lee antes de darlos por buenos (se pueden reescribir: todo está en
  `historia.gd`; lo único que no se toca es el `id` de una página ya publicada).

### ✅ Hecho (21 oct, parte 7; el dueño leyó los textos y le valen)

- **El dosier del centro comercial** (`historia.gd`, `DOSIERES` → `"centro"`), con las cinco páginas de la tabla:
  - Ids: `cc_albaran` (baja), `cc_turno` (1ª), `cc_incidencias` (2ª), `cc_correo` (3ª) y `cc_recogida` (azotea).
    **No se cambian**: el guardado apunta las páginas por su id.
  - Los cuatro primeros cuerpos salen como los científicos de los Apartamentos (uno por planta, mientras su página
    falte). Lo nuevo: el jefe de seguridad y la secretaria no llevan bata, sino su ropa (uniforme azul marino con
    chapa dorada y blusa rosa): `look` admite `ropa`, `pantalon` y `tarjeta` (`cientifico.gd`).
  - **La sede de Velaria se llama Torre Velaria** (la eligió el dueño entre tres): la orden de recogida lleva al
    Sujeto 0 «directo al laboratorio de la planta 40». Será el tercer edificio.
  - El gerente se llama Arturo Salcedo. La nota al pie de su página explica la mutación: «Me prometieron la dosis
    buena. Me mandaron una jeringa y esta hoja».
  - En el ordenador, la página del gerente que falta dice «La lleva el gerente del centro, arriba del todo, en la
    azotea. Tendrás que quitársela». Cada dosier tiene ahora su propia nota y su aviso de página que falta (los de
    los Apartamentos, igual que antes).
- **Cinco noticias nuevas de Canal 8** (`NOTICIAS`, emisiones 6 a 10), con las condiciones que ya había (no ha hecho
  falta ninguna nueva): `n_reformas` (al completar los Apartamentos), `n_velaria_noche` (con la página 1), `n_turnos`
  (con la 2), `n_audio` (con la 4) y `n_helicoptero` (al completar el centro). La 3ª planta no trae noticia, como el
  diario de los Apartamentos.
  - Lo que no decía el plan: con diez emisiones ya no cabían; la lista del programa Noticias tiene ahora su propio
    desplazamiento y la tele se queda quieta. Y la pista de las que faltan dice qué edificio completar.
- **Pendiente para el trozo 6 de la parte 4 (azotea y gerente):** al morir el gerente, llamar a
  `partida.pagina_del_jefe()`: si la orden de recogida falta, la apunta y la enseña con el juego parado (como al
  coger la de un muerto; `Historia.del_jefe` dice cuál es). Ya está probada en la foto de prueba
  (`captura-pagina-jefe.png`).
- ✅ **El guiño de la cafetera** (hecho el 21 oct, aparte del trozo de la farmacéutica): la primera vez que está en
  la sala después de rescatarla, huele el café y le dice a Johnny las tres frases de `Historia.CAFETERA`; desde
  entonces el café es solo café. Ver «Supervivientes».
- Fotos de prueba (`--captura --edificio centro`): `captura-cientifico.png` y `captura-pagina.png` (el farmacéutico
  de la planta baja), `captura-cuerpos.png` (los dos sin bata), `captura-dosier.png` (página 3),
  `captura-dosier-falta.png` (la del gerente, sin encontrar), `captura-pagina-jefe.png` y `captura-noticias.png`.
  Con `--captura` a secas, las de los Apartamentos, como siempre.

## Para que enganche (ideas aprobadas)

1. **Niveles de alerta**, como las ascensiones de *Isaac* o el calor de *Hades*: al completar un edificio se
   desbloquea Alerta 1 (más zombis o más rápidos, pero más dólares y objetos raros), luego Alerta 2, 3...
2. **Eventos sorpresa en una planta**: apagón (solo se ve con la linterna), alarma de incendios (los aspersores
   mojan el suelo y, con cables sueltos, peligro), horda que baja por las escaleras mecánicas, superviviente que
   vende cosas.
3. **Reto del día**: el mismo edificio para todo el mundo ese día (la misma semilla), con una regla rara ("solo
   cuerpo a cuerpo") y tu mejor marca. Sin servidor.
4. **Colecciones con porcentaje**: "Centro comercial: 23/40 objetos encontrados", y el bestiario de zombis.
5. **Salas opcionales con riesgo** (ver Las tiendas).
6. **La sala de mantenimiento crece** con cada superviviente (ver Supervivientes).
7. **Partidas cortas**, de 15-20 minutos (sobre todo por el móvil).

### Decidido con el dueño (21 oct, para la parte 8)

Entran las cuatro: niveles de alerta, eventos sorpresa, reto del día y colecciones con bestiario. **Las salas
opcionales con riesgo (la joyería), más adelante**: piden un tipo de tienda nuevo y objetos «muy buenos» que aún no
existen. Números provisionales (los puso Claude; se ajustan al probar):

- **Niveles de alerta, una regla fija por nivel** (como las ascensiones de *Isaac*), por edificio. Al completar un
  edificio se desbloquea su Alerta 1; al completarlo con Alerta 1, la 2, y así hasta la 5. Se elige en «Elige
  edificio». Las reglas se suman:
  - A1: +25 % de zombis.
  - A2: zombis un 10 % más rápidos.
  - A3: los jefes, con +25 % de vida y se enfadan antes.
  - A4: los botiquines curan la mitad.
  - A5: el guardia de la tarjeta (o la llave) aguanta el doble y los zombis te oyen más lejos.
  - Recompensa: +20 % de dólares por nivel y mejores rarezas en las armas que se crean en el banco.
- **Eventos sorpresa, a veces: 1 de cada 4 plantas**, nunca en la del jefe. En los dos edificios:
  - Apagón: solo se ve con la linterna.
  - Alarma de incendios: los aspersores mojan el suelo (resbala) y, donde hay cables, calambrazos.
  - Horda por las escaleras: las mecánicas en el centro, las de incendios en los Apartamentos.
  - Vendedor ambulante: un superviviente en el pasillo que vende cosas por dólares.
- **Reto del día:** cada día, el mismo edificio generado igual para todo el mundo (la semilla sale de la fecha) y una
  regla rara de una lista (solo cuerpo a cuerpo, todo a oscuras, sin botiquines, zombis rápidos...). Se guarda la
  mejor marca de cada uno (hasta qué planta llega y en cuánto tiempo). Sin servidor: solo compites contigo.
- **Colecciones:** un programa nuevo en ConserjeOS con, por cada edificio, los objetos encontrados (p. ej. 23/40),
  las páginas del dosier y las armas creadas, en porcentaje; y un **bestiario** con cada zombi que has visto, con su
  dibujo y una frase.

## Por partes

1. ✅ **El esqueleto** (21 oct): pantalla "Elige edificio" (con el candado), el edificio elegido en la partida, el
   generador de plantas con tiendas y sus habitaciones (con suelos y muebles de los que ya hay), la tarjeta de
   acceso y el guardia que la lleva. Lo que ha quedado:
   - Cada edificio es una ficha en `scripts/edificios.gd` (nombre, generador, cerrojo, jefe, avisos...). Las
     partes siguientes añaden datos ahí.
   - Las tiendas (`scripts/mapa/tienda.gd`): sala de venta grande delante y las habitaciones de dentro en fila
     contra la pared del fondo; el aseo, dentro del almacén, la cocina o la rebotica (nunca en la cámara). En
     cada planta, tiendas de tipos distintos, y siempre una con aseo para el superviviente. La farmacia lleva
     rebotica y aseo. De momento el jefe de cada planta sigue siendo la portera, en una "tienda destrozada".
   - **El guardia, hecho evento** (lo pidió el dueño): ronda el pasillo despacio; al verte toca el silbato y
     llegan refuerzos corriendo por las puntas del pasillo (2, y uno más cada dos plantas); huye a la punta más
     lejana, se cansa cada 3 s y se para a resoplar ("uf"); acorralado en una punta, pega; a media vida vuelve a
     silbar. Tiene 90 de vida (+20 % por planta) y si sales del pasillo, al volver sigue igual de herido. Al caer
     suelta la tarjeta (dibujada con código) y 2 billetes. Desde la parte 4 lleva el dibujo del vigilante.
2. ✅ **Cómo se ve** (21 oct): suelos, paredes, escaparates y muebles con PixelLab. Unas 120 generaciones (detalle y
   recetas en `assets/pixellab.json` → `centro-comercial`). Lo que ha quedado:
   - **Suelos, paredes y tapa** (`docs/FONDOS.md`): la galería (el pasillo: baldosa clara, paneles crema y su tapa gris
     clara, sin alfombra), la sala de venta (terrazo o vinilo, pared verde grisácea), almacén (hormigón con raya
     amarilla y bloques de hormigón), cámara (chapa con escarcha y paneles helados), cocina (baldosa roja y azulejo
     blanco), linóleo gris (taller, taquillas y rebotica) y moqueta (probadores). El aseo sigue con los del baño.
   - **El dueño pidió (tras la primera hoja) que nada pareciera limpio y que ningún mueble saliera girado.** Así que:
     - **Muebles rectos y destrozados**, pedidos con un boceto de su forma en la perspectiva del juego
       (`tools/guias_centro.py`): 17 de frente y 5 de lado (caja, perchero, banco de trabajo, fogón y banco de la
       galería, vistos desde arriba y pegados a la pared). **Los altos (estanterías, taquillas, neveras) solo van en
       la pared del fondo**: de lado, desde arriba, son una barra que no se entiende. **El carrito no está**: siempre
       salía en diagonal. Cada tipo de tienda tiene sus muebles (`Catalogo.SALAS`, "tienda-<tipo>").
     - **Restos sueltos** que el juego reparte al azar (siempre igual en cada sitio): charcos de sangre, cristales,
       latas, ropa, cascotes y papeles por el suelo; salpicones, huellas, pintadas y agujeros en las paredes. En las
       tiendas y la galería; los apartamentos no cambian.
     - **Escaparates rotos** (cristal reventado, pintadas, sangre) a los dos lados de las puertas de tienda de la pared
       de arriba del pasillo, y encima de la puerta un **letrero de neón** con su nombre (SUPER, FERRETERIA, ELECTRO,
       BURGER, MODA, FARMACIA) que dibuja el juego (`scripts/mapa/neon.gd`): una o dos letras fundidas, parpadeos y
       apagones, y una luz de su color en el suelo. Las puertas de abajo siguen con su cartel (de esa pared solo se ve
       la tapa).
   - **Filas en medio de las salas de venta** (lo pidió el dueño al verlo dentro): además de los muebles de las paredes,
     filas con pasillos (góndolas en el supermercado, mesas en el restaurante, perchas y maniquíes en la de ropa,
     estanterías en la ferretería y la farmacia, estanterías de teles en electrónica): "islas" de cada "tienda-<tipo>"
     en `Catalogo.SALAS` y `Muebles.islas`.
3. ✅ **Los peligros** (21 oct): frío, fuego y agua con corriente, todo dibujado con código (sin PixelLab). Los números
   y dónde va cada uno, en `scripts/peligros/peligros.gd`; cada peligro, su nodo en `scripts/peligros/`. Lo que ha quedado:
   - **Como los charcos, pero no se secan**: se deciden al generar la planta (cada tienda, siempre el mismo) y al volver
     siguen como se dejaron. Les hacen daño a Johnny y a los zombis despiertos (a los dormidos no) y la esquiva los
     cruza sin daño. Ningún zombi aparece dormido encima del fuego o del agua. La primera vez, Johnny lo dice
     ("¡Brrr! Qué frío hace en la cámara", "¡La cocina está ardiendo!", "¡Ojo! El agua tiene corriente").
   - **Frío** (la cámara del súper y la del restaurante): 3 de vida por segundo y un 40 % más lento; al salir dura
     1,5 s. Vaho al respirar, copos cayendo, tinte azul y escarcha en el borde de la pantalla. **Un zombi que pasa 4 s
     seguidos dentro se congela 2 s** (quieto y azul hielo; lo pidió el dueño).
   - **Fuego** (la cocina del restaurante): el fogón o la freidora arde siempre (con llamas encima) y cada 3 s cada
     casilla que arde puede prender una de al lado (35 %); cada una arde 15-25 s, deja ceniza y no vuelve a prender en
     10 s, así que se va moviendo. Como mucho, el 35 % del suelo de la cocina; nunca junto a las puertas ni en el camino
     hasta el aseo; no sale de la cocina. La primera vez que entras ya lleva 30 s ardiendo. Quema como el molotov
     (Johnny, 12 por segundo y sigue 2 s; los zombis se prenden). Su luz hace sombras: no se cuela a la sala de al lado.
   - **Agua con corriente** (la tienda de electrónica): un charco de 25-35 casillas en la sala de venta (lejos de las
     puertas y sin cortar el paso a las habitaciones del fondo) con un cable pelado que baja por la pared. Un calambrazo
     cada 1,2 s (rayos y fogonazo azul): Johnny, 10 de vida y tieso 0,4 s; zombis, 15 y aturdidos 1 s.
   - **El cuadro eléctrico** (pared de arriba del almacén o de las taquillas, nunca detrás de un mueble): plantándote
     delante bajas la palanca y vuelves a subirla. **El riesgo, como pidió el dueño, es que se va la luz**: con
     corriente, las estanterías de teles alumbran y la tienda está más clara que un piso (oscuridad 0,72); sin ella, el
     agua no hace nada pero la tienda se queda muy oscura (0,94) y solo se ve con la linterna. (En el plan era un
     chispazo 1 de cada 3 veces; se cambió.)
   - Para probarlo: `--captura --edificio centro --fotos-tiendas` saca también `captura-peligro-frio/fuego/agua/sin-luz/cuadro.png`.
4. **Zombis nuevos**, minijefes y jefe final, por trozos (ver «Decidido con el dueño»):
   - ✅ **Trozo 1: vigilante y dependienta** (21 oct; con el visto bueno del dueño, probado en el móvil). Animados con PixelLab (andar, ataque, golpe y muerte en las 8
     direcciones; 73 generaciones, detalle en `assets/pixellab.json` → `centro-comercial-parte4` → `trozo1`) y
     metidos en el juego con los números del plan:
     - **Vigilante** (`zombi_vigilante.tscn`): vida 45, velocidad 85, porrazo de 12 con más alcance. Sale en las
       tiendas desde la 1ª planta y son los refuerzos del silbato (antes, normales, rápidos y venenosos). El guardia
       de la tarjeta lleva su dibujo (sin el tinte azul) y hace lo mismo que antes.
     - **Dependienta** (`zombi_dependienta.gd`): vida 20, velocidad 95. Al despertar grita «¡OFERTAS!» (con su
       sonido): despierta a toda la tienda y todos, ella también, van un 30 % más rápidos durante 5 s. Luego guarda
       las distancias (se aparta si te acercas a menos de 200 y se acerca si te alejas a más de 300) y vuelve a gritar
       cada 8 s. Lo que no decía el plan: si la acorralas, te chilla en la cara y quita 6 (su «ataque» es el grito, sin
       zarpazo). En las tiendas desde la planta baja, una por tienda como mucho.
     - Cuestan 1,5 cada uno en el reparto de zombis de las tiendas; los Apartamentos no cambian.
     - Teclas de prueba **V** (vigilante) y **B** (dependienta); salen en la sala de exposición (F9), que se ha
       alargado para que quepan. `--captura --edificio centro --fotos-tiendas` saca `captura-grito.png` (el grito
       despertando a tres vigilantes) y dice qué zombis hay en cada tienda; `--captura`, `captura-expo-zombis.png`.
     - Pegas conocidas: el andar del vigilante no cierra del todo el ciclo en algunas direcciones y la dependienta,
       andando hacia arriba a la derecha, se gira un poco de perfil.
   - ✅ **Trozo 2: el antidisturbios y lo común de los minijefes** (21 oct). Lo que ha quedado:
     - **El sorteo:** al empezar cada partida del centro comercial se sortea el minijefe de cada planta (baja, 1ª, 2ª
       y 3ª, sin repetir; ficha `minijefes` y `MINIJEFES` en `edificios.gd`). Donde toca uno que aún no está hecho
       (cocinero, modista, mascota) sale la portera, y también en la 4ª planta (la que será la azotea).
     - **Su tienda** se llama según quién esté (Oficina de seguridad, Cocina central, Taller de costura, Juguetería):
       el cartel de la puerta (sin neón), la sala, el aviso de las escaleras, el de la tarjeta, el de "ha caído" y el
       nombre de la barra. Por dentro, el local destrozado de siempre.
     - **Lo común** (`scripts/minijefe.gd`): igual que la portera (aparece al entrar, barra grande, +25 % de vida por
       planta, se enfada a media vida con grito y vapor, al caer billetes, munición, objetos y la mutación).
     - **El antidisturbios** (`scripts/antidisturbios.gd`), con los números del plan. Detalles decididos al hacerlo:
       el escudo tapa un tercio de la vuelta por delante (y la espalda es otro tercio); a sus pies se ve un arco
       azulado por donde tapa; sigue tapando cuando está atontado. Solo anda hacia delante, así que para seguir a
       Johnny tiene que girarse. La carga avisa 0,8 s (la segunda seguida, 0,5) y corre como mucho 1,3 s; esquivando
       se la pasa de largo; si te pilla te quedas 0,7 s sin poder moverte ("tirado"). Atontado, estrellitas.
       Silbato cada 13 s si quedan pocos zombis: llegan vigilantes (los del trozo 1).
     - **Su dibujo**, animado con PixelLab sobre su modelo de 72: andar, porrazo, carga (se agacha tras el escudo),
       golpe (también cuando está atontado) y muerte en las 8 direcciones, y el silbato de frente. **42 generaciones**
       (detalle y textos en `assets/pixellab.json` → `centro-comercial-parte4` → `antidisturbios-72` → `animaciones`).
       Se monta con `py tools/jefe_hoja.py antidisturbios-72 jefe-antidisturbios`, que alinea por los pies los
       lienzos de PixelLab (cada animación viene de un tamaño) y borra las motas sueltas. Pegas conocidas: andando de
       frente y de espaldas casi no mueve las piernas; en la carga hacia la derecha el escudo lleva una franja negra
       con letras; el porrazo cae en un fotograma algo distinto según la dirección.
     - Tecla de prueba **K**; también en la exposición (F9, alargada otra vez). `--captura --edificio centro` lo saca en la 1ª planta,
       prueba el escudo (lo escribe en la terminal) y hace `captura-jefe.png`.
   - ✅ **Trozo 3: el cocinero** (21 oct), con sus animaciones. Lo que ha quedado:
     - **Ya sale en el sorteo** como el antidisturbios (su tienda, la Cocina central): `scripts/cocinero.gd` y
       `escenas/personajes/cocinero.tscn`, con los números del plan: vida 450 (+25 % por planta), velocidad 60.
     - **A media distancia:** si Johnny se acerca a menos de 200, se aparta (sin dejar de mirarle: anda hacia atrás);
       si se aleja a más de 360 o no le ve, va a por él; entre medias da pasitos de lado.
     - **Abanico:** 0,5 s de aviso (rayas rojas en el suelo por donde irán, mientras echa el brazo atrás) y 3
       cuchillos que giran (12 cada uno, a 340 y separados 0,28 rad). Solo si ve a Johnny; cada 2,4 s como mucho.
     - **Lluvia:** tira los cuchillos hacia arriba (0,5 s; se les ve subir) y caen 5 alrededor de Johnny (a entre 60
       y 150 de él), cada uno con su marca roja 0,8 s antes y uno tras otro cada 0,15 s; el primero, donde va a estar
       si sigue andando. 12 cada uno. Se quedan clavados 4 s (en el suelo; los del abanico, en la pared). Cada 6,5 s.
     - **Aceite hirviendo:** «¡CALENTITO!», 0,6 s de preparar el brazo y la sartén vuela 0,8 s con una marca roja
       donde caerá; deja un charco de 6 s (radio 60) que quema como el molotov: a Johnny, el estado fuego (12 por
       segundo y 2 s más al salir); a los zombis, los prende. Cada 8 s, si Johnny está a entre 120 y 480.
     - **Cuchillazo:** si Johnny está a menos de 140, 0,5 s de aviso (un trozo rojo, como el porrazo) y 20; le empuja
       un poco. Cada 1,4 s.
     - **Enfadado** («¡A LA OLLA!»): 5 cuchillos en el abanico y más rápidos (430), lluvia de 7 con la marca más
       corta (0,6 s) y todo más seguido (abanico 1,5 s, lluvia 4,5, sartén 6, cuchillazo 1).
     - **Decidido al hacerlo** (para contárselo al dueño): su propio aceite no le quema (es el cocinero), pero el
       fuego del molotov sí (si no, el molotov no le haría nada); a los demás zombis su aceite sí les quema. Los
       números que no daba el plan (distancias, esperas, lo que tardan las marcas, la lluvia de 7 enfadado) son de
       prueba: se ajustan jugando. En el código, su sartén es el proyectil "sarten" y su charco, "hirviendo" (el
       "aceite" es el de la bomba de aceite de Johnny, de la parte 6).
     - Los cuchillos (`cuchillo.gd`), la sartén (`proyectil.gd`) y el charco de aceite (`charco.gd`: una mancha
       dorada con burbujas que revientan y vapor) se dibujan con código.
     - **Su dibujo**, animado con PixelLab sobre su modelo de 72: andar, lanzar (brazo atrás y lanzamiento; vale para
       el abanico, la lluvia y la sartén), cuchillazo (tajo de arriba abajo), golpe (lo hace al enfadarse) y muerte en
       las 8 direcciones. **42 generaciones** (5 de la prueba de perfil, 35 de la tanda y 2 de repetir el lanzar de
       espaldas, que se daba la vuelta), más unas 5 de otra sesión que animó a la vez solo de perfil y no se usan
       (detalle en `assets/pixellab.json` → `centro-comercial-parte4` → `piezas` → `cocinero-72` → `animaciones`).
       Lo que lanza sale en el fotograma del brazo del todo adelante (4 en e, se, n y no; 5 en s, ne, o y so) y el
       cuchillazo hace daño en el del tajo (4 en s, se, e y n; 5 en ne, no, o y so). Se monta con
       `py tools/jefe_hoja.py cocinero-72 jefe-cocinero`, que además oscurece su sangre (PixelLab la pinta roja viva;
       se baja toda por igual, también el cinto rojo del delantal). Pegas conocidas: andando de frente y de espaldas
       es más balanceo que paso; al echar el brazo atrás el cuerpo gira algo hacia la cámara; en el lanzar hacia
       abajo el cuchillo se alarga como una hoja en un fotograma y hacia abajo a la izquierda sale una raya roja; en
       el tajo, una raya roja pegada al cuchillo; en el golpe se tuerce un poco de lado hacia arriba y hacia la
       izquierda.
     - Tecla de prueba **G**; también en la exposición (F9, alargada otra vez). `--captura --edificio centro --jefe
       cocinero` lo saca en la 1ª planta, comprueba que su aceite no le quema y hace `captura-jefe.png` (con el
       aceite, cuchillos clavados, la lluvia marcando el suelo y el abanico recién lanzado).
   - **Siguiente paso: la portera a 72 px** (el dueño lo pidió para que todos los jefes tengan el tamaño de un zombi
     grande): modelo nuevo copiando la de ahora (~6 generaciones, enseñárselo antes de seguir) y sus animaciones
     (andar, fregonazo, lanzar, grito y muerte; ~40). Unas 46-50 en total. Aprobado dejarlo para otra sesión.
5. **Supervivientes nuevos** con sus eventos (decidido: ver «Supervivientes»). ✅ Lo común, ✅ el rescate de la
   farmacéutica y ✅ el del técnico con su mejora; falta el rescate propio del ferretero y la mejora de la sala del
   ferretero y de la farmacéutica (un trozo para cada uno).
6. **Reparto de objetos** y recetas que mezclan edificios (decidido: ver «Objetos»), en dos trozos:
   - ✅ **Trozo A: los objetos** (21 oct). Los nueve nuevos con sus iconos dibujados con código y el reparto por
     edificio y por tienda (`Objetos.TIENDAS`, en `scripts/objetos.gd`). Las listas que aprobó el dueño:

     | Tienda | De siempre | Nuevos |
     |---|---|---|
     | Ferretería | clavos, hacha, llave inglesa, cuchillas, spray | cinta americana, cadena |
     | Electrónica | táser, extintor | batería, cable |
     | Restaurante | alcohol, gasolina, mechero, extintor | aceite, bombona de gas |
     | Supermercado | lejía, alcohol, mechero | hielo seco |
     | Farmacia | alcohol, lejía | jeringuilla |
     | Tienda de ropa | cuchillas, spray | perchas |

     - Todos los de la lista de una tienda salen igual de a menudo. En el pasillo se elige una tienda al azar y luego
       uno de su lista. El jefe de la planta suelta sus dos objetos seguros de su tienda (si no tiene, como en el pasillo).
     - Lo que no decía el plan: **el baúl pasa de 24 a 32 casillas** (8 por fila, para que siga cabiendo en la
       pantalla), porque con 26 objetos distintos y las armas creadas no cabían; y en el banco de trabajo, si hay más
       de 24 cosas, las casillas se hacen más pequeñas (10 por fila).
     - Tecla de prueba **U**: uno de cada objeto al baúl. `--captura` cuenta lo que sale en cada sitio de los dos
       edificios y saca `captura-objetos-nuevos.png`, `captura-banco-todo.png` y `captura-baul-todo.png`.
   - ✅ **Trozo B: las recetas** (21 oct). Las seis que mezclan los dos edificios y tres solo del centro, que el dueño
     aprobó: el banco de trabajo tiene ahora 24 recetas. Cada arma, con sus números en `Recetas.LISTA`, `Armas.CREADAS`
     y `Lanzables.ARROJADIZAS`, aprovechando lo que ya había:

     | Arma | Ingredientes | Tipo | Qué hace (con rareza verde) |
     |---|---|---|---|
     | Pistola eléctrica | pistola de agua + batería | a distancia | chispas (daño 5, 5 por segundo, depósito de 30) que aturden 0,4 s y saltan al zombi de al lado con medio daño, como la inmovilizadora |
     | Bomba de aceite | trapo + aceite | arrojadiza (3) | se rompe al caer, como el molotov; el charco resbala y a los 2 s arde: un fuego como el del molotov, un 25 % más grande |
     | Mangual | mancuernas + cadena | cuerpo a cuerpo | golpe en círculo (daño 16) que echa muy lejos a todos los de alrededor y los deja tirados medio segundo |
     | Mina despertador | despertador + bombona de gas | arrojadiza (2) | se queda en el suelo haciendo tic-tac (se ve el despertador) y, ya quieta, explota (90) cuando un zombi pasa cerca |
     | Nube somnífera | spray + jeringuilla | arrojadiza (3) | a los 1,2 s suelta una nube morada que dura 3 s: los zombis que pilla se duermen mientras están dentro y 3 s más, con sus «z» |
     | Garfio | cuerda + perchas | a distancia | sale con la cuerda (alcance 320), engancha al primer zombi (daño 8) y lo trae hasta delante de Johnny, aturdido; sin munición. A los jefes solo les pega |
     | Bate helado | bate + hielo seco | cuerpo a cuerpo | cada golpe (17) congela 1 s |
     | Látigo eléctrico | cable + batería | cuerpo a cuerpo | el alcance del látigo escorpión (daño 12) con la descarga de la inmovilizadora |
     | Bomba de clavos | cinta americana + clavos | arrojadiza (3) | explota (40) y lanza 14 clavos en todas direcciones que atraviesan, pinchan y hacen sangrar |

     - Los jefes no se congelan, ni se duermen, ni se dejan arrastrar, como pasaba ya con aturdir y prender.
     - `--captura` (en los dos edificios) prueba cada una contra zombis y saca `captura-arma-<receta>.png`.
7. ✅ **La historia:** dosier, noticias y el guiño de la cafetera (ver «Historia»). Pendiente: la página del gerente
   (trozo 6 de la parte 4).
8. **Extras:** niveles de alerta, eventos sorpresa, reto del día, colecciones (decidido: ver «Para que enganche»).
