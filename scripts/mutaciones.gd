# Mutaciones: mejoras que solo duran una partida (src/mutaciones.js del JS).
#
# Al caer la portera (la mini jefa de cada planta), un segundo después de que su cuerpo llegue al suelo, el
# juego se para y sale un recuadro con dos mutaciones al azar para elegir una (menus.gd: mutacion). Como mucho
# se juntan 4 por partida y nunca se repite una que ya tengas. Se pierden al acabar la partida: no se guardan.
#
# Cada una: o cambia los atributos de Johnny (aplicar), o hace algo ella sola cada pocos segundos ("cada").
# Si no hay a quién hacérselo, no gasta la vez: lo intenta en el siguiente paso.
# Caníbal se cura en partida.gd (al morir un zombi), Ansiedad está en johnny.gd (arma) y el escudo de
# Endurecimiento se pone en cada planta (partida.gd). A la portera no le afectan.
class_name Mutaciones
extends Node

# Los números de cada una (provisionales, los del JS). Tentacular: el empujón los manda a unos 150 de distancia
const MUT := {
	"tentacular": {"cada": 4.0, "radio": 90.0, "empuje": 520.0, "aturde": 1.0},
	"gastro": {"cada": 3.0, "alcance": 420.0},
	"insensible": {"dano": 0.5},
	"canibal": {"cura": 0.05},
	"endurecimiento": {"escudo": 80},
	"locura": {"cada": 5.0, "radio": 140.0, "lio": 2.0},
	"flatulento": {"cada": 3.0, "radio": 70.0, "dps": 10.0, "paraliza": 2.0},
}
const MAXIMO := 4
const LISTA := [
	{"id": "tentacular", "nombre": "Tentacular", "icono": "dash",
		"desc": "Cada 4 s te sale un tentáculo del pecho que aparta a los zombis de alrededor y los aturde 1 s"},
	{"id": "gastro", "nombre": "Gastroenteritis", "icono": "molotov",
		"desc": "Cada 3 s le lanzas un vómito de ácido al zombi más cercano: deja un charco que quema a los zombis que lo pisan"},
	{"id": "insensible", "nombre": "Insensible", "icono": "casco",
		"desc": "Pierdes la sensibilidad del cuerpo: recibes la mitad de daño"},
	{"id": "canibal", "nombre": "Caníbal", "icono": "corazon",
		"desc": "Cada zombi que matas te cura un 5 % de la vida"},
	{"id": "ansiedad", "nombre": "Ansiedad", "icono": "cafe",
		"desc": "Golpeas más rápido cuerpo a cuerpo cuantos más zombis tengas a la vista (+5 % cada uno, hasta +50 %)"},
	{"id": "endurecimiento", "nombre": "Endurecimiento", "icono": "fuerza",
		"desc": "La piel se endurece: escudo de 80 en cada planta que para la mitad de cada golpe hasta gastarse"},
	{"id": "locura", "nombre": "Locura", "icono": "jefe",
		"desc": "Cada 5 s gritas tan fuerte que los zombis de alrededor se desorientan 2 s"},
	{"id": "flatulento", "nombre": "Flatulento", "icono": "herramientas",
		"desc": "Cada 3 s sueltas gases corrosivos que queman y paralizan 2 s a los zombis cercanos"},
]
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")

var johnny: Node2D
var tengo: Array = []      # las de esta partida
var espera := {}           # lo que le falta a cada una para actuar otra vez


static func mutacion(id: String) -> Dictionary:
	for m in LISTA:
		if m.id == id:
			return m
	return {}


# Dos al azar entre las que aún no tienes
func sortear(n := 2) -> Array:
	var quedan := LISTA.filter(func(m): return not m.id in tengo)
	quedan.shuffle()
	return quedan.slice(0, n)


# Lo que cambian en los atributos (después de los talentos)
static func aplicar(st: Dictionary, ids: Array) -> Dictionary:
	for id in ids:
		match id:
			"insensible": st.dano_recibido *= MUT.insensible.dano
			"canibal": st.canibal = MUT.canibal.cura
			"ansiedad": st.ansiedad = true
			"endurecimiento": st.escudo_mut = MUT.endurecimiento.escudo
	return st


func _physics_process(delta: float) -> void:
	if johnny == null or not johnny.vivo:
		return
	for id in tengo:
		if not MUT.has(id) or not MUT[id].has("cada"):
			continue
		espera[id] = espera.get(id, MUT[id].cada) - delta
		if espera[id] > 0.0:
			continue
		espera[id] = MUT[id].cada if actuar(id) else 0.0


# Zombis (no la portera) que están a menos de "r" de Johnny
func cerca(r: float) -> Array:
	var p: Vector2 = johnny.global_position
	return get_tree().get_nodes_in_group("zombis").filter(func(z): return z is Zombi and not z.dormido and p.distance_to(z.global_position) < r + z.radio)


# Lo que hace cada una; devuelve si lo ha hecho (sin nadie cerca no lo gasta)
func actuar(id: String) -> bool:
	var m: Dictionary = MUT[id]
	var p: Vector2 = johnny.global_position
	match id:
		"tentacular":
			var zs := cerca(m.radio)
			if zs.is_empty():
				return false
			for z in zs:
				z.velocity = p.direction_to(z.global_position) * m.empuje * z.empuje
				z.aturdido = maxf(z.aturdido, m.aturde)
			Particulas.anillo(johnny, p, m.radio, Color("#b5179e"))
		"gastro":
			# al zombi (o la portera) más cercano que no esté a oscuras
			var objetivo: Node2D = null
			var mejor: float = m.alcance
			var mapa := get_tree().get_first_node_in_group("mapa")
			for z in get_tree().get_nodes_in_group("zombis"):
				var d := p.distance_to(z.global_position)
				if d < mejor and not (mapa and mapa.oculto(z.global_position)):
					mejor = d
					objetivo = z
			if objetivo == null:
				return false
			var vomito := PROYECTIL.instantiate()
			vomito.tipo = "vomito"
			vomito.desde = p
			vomito.alto_salida = 30.0
			vomito.hasta = objetivo.global_position + Vector2(0, objetivo.radio * 0.5)
			johnny.get_parent().add_child(vomito)
		"locura":
			var zs := cerca(m.radio)
			if zs.is_empty():
				return false
			for z in zs:
				z.liado = maxf(z.liado, m.lio)
				z.lio_angulo = randf() * TAU
			Particulas.anillo(johnny, p, m.radio, Color("#ffd23f"))
			Zombi.texto_flotante(johnny.get_parent(), p + Vector2(-50, -100), "¡AAAAAH!", Color("#ffd23f"), 22)
		"flatulento":
			var zs := cerca(m.radio)
			if zs.is_empty():
				return false
			for z in zs:
				z.aturdido = maxf(z.aturdido, m.paraliza)
				Estados.poner(z.estados, "gases", m.paraliza, m.dps)   # el daño va como un estado, poco a poco
			# la nube de gases
			for i in 14:
				var a := randf() * TAU
				var v: float = randf_range(0.6, 1.1) * m.radio * 1.6
				Particulas.soltar(johnny, p + Vector2(0, 8), Vector2(cos(a) * v, sin(a) * v * 0.7 - 20.0),
					[Color("#b5c94a"), Color("#8a9a3a"), Color("#d8e07a")][i % 3], randf_range(4, 8), 0.6)
		_:
			return false
	return true
