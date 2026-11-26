# Un hilo de la modista (fase 1, «la tienda»; modista.gd y docs/JEFES_CENTRO.md). Ella tira un carrete que rueda por
# el suelo hasta la pared y va dejando un hilo tendido detrás. Los hilos se quedan y van llenando la sala como una
# telaraña:
#   - Flojo (lo normal): pisarlo enreda a Johnny (el estado "enredado": anda más despacio), pero no le hace daño.
#   - Tenso: cuando ella grita «¡A TENSAR!» (tensar()), se pone rojo y avisa un momento (AVISO, con el abanico por
#     donde va a pasar pintado en el suelo), y luego tira de él: el hilo **barre la sala** como una guadaña, girando
#     sobre el carrete clavado en la pared (BARRIDO, hacia donde está ella; las paredes lo paran). A quien pilla le
#     quita DANO y lo deja **atado** un momento (el estado "atado"), y ella va corriendo a por él (modista.gd, atado).
#     Después se queda flojo donde ha acabado.
#   - Cortado: solo a golpes (johnny.gd, golpear): los tiros lo atraviesan. Uno de cada tres es **doble** (más
#     gordo): el primer golpe le quita una hebra y hace falta otro. Al pasar a la fase 2, se caen todos (caer).
# El carrete que rueda también da (DANO_CARRETE, una vez). Va por el suelo: los muebles no lo paran, las paredes sí.
# Se dibuja con código, a cuadraditos de 2. Se crea con HiloModista.new(); se le pone "dir" y "dueno" y se mete en
# la escena con su global_position donde empieza.
class_name HiloModista
extends Node2D

const VELOCIDAD := 380.0      # lo deprisa que rueda el carrete
const GROSOR := 12.0          # lo cerca que tiene que estar Johnny del hilo para tocarlo
const DANO := 14
const DANO_CARRETE := 8
const AVISO := 0.8
const TENSO := 0.55            # lo que tarda en barrer
const BARRIDO := 0.8           # lo que gira al tensar (radianes: unos 45 grados)
const MAX_LARGO := 1400.0
const HILO := Color("#e8dcc4")
const SOMBRA := Color(0.1, 0.05, 0.08, 0.35)
const ROJO := Color("#ff3a4a")
const MADERA := Color("#b07a46")
const MADERA_OSCURA := Color("#6a4424")

var dir := Vector2.RIGHT
var dueno: Node2D = null
var largo := 0.0              # hasta dónde ha llegado el carrete
var fondo := MAX_LARGO        # dónde está la pared
var estado := "rodando"       # rodando, flojo, aviso, tenso o cortado
var t := 0.0
var dio := false              # ya ha dado a Johnny en esta tensada (o el carrete al pasar)
var tiempo := 0.0
var oculto := false           # en la pasarela (fase 2): a oscuras no se ve; solo en la luz del foco o con un brillo que lo recorre
var doble := false            # el gordo: aguanta dos golpes
var ancla := Vector2.ZERO     # tensando, el carrete (sobre el que gira)
var desde := Vector2.ZERO     # tensando, dónde empezaba el alfiler
var giro := 0.0               # tensando, lo que va a girar (con signo)


func _ready() -> void:
	add_to_group("hilos")
	z_index = -1   # en el suelo, por debajo de todos
	dir = dir.normalized()
	# luce por sí mismo: que se vea también a oscuras
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = sin_luz
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.has_method("muro_entre"):
		var choque: Dictionary = mapa.muro_entre(global_position, global_position + dir * MAX_LARGO)
		if not choque.is_empty():
			fondo = maxf(0.0, global_position.distance_to(choque.position) - 8.0)


func tendido() -> bool:
	return estado in ["flojo", "aviso", "tenso"]


# Ella tira de todos: se ponen rojos y, tras el aviso, hacen daño
func tensar() -> void:
	if estado != "flojo":
		return
	estado = "aviso"
	t = 0.0
	dio = false
	ancla = punta()
	desde = global_position
	# gira hacia donde está ella (que tira), lo que dejen las paredes
	var brazo := desde - ancla
	var lado := 1.0 if randf() < 0.5 else -1.0
	if is_instance_valid(dueno):
		var a := angle_difference(brazo.angle(), (dueno.global_position - ancla).angle())
		if absf(a) > 0.05:
			lado = signf(a)
	giro = 0.0
	var mapa := get_tree().get_first_node_in_group("mapa")
	for i in range(1, 9):
		var g := lado * BARRIDO * i / 8.0
		if mapa and mapa.has_method("muro_entre") and not mapa.muro_entre(ancla, ancla + brazo.rotated(g)).is_empty():
			break
		giro = g


# Dónde va el alfiler a esa altura del barrido (0 al empezar, 1 al acabar)
func en_barrido(u: float) -> Vector2:
	return ancla + (desde - ancla).rotated(giro * u)


