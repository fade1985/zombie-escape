# Rediseño de los jefes del centro comercial

Plan del 21 nov para rehacer los cinco jefes del centro comercial (antidisturbios, cocinero, modista, mascota y el
gerente), **uno a uno**. Al terminar cada uno, se marca aquí como hecho y se apunta lo que cambió respecto al plan.

| Jefe | Estado |
|---|---|
| Antidisturbios | en diseño |
| Cocinero | pendiente |
| Modista | pendiente |
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

### Fase 2: sin escudo (por decidir con el dueño)
Sin escudo ya se le pega por todos lados, así que pelea más rápido y más agresivo.
- **Se quedan** el gas (más botes, nubes más grandes) y la carga (más rápida; al chocar se atonta menos rato,
  ya no hay escudo que romper).
- **Se van** las pelotas de goma (explotaron con el escudo) y el silbato (ya no llama a nadie: es él solo).
- **Nuevo, barrido eléctrico**: golpea el suelo y sale una franja de chispas que cruza la sala de lado a lado;
  2-3 seguidas, cada una con el hueco en otro sitio (o se atraviesan esquivando).
- **Nuevo, combo de porrazos**: 3 golpes encadenados avanzando; el último se le queda clavado en el suelo y es la
  ventana para pegarle.

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
- **Corte en cruz**: franjas en cruz o en X desde él hasta las paredes.
- **La olla se vuelca**: una ola de aceite cruza la sala y deja libres un par de mesas o huecos.
- La olla le cura más a menudo: hay que vigilar los ingredientes.

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
