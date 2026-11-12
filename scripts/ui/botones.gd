# Los botones de todos los menús reaccionan: al pasar por encima (o elegirlos con el mando o el teclado) dan un
# saltito, y al pulsarlos se aplastan un poco y vuelven. Es un autoload: mira cada nodo que entra en el juego y,
# si es un botón, le engancha las animaciones. Así no hace falta tocar cada menú.
# Al terminar siempre vuelven a su tamaño normal, para que la fuente pixel art se vea nítida.
extends Node


func _ready() -> void:
	get_tree().node_added.connect(_nodo_nuevo)


func _nodo_nuevo(nodo: Node) -> void:
	if nodo is Button:
		var b: Button = nodo
		b.mouse_entered.connect(saltito.bind(b))
		b.focus_entered.connect(saltito.bind(b))
		b.button_down.connect(aplastar.bind(b))
		b.button_up.connect(soltar.bind(b))


func _animar(b: Control) -> Tween:
	if b.has_meta("tween"):
		var viejo: Tween = b.get_meta("tween")
		if viejo and viejo.is_valid():
			viejo.kill()
	b.pivot_offset = b.size / 2.0
	var t := b.create_tween()
	b.set_meta("tween", t)
	return t


# (saltito, aplastar y soltar valen también para otros controles: la chapa de la barra del brillo de Opciones)
func saltito(b: Control) -> void:
	if (b is BaseButton and (b as BaseButton).disabled) or not b.is_visible_in_tree():
		return
	var t := _animar(b)
	t.tween_property(b, "scale", Vector2(1.06, 1.06), 0.05)
	t.tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func aplastar(b: Control) -> void:
	if b is BaseButton and (b as BaseButton).disabled:
		return
	_animar(b).tween_property(b, "scale", Vector2(1.04, 0.9), 0.04)


func soltar(b: Control) -> void:
	var t := _animar(b)
	t.tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
