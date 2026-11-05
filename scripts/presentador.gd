# El presentador: el tercer minijefe de Torre Velaria (parte 5 del plan, docs/PLAN_TERCER_EDIFICIO.md, «Los cuatro
# minijefes»). El de «el futuro del trabajo»: americana azul brillante, tupé engominado, micrófono de diadema y sonrisa
# de anuncio. Su sala, el Plató de presentaciones: la pantalla gigante, el atril y dos focos de pie en el escenario y,
# en el resto, filas de butacas con un público de zombis sentados. Lo común de los minijefes, en minijefe.gd.
#
#   - Grito al micrófono («¡¿ME OÍS AL FONDO?!»): marca en el suelo un cono hacia Johnny y suelta una onda que le
#     EMPUJA hacia atrás y le quita DANO_GRITO.
#   - Focos («¡UN APLAUSO!»): un foco del escenario se enciende y su haz va siguiendo a Johnny por el suelo. Si Johnny
#     está dentro y mira hacia el foco, la pantalla se pone blanca un momento (cegar).
#   - Confeti («¡SORPRESA!»): cañones de confeti que marcan el suelo donde va estando Johnny y revientan al momento
#     (confeti.gd).
#   - El público: al llegar, sienta a PUBLICO oficinistas en las butacas (dormidos y "sentados": zombi.gd). No se
#     despiertan ni viéndole ni oyendo tiros, solo si les pegan.
# Enfadado (a media vida): «¡EN PIE, PÚBLICO!»: el público se levanta todo a la vez. Y grita dos veces y más ancho, los
# dos focos a la vez y más cañones. Si muere, los que sigan sentados se desploman con él.
# Números provisionales: se ajustan jugando.
extends Minijefe

const VELOCIDAD := 85.0
const AVISO_GRITO := [0.8, 0.65]     # lo que se ve el cono antes de la onda
const ABRE_GRITO := [0.52, 0.8]      # la mitad del cono (en radianes: unos 60° y 90° de ancho)
const ALCANCE_GRITO := 270.0
const DANO_GRITO := 12
const EMPUJE := 950.0
const OTRO_GRITO := 0.55             # enfadado: el segundo grito, tanto después del primero
const FOCOS := [1, 2]                # los focos que enciende a la vez
const HAZ := 4.5                     # lo que dura encendido un foco
const ENCIENDE := 0.6                # lo que tarda en dar de lleno (antes, no ciega)
const RADIO_HAZ := 62.0              # el círculo de luz en el suelo
const SIGUE_HAZ := [95.0, 125.0]     # lo deprisa que el círculo sigue a Johnny
const MIRAR := 0.9                   # si Johnny apunta así de cerca de la dirección del foco (radianes), le ciega
const CEGADO := 1.3                  # lo que dura la pantalla blanca (entera un rato y luego se va)
const ENTRE_CEGADOS := 2.0           # después de cegarle, este rato sin volver a cegar
const CABEZA_FOCO := Vector2(0, -124)   # dónde está la luz del foco, respecto a sus pies
const CANONES := [4, 6]
const CADA_CANON := 0.35
const AVISO_CONFETI := 0.9
const DANO_CONFETI := 10
const PUBLICO := 10                  # los oficinistas que sienta en las butacas
const PIE := 30.0                    # a qué altura dibuja los pies respecto a su centro
const BUTACAS := "theaterseats"
const FOCO := "spotlight"
const CHASQUIDO := 1.0               # lo que dura su animación de chasquear los dedos

var espera_grito := 1.2
var espera_focos := 3.0
var espera_confeti := 6.0
var haces: Array = []                # los focos encendidos: {"foco", "punto", "t"}
var cegado_t := 0.0                  # lo que le queda a la pantalla blanca
var sin_cegar := 0.0
var publico: Array = []              # los oficinistas sentados
var onda := {}                       # la onda del grito que se va abriendo (para dibujarla): {"angulo", "abre", "t"}
var suelo: Node2D                    # lo que se dibuja en el suelo, sin luz: el cono del grito y el círculo de los focos
var luz: Node2D                      # los haces de luz, por encima de todo
var blanco: ColorRect                # la pantalla blanca de los focos


