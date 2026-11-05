# Tercer edificio: plan para elegir

> **Decidido con el dueño (5 nov 2026): la idea A, Torre Velaria subiendo hasta la planta 40, con los jefes y las
> skins tal como están aquí.** Los números son provisionales; el final de la historia está por decidir. Se hace por
> partes, cada una con su visto bueno; al terminar una, se marca aquí con ✅ y lo que haya cambiado respecto al plan.
> Nada programado todavía.

## Lo que ya dice la historia

El final del centro comercial ya apunta al tercer edificio, y no hace falta cambiar nada para que encaje:

- La orden de recogida del gerente (`cc_recogida`) manda al Sujeto 0 a **Torre Velaria, la sede, «directo al
  laboratorio de la planta 40. Él ya lo conoce, aunque no se acuerde»**.
- El relato del final del centro: Johnny sube al helicóptero, «Planta 40», «Ya conoce el camino», y acaba con
  «Cuarenta plantas de moqueta. Alguien tendrá que limpiarlas».
- La última noticia: Velaria dice que el conserje «está con nosotros, a salvo» y que **mañana presenta en su torre
  «el futuro del trabajo»**. La reportera sigue sin saber de su hermana (Elena Ruiz, que murió en el centro).

Hay una pregunta sin responder que el tercer edificio puede cerrar: **¿por qué Johnny «ya conoce» la planta 40?**

## Lo que no cambia (como en los otros dos)

- Se empieza en la **sala de mantenimiento** y se elige el edificio en «Elige edificio». La torre sale con candado
  hasta completar el centro comercial.
- **5 plantas**: cuatro con «sitios» detrás de las puertas del pasillo y la última, la del jefe final.
- **Cuatro minijefes al azar** (uno por planta, sin repetir), **un jefe final** con dos fases, **tres
  supervivientes** con su rescate propio y su mejora, **un dosier de 5 páginas**, **unas 5 noticias**, **un relato
  final** y **cinco skins** (una por jefe).
- Lo que ya tiene el juego para todos los edificios entra solo o casi solo: niveles de alerta, eventos sorpresa,
  reto del día, colecciones y bestiario.
- Todo texto nuevo, con `Idioma.t()` y traducido a los 7 idiomas antes de subir.

---

## Las tres ideas

### Idea A · Torre Velaria: subir hasta la planta 40 (✅ la elegida)

La sede de Velaria Corp.: un rascacielos de oficinas. Johnny entra por el vestíbulo y sube hasta el laboratorio de
la planta 40. **Encaja tal cual con lo que ya cuenta el juego** (la planta 40, la moqueta, «el futuro del
trabajo») y es lo más distinto de lo que hay: ni casas ni tiendas, sino **departamentos de oficina**. Los zombis
son oficinistas que siguen con su trabajo (como los del centro, que seguían con el suyo): el VD-7 ya no va en el
café, va **en el aire acondicionado de toda la torre**.

Todo el plan de abajo está pensado para esta idea.

### Idea B · Torre Velaria: escapar hacia abajo

La misma torre, pero al revés: el helicóptero ya ha dejado a Johnny arriba. **Despierta en una camilla del
laboratorio de la planta 40 y tiene que bajar** hasta la calle: 40 → 30 → 20 → 10 → vestíbulo, con el jefe final
esperándole en el vestíbulo, junto a las puertas de cristal. Es la más «Zombie *Escape*».

- Lo bueno: es una sorpresa (los otros dos edificios se suben) y pega con el relato (el helicóptero sí le lleva).
- Lo malo: **más trabajo de código** que la A: el juego da por hecho que se sube (los nombres de las plantas, las
  escaleras, la azotea al final, y que se empieza desde la sala de mantenimiento). Habría que explicar por qué cada
  partida empieza en el laboratorio y no en la sala.
