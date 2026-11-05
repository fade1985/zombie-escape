# El becario: el cuarto minijefe de Torre Velaria (parte 5 del plan, docs/PLAN_TERCER_EDIFICIO.md, «Los cuatro
# minijefes»). Camisa que le queda grande, corbata torcida, acreditación colgada y una pila de fotocopias bajo el
# brazo. Su sala, la Sala de fotocopias: fotocopiadoras e impresoras en la pared del fondo y mesas con papeles en medio.
# Lo común de los minijefes, en minijefe.gd.
#
#   - Fotocopias («¡A COPIAR!»): corre a la fotocopiadora más cercana, la máquina echa un destello y salen COPIAS de él
#     (copia_becario.gd): iguales, pero sin sombra y un pelín más claras. Mueren de un golpe y no hacen daño. Con el
#     destello, el de verdad se cambia de sitio con una de ellas: hay que encontrarle. Pistas: solo él tiene sombra, y
#     solo él se refleja en el frontal de las fotocopiadoras que tiene cerca (la pantallita se enciende).
#   - Carrito del correo («¡CORREO URGENTE!»): saca el carrito, marca en el suelo una franja roja y embiste por ella
#     (lo común, en minijefe.gd: embestir). Si se come una pared, se queda atontado un momento.
#   - Café para todos («¡CAFÉ PARA TODOS!»): tira vasos de café en curva donde está Johnny y alrededor (proyectil.gd,
#     "cafe"): dejan un charco de café que resbala (charco.gd).
# Enfadado (a media vida): «¡ME VAN A CONTRATAR!»: saca más copias, las copias también pegan y tira más vasos. Si
# muere, las copias que queden se deshacen en papeles con él.
# Números provisionales: se ajustan jugando.
extends Minijefe

const COPIA := preload("res://escenas/personajes/copia_becario.tscn")

const VELOCIDAD := 120.0
const COPIAS := [3, 5]               # las que saca cada vez
const MAX_COPIAS := 8                # más de estas a la vez, no
const ESPERA_COPIAS := [12.0, 9.0]
const HASTA_COPIADORA := 3.0         # lo más que corre buscando su fotocopiadora (si no llega, copia donde esté)
const COPIANDO := 1.0                # lo que está con la máquina (el destello, a la mitad)
const SEPARA := 56.0                 # lo separadas que salen las copias
const AVISO_CARRITO := [0.8, 0.6]
const VELOCIDAD_CARRITO := 520.0
const TIEMPO_CARRITO := 1.1
const DANO_CARRITO := 14
const ATONTADO := 1.4
const ESPERA_CARRITO := [6.0, 4.5]
const VASOS := [4, 6]
const ESPERA_CAFE := [7.0, 5.5]
const LANZA := 0.4                   # cuándo salen los vasos (el brazo, arriba)
const LANZAR := 0.85                 # lo que dura su animación de tirar
const PIE := 30.0                    # a qué altura dibuja los pies respecto a su centro
const COPIADORA := "copier"
const REFLEJO := 340.0               # a esta distancia de una fotocopiadora (o menos) se refleja en ella
# Dónde está, en una fotocopiadora (respecto a sus pies, en unidades): la pantallita y el frontal donde se refleja
const PANTALLA := Rect2(-26, -80, 22, 8)
const FRONTAL := Rect2(-34, -62, 68, 30)

var espera_copias := 4.0
var espera_carrito := 2.0
var espera_cafe := 5.5
var copias: Array = []               # las copias que siguen enteras
var destellos: Array = []            # el destello de la máquina al copiar: {"copiadora", "t"}
var reflejo: Node2D                  # lo que se ve en las fotocopiadoras, encima de ellas
var carrito: Node2D                  # el carrito del correo, delante de él


