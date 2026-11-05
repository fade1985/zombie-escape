# La base de todos los zombis: persigue a Johnny esquivando paredes y muebles, le da zarpazos al llegar, y se
# encoge o se muere cuando le pegan o le disparan. Los números son los del juego de navegador (src/zombies.js).
#
# Cada tipo es una escena (escenas/personajes/zombi_*.tscn) que pone sus números en el Inspector (vida,
# velocidad, daño...). El normal, el lento y el rápido solo cambian esos números; los que tienen un ataque
# especial (explosivo, tentáculos y venenoso) tienen además su script, que "hereda" de este: usa todo lo de
# aquí y solo cambia lo suyo.
#
# Fase 7a: los charcos les ponen estados (estados.gd), el fuego del molotov los prende (siguen ardiendo un
# rato al salir, y el que arde prende a los que tiene pegados: contagiar) y las mutaciones de Johnny los aturden
# (se quedan quietos) o los desorientan (dan vueltas sin rumbo). Aturdidos o desorientados no hacen daño. Con
# ácido, todo les quita más (ArmasCreadas.con_acido).
class_name Zombi
extends CharacterBody2D

signal murio   # avisa cuando se muere (la sala cuenta los muertos para sacar más)
signal prendido   # avisa cuando empieza a arder (para el logro "Pirómano")
signal herido(cantidad: int, golpe: bool)   # le quitan vida: con un golpe o una bala (golpe) o con el fuego y los charcos

const FRENADA := 900.0     # lo rápido que se para después de que le empujen de un golpe
const VISTA := 330.0       # dormido, a qué distancia ve a Johnny (si no hay un muro en medio)
const OIDO := 430.0        # dormido, a qué distancia oye un disparo (aunque haya muros)
const CORRILLO := 140.0    # al despertar, despierta también a los que tiene a esta distancia
const ESPABILAR := 0.5     # lo que tarda en echar a andar después de despertar
const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]
const CAPA_ZOMBIS := 3     # su capa de choque, la 3 de project.godot

@export var vida_max := 30
@export var velocidad := 80.0    # unidades por segundo
@export var dano := 10           # lo que quita cada zarpazo (0 = no da zarpazos)
@export var radio := 16.0        # su círculo de choque (Johnny y las balas lo usan para saber si le dan)
@export var alcance := 18.0      # a qué distancia de Johnny (además de los dos radios) lanza el zarpazo
@export var empuje := 1.0        # cuánto sale despedido con los golpes (1 = como el normal; más, más lejos)
@export var giro := 8.0          # lo rápido que cambia de rumbo (el rápido gira poco: se pasa de largo)
@export var bamboleo := 0.2      # cuánto se tambalea de lado a lado al andar
@export var bamboleo_ritmo := 2.3
@export var a_tirones := false   # el lento: avanza a tirones, como si se arrastrara con las manos
@export var altura := 86.0       # dónde le salen los números de daño (por encima de la cabeza)
# Las ropas: cada uno sale con una al azar (si no hay ninguna, se queda con la que trae su escena)
@export var ropas: Array[SpriteFrames] = []

var vida := 30
var importante := false    # el guardia de la tarjeta y el zombi de la llave: Ninja no los mata de un golpe (johnny.golpe_ninja)
var estado := "andar"      # "andar", "zarpazo", "golpe" o "muerto" (y los suyos en cada tipo)
var direccion := "s"
var tiempo := 0.0          # para el bamboleo al andar
var rumbo := Vector2.ZERO  # hacia dónde anda ahora (gira poco a poco hacia donde quiere ir)
var zarpazo_dado := false  # si ya ha dado el golpe en este zarpazo (solo uno por animación)
var momento_zarpazo := 0.429   # en qué punto de la animación de ataque llega la mano (lo pone su hoja)
# Los zombis de los apartamentos esperan dormidos en su habitación ("zona") hasta que notan a Johnny
var dormido := false
# El público del plató del presentador (presentador.gd): dormido en su butaca, sin despertarse por ver a Johnny ni por
# oír disparos (ni por el corrillo de los de al lado): solo si le pegan o cuando el presentador le levanta
var sentado := false
var zona := -1
var espabilando := 0.0     # tiempo que le queda quieto después de despertar
var exclamacion := true     # suelta el "!" al despertar (la dependienta no: lo suyo es su grito)
var apretado := false      # pasando por una puerta abierta: ni se aparta de los demás ni choca con ellos (pedir_velocidad)

var estados := {}          # lo que le han puesto los charcos (estados.gd)
var pisando := {}          # los estados de los charcos que pisa en este paso
var estado_acc := 0.0      # el daño de los estados, que se le da a pellizcos
var estado_tick := 0.0
var arder_t := 0.0         # segundos que le quedan ardiendo
var arder_tick := 0.0
var arder_acc := 0.0       # la quemadura que lleva sin enseñar
var arder_texto := 0.0
var arder_dano := 1.0      # Puntería de quien lo prendió
var contagio_t := 0.0      # lo que lleva ardiendo desde que lo pasó a los de al lado (contagiar)
var chamuscado := 0.0      # recién apagado: lo que le queda para poder contagiarse otra vez
var llamas: Llamas
var acido_t := 0.0         # lo que lleva el ácido royéndole (las manchas crecen)
var muerte_fuerte := false # si ha caído de un golpe fuerte (MUERTE_FUERTE): revienta en sangre (partida.sangre, M49)
var talla_restos := "mediano"   # si muere quemado, la talla de su calavera y sus huesos (quemado.gd)
var aturdido := 0.0        # Tentacular, Flatulento: quieto
var liado := 0.0           # Locura: da vueltas sin rumbo
var frio_t := 0.0          # segundos seguidos dentro del frío de la cámara (peligros.gd): a los 4, se congela
var congelado := 0.0       # congelado: quieto y azul (también lleva "aturdido")
var gaseado := 0.0         # dormido por el gas de las rejillas de Recursos Humanos (peligros/gas.gd): quieto...
var frenesi := 0.0         # ...y, al despertar, frenético (más rápido) este rato
var electrico := 0.0       # le ha dado un rayo hace poco (ArmasCreadas.aturdir): para Mezcla explosiva
var lio_angulo := 0.0
# M80: la barrera del grito de la dependienta (zombi_dependienta.gd): mientras siga viva alguna de las que le han
# gritado ("barrera"), no hay quien le haga daño: las balas rebotan en su burbuja y los golpes, el fuego y los charcos
# no le quitan vida (antes, el grito les metía prisa)
var barrera: Array = []
var capas_barrera: Array[Sprite2D] = []   # las tres capas de la burbuja (detrás, delante y brillo), al ponérsela
var barrera_k := 0.0       # lo subida que está la burbuja (0 = no hay, 1 = entera)
var destello_barrera := 0.0   # lo que brilla porque le acaban de dar (de 1 a 0)
var exclamacion_suelta: Label   # el "!" que soltó al despertar (M80: si luego le ponen la barrera, se quita)
# La diana de la sala de pruebas (sala_armas.gd): no pierde vida (el daño se cuenta, pero se le devuelve en el
# acto), no da zarpazos y no se va de su sitio, "casa" (si un golpe la echa para atrás, vuelve andando). Sus números
# de daño los pone la sala, más grandes
var diana := false
var casa := Vector2.ZERO

