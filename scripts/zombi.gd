# La base de todos los zombis: persigue a Johnny esquivando paredes y muebles, le da zarpazos al llegar, y se
# encoge o se muere cuando le pegan o le disparan. Los números son los del juego de navegador (src/zombies.js).
#
# Cada tipo es una escena (escenas/personajes/zombi_*.tscn) que pone sus números en el Inspector (vida,
# velocidad, daño...). El normal, el lento y el rápido solo cambian esos números; los que tienen un ataque
# especial (explosivo, tentáculos y venenoso) tienen además su script, que "hereda" de este: usa todo lo de
# aquí y solo cambia lo suyo.
class_name Zombi
extends CharacterBody2D

signal murio   # avisa cuando se muere (la sala cuenta los muertos para sacar más)

const FRENADA := 900.0     # lo rápido que se para después de que le empujen de un golpe
const VISTA := 330.0       # dormido, a qué distancia ve a Johnny (si no hay un muro en medio)
const OIDO := 430.0        # dormido, a qué distancia oye un disparo (aunque haya muros)
const CORRILLO := 140.0    # al despertar, despierta también a los que tiene a esta distancia
const ESPABILAR := 0.5     # lo que tarda en echar a andar después de despertar
const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]

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
var estado := "andar"      # "andar", "zarpazo", "golpe" o "muerto" (y los suyos en cada tipo)
var direccion := "s"
var tiempo := 0.0          # para el bamboleo al andar
var rumbo := Vector2.ZERO  # hacia dónde anda ahora (gira poco a poco hacia donde quiere ir)
var zarpazo_dado := false  # si ya ha dado el golpe en este zarpazo (solo uno por animación)
var momento_zarpazo := 0.429   # en qué punto de la animación de ataque llega la mano (lo pone su hoja)
# Los zombis de los apartamentos esperan dormidos en su habitación ("zona") hasta que notan a Johnny
var dormido := false
var zona := -1
var espabilando := 0.0     # tiempo que le queda quieto después de despertar

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var agente: NavigationAgent2D = $Agente


func _ready() -> void:
	vida = vida_max
	if not ropas.is_empty():
		sprite.sprite_frames = ropas.pick_random()
	poner_animacion("reposo")
	# Cada uno empieza su bamboleo en un punto distinto, para que no anden todos al compás
	tiempo = randf() * 10.0
	agente.max_speed = velocidad
	# El agente nos devuelve aquí la velocidad ya corregida para no chocar con otros zombis
	agente.velocity_computed.connect(_al_calcular_velocidad)
	sprite.animation_finished.connect(_al_acabar_animacion)


func _physics_process(delta: float) -> void:
	if estado == "muerto":
		return
	tiempo += delta
	var johnny := get_tree().get_first_node_in_group("jugador")
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

	match estado:
		"andar":
			if johnny == null or not johnny.vivo:
				pedir_velocidad(Vector2.ZERO)
				poner_animacion("reposo")
				return
			andar(delta, johnny)

		"zarpazo":
			pedir_velocidad(Vector2.ZERO)
			# Cuando la mano llega abajo, si Johnny sigue a tiro, le da
			if not zarpazo_dado and avance_animacion() >= momento_zarpazo:
				zarpazo_dado = true
				if johnny and global_position.distance_to(johnny.global_position) < radio + johnny.RADIO + alcance + 10.0:
					johnny.recibir_dano(dano)

		"golpe":
			# Sale despedido hacia atrás y va frenando; aquí no se usa el agente, se mueve él solo
			velocity = velocity.move_toward(Vector2.ZERO, FRENADA * delta)
			move_and_slide()
			# Si su hoja no tiene animación de encogerse (el de tentáculos), sigue al dejar de deslizarse
			if not sprite.animation.begins_with("golpe") and velocity.length() < 5.0:
				estado = "andar"

		_:
			# Los estados propios de cada tipo (la mecha del explosivo, el latigazo...)
			estado_propio(delta, johnny)


