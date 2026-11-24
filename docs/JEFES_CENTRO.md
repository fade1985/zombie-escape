# Rediseño de los jefes del centro comercial

Plan del 21 nov para rehacer los cinco jefes del centro comercial (antidisturbios, cocinero, modista, mascota y el
gerente), **uno a uno**. Al terminar cada uno, se marca aquí como hecho y se apunta lo que cambió respecto al plan.

| Jefe | Estado |
|---|---|
| Antidisturbios | hecho, con el visto bueno del dueño (21 nov) |
| Cocinero | hecho, pendiente del visto bueno del dueño (23 nov) |
| Modista | hecha, pendiente del visto bueno del dueño (24 nov) |
| Mascota | pendiente |
| Gerente | pendiente |

## Por qué

Los cinco heredan de `minijefe.gd` (vida, barra, enfado, llamar zombis, moverse, morir), y eso está bien. Lo malo
es que además **se repiten los ataques**:

- El golpe de cerca con marca roja de medio segundo (18-22): porrazo, cuchillazo, tijeretazo, maletinazo.
- La embestida en línea recta que atonta al chocar: antidisturbios, mascota y el mutado usan la misma `embestir`.
- Lanzar en abanico: cuchillos del cocinero y contratos del gerente.
- Llamar ayuda: el silbato y «¡A TRABAJAR!».
- El enfado a media vida solo los acelera (más seguido, menos aviso); no cambia cómo pelean (salvo el gerente).

Cada uno tiene una idea propia buena (el escudo, la cocina, los maniquíes, el salto con críos, la mutación),
pero rodeada del mismo relleno.

## Las reglas del rediseño

1. Cada jefe tiene un **truco para hacerle daño de verdad** (una ventana de castigo que se gana el jugador, no
   que toca por suerte).
2. **La sala forma parte de la pelea** (columnas, ollas, maniquíes, cajas, la azotea).
3. **La media vida cambia la pelea**: una transición corta y otra forma de luchar, no solo más rápido.
4. Ideas de juegos del estilo (Souls, Elden Ring, Zelda): combos con el último golpe que se clava, puntos débiles,
   patrones que se aprenden.
5. Johnny tiene **esquiva** (`johnny.gd`: 0,16 s sin que le hagan daño, se recarga en menos de un segundo): las
   franjas pueden atravesarse esquivando, no hace falta que siempre tengan hueco (aunque a veces lo tengan).
6. Todo ataque sigue **avisado** (se puede esquivar siempre), como ahora.

## Piezas comunes nuevas (en `minijefe.gd` o en scripts propios)

Se hacen una vez y cada jefe las viste a su manera; casi todo dibujado con código, como los avisos actuales.

1. **Franja que barre la sala**: una línea de daño que cruza la habitación de pared a pared, con aviso. Puede
   llevar un hueco o venir en olas.
2. **Cosas que rebotan y se acumulan**: rebotan en las paredes y no se van solas; se suman hasta que el jefe o
   Johnny las limpia.
3. **Zonas en el suelo**: casillas que se encienden con un dibujo (damero, cruz, espiral) y luego hacen daño.
4. **Ventana de castigo**: el jefe queda expuesto y recibe mucho más daño.
5. **Fases con transición**: una escena corta a media vida (se rompe algo, se apaga la luz, cambia la sala).

Lo que hay (aviso rojo, embestida, llamar zombis) se queda, pero como secundario.

## 1. El antidisturbios · «El muro»

**Idea central:** el escudo es el reto: hay que romperlo.

### Fase 1: con escudo
- **El escudo** funciona como ahora: de frente rebota todo, de lado daño normal, por la espalda el doble;
  explosiones y fuego le dan por todos lados.
- **Pelotas de goma**: dispara bolas que rebotan en las paredes y se quedan en la sala (2-3 por tanda). Johnny
  puede romperlas a golpes, pero mientras tanto el antidisturbios carga.
