# El guardia de seguridad del centro comercial: lleva la tarjeta de acceso a la tienda del jefe y ronda por el
# pasillo de la planta. Hay que cazarlo, y no se deja:
#   - Mientras no te ha visto, hace su ronda despacio, de una punta del pasillo a la otra.
#   - Cuando te ve, toca el silbato (los refuerzos los saca la partida: señal "silbato") y huye hacia la punta
#     del pasillo que le queda más lejos de Johnny.
#   - Correr le cansa: cada poco se para a recuperar el aliento. Ese es el momento de pillarle.
#   - Si le acorralas (o le alcanzas mientras descansa), se defiende a zarpazos.
#   - A media vida, vuelve a tocar el silbato.
# Lleva el dibujo del vigilante (zombi_vigilante.tscn), el mismo que los refuerzos que llegan al silbato.
extends Zombi

signal silbato   # ha tocado el silbato: la partida trae refuerzos

const RONDA := 55.0          # su velocidad haciendo la ronda
const HUIDA := 165.0         # y huyendo (Johnny anda a 210: se le alcanza, pero cuesta)
const ALIENTO := 3.2         # segundos que aguanta corriendo...
const RESPIRO := 1.8         # ...y lo que tarda en recuperarse
const DEFENDERSE := 70.0     # más cerca que esto (además de los radios), se gira y pega

var alerta := false          # si ya ha visto a Johnny (entonces ya no hace la ronda)
var silbidos := 0            # cuántas veces ha tocado el silbato (dos como mucho: al verte y a media vida)
var aliento := ALIENTO
var cansado := 0.0           # tiempo que le queda parado recuperándose
var meta := Vector2.INF      # adónde va (en la ronda, una punta; huyendo, la punta lejos de Johnny)
var puntas: Array = []       # los dos extremos del pasillo, los pone la partida


func andar(delta: float, johnny: Node2D) -> void:
	if not alerta:
		if distancia_a(johnny) < VISTA and se_ve(johnny):
			alerta = true
			tocar_silbato()
		else:
			rondar(delta)
			return
	if silbidos < 2 and vida <= vida_max / 2:
		tocar_silbato()
	var cerca: bool = distancia_a(johnny) < radio + johnny.RADIO + DEFENDERSE
	# Cansado: se queda quieto resoplando, salvo que le tengas encima
	if cansado > 0.0:
		cansado -= delta
		if cerca and se_ve(johnny):
			empezar_zarpazo(johnny)
			return
		pedir_velocidad(Vector2.ZERO)
		mirar_hacia(johnny.global_position - global_position)
		poner_animacion("reposo")
		if cansado <= 0.0:
			aliento = ALIENTO
		return
	# Acorralado en una punta del pasillo: pega
	if cerca and se_ve(johnny) and puntas.any(func(p): return global_position.distance_to(p) < 130.0):
		empezar_zarpazo(johnny)
		return
	aliento -= delta
	if aliento <= 0.0:
		cansado = RESPIRO
		Zombi.texto_flotante(get_parent(), global_position + Vector2(-10, -altura), "uf", Color("#9fc4ff"), 18)
		return
	ir_hacia(delta, camino_hacia(huida(johnny)), HUIDA)


# La ronda: de una punta a la otra, despacio
func rondar(delta: float) -> void:
	if puntas.size() < 2:
		pedir_velocidad(Vector2.ZERO)
		poner_animacion("reposo")
		return
	if meta == Vector2.INF or global_position.distance_to(meta) < 40.0:
		meta = puntas[0] if meta != puntas[0] else puntas[1]
	ir_hacia(delta, camino_hacia(meta), RONDA)


# Adónde huir: la punta del pasillo más lejos de Johnny (si está en medio, la que tiene detrás)
func huida(johnny: Node2D) -> Vector2:
	if puntas.size() < 2:
		return global_position + johnny.global_position.direction_to(global_position) * 200.0
	var a: Vector2 = puntas[0]
	var b: Vector2 = puntas[1]
	return a if johnny.global_position.distance_to(a) > johnny.global_position.distance_to(b) else b


func tocar_silbato() -> void:
	silbidos += 1
	Sonido.tocar("silbato")
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-34, -altura), "¡PRIIII!", Color("#ffd23f"), 22)
	silbato.emit()


# Al recibir un golpe, se le pasa el cansancio del susto (y sale corriendo otra vez)
func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	super(cantidad, fuerza)
	alerta = true
	if cansado > 0.0 and randf() < 0.5:
		cansado = 0.0
		aliento = ALIENTO * 0.6
