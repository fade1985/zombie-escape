# El científico jefe: el jefe final de los Apartamentos, en la azotea. El doctor Héctor Salas, director del estudio
# del VD-7 (historia.gd): el que estaba detrás de todo lo que pasa en el edificio. Grande como el gerente (lienzo
# de 128), con la bata manchada, las gafas de laboratorio y una jeringa enorme. Lo común con los minijefes (la vida
# y su barra, llamar a otros, moverse y morir), en minijefe.gd. Diseño: docs/historial/JEFES_APARTAMENTOS.md, apartado 4.
#
# FASE 1, el científico. Rápido y cobarde: no pega de cerca, se mantiene a distancia de Johnny (si se le acerca,
# se aleja) y desde ahí hace cuatro cosas, cada una con su aviso:
#   - Probetas: tres de golpe (ácido, veneno y aceite, que resbala), en curva alta a donde está Johnny y alrededor,
#     con sus anillos rojos en el suelo (proyectil.gd, tipos probeta_*). Dejan los charcos de siempre (charco.gd).
#   - Sujetos: si quedan pocos zombis, levanta la jeringa y grita: llegan tres vecinos.
#   - Suero: si hay zombis cerca sin inyectar, levanta la jeringa y les lanza un rayo verde a los tres más cercanos:
#     más vida, más rápidos y pegan más (y se les ve verdes).
#   - Cúpula: de vez en cuando (si ya le han hecho daño) se mete en una cúpula de cristal unos segundos: ahí no se le
#     puede dar (los golpes se los lleva la cúpula, con su barra azul encima de la de vida, la de "armadura"), y
#     desde dentro tira probetas más seguidas. Hay que romperla (140 de daño) o esperar a que la baje; al romperse,
#     se tambalea un momento (ahí se le puede dar bien).
# A MEDIA VIDA no se enfada: grita, se pincha su propia jeringa (sin que se le pueda hacer daño) y, con un fogonazo,
# le revienta la bata y crece: la CRIATURA (otro dibujo, jefe-criatura). Antes de pincharse no puede caer (se queda
# con 1): la transformación llega siempre.
#
# FASE 2, la criatura: una masa enorme hecha con trozos de los otros jefes, como si los hubiera creado él: la boca
# del Glotón, los brazos del Gymbro y el fuego del bombero. Más lenta de cabeza (ya no piensa: solo ataca), con
# tres ataques que los recuerdan, también con aviso:
#   - Lenguas-látigo: tres franjas rojas en abanico y, al rato, tres lenguas por ellas (como el Glotón, más largas).
#   - Puñetazo al suelo: si Johnny está cerca, marca un círculo rojo y da con los dos puños: una onda expansiva que
#     crece desde él; si te pilla (esquivando, no) te quita 24 y te tira al suelo.
#   - Escupitajos de fuego: si Johnny está lejos y a la vista, tres bolas de fuego en abanico (bola_fuego.gd).
# Al caer la criatura, la partida enseña la última página del dosier y trae el helicóptero de Velaria (partida.gd).
# Sus animaciones (PixelLab): andar y probetas en las 8 direcciones (las del oeste, el este en espejo), suero (vale
# para llamar) y jeringa solo de frente. Las de la criatura, en otra hoja: andar, lenguas, punetazo, escupir y muerte.
extends Minijefe

signal armadura_cambiada(armadura: int, maxima: int)   # la cúpula, en la barra fina azul de la partida

const VELOCIDAD := 95.0
const LEJOS := 430.0                     # más lejos que esto, se acerca a Johnny
const CERCA := 220.0                     # más cerca que esto, se aleja (no pega de cerca)
const AVISO_PROBETAS := 0.55
const PROBETAS := 3                      # cuántas tira de golpe (en la cúpula, 2, pero más seguidas)
const TIPOS_PROBETA := ["probeta_acido", "probeta_veneno", "probeta_aceite"]
const ALCANCE_PROBETAS := 540.0
const DESPUES := 0.45                    # lo que tarda en acabar la animación después de soltar (y en volver a andar)
const SUJETOS := ["normal", "rapido", "venenoso"]   # los que llegan al grito
const POCOS := 1                         # llama si quedan como mucho estos zombis
const GRITO := 1.2                       # lo que dura levantar la jeringa (suero y sujetos)
const ALCANCE_SUERO := 480.0
const SUERO_A := 3                       # a cuántos zombis inyecta de una vez
const SUERO_VIDA := 1.6                  # la vida máxima se multiplica por esto (y se le suma la diferencia)
const SUERO_VELOCIDAD := 1.3
const SUERO_DANO := 6
const CUPULA_VIDA := 140
const CUPULA_DURA := 7.0                 # lo que aguanta dentro si no se la rompen
const CUPULA_SUBE := 0.4                 # lo que tarda en subir (y en bajar)
const CUPULA_PROBETAS := 1.6             # dentro, cada cuánto tira probetas
const TAMBALEO := 0.9                    # lo que se tambalea al rompérsela
const ESPERAS := {"probetas": 3.0, "suero": 9.0, "sujetos": 14.0, "cupula": 14.0}
const PIE := 34.0                        # a qué altura dibuja los pies respecto a su centro
# El fotograma de "probetas" con el brazo adelante (cuando sale la probeta de código), según hacia dónde mire
const SUELTA := {"s": 4, "se": 5, "e": 4, "ne": 4, "n": 4, "no": 4, "o": 4, "so": 5}
const VERDE := Color("#b6ff6a")          # el VD-7
const CRISTAL := Color("#9fd8ff")
const CONTORNO := Color("#1d1b2c")