- Casi todo lo de la idea A vale igual (departamentos, zombis, minijefes, skins); cambiaría el orden de las plantas
  y dónde está el jefe final.

### Idea C · La fábrica de «Velaria Noche»

La fábrica donde se envasa el somnífero que se vende en las farmacias (el contrato «Turno infinito» ya decía que
Velaria quería venderlo «a fábricas»). Plantas con muelle de carga, línea de envasado, laboratorio de control de
calidad, almacén automático y oficinas; peligros de fábrica (cintas transportadoras que te arrastran, prensas que
aplastan, cubas de jarabe de VD-7); un capataz con carretilla, una inspectora de calidad... y el director de la
planta en el tejado, entre chimeneas.

- Lo bueno: muy distinta por dentro (máquinas en marcha, cosas que se mueven solas).
- Lo malo: **no encaja con el final del centro** (el helicóptero va a la torre). Habría que reescribir el relato del
  centro y la última noticia, que algunos jugadores ya han leído, o dejarla para un **cuarto edificio** (por ejemplo,
  después de la torre). Claude la dejaría para el cuarto.

---

## El plan de la idea A: Torre Velaria

**Ficha** (`edificios.gd`, `"torre"`): «Torre Velaria» · *«Oficinas de moqueta, empleados que no duermen y un
laboratorio en la planta 40»*. Se abre al completar el centro comercial (`"abre": "centro"`).

### Las plantas

En la torre el ascensor solo para cada diez plantas (las de en medio están tapiadas por obras), así que las cinco
plantas son: **vestíbulo, planta 10, planta 20, planta 30 y planta 40**. Es solo cambiar cómo se llaman; por dentro
siguen siendo 5 plantas como siempre.

- **Vestíbulo** (la planta baja): mostrador de recepción, tornos de acceso, sofás, una maqueta de la torre y el
  pasillo con los departamentos de abajo.
- **Plantas 10, 20 y 30:** el pasillo es un **distribuidor de oficina** (moqueta gris, paredes de cristal
  esmerilado, plantas de plástico, fuentes de agua), con un **ventanal al fondo** y la ciudad de noche detrás. En
  cada puerta, en vez del letrero de neón del centro, un **rótulo de departamento iluminado** (blanco y frío).
- **Planta 40: el laboratorio** (en lugar de la azotea). Una sala grande y abierta, blanca, con cápsulas de cristal,
  mesas de laboratorio y, en lo alto, una **cabina de control blindada**. Se llega por las escaleras y no se vuelve.
  Al ganar se escapa por el helipuerto de arriba.

### Los departamentos (los «sitios» de cada planta)

Como las tiendas del centro: una sala grande delante y sus habitaciones de dentro al fondo. Cada tipo tiene su
peligro y lo suyo, para que al entrar ya sepas qué te espera. En cada planta, tipos distintos.

| Departamento | Habitaciones de dentro | Peligro | Qué se encuentra |
|---|---|---|---|
| Atención al cliente (filas de cubículos con cascos) | sala de impresoras, office (cocinita) | — (los teléfonos suenan y despiertan) | billetes, munición |
| Informática | sala de servidores, almacén | cámaras de seguridad | baterías |
| Recursos Humanos | archivo, sala de entrevistas | gas de las rejillas | vendas |
| Marketing | estudio de grabación, almacén de material | ventanal roto con viento | munición, granadas |
| Seguridad corporativa | sala de cámaras, armero | cámaras de seguridad | munición, armas |
| Dirección (solo de la planta 20 arriba) | despacho, sala de juntas, aseo privado | ventanal roto con viento | billetes |

- **La sala del minijefe** es la de su departamento (el despacho de Recursos Humanos, el centro de datos, el plató
  de presentaciones, la sala de fotocopias): se llama según quién esté, como en el centro.
