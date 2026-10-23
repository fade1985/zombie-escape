# El cocinero: uno de los cuatro minijefes del centro comercial (su tienda, la Cocina central). Un cocinero zombi
# enorme y gordo, con su gorro y un cuchillo de carnicero. Lo común de los minijefes, en minijefe.gd.
#
# Es lento y no quiere que te le acerques: se queda a media distancia y te lanza de todo.
#   - Abanico: levanta el brazo (medio segundo, con unas rayas rojas en el suelo por donde irán) y lanza 3
#     cuchillos que giran en el aire (12 cada uno).
#   - Lluvia: tira cuchillos hacia arriba y caen 5 alrededor de Johnny, cada uno con su marca roja en el suelo
#     antes (el primero, justo donde va a estar). Se quedan clavados un rato (cuchillo.gd).
#   - Aceite hirviendo: tira la sartén (sale una marca donde caerá) y deja un charco que quema como el fuego del
#     molotov durante 6 s (charco.gd). A él su aceite no le quema: es el cocinero.
#   - Cuchillazo: si Johnny se le pega, marca un trozo de suelo (medio segundo) y le da: 20.
# Enfadado (a media vida): 5 cuchillos en el abanico y más rápidos, 7 en la lluvia y todo más seguido.
# Sus animaciones (PixelLab): andar, lanzar (vale para el abanico, la lluvia y la sartén), cuchillazo, golpe (al
# enfadarse) y muerte. Lo que lanza sale justo en el fotograma en el que el brazo llega adelante (SUELTA) y el
# cuchillazo hace daño en el del tajo (TAJO).
extends Minijefe

const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const VELOCIDAD := 60.0
const CERCA := 200.0               # si Johnny está más cerca que esto, se aparta...
const LEJOS := 360.0               # ...y si está más lejos, va a por él (entre medias, pasitos de lado)
const AVISO_ABANICO := 0.5
const CUCHILLOS := [3, 5]          # los del abanico (normal y enfadado)
const ABRE := [0.28, 0.22]         # lo que se separan entre sí, en radianes
const VELOCIDAD_CUCHILLO := [340.0, 430.0]
const DANO_CUCHILLO := 12
const LARGO_RAYAS := 280.0         # lo largas que se ven en el suelo las rayas del aviso del abanico
const AVISO_LLUVIA := 0.5          # lo que tarda en tirarlos hacia arriba
const LLUVIA := [5, 7]             # los que caen alrededor de Johnny
const MARCA_LLUVIA := [0.8, 0.6]   # lo que está cada marca en el suelo antes de caer su cuchillo
const HUECO_LLUVIA := 0.15         # entre una marca y la siguiente
const DANO_LLUVIA := 12
const AVISO_SARTEN := 0.6
const AVISO_CUCHILLAZO := 0.5
const ALCANCE_CUCHILLAZO := 110.0
const MEDIO_CUCHILLAZO := 0.9      # medio ángulo del trozo que barre
const DANO_CUCHILLAZO := 20
const DISTANCIA_CUCHILLAZO := 140.0   # si Johnny está más cerca que esto, prefiere el cuchillazo
# lo que espera a repetir cada ataque (normal y enfadado)
const ESPERAS := {"abanico": [2.4, 1.5], "lluvia": [6.5, 4.5], "sarten": [8.0, 6.0], "cuchillazo": [1.4, 1.0]}
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
# El fotograma de "lanzar" con el brazo del todo adelante (cuando sale el cuchillo o la sartén) y el del tajo del
# cuchillazo, según hacia dónde mire
const SUELTA := {"e": 4, "se": 4, "n": 4, "no": 4, "s": 5, "ne": 5, "o": 5, "so": 5}
const TAJO := {"s": 4, "se": 4, "e": 4, "n": 4, "ne": 5, "no": 5, "o": 5, "so": 5}
const DESPUES := 0.4               # lo que tarda en acabar la animación después de soltar (y en volver a andar)
const SUBEN := 0.4                 # la lluvia: lo que se ven subir los cuchillos al tirarlos

var espera := {"abanico": 1.0, "lluvia": 3.0, "sarten": 4.5, "cuchillazo": 0.8}
var lado := 1.0                    # hacia qué lado da los pasitos


