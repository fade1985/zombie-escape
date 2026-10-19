# Una sala donde anda Johnny. De momento solo sirve para la prueba desde la terminal:
#
# Si se arranca con "-- --captura", Johnny anda solo un rato (abajo a la derecha, luego arriba hacia la
# lavadora), se guarda una foto en captura.png y el juego se cierra. Así se comprueba que todo arranca
# bien sin tener que jugar.
extends Node2D

var tiempo := 0.0

@onready var johnny := $Cosas/Johnny


func _ready() -> void:
	if "--captura" in OS.get_cmdline_user_args():
		print("Prueba: Johnny empieza en ", johnny.position)
	else:
		set_process(false)


func _process(delta: float) -> void:
	tiempo += delta
	# Le "pulsamos" las teclas como si fuéramos el jugador
	Input.action_release("derecha")
	Input.action_release("arriba")
	if tiempo < 0.8:
		Input.action_press("derecha")
	elif tiempo < 1.5:
		Input.action_press("arriba")
	if tiempo > 1.9:
		print("Prueba: Johnny acaba en ", johnny.position.round(), " mirando a ", johnny.direccion)
		var foto := get_viewport().get_texture().get_image()
		foto.save_png("res://captura.png")
		get_tree().quit()