func pensar(delta: float, johnny: Node2D) -> void:
	espera_grito -= delta
	espera_focos -= delta
	espera_confeti -= delta
	match estado:
		"andar":
			mirada = global_position.direction_to(johnny.global_position)
			perseguir(delta, johnny, VELOCIDAD)
			if t >= dur:
				elegir(johnny)
		"microfono":
			frenar(delta)
			var aviso: float = AVISO_GRITO[fase - 1]
			if t < aviso * 0.5:
				datos.angulo = global_position.direction_to(johnny.global_position).angle()
				mirada = Vector2.from_angle(datos.angulo)
			var gritos := 2 if enfadado() else 1
			if datos.gritos < gritos and t >= aviso + datos.gritos * OTRO_GRITO:
				datos.gritos += 1
				gritar_al_microfono(johnny)
			if t >= aviso + (gritos - 1) * OTRO_GRITO + 0.6:
				andar(0.6 if enfadado() else 0.9)
		"focos":
			frenar(delta)
			if t >= 0.45 and not datos.get("hecho", false):
				datos.hecho = true
				encender_focos(johnny)
			if t >= CHASQUIDO:
				andar(0.4)
		"confeti":
			frenar(delta)
			var n: int = CANONES[fase - 1]
			if t >= 0.45 + datos.puestos * CADA_CANON and datos.puestos < n:
				datos.puestos += 1
				poner_canon(johnny)
			if datos.puestos >= n and t >= CHASQUIDO:
				andar(0.5)


func elegir(johnny: Node2D) -> void:
	if espera_focos <= 0.0 and haces.is_empty():
		espera_focos = 9.0 if enfadado() else 12.0
		cambiar("focos")
		gritar(Idioma.t("¡UN APLAUSO!"), Color("#ffe9a0"), 18)
		return
	if espera_confeti <= 0.0:
		espera_confeti = 6.0 if enfadado() else 8.0
		cambiar("confeti", {"puestos": 0})
		gritar(Idioma.t("¡SORPRESA!"), Color("#ff4d8d"), 18)
		return
	if espera_grito <= 0.0 and global_position.distance_to(johnny.global_position) < ALCANCE_GRITO + 120.0:
		espera_grito = 3.2 if enfadado() else 4.0
		var a := global_position.direction_to(johnny.global_position).angle()
		cambiar("microfono", {"angulo": a, "gritos": 0})
		gritar(Idioma.t("¡¿ME OÍS AL FONDO?!"), Color("#7fe0ff"), 18)
		return
	andar(0.3)


# ── El grito al micrófono ──

# La onda: si Johnny está dentro del cono (y no hay una pared en medio), le quita lo suyo y le empuja hacia fuera
func gritar_al_microfono(johnny: Node2D) -> void:
	var abre: float = ABRE_GRITO[fase - 1]
	onda = {"angulo": datos.angulo, "abre": abre, "t": 0.0}
	Sonido.tocar("microfono")
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() > ALCANCE_GRITO + johnny.RADIO or absf(angle_difference(datos.angulo, hacia.angle())) > abre:
		return
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
		return   # (detrás de una pared, no le llega)
	johnny.recibir_dano(DANO_GRITO, self)
	johnny.empujar(hacia.normalized() * EMPUJE)


# ── Los focos ──

func focos() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary \
		and m.datos.get("tipo", "") == FOCO)


# Enciende los focos (uno, o los dos enfadado; si no hay focos en la sala, ninguno): su círculo de luz sale a medio
# camino entre el foco y Johnny y va a por él
func encender_focos(johnny: Node2D) -> void:
	var lista := focos()
	lista.shuffle()
	for i in mini(FOCOS[fase - 1], lista.size()):
		var f: Node2D = lista[i]
		haces.append({"foco": f, "punto": f.global_position.lerp(johnny.global_position, 0.6), "t": 0.0})
	if not lista.is_empty():
		Sonido.tocar("foco")


func mover_haces(delta: float) -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	for h in haces.duplicate():
		h.t += delta
		if h.t >= HAZ or not is_instance_valid(h.foco):
			haces.erase(h)
			continue
		if johnny == null or not johnny.vivo:
			continue
		var paso: float = SIGUE_HAZ[fase - 1] * delta
		h.punto = h.punto.move_toward(johnny.global_position, paso)
		if h.t >= ENCIENDE and sin_cegar <= 0.0 and h.punto.distance_to(johnny.global_position) < RADIO_HAZ \
				and mira_al_foco(johnny, h.foco):
			cegar()