# La jeringa y la criatura
const CRIATURA := "res://assets/sprites/jefe-criatura.tres"
const JERINGA := 2.6                     # lo que tarda en pincharse (los 13 fotogramas de jeringa_s)
const MUTAR := 1.3                       # el cambio: fogonazo, temblor y un rugido, también sin que le hagan daño
const RADIO_CRIATURA := 48.0
const ARRIBA_CRIATURA := 225.0
const OFFSET_CRIATURA := Vector2(-82, -162)   # (lo dice py tools/jefe_hoja.py criatura-128 jefe-criatura)
const PIE_CRIATURA := 34.0
const VELOCIDAD_CRIATURA := 100.0
const LENGUAS := 3
const ABRE_LENGUAS := 0.4
const LARGO_LENGUA := 330.0
const ANCHO_LENGUA := 14.0               # medio ancho de cada franja
const AVISO_LENGUAS := 0.65
const DURA_LENGUAS := 0.45
const DANO_LENGUA := 18
const BOCA := 0.5                        # a qué altura tiene la boca (parte de "arriba"): de ahí salen las lenguas
const AVISO_PUNETAZO := 0.75
const DISTANCIA_PUNETAZO := 240.0        # si Johnny está más cerca que esto, prefiere el puñetazo
const RADIO_ONDA := 210.0
const DURA_ONDA := 0.4
const DANO_PUNETAZO := 24
const AVISO_FUEGO := 0.5
const LEJOS_FUEGO := 230.0               # si Johnny está más lejos que esto, prefiere escupir
const BOLAS := 3
const ABRE_BOLAS := 0.24
const VELOCIDAD_BOLA := 360.0
const DANO_BOLA := 12
const QUEMA_BOLA := {"fuego": {"dps": 8.0, "despues": 1.5}}
const ESPERAS_CRIATURA := {"lenguas": 2.2, "punetazo": 3.2, "fuego": 3.6}
# El fotograma de cada ataque de la criatura en el que llega el golpe (cuando salen las lenguas, la onda y las bolas)
const GOLPE := {"lenguas": 3, "punetazo": 4, "escupir": 4}
const LENGUA := Color("#b8352f")
const LENGUA_LUZ := Color("#e8766e")
const FUEGO := [Color("#ff9f1c"), Color("#ffd23f"), Color("#ff5a1f"), Color("#fff1a8")]

var espera := {"probetas": 1.5, "suero": 4.0, "sujetos": 2.0, "cupula": 8.0}
var cupula := 0                          # lo que le queda a la cúpula (0 = no hay)
var dentro := 0.0                        # lo que lleva dentro de la cúpula
var mutado := false
var espera_criatura := {"lenguas": 0.8, "punetazo": 1.5, "fuego": 2.0}


