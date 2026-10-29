# Los tutoriales: la ventana que sale la primera vez que Johnny se encuentra algo nuevo (cómo se juega, los lanzables,
# el primer jefe...) y explica qué pasa y cómo se hace. Cada uno sale una sola vez (Guardado: "tutoriales", los vistos)
# y se puede volver a ver en el apartado Tutorial del menú principal y de la pausa (ui/tutorial.gd), donde los que aún
# no han salido están con «???» (menos «Cómo se juega», que se puede leer antes de jugar). Se apagan en
# Opciones → Ayudas (ajuste "tutoriales"), que también tiene un botón para que vuelvan a salir todos.
#
# Cada ficha: grupo (su apartado en la lista), titulo, icono (assets/ui/iconos), cuando (cuándo sale, para la lista y
# para no perderse) y lineas, lo que se explica. Su foto es assets/ui/tutorial/<id>.png, recortada de las capturas de
# la prueba (tools/fotos_tutorial.py). En las líneas, las teclas van entre llaves ({esquivar}, con el nombre de la
# acción de project.godot): salen las del jugador (las cambiadas en Opciones también), los botones del mando si hay uno
# enchufado o, en el móvil, los de la pantalla (tecla()). {moverse}, {apuntar} y {atacar_modo} son de aquí.
#
# Quién los llama: partida.gd (tutorial(id), y la mayoría en mirar_tutoriales), eventos.gd, supervivientes.gd y
# menu_principal.gd (el de la alerta).
#
# Idiomas: los textos de las tablas están en español, entre # [traducir] y # [/traducir], y salen ya traducidos por
# nombre_grupo(), titulo_de(), cuando_de() y texto() (que traduce cada línea ANTES de poner las teclas): la
# traducción conserva los {nombres} tal cual. Quien los enseñe no tiene que traducirlos otra vez.
class_name Tutoriales

const GRUPOS := ["Lo básico", "Armas", "Plantas y jefes", "Eventos sorpresa", "Sala de mantenimiento", "Más edificios"]  # [traducir]

