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
  minijefes (y la portera a su nuevo tamaño); 3) cocinero; 4) modista; 5) mascota (rehecha a 72); 6) azotea y gerente.
  Coste previsto: unas 415 generaciones en total (54 ya gastadas en los 8 modelos).

## Supervivientes

### Decidido con el dueño (21 oct, para la parte 5)

- **Cuatro supervivientes nuevos, solo del centro comercial**, uno por cada tipo de tienda con trastienda. **Uno por
  partida, como ahora**: sale uno de los que aún no tienes, en una planta al azar (nunca la azotea); en los
  Apartamentos siguen saliendo el policía, la médica y el militar. Al rescatarlo se queda a vivir en la sala de
  mantenimiento para siempre y **la hace crecer** con algo suyo; como ahora, puede acompañarte (uno a la vez).
- **Cada uno con su propio rescate** (no la horda de siempre para todos), y **dibujados con código** (`persona.gd`),
  como los tres de ahora: gratis y con el mismo aspecto.
- Números provisionales (los puso Claude; se ajustan al probar):

| Quién | Dónde y cómo se le rescata | En la sala | Si te acompaña |
|---|---|---|---|
| **Camarera** | Encerrada en la cámara frigorífica del restaurante, congelándose: una barra de frío de unos 2 min desde que entras en la tienda; si se acaba, se pierde (esa partida) | Arregla la cafetera: cada partida empieza con un café, +25 de vida máxima esa partida | Tira platos: flojo (4) y de lejos, cada 1,5 s |
| **Ferretero** | Atrincherado en el almacén de la ferretería: la horda de siempre mientras quita la barricada (más corta, unos 2 min) | Monta su puesto: vende munición, molotovs y granadas por dólares | Martillazos de cerca (8) |
| **Farmacéutica** | Herida en la rebotica de la farmacia: escoltarla hasta las escaleras; anda despacio y van saliendo zombis; si la tumban, hay que levantarla (como ahora) | Cada partida empieza con un botiquín en la mochila | Los charcos de veneno y ácido te hacen la mitad |
| **Técnico** | En la tienda de electrónica con el agua electrificada: bajar la palanca del cuadro (la tienda a oscuras) y aguantar la horda a oscuras unos 90 s mientras arregla algo | Arregla las cámaras de seguridad: el minimapa enseña los zombis | Descarga cada 4 s: aturde 1 s al zombi más cercano |

- **Guiño para la historia (parte 7):** según el dosier, la cafetera de la sala se la regaló Velaria a Johnny y por
  ahí le metían el VD-7. Decidido en la parte 7: al arreglarla encuentra un doble fondo con cápsulas de VD-7 y te lo
  dice; desde entonces el café es solo café.
- Se hace por trozos, cada uno con su visto bueno: lo común (que salgan los nuevos en el centro y su sitio en la
  sala) y luego un superviviente por trozo.

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
- **Ocho objetos nuevos, solo del centro comercial** (iconos de 16×16 dibujados con código, `tools/objetos16.py`):

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
  escalera de incendios. La última página nombra **la sede de Velaria**: el siguiente edificio (nombre por decidir).
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
- **El guiño de la cafetera** (con la camarera de la parte 5): al arreglar la cafetera de la sala encuentra un doble
  fondo con cápsulas de VD-7 y te lo dice; desde entonces el café es solo café.
- Los textos los escribe Claude y el dueño los lee antes de darlos por buenos (se pueden reescribir: todo está en
  `historia.gd`; lo único que no se toca es el `id` de una página ya publicada).

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
5. **Supervivientes nuevos** con sus eventos (decidido: ver «Supervivientes»).
6. **Reparto de objetos** y recetas que mezclan edificios (decidido: ver «Objetos»).
7. **La historia:** dosier y noticias (decidido: ver «Historia»).
8. **Extras:** niveles de alerta, eventos sorpresa, reto del día, colecciones.
