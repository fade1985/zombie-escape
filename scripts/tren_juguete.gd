# El tren de juguete de la Juguetería (la sala de la mascota, minijefe del centro comercial; docs/JEFES_CENTRO.md,
# «La fiesta de cumpleaños»). Unas vías dan la vuelta a la sala (un rectángulo con las esquinas redondeadas, pintado con
# código en el suelo) y el tren (locomotora y VAGONES vagones, dibujos de PixelLab en 8 direcciones) espera en su
# estación. Cuando la mascota lo manda (mascota.gd, salir()), pita («¡CHU-CHUUU!»), las vías se encienden en rojo
# AVISO s y da una vuelta entera a la sala a VELOCIDAD. Es una franja que sigue un camino fijo: hay que cruzar las vías
# por delante o por detrás del tren, o esquivando. Si pilla a Johnny le quita DANO y le aparta a un lado. Si pilla a la
# mascota mareada o sentada encima de las vías, la atropella (DANO_JEFE): un premio para quien la lleve hasta ahí.
# Se crea con TrenJuguete.new(), se le pone "dueno" (la mascota) y se mete en la escena en el medio de la sala.
class_name TrenJuguete
extends Node2D

const LOCOMOTORA := preload("res://assets/sprites/tren-locomotora.png")
const VAGON := preload("res://assets/sprites/tren-vagon.png")
const VAGONES := 3
const SEPARA := 50.0        # de un vagón al siguiente, a lo largo de la vía
const VELOCIDAD := 400.0
const AVISO := 1.3
const DANO := 16
const DANO_JEFE := 45
const RADIO := 24.0         # lo que pilla cada vagón
const MARGEN := 130.0       # lo que se separan las vías de las paredes
const MAX_MEDIO := Vector2(560, 270)   # lo más grande que es el rectángulo (la mitad de su ancho y de su alto)
const CURVA := 70.0         # el radio de las esquinas
const ANCHO_VIA := 11.0     # de cada raíl al centro de la vía
const MAX_LADO := 1400.0

var dueno: Node2D = null
var puntos := PackedVector2Array()   # el camino, en el mundo, cerrado (el último punto es el primero)
var largos := PackedFloat32Array()   # lo andado hasta cada punto
var largo := 0.0
var s := 0.0                # dónde está la locomotora, a lo largo del camino
var estado := "parado"      # "parado", "aviso" o "corre"
var t := 0.0
var recorrido := 0.0        # en la vuelta de ahora, lo que lleva
var espera_johnny := 0.0
var atropellada := false    # en esta vuelta ya ha atropellado a la mascota
var coches: Array[Sprite2D] = []
var vias: Node2D


func _ready() -> void:
	add_to_group("tren_juguete")
	y_sort_enabled = true
	vias = Node2D.new()
	vias.z_index = -1   # en el suelo, por debajo de todos
	vias.draw.connect(pintar_vias)
	add_child(vias)
	trazar()
	for i in VAGONES + 1:
		var c := Sprite2D.new()
		c.texture = LOCOMOTORA if i == 0 else VAGON
		c.hframes = 8
		c.scale = Vector2(2, 2)
		c.offset = Vector2(0, -6)
		add_child(c)
		coches.append(c)
	s = SEPARA * VAGONES + 10.0   # (en su estación: el primer tramo recto de arriba)
	colocar()


# El camino: un rectángulo con las esquinas redondeadas alrededor del medio de la sala, separado de las paredes
func trazar() -> void:
	var medio := Vector2(minf(hasta_pared(Vector2.LEFT), hasta_pared(Vector2.RIGHT)),
		minf(hasta_pared(Vector2.UP), hasta_pared(Vector2.DOWN))) - Vector2(MARGEN, MARGEN)
	medio = medio.clamp(Vector2(CURVA + 60, CURVA + 40), MAX_MEDIO)
	var c := global_position
	var r := CURVA
	# las cuatro esquinas (sus centros), en el sentido de las agujas del reloj desde arriba a la izquierda
	var esquinas := [c + Vector2(-medio.x + r, -medio.y + r), c + Vector2(medio.x - r, -medio.y + r),
		c + Vector2(medio.x - r, medio.y - r), c + Vector2(-medio.x + r, medio.y - r)]
	var desde_angulo := [PI, -PI / 2.0, 0.0, PI / 2.0]
	puntos.clear()
	for i in 4:
		for k in 7:   # cada curva, en 6 trozos
			var a: float = desde_angulo[i] + k * (PI / 2.0) / 6.0
			puntos.append(esquinas[i] + Vector2.from_angle(a) * r)
	puntos.append(puntos[0])
	largos.clear()
	largo = 0.0
	largos.append(0.0)
	for i in range(1, puntos.size()):
		largo += puntos[i - 1].distance_to(puntos[i])
		largos.append(largo)


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


# El sitio y la dirección del camino a "d" de su principio: [punto, dirección]
func en(d: float) -> Array:
	d = fposmod(d, largo)
	var i := 1
	while i < largos.size() - 1 and largos[i] < d:
		i += 1
	var a := puntos[i - 1]
	var b := puntos[i]
	var tramo := largos[i] - largos[i - 1]
	var k := (d - largos[i - 1]) / tramo if tramo > 0.0 else 0.0
	return [a.lerp(b, k), a.direction_to(b)]


# Lo cerca que está "p" de las vías (para no poner cajas encima)
func cerca_de_via(p: Vector2, margen: float) -> bool:
	for i in range(1, puntos.size()):
		if Geometry2D.get_closest_point_to_segment(p, puntos[i - 1], puntos[i]).distance_to(p) < margen:
			return true
	return false


