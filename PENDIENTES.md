# Pendientes · fallos, mejoras y cosas por limar

Lista del dueño. Él dicta los puntos y Claude solo los apunta aquí.

- **No se trabaja en ningún punto hasta que el dueño lo pida** ("haz el F2", "el de la puerta del baño").
- Cuando un punto está hecho y tiene el visto bueno, **se borra de la lista** (no se tacha) en el mismo commit.
- Cada punto lleva un código fijo (`F` fallo, `M` mejora, `L` por limar) y un número que **no se vuelve a usar**
  aunque el punto se borre, para que "haz el F2" siempre señale al mismo.
- Una línea por punto, con lo justo para reconocerlo: dónde pasa y cómo se ve. Si hace falta más detalle, se
  pone debajo con sangría.

## Fallos

- **F1.** En la sala de mantenimiento aparece siempre un mueble al lado de la taquilla que no debería
  existir: quitarlo.
- **F2.** Los zombis de un piso se concentran en el baño: tienen que estar repartidos por todas las
  habitaciones del piso.
- **F3.** El vómito de la mutación Gastroenteritis atraviesa paredes: no debe hacerlo.

## Mejoras

- **M1.** El superviviente que acompaña a Johnny ataca a los zombis que ve: si los ve pero no los tiene a
  rango, se acerca y los ataca aunque rompa la formación. Cuando mata a todos los que ve (uno o varios),
  vuelve a la formación como siempre.
- **M2.** La habitación del Glotón nunca tiene muebles: en su lugar está toda llena de caca, heces y diarrea,
  también las paredes. Esa porquería es una mezcla de mierda y ácido: quita vida al pisarla, así que en la
  pelea no se puede uno acercar a él sin más.
- **M3.** Mini presentación de cada jefe: al empezar la pelea, un pequeño zoom que lo enfoca solo a él
  mientras suelta un grito, y sale su nombre en pantalla.
- **M4.** Meter objetos en el baúl a mano: además de que los del inventario pasen solos al baúl al acabar la
  partida, al arrimarse al baúl se pueda elegir desde el inventario qué objetos guardar en él.
- **M5.** Ascensor a la sala de mantenimiento: al completar una planta, además de abrirse las escaleras de
  emergencia, sale un mensaje de Johnny diciendo que ha podido arreglar el ascensor para bajar a la planta
  baja, donde está la sala de mantenimiento. El ascensor solo sirve para bajar a la planta baja y volver a la
  planta de la que venimos; nunca para ir entre plantas.
- **M6.** La habitación del Gymbro es un gimnasio: máquinas pegadas a las paredes que reducen el espacio
  libre, y mancuernas por el suelo que, al pisarlas, nos hacen caer y tardamos 2 segundos en levantarnos.
- **M7.** La habitación de la portera: cubos y fregonas colgando de las paredes, cubos de basura, y cubos
  por el suelo que, al pisarlos, nos hacen caer y tardamos 2 segundos en levantarnos.
- **M8.** La habitación del jefe de bomberos está en llamas por todo el borde, rodeando la habitación entera
  menos la puerta de entrada. Su ataque de girar con una lengua de llamas tiene que llegar hasta la pared,
  de forma que solo se pueda esquivar corriendo en el mismo sentido en el que gira.

## Por limar

- **L1.** Rehacer con PixelLab el banco de trabajo, el baúl, la taquilla, la ferretería y la cafetera: vistos
  de frente y un poco desde arriba (tres cuartos), con el mismo arte que llevan los muebles hasta ahora.
- **L2.** El nombre de cada puerta de piso se ve poco estético. Ponerlo como en un edificio real: la letra
  del piso al lado de la puerta y, junto al ascensor, en grande, la planta en la que estás. Que quede más
  realista.
- **L3.** El ascensor averiado: quitar el letrero "averiado" de encima y poner en su lugar más cintas
  amarillas con franjas negras cruzándolo. Que quede más realista.
- **L4.** En los pasillos, sin muebles: solo plantas con maceta y las lámparas que ya hay. Más realista.
  Lo elegido por el dueño:
  - Plantas (tres tipos): ficus o palmera de interior en maceta grande, sansevieria (lengua de suegra) y la
    planta que ya tenemos.
  - Cosas de portal: felpudo delante de cada puerta; extintor en la pared; buzones solo en la planta baja,
    cerca del portal; cartel de salida de emergencia que se enciende cuando ya se puede subir a la siguiente
    planta.
  - Arquitectura: solo el radiador, nada de ventanas.