# [traducir]
const LISTA := {
	"jugar": {"grupo": "Lo básico", "titulo": "Cómo se juega", "icono": "skin-conserje", "cuando": "Al empezar",
		"lineas": ["Muévete con {moverse}.",
			"{atacar_modo} El modo de atacar se cambia con {cambiar_modo}.",
			"Esquiva con {esquivar}: un acelerón corto en el que no te hacen daño.",
			"Cambia entre la fregona y la pistola con {cambiar_arma}, y pausa el juego con {pausa}."]},
	"apartamentos": {"grupo": "Lo básico", "titulo": "Limpia los apartamentos", "icono": "puerta",
		"cuando": "Al salir al pasillo",
		"lineas": ["Al entrar en un apartamento, la puerta se cierra detrás de ti y no se abre hasta que no queda ni un zombi.",
			"La sala del jefe de la planta está cerrada con llave: la lleva un zombi de otro apartamento y la suelta al caer.",
			"Vence al jefe y se abren las escaleras a la planta siguiente."]},
	"tercios": {"grupo": "Lo básico", "titulo": "La vida en tercios", "icono": "corazon",
		"cuando": "Al perder un tercio de vida",
		"lineas": ["Tu vida está partida en tres tercios. El que pierdes ya no se cura con vendas, y por cada uno andas más lento.",
			"Solo el botiquín devuelve un tercio perdido.",
			"Si se te hace cuesta arriba, en Opciones → Ayudas está «Vida entera»."]},
	"curas": {"grupo": "Lo básico", "titulo": "Vendas y botiquín", "icono": "botiquin",
		"cuando": "Al coger la primera cura",
		"lineas": ["Las vendas se usan con {usar_vendas}: curan 25, sin pasar del tercio en el que estás.",
			"El botiquín, con {usar_botiquin}: devuelve un tercio perdido y cura 50.",
			"Caben 3 vendas y 2 botiquines. Los armaritos de los baños se abren al acercarte y sueltan lo suyo."]},
	"inventario": {"grupo": "Lo básico", "titulo": "Inventario y mochila", "icono": "mochila",
		"cuando": "Al coger el primer objeto",
		"lineas": ["Lo que recoges va a la mochila. El inventario se abre con {inventario}: tus armas, la munición, los lanzables y la mochila.",
			"Elige una casilla para ver su ficha y sus botones (usar, ponérmela, tirar...).",
			"Si caes, lo que llevas se pierde; si completas el edificio, pasa al baúl."]},
	"dolares": {"grupo": "Lo básico", "titulo": "Dólares", "icono": "billete", "cuando": "Al coger el primer billete",
		"lineas": ["Los zombis a veces sueltan billetes, y los jefes muchos: pasa por encima para cogerlos.",
			"Se guardan al acabar la partida: todos si completas el edificio y la mitad si caes o abandonas.",
			"Se gastan en el ordenador de la sala de mantenimiento."]},
	"armas": {"grupo": "Armas", "titulo": "Armas nuevas", "icono": "escopeta", "cuando": "Al llevar otra arma",
		"lineas": ["Llevas dos armas en la mano: una de cuerpo a cuerpo y otra a distancia. Cambias de una a otra con {cambiar_arma}.",
			"Las demás van de repuesto, una de cada tipo, y se cambian en el inventario ({inventario}).",
			"El color del borde es su calidad: gris Normal, verde Poco común, azul Rara y morado Épica."]},
	"municion": {"grupo": "Armas", "titulo": "Munición y recarga", "icono": "municion", "cuando": "Al recargar",
		"lineas": ["Recarga con {recargar}; al vaciarse el cargador, recarga solo.",
			"Cada arma gasta la suya (balas, cartuchos...). Una caja de munición del suelo te da un cargador.",
			"Sin munición, Johnny saca el arma de cuerpo a cuerpo."]},
	"lanzables": {"grupo": "Armas", "titulo": "Lanzables", "icono": "molotov", "cuando": "En la primera pelea",
		"lineas": ["Lanza con {lanzar}: mantén para apuntar y suelta para lanzar.",
			"Lo que lanzas se cambia con {cambiar_lanzable}: el molotov prende fuego y la granada explota. Llevas 3 a mano y hasta 8 de repuesto.",
			"¡Ojo! La explosión también te hace daño a ti."]},
	"piezas": {"grupo": "Armas", "titulo": "Piezas de mejora", "icono": "obj-pieza_cuerpo",
		"cuando": "Al coger la primera pieza",
		"lineas": ["Con las piezas se sube la calidad de las armas y los lanzables, en el banco de trabajo de la sala de mantenimiento.",
			"Hay de cuatro familias: cuerpo a cuerpo, a distancia, especiales y arrojables. Las sueltan los zombis de vez en cuando y los jefes.",
			"Van en la mochila: si completas el edificio, pasan al baúl."]},
	"jefes": {"grupo": "Plantas y jefes", "titulo": "Jefes", "icono": "jefe", "cuando": "Al llegar al primer jefe",
		"lineas": ["Cada planta tiene su jefe, con su barra de vida arriba. A media vida se enfada y se vuelve más peligroso.",
			"Antes de cada ataque marca el suelo: ¡sal de la marca o esquívala!",
			"Al caer suelta dólares, munición y piezas, y se abren las escaleras."]},
	"mutaciones": {"grupo": "Plantas y jefes", "titulo": "Mutaciones", "icono": "zombi",
		"cuando": "Antes de la primera mutación",
		"lineas": ["Al vencer a un jefe, el virus te cambia: elige una de las dos cartas (también con 1 y 2).",
			"Cada mutación te da algo bueno y, a veces, algo malo.",
			"Duran hasta que acaba la partida, y llevas como mucho 4."]},
	"ascensor": {"grupo": "Plantas y jefes", "titulo": "El ascensor", "icono": "herramientas",
		"cuando": "Al arreglar el ascensor",
		"lineas": ["Johnny ha arreglado el ascensor del pasillo: baja a la sala de mantenimiento y vuelve a esta misma planta.",
			"Úsalo para ir al ordenador, al banco de trabajo o al baúl en mitad de la partida."]},
	"supervivientes": {"grupo": "Plantas y jefes", "titulo": "Supervivientes", "icono": "medico",
		"cuando": "Al rescatar al primero",
		"lineas": ["Se une al equipo: te acompaña y te ayuda a su manera.",
			"Cada uno tiene su rescate. No te alejes de él y, si cae, quédate a su lado para levantarlo.",
			"Si completas el edificio con él, se muda a las viviendas (la puerta de la derecha de la sala de mantenimiento) y podrá acompañarte."]},
	"apagon": {"grupo": "Eventos sorpresa", "titulo": "Apagón", "icono": "alerta", "cuando": "En el primer apagón",
		"lineas": ["Se ha ido la luz en toda la planta: solo ves lo que alumbra tu linterna, hacia donde miras.",
			"En la sala del jefe todo sigue como siempre.",
			"Al subir a la planta siguiente, te llevas un premio en dólares."]},
	"incendio": {"grupo": "Eventos sorpresa", "titulo": "Alarma de incendios", "icono": "alerta",
		"cuando": "En la primera alarma de incendios",
		"lineas": ["Los aspersores llenan el suelo de charcos que resbalan.",
			"En algunos cae un cable pelado que da calambrazos a Johnny y a los zombis: ¡llévalos hasta él! Esquivando cruzas sin daño.",
			"Al subir a la planta siguiente, te llevas un premio en dólares."]},
	"horda": {"grupo": "Eventos sorpresa", "titulo": "Horda", "icono": "alerta", "cuando": "En la primera horda",
		"lineas": ["Una horda enorme llena el pasillo y va a por ti.",
			"Si te metes en un piso, los que queden te esperan fuera. Aquí los lanzables vienen de perlas.",
			"Al acabar con todos, te deja dólares y una caja de munición."]},
	"ordenador": {"grupo": "Sala de mantenimiento", "titulo": "El ordenador", "icono": "dosier",
		"cuando": "Al encender el ordenador",
		"lineas": ["Gasta los dólares ahorrados: puntos de talento (mejoras para siempre) y armas y lanzables para la partida.",
			"También están los logros, que dan premio, el Dosier, las Noticias y las Colecciones."]},
	"taquilla": {"grupo": "Sala de mantenimiento", "titulo": "La taquilla", "icono": "skin-portero",
		"cuando": "Al abrir la taquilla",
		"lineas": ["Aquí eliges la ropa de Johnny. Cada una tiene su ventaja.",
			"Se consiguen venciendo a ciertos jefes: las que te faltan salen con «???» y cómo conseguirlas."]},
	"banco": {"grupo": "Sala de mantenimiento", "titulo": "El banco de trabajo", "icono": "herramientas",
		"cuando": "Al usar el banco de trabajo",
		"lineas": ["Sube la calidad de tus armas y lanzables, nivel a nivel, con las piezas de su familia (las de la mochila y las del baúl).",
			"Normal, Poco común, Rara y Épica: la Épica trae además un truco.",
			"Elige la casilla y pulsa «Mejorar»."]},
	"baul": {"grupo": "Sala de mantenimiento", "titulo": "El baúl", "icono": "mochila", "cuando": "Al abrir el baúl",
		"lineas": ["Lo que guardas aquí no se pierde aunque caigas: objetos, armas y lanzables mejorados.",
			"Elige una casilla o arrástrala para pasarla entre lo que llevas y el baúl.",
			"Al completar el edificio, lo que llevas pasa solo al baúl."]},
	"centro": {"grupo": "Más edificios", "titulo": "El centro comercial", "icono": "centro",
		"cuando": "Al llegar al centro comercial",
		"lineas": ["La sala del jefe se abre con una tarjeta de acceso: la lleva el guardia de seguridad que hace la ronda.",
			"Si te ve, toca el silbato, llegan refuerzos y él huye: ¡que no se escape!"]},
	"peligros": {"grupo": "Más edificios", "titulo": "Peligros de las tiendas", "icono": "alerta",
		"cuando": "En la primera tienda con peligro",
		"lineas": ["La cámara frigorífica congela, la cocina quema y el agua de la tienda de electrónica da calambres (su cuadro eléctrico corta la corriente).",
			"También hacen daño a los zombis despiertos: ¡llévalos hasta ellos!",
			"Esquivando los cruzas sin daño."]},
	"alerta": {"grupo": "Más edificios", "titulo": "Alerta y Reto del día", "icono": "trofeo",
		"cuando": "Al completar el primer edificio",
		"lineas": ["Debajo de cada edificio completado eliges la alerta con < y >: más difícil, más dólares. Completarlo con la más alta abre la siguiente.",
			"El Reto del día es el mismo edificio para todo el mundo ese día, con una regla rara. Completarlo la primera vez cada día da $10."]},
}
# [/traducir]

