# El garfio (arma creada del centro comercial: cuerda + perchas). Sale recto desde la boca del arma con la cuerda
# detrás. Si pilla a un zombi, le pega, lo engancha y lo arrastra hasta delante de Johnny (lo suelta aturdido un
# momento); si choca con una pared o un mueble, o llega a su alcance, vuelve solo. A los jefes (no son Zombi) no
# los mueve: solo les pega. Como el bumerán, no gasta munición.
extends Node2D

const ALTURA_CUERPO := 22.0   # se dibuja a esta altura sobre el suelo (va "de verdad" a ras de suelo, como la bala)
const BAJADA := 14.0          # lo rápido que baja de la mano a la altura del cuerpo
const ARRASTRE := 520.0   # lo rápido que trae al zombi
const CERCA := 56.0       # lo suelta a esta distancia de Johnny
const SOLTAR := 0.6       # segundos que se queda aturdido al soltarlo

var johnny: Node2D
var mano_rel := Vector2.ZERO   # dónde está la mano que lanza, respecto a Johnny (la boca del dibujo): de ahí sale la cuerda
var angulo := 0.0
var altura := 50.0   # a qué altura sobre el suelo se dibuja el gancho: sale de la mano de Johnny y baja a la del cuerpo
var dano := 8.0
var alcance := 320.0
var velocidad := 620.0
var origen := Vector2.INF   # de dónde salió (se apunta en el primer paso, ya colocado en la boca del arma)
var presa: Node2D = null    # el zombi enganchado
var vuelve := false
var t := 0.0


func _ready() -> void:
	z_index = 4   # por encima de Johnny y de los zombis: sale de su mano y no debe quedar detrás de su dibujo


func _physics_process(delta: float) -> void:
	if origen == Vector2.INF:
		origen = global_position
	t += delta
	altura += (ALTURA_CUERPO - altura) * (1.0 - exp(-delta * BAJADA))
	if not is_instance_valid(johnny) or t > 3.0:
		soltar()
		return
	var mano: Vector2 = johnny.global_position + Vector2(0, 16)
	if presa:
		if not is_instance_valid(presa) or not presa.is_in_group("zombis"):
			presa = null   # se ha muerto por el camino: el garfio vuelve solo
			vuelve = true
		else:
			var falta := mano - presa.global_position
			if falta.length() <= CERCA:
				soltar()
				return
			# mientras lo arrastra, quieto (aturdido) y deslizándose hacia Johnny
			presa.aturdido = maxf(presa.aturdido, 0.2)
			presa.velocity = falta.normalized() * ARRASTRE
			presa.move_and_slide()
			global_position = presa.global_position
	elif vuelve:
		var falta := mano - global_position
		angulo = falta.angle()
		global_position += falta.normalized() * minf(velocidad * 1.3 * delta, falta.length())
		if falta.length() < 22.0:
			soltar()
			return
	else:
		var despues := global_position + Vector2.from_angle(angulo) * velocidad * delta
		var rayo := PhysicsRayQueryParameters2D.create(global_position, despues, 1)
		if not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty() \
				or global_position.distance_to(origen) >= alcance:
			vuelve = true
		else:
			global_position = despues
			for zombi in get_tree().get_nodes_in_group("zombis"):
				if global_position.distance_to(zombi.global_position) < zombi.radio + 12.0:
					enganchar(zombi)
					break
	queue_redraw()


# Le pega y, si es un zombi normal (no un jefe) y sigue vivo, se lo trae
func enganchar(zombi: Node2D) -> void:
	ArmasCreadas.golpe(zombi, Vector2.from_angle(angulo), dano, 0.0, "garfio")
	if zombi is Zombi and zombi.is_in_group("zombis"):
		presa = zombi
		Sonido.tocar("latigazo")
	else:
		vuelve = true


# Vuelve a la mano: si traía a un zombi, lo suelta aturdido delante de Johnny
func soltar() -> void:
	if presa and is_instance_valid(presa) and presa.is_in_group("zombis"):
		ArmasCreadas.aturdir(presa, SOLTAR)
		presa.velocity = Vector2.ZERO
	Sonido.tocar("cambiar")
	queue_free()


func _draw() -> void:
	if not is_instance_valid(johnny):
		return
	# la cuerda, desde la mano de Johnny que se ve en el dibujo (con su borde oscuro)
	var mano: Vector2 = to_local(johnny.global_position + mano_rel)
	var punta := Vector2(0, -altura)
	for capa in [[4.0, Color("#1d1b2c")], [2.0, Color("#d8b25a")]]:
		draw_line(mano, punta, capa[1], capa[0])
	# el gancho: una percha doblada en forma de anzuelo, mirando hacia donde va
	draw_set_transform(punta, angulo)
	var gancho := PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(9, -4), Vector2(6, -8), Vector2(2, -6)])
	for capa in [[5.0, Color("#1d1b2c")], [2.5, Color("#d0d4da")]]:
		draw_polyline(gancho, capa[1], capa[0])
