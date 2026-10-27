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
