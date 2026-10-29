# La pantalla completa en el ordenador (autoload). Arranca como se dejó la última vez (ajuste «pantalla_completa», que
# guarda Tactil.pantalla_completa al cambiarla) y se cambia con F11 o Alt+Intro desde cualquier sitio, también con un
# menú abierto. En la web no hace nada: allí F11 es del navegador. Las pruebas (--captura) no arrancan en pantalla
# completa (la prueba --pantalla prueba las teclas).
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		set_process_input(false)
		return
	if "--captura" not in OS.get_cmdline_user_args() and Guardado.ajuste("pantalla_completa"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	if evento.keycode == KEY_F11 or (evento.alt_pressed and evento.keycode in [KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
		Tactil.pantalla_completa()
