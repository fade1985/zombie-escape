# La modista: una de los cuatro minijefes del centro comercial (su tienda, el Taller de costura). La encargada de
# la tienda de ropa, alta y tiesa como un maniquí, con unas tijeras de sastre enormes. Lo común de los minijefes,
# en minijefe.gd.
#
# Su tienda está llena de maniquíes de cuerpo entero con su mismo vestido (el mueble "tallmannequin" del
# catálogo), y juega con ellos:
#   - Se esconde: le brillan los ojos un instante y se cambia de sitio con un maniquí lejano (el maniquí aparece
#     donde estaba ella). Allí se queda quieta, de frente, como uno más. Si Johnny se le acerca o le pega, salta;
#     si no, le tira alfileres desde allí o se vuelve a cambiar. Al llegar al sitio nuevo le brillan otra vez los
#     ojos, un momento: quien esté atento sabe dónde se ha metido.
#   - Ráfaga de alfileres: marca una raya en el suelo (que sigue a Johnny hasta un poco antes de tirar) y lanza
#     unos cuantos seguidos, en línea recta: 8 cada uno.
#   - Tijeretazo: si Johnny está cerca, marca en rojo un trozo de suelo (medio segundo) y corta: 22 y empuja.
# Enfadada (a media vida): 3 maniquíes cobran vida (maniqui_vivo.gd: solo se mueven cuando Johnny no los mira),
# se cambia de sitio más a menudo y las ráfagas son más largas.
extends Minijefe

const VIVO := preload("res://scripts/maniqui_vivo.gd")
const BALA := preload("res://escenas/armas/bala_zombi.tscn")
const MANIQUI := "tallmannequin"   # los maniquíes de su tienda (catalogo.gd)
const VELOCIDAD := 90.0
# Los alfileres: cuántos en cada ráfaga (normal y enfadada), cada cuánto sale uno, lo deprisa que vuelan y el daño
const ALFILERES := [5, 7]
const CADA_ALFILER := 0.09
const VELOCIDAD_ALFILER := 480.0
const DANO_ALFILER := 8
const AVISO_ALFILERES := [0.7, 0.5]
const FIJA := 0.2                  # la raya deja de seguir a Johnny este rato antes de tirar
const GIRO_RAYA := 2.5             # lo deprisa que la raya sigue a Johnny (radianes por segundo)
const ALCANCE_ALFILERES := 700.0   # más lejos que esto no tira
const AVISO_TIJERETAZO := 0.5
const ALCANCE_TIJERETAZO := 110.0
const MEDIO_TIJERETAZO := 0.8      # medio ángulo del trozo que corta
const DANO_TIJERETAZO := 22
const DISTANCIA_TIJERETAZO := 140.0   # si Johnny está más cerca que esto, prefiere el tijeretazo
# Esconderse entre los maniquíes
const OJOS := 0.6                  # lo que le brillan los ojos antes de cambiarse de sitio
const OJOS_LLEGAR := 0.35          # y al llegar al sitio nuevo
const ESCONDIDA := [2.6, 1.8]      # lo que se queda quieta como un maniquí más (normal y enfadada)
const CAMBIOS := [7.0, 4.5]        # cada cuánto se cambia de sitio
const LEJOS_DE_JOHNNY := 260.0     # el maniquí con el que se cambia está por lo menos así de lejos de Johnny
const DESPIERTA := 130.0           # escondida, si Johnny se le acerca más que esto, salta
const OTRA_VEZ := [0.25, 0.5]      # al dejar de esconderse, lo probable que vuelva a cambiarse de sitio
const VIVOS := 3                   # los maniquíes que cobran vida al enfadarse
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
const PIE_MANIQUI := Vector2(0, 26)   # su centro, respecto a los pies de un maniquí (para ponerse en su sitio)
# Los fotogramas de sus animaciones en los que corta las tijeras (el tajo blanco; hacia la izquierda, en el 5) y
# lanza los alfileres (el brazo ya estirado)
const CORTA := 4
const LANZA := 4
# Dónde tiene los ojos en cada dirección (respecto a su centro), para el brillo; de espaldas, solo el resplandor
const OJOS_EN := {"s": [Vector2(-5, -91), Vector2(1, -91)], "se": [Vector2(0, -91), Vector2(5, -91)],
	"so": [Vector2(-9, -91), Vector2(-4, -91)], "e": [Vector2(4, -86)], "o": [Vector2(-8, -86)],
	"n": [], "ne": [], "no": []}
const CABEZA := Vector2(-2, -89)

var espera_tijeretazo := 1.0
var espera_alfileres := 1.5
var espera_cambio := 3.0
var vivos: Array = []
var ojos: Node2D                   # el brillo de los ojos, que se ve también a oscuras