# La sangre: salta al pegarle, deja charco si muere a golpes o a tiros y, el lento, va dejando su rastro
var color_sangre := Color("#7a1f1a")   # la pone la partida según el tipo (partida.gd, MANCHAS y SANGRE)
var a_golpes := false      # si el último daño fue un golpe o una bala (no fuego ni charcos)
var rastro := 0.0          # lo que ha avanzado desde la última marca del rastro
# El destello blanco al recibir un golpe: un shader que mezcla el dibujo con blanco
const DESTELLO := preload("res://escenas/personajes/destello.gdshader")
const BARRA := preload("res://scripts/barra_zombi.gd")
const CHARCO := preload("res://escenas/armas/charco.tscn")
const BOOM := preload("res://escenas/armas/explosion.tscn")   # la de Mezcla explosiva
# M80: la burbuja de la barrera: la cúpula de cristal del científico jefe pintada en dorado
# (tools/pixelfx/escudo-barrera.py), tres hojas de 8 × 6 fotogramas de 80 px a 20 por segundo
const BARRERA := [preload("res://assets/sprites/escudo-barrera-detras.png"),
	preload("res://assets/sprites/escudo-barrera-delante.png"), preload("res://assets/sprites/escudo-barrera-brillo.png")]
const BARRERA_CENTRO := Vector2(40, 38)   # el centro de la esfera en cada fotograma (en píxeles del dibujo)
const BARRERA_RADIO := 31.0               # lo que mide la esfera en el dibujo (de radio)
const BARRERA_SUBE := 0.3                 # lo que tarda en subir (y en bajar)
const BARRERA_CABEZA := 12.0              # lo alto de la cabeza, esto por debajo de sus números de daño ("altura")
const BARRERA_MARGEN := 6.0               # lo que sobra de burbuja por encima de la cabeza y por debajo de los pies

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var agente: NavigationAgent2D = $Agente


func _ready() -> void:
	collision_mask |= Planta.CAPA_BORDE   # el borde del helipuerto de la azotea (planta.gd): andando, no se cruza
	vida = vida_max
	# su reventón de sangre (M49), preparado para que el primero no pare el juego un momento (solo una vez por color)
	EfectoSuelo.precalentar(get_parent(), EfectoSuelo.SANGRE.get(get_meta("tipo", ""), "sangre"))
	if not ropas.is_empty():
		sprite.sprite_frames = ropas.pick_random()
	poner_animacion("reposo")
	# Cada uno empieza su bamboleo en un punto distinto, para que no anden todos al compás
	tiempo = randf() * 10.0
	agente.max_speed = velocidad
	# El agente nos devuelve aquí la velocidad ya corregida para no chocar con otros zombis
	agente.velocity_computed.connect(_al_calcular_velocidad)
	sprite.animation_finished.connect(_al_acabar_animacion)
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = DESTELLO
	# para el fuego y el ácido de su shader: que cada uno arda distinto, y lo que mide su cuerpo en píxeles del dibujo
	# (de los pies, que están en el 0 del dibujo, a lo alto de la cabeza, un poco por debajo de sus números de daño)
	sprite.material.set_shader_parameter("semilla", randf() * 100.0)
	sprite.material.set_shader_parameter("alto", (altura + sprite.position.y) / sprite.scale.y * 0.85)
	# la barrita de vida encima de la cabeza (sale al herirle)
	var barra := BARRA.new()
	barra.zombi = self
	barra.alto = altura - 8.0
	add_child(barra)


# Se pone blanco de golpe y vuelve a su color enseguida
func destellar() -> void:
	sprite.material.set_shader_parameter("destello", 0.9)
	var t := create_tween()
	t.tween_interval(0.05)
	t.tween_property(sprite.material, "shader_parameter/destello", 0.0, 0.1)


# Dónde dejar las manchas: en el mismo sitio que el zombi
func suelo() -> Node:
	return get_parent()


# El lento, mientras se arrastra, deja una estela de sangre detrás: dos marquitas, una a cada lado
func dejar_rastro(delta: float) -> void:
	if not a_tirones or velocity.length() < 5.0:
		return
	rastro += velocity.length() * delta
	if rastro < 4.0:
		return
	rastro = 0.0
	var lado := velocity.normalized().orthogonal() * 5.0
	for s in [-1.0, 0.0, 1.0]:
		if randf() < 0.85:
			Mancha.gota(suelo(), global_position + Vector2(0, 4) + lado * s + Vector2(randf_range(-2, 2), randf_range(-2, 2)),
				Color(color_sangre, randf_range(0.3, 0.5)), Vector2(4, 4), "Rastro", 1400)   # no-tr (nombre de nodo)


