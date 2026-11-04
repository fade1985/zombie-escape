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
#   - Su cocina (M82): los 9 muebles de las paredes de la Cocina central, tres en cada una (catalogo.gd,
#     "jefe-cocinero": 7 fogones industriales y 2 freidoras), rebosan: cada 4,5 s uno se pone al rojo, echa vapor y burbujea (1 s, el aviso) y suelta por delante
#     un charco de aceite hirviendo que se va extendiendo despacio por el suelo (6 s, hasta casi el doble que el de
#     la sartén) y se seca a los 14 s. Quema como el de la sartén. Nunca el que soltaría el aceite encima de Johnny,
#     ni uno que aún tiene su charco. Fuera de su cocina (la sala de pruebas), sin muebles, no pasa nada.
# Enfadado (a media vida): 5 cuchillos en el abanico y más rápidos, 7 en la lluvia y todo más seguido; y su cocina
# rebosa cada 3 s, la mitad de las veces dos muebles a la vez, con los charcos un poco más grandes.
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
# M82: los muebles de su cocina que rebosan aceite hirviendo (charco.gd, "hirviendo" con "crece")
const CHARCO := "res://escenas/armas/charco.tscn"   # (se carga al rebosar, como en proyectil.gd)
const REBOSAN := ["industrialstove", "fryer"]
const CADA_REBOSE := [4.5, 3.0]    # cada cuánto rebosa uno (normal y enfadado)
const DOS_A_LA_VEZ := 0.5          # enfadado: la suerte de que rebosen dos a la vez
const AVISO_REBOSE := 1.0          # lo que echa vapor y burbujea antes de soltar el aceite
const GRANDE_REBOSE := [1.8, 2.0]  # lo grande que llega a ser el charco, respecto al de la sartén (normal y enfadado)
const RADIO_ACEITE := 60.0         # el del charco de la sartén ("hirviendo" en charco.gd)
const CRECE_REBOSE := 6.0          # lo que tarda en extenderse del todo
const DURA_REBOSE := 14.0          # lo que dura (y luego se seca)
const LEJOS_REBOSE := 90.0         # no rebosa un mueble si su aceite saldría así de cerca de Johnny
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
# El fotograma de "lanzar" con el brazo del todo adelante (cuando sale el cuchillo o la sartén) y el del tajo del
# cuchillazo, según hacia dónde mire
const SUELTA := {"e": 4, "se": 4, "n": 4, "no": 4, "s": 5, "ne": 5, "o": 5, "so": 5}
const TAJO := {"s": 4, "se": 4, "e": 4, "n": 4, "ne": 5, "no": 5, "o": 5, "so": 5}
const DESPUES := 0.4               # lo que tarda en acabar la animación después de soltar (y en volver a andar)
const SUBEN := 0.4                 # la lluvia: lo que se ven subir los cuchillos al tirarlos

var espera := {"abanico": 1.0, "lluvia": 3.0, "sarten": 4.5, "cuchillazo": 0.8}
var lado := 1.0                    # hacia qué lado da los pasitos
var rebose := 4.0                  # M82: lo que falta para que rebose el siguiente mueble de la cocina
var rebosando: Array = []          # los que están avisando: [mueble, lo que les falta para soltar el aceite]
var mojado := {}                   # mueble -> hasta cuándo dura su charco (no vuelve a rebosar hasta que se seque)


func pensar(delta: float, johnny: Node2D) -> void:
	for k in espera:
		espera[k] -= delta
	rebosar(delta, johnny)
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
		gritar(Idioma.t("¡CALENTITO!"), Color("#ffb347"))
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


# El cuchillazo: daña y empuja a Johnny si está dentro del trozo marcado (y no hay una pared o un mueble en medio)
func cuchillazo(johnny: Node2D) -> void:
	Sonido.tocar("barrido")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_CUCHILLAZO and desvio <= MEDIO_CUCHILLAZO + 0.15 \
			and not Aviso.tapado(self, johnny.global_position):
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


# ── Su cocina rebosa (M82) ──

# Cada tanto, uno (o dos, enfadado) de los fogones y las freidoras avisa y luego suelta su aceite
func rebosar(delta: float, johnny: Node2D) -> void:
	for r in rebosando:
		r[1] -= delta
		echar_vapor(r[0], 1.0 - r[1] / AVISO_REBOSE)
	for r in rebosando.filter(func(x): return x[1] <= 0.0):
		rebosando.erase(r)
		if is_instance_valid(r[0]):
			derramar(r[0])
	rebose -= delta
	if rebose > 0.0:
		return
	var libres := fogones().filter(func(m): return tiempo >= mojado.get(m, 0.0) 		and salida(m).distance_to(johnny.global_position) > LEJOS_REBOSE)
	if libres.is_empty():
		rebose = 0.5   # (todos con su charco o junto a Johnny: vuelve a mirar en un momento)
		return
	rebose = CADA_REBOSE[fase - 1]
	libres.shuffle()
	for m in libres.slice(0, 2 if enfadado() and randf() < DOS_A_LA_VEZ else 1):
		rebosando.append([m, AVISO_REBOSE])
		mojado[m] = tiempo + AVISO_REBOSE + DURA_REBOSE
	Sonido.tocar("chisporroteo")


