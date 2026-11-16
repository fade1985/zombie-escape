# Pendientes · fallos, mejoras y cosas por limar

Lista del dueño. Él dicta los puntos y Claude solo los apunta aquí.

- **No se trabaja en ningún punto hasta que el dueño lo pida** ("haz el F2", "el de la puerta del baño").
- Cuando un punto está hecho y tiene el visto bueno, **se borra de la lista** (no se tacha) en el mismo commit.
- Cada punto lleva un código fijo (`F` fallo, `M` mejora, `L` por limar) y un número que **no se vuelve a usar**
  aunque el punto se borre, para que "haz el F2" siempre señale al mismo.
- Una línea por punto, con lo justo para reconocerlo: dónde pasa y cómo se ve. Si hace falta más detalle, se
  pone debajo con sangría.

Dictados el 16 nov, repartidos en cuatro tandas (cada una, su sesión): **T1** arreglos pequeños (Sonnet · medium),
**T2** reglas del juego (Opus · high), **T3** supervivientes con comida favorita (Opus · high), **T4** el garaje
(Opus · high; antes de nada, pedir al dueño las fotos de referencia).

## Fallos

- **F23** (T1) Bajo D, dormitorio de matrimonio: un muro invisible junto a la cama no deja rodearla ni acercarse.
- **F24** (T1) Apartamentos: a veces los durmientes se quedan dando vueltas sobre sí mismos al entrar en una estancia.
- **F25** (T1) Al registrar un mueble a veces se cierra también la puerta. Acordado: si hay un mueble al alcance, la E
  es siempre para el mueble; la puerta solo cuando no hay ninguno cerca o Johnny la está tocando.
- **F26** (T2) Al mejorar la rareza de un lanzable sube también cuántos se pueden llevar: no debe cambiar.

## Mejoras

- **M115** (T2) Durabilidad de 1 a 4 (ahora la ficha enseña de 0 a 3). Gasta una solo la primera vez que sale del
  baúl en cada partida (ya funciona así).
- **M116** (T2) Al caer o abandonar se pierden todos los dólares; cambiarlo también en el tutorial.
- **M117** (T2) Banco de trabajo: los lanzables se mejoran de uno en uno; el mejorado sale de su montón y se junta con
  los de su nueva rareza. Con el baúl lleno, aviso de que no se puede mejorar hasta liberar sitio.
- **M118** (T2) Si el durmiente explosivo llega a explotar, despierta a todos los durmientes del apartamento.
- **M119** (T2) Los zombis que invocan los jefes no dan nada (ni mutágeno, ni dólares, ni munición).
- **M120** (T2) El reto del día y la alerta, bloqueados hasta completar el primer edificio.
- **M121** (T2) La alerta pasa a llamarse «mejora del compuesto VD-7»: sin premios de ningún tipo y solo esto (fuera
  las reglas de ahora): +20 % por nivel a la vida, el daño, la velocidad de movimiento y la de ataque de los
  enemigos (+100 % en el nivel 5).
- **M122** (T2) Logros por matar durmientes o hacer daño con cada arma, para que el 100 % obligue a usarlas todas.
- **M123** (T2) Ventanas de tutorial nuevas: antes del primer jefe, que pase por la sala de mantenimiento a gastar
  dólares y mutágeno o a dejar cosas a salvo en el baúl; guardar las balas para los jefes (muy duros cuerpo a
  cuerpo); llevar siempre lanzables (las hordas pueden ser imposibles).
- **M124** (T3) Supervivientes: en los trasteros hay que darles a la E para que te acompañen, y solo si llevas su
  comida favorita (una por superviviente); sin ella dicen en la cabeza «Estoy muy débil» (como el texto de la llave,
  en blanco). La comida sale en la nevera y la encimera, con una probabilidad parecida a la de los materiales.
  Arte: prompt para GPT con imagen de referencia del dueño. Con su tutorial.
- **M125** (T4) Nuevo reto del día: un garaje subterráneo (columnas y coches, como la azotea) con 25 oleadas de
  durmientes cada vez más duras y, cada 5, también un jefe del edificio. El baúl en el centro (pausa al abrirlo). Los
  durmientes sueltan balas un 10 % y no dan dólares; la oleada N da N dólares, y te los llevas aunque caigas o
  abandones. 5 s de descanso entre oleadas (10 s si hubo sonámbulo). Una vez al día. Cada día prohíbe una cosa
  (cuerpo a cuerpo, a distancia, especiales, lanzables o vendas y botiquines): se ve al pasar el cursor. Bajo el
  botón, en vez del premio, «Récord: N oleada/oleadas» de la condición de ese día. Arte con prompts para GPT y
  fotos de referencia del dueño (pedirlas antes de empezar). Con su tutorial.

## Por limar

- **L39** (T1) Ordenador, sujetos: en vez de «Elige un sujeto…», el fondo de la ficha vacío.
- **L40** (T1) Al coger un material salen dos textos: quitar el blanco pequeño y dejar el amarillo sobre Johnny.
- **L41** (T1) El cartel de arriba: «Sala de mantenimiento», «Apartamento 3ºB», «Azotea» y, en el pasillo, «Planta 2».
- **L42** (T1) Las balas de la gatling, en dos filas en zigzag sobre la vida, ajustadas al marco por los dos lados.
- **L43** (T1) Al completar un edificio, fuera «Jugar otra vez»: se vuelve al menú principal (para cambiar la alerta).
- **L44** (T1) Logros: el recuadro del dinero, igual que en la tienda de armas y el inventario.
- **L45** (T1) Cartel de edificio completado: sin la última frase si no se ha hecho mejor marca.
- **L46** (T1) Elige edificio: «Récord» debajo de Apartamentos, en el amarillo del juego.


