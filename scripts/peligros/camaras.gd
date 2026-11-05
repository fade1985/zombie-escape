# Las cámaras de seguridad de Informática y Seguridad corporativa, en Torre Velaria (peligros.gd, CAMARAS): colgadas en
# la pared de arriba de la sala grande, barren el suelo con su cono de luz, de un lado a otro. Las paredes y los muebles
# les tapan la vista. Si una ve a Johnny un rato ("ve"), se le llena la barrita naranja de encima y salta la alarma: luz roja y sirena, se
# despiertan todos los zombis del departamento y, la primera vez que llama esa cámara, llegan refuerzos por la puerta
# (los escoltas de Velaria, zombi_escolta.gd). Se rompen de un disparo (bala.gd,
# camara_en): rotas, sueltan chispas y ya no ven. Si no está la alarma, después de sonar descansan un poco.
#
# Se dibuja todo con código: el cono (en el suelo, que luce por sí mismo) en este nodo, y cada cámara (la caja, el
# objetivo y su piloto) en el pie de la pared, en las cosas del mapa, para ordenarse con la cara del muro.
extends Node2D

const ARRIBA := -60.0        # a qué altura de la pared está colgada, desde el pie
const CONO := Color(1.0, 0.97, 0.8, 0.13)
const CONO_VE := Color(1.0, 0.55, 0.3, 0.2)
const CONO_ALARMA := Color(1.0, 0.15, 0.1, 0.22)
const PILOTO := Color("#ff3b3b")
const CIEGA := 200.0         # a esta distancia de Johnny, el informático joven ciega las cámaras

var datos: Dictionary
var mapa: Node
var cuerpos: Array = []      # el dibujo de cada cámara en la pared (Node2D, en las cosas del mapa)
var sospecha: Array = []     # lo llena que está la barrita de cada una (0 a 1)
var alarma := 0.0            # lo que le queda sonando a la alarma
var descanso := 0.0          # lo que les queda descansando después
var sirena := 0.0
var luz_alarma: Array = []   # las luces rojas de cada cámara (solo con la alarma)
var t := 0.0


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Camaras"   # no-tr (nombre de nodo)
	add_to_group("camaras")
	z_index = 3
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el cono luce por sí mismo
	propio.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = propio
	for i in d.camaras.size():
		var c: Dictionary = d.camaras[i]
		var cuerpo := Node2D.new()
		cuerpo.name = "Camara%d" % i
		cuerpo.position = Vector2(c.x, c.y + 1)
		cuerpo.draw.connect(dibujar_camara.bind(cuerpo, i))
		m.cosas.add_child(cuerpo)
		cuerpos.append(cuerpo)
		sospecha.append(0.0)
		var luz := PointLight2D.new()
		luz.texture = preload("res://escenas/luces/luz_suave.tres")
		luz.texture_scale = 2.5
		luz.color = PILOTO
		luz.energy = 0.0
		luz.position = Vector2(c.x, c.y + 40.0)
		add_child(luz)
		luz_alarma.append(luz)


func _exit_tree() -> void:
	for c in cuerpos:
		if is_instance_valid(c):
			c.queue_free()


# De dónde sale el cono de cada una (un poco por delante de la pared) y hacia dónde mira ahora
func ojo(i: int) -> Vector2:
	return Vector2(datos.camaras[i].x, datos.camaras[i].y + 10.0)


func angulo(i: int) -> float:
	var c: Dictionary = datos.camaras[i]
	var v: Dictionary = Peligros.CAMARAS
	return c.mira + sin(t * TAU / v.vuelta + i * 2.1) * v.barre


# ¿La cámara "i" ve el punto "p"? Dentro del cono y sin nada en medio (paredes, muebles, puertas cerradas)
func ve(i: int, p: Vector2, quien: Node) -> bool:
	if datos.camaras[i].rota:
		return false
	# con el informático joven cerca, la cámara no ve a nadie (se la ha colado: supervivientes.gd)
	if Supervivientes.informatico_cerca(get_tree(), p, CIEGA):
		return false
	var o := ojo(i)
	var v: Dictionary = Peligros.CAMARAS
	if o.distance_to(p) > v.alcance or absf(angle_difference(angulo(i), (p - o).angle())) > v.abre:
		return false
	var rayo := PhysicsRayQueryParameters2D.create(o, p, 1)
	rayo.exclude = [quien.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


func _physics_process(delta: float) -> void:
	t += delta
	descanso = maxf(descanso - delta, 0.0)
	var johnny := get_tree().get_first_node_in_group("jugador")
	for i in datos.camaras.size():
		var viendo: bool = alarma <= 0.0 and descanso <= 0.0 and johnny != null and johnny.vivo \
			and ve(i, johnny.global_position, johnny)
		if viendo:
			Peligros.avisar(self, datos, Idioma.t("¡Una cámara! Si me ve, saltará la alarma"))
			sospecha[i] += delta / Peligros.CAMARAS.ve
			Sonido.tocar("camara")
			if sospecha[i] >= 1.0:
				saltar(i)
		else:
			sospecha[i] = maxf(sospecha[i] - delta * 0.5, 0.0)
	if alarma > 0.0:
		alarma -= delta
		sirena -= delta
		if sirena <= 0.0:
			sirena = 1.6
			Sonido.tocar("alarma")
		if alarma <= 0.0:
			descanso = Peligros.CAMARAS.descanso
	for i in luz_alarma.size():
		luz_alarma[i].energy = (0.9 + 0.6 * sin(t * 12.0)) if alarma > 0.0 and not datos.camaras[i].rota else 0.0
	modulate.a = 1.0 - mapa.niebla.get(datos.sala, 0.0)
	queue_redraw()
	for c in cuerpos:
		c.queue_redraw()


# Salta la alarma: todos los zombis del departamento despiertan (y, como siempre, van a por Johnny); si esa cámara no
# había llamado aún, llegan refuerzos por la puerta del departamento
func saltar(i: int) -> void:
	alarma = Peligros.CAMARAS.alarma
	sirena = 0.0
	for k in sospecha.size():
		sospecha[k] = 0.0
	Zombi.texto_flotante(get_parent(), ojo(i) + Vector2(-60, 20), Idioma.t("¡ALARMA!"), PILOTO, 22)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.get("dormido"):
			zombi.despertar()
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("¡Me han visto! Ya vienen..."))
	if datos.camaras[i].llamo or partida == null or not partida.has_method("meter_zombi") or mapa.puertas.is_empty():
		return
	datos.camaras[i].llamo = true
	var puerta: Node2D = mapa.puertas[0]
	for k in Peligros.CAMARAS.refuerzos:
		var zombi: Node2D = partida.meter_zombi("escolta", puerta.llegada() + Vector2(randf_range(-24, 24), randf_range(-24, 24)))
		if zombi and zombi.get("dormido"):
			zombi.despertar()


