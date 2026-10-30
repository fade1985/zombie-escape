# Prepara los shaders grandes antes de jugar. La primera vez que se dibuja con un shader, la tarjeta gráfica tiene que
# montarlo, y hasta que acaba el juego se para: en el ordenador apenas se nota, pero en la web, cada uno de los grandes
# son de 100 a 300 ms, y con todos juntos el primer zombi que ardía dejaba el juego parado casi dos segundos (F17).
# Se hace una vez al abrir el menú: dibuja cada uno de los de SHADERS en una pantallita escondida (un SubViewport que
# no se ve), con luz y sin ella, porque cada forma de dibujarlo se monta aparte. Uno por fotograma, para que el menú no
# se quede parado de golpe. Si se añade un shader grande, va en la lista.
class_name Calentador
extends SubViewport

const SHADERS := [
	preload("res://escenas/personajes/destello.gdshader"),
	preload("res://escenas/personajes/brillo.gdshader"),
	preload("res://escenas/personajes/aviso.gdshader"),   # (las marcas de los ataques de los jefes)
]

static var hecho := false


static func empezar(desde: Node) -> void:
	if not hecho:
		hecho = true
		desde.get_tree().root.add_child.call_deferred(Calentador.new())


func _ready() -> void:
	size = Vector2i(16, 16)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	var luz := PointLight2D.new()
	luz.texture = Luz.TEXTURA
	add_child(luz)
	for shader: Shader in SHADERS:
		for capa in [1, 0]:   # (con capa 0, la luz no le llega: sin luz)
			var dibujo := Sprite2D.new()
			dibujo.texture = Luz.TEXTURA
			dibujo.light_mask = capa
			dibujo.material = ShaderMaterial.new()
			dibujo.material.shader = shader
			add_child(dibujo)
			render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			dibujo.queue_free()
	queue_free()
