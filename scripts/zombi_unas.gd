# El de las uñas (23 nov): un vecino alto y flaquísimo, estirado como un palo, con las uñas de los dedos largas como
# huesos. Las dispara. Sale en todos los edificios desde el nivel 3 (planta.gd, horda) y en el garaje (garaje.gd, tipos).
# Copiado del oficinista (zombi_oficinista.gd):
#   - Guarda las distancias: si Johnny se acerca, se aparta; si se va, le sigue; en medio, se planta.
#   - Cada ESPERA segundos (más o menos), si le ve y hay paso libre, se planta, echa el brazo atrás y lo lanza: suelta
#     TIROS uñas en abanico (bala_zombi.gd, forma "una"), que van rectas, se esquivan y se paran en las paredes.
#   - No tiene zarpazo (su hoja no tiene ese golpe): si lo acorralas, te dispara a quemarropa.
# Las uñas salen en el "hit" de su hoja (momento_zarpazo, 0,375: el brazo ya está estirado).
# Números provisionales: se ajustan jugando.
extends Zombi

const BALA := preload("res://escenas/armas/bala_zombi.tscn")
const CERCA := 170.0          # más cerca que esto, se aparta de Johnny
const LEJOS := 300.0          # más lejos que esto, se acerca
const ALCANCE_TIRO := 400.0   # hasta dónde dispara
const ESPERA := 2.5           # entre tiro y tiro (y un pellizco al azar, hasta ESPERA + 0,5)
const TIROS := 3              # uñas por tiro
const ABANICO := 12.0         # grados entre una uña y la de al lado
const DANO_TIRO := 6          # lo que quita cada uña
const VELOCIDAD_TIRO := 300.0 # algo más rápidas que la taza del oficinista (260), pero se esquivan
const ALTO_MANO := 40.0       # a qué altura vuelan las uñas (las demás balas, a 22: él es muy alto)
const QUEMARROPA := 70.0      # más cerca que esto (acorralado), dispara aunque no le toque

var espera := 0.0
var tirado := false           # si ya ha soltado las uñas de este disparo


func _ready() -> void:
	super()
	momento_zarpazo = 0.375   # el "hit" de su hoja (assets/sprites/zombi-unas.json)
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
	# acorralado: dispara a quemarropa en cuanto puede (sin esperar a que le toque)
	var acorralado: bool = distancia < radio + johnny.RADIO + QUEMARROPA
	if ve and (espera <= 0.0 or (acorralado and espera <= ESPERA * 0.6)) and distancia < ALCANCE_TIRO and despejado(johnny):
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
		espera = randf_range(ESPERA, ESPERA + 0.5) / ritmo   # (con la mejora del VD-7, menos)
		if johnny:
			disparar(johnny)
	# se queda plantado hasta acabar el disparo
	if tirado and not sprite.is_playing():
		estado = "andar"


# Tres uñas en abanico: la del medio, un poco hacia donde va Johnny; las otras dos, ABANICO grados a cada lado
func disparar(johnny: Node2D) -> void:
	var destino: Vector2 = johnny.global_position + johnny.velocity * 0.2
	var dir := global_position.direction_to(destino)
	for i in TIROS:
		var d := dir.rotated(deg_to_rad(ABANICO * (i - (TIROS - 1) / 2.0)))
		var bala := BALA.instantiate()
		bala.dueno = self
		bala.position = position + d * (radio + 6.0)
		bala.velocidad = d * VELOCIDAD_TIRO
		bala.dano = DANO_TIRO
		bala.radio = 6.0
		bala.forma = "una"
		bala.alto = ALTO_MANO
		get_parent().add_child(bala)
	Sonido.tocar("lanzar")


# ¿Hay paso libre hasta Johnny? (las paredes y los muebles paran las uñas: si no, ni lo intenta)
func despejado(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()
