# Los cachos de carne que salen volando cuando revienta el zombi explosivo (19 nov, los pidió el dueño: «que salten por
# los aires y caigan al suelo con sangre y salpicones en todas las direcciones», con una foto suya de carne cruda). Los
# dibujos, de PixelLab (assets/sprites/cachos-carne.png, hecha con assets/sources/zombi-explosivo-gpt/carne.py).
#
# Cada cacho sale hacia un lado distinto, sube y cae por su peso como las gotas de Particulas (su altura, "z"), dando
# vueltas a cuartos (girar a cuartos no tuerce los píxeles), soltando gotas de sangre por el camino; al tocar el suelo
# deja una mancha y salpicaduras finas hacia todos los lados (Mancha.salpicon), rebota un poco y se queda tirado. No atraviesa paredes
# ni muebles. Todos los de un reventón van en un solo nodo, en el suelo de esa sala: se quedan hasta salir de ella.
# Se prueba con --captura --cachos
class_name Cachos
extends Node2D

const DIBUJOS := preload("res://assets/sprites/cachos-carne.png")
const CELDA := 16            # cada cacho, en su casilla de 16 × 16 píxeles del dibujo (a escala 2, como todo)
const PESO := 620.0          # lo que tira hacia abajo (el de Particulas)
const SANGRE := Color("#7a1f1a")

var lista: Array[Dictionary] = []
var volando := 0             # cuántos siguen en el aire (mientras, se pintan por encima de los personajes)


# Un reventón: "n" cachos que salen de "donde" (el suelo bajo el zombi) hacia todos los lados
static func lanzar(sala: Node, donde: Vector2, n := 14) -> Cachos:
	var c := Cachos.new()
	c.material = Recorte.material("punto")   # (ni encima de un muro ni al otro lado: recorte.gd)
	var cuantos := DIBUJOS.get_width() / CELDA
	var orden := range(cuantos)
	orden.shuffle()
	for i in n:
		# repartidos alrededor (cada uno en su trozo del círculo, algo movido), unos lejos y otros cerca
		var a := TAU * (i + randf_range(0.1, 0.9)) / n
		var v := Vector2.from_angle(a) * randf_range(90.0, 330.0)
		c.lista.append({"p": donde + v.normalized() * 6.0, "v": Vector2(v.x, v.y * 0.6), "z": randf_range(24.0, 48.0),
			"vz": randf_range(120.0, 280.0), "cual": orden[i % cuantos], "giro": randi() % 4,
			"gira": randf_range(10.0, 22.0) * (1.0 if randf() < 0.5 else -1.0), "t_giro": 0.0, "rebotes": 1 + randi() % 2,
			"gota": randf_range(0.0, 0.05), "quieto": false})
	c.volando = n
	c.z_index = 20
	sala.add_child(c)
	# la sangre del reventón, en el sitio: el reventón de sangre (el de los golpes fuertes, EfectoSuelo), una mancha
	# roja en medio y salpicaduras alrededor, hacia todos los lados (19 nov: el dueño quería más sangre)
	EfectoSuelo.soltar(sala, "sangre", donde, 1.4)
	Mancha.sangre(sala, donde, randf_range(20.0, 26.0), SANGRE)
	for i in 18:
		var hacia := Vector2.from_angle(TAU * (i + randf()) / 18.0)
		var lejos := randf_range(10.0, 56.0)
		Mancha.salpicon(sala, donde + Vector2(hacia.x, hacia.y * 0.6) * lejos, SANGRE, hacia * randf_range(150.0, 400.0),
			8.0 if randf() < 0.3 else 2.0)
	return c


func _process(delta: float) -> void:
	if volando == 0:
		set_process(false)
		z_index = -1   # todos en el suelo: por debajo de los personajes y encima de las manchas (Mancha, -2)
		queue_redraw()
		return
	var espacio := get_world_2d().direct_space_state
	var rayo := PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, 1)   # (una consulta para todos los cachos)
	for q in lista:
		if q.quieto:
			continue
		# por el suelo: si da con una pared o un mueble, se para junto a ella y cae ahí mismo
		var despues: Vector2 = q.p + q.v * delta
		rayo.from = q.p
		rayo.to = despues
		var choque := espacio.intersect_ray(rayo)
		if choque:
			q.p = choque.position + choque.normal * 8.0
			q.v = Vector2.ZERO
		else:
			q.p = despues
		# da vueltas a cuartos, más despacio según pierde fuerza
		q.t_giro += delta * absf(q.gira) * (0.3 + q.v.length() / 330.0)
		if q.t_giro >= 1.0:
			q.t_giro -= 1.0
			q.giro = (q.giro + (1 if q.gira > 0.0 else 3)) % 4
		# gotas de sangre por el camino, mientras va alto
		q.gota -= delta
		if q.gota <= 0.0 and q.z > 4.0:
			q.gota = randf_range(0.02, 0.05)
			Particulas.volar(self, q.p, q.z, q.v * 0.3, randf_range(0.0, 60.0), SANGRE, 2.0, get_parent(),
				Color(SANGRE, randf_range(0.6, 0.85)), Vector2.ONE * 4.0)
		# sube y cae; al tocar el suelo deja su salpicón, rebota (cada vez con menos fuerza) y al final se queda
		q.vz -= PESO * delta
		q.z += q.vz * delta
		if q.z > 0.0:
			continue
		q.z = 0.0
		if q.v.length() > 20.0 or q.vz < -120.0:
			# el golpe: una mancha gorda y salpicaduras finas hacia todos los lados, alrededor del cacho
			Mancha.salpicon(get_parent(), q.p, SANGRE, q.v + Vector2(0, 1), 10.0)
			for k in randi_range(5, 8):
				var hacia := Vector2.from_angle(randf() * TAU)
				Mancha.salpicon(get_parent(), q.p + hacia * randf_range(8.0, 16.0), SANGRE, hacia * randf_range(120.0, 320.0), 2.0)
		if q.rebotes > 0:
			q.rebotes -= 1
			q.vz = -q.vz * 0.3
			q.v *= 0.4
			continue
		q.quieto = true
		q.v = Vector2.ZERO
		volando -= 1
	queue_redraw()


func _draw() -> void:
	for q in lista:
		var donde: Vector2 = q.p - Vector2(0, q.z)
		var p: Vector2 = (donde / 2.0).round() * 2.0   # en píxeles enteros del dibujo
		draw_set_transform(p, q.giro * PI / 2.0, Vector2(2, 2))
		draw_texture_rect_region(DIBUJOS, Rect2(-CELDA / 2.0, -CELDA / 2.0, CELDA, CELDA),
			Rect2(q.cual * CELDA, 0, CELDA, CELDA))
	draw_set_transform(Vector2.ZERO)
