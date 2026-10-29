# Los logros: retos que se ven en el ordenador de la sala de mantenimiento (programa "Logros"), para que el
# jugador elija cuál intentar en cada partida. Al cumplir uno sale un aviso; el premio (dólares) se cobra en el
# ordenador.
# Para añadir uno: una línea más en LISTA y, si hace falta, su aviso en el sitio del juego donde pasa la cosa
# (partida.gd llama a cumplir("id") o a las funciones de abajo). Si sale de algo que ya está en el guardado (las skins,
# el bestiario...), basta con su "mira": el repaso (revisar) lo da por conseguido en cuanto llegue.
# En el guardado (Guardado: "logros") solo se apunta el estado de cada uno: {"id": "conseguido" | "cobrado"}.
# Lo que no está, sigue pendiente. Lo que se cuenta solo para los logros (jefes derrotados, partidas ganadas, armas
# con las que se ha matado, reglas del reto completadas) va aparte, en "logros_cuentas".
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
#   talentos), arbol (el árbol entero) y las cuentas de los logros (jefes, victorias, armas, reglas)
# Los textos de LISTA (nombre y desc) y de TEMAS se traducen al enseñarlos, con nombre_de(), desc_de() y nombre_tema()
# [traducir]
const LISTA := [
	# ── Edificios
	{"id": "primer_turno", "tema": "edificios", "nombre": "Primer turno", "icono": "apartamentos", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Limpia tu primer apartamento."},
	{"id": "sube_conserje", "tema": "edificios", "nombre": "Sube, conserje", "icono": "escalera", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Llega a la planta 3."},
	{"id": "fin_jornada", "tema": "edificios", "nombre": "Fin de la jornada", "icono": "trofeo", "premio": 50, "meta": 1, "cuenta": "",
		"desc": "Gana una partida: limpia el edificio de arriba abajo."},
	{"id": "liquidacion", "tema": "edificios", "nombre": "Liquidación total", "icono": "centro", "premio": 20, "cuenta": "",
		"mira": "completado", "edificio": "centro", "desc": "Completa el Centro comercial: derrota al gerente."},
	{"id": "alerta_naranja", "tema": "edificios", "nombre": "Alerta naranja", "icono": "alerta", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Completa un edificio con la Alerta 3 o más."},
	{"id": "alerta_maxima", "tema": "edificios", "nombre": "Alerta máxima", "icono": "alerta", "premio": 35, "meta": 1, "cuenta": "",
		"desc": "Completa un edificio con la Alerta 5."},
	{"id": "jornada_expres", "tema": "edificios", "nombre": "Jornada exprés", "icono": "cafe", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Gana una partida en menos de 15 minutos."},
	{"id": "empleado_mes", "tema": "edificios", "nombre": "Empleado del mes", "icono": "trofeo", "premio": 20, "meta": 10, "cuenta": "total",
		"mira": "victorias", "desc": "Gana 10 partidas, sumando todas."},
	# ── Jefes
	{"id": "desahucio", "tema": "jefes", "nombre": "Desahucio", "icono": "jefe", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Derrota a la portera."},
	{"id": "sin_rasguno", "tema": "jefes", "nombre": "Sin un rasguño", "icono": "casco", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Derrota a un jefe sin perder vida en toda la pelea."},
	{"id": "por_los_pelos", "tema": "jefes", "nombre": "Por los pelos", "icono": "vida", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Derrota a un jefe con menos del 10 % de tu vida."},
	{"id": "visto_y_no_visto", "tema": "jefes", "nombre": "Visto y no visto", "icono": "dash", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Derrota a un jefe en menos de 30 segundos de pelea."},
	{"id": "cazajefes", "tema": "jefes", "nombre": "Cazajefes", "icono": "jefe", "premio": 15, "meta": 25, "cuenta": "total",
		"mira": "jefes", "desc": "Derrota a 25 jefes, sumando todas tus partidas."},
	# ── Combate
	{"id": "fregona_oro", "tema": "combate", "nombre": "Fregona de oro", "icono": "fregona", "premio": 10, "meta": 10, "cuenta": "partida",
		"desc": "Mata 10 zombis a fregonazos en una misma partida."},
	{"id": "exterminador", "tema": "combate", "nombre": "Exterminador", "icono": "zombi", "premio": 15, "meta": 100, "cuenta": "total",
		"desc": "Mata 100 zombis, sumando todas tus partidas."},
	{"id": "limpieza_general", "tema": "combate", "nombre": "Limpieza general", "icono": "zombi", "premio": 20, "meta": 1000, "cuenta": "total",
		"desc": "Mata 1.000 zombis, sumando todas tus partidas."},
	{"id": "piromano", "tema": "combate", "nombre": "Pirómano", "icono": "molotov", "premio": 15, "meta": 5, "cuenta": "partida",
		"desc": "Prende fuego a 5 zombis con un mismo molotov."},
	{"id": "racha", "tema": "combate", "nombre": "Racha imparable", "icono": "fuerza", "premio": 10, "meta": 30, "cuenta": "partida",
		"desc": "Mata 30 zombis seguidos sin perder vida."},
	{"id": "intocable", "tema": "combate", "nombre": "Intocable", "icono": "reflejos", "premio": 25, "meta": 1, "cuenta": "",
		"desc": "Pasa una planta entera, de la llegada a las escaleras, sin perder vida."},
	{"id": "sin_tiritas", "tema": "combate", "nombre": "Sin tiritas", "icono": "botiquin", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Gana una partida sin curarte con vendas ni botiquín."},
	# ── Armas y talentos
	{"id": "manitas", "tema": "armas", "nombre": "Manitas", "icono": "herramientas", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Mejora un arma en el banco de trabajo."},
	{"id": "joya_corona", "tema": "armas", "nombre": "Joya de la corona", "icono": "obj-pieza_especial", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Sube un arma o un arrojable a Épica en el banco de trabajo."},
	{"id": "arsenal", "tema": "armas", "nombre": "Arsenal completo", "icono": "escopeta", "premio": 15, "cuenta": "total",
		"mira": "armas", "desc": "Mata un zombi con cada arma: la fregona y todas las de la tienda."},
	{"id": "especialista", "tema": "armas", "nombre": "Especialista", "icono": "militar", "premio": 15, "cuenta": "",
		"mira": "rama", "desc": "Llena una rama entera del árbol de talentos."},
	{"id": "conserje_total", "tema": "armas", "nombre": "Conserje total", "icono": "medico", "premio": 25, "cuenta": "",
		"mira": "arbol", "desc": "Llena el árbol de talentos entero."},
	# ── Supervivientes
	{"id": "buen_vecino", "tema": "supervivientes", "nombre": "Buen vecino", "icono": "corazon", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Rescata a un superviviente: aguanta la horda mientras fuerza la cerradura."},
	{"id": "comunidad", "tema": "supervivientes", "nombre": "Comunidad de vecinos", "icono": "apartamentos", "premio": 10, "cuenta": "",
		"mira": "rescatados", "edificio": "apartamentos", "desc": "Rescata a los 3 supervivientes de los Apartamentos."},
	{"id": "plantilla", "tema": "supervivientes", "nombre": "Plantilla completa", "icono": "centro", "premio": 10, "cuenta": "",
		"mira": "rescatados", "edificio": "centro", "desc": "Rescata a los 3 supervivientes del Centro comercial."},
	{"id": "buena_compania", "tema": "supervivientes", "nombre": "Buena compañía", "icono": "corazon", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Gana una partida con un vecino de las viviendas acompañándote."},
	# ── Sorpresas y retos
	{"id": "caja_fuerte", "tema": "sorpresas", "nombre": "Caja fuerte", "icono": "llave", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Abre la cámara acorazada de la Joyería del centro comercial."},
	{"id": "se_fue_la_luz", "tema": "sorpresas", "nombre": "Se fue la luz", "icono": "obj-bateria", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Supera un apagón: llega a la planta siguiente."},
	{"id": "simulacro", "tema": "sorpresas", "nombre": "Simulacro", "icono": "lanzallamas", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Supera un incendio: llega a la planta siguiente."},
	{"id": "contra_marea", "tema": "sorpresas", "nombre": "Contra la marea", "icono": "bate", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Vence a una horda del pasillo."},
	{"id": "reto_aceptado", "tema": "sorpresas", "nombre": "Reto aceptado", "icono": "diana", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Completa un reto del día."},
	{"id": "todas_reglas", "tema": "sorpresas", "nombre": "Ninguna regla me para", "icono": "diana", "premio": 25, "cuenta": "total",
		"mira": "reglas", "desc": "Completa el reto del día con cada una de sus 7 reglas."},
	# ── Colecciones
	{"id": "cambio_look", "tema": "colecciones", "nombre": "Cambio de look", "icono": "skin-portero", "premio": 5, "cuenta": "",
		"mira": "skin", "desc": "Ponte una skin en la taquilla del vestuario."},
	{"id": "vestuario", "tema": "colecciones", "nombre": "Vestuario completo", "icono": "skin-bombero", "premio": 15, "cuenta": "",
		"mira": "skins", "desc": "Consigue todas las skins de Johnny."},
	{"id": "naturalista", "tema": "colecciones", "nombre": "Naturalista", "icono": "colecciones", "premio": 15, "cuenta": "",
		"mira": "bestiario", "desc": "Completa el bestiario: ve a todos los enemigos."},
	{"id": "investigador", "tema": "colecciones", "nombre": "Investigador", "icono": "dosier", "premio": 15, "cuenta": "",
		"mira": "paginas", "desc": "Encuentra todas las páginas del dosier VD-7."},
	{"id": "chatarrero", "tema": "colecciones", "nombre": "Chatarrero", "icono": "mochila", "premio": 5, "cuenta": "",
		"mira": "objetos", "desc": "Coge al menos una vez cada objeto de las Colecciones."},
]
# [/traducir]
# Los apartados del programa Logros del ordenador, en orden
# [traducir]
const TEMAS := {"edificios": "Edificios", "jefes": "Jefes", "combate": "Combate", "armas": "Armas y talentos",
	"supervivientes": "Supervivientes", "sorpresas": "Sorpresas y retos", "colecciones": "Colecciones"}
# [/traducir]

const AL_PRENDER := 5.0   # segundos tras lanzar un molotov en los que sus llamas cuentan para "Pirómano"
const JEFE_RAPIDO := 30.0     # Visto y no visto: los segundos de pelea con el jefe, como mucho
const JEFE_APURADO := 0.1     # Por los pelos: la parte de su vida máxima que le queda a Johnny, como mucho
const EXPRES := 15 * 60.0     # Jornada exprés: los segundos de partida, como mucho
const PRIMER_REPASO := 1.5    # al empezar la partida, lo que tarda el primer repaso del guardado (revisar)
# Los ajustes de las ayudas que quitan los logros (los Tutoriales no: no ayudan a jugar)
const AYUDAS := ["vida_entera", "pistola_sin_fin", "lanzar_solo"]

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
var por_avisar: Array = []     # los nombres de los recién conseguidos que aún no se han avisado (avisar)
var repasar := true       # si se hace el repaso del guardado, revisar (la partida de prueba lo apaga: prueba_comun.gd)
var repasado_en := -1     # con cuántas escrituras iba el guardado en el último repaso (Guardado.escrituras)
var espera := PRIMER_REPASO


func preparar(p: Node) -> void:
	partida = p
	var s := Guardado.cargar()
	muertos_antes = s.muertos - s.muertos_con_ayudas
	armas_usadas = s.logros_cuentas.get("armas", []).duplicate()
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


static func datos(id: String) -> Dictionary:
	for l in LISTA:
		if l.id == id:
			return l
	return {}


# El nombre y la descripción de un logro, y el nombre de un apartado (TEMAS), ya en el idioma del jugador
static func nombre_de(id: String) -> String:
	return Idioma.t(datos(id).get("nombre", ""))


static func desc_de(id: String) -> String:
	return Idioma.t(datos(id).get("desc", ""))


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
		"objetos": return Objetos.NOMBRES.size()
		"paginas": return paginas(Guardado.NUEVO)[1]
		"rama": return Talentos.RAMAS.map(func(r): return puntos_rama(r.id)[1]).min()
		"arbol": return Talentos.LISTA.reduce(func(n, t): return n + t.max, 0)
		"armas": return arsenal().size()
		"reglas": return Reto.REGLAS.size()
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
		"objetos": return s.encontrados.filter(func(id): return id in Objetos.NOMBRES).size()
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
		"reglas": return cuentas.get("reglas", []).filter(func(id): return id in Reto.REGLAS).size()
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


# Cobra el premio de uno conseguido (desde el ordenador). Devuelve los dólares cobrados (0 si no se podía)
static func cobrar(id: String) -> int:
	var l := datos(id)
	var cobrado := [0]
	Guardado.cambiar(func(g):
		if estado(g, id) == "conseguido":
			g.logros[id] = "cobrado"
			g.dolares += l.premio
			cobrado[0] = l.premio)
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


# Uno más en una lista de los logros del guardado ("logros_cuentas": armas, reglas), si no estaba
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
	if Reto.activo:
		cumplir("reto_aceptado")
		apuntar("reglas", Reto.regla)
	else:   # (el reto va sin alerta)
		if Alerta.nivel >= 3:
			cumplir("alerta_naranja")
		if Alerta.nivel >= Alerta.MAX:
			cumplir("alerta_maxima")
	if partida.supervivientes.equipo.any(func(a): return is_instance_valid(a) and a.es_vecino):
		cumplir("buena_compania")
	sumar("victorias")


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
	if not tocado:
		cumplir("intocable")
