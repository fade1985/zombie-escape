# Controles y sala de pruebas

## Jugar

El mando sigue lo habitual en juegos de dos sticks: gatillos para atacar (RT) y lanzar (LT), y esquivar también en
LB para no soltar el stick derecho al apuntar. Todo se puede cambiar en Opciones.

| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | WASD o flechas | stick izquierdo |
| Esquivar | Espacio o Mayús | A o LB |
| Atacar | según el modo: solo (asistido) o ratón + clic o J (libre) | RT / stick derecho |
| Cambiar modo de atacar | F1 o C | cruceta abajo |
| Cambiar de arma (cuerpo a cuerpo / distancia) | Q o rueda | Y |
| Recargar | R | X |
| Lanzar (mantener para apuntar, soltar para lanzar) | E o clic derecho | LT |
| Cambiar lo que se lanza (3 a mano) | F | RB |
| Inventario | Tab o I | Select |
| Pausa | Esc | Start |

- **Opciones** (menú y pausa): modo de atacar, música, sonido, la pestaña **Ayudas** (*Vida entera*, *Pistola sin
  fin*, *Lanzar apuntando solo*; no cambian récords) y la lista de controles (pulsar la casilla y luego la tecla; si
  ya la usaba otra acción, se intercambian).
- **Munición:** va por tipos (balas de pistola, que también gasta la MP5; cartuchos; gasolina, ácido y baterías) en 8
  huecos de dos cargadores. Una caja da un cargador del arma a distancia de la mano.
- **Lanzables:** 3 a mano y 8 de repuesto; al acabarse uno de la mano, entra el primero de repuesto.
- **Inventario «todo a la vista»:** Johnny en medio con sus armas (dos de cada tipo: la de la mano y la de repuesto) y
  sus 3 arrojables; la mochila, la munición y los arrojables de repuesto (8 de cada); a la derecha, la ficha de lo
  elegido con sus botones (**Ponérmela**, **Usar**, **A la mano**, **Al repuesto**, **Tirar al suelo**).
  - Flechas o mando: la ficha sigue a la marca; Intro o A salta al botón principal; Y lo hace directamente; X o Supr
    tira; B, Esc o Tab cierran.
  - Ratón o dedo: se toca, o se **arrastra** (se encienden los sitios donde vale soltar; encima de Johnny, se pone el
    arma o se usa la cura; en la zona roja de la ficha, se tira la casilla entera; donde no vale, vuelve y tiembla).
- **Elige edificio:** **<** y **>** cambian el nivel de alerta (completar el edificio abre el siguiente, hasta el 5).
  El botón **Reto del día**: el edificio igual para todo el mundo ese día, con la regla rara de hoy.

## La sala de pruebas

Todo lo de probar está en un solo sitio. **F11**, desde cualquier sitio de cualquier planta, lleva a la **sala de
pruebas**; **F11** otra vez (o su puerta) vuelve justo adonde estabas. Con la puerta de un apartamento cerrada, no se
puede ir. En el navegador, F11 también pone la pantalla completa. Lo que pasa allí no cuenta: los zombis no sueltan
nada, no se apuntan en las Colecciones y, al salir, Johnny vuelve a llevar lo que llevaba (armas, balas, mochila y
arrojables).

- **La diana:** un zombi en el centro que no muere ni ataca. **Coma** y **punto** pasan por todas las armas de la
  tienda; munición sin fin, pero hay que recargar.
- **Las líneas de ayuda**, en el suelo: alcance (blanco), a quién apunta (amarillo), por dónde irá la bala (azul a
  rayas), dónde le da a cada zombi (rojo) y el camino de cada bala (verde si da, naranja si pasa rozando, rojo con X
  si choca).
- **El panel de daño**, arriba a la izquierda: la ficha del arma y el recuento (disparos, aciertos, daño por
  segundo...). **Retroceso** pone el recuento a cero; el **guion** esconde el panel.
- **El baúl de pruebas** (arriba a la izquierda): todas las armas y los arrojables en cada calidad, para cogerlos y
  cambiarlos. Es de mentira: el baúl de verdad y la partida guardada no se tocan.
- **Atajos**, también con el panel cerrado: **1…8**, un zombi de cada tipo; **Mayús + 1…0**, un jefe (portera,
  antidisturbios, cocinero, modista, mascota, gerente, Glotón, Gymbro, jefe de bomberos, científico jefe). Salen con
  las opciones del panel (a media vida, quieto, cuántos). El número de cada uno está en su botón.
- **El panel de pruebas** (**P**; P, Esc o B lo cierran). Con el juego parado, por pestañas:

