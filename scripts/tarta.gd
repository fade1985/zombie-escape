# La tarta de cumpleaños de la Juguetería (la sala de la mascota en la fase 2; mascota.gd, poner_tarta;
# docs/JEFES_CENTRO.md, «La fiesta de cumpleaños»): una mesa redonda con una tarta y tres velas encendidas, en medio de la
# sala. Es un mueble (no se atraviesa). Si le da una bala de Johnny o la mascota se la come embistiendo, las velas salen
# volando (VELAS) y caen por el suelo, lejos de quien la ha golpeado: donde cae cada una prende un fuego pequeño, y el
# relleno de la mascota que haya cerca arde (relleno.gd). Luego la tarta se queda apagada RECARGA s y las velas vuelven a
# encenderse. Dibujo de PixelLab (tarta.png, sin las llamas: las llamas de las velas se dibujan con código y titilan).
# Se crea con Tarta.new() y se mete en la escena en su sitio: cae del techo (CAE s) y luego es un mueble.
class_name Tarta
extends StaticBody2D

const DIBUJO := preload("res://assets/sprites/tarta.png")
const RADIO := 44.0          # la mesa, lo que choca
const CAE := 0.5
const RECARGA := 7.0
const VUELO := 0.7           # lo que tardan las velas en caer
const ALTO := 110.0          # lo alto que suben
const LEJOS := [110.0, 240.0]
const PRENDE := 60.0         # el relleno a menos de esto de donde cae una vela arde
# donde están las mechas en el dibujo (píxeles del dibujo de 64, el centro es el 32, 32)
const MECHAS := [Vector2(24, 10), Vector2(32, 7), Vector2(40, 10)]

var t := 0.0
var apagada := 0.0           # lo que le falta para volver a encenderse (0: encendida)
var velas: Array = []        # las que van por el aire: [desde, hasta, t]
var sprite: Sprite2D
var aire: Node2D             # las velas volando, por encima de todo
var choque: CollisionShape2D


func _ready() -> void:
	add_to_group("tarta")
	collision_layer = 1
	collision_mask = 0
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO
	forma.shape = circulo
	forma.disabled = true   # (cayendo, aún no)
	forma.position = Vector2(0, -16)
	add_child(forma)
	choque = forma
	sprite = Sprite2D.new()
	sprite.texture = DIBUJO
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -26)   # (las patas de la mesa, en su sitio)
	sprite.show_behind_parent = true   # (las llamas de las velas, que se dibujan aquí, por encima)
	add_child(sprite)
	aire = Node2D.new()
	aire.z_index = 3
	aire.draw.connect(pintar_velas)
	add_child(aire)


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	aire.queue_redraw()
	if t < CAE:
		var k := t / CAE
		sprite.position.y = -(1.0 - k * k) * 500.0
		return
	if sprite.position.y != 0.0:
		sprite.position.y = 0.0
		choque.set_deferred("disabled", false)
		Temblor.temblar(6.0)
		Sonido.tocar("pisoton")
		for i in 14:
			Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-50, 50), 6), Vector2(randf_range(-90, 90), randf_range(-60, -10)),
				Color("#cdbfa6", 0.8), randf_range(3, 5), 0.5)
	if apagada > 0.0:
		apagada -= delta
		if apagada <= 0.0:
			Sonido.tocar("fuego")
	for v in velas:
		v[2] += delta
		if v[2] >= VUELO:
			caer_vela(v[1])
	velas = velas.filter(func(v): return v[2] < VUELO)


func lista() -> bool:
	return t >= CAE and apagada <= 0.0