- **Cómo se abre la sala del jefe (el «cerrojo» nuevo): el código.** En la puerta hay un teclado. Repartidos por los
  departamentos de la planta hay **tres ordenadores encendidos** (con una lucecita para encontrarlos); plantándote
  delante, Johnny apunta una cifra del código. El riesgo: al encenderlo salta el **«control de productividad»** y se
  despiertan los zombis de ese departamento. Con las tres cifras, la puerta se abre. (Los Apartamentos tienen la
  llave y el centro, el guardia de la tarjeta: este es de buscar, no de cazar.)

### Los peligros nuevos

Como los del centro, se deciden al generar la planta, no se secan, **también les afectan a los zombis** (para poder
usarlos) y se dibujan con código, sin PixelLab. Ninguno repite los que ya hay (frío, fuego, agua con corriente,
charcos, porquería, apagón, aspersores).

- **Ventanal roto con viento** (Marketing y Dirección): a treinta plantas de altura, la corriente empuja hacia la
  ventana. A Johnny lo arrastra poco a poco (si llega al borde, se agarra: mucho daño y vuelve atrás); **a los zombis
  los tira por la ventana**. Papeles volando, cortinas agitándose y el ruido del viento. Hay que cruzarlo pegado a
  las mesas, o atraer a los zombis hacia él.
- **Cámaras de seguridad** (Informática y Seguridad): en las esquinas, barren la sala con su cono de luz. Si te
  pillan, suena la alarma y llegan **2 escoltas de Velaria** (el zombi nuevo, abajo). Se pueden romper de un
  disparo (y hace ruido) o esquivar. El técnico del centro ya «arregla las cámaras» del minimapa: pega con él.
- **Gas de las rejillas** (Recursos Humanos): el VD-7 del aire acondicionado, una nube morada que sale de las
  rejillas a ratos. **A Johnny no le hace nada** (es el Sujeto 0: el dosier ya lo dice). **A los zombis los duerme
  unos segundos y luego despiertan frenéticos** (más rápidos un rato): sirve para escapar, pero vuelven peor. Se
  corta con la válvula del cuarto de las máquinas del departamento.

### Los zombis nuevos (48 px, como Johnny)

Números de partida para comparar (Johnny anda a 210; el zombi normal, 30 de vida y 80 de velocidad):

- **Oficinista** (camisa blanca, corbata torcida, acreditación colgada, cascos de teleoperador): el primer zombi
  normal **que ataca de lejos**. Tira grapadoras y tazas a media distancia (proyectil lento, 8 de daño) y, si te
  acercas, se aparta. Vida 25, velocidad 75. Desde el vestíbulo, unos pocos por departamento.
- **Escolta de Velaria** (traje negro, chaleco, pinganillo): el «vigilante» de la torre. Llegan cuando una cámara
  te ve y salta la alarma. El chaleco para la mitad de las balas de frente; pega con un táser
  (6 de daño y te deja tieso medio segundo). Vida 50, velocidad 90.
- **Clientes de siempre:** los zombis normales, lentos, rápidos, gordos y demás siguen saliendo (son los empleados
  de a pie).

### Los cuatro minijefes (lienzo de 72, como los otros)

Como siempre: aparecen al entrar en su sala con su presentación, barra grande, +25 % de vida por planta, avisan cada
ataque, a media vida se enfadan, y al caer billetes, munición, objetos, mutación y, la primera vez, su skin.

1. **La directora de Recursos Humanos** (traje chaqueta, moño tirante, gafas de pasta, un sello de goma enorme).
   Vida 450, velocidad 75.
   - *Sello de despido*: marca en el suelo y, al caer, si te pilla, «¡DESPEDIDO!»: 15 de daño y **3 s sin poder
     usar el arma** (solo la fregona).
   - *Evaluación de desempeño*: llama a 3 oficinistas; mientras queden de pie, a ella le entra la mitad del daño.
   - *Lluvia de cajas*: cajas de cartón (las de recoger la mesa al irte) que caen alrededor de Johnny con su sombra
     antes.
   - Enfadada: el sello cae en tres sitios seguidos y llama a 5.