- **Gas lacrimógeno**: botes que dejan nubes en el suelo un rato; van quitando espacio.
- **Carga**: como ahora. **El truco**: en la sala hay columnas o taquillas metálicas; si se estrella contra una,
  el escudo se agrieta (se ve cada vez más roto). A los 3 choques, el escudo revienta.
- Al reventar el escudo, **todas las pelotas de goma explotan a la vez**.

### Transición
El escudo revienta en pedazos, se tambalea, tira el escudo roto y saca la porra eléctrica (con su grito).

### Fase 2: sin escudo
Sin escudo ya se le pega por todos lados, así que pelea más rápido y más agresivo.
- **Se quedan** el gas (más botes, nubes más grandes) y la carga (más rápida; al chocar se atonta menos rato,
  ya no hay escudo que romper).
- **Se van** las pelotas de goma (explotaron con el escudo), el silbato (ya no llama a nadie: es él solo) y el porrazo
  suelto (el golpe de cerca es solo el combo).
- **Nuevo, barrido eléctrico**: golpea el suelo y sale una franja de chispas que cruza la sala de lado a lado;
  2-3 seguidas, cada una con el hueco en otro sitio (o se atraviesan esquivando).
- **Nuevo, combo de porrazos**: 3 golpes encadenados avanzando; el último se le queda clavado en el suelo y es la
  ventana para pegarle.

### Cómo quedó (21 nov)
- `antidisturbios.gd`, `pelota_goma.gd`, `barrido_electrico.gd`; el gas es un proyectil y un charco nuevos ("gas").
- En vez de enfadarse a media vida, con el escudo entero **no baja de la mitad** («¡EL ESCUDO AGUANTA!»): romperlo
  es obligatorio. La fase 2 empieza al reventar el escudo.
- Las taquillas: 6-9 sueltas por la oficina. Solo ellas agrietan el escudo; las paredes atontan como siempre. Donde
  no hay taquillas (la sala de pruebas), vale cualquier choque.
- Las pelotas se rompen de un disparo (no a golpes, de momento); como mucho 9 a la vez.
- Con la porra clavada (1,8 s) le entra un 50 % más.
- Prueba: `--captura --edificio centro --jefe antidisturbios --muro`.
- Ajustes tras la primera mirada del dueño: rozar una taquilla cargando también le para (antes resbalaba por su
  lado); las olas, más lentas (170 en vez de 300, una cada 0,9 s) y dibujadas como un rayo en zigzag que parpadea.
- Segundo ajuste: la carga no se estrella hasta haber corrido **la mitad** (antes, si choca, frena sin atontarse ni
  agrietar; si roza, sigue), y no empieza una carga con algo a menos de media carga delante. El centro de la oficina
  (donde sale él) queda sin taquillas, y delante de la puerta también.
- Tercer ajuste: fuera el arco blanco de los pies y las grietas pintadas (se veían como una raya blanca suelta); al
  correr usa la animación de andar deprisa (la de "carga" es solo agacharse: parecía que flotaba; falta una de correr
  agachado en PixelLab); las pelotas, a 300 y rebotando en el dibujo entero de los muebles (antes, solo en su huella
  del suelo, y parecía que atravesaban los armarios); el gas, una nube de humo (`nube_gas.gd`) y no un charco; las
  olas, una cada 1,4 s, y el hueco marcado con dos bolas eléctricas en vez de postes amarillos.
- Cuarto ajuste: el humo del gas, de pixelfx (el "smoke-bomb" visto desde arriba, `tools/pixelfx/gas-lacrimogeno.js`,
  `efecto_suelo.gd` "gas"), y el bote que vuela, en pixel art; las estrellitas de atontado (de todos los jefes y de
  Johnny en el suelo), el "stunned" de pixelfx (`tools/pixelfx/estrellitas.js`); el barrido, 5 olas, y ya no se pasa
  esquivando: solo por el hueco (23 nov: las olas, cada 1,9 s en vez de 1,4, y el hueco de la primera, cerca de Johnny para que le dé tiempo a llegar). Más gas: 3 botes de cada vez (4 en la fase 2), repartidos alrededor de Johnny, cada
  5 s (4 en la fase 2). Pelotas: como mucho 12 a la vez (antes 9). El barrido, cada 11 s (antes 7).