func pensar(delta: float, johnny: Node2D) -> void:
	if mutado:
		pensar_criatura(delta, johnny)
		return
	for k in espera:
		espera[k] -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			# a distancia: si Johnny está lejos se acerca, si se le acerca se aleja, y entre medias le mira
			if d > LEJOS:
				perseguir(delta, johnny, VELOCIDAD)
			elif d < CERCA:
				huir(delta, hacia)
			else:
				frenar(delta)
			mirada = marcha.normalized() if marcha.length() > 10.0 else hacia.normalized()
			if t >= dur:
				elegir(johnny, d)
		"aviso_probetas":
			frenar(delta)
			if t >= AVISO_PROBETAS:
				cambiar("probetas", {"destinos": datos.destinos, "angulo": datos.angulo})
				lanzar_probetas()
		"probetas":
			frenar(delta)
			if t >= DESPUES:
				andar(0.6)
		"sujetos", "suero":
			frenar(delta)
			mirada = Vector2.DOWN   # (levantar la jeringa solo está dibujado de frente)
			if t >= GRITO * 0.45 and not datos.get("hecho", false):
				datos.hecho = true
				if estado == "sujetos":
					llamar_sujetos()
				else:
					inyectar()
			if t >= GRITO:
				andar(0.4)
		"cupula_sube":
			frenar(delta)
			if t >= CUPULA_SUBE:
				cambiar("cupula", {"tira": CUPULA_PROBETAS * 0.5, "angulo": hacia.angle()})
		"cupula":
			# dentro: quieto, mirando a Johnny y tirando probetas más seguidas (dos cada vez)
			frenar(delta)
			dentro += delta
			contacto = 0
			mirada = hacia.normalized()
			datos.tira -= delta
			if datos.tira <= 0.0 and d < ALCANCE_PROBETAS:
				datos.tira = CUPULA_PROBETAS
				datos.destinos = destinos_probetas(johnny, 2)
				datos.angulo = hacia.angle()
				datos.suelta = 0.0
				lanzar_probetas()
			datos.suelta = datos.get("suelta", 1.0) + delta
			if dentro >= CUPULA_DURA:
				bajar_cupula()
		"cupula_baja":
			frenar(delta)
			contacto = 0
			if t >= CUPULA_SUBE:
				andar(0.3)
		"tambaleo":
			frenar(delta, 6.0)
			if t >= TAMBALEO:
				andar(0.3)
		"jeringa":
			sin_tocar(delta)
			mirada = Vector2.DOWN   # (la jeringa solo está dibujada de frente)
			if t >= JERINGA * 0.35 and not datos.get("pinchado", false):
				datos.pinchado = true
				Sonido.tocar("jeringa")
			if t >= JERINGA:
				mutar()


# Quieto y sin que le hagan daño (pinchándose y mutando)
func sin_tocar(delta: float) -> void:
	invulnerable = true
	contacto = 0
	frenar(delta)


# Alejarse de Johnny por el mapa de navegación: hacia atrás y, si ahí está el murete o un aparato (el punto
# alcanzable queda pegado a él), de lado. Si no hay escapatoria, se queda quieto
func huir(delta: float, hacia: Vector2) -> void:
	var mapa := agente.get_navigation_map()
	var atras := -hacia.normalized()
	for giro in [0.0, 1.0, -1.0, 1.9, -1.9]:
		var destino := NavigationServer2D.map_get_closest_point(mapa, global_position + atras.rotated(giro) * 180.0)
		if destino.distance_to(global_position) < 90.0:
			continue   # por ahí no se puede (el murete, un aparato): otro lado
		agente.target_position = destino
		var dir := global_position.direction_to(agente.get_next_path_position())
		marcha += (dir * VELOCIDAD - marcha) * (1.0 - exp(-delta * 6.0))
		return
	frenar(delta)


func elegir(johnny: Node2D, d: float) -> void:
	var angulo := (johnny.global_position - global_position).angle()
	if espera.cupula <= 0.0 and vida < vida_max * 0.92:
		espera.cupula = ESPERAS.cupula
		subir_cupula()
		return
	if espera.sujetos <= 0.0 and secuaces() <= POCOS:
		espera.sujetos = ESPERAS.sujetos
		cambiar("sujetos")
		gritar("¡MÁS SUJETOS!", VERDE, 24)
		Sonido.tocar("rugido")
		return
	if espera.suero <= 0.0 and not sin_suero().is_empty():
		espera.suero = ESPERAS.suero
		cambiar("suero")
		gritar("¡DOSIS DOBLE!", VERDE, 24)
		return
	if espera.probetas <= 0.0 and d < ALCANCE_PROBETAS:
		espera.probetas = ESPERAS.probetas
		cambiar("aviso_probetas", {"destinos": destinos_probetas(johnny, PROBETAS), "angulo": angulo})
		mirada = Vector2.from_angle(angulo)
		return
	andar(0.3)


# ── Las probetas ──

# Dónde caerán: la primera donde está Johnny, la segunda a donde va (si anda) y las demás alrededor. Siempre donde
# se pueda estar (no dentro de un aparato ni fuera de la azotea)
func destinos_probetas(johnny: Node2D, cuantas: int) -> Array:
	var lista := [johnny.global_position]
	if cuantas > 1:
		lista.append(johnny.global_position + johnny.velocity * 0.7 + Vector2.from_angle(randf() * TAU) * 30.0)
	while lista.size() < cuantas:
		lista.append(johnny.global_position + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 130.0))
	var mapa := agente.get_navigation_map()
	for i in lista.size():
		lista[i] = NavigationServer2D.map_get_closest_point(mapa, lista[i])
	return lista


# Salen de su mano, cada una de un tipo (ácido, veneno y aceite, en ese orden), en curva alta a sus sitios
func lanzar_probetas() -> void:
	Sonido.tocar("lanzar")
	var tipos := TIPOS_PROBETA.duplicate()
	tipos.shuffle()
	for i in datos.destinos.size():
		var p: Node2D = load("res://escenas/armas/proyectil.tscn").instantiate()
		p.tipo = tipos[i % tipos.size()]
		p.desde = global_position + mirada * 20.0 + Vector2(0, PIE * 0.5)
		p.alto_salida = arriba * 0.55
		p.hasta = datos.destinos[i]
		p.dueno = self
		get_parent().add_child(p)