| Pestaña | Qué tiene |
|---|---|
| Jefes | un botón por jefe (atajo: **Mayús + 1…0**); **A media vida** (sale ya enfadado) y **Quieto** (ataca y avisa, pero no se mueve) |
| Zombis | un botón por tipo (atajo: **1…8**: normal, lento, rápido, explosivo, tentáculos, venenoso, vigilante, dependienta), **Cuántos** (1, 3, 5 o 10) y **Borrar todos** |
| Ayudas | se encienden y se apagan: cada línea de ayuda, el panel de daño, los avisos de los jefes en el suelo y la penumbra |
| Johnny | **Invencible**, **Munición sin fin**, la **Diana** (ponerla o quitarla) y **Siguiente skin** (no se guarda) |
| Ir a | la **Exposición** (todos los muebles y zombis; F11 vuelve), la **Azotea**, el **Superviviente** (su apartamento ya sin zombis; en el centro comercial, cada vez el siguiente) y la sala de cada minijefe del edificio, en la planta que le tocó |
| Varios | **Mutaciones**, **Soltar un objeto**, **Piezas al baúl** (10 de cada familia y unas armas y arrojables mejorados, al baúl de verdad, para probar el banco), **Colecciones completas** y **Científico muerto** (la página siguiente; no se guarda) |

En **Elige edificio**, la **N** abre todos los edificios hasta cerrar el juego.

**Pruebas sin jugar** (`--captura`, ver CLAUDE.md): la lista de opciones (`--jefe X`, `--armas`, `--inventario`,
`--evento X`...) está al principio de `scripts/pruebas/partida_prueba.gd`, con el archivo de cada una; encima de
cada prueba se explica lo que comprueba y las fotos que saca.

## La sala de mantenimiento

La partida empieza aquí. Tres estancias de 10 × 10 una al lado de otra (arriba pone en cuál estás):

- **Despacho** (en medio): la puerta de abajo sale al pasillo. La mesa del **ordenador** (ConserjeOS: talentos,
  tienda de armas, logros, Dosier, Noticias y Colecciones), un corcho y una papelera. La tienda vende armas cuerpo a
  cuerpo, A distancia y especiales, en calidad Normal, y los arrojables de uno en uno (molotov y granada $5,
  atraedora y congeladora $8) hasta su máximo; todo, para esa partida.
- **Vestuario** (izquierda): ducha, lavabo, váter y banco, de adorno, y la **taquilla** de Johnny para elegir skin
  (las que no tienes salen con «???» y cómo se consiguen): el portero (la portera; fregona × 4), el glotón (el
  Glotón; quien te hace daño lo paga), el gymbro (el Gymbro; cuerpo a cuerpo × 3) y el bombero (el jefe de bomberos;
  lo que quema × 3 y el fuego no le hace nada).
- **Taller** (derecha): el **banco de trabajo**, que sube de calidad, nivel a nivel, las armas y los
  paquetes de arrojables (los que lleva y los del baúl) con las piezas de su familia que sueltan los zombis y los
  jefes: las armas, 3 para Poco común, 6 para Rara y 10 para Épica; los arrojables, que se gastan, 1, 2 y 4. Valen las
  de la mochila (se gastan primero) y las del baúl. Se maneja como el baúl: elegir la casilla y «Mejorar» (o Y en el
  mando). La **Épica** trae un truco: cuerpo a cuerpo, cada 4 golpes uno es crítico («¡GOLPE DE GRACIA!»); a distancia,
  las balas atraviesan a un zombi (estela morada); especiales, el zombi que matan revienta y prende, echa ácido o da
  calambre a los de al lado; arrojables, al romperse o explotar sueltan 2 más pequeños. Y el **baúl**
  (32 casillas; lo guardado no se pierde si Johnny cae; se maneja como el inventario y se arrastra de una mitad a la
  otra). Guarda objetos, armas (menos la fregona y la pistola Normales) y paquetes de arrojables mejorados, cada arma
  y cada paquete en su casilla con el borde del color de su **calidad** (gris Normal, verde Poco común, azul Rara,
  morado Épica). Lo que lleva encima se pierde si cae; al completar el edificio, sus armas y sus arrojables mejorados
  pasan solos al baúl. La joyería del centro comercial da un arma Épica. Por la puerta de la derecha, las **viviendas** de los rescatados: arrimarse a uno para que te acompañe (uno a
  la vez).

Al caer el jefe de una planta (de la 1ª en adelante), Johnny arregla el **ascensor** del pasillo: baja a esta sala y
vuelve a la misma planta, delante del ascensor. En la planta baja sigue averiado y la azotea no tiene.

## Móvil (táctil)

`scripts/ui/tactil.gd`, solo mientras se juega. Joystick izquierdo (mitad izquierda de la pantalla); abajo a la
derecha, según el modo: esquivar grande (asistido) o joystick derecho (libre).
En arco: esquivar, las dos armas (tocar la otra la saca; tocar la de a distancia en la mano recarga) y lanzar (arrastrar y
soltar), con el botoncito de cambiar lanzable. Bajo el minimapa: modo, inventario y pausa. En los menús el dedo hace
de ratón. En táctil la pantalla se agranda sin redondear.

En Opciones → General, apartado **Móvil** (solo en táctil): tamaño de los botones (0,8 a 1,4), transparencia (100 a
30 %) y vibración (35 ms al recibir un golpe y al esquivar; en iPhone no hay).

Probarlo en el navegador integrado: menos de 768 de ancho (p. ej. 740×360) y toques con `TouchEvent` desde
JavaScript (los clics llegan como ratón).

## Guardado

`%APPDATA%\Godot\app_userdata\Zombie Escape\guardado.json` (borrarlo = empezar de cero); la prueba con `--captura`
usa `guardado-prueba.json`. En la web va en el navegador (IndexedDB).
