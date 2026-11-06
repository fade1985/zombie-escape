# Un mueble de la sala de mantenimiento que se usa arrimándose a él (Baul y BancoTrabajo en src/props.js del JS):
# pegado a la pared de arriba, sin su nombre escrito (se reconoce por el dibujo). Delante tiene una zona
# invisible (zona_usar.gd): con Johnny en ella y el clic (atacar), avisa con "usar" y la
# partida abre su pantalla (ui/inventario.gd). Como la mesa del ordenador (ordenador.gd), pero sin luz.
extends StaticBody2D

signal usar

const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")

var zona: Area2D      # la de delante (zona_usar.gd)


# "x": su centro; "arriba": donde acaba el muro de arriba; "ancho" y "hondo": lo que ocupa en el suelo
func montar(nombre: String, dibujo: String, x: float, arriba: float, ancho: float, hondo: float) -> void:
	name = nombre
	add_to_group("obstaculos")
	position = Vector2(x, arriba + hondo)   # el pie, para ordenarse con los personajes
	var sprite := Sprite2D.new()
	sprite.texture = load(dibujo)
	sprite.scale = Vector2(2, 2)
	sprite.centered = false
	var tam := sprite.texture.get_size()
	sprite.offset = Vector2(-floorf(tam.x / 2.0), -tam.y)
	add_child(sprite)

	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho, hondo)
	forma.shape = rect
	forma.position = Vector2(0, -hondo / 2.0)
	add_child(forma)

	# la zona de delante, donde se para Johnny para usarlo: se abre con el clic (zona_usar.gd)
	zona = ZONA_USAR.new()
	zona.montar(ancho)
	add_child(zona)
	zona.usar.connect(usar.emit)
