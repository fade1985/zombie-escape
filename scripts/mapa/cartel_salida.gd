# El cartel EXIT de la salida de incendios, en la pared de arriba del pasillo, al final (lo pone mapa.gd; la puerta de las
# escaleras, puerta.gd, le dice si ya se pueden usar: al caer el jefe de la planta). Sus dibujos, de
# tools/puerta_salida.py.
#   Apagado: una caja de chapa con el panel verde oscuro, sin luz. La penumbra se lo come como a todo lo demás.
#   Encendido: el panel verde vivo con las letras blancas, que no le afecta la penumbra (como los neones, neon.gd), con su
#   halo y una luz verde de verdad (lampara.gd, sin bombilla ni polvo) que alumbra un poco la pared y el suelo.
# Al encenderse (Johnny acaba de tumbar al jefe) arranca a trompicones, como un fluorescente viejo, y se queda fijo. Si al
# montar el pasillo ya estaba pasado (Johnny vuelve a una planta que ya limpió), nace encendido, sin parpadeo.
extends Node2D

const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const APAGADO := preload("res://assets/sprites/cartel-salida-apagado.png")
const ENCENDIDO := preload("res://assets/sprites/cartel-salida-encendido.png")
const TAMANO := Vector2(72, 26)   # 36 × 13 píxeles
const ALTO := 74.0                # a qué altura va el centro del cartel, por encima del pie del muro
const VERDE := Color("#3bd84a")
const FUERZA := 0.7               # lo fuerte que alumbra (la de una lámpara, 1, es más)
const RADIO := 170.0
# El arranque: [desde, hasta) los segundos en que luce (lo demás, apagado); pasado el último, ya queda fijo
const ARRANQUE := [[0.0, 0.1], [0.28, 0.4], [0.72, 0.82], [1.0, 1.08]]
const FIN_ARRANQUE := 1.3

var encendido := false          # si se puede pasar (lo dice la puerta)
var arrancando := -1.0          # los segundos desde que empezó a encenderse (-1: no está arrancando)
var vida := 0.0                 # los segundos que lleva en el mapa
var luz: Node2D
var propio: CanvasItemMaterial


func _ready() -> void:
	# lo que no se ilumina con la penumbra, mientras luce: el cartel encendido brilla por sí mismo
	propio = CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	# su luz verde en la pared y el suelo (una lámpara sin bombilla ni polvo)
	luz = LAMPARA.instantiate()
	luz.radio = RADIO
	luz.alto = ALTO
	luz.suelo = Vector2(0, 46)
	luz.fuerza = 0.0
	add_child(luz)
	luz.get_node("Bombilla").visible = false
	luz.get_node("Polvo").visible = false
	for nombre in ["LuzSuelo", "LuzCosas"]:
		luz.get_node(nombre).color = VERDE
	repasar()


# La puerta de las escaleras avisa de cada cambio (también la primera vez, nada más montar el pasillo)
func encender(valor: bool) -> void:
	if valor == encendido:
		return
	encendido = valor
	arrancando = 0.0 if valor and vida > 0.3 else -1.0   # (al montar el pasillo no hay parpadeo)
	repasar()


# Si luce en este instante: encendido y, mientras arranca, solo en sus tramos
func luce() -> bool:
	if not encendido:
		return false
	if arrancando < 0.0:
		return true
	for tramo in ARRANQUE:
		if arrancando >= tramo[0] and arrancando < tramo[1]:
			return true
	return false


func repasar() -> void:
	var enciende := luce()
	material = propio if enciende else null
	if luz:
		luz.fuerza = FUERZA if enciende else 0.0
	queue_redraw()


func _process(delta: float) -> void:
	vida += delta
	if arrancando >= 0.0:
		arrancando += delta
		if arrancando >= FIN_ARRANQUE:
			arrancando = -1.0   # ya queda fijo
		repasar()


func _draw() -> void:
	var rect := Rect2(Vector2(-TAMANO.x / 2.0, -ALTO - TAMANO.y / 2.0), TAMANO)
	if luce():
		# el halo: dos cajas de verde transparente por detrás, cada vez más anchas
		for margen in [10.0, 5.0]:
			draw_rect(rect.grow(margen), Color(VERDE.r, VERDE.g, VERDE.b, 0.09 if margen > 6.0 else 0.13))
		draw_texture_rect(ENCENDIDO, rect, false)
	else:
		draw_texture_rect(APAGADO, rect, false)