# Si Johnny está mirando (o apuntando) hacia la luz del foco
func mira_al_foco(johnny: Node2D, f: Node2D) -> bool:
	var i: int = DIRS.find(johnny.direccion)
	if i < 0:
		return false
	var hacia: Vector2 = f.global_position + CABEZA_FOCO - johnny.global_position
	return absf(angle_difference(i * PI / 4.0, hacia.angle())) < MIRAR


func cegar() -> void:
	cegado_t = CEGADO
	sin_cegar = CEGADO + ENTRE_CEGADOS
	Sonido.tocar("foco")
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny:
		Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(-40, -70), Idioma.t("¡Cegado!"),
			Color("#ffe9a0"), 18)


# ── El confeti ──

func poner_canon(johnny: Node2D) -> void:
	var c := Confeti.new()
	c.position = johnny.global_position
	c.aviso = AVISO_CONFETI
	c.dano = DANO_CONFETI
	c.dueno = self
	get_parent().add_child(c)
	Sonido.tocar("lanzar")


# El suelo de su sala (la principal del sitio), en unidades
func sala() -> Rect2:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.sitio.has("apt") and not mapa.sitio.apt.salas.is_empty() and mapa.sitio.apt.salas[0].has("c0"):
		var s: Dictionary = mapa.sitio.apt.salas[0]
		return Rect2(Vector2(s.c0, s.f0) * 32.0, Vector2(s.ancho, s.fondo) * 32.0)
	return Rect2(global_position - Vector2(400, 300), Vector2(800, 600))


# ── El público ──

# Sienta a los oficinistas en butacas al azar: de pie justo detrás del respaldo (que les tapa las piernas), mirando al
# escenario, dormidos y "sentados" (zombi.gd: no se despiertan solos)
func sentar_publico() -> void:
	var partida := get_tree().current_scene
	if not partida.has_method("meter_zombi"):
		return
	var asientos := []
	for m in get_tree().get_nodes_in_group("muebles"):
		if m.get("datos") is Dictionary and m.datos.get("tipo", "") == BUTACAS:
			var largo: float = Catalogo.MUEBLES[BUTACAS].len
			for k in 4:
				asientos.append(m.global_position + Vector2(-largo / 2.0 + (k + 0.5) * largo / 4.0, -Catalogo.MUEBLES[BUTACAS].dep - 20.0))
	asientos.shuffle()
	for i in mini(PUBLICO, asientos.size()):
		var z: Node2D = partida.meter_zombi("oficinista", asientos[i])
		z.dormido = true
		z.sentado = true
		# (si no, se apartan y se empujan unos a otros, tan juntos, y se salen de su butaca)
		z.agente.avoidance_enabled = false
		z.set_collision_mask_value(Zombi.CAPA_ZOMBIS, false)
		z.mirar_hacia(Vector2.UP)
		publico.append(z)


# Enfadado: todos en pie a la vez (con un pelín de diferencia, para que no parezca un solo muñeco)
func levantar_publico() -> void:
	for z in publico:
		if is_instance_valid(z) and z.sentado:
			get_tree().create_timer(randf_range(0.0, 0.5), false).timeout.connect(func():
				if is_instance_valid(z) and z.sentado:
					z.despertar())


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡EN PIE, PÚBLICO!"))
	haces.clear()
	levantar_publico()


func morir() -> void:
	haces.clear()
	cegado_t = 0.0
	# los que siguen sentados se desploman con él: se acabó la función
	for z in publico:
		if is_instance_valid(z) and z.sentado:
			z.herir(99999.0)
	super()


# En la foto de la prueba (--captura): gritando al micrófono
func foto(johnny: Node2D) -> void:
	cambiar("microfono", {"angulo": global_position.direction_to(johnny.global_position).angle(), "gritos": 0})


func _ready() -> void:
	super()
	# lo del suelo y la luz, en las coordenadas del mapa (top_level): el suelo sin luz y por debajo de todo; los haces,
	# sumando luz y por encima
	suelo = Node2D.new()
	suelo.top_level = true
	suelo.z_as_relative = false
	suelo.z_index = -1
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	suelo.material = sin_luz
	suelo.draw.connect(pintar_suelo)
	add_child(suelo)
	luz = Node2D.new()
	luz.top_level = true
	luz.z_as_relative = false
	luz.z_index = 3
	var suma := CanvasItemMaterial.new()
	suma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	luz.material = suma
	luz.draw.connect(pintar_luz)
	add_child(luz)
	# la pantalla blanca, por encima del juego y del HUD
	var capa := CanvasLayer.new()
	capa.layer = 30
	add_child(capa)
	blanco = ColorRect.new()
	blanco.color = Color(1, 1, 1, 0)
	blanco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blanco.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(blanco)
	sentar_publico.call_deferred()


