# El ventanal roto de Marketing y Dirección, en Torre Velaria (peligros.gd, VIENTO): un hueco en la pared de un lado de la
# sala grande, con los cristales rotos y la ciudad de noche detrás. La corriente empuja hacia él a todo lo que haya en la
# sala (a Johnny y a los zombis despiertos), más cuanto más cerca, y a rachas: un rato flojo y otro fuerte. Detrás de un
# mueble no sopla (un rayo del personaje hacia el ventanal que choca con algo antes de llegar), así que se cruza pegado a
# las mesas. En el borde, Johnny se agarra (le quita vida y sale despedido hacia dentro) y los zombis salen volando por
# la ventana: cuentan como muertos, pero no dejan cuerpo ni sueltan nada (partida.gd, "ventana").
#
# Se dibuja todo con código: el hueco con la ciudad y los cristales (en el muro), las cortinas que se agitan a los lados,
# las rayas del aire y los papeles que vuelan hacia el ventanal.
extends Node2D

const CASILLA := 32
const PAPELES := 22
const RAYAS := 26
const CIELO := Color("#0d1630")
const CIELO_ABAJO := Color("#1c2850")
const MARCO := Color("#3b4352")
const CRISTAL := Color(0.75, 0.88, 1.0, 0.75)
const CORTINA := Color("#8a8f99")
const CORTINA_SOMBRA := Color("#5f646e")

var datos: Dictionary
var mapa: Node
var zona: Rect2              # la sala grande, en unidades
var hacia := 1.0             # hacia dónde sopla: -1 a la izquierda, 1 a la derecha
var hueco: Node2D            # el ventanal, en el muro
var aire: Node2D             # las rayas y los papeles, por encima de todo
var papeles: Array = []      # [x, y, vuelta, giro, semilla]
var rayas: Array = []        # [x, y, largo, rapidez]
var luces: Array = []        # las ventanas encendidas de la ciudad: [x, y, color]
var t := 0.0
var agarre := 0.0            # tras agarrarse al borde, un momento sin que vuelva a pasar
var sonido_t := 0.0


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Viento"   # no-tr (nombre de nodo)
	var sala: Dictionary = m.sitio.apt.salas[d.sala]
	zona = Rect2(sala.c0 * CASILLA, sala.f0 * CASILLA, sala.ancho * CASILLA, sala.fondo * CASILLA)
	hacia = -1.0 if d.lado == "izquierda" else 1.0
	# el ventanal va en el muro del lado, por encima del muro (que se dibuja en el suelo)
	hueco = Node2D.new()
	hueco.name = "Ventanal"
	hueco.z_index = 3
	hueco.draw.connect(dibujar_hueco)
	add_child(hueco)
	aire = Node2D.new()
	aire.name = "Aire"
	aire.z_index = 4   # los papeles vuelan por delante de los personajes
	aire.light_mask = Luz.capa_sala(d.sala)
	aire.draw.connect(dibujar_aire)
	add_child(aire)
	# una luz fría que entra por el hueco (la de la ciudad)
	var luz := PointLight2D.new()
	luz.texture = preload("res://escenas/luces/luz_suave.tres")
	luz.texture_scale = 3.0
	luz.color = Color(0.6, 0.72, 1.0)
	luz.energy = 0.9
	luz.position = Vector2(d.x - hacia * 40.0, (d.y0 + d.y1) / 2.0)
	add_child(luz)
	for i in PAPELES:
		papeles.append([randf() * zona.size.x, randf() * zona.size.y, randf_range(0.6, 1.4), randf() * TAU, randf() * TAU])
	for i in RAYAS:
		rayas.append([randf() * zona.size.x, randf() * zona.size.y, randf_range(14, 34), randf_range(0.7, 1.3)])
	var dado := RandomNumberGenerator.new()
	dado.seed = int(d.x * 7 + d.y0)
	for i in 22:
		luces.append([dado.randi_range(0, 26), dado.randi_range(2, int((d.y1 - d.y0) / 2.0) - 4),
			[Color("#ffd27a"), Color("#fff1c2"), Color("#9fd8ff")][dado.randi() % 3]])


# Lo fuerte que sopla ahora (de 0 a 1): flojo entre racha y racha, y la racha sube y baja suave
func fuerza() -> float:
	var v: Dictionary = Peligros.VIENTO
	var ciclo: float = fposmod(t, v.calma + v.racha)
	if ciclo < v.calma:
		return v.flojo
	var k: float = sin((ciclo - v.calma) / v.racha * PI)
	return lerpf(v.flojo, 1.0, k)