2. **El informático** (sudadera, gafas, cables colgando del cuello, una taza de café de VD-7 pegada a la mano).
   Vida 420, velocidad 80. Su sala, el centro de datos: filas de armarios de servidores con lucecitas.
   - *Cortocircuito*: el suelo se electrifica por franjas, por turnos (se ve venir: chispitas antes); hay que ir
     saltando de franja segura en franja segura.
   - *Apagón*: corta la luz de su sala unos segundos; solo se ve con la linterna y las lucecitas de los servidores.
   - *Teclados*: los tira en abanico (8 cada uno).
   - Enfadado: **se «reinicia»**: desaparece y vuelve a aparecer junto a otro armario.
3. **El presentador** (el de «el futuro del trabajo»: americana brillante, micrófono de diadema, sonrisa de anuncio).
   Vida 430, velocidad 85. Su sala, el plató de presentaciones, con filas de sillas y un público de zombis sentados.
   - *Grito al micrófono*: onda en cono que **empuja** a Johnny hacia atrás (y 12 de daño).
   - *Focos*: un foco le apunta y, si lo miras, la pantalla se pone blanca un momento.
   - *Confeti*: cañones de confeti que explotan donde estabas.
   - Enfadado: **el público se levanta** (los zombis sentados despiertan todos a la vez).
4. **El becario** (camisa grande, acreditación de «BECARIO», una pila de fotocopias). Vida 380, velocidad 120.
   Su sala, la de fotocopias.
   - *Fotocopias*: pasa por la fotocopiadora y salen **copias de él** iguales (mueren de un golpe y hacen poco daño);
     hay que encontrar al de verdad (el único que tiene sombra, o el que se ve en el cristal de la fotocopiadora).
   - *Carrito del correo*: embiste con el carrito (franja roja antes).
   - *Café para todos*: tira vasos de café que dejan charco que resbala.
   - Enfadado: más copias, y las copias también pegan.

### El jefe final: el Sujeto 1 (planta 40)

**La respuesta a «ya conoce el camino»:** hace años, Johnny fue el primero que probó el VD-7 en este laboratorio. No
se convirtió. Velaria le borró la memoria, le dio un trabajo de conserje en el número 14 para tenerlo vigilado y
siguió estudiando su sangre. Con ella ha hecho **el Sujeto 1**: el soldado que quería Velaria, uno que no duerme,
no se cansa y no se convierte. Una copia de Johnny, pero enorme y mal hecha.

- **La presidenta de Velaria** (traje blanco, tableta en la mano) mira desde la cabina blindada, no se le puede
  pegar, y **maneja el laboratorio** durante el combate: suelta gas por las rejillas, abre las cápsulas de los
  sujetos (zombis) y enciende barreras láser que cruzan la sala (queman a Johnny y a los zombis).
- **Fase 1: el Sujeto 1** (lienzo de 128, como el gerente y el doctor Salas; vida 1500). **Pelea como Johnny**:
  esquiva rodando (a veces se libra de una bala), fregonazo gigante en arco, y tira cubos de agua que dejan el
  suelo resbaladizo.
- **Fase 2, a media vida: se parte en dos.** No se pincha nada (eso ya lo hacen el gerente y Salas): el cuerpo no
  aguanta y **se divide en dos Sujetos más pequeños**, con la mitad de la vida cada uno; al caer uno, el otro se
  enfada. Mientras, la cabina se rompe y la presidenta huye hacia el helipuerto.
- Al caer, suelta la última página del dosier (la ficha de Johnny). Johnny sube al helipuerto... y el final lo
  cuenta el relato.

### Los supervivientes (tres, solo de la torre)

Como en el centro: sale uno de los que aún no tienes, en una planta al azar; vive en las viviendas (habría que
añadir **tres habitaciones más** al pasillo de las viviendas) y cada uno con su rescate propio, su mejora y lo suyo
al acompañarte. Números provisionales.

