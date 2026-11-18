# Los tutoriales: la ventana que sale la primera vez que Johnny se encuentra algo nuevo (cómo se juega, los lanzables,
# el primer jefe...) y explica qué pasa y cómo se hace. Cada uno sale una sola vez (Guardado: "tutoriales", los vistos)
# y se puede volver a ver en el apartado Tutorial del menú principal y de la pausa (ui/tutorial.gd), donde los que aún
# no han salido están con «???» (menos «Cómo se juega» y «Moverse y esquivar», que se pueden leer antes de jugar). Se apagan en
# Opciones → Ayudas (ajuste "tutoriales"), que también tiene un botón para que vuelvan a salir todos.
#
# Cada ficha: grupo (su apartado en la lista), titulo, icono (assets/ui/iconos), cuando (cuándo sale, para la lista y
# para no perderse) y lineas, lo que se explica. Sin fotos (se quitaron el 8 nov). En las líneas, las teclas van entre llaves ({esquivar}, con el nombre de la
# acción de project.godot): salen las del jugador (las cambiadas en Opciones también), los botones del mando si hay uno
# enchufado o, en el móvil, los de la pantalla (tecla()). {moverse}, {apuntar} y {atacar_modo} son de aquí.
#
# Quién los llama: partida.gd (tutorial(id), y la mayoría en mirar_tutoriales), eventos.gd, supervivientes.gd y
# menu_principal.gd (el de la mejora del compuesto VD-7 y el reto del día).
#
# Idiomas: los textos de las tablas están en español, entre # [traducir] y # [/traducir], y salen ya traducidos por
# nombre_grupo(), titulo_de(), cuando_de() y texto() (que traduce cada línea ANTES de poner las teclas): la
# traducción conserva los {nombres} tal cual. Quien los enseñe no tiene que traducirlos otra vez.
class_name Tutoriales

const GRUPOS := ["Lo básico", "Armas", "Plantas y jefes", "Supervivientes", "Eventos sorpresa", "Sala de mantenimiento", "Más edificios"]  # [traducir]