func en_racha() -> bool:
	return fposmod(t, Peligros.VIENTO.calma + Peligros.VIENTO.racha) >= Peligros.VIENTO.calma


# El punto del hueco más cercano a "p" (en la cara de dentro del muro)
func boca(p: Vector2) -> Vector2:
	return Vector2(datos.x, clampf(p.y, datos.y0 + 8.0, datos.y1 - 8.0))


# El empujón (unidades por segundo) que le toca a quien esté en "p": cero fuera de la sala o al abrigo de un mueble
func empuje(p: Vector2, quien: Node) -> Vector2:
	if not zona.has_point(p):
		return Vector2.ZERO
	var meta := boca(p)
	var lejos := absf(p.x - datos.x) / zona.size.x
	var v: Dictionary = Peligros.VIENTO
	var cuanto: float = lerpf(v.cerca, v.lejos, clampf(lejos, 0.0, 1.0)) * fuerza()
	# al abrigo: un mueble (o lo que sea) entre él y el ventanal, cerca
	var hasta := p + p.direction_to(meta) * minf(v.abrigo, p.distance_to(meta))
	var rayo := PhysicsRayQueryParameters2D.create(p, hasta, 1)
	rayo.exclude = [quien.get_rid()]
	var choca := get_world_2d().direct_space_state.intersect_ray(rayo)
	if choca and absf(choca.position.x - datos.x) > 6.0:
		return Vector2.ZERO
	return p.direction_to(meta) * cuanto


func en_borde(p: Vector2) -> bool:
	return absf(p.x - datos.x) < Peligros.VIENTO.borde and p.y > datos.y0 - 4.0 and p.y < datos.y1 + 4.0


func _physics_process(delta: float) -> void:
	t += delta
	agarre = maxf(agarre - delta, 0.0)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and zona.has_point(johnny.global_position):
		Peligros.avisar(self, datos, Idioma.t("¡Qué corriente! Si me acerco al ventanal, me lleva"))
		johnny.move_and_collide(empuje(johnny.global_position, johnny) * delta)
		if en_borde(johnny.global_position) and agarre <= 0.0:
			agarrarse(johnny)
		# el ruido del viento, más seguido en la racha
		sonido_t -= delta
		if sonido_t <= 0.0:
			sonido_t = 0.9 if en_racha() else 1.6
			Sonido.tocar("viento")
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.get("dormido") or zombi.get("estado") == "muerto" or zombi.has_meta("ventana") or zombi is Minijefe:
			continue
		var p: Vector2 = zombi.global_position
		if not zona.has_point(p):
			continue
		zombi.move_and_collide(empuje(p, zombi) * Peligros.VIENTO.zombis * delta)
		if en_borde(zombi.global_position):
			tirar(zombi)
	for papel in papeles:
		papel[0] += hacia * (70.0 + 120.0 * fuerza()) * papel[2] * delta
		papel[1] += sin(t * 3.0 + papel[4]) * 30.0 * delta
		papel[3] += delta * 6.0 * papel[2]
		if (hacia > 0.0 and papel[0] > zona.size.x) or (hacia < 0.0 and papel[0] < 0.0):
			papel[0] = 0.0 if hacia > 0.0 else zona.size.x
			papel[1] = randf() * zona.size.y
	for raya in rayas:
		raya[0] += hacia * (160.0 + 260.0 * fuerza()) * raya[3] * delta
		if (hacia > 0.0 and raya[0] > zona.size.x + 40.0) or (hacia < 0.0 and raya[0] < -40.0):
			raya[0] = -40.0 if hacia > 0.0 else zona.size.x + 40.0
			raya[1] = randf() * zona.size.y
	# en una sala aún sin descubrir no se ve
	modulate.a = 1.0 - mapa.niebla.get(datos.sala, 0.0)
	hueco.queue_redraw()
	aire.queue_redraw()


# Johnny llega al borde: se agarra al marco (le quita vida) y sale despedido hacia dentro
func agarrarse(johnny: Node2D) -> void:
	agarre = 2.0
	johnny.recibir_dano(Peligros.VIENTO.dano, null, "viento")
	johnny.empujar(Vector2(-hacia, 0.0) * Peligros.VIENTO.rebote)
	Sonido.tocar("cristal")
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("¡Uf! Casi me caigo por la ventana"))