func _physics_process(delta: float) -> void:
	if estado == "muerto":
		return
	tiempo += delta
	if not capas_barrera.is_empty():
		animar_barrera(delta)
	sufrir(delta)
	if estado == "muerto":
		return
	var johnny := objetivo()
	if dormido or espabilando > 0.0:
		pedir_velocidad(Vector2.ZERO)
		poner_animacion("reposo")
		if dormido:
			vigilar(johnny)
		else:
			espabilando -= delta
			if johnny:
				mirar_hacia(johnny.global_position - global_position)
		return
	# Aturdido o desorientado: se le corta lo que hacía (salvo la mecha del explosivo, que ya no se apaga)
	if (aturdido > 0.0 or liado > 0.0) and estado != "mecha":
		mareo(delta)
		return

	match estado:
		"andar":
			if johnny == null or not johnny.vivo:
				pedir_velocidad(Vector2.ZERO)
				poner_animacion("reposo")
				return
			# la atraedora (arrojadiza creada) suena: va hacia ella en vez de hacia Johnny
			var cebo := cebo_cerca()
			if cebo:
				ir_hacia(delta, camino_hacia(cebo.global_position), velocidad)
				dejar_rastro(delta)
				return
			andar(delta, johnny)
			dejar_rastro(delta)

		"zarpazo":
			pedir_velocidad(Vector2.ZERO)
			# Cuando la mano llega abajo, si Johnny sigue a tiro, le da
			if not zarpazo_dado and avance_animacion() >= momento_zarpazo:
				zarpazo_dado = true
				if johnny and global_position.distance_to(johnny.global_position) < radio + johnny.RADIO + alcance + 10.0:
					dar_zarpazo(johnny)

		"golpe":
			# Sale despedido hacia atrás y va frenando; aquí no se usa el agente, se mueve él solo
			velocity = velocity.move_toward(Vector2.ZERO, FRENADA * delta)
			move_and_slide()
			# Si su hoja no tiene animación de encogerse, sigue al dejar de deslizarse
			if not sprite.animation.begins_with("golpe") and velocity.length() < 5.0:
				estado = "andar"

		_:
			# Los estados propios de cada tipo (la mecha del explosivo, el latigazo...)
			estado_propio(delta, johnny)


# A por quién va: Johnny o, en la horda del superviviente, el que fuerza la cerradura si le pilla más cerca o
# Johnny se ha alejado de él (presaDe del JS; ver supervivientes.gd y aliado.gd)
func objetivo() -> Node2D:
	var johnny := get_tree().get_first_node_in_group("jugador")
	var presa := get_tree().get_first_node_in_group("presa")
	if presa and johnny and not dormido and presa.presa_de(self, johnny, Supervivientes.HORDA.lejos):
		return presa
	return johnny


# La atraedora que le está llamando (la más cercana a menos de su distancia), o null
func cebo_cerca() -> Node2D:
	var mejor: Node2D = null
	var cerca: float = Lanzables.ARROJADIZAS.atraedora.atrae
	for cebo in get_tree().get_nodes_in_group("cebos"):
		var d := global_position.distance_to(cebo.global_position)
		if d < cerca:
			cerca = d
			mejor = cebo
	return mejor


# Andar normal: va a por Johnny y, al llegar, le da un zarpazo. Los tipos especiales lo cambian
func andar(delta: float, johnny: Node2D) -> void:
	if diana:
		quedarse(delta, johnny)
		return
	if dano > 0 and distancia_a(johnny) < radio + johnny.RADIO + alcance and se_ve(johnny):
		empezar_zarpazo(johnny)
		return
	ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)


# La diana: quieta en su sitio, mirando a Johnny; si la han movido, vuelve
func quedarse(delta: float, johnny: Node2D) -> void:
	if global_position.distance_to(casa) > 6.0:
		ir_hacia(delta, global_position.direction_to(casa), velocidad)
		return
	pedir_velocidad(Vector2.ZERO)
	mirar_hacia(johnny.global_position - global_position)
	poner_animacion("reposo")


# Lo rellenan los tipos que tienen estados suyos
func estado_propio(_delta: float, _johnny: Node2D) -> void:
	pass


# Le decimos al agente adónde queremos ir, y él nos da la dirección del siguiente punto del camino
# (el camino rodea paredes y muebles: lo saca de la región de navegación de la sala)
func camino_hacia(destino: Vector2) -> Vector2:
	agente.target_position = destino
	return global_position.direction_to(agente.get_next_path_position())


# Anda en esa dirección, girando poco a poco (según "giro") y con su bamboleo
func ir_hacia(delta: float, hacia: Vector2, rapidez: float) -> void:
	if rumbo == Vector2.ZERO:
		rumbo = hacia
	rumbo = rumbo.lerp(hacia, 1.0 - exp(-delta * giro)).normalized()
	var paso := rumbo + rumbo.orthogonal() * sin(tiempo * bamboleo_ritmo) * bamboleo
	if a_tirones:
		rapidez *= 0.55 + 0.45 * absf(sin(tiempo * 2.0))
	if frenesi > 0.0:
		rapidez *= Peligros.GAS.rapido   # (despierta frenético del gas)
	rapidez *= Estados.frenado(estados)   # el frío de la cámara
	if not Tornos.frenan.is_empty():
		rapidez *= Tornos.freno(global_position)   # los tornos a medio abrir de la recepcionista (tornos.gd)
	if con_acido():
		rapidez *= 1.0 - Mejoras.de_johnny(get_tree(), "pegajoso")   # (Pegajoso: el ácido los frena)
	pedir_velocidad(paso.normalized() * rapidez)
	mirar_hacia(paso)
	poner_animacion("andar")


