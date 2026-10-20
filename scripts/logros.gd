# Los logros: retos que se ven en el ordenador de la sala de mantenimiento (programa "Logros"), para que el
# jugador elija cuál intentar en cada partida. Al cumplir uno sale un aviso; el premio (dólares) se cobra en el
# ordenador.
# Para añadir uno: una línea más en LISTA y, si hace falta, su aviso en el sitio del juego donde pasa la cosa
# (partida.gd llama a cumplir("id") o a las funciones de abajo).
# En el guardado (Guardado: "logros") solo se apunta el estado de cada uno: {"id": "conseguido" | "cobrado"}.
# Lo que no está, sigue pendiente.
class_name Logros
extends Node

# "meta": cuántas veces hay que hacerlo (sale con barra de progreso si es más de 1).
# "cuenta": "partida" (en una sola partida), "total" (sumando todas) o "" (basta con hacerlo una vez)
const LISTA := [
	{"id": "primer_turno", "nombre": "Primer turno", "icono": "apartamentos", "premio": 5, "meta": 1, "cuenta": "",
		"desc": "Limpia tu primer apartamento."},
	{"id": "fregona_oro", "nombre": "Fregona de oro", "icono": "fregona", "premio": 10, "meta": 10, "cuenta": "partida",
		"desc": "Mata 10 zombis a fregonazos en una misma partida."},
	{"id": "exterminador", "nombre": "Exterminador", "icono": "zombi", "premio": 15, "meta": 100, "cuenta": "total",
		"desc": "Mata 100 zombis, sumando todas tus partidas."},
	{"id": "sube_conserje", "nombre": "Sube, conserje", "icono": "escalera", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Llega a la planta 3."},
	{"id": "desahucio", "nombre": "Desahucio", "icono": "jefe", "premio": 20, "meta": 1, "cuenta": "",
		"desc": "Derrota a la portera."},
	{"id": "buen_vecino", "nombre": "Buen vecino", "icono": "corazon", "premio": 15, "meta": 1, "cuenta": "",
		"desc": "Rescata a un superviviente: aguanta la horda mientras fuerza la cerradura."},
	{"id": "manitas", "nombre": "Manitas", "icono": "herramientas", "premio": 10, "meta": 1, "cuenta": "",
		"desc": "Crea un arma en el banco de trabajo."},
	{"id": "piromano", "nombre": "Pirómano", "icono": "molotov", "premio": 15, "meta": 5, "cuenta": "partida",
		"desc": "Prende fuego a 5 zombis con un mismo molotov."},
	{"id": "intocable", "nombre": "Intocable", "icono": "reflejos", "premio": 25, "meta": 1, "cuenta": "",
		"desc": "Pasa una planta entera, de la llegada a las escaleras, sin perder vida."},
	{"id": "fin_jornada", "nombre": "Fin de la jornada", "icono": "trofeo", "premio": 50, "meta": 1, "cuenta": "",
		"desc": "Gana una partida: limpia el edificio de arriba abajo."},
]

const AL_PRENDER := 5.0   # segundos tras lanzar un molotov en los que sus llamas cuentan para "Pirómano"

var partida: Node
var muertos_antes := 0    # zombis matados en otras partidas (para "Exterminador")
var fregonazos := 0       # zombis matados con la fregona en esta partida
var prendidos := 0        # zombis prendidos por el último molotov
var molotov_t := 0.0      # segundos que le quedan al último molotov para contar
var tocado := false       # si Johnny ha perdido vida en esta planta
var vida_antes := 0


func preparar(p: Node) -> void:
	partida = p
	muertos_antes = Guardado.cargar().muertos
	p.johnny.vida_cambiada.connect(func(vida, _maxima):
		if vida < vida_antes:
			tocado = true
		vida_antes = vida)


func _process(delta: float) -> void:
	molotov_t = maxf(0.0, molotov_t - delta)


static func datos(id: String) -> Dictionary:
	for l in LISTA:
		if l.id == id:
			return l
	return {}


# "pendiente", "conseguido" (falta cobrarlo) o "cobrado"
static func estado(s: Dictionary, id: String) -> String:
	return s.logros.get(id, "pendiente")


# Lo que lleva hecho de los que tienen meta (para la barra del ordenador)
func progreso(id: String) -> int:
	match id:
		"fregona_oro": return fregonazos
		"piromano": return prendidos
		"exterminador": return muertos_antes + (partida.muertos if partida else 0)
	return 0


# Cumplido: se apunta en el guardado y sale el aviso (si ya estaba, no pasa nada)
func cumplir(id: String) -> void:
	if partida == null:
		return
	var s := Guardado.cargar()
	if estado(s, id) != "pendiente":
		return
	Guardado.cambiar(func(g): g.logros[id] = "conseguido")
	Sonido.tocar("limpio")
	var l := datos(id)
	var johnny: Node2D = partida.johnny
	Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(-70, -90), "¡LOGRO!", Color("#e8b923"), 22)
	partida.decir("¡Logro conseguido: %s! Cobra el premio en el ordenador" % l.nombre, 4.0)


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


# ── Los avisos que da la partida ──

# Un zombi ha caído: "fregona", si Johnny llevaba la fregona en la mano (y no murió quemado)
func zombi_muerto(fregona: bool) -> void:
	if fregona:
		fregonazos += 1
		if fregonazos >= datos("fregona_oro").meta:
			cumplir("fregona_oro")
	if progreso("exterminador") >= datos("exterminador").meta:
		cumplir("exterminador")


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
