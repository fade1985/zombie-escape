# Los logros: retos que se ven en el ordenador de la sala de mantenimiento (programa "Logros"), para que el
# jugador elija cuál intentar en cada partida. Al cumplir uno sale un aviso; el premio (dólares) se cobra en el
# ordenador.
# Para añadir uno: una línea más en LISTA y, si hace falta, su aviso en el sitio del juego donde pasa la cosa
# (partida.gd llama a cumplir("id") o a las funciones de abajo). Si sale de algo que ya está en el guardado (las skins,
# el bestiario...), basta con su "mira": el repaso (revisar) lo da por conseguido en cuanto llegue.
# En el guardado (Guardado: "logros") solo se apunta el estado de cada uno: {"id": "conseguido" | "cobrado"}.
# Lo que no está, sigue pendiente. Lo que se cuenta solo para los logros (jefes derrotados, partidas ganadas, armas
# con las que se ha matado, condiciones del garaje jugadas) va aparte, en "logros_cuentas".
# Con alguna de las ayudas de Opciones → Ayudas encendida (AYUDAS) no se consigue ningún logro, y vale para toda la
# partida: si se enciende y se apaga, esa partida ya no da logros (ni suma en las cuentas). Los que ya se tenían se
# conservan y se cobran igual.
class_name Logros
extends Node

