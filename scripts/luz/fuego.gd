# La luz de un fuego: naranja y temblando siempre (brilloFuego de src/luz.js). Preparada para la fase 7: el
# charco de fuego del molotov la lleva con radio = 3 veces el del fuego y se le pone `vida` (se apaga en su
# último segundo); un zombi ardiendo, una pequeña (radio 90, fuerza 0.75) que va con él.
# Sin sombras: un fuego se mueve o dura poco, y las sombras son lo que más cuesta.
extends PointLight2D

@export var radio := 90.0
@export var fuerza := 1.0
@export var vida := INF            # segundos que le quedan (INF: hasta que se quite)

var semilla := randf()
var tiempo := 0.0


func _ready() -> void:
	texture_scale = radio / 128.0


func _process(delta: float) -> void:
	tiempo += delta
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	var b := minf(1.0, vida) * (0.82 + 0.1 * sin(tiempo * 11.0 + semilla * 7.0) + 0.08 * sin(tiempo * 23.7 + semilla * 3.0))
	energy = 0.9 * fuerza * b * Luz.fuerza()