# Dormido: se despierta si Johnny entra en su habitación o le ve cerca sin un muro en medio. Con la skin de la modista
# (Skins.camuflaje), entrar en la habitación no le despierta, y le ve solo a la mitad de distancia
func vigilar(johnny: Node2D) -> void:
	if johnny == null or not johnny.vivo or sentado:
		return
	var mapa := get_tree().get_first_node_in_group("mapa")
	var camuflaje := Skins.camuflaje(johnny.get("skin") if johnny.get("skin") != null else "")
	if (camuflaje >= 1.0 and mapa and zona >= 0 and mapa.zona_en(johnny.global_position) == zona) 			or (distancia_a(johnny) < VISTA * camuflaje and se_ve(johnny)):
		despertar()


# Suelta un "!" y, al rato, echa a andar. Arrastra a los que tiene al lado.
func despertar() -> void:
	if not dormido:
		return
	dormido = false
	if sentado:
		sentado = false
		# (sentado, ni se aparta de los de al lado ni choca con ellos: presentador.gd, sentar_publico)
		agente.avoidance_enabled = true
		set_collision_mask_value(CAPA_ZOMBIS, true)
	espabilando = ESPABILAR
	if exclamacion and not con_barrera():   # (M80: con la barrera puesta, sin el "!": ya se ve la burbuja)
		exclamacion_suelta = Zombi.texto_flotante(get_parent(), global_position + Vector2(-4, -altura), "!", Color("ffd23f"), 26)
	for otro in get_tree().get_nodes_in_group("zombis"):
		if otro != self and otro.get("dormido") and not otro.get("sentado") and distancia_a(otro) < CORRILLO:
			otro.despertar()


# M80: el grito de la dependienta "de" le pone la barrera (la burbuja se prepara la primera vez: lo de detrás, por
# debajo de su dibujo; lo de delante y el brillo, encima)
func meter_barrera(de: Node) -> void:
	if de not in barrera:
		barrera.append(de)
	# (si se acababa de despertar, fuera su "!": con la burbuja ya se ve que viene)
	if is_instance_valid(exclamacion_suelta):
		exclamacion_suelta.queue_free()
	if not capas_barrera.is_empty():
		return
	for i in 3:
		var capa := Sprite2D.new()
		capa.texture = BARRERA[i]
		capa.hframes = 8
		capa.vframes = 6
		capa.offset = Vector2(40, 40) - BARRERA_CENTRO
		capa.position = centro_burbuja() - global_position
		capa.visible = false
		if i > 0:
			capa.z_index = 1
		if i == 2:
			var suma := CanvasItemMaterial.new()
			suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			capa.material = suma
		add_child(capa)
		move_child(capa, sprite.get_index() + (0 if i == 0 else i))
		capas_barrera.append(capa)


# M80: ¿tiene la barrera? Mientras quede viva alguna de las dependientas que le han gritado
func con_barrera() -> bool:
	barrera = barrera.filter(func(d): return is_instance_valid(d) and d.estado != "muerto")
	return not barrera.is_empty() and estado != "muerto"


# M80: la burbuja sube al ponérsela y baja al quitársela (al morir la última dependienta), y brilla al darle
func animar_barrera(delta: float) -> void:
	barrera_k = clampf(barrera_k + delta / BARRERA_SUBE * (1.0 if con_barrera() else -1.0), 0.0, 1.0)
	destello_barrera = maxf(0.0, destello_barrera - delta * 4.0)
	var cuadro := int(tiempo * 20.0) % 48
	for capa in capas_barrera:
		capa.visible = barrera_k > 0.0
		capa.scale = Vector2.ONE * radio_burbuja() / BARRERA_RADIO
		capa.frame = cuadro
	capas_barrera[1].modulate = Color.WHITE.lerp(Color(1.5, 1.4, 1.1), destello_barrera)
	capas_barrera[2].modulate = Color.WHITE * (1.0 + 2.0 * destello_barrera)


# M80: la burbuja, tal como se ve (bala.gd la mira para que la bala rebote en su borde, como en la del bombero)
# (centrada entre los pies, en el 0 de su dibujo, y lo alto de la cabeza, un poco por debajo de sus números de daño;
# con un pelín de margen por arriba y por abajo)
func centro_burbuja() -> Vector2:
	return global_position + Vector2(0, (sprite.position.y - altura + BARRERA_CABEZA) / 2.0)


func radio_burbuja() -> float:
	return ((sprite.position.y + altura - BARRERA_CABEZA) / 2.0 + BARRERA_MARGEN) * barrera_k


func escudo_toca(p: Vector2) -> bool:
	return barrera_k > 0.5 and con_barrera() and p.distance_to(centro_burbuja()) < radio_burbuja()


# Los colores del rebote de las balas en la burbuja (en dorado), de blanco a oscuro como pide impacto.gd
func colores_escudo() -> Array:
	return [Color.WHITE, Color("#fff8dc"), Color("#ffd23f"), Color("#e0aa2a"), Color("#a87818")]


# Una bala ha rebotado en su burbuja (bala.gd, rebotar): la burbuja brilla
func onda_en(_p: Vector2) -> void:
	destello_barrera = 1.0


# Los disparos se oyen (las armas de cuerpo a cuerpo son silenciosas): lo llama Johnny al disparar, y también el policía
# y el militar (aliado.gd, M43)
func oir_disparo(donde: Vector2) -> void:
	# (con la Alerta 5, más lejos; con el reto del día "Oído fino", el triple)
	if dormido and not sentado and global_position.distance_to(donde) < OIDO * Alerta.oido() * Reto.oido():
		despertar()


func distancia_a(nodo: Node2D) -> float:
	return global_position.distance_to(nodo.global_position)


