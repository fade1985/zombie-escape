# Un mueble de la sala de mantenimiento que se usa al arrimarse (Baul y BancoTrabajo en src/props.js del JS):
# pegado a la pared de arriba, con su letrero debajo. Delante tiene una zona invisible: cuando Johnny se
# arrima, avisa con "usar" y la partida abre su pantalla (ui/inventario.gd). Al cerrarla hay que apartarse un
# poco antes de que se vuelva a abrir. Como la mesa del ordenador (ordenador.gd), pero sin luz.
extends StaticBody2D

signal usar

var lista := true     # se pone a false al abrirse, y vuelve a true cuando Johnny se aparta


# "x": su centro; "arriba": donde acaba el muro de arriba; "ancho" y "hondo": lo que ocupa en el suelo
func montar(nombre: String, dibujo: String, letrero_texto: String, color: Color, x: float, arriba: float,
		ancho: float, hondo: float) -> void:
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

	var letrero := Label.new()
	letrero.text = letrero_texto
	letrero.theme = Tema.crear()
	letrero.add_theme_color_override("font_color", color)
	letrero.size = Vector2(160, 20)
	letrero.position = Vector2(-80, 4)
	letrero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letrero.z_index = 5
	add_child(letrero)

	# la zona de delante, donde se para Johnny para usarlo
	var zona := Area2D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(ancho + 20, 40)
	hueco.shape = r
	hueco.position = Vector2(0, 18)
	zona.add_child(hueco)
	add_child(zona)
	zona.body_entered.connect(func(_cuerpo):
		if lista:
			lista = false
			usar.emit())
	zona.body_exited.connect(func(_cuerpo): lista = true)
