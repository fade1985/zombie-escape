# El garaje subterráneo (M125, el reto del día nuevo; 16 nov): un solo sitio grande, como la azotea, con columnas y
# coches, y el baúl en el centro. Ahí van saliendo 25 oleadas de durmientes, cada una más dura que la anterior, y cada 5
# también un jefe (un «sonámbulo») del edificio: los cuatro minijefes en su orden y, en la 25, el jefe final.
#
# Cómo va una oleada: salen sus durmientes, ya despiertos, lejos de Johnny (como mucho A_LA_VEZ a la vez: los demás
# esperan y salen según caen los de delante). Se acaba al matar al último durmiente o sonámbulo, y entonces da tantos
# dólares como su número (la 1, $1; la 25, $25). Luego, DESCANSO segundos hasta la siguiente (DESCANSO_JEFE si en ella
# salió un jefe). Los durmientes no sueltan dólares ni mutágeno: solo munición, a veces (MUNICION), para que no se
# acabe nunca. Los dólares se los lleva Johnny siempre: ganando, cayendo o abandonando (terminar).
#
# Cada día, además, una condición (CONDICIONES): una familia de cosas que ese día no vale (no se puede equipar ni sacar
# del baúl, y si ya la llevas, no se puede usar: prohibido()). Sale de la fecha, así que es la misma para todo el mundo y
# en los tres edificios. Se juega una vez al día en cada edificio (el intento se gasta al entrar, gastar()), y se apunta
# el récord de oleadas de cada edificio con cada condición, aparte (en el guardado, "garajes": Guardado.GARAJE).
#
# Se entra por el botón «Reto del día» de cada tarjeta de «Elige edificio» (menu_principal.gd: empezar() antes de abrir
# la partida, quitar() para una normal). Lo monta partida.gd: si Garaje.activo, en lugar de la sala de mantenimiento se
# genera el garaje (Planta.garaje) y se llama a arrancar(). La partida le pregunta a este nodo en tres sitios: al meter un
# zombi (endurecer), al caer uno (al_caer) y al acabar (terminar). Para cambiar los números, se cambian las constantes de
# aquí abajo. (Hasta el 16 nov el reto del día era otro: un edificio entero con una regla rara, reto.gd, ya quitado)
class_name Garaje
extends Node

const OLEADAS := 25
const CADA_JEFE := 5             # cada 5 oleadas, también un jefe
const PRIMERA := 4               # los durmientes de la oleada 1...
const MAS_POR_OLEADA := 2        # ...y cuántos más en cada una (la 25, 52)
const A_LA_VEZ := 18             # como mucho, tantos vivos a la vez (la web no aguanta más; los demás esperan su turno)
const DESDE := 6                 # desde esta oleada, los durmientes se endurecen...
const MAS_VIDA := 0.06           # ...un 6 % más de vida y de zarpazo por oleada (la 25, el doble)...
const MAS_VELOCIDAD := 0.02      # ...y un 2 % más rápidos
const JEFE_MAS := 1.25           # cada jefe, un 25 % más de vida que el anterior
const DESCANSO := 5.0            # segundos entre una oleada y la siguiente...
const DESCANSO_JEFE := 10.0      # ...o estos, si en ella salió un jefe
const ESPERA := 3.0              # lo que tarda en salir la primera, al entrar
const MUNICION := 0.10           # lo que tiene cada durmiente de soltar munición al caer
const LEJOS := 380.0             # a cuánto de Johnny salen, como poco

# Las condiciones del día: cada día toca una (condicion_de). "nombre" sale en el cuadro del botón, arriba en la partida y
# en el cartel del final; "desc", en el cuadro del botón. La clave es la familia que no vale (familia())
# [traducir]
const CONDICIONES := {
	"cuerpo": {"nombre": "Sin cuerpo a cuerpo", "desc": "Hoy no vale ningún arma cuerpo a cuerpo, ni siquiera la fregona."},
	"distancia": {"nombre": "Sin armas a distancia", "desc": "Hoy no vale ningún arma a distancia: ni la pistola, ni la escopeta, ni las demás."},
	"especial": {"nombre": "Sin armas especiales", "desc": "Hoy no valen las armas especiales: las que echan fuego, ácido, hielo o rayos."},
	"lanzables": {"nombre": "Sin lanzables", "desc": "Hoy no vale nada que se lance: ni molotovs, ni granadas, ni los demás."},
	"curas": {"nombre": "Sin curas", "desc": "Hoy no valen las vendas ni los botiquines."},
}
# [/traducir]

