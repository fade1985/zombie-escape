# La sala: al empezar saca el mapa de por dónde se puede andar (para los zombis), une la pantalla (barra de
# vida y cartel del arma) con Johnny, saca otra tanda de zombis (de tipos mezclados) cuando se acaban y, si a
# Johnny le pillan, vuelve a empezar.
#
# Teclas solo para probar: F2 a F7 sacan un zombi de cada tipo (normal, lento, rápido, explosivo, tentáculos y
# venenoso) y P, la portera.
#
# Si se arranca con "-- --captura" hace una prueba sola: salen uno de cada tipo y la portera, Johnny se queda
# quieto, los zombis vienen a por él,
# Johnny va cambiando de arma (fregona, pistola, escopeta y MP5) y de modo de atacar (asistido, hacia donde
# mira y libre con el stick derecho), en la terminal se va viendo cómo
# van los zombis, se guarda una foto en captura.png y el juego se cierra. Sirve para comprobar desde la
# terminal que todo arranca bien sin tener que jugar.
extends Node2D

const ZOMBIS := {
	"normal": preload("res://escenas/personajes/zombi_normal.tscn"),
	"lento": preload("res://escenas/personajes/zombi_lento.tscn"),
	"rapido": preload("res://escenas/personajes/zombi_rapido.tscn"),
	"explosivo": preload("res://escenas/personajes/zombi_explosivo.tscn"),
	"tentaculos": preload("res://escenas/personajes/zombi_tentaculos.tscn"),
	"venenoso": preload("res://escenas/personajes/zombi_venenoso.tscn"),
	"portera": preload("res://escenas/personajes/portera.tscn"),
}
# Qué tipos salen en las tandas: los que se repiten salen más a menudo
const MEZCLA := ["normal", "normal", "normal", "lento", "lento", "rapido", "rapido", "explosivo", "tentaculos", "venenoso"]
# Las teclas de prueba
const TECLAS := {KEY_F2: "normal", KEY_F3: "lento", KEY_F4: "rapido", KEY_F5: "explosivo", KEY_F6: "tentaculos",
	KEY_F7: "venenoso", KEY_P: "portera"}
# Dónde salen las tandas nuevas de zombis (en las esquinas y los bordes del baño, lejos del centro)
const SALIDAS := [Vector2(110, 520), Vector2(850, 520), Vector2(850, 250), Vector2(110, 300), Vector2(480, 580),
	Vector2(300, 560)]
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
	johnny.modo_cambiado.connect(func(nombre): $Pantalla/Ayuda.text = "Modo: %s (F1 cambia) · 1-6 arma · Q cambiar · R recargar · F2-F7 zombis · P portera" % nombre)
	johnny.murio.connect(_al_morir_johnny)
	johnny.avisar_arma()
	for zombi in get_tree().get_nodes_in_group("zombis"):
		zombi.murio.connect(_al_morir_zombi)

	captura = "--captura" in OS.get_cmdline_user_args()
	if captura:
		print("Navegación: ", $Navegacion.navigation_polygon.get_polygon_count(), " trozos de suelo andable")
		# Uno de cada tipo, cada uno en una salida, y la portera arriba en el centro
		var tipos := ["lento", "rapido", "explosivo", "tentaculos", "venenoso"]
		for i in tipos.size():
			meter_zombi(tipos[i], SALIDAS[i])
		meter_zombi("portera", Vector2(560, 300))
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


# Saca un zombi del tipo que se pida (o la portera) en ese sitio, y le conecta lo que toca
func meter_zombi(tipo: String, donde: Vector2) -> Node2D:
	var zombi: Node2D = ZOMBIS[tipo].instantiate()
	zombi.position = donde
	zombi.murio.connect(_al_morir_zombi)
	if tipo == "portera":
		# Su barra de vida grande, arriba, y los vecinos que llama
		var barra_jefa: ProgressBar = $Pantalla/Jefa
		zombi.vida_cambiada.connect(func(vida, maxima):
			barra_jefa.max_value = maxima
			barra_jefa.value = vida
			barra_jefa.visible = vida > 0)
		zombi.pide_zombi.connect(meter_zombi)
	$Cosas.add_child(zombi)
	return zombi


# Teclas de prueba: sacan el zombi de esa tecla en la salida más lejana a Johnny
func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode in TECLAS:
		var lejos: Vector2 = SALIDAS[0]
		for salida in SALIDAS:
			if salida.distance_to(johnny.position) > lejos.distance_to(johnny.position):
				lejos = salida
		meter_zombi(TECLAS[evento.keycode], lejos)


# Cuando cae el último zombi, al rato sale otra tanda, de tipos mezclados (para poder seguir probando)
func _al_morir_zombi() -> void:
	if not get_tree().get_nodes_in_group("zombis").is_empty():
		return
	await get_tree().create_timer(1.5).timeout
	var salidas := SALIDAS.duplicate()
	salidas.shuffle()
	for i in POR_TANDA:
		meter_zombi(MEZCLA.pick_random(), salidas[i])


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
				var tipo: String = z.scene_file_path.get_file().get_basename().trim_prefix("zombi_")
				linea += "%s(%d,%d %s %d) " % [tipo, z.position.x, z.position.y, z.estado, z.vida]
		print(linea)
	if tiempo > 6.0:
		var foto := get_viewport().get_texture().get_image()
		foto.save_png("res://captura.png")
		get_tree().quit()
