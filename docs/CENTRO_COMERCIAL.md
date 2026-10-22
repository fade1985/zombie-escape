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
- **El gerente** (jefe final, grande como era la portera: unos 117 px; vida 1400): contratos que cortan en abanico
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
  - El rescate propio de la farmacéutica y su mejora (el botiquín al empezar) ya están hechos (ver abajo).
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
  - ✅ **Su mejora de la sala** (21 oct; lo decidió el dueño; con su visto bueno tras probarlo en el móvil): con
    ella rescatada, **cada partida, en los dos edificios, empiezas con un botiquín en la mochila**, y el cartel del principio lo dice («La Farmacéutica te ha
    preparado un botiquín: está en la mochila»).
    - Ocupa una casilla de la mochila. **Se usa desde el inventario**: lo eliges y pulsas **«Usar»** (con el mando
      o las flechas, la marca salta sola a «Usar»: A dos veces). Se cierra el inventario y cura como el de los
      baños (`partida.cura_botiquin()`: más con Sanitario y la mitad con la Alerta 4), con el número verde y las
      chispas encima de Johnny. **Con la vida llena** no se gasta: «Tienes la vida al máximo: guárdalo para luego».
    - Se puede **tirar al suelo** como los demás objetos. **No sirve para el banco** ni va al baúl: si no lo usas,
      se pierde al acabar la partida (en la siguiente te prepara otro).
    - Es la base para los objetos de curar de más adelante (vendas, comida): `Objetos.USABLES` en
      `scripts/objetos.gd` y `partida.usar_objeto()`.
    - `--captura --edificio centro` lo prueba (sin ella no hay botiquín; con ella, «Usar» con la vida llena no lo
      gasta y con la vida a medias cura y lo gasta; que no sale en el banco y que se tira) y saca
      `captura-farmaceutica-botiquin.png` (el inventario con el botiquín elegido).
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
- ✅ **El rescate propio del ferretero y su puesto** (21 oct; `scripts/barricada.gd`, `scripts/mapa/mostrador.gd`
  y `scripts/ui/puesto.gd`; números provisionales; con el visto bueno del dueño tras probarlo en el móvil):
  - Grita desde el almacén de la ferretería, como antes, pero su puerta tiene **cuatro tablas clavadas** (la
    barricada). Al limpiar la tienda no se abre: dice «¡Espera, que quito la barricada!» y, al segundo, **la entrada
    de la tienda se cierra de golpe** y empieza la horda allí mismo (no hay que ir a la salida).
  - **2 minutos de trabajo**. Arriba, la barra «Ferretero quita la barricada · 1:45». Grupos cada 6 s al principio
    y cada 3 s al final, de 2 a 5 zombis, 30 a la vez como mucho; los primeros 50 s lentos y normales, y luego
    también rápidos y algún explosivo. Entran por el taller u otras habitaciones de la tienda (nunca por su almacén)
    o por la entrada, y él avisa de por dónde.
  - Él está dentro (no se le ve y no le pueden tumbar): **lo que se defiende es la puerta**. Los zombis que la
    pillan más cerca que a Johnny, o todos si Johnny se aleja más de 300, van a aporrearla (tiembla); y **mientras
    haya un zombi a menos de 70 de la puerta, él no avanza**: la barra se pone roja («¡Están empujando la puerta!
    Quítaselos») y él se queja («¡Me están empujando la puerta!»).
  - Las tablas van cayendo según avanza (una cada cuarto, con astillas). Lo que dice sale encima de la puerta,
    como sus gritos («¡Cuántos clavos le metí!», «Esta tabla no sale…»…). A mitad, **por debajo de la puerta**,
    un molotov, una granada y dos cajas de munición.
  - Al acabar: «¡Barricada fuera! La entrada se ha abierto», se abre su puerta («¡Fuera tablas! Gracias, chaval.
    Vámonos de aquí»), cuenta para «Buen vecino» y se une al arrimarte, como siempre. Al salir con él ya no hay otra
    horda.
  - **Su puesto**: cuando ya vive en la sala, atiende **detrás de un mostrador** dibujado con código (la franja
    naranja de su chaleco, el letrero «Ferretería» y, encima, una caja de munición, un molotov y una granada). Al
    arrimarte por delante se para el juego y sale la ventanita del puesto, con tres tarjetas: **munición (un
    cargador) $2, molotov $3 y granada $4**, cada una con lo que llevas. Se paga con los **dólares ahorrados** (como
    en el ordenador) y lo comprado es para esa partida. Si ya vas lleno («No te cabe…»), si tu arma no usa balas o
    si no te llega («No te llega: te faltan $2»), lo dice. Con el ratón o el dedo, con flechas e Intro (o 1, 2 y 3)
    o con el mando (cruceta y A); Esc o B cierra.
  - Para que te acompañe, hay que **rodear el mostrador** y arrimarse a él. El puesto sigue abierto aunque te
    acompañe. Lo que no decía el plan: en la sala su nombre va debajo del mostrador (no encima del letrero).
  - Con el ferretero, en el centro comercial ya ninguno tiene la horda de siempre: la prueba de la horda solo sale
    en los Apartamentos.
  - `--captura --edificio centro` prueba la barricada entera y el puesto (lo escribe en la terminal) y saca
    `captura-ferretero-barricada.png`, `captura-ferretero-empujan.png`, `captura-ferretero-sala.png`,
    `captura-ferretero-puesto.png` y `captura-ferretero-compra.png`.

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
  (vendas, comida que cura desde la mochila; ya se puede usar algo desde el inventario: el botiquín de la
  farmacéutica, `Objetos.USABLES`) y la ropa de la tienda de ropa para cambiar el aspecto de Johnny en las
  taquillas. Les falta lo suyo: cada objeto de curar, y los trajes.

