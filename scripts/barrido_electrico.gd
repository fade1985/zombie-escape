# El barrido eléctrico del antidisturbios (fase 2, sin escudo; docs/JEFES_CENTRO.md): golpea el suelo con la porra y
# salen varias olas de chispas, una tras otra, que cruzan la sala de pared a pared. Cada ola es una raya recta (de lado
# a lado de la sala, a lo ancho o a lo alto) que avanza desde él hacia la pared de enfrente, con un hueco por donde
# pasar (marcado con dos postes amarillos), cada ola en otro sitio. También se puede atravesar esquivando (el
# instante de la esquiva no hace daño). Si toca a Johnny, le quita lo suyo (una vez por ola).
# Va recta, a lo ancho o a lo alto (la dirección hacia Johnny, redondeada): así cruza la sala de pared a pared.
# Las paredes la paran (los muebles, no: va por el suelo). Se dibuja con código, a cuadraditos de 2.
# Se crea con BarridoElectrico.new(); se le ponen "dir", "olas" y "dueno" y se mete en la escena donde está el jefe.
class_name BarridoElectrico
extends Node2D

const VELOCIDAD := 300.0   # lo deprisa que avanza cada ola
const HUECO := 64.0        # medio ancho del hueco de cada ola
const GROSOR := 14.0       # lo que tiene que estar Johnny de cerca de la raya para que le dé
const DANO := 14
const MAX_LADO := 1400.0   # lo más lejos que se busca la pared a cada lado

var dir := Vector2.RIGHT     # hacia dónde avanzan (ya redondeada a lo ancho o a lo alto)
var olas: Array = []         # cada una: {"sale": segundos}; su "hueco" (dónde está, a lo largo de la raya) lo pone _ready
var dueno: Node2D = null
var t := 0.0
var lado := Vector2.DOWN     # a lo largo de la raya
var desde := -600.0          # dónde acaba la raya a cada lado (lo que deja la pared)
var hasta := 600.0
var fondo := 1200.0          # hasta dónde avanza (la pared de enfrente)


func _ready() -> void:
	z_index = -1   # en el suelo, por debajo de todos
	# a lo ancho o a lo alto
	dir = Vector2(signf(dir.x), 0) if absf(dir.x) >= absf(dir.y) else Vector2(0, signf(dir.y))
	lado = dir.orthogonal()
	desde = -hasta_pared(-lado)
	hasta = hasta_pared(lado)
	fondo = hasta_pared(dir)
	# el hueco de cada ola, al azar dentro de la sala, y lejos del de la anterior (que haya que moverse)
	var anterior := INF
	for ola in olas:
		if ola.has("hueco"):
			continue
		var h := 0.0
		for i in 8:
			h = randf_range(desde + HUECO + 24.0, maxf(desde + HUECO + 24.0, hasta - HUECO - 24.0))
			if absf(h - anterior) >= 220.0:
				break
		ola.hueco = h
		anterior = h
	Sonido.tocar("calambre")


# Lo que hay desde aquí hasta la pared (los muros del mapa; los muebles no la paran)
func hasta_pared(hacia: Vector2) -> float:
	var espacio := get_world_2d().direct_space_state
	var rayo := PhysicsRayQueryParameters2D.create(global_position, global_position + hacia * MAX_LADO, 1)
	for i in 12:
		var choque := espacio.intersect_ray(rayo)
		if choque.is_empty():
			return MAX_LADO
		if (choque.collider as Node).is_in_group("muros"):
			return global_position.distance_to(choque.position)
		rayo.exclude = rayo.exclude + [choque.rid]   # (un mueble: sigue buscando)
	return MAX_LADO


func _physics_process(delta: float) -> void:
	var antes := t
	t += delta
	queue_redraw()
	var quedan := false
	var johnny := get_tree().get_first_node_in_group("jugador")
	for ola in olas:
		var d1: float = (t - ola.sale) * VELOCIDAD
		if d1 <= fondo:
			quedan = true
		if d1 < 0.0 or ola.get("dio", false) or johnny == null or not johnny.vivo:
			continue
		var d0: float = (antes - ola.sale) * VELOCIDAD
		var rel: Vector2 = johnny.global_position - global_position
		var p := rel.dot(dir)
		var s := rel.dot(lado)
		# ¿la raya ha pasado por encima de él en este paso? (fuera del hueco y de la sala, no)
		if p >= d0 - GROSOR and p <= d1 + GROSOR and d1 <= fondo + GROSOR and absf(s - ola.hueco) > HUECO \
				and s >= desde and s <= hasta and johnny.esquiva_t <= 0.0:
			ola.dio = true
			johnny.recibir_dano(DANO, dueno)
			johnny.empujar(dir * 350.0)
			Sonido.tocar("rayo")
	if not quedan:
		queue_free()


func _draw() -> void:
	for ola in olas:
		var d: float = (t - ola.sale) * VELOCIDAD
		if d < 0.0 or d > fondo:
			continue
		pintar_ola(d, ola.hueco)


# Una ola: una raya de chispas que tiembla, de pared a pared, con su hueco entre dos postes amarillos
func pintar_ola(d: float, hueco: float) -> void:
	var base := dir * d
	var s := desde
	while s <= hasta:
		if absf(s - hueco) > HUECO:
			# tiembla de un lado a otro (como un rayo), con el centro blanco y el borde azul
			var temblor := roundf(sin(s * 0.21 + t * 47.0) * 1.6 + sin(s * 0.07 - t * 31.0) * 1.4) * 2.0
			var p := base + lado * s + dir * temblor
			p = (p / 2.0).floor() * 2.0
			# (gruesa: una franja de 16 de brillo azul, 8 de azul claro y 4 de blanco, para verla venir)
			var a := lado.abs() * 4.0
			draw_rect(Rect2(p - dir.abs() * 8.0 - lado.abs() * 2.0, dir.abs() * 16.0 + a), Color("#2a6cff", 0.45))
			draw_rect(Rect2(p - dir.abs() * 4.0 - lado.abs() * 2.0, dir.abs() * 8.0 + a), Color("#5fd3ff"))
			draw_rect(Rect2(p - dir.abs() * 2.0 - lado.abs() * 2.0, dir.abs() * 4.0 + a), Color("#ffffff"))
			# alguna chispa suelta que salta
			if hash(int(s) + int(t * 20.0) * 7919) % 23 == 0:
				draw_rect(Rect2(p + dir * 6.0 + Vector2(-1, -5), Vector2(2, 2)), Color("#fff3a8"))
		s += 4.0
	# los postes del hueco
	for borde in [hueco - HUECO, hueco + HUECO]:
		if borde < desde or borde > hasta:
			continue
		var p: Vector2 = ((base + lado * borde) / 2.0).floor() * 2.0
		draw_rect(Rect2(p + Vector2(-4, -22), Vector2(8, 26)), Color("#1d1b2c"))
		draw_rect(Rect2(p + Vector2(-2, -20), Vector2(4, 22)), Color("#ffd23f"))
		draw_rect(Rect2(p + Vector2(-2, -20), Vector2(4, 4)), Color("#fff3a8"))