# ── Los sujetos y el suero ──

# Llegan tres vecinos, repartidos a su alrededor (donde se pueda estar: no dentro de un aparato ni fuera de la azotea)
func llamar_sujetos() -> void:
	for i in 3:
		var a := float(i) / 3.0 * TAU + randf_range(-0.4, 0.4)
		var donde := global_position + Vector2(cos(a), sin(a) * 0.8) * randf_range(120.0, 170.0)
		donde = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), donde)
		pide_zombi.emit(SUJETOS[i], donde)
	Luz.destello(get_parent(), global_position + Vector2(0, -arriba * 0.9), 160.0, 0.3, 0.8, VERDE)


# Los zombis de alrededor que aún no llevan suero (sin contar a los jefes), del más cercano al más lejano
func sin_suero() -> Array:
	var lista := []
	for z in get_tree().get_nodes_in_group("zombis"):
		if z == self or z is Minijefe or not "velocidad" in z or z.has_meta("suero"):
			continue
		if z.global_position.distance_to(global_position) <= ALCANCE_SUERO:
			lista.append(z)
	lista.sort_custom(func(a, b): return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	return lista


# El suero: un rayo verde de la jeringa a cada uno (lo pinta pintar_encima mientras dura el grito) y los mejora
func inyectar() -> void:
	datos.rayos = []
	for z in sin_suero().slice(0, SUERO_A):
		z.set_meta("suero", true)
		var mas: int = int(z.vida_max * (SUERO_VIDA - 1.0))
		z.vida_max += mas
		z.vida += mas
		z.velocidad *= SUERO_VELOCIDAD
		if z.has_node("Agente"):
			z.get_node("Agente").max_speed = z.velocidad   # (el agente de navegación también tiene que dejarle ir más rápido)
		z.dano += SUERO_DANO
		if z.has_node("Sprite"):
			z.get_node("Sprite").modulate = Color(0.72, 1.25, 0.72)
		datos.rayos.append(z.global_position)
		var alto: float = z.altura if "altura" in z else 80.0
		Zombi.texto_flotante(get_parent(), z.global_position + Vector2(-30, -alto), "¡SUERO!", VERDE, 18)
		for i in 8:
			Particulas.soltar(self, z.global_position + Vector2(randf_range(-14, 14), randf_range(-60, 0)),
				Vector2(randf_range(-30, 30), randf_range(-70, -20)), VERDE, 3, 0.5)
	if datos.rayos.is_empty():
		return
	Sonido.tocar("jeringa")
	Luz.destello(get_parent(), global_position + Vector2(0, -arriba * 0.9), 180.0, 0.3, 0.9, VERDE)


# ── La cúpula ──

func subir_cupula() -> void:
	cupula = CUPULA_VIDA
	dentro = 0.0
	armadura_cambiada.emit(cupula, CUPULA_VIDA)
	Sonido.tocar("cristal")
	gritar("¡NO ME TOCARÁS!", CRISTAL, 22)
	cambiar("cupula_sube")


func bajar_cupula() -> void:
	cupula = 0
	armadura_cambiada.emit(0, CUPULA_VIDA)
	cambiar("cupula_baja")


# Se la han roto: cristales por todos lados y se tambalea un momento
func romper_cupula() -> void:
	cupula = 0
	armadura_cambiada.emit(0, CUPULA_VIDA)
	Sonido.tocar("cristal")
	Sonido.tocar("explosion")
	Temblor.temblar(6.0)
	gritar("¡MI CÚPULA!", CRISTAL, 22)
	for i in 22:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(cos(a) * 60.0, -arriba * 0.45 + sin(a) * 80.0),
			Vector2(cos(a) * randf_range(80, 200), sin(a) * randf_range(40, 120) - 60.0), [CRISTAL, Color.WHITE].pick_random(), 3, 0.6)
	cambiar("tambaleo")


# Con la cúpula puesta, los golpes se los lleva ella (y, si le dan de más, lo que sobra se pierde); antes de
# pincharse no puede caer: como mucho se queda con 1 (y a media vida se pincha seguro)
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	if cupula > 0:
		cupula -= cantidad
		if cupula <= 0:
			romper_cupula()
		else:
			armadura_cambiada.emit(cupula, CUPULA_VIDA)
			Sonido.tocar("cristal")
		return 0
	return cantidad if mutado else mini(cantidad, vida - 1)


# El mordisco del glotón pasa la cúpula, pero antes de pincharse tampoco le hace caer
func morder(cantidad: int) -> void:
	super(cantidad if mutado else mini(cantidad, vida - 1))