# El reto que se juega (lo pone el menú antes de abrir la partida: empezar; quitar(), para una normal), de qué día
# ("2026-11-16") y su condición (una clave de CONDICIONES)
static var activo := false
static var fecha := ""
static var condicion := ""
static var avisado := -10000     # cuándo salió el último «hoy no vale» (en milisegundos: uno por segundo, como mucho)

var partida: Node
var oleada := 0                  # la que está en marcha (0: aún ninguna)
var superadas := 0               # las que ha terminado
var quedan := 0                  # los durmientes de la oleada que aún no han salido
var jefe_pendiente := ""         # el jefe de la oleada, si aún no ha salido
var hubo_jefe := false           # si en la oleada de ahora salió un jefe (el descanso, más largo)
var descanso := -1.0             # lo que falta para la siguiente (-1: en plena oleada)
var en_marcha := false


# El día de hoy, como se escribe en el guardado
static func hoy() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


# La condición que toca un día: sale de la fecha, así que es la misma para todo el mundo (y en los tres edificios)
static func condicion_de(dia: String) -> String:
	var claves := CONDICIONES.keys()
	return claves[("garaje-" + dia).hash() % claves.size()]


# «Elige edificio» lo llama antes de abrir la partida del garaje de hoy. En las pruebas, "--condicion X" fuerza esa
static func empezar(dia := hoy()) -> void:
	activo = true
	fecha = dia
	condicion = condicion_de(dia)
	if Captura.activa() and Captura.dato("--condicion") in CONDICIONES:
		condicion = Captura.dato("--condicion")


# ...o esto, para una partida normal
static func quitar() -> void:
	activo = false
	fecha = ""
	condicion = ""


static func nombre(c := condicion) -> String:
	return Idioma.t(CONDICIONES[c].nombre) if c in CONDICIONES else ""


static func desc(c := condicion) -> String:
	return Idioma.t(CONDICIONES[c].desc) if c in CONDICIONES else ""


# ── Lo prohibido ──

# La familia de algo, para las condiciones: un arma, la suya (Armas.familia: "cuerpo", "distancia" o "especial"); un
# lanzable (su id o su clave con la calidad, "molotov:2"), "lanzables"; las vendas y el botiquín, "curas"; lo demás, ""
static func familia(id: String) -> String:
	if Armas.DATOS.has(id):
		return Armas.familia(id)
	if Lanzables.DATOS.has(Lanzables.tipo_de(id)):
		return "lanzables"
	if id in Objetos.USABLES:
		return "curas"
	return ""


# ¿Hoy no vale? Lo miran el baúl y el inventario (no se saca ni se pone en la mano), Johnny al atacar, los lanzables al
# lanzar y la partida al curar (partida.usar_objeto)
static func prohibido(id: String) -> bool:
	return activo and condicion != "" and familia(id) == condicion


# Lo que se dice al intentar sacar, poner o usar algo prohibido
static func no_vale() -> String:
	return Idioma.t("Hoy no vale en el garaje: %s.") % nombre()


# Al intentar usar algo prohibido en plena pelea: «¡Hoy no vale!» encima de Johnny (uno por segundo, como mucho)
static func avisar(johnny: Node2D) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - avisado < 1000:
		return
	avisado = ahora
	Sonido.tocar("no")
	Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(-60, -80), Idioma.t("¡Hoy no vale!"),
		Tema.ROJO, 18)


# ── El guardado: una vez al día en cada edificio, y el récord de cada condición ──

# La ficha del garaje de un edificio (Guardado.GARAJE), creada si aún no la hay
static func ficha(s: Dictionary, edificio: String) -> Dictionary:
	if not edificio in s.garajes:
		s.garajes[edificio] = Guardado.GARAJE.duplicate(true)
	return s.garajes[edificio]


# Si ese edificio ya ha jugado el garaje ese día (el intento se gasta al entrar: gastar)
static func jugado(s: Dictionary, edificio: String, dia := hoy()) -> bool:
	return s.garajes.has(edificio) and s.garajes[edificio].fecha == dia


# El récord de un edificio con una condición: las oleadas superadas (0, ninguna)
static func record(s: Dictionary, edificio: String, c: String) -> int:
	return int(s.garajes[edificio].records.get(c, 0)) if s.garajes.has(edificio) else 0


# Lo de debajo del botón: «Récord: 3 oleadas»
static func texto_record(n: int) -> String:
	return Idioma.n("Récord: %d oleada", "Récord: %d oleadas", n) % n


func preparar(p: Node) -> void:
	partida = p
	name = "Garaje"   # no-tr (nombre de nodo)


