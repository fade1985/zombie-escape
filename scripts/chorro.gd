# Una gota del lanzallamas, del súpersoplete o del desintegrador (los "chorros" de src/armas-creadas.js). Vuela
# recta, atraviesa a los zombis (a cada uno le da una vez), se para en las paredes y los muebles y se apaga al
# llegar a su alcance. Como la bala, la gota "de verdad" va a ras de suelo y se dibuja más arriba.
# El fuego crece y pasa de amarillo a naranja y rojo; el ácido, de verde claro a verde.
extends Node2D

const ALTURA_CUERPO := 22.0
const BAJADA := 14.0

var tipo := "llama"          # "llama", "cono" (el súpersoplete) o "acido"
var velocidad := Vector2.ZERO
var dano := 0.0
var empuje := 1.0
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
		ArmasCreadas.golpe(zombi, velocidad, dano, empuje, tipo)
	queue_redraw()


func _draw() -> void:
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
