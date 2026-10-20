# Lo que hacen las armas creadas (fase 7b2; src/armas-creadas.js del JS). Sus números están en Armas.CREADAS;
# aquí, sus efectos:
#   - Cuerpo a cuerpo, al golpear: aturdir, prender, hacer sangrar, envenenar o la descarga que salta a otro
#     zombi. Los jefes (la portera) no se aturden ni arden; sangrar y el veneno sí les hacen daño.
#   - A distancia: las gotas de fuego o ácido (chorro.gd) y el bumerán (bumeran.gd).
#   - Las chispitas de color en la punta del arma que lleva Johnny.
class_name ArmasCreadas

const CHORRO := preload("res://scripts/chorro.gd")
const BUMERAN := preload("res://scripts/bumeran.gd")
const CHARCO := preload("res://escenas/armas/charco.tscn")
const EMPUJE := 170.0   # empuje base, como el de las balas

# Números de los efectos (provisionales, como EFECTOS en el JS)
const EFECTOS := {
	"aturde": 0.6,                                                   # segundos aturdido (el aplastacabezas)
	"sangra": {"t": 3.0, "total": 0.6, "color": Color("#ff4d6d")},   # dura 3 s y quita en total el 60 % del golpe
	"veneno": {"t": 4.0, "total": 1.0, "color": Color("#9be564")},   # dura 4 s y quita en total otro golpe entero
	"acido": {"t": 3.0, "total": 3.0, "color": Color("#c7e04a")},    # el ácido sigue royendo: el triple de una gota
	"descarga": {"aturde": 1.0, "salto": 130.0, "dano": 0.5},        # aturde 1 s y salta al más cercano con medio daño
	"tick": 0.5,                                                     # cada cuánto se quitan los pellizcos
}
const ACIDO_CHARCO := 0.6   # cada cuánto puede dejar el desintegrador un charco de ácido

static var acido_espera := 0   # cuándo (en milisegundos) puede salir el siguiente charco de ácido


# Lo que hace un arma creada cuerpo a cuerpo al golpear a un zombi (lo llama golpear de johnny.gd)
static func efecto_golpe(zombi: Node2D, w: Dictionary, dano: float) -> void:
	if not zombi.is_in_group("zombis"):   # ya está muerto
		return
	match w.get("efecto", ""):
		"aturde":
			aturdir(zombi, EFECTOS.aturde)
		"fuego":
			prender(zombi)
		"sangra", "veneno":
			herir(zombi, w.efecto, dano)
		"descarga":
			aturdir(zombi, EFECTOS.descarga.aturde)
			# salta al zombi más cercano
			var otro: Node2D = null
			var mejor: float = EFECTOS.descarga.salto
			for o in zombi.get_tree().get_nodes_in_group("zombis"):
				var d: float = o.global_position.distance_to(zombi.global_position)
				if o != zombi and d < mejor:
					mejor = d
					otro = o
			if otro:
				rayo(zombi, zombi.global_position + Vector2(0, -40), otro.global_position + Vector2(0, -40))
				var hacia := (otro.global_position - zombi.global_position).normalized()
				otro.recibir_golpe(roundi(dano * EFECTOS.descarga.dano), hacia * EMPUJE * 0.5)
				aturdir(otro, EFECTOS.descarga.aturde)


# Se queda quieto echando chispitas amarillas (como con la mutación Tentacular). Los jefes, no
static func aturdir(zombi: Node2D, t: float) -> void:
	if zombi is Zombi and zombi.is_in_group("zombis"):
		zombi.aturdido = maxf(zombi.aturdido, t)


# Lo prende como el molotov. Los jefes no arden
static func prender(zombi: Node2D) -> void:
	if zombi is Zombi and zombi.is_in_group("zombis"):
		zombi.prender()


# Sangrar, veneno o ácido: quita poco a poco una parte del golpe (con cada golpe vuelve a empezar)
static func herir(zombi: Node2D, tipo: String, dano: float) -> void:
	if not zombi.is_in_group("zombis") or not zombi.has_method("herir"):
		return
	var ef: Dictionary = EFECTOS[tipo]
	var h: Herida = zombi.get_node_or_null("herida_" + tipo)
	if h == null:
		h = Herida.new()
		h.name = "herida_" + tipo
		h.color = ef.color
		zombi.add_child(h)
	h.t = ef.t
	h.dps = dano * ef.total / ef.t


# El rayo de la descarga: una línea en zigzag de puntitos azules y blancos
static func rayo(desde: Node, a: Vector2, b: Vector2) -> void:
	var n := maxi(4, roundi(a.distance_to(b) / 8.0))
	for i in n + 1:
		var lado := 1.0 if i % 2 else -1.0
		var p := a.lerp(b, float(i) / n) + Vector2(lado * randf_range(2, 6), lado * randf_range(2, 6))
		Particulas.soltar(desde, p, Vector2.ZERO, Color("#9fe8ff") if i % 3 else Color.WHITE, 3, 0.2)