# [traducir]
const LISTA := {
	# (16 nov, revisión de todos: frases cortas, y todo lo que hay que saber va en estas ventanas, con «Entendido»; los
	# avisos blancos de abajo, partida.decir, ya no se ven)
	# (17 nov, lo pidió el dueño: «Moverse y esquivar», la de la primera partida, que repetía sus frases, se ha unido a
	# esta. Sale al empezar todas las partidas hasta verse; en la primera, la de la guía, sin la línea de atacar, que la
	# cuenta «Atacar» en la primera pelea: texto(id, sin_atacar) y partida.ver_tutorial)
	"jugar": {"grupo": "Lo básico", "titulo": "Cómo se juega", "icono": "skin-conserje", "cuando": "Al empezar la primera partida",
		"lineas": ["Muévete con {moverse} y esquiva con {esquivar}: mientras esquivas, no te hacen daño.",
			"{atacar_modo}",
			"Abre y cierra muebles y puertas con {usar}, cuando estés delante y se marquen en amarillo.",
			"Pausa el juego con {pausa}."]},   # (cambiar de arma ya no va aquí: en «Cambiar de arma», al coger la pistola, M97)
	# (solo en la primera partida, la de la guía, en la primera pelea: guia.gd; en las demás lo cuenta «Cómo se juega»,
	# que al verse lo apunta también: partida.ver_tutorial)
	"atacar": {"grupo": "Lo básico", "titulo": "Atacar", "icono": "fregona", "cuando": "En la primera pelea",
		"lineas": ["{atacar_modo}"]},
	# (también en la primera partida, al salir al pasillo: guia.al_montar; 16 nov, antes la tapaba un aviso de abajo)
	"apartamentos": {"grupo": "Lo básico", "titulo": "Limpia los apartamentos", "icono": "puerta",
		"cuando": "Al salir al pasillo",
		"lineas": ["Al entrar en un apartamento, la puerta se cierra hasta que no quede ni un durmiente.",
			"La sala del jefe está cerrada con llave: la lleva un durmiente de algún apartamento. Al caer la suelta: pasa por encima para cogerla.",
			"Vence al jefe y se abren las escaleras a la planta siguiente."]},
	"tercios": {"grupo": "Lo básico", "titulo": "La vida en tercios", "icono": "corazon",
		"cuando": "Al perder un tercio de vida",
		"lineas": ["Tu vida va en tres tercios. El que pierdes se oscurece y las vendas ya no lo llenan.",
			"Por cada tercio perdido andas más lento, y no se recupera al subir de planta.",
			"Solo el botiquín te devuelve uno (y la mutación Segundo aliento, una vez por planta).",
			"¿Se te hace cuesta arriba? En Opciones → Ayudas está «Vida entera»."]},
	# (uno solo para las dos curas, M110: sale al abrir el primer armarito, partida.abrir_armarito, o al coger la primera
	# cura de otra parte, mirar_tutoriales. Antes el botiquín tenía el suyo, "botiquin": en los guardados viejos sigue entre
	# los vistos y no molesta, porque solo se miran los de esta lista)
	"curas": {"grupo": "Lo básico", "titulo": "Vendas y botiquines", "icono": "botiquin",
		"cuando": "Al abrir el primer armarito o coger la primera cura",
		"lineas": ["Abre los armaritos de los baños con {usar}: dan unas vendas o un botiquín.",
			"Vendas, con {usar_vendas}: curan 25, sin pasar del tercio en el que estás.",
			"Botiquín, con {usar_botiquin}: cura 40 y te devuelve un tercio perdido. Guárdalo para entonces.",
			"Llevas como mucho 3 vendas y 2 botiquines."]},
	# (16 nov: con lo primero que entra en la mochila, sea lo que sea, detrás de su ventana: mirar_tutoriales. Antes solo
	# con objetos que no eran curas ni materiales, y los durmientes ya no sueltan objetos)
	"inventario": {"grupo": "Lo básico", "titulo": "Inventario y mochila", "icono": "mochila",
		"cuando": "Al coger el primer objeto",
		"lineas": ["Abre el inventario con {inventario}: tus armas, la munición, los lanzables y la mochila.",
			"Elige una casilla para ver qué es y qué puedes hacer con ella.",
			"Si caes o abandonas, pierdes lo de la mochila; si completas el edificio, pasa al baúl."]},
	"dolares": {"grupo": "Lo básico", "titulo": "Dólares", "icono": "billete", "cuando": "Al coger el primer billete",
		"lineas": ["Los durmientes sueltan billetes al caer, y los jefes, muchos: pasa por encima para cogerlos.",
			"Si completas el edificio te los quedas todos; si caes o abandonas, los pierdes.",
			"Se gastan en la tienda de armas del ordenador de la sala de mantenimiento."]},
	# (15 nov: el mutágeno, que paga las mutaciones; sale como el de los dólares, desde partida.mirar_tutoriales)
	"mutageno": {"grupo": "Lo básico", "titulo": "Mutágeno", "icono": "mutageno", "cuando": "Al coger el primer mutágeno",
		"lineas": ["Al caer, los durmientes sueltan mutágeno: pasa por encima para cogerlo.",
			"Solo te lo quedas si completas el edificio: si caes o abandonas, pierdes el de esa partida.",
			"Se gasta en Mutaciones, en el ordenador: mejoras para Johnny que duran para siempre."]},
	# (sale al llevar la primera arma a distancia, sacada del baúl o cogida del suelo: partida.mirar_tutoriales; M97.
	# Hasta el 15 nov salía en la tienda, al coger la pistola de regalo, que ahora va al baúl)
	"cambiar_arma": {"grupo": "Armas", "titulo": "Cambiar de arma", "icono": "pistola",
		"cuando": "Al llevar la primera arma a distancia",
		"lineas": ["Ahora llevas dos armas en la mano: una de cuerpo a cuerpo, como la fregona, y otra a distancia, como la pistola.",
			"Cambia de una a otra con {cambiar_arma}."]},
	"armas": {"grupo": "Armas", "titulo": "Armas nuevas", "icono": "escopeta", "cuando": "Al llevar otra arma",
		"lineas": ["Llevas dos armas en la mano (cuerpo a cuerpo y a distancia: cambias con {cambiar_arma}) y una de repuesto de cada tipo.",
			"Las de repuesto se cambian en el inventario ({inventario}).",
			"El color del borde es su calidad: gris Normal, verde Poco común, azul Rara y morado Épica. Cuanto mejor, más partidas dura."]},
	"municion": {"grupo": "Armas", "titulo": "Munición y recarga", "icono": "municion", "cuando": "Al recargar",
		"lineas": ["Recarga con {recargar}; al vaciarse el cargador, recarga solo.",
			"Cada arma gasta su munición. Una caja de munición del suelo te da un cargador.",
			"Sin munición, Johnny saca el arma de cuerpo a cuerpo.",
			"¡Ojo! Disparar dentro de un apartamento despierta a todos los durmientes."]},
	# (15 nov: sale con el primer lanzable, comprado o regalado en la tienda, que va al baúl, o sacado del baúl:
	# ui/ordenador.gd, comprar_lanzable, y partida.mirar_tutoriales. Antes, en la primera pelea)
	"lanzables": {"grupo": "Armas", "titulo": "Lanzables", "icono": "molotov", "cuando": "Al conseguir el primer lanzable",
		"lineas": ["Se compran en la tienda de armas del ordenador y van al baúl: sácalos de allí para llevarlos.",
			"Mantén {lanzar} para apuntar y suelta para lanzar. Cambia de lanzable con {cambiar_lanzable}.",
			"Molotov: fuego. Granada: explota. Atraedora: llama a los durmientes y explota. Congeladora: los congela.",
			"¡Ojo! El fuego y las explosiones también te hacen daño a ti."]},
	# (16 nov, M123: al salir de la sala de mantenimiento sin ningún lanzable encima; partida.cruzar)
	"lanzables_siempre": {"grupo": "Armas", "titulo": "Lleva lanzables", "icono": "molotov", "cuando": "Al salir sin lanzables",
		"lineas": ["No llevas ningún lanzable. Sácalos del baúl o cómpralos en la tienda de armas del ordenador.",
			"Llévalos siempre: algunas hordas son imposibles sin un molotov o una granada."]},
	"piezas": {"grupo": "Armas", "titulo": "Materiales de fabricación", "icono": "obj-pieza_cuerpo",
		"cuando": "Al coger el primer material",
		"lineas": ["Sirven para mejorar armas y lanzables en el banco de trabajo de la sala de mantenimiento.",
			"Están en armarios, mesillas, escritorios, cajas registradoras, archivadores... Ponte delante y ábrelos con {usar}. No todos tienen.",
			"Van en la mochila: si completas el edificio, pasan al baúl; si caes, se pierden."]},
	"jefes": {"grupo": "Plantas y jefes", "titulo": "Jefes", "icono": "jefe", "cuando": "Al llegar al primer jefe",
		"lineas": ["Cada planta tiene su jefe. A media vida se enfada y se vuelve más peligroso.",
			"Avisa antes de atacar, casi siempre con una marca en el suelo: ¡sal de ella o esquiva con {esquivar}!",
			"Algunos tienen cerca cosas para usar contra ellos con {usar}, como los bidones.",
			"Al caer suelta muchos dólares y se abren las escaleras."]},
	"mutaciones": {"grupo": "Plantas y jefes", "titulo": "Efectos secundarios", "icono": "zombi",
		"cuando": "Antes del primer efecto secundario",
		"lineas": ["Al vencer a un jefe, el virus te cambia: elige una de las dos cartas.",
			"Cada una te da un poder hasta que acaba la partida. Llevas como mucho 4."]},
	"ascensor": {"grupo": "Plantas y jefes", "titulo": "El ascensor", "icono": "herramientas",
		"cuando": "Al arreglar el ascensor",
		"lineas": ["Al vencer al jefe, Johnny arregla el ascensor del pasillo: baja a la sala de mantenimiento y te devuelve a esta planta.",
			"Úsalo para comprar, mejorar o sacar cosas del baúl a mitad de partida.",
			"En cada planta nueva vuelve a estar averiado hasta que cae su jefe."]},
	# (16 nov, M123: al coger la primera caja de munición, partida.soltar_municion; antes, detrás de «Jefes», en la primera pelea)
	"balas_jefes": {"grupo": "Plantas y jefes", "titulo": "Guarda las balas", "icono": "pistola", "cuando": "Al coger el primer cargador",
		"lineas": ["Los jefes aguantan muchísimo: cuerpo a cuerpo es muy difícil vencerlos.",
			"Guarda las balas de tus armas a distancia para ellos y limpia los apartamentos con la fregona o tu arma cuerpo a cuerpo."]},
	# (16 nov, M123: la primera vez que sale al pasillo de la planta baja con la llave del jefe; partida.cruzar)
	"antes_jefe": {"grupo": "Plantas y jefes", "titulo": "Antes del jefe", "icono": "herramientas",
		"cuando": "Al salir con la llave del jefe",
		"lineas": ["Ya puedes abrir la puerta del jefe. Antes de la pelea, pasa por la sala de mantenimiento: está aquí, en la planta baja.",
			"En el ordenador, gasta los dólares en la tienda de armas y el mutágeno en Mutaciones: si caes, se pierden.",
			"Deja a salvo en el baúl lo que no quieras perder."]},
	# (16 nov: el jefe final, que espera en el helipuerto de la azotea; partida.gd, al montar su sala)
	"azotea": {"grupo": "Plantas y jefes", "titulo": "La azotea", "icono": "jefe", "cuando": "Al llegar a la azotea",
		"lineas": ["El último jefe del edificio te espera en el helipuerto: entra en las líneas blancas para empezar la pelea.",
			"Al vencerlo llega un helicóptero: arrímate a su escalera para escapar."]},
	# Los supervivientes (16 nov): el de siempre, al llegar al pasillo de la planta en la que hay uno encerrado
	# (supervivientes.al_montar), y el de cada rescate, al entrar donde está él (rescate_<su "rescate">; los de los
	# Apartamentos, "rescate_horda"). Hasta entonces, lo que había que hacer lo decían los avisos de abajo
	"supervivientes": {"grupo": "Supervivientes", "titulo": "Supervivientes", "icono": "medico",
		"cuando": "Al oír al primero pedir socorro",
		"lineas": ["Si en la planta hay un superviviente encerrado, se le oye pedir socorro y sale un «!» en el minimapa.",
			"Ve a por él y protégelo mientras hace lo suyo para salir. Si cae, quédate a su lado para levantarlo.",
			"Si completas el edificio con él, se muda a los trasteros y podrá acompañarte."]},
	"rescate_horda": {"grupo": "Supervivientes", "titulo": "Rescate en los apartamentos", "icono": "medico",
		"cuando": "Al encontrar al primero de los apartamentos",
		"lineas": ["Al salir del piso con él, la puerta se cierra de golpe: se pone a forzar la cerradura y entran durmientes por las habitaciones.",
			"Quédate cerca y protégelo. Si lo tumban, la cerradura no avanza: ponte a su lado para levantarlo."]},
	"rescate_barricada": {"grupo": "Supervivientes", "titulo": "El ferretero", "icono": "medico",
		"cuando": "Al encontrar al ferretero",
		"lineas": ["Se ha atrincherado en el almacén: al limpiar la tienda, se pone a quitar las tablas y entran durmientes.",
			"Defiende su puerta: mientras haya un durmiente pegado a ella, no avanza."]},
	"rescate_escolta": {"grupo": "Supervivientes", "titulo": "La farmacéutica", "icono": "medico",
		"cuando": "Al encontrar a la farmacéutica",
		"lineas": ["Está herida y va cojeando: llévala hasta la puerta de las escaleras de la planta.",
			"Por el camino salen durmientes. No te alejes de ella: si se queda sola, van a por ella."]},
	"rescate_averia": {"grupo": "Supervivientes", "titulo": "El técnico", "icono": "medico",
		"cuando": "Al encontrar al técnico",
		"lineas": ["No se va sin arreglar el cable pelado, pero con corriente no puede: ponte delante del cuadro eléctrico de la tienda y baja la palanca con {usar}.",
			"Se queda todo a oscuras y entran durmientes: protégelo hasta que acabe."]},
	"rescate_copia": {"grupo": "Supervivientes", "titulo": "El informático joven", "icono": "medico",
		"cuando": "Al encontrar al informático joven",
		"lineas": ["No se va sin copiar los archivos de Velaria: la puerta se cierra y entran durmientes. Protégelo hasta que acabe.",
			"Mientras copia, saltan las cámaras de la sala: rómpelas antes de un tiro y te ahorras escoltas."]},
	"rescate_valvulas": {"grupo": "Supervivientes", "titulo": "La limpiadora de noche", "icono": "medico",
		"cuando": "Al encontrar a la limpiadora de noche",
		"lineas": ["Está encerrada en el cuarto de la limpieza, lleno de gas. Para abrirlo, cierra las tres válvulas del departamento: ponte delante de cada una.",
			"Cada válvula silba al cerrarse y despierta frenéticos a los durmientes de cerca."]},
	"rescate_tornos": {"grupo": "Supervivientes", "titulo": "La recepcionista", "icono": "medico",
		"cuando": "Al encontrar a la recepcionista",
		"lineas": ["Quiere abrir los tornos de la entrada con su tarjeta: mientras tanto, entran durmientes por las puertas del vestíbulo.",
			"Protégela hasta que acabe. Si la tumban, ponte a su lado para levantarla."]},
	"apagon": {"grupo": "Eventos sorpresa", "titulo": "Apagón", "icono": "alerta", "cuando": "En el primer apagón",
		"lineas": ["Se ha ido la luz en toda la planta: solo ves lo que alumbra tu linterna, hacia donde miras.",
			"En la sala del jefe todo sigue como siempre.",
			"Al subir a la planta siguiente, te llevas un premio en dólares y munición."]},
	"incendio": {"grupo": "Eventos sorpresa", "titulo": "Alarma de incendios", "icono": "alerta",
		"cuando": "En la primera alarma de incendios",
		"lineas": ["Los aspersores llenan el suelo de charcos que resbalan.",
			"En algunos cae un cable pelado que da calambrazos a ti y a los durmientes: ¡llévalos hasta él! Esquivando lo cruzas sin daño.",
			"Al subir a la planta siguiente, te llevas un premio en dólares y munición."]},
	"horda": {"grupo": "Eventos sorpresa", "titulo": "Horda", "icono": "alerta", "cuando": "En la primera horda",
		"lineas": ["Una horda enorme llena el pasillo y va a por ti.",
			"Si te metes en un piso, los que queden te esperan fuera. Aquí los lanzables vienen de perlas.",
			"Al acabar con todos, te deja dólares y munición."]},
	"ordenador": {"grupo": "Sala de mantenimiento", "titulo": "El ordenador", "icono": "dosier",
		"cuando": "Al encender el ordenador",
		"lineas": ["Gasta el mutágeno en Mutaciones (mejoras para siempre) y los dólares en la Tienda de armas.",
			"También están los Logros, que dan premio, el Dosier, los Vídeos y Sujetos."]},
	"taquilla": {"grupo": "Sala de mantenimiento", "titulo": "La taquilla", "icono": "skin-portero",
		"cuando": "Al abrir la taquilla",
		"lineas": ["Aquí eliges la ropa de Johnny. Cada traje nuevo tiene su ventaja.",
			"Se consiguen venciendo a cada jefe por primera vez: los que te faltan salen con «???»."]},
	"banco": {"grupo": "Sala de mantenimiento", "titulo": "El banco de trabajo", "icono": "herramientas",
		"cuando": "Al usar el banco de trabajo",
		"lineas": ["Mejora tus armas y lanzables con los materiales de su familia (los de la mochila y los del baúl).",
			"Normal, Poco común, Rara y Épica: cada mejora dura una partida más, y la Épica trae un truco.",
			"Elige la casilla y pulsa «Mejorar»."]},
	"baul": {"grupo": "Sala de mantenimiento", "titulo": "El baúl", "icono": "mochila", "cuando": "Al abrir el baúl",
		"lineas": ["En el baúl guardas armas, lanzables y objetos para otras partidas. La munición no: al acabar la partida se pierde toda, también la del baúl.",
			"Al sacar un arma o un lanzable del baúl, su durabilidad baja 1. Con 0, es su última partida: se destruye al acabarla.",
			"Al acabar la partida, lo que aún dura vuelve solo al baúl. Elige una casilla o arrástrala para pasarla."]},
	"tienda": {"grupo": "Sala de mantenimiento", "titulo": "La tienda de armas", "icono": "pistola",
		"cuando": "Al abrir la tienda de armas",
		"lineas": ["Lo que compras va al baúl: sácalo de allí para llevarlo. Si el baúl está lleno, haz sitio antes.",
			"Todo es Normal: dura solo la partida en la que lo sacas. Las armas a distancia traen munición.",
			"Johnny empieza solo con la fregona: la primera pistola es un regalo, y también un molotov, una granada y una atraedora."]},
	# Los de los programas del ordenador: salen al abrir cada uno la primera vez (ordenador.gd, TUTORIAL_DE) y, hasta
	# entonces, su icono lleva un «!» (mapa/ordenador.gd, novedades)
	"talentos": {"grupo": "Sala de mantenimiento", "titulo": "Mutaciones", "icono": "escritorio-talentos",
		"cuando": "Al abrir Mutaciones",
		"lineas": ["Gasta el mutágeno en mejoras para siempre, en tres ramas: Militar, Superviviente y Químico.",
			"Para abrir una mutación hay que llenar antes la que tiene encima.",
			"«Resetear mutaciones» las quita para repartirlas otra vez, pero el mutágeno gastado se pierde."]},
	"logros": {"grupo": "Sala de mantenimiento", "titulo": "Logros", "icono": "escritorio-logros",
		"cuando": "Al abrir Logros",
		"lineas": ["Aquí están los retos del juego. Al conseguir uno, vuelve aquí a cobrar su premio en dólares.",
			"Si el premio no cabe en el máximo de dólares (MAX), lo que sobra se pierde.",
			"Con una Ayuda encendida, esa partida no da logros."]},
	"dosier": {"grupo": "Sala de mantenimiento", "titulo": "Dosier VD-7", "icono": "escritorio-dosier",
		"cuando": "Al abrir el Dosier",
		"lineas": ["Mientras te falten páginas, en alguna planta hay un muerto con una. Cógela y se queda aquí para siempre.",
			"Completar el dosier es una de las tres cosas que pide el edificio siguiente para abrirse."]},
	# (el programa Sujetos: hasta el 16 nov la ficha se llamaba «Colecciones»; el id sigue igual, por los guardados)
	"colecciones": {"grupo": "Sala de mantenimiento", "titulo": "Sujetos", "icono": "escritorio-colecciones",
		"cuando": "Al abrir Sujetos",
		"lineas": ["Aquí se apuntan los durmientes y los jefes que te encuentras, con lo que hacen y dónde salen. Los que faltan, con «???»."]},
	"videos": {"grupo": "Sala de mantenimiento", "titulo": "Vídeos", "icono": "escritorio-videos",
		"cuando": "Al abrir Vídeos",
		"lineas": ["Al coger la página del dosier de una planta, en algún apartamento se enciende una tele con las noticias de Canal 8: ponte delante y pulsa {usar}.",
			"Si la ves entera, se guarda aquí. Ver todos los de un edificio también cuenta para abrir el siguiente."]},
	"trasteros": {"grupo": "Sala de mantenimiento", "titulo": "Los trasteros", "icono": "medico",
		"cuando": "Al entrar en los trasteros",
		# (17 nov, lo pidió el dueño: cómo ayudan sin venir, las «mejora» de Supervivientes.DATOS; que viene uno a la vez, y
		# en líneas más cortas)
		"lineas": ["Aquí viven los supervivientes que rescatas, cada uno en su trastero.",
			"Algunos te ayudan aunque no vengan contigo, cada uno a su manera: un botiquín al empezar, los durmientes en el minimapa, la tienda más barata, una fregona que barre más ancho y pistas de la sala del jefe.",
			"Ponte delante de uno y pulsa {usar}: te contará su vida y cuál es su comida favorita.",
			"Si le das de comer, te acompañará una partida y luego volverá a su trastero. Solo viene uno a la vez."]},
	# (17 nov, lo pidió el dueño: si no, no se sabe que las cocinas se han abierto; partida.gd, al limpiar un piso)
	"cocinas": {"grupo": "Supervivientes", "titulo": "Las cocinas", "icono": "obj-donut",
		"cuando": "Al limpiar un piso con alguien en los trasteros",
		"lineas": ["Ya vive alguien en los trasteros: desde ahora, las neveras y las encimeras de las cocinas se pueden abrir con {usar}.",
			"A veces guardan la comida favorita de un superviviente. Llévasela a su trastero y te acompañará."]},
	# (16 nov, M124: la comida favorita de cada superviviente; sale al abrir la primera nevera o encimera que la tiene)
	"comida": {"grupo": "Supervivientes", "titulo": "Comida favorita", "icono": "obj-donut",
		"cuando": "Al encontrar la primera comida",
		"lineas": ["Las neveras y las encimeras de las cocinas guardan a veces la comida favorita de alguno de los supervivientes de los trasteros.",
			"Si completas el edificio, pasa al baúl. En su trastero, pulsa {usar} delante de él y dale de comer: te acompañará una partida."]},
	"centro": {"grupo": "Más edificios", "titulo": "El centro comercial", "icono": "centro",
		"cuando": "Al llegar al centro comercial",
		"lineas": ["Todas las puertas de la planta están cerradas: la llave maestra la lleva el guardia de seguridad que hace la ronda.",
			"Si te ve, ruge y llama a sus guardias: vienen todos a por ti. Acaba con él y su llave es tuya."]},
	"peligros": {"grupo": "Más edificios", "titulo": "Peligros de las tiendas", "icono": "alerta",
		"cuando": "En la primera tienda con peligro",
		"lineas": ["La cámara frigorífica te frena y te hiela, la cocina quema y el agua de Electrónica da calambres (su cuadro eléctrico la apaga).",
			"También dañan a los durmientes: ¡llévalos hasta ellos! Esquivando los cruzas sin daño."]},
	"dependienta": {"grupo": "Más edificios", "titulo": "La dependienta", "icono": "alerta",
		"cuando": "Al oír su primer grito",
		"lineas": ["Su grito despierta a toda la tienda y pone furiosos a todos los durmientes, a ella también: arden en rojo, andan y atacan más rápido y aguantan más.",
			"La furia no se va hasta que cae ella: ve primero a por la dependienta, que es flojita, o cárgate a todos furiosos."]},
	# (16 nov: la cámara acorazada de la joyería, al entrar en ella la primera vez: joyeria.al_montar)
	"joyeria": {"grupo": "Más edificios", "titulo": "La joyería", "icono": "centro", "cuando": "Al entrar en la joyería",
		"lineas": ["La cámara acorazada guarda un arma Épica. Se abre con la llave dorada que lleva el guardia de seguridad.",
			"Sin la llave, ponte delante de la puerta dos veces: salta la alarma y tienes que aguantar dentro de la joyería hasta que se abra."]},
	"torre": {"grupo": "Más edificios", "titulo": "Torre Velaria", "icono": "torre",
		"cuando": "Al llegar a Torre Velaria",
		"lineas": ["La sala del jefe se abre con un código de tres cifras. Cada cifra está en un ordenador encendido (brilla en verde) de algún departamento.",
			"Ponte delante para leerla, pero salta el «control de productividad» y se despiertan los durmientes."]},
	"peligros_torre": {"grupo": "Más edificios", "titulo": "Peligros de la torre", "icono": "alerta",
		"cuando": "En el primer departamento con peligro",
		"lineas": ["Los ventanales rotos te arrastran hacia fuera: crúzalos pegado a las mesas. Los durmientes que llegan al borde salen volando.",
			"Si una cámara te ve, salta la alarma y llegan escoltas: rómpela de un tiro antes.",
			"El gas duerme a los durmientes, pero despiertan frenéticos. A ti no te hace nada; una válvula lo corta."]},
	# (16 nov, M121: la alerta pasa a ser la mejora del compuesto VD-7, sin premios)
	"alerta": {"grupo": "Más edificios", "titulo": "Compuesto VD-7 y Reto del día", "icono": "trofeo",
		"cuando": "Al completar el primer edificio",
		"lineas": ["Debajo de cada edificio completado eliges la mejora del compuesto VD-7 con < y >: cada nivel, los enemigos tienen un 20 % más de vida, daño, velocidad y ataque.",
			"No da premios: es para quien busque más reto. Cada mejora se abre al completar ese edificio con la anterior.",
			"El Reto del día es un garaje con 25 oleadas de durmientes y una condición distinta cada día. Se juega una vez al día en cada edificio."]},
	# (16 nov, M125: el reto del día pasa a ser el garaje; sale al entrar en él, partida.empezar_garaje)
	"garaje": {"grupo": "Más edificios", "titulo": "El garaje del reto del día", "icono": "trofeo",
		"cuando": "Al entrar en el garaje",
		"lineas": ["Aguanta 25 oleadas de durmientes, cada una más dura que la anterior. Cada 5 oleadas llega también un jefe del edificio.",
			"En el centro está el baúl, con lo que tengas guardado: si te quedas sin nada, ve a por más.",
			"Cada oleada superada da tantos dólares como su número: la 5, $5. Te los llevas siempre, ganes, caigas o abandones.",
			"Cada día hay una condición, la misma para todos: algo que no vale, ni sacarlo del baúl ni usarlo. Sale arriba del todo.",
			"Se juega una vez al día en cada edificio, y se guarda tu récord de oleadas con cada condición."]},
}
# [/traducir]

