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
# Lo monta partida.gd: si Garaje.activo, en lugar de la sala de mantenimiento se genera el garaje (Planta.garaje) y se
# llama a arrancar(). La partida le pregunta a este nodo en tres sitios: al meter un zombi (endurecer), al caer uno
# (al_caer) y al acabar (terminar). Para cambiar los números, se cambian las constantes de aquí abajo.
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

# El reto que se juega (lo pone el menú antes de abrir la partida, como Reto.empezar; quitar(), para una normal)
static var activo := false

var partida: Node
var oleada := 0                  # la que está en marcha (0: aún ninguna)
var superadas := 0               # las que ha terminado
var quedan := 0                  # los durmientes de la oleada que aún no han salido
var jefe_pendiente := ""         # el jefe de la oleada, si aún no ha salido
var hubo_jefe := false           # si en la oleada de ahora salió un jefe (el descanso, más largo)
var descanso := -1.0             # lo que falta para la siguiente (-1: en plena oleada)
var en_marcha := false


static func empezar() -> void:
	activo = true


static func quitar() -> void:
	activo = false


func preparar(p: Node) -> void:
	partida = p
	name = "Garaje"   # no-tr (nombre de nodo)


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
# para la siguiente. Mientras está el jefe, ahí va su barra (y esto no se ve)
func etiqueta() -> String:
	if not activo or not en_marcha:
		return ""
	if descanso >= 0.0:
		return " · " + (Idioma.t("Siguiente oleada en %d") % ceili(descanso) if oleada > 0
			else Idioma.t("La primera oleada llega en %d") % ceili(descanso))
	return " · " + Idioma.t("Oleada %d / %d") % [oleada, OLEADAS]


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
# las armas que lleva, al baúl, como siempre; la mochila, solo si gana. Y el cartel del final con las oleadas superadas
func terminar(gano: bool, abandona: bool) -> void:
	en_marcha = false
	if abandona:
		Sonido.musica("")
	else:
		Sonido.jingle(gano)
	var equipo: Array = partida.equipo_encima()
	var rotas := []
	var dolares: int = partida.dolares
	var s := Guardado.cambiar(func(g):
		g.muertos += partida.muertos
		for id in partida.matados:
			g.matados[id] = int(g.matados.get(id, 0)) + partida.matados[id]
		rotas.append_array(Objetos.cerrar_baul(g, equipo))
		if gano:
			for id in partida.mochila:
				g.baul[id] = g.baul.get(id, 0) + 1
		g.dolares = mini(g.dolares + dolares, partida.TOPE)
		g.dolares_total += dolares)
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
		"muertos": partida.muertos,
		"tiempo": "%d:%02d" % [int(partida.duracion) / 60, int(partida.duracion) % 60],   # no-tr
		"dolares": dolares,
		"cartera": s.dolares,
		"asesino": "" if gano else partida.johnny.golpe_de,
		"conseguido": partida.conseguido(Guardado.cargar()) + partida.filas_rotas(rotas),
	})