# Una bala en "p" (volando o al chocar con la pared): si está junto a una cámara entera, la rompe (bala.gd). Hace el ruido del cristal
# y suelta chispas
func romper_en(p: Vector2) -> bool:
	for i in datos.camaras.size():
		var c: Dictionary = datos.camaras[i]
		if not c.rota and p.distance_to(Vector2(c.x, c.y)) < 30.0:
			c.rota = true
			sospecha[i] = 0.0
			luz_alarma[i].energy = 0.0
			Sonido.tocar("cristal")
			Sonido.tocar("chispa")
			for k in 10:
				Particulas.soltar(get_parent(), Vector2(c.x, c.y + ARRIBA + 10.0), Vector2(randf_range(-90, 90), randf_range(-60, 40)),
					Color("#ffd23f") if k % 2 else Color.WHITE, 2, 0.35)
			return true
	return false


# El cono de cada cámara entera: blanco cálido vigilando, naranja si te está viendo, rojo con la alarma
func _draw() -> void:
	var v: Dictionary = Peligros.CAMARAS
	for i in datos.camaras.size():
		if datos.camaras[i].rota:
			continue
		var o := ojo(i)
		var a := angulo(i)
		var color := CONO_ALARMA if alarma > 0.0 else CONO.lerp(CONO_VE, clampf(sospecha[i], 0.0, 1.0))
		var puntos := PackedVector2Array([o])
		for k in 13:
			var b: float = a - v.abre + v.abre * 2.0 * k / 12.0
			puntos.append(o + Vector2.from_angle(b) * alcance_libre(o, b))
		draw_colored_polygon(puntos, color)


# Hasta dónde llega el cono en esa dirección: lo corta la primera pared o el primer mueble (lo que tapa, no lo ve)
func alcance_libre(o: Vector2, b: float) -> float:
	var fin := o + Vector2.from_angle(b) * Peligros.CAMARAS.alcance
	var rayo := PhysicsRayQueryParameters2D.create(o, fin, 1)
	var choca := get_world_2d().direct_space_state.intersect_ray(rayo)
	return o.distance_to(choca.position) if choca else Peligros.CAMARAS.alcance


# La cámara en la pared: el soporte, la caja gris con su objetivo (mirando hacia donde barre) y el piloto rojo, que
# parpadea; encima, la barrita que se va llenando si te ve. Rota: torcida, sin piloto y con alguna chispa
func dibujar_camara(cuerpo: Node2D, i: int) -> void:
	var c: Dictionary = datos.camaras[i]
	var oscuro: float = mapa.niebla.get(datos.sala, 0.0)
	cuerpo.modulate = Color.WHITE.lerp(Color(0.07, 0.063, 0.11), 0.9 * oscuro)
	var y := ARRIBA
	cuerpo.draw_rect(Rect2(-2, y - 10, 4, 12), Color("#2b2d33"))   # el soporte
	var mira: float = angulo(i) if not c.rota else c.mira + 0.9
	var lado := 1.0 if cos(mira) >= 0.0 else -1.0
	# la caja (dos píxeles del dibujo por unidad), inclinada hacia el lado que mira
	cuerpo.draw_rect(Rect2(-10, y, 20, 10), Color("#1d1f24"))
	cuerpo.draw_rect(Rect2(-8, y + 2, 16, 6), Color("#c9ccd2"))
	cuerpo.draw_rect(Rect2(-8, y + 2, 16, 2), Color("#eef0f3"))
	# el objetivo, en la punta que mira
	cuerpo.draw_rect(Rect2(lado * 8 - 3, y + 2, 6, 6), Color("#1d1f24"))
	cuerpo.draw_rect(Rect2(lado * 8 - 1, y + 4, 2, 2), Color("#5fa8ff") if not c.rota else Color("#333333"))
	if c.rota:
		if int(t * 6.0 + i) % 5 == 0:
			cuerpo.draw_rect(Rect2(randf_range(-8, 8), y + 10, 2, 2), Color("#ffd23f"))
		return
	var encendido: bool = alarma > 0.0 or sin(t * 5.0 + i) > 0.2
	cuerpo.draw_rect(Rect2(-lado * 6 - 1, y + 4, 2, 2), PILOTO if encendido else Color("#4a1515"))
	if sospecha[i] > 0.0 and alarma <= 0.0:
		var alto := 12.0
		var lleno := roundf(alto * sospecha[i] / 2.0) * 2.0
		cuerpo.draw_rect(Rect2(-3, y - 30, 6, alto), Color(0, 0, 0, 0.6))
		cuerpo.draw_rect(Rect2(-3, y - 30 + alto - lleno, 6, lleno), Color("#ffb03b"))