func _physics_process(delta: float) -> void:
	t += delta
	tiempo += delta
	var johnny := get_tree().get_first_node_in_group("jugador")
	match estado:
		"rodando":
			largo = minf(largo + VELOCIDAD * delta, fondo)
			if johnny and johnny.vivo and not dio and punta().distance_to(johnny.global_position) < 18.0 + johnny.RADIO:
				dio = true
				johnny.recibir_dano(DANO_CARRETE, dueno if is_instance_valid(dueno) else self)
			if largo >= fondo:
				estado = "flojo"
				t = 0.0
				dio = false
				Sonido.tocar("alfiler")
		"flojo":
			if johnny and johnny.vivo and toca(johnny.global_position):
				johnny.pisar({"enredado": {}})
		"aviso":
			if t >= AVISO:
				estado = "tenso"
				t = 0.0
				Sonido.tocar("tijeras")
		"tenso":
			# barre: el alfiler gira alrededor del carrete (deprisa al principio, frenando al final)
			var antes := global_position
			var u := minf(1.0, t / TENSO)
			global_position = en_barrido(1.0 - (1.0 - u) * (1.0 - u))
			dir = (ancla - global_position).normalized()
			var pillado: bool = johnny != null and johnny.vivo and not dio and (toca(johnny.global_position)
				or Geometry2D.point_is_inside_triangle(johnny.global_position, ancla, antes, global_position))
			if pillado:
				dio = true
				johnny.recibir_dano(DANO, dueno if is_instance_valid(dueno) else self)
				johnny.pisar({"atado": {}})
				if is_instance_valid(dueno) and dueno.has_method("atado"):
					dueno.atado(johnny)
			if t >= TENSO:
				estado = "flojo"
				t = 0.0
		"cortado":
			if t >= 0.35:
				queue_free()
	queue_redraw()


# Dónde está el carrete (o el final del hilo)
func punta() -> Vector2:
	return global_position + dir * largo


# ¿Está ese punto encima del hilo?
func toca(p: Vector2, margen := GROSOR) -> bool:
	return distancia(p) < margen


func distancia(p: Vector2) -> float:
	var a := global_position
	var b := punta()
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


# Un golpe de Johnny desde "desde" hacia "angulo", con ese alcance y medio ángulo (johnny.gd, golpear): si pilla algún
# trozo del hilo, lo corta
func cortar_golpe(desde: Vector2, angulo: float, alcance: float, mitad: float) -> bool:
	if not tendido() and estado != "rodando":
		return false
	var cerca := Geometry2D.get_closest_point_to_segment(desde, global_position, punta())
	var hacia := cerca - desde
	if hacia.length() > alcance + 14.0:
		return false
	if hacia.length() > 20.0 and absf(angle_difference(angulo, hacia.angle())) > mitad + 0.35:
		# el más cercano queda fuera del golpe; puede que otro trozo caiga dentro (la punta del arma)
		var punta_golpe := desde + Vector2.from_angle(angulo) * alcance
		if not toca(punta_golpe, 22.0):
			return false
	if doble:
		# el gordo: este golpe le quita una hebra; con el siguiente, se corta
		doble = false
		for i in 4:
			Particulas.soltar(get_parent(), cerca, Vector2.from_angle(randf() * TAU) * randf_range(30.0, 70.0), HILO, 2, 0.4)
		Sonido.tocar("tijeras")
		return true
	cortar()
	return true


func cortar() -> void:
	if estado == "cortado":
		return
	var donde := global_position + dir * largo * 0.5
	for i in 6:
		Particulas.soltar(get_parent(), donde + dir * randf_range(-largo * 0.4, largo * 0.4),
			Vector2.from_angle(randf() * TAU) * randf_range(30.0, 80.0), HILO, 2, 0.5)
	estado = "cortado"
	t = 0.0
	Sonido.tocar("tijeras")


# Al pasar a la fase 2 se caen todos (sin ruido)
func caer() -> void:
	estado = "cortado"
	t = 0.0