func _ready() -> void:
	super()
	ojos = Node2D.new()
	ojos.name = "Ojos"
	ojos.z_index = 2
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ojos.material = sin_luz
	ojos.draw.connect(_pintar_ojos)
	add_child(ojos)
	# al aparecer ya está escondida: ocupa el sitio de un maniquí (sin dejar otro donde estaba)
	empezar_escondida.call_deferred()


func empezar_escondida() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	var m: Node2D = maniqui_lejos(johnny) if johnny else null
	if m == null:
		return
	global_position = m.global_position - PIE_MANIQUI
	m.get_parent().remove_child(m)
	m.queue_free()
	rehornear()
	mirada = Vector2.DOWN
	cambiar("escondida", {"dur": ESCONDIDA[0] + 1.0, "llegada": false})


func pensar(delta: float, johnny: Node2D) -> void:
	espera_tijeretazo -= delta
	espera_alfileres -= delta
	espera_cambio -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			perseguir(delta, johnny, VELOCIDAD)
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if t >= dur:
				elegir(johnny, hacia, d)
		"aviso_tijeretazo":
			frenar(delta)
			if t >= AVISO_TIJERETAZO:
				cambiar("tijeretazo", {"angulo": datos.angulo})
				tijeretazo(johnny)
		"tijeretazo":
			frenar(delta)
			if t >= 0.4:
				andar(0.5 if enfadado() else 0.8)
		"aviso_alfileres":
			# la raya sigue a Johnny (despacio) hasta un poco antes de tirar
			frenar(delta)
			if t < datos.aviso - FIJA:
				var paso := GIRO_RAYA * delta
				datos.angulo += clampf(angle_difference(datos.angulo, hacia.angle()), -paso, paso)
				mirada = Vector2.from_angle(datos.angulo)
			if t >= datos.aviso:
				cambiar("alfileres", {"angulo": datos.angulo, "quedan": ALFILERES[fase - 1], "siguiente": 0.0})
		"alfileres":
			frenar(delta)
			datos.siguiente -= delta
			if datos.quedan > 0 and datos.siguiente <= 0.0:
				lanzar_alfiler(datos.angulo + randf_range(-0.03, 0.03))
				datos.quedan -= 1
				datos.siguiente = CADA_ALFILER
			elif datos.quedan <= 0 and datos.siguiente <= -0.25:
				andar(0.5 if enfadado() else 0.8)
		"ojos":
			# le brillan los ojos... y se cambia de sitio (si le pegan antes, se queda: la han pillado)
			frenar(delta)
			if datos.get("pillada", false):
				pillada(johnny, hacia, d)
			elif t >= OJOS:
				cambiarse(johnny)
		"escondida":
			marcha = Vector2.ZERO
			contacto = 0
			mirada = Vector2.DOWN
			if datos.get("pillada", false) or d < DESPIERTA:
				pillada(johnny, hacia, d)
			elif t >= datos.dur:
				salir(johnny, hacia, d)
		"pillada":
			# un respingo (su animación de golpe) y salta a por Johnny
			frenar(delta)
			if t >= 0.35:
				if d < DISTANCIA_TIJERETAZO + 40.0:
					apuntar_tijeretazo(hacia)
				elif d < ALCANCE_ALFILERES and ve_a(johnny):
					apuntar_alfileres(hacia)
				else:
					andar(0.4)


func elegir(johnny: Node2D, hacia: Vector2, d: float) -> void:
	if d < DISTANCIA_TIJERETAZO and espera_tijeretazo <= 0.0:
		apuntar_tijeretazo(hacia)
		return
	if espera_cambio <= 0.0 and d > 180.0 and maniqui_lejos(johnny) != null:
		espera_cambio = CAMBIOS[fase - 1]
		cambiar("ojos")
		return
	if d > 160.0 and d < ALCANCE_ALFILERES and espera_alfileres <= 0.0 and ve_a(johnny):
		apuntar_alfileres(hacia)
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


func apuntar_tijeretazo(hacia: Vector2) -> void:
	espera_tijeretazo = 1.0 if enfadado() else 1.4
	mirada = hacia.normalized()
	cambiar("aviso_tijeretazo", {"angulo": hacia.angle()})


func apuntar_alfileres(hacia: Vector2) -> void:
	espera_alfileres = 2.0 if enfadado() else 2.8
	mirada = hacia.normalized()
	cambiar("aviso_alfileres", {"angulo": hacia.angle(), "aviso": AVISO_ALFILERES[fase - 1]})


# El tijeretazo: daña y empuja a Johnny si está dentro del trozo marcado
func tijeretazo(johnny: Node2D) -> void:
	Sonido.tocar("tijeras")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_TIJERETAZO and desvio <= MEDIO_TIJERETAZO + 0.15:
		johnny.recibir_dano(DANO_TIJERETAZO, self)
		johnny.empujar(hacia.normalized() * 650.0)