# En el móvil, con qué se hace cada acción (ui/tactil.gd; desde el M114, la mochila, la pausa y las curas, arriba a la derecha)
# [traducir]
const TACTIL := {
	"esquivar": "el botón de esquivar", "cambiar_arma": "el botón de la otra arma",
	"recargar": "el botón del arma a distancia, con ella en la mano", "lanzar": "el botón de lanzar",
	"cambiar_lanzable": "el botoncito de al lado de lanzar", "usar_vendas": "el botón de las vendas, arriba a la derecha",
	"usar_botiquin": "el botón del botiquín, arriba a la derecha", "inventario": "el botón de la mochila, arriba a la derecha",
	"pausa": "el botón de pausa, arriba a la derecha", "usar": "el botón «Abrir», que sale encima de los botones",
}
# [/traducir]

static var vistos: Array = []   # los ya vistos: copia de Guardado "tutoriales", que se mira a menudo (mirar_tutoriales)
static var vistos_de := ""      # de qué archivo son (la prueba con --captura usa otro)
# Los «!» de la sala de mantenimiento (mapa.gd, mapa/ordenador.gd) encima de lo que tiene un tutorial sin ver: la taquilla,
# el ordenador, el banco, el baúl y la puerta de los trasteros. En la partida de prueba no salen (partida.gd lo apaga),
# salvo en la suya (--marcas-sala), para que no cambien las fotos de las demás
static var marcas := true