### ✅ Hecho (22 oct 2026, parte 9: los objetos de curar)

- **Dos objetos nuevos, solo del centro comercial**: las **vendas** (las suelta un zombi de la farmacia; curan 25) y
  el **bocadillo** (del supermercado; cura 15). Salen como los demás objetos (la misma probabilidad), van en la
  mochila y se usan desde el inventario con «Usar», como el botiquín de la farmacéutica. No van al baúl ni entran en
  recetas: lo que no uses se pierde al acabar la partida.
- Están en `Objetos.NOMBRES` y `Objetos.TIENDAS` (así cuentan en Colecciones: el centro pasa de 21 a 23 objetos, con
  su tienda debajo) y en `Objetos.USABLES`, con lo que curan (`"cura"`). La partida pregunta `cura_de(id)` (en
  `partida.gd`): lo suyo más el talento Sanitario y, con la Alerta 4, la mitad; los textos del talento y de la
  alerta lo dicen. Iconos de 16×16 con código, `obj-vendas.png` y `obj-bocadillo.png` (`tools/objetos16.py`, 28 ya).
- **El vendedor ambulante** también los vende (vendas $4, bocadillo $3): van a la mochila, para cuando hagan falta.
  Su «objeto sorpresa» sigue siendo chatarra para el banco (`Objetos.al_azar(..., true)`).
- **El reto del día «Sin botiquines» pasa a llamarse «Sin curas»** (`curas` en `reto.gd`): además de los armaritos
  vacíos y sin el botiquín de la farmacéutica, los zombis no sueltan vendas ni bocadillos y el vendedor no vende
  nada que cure.
- La tecla de prueba U (uno de cada objeto al baúl) no mete los de curar.
- Prueba: la larga (`--captura`, con o sin `--edificio centro`), en `probar_curas`: con la vida baja y los dos en la
  mochila, saca el inventario con las vendas elegidas (`captura-vendas.png`), usa cada uno y cuenta la vida antes y
  después; dice dónde salen, que no entran en recetas, que el vendedor los vende y los 23 objetos de Colecciones.

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
- ✅ **La página del gerente** (trozo 6 de la parte 4, parte 3): al caer el gerente mutado, la partida llama a
  `pagina_del_jefe()`: si la orden de recogida falta, la apunta y la enseña con el juego parado (como al coger la de
  un muerto). Al cerrarla llega el helicóptero de Velaria.
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
- **El orden** (21 oct, con el dueño): cuatro trozos, cada uno con su visto bueno: 1) niveles de alerta, 2) eventos
  sorpresa, 3) colecciones (después de juntar la parte 6, que reparte los objetos por edificio) y 4) reto del día
  (un botón en cada tarjeta de «Elige edificio»; los dólares cuentan como siempre, pero no abre alertas ni cuenta
  como edificio completado).

### ✅ Hecho (21 oct, parte 8, trozo 1: niveles de alerta)

- Las reglas y sus números, en `scripts/alerta.gd` (como estaban arriba). La partida solo le pregunta: el
  presupuesto de zombis de cada sitio (A1), la velocidad de los que no son jefes (A2), la vida de los jefes y a qué
  parte de ella se enfadan: al 70 % en vez de a la mitad (A3, en `portera.gd` y `minijefe.gd`, así que también en
  los minijefes que vengan), lo que cura el botiquín (A4) y el guardia, y el oído de los zombis: los disparos se oyen
  a 1,5 veces la distancia (A5).
- **Lo que cambia respecto al plan: los Apartamentos en la A5** (no tienen guardia). Allí la llave no está en el
  suelo: la lleva un vecino zombi, con la llave flotando encima, que espera en esa habitación y aguanta el doble
  (como el guardia: +20 % por planta); al caer la suelta.