# Si Johnny está a la vista (sin paredes ni aparatos en medio)
func a_la_vista(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# ── La jeringa y el cambio ──

# A media vida: en vez de enfadarse como los minijefes, se pincha su jeringa. Baja la cúpula si la tenía, aparta a
# Johnny (para que vea la jeringa) y luego muta (mutar())
func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	vapor = false   # (el vapor de enfadado es de los minijefes)
	if cupula > 0:
		cupula = 0
		armadura_cambiada.emit(0, CUPULA_VIDA)
	gritar("¡AÚN NO HE TERMINADO!", VERDE, 24)
	Sonido.tocar("rugido")
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < 240.0:
		johnny.empujar(hacia.normalized() * 800.0)
	cambiar("jeringa")


# El cambio: otro dibujo (más grande), un fogonazo verde, temblor, un rugido y trozos de la bata por los aires.
# Crece de golpe desde un poco más pequeño, como si se hinchara
func mutar() -> void:
	mutado = true
	Bestiario.apuntar("criatura")   # visto: al bestiario de las Colecciones del ordenador
	cambiar("mutar")
	if ResourceLoader.exists(CRIATURA):
		sprite.sprite_frames = load(CRIATURA)
		sprite.offset = OFFSET_CRIATURA
	sprite.play("reposo_s")
	radio = RADIO_CRIATURA
	arriba = ARRIBA_CRIATURA
	dano_contacto = 14
	$Choque.shape = $Choque.shape.duplicate()
	$Choque.shape.radius = radio
	$Sombra.ancho = 130.0
	$Sombra.alto = 36.0
	$Sombra.queue_redraw()
	sprite.scale = Vector2(1.5, 1.5)
	sprite.modulate = Color(2.2, 2.6, 1.8)
	var tw := create_tween().set_parallel()
	tw.tween_property(sprite, "scale", Vector2(2, 2), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.6)
	Luz.destello(self, global_position + Vector2(0, -100), 440.0, 0.7, 1.8, VERDE)
	Temblor.temblar(14.0)
	Sonido.tocar("rugido")
	Sonido.tocar("explosion")
	gritar("¡GRAAAAH!", VERDE, 30)
	for i in 30:
		# los trozos de la bata (blancos), el VD-7 (verde) y las primeras llamas
		Particulas.soltar(self, global_position + Vector2(randf_range(-40, 40), randf_range(-150, 0)),
			Vector2.from_angle(randf() * TAU) * randf_range(60, 180), [Color("#f1f1e6"), Color("#f1f1e6"), VERDE, FUEGO[0]].pick_random(), 4, 0.9)


# ── La criatura ──

func pensar_criatura(delta: float, johnny: Node2D) -> void:
	for k in espera_criatura:
		espera_criatura[k] -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"mutar":
			sin_tocar(delta)
			mirada = Vector2.DOWN
			if t >= MUTAR:
				andar(0.3)
		"andar":
			if d > 120.0:
				perseguir(delta, johnny, VELOCIDAD_CRIATURA)
			else:
				frenar(delta)
			mirada = marcha.normalized() if marcha.length() > 10.0 else hacia.normalized()
			if t >= dur:
				elegir_criatura(johnny, d)
		"aviso_lenguas":
			frenar(delta)
			if t >= AVISO_LENGUAS:
				cambiar("lenguas", {"angulo": datos.angulo})
				Sonido.tocar("latigazo")
				lenguas(johnny)
		"lenguas":
			frenar(delta)
			if t >= DESPUES:
				andar(0.4)
		"aviso_punetazo":
			frenar(delta, 12.0)
			if t >= AVISO_PUNETAZO:
				cambiar("punetazo")
				punetazo()
		"punetazo":
			frenar(delta)
			onda(johnny)
			if t >= DURA_ONDA + 0.25:
				andar(0.4)
		"aviso_fuego":
			frenar(delta)
			if t >= AVISO_FUEGO:
				cambiar("escupir", {"angulo": datos.angulo})
				escupir()
		"escupir":
			frenar(delta)
			if t >= DESPUES:
				andar(0.4)


func elegir_criatura(johnny: Node2D, d: float) -> void:
	var angulo := (johnny.global_position - global_position).angle()
	if d < DISTANCIA_PUNETAZO and espera_criatura.punetazo <= 0.0:
		espera_criatura.punetazo = ESPERAS_CRIATURA.punetazo
		empezar("aviso_punetazo", angulo)
		return
	if d > LEJOS_FUEGO and espera_criatura.fuego <= 0.0 and a_la_vista(johnny):
		espera_criatura.fuego = ESPERAS_CRIATURA.fuego
		empezar("aviso_fuego", angulo)
		return
	if d < LARGO_LENGUA + 20.0 and espera_criatura.lenguas <= 0.0:
		espera_criatura.lenguas = ESPERAS_CRIATURA.lenguas
		empezar("aviso_lenguas", angulo)
		return
	andar(0.3)


# Empieza un ataque mirando hacia donde está Johnny (el abanico va hacia ahí, aunque se mueva)
func empezar(nuevo: String, angulo: float) -> void:
	cambiar(nuevo, {"angulo": angulo})
	mirada = Vector2.from_angle(angulo)


# Los ángulos de las tres lenguas, alrededor de donde apuntó
func angulos_lenguas() -> Array:
	var lista := []
	for i in LENGUAS:
		lista.append(datos.angulo + (i - (LENGUAS - 1) / 2.0) * ABRE_LENGUAS)
	return lista


# ¿Está Johnny dentro de alguna franja? (como el latigazo del Glotón)
func lenguas(johnny: Node2D) -> void:
	Temblor.temblar(5.0)
	for a in angulos_lenguas():
		var linea := Vector2.from_angle(a)
		var hacia: Vector2 = johnny.global_position - global_position
		var a_lo_largo := clampf(hacia.dot(linea), 0.0, LARGO_LENGUA)
		if hacia.distance_to(linea * a_lo_largo) <= ANCHO_LENGUA + johnny.RADIO:
			johnny.recibir_dano(DANO_LENGUA, self)
			johnny.empujar(linea * 500.0)
			return


# El puñetazo al suelo: temblor, polvo y la onda, que crece en DURA_ONDA (onda())
func punetazo() -> void:
	Sonido.tocar("porrazo")
	Temblor.temblar(12.0)
	for i in 16:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(cos(a) * 40.0, PIE_CRIATURA + sin(a) * 12.0),
			Vector2(cos(a) * randf_range(60, 140), sin(a) * randf_range(30, 70) - 40.0), Color("#8a7a66"), 4, 0.5)


