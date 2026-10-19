# Un zombi normal: persigue a Johnny esquivando paredes y muebles, le da zarpazos al llegar, y se encoge
# o se muere cuando le pegan o le disparan. Los números son los del juego de navegador (src/zombies.js).
# Viene de la prueba de Godot (zombie-godot-poc), con dos cosas nuevas: sale con una ropa al azar y enseña
# un número con el daño que recibe.
extends CharacterBody2D

signal murio   # avisa cuando se muere (la sala cuenta los muertos para sacar más)

const VELOCIDAD := 80.0    # unidades por segundo
const VIDA_MAX := 30
const DANO := 10           # lo que quita cada zarpazo
const RADIO := 16.0        # su círculo de choque
const ALCANCE := 18.0      # a qué distancia de Johnny (además de los dos radios) lanza el zarpazo
const MOMENTO_ZARPAZO := 0.429   # en qué punto de la animación de ataque llega la mano (lo pone su hoja)
const FRENADA := 900.0     # lo rápido que se para después de que le empujen de un golpe

# Las ropas: la de siempre y las 6 variantes del juego (tools/variantes.py del juego JS). Cada uno sale con una
const ROPAS := [
	preload("res://assets/sprites/zombi-normal.tres"),
	preload("res://assets/sprites/zombi-normal-rojo.tres"),
	preload("res://assets/sprites/zombi-normal-bata.tres"),
	preload("res://assets/sprites/zombi-normal-mostaza.tres"),
	preload("res://assets/sprites/zombi-normal-negro.tres"),
	preload("res://assets/sprites/zombi-normal-militar.tres"),
	preload("res://assets/sprites/zombi-normal-turquesa.tres"),
]

const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]

var vida := VIDA_MAX
var estado := "andar"      # "andar", "zarpazo", "golpe" o "muerto"
var direccion := "s"
var tiempo := 0.0          # para el bamboleo al andar
var zarpazo_dado := false  # si ya ha dado el golpe en este zarpazo (solo uno por animación)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var agente: NavigationAgent2D = $Agente


func _ready() -> void:
	sprite.sprite_frames = ROPAS.pick_random()
	sprite.play("reposo_s")
	# Cada uno empieza su bamboleo en un punto distinto, para que no anden todos al compás
	tiempo = randf() * 10.0
	agente.max_speed = VELOCIDAD
	# El agente nos devuelve aquí la velocidad ya corregida para no chocar con otros zombis
	agente.velocity_computed.connect(_al_calcular_velocidad)
	sprite.animation_finished.connect(_al_acabar_animacion)


func _physics_process(delta: float) -> void:
	if estado == "muerto":
		return
	tiempo += delta
	var johnny := get_tree().get_first_node_in_group("jugador")

	match estado:
		"andar":
			if johnny == null or not johnny.vivo:
				pedir_velocidad(Vector2.ZERO)
				poner_animacion("reposo")
				return
			var distancia: float = global_position.distance_to(johnny.global_position)
			if distancia < RADIO + johnny.RADIO + ALCANCE:
				empezar_zarpazo(johnny)
				return
			# Le decimos al agente adónde queremos ir, y él nos da el siguiente punto del camino
			# (el camino rodea paredes y muebles: lo saca de la región de navegación de la sala)
			agente.target_position = johnny.global_position
			var hacia := global_position.direction_to(agente.get_next_path_position())
			# Un poco de bamboleo de lado a lado, como en el juego
			hacia += hacia.orthogonal() * sin(tiempo * 2.3) * 0.2
			pedir_velocidad(hacia.normalized() * VELOCIDAD)
			mirar_hacia(hacia)
			poner_animacion("andar")

		"zarpazo":
			pedir_velocidad(Vector2.ZERO)
			# Cuando la mano llega abajo, si Johnny sigue a tiro, le da
			var hecho := sprite.frame_progress + sprite.frame
			var total := sprite.sprite_frames.get_frame_count(sprite.animation)
			if not zarpazo_dado and hecho / total >= MOMENTO_ZARPAZO:
				zarpazo_dado = true
				if johnny and global_position.distance_to(johnny.global_position) < RADIO + johnny.RADIO + ALCANCE + 10.0:
					johnny.recibir_dano(DANO)

		"golpe":
			# Sale despedido hacia atrás y va frenando; aquí no se usa el agente, se mueve él solo
			velocity = velocity.move_toward(Vector2.ZERO, FRENADA * delta)
			move_and_slide()