# Un "rayo" del zombi a Johnny: si choca con una pared, un mueble o una puerta cerrada (capa 1), no le ve
func se_ve(nodo: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, nodo.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# ¿Está en una puerta abierta de dentro (mapa/puerta_bano.gd), en su "arrimo"? Ahí pasan apretados (pedir_velocidad) y
# los que atacan de lejos no se plantan: primero salen de ella, o se la taponarían a los de detrás
func en_puerta() -> bool:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa:
		for hoja in mapa.hojas:
			if hoja.abriendo and hoja.arrimo.has_point(global_position):
				return true
	return false


# Con el "avoidance" encendido no se mueve directamente: se le pasa al agente la velocidad que queremos,
# y él la corrige (si hay otro zombi delante, la tuerce un poco) y nos la devuelve en _al_calcular_velocidad.
# En una puerta abierta, no: el agente no sabe de paredes y le empujaría contra el marco, y si además chocaran entre
# ellos se trabarían en el hueco. Ahí pasan apretados: con la velocidad tal cual y sin chocar con los otros zombis
func pedir_velocidad(v: Vector2) -> void:
	agente.velocity = v
	var puerta := en_puerta()
	if puerta != apretado:
		apretado = puerta
		set_collision_mask_value(CAPA_ZOMBIS, not puerta)
	if apretado:
		mover(v)


func _al_calcular_velocidad(segura: Vector2) -> void:
	if not apretado:
		mover(segura)


func mover(segura: Vector2) -> void:
	if estado == "golpe" or estado == "muerto" or aturdido > 0.0:
		return
	# en la lejía resbala: le cuesta cambiar de velocidad
	var agarre := Estados.agarre(estados)
	if agarre < 1.0:
		segura = velocity.lerp(segura, 1.0 - exp(-get_physics_process_delta_time() * 14.0 * maxf(0.08, agarre)))
	velocity = segura
	move_and_slide()


func empezar_zarpazo(johnny: Node2D) -> void:
	estado = "zarpazo"
	zarpazo_dado = false
	mirar_hacia(johnny.global_position - global_position)
	poner_animacion("ataque")


# El zarpazo le llega a Johnny (cada tipo puede añadirle lo suyo: el táser del escolta de Velaria lo deja tieso)
func dar_zarpazo(johnny: Node2D) -> void:
	johnny.recibir_dano(dano, self)


# Lo llaman las armas de Johnny (golpes y balas) y las explosiones. "fuerza" es hacia dónde y con qué
# fuerza sale despedido (la de un zombi normal: cada tipo la multiplica por su "empuje"). Con ácido, le quita más
# (ArmasCreadas.con_acido)
func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	if estado == "muerto":
		return
	if gaseado > Peligros.GAS.duerme:
		espabilar_gas()   # (el sueño largo de la planta de la limpiadora: con un golpe, se despierta frenético)
	if dormido:
		despertar()
		espabilando = 0.0   # con un golpe no hay tiempo de pensárselo
	if con_barrera():   # M80: con la barrera, el golpe le empuja un poco pero no le quita vida
		velocity = fuerza * empuje * 0.5
		destello_barrera = 1.0
		return
	cantidad = ArmasCreadas.con_acido(self, cantidad)
	vida -= cantidad
	herido.emit(cantidad, true)
	if diana:
		vida = vida_max
	velocity = fuerza * empuje
	numero_flotante(cantidad)
	Sonido.tocar("golpe")
	a_golpes = true
	destellar()
	# la sangre salta hacia donde va el golpe (más si es el último)
	Particulas.salpicar(self, suelo(), global_position + Vector2(0, 6), altura * 0.5, fuerza, color_sangre,
		10 if vida <= 0 else 5)
	# Se gira hacia quien le ha pegado (al revés del empuje)
	mirar_hacia(-fuerza)
	if vida <= 0:
		# de un golpe fuerte: un crítico, uno que empuja tanto como una explosión o uno que le sobra media vida
		muerte_fuerte = Zombi.critico or fuerza.length() >= MUERTE_FUERTE or -vida >= vida_max / 2
		morir()
	else:
		encogerse()


func encogerse() -> void:
	estado = "golpe"
	poner_animacion("golpe", true)


func morir() -> void:
	if diana:   # (por si algo la mata de golpe: la diana no se muere)
		vida = vida_max
		encogerse()
		return
	estado = "muerto"
	if congelado > 0.0:
		deshelar()   # (muere congelado: el hielo revienta)
	Sonido.tocar("chof")
	Sonido.tocar("muerte")
	$Sombra.apagar()
	var cae: bool = sprite.sprite_frames.has_animation("muerte_" + direccion)
	Zombi.quemaduras(sprite, 0.0, 0.0, tiempo)   # (si cae ardiendo, le vuelve a poner el fuego quemado.gd)
	if has_node("LuzAcido"):
		get_node("LuzAcido").queue_free()
	if arder_t > 0.0 and not cae:
		# murió ardiendo (sin animación de caer): queda chamuscado y su luz se apaga poco a poco
		sprite.self_modulate = Color(0.32, 0.27, 0.27)
		create_tween().tween_property(llamas, "fuerza", 0.0, 0.6)
	else:
		sprite.self_modulate = Color.WHITE
	if cae:
		poner_animacion("muerte")
		if arder_t > 0.0:
			Quemado.empezar(self, sprite, talla_restos)   # cae en llamas, se vuelve carbón y se deshace en ceniza
	else:
		# Sin animación de morir (el de tentáculos): se queda quieto, cae de lado y se oscurece
		sprite.pause()
		var tween := create_tween().set_parallel()
		tween.tween_property(sprite, "rotation", PI / 2 * (1 if randf() < 0.5 else -1), 0.35)
		tween.tween_property(sprite, "modulate", Color(0.55, 0.5, 0.55), 0.35)
	remove_from_group("zombis")
	# El cuerpo ya no choca ni se aparta de nadie: se queda en el suelo, por debajo de los que siguen de pie
	$Choque.set_deferred("disabled", true)
	agente.avoidance_enabled = false
	z_index = -1
	Cuerpo.caer(self, sprite)   # si tendido se metería en una pared, resbala al caer
	quimica_al_morir()
	murio.emit()


# Si lleva ácido encima: el de un charco o el que le sigue royendo (la herida del lanza ácido)
func con_acido() -> bool:
	return estados.has("acido") or has_node("herida_acido")


# Cuántos efectos lleva a la vez, de los cuatro de Químico: fuego, ácido, rayo (el calambre de hace poco) y frío
func efectos_puestos() -> int:
	return [arder_t > 0.0, con_acido(), electrico > 0.0, congelado > 0.0].count(true)


# Los talentos de Químico al morir: Reacción en cadena (si muere ardiendo, revienta y prende a los de al lado, como el
# truco de las Épicas), Residuo tóxico (si lleva ácido, deja un charco de ácido que solo daña a los zombis) y Mezcla
# explosiva (si lleva dos efectos a la vez, explota; a Johnny no le hace nada). Los que prende, mancha o revienta pueden
# morir igual y seguir la cadena
func quimica_al_morir() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null:
		return
	if johnny.stats.mezcla and efectos_puestos() >= 2:
		var boom := BOOM.instantiate()
		boom.radio = Talentos.MEZCLA.radio
		boom.dano_zombis = roundi(Talentos.MEZCLA.dano * johnny.stats.dano_quimico)   # (con el Catalizador, más)
		boom.a_johnny = false
		boom.position = position
		get_parent().add_child.call_deferred(boom)
	if johnny.stats.reaccion and arder_t > 0.0:
		ArmasCreadas.estallido(self, "llama", 0.0, arder_dano)
	if johnny.stats.residuo and con_acido():
		var charco: Node2D = CHARCO.instantiate()
		charco.tipo = "residuo"
		charco.position = (position / 2.0).round() * 2.0   # (en píxel entero del dibujo, como los demás charcos)
		get_parent().add_child.call_deferred(charco)


# ── Estados, fuego y mareo ──

# Lo llaman los charcos en cada paso mientras los pisa
func pisar(estados_charco: Dictionary) -> void:
	Estados.pisar(pisando, estados_charco, true)


# El fuego lo prende (o le renueva la quemadura si ya ardía). Las llamas se las pinta su shader (quemaduras), y de
# Llamas solo lleva su luz naranja, que le alumbra a él y alrededor
func prender(dano_lanzar := 1.0) -> void:
	if arder_t <= 0.0 and estado != "muerto":
		prendido.emit()
		contagio_t = 0.0
	arder_t = Lanzables.MOLOTOV.sigue + Mejoras.de_johnny(get_tree(), "arde_extra")   # (Incendiario: más)
	arder_dano = dano_lanzar
	if llamas == null:
		llamas = Llamas.new()
		llamas.alto = altura * 0.8
		llamas.ancho = radio
		llamas.cuerpo = false
		add_child(llamas)


# Daño sin golpe (los estados, el fuego): no le empuja ni se encoge; el número sale del color de lo que le daña. Con
# ácido, como los golpes, le quita más
func herir(cantidad: float, color := Color.WHITE) -> void:
	if estado == "muerto":
		return
	if dormido:
		despertar()
	if con_barrera():   # M80: con la barrera, ni el fuego ni los charcos le quitan vida
		return
	var n := ArmasCreadas.con_acido(self, maxi(1, roundi(cantidad)))
	vida -= n
	herido.emit(n, false)
	if diana:
		vida = vida_max
	a_golpes = false
	Zombi.texto_flotante(get_parent(), global_position + Vector2(randf_range(-14, 2), -altura), str(n), color, 16)
	if vida <= 0:
		morir()


# Cada paso: los estados de los charcos (a pellizcos cada medio segundo), la quemadura y lo que se ve encima
func sufrir(delta: float) -> void:
	gas_y_frenesi(delta)
	# el frío de la cámara: tras unos segundos seguidos dentro, se congela (y al deshelarse vuelve a contar)
	if not pisando.has("frio"):
		frio_t = 0.0
	elif congelado <= 0.0:
		frio_t += delta
		if frio_t >= Peligros.FRIO.congela:
			congelar(Peligros.FRIO.congelado)
	var dano := Estados.actualizar(estados, pisando, delta)
	pisando = {}
	if dano > 0.0:
		estado_acc += dano
		estado_tick += delta
		if estado_tick >= Estados.TICK_ZOMBI:
			var color := Estados.color(estados)
			var cuanto := estado_acc
			estado_acc = 0.0
			estado_tick = 0.0
			herir(cuanto, color)
	else:
		estado_tick = 0.0
	chamuscado = maxf(chamuscado - delta, 0.0)
	if arder_t > 0.0:
		arder(delta)
	if llamas:
		llamas.fuerza = clampf(arder_t / 0.5, 0.0, 1.0)
	# arder y el ácido (el de los charcos o el que le sigue royendo del lanza ácido: armas_creadas.gd, la herida) se
	# los pinta su shader, con su luz; los demás estados, con su tinte suave
	var arde := arder_t > 0.0
	var acido := con_acido()
	acido_t = acido_t + delta if acido else 0.0
	electrico = maxf(electrico - delta, 0.0)
	# bañado en vómito (Gastroenteritis): se ve el vómito en vez de las manchas verdes de su ácido (salvo si además le
	# roe el del lanza ácido), y se le va escurriendo en el último medio segundo
	var vomito := 0.0
	if estados.has("vomito"):
		vomito = clampf(estados.vomito.t / 0.5, 0.0, 1.0)
		if not has_node("herida_acido"):
			acido_t = 0.0
	sprite.self_modulate = Color.WHITE if arde or acido or vomito > 0.0 else Estados.tinte(estados, tiempo)
	Zombi.quemaduras(sprite, 1.0 if arde else 0.0, Zombi.cuanto_acido(acido_t), tiempo, vomito)
	if acido or has_node("LuzAcido"):
		var luz := Brillo.luz_acido(self, altura * 0.8)
		luz.visible = acido
		luz.fuerza = 0.55
	if congelado > 0.0:
		congelado -= delta
		if congelado <= 0.0:
			deshelar()
	Estados.efectos(self, estados, velocity, delta, altura * 0.6, radio)


# El fuego y el ácido de un dibujo con el shader de los zombis (escenas/personajes/quemaduras.gdshaderinc): "fuego"
# (0-1, con menos las llamas se encogen) y "acido" (0-1, las manchas crecen), con "t" de reloj. Si hay algo, le pone
# encima la copia que brilla a oscuras (Brillo). También lo usan quemado.gd y, con el ácido, los jefes
# (armas_creadas.gd, la herida)
static func quemaduras(s: CanvasItem, fuego: float, acido: float, t: float, vomito := 0.0) -> void:
	var m := s.material as ShaderMaterial
	m.set_shader_parameter("fuego", fuego)
	m.set_shader_parameter("acido", acido)
	m.set_shader_parameter("vomito", vomito)
	m.set_shader_parameter("t", fmod(t, 100.0))   # (con números pequeños, el ruido del shader no se estropea)
	if (fuego > 0.0 or acido > 0.0) and s is AnimatedSprite2D:
		Brillo.de(s)
	elif s.has_node("Brillo"):
		s.get_node("Brillo").hide()   # (se esconde ya, sin esperar a su paso)


# Cuánto le han crecido las manchas de ácido tras "puesto" segundos (de un poco a todo en segundo y medio; 0 sin ácido)
static func cuanto_acido(puesto: float) -> float:
	return 0.0 if puesto <= 0.0 else clampf(0.3 + puesto / 1.5, 0.0, 1.0)


# Se le acaba el congelado (o muere congelado: morir): el hielo revienta (M51: el "deshielo" de pixelfx, EfectoSuelo) y
# vuelve a moverse su dibujo
func deshelar() -> void:
	congelado = 0.0
	sprite.material.set_shader_parameter("hielo", 0.0)
	sprite.play()
	Sonido.tocar("deshielo")
	EfectoSuelo.soltar(get_parent(), "deshielo", global_position)


# El gas de las rejillas (peligros/gas.gd) le duerme: se queda quieto "dormir" segundos y despierta frenético
# (gas_y_frenesi). Mientras le dura una cosa u otra, el gas ya no le hace nada
func gasear(dormir: float) -> void:
	if gaseado > 0.0 or frenesi > 0.0 or estado == "muerto":
		return
	gaseado = dormir
	aturdido = maxf(aturdido, dormir)
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-8, -altura), "z", Color("#c77dff"), 18)   # no-tr


