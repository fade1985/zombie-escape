# Un hilo de la modista (fase 1, «la tienda»; modista.gd y docs/JEFES_CENTRO.md). Ella tira un carrete que rueda por
# el suelo hasta la pared y va dejando un hilo tendido detrás. Los hilos se quedan y van llenando la sala como una
# telaraña:
#   - Flojo (lo normal): pisarlo enreda a Johnny (el estado "enredado": anda más despacio), pero no le hace daño.
#   - Tenso: cuando ella grita «¡A TENSAR!» (tensar()), se pone rojo y avisa un momento (AVISO), y luego, durante
#     TENSO, quita DANO a quien lo toque. Después vuelve a quedarse flojo.
#   - Cortado: un golpe (johnny.gd, golpear) o un tiro (bala.gd) lo cortan (cortar_en); al pasar a la fase 2, se
#     caen todos (caer).
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
const TENSO := 0.5
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
	if estado == "flojo":
		estado = "aviso"
		t = 0.0
		dio = false


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
			if johnny and johnny.vivo and not dio and toca(johnny.global_position):
				dio = true
				johnny.recibir_dano(DANO, dueno if is_instance_valid(dueno) else self)
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


# Un tiro que pasa por encima lo corta (bala.gd). Devuelve si lo ha cortado
func cortar_en(p: Vector2) -> bool:
	if not tendido() and estado != "rodando" or not toca(p, 10.0):
		return false
	cortar()
	return true


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
	var n := int(largo / 2.0)
	var lado := dir.orthogonal()
	if lado.y < 0.0:
		lado = -lado   # (la comba, siempre hacia abajo en la pantalla)
	for i in n + 1:
		var u := float(i) / maxf(1.0, n)
		var p := b * u + lado * comba * sin(u * PI)
		var c := (p / 2.0).floor() * 2.0
		draw_rect(Rect2(c + Vector2(0, 4), Vector2(2, 2)), Color(SOMBRA, SOMBRA.a * k))
		draw_rect(Rect2(c, Vector2(2, 2)), Color(color, k))
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