# En el móvil, con qué se hace cada acción (ui/tactil.gd)
# [traducir]
const TACTIL := {
	"esquivar": "el botón de esquivar", "cambiar_arma": "el botón de la otra arma",
	"recargar": "el botón del arma a distancia, con ella en la mano", "lanzar": "el botón de lanzar",
	"cambiar_lanzable": "el botoncito de al lado de lanzar", "usar_vendas": "el botón de las vendas, bajo el minimapa",
	"usar_botiquin": "el botón del botiquín, bajo el minimapa", "inventario": "el botón de la mochila, bajo el minimapa",
	"pausa": "el botón de pausa, bajo el minimapa", "cambiar_modo": "el botón del modo, bajo el minimapa",
}
# [/traducir]

static var vistos: Array = []   # los ya vistos: copia de Guardado "tutoriales", que se mira a menudo (mirar_tutoriales)
static var vistos_de := ""      # de qué archivo son (la prueba con --captura usa otro)


static func visto(id: String) -> bool:
	if vistos_de != Guardado.archivo:
		vistos = Guardado.cargar().tutoriales.duplicate()
		vistos_de = Guardado.archivo
	return id in vistos


# Si hay que enseñarlo ahora: aún no se ha visto y los tutoriales están encendidos (Opciones → Ayudas)
static func toca(id: String) -> bool:
	return Guardado.ajuste("tutoriales") and not visto(id)