# Al entrar en el garaje (partida.empezar_garaje): el intento de hoy de este edificio, gastado, aunque se caiga en la
# primera oleada o se salga al menú
func gastar() -> void:
	var edificio: String = partida.edificio
	Guardado.cambiar(func(g): ficha(g, edificio).fecha = fecha)


# Johnny ya está en el garaje: la primera oleada, al rato
func arrancar() -> void:
	en_marcha = true
	descanso = ESPERA


func _physics_process(delta: float) -> void:
	if not en_marcha or partida.terminada or partida.cambiando or not partida.johnny.vivo:
		return
	partida.rescatar_atascados(delta)   # (el garaje va como «limpio» para la partida: esto lo hace aquí)
	if descanso >= 0.0:
		descanso -= delta
		if descanso < 0.0:
			nueva_oleada()
		return
	# los que esperan su turno salen según caen los de delante
	var vivos := vivos_ahora()
	while quedan > 0 and vivos < A_LA_VEZ:
		soltar(tipos(oleada).pick_random())
		quedan -= 1
		vivos += 1
	if quedan == 0 and jefe_pendiente == "" and vivos == 0:
		oleada_superada()


func vivos_ahora() -> int:
	return partida.get_tree().get_nodes_in_group("zombis").size()


func nueva_oleada() -> void:
	oleada += 1
	descanso = -1.0
	quedan = durmientes(oleada)
	hubo_jefe = false
	jefe_pendiente = jefe_de(oleada)
	partida.gran_aviso(Idioma.t("OLEADA %d") % oleada)
	Sonido.tocar("rugido")
	if jefe_pendiente != "":
		hubo_jefe = true
		sacar_jefe.call_deferred()


# El jefe de la oleada sale en un extremo del garaje, con su barra de vida y su nombre (partida.meter_zombi)
func sacar_jefe() -> void:
	var tipo := jefe_pendiente
	partida.jefa = partida.meter_zombi(tipo, partida.mapa.punto_libre(partida.johnny.position, LEJOS))
	partida.jefa_salio = true
	jefe_pendiente = ""
	Sonido.tocar("jefe")
	Sonido.musica("jefe")


func oleada_superada() -> void:
	superadas = oleada
	var n: int = partida.sumar_dolares(oleada)   # la oleada N da N dólares
	partida.numero(partida.johnny.position + Vector2(0, -90), "+$%d" % n, Tema.VERDE)
	Sonido.tocar("limpio")
	if hubo_jefe:
		Sonido.musica("menu")
	if oleada >= OLEADAS:
		en_marcha = false
		partida.gran_aviso(Idioma.t("¡GARAJE SUPERADO!"))
		await partida.get_tree().create_timer(2.0, false).timeout
		partida.terminar(true)
		return
	descanso = DESCANSO_JEFE if hubo_jefe else DESCANSO


# Lo que se añade al nombre del sitio, arriba del todo (partida.gd, poner_lugar): la oleada en la que va o lo que falta
# para la siguiente, y la condición del día. Mientras está el jefe, ahí va su barra (y esto no se ve)
func etiqueta() -> String:
	if not activo or not en_marcha:
		return ""
	var cond := " · " + nombre() if condicion != "" else ""
	if descanso >= 0.0:
		return " · " + (Idioma.t("Siguiente oleada en %d") % ceili(descanso) if oleada > 0
			else Idioma.t("La primera oleada llega en %d") % ceili(descanso)) + cond
	return " · " + Idioma.t("Oleada %d / %d") % [oleada, OLEADAS] + cond


# ── Lo que trae cada oleada ──

static func durmientes(n: int) -> int:
	return PRIMERA + MAS_POR_OLEADA * (n - 1)


# El jefe de la oleada n ("" si no toca): en la 5, 10, 15 y 20, los cuatro minijefes del edificio, en su orden; en la
# 25, el jefe final. Si alguno aún no tiene su escena, el de relleno del edificio (la portera)
func jefe_de(n: int) -> String:
	if n % CADA_JEFE != 0:
		return ""
	var k := n / CADA_JEFE
	var ed: Dictionary = partida.ed
	var tipo: String = ed.final if k > ed.minijefes.size() else ed.minijefes[k - 1]
	return tipo if partida.ZOMBIS.has(tipo) else ed.jefe


# Qué durmientes salen: primero los lentos y los normales, y cada pocas oleadas, peores (y los del edificio)
func tipos(n: int) -> Array:
	var lista := ["lento", "normal", "normal"]
	if partida.ed.generador == "apartamento":
		lista.append("vecina")
	if n >= 3:
		lista += ["rapido", "rapido"]
	if n >= 7:
		lista += ["explosivo", "venenoso"]
	if n >= 9:
		match partida.ed.generador:
			"tienda": lista.append("vigilante")
			"departamento": lista += ["oficinista", "escolta"]
	if n >= 12:
		lista.append("tentaculos")
	return lista