static func visto(id: String) -> bool:
	if vistos_de != Guardado.archivo:
		vistos = Guardado.cargar().tutoriales.duplicate()
		vistos_de = Guardado.archivo
	return id in vistos


# Si hay que enseñarlo ahora: aún no se ha visto y los tutoriales están encendidos (Opciones → Ayudas)
static func toca(id: String) -> bool:
	return Guardado.ajuste("tutoriales") and not visto(id)


# Si va el «!» encima del mueble que enseña este tutorial (ver "marcas")
static func marca(id: String) -> bool:
	return marcas and toca(id)


static func apuntar(id: String) -> void:
	if visto(id):
		return
	vistos.append(id)
	Guardado.cambiar(func(s): if not id in s.tutoriales: s.tutoriales.append(id))
	# los «!» de encima de los muebles (exclamacion.gd), mirados ya: el de este se quita al momento
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol:
		arbol.call_group("exclamaciones", "refrescar")


# Que vuelvan a salir todos (el botón de abajo de la lista de Tutorial), también la guía de la primera partida (guia.gd)
static func olvidar() -> void:
	vistos = []
	vistos_de = Guardado.archivo
	Guardado.cambiar(func(s):
		s.tutoriales = []
		s.guia_otra_vez = true)


# Si sale en la lista del apartado Tutorial (los demás, con «???»)
static func se_ve(id: String) -> bool:
	return id == "jugar" or visto(id)