# ¡Golpe a la tarta! (una bala de Johnny, bala.gd, o la mascota embistiendo): las velas salen volando, hacia el otro lado
func tocada(desde: Vector2) -> void:
	if not lista():
		return
	apagada = RECARGA
	Sonido.tocar("chof")
	var lejos_de := (global_position - desde).normalized() if desde.distance_to(global_position) > 1.0 else Vector2.from_angle(randf() * TAU)
	for i in MECHAS.size():
		var a := lejos_de.angle() + (i - 1) * 0.7 + randf_range(-0.25, 0.25)
		var hasta := global_position + Vector2.from_angle(a) * randf_range(LEJOS[0], LEJOS[1])
		var mapa := get_world_2d().navigation_map
		hasta = NavigationServer2D.map_get_closest_point(mapa, hasta)
		velas.append([mecha(i), hasta, 0.0])
	for i in 18:
		Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-30, 30), -60), Vector2(randf_range(-120, 120), randf_range(-160, -40)),
			[Color("#ff9ec4"), Color("#f4f0e4"), Color("#ffd23f")][i % 3], randf_range(2, 4), 0.5)


# La bala de Johnny (bala.gd): le da a la mesa
func tocada_bala(velocidad: Vector2) -> void:
	tocada(global_position - velocidad.normalized() * 50.0)


# Donde está la mecha "i" (en el mundo)
func mecha(i: int) -> Vector2:
	return global_position + sprite.position + (MECHAS[i] - Vector2(32, 32) + sprite.offset) * 2.0


func caer_vela(donde: Vector2) -> void:
	var fuego: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	fuego.tipo = "fuego"
	fuego.escala = 0.4
	fuego.duracion = 0.5
	fuego.position = donde - get_parent().global_position
	get_parent().add_child(fuego)
	Relleno.prender_cerca(get_tree(), donde, PRENDE)
	for i in 6:
		Particulas.soltar(get_parent(), donde, Vector2(randf_range(-60, 60), randf_range(-90, -30)), Llamas.FUEGO[i % 4], 2, 0.35)


# Las llamas de las velas (titilan); apagada, un hilito de humo
func _draw() -> void:
	if t < CAE:
		return
	for i in MECHAS.size():
		var p := mecha(i) - global_position
		if apagada > 0.0:
			if randf() < 0.15:
				Particulas.soltar(get_parent(), global_position + p, Vector2(randf_range(-8, 8), -40), Color("#bbbbbb", 0.5), 2, 0.6)
			continue
		var alto := 3 + int(absf(sin(t * 9.0 + i * 2.1)) * 2.0)
		draw_rect(Rect2(p + Vector2(-2, -alto * 2), Vector2(4, alto * 2)), Color("#ff9a3c"))
		draw_rect(Rect2(p + Vector2(-2, -alto * 2 + 2), Vector2(2, alto * 2 - 4)), Color("#ffd23f"))
		draw_rect(Rect2(p + Vector2(0, -alto * 2 - 2), Vector2(2, 2)), Color("#fff3b0"))


# Las velas por el aire: dando vueltas, con su llamita, y su marca en el suelo donde van a caer
func pintar_velas() -> void:
	for v in velas:
		var k: float = minf(1.0, v[2] / VUELO)
		var suelo: Vector2 = (v[0] as Vector2).lerp(v[1], k)
		var p := suelo + Vector2(0, -sin(k * PI) * ALTO) - global_position
		Aviso.abanico(aire, (v[1] as Vector2) - global_position, 0.0, PI, 34.0, k, t, 0.6, 0.25)
		# la vela (rosa, de 3 x 9 píxeles) dando vueltas, con su llama encendida en la punta
		aire.draw_set_transform(p, k * TAU * 2.0)
		aire.draw_rect(Rect2(-4, -10, 8, 20), Color("#7a2f4a"))
		aire.draw_rect(Rect2(-2, -8, 4, 16), Color("#ff9ec4"))
		aire.draw_rect(Rect2(-2, -18, 4, 8), Color("#ff9a3c"))
		aire.draw_rect(Rect2(-2, -16, 2, 4), Color("#fff3b0"))
		aire.draw_set_transform(Vector2.ZERO)
		if randf() < 0.5:
			Particulas.soltar(get_parent(), global_position + p, Vector2(randf_range(-20, 20), randf_range(-20, 20)), Llamas.FUEGO[randi() % 4], 2, 0.3)
