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

## Supervivientes

Supervivientes nuevos, uno por planta, con su evento de rescate como los de ahora; al rescatarlos van a la sala de
mantenimiento. Cada uno debería **hacer crecer la sala** (uno arregla la cafetera y cura al empezar, otro abre
una tienda...).

## Objetos

- Objetos nuevos y objetos que ya existen, **repartidos por edificio**: algunos solo salen en los apartamentos y
  otros solo en el centro comercial, para que valga la pena volver a un edificio completado.
- **Recetas del banco de trabajo que piden objetos de los dos edificios** ("me falta X de los apartamentos para
  fabricar Y"). Quien juegue solo uno no se queda bloqueado.

## Historia

Dosier y noticias del centro comercial (`historia.gd`: una entrada más en `DOSIERES` y noticias nuevas).

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
     suelta la tarjeta (dibujada con código) y 2 billetes. De momento es el zombi normal con la bata teñida de azul.
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
4. **Zombis nuevos**, minijefes y jefe final.
5. **Supervivientes nuevos** con sus eventos.
6. **Reparto de objetos** y recetas que mezclan edificios.
7. **La historia:** dosier y noticias.
8. **Extras:** niveles de alerta, eventos sorpresa, reto del día, colecciones.