# El nombre de un grupo (de GRUPOS), ya traducido
static func nombre_grupo(grupo: String) -> String:
	return Idioma.t(grupo)


# El título de un tutorial, ya traducido
static func titulo_de(id: String) -> String:
	return Idioma.t(LISTA[id].titulo)


# Cuándo sale un tutorial, ya traducido (hoy no lo enseña ninguna pantalla)
static func cuando_de(id: String) -> String:
	return Idioma.t(LISTA[id].cuando)


# Las líneas de la ficha, cada una con su punto y las teclas en amarillo (BBCode, para un RichTextLabel). Con
# "sin_atacar", sin la línea de cómo se ataca ({atacar_modo}: «Cómo se juega» en la primera partida, la de la guía)
static func texto(id: String, sin_atacar := false) -> String:
	var lineas: Array = []
	for l: String in LISTA[id].lineas:
		if sin_atacar and l == "{atacar_modo}":
			continue
		lineas.append("• " + con_teclas(Idioma.t(l)))
	return "\n".join(lineas)


# Una frase ya traducida con sus {acciones} cambiadas por las teclas, en amarillo
static func con_teclas(texto_traducido: String) -> String:
	var t := texto_traducido.replace("{atacar_modo}", atacar_modo())
	while t.contains("{"):
		var a := t.find("{")
		var b := t.find("}", a)
		var accion := t.substr(a + 1, b - a - 1)
		var nombre := tecla(accion)
		if a == 0:   # al principio de la frase, con mayúscula
			nombre = nombre.left(1).to_upper() + nombre.substr(1)
		t = t.left(a) + "[color=#%s]%s[/color]" % [Tema.AMARILLO.to_html(false), nombre] + t.substr(b + 1)
	return t


