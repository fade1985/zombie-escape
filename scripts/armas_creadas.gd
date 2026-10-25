# Lo que hacen las armas creadas (fase 7b2; src/armas-creadas.js del JS). Sus números están en Armas.CREADAS;
# aquí, sus efectos. Son todas a distancia (las de cuerpo a cuerpo y el garfio se quitaron del juego el 25 oct):
#   - Las chispas de la pistola eléctrica (chorro.gd), que aturden y saltan a otro zombi. La llamarada del
#     lanzallamas y el chorro del lanza ácido van aparte (llamarada.gd).
#   - Lo que dejan en el zombi: la quemadura, el ácido que sigue royendo y la herida que sangra (la de los clavos
#     de la bomba de clavos, granada.gd). Los jefes no se aturden ni arden; sangrar y el ácido sí les hacen daño.
class_name ArmasCreadas

const CHORRO := preload("res://scripts/chorro.gd")
const EMPUJE := 170.0   # empuje base, como el de las balas
# Los efectos de las armas que queman: el lanzallamas (con la skin del bombero, × 3: johnny.gd, arma())
const QUEMAN := ["llama"]

# Números de los efectos (provisionales, como EFECTOS en el JS)
const EFECTOS := {
	"sangra": {"t": 3.0, "total": 0.6, "color": Color("#ff4d6d")},   # dura 3 s y quita en total el 60 % del golpe
	"acido": {"t": 3.0, "total": 3.0, "color": Color("#c7e04a")},    # el ácido sigue royendo: el triple de un pellizco
	"descarga": {"salto": 130.0, "dano": 0.5},                       # salta al más cercano con medio daño
	"chispa": 0.4,                                                   # la pistola eléctrica: cada chispa aturde 0,4 s (y salta)
	"tick": 0.5,                                                     # cada cuánto se quitan los pellizcos
}


# La descarga: aturde al zombi y salta al más cercano (a menos de "salto"), que se lleva medio daño y también
# se queda aturdido. La usan las chispas de la pistola eléctrica
static func descarga(zombi: Node2D, dano: float, aturde: float) -> void:
	aturdir(zombi, aturde)
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
		aturdir(otro, aturde)


# Se queda quieto echando chispitas amarillas (como con la mutación Tentacular). Los jefes, no
static func aturdir(zombi: Node2D, t: float) -> void:
	if zombi is Zombi and zombi.is_in_group("zombis"):
		zombi.aturdido = maxf(zombi.aturdido, t)


# Lo prende como el molotov ("quema": cuánto más arde; la skin del bombero, × 3). Los jefes no arden
static func prender(zombi: Node2D, quema := 1.0) -> void:
	if zombi is Zombi and zombi.is_in_group("zombis"):
		zombi.prender(quema)


# Sangrar o ácido: quita poco a poco una parte del golpe (con cada golpe vuelve a empezar)
static func herir(zombi: Node2D, tipo: String, dano: float) -> void:
	if not zombi.is_in_group("zombis") or not zombi.has_method("herir"):
		return
	var ef: Dictionary = EFECTOS[tipo]
	var h: Herida = zombi.get_node_or_null("herida_" + tipo)
	if h == null:
		h = Herida.new()
		h.name = "herida_" + tipo
		h.color = ef.color
		h.acido = tipo == "acido"
		zombi.add_child(h)
	h.t = ef.t
	h.dps = dano * ef.total / ef.t


# El rayo de la descarga: una línea en zigzag de puntitos azules y blancos
static func rayo(desde: Node, a: Vector2, b: Vector2) -> void:
	Sonido.tocar("click")
	var n := maxi(4, roundi(a.distance_to(b) / 8.0))
	for i in n + 1:
		var lado := 1.0 if i % 2 else -1.0
		var p := a.lerp(b, float(i) / n) + Vector2(lado * randf_range(2, 6), lado * randf_range(2, 6))
		Particulas.soltar(desde, p, Vector2.ZERO, Color("#9fe8ff") if i % 3 else Color.WHITE, 3, 0.2)


# ── A distancia ──

