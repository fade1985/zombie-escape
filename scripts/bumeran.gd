# El bumerán segador (src/armas-creadas.js): sale girando, atraviesa a los zombis que pilla y, al llegar a su
# alcance o chocar con una pared o un mueble, da la vuelta y vuelve a Johnny (pegando otra vez a la vuelta).
extends Node2D

const ALTURA := 22.0

var johnny: Node2D
var angulo := 0.0
var dano := 14.0
var empuje := 1.5
var alcance := 300.0
var velocidad := 460.0
var ida := true
var origen := Vector2.INF   # de dónde salió (se apunta en el primer paso, ya colocado en la boca del arma)
var golpeados: Array = []
var giro := 0.0
var t := 0.0


func _physics_process(delta: float) -> void:
	if origen == Vector2.INF:
		origen = global_position
	t += delta
	giro += delta * 22.0
	var hacia := Vector2.from_angle(angulo)
	if ida:
		var despues := global_position + hacia * velocidad * delta
		var rayo := PhysicsRayQueryParameters2D.create(global_position, despues, 1)
		var choca := not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()
		if not choca:
			global_position = despues
		if choca or global_position.distance_to(origen) >= alcance:
			ida = false
			golpeados.clear()
	else:
		# de vuelta: va derecho a Johnny, algo más rápido (y atraviesa lo que haya)
		var donde: Vector2 = johnny.global_position + Vector2(0, 16) if is_instance_valid(johnny) else origen
		var falta := donde - global_position
		angulo = falta.angle()
		global_position += falta.normalized() * minf(velocidad * 1.2 * delta, falta.length())
		if falta.length() < 22.0 or t > 4.0:
			Sonido.tocar("cambiar")   # vuelve a la mano
			queue_free()
			return
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi in golpeados or global_position.distance_to(zombi.global_position) >= zombi.radio + 14.0:
			continue
		golpeados.append(zombi)
		ArmasCreadas.golpe(zombi, Vector2.from_angle(angulo), dano, empuje, "bumeran")
	queue_redraw()


func _draw() -> void:
	# una "V" plateada con su borde oscuro, girando
	draw_set_transform(Vector2(0, -ALTURA), giro)
	for capa in [[9.0, Color("#1d1b2c")], [5.0, Color("#cfd3dc")]]:
		draw_polyline(PackedVector2Array([Vector2(-13, -11), Vector2.ZERO, Vector2(13, -11)]), capa[1], capa[0])