# Que se despierte ya del gas (frenético): lo usan las válvulas de la planta de la limpiadora de noche (valvulas.gd),
# que duermen a todo el departamento hasta que se cierra una válvula cerca, y un golpe
func espabilar_gas() -> void:
	if gaseado > 0.0:
		gaseado = 0.05
		aturdido = minf(aturdido, 0.05)


func gas_y_frenesi(delta: float) -> void:
	if gaseado > 0.0:
		gaseado -= delta
		aturdido = maxf(aturdido, gaseado)
		if gaseado <= 0.0:
			# despierta frenético: un "!" morado y más rápido un rato
			frenesi = Peligros.GAS.frenetico
			agente.max_speed *= Peligros.GAS.rapido
			Zombi.texto_flotante(get_parent(), global_position + Vector2(-4, -altura), "!", Color("#d38cff"), 26)
	elif frenesi > 0.0:
		frenesi -= delta
		if randf() < 6.0 * delta:
			Particulas.soltar(self, global_position + Vector2(randf_range(-10, 10), -altura * randf_range(0.3, 0.9)),
				Vector2(randf_range(-20, 20), -40), Color("#c77dff"), 2, 0.35)
		if frenesi <= 0.0:
			agente.max_speed /= Peligros.GAS.rapido


# Se queda helado: quieto, azul y con el dibujo parado, soltando escarcha
func congelar(segundos: float) -> void:
	frio_t = 0.0
	congelado = segundos
	aturdido = maxf(aturdido, segundos)
	sprite.material.set_shader_parameter("hielo", 0.6)   # azul hielo (el mismo shader del destello)
	Sonido.tocar("cristal")
	EfectoSuelo.soltar(get_parent(), "escarcha-zombi", global_position)   # (M51: el estallido de escarcha pequeño)