# La onda pilla a Johnny cuando pasa por donde está (una sola vez). Si en ese momento está esquivando, le pasa por
# debajo y ya no le pilla (la onda es un frente que avanza, no un disco)
func onda(johnny: Node2D) -> void:
	if datos.get("hecho", false) or t > DURA_ONDA:
		return
	var r := RADIO_ONDA * t / DURA_ONDA
	var hacia: Vector2 = johnny.global_position - global_position
	if Vector2(hacia.x, hacia.y / 0.7).length() <= r + johnny.RADIO:
		datos.hecho = true
		if johnny.esquiva_t <= 0.0:
			johnny.recibir_dano(DANO_PUNETAZO, self)
			johnny.empujar(hacia.normalized() * 700.0)
			johnny.pisar({"tirado": {}})


# Las bolas de fuego, en abanico, desde la boca
func escupir() -> void:
	Sonido.tocar("fuego")
	var boca := global_position + mirada * 36.0
	for i in BOLAS:
		var a: float = datos.angulo + (i - (BOLAS - 1) / 2.0) * ABRE_BOLAS
		var bola := BolaFuego.new()
		bola.dueno = self
		bola.desde = boca
		bola.velocidad = Vector2.from_angle(a) * VELOCIDAD_BOLA
		bola.dano = DANO_BOLA
		bola.quema = QUEMA_BOLA
		get_parent().add_child(bola)
	Luz.destello(get_parent(), boca, 140.0, 0.25, 0.7)