| Quién | Dónde y cómo se le rescata | En la sala (su mejora) | Si te acompaña |
|---|---|---|---|
| **Recepcionista** | Detrás del mostrador del vestíbulo, con la persiana bajada: la horda mientras ella abre los tornos con su tarjeta (los tornos frenan a los zombis) | Al entrar en cada planta, un aviso dice dónde está lo que abre la sala del jefe (la llave, el guardia o el código) | Grita «¡Detrás!» cuando un zombi te va a pegar por la espalda (medio segundo de ventaja) |
| **Informático joven** (el que hacía las prácticas con el becario) | En la sala de servidores: protegerle 60 s mientras copia los archivos de Velaria (con las cámaras dando la alarma) | «Precio de empleado»: la tienda de armas del ordenador, un 15 % más barata | Las cámaras que tiene cerca no dan la alarma, y abre el teclado del jefe sin código |
| **Limpiadora de noche** (otra como Johnny) | Encerrada en el cuarto de la limpieza de Recursos Humanos, lleno de gas: cerrar las tres válvulas del departamento para que pueda salir (con los zombis dormidos y frenéticos por el gas) | Le arregla la fregona a Johnny: el fregonazo barre más ancho | Friega por donde pasa: los charcos (veneno, ácido, resbalones) desaparecen a su paso |

### Las skins (solo la cabeza de Johnny, como en la M90)

Una por jefe, se gana al matarlo por primera vez. Las ventajas no repiten las de ahora (fregona, mordisco, cuerpo a
cuerpo, fuego, curas, aguante, camuflaje, rapidez, billetes).

| Skin | La cabeza | La ventaja |
|---|---|---|
| **La directora** | moño tirante y gafas de pasta, con su barba de siempre | «Despido»: el primer golpe a un zombi dormido lo mata (combina bien con la de la modista) |
| **El informático** | cascos con micrófono y gafas | Las cámaras no te ven y la linterna alumbra un 50 % más lejos |
| **El presentador** | tupé engominado y micrófono de diadema | Recoges un 30 % más de munición |
| **El becario** | gorra del revés y la acreditación colgada | «Copia de seguridad»: una vez por partida, al caer, te levantas con 25 de vida |
| **El Sujeto 1** | la cara de Johnny con venas moradas y los ojos brillantes | Las mutaciones (lo que te da el VD-7 al matar a un jefe) duran el doble |

### La historia

**Dosier de la torre** (5 páginas, una por planta, como los otros; los textos los escribe Claude y el dueño los lee
antes de darlos por buenos):

| Planta | Quién la lleva | Qué es | Lo que cuenta |
|---|---|---|---|
| Vestíbulo | La recepcionista de noche (muerta; no es la superviviente) | Libro de visitas antiguo | Hace 11 años: «J. Rush, voluntario. Planta 40». Una nota: «Este nombre me suena» |
| Planta 10 | Una médica de empresa | Circular de Recursos Humanos: «Programa Bienestar» | El VD-7 va en el aire acondicionado de toda la torre: «Empleados más tranquilos, más horas» |
| Planta 20 | Un guionista de Marketing | El guion de «El futuro del trabajo» | Velaria va a presentar el turno infinito para todo el país, con el Sujeto 1 como «el empleado perfecto» |
| Planta 30 | Un científico del laboratorio | Informe del Sujeto 1 | Hecho con la sangre del Sujeto 0. «No duerme, no se cansa. No obedece» |
| Planta 40 | El Sujeto 1, al caer | La ficha del Sujeto 0 | Quién era Johnny antes, por qué no recuerda nada y por qué le pusieron de conserje en el 14 |