# Con el "avoidance" encendido no se mueve directamente: se le pasa al agente la velocidad que queremos,
# y él la corrige (si hay otro zombi delante, la tuerce un poco) y nos la devuelve en _al_calcular_velocidad
func pedir_velocidad(v: Vector2) -> void:
	agente.velocity = v


func _al_calcular_velocidad(segura: Vector2) -> void:
	if estado != "andar" and estado != "zarpazo":
		return
	velocity = segura
	move_and_slide()


func empezar_zarpazo(johnny: Node2D) -> void:
	estado = "zarpazo"
	zarpazo_dado = false
	mirar_hacia(johnny.global_position - global_position)
	poner_animacion("ataque")


# Lo llaman las armas de Johnny (golpes y balas). "empuje" es hacia dónde y con qué fuerza sale despedido
func recibir_golpe(cantidad: int, empuje: Vector2) -> void:
	if estado == "muerto":
		return
	vida -= cantidad
	velocity = empuje
	numero_flotante(cantidad)
	# Se gira hacia quien le ha pegado (al revés del empuje)
	mirar_hacia(-empuje)
	if vida <= 0:
		morir()
	else:
		estado = "golpe"
		poner_animacion("golpe", true)


func morir() -> void:
	estado = "muerto"
	poner_animacion("muerte")
	remove_from_group("zombis")
	# El cuerpo ya no choca ni se aparta de nadie: se queda en el suelo
	$Choque.set_deferred("disabled", true)
	agente.avoidance_enabled = false
	murio.emit()


# El daño, en un número que sube y se desvanece encima de la cabeza (como en el juego)
func numero_flotante(cantidad: int) -> void:
	var numero := Label.new()
	numero.text = str(cantidad)
	numero.add_theme_font_size_override("font_size", 18)
	numero.add_theme_constant_override("outline_size", 6)
	numero.add_theme_color_override("font_outline_color", Color(0.11, 0.1, 0.17))
	numero.z_index = 10
	# Va en la sala, no en el zombi, para que no se mueva con él ni desaparezca si se muere
	get_parent().add_child(numero)
	numero.global_position = global_position + Vector2(randf_range(-14, 2), -86)
	var tween := numero.create_tween()
	tween.tween_property(numero, "position:y", numero.position.y - 30.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(numero, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tween.tween_callback(numero.queue_free)


func _al_acabar_animacion() -> void:
	# Al acabar el zarpazo o el encogerse, vuelve a perseguir (la muerte se queda en el último fotograma)
	if estado == "zarpazo" or estado == "golpe":
		estado = "andar"


# Elige una de las 8 direcciones según un vector (como en johnny.gd)
func mirar_hacia(v: Vector2) -> void:
	if v.length() > 0.01:
		direccion = DIRS[wrapi(roundi(v.angle() / (PI / 4)), 0, 8)]


# Pone "andar_se", "ataque_n"... Si solo cambia la dirección, sigue por el mismo fotograma.
# "otra_vez" la vuelve a empezar aunque ya estuviera puesta (dos golpes seguidos)
func poner_animacion(estado_anim: String, otra_vez := false) -> void:
	var nombre := estado_anim + "_" + direccion
	if sprite.animation == nombre and not otra_vez:
		return
	var mismo_estado := sprite.animation.get_slice("_", 0) == estado_anim
	var fotograma := sprite.frame
	var avance := sprite.frame_progress
	sprite.play(nombre)
	if otra_vez:
		sprite.frame = 0
	elif mismo_estado:
		# Las direcciones no tienen todas los mismos fotogramas: si nos pasamos, volvemos a empezar
		sprite.set_frame_and_progress(fotograma % sprite.sprite_frames.get_frame_count(nombre), avance)