# En la foto de la prueba (--captura): tirando las probetas hacia Johnny; la criatura, soltando las lenguas
func foto(johnny: Node2D) -> void:
	var angulo := (johnny.global_position - global_position).angle()
	if mutado:
		empezar("aviso_lenguas", angulo)
		t = AVISO_LENGUAS - 0.05
		return
	cambiar("aviso_probetas", {"destinos": destinos_probetas(johnny, PROBETAS), "angulo": angulo})
	mirada = Vector2.from_angle(angulo)
	t = AVISO_PROBETAS - 0.02


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	if mutado:
		animar_criatura(dir)
		return
	match estado:
		"aviso_probetas":
			preparar("probetas", dir, SUELTA[dir], AVISO_PROBETAS)
		"probetas":
			soltar("probetas", dir, SUELTA[dir])
		"sujetos", "suero":
			fijar("suero", "s", avance("suero_s", t / GRITO))
		"grito":
			fijar("suero", "s", avance("suero_s", minf(t / 0.9, 0.5)))
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		"cupula", "cupula_sube", "cupula_baja":
			# dentro, tirando probetas con la misma animación (más corta), y si no, quieto
			if estado == "cupula" and datos.get("suelta", 1.0) < DESPUES:
				soltar("probetas", dir, SUELTA[dir], datos.suelta)
			else:
				poner("reposo_" + dir)
		"tambaleo":
			poner("reposo_" + dir)
			sprite.position.x = sin(tiempo * 30.0) * 3.0
		"jeringa":
			# los 13 fotogramas en lo que dura; del 9 en adelante (tira la jeringa y se encorva), temblando
			var f := avance("jeringa_s", t / JERINGA)
			fijar("jeringa", "s", f)
			if f >= 9:
				sprite.position.x = sin(tiempo * 60.0) * 2.0
		_:
			# (lo que anda de verdad: contra el murete, que no ande en el sitio)
			var paso := minf(marcha.length(), get_real_velocity().length())
			if paso > 8.0:
				poner("andar_" + dir, clampf(paso / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func animar_criatura(dir: String) -> void:
	sprite.position = Vector2(0, PIE_CRIATURA)
	if not sprite.sprite_frames.has_animation("lenguas_s"):
		# (mientras no esté su hoja: la vista quieta del científico, y a seguir)
		poner("reposo_" + dir)
		return
	match estado:
		"mutar":
			poner("reposo_s")
			sprite.position.x = sin(tiempo * 70.0) * 3.0 * (1.0 - t / MUTAR)
		"aviso_lenguas":
			preparar("lenguas", dir, GOLPE.lenguas, AVISO_LENGUAS)
		"lenguas":
			soltar("lenguas", dir, GOLPE.lenguas)
		"aviso_punetazo":
			# los puños en alto, temblando de rabia
			preparar("punetazo", dir, GOLPE.punetazo, AVISO_PUNETAZO)
			sprite.position.x = sin(tiempo * 55.0) * 2.0
		"punetazo":
			soltar("punetazo", dir, GOLPE.punetazo)
		"aviso_fuego":
			preparar("escupir", dir, GOLPE.escupir, AVISO_FUEGO)
		"escupir":
			soltar("escupir", dir, GOLPE.escupir)
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD_CRIATURA, 0.5, 1.5))
			else:
				poner("reposo_" + dir)


# Antes de soltar: hasta el fotograma "golpe" (sin llegar) en lo que dura el aviso
func preparar(anim: String, dir: String, golpe: int, aviso: float) -> void:
	fijar(anim, dir, mini(golpe - 1, int(t / aviso * golpe)))


# Y desde el fotograma "golpe" hasta el final, en lo que tarda en volver a andar. "desde": el tiempo que lleva desde
# que soltó (si no se dice, el del estado, que empieza en 0 al soltar; dentro de la cúpula no, y se pasa datos.suelta)
func soltar(anim: String, dir: String, golpe: int, desde := -1.0) -> void:
	var lleva := t if desde < 0.0 else desde
	var resto := sprite.sprite_frames.get_frame_count(anim + "_" + dir) - golpe
	fijar(anim, dir, golpe + clampi(int(lleva / DESPUES * resto), 0, maxi(0, resto - 1)))


func morir() -> void:
	super()
	# (el científico sin mutar no tiene animación de muerte: si cayera así, de lado; la criatura cae con la suya)
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# Los avisos, en el suelo (por debajo de él)
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_probetas":
			# un círculo donde caerá cada probeta, que se llena hacia fuera (aviso.gd)
			var k := minf(1.0, t / AVISO_PROBETAS)
			for i in datos.destinos.size():
				Aviso.abanico(self, datos.destinos[i] - global_position, 0.0, PI, 50.0, k, tiempo, 0.6, 0.0, i)
		"cupula_sube", "cupula", "cupula_baja":
			# el borde de la cúpula en el suelo
			var k := minf(1.0, t / CUPULA_SUBE)
			if estado == "cupula":
				k = 1.0
			elif estado == "cupula_baja":
				k = 1.0 - k
			draw_set_transform(Vector2(0, 6), 0.0, Vector2(1, 0.55))
			draw_circle(Vector2.ZERO, 78.0 * k, Color(CRISTAL, 0.12))
			draw_arc(Vector2.ZERO, 78.0 * k, 0.0, TAU, 40, Color(CRISTAL, 0.7), 3.0)
		"aviso_lenguas":
			# las tres barras de las lenguas, que se llenan hacia fuera (aviso.gd)
			var k := minf(1.0, t / AVISO_LENGUAS)
			var lenguas := angulos_lenguas()
			for i in lenguas.size():
				Aviso.barra(self, Vector2(0, 6), lenguas[i], radio * 0.5, LARGO_LENGUA, ANCHO_LENGUA, k, tiempo, i)
		"aviso_punetazo":
			# el círculo de la onda, que se llena de él hacia fuera (aviso.gd)
			Aviso.abanico(self, Vector2(0, 6), 0.0, PI, RADIO_ONDA, minf(1.0, t / AVISO_PUNETAZO), tiempo, 0.7)
		"punetazo":
			# la onda: un anillo que crece desde los puños y se apaga
			var k := minf(1.0, t / DURA_ONDA)
			draw_set_transform(Vector2(0, 6), 0.0, Vector2(1, 0.7))
			draw_arc(Vector2.ZERO, RADIO_ONDA * k, 0.0, TAU, 48, Color(1, 0.9, 0.7, 0.9 * (1.0 - k)), 10.0 * (1.0 - k) + 3.0)
			draw_arc(Vector2.ZERO, RADIO_ONDA * k * 0.85, 0.0, TAU, 48, Color(1, 0.6, 0.3, 0.5 * (1.0 - k)), 4.0)
		"aviso_fuego":
			# una barra fina por donde irá cada bola, que se llena hacia fuera (aviso.gd)
			var k := minf(1.0, t / AVISO_FUEGO)
			for i in BOLAS:
				var a: float = datos.angulo + (i - (BOLAS - 1) / 2.0) * ABRE_BOLAS
				Aviso.barra(self, Vector2(0, 6), a, radio, radio + 320.0, 3.0, k, tiempo, i)
	draw_set_transform(Vector2.ZERO)


