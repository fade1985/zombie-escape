# El relleno de la mascota descosida (fase 2; mascota.gd, soltar_relleno; docs/JEFES_CENTRO.md, «La fiesta de
# cumpleaños»): un pegote de algodón blanco que se le cae de la barriga rajada y se queda en el suelo VIDA s. No hace
# nada... hasta que le llega el fuego: un charco de fuego (el molotov, el aceite...), la llamarada del lanzallamas, una
# explosión, una vela de la tarta (tarta.gd) o el relleno de al lado, que ya arde. Entonces prende: en su sitio queda un
# fuego pequeño (charco.gd, "fuego", con la marca "relleno") que quema a quien lo pise; y a la mascota, si corre por
# encima, le quita mucho (mascota.gd, quemarse). El fuego corre por el reguero de relleno, un pegote tras otro.
# Se dibuja con código, a cuadraditos: unas bolitas de algodón, con su sombra.
class_name Relleno
extends Node2D

const VIDA := 10.0
const RADIO := 26.0
const PRENDE := 0.15        # lo que tarda en prender del relleno de al lado (se ve correr el fuego)
const CONTAGIA := 70.0      # a esta distancia, prende el de al lado
const ESCALA_FUEGO := 0.55  # el fuego que deja (el del molotov tiene radio 64: este, 35)
const DURA_FUEGO := 0.9     # (× 4 s del fuego: 3,6 s)
const GOTA := 2.0           # un píxel del dibujo
const COLORES := [Color("#f4f0e4"), Color("#e2dccb"), Color("#ffffff"), Color("#d6cfbd")]
const SOMBRA := Color("#5a5040", 0.55)
const EXPLOSION_GD := preload("res://scripts/explosion.gd")

var t := 0.0
var prende := -1.0          # cuenta atrás para prender (-1: no)
var mira := 0.0
var bolitas := []           # [sitio, radio en píxeles, color]

# Las explosiones que hay ahora en la sala (se miran una vez por paso para todo el relleno)
static var paso_explosiones := -1
static var explosiones: Array = []
static var sonado := 0      # (cuándo ha sonado el último fuego: que no suenen veinte a la vez)


func _ready() -> void:
	add_to_group("relleno")
	z_index = -1   # en el suelo, por debajo de todos
	mira = randf() * 0.1
	for i in 7:
		var a := randf() * TAU
		var r := sqrt(randf()) * RADIO * 0.6
		bolitas.append([(Vector2(cos(a) * r, sin(a) * r * 0.6) / GOTA).round() * GOTA, randi_range(3, 5), COLORES[i % COLORES.size()]])
	bolitas.sort_custom(func(x, y): return x[0].y < y[0].y)


func _physics_process(delta: float) -> void:
	t += delta
	if t >= VIDA:
		queue_free()
		return
	if t < 0.3 or t > VIDA - 1.5:
		queue_redraw()
	if prende >= 0.0:
		prende -= delta
		if prende <= 0.0:
			arder()
		return
	mira -= delta
	if mira <= 0.0:
		mira = 0.1
		if le_llega_fuego():
			arder()


# ¿Le llega algún fuego? Un charco que arde, la llamarada del lanzallamas o una explosión
func le_llega_fuego() -> bool:
	for c in get_tree().get_nodes_in_group("charcos"):
		if c.tipo in ["fuego", "hirviendo"] and c.arde_en(global_position, RADIO * 0.5):
			return true
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.get("llamarada"):
		var l: Llamarada = johnny.llamarada
		if l.encendida and l.variante == "llama":
			var u := Vector2.from_angle(l.angulo)
			var p := global_position - l.global_position
			var delante := p.dot(u)
			if delante > -RADIO and delante < l.tope + RADIO and absf(p.cross(u)) < Llamarada.BOCA + maxf(0.0, delante) * l.abre() + RADIO:
				return true
	for e in explosiones_ahora():
		if global_position.distance_to(e[0]) < e[1] + RADIO:
			return true
	return false


func explosiones_ahora() -> Array:
	if paso_explosiones != Engine.get_physics_frames():
		paso_explosiones = Engine.get_physics_frames()
		explosiones.clear()
		for n in get_parent().get_children():
			if n.get_script() == EXPLOSION_GD and not n.helada and n.tiempo < 0.3:
				explosiones.append([n.global_position, n.radio])
	return explosiones


# ¡Arde! En su sitio, un fuego pequeño; y el relleno de al lado prenderá enseguida
func arder() -> void:
	if is_queued_for_deletion():
		return
	var fuego: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	fuego.tipo = "fuego"
	fuego.escala = ESCALA_FUEGO
	fuego.duracion = DURA_FUEGO
	fuego.set_meta("relleno", true)
	fuego.position = position
	get_parent().add_child(fuego)
	for r in get_tree().get_nodes_in_group("relleno"):
		if r != self and r.prende < 0.0 and r.global_position.distance_to(global_position) < CONTAGIA:
			r.prende = PRENDE
	if Time.get_ticks_msec() - sonado > 250:
		sonado = Time.get_ticks_msec()
		Sonido.tocar("fuego")
	for i in 6:
		Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-10, 10), -4), Vector2(randf_range(-40, 40), randf_range(-120, -60)),
			Llamas.FUEGO[i % 4], randf_range(2, 3), 0.4)
	queue_free()


# Prende el relleno que haya cerca de "donde" (las velas de la tarta)
static func prender_cerca(arbol: SceneTree, donde: Vector2, radio: float) -> void:
	for r in arbol.get_nodes_in_group("relleno"):
		if r.prende < 0.0 and r.global_position.distance_to(donde) < radio:
			r.prende = randf_range(0.0, 0.1)


# Las bolitas de algodón, a cuadraditos, con su sombra; al caer crecen de golpe y al final se van apagando
func _draw() -> void:
	var k := minf(1.0, t / 0.15)
	modulate.a = clampf((VIDA - t) / 1.5, 0.0, 1.0)
	for b in bolitas:
		disco(b[0] + Vector2(0, GOTA), b[1] * k + 1.0, SOMBRA)
	for b in bolitas:
		disco(b[0], b[1] * k, b[2])
		disco(b[0] + Vector2(-GOTA, -GOTA), maxf(0.0, b[1] * k - 2.0), Color.WHITE)


# Un círculo de cuadraditos (r en píxeles del dibujo)
func disco(centro: Vector2, r: float, color: Color) -> void:
	var n := floori(r)
	for y in range(-n, n + 1):
		var medio := floori(sqrt(maxf(0.0, r * r - y * y)))
		draw_rect(Rect2(centro + Vector2(-medio, y) * GOTA, Vector2((medio * 2 + 1) * GOTA, GOTA)), color)