# Andar normal: va a por Johnny y, al llegar, le da un zarpazo. Los tipos especiales lo cambian
func andar(delta: float, johnny: Node2D) -> void:
	if dano > 0 and distancia_a(johnny) < radio + johnny.RADIO + alcance and se_ve(johnny):
		empezar_zarpazo(johnny)
		return
	ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)


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
	pedir_velocidad(paso.normalized() * rapidez)
	mirar_hacia(paso)
	poner_animacion("andar")


# Dormido: se despierta si Johnny entra en su habitación o le ve cerca sin un muro en medio
func vigilar(johnny: Node2D) -> void:
	if johnny == null or not johnny.vivo:
		return
	var mapa := get_tree().get_first_node_in_group("mapa")
	if (mapa and zona >= 0 and mapa.zona_en(johnny.global_position) == zona) 			or (distancia_a(johnny) < VISTA and se_ve(johnny)):
		despertar()


# Suelta un "!" y, al rato, echa a andar. Arrastra a los que tiene al lado.
func despertar() -> void:
	if not dormido:
		return
	dormido = false
	espabilando = ESPABILAR
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-4, -altura), "!", Color("ffd23f"), 26)
	for otro in get_tree().get_nodes_in_group("zombis"):
		if otro != self and otro.get("dormido") and distancia_a(otro) < CORRILLO:
			otro.despertar()


# Los disparos se oyen (las armas de cuerpo a cuerpo son silenciosas): lo llama Johnny al disparar
func oir_disparo(donde: Vector2) -> void:
	if dormido and global_position.distance_to(donde) < OIDO:
		despertar()


func distancia_a(nodo: Node2D) -> float:
	return global_position.distance_to(nodo.global_position)


# Un "rayo" del zombi a Johnny: si choca con una pared o un mueble (capa 1), no le ve
func se_ve(nodo: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, nodo.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Con el "avoidance" encendido no se mueve directamente: se le pasa al agente la velocidad que queremos,
# y él la corrige (si hay otro zombi delante, la tuerce un poco) y nos la devuelve en _al_calcular_velocidad
func pedir_velocidad(v: Vector2) -> void:
	agente.velocity = v


func _al_calcular_velocidad(segura: Vector2) -> void:
	if estado == "golpe" or estado == "muerto":
		return
	velocity = segura
	move_and_slide()


func empezar_zarpazo(johnny: Node2D) -> void:
	estado = "zarpazo"
	zarpazo_dado = false
	mirar_hacia(johnny.global_position - global_position)
	poner_animacion("ataque")


# Lo llaman las armas de Johnny (golpes y balas) y las explosiones. "fuerza" es hacia dónde y con qué
# fuerza sale despedido (la de un zombi normal: cada tipo la multiplica por su "empuje")
func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	if estado == "muerto":
		return
	if dormido:
		despertar()
		espabilando = 0.0   # con un golpe no hay tiempo de pensárselo
	vida -= cantidad
	velocity = fuerza * empuje
	numero_flotante(cantidad)
	# Se gira hacia quien le ha pegado (al revés del empuje)
	mirar_hacia(-fuerza)
	if vida <= 0:
		morir()
	else:
		encogerse()


func encogerse() -> void:
	estado = "golpe"
	poner_animacion("golpe", true)


func morir() -> void:
	estado = "muerto"
	if sprite.sprite_frames.has_animation("muerte_" + direccion):
		poner_animacion("muerte")
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
	murio.emit()


func numero_flotante(cantidad: int) -> void:
	Zombi.texto_flotante(get_parent(), global_position + Vector2(randf_range(-14, 2), -altura), str(cantidad))


# Un texto que sube y se desvanece (los números de daño, los gritos de la portera...). Va en la sala, no
# en quien lo dice, para que no se mueva con él ni desaparezca si se muere. "static": se puede usar desde
# cualquier sitio sin tener un zombi, escribiendo Zombi.texto_flotante(...)
static func texto_flotante(sala: Node, donde: Vector2, texto: String, color := Color.WHITE, tamano := 18) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 6)
	etiqueta.add_theme_color_override("font_outline_color", Color(0.11, 0.1, 0.17))
	etiqueta.z_index = 10
	sala.add_child(etiqueta)
	etiqueta.global_position = donde
	var tween := etiqueta.create_tween()
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 30.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(etiqueta, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tween.tween_callback(etiqueta.queue_free)


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