# Lo que va por encima de él (en el nodo "Vapor"): la cúpula de cristal, los rayos del suero, las lenguas de la
# criatura y el fuego de la boca al escupir
func pintar_encima(lienzo: Node2D) -> void:
	match estado:
		"cupula_sube", "cupula", "cupula_baja":
			var k := minf(1.0, t / CUPULA_SUBE)
			if estado == "cupula":
				k = 1.0
			elif estado == "cupula_baja":
				k = 1.0 - k
			var centro := Vector2(0, -arriba * 0.42)
			lienzo.draw_set_transform(centro, 0.0, Vector2(1, 1.25) * k)
			lienzo.draw_circle(Vector2.ZERO, 78.0, Color(CRISTAL, 0.22))
			lienzo.draw_arc(Vector2.ZERO, 78.0, 0.0, TAU, 48, Color(CRISTAL, 0.85), 3.0)
			lienzo.draw_arc(Vector2(-14, -14), 54.0, PI * 1.05, PI * 1.55, 16, Color(1, 1, 1, 0.55), 4.0)   # el brillo
			# las grietas, según lo que le han dado
			var dano := 1.0 - float(cupula) / CUPULA_VIDA if cupula > 0 else 0.0
			for i in int(dano * 8.0):
				var a := i * 2.4 + 0.7
				var p := Vector2.from_angle(a) * 20.0
				lienzo.draw_line(p, p + Vector2.from_angle(a + 0.3) * 40.0, Color(1, 1, 1, 0.8), 2.0)
				lienzo.draw_line(p + Vector2.from_angle(a + 0.3) * 20.0, p + Vector2.from_angle(a - 0.5) * 42.0, Color(1, 1, 1, 0.6), 2.0)
			lienzo.draw_set_transform(Vector2.ZERO)
		"suero":
			# los rayos verdes de la jeringa a cada zombi, mientras dura el grito
			if not datos.has("rayos") or t > GRITO * 0.9:
				return
			var punta := Vector2(8, -arriba * 1.0)
			var brillo := 0.9 * (1.0 - (t - GRITO * 0.45) / (GRITO * 0.45))
			for p in datos.rayos:
				var hasta: Vector2 = p - global_position + Vector2(0, -40)
				lienzo.draw_line(punta, hasta, Color(VERDE, brillo * 0.5), 9.0)
				lienzo.draw_line(punta, hasta, Color(Color.WHITE, brillo), 3.0)
		"lenguas":
			# salen disparadas de la boca, culebrean y se recogen
			var largo := LARGO_LENGUA * minf(1.0, t / 0.08) * clampf((DESPUES - t) / 0.18, 0.0, 1.0)
			for a in angulos_lenguas():
				lienzo.draw_set_transform(Vector2(0, -arriba * BOCA), a)
				var puntos := PackedVector2Array()
				for i in 15:
					var f := i / 14.0
					puntos.append(Vector2(largo * f, sin(f * 9.0 + t * 35.0 + a * 5.0) * 7.0 * (1.0 - f)))
				lienzo.draw_polyline(puntos, CONTORNO, 13.0)
				lienzo.draw_polyline(puntos, LENGUA, 8.0)
				lienzo.draw_polyline(puntos.slice(0, 9), LENGUA_LUZ, 3.0)
			lienzo.draw_set_transform(Vector2.ZERO)
		"escupir":
			# el fogonazo en la boca
			if t < 0.25:
				var boca := Vector2(0, -arriba * BOCA) + mirada * 30.0
				lienzo.draw_circle(boca, 26.0 * (1.0 - t / 0.25), Color(FUEGO[0], 0.7))
				lienzo.draw_circle(boca, 14.0 * (1.0 - t / 0.25), Color(FUEGO[3], 0.9))
