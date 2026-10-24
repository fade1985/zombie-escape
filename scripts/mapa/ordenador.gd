# La mesa del ordenador de la sala de mantenimiento (Ordenador en src/props.js del JS): pegada a la pared de
# arriba, con el monitor que brilla un poco para que se vea que se puede usar. Delante tiene una zona
# invisible: cuando Johnny se arrima, avisa con "usar" y la partida enciende la pantalla de ConserjeOS
# (ui/ordenador.gd). Al cerrarla hay que apartarse un poco antes de que se vuelva a abrir. El dibujo sale de
# PixelLab, al estilo de los muebles, como el banco y el baúl (tools/ordenador_mantenimiento.py).
extends StaticBody2D

signal usar

const ANCHO := 92.0   # lo que ocupa en el suelo: de la pared a las patas de delante (como en el JS)
const HONDO := 44.0

var lista := true     # se pone a false al abrirse, y vuelve a true cuando Johnny se aparta
var brillo: PointLight2D
var t := 0.0


# "x": su centro; "arriba": donde acaba el muro de arriba
func montar(x: float, arriba: float) -> void:
	name = "Ordenador"
	add_to_group("obstaculos")
	position = Vector2(x, arriba + HONDO)   # el pie de la mesa, para ordenarse con los personajes
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/mesa-ordenador.png")
	sprite.scale = Vector2(2, 2)
	sprite.centered = false
	var tam := sprite.texture.get_size()
	sprite.offset = Vector2(-floorf(tam.x / 2.0), -tam.y)
	add_child(sprite)

	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ANCHO, HONDO)
	forma.shape = rect
	forma.position = Vector2(0, -HONDO / 2.0)
	add_child(forma)

	# el resplandor azulado del monitor, sobre la pantalla
	brillo = PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.35
	brillo.color = Color("#78dcff")
	brillo.position = Vector2(-2, -76)
	add_child(brillo)

	# la zona de delante, donde se para Johnny para usarlo
	var zona := Area2D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(ANCHO + 20, 40)
	hueco.shape = r
	hueco.position = Vector2(0, 18)
	zona.add_child(hueco)
	add_child(zona)
	zona.body_entered.connect(func(_cuerpo):
		if lista:
			lista = false
			usar.emit())
	zona.body_exited.connect(func(_cuerpo): lista = true)


func _process(delta: float) -> void:
	t += delta
	brillo.energy = 0.7 + sin(t * 2.5) * 0.2