func _process(delta: float) -> void:
	if estado != "muerto":
		mover_haces(delta)
	sin_cegar -= delta
	cegado_t = maxf(0.0, cegado_t - delta)
	# entera la mitad del rato y luego se va
	blanco.color.a = clampf(cegado_t / (CEGADO * 0.5), 0.0, 1.0)
	if not onda.is_empty():
		onda.t += delta
		if onda.t > 0.45:
			onda = {}
	suelo.queue_redraw()
	luz.queue_redraw()


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"microfono":
			# coge aire mientras se ve el cono (fotogramas 0 a 2) y grita (3 a 7)
			var aviso: float = AVISO_GRITO[fase - 1]
			var f := 0
			if t < aviso:
				f = int(t / aviso * 3.0)
			else:
				f = 3 + int((t - aviso) / 0.12) % 5
			fijar("grito", dir, mini(f, 7))
		"focos", "confeti":
			fijar("chasquear", "s", avance("chasquear_s", minf(1.0, t / CHASQUIDO)))
		"grito":
			fijar("grito", "s", 5)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


# En el suelo, sin luz: el cono del grito que viene (se llena mientras avisa) y el círculo de cada foco
func pintar_suelo() -> void:
	if estado == "microfono" and t < AVISO_GRITO[fase - 1] + (1 if enfadado() else 0) * OTRO_GRITO:
		var lleno := clampf(t / AVISO_GRITO[fase - 1], 0.0, 1.0)
		var abre: float = ABRE_GRITO[fase - 1]
		var puntos := PackedVector2Array([global_position])
		for i in 13:
			puntos.append(global_position + Vector2.from_angle(datos.angulo - abre + abre * 2.0 * i / 12.0) * ALCANCE_GRITO)
		suelo.draw_colored_polygon(puntos, Color("#7fe0ff", 0.12 + 0.18 * lleno))
		suelo.draw_polyline(puntos + PackedVector2Array([global_position]), Color("#7fe0ff", 0.8), 2.0)
	for h in haces:
		var k := clampf(h.t / ENCIENDE, 0.0, 1.0)
		suelo.draw_set_transform(h.punto, 0.0, Vector2(1.0, 0.6))
		suelo.draw_circle(Vector2.ZERO, RADIO_HAZ, Color(1.0, 0.95, 0.7, 0.18 + 0.3 * k))
		suelo.draw_arc(Vector2.ZERO, RADIO_HAZ, 0.0, TAU, 32, Color(1.0, 0.95, 0.7, 0.7 * k), 2.0)
		suelo.draw_set_transform(Vector2.ZERO)


# Por encima, sumando luz: el haz de cada foco (de su luz al círculo del suelo) y la onda del grito, que se abre
func pintar_luz() -> void:
	for h in haces:
		if not is_instance_valid(h.foco):
			continue
		var k := clampf(h.t / ENCIENDE, 0.0, 1.0) * clampf((HAZ - h.t) / 0.3, 0.0, 1.0)
		var desde: Vector2 = h.foco.global_position + CABEZA_FOCO
		var lado: Vector2 = (h.punto - desde).orthogonal().normalized() * RADIO_HAZ
		luz.draw_colored_polygon(PackedVector2Array([desde + lado * 0.12, desde - lado * 0.12, h.punto - lado, h.punto + lado]),
			Color(0.35, 0.33, 0.22, 0.5 * k))
		luz.draw_circle(desde, 12.0, Color(0.8, 0.78, 0.55, k))
	if not onda.is_empty():
		var r: float = ALCANCE_GRITO * clampf(onda.t / 0.3, 0.1, 1.0)
		var a := clampf(1.0 - onda.t / 0.45, 0.0, 1.0)
		for i in 3:
			var ri := r - i * 26.0
			if ri > 10.0:
				luz.draw_arc(global_position, ri, onda.angulo - onda.abre, onda.angulo + onda.abre, 16,
					Color(0.5, 0.85, 1.0, 0.7 * a), 5.0 - i)