# Disparo de un arma creada a distancia desde la boca del arma: suelta gotas de fuego, ácido o chispas que
# atraviesan a los zombis
static func disparar(johnny: Node2D, angulo: float, w: Dictionary, salida: Vector2) -> void:
	var sala: Node = johnny.get_parent()
	Sonido.tocar({"acido": "escupitajo", "chispa": "chispa"}.get(w.efecto, "fuego"))
	var g := CHORRO.new()
	g.tipo = w.efecto
	g.velocidad = Vector2.from_angle(angulo + (randf() - 0.5) * 0.14) * w.velocidad * randf_range(0.85, 1.15)
	g.dano = w.dano
	g.empuje = w.empuje
	g.quema = w.get("quema", 1.0)
	g.vida_max = w.alcance / w.velocidad
	sala.add_child(g)
	g.global_position = salida
	if w.efecto == "chispa":
		Luz.destello(johnny, salida - Vector2(0, 50), 110.0, 0.06, 1.0, Color("#9fe8ff"))
	elif w.efecto != "acido":
		Luz.destello(johnny, salida - Vector2(0, 50), 120.0, 0.08)


# Lo que pasa cuando una gota o un clavo de la bomba de clavos tocan a un zombi ("quema":
# cuánto más arde el que prende una gota de fuego)
static func golpe(zombi: Node2D, hacia: Vector2, dano: float, empuje: float, tipo: String, quema := 1.0) -> void:
	# al jefe de bomberos (bombero.gd) el fuego no le hace nada: ni el daño ni prenderle
	if tipo == "llama" and zombi.get("inmune_fuego"):
		zombi.prender()
		return
	var johnny := zombi.get_tree().get_first_node_in_group("jugador")
	var d: int = johnny.con_critico(dano) if johnny else roundi(dano)
	zombi.recibir_golpe(d, hacia.normalized() * EMPUJE * empuje)
	if not zombi.is_in_group("zombis"):
		return
	if tipo == "llama":
		prender(zombi, quema)
	elif tipo == "chispa":
		descarga(zombi, d, EFECTOS.chispa)
	elif tipo == "clavo":
		herir(zombi, "sangra", d)
	elif tipo == "acido":
		herir(zombi, "acido", d)


# Sangrar o ácido en un zombi: va de hijo suyo y le quita vida a pellizcos. Sangrar le hace gotear; el ácido, no: lo
# tiñe de verde (a los zombis, zombi.gd, que lo junta con el fuego; a los jefes, aquí). Al jefe de bomberos el ácido
# solo lo tiñe: su herir() es el del fuego de los charcos (la vida se la quita el chorro, llamarada.gd)
class Herida extends Node:
	var t := 0.0
	var dps := 0.0
	var color := Color.WHITE
	var tick := 0.0
	var acido := false
	var puesta := 0.0   # lo que lleva puesta (para que el verde lata)

	func _physics_process(delta: float) -> void:
		var zombi: Node2D = get_parent()
		if not zombi.is_in_group("zombis"):
			pintar(zombi, false)
			queue_free()
			return
		t -= delta
		tick += delta
		puesta += delta
		if acido:
			pintar(zombi, true)
		elif randf() < 6.0 * delta:   # gotitas que caen
			Particulas.soltar(zombi, zombi.global_position + Vector2(randf_range(-10, 10), -40),
				Vector2(randf_range(-15, 15), randf_range(20, 50)), color, 2, 0.4)
		if tick >= ArmasCreadas.EFECTOS.tick:
			tick -= ArmasCreadas.EFECTOS.tick
			if not zombi.get("inmune_fuego"):
				zombi.herir(dps * ArmasCreadas.EFECTOS.tick, color)
		if t <= 0.0:
			pintar(zombi, false)
			queue_free()

	# El ácido en un jefe (que no es Zombi): con el shader de los zombis (el del destello), que se le pone la primera
	# vez, y su luz verde, que se quita al acabarse
	func pintar(jefe: Node2D, si: bool) -> void:
		if not acido or jefe is Zombi or not jefe.get("sprite") is CanvasItem:
			return
		var s: CanvasItem = jefe.get("sprite")
		if not s.material is ShaderMaterial:
			if not si:
				return
			s.material = ShaderMaterial.new()
			s.material.shader = Zombi.DESTELLO
			s.material.set_shader_parameter("semilla", randf() * 100.0)
		Zombi.quemaduras(s, 0.0, Zombi.cuanto_acido(puesta) if si else 0.0, puesta)
		if si:
			var alto: float = jefe.get("arriba") if jefe.get("arriba") != null else 120.0   # (Minijefe.arriba)
			Brillo.luz_acido(jefe, alto).fuerza = 0.55
		elif jefe.has_node("LuzAcido"):
			jefe.get_node("LuzAcido").queue_free()
