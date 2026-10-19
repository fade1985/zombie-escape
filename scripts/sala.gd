# La sala: al empezar saca el mapa de por dónde se puede andar (para los zombis), une la pantalla (barra de
# vida y cartel del arma) con Johnny, saca otra tanda de zombis cuando se acaban y, si a Johnny le pillan,
# vuelve a empezar.
#
# Si se arranca con "-- --captura" hace una prueba sola: Johnny se queda quieto, los zombis vienen a por él,
# Johnny va cambiando de arma (fregona, pistola, escopeta y MP5) y de modo de atacar (asistido, hacia donde
# mira y libre con el stick derecho), en la terminal se va viendo cómo
# van los zombis, se guarda una foto en captura.png y el juego se cierra. Sirve para comprobar desde la
# terminal que todo arranca bien sin tener que jugar.
extends Node2D

const ZOMBI := preload("res://escenas/personajes/zombi_normal.tscn")
# Dónde salen las tandas nuevas de zombis (en las esquinas del baño, lejos del centro)
const SALIDAS := [Vector2(110, 520), Vector2(850, 520), Vector2(850, 250), Vector2(110, 300)]
const POR_TANDA := 3

var tiempo := 0.0
var captura := false

@onready var johnny := $Cosas/Johnny
@onready var barra: ProgressBar = $Pantalla/Vida
@onready var cartel: Label = $Pantalla/Arma


func _ready() -> void:
	# "Hornear" la navegación: Godot mira las paredes y los muebles (los nodos del grupo "obstaculos") y
	# recorta del suelo todo lo que choca, dejando el sitio justo para el radio de un zombi. Se hace al
	# empezar para que, si se mueve un mueble en el editor, el camino se rehaga solo.
	$Navegacion.bake_navigation_polygon(false)

	# Señales: Johnny avisa cuando le cambia la vida o el arma, o se muere, y la sala hace lo que toca
	johnny.vida_cambiada.connect(_al_cambiar_vida)
	johnny.arma_cambiada.connect(func(texto): cartel.text = texto)
	johnny.modo_cambiado.connect(func(nombre): $Pantalla/Ayuda.text = "Modo: %s (F1 cambia) · 1-6 elegir arma · Q cambiar · R recargar" % nombre)
	johnny.murio.connect(_al_morir_johnny)
	johnny.avisar_arma()
	for zombi in get_tree().get_nodes_in_group("zombis"):
		zombi.murio.connect(_al_morir_zombi)

	captura = "--captura" in OS.get_cmdline_user_args()
	if captura:
		print("Navegación: ", $Navegacion.navigation_polygon.get_polygon_count(), " trozos de suelo andable")
	else:
		set_process(false)


func _al_cambiar_vida(vida: int, maxima: int) -> void:
	barra.max_value = maxima
	barra.value = vida


func _al_morir_johnny() -> void:
	$Pantalla/Aviso.show()
	# A los 2 segundos, la sala vuelve a empezar desde cero
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


# Cuando cae el último zombi, al rato sale otra tanda (para poder seguir probando las armas)
func _al_morir_zombi() -> void:
	if not get_tree().get_nodes_in_group("zombis").is_empty():
		return
	await get_tree().create_timer(1.5).timeout
	var salidas := SALIDAS.duplicate()
	salidas.shuffle()
	for i in POR_TANDA:
		var zombi := ZOMBI.instantiate()
		zombi.position = salidas[i]
		zombi.murio.connect(_al_morir_zombi)
		$Cosas.add_child(zombi)


# Solo con --captura: la prueba sola
func _process(delta: float) -> void:
	tiempo += delta
	# Le "pulsamos" las teclas como si fuéramos el jugador: [cuándo se pulsa, cuándo se suelta, qué]
	#  - modo asistido: 4 pistola, 5 escopeta
	#  - F1 al modo "hacia donde mira", y J pulsada
	#  - 6 MP5, F1 al modo libre y el stick derecho empujado hacia la derecha
	var pasos := [[1.6, 1.7, "arma_4"], [2.4, 2.5, "arma_5"], [3.0, 3.1, "cambiar_modo"], [3.0, 3.8, "atacar"],
		[3.8, 3.9, "arma_6"], [3.9, 4.0, "cambiar_modo"], [4.0, 4.8, "apuntar_derecha"]]
	for paso in pasos:
		if tiempo > paso[0] and tiempo - delta <= paso[0]:
			Input.action_press(paso[2])
		elif tiempo > paso[1] and tiempo - delta <= paso[1]:
			Input.action_release(paso[2])
	# Cada medio segundo apunta cómo va cada zombi, para ver en la terminal que se acercan y reciben
	if int(tiempo * 2.0) != int((tiempo - delta) * 2.0):
		var linea := "t=%.1f vida=%d %s %s | " % [tiempo, johnny.vida, johnny.modo, cartel.text.get_slice("\n", 0)]
		for z in $Cosas.get_children():
			if "estado" in z:   # solo los zombis tienen "estado" (también los ya muertos)
				linea += "%s(%d,%d %s %d) " % [z.name, z.position.x, z.position.y, z.estado, z.vida]
		print(linea)
	if tiempo > 4.7:
		var foto := get_viewport().get_texture().get_image()
		foto.save_png("res://captura.png")
		get_tree().quit()
