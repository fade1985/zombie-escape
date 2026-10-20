# El zombi venenoso (el gordo): no da zarpazos. Guarda las distancias (si Johnny se acerca, se aleja; si se
# va, le sigue; en medio, le rodea) y cada poco se planta y le escupe un moco en parábola que deja un charco
# verde. Números de src/zombies.js (POISON y spit).
extends Zombi

const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const CERCA := 220.0        # más cerca que esto, se aleja
const LEJOS := 310.0        # más lejos que esto, se acerca
const ALCANCE_ESCUPIR := 430.0
const ESPERA := 2.6         # entre escupitajo y escupitajo
const PREPARAR := 0.4       # el moco sale de la boca a los 0,4 s de empezar la animación
const BOCA := 88.0          # a qué altura tiene la boca

var espera := 0.0
var lado := 1.0             # hacia qué lado rodea a Johnny
var t_escupir := 0.0
var escupido := false


func _ready() -> void:
	super()
	espera = randf_range(1.0, 2.2)
	lado = 1.0 if randf() < 0.5 else -1.0


func _physics_process(delta: float) -> void:
	espera -= delta
	super(delta)


func andar(delta: float, johnny: Node2D) -> void:
	var hacia: Vector2 = global_position.direction_to(johnny.global_position)
	var distancia := distancia_a(johnny)
	var ve := se_ve(johnny)
	if ve and espera <= 0.0 and distancia < ALCANCE_ESCUPIR:
		# Se planta, se echa atrás y escupe
		estado = "escupir"
		t_escupir = 0.0
		escupido = false
		mirar_hacia(hacia)
		poner_animacion("ataque")
		return
	var rumbo_deseado: Vector2
	if not ve or distancia > LEJOS:
		rumbo_deseado = camino_hacia(johnny.global_position)
	elif distancia < CERCA:
		# Se aleja usando el mapa de navegación: así, si tiene una pared detrás, se escapa por un lado
		rumbo_deseado = camino_hacia(global_position - hacia * 120.0)
	else:
		rumbo_deseado = hacia.orthogonal() * lado
	ir_hacia(delta, rumbo_deseado, velocidad)
	# Anda hacia donde le toque, pero siempre mirando a Johnny
	mirar_hacia(hacia)
	poner_animacion("andar")


func estado_propio(delta: float, johnny: Node2D) -> void:
	if estado != "escupir":
		return
	pedir_velocidad(Vector2.ZERO)
	t_escupir += delta
	if not escupido and t_escupir >= PREPARAR:
		escupido = true
		espera = ESPERA
		if johnny:
			var moco := PROYECTIL.instantiate()
			moco.tipo = "veneno"
			var delante := Vector2.from_angle(DIRS.find(direccion) * PI / 4) * 26.0
			moco.desde = global_position + delante
			moco.alto_salida = BOCA
			moco.hasta = johnny.global_position
			get_parent().add_child(moco)
			Sonido.tocar("escupitajo")
	# Se queda plantado hasta acabar la animación (si se moviera sin mover las piernas, parecería que flota)
	if escupido and not sprite.is_playing():
		estado = "andar"