- Recompensas: los dólares de más (+20 % por nivel) se suman al completar el edificio, y el cartel del final lo
  dice aparte («De ellos, por la Alerta 2»). En el banco, las rarezas pasan de 75/20/5 % (verde/azul/morada) a
  30/50/20 % con la A5 (cada nivel: −9, +6 y +3 puntos).
- En «Elige edificio», debajo de cada tarjeta abierta: «< Alerta 2 (de 3) >», con su regla y su recompensa
  debajo; sin ninguna abierta, «Complétalo para abrir la Alerta 1». Se recuerda la última elegida. Al empezar la
  partida, el aviso dice la alerta y su regla; al completar el edificio con la más alta abierta, se abre la
  siguiente y el cartel del final lo celebra.
- Guardado: `alerta_max` y `alerta` en el progreso de cada edificio. Icono nuevo: `assets/ui/iconos/alerta.png`
  (`tools/icono_alerta.py`).
- Prueba: `--captura --alerta N` (con o sin `--edificio centro`): los números de cada regla en la terminal,
  `captura-alerta.png`, `captura-alerta-llave.png` y `captura-alerta-fin.png`. Para comparar plantas con y sin
  alerta, `Planta.semilla` hace que salgan iguales (servirá también para el reto del día).
- Lo que salió al probar: con la A1 el presupuesto sube un 25 %, pero no todo cabe. En los Apartamentos salen un
  13 % más de zombis y más duros (su «coste» sube un 30 %); en el centro comercial, solo un 8 % más (coste +13 %),
  porque las tiendas se llenan antes. Si se quiere más, se sube `MAS_ZOMBIS`.

### ✅ Hecho (21 oct, parte 8, trozo 2: eventos sorpresa)

- Todo en `scripts/eventos.gd` (y el vendedor en `scripts/vendedor.gd`), con sus números en constantes. En cada
  planta menos la última, una de cada cuatro veces (25 %): en 2000 partidas sorteadas sale de media uno por partida
  (sin ninguno, 31 %; uno, 43 %; dos, 21 %; tres o cuatro, 5 %). En una partida no se repite ninguno. Con
  `Planta.semilla` (el reto del día) salen los mismos para todos.
- Empieza la primera vez que Johnny pisa el pasillo de la planta (en la planta baja, al salir de la sala de
  mantenimiento): un cartel grande arriba en el centro («¡APAGÓN!» y una frase), con su sonido, y mientras dura, el
  nombre del evento junto al del sitio, arriba a la derecha. Dura toda la planta. En la sala del jefe y en la de
  mantenimiento no pasa nada.
- **Apagón:** a oscuras del todo (la oscuridad del sitio +0,4, hasta el tope) y todas las lámparas, apliques y
  neones apagados: solo se ve con la linterna.
- **Alarma de incendios:** suena la sirena (al empezar y cada 12 s), llueve de los aspersores y en cada sitio hay de
  4 a 9 charcos de agua que resbalan como la lejía (sin hacer daño); al volver a un sitio siguen donde estaban. En
  dos de ellos (en los sitios pequeños, uno) hay un cable pelado que chisporrotea y cada 1,6 s da un calambrazo a
  todo el charco: a Johnny, 10 de vida y tieso un momento; a los zombis despiertos, 15 y aturdidos (los números del
  agua de la tienda de electrónica). Avisa la primera vez que te acercas.
- **Horda por las escaleras:** a los 4 s bajan zombis por la puerta de las escaleras del fondo del pasillo, de uno en
  uno, en tres oleadas de 4, 6 y 8 (+15 % por planta, y con la Alerta 1, más), cada vez peores (en el centro
  comercial, también vigilantes). Entre oleada y oleada, 10 s, o enseguida si ya no queda ninguno. Si Johnny se mete
  en una tienda o un piso, los que quedan le esperan en el pasillo. Premio: 3 billetes (+1 por planta) y una caja
  de munición.
- **Vendedor ambulante:** un superviviente con una mochila enorme y una manta en el suelo con lo que vende, contra la
  pared de arriba del pasillo, a un lado del ascensor. Los zombis no le hacen caso. Al arrimarse, el juego se para y
  sale su puesto: tres cosas sorteadas, cada una una vez (botiquín $8, caja de munición $3, molotov $5, granada $6,
  chaleco +30 de escudo hasta la planta siguiente $10, objeto sorpresa para el banco $6). Paga con los dólares de la
  partida y, si no llegan, con los ahorrados. No deja comprar lo que no sirve (con la vida llena, sin sitio...).
- **Lo que cambia respecto al plan:** nada de lo decidido; solo los detalles de arriba (el chaleco usa el icono del
  casco, y la horda baja por la puerta de las escaleras, no por unas escaleras dibujadas).
- Prueba: `--captura --evento apagon|incendio|horda|vendedor` (con o sin `--edificio centro`). La prueba larga sigue
  sin eventos.

### ✅ Hecho (22 oct 2026, parte 8, trozo 3: colecciones y bestiario)