# Ardiendo: la quemadura a pellizcos, y el número cada medio segundo (o si ya le mata). Cada "contagia" segundos
# prende a los que tiene pegados (contagiar), y al apagarse se queda chamuscado
func arder(delta: float) -> void:
	var m := Lanzables.MOLOTOV
	arder_t -= delta
	if arder_t <= 0.0:
		chamuscado = m.chamuscado
	contagio_t += delta
	if contagio_t >= m.contagia:
		contagio_t -= m.contagia
		contagiar()
	arder_tick += delta
	if arder_tick < m.tick:
		return
	arder_tick -= m.tick
	arder_acc += m.quema * m.tick * arder_dano
	arder_texto += m.tick
	if arder_texto >= 0.5 or vida <= arder_acc:
		var cuanto := arder_acc
		arder_acc = 0.0
		arder_texto = 0.0
		herir(cuanto, Llamas.FUEGO[2])


# El fuego se contagia: prende a los zombis que tiene pegados que no ardan ya ni se acaben de apagar (chamuscado), con
# la misma fuerza que su fuego, durante "contagio" segundos, y les salta una chispa. Los jefes no arden
func contagiar() -> void:
	var m := Lanzables.MOLOTOV
	var desde := global_position + Vector2(0, -altura * 0.5)
	for o in get_tree().get_nodes_in_group("zombis"):
		if o == self or not o is Zombi or o.estado == "muerto" or o.arder_t > 0.0 or o.chamuscado > 0.0:
			continue
		if global_position.distance_to(o.global_position) > radio + o.radio + m.pegado:
			continue
		o.prender(arder_dano)
		o.arder_t = m.contagio + Mejoras.de_johnny(get_tree(), "arde_extra")   # (Incendiario: más)
		var hacia: Vector2 = desde.direction_to(o.global_position + Vector2(0, -o.altura * 0.5))
		for i in 4:
			Particulas.soltar(self, desde + Vector2(randf_range(-4, 4), randf_range(-6, 6)),
				hacia * randf_range(90, 150) + Vector2(0, -randf_range(10, 40)), Llamas.FUEGO[i % 3], 2, randf_range(0.25, 0.4))