- Animaciones nuevas de PixelLab (21 nov): correr con el escudo delante (la carga) y el empujón con el escudo (al
  disparar las pelotas). Hacia el noreste las dos salieron mal y allí se usa lo de antes (`descartes/`). La de lanzar
  el bote (plantilla "throw-object") perdía el escudo: descartada, el gas sigue con el principio del porrazo.
  La carga, además, con zancadas más rápidas, sombras azuladas que deja detrás, polvo y un temblor en cada zancada
  (`estela_carga`): con la animación sola parecía que andaba deprisa.
- Pistas para saber que hay que romper el escudo (21 nov): Johnny lo dice al entrar («Ese escudo lo aguanta todo...
  A ver si consigo que se lo estampe contra las taquillas») y junto a la barra de vida hay tres escuditos que se
  agrietan con cada choque (`barra_jefe.gd`, `pintar_escudo`).
- Más animaciones (23 nov, v3): lanzar el bote con el escudo en el otro brazo (`lanzar`), el escudo reventando al
  pasar de fase (`romper`, solo de frente: en las otras direcciones salió raro) y un dibujo nuevo **sin escudo** (otro
  estado del personaje en PixelLab, `assets/sources/antidisturbios-sin-72`) con su andar, porrazo (el combo), porrazo
  al suelo (`suelo`: el aviso del barrido y la porra clavada), golpe y muerte. Es otra hoja,
  `jefe-antidisturbios-sin`, con los mismos nombres: `animar` la pone al acabar de reventar el escudo, con su offset.
  Descartadas por prescindibles: mareado, el silbato en otras direcciones y repetir el noreste.

### Dibujos nuevos
El antidisturbios sin escudo con la porra (andar, combo, golpe al suelo, muerte). El escudo agrietado y las
pelotas, el gas y las chispas, con código.

## 2. El cocinero · «El banquete»

**Idea central:** la cocina es el reloj: si no le cortas la comida, se cura.

### Fase 1
- **La olla**: una olla gigante en el centro. Cada cierto tiempo va a removerla y, si termina, se come el guiso y
  se cura un poco. **El truco**: hay 3 sacos o cajas de ingredientes por la sala; si los rompes antes, la olla
  sale mala, se pone enfermo, se queda doblado unos segundos y recibe el doble de daño.
- **Fogones en damero**: las casillas del suelo se ponen al rojo, primero las blancas y luego las negras.
- **Sartenes que rebotan**: rebotan por la sala dejando gotas de aceite; se acumulan hasta que él las recoge con un
  grito.

### Fase 2: «servicio de urgencia»
Se le cae el gorro, coge dos cuchillos, modo frenético.
- **Corte en cruz**: franjas en cruz o en X desde él hasta las paredes. Desde el 24 nov (el dueño: no se entendía), grita
  «¡CORTE EN CRUZ!», en el aviso tiene cuatro cuchillos grandes apuntando por las franjas y luego salen volando hasta la
  pared dejando un tajo rojo: solo da el cuchillo que pilla a Johnny al pasar.
- **La olla se vuelca**: una ola de aceite cruza la sala y deja libres un par de mesas o huecos.
  Desde el 24 nov, la olla se vuelca de verdad: una animación de PixelLab (`assets/sources/salas/centro/olla-vuelca`,
  hoja `olla-vuelca`) que sustituye un momento a su dibujo quieto; la ola sale cuando el guiso llega al suelo. La ola es ahora de guiso verde, del color de lo que cae de la olla
  (`ola_aceite.gd`; era aceite dorado): el frente ondula, deja una película detrás y lleva burbujas, huesos, carne y gotas.