func pensar(delta: float, johnny: Node2D) -> void:
	espera_copias -= delta
	espera_carrito -= delta
	espera_cafe -= delta
	match estado:
		"andar":
			mirada = global_position.direction_to(johnny.global_position)
			perseguir(delta, johnny, VELOCIDAD)
			if t >= dur:
				elegir(johnny)
		"a_copiar":
			var c: Node2D = datos.copiadora
			if not is_instance_valid(c):
				cambiar("copiando", {"copiadora": null})
				return
			var boca := boca_de(c)
			agente.target_position = boca
			marcha += (global_position.direction_to(agente.get_next_path_position()) * VELOCIDAD * 1.25 - marcha) \
				* (1.0 - exp(-delta * 6.0))
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if global_position.distance_to(boca) < 26.0 or t >= HASTA_COPIADORA:
				cambiar("copiando", {"copiadora": c})
		"copiando":
			frenar(delta)
			if datos.copiadora != null:
				mirada = Vector2.UP
			if t >= COPIANDO * 0.5 and not datos.get("hecho", false):
				datos.hecho = true
				fotocopiar(datos.copiadora)
			if t >= COPIANDO:
				andar(0.3)
		"aviso_carrito":
			# se gira hacia Johnny mientras la franja roja marca por dónde irá (al final ya no se gira: se puede esquivar)
			frenar(delta, 6.0)
			if t < datos.aviso * 0.7:
				mirada = global_position.direction_to(johnny.global_position)
			if t >= datos.aviso:
				cambiar("carrito")
				Sonido.tocar("carrito")
		"carrito":
			match embestir(delta, johnny, VELOCIDAD_CARRITO, DANO_CARRITO, TIEMPO_CARRITO, PIE):
				"pillado":
					cambiar("recuperar", {"dur": 0.6})
				"pared":
					estrellarse()
				"fin":
					marcha *= 0.3
					cambiar("recuperar", {"dur": 0.5})
		"atontado":
			frenar(delta, 4.0)
			if t >= ATONTADO:
				andar(0.4)
		"recuperar":
			frenar(delta, 5.0)
			if t >= datos.dur:
				andar(0.5 if enfadado() else 0.8)
		"cafe":
			frenar(delta)
			if t < LANZA:
				mirada = global_position.direction_to(johnny.global_position)
			if t >= LANZA and not datos.get("hecho", false):
				datos.hecho = true
				tirar_cafe(johnny)
			if t >= LANZAR:
				andar(0.5 if enfadado() else 0.8)


func elegir(johnny: Node2D) -> void:
	var d := global_position.distance_to(johnny.global_position)
	copias = copias.filter(func(c): return is_instance_valid(c) and c.estado != "muerto")
	if espera_copias <= 0.0 and copias.size() + COPIAS[fase - 1] <= MAX_COPIAS:
		espera_copias = ESPERA_COPIAS[fase - 1]
		var c := copiadora_cercana()
		cambiar("a_copiar" if c else "copiando", {"copiadora": c})
		gritar(Idioma.t("¡A COPIAR!"), Color("#e8f4ff"), 18)
		return
	if espera_carrito <= 0.0 and d > 90.0 and d < VELOCIDAD_CARRITO * TIEMPO_CARRITO:
		espera_carrito = ESPERA_CARRITO[fase - 1]
		cambiar("aviso_carrito", {"aviso": AVISO_CARRITO[fase - 1]})
		gritar(Idioma.t("¡CORREO URGENTE!"), Color("#ff5d73"), 18)
		return
	if espera_cafe <= 0.0 and d < 520.0:
		espera_cafe = ESPERA_CAFE[fase - 1]
		cambiar("cafe")
		gritar(Idioma.t("¡CAFÉ PARA TODOS!"), Color("#d9a066"), 18)
		return
	andar(0.3)


# ── Las fotocopias ──

func copiadoras() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary \
		and m.datos.get("tipo", "") == COPIADORA)


func copiadora_cercana() -> Node2D:
	var mejor: Node2D = null
	for c in copiadoras():
		if mejor == null or global_position.distance_to(boca_de(c)) < global_position.distance_to(boca_de(mejor)):
			mejor = c
	return mejor


# Dónde se pone para copiar: delante de la máquina (las fotocopiadoras están en la pared del fondo)
func boca_de(c: Node2D) -> Vector2:
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), c.global_position + Vector2(0, 34))


# El destello: salen las copias en fila a los lados y él se cambia de sitio con una de ellas (con el destello no se
# ve). Siempre donde se pueda estar
func fotocopiar(c: Node2D) -> void:
	Sonido.tocar("fotocopia")
	Temblor.temblar(3.0)
	if c:
		destellos.append({"copiadora": c, "t": 0.0})
	var n: int = COPIAS[fase - 1]
	var mapa := agente.get_navigation_map()
	var sitios := [global_position]
	for i in n:
		var lado := 1.0 if i % 2 == 0 else -1.0
		var donde := global_position + Vector2(lado * SEPARA * (i / 2 + 1), 30.0 + randf_range(-10.0, 30.0))
		sitios.append(NavigationServer2D.map_get_closest_point(mapa, donde))
	sitios.shuffle()
	global_position = sitios[0]
	for i in range(1, sitios.size()):
		var copia: Node2D = COPIA.instantiate()
		copia.jefe = self
		copia.position = sitios[i]
		copia.mirada = Vector2.DOWN
		get_parent().add_child(copia)
		copias.append(copia)
	for s in sitios:
		for j in 5:
			Particulas.soltar(self, s + Vector2(randf_range(-16, 16), randf_range(-60, 0)),
				Vector2(randf_range(-90, 90), randf_range(-120, -30)), Color("#f4f6f8"), randf_range(3, 5), 0.6)