- Un programa nuevo en ConserjeOS, **Colecciones** (`COLECCION.EXE`, en `scripts/ui/ordenador.gd`), con una ficha por
  edificio: objetos encontrados, armas creadas y páginas del dosier, cada una con su cuenta y su porcentaje; y el
  **bestiario**: una ficha por enemigo y, en las de los vistos, su dibujo de frente, su nombre y una frase. Icono
  nuevo: `assets/ui/iconos/colecciones.png` (`tools/icono_colecciones.py`), un álbum de pegatinas. Mientras haya algo
  nuevo desde la última vez, el icono dice «¡NUEVO!»; al abrir el programa se apaga.
- Guardado (para siempre, entre partidas): `encontrados`, `creadas`, `bestiario` y `colecciones_nuevo`. Un guardado de
  antes se rellena una vez con lo que haya en el baúl (objetos con más de 0 y las recetas de `baul_armas`).
- Dónde se apunta: un objeto, al cogerlo del suelo (`soltar_objeto` de `partida.gd`) o al comprárselo al vendedor
  ambulante (`vendedor.gd`); un arma, al crearla en el banco (`inventario.gd`), y cuenta como creada alguna vez,
  aunque luego se pierda; un enemigo, cuando aparece en la sala donde estás (`meter_zombi` de `partida.gd`, por donde
  pasan todos), más el gerente al mutar (`gerente.gd`) y el maniquí vivo de la modista (`modista.gd`). El bestiario
  apunta en memoria y solo escribe el guardado la primera vez que ve a cada uno.
- Las cuentas: los objetos, por edificio, 17 en los Apartamentos y 21 en el centro comercial (los explosivos cuentan
  en los dos: los suelta el zombi explosivo); debajo de cada objeto, dónde sale (en el centro, sus tiendas). Las
  recetas, 15 de los Apartamentos y 9 del centro (las 6 que mezclan los dos edificios y las 3 solo del centro). El
  bestiario, 17 fichas (`scripts/bestiario.gd`): los seis zombis de siempre, la portera, la dependienta, el vigilante,
  el guardia de la tarjeta, los cuatro minijefes, el maniquí, el gerente y el gerente mutado. Los textos del bestiario
  están en `scripts/bestiario.gd`; el dueño los retocará al verlos en el juego. El dibujo de cada ficha es el fotograma
  de frente de su hoja, recortado a lo dibujado (el recorte lo calcula `py tools/recortes_bestiario.py` y queda escrito
  en `bestiario.gd`, para no leer imágenes en el juego); a tamaño del juego, salvo el gerente y su mutación, a la mitad
  para que quepan con la frase.
- Tecla de prueba **F8**: todo encontrado, creado y visto (y el aviso de nuevo puesto).
- Prueba: la larga (`--captura`, con o sin `--edificio centro`), en `probar_colecciones`, deja en el guardado parte
  de lo que hay y saca `captura-escritorio-nuevo.png` (el icono con el aviso), `captura-colecciones.png` (los objetos
  del edificio), `captura-bestiario.png` (la ficha del vecino) y `captura-bestiario-falta.png` (la del gerente, sin
  ver); en la terminal, lo encontrado, creado y visto de cada edificio, y avisa si los totales no cuadran.

### ✅ Hecho (22 oct 2026, parte 8, trozo 4: reto del día)

- Todo en `scripts/reto.gd`: cada día, el edificio sale igual para todo el mundo y con una regla rara, **la misma
  para los dos edificios ese día**. La semilla de las plantas (`Planta.semilla`, la del trozo 1) sale de la fecha y
  del edificio, y la partida pone también el dado de siempre con ella al empezar, así que el orden de los minijefes,
  la planta del superviviente y los eventos sorpresa salen iguales para todos; lo que pasa dentro ya depende de cada
  jugador. La regla sale de la fecha. Sin servidor: solo compites contigo.
- **Las siete reglas** (números en constantes de `reto.gd`; cada una se mira en una línea del sitio donde se aplica):
  - *Solo cuerpo a cuerpo*: la pistola empieza vacía, no caen cajas de munición ni molotovs ni granadas, el vendedor
    ambulante y el puesto del ferretero no los venden, y la ayuda «Pistola sin fin» no vale.
  - *Todo a oscuras*: todos los sitios menos la sala de mantenimiento como en el apagón (la misma oscuridad de más y
    las lámparas apagadas: `eventos.gd`, `al_montar`); ese día el apagón no se sortea.
  - *Sin curas* (se llamó «Sin botiquines» hasta la parte 9): los armaritos de los baños salen vacíos, la farmacéutica
    no te prepara el suyo, los zombis no sueltan vendas ni bocadillos y el vendedor no vende nada que cure.
  - *Zombis rápidos*: todos un 35 % más rápidos (los jefes, no).
  - *De cristal*: Johnny con la mitad de vida.
  - *Casa llena*: el doble de presupuesto de zombis en cada sitio (y en las oleadas de la horda).
  - *Oído fino*: los zombis dormidos oyen los disparos desde el triple de lejos.