static func apuntar(id: String) -> void:
	if visto(id):
		return
	vistos.append(id)
	Guardado.cambiar(func(s): if not id in s.tutoriales: s.tutoriales.append(id))


# Que vuelvan a salir todos (el botón de Opciones → Ayudas), también la guía de la primera partida (guia.gd)
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


# Las líneas de la ficha, cada una con su punto y las teclas en amarillo (BBCode, para un RichTextLabel)
static func texto(id: String) -> String:
	var lineas: Array = []
	for l: String in LISTA[id].lineas:
		lineas.append("• " + con_teclas(Idioma.t(l)))
	return "\n".join(lineas)


# Una frase ya traducida con sus {acciones} cambiadas por las teclas, en amarillo (también la usan las pistas de la
# primera partida, guia.gd)
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


# Cómo se ataca, según el modo elegido (johnny.gd, MODOS)
static func atacar_modo() -> String:
	if Guardado.ajuste("modo") == "libre":
		return Idioma.t("Apunta y ataca con {apuntar}.") if Tactil.activo else Idioma.t("Apunta con {apuntar} y ataca con {atacar}.")
	return Idioma.t("Johnny apunta y ataca solo al zombi más cercano: tú preocúpate de moverte.")


# El nombre de lo que se pulsa para una acción: en el móvil, el botón de la pantalla; con un mando enchufado, sus
# botones; si no, las teclas
static func tecla(accion: String) -> String:
	var mando := not Input.get_connected_joypads().is_empty()
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
