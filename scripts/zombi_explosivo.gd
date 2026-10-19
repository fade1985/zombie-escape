# El zombi explosivo (el hombretón de la gabardina): no da zarpazos. Cuando llega cerca de Johnny se planta,
# abre la gabardina (enseña la dinamita), parpadea en rojo con un círculo de aviso en el suelo y revienta.
# Si lo matas antes, revienta igual. Números de src/zombies.js (EXPLOSION).
extends Zombi

const EXPLOSION := preload("res://escenas/armas/explosion.tscn")
const RADIO_EXPLOSION := 90.0
const DANO_EXPLOSION := 30
const MECHA := 0.8         # segundos desde que abre la gabardina hasta que revienta
const DISPARADOR := 70.0   # a qué distancia de Johnny (además de su radio) enciende la mecha

var mecha := 0.0
var reventado := false


func andar(delta: float, johnny: Node2D) -> void:
	if distancia_a(johnny) < DISPARADOR + johnny.RADIO and se_ve(johnny):
		# ¡Se enciende la mecha! Abre la gabardina y se queda así (la animación no se repite: acaba abierta)
		estado = "mecha"
		mecha = MECHA
		mirar_hacia(johnny.global_position - global_position)
		poner_animacion("ataque")
		return
	ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)


func estado_propio(delta: float, _johnny: Node2D) -> void:
	if estado != "mecha":
		return
	pedir_velocidad(Vector2.ZERO)
	mecha -= delta
	# Parpadea en rojo cada vez más deprisa (en blanco taparía la dinamita) y tiembla
	var k := 1.0 - mecha / MECHA
	var rojo := int(tiempo * (8.0 + k * 16.0)) % 2 == 0
	sprite.modulate = Color(1.0, 0.55, 0.5) if rojo else Color.WHITE
	sprite.position.x = randf_range(-1.5, 1.5)
	queue_redraw()
	if mecha <= 0.0:
		vida = 0
		morir()


# Con la gabardina abierta no se encoge con los golpes: solo pierde vida (y si se muere, revienta)
func encogerse() -> void:
	if estado != "mecha":
		super()


func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	if estado == "mecha":
		fuerza = Vector2.ZERO   # plantado: no le mueven
	super(cantidad, fuerza)


func morir() -> void:
	super()
	sprite.modulate = Color.WHITE
	sprite.position.x = 0.0
	queue_redraw()
	if reventado:
		return
	reventado = true
	# La explosión se añade "en diferido" (al acabar este paso): si revienta a otro explosivo, ese reventará
	# en el paso siguiente, en cadena, sin liarse
	var bum := EXPLOSION.instantiate()
	bum.radio = RADIO_EXPLOSION
	bum.dano = DANO_EXPLOSION
	bum.origen = self
	bum.position = position
	get_parent().add_child.call_deferred(bum)


# El aviso en el suelo: un círculo rojo que se va llenando mientras corre la mecha
func _draw() -> void:
	if estado != "mecha":
		return
	var k := 1.0 - mecha / MECHA
	var centro := Vector2(0, 4)
	draw_circle(centro, RADIO_EXPLOSION, Color(1, 0.31, 0.24, 0.12 + k * 0.25))
	draw_arc(centro, RADIO_EXPLOSION, 0, TAU, 48, Color(1, 0.36, 0.24), 3.0)
