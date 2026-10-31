# Pendientes · fallos, mejoras y cosas por limar

Lista del dueño. Él dicta los puntos y Claude solo los apunta aquí.

- **No se trabaja en ningún punto hasta que el dueño lo pida** ("haz el F2", "el de la puerta del baño").
- Cuando un punto está hecho y tiene el visto bueno, **se borra de la lista** (no se tacha) en el mismo commit.
- Cada punto lleva un código fijo (`F` fallo, `M` mejora, `L` por limar) y un número que **no se vuelve a usar**
  aunque el punto se borre, para que "haz el F2" siempre señale al mismo.
- Una línea por punto, con lo justo para reconocerlo: dónde pasa y cómo se ve. Si hace falta más detalle, se
  pone debajo con sangría.

## Fallos

- **F15** A veces los zombis se quedan atascados en una puerta al intentar salir todos a la vez.
- **F16** Pantalla completa: al pulsar Esc (para la pausa) también se sale de la pantalla completa, y no debería. En la
  web es el propio navegador; mirar si se puede evitar (por ejemplo con el bloqueo de teclado de Chrome).

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
- **M36** Skin de Johnny del doctor Salas (cuando se cree): su efecto es que los zombis tengan un 50 % de probabilidad
  de dar dos objetos aleatorios en lugar de uno.
- **M37** Mutación Flatulento: poner algo que haga que se vea el efecto.
- **M38** Zombi gordo de ácido: al morir, que deje un charco grande de ácido que actúe como el que suelta en vida.
- **M39** Baúl: que también se pueda dejar la pistola (hoy la pistola Normal no se puede guardar a mano).
- **M40** Rescate del superviviente: que dure un minuto, pero con muchos más zombis y en menos tiempo.
- **M41** Jefe doctor Salas: es demasiado fácil; aumentar la dificultad de algún modo.
- **M42** Bajar el número de granadas y cócteles molotov: con diez lanzables se mata a los jefes muy fácil.
- **M43** Supervivientes: que los zombis también oigan sus disparos, como pasa con los de Johnny.
- **M44** Controles en pantalla: cuando se juega con mando, que los dibujos de los controles sean los del mando (botones
  y gatillos) y no las letras del teclado.
- **M45** Menú de inicio: tres huecos de guardado, para que el jugador pueda empezar el juego de cero si quiere.
- **M46** Menú principal: falta el botón de salir del juego. Hoy está en el `.exe` pero se oculta en la web
  (`scripts/ui/menu_principal.gd`, porque el navegador no deja cerrar la pestaña): decidir qué hace allí.
- **M47** Web: el juego tarda mucho en cargar. Se descarga el motor de Godot (unos 10 MB comprimido) y todo el juego
  de golpe (unos 30 MB: 28 de dibujos y 2,4 de música) antes de empezar. Ideas: hacer más pequeñas las hojas de
  dibujos más grandes (jefe criatura, gerente mutado…), cargar cada jefe solo cuando sale y una pantalla de carga
  más bonita para que la espera se note menos.

## Por limar

- **L21** El número de cada planta se ve demasiado perfecto comparado con lo destrozado que está el edificio; que se vea
  desgastado, sucio o roto.
- **L23** Puertas: que se vean más sucias, con sangre y arañazos.
- **L27** Pasillo de los apartamentos: cambiar las puertas de la pared de abajo para que encajen más con el diseño del
  juego.
- **L28** Pasillo de los apartamentos, pared de abajo: las placas con la letra del piso, en vez de estar en el tabique,
  tiradas por el suelo cerca de la puerta, como si las hubiesen arrancado.
- **L30** Gymbro: cambiar su aura por hacer que su cuerpo se vuelva de metal, que queda mejor visualmente.