# "tema": el apartado del ordenador en el que sale (TEMAS).
# "meta": cuántas veces hay que hacerlo (sale con barra de progreso si es más de 1).
# "cuenta": "partida" (en una sola partida), "total" (sumando todas) o "" (basta con hacerlo una vez).
# "mira": sale de lo que hay en el guardado (hecho() dice cuánto lleva y, si no tiene "meta", meta() cuánto pide):
#   completado (el edificio "edificio" completado), rescatados (los de "edificio" que viven en las viviendas), skin
#   (una puesta), skins, bestiario, paginas (del dosier), objetos (de las Colecciones), rama (la más llena del árbol de
#   talentos), arbol (el árbol entero) y las cuentas de los logros (jefes, victorias, armas, condiciones)
# Los textos de BASE (nombre y desc) y de TEMAS se traducen al enseñarlos, con nombre_de(), desc_de() y nombre_tema()
# LISTA, la de todos, es BASE más los de cada arma (de_armas: M122), que se hacen solos
# [traducir]
const BASE := [
	# ── Edificios
	{"id": "primer_turno", "tema": "edificios", "nombre": "Primer turno", "icono": "logro-primer_turno", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Limpia tu primer apartamento."},
	{"id": "sube_conserje", "tema": "edificios", "nombre": "Sube, conserje", "icono": "logro-sube_conserje", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Llega a la planta 3."},
	{"id": "fin_jornada", "tema": "edificios", "nombre": "Fin de la jornada", "icono": "logro-fin_jornada", "premio": 50, "meta": 1, "cuenta": "",
		"desc": "Gana una partida: limpia el edificio de arriba abajo."},
	{"id": "liquidacion", "tema": "edificios", "nombre": "Liquidación total", "icono": "logro-liquidacion", "premio": 20, "cuenta": "",
		"mira": "completado", "edificio": "centro", "desc": "Completa el Centro comercial: derrota al gerente."},
	{"id": "reestructuracion", "tema": "edificios", "nombre": "Reestructuración", "icono": "logro-reestructuracion", "premio": 25, "cuenta": "",
		"mira": "completado", "edificio": "torre", "desc": "Completa Torre Velaria: derrota al Sujeto 1."},
	{"id": "alerta_naranja", "tema": "edificios", "nombre": "VD-7 reforzado", "icono": "logro-alerta_naranja", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Completa un edificio con la mejora 3 del compuesto VD-7 o más."},
	{"id": "alerta_maxima", "tema": "edificios", "nombre": "VD-7 al máximo", "icono": "logro-alerta_maxima", "premio": 35, "meta": 1, "cuenta": "",
		"desc": "Completa un edificio con la mejora 5 del compuesto VD-7."},
	{"id": "jornada_expres", "tema": "edificios", "nombre": "Jornada exprés", "icono": "logro-jornada_expres", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Gana una partida en menos de 15 minutos."},
	{"id": "empleado_mes", "tema": "edificios", "nombre": "Empleado del mes", "icono": "logro-empleado_mes", "premio": 20, "meta": 10, "cuenta": "total",
		"mira": "victorias", "desc": "Gana 10 partidas, sumando todas."},
	# ── Jefes
	{"id": "desahucio", "tema": "jefes", "nombre": "Desahucio", "icono": "logro-desahucio", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Derrota a la portera."},
	{"id": "sin_rasguno", "tema": "jefes", "nombre": "Sin un rasguño", "icono": "logro-sin_rasguno", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Derrota a un jefe sin perder vida en toda la pelea."},
	{"id": "por_los_pelos", "tema": "jefes", "nombre": "Por los pelos", "icono": "logro-por_los_pelos", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Derrota a un jefe con menos del 10 % de tu vida."},
	{"id": "visto_y_no_visto", "tema": "jefes", "nombre": "Visto y no visto", "icono": "logro-visto_y_no_visto", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Derrota a un jefe en menos de 30 segundos de pelea."},
	{"id": "cazajefes", "tema": "jefes", "nombre": "Cazajefes", "icono": "logro-cazajefes", "premio": 15, "meta": 25, "cuenta": "total",
		"mira": "jefes", "desc": "Derrota a 25 jefes, sumando todas tus partidas."},
	# ── Combate
	{"id": "fregona_oro", "tema": "combate", "nombre": "Fregona de oro", "icono": "logro-fregona_oro", "premio": 10, "meta": 10, "cuenta": "partida",
		"desc": "Mata 10 durmientes a fregonazos en una misma partida."},
	{"id": "exterminador", "tema": "combate", "nombre": "Exterminador", "icono": "logro-exterminador", "premio": 15, "meta": 100, "cuenta": "total",
		"desc": "Mata 100 durmientes, sumando todas tus partidas."},
	{"id": "limpieza_general", "tema": "combate", "nombre": "Limpieza general", "icono": "logro-limpieza_general", "premio": 20, "meta": 1000, "cuenta": "total",
		"desc": "Mata 1.000 durmientes, sumando todas tus partidas."},
	{"id": "piromano", "tema": "combate", "nombre": "Pirómano", "icono": "logro-piromano", "premio": 15, "meta": 5, "cuenta": "partida",
		"desc": "Prende fuego a 5 durmientes con un mismo molotov."},
	{"id": "racha", "tema": "combate", "nombre": "Racha imparable", "icono": "logro-racha", "premio": 10, "meta": 30, "cuenta": "partida",
		"desc": "Mata 30 durmientes seguidos sin perder vida."},
	{"id": "intocable", "tema": "combate", "nombre": "Intocable", "icono": "logro-intocable", "premio": 25, "meta": 1, "cuenta": "",
		"desc": "Pasa una planta entera, de la llegada a las escaleras, sin perder vida."},
	{"id": "sin_tiritas", "tema": "combate", "nombre": "Sin tiritas", "icono": "logro-sin_tiritas", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Gana una partida sin curarte con vendas ni botiquín."},
	# ── Armas y talentos
	{"id": "manitas", "tema": "armas", "nombre": "Manitas", "icono": "logro-manitas", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Mejora un arma en el banco de trabajo."},
	{"id": "joya_corona", "tema": "armas", "nombre": "Joya de la corona", "icono": "logro-joya_corona", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Sube un arma o un lanzable a Épica en el banco de trabajo."},
	{"id": "arsenal", "tema": "armas", "nombre": "Arsenal completo", "icono": "logro-arsenal", "premio": 15, "cuenta": "total",
		"mira": "armas", "desc": "Mata un durmiente con cada arma: la fregona y todas las de la tienda."},
	{"id": "especialista", "tema": "armas", "nombre": "Especialista", "icono": "logro-especialista", "premio": 15, "cuenta": "",
		"mira": "rama", "desc": "Llena una rama entera de mutaciones."},
	{"id": "conserje_total", "tema": "armas", "nombre": "Conserje total", "icono": "logro-conserje_total", "premio": 25, "cuenta": "",
		"mira": "arbol", "desc": "Llena todas las mutaciones."},
	# ── Supervivientes
	{"id": "buen_vecino", "tema": "supervivientes", "nombre": "Buen vecino", "icono": "logro-buen_vecino", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Rescata a un superviviente: aguanta la horda mientras fuerza la cerradura."},
	{"id": "comunidad", "tema": "supervivientes", "nombre": "Comunidad de vecinos", "icono": "logro-comunidad", "premio": 10, "cuenta": "",
		"mira": "rescatados", "edificio": "apartamentos", "desc": "Rescata a los 3 supervivientes de los Apartamentos."},
	{"id": "plantilla", "tema": "supervivientes", "nombre": "Plantilla completa", "icono": "logro-plantilla", "premio": 10, "cuenta": "",
		"mira": "rescatados", "edificio": "centro", "desc": "Rescata a los 3 supervivientes del Centro comercial."},
	{"id": "horas_extra", "tema": "supervivientes", "nombre": "Horas extra", "icono": "logro-horas_extra", "premio": 10, "cuenta": "",
		"mira": "rescatados", "edificio": "torre", "desc": "Rescata a los 3 supervivientes de Torre Velaria."},
	{"id": "buena_compania", "tema": "supervivientes", "nombre": "Buena compañía", "icono": "logro-buena_compania", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Gana una partida con un superviviente de los trasteros acompañándote."},
	# ── Sorpresas y retos
	{"id": "caja_fuerte", "tema": "sorpresas", "nombre": "Caja fuerte", "icono": "logro-caja_fuerte", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Abre la cámara acorazada de la Joyería del centro comercial."},
	{"id": "se_fue_la_luz", "tema": "sorpresas", "nombre": "Se fue la luz", "icono": "logro-se_fue_la_luz", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Supera un apagón: llega a la planta siguiente."},
	{"id": "simulacro", "tema": "sorpresas", "nombre": "Simulacro", "icono": "logro-simulacro", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Supera un incendio: llega a la planta siguiente."},
	{"id": "contra_marea", "tema": "sorpresas", "nombre": "Contra la marea", "icono": "logro-contra_marea", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Vence a una horda del pasillo."},
	{"id": "reto_aceptado", "tema": "sorpresas", "nombre": "Reto aceptado", "icono": "logro-reto_aceptado", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Supera las 25 oleadas del garaje del reto del día."},
	{"id": "todas_reglas", "tema": "sorpresas", "nombre": "Ninguna regla me para", "icono": "logro-todas_reglas", "premio": 25, "cuenta": "total",
		"mira": "condiciones", "desc": "Juega el garaje del reto del día con cada una de sus 5 condiciones."},
	# ── Colecciones
	{"id": "cambio_look", "tema": "colecciones", "nombre": "Cambio de look", "icono": "logro-cambio_look", "premio": 5, "cuenta": "",
		"mira": "skin", "desc": "Ponte una skin en la taquilla del vestuario."},
	{"id": "vestuario", "tema": "colecciones", "nombre": "Vestuario completo", "icono": "logro-vestuario", "premio": 15, "cuenta": "",
		"mira": "skins", "desc": "Consigue todas las skins de Johnny."},
	{"id": "naturalista", "tema": "colecciones", "nombre": "Naturalista", "icono": "logro-naturalista", "premio": 15, "cuenta": "",
		"mira": "bestiario", "desc": "Completa el bestiario: ve a todos los enemigos."},
	{"id": "investigador", "tema": "colecciones", "nombre": "Investigador", "icono": "logro-investigador", "premio": 15, "cuenta": "",
		"mira": "paginas", "desc": "Encuentra todas las páginas del dosier VD-7."},
	{"id": "chatarrero", "tema": "colecciones", "nombre": "Chatarrero", "icono": "logro-chatarrero", "premio": 5, "cuenta": "",
		"mira": "objetos", "desc": "Coge al menos una vez cada objeto de las Colecciones."},
]
# [/traducir]
# Los apartados del programa Logros del ordenador, en orden
# [traducir]
const TEMAS := {"edificios": "Edificios", "jefes": "Jefes", "combate": "Combate", "armas": "Armas y mutaciones",
	"arsenal_cuerpo": "Cuerpo a cuerpo", "arsenal_distancia": "A distancia", "arsenal_especial": "Especiales",
	"supervivientes": "Supervivientes", "sorpresas": "Sorpresas y retos", "colecciones": "Colecciones"}
# [/traducir]
# Los logros de cada arma (M122, 16 nov: para que el 100 % obligue a usarlas todas): tres por cada una de las del arsenal
# (la fregona y las de la tienda), por los durmientes que se matan con ella en la mano, sumando todas las partidas
# (como Fregona de oro: los que mueren quemados no cuentan, salvo con el lanzallamas, que mata así). Cada arma, en el
# apartado de su familia (Armas.familia): Cuerpo a cuerpo, A distancia y Especiales; en el ordenador se ve uno por arma,
# el nivel que toca (ui/archivador_logros.gd). Se cuentan en la partida (por_arma) y se guardan al subir de planta y al
# acabar (guardar_armas), en "logros_cuentas" → "con_arma" ({arma: cuántos})
const NIVELES_ARMA := [{"meta": 10, "premio": 5}, {"meta": 50, "premio": 10}, {"meta": 200, "premio": 20}]
static var LISTA: Array = BASE + de_armas()

const TOPE: int = preload("res://scripts/ui/chapa.gd").MAXIMO   # el tope de los dólares («MAX»; partida.TOPE)
const AL_PRENDER := 5.0   # segundos tras lanzar un molotov en los que sus llamas cuentan para "Pirómano"
const JEFE_RAPIDO := 30.0     # Visto y no visto: los segundos de pelea con el jefe, como mucho
const JEFE_APURADO := 0.1     # Por los pelos: la parte de su vida máxima que le queda a Johnny, como mucho
const EXPRES := 15 * 60.0     # Jornada exprés: los segundos de partida, como mucho
const PRIMER_REPASO := 1.5    # al empezar la partida, lo que tarda el primer repaso del guardado (revisar)
# Los ajustes de las ayudas que quitan los logros (los Tutoriales no: no ayudan a jugar)
const AYUDAS := ["vida_entera", "pistola_sin_fin", "lanzar_solo", "disparo_asistido"]

var partida: Node
var con_ayudas := false   # si en esta partida ha estado encendida alguna ayuda (aunque ya se haya apagado)
var muertos_antes := 0    # zombis matados en otras partidas sin ayudas (para "Exterminador")
var fregonazos := 0       # zombis matados con la fregona en esta partida
var prendidos := 0        # zombis prendidos por el último molotov
var molotov_t := 0.0      # segundos que le quedan al último molotov para contar
var tocado := false       # si Johnny ha perdido vida en esta planta
var vida_antes := 0
var racha := 0            # zombis matados seguidos sin perder vida ("Racha imparable")...
var mejor_racha := 0      # ...y la más larga de esta partida (la barra del ordenador)
var curado := false       # si ha usado vendas o botiquín en esta partida ("Sin tiritas"; partida.gd, usar_objeto)
var jefe: Node2D          # el jefe con el que se pelea (partida.gd lo da al salir: jefe_sale)...
var pelea_t := 0.0        # ...los segundos que lleva la pelea (sin su presentación ni la espera en el helipuerto)...
var tocado_jefe := false  # ...y si Johnny ha perdido vida en ella
var armas_usadas: Array = []   # las armas con las que ya se ha matado alguna vez ("Arsenal completo"; del guardado)
var por_arma := {}             # los durmientes matados con cada arma en esta partida, aún sin guardar (los de cada arma)...
var con_arma := {}             # ...los que ya están en el guardado (se leen al empezar: así no se lee el guardado a cada muerto)...
var armas_avisadas: Array = [] # ...y los de cada arma que ya se han dado por cumplidos en esta partida
var por_avisar: Array = []     # los nombres de los recién conseguidos que aún no se han avisado (avisar)
var repasar := true       # si se hace el repaso del guardado, revisar (la partida de prueba lo apaga: prueba_comun.gd)
var repasado_en := -1     # con cuántas escrituras iba el guardado en el último repaso (Guardado.escrituras)
var espera := PRIMER_REPASO


func preparar(p: Node) -> void:
	partida = p
	var s := Guardado.cargar()
	muertos_antes = s.muertos - s.muertos_con_ayudas
	armas_usadas = s.logros_cuentas.get("armas", []).duplicate()
	con_arma = s.logros_cuentas.get("con_arma", {}).duplicate()
	con_ayudas = ayudas_encendidas()
	p.johnny.vida_cambiada.connect(func(vida, _maxima):
		if vida < vida_antes:
			tocado = true
			tocado_jefe = true
			racha = 0
		vida_antes = vida)


func _process(delta: float) -> void:
	molotov_t = maxf(0.0, molotov_t - delta)
	# una ayuda encendida a media partida (desde la pausa): se avisa y esta partida ya no da logros
	if not con_ayudas and ayudas_encendidas():
		con_ayudas = true
		partida.decir(Idioma.t("Con ayudas encendidas, en esta partida ya no se consiguen logros"), 4.0)
	# la pelea con el jefe: no cuenta mientras se presenta ni mientras espera arriba, en el helipuerto
	if is_instance_valid(jefe):
		if jefe.get("esperando") or partida.presentacion.activa:
			pelea_t = 0.0
			tocado_jefe = false
		else:
			pelea_t += delta
	# lo que sale del guardado: al empezar (un poco después) y cada vez que se escribe
	espera = maxf(0.0, espera - delta)
	if espera <= 0.0 and repasado_en != Guardado.escrituras:
		revisar()


# Si hay alguna ayuda de Opciones encendida ahora mismo
static func ayudas_encendidas() -> bool:
	for a in AYUDAS:
		if Guardado.ajuste(a):
			return true
	return false


# Si en esta partida no se pueden conseguir logros (hay una ayuda encendida o la hubo)
func sin_logros() -> bool:
	return con_ayudas or ayudas_encendidas()


# Los logros de cada arma (M122): «arma_katana_2» es el segundo nivel de la katana
static func de_armas() -> Array:
	var lista := []
	for arma in arsenal():
		for i in NIVELES_ARMA.size():
			lista.append({"id": "arma_%s_%d" % [arma, i + 1], "tema": "arsenal_" + Armas.familia(arma), "icono": arma,
				"premio": NIVELES_ARMA[i].premio, "meta": NIVELES_ARMA[i].meta, "cuenta": "total", "arma": arma, "nivel": i + 1})
	return lista


# De los de un arma, el que se ve en el ordenador: el primer nivel que aún no está cobrado (o, con todos, el último)
static func toca_ver(l: Dictionary, s: Dictionary) -> bool:
	if not l.has("arma"):
		return true
	for i in NIVELES_ARMA.size():
		var id := "arma_%s_%d" % [l.arma, i + 1]
		if estado(s, id) != "cobrado" or i == NIVELES_ARMA.size() - 1:
			return id == l.id
	return false


static func datos(id: String) -> Dictionary:
	for l in LISTA:
		if l.id == id:
			return l
	return {}


# El nombre y la descripción de un logro, y el nombre de un apartado (TEMAS), ya en el idioma del jugador
static func nombre_de(id: String) -> String:
	var l := datos(id)
	if l.has("arma"):
		# (su nombre, según el nivel, con el del arma delante: «Katana: veterano»)
		var nombre: String = [Idioma.t("%s: novato"), Idioma.t("%s: veterano"), Idioma.t("%s: maestro")][l.nivel - 1]
		return nombre % Armas.nombre(l.arma)
	return Idioma.t(l.get("nombre", ""))


static func desc_de(id: String) -> String:
	var l := datos(id)
	if l.has("arma"):
		return Idioma.n("Mata %d durmiente con esta arma, sumando todas tus partidas.",
			"Mata %d durmientes con esta arma, sumando todas tus partidas.", l.meta) % l.meta
	return Idioma.t(l.get("desc", ""))


static func nombre_tema(tema: String) -> String:
	return Idioma.t(TEMAS.get(tema, ""))


# "pendiente", "conseguido" (falta cobrarlo) o "cobrado"
static func estado(s: Dictionary, id: String) -> String:
	return s.logros.get(id, "pendiente")


# Las armas de "Arsenal completo": la fregona y las de la tienda
static func arsenal() -> Array:
	return ["fregona"] + Armas.PRECIOS.keys()


# Cuánto pide uno: su "meta" o, si no la tiene, lo que sale de su "mira" (todas las skins, todo el bestiario...)
static func meta(l: Dictionary) -> int:
	match l.get("mira", ""):
		"rescatados":
			return Supervivientes.DATOS.values().filter(func(d): return d.edificio == l.edificio).size()
		"skins": return Skins.LISTA.size()
		"bestiario": return Bestiario.LISTA.size()
		"objetos": return Objetos.NOMBRES.size() - Objetos.COMIDAS.size()   # (la comida no cuenta: M124)
		"paginas": return paginas(Guardado.NUEVO)[1]
		"rama": return Talentos.RAMAS.map(func(r): return puntos_rama(r.id)[1]).min()
		"arbol": return Talentos.LISTA.reduce(func(n, t): return n + t.max, 0)
		"armas": return arsenal().size()
		"condiciones": return Garaje.CONDICIONES.size()
	return l.get("meta", 1)


# Lo que lleva hecho, según el guardado, uno con "mira"
static func hecho(l: Dictionary, s: Dictionary) -> int:
	var cuentas: Dictionary = s.logros_cuentas
	match l.get("mira", ""):
		"completado":
			return 1 if s.edificios.has(l.edificio) and s.edificios[l.edificio].completado else 0
		"rescatados":
			var de_aqui := Supervivientes.DATOS.keys().filter(func(id): return Supervivientes.DATOS[id].edificio == l.edificio)
			return s.rescatados.filter(func(id): return id in de_aqui).size()
		"skin": return 1 if s.skin != "" else 0
		"skins": return s.skins.filter(func(id): return id in Skins.LISTA).size()
		"bestiario": return s.bestiario.filter(func(id): return id in Bestiario.LISTA).size()
		"objetos": return s.encontrados.filter(func(id): return id in Objetos.NOMBRES and not id in Objetos.COMIDAS).size()
		"paginas": return paginas(s)[0]
		"rama":
			# la rama más llena, en la escala de la más pequeña: solo llega a la meta con una rama entera
			var m := meta(l)
			return Talentos.RAMAS.map(func(r):
				var p := puntos_rama(r.id, s)
				return p[0] * m / p[1]).max()
		"arbol": return Talentos.RAMAS.reduce(func(n, r): return n + puntos_rama(r.id, s)[0], 0)
		"jefes", "victorias": return int(cuentas.get(l.mira, 0))
		"armas": return cuentas.get("armas", []).filter(func(id): return id in arsenal()).size()
		# (las del garaje, en su lista: las 7 reglas del reto viejo, "reglas", ya no cuentan)
		"condiciones": return cuentas.get("condiciones", []).filter(func(id): return id in Garaje.CONDICIONES).size()
	return 0


# Las páginas del dosier (de todos los edificios): [encontradas, todas]
static func paginas(s: Dictionary) -> Array:
	var n := 0
	var todas := 0
	for id in Historia.DOSIERES:
		for p in Historia.DOSIERES[id].paginas:
			todas += 1
			if Historia.encontrada(s, p.id):
				n += 1
	return [n, todas]


# Los puntos puestos en una rama de talentos y los que admite entera: [puestos, todos]
static func puntos_rama(rama: String, s := {}) -> Array:
	var n := 0
	var todos := 0
	for t in Talentos.LISTA:
		if t.rama == rama:
			todos += t.max
			n += mini(int(s.get("talentos", {}).get(t.id, 0)), t.max)
	return [n, todos]


# Lo que lleva hecho de los que tienen meta (para la barra del ordenador). "s", el guardado, si ya se tiene leído
func progreso(id: String, s := {}) -> int:
	match id:
		"fregona_oro": return fregonazos
		"piromano": return prendidos
		"racha": return mejor_racha
		"exterminador", "limpieza_general":
			return muertos_antes + (partida.muertos if partida and not sin_logros() else 0)
	var l := datos(id)
	if l.has("mira"):
		return hecho(l, s if not s.is_empty() else Guardado.cargar())
	if l.has("arma"):   # los de cada arma: los guardados y los de esta partida
		var guardados: Dictionary = s.logros_cuentas.get("con_arma", {}) if not s.is_empty() else con_arma
		return int(guardados.get(l.arma, 0)) + (int(por_arma.get(l.arma, 0)) if not sin_logros() else 0)
	return 0


# Cumplido: se apunta en el guardado y sale el aviso (si ya estaba, no pasa nada). Con ayudas, no se apunta.
# Los que se cumplen a la vez (al ganar, en el repaso) salen en un solo aviso, al acabar el fotograma (avisar)
func cumplir(id: String) -> void:
	if partida == null or sin_logros():
		return
	var s := Guardado.cargar()
	if estado(s, id) != "pendiente":
		return
	Guardado.cambiar(func(g): g.logros[id] = "conseguido")
	if por_avisar.is_empty():
		avisar.call_deferred()
	por_avisar.append(nombre_de(id))


func avisar() -> void:
	if por_avisar.is_empty() or partida == null:
		return
	Sonido.tocar("limpio")
	if por_avisar.size() == 1:
		partida.gran_aviso(Idioma.t("¡LOGRO CONSEGUIDO!"))
		partida.decir(Idioma.t("¡Logro conseguido: %s! Cobra el premio en el ordenador") % por_avisar[0], 4.0)
	else:
		partida.gran_aviso(Idioma.t("¡%d LOGROS CONSEGUIDOS!") % por_avisar.size())
		if por_avisar.size() == 2:
			partida.decir(Idioma.t("¡Logros conseguidos: %s y %s! Cobra los premios en el ordenador") % por_avisar, 5.0)
		else:   # (con más, los nombres no caben en la pantalla)
			partida.decir(Idioma.t("¡%d logros conseguidos! Míralos y cobra los premios en el ordenador") % por_avisar.size(), 5.0)
	por_avisar.clear()


# Cobra el premio de uno conseguido (desde el ordenador). Devuelve los dólares cobrados, o -1 si no se podía. Sin pasar
# del tope de los dólares («MAX», TOPE, contando los "en_partida", los de la partida en curso): lo que no cabe se pierde
# para siempre y el logro queda cobrado igual (lo pidió el dueño el 15 nov; lo explica el tutorial de Logros)
static func cobrar(id: String, en_partida := 0) -> int:
	var l := datos(id)
	var cobrado := [-1]
	Guardado.cambiar(func(g):
		if estado(g, id) == "conseguido":
			g.logros[id] = "cobrado"
			cobrado[0] = clampi(TOPE - g.dolares - en_partida, 0, l.premio)
			g.dolares += cobrado[0])
	return cobrado[0]


# El repaso: los que salen del guardado ("mira") y ya llegan a su meta, conseguidos. Se hace al empezar la partida,
# cada vez que se escribe el guardado (_process), al acabarla y al abrir el programa Logros del ordenador; así
# también salen los que se hicieron antes de que existiera el logro (las skins que ya se tenían...)
func revisar() -> void:
	repasado_en = Guardado.escrituras
	if not repasar or partida == null or sin_logros():
		return
	var s := Guardado.cargar()
	for l in LISTA:
		if l.has("mira") and estado(s, l.id) == "pendiente" and hecho(l, s) >= meta(l):
			cumplir(l.id)
	repasado_en = Guardado.escrituras   # (lo que acaba de escribir cumplir ya está repasado)


# Uno más en una cuenta de los logros del guardado ("logros_cuentas": jefes, victorias); el repaso mira si ya llega
func sumar(clave: String) -> void:
	if partida == null or sin_logros():
		return
	Guardado.cambiar(func(g): g.logros_cuentas[clave] = int(g.logros_cuentas.get(clave, 0)) + 1)


# Uno más en una lista de los logros del guardado ("logros_cuentas": armas, condiciones), si no estaba
func apuntar(clave: String, id: String) -> void:
	if partida == null or sin_logros():
		return
	Guardado.cambiar(func(g):
		var lista: Array = g.logros_cuentas.get(clave, [])
		if not id in lista:
			lista.append(id)
		g.logros_cuentas[clave] = lista)


# ── Los avisos que da la partida ──

# Un zombi ha caído: "arma", la que llevaba Johnny en la mano; "ardia", si murió quemado (no cuenta como fregonazo)
func zombi_muerto(arma: String, ardia: bool) -> void:
	if arma == "fregona" and not ardia:
		fregonazos += 1
		if fregonazos >= datos("fregona_oro").meta:
			cumplir("fregona_oro")
	for id in ["exterminador", "limpieza_general"]:
		if progreso(id) >= datos(id).meta:
			cumplir(id)
	racha += 1
	mejor_racha = maxi(mejor_racha, racha)
	if racha >= datos("racha").meta:
		cumplir("racha")
	if arma in arsenal() and not arma in armas_usadas:
		armas_usadas.append(arma)
		apuntar("armas", arma)
	# los de cada arma (M122): uno más con la de la mano y, si llega a un nivel, conseguido
	if arma in arsenal() and (not ardia or arma == "lanzallamas") and partida != null and not sin_logros():
		por_arma[arma] = int(por_arma.get(arma, 0)) + 1
		for i in NIVELES_ARMA.size():
			var id := "arma_%s_%d" % [arma, i + 1]
			if not id in armas_avisadas and progreso(id) >= NIVELES_ARMA[i].meta:
				armas_avisadas.append(id)
				cumplir(id)   # (si ya lo tenía, no pasa nada)


# Los durmientes de cada arma de esta partida, al guardado (al subir de planta y al acabar la partida: partida.gd)
func guardar_armas() -> void:
	if por_arma.is_empty():
		return
	var cuantos := por_arma.duplicate()
	por_arma.clear()
	if partida == null or sin_logros():
		return
	for arma in cuantos:
		con_arma[arma] = int(con_arma.get(arma, 0)) + cuantos[arma]
	Guardado.cambiar(func(g):
		var con: Dictionary = g.logros_cuentas.get("con_arma", {})
		for arma in cuantos:
			con[arma] = int(con.get(arma, 0)) + cuantos[arma]
		g.logros_cuentas["con_arma"] = con)


# Sale el jefe de la planta (partida.gd): empieza su pelea
func jefe_sale(z: Node2D) -> void:
	jefe = z
	pelea_t = 0.0
	tocado_jefe = false


# Un jefe ha caído ("z", su nodo): Desahucio (solo la portera), los de la pelea y Cazajefes
func jefe_muerto(tipo: String, z: Node2D) -> void:
	if tipo == "portera":
		cumplir("desahucio")
	var johnny: Node = partida.johnny
	if johnny.vivo and johnny.vida < johnny.stats.vida_max * JEFE_APURADO:
		cumplir("por_los_pelos")
	if jefe != null and z == jefe:   # (uno que no salió en su sala, como los de la prueba, no tiene pelea contada)
		if not tocado_jefe:
			cumplir("sin_rasguno")
		if pelea_t < JEFE_RAPIDO:
			cumplir("visto_y_no_visto")
		jefe = null
	sumar("jefes")


# La partida ganada (partida.gd, terminar)
func partida_ganada() -> void:
	cumplir("fin_jornada")
	if partida.duracion < EXPRES:
		cumplir("jornada_expres")
	if not curado:
		cumplir("sin_tiritas")
	if Alerta.nivel >= 3:
		cumplir("alerta_naranja")
	if Alerta.nivel >= Alerta.MAX:
		cumplir("alerta_maxima")
	if partida.supervivientes.equipo.any(func(a): return is_instance_valid(a) and a.es_vecino):
		cumplir("buena_compania")
	sumar("victorias")


# El garaje del reto del día, acabado (garaje.gd, terminar; ganes, caigas o abandones): su condición, a la lista de
# «Ninguna regla me para»; y superadas las 25 oleadas, «Reto aceptado»
func garaje_jugado(condicion: String, gano: bool) -> void:
	if condicion != "":
		apuntar("condiciones", condicion)
	if gano:
		cumplir("reto_aceptado")


func molotov_lanzado() -> void:
	prendidos = 0
	molotov_t = AL_PRENDER


# Un zombi ha empezado a arder
func zombi_prendido() -> void:
	if molotov_t <= 0.0:
		return
	prendidos += 1
	if prendidos >= datos("piromano").meta:
		cumplir("piromano")


# Al llegar a una planta nueva se empieza a contar el daño de cero
func planta_nueva() -> void:
	tocado = false
	vida_antes = partida.johnny.vida


# Al dejar una planta por las escaleras
func planta_pasada() -> void:
	guardar_armas()   # (los durmientes de cada arma, al guardado: M122)
	if not tocado:
		cumplir("intocable")
