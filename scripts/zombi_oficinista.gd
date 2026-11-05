# El oficinista de Torre Velaria (parte 4 del plan, docs/PLAN_TERCER_EDIFICIO.md, «Los zombis nuevos»): camisa blanca,
# corbata torcida, acreditación y cascos de teleoperador. Es el primer zombi de a pie que ataca de lejos:
#   - Guarda las distancias, como la dependienta: si Johnny se acerca, se aparta; si se va, le sigue; en medio, se planta.
#   - Cada ESPERA segundos, si le ve, le tira una grapadora o una taza (bala_zombi.gd: va recta y despacio, DANO_TIRO).
#   - Si lo acorralas, te da un manotazo flojo (el "dano" de su escena).
# El tiro usa la animación de ataque (el lanzamiento), y llega en su "hit" (momento_zarpazo, de su hoja).
# Números provisionales: se ajustan jugando.
extends Zombi

const BALA := preload("res://escenas/armas/bala_zombi.tscn")
const CERCA := 170.0          # más cerca que esto, se aparta de Johnny
const LEJOS := 300.0          # más lejos que esto, se acerca
const ALCANCE_TIRO := 380.0   # hasta dónde tira
const ESPERA := 2.5           # entre tiro y tiro
const DANO_TIRO := 8
const VELOCIDAD_TIRO := 260.0 # despacio (los alfileres de la modista van a 480; Johnny anda a 210): se puede esquivar
const MANO := 46.0            # a qué altura le sale de la mano

var espera := 0.0
var tirado := false           # si ya ha soltado lo de este lanzamiento


func _ready() -> void:
	super()
	espera = randf_range(0.8, 1.8)


func _physics_process(delta: float) -> void:
	espera -= delta
	super(delta)


func andar(delta: float, johnny: Node2D) -> void:
	if diana:
		quedarse(delta, johnny)
		return
	var hacia: Vector2 = global_position.direction_to(johnny.global_position)
	var distancia := distancia_a(johnny)
	var ve := se_ve(johnny) and not en_puerta()
	# acorralado: manotazo
	if distancia < radio + johnny.RADIO + alcance and ve:
		empezar_zarpazo(johnny)
		return
	if ve and espera <= 0.0 and distancia < ALCANCE_TIRO and despejado(johnny):
		estado = "tirar"
		tirado = false
		mirar_hacia(hacia)
		poner_animacion("ataque", true)
		return
	if not ve or distancia > LEJOS:
		ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)
	elif distancia < CERCA:
		# se aparta usando el mapa de navegación: con una pared detrás, se escapa por un lado
		ir_hacia(delta, camino_hacia(global_position - hacia * 140.0), velocidad)
	else:
		pedir_velocidad(Vector2.ZERO)
		poner_animacion("reposo")
	mirar_hacia(hacia)


func estado_propio(_delta: float, johnny: Node2D) -> void:
	if estado != "tirar":
		return
	pedir_velocidad(Vector2.ZERO)
	if not tirado and avance_animacion() >= momento_zarpazo:
		tirado = true
		espera = ESPERA
		if johnny:
			tirar(johnny)
	# se queda plantado hasta acabar el lanzamiento
	if tirado and not sprite.is_playing():
		estado = "andar"


# Una grapadora o una taza: una bala de los malos que va recta (bala_zombi.gd), un poco hacia donde va Johnny
func tirar(johnny: Node2D) -> void:
	var destino: Vector2 = johnny.global_position + johnny.velocity * 0.25
	var dir := global_position.direction_to(destino)
	var bala := BALA.instantiate()
	bala.dueno = self
	bala.position = position + dir * (radio + 6.0)
	bala.velocidad = dir * VELOCIDAD_TIRO
	bala.dano = DANO_TIRO
	bala.radio = 7.0
	bala.forma = "taza" if randf() < 0.5 else "grapadora"
	get_parent().add_child(bala)
	Sonido.tocar("lanzar")


# ¿Hay paso libre hasta Johnny? (las paredes y los muebles paran lo que tira: si no, ni lo intenta)
func despejado(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()
