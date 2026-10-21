# Controles y teclas de prueba

## Jugar

- **Moverse:** WASD, flechas o stick izquierdo. **Esquivar:** Espacio, Mayús o A.
- **Opciones** (menú principal y pausa): modo de atacar (se guarda), música, sonido y la lista de controles, que se pueden cambiar (pulsar la casilla y luego la tecla o el botón; si ya la usaba otra acción, se intercambian; "Restablecer controles" vuelve a los de serie). **F1** también cambia el modo de atacar: *asistido* (apunta y ataca solo, como en el JS), *hacia donde mira* (J, clic o
  X) y *libre* (ratón + clic, o stick derecho).
- **Q** / rueda / Y: cambiar entre las dos armas. **R** / RB: recargar.
- **E**, clic derecho o RT (mantener para apuntar, soltar para lanzar): molotov o granada; **F** / LB cambia entre ellos.
- **Tab**, **I** o Select: inventario (las armas, las guardadas y la mochila; ponérselas y tirar al suelo).
- **Esc** / Start: pausa. Los menús van con ratón, flechas + Intro o mando (cruceta o stick, A pulsar, B volver).

## Teclas de prueba

- **1-6**: poner cualquier arma.
- **F2 a F7**: un zombi de cada tipo (normal, lento, rápido, explosivo, tentáculos, venenoso). **P**: la portera.
- **M**: recuadro de mutaciones. **O**: soltar un objeto al azar.
- **F9**: sala de exposición (todos los muebles con sus variantes y todos los zombis con sus ropas) y vuelta.
- **F10**: quitar y poner la penumbra. **H**: apartamento del superviviente ya sin zombis (rescate y horda).

## La sala de mantenimiento

La partida (`escenas/partida.tscn`) empieza ahí, tras el menú principal (`escenas/menu_principal.tscn`).
- Mesa del ordenador: **ConserjeOS** (puntos de talento, árbol de talentos, tienda de armas, logros, Dosier VD-7 y Noticias de Canal 8).
- A su derecha, el **baúl** (las armas creadas para la partida); a su izquierda, el **banco de trabajo** (recetas).
- Los baños tienen un armarito con botiquín. Los supervivientes rescatados esperan a la derecha del ordenador:
  arrimarse a uno para que te acompañe.
- La sala de pruebas de las fases 1-3: abrir `escenas/salas/bano.tscn` y **F6**.

## Móvil (táctil)

`scripts/ui/tactil.gd`, solo mientras se juega. Joystick izquierdo (se toca en la mitad izquierda); abajo a la
derecha, según el modo: nada (asistido), botón de atacar (hacia donde mira) o joystick derecho (libre). En arco:
esquivar, las dos armas (tocar la otra la saca; tocar la de fuego en la mano recarga) y lanzar (arrastrar y soltar),
con el botoncito de cambiar lanzable. Bajo el minimapa: modo, inventario y pausa. En los menús el dedo hace de
ratón. En táctil la pantalla se agranda sin redondear (si no, en móviles con muchos píxeles se quedaría en 1×).

Probarlo en el navegador integrado: menos de 768 de ancho (p. ej. 740×360) y toques con `TouchEvent` desde
JavaScript (los clics llegan como ratón).

## Guardado

`%APPDATA%\Godot\app_userdata\Zombie Escape\guardado.json` (borrarlo = empezar de cero); la prueba con `--captura`
usa `guardado-prueba.json`. En la web va en el navegador (IndexedDB).