# Un zombi en el borde sale volando por la ventana: cuenta como muerto (sin cuerpo y sin soltar nada) y se va encogiendo
# hacia fuera hasta desaparecer
func tirar(zombi: Node2D) -> void:
	zombi.set_meta("ventana", true)
	zombi.morir()
	var tween := zombi.create_tween().set_parallel()
	tween.tween_property(zombi, "global_position", zombi.global_position + Vector2(hacia * 90.0, -30.0), 0.6)
	tween.tween_property(zombi, "scale", Vector2(0.3, 0.3), 0.6)
	tween.tween_property(zombi, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(zombi.hide)


# Un rectángulo en píxeles del dibujo (2 unidades), con "x" contada desde la cara de dentro del muro hacia fuera
func px(nodo: Node2D, x: float, y: float, w: float, h: float, color: Color) -> void:
	var x0: float = datos.x + (x * 2.0 if hacia > 0.0 else -(x + w) * 2.0)
	nodo.draw_rect(Rect2(x0, datos.y0 + y * 2.0, w * 2.0, h * 2.0), color)


# El hueco del ventanal, en el muro de fuera (las dos casillas): la ciudad de noche (cielo, edificios con ventanas encendidas), el marco
# y los trozos de cristal que quedan en los bordes; a los lados, las cortinas agitándose hacia el hueco
func dibujar_hueco() -> void:
	var alto: float = (datos.y1 - datos.y0) / 2.0   # en píxeles del dibujo
	var ancho := 32.0                              # el muro de fuera entero (dos casillas)
	px(hueco, 0, 0, ancho, alto, CIELO)
	px(hueco, 0, alto * 0.55, ancho, alto * 0.45, CIELO_ABAJO)
	# la ciudad, muy abajo: siluetas y sus ventanitas
	for i in 9:
		var h := 8.0 + float((i * 37) % 13)
		px(hueco, 1 + i * 3.4, alto - h, 3, h, Color("#070b18"))
	for l in luces:
		if int(t * 0.7 + l[1]) % 7 != 0:
			px(hueco, 3 + l[0], l[1], 1, 1, l[2])
	# el marco y los cristales rotos que quedan pegados
	px(hueco, 0, 0, 1, alto, MARCO)
	px(hueco, ancho - 1, 0, 1, alto, MARCO)
	px(hueco, 0, 0, ancho, 1, MARCO)
	px(hueco, 0, alto - 1, ancho, 1, MARCO)
	for k in [[1, 1, 4, 2], [1, 3, 2, 3], [ancho - 4, 1, 3, 2], [1, alto - 4, 3, 3], [ancho - 3, alto - 5, 2, 4]]:
		px(hueco, k[0], k[1], k[2], k[3], CRISTAL)
	# las cortinas: arriba y abajo del hueco, ondeando hacia fuera según sople
	var ondea: float = 2.0 + 4.0 * fuerza()
	for lado in [0, 1]:
		for i in 6:
			var largo: float = 3.0 + ondea * (0.6 + 0.4 * sin(t * 9.0 + i * 1.3 + lado))
			var y: float = 1.0 + i if lado == 0 else alto - 2.0 - i
			px(hueco, -2, y, 2 + largo, 1, CORTINA if i % 2 == 0 else CORTINA_SOMBRA)


# Las rayas del aire (finas y medio transparentes, más en la racha) y los papeles volando y dando vueltas
func dibujar_aire() -> void:
	var f := fuerza()
	for raya in rayas:
		var x: float = zona.position.x + raya[0]
		var y: float = zona.position.y + raya[1]
		aire.draw_rect(Rect2(roundf(x / 2.0) * 2.0, roundf(y / 2.0) * 2.0, raya[2] * (1.0 + f), 2), Color(0.85, 0.9, 1.0, 0.14 + 0.26 * f))
	for papel in papeles:
		var x: float = zona.position.x + papel[0]
		var y: float = zona.position.y + papel[1]
		var ancho: float = 2.0 + 4.0 * absf(cos(papel[3]))   # al girar, se ve de canto
		aire.draw_rect(Rect2(roundf(x / 2.0) * 2.0, roundf(y / 2.0) * 2.0, roundf(ancho / 2.0) * 2.0 + 2.0, 8), Color("#f2efe6"))
		aire.draw_rect(Rect2(roundf(x / 2.0) * 2.0, roundf(y / 2.0) * 2.0 + 2.0, roundf(ancho / 2.0) * 2.0, 2), Color("#b9b5aa"))