- La olla le cura más a menudo: hay que vigilar los ingredientes.

### Cómo quedó (23 nov)
- `cocinero.gd`, `saco_ingredientes.gd`, `sarten_rebota.gd`, `fogones_damero.gd`, `ola_aceite.gd` (el barrido del
  antidisturbios con otro dibujo: `barrido_electrico.gd` ahora tiene velocidad, daño y sonidos que se cambian).
- La olla es un mueble de verdad (`bigpot`, dibujo de PixelLab), puesto en medio de la cocina con la opción nueva
  `en_medio` de `Catalogo.SALAS` (`muebles.gd`, `en_medio`): choca y los zombis la rodean.
- Los sacos: 3 (patatas, tomates, harina; PixelLab), caen cada vez que cocina, aguantan 40 y son del grupo "zombis" (se
  rompen a golpes, a tiros y con explosiones). Cocina cada 17 s (12 en la fase 2); remueve 4,5 s (3,5), con un escudo de burbuja azul que no deja entrar nada («¡INMUNE!»; 24 nov, el
  dueño); se cura un 7 %
  de su vida por saco que quede (8 %; 24 nov, el dueño: más, eran 4 y 5 %). Sin sacos: enfermo 4,5 s y le entra el doble; se da la
  vuelta, vomita tres veces (un chorro y un charco «vomito», que a Johnny no le hace nada) y lleva estrellitas (24 nov, el dueño:
  que se note). Si se rompen todos antes, va a
  cocinar enseguida («¿Y MIS INGREDIENTES?»). Junto a la barra, tres saquitos que se tachan (`barra_jefe.gd`, `pintar_sacos`).
- El damero: cuadros de 4×4 casillas en toda la sala (24 nov: de 2×2 casi no cabía Johnny), aviso 1,1 s (0,8 en la fase 2) y quema 0,7 s, 12 de daño; esquivando
  también quema: hay que salir del cuadro. Cada 9 s (7,5). Al quemar, cada cuadro saca el efecto de pixelfx
  `fogon-llamas` (`tools/pixelfx/fogon-llamas.js`): plancha al rojo, lenguas de fuego, chispas y brasas. El suelo de la
  cocina es de rejillas de acero (24 nov, el dueño: con baldosas no cuadraba el fuego de repente; `tools/suelo_rejilla.py`,
  `ESTILO_TIENDA` "jefe-cocinero" en `mapa.gd`): cada panel es justo un cuadro del damero, y el fuego sale de debajo.
- Sartenes: hasta 5, una cada 3,5 s (24 nov, el dueño: eran 4, cada 5 s), rebotan y sueltan gotitas de aceite de 3 s; con 3 o más, «¡A FREGAR!» (cada 12 s): tiemblan 0,6 s y
  vuelven a su mano dando a quien pillen. Solo en la fase 1.
- Se fueron el abanico de cuchillos, la sartén de antes y el aceite que rebosaban los fogones solos (M82).
- Fase 2: otra hoja (`jefe-cocinero-sin`, PixelLab: calvo y con un cuchillo en cada mano), el gorro sale volando
  (con código). Cruz cada 5 s (+ o X, la mitad de las veces encadena la otra), 18 de daño; ola cada 13 s (dos olas, cada
  una con su hueco; sale de la olla hacia Johnny, así que detrás de la olla no llega); combo de dos cuchillazos y
  cuchillos clavados 1,6 s (le entra un 50 % más); lluvia de 6 cuchillos cada 8 s; la marca de cada
  uno es el aviso de los jefes (`aviso.gd`, un círculo de cuadraditos que se llena; 24 nov, el dueño: antes, un anillo rojo).