func pensar(delta: float, johnny: Node2D) -> void:
	for k in espera:
		espera[k] -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			mirada = hacia.normalized()   # no le quita ojo a Johnny
			guardar_distancia(delta, johnny, hacia, d)
			if t >= dur:
				elegir(johnny, d)
		"aviso_cuchillazo":
			frenar(delta)
			if t >= AVISO_CUCHILLAZO:
				cambiar("cuchillazo", {"angulo": datos.angulo})
				cuchillazo(johnny)
		"aviso_abanico":
			frenar(delta)
			if t >= AVISO_ABANICO:
				cambiar("abanico", {"angulo": datos.angulo})
				abanico()
		"aviso_lluvia":
			frenar(delta)
			mirada = hacia.normalized()
			if t >= AVISO_LLUVIA:
				cambiar("lluvia")
				lluvia(johnny)
		"aviso_sarten":
			frenar(delta)
			mirada = hacia.normalized()
			if t >= AVISO_SARTEN:
				cambiar("sarten")
				sarten(johnny)
		"cuchillazo", "abanico", "lluvia", "sarten":
			frenar(delta)
			if t >= DESPUES:
				andar(0.5 if enfadado() else 0.9)


# A media distancia: si Johnny se acerca, se aparta; si se aleja (o no le ve), va a por él; entre medias,
# pasitos de lado
func guardar_distancia(delta: float, johnny: Node2D, hacia: Vector2, d: float) -> void:
	var quiere := Vector2.ZERO
	if d > LEJOS or not a_la_vista(johnny):
		quiere = camino_a(johnny)
	elif d < CERCA:
		quiere = -hacia.normalized()
	else:
		quiere = hacia.normalized().orthogonal() * lado * 0.5
	marcha += (quiere * VELOCIDAD - marcha) * (1.0 - exp(-delta * 6.0))
	# si se ha topado con algo (andando de lado o hacia atrás), cambia de lado
	if t > 0.3 and marcha.length() > 20.0 and get_real_velocity().length() < 8.0:
		lado = -lado


func elegir(johnny: Node2D, d: float) -> void:
	var f := fase - 1
	var angulo := (johnny.global_position - global_position).angle()
	if d < DISTANCIA_CUCHILLAZO and espera.cuchillazo <= 0.0:
		espera.cuchillazo = ESPERAS.cuchillazo[f]
		empezar("aviso_cuchillazo", angulo)
		return
	if espera.sarten <= 0.0 and d > 120.0 and d < 480.0:
		espera.sarten = ESPERAS.sarten[f]
		empezar("aviso_sarten", angulo)
		gritar("¡CALENTITO!", Color("#ffb347"))
		return
	if espera.lluvia <= 0.0:
		espera.lluvia = ESPERAS.lluvia[f]
		empezar("aviso_lluvia", angulo)
		return
	if espera.abanico <= 0.0 and a_la_vista(johnny):
		espera.abanico = ESPERAS.abanico[f]
		empezar("aviso_abanico", angulo)
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# Empieza un ataque mirando hacia donde está Johnny (el abanico y el cuchillazo van hacia ahí, aunque se mueva)
func empezar(nuevo: String, angulo: float) -> void:
	cambiar(nuevo, {"angulo": angulo})
	mirada = Vector2.from_angle(angulo)


# El cuchillazo: daña y empuja a Johnny si está dentro del trozo marcado
func cuchillazo(johnny: Node2D) -> void:
	Sonido.tocar("barrido")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_CUCHILLAZO and desvio <= MEDIO_CUCHILLAZO + 0.15:
		johnny.recibir_dano(DANO_CUCHILLAZO, self)
		johnny.empujar(hacia.normalized() * 500.0)


# El abanico: los cuchillos salen en línea recta, repartidos alrededor de donde apuntó
func abanico() -> void:
	var n: int = CUCHILLOS[fase - 1]
	for i in n:
		var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
		var c := Cuchillo.new()
		c.dueno = self
		c.position = global_position + Vector2.from_angle(a) * (radio + 6.0)
		c.velocidad = Vector2.from_angle(a) * VELOCIDAD_CUCHILLO[fase - 1]
		c.dano = DANO_CUCHILLO
		get_parent().add_child(c)
	Sonido.tocar("cuchillos")


# La lluvia: caen alrededor de Johnny, cada marca un poco después de la anterior; la primera, donde va a estar
func lluvia(johnny: Node2D) -> void:
	var marca: float = MARCA_LLUVIA[fase - 1]
	Sonido.tocar("cuchillos")
	for i in LLUVIA[fase - 1]:
		var donde: Vector2 = johnny.global_position + johnny.velocity * (marca + i * HUECO_LLUVIA + Cuchillo.CAIDA)
		if i > 0:
			for intento in 4:
				donde = johnny.global_position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 150.0)
				if libre(donde):
					break
		if not libre(donde):
			if i > 0:
				continue
			donde = johnny.global_position
		var c := Cuchillo.new()
		c.dueno = self
		c.modo = "cae"
		c.position = donde
		c.aviso = marca
		c.espera = i * HUECO_LLUVIA
		c.dano = DANO_LLUVIA
		get_parent().add_child(c)