# Las que siguen enteras (y no el jefe)
func copias_vivas() -> Array:
	copias = copias.filter(func(c): return is_instance_valid(c) and c.estado != "muerto")
	return copias


# ── El café ──

# Dónde caen: el primero donde está Johnny, el segundo a donde va y los demás alrededor (donde se pueda estar)
func destinos_cafe(johnny: Node2D, cuantos: int) -> Array:
	var lista := [johnny.global_position]
	if cuantos > 1:
		lista.append(johnny.global_position + johnny.velocity * 0.7 + Vector2.from_angle(randf() * TAU) * 30.0)
	while lista.size() < cuantos:
		lista.append(johnny.global_position + Vector2.from_angle(randf() * TAU) * randf_range(80.0, 150.0))
	var mapa := agente.get_navigation_map()
	for i in lista.size():
		lista[i] = NavigationServer2D.map_get_closest_point(mapa, lista[i])
	return lista


func tirar_cafe(johnny: Node2D) -> void:
	Sonido.tocar("lanzar")
	for donde in destinos_cafe(johnny, VASOS[fase - 1]):
		var p: Node2D = load("res://escenas/armas/proyectil.tscn").instantiate()
		p.tipo = "cafe"
		p.desde = global_position + mirada * 20.0 + Vector2(0, PIE * 0.5)
		p.alto_salida = arriba * 0.55
		p.hasta = donde
		p.dueno = self
		get_parent().add_child(p)


# El suelo de su sala (la principal del sitio), en unidades
func sala() -> Rect2:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.sitio.has("apt") and not mapa.sitio.apt.salas.is_empty() and mapa.sitio.apt.salas[0].has("c0"):
		var s: Dictionary = mapa.sitio.apt.salas[0]
		return Rect2(Vector2(s.c0, s.f0) * 32.0, Vector2(s.ancho, s.fondo) * 32.0)
	return Rect2(global_position - Vector2(400, 300), Vector2(800, 600))


# ── Enfadarse y morir ──

func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡ME VAN A CONTRATAR!"))
	espera_copias = minf(espera_copias, 1.0)   # enseguida saca más
	for c in copias_vivas():
		c.sprite.modulate = c.TINTE * Color(1.0, 0.8, 0.78)


func morir() -> void:
	# se acabó la oficina: las copias se deshacen en papeles con él
	for c in copias_vivas():
		c.deshacer()
	copias.clear()
	destellos.clear()
	$Sombra2.apagar(1.0)
	super()
	carrito.queue_redraw()


# En la foto de la prueba (--captura): preparando el carrito
func foto(_johnny: Node2D) -> void:
	cambiar("aviso_carrito", {"aviso": 0.8})


func _ready() -> void:
	super()
	# el carrito, en un nodo propio: por delante de él si va hacia abajo o de lado, por detrás si va hacia arriba
	carrito = Node2D.new()
	carrito.draw.connect(pintar_carrito)
	add_child(carrito)
	# lo de las fotocopiadoras, en las coordenadas del mapa (top_level), por encima de los muebles
	reflejo = Node2D.new()
	reflejo.top_level = true
	reflejo.z_as_relative = false
	reflejo.z_index = 1
	reflejo.draw.connect(pintar_reflejo)
	add_child(reflejo)


func _process(delta: float) -> void:
	for d in destellos.duplicate():
		d.t += delta
		if d.t > 0.6 or not is_instance_valid(d.copiadora):
			destellos.erase(d)
	reflejo.queue_redraw()
	carrito.queue_redraw()


# ── Dibujo ──

func con_carrito() -> bool:
	return estado in ["aviso_carrito", "carrito", "atontado", "recuperar"]


func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_carrito":
			fijar("carrito", dir, 1)
		"carrito":
			fijar("carrito", dir, 3 + int(t / 0.07) % 6)
		"recuperar":
			fijar("carrito", dir, 2)
		"cafe":
			fijar("lanzar", dir, avance("lanzar_" + dir, t / LANZAR))
		"copiando":
			# dándole a los botones de la máquina (de espaldas), con el gesto de tirar
			fijar("lanzar", dir, avance("lanzar_" + dir, t / COPIANDO))
		"grito":
			fijar("lanzar", "s", 4)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.5, 1.8))
			else:
				poner("reposo_" + dir)


# El aviso del carrito, en el suelo: la franja roja por donde va a pasar
func _draw() -> void:
	if estado == "aviso_carrito":
		franja(VELOCIDAD_CARRITO * TIEMPO_CARRITO, minf(1.0, t / datos.aviso))