# Aturdido no se mueve (salvo lo que le hayan empujado); desorientado anda despacio hacia un lado y otro.
# Chispitas sobre la cabeza: amarillas si está aturdido, moradas si está desorientado, copos si está congelado
func mareo(delta: float) -> void:
	if estado != "andar":
		estado = "andar"   # se le corta el zarpazo o su ataque especial
	if randf() < 5.0 * delta:
		Particulas.soltar(self, global_position + Vector2(randf_range(-10, 10), -altura * 0.75), Vector2(randf_range(-15, 15), -35),
			Color("#e8f6ff") if congelado > 0.0 else Color("#ffd23f") if aturdido > 0.0 and gaseado <= 0.0 else Color("#c77dff"), 2, 0.45)
	if aturdido > 0.0:
		aturdido -= delta
		velocity = velocity.move_toward(Vector2.ZERO, FRENADA * delta)
		move_and_slide()
		poner_animacion("reposo" if velocity.length() < 20.0 else "golpe")
		if congelado > 0.0:
			sprite.pause()
		return
	liado -= delta
	lio_angulo += delta * 2.5
	var hacia := Vector2.from_angle(lio_angulo)
	pedir_velocidad(hacia * velocidad * 0.4)
	mirar_hacia(hacia)
	poner_animacion("andar")


func numero_flotante(cantidad: int) -> void:
	if diana:
		return
	Zombi.numero_golpe(get_parent(), global_position + Vector2(randf_range(-14, 2), -altura), cantidad)


# El número de un golpe o una bala (en los zombis y los jefes): blanco o, si es crítico, amarillo, grande y con «!», para
# que se note (M15). "critico" lo pone quien pega (johnny.golpear y bala.gd) justo antes de recibir_golpe y lo quita después
static var critico := false
static var de_bala := false   # lo pone bala.gd mientras da a un zombi (el chaleco del escolta de Velaria solo para balas)
const MUERTE_FUERTE := 360.0   # el empuje de un golpe que revienta al zombi si lo mata (la explosión empuja 374)
const CRITICO := Color("#ffd23f")

static func numero_golpe(sala: Node, donde: Vector2, cantidad: int) -> void:
	if critico:
		Zombi.texto_flotante(sala, donde + Vector2(-6, -12), "%d!" % cantidad, CRITICO, 32)
	else:
		Zombi.texto_flotante(sala, donde, str(cantidad))


# Un texto que sube y se desvanece (los números de daño, los gritos de la portera...). Va en la sala, no
# en quien lo dice, para que no se mueva con él ni desaparezca si se muere. "static": se puede usar desde
# cualquier sitio sin tener un zombi, escribiendo Zombi.texto_flotante(...). "donde" es la esquina de arriba a la
# izquierda del texto, o su medio si es "centrado"; "dura" son los segundos que sube (0,6 en los números de daño)
static func texto_flotante(sala: Node, donde: Vector2, texto: String, color := Color.WHITE, tamano := 18,
		centrado := false, dura := 0.6) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.theme = Tema.crear()
	# la fuente pixel art solo se ve nítida a 16 o a 32 (un píxel suyo = 1 o 2 unidades)
	etiqueta.add_theme_font_size_override("font_size", 16 if tamano < 24 else 32)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 4 if tamano < 24 else 8)
	etiqueta.add_theme_color_override("font_outline_color", Color(0.11, 0.1, 0.17))
	etiqueta.z_index = 10
	sala.add_child(etiqueta)
	etiqueta.global_position = donde - Vector2(etiqueta.get_minimum_size().x / 2.0 if centrado else 0.0, 0.0)
	var tween := etiqueta.create_tween()
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 30.0, dura).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(etiqueta, "modulate:a", 0.0, dura).set_delay(dura * 0.25 / 0.6)
	tween.tween_callback(etiqueta.queue_free)
	return etiqueta


func _al_acabar_animacion() -> void:
	# Al acabar el zarpazo o el encogerse, vuelve a perseguir (la muerte se queda en el último fotograma)
	if estado == "zarpazo" or estado == "golpe":
		estado = "andar"


# Por dónde va la animación en curso, de 0 (empieza) a 1 (acaba)
func avance_animacion() -> float:
	var total := sprite.sprite_frames.get_frame_count(sprite.animation)
	return (sprite.frame + sprite.frame_progress) / total


# Elige una de las 8 direcciones según un vector (como en johnny.gd)
func mirar_hacia(v: Vector2) -> void:
	if v.length() > 0.01:
		direccion = DIRS[wrapi(roundi(v.angle() / (PI / 4)), 0, 8)]


# Pone "andar_se", "ataque_n"... Si solo cambia la dirección, sigue por el mismo fotograma.
# "otra_vez" la vuelve a empezar aunque ya estuviera puesta (dos golpes seguidos).
# Si la hoja no tiene esa animación (el de tentáculos solo tiene el dibujo quieto), pone el reposo
func poner_animacion(estado_anim: String, otra_vez := false) -> void:
	var nombre := estado_anim + "_" + direccion
	if not sprite.sprite_frames.has_animation(nombre):
		nombre = "reposo_" + direccion
	if sprite.animation == nombre and not otra_vez:
		return
	var mismo_estado := sprite.animation.get_slice("_", 0) == nombre.get_slice("_", 0)
	var fotograma := sprite.frame
	var avance := sprite.frame_progress
	sprite.play(nombre)
	if otra_vez:
		sprite.frame = 0
	elif mismo_estado:
		# Las direcciones no tienen todas los mismos fotogramas: si nos pasamos, volvemos a empezar
		sprite.set_frame_and_progress(fotograma % sprite.sprite_frames.get_frame_count(nombre), avance)
