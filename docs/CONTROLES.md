# Controles y teclas de prueba

## Jugar

Los de serie del mando siguen lo habitual en juegos de dos sticks: los gatillos para atacar (RT) y lanzar
(LT), y esquivar también en LB para no soltar el stick derecho al apuntar.

- **Moverse:** WASD, flechas o stick izquierdo. **Esquivar:** Espacio, Mayús, A o LB.
- **Opciones** (menú principal y pausa): modo de atacar (se guarda), música, sonido y la lista de controles, que se pueden cambiar (pulsar la casilla y luego la tecla o el botón; si ya la usaba otra acción, se intercambian; "Restablecer controles" vuelve a los de serie). **F1**, **C** o la cruceta abajo también cambian el modo de atacar: *asistido* (apunta y ataca solo, como en el JS), *hacia donde mira* (J, clic o
  RT) y *libre* (ratón + clic, o stick derecho).
- **Q** / rueda / Y: cambiar entre las dos armas. **R** / X: recargar.
- **E**, clic derecho o LT (mantener para apuntar, soltar para lanzar): molotov o granada; **F** / RB cambia entre ellos.
- **Tab**, **I** o Select: inventario (las armas, las guardadas y la mochila; ponérselas y tirar al suelo).
- **Esc** / Start: pausa. Los menús van con ratón, flechas + Intro o mando (cruceta o stick, A pulsar, B volver).
- **Elige edificio:** debajo de cada tarjeta, **<** y **>** cambian el nivel de alerta (de los abiertos; se
  recuerda el último elegido). Completar el edificio con una alerta abre la siguiente, hasta la 5.

## Teclas de prueba

- **1-6**: poner cualquier arma.
- **F2 a F7**: un zombi de cada tipo (normal, lento, rápido, explosivo, tentáculos, venenoso). **V**: un vigilante y
  **B**: una dependienta (los del centro comercial). **P**: la portera. **K**: el antidisturbios.
- **M**: recuadro de mutaciones. **O**: soltar un objeto al azar.
- **F9**: sala de exposición (todos los muebles con sus variantes y todos los zombis con sus ropas) y vuelta.
- **F10**: quitar y poner la penumbra. **H**: apartamento del superviviente ya sin zombis (rescate y horda).
  En el centro comercial, cada H trae al siguiente de sus tres (ferretero, farmacéutica, técnico): rehace
  la planta con su tienda y te lleva a ella, ya sin zombis. Con uno ya rescatado en la partida, no hace nada.

**Pruebas sin jugar** (se añaden detrás de `--path . -- --captura`; ver CLAUDE.md):
- `--edificio centro`: en el centro comercial. `--fotos-tiendas`: una foto de cada tienda y de los peligros.
- `--alerta N` (1 a 5): en vez de la prueba larga, la de los niveles de alerta: dice en la terminal los números de
  cada regla (zombis, velocidad, jefe, botiquín, oído, rarezas del banco, guardia o vecino de la llave) y saca
  `captura-alerta.png` (el aviso del principio), `captura-alerta-llave.png` (el guardia o, en los Apartamentos, el
  vecino de la llave) y `captura-alerta-fin.png`; la foto de "Elige edificio" sale con las alertas abiertas.

## La sala de mantenimiento

La partida (`escenas/partida.tscn`) empieza ahí, tras el menú principal (`escenas/menu_principal.tscn`).
- Mesa del ordenador: **ConserjeOS** (puntos de talento, árbol de talentos, tienda de armas, logros, Dosier VD-7 y Noticias de Canal 8).
- A su derecha, el **baúl** (las armas creadas para la partida); a su izquierda, el **banco de trabajo** (recetas).
- Los baños tienen un armarito con botiquín. Los supervivientes rescatados esperan a la derecha del ordenador (los
  del centro comercial, en una segunda fila, debajo): arrimarse a uno para que te acompañe.
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