**Noticias de Canal 8** (unas 5): la presentación de «el futuro del trabajo» en directo desde la torre; la torre
cierra «por un simulacro»; empleados que salen dormidos por la puerta giratoria; un audio de la presidenta; y al
completar la torre, la torre a oscuras y el helicóptero de Velaria saliendo... ¿con quién?

**El relato del final**: Johnny en el helipuerto con su ficha en la mano. **Cómo acaba lo decide el dueño:** cerrar
la historia (Johnny sabe quién es y se lo cuenta a Marta, la reportera), o dejar el gancho para un cuarto edificio
(la presidenta escapa; la fábrica de la idea C podría ser el siguiente).

### Lo que hay que pedir a PixelLab

Cálculo aproximado por lo que costaron los dos edificios anteriores. Antes de cada tanda se dice el coste.

| Qué | Para qué | Generaciones (aprox.) |
|---|---|---|
| Suelos, paredes y tapas | moqueta, cristal esmerilado, el vestíbulo de mármol, el centro de datos, el laboratorio blanco | 25 |
| Muebles rectos y destrozados | cubículos, mesas, sillas, impresoras, fotocopiadora, armarios de servidores, fuentes de agua, plantas, sofás, mostrador, tornos, cápsulas y mesas de laboratorio | 90 |
| Restos sueltos | papeles, tazas, grapadoras, cristales, acreditaciones por el suelo | (en lo de arriba) |
| Oficinista y escolta | modelo + andar, ataque, golpe y muerte en 8 direcciones | 75 |
| Cuatro minijefes (72 px) | modelo + 5 o 6 animaciones cada uno | 180 |
| El Sujeto 1 (128 px) y la presidenta | modelo, animaciones y la fase partida en dos | 65 |
| Tres supervivientes (48 px) | como los del centro | 45 |
| Cinco cabezas de skin | 8 direcciones de Johnny quieto, una vez cada una | 15 |
| **Total** | | **unas 495** |

Los peligros (viento, cámaras, gas, láseres), los rótulos de departamento, la ciudad de noche por los ventanales y
los iconos se dibujan con código, como en el centro.

### Por partes (una sesión cada una, con su visto bueno)

Con el modelo que toca según `CLAUDE.md` (Opus para lo nuevo o difícil; Sonnet para lo que ya sabemos hacer).

1. **El esqueleto** (Opus): la ficha `"torre"`, el candado, el generador de departamentos y sus habitaciones (con
   muebles prestados de los otros edificios), los nombres de las plantas (10, 20, 30, 40) y el cerrojo del código con
   sus tres ordenadores. ✅ **Hecho el 5 nov, con el visto bueno del dueño.** Lo que ha quedado:
   - La ficha `"torre"` en `edificios.gd` (se abre al completar el centro) y sus cuatro minijefes en `MINIJEFES` (sin
     hacer: en su planta sale la portera, con su cuarto de la limpieza). El icono de su tarjeta, `tools/icono_torre.py`.
   - Los seis departamentos son tipos de `Tienda.TIPOS` con `"edificio": "torre"`; cada uno toma de momento el plano, los
     muebles y los suelos de una tienda del centro (`"presta"`), con sus habitaciones con su nombre (sala de servidores,
     archivo, sala de juntas...). Dirección, solo de la planta 20 arriba. Sin escaparates: solo su rótulo, que de momento
     es el letrero de neón del centro. Sin dependientas ni vigilantes (sus zombis llegan en la parte 4).
   - Las plantas se llaman vestíbulo y planta 10, 20, 30 y 40 (`Planta.nombre_torre`); la 40, de momento, es la azotea
     del centro. El cartel pintado junto al ascensor no sale en la torre (los que hay van del 0 al 3).
   - El código: tres cifras al azar en tres ordenadores encendidos (`terminal.gd`, dibujado con código), en habitaciones
     distintas de los departamentos normales (en el vestíbulo, que solo tiene dos, uno lleva dos). Al leer uno, la cifra
     sale en grande y se despiertan los zombis de allí; con las tres, la sala del jefe se abre como con la llave.
   - El pasillo, de momento, la galería del centro.
   - Prueba: `--captura --edificio torre --torre`.