- **Qué cuenta y qué no:** como siempre, los dólares (solo si lo completas), los zombis matados, las partidas, los
  supervivientes rescatados, las colecciones, los logros y los objetos al baúl. No cuenta como edificio completado:
  no toca «Completado», las victorias, la mejor planta ni el mejor tiempo del edificio, y va sin alerta y no abre
  ninguna.
- **Guardado:** `retos`, una ficha por edificio (`Guardado.RETO`): la fecha, la regla, los intentos, la planta más
  alta de hoy y, si se ha completado, el mejor tiempo. Si la ficha es de otro día, se empieza de cero: el reto es
  nuevo. Mejor marca = llegar más lejos; con el edificio completado, hacerlo en menos tiempo.
- **Cómo se ve:** en «Elige edificio», debajo del selector de alerta de cada tarjeta abierta, el botón «Reto del
  día» (con el trofeo) y, debajo, «Hoy: Casa llena» y tu marca («Aún no lo has intentado», «Has llegado a la
  planta 3 (2 intentos)» o «Completado en 12:34 (3 intentos)»). En la partida, el aviso del principio dice la regla
  y, arriba a la derecha, junto al nombre del sitio, «· Reto: Casa llena». Al acabar, el cartel dice «¡Reto
  completado!» (o «¡Derrota!») con una línea «Reto del día · Casa llena» y la marca: en amarillo, «¡mejor marca de
  hoy!» si la has mejorado. «Jugar otra vez» repite el mismo reto.