# El carrito del correo: de metal gris, con la saca azul llena de sobres y paquetes, sus cuatro ruedas y el asa hacia
# él. Se dibuja a cuadraditos (2 unidades, un píxel del dibujo), siempre de frente, como los muebles
func pintar_carrito() -> void:
	if estado == "muerto" or not con_carrito():
		return
	carrito.z_index = -1 if mirada.y < -0.4 else 1
	# delante de sus manos (corriendo se inclina mucho hacia delante), y un pelín más grande que un píxel por píxel: así
	# se ve bien que lleva un carrito
	var c := (mirada * Vector2(84.0, 46.0) + Vector2(0, 12)).round()
	c = (c / 2.0).round() * 2.0
	if estado == "carrito":
		c.y += 2.0 if int(t / 0.05) % 2 == 0 else 0.0   # traquetea
	carrito.draw_set_transform(c, 0.0, Vector2(1.5, 1.5))
	c = Vector2.ZERO
	var negro := Color("#1d1b2c")
	# las ruedas
	for x in [-18.0, 14.0]:
		carrito.draw_rect(Rect2(c + Vector2(x, 10), Vector2(6, 6)), negro)
		carrito.draw_rect(Rect2(c + Vector2(x + 2, 12), Vector2(2, 2)), Color("#5a5a66"))
	# la cesta de metal
	carrito.draw_rect(Rect2(c + Vector2(-24, -18), Vector2(48, 30)), negro)
	carrito.draw_rect(Rect2(c + Vector2(-22, -16), Vector2(44, 26)), Color("#8a919c"))
	carrito.draw_rect(Rect2(c + Vector2(-22, -16), Vector2(44, 4)), Color("#b9c0c9"))
	for x in [-12.0, 0.0, 12.0]:
		carrito.draw_rect(Rect2(c + Vector2(x, -12), Vector2(2, 22)), Color("#6a707a"))
	# la saca azul y lo que asoma: sobres blancos y un paquete marrón
	carrito.draw_rect(Rect2(c + Vector2(-20, -26), Vector2(40, 12)), negro)
	carrito.draw_rect(Rect2(c + Vector2(-18, -24), Vector2(36, 10)), Color("#3f6fb0"))
	carrito.draw_rect(Rect2(c + Vector2(-14, -32), Vector2(10, 8)), Color("#f2f2ea"))
	carrito.draw_rect(Rect2(c + Vector2(-12, -30), Vector2(6, 2)), Color("#c9c9c0"))
	carrito.draw_rect(Rect2(c + Vector2(-2, -34), Vector2(8, 10)), Color("#fbfbf5"))
	carrito.draw_rect(Rect2(c + Vector2(6, -30), Vector2(10, 8)), Color("#a8743f"))
	carrito.draw_rect(Rect2(c + Vector2(10, -30), Vector2(2, 8)), Color("#e0c080"))
	# el asa, por el lado de él
	if mirada.y > 0.4:
		carrito.draw_rect(Rect2(c + Vector2(-20, -40), Vector2(40, 3)), negro)
	elif mirada.y < -0.4:
		carrito.draw_rect(Rect2(c + Vector2(-20, 14), Vector2(40, 3)), negro)


# Lo que se ve en las fotocopiadoras que tiene cerca (solo él, no las copias): la pantallita encendida y su reflejo,
# pequeño y azulado, en el frontal de la máquina. Y el destello de la máquina al copiar
func pintar_reflejo() -> void:
	if estado == "muerto":
		return
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	for c in copiadoras():
		var pie: Vector2 = c.global_position
		var d := global_position.distance_to(pie)
		if d > REFLEJO or tex == null:
			continue
		var k := clampf((REFLEJO - d) / 120.0, 0.0, 1.0)
		reflejo.draw_rect(Rect2(pie + PANTALLA.position, PANTALLA.size), Color(0.45, 0.95, 0.85, 0.75 * k))
		# el reflejo: los pies abajo del frontal, más a un lado o al otro según dónde esté él
		var x := clampf((global_position.x - pie.x) * 0.1, -18.0, 18.0)
		var donde := pie + Vector2(x, FRONTAL.end.y - 2.0)
		reflejo.draw_set_transform(donde, 0.0, Vector2(0.4, 0.4) * sprite.scale)
		reflejo.draw_texture(tex, sprite.offset, Color(0.6, 0.75, 0.95, 0.45 * k))
		reflejo.draw_set_transform(Vector2.ZERO)
	for dd in destellos:
		var a := clampf(1.0 - dd.t / 0.6, 0.0, 1.0)
		var p: Vector2 = dd.copiadora.global_position
		reflejo.draw_rect(Rect2(p + Vector2(-40, -116), Vector2(80, 116)), Color(1, 1, 1, 0.55 * a))
		reflejo.draw_rect(Rect2(p + Vector2(-60, -10), Vector2(120, 20)), Color(0.85, 1.0, 0.95, 0.5 * a))
