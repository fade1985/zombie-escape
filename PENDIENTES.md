# Pendientes · fallos, mejoras y cosas por limar

Lista del dueño. Él dicta los puntos y Claude solo los apunta aquí.

- **No se trabaja en ningún punto hasta que el dueño lo pida** ("haz el F2", "el de la puerta del baño").
- Cuando un punto está hecho y tiene el visto bueno, **se borra de la lista** (no se tacha) en el mismo commit.
- Cada punto lleva un código fijo (`F` fallo, `M` mejora, `L` por limar) y un número que **no se vuelve a usar**
  aunque el punto se borre, para que "haz el F2" siempre señale al mismo.
- Una línea por punto, con lo justo para reconocerlo: dónde pasa y cómo se ve. Si hace falta más detalle, se
  pone debajo con sangría.

## Fallos

- **F12** Cuando un enemigo muere cerca de una pared, su cuerpo se mete dentro de la pared y se ve mal (visto en el
  pasillo de un apartamento, en la web).
- **F13** Menús del ordenador: al moverse por ellos se va solo al final de la página; al entrar en cualquier menú tiene
  que empezar arriba del todo.
- **F14** Talentos: al poner un punto, la página se va sola hasta abajo del todo; tiene que quedarse donde estaba
  (parecido al F13).
- **F15** A veces los zombis se quedan atascados en una puerta al intentar salir todos a la vez.
- **F16** Pantalla completa: al pulsar Esc (para la pausa) también se sale de la pantalla completa, y no debería. En la
  web es el propio navegador; mirar si se puede evitar (por ejemplo con el bloqueo de teclado de Chrome).
- **F17** El molotov: al lanzarlo con varios enemigos delante, el juego se congela (el dueño lo llama «crasheo»). Medido
  en Windows con 12 zombis: unos 10 fotogramas de 30 a 50 ms y 0,4 s parados en total tras caer la botella; en la web,
  con muchos zombis, puede ser peor. Mirar con `--lentos`, sobre todo la web (`docs/WEB.md`).
- **F18** Tutorial: cuando matan a Johnny por primera vez se vuelve a explicar el tutorial, y no debería (le pasó a un
  jugador nuevo probando la web).

## Mejoras

- **M27** Mutación Gastroenteritis: los zombis alcanzados quedan bañados en vómito un par de segundos, con un efecto en
  todo el cuerpo como el del ácido.
- **M28** Johnny ardiendo: que se vea con el mismo efecto de fuego que los zombis, que queda mejor.
- **M29** Mutación del tentáculo (Tentacular): un efecto visual mejor, por ejemplo que se vea el tentáculo alrededor de
  Johnny, o lo que se le ocurra a Claude.
- **M30** Tropiezo de Johnny en las salas de la portera y del gymbro: ahora la caída es una imagen fija ladeada; que
  quede más natural, cambiando de postura y quedándose tumbado en el suelo, o con la animación de morir si la tiene.
- **M31** Cuando la vida de Johnny llega a cero: que no sea solo la frase «Te han pillado», sino algo que explique que
  vuelve a la sala de mantenimiento y se levanta allí diciendo «vaya, me he quedado dormido» o «vaya pesadilla». Ideas:
  - Sonámbulo (la del dueño): se desmaya por los mordiscos y vuelve solo, andando como un autómata.
  - Medio zombi: la infección lo lleva arrastrando los pies entre los zombis, que no le hacen caso porque lo huelen como uno más.
  - Rescatado: un superviviente lo saca a rastras y lo deja en mantenimiento.
  - Cámara de seguridad: el regreso se ve en blanco y negro por las cámaras del edificio y acaba en el monitor del ordenador.
  - Pesadilla: fundido a negro y se despierta de golpe; cada intento es otro sueño, lo que explicaría que el edificio vuelva a estar lleno.
- **M32** Talentos: una opción para resetearlos.
- **M33** Modo de disparo asistido: mientras se juega, que se oculte el ratón porque molesta para ver; que vuelva a
  aparecer al abrir un menú y se oculte otra vez al cerrarlo.
- **M34** Cambiar la flecha del ratón por una mirilla mientras se está en el juego.
- **M35** Tutorial: explicar el sistema de vida de Johnny por tercios y lo que le pasa cuando baja.

## Por limar

- **L18** Jefe de bomberos: la lengua de llamas da un tirón al empezar y se queda parada un momento, y se nota.
- **L19** Ordenador, tienda de armas: en el texto de arriba hay algo entre paréntesis que no se entiende bien (puede
  ser «(al completar el edificio, va solo)», lo de guardar lo que llevas en el baúl). Reescribirlo más claro, en los
  siete idiomas.
- **L20** Sala de mantenimiento: no debe haber sangre en ninguna de sus habitaciones (taquilla, despacho, taller).
- **L21** El número de cada planta se ve demasiado perfecto comparado con lo destrozado que está el edificio; que se vea
  desgastado, sucio o roto.
- **L22** Barra de vida de Johnny: el número de la vida tapa los tercios; mirar cómo dejarlos a la vista.
- **L23** Puertas: que se vean más sucias, con sangre y arañazos.
- **L24** Textos del juego: muchas tildes salen al revés.
- **L25** Jefe de bomberos: la lengua de fuego no pega con la estética del juego.
- **L26** El campo de invulnerabilidad (el del jefe de bomberos, parece) no pega con la estética del juego.