2. **Cómo se ve** (Sonnet): suelos, paredes y muebles con PixelLab; rótulos de departamento y ventanales con la ciudad.
   ✅ **Hecho el 5 nov, con el visto bueno del dueño.** 45 generaciones (no las 115 del cálculo: los departamentos
   siguen en los planos de las tiendas y usan unos 20 muebles). Lo que ha quedado:
   - Suelos, paredes y tapa propios (`docs/FONDOS.md`, apartado de la torre): el pasillo, de moqueta gris y cristal esmerilado;
     el vestíbulo, de mármol en damero con paredes de piedra; los departamentos, con tabique claro, y el centro de datos
     (Informática, sala de servidores, sala de cámaras) y Dirección (parquet y madera) con los suyos.
   - 19 muebles de oficina (cubículos, escritorios, impresoras, fotocopiadoras, racks, fuentes de agua, archivadores, sofás,
     recepción, torno, mesas de juntas, de dirección, de mezclas y de entrevistas, librería, pared de monitores, armero, cocina
     del office, maqueta de la torre), 5 de ellos también de lado. Puestos en las casillas de la tienda cuyo plano usa cada
     departamento (`Catalogo.SALAS` `<sala>-<tipo>`, ya sin `presta` para los muebles; `presta` queda solo para el plano). Los
     planos propios de cada departamento, y los muebles que faltan (cápsulas y mesas del laboratorio, de la parte 6), quedan
     para más adelante.
   - El pasillo de la torre y el vestíbulo tienen sus muebles puestos a mano (`"torre"` y `"vestibulo"` de `Catalogo.SALAS`):
     fuentes de agua, sofás, plantas, y en el vestíbulo, la recepción, la maqueta de la torre y dos tornos.
   - Rótulos iluminados (`neon.gd`, `iluminado`), ventanal con la ciudad de noche a la punta izquierda del pasillo
     (`ventanal.gd`) y el cartel del número de planta junto al ascensor (0, 10, 20, 30 y 40, `puerta.gd`).
   - Sin hacer (opcional): cambiar el ordenador del código (`terminal.gd`) por uno de PixelLab.
   - Prueba: `--captura --edificio torre --departamentos` (`--tipo X`) y `--torre`.
3. **Los peligros** (Opus): viento, cámaras y gas. ✅ **Hecho el 5 nov, con el visto bueno del dueño.** Lo que ha quedado
   (los números, en `Peligros.VIENTO`, `CAMARAS` y `GAS`; todo dibujado con código y solo con los zombis despiertos):
   - **Viento** (`viento.gd`; Marketing y Dirección): el ventanal roto, en la pared de un lado de la sala grande, con la ciudad
     detrás, cortinas, rayas de aire y papeles volando. Empuja de 90 (pegado) a 30 (en la otra punta), a rachas (4 s a la mitad y
     2 s fuerte), y a los zombis un 60 % más. Detrás de un mueble no sopla. En el borde, Johnny se agarra (20 de vida y sale
     despedido hacia dentro) y los zombis salen volando: cuentan como muertos, sin cuerpo ni botín.
   - **Cámaras** (`camaras.gd`; Informática 2 y Seguridad 3): cerca de las esquinas de arriba (y en Seguridad, una en medio),
     nunca encima de una puerta ni tapadas por un mueble alto. Barren un cono de 9 casillas (ida y vuelta en 8 s); si te ven
     medio segundo, alarma: sirena y luz roja 6 s, se despiertan los zombis del departamento y, la primera vez de cada cámara,
     llegan 2 zombis normales por la puerta (los escoltas de Velaria, en la parte 4). Se rompen de un tiro.
   - **Gas** (`gas.gd` y `valvula.gd`; Recursos Humanos): 3 rejillas en el suelo de la sala grande, cada una 5 s echando y 9 s
     parada (no a la vez). A Johnny no le hace nada; a los zombis los duerme 3 s y los despierta frenéticos (un 50 % más
     rápidos, 6 s). La válvula, en la pared del archivo (o de otra habitación de dentro), lo corta y lo vuelve a abrir.
   - El viento tiene su cartel de derrota («El viento», `Menus.PELIGROS`) y sus tres sonidos nuevos (`viento`, `camara`, `siseo`).
   - Pruebas: `--captura --edificio torre --viento`, `--camaras` y `--gas`.