# Un alfiler: una bala de los malos (bala_zombi.gd) con forma de aguja
func lanzar_alfiler(angulo: float) -> void:
	var dir := Vector2.from_angle(angulo)
	var bala := BALA.instantiate()
	bala.dueno = self
	bala.position = position + dir * (radio + 6.0)
	bala.velocidad = dir * VELOCIDAD_ALFILER
	bala.dano = DANO_ALFILER
	bala.radio = 5.0
	bala.forma = "alfiler"
	get_parent().add_child(bala)
	Sonido.tocar("alfiler")


# ¿Ve a Johnny desde donde está? (los muebles y los maniquíes tapan)
func ve_a(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# ── Los maniquíes ──

# Los maniquíes de cuerpo entero que hay en el sitio (los muebles de su tienda)
func maniquies() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary \
		and m.datos.get("tipo", "") == MANIQUI)


# Uno al azar lejos de Johnny (y no pegado a ella), o null si no hay
func maniqui_lejos(johnny: Node2D) -> Node2D:
	var buenos := maniquies().filter(func(m): return m.global_position.distance_to(johnny.global_position) > LEJOS_DE_JOHNNY \
		and m.global_position.distance_to(global_position + PIE_MANIQUI) > 120.0)
	return buenos.pick_random() if not buenos.is_empty() else null


# Se cambia de sitio con un maniquí: ella va a donde estaba él y él aparece donde estaba ella
func cambiarse(johnny: Node2D) -> void:
	var m := maniqui_lejos(johnny)
	if m == null:
		andar(0.3)
		return
	var antes := global_position
	var paso: Vector2 = antes + PIE_MANIQUI - m.global_position
	global_position = m.global_position - PIE_MANIQUI
	m.global_position += paso
	m.datos.x += paso.x
	m.datos.y += paso.y
	rehornear()
	soplo(antes)
	soplo(global_position)
	Sonido.tocar("esquiva")
	marcha = Vector2.ZERO
	mirada = Vector2.DOWN
	cambiar("escondida", {"dur": ESCONDIDA[fase - 1], "llegada": true})


# Deja de estar escondida sin que la pillen: alfileres desde allí, otro cambio de sitio o a andar
func salir(johnny: Node2D, hacia: Vector2, d: float) -> void:
	if d > 170.0 and d < ALCANCE_ALFILERES and ve_a(johnny):
		apuntar_alfileres(hacia)
	elif randf() < OTRA_VEZ[fase - 1] and maniqui_lejos(johnny) != null:
		cambiar("ojos")
	else:
		andar(0.4)


# ¿Está quieta entre los maniquíes? (el apuntado automático de Johnny no la busca: johnny.gd)
func escondida() -> bool:
	return estado == "escondida"


# Si le pegan escondida (o con los ojos brillando), la han pillado: el golpe le hace el daño de siempre
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	if estado == "escondida" or estado == "ojos":
		datos.pillada = true
	return cantidad


func pillada(_johnny: Node2D, _hacia: Vector2, _d: float) -> void:
	espera_cambio = CAMBIOS[fase - 1]
	cambiar("pillada")
	gritar("¡SSSS!", Color("#ff5d73"), 20)


# El mapa vuelve a mirar por dónde se puede andar (los maniquíes han cambiado de sitio)
func rehornear() -> void:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.has_method("rehornear"):
		mapa.rehornear()


# Un soplo de hilos y trocitos de tela donde aparece o desaparece
func soplo(donde: Vector2) -> void:
	for i in 10:
		Particulas.soltar(self, donde + Vector2(randf_range(-22, 22), randf_range(-90, 20)),
			Vector2.from_angle(randf() * TAU) * randf_range(40.0, 90.0),
			[Color("#6b1f2a"), Color("#e8dcc4"), Color("#e8b33a")][i % 3], 3, 0.5)


# Enfadada: tres maniquíes cobran vida (los de la tienda; si no hay bastantes, aparecen a su alrededor)
func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡TE TOMO MEDIDAS!")
	despertar_maniquies(johnny)


func despertar_maniquies(johnny: Node2D) -> void:
	var lista := maniquies().filter(func(m): return m.global_position.distance_to(johnny.global_position) > 200.0)
	lista.shuffle()
	var donde := []
	for m in lista.slice(0, VIVOS):
		donde.append(m.global_position)
		m.get_parent().remove_child(m)
		m.queue_free()
	if not donde.is_empty():
		rehornear()
	while donde.size() < VIVOS:
		var a := donde.size() * TAU / VIVOS + randf() * 0.5
		donde.append(global_position + PIE_MANIQUI + Vector2(cos(a), sin(a) * 0.8) * 130.0)
	Bestiario.apuntar("maniqui")   # visto: al bestiario de las Colecciones del ordenador
	for p in donde:
		var vivo := VIVO.new()
		get_parent().add_child(vivo)
		vivo.global_position = p - Vector2(0, VIVO.PIE)
		vivos.append(vivo)