# El aceite hirviendo: la sartén cae donde va a estar Johnny
func sarten(johnny: Node2D) -> void:
	var p := PROYECTIL.instantiate()
	p.tipo = "sarten"
	p.desde = global_position + mirada * 30.0   # sale de la mano, con el brazo adelante
	p.alto_salida = arriba * 0.6
	p.hasta = johnny.global_position + johnny.velocity * 0.4
	if not libre(p.hasta):
		p.hasta = johnny.global_position
	p.dueno = self
	get_parent().add_child(p)
	Sonido.tocar("lanzar")


# Si Johnny está a la vista (sin paredes ni muebles en medio): los cuchillos del abanico van en línea recta
func a_la_vista(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Si ahí se puede estar (dentro del mapa de navegación: ni pared, ni mueble, ni fuera del local)
func libre(p: Vector2) -> bool:
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), p).distance_to(p) < 12.0


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡A LA OLLA!")


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_abanico":
			preparar("lanzar", dir, SUELTA[dir], AVISO_ABANICO)
		"aviso_lluvia":
			preparar("lanzar", dir, SUELTA[dir], AVISO_LLUVIA)
		"aviso_sarten":
			preparar("lanzar", dir, SUELTA[dir], AVISO_SARTEN)
		"abanico", "lluvia", "sarten":
			soltar("lanzar", dir, SUELTA[dir])
		"aviso_cuchillazo":
			preparar("cuchillazo", dir, TAJO[dir], AVISO_CUCHILLAZO)
		"cuchillazo":
			soltar("cuchillazo", dir, TAJO[dir])
		"grito":
			# al enfadarse: se encoge como si le hubieran dado y luego tiembla de rabia
			fijar("golpe", dir, avance("golpe_" + dir, t / 0.6))
			if t > 0.6:
				sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				# si va hacia atrás (apartándose de Johnny sin dejar de mirarle), las piernas también
				var atras := -1.0 if marcha.dot(mirada) < -0.3 * marcha.length() else 1.0
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5) * atras)
			else:
				poner("reposo_" + dir)


# Antes de soltar: hasta el fotograma "golpe" (sin llegar) en lo que dura el aviso
func preparar(anim: String, dir: String, golpe: int, aviso: float) -> void:
	fijar(anim, dir, mini(golpe - 1, int(t / aviso * golpe)))


# Y desde el fotograma "golpe" hasta el final, en lo que tarda en volver a andar
func soltar(anim: String, dir: String, golpe: int) -> void:
	var resto := sprite.sprite_frames.get_frame_count(anim + "_" + dir) - golpe
	fijar(anim, dir, golpe + clampi(int(t / DESPUES * resto), 0, maxi(0, resto - 1)))


# Los avisos, en el suelo (por debajo de él): las rayas del abanico y el trozo del cuchillazo
func _draw() -> void:
	if estado == "muerto":
		return
	var rojo := Color(1, 0.24, 0.35)
	match estado:
		"aviso_abanico":
			var k := minf(1.0, t / AVISO_ABANICO)
			var n: int = CUCHILLOS[fase - 1]
			draw_set_transform(Vector2(0, 6))
			for i in n:
				var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
				var desde := Vector2.from_angle(a) * radio
				draw_line(desde, desde + Vector2.from_angle(a) * LARGO_RAYAS * k, Color(rojo, 0.35 + 0.5 * k), 3.0)
		"aviso_cuchillazo":
			var k := minf(1.0, t / AVISO_CUCHILLAZO)
			var puntos := PackedVector2Array([Vector2.ZERO])
			for i in 17:
				var b: float = datos.angulo - MEDIO_CUCHILLAZO + i / 16.0 * MEDIO_CUCHILLAZO * 2.0
				puntos.append(Vector2.from_angle(b) * ALCANCE_CUCHILLAZO)
			draw_set_transform(Vector2(0, 6))
			draw_colored_polygon(puntos, Color(rojo, 0.1 + k * 0.25))
			puntos.append(Vector2.ZERO)
			draw_polyline(puntos, Color(rojo, 0.9), 3.0)


# La lluvia: al soltarlos, los cuchillos suben dando vueltas hasta salir de la pantalla (luego caen sobre sus marcas)
func pintar_encima(lienzo: Node2D) -> void:
	if estado != "lluvia" or t > SUBEN:
		return
	var k := t / SUBEN
	var n: int = LLUVIA[fase - 1]
	for i in n:
		var x := (i - (n - 1) / 2.0) * 12.0 * (1.0 + k)
		Cuchillo.dibujar(lienzo, Vector2(x, -arriba * 0.7 - k * k * 420.0 - i * 6.0), -PI / 2.0 + tiempo * 14.0 + i)