func _draw() -> void:
	var b := dir * largo
	var k := 1.0
	var color := HILO
	var comba := 4.0          # lo que cuelga por el medio (flojo); tenso, recto
	match estado:
		"aviso":
			# parpadea al rojo cada vez más deprisa
			var parpadeo := sin(tiempo * (14.0 + t * 30.0)) > 0.0
			color = ROJO if parpadeo else HILO.lerp(ROJO, 0.4)
			comba = 4.0 * (1.0 - t / AVISO)
		"tenso":
			color = ROJO.lightened(0.25)
			comba = 0.0
		"cortado":
			k = 1.0 - t / 0.35
	if k <= 0.0:
		return
	if estado == "aviso":
		pintar_abanico()
	elif estado == "tenso":
		# la estela del barrido: el hilo un poco antes, desvaído
		for e in [0.12, 0.24]:
			var u := maxf(0.0, t / TENSO - e)
			var p := en_barrido(1.0 - (1.0 - u) * (1.0 - u)) - global_position
			var q := ancla - global_position
			var m := int(p.distance_to(q) / 4.0)
			for i in m + 1:
				var c := (p.lerp(q, float(i) / maxf(1.0, m)) / 2.0).floor() * 2.0
				draw_rect(Rect2(c, Vector2(2, 2)), Color(ROJO, 0.35 - e))
	var n := int(largo / 2.0)
	var lado := dir.orthogonal()
	if lado.y < 0.0:
		lado = -lado   # (la comba, siempre hacia abajo en la pantalla)
	var focos: Array = get_tree().get_nodes_in_group("foco_modista") if oculto else []
	var brillo := fmod(tiempo, 2.6) / 0.8   # (oculto: por dónde va el brillo que lo recorre; pasado 1, ninguno)
	for i in n + 1:
		var u := float(i) / maxf(1.0, n)
		var p := b * u + lado * comba * sin(u * PI)
		var c := (p / 2.0).floor() * 2.0
		var ve := k
		if oculto:
			ve = k * (1.0 if focos.any(func(f): return f.alumbra(global_position + c)) else
				(0.85 if absf(u - brillo) < 0.05 else 0.06))
		draw_rect(Rect2(c + Vector2(0, 4), Vector2(2, 2)), Color(SOMBRA, SOMBRA.a * ve))
		draw_rect(Rect2(c, Vector2(2, 2)), Color(color, ve))
		if doble:
			draw_rect(Rect2(c + lado.round() * 2.0, Vector2(2, 2)), Color(color.darkened(0.3), ve))
	if estado == "tenso":
		# el brillo del hilo tenso
		for i in range(0, n + 1, 3):
			var c := ((b * float(i) / maxf(1.0, n)) / 2.0).floor() * 2.0
			draw_rect(Rect2(c - Vector2(2, 2), Vector2(6, 6)), Color(ROJO, 0.18))
	# el alfiler clavado donde empieza
	draw_rect(Rect2(Vector2(-2, -8), Vector2(2, 8)), Color("#c8ccd4"))
	draw_rect(Rect2(Vector2(-4, -10), Vector2(6, 4)), ROJO)
	if estado == "rodando":
		pintar_carrete(b)
	elif estado != "cortado":
		# el carrete, ya parado contra la pared
		pintar_carrete(b)


# El aviso del barrido: por dónde va a pasar el hilo, un abanico de puntitos rojos (el arco que hace el alfiler y unas
# rayas de lo que barre) que se encienden según se acerca el tirón
func pintar_abanico() -> void:
	if absf(giro) < 0.01:
		return
	var fuerza := minf(1.0, t / AVISO)
	var q := ancla - global_position
	var largo_brazo := desde.distance_to(ancla)
	var pasos := int(absf(giro) * largo_brazo / 5.0)
	for i in pasos + 1:
		var p := en_barrido(float(i) / maxf(1.0, pasos)) - global_position
		draw_rect(Rect2((p / 2.0).floor() * 2.0 - Vector2(1, 1), Vector2(4, 4)), Color(ROJO, 0.4 + 0.5 * fuerza))
	for u in [0.25, 0.5, 0.75, 1.0]:
		var p := en_barrido(u) - global_position
		var m := int(p.distance_to(q) / 6.0)
		for i in m + 1:
			var c := (p.lerp(q, float(i) / maxf(1.0, m)) / 2.0).floor() * 2.0
			draw_rect(Rect2(c, Vector2(2, 2)), Color(ROJO, (0.3 + 0.5 * fuerza) * (0.6 if u < 1.0 else 1.0)))


# El carrete (6×8 píxeles del dibujo): dos tapas de madera y el hilo enrollado; rodando, las rayas giran
func pintar_carrete(en: Vector2) -> void:
	var c := (en / 2.0).floor() * 2.0 + Vector2(-6, -10)
	draw_rect(Rect2(c + Vector2(0, 14), Vector2(12, 4)), Color(0, 0, 0, 0.3))   # su sombra
	draw_rect(Rect2(c, Vector2(12, 2)), MADERA)
	draw_rect(Rect2(c + Vector2(0, 12), Vector2(12, 2)), MADERA_OSCURA)
	draw_rect(Rect2(c + Vector2(2, 2), Vector2(8, 10)), HILO)
	var fase_raya := int(largo / 6.0) % 3 if estado == "rodando" else 0
	for y in range(2 + fase_raya * 2, 12, 6):
		draw_rect(Rect2(c + Vector2(2, y), Vector2(8, 2)), HILO.darkened(0.25))