- Animaciones nuevas de PixelLab: remover y enfermo (con y sin gorro) y, sin gorro, andar, cuchillazo doble y lanzar.
- Pista: al entrar, Johnny dice «Si se come ese guiso, se cura... A ver qué cocina sin ingredientes».
- Prueba: `--captura --edificio centro --jefe cocinero --banquete`.

## 3. La modista · «El desfile»

**Idea central:** pelea de mirar y pensar.

### Fase 1: la tienda
- **Hilos**: cose hilos entre maniquíes, como láseres que cruzan la sala; hacen daño al tocarlos y se cortan a
  golpes. Se van tensando.
- **Carretes que rebotan**: ruedan dejando hilo; se acumulan en una telaraña.
- **El truco**: cuando se esconde, solo la de verdad tiene sombra (o parpadea distinto). Si le das a ella, sale
  aturdida; si te equivocas, ese maniquí revienta en alfileres.

### Fase 2: la pasarela
Se apagan las luces; solo un foco recorre la sala de lado a lado.
- Los maniquíes solo se mueven a oscuras; bajo el foco, quietos.
- Ella ataca desde la oscuridad con tijeretazos que cruzan la sala en línea, de un borde al otro.
- **El truco**: si el foco la pilla, se queda congelada como un maniquí.

### Cómo quedó (24 nov)
- `modista.gd`, `hilo_modista.gd` (los hilos y su carrete), `foco_modista.gd` (el foco); `maniqui_vivo.gd` también se
  queda quieto bajo el foco.
- **Hilos** (fase 1): tira un carrete hacia Johnny (desviado al azar, para que se crucen) que rueda hasta la pared
  dejando el hilo; el carrete da 8 al pasar. Flojo, el hilo **solo enreda** (el estado nuevo "enredado": anda un 45 %
  más despacio). Tira tres de golpe, en abanico, cada 2,4 s, hasta 10 (24 nov, el dueño: más, si no cortarlos no
  aporta; eran uno cada 3 s, hasta 5). Con 4 o más tendidos, cada 9 s, «¡A TENSAR!»: se ponen rojos, 0,8 s de aviso con un
  abanico rojo en el suelo, y **barren la sala**: cada hilo gira como una guadaña unos 45° sobre su carrete de la
  pared, hacia donde está ella (las paredes lo paran), en 0,55 s. Al que pilla le quita 14 y lo deja **atado** 1,3 s
  (el estado "atado"); ella grita «¡TE TENGO!» y va corriendo a por él para darle un tijeretazo. **Solo se cortan a
  golpes** (los tiros los atraviesan) y uno de cada tres es **gordo**: hacen falta dos golpes (24 nov, el dueño: se
  esquivaban y se rompían demasiado fácil). Junto a la barra, diez carretitos: llenos los
  hilos tendidos, y en rojo cuando ya puede tensar (`barra_jefe.gd`, `pintar_hilos`).
- **Esconderse** (cada 7 s): grita «¿A QUE NO ME ENCUENTRAS?», le brillan los ojos 0,6 s y se cambia con un maniquí lejano; a la vez salen retales de
  todos los maniquíes (`tools/pixelfx/retales.js`, el "feather-burst" en granate y crema), para que no se vea con cuál.
  Escondida 6 s (eran 4,5), **disfrazada de maniquí**: se dibuja con el mismo dibujo que el maniquí con el que se cambia
  (24 nov, el dueño: antes se veía solo un salto, porque ella no se parece a los maniquíes). Ya no salta si Johnny se acerca. Solo la delata que **respira** (sube un píxel la mitad de cada
  respiración de 1,7 s) y un parpadeo de los ojos cada 2-3,5 s. Si le pegan escondida: «¡ME HAS VISTO!», aturdida 2,5 s
  con estrellitas y le entra el doble. Si le pegan a otro maniquí: un aro rojo de 0,5 s y revienta en 12 alfileres.
  Cada maniquí lleva para eso un señuelo invisible del grupo "zombis" (el apuntado automático no lo busca).