# ¡Viajeros al tren! Pita y avisa; luego da una vuelta
func salir() -> void:
	if estado != "parado":
		return
	estado = "aviso"
	t = 0.0
	Sonido.tocar("silbato")
	Zombi.texto_flotante(get_parent(), coches[0].global_position + Vector2(-60, -70), Idioma.t("¡CHU-CHUUU!"), Color("#ffd23f"), 20)


func _physics_process(delta: float) -> void:
	t += delta
	espera_johnny -= delta
	vias.queue_redraw()
	match estado:
		"aviso":
			# echa humo por la chimenea, impaciente
			if randf() < delta * 20.0:
				Particulas.soltar(get_parent(), coches[0].global_position + Vector2(0, -34), Vector2(randf_range(-20, 20), -70),
					Color("#e8e8e8", 0.8), randf_range(3, 6), 0.6)
			if t >= AVISO:
				estado = "corre"
				recorrido = 0.0
				atropellada = false
		"corre":
			var paso := VELOCIDAD * delta
			s += paso
			recorrido += paso
			if randf() < delta * 14.0:
				Particulas.soltar(get_parent(), coches[0].global_position + Vector2(0, -34), Vector2(randf_range(-30, 30), -60),
					Color("#e8e8e8", 0.7), randf_range(3, 6), 0.5)
			pillar()
			if recorrido >= largo:
				estado = "parado"
	colocar()


# Cada coche en su sitio, mirando hacia donde va (su dibujo de las 8 direcciones)
func colocar() -> void:
	for i in coches.size():
		var donde: Array = en(s - i * SEPARA)
		var c := coches[i]
		c.global_position = donde[0]
		c.frame = wrapi(roundi((donde[1] as Vector2).angle() / (PI / 4.0)), 0, 8)
		# corriendo, traquetea un poco
		c.offset.y = -6.0 - (absf(sin(t * 22.0 + i)) * 2.0 if estado == "corre" else 0.0)


# Lo que pilla al pasar: Johnny (si no esquiva) y la mascota, si está mareada o sentada encima de las vías
func pillar() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	for i in coches.size():
		var c := coches[i]
		var dir: Vector2 = en(s - i * SEPARA)[1]
		if johnny and johnny.vivo and espera_johnny <= 0.0 and johnny.esquiva_t <= 0.0 \
				and c.global_position.distance_to(johnny.global_position) < RADIO + johnny.RADIO:
			johnny.recibir_dano(DANO, dueno)
			var fuera: Vector2 = dir.orthogonal()
			if fuera.dot(johnny.global_position - c.global_position) < 0.0:
				fuera = -fuera
			johnny.empujar(fuera * 1100.0)
			espera_johnny = 0.8
			Sonido.tocar("golpe")
			Temblor.temblar(6.0)
		if is_instance_valid(dueno) and not atropellada and dueno.estado in ["atontado", "sorpresa"] \
				and c.global_position.distance_to(dueno.global_position) < RADIO + dueno.radio:
			atropellada = true
			dueno.recibir_golpe(DANO_JEFE, dir, true)
			Temblor.temblar(10.0)
			Zombi.texto_flotante(get_parent(), dueno.global_position + Vector2(-50, -150), Idioma.t("¡ATROPELLO!"), Color("#ff5d73"), 22)


# Las vías, en el suelo: las traviesas de madera y los dos raíles; avisando, se encienden en rojo y parpadean
func pintar_vias() -> void:
	var rojo := 0.0
	if estado == "aviso":
		rojo = 0.55 + 0.45 * absf(sin(t * 12.0))
	elif estado == "corre":
		rojo = 0.35
	var madera := Color("#6b4a2e").lerp(Color("#c0392b"), rojo * 0.6)
	var riel := Color("#a8adb8").lerp(Color("#ff5d5d"), rojo)
	var oscuro := Color("#3c3f48")
	# las traviesas, cada 22 a lo largo
	var d := 0.0
	while d < largo:
		var e: Array = en(d)
		var p: Vector2 = vias.to_local(e[0])
		var lado: Vector2 = (e[1] as Vector2).orthogonal()
		vias.draw_line(p - lado * (ANCHO_VIA + 8.0), p + lado * (ANCHO_VIA + 8.0), madera.darkened(0.35), 10.0)
		vias.draw_line(p - lado * (ANCHO_VIA + 7.0) + Vector2(0, -1), p + lado * (ANCHO_VIA + 7.0) + Vector2(0, -1), madera, 6.0)
		d += 20.0
	# los raíles: dos líneas a cada lado del centro, con su sombra
	for signo in [-1.0, 1.0]:
		var linea := PackedVector2Array()
		for i in puntos.size():
			var antes := puntos[maxi(i - 1, 0)]
			var luego := puntos[mini(i + 1, puntos.size() - 1)]
			var lado := antes.direction_to(luego).orthogonal()
			if i == 0 or i == puntos.size() - 1:
				lado = puntos[puntos.size() - 2].direction_to(puntos[1]).orthogonal()
			linea.append(vias.to_local(puntos[i] + lado * ANCHO_VIA * signo))
		vias.draw_polyline(linea, oscuro, 6.0)
		var arriba := linea.duplicate()
		for i in arriba.size():
			arriba[i] += Vector2(0, -2)
		vias.draw_polyline(arriba, riel, 4.0)