- **Lo que cambia respecto al plan:** nada; la regla es la misma para los dos edificios (más fácil de contar).
- Prueba: `--captura --reto si` (o `--reto oscuras`, `--reto cuerpo`... para forzar una regla; con o sin
  `--edificio centro`): comprueba que la 1ª planta sale igual dos veces con la semilla de hoy y distinta con la de
  otro día, dice en la terminal lo que cambia cada regla y cómo queda el primer piso con la que se juega, y saca
  `captura-reto-tarjeta.png` (la tarjeta con el botón y una marca inventada), `captura-reto.png` (el aviso),
  `captura-reto-piso.png`, `captura-reto-derrota.png` (caída en la 2ª planta) y `captura-reto-fin.png` (completado,
  con la marca mejorada); al final mira el guardado: la marca de hoy, y que el edificio sigue igual.

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
   - ✅ **Trozo 3: el cocinero** (21 oct), con sus animaciones y con el visto bueno del dueño (probado en el móvil, tal cual: el molotov sí le quema y el cinto del delantal queda oscuro). Lo que ha quedado:
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
   - ✅ **Trozo 4: la modista** (21 oct). Lo que ha quedado:
     - **Su tienda, el Taller de costura**, llena de maniquíes de cuerpo entero (unos 23) con su mismo vestido: un
       mueble nuevo, `tallmannequin` (PixelLab, 1 generación), en filas por la sala y por las paredes ("jefe-modista"
       en `catalogo.gd`). Decidido con el dueño: mejor que el busto de la tienda de ropa, que es más bajo que ella.
     - **Ella** (`scripts/modista.gd`), con los números del plan. Detalles decididos al hacerlo: al entrar ya está
       escondida en el sitio de un maniquí. Escondida se queda de frente y quieta, sin hacer daño al tocarla; si
       Johnny se acerca a menos de 130 o le pega, da un respingo («¡SSSS!») y salta con el tijeretazo o los
       alfileres. Se cambia de sitio cada 7 s (enfadada, 4,5) con un maniquí lejos de Johnny: le brillan los ojos
       0,6 s (si le pegas entonces, no se va) y otra vez un momento al llegar. La ráfaga son 5 alfileres (7
       enfadada) con una raya en el suelo que sigue a Johnny hasta 0,2 s antes de tirar. Los alfileres y el brillo
       de los ojos, dibujados con código (el brillo se ve también a oscuras).
     - **Los maniquíes que cobran vida** (`scripts/maniqui_vivo.gd`): al enfadarse, 3 de los de la tienda (si no
       hay, aparecen a su alrededor). Tiemblan al despertar; solo se mueven (a 165, bamboleándose) cuando no están
       delante de Johnny o hay algo en medio; si te tocan moviéndose, 10. Vida 45; al caer la modista se caen todos.
     - Tecla de prueba **T**; también en la exposición (F9, alargada otra vez). `--captura --edificio centro --jefe
       modista` la saca en la 1ª planta, cuenta los maniquíes, la cambia de sitio, despierta a tres y hace
       `captura-jefe.png` con ella tirando alfileres.
     - **Escondida, el apuntado automático no la busca** (`johnny.gd`): en el modo asistido Johnny se giraba solo
       hacia ella y la descubría. Hay que encontrarla o pegarle a mano.
     - **Su dibujo:** el modelo, delgado, se quedó así (lo decidió el dueño). Piel corregida con `piel.py` (ahora
       admite la fila de los zapatos y la saturación máxima, para no tocar la cinta métrica) y subida como personaje
       nuevo (0,25). Animada con PixMiniMax sobre ese modelo, con la receta del antidisturbios: andar, alfileres,
       tijeretazo, golpe (el respingo al pillarla) y muerte, en las 8 direcciones. **41,25 generaciones** en total
       (con el maniquí; detalle y textos en `assets/pixellab.json` → `centro-comercial-parte4` → `trozo4`). Se monta
       con `py tools/jefe_hoja.py modista-72 jefe-modista`. Pegas conocidas: andando hacia arriba a la derecha se
       pone algo de perfil a mitad del paso; el tijeretazo lleva un tajo blanco grande (se ha dejado: se lee como el
       corte); en el golpe, el primer fotograma lleva una raya blanca en varias direcciones (el juego se lo salta).
   - ✅ **Trozo 5: la mascota** (21 oct). Lo que ha quedado:
     - **La mascota** (`scripts/mascota.gd`, `escenas/personajes/mascota.tscn`), con los números del plan (vida 420,
       +25 % por planta; velocidad 140). **Embestida:** se pone mirando a Johnny, rasca el suelo 0,6 s (enfadada,
       0,4 s) con la franja roja marcando por dónde irá y sale a 520, como mucho 1,1 s; si te pilla, 22 y te tira;
       esquivando se la pasa de largo; si se estrella contra una pared o un mueble, mareada 1,8 s con estrellitas.
       **Salto:** se agacha 0,35 s y salta hacia donde estás; en el aire (0,8 s, no se le puede dar) se ve en el
       suelo su sombra creciendo con un aro rojo donde va a caer; al aterrizar, 18 y empuja a lo que esté en el
       círculo (radio 90), con temblor y polvo. Grita «¡ABRAZOS GRATIS!» al embestir.
     - **Lo que cambió respecto al plan:** el mareo no tiene animación propia: usa el golpe, con balanceo y
       estrellitas hechos con código; enfadada (3 embestidas seguidas) **rebota en las paredes** («¡BOING!») y solo
       se marea si se estrella en la última; el salto se dibuja en tres tiempos (agacharse, aire y caída) y la
       altura la pone el código (`ALTURA_SALTO` 150), no el dibujo.
     - **Lo común pasó a `minijefe.gd`:** la carrera en línea recta (`embestir()`, `pared_chocada()`,
       `estrellarse()`), la franja roja y el estado "atontado" con estrellitas, que ahora usan la mascota y el
       antidisturbios (que se comporta igual que antes).
     - **Su dibujo:** modelo nuevo a 72 copiando el de 128 (6 generaciones) y animaciones de PixelLab sobre él:
       andar, embestida, salto, golpe y muerte en las 8 direcciones. **47 generaciones en total** (detalle, textos y
       pegas en `assets/pixellab.json` → `centro-comercial-parte4` → `mascota-72` → `animaciones`). Se monta con
       `py tools/jefe_hoja.py mascota-72 jefe-mascota` (su ficha en `JEFES` le quita a la embestida el primer
       fotograma, que sale de pie). Pegas conocidas: el golpe gira la cara de tres
       cuartos hacia la cámara en unos 4 de 9 fotogramas (el dueño lo dio por bueno); al aterrizar el salto deja
       alguna nube de polvo dibujada; andando de frente y de espaldas es sobre todo balanceo, y a mitad del ciclo
       gira un poco la cabeza.
     - Tecla de prueba **J** (la **U** es de los objetos); también en la exposición (F9, con una fila más). `--captura --edificio centro --jefe
       mascota` hace `captura-jefe.png` con la mascota saltando y su sombra (con `--jefe <nombre>` vale para
       cualquier jefe).
   - **Trozo 6: la azotea y el gerente**, en tres partes con el visto bueno del dueño en cada una (decidido el 21 oct:
     1) la azotea; 2) el gerente con su dibujo y sus ataques; 3) la mutación y el final, con el helicóptero de Velaria
     al caer el gerente; los aparatos de la azotea, con PixelLab).
     - ✅ **Parte 1: la azotea** (21 oct). Lo que ha quedado:
       - El centro comercial tiene ahora la planta baja y tres plantas con tiendas (cada una con su minijefe) y,
         encima, **la azotea** (la 5ª: `Planta.azotea`, ficha `azotea`, `final` y `el_final` en `edificios.gd`). Los
         Apartamentos no cambian. Es un sitio "jefe" sin pasillo: el jefe aparece al llegar, en medio del helipuerto,
         y al caer se abre la salida.
       - Un espacio abierto de 44 × 30 casillas (como en el juego JS), más grande que la pantalla. **Suelo de
         hormigón** con sus losas, juntas, grava y grietas; **el murete**: arriba se le ve de frente, bajito, con la
         ciudad de noche detrás (edificios con ventanas encendidas y estrellas), y en los lados y abajo, su remate
         visto desde arriba; **el helipuerto pintado** (el círculo amarillo y la H, gastados). Todo esto, dibujado con
         código (`tools/azotea.py`). Restos sueltos por el suelo (sangre, latas, cascotes y papeles, sin ropa y menos
         que en las tiendas) y manchas de sangre.
       - **Los aparatos**, con PixelLab (4 generaciones, con las guías de `tools/guias_azotea.py`): aire acondicionado
         (con dos ventiladores), climatizadora (una caja larga con su conducto), chimenea de ladrillo y extractor de
         turbina. Van sueltos (2-3, 1-2, 2-3 y 3-4), lejos unos de otros, del helipuerto y de las puertas, para que
         sirvan de cobertura y se pueda pasar entre ellos.
       - **Se llega por la izquierda**, por la escalera, que se cierra detrás («¡La puerta se ha cerrado detrás de
         ti!»; luego, «Ya no hay vuelta atrás»). Al llegar: «Azotea · ¡El último combate del edificio!». **A la
         derecha, la escalera de incendios** (peldaños de rejilla y barandilla roja, dibujados con código en
         `puerta.gd`), con una cinta de peligro mientras siga cerrada. Al caer el jefe: «¡… ha caído! La escalera de
         incendios ya está abierta», y por ahí se acaba el edificio.
       - Mientras no esté el gerente (parte 2), en la azotea sale la portera.
       - Tecla de prueba **N**: derecho a la azotea. `--captura --edificio centro` acaba en la azotea y saca
         `captura-azotea.png` (al llegar, con el jefe), `captura-azotea-entera.png` (entera, sin penumbra) y
         `captura-azotea-incendios.png` (quitado el jefe, con la escalera abierta).
     - ✅ **Parte 2: el gerente, con su dibujo y sus ataques** (21 oct). Lo que ha quedado:
       - **Su dibujo**, animado con PixelLab sobre el modelo aprobado (`gerente-128`, 117 px, como la portera): andar,
         lanzar contratos y maletinazo en las 8 direcciones, y «¡A TRABAJAR!» y pincharse la jeringa, solo de frente
         (la jeringa es para la parte 3). Hoja `jefe-gerente` (`py tools/jefe_hoja.py gerente-128 jefe-gerente`).
         Costó **33 generaciones** (lo previsto eran ~30): 26 y 7 repeticiones de las que se giraban de espaldas
         (andar arriba a los lados, contratos arriba-derecha y maletinazo arriba y arriba a los lados).
       - **Pegas que quedan:** el maletinazo arriba-derecha mira a la cámara 2 fotogramas al levantar el maletín y
         arriba-izquierda se pone de perfil; los contratos arriba-derecha, de lado a mitad del lanzamiento (se le ve
         la corbata); al lanzar dibuja un barrido blanco (aunque se le pidió que no) y de frente los papeles le caen a
         los pies. Cada ataque dura menos de un segundo.
       - **`gerente.gd`** (hereda de `minijefe.gd`): **1400 de vida justa** (sin el 25 % más por planta de los otros
         jefes) y la barra dice «El gerente». Anda despacio hacia Johnny rodeando los aparatos y, con aviso, hace tres
         cosas: **contratos** (rayas rojas en el suelo 0,6 s y 5 hojas de papel en abanico que cortan 10 cada una; los
         paran los aparatos y las paredes: `contrato.gd`, dibujado con código), **maletinazo** si Johnny se acerca
         (trozo de suelo rojo 0,5 s; 20 y le aparta de un empujón) y **«¡A TRABAJAR!»** si quedan pocos zombis (como
         mucho 1): grita y llegan dos dependientas y un vigilante (cada 15 s como mucho).
       - **A media vida**, de momento, se enfada como los minijefes («¡ESTÁS DESPEDIDO!», vapor y rojo): 7 contratos
         más rápidos y todo más seguido. La jeringa de VD-7 y la mutación van en la parte 3, en `al_enfadarse()`.
       - **Al caer** (de lado: no tiene animación de muerte, porque en la parte 3 el que muere es el mutado) suelta lo
         de los jefes, **no saca mutación** (se acaba el edificio) y se abre la escalera de incendios. La página del
         dosier al morir (`pagina_del_jefe()`) queda para la parte 3. Si se sube a la azotea en la Alerta 3, la vida y
         el enfado cambian como con los demás jefes.
       - Tecla de prueba **L** (también en la exposición, F9). `--captura --edificio centro` saca además
         `captura-gerente.png` (lanzando contratos), `captura-gerente-maletinazo.png` y `captura-gerente-trabajar.png`,
         y le hace caer para comprobar que no sale la mutación.
     - ✅ **Parte 3: la mutación, la página del dosier y el helicóptero de Velaria** (21 oct). Lo que ha quedado:
       - **El dibujo del mutado**, animado con PixelLab sobre el modelo aprobado (`gerente-mutado-128`, 127 px): andar,
         latigazo de tentáculos, embestida (carrera en bucle) y muerte (cae de espaldas), en las 8 direcciones. Hoja
         `jefe-gerente-mutado` (`py tools/jefe_hoja.py gerente-mutado-128 jefe-gerente-mutado`). Costó
         **32 generaciones**, sin repeticiones: con la frase fuerte de espaldas desde el principio, ninguna se giró.
       - **La jeringa:** a media vida, en vez de enfadarse, grita «¡AQUÍ NO PARA NADIE!», aparta a Johnny y se pincha
         (2,6 s con la animación de la jeringa, sin que se le pueda dar); al final, encorvado y temblando. Luego
         **muta**: fogonazo verde, temblor, rugido y trocitos, y crece de golpe al dibujo del mutado (1,3 s también
         sin que se le pueda dar). La barra sigue con la vida que tenía. Antes de pincharse **no puede caer**: aunque le
         den mucho de golpe, se queda con 1, así que la mutación llega siempre.
       - **El mutado** es más rápido (110 en vez de 70), pega más si Johnny se le pega (14) y ya no lanza contratos ni
         grita «¡A TRABAJAR!» (decidido aquí: ya no piensa, solo ataca, y así el final es un duelo). Con aviso hace:
         **latigazos**, tres franjas rojas en abanico (0,75 s) y tres tentáculos de 340 de largo por ellas (18 de daño;
         el zombi de tentáculos llega a 220), y la **embestida** si Johnny está lejos: franja roja (0,8 s) y sale
         corriendo (24 de daño y le tira); si se estrella contra un aparato o el murete se queda **atontado** 2,2 s.
       - **Al caer el mutado** (con su animación): «¡El gerente ha caído!», se abre la escalera de incendios, y al rato
         sale la **página del dosier** (la orden de recogida, si falta) y, al cerrarla, llega el **helicóptero de
         Velaria** (`helicoptero.gd`, dibujado con código): viene volando de fuera, se queda sobre el helipuerto con el
         rotor girando, la luz roja que parpadea y un foco que busca a Johnny por el suelo, con el aviso «¡Un
         helicóptero de Velaria viene a por ti! Vete por la escalera de incendios». No ataca: Johnny se va por la
         escalera. Suena el rotor (efecto nuevo, `rotor`) y al pincharse, `jeringa`.
       - `--captura --edificio centro` saca además `captura-gerente-jeringa.png`, `captura-gerente-muta.png`,
         `captura-mutado.png` (latigazos), `captura-mutado-embestida.png` y `captura-helicoptero.png`, y comprueba en
         la salida que sale la página y llega el helicóptero (y que no sale la mutación de Johnny).
   - ✅ **La portera a 72 px** (22 oct; el dueño lo pidió para que todos los jefes tengan el tamaño de un zombi
     grande): modelo nuevo copiando la de antes (visto bueno del dueño) y sus animaciones (andar, fregonazo, lanzar,
     grito y muerte), 40 generaciones. Ahora mide unos 70 px, como los minijefes; el detalle, en `docs/ZOMBIS.md`
     («La portera») y en `assets/pixellab.json` → `portera-72`.
5. **Supervivientes nuevos** con sus eventos (decidido: ver «Supervivientes»). ✅ Lo común, ✅ el rescate de la
   farmacéutica, ✅ el del técnico con su mejora, ✅ el del ferretero con su puesto y ✅ la mejora de la
   farmacéutica (cada partida, un botiquín en la mochila que se usa desde el inventario).
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
7. ✅ **La historia:** dosier, noticias y el guiño de la cafetera (ver «Historia»). La página del gerente, también
   (sale al caer él, en la parte 3 del trozo 6 de la parte 4).
8. **Extras:** niveles de alerta, eventos sorpresa, reto del día, colecciones (decidido: ver «Para que enganche»).
   ✅ Trozo 1, niveles de alerta (21 oct). ✅ Trozo 2, eventos sorpresa (21 oct). ✅ Trozo 3, colecciones y
   bestiario (22 oct). ✅ Trozo 4, reto del día (22 oct). **Parte 8 terminada.**
9. ✅ **Los objetos de curar** (22 oct): las vendas de la farmacia y el bocadillo del supermercado, que se usan desde
   el inventario (ver «Objetos»). Quedan, de lo apartado: la joyería (sala opcional con riesgo) y los trajes de
   Johnny de la tienda de ropa.
