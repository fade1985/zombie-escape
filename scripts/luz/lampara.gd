# Una luz fija del mapa: un aplique del pasillo, una lámpara de pie o la lamparita de una mesilla (sacada de la
# prueba de concepto). Lleva dos luces iguales (ver luz.gd):
#   - LuzSuelo: alumbra el suelo y hace SOMBRAS
#   - LuzCosas: alumbra personajes, muebles y caras de muro, SIN sombras
# Y una Bombilla: un brillo pequeño que se ve aunque esté todo oscuro.
#
# El nodo va en el pie del mueble (o del muro, en los apliques); `suelo` es dónde está el centro del charco de
# luz y `alto`, a qué altura está la bombilla. Si "parpadea", tiembla y de vez en cuando falla (dos o tres guiños
# o un apagón corto), con la misma cuenta que brilloAplique() en src/luz.js del juego.
# En una habitación aún sin descubrir (niebla) está apagada, y se enciende al entrar.
extends Node2D

@export var parpadea := false
@export var semilla := 0.37        # cambia el momento de los fallos (para que dos lámparas no fallen a la vez)
@export var fuerza := 1.0          # lo fuerte que luce a tope
@export var radio := 210.0         # hasta dónde llega la luz, en unidades
@export var suelo := Vector2(0, -8)
@export var alto := 72.0

var mapa: Node = null              # para mirar la niebla de su habitación
var zona := -1
var tiempo := 0.0

@onready var luz_suelo: PointLight2D = $LuzSuelo
@onready var luz_cosas: PointLight2D = $LuzCosas
@onready var bombilla: Sprite2D = $Bombilla


func _ready() -> void:
	tiempo = semilla * 10.0
	luz_suelo.position = suelo
	luz_cosas.position = Vector2(suelo.x, (suelo.y - alto) / 2.0)   # un poco más arriba: llega a lo alto de los muebles
	luz_suelo.texture_scale = radio / 128.0
	luz_cosas.texture_scale = radio / 128.0
	bombilla.position = Vector2(0, -alto)


func _process(delta: float) -> void:
	tiempo += delta
	var b := brillo(tiempo)
	if mapa and zona >= 0:
		b *= 1.0 - mapa.niebla.get(zona, 0.0)
	var e := fuerza * b * Luz.fuerza()
	luz_suelo.energy = 0.85 * e
	luz_cosas.energy = 0.75 * e
	luz_suelo.enabled = e > 0.02
	luz_cosas.enabled = e > 0.02
	bombilla.modulate.a = b


# Un número "al azar" fijo para cada (a, b): siempre sale el mismo, así el parpadeo no depende de la suerte
func al_azar(a: float, b: float) -> float:
	var s := sin(a * 127.1 + b * 311.7) * 43758.5453
	return s - floorf(s)


# Lo fuerte que luce en el instante t (0 = apagada, 1 = a tope)
func brillo(t: float) -> float:
	if not parpadea:
		return 0.97 + 0.03 * sin(t * 2.0 + semilla * 40.0)
	# casi siempre, un temblor suave...
	var base := 0.88 + 0.07 * sin(t * 6.3 + semilla * 20.0) + 0.05 * sin(t * 15.7 + semilla * 50.0)
	# ...y de vez en cuando falla: el tiempo se parte en tramos de 3,5 s y en algunos hay un fallo
	var tramo := floorf(t / 3.5 + semilla * 7.0)
	var dentro := (t / 3.5 + semilla * 7.0 - tramo) * 3.5
	var suerte := al_azar(tramo, semilla * 100.0)
	if suerte < 0.45:
		return base                                    # este tramo, sin fallo
	var dt := dentro - al_azar(tramo + 0.5, semilla) * 2.4   # tiempo desde que empieza el fallo
	if suerte > 0.85:
		# apagón: se va medio segundo y vuelve con un par de chispazos
		if dt >= 0.0 and dt < 0.5:
			return 0.05
		if dt >= 0.5 and dt < 0.75:
			return base if int(dt * 20.0) % 2 else 0.2
		return base
	# cortes rápidos: dos o tres guiños
	if dt >= 0.0 and dt < 0.3:
		return base if int(dt * 22.0) % 2 else 0.25
	return base
