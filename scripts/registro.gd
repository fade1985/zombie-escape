# El registro de la partida, para que el jugador lo mande cuando algo falle (docs/LANZAMIENTO.md, «Robustez»).
#
# Godot ya escribe solo un archivo con todo lo que sale por la consola: user://logs/godot.log (en Windows,
# %APPDATA%\Johnny Rush\logs; guarda los 5 últimos, uno por vez que se abre el juego). Esto le añade:
#   - al arrancar, una cabecera con la versión del juego, el sistema, el procesador y la tarjeta gráfica;
#   - migas de pan: por dónde iba el jugador (apuntar(), p. ej. al llegar a cada planta);
#   - los errores con su archivo, línea y de dónde venían (las trazas del script), y cuántos van (errores);
#   - las últimas líneas también en memoria (ULTIMAS), porque en la web no hay archivo: «Copiar el registro» de Opciones.
# Opciones > General tiene el botón: en el ordenador abre la carpeta (abrir_carpeta) y en la web lo copia (copiar).
# Se prueba con -- --captura --registro (prueba_varias.gd).
extends Node

const ULTIMAS := 400   # las líneas que se guardan en memoria para copiarlas

var lineas: PackedStringArray = []
var errores := 0      # los errores que han saltado desde que se abrió el juego (avisos aparte)
var avisos := 0
var distintos := {}   # cada error o aviso distinto (su primera línea y su sitio) → cuántas veces ha salido
var cerrojo := Mutex.new()   # el registro puede escribirse desde otros hilos (el sonido, la carga de cosas)
var escucha: Escucha


# Lo que sale por la consola, también a la memoria
class Escucha extends Logger:
	var registro: Node

	func _log_message(mensaje: String, _es_error: bool) -> void:
		registro.guardar(mensaje.strip_edges(false, true))

	func _log_error(funcion: String, archivo: String, linea: int, codigo: String, razon: String, _editor: bool,
			tipo: int, trazas: Array[ScriptBacktrace]) -> void:
		var que := "AVISO" if tipo == Logger.ERROR_TYPE_WARNING else "ERROR"   # no-tr
		# (un push_error o push_warning dice que viene del motor: el sitio de verdad es el primer paso de la traza del script)
		for t in trazas:
			if archivo.ends_with(".cpp") and t.get_frame_count() > 0:
				archivo = t.get_frame_file(0)
				linea = t.get_frame_line(0)
				funcion = t.get_frame_function(0)
				break
		var texto := "%s: %s\n   en %s:%d (%s)" % [que, razon if razon != "" else codigo, archivo, linea, funcion]   # no-tr
		for t in trazas:
			if not t.is_empty():
				texto += "\n" + t.format(3)
		registro.contar(tipo == Logger.ERROR_TYPE_WARNING, texto.get_slice("
", 0) + texto.get_slice("
", 1))
		registro.guardar(texto)


func _init() -> void:
	escucha = Escucha.new()
	escucha.registro = self
	OS.add_logger(escucha)


func _ready() -> void:
	(func(): print(cabecera())).call_deferred()   # (al final del arranque: así ya sabe el idioma elegido)


# Al cerrar, el resumen: cuántos errores y avisos ha habido y cuáles (para ver de un vistazo si una partida ha ido limpia;
# las pruebas --captura lo dejan al final de su salida: «Registro al cerrar: ...»)
func _exit_tree() -> void:
	cerrojo.lock()
	var lista := distintos.keys().map(func(k): return "   %dx %s" % [distintos[k], k])   # no-tr
	cerrojo.unlock()
	print("Registro al cerrar: %d errores y %d avisos%s" % [errores, avisos, (":
" + "
".join(lista)) if lista else ""])   # no-tr


# Quién es el equipo: lo primero que hay que saber de un fallo
func cabecera() -> String:
	var memoria := OS.get_memory_info()
	var pantalla := DisplayServer.screen_get_size()
	return "\n".join([   # no-tr
		"=== Johnny Rush: Zombie Escape %s · %s ===" % [version(), Time.get_datetime_string_from_system(false, true)],   # no-tr
		"Godot %s · %s %s · %s" % [Engine.get_version_info().string, OS.get_name(), OS.get_version(), OS.get_processor_name()],   # no-tr
		"Tarjeta: %s (%s) · memoria: %d MB · pantalla: %dx%d · idioma: %s" % [   # no-tr
			RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(),
			int(memoria.get("physical", 0) / 1048576), pantalla.x, pantalla.y, Idioma.actual],
	])


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "?"))


# Por dónde va el jugador (sale en el registro con la hora)
func apuntar(texto: String) -> void:
	print("[%s] %s" % [Time.get_time_string_from_system(), texto])   # no-tr


func guardar(texto: String) -> void:
	cerrojo.lock()
	lineas.append(texto)
	if lineas.size() > ULTIMAS:
		lineas = lineas.slice(lineas.size() - ULTIMAS)
	cerrojo.unlock()


func contar(es_aviso: bool, cual: String) -> void:
	cerrojo.lock()
	distintos[cual] = distintos.get(cual, 0) + 1
	if es_aviso:
		avisos += 1
	else:
		errores += 1
	cerrojo.unlock()


# Todo lo que hay en memoria, con la cabecera delante aunque ya no esté entre las últimas líneas
func texto() -> String:
	cerrojo.lock()
	var todo := "\n".join(lineas)
	cerrojo.unlock()
	if not todo.begins_with("=== Johnny Rush"):   # no-tr
		todo = cabecera() + "\n...\n" + todo
	return todo


# El botón de Opciones: ¿hay carpeta que abrir o se copia?
func hay_archivo() -> bool:
	return OS.get_name() != "Web" and OS.get_name() != "Android" and OS.get_name() != "iOS"   # no-tr


func carpeta() -> String:
	return ProjectSettings.globalize_path("user://logs")


func abrir_carpeta() -> void:
	OS.shell_open(carpeta())


func copiar() -> void:
	DisplayServer.clipboard_set(texto())