4. **Los zombis nuevos** (Sonnet): oficinista y escolta. ✅ **Hecho el 5 nov, con el visto bueno del dueño.** 76 generaciones
   (12 de los dos modelos, 0,25 de importar el oficinista con la piel verde y 64 de las animaciones). Lo que ha quedado:
   - **Oficinista** (`zombi_oficinista.gd`, `zombi-oficinista`; vida 25, velocidad 75): guarda las distancias (se aparta a menos de
     170, se acerca a más de 300) y cada 2,5 s tira una taza o una grapadora que va recta y despacio (260; 8 de daño; dibujadas con
     código en `bala_zombi.gd`). Si lo acorralas, manotazo de 5. Sale en todos los departamentos desde el vestíbulo: como mucho 2
     por departamento y, si a suertes no sale ninguno, uno de los de siempre se cambia por él.
   - **Escolta de Velaria** (`zombi_escolta.gd`, `zombi-escolta`; vida 50, velocidad 90): el chaleco le para media bala de frente
     (chispas y «¡TOC!»; los golpes, el fuego y las explosiones, enteros). Su táser quita 6 y deja a Johnny tieso medio segundo
     (el `"calambre"` del agua con corriente). Llegan dos con la alarma de cada cámara, hacen guardia en Seguridad corporativa (1 o 2)
     y, de la planta 20 arriba, a veces sale uno suelto en los demás departamentos.
   - Su ficha en el bestiario (solo de la torre) y en el panel de pruebas (F9). Los dibujos, en `docs/ZOMBIS.md` (Torre Velaria) y en
     `assets/pixellab.json` → `torre-parte4`.
   - Pegas: en el lanzamiento del oficinista PixelLab le pintó algo azul en la mano (los dos primeros fotogramas); el táser del
     escolta suelta una chispita amarilla en algunas direcciones.
   - Pruebas: `--captura --edificio torre --oficinista`, `--escolta` y `--camaras`.
5. **Minijefes**, uno por sesión (Opus): directora, informático, presentador y becario.
6. **La planta 40 y el Sujeto 1** (Opus), con la presidenta y los láseres.
7. **Los supervivientes** (Sonnet lo común; Opus cada rescate nuevo): las tres habitaciones nuevas de las
   viviendas y un superviviente por trozo.
8. **La historia** (Sonnet): dosier, noticias y relato final.
9. **Las skins** (Sonnet): las cinco cabezas y sus ventajas.
10. **Repaso** (Sonnet): que la torre entre en alertas, eventos sorpresa, reto del día, colecciones y bestiario; las
    traducciones de todo a los 7 idiomas; la prueba de cada cosa (`--captura --edificio torre ...`).

## Preguntas para el dueño

1. ✅ ¿Qué idea? **La A, subir la torre** (5 nov). La C (la fábrica) queda como idea para un cuarto edificio.
2. ✅ Los cuatro minijefes, el Sujeto 1 y las cinco skins, **tal como están en el plan** (5 nov). Los números son
   provisionales: se ajustan jugando.
3. ¿Cómo quieres que acabe la historia: cerrada, o con gancho para un cuarto edificio?
4. ¿Algo que no quieras (el viento que te arrastra, las copias del becario, el código de la puerta...)?