- Se quedan los alfileres y el tijeretazo; se fue «¡TE TOMO MEDIDAS!». Ella anda a media distancia (unos 260).
- **Fase 2**: «¡QUE EMPIECE EL DESFILE!» con su pose; los hilos se caen, se apagan las lámparas de la tienda (más
  oscuridad: `Luz.evento` + 0,45), sale el foco (radio 120, cruza de lado a lado a 115 y sube y baja en 14 s) y
  despiertan 3 maniquíes. Johnny dice «Si el foco la pilla, se queda tiesa...». Ella ronda apartándose del foco (se le
  ven los ojos) y cada 5,5 s, «¡A LA PASARELA!»: franja de aviso hasta la pared (0,9 s, luego 0,55) y cruza corriendo
  a 900 con las tijeras por delante, 3 veces seguidas, 18 de daño. Si el foco la pilla (también corriendo): «¡TIESA!»,
  gris y quieta 2,2 s, le entra el doble; luego 3,5 s en que el foco no la para. Al caer ella vuelve la luz.
- Animaciones nuevas de PixelLab (v3, 20 generaciones): corte (8 direcciones; de frente y abajo a la derecha se quitan
  los dos últimos fotogramas, con unas tijeras gigantes brillando), aturdida y desfile (solo de frente).
- Pista: al entrar, Johnny dice «Uno de esos maniquíes respira...».
- Prueba: `--captura --edificio centro --jefe modista --desfile`.

## 4. La mascota · «La fiesta de cumpleaños»

**Idea central:** caos de juguetes que rebotan y se acumulan.

### Fase 1
- **Pelotas saltarinas**: cada embestida contra una pared suelta 2 pelotas que rebotan sin parar y se suman.
- **Salto**: como ahora, pero al caer aplasta las pelotas cercanas y salen disparadas en todas direcciones.
- **Tren de juguete**: unas vías en el suelo; el tren las recorre (una franja que sigue un camino fijo).
- **El truco**: cajas sorpresa por la sala; si choca contra una, el muñeco salta, la deja tirada mucho más rato y
  todas las pelotas explotan. Hay que llevarla hasta ellas.

### Fase 2: «descosida»
Se le rompe la tripa y va soltando relleno.
- El relleno se queda en el suelo y arde con el fuego (molotov, lanzallamas): daño enorme si la llevas por encima.
- Más pequeña y mucho más rápida; rebota por la sala como una pelota más.
- Los críos traen globos que al reventar sueltan más pelotas.

## 5. El gerente · «La junta de accionistas»

**Idea central:** el jefe final, en 3 fases; la azotea cambia en cada una.

### Fase 1: el ejecutivo
- **Contratos que vuelven**: vuelven a su mano como un bumerán (se esquivan dos veces).
- **El gráfico de ventas**: columnas que suben del suelo en fila, recorriendo la azotea de lado a lado.
- **«¡A TRABAJAR!»**: como ahora.

### Transición: la jeringa
**El truco**: mientras se pincha, si le pegas a la jeringa lo bastante, se rompe y muta mal (menos vida y medio
tentáculo roto). Si no llegas, muta entero.

### Fase 2: el mutado
- **Latigazos que barren** la azotea de lado a lado, a ras de suelo, uno tras otro.
- **Tentáculos clavados**: golpea el suelo y se quedan clavados unos segundos; pegarle a uno clavado hace daño al
  cuerpo (punto débil).
- **Embestida** contra los aparatos, como ahora.

### Fase 3 (a un cuarto de vida): el colapso
- La azotea se resquebraja: trozos se marcan y se hunden; el sitio para moverse se hace pequeño.
- El helicóptero de Velaria barre la azotea con su foco disparando.

## Orden

Se van rehaciendo uno a uno, empezando por el **antidisturbios** (decidido por el dueño el 21 nov). Las piezas
comunes se hacen según las vaya necesitando cada jefe.
