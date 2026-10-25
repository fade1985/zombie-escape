# Una gota de fuego o de ácido (los "chorros" de src/armas-creadas.js), una
# chispa de la pistola eléctrica o un clavo de la bomba de clavos (los dos del centro comercial). Vuela
# recta, atraviesa a los zombis (a cada uno le da una vez), se para en las paredes y los muebles y se apaga al
# llegar a su alcance. Como la bala, la gota "de verdad" va a ras de suelo y se dibuja más arriba.
# El fuego crece y pasa de amarillo a naranja y rojo; el ácido, de verde claro a verde.
extends Node2D

const ALTURA_CUERPO := 22.0
const BAJADA := 14.0

var tipo := "llama"          # "llama", "acido", "chispa" o "clavo"
var velocidad := Vector2.ZERO
var dano := 0.0
var empuje := 1.0
var quema := 1.0             # el fuego: por cuánto se multiplica lo que sigue ardiendo el zombi (la skin del bombero)
var radio := 8.0
var vida_max := 0.5
var vida := -1.0
var altura := 50.0
var golpeados: Array = []


func _physics_process(delta: float) -> void:
	if vida < 0.0:
		vida = vida_max
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	altura += (ALTURA_CUERPO - altura) * (1.0 - exp(-delta * BAJADA))
	var despues := global_position + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(global_position, despues, 1)
	if not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
		queue_free()
		return
	global_position = despues
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi in golpeados or global_position.distance_to(zombi.global_position) >= zombi.radio + radio:
			continue
		golpeados.append(zombi)
		ArmasCreadas.golpe(zombi, velocidad, dano, empuje, tipo, quema)
	queue_redraw()


func _draw() -> void:
	if tipo == "clavo":
		# un clavo gris que vuela de punta, con su borde oscuro
		var dir := velocidad.normalized()
		for capa in [[4.0, Color("#1d1b2c")], [2.0, Color("#d0d4da")]]:
			draw_line(Vector2(0, -altura) - dir * 6.0, Vector2(0, -altura) + dir * 6.0, capa[1], capa[0])
		return
	if tipo == "chispa":
		# chispas azules y blancas que tiemblan
		for i in 3:
			var p := ((Vector2(randf_range(-6, 6), -altura + randf_range(-6, 6))) / 2.0).round() * 2.0
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color.WHITE if i == 0 else Color("#9fe8ff"))
		return
	var k := 1.0 - vida / vida_max   # 0 al salir, 1 al apagarse
	var color: Color
	var r: float
	if tipo == "acido":
		color = Color("#c7f27a") if k < 0.6 else Color("#8fd13f")
		r = radio * (0.5 + 0.5 * k)
	else:
		color = Color("#fff3a0") if k < 0.3 else (Color("#ff9f1c") if k < 0.65 else Color("#d94a1a"))
		r = radio * (0.5 + 1.1 * k)
	color.a = minf(1.0, 1.6 - k * 1.3)
	# a cuadraditos, para que case con el pixel art
	r = maxf(2.0, roundf(r / 2.0) * 2.0)
	draw_rect(Rect2(Vector2(-r, -altura - r), Vector2(r, r) * 2.0), color)
