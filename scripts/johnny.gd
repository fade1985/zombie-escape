# Johnny, el conserje: se mueve con WASD, las flechas o el stick izquierdo del mando, y pone la animación
# de andar o de reposo mirando hacia una de las 8 direcciones.
# (Los fregonazos, la vida y la luz que lleva encima vendrán en las fases de combate y de luz.)
extends CharacterBody2D

const VELOCIDAD := 210.0   # unidades por segundo, la misma que en el juego de navegador
const ARRANQUE := 14.0     # lo rápido que llega a su velocidad (y frena): igual que en el juego
const PASO := 140.0        # unidades que avanza en un ciclo de andar, como en el juego

# Nombre corto de cada dirección, empezando por el este y girando hacia abajo (sentido de las agujas
# del reloj, porque en pantalla la Y crece hacia abajo)
const DIRS := ["e", "se", "s", "so", "o", "no", "n", "ne"]

var direccion := "s"   # hacia dónde mira

@onready var sprite: AnimatedSprite2D = $Sprite


func _physics_process(delta: float) -> void:
	# Lo que pide el jugador: un vector de largo 0 a 1 (el stick a medias da menos de 1)
	var pedido := Input.get_vector("izquierda", "derecha", "arriba", "abajo")

	# Acelera suave hacia la velocidad deseada, como en el juego
	var k := 1.0 - exp(-delta * ARRANQUE)
	velocity += (pedido * VELOCIDAD - velocity) * k

	# move_and_slide mueve el cuerpo y, si choca con una pared, lo hace resbalar a lo largo de ella
	move_and_slide()

	if pedido.length() > 0.1:
		# angle() da el ángulo en radianes; lo pasamos a uno de los 8 trozos de 45°
		var trozo := wrapi(roundi(pedido.angle() / (PI / 4)), 0, 8)
		direccion = DIRS[trozo]

	var rapidez := velocity.length()
	if rapidez > 20.0:
		cambiar_animacion("andar_" + direccion)
		# El paso va según lo que avanza de verdad: más despacio al arrancar y al frenar.
		# Cada dirección tiene su número de fotogramas; la hoja los pone a su velocidad (12 por segundo)
		var fotogramas := sprite.sprite_frames.get_frame_count(sprite.animation)
		var fps := sprite.sprite_frames.get_animation_speed(sprite.animation)
		sprite.speed_scale = (rapidez / PASO * fotogramas) / fps
	else:
		cambiar_animacion("reposo_" + direccion)
		sprite.speed_scale = 1.0


# Pone una animación. Si solo cambia la dirección (andar_s → andar_se), sigue por el mismo
# fotograma, para que al girar no se le junten los pies de golpe
func cambiar_animacion(nombre: String) -> void:
	if sprite.animation == nombre:
		return
	var mismo_estado := sprite.animation.get_slice("_", 0) == nombre.get_slice("_", 0)
	var fotograma := sprite.frame
	var avance := sprite.frame_progress
	sprite.play(nombre)
	if mismo_estado:
		# Las direcciones no tienen todas los mismos fotogramas: si nos pasamos, volvemos a empezar
		sprite.set_frame_and_progress(fotograma % sprite.sprite_frames.get_frame_count(nombre), avance)
