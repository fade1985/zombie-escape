# Ayudas para las pruebas sin jugar ("-- --captura", ver CLAUDE.md): saber si se está probando, leer lo que
# acompaña a la prueba en la línea de órdenes y guardar fotos de la pantalla.
class_name Captura


# Si el juego se ha arrancado con "-- --captura"
static func activa() -> bool:
	return "--captura" in OS.get_cmdline_user_args()


# Lo que va detrás de "nombre" en la línea de órdenes ("--jefe cocinero" → "cocinero"); si no está, "si_no"
static func dato(nombre: String, si_no := "") -> String:
	var args := OS.get_cmdline_user_args()
	var i := args.find(nombre)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else si_no


# Guarda lo que se ve en la pantalla en la carpeta capturas/ del juego: Captura.foto("captura-menu.png"). Esa carpeta
# lleva un .gdignore, para que Godot no importe las fotos como si fueran dibujos del juego
const CARPETA := "res://capturas/"

static func foto(archivo: String) -> void:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var raiz: Window = (Engine.get_main_loop() as SceneTree).root
	raiz.get_texture().get_image().save_png(CARPETA + archivo)


# ── Que una prueba rota acabe, en vez de quedarse en negro ──
# Si algún archivo de scripts/pruebas/ no compila, Godot no carga la partida de prueba y el juego se quedaba con la
# pantalla en negro, sin acabar nunca; y un error de script a mitad de una prueba la dejaba parada (a veces en medio de
# un fundido a negro) hasta que saltaba el timeout. Ahora, en los dos casos, dice qué ha pasado en la terminal ("ERROR DE
# LA PRUEBA: ...") y cierra el juego: con el código 2 si no compila y con el 1 si falla a mitad. El trailer no se vigila
# (se graba con calma y no se quiere que se corte)
static var fallado := false
static var vigilante: Logger = null


# Un error de script, salte donde salte (pueden llegar desde otro hilo: por eso se avisa con call_deferred)
class Vigilante extends Logger:
	func _log_error(_funcion: String, archivo: String, linea: int, codigo: String, razon: String, _editor: bool,
			tipo: int, _trazas: Array[ScriptBacktrace]) -> void:
		if tipo == Logger.ERROR_TYPE_SCRIPT:
			Captura.fallar.call_deferred("un error de script en %s:%d (%s)" % [archivo, linea, razon if razon != "" else codigo], 1)


# Se pone al abrir el menú con --captura: vigila los errores de script hasta que acaba la prueba
static func vigilar() -> void:
	if vigilante == null and not "--trailer" in OS.get_cmdline_user_args():
		vigilante = Vigilante.new()
		OS.add_logger(vigilante)


# Dice por qué falla la prueba y cierra el juego (solo la primera vez)
static func fallar(motivo: String, codigo := 1) -> void:
	if fallado:
		return
	fallado = true
	printerr("ERROR DE LA PRUEBA: %s. Se cierra el juego (código %d)." % [motivo, codigo])
	(Engine.get_main_loop() as SceneTree).quit(codigo)


# Al cargar la partida de prueba, Godot solo dice «Could not resolve super class», sin señalar qué archivo falla: se
# cargan uno a uno los de scripts/pruebas/ para que cada uno que no compile cuente él mismo su error y su línea
static func diagnosticar() -> void:
	for archivo in DirAccess.get_files_at("res://scripts/pruebas"):
		if archivo.ends_with(".gd"):
			load("res://scripts/pruebas/" + archivo)


# Pasa del menú a la partida: la de verdad o, con --captura, la de prueba (pruebas/partida_prueba.gd). Antes de abrir
# esa, mira que compile: si no, se cierra con el aviso en vez de dejar la pantalla en negro
static func ir_a_la_partida() -> void:
	if activa():
		var guion := load("res://scripts/pruebas/partida_prueba.gd") as GDScript
		if guion == null or not guion.can_instantiate():
			diagnosticar()
			fallar("la partida de prueba no compila (mira el SCRIPT ERROR de más arriba: dice el archivo y la línea)", 2)
			return
	(Engine.get_main_loop() as SceneTree).change_scene_to_file(
		"res://escenas/partida_prueba.tscn" if activa() else "res://escenas/partida.tscn")