# Cómo se ataca: apuntando tú, o solo con la ayuda "Disparo asistido" (johnny.gd, MODOS)
static func atacar_modo() -> String:
	if not Guardado.ajuste("disparo_asistido"):
		var como := Idioma.t("Apunta y ataca con {apuntar}.") if Tactil.activo else Idioma.t("Apunta con {apuntar} y ataca con {atacar}.")
		return como + " " + Idioma.t("Si prefieres que Johnny apunte solo, en Opciones → Ayudas está «Disparo asistido».")
	return Idioma.t("Johnny apunta y ataca solo al durmiente más cercano: tú preocúpate de moverte.")


# El nombre de lo que se pulsa para una acción: en el móvil, el botón de la pantalla; jugando con el mando, sus
# botones; si no, las teclas
static func tecla(accion: String) -> String:
	var mando := Controles.con_mando
	match accion:
		"moverse":
			if Tactil.activo:
				return Idioma.t("el joystick (toca y arrastra en la mitad izquierda)")
			if mando:
				return Idioma.t("el stick izquierdo")
			var letras: Array[String] = []
			for a in ["arriba", "izquierda", "abajo", "derecha"]:
				letras.append(Controles.tecla_de(a))
			# WASD, todas juntas; si alguna es más larga (Flecha arriba...), separadas
			return "".join(letras) if letras.all(func(l): return l.length() == 1) else ", ".join(letras)
		"apuntar":
			if Tactil.activo:
				return Idioma.t("el joystick de abajo a la derecha")
			return Idioma.t("el stick derecho") if mando else Idioma.t("el ratón")
	if Tactil.activo:
		return Idioma.t(TACTIL[accion]) if TACTIL.has(accion) else accion
	var nombres: Array[String] = []
	for ev in Controles.eventos(accion, mando):
		var n := Opciones.nombre_evento(ev)
		if n != "" and not n in nombres:
			nombres.append(n)
	if nombres.is_empty():
		return "-"
	var todos := nombres[0]
	for i in range(1, nombres.size()):
		todos = Idioma.t("%s o %s") % [todos, nombres[i]]   # (frase entera: «A o B»; con tres, «A o B o C»)
	return todos