# Las chispitas en la punta del arma creada que lleva Johnny (más o menos donde la lleva el dibujo)
static func detalle(johnny: Node2D, w: Dictionary, delta: float) -> void:
	if not w.has("detalle") or randf() > 14.0 * delta:
		return
	var mira := Vector2.from_angle(johnny.DIRS.find(johnny.direccion) * PI / 4)
	var donde: Vector2 = johnny.global_position + Vector2(mira.x * 26.0, -8.0 + mira.y * 16.0) + Vector2(randf_range(-5, 5), randf_range(-5, 5))
	var sube: bool = w.get("sube", false)
	Particulas.soltar(johnny, donde, Vector2(randf_range(-12, 12), randf_range(-55, -30) if sube else randf_range(20, 45)), w.detalle, 2, 0.35)


# ── A distancia ──

# Disparo de un arma creada a distancia desde la boca del arma. Las tres de chorro sueltan gotas de fuego o
# ácido que atraviesan a los zombis; el bumerán sale una vez y vuelve a la mano
static func disparar(johnny: Node2D, angulo: float, w: Dictionary, salida: Vector2) -> void:
	var sala: Node = johnny.get_parent()
	if w.efecto == "bumeran":
		var b := BUMERAN.new()
		b.johnny = johnny
		b.angulo = angulo
		b.dano = w.dano
		b.empuje = w.empuje
		b.alcance = w.alcance
		b.velocidad = w.velocidad
		sala.add_child(b)
		b.global_position = salida
		return
	var cono: bool = w.efecto == "cono"
	var n := 9 if cono else 1
	var abertura := 0.9 if cono else 0.14
	for i in n:
		var a := angulo + randf_range(-0.05, 0.05) if cono else angulo + (randf() - 0.5) * abertura
		if cono:
			a += (float(i) / (n - 1) - 0.5) * abertura
		var g := CHORRO.new()
		g.tipo = w.efecto
		g.velocidad = Vector2.from_angle(a) * w.velocidad * randf_range(0.85, 1.15)
		g.dano = w.dano
		g.empuje = w.empuje
		g.radio = 10.0 if cono else 8.0
		g.vida_max = w.alcance / w.velocidad
		sala.add_child(g)
		g.global_position = salida
	if w.efecto != "acido":
		Luz.destello(johnny, salida - Vector2(0, 50), 170.0 if cono else 120.0, 0.08)


# Lo que pasa cuando una gota o el bumerán toca a un zombi
static func golpe(zombi: Node2D, hacia: Vector2, dano: float, empuje: float, tipo: String) -> void:
	var johnny := zombi.get_tree().get_first_node_in_group("jugador")
	var d: int = johnny.con_critico(dano) if johnny else roundi(dano)
	zombi.recibir_golpe(d, hacia.normalized() * EMPUJE * empuje)
	if not zombi.is_in_group("zombis"):
		return
	if tipo == "llama" or tipo == "cono":
		prender(zombi)
	elif tipo == "acido":
		herir(zombi, "acido", d)
		# de vez en cuando, un charco de ácido a sus pies (el de Gastroenteritis: solo daña a los zombis)
		if Time.get_ticks_msec() >= acido_espera:
			acido_espera = Time.get_ticks_msec() + roundi(ACIDO_CHARCO * 1000)
			var charco := CHARCO.instantiate()
			charco.tipo = "vomito"
			charco.position = (zombi.position / 2.0).round() * 2.0 + Vector2(0, zombi.radio * 0.5)
			zombi.get_parent().add_child(charco)


# Sangrar, veneno o ácido en un zombi: va de hijo suyo, le quita vida a pellizcos y le hace gotear
class Herida extends Node:
	var t := 0.0
	var dps := 0.0
	var color := Color.WHITE
	var tick := 0.0

	func _physics_process(delta: float) -> void:
		var zombi: Node2D = get_parent()
		if not zombi.is_in_group("zombis"):
			queue_free()
			return
		t -= delta
		tick += delta
		if randf() < 6.0 * delta:   # gotitas que caen
			Particulas.soltar(zombi, zombi.global_position + Vector2(randf_range(-10, 10), -40),
				Vector2(randf_range(-15, 15), randf_range(20, 50)), color, 2, 0.4)
		if tick >= ArmasCreadas.EFECTOS.tick:
			tick -= ArmasCreadas.EFECTOS.tick
			zombi.herir(dps * ArmasCreadas.EFECTOS.tick, color)
		if t <= 0.0:
			queue_free()