func morir() -> void:
	super()
	ojos.queue_redraw()
	# sin ella, los maniquíes vuelven a ser maniquíes (y se caen)
	for vivo in vivos:
		if is_instance_valid(vivo):
			vivo.morir()
	# mientras no tenga su animación de muerte (solo la vista quieta), cae de lado
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_tijeretazo":
			fijar("tijeretazo", dir, mini(CORTA - 1, int(t / AVISO_TIJERETAZO * CORTA)))
		"tijeretazo":
			var resto := sprite.sprite_frames.get_frame_count("tijeretazo_" + dir) - CORTA
			fijar("tijeretazo", dir, CORTA + clampi(int(t / 0.4 * resto), 0, maxi(0, resto - 1)))
		"aviso_alfileres":
			fijar("alfileres", dir, mini(LANZA - 1, int(t / datos.aviso * LANZA)))
		"alfileres":
			# con el brazo fuera mientras salen; luego vuelve a la postura
			var total := sprite.sprite_frames.get_frame_count("alfileres_" + dir)
			var k: float = t / (ALFILERES[fase - 1] * CADA_ALFILER + 0.25)
			fijar("alfileres", dir, LANZA + clampi(int(k * (total - LANZA)), 0, maxi(0, total - LANZA - 1)))
		"pillada":
			# el respingo, desde el fotograma 2 (en el 1 PixelLab pintó una raya blanca en varias direcciones)
			var total := sprite.sprite_frames.get_frame_count("golpe_" + dir)
			fijar("golpe", dir, mini(total - 1, 2 + int(t / 0.35 * (total - 2))))
		"ojos", "escondida":
			fijar("quieto", dir, 0)
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)
	ojos.queue_redraw()


# Los avisos, en el suelo (por debajo de ella)
func _draw() -> void:
	if estado == "muerto":
		return
	var rojo := Color(1, 0.24, 0.35)
	match estado:
		"aviso_tijeretazo":
			var k := minf(1.0, t / AVISO_TIJERETAZO)
			var puntos := PackedVector2Array([Vector2.ZERO])
			for i in 17:
				var b: float = datos.angulo - MEDIO_TIJERETAZO + i / 16.0 * MEDIO_TIJERETAZO * 2.0
				puntos.append(Vector2.from_angle(b) * ALCANCE_TIJERETAZO)
			draw_set_transform(Vector2(0, 6))
			draw_colored_polygon(puntos, Color(rojo, 0.1 + k * 0.25))
			puntos.append(Vector2.ZERO)
			draw_polyline(puntos, Color(rojo, 0.9), 3.0)
		"aviso_alfileres":
			# una raya fina por donde irán los alfileres, que se va llenando
			var k := minf(1.0, t / datos.aviso)
			var fija: bool = t >= datos.aviso - FIJA
			draw_set_transform(Vector2(0, 6), datos.angulo)
			draw_rect(Rect2(radio, -5, ALCANCE_ALFILERES, 10), Color(rojo, 0.08 + k * 0.15))
			draw_line(Vector2(radio, 0), Vector2(radio + ALCANCE_ALFILERES * k, 0), Color(rojo, 0.95 if fija else 0.6), 2.0)


# El brillo de los ojos: antes de cambiarse de sitio (cada vez más fuerte) y al llegar al sitio nuevo (se apaga)
func _pintar_ojos() -> void:
	var k := 0.0
	if estado == "ojos":
		k = minf(1.0, t / (OJOS * 0.5))
	elif estado == "escondida" and datos.get("llegada", false) and t < OJOS_LLEGAR:
		k = 1.0 - t / OJOS_LLEGAR
	if k <= 0.0:
		return
	var dir := direccion()
	var cabeza: Vector2 = CABEZA if OJOS_EN[dir].is_empty() else (OJOS_EN[dir][0] + OJOS_EN[dir][-1]) / 2.0
	ojos.draw_circle(cabeza, 16.0, Color(1.0, 0.36, 0.45, 0.18 * k))
	for p in OJOS_EN[dir]:
		ojos.draw_circle(p, 4.5, Color(1.0, 0.42, 0.5, 0.45 * k))
		ojos.draw_rect(Rect2(p - Vector2(2, 1), Vector2(4, 2)), Color(1.0, 0.95, 0.7, k))