func soltar(tipo: String) -> void:
	var donde: Vector2 = partida.mapa.punto_libre(partida.johnny.position, LEJOS)
	var z: Node2D = partida.meter_zombi(tipo, donde)
	z.zona = partida.mapa.zona_en(donde)


# ── Lo que pregunta la partida ──

# Al meter un zombi (partida.meter_zombi, antes de ponerlo en el mapa: su vida sale de vida_max al entrar): desde la
# oleada DESDE, los durmientes más duros y rápidos; los jefes, cada uno JEFE_MAS más de vida que el anterior
func endurecer(zombi: Node2D, tipo: String) -> void:
	if not activo:
		return
	if tipo in partida.JEFES:
		zombi.vida_max = int(zombi.vida_max * pow(JEFE_MAS, maxi(0, oleada / CADA_JEFE - 1)))
		return
	var pasos := maxi(0, oleada - DESDE + 1)
	if pasos == 0:
		return
	if "vida_max" in zombi:
		zombi.vida_max = roundi(zombi.vida_max * (1.0 + MAS_VIDA * pasos))
	if "dano" in zombi:
		zombi.dano = roundi(zombi.dano * (1.0 + MAS_VIDA * pasos))
	if "velocidad" in zombi:
		zombi.velocidad *= 1.0 + MAS_VELOCIDAD * pasos


# Al caer un zombi (partida.meter_zombi, ya contado): su sangre y, a veces, munición de las armas que lleva. Nada más:
# ni dólares, ni mutágeno, ni mutaciones, ni el helicóptero del jefe final
func al_caer(zombi: Node2D, tipo: String) -> void:
	partida.sangre(tipo, zombi)
	if tipo in partida.JEFES:
		partida.jefa = null
		return
	if randf() < MUNICION:
		partida.soltar_municion(zombi.position)


# Al acabar (partida.terminar, en lugar de lo suyo): los dólares de las oleadas, a la cartera ganes, caigas o abandones;
# las armas que lleva, al baúl, como siempre; la mochila, solo si gana; el récord de este edificio con la condición de
# hoy, si lo mejora. Y el cartel del final con las oleadas superadas
func terminar(gano: bool, abandona: bool) -> void:
	en_marcha = false
	if abandona:
		Sonido.musica("")
	else:
		Sonido.jingle(gano)
	var equipo: Array = partida.equipo_encima()
	var rotas := []
	var dolares: int = partida.dolares
	var edificio: String = partida.edificio
	var nuevo := [false]   # (en una lista, para que la función de dentro pueda cambiarlo)
	var s := Guardado.cambiar(func(g):
		var f := ficha(g, edificio)
		if condicion != "" and superadas > int(f.records.get(condicion, 0)):
			nuevo[0] = true
			f.records[condicion] = superadas
		g.muertos += partida.muertos
		for id in partida.matados:
			g.matados[id] = int(g.matados.get(id, 0)) + partida.matados[id]
		rotas.append_array(Objetos.cerrar_baul(g, equipo))
		if gano:
			for id in partida.mochila:
				g.baul[id] = g.baul.get(id, 0) + 1
		g.dolares = mini(g.dolares + dolares, partida.TOPE)
		g.dolares_total += dolares)
	partida.logros.garaje_jugado(condicion, gano)
	partida.logros.revisar()
	if abandona:
		partida.ir_al_menu()
		return
	partida.get_tree().paused = true
	partida.menus.fin({
		"gano": gano,
		"garaje": true,
		"titulo": Idioma.t("¡Garaje superado!") if gano else Idioma.t("¡Derrota!"),
		"sub": Idioma.t("Caíste en la oleada %d del garaje") % maxi(oleada, 1),
		"oleadas": "%d / %d" % [superadas, OLEADAS],
		"condicion": nombre(),
		"record": texto_record(int(s.garajes[edificio].records.get(condicion, 0))),
		"nuevo_record": nuevo[0],
		"muertos": partida.muertos,
		"tiempo": "%d:%02d" % [int(partida.duracion) / 60, int(partida.duracion) % 60],   # no-tr
		"dolares": dolares,
		"cartera": s.dolares,
		"asesino": "" if gano else partida.johnny.golpe_de,
		"conseguido": partida.conseguido(Guardado.cargar()) + partida.filas_rotas(rotas),
	})