# Los fogones industriales y las freidoras de la cocina (de su sitio: los muebles que hay montados)
func fogones() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary 		and m.datos.get("tipo", "") in REBOSAN)


# Dónde queda el centro del charco de un mueble: delante de él (hacia el centro de la sala), con algo de aceite por
# debajo del mueble, que es de donde sale. (El mueble tiene su sitio en los pies: el centro de lo que ocupa, más arriba)
func salida(m: Node2D) -> Vector2:
	var r := RADIO_ACEITE * GRANDE_REBOSE[1]
	var centro: Vector2 = m.global_position - Vector2(0, m.datos.h / 2.0)
	match m.datos.get("lado", "arriba"):
		"abajo": return centro - Vector2(0, m.datos.h / 2.0 + r * 0.6 * 0.5)
		"izquierda": return centro + Vector2(m.datos.w / 2.0 + r * 0.5, 0)
		"derecha": return centro - Vector2(m.datos.w / 2.0 + r * 0.5, 0)
	return centro + Vector2(0, m.datos.h / 2.0 + r * 0.6 * 0.5)


# El aviso ("k": lo que lleva, de 0 a 1): el mueble se pone al rojo y palpita cada vez más deprisa, le sale mucho
# vapor por arriba y le saltan gotas de aceite hirviendo
func echar_vapor(m: Node2D, k: float) -> void:
	if not is_instance_valid(m):
		return
	var pulso := 0.5 + 0.5 * sin(tiempo * (14.0 + k * 16.0))
	colorear(m, Color(1.0, 0.92, 0.82).lerp(Color(1.0, 0.45, 0.25), (0.35 + 0.45 * k) * pulso))
	var w: float = m.datos.w * 0.35
	var arriba_mueble: Vector2 = m.global_position - Vector2(0, m.datos.h + 14.0)
	for i in 2:
		Particulas.soltar(self, arriba_mueble + Vector2(randf_range(-w, w), randf_range(-6, 6)),
			Vector2(randf_range(-14, 14), randf_range(-90, -50)), Color(1, 0.97, 0.92, 0.8), randf_range(4, 8), 0.8)
	if randf() < 0.5:
		var hacia := (salida(m) - m.global_position).normalized()
		Particulas.volar(self, m.global_position + Vector2(randf_range(-w, w), 0), m.datos.h * 0.8,
			hacia * randf_range(20, 60), randf_range(80, 160), Color("#f0b040"), randf_range(2, 4))


# El color del dibujo de un mueble (el del propio mueble, "modulate", ya lo usa la niebla: mapa.gd)
func colorear(m: Node2D, color: Color) -> void:
	for h in m.get_children():
		if h is Sprite2D:
			h.modulate = color


# Suelta el aceite: un charco hirviendo que se va extendiendo desde el mueble
func derramar(m: Node2D) -> void:
	colorear(m, Color.WHITE)
	var charco: Node2D = load(CHARCO).instantiate()
	charco.tipo = "hirviendo"
	charco.escala = GRANDE_REBOSE[fase - 1]
	charco.crece = CRECE_REBOSE
	charco.extra = DURA_REBOSE - 6.0   # (el de la sartén dura 6 s)
	charco.dueno = self                # (a él no le quema)
	var donde := salida(m)
	charco.position = (donde / 2.0).round() * 2.0   # en píxel entero del dibujo, como el de la sartén
	get_parent().add_child(charco)
	Sonido.tocar("chof")
	for i in 8:
		var a := randf() * TAU
		Particulas.soltar(self, donde, Vector2(cos(a), sin(a) * 0.6) * randf_range(50, 120), Color("#e8c547"), randf_range(3, 5), 0.4)


# Si Johnny está a la vista (sin paredes ni muebles en medio): los cuchillos del abanico van en línea recta
func a_la_vista(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Si ahí se puede estar (dentro del mapa de navegación: ni pared, ni mueble, ni fuera del local)
func libre(p: Vector2) -> bool:
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), p).distance_to(p) < 12.0


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡A LA OLLA!"))


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
	match estado:
		"aviso_abanico":
			# una barra fina por donde irá cada cuchillo, que se llena hacia fuera (aviso.gd)
			var k := minf(1.0, t / AVISO_ABANICO)
			var n: int = CUCHILLOS[fase - 1]
			for i in n:
				var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
				Aviso.barra(self, Vector2(0, 6), a, radio, radio + LARGO_RAYAS, 3.0, k, tiempo, i)
		"aviso_cuchillazo":
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_CUCHILLAZO, ALCANCE_CUCHILLAZO,
				minf(1.0, t / AVISO_CUCHILLAZO), tiempo)


# La lluvia: al soltarlos, los cuchillos suben dando vueltas hasta salir de la pantalla (luego caen sobre sus marcas)
func pintar_encima(lienzo: Node2D) -> void:
	if estado != "lluvia" or t > SUBEN:
		return
	var k := t / SUBEN
	var n: int = LLUVIA[fase - 1]
	for i in n:
		var x := (i - (n - 1) / 2.0) * 12.0 * (1.0 + k)
		Cuchillo.dibujar(lienzo, Vector2(x, -arriba * 0.7 - k * k * 420.0 - i * 6.0), -PI / 2.0 + tiempo * 14.0 + i)
