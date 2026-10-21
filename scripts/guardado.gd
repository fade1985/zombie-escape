# El guardado entre partidas (como src/save.js del JS): un archivo de texto en user://guardado.json.
# En Windows, user:// es %APPDATA%\Godot\app_userdata\Zombie Escape.
#
# Se guarda: dólares, puntos y talentos, armas encontradas, el baúl, las recetas aprendidas, los supervivientes
# rescatados, récords y el progreso de cada edificio.
# Las partidas a medias NO se guardan: si cierras, empiezas el edificio de nuevo.
#
# Se usa así:  var s := Guardado.cargar()  ·  s.dolares += 5  ·  Guardado.escribir(s)
# o, en un paso:  Guardado.cambiar(func(s): s.dolares += 5)
class_name Guardado

static var archivo := "user://guardado.json"   # la prueba con --captura usa otro

# Lo que tiene un guardado nuevo. Al cargar uno viejo, lo que le falte se rellena con esto
const NUEVO := {
	"mejor_planta": 0,    # la planta más alta a la que se ha llegado en cualquier edificio
	"dolares": 0,         # dólares ahorrados (en el JS se llamaban "keys")
	"dolares_total": 0,   # dólares conseguidos en total
	"puntos": 0,          # puntos de talento sin gastar (se compran con dólares en el ordenador: fase 6b)
	"talentos": {},       # puntos puestos en cada talento: {"ataque": 3, ...} (fase 6b)
	"armas": [],          # armas desbloqueadas (encontradas o compradas). La fregona siempre está
	"partidas": 0,
	"victorias": 0,
	"muertos": 0,         # zombis matados en total
	"baul": {},           # objetos guardados en el baúl de la sala de mantenimiento: {"clavos": 2, ...} (fase 7b)
	"baul_armas": [],     # armas creadas en el banco de trabajo, esperando en el baúl (recetas.gd)
	"recetas": ["molotov"], # recetas del banco de trabajo aprendidas (las sueltan los jefes): no se pierden nunca
	"rescatados": [],     # supervivientes rescatados (ids de Supervivientes.DATOS): viven en la sala de mantenimiento
	"acompanante": "",    # el que te acompaña en cada partida (uno de los rescatados), o "" para ir solo
	"logros": {},         # estado de cada logro (logros.gd): {"desahucio": "conseguido" | "cobrado"}
	"paginas": [],        # páginas del dosier encontradas (ids de Historia.DOSIERES): no se vuelven a encontrar
	"noticias_vistas": [], # noticias del ordenador ya vistas (ids de Historia.NOTICIAS): el aviso no se repite
	"cafetera": false,    # la farmacéutica ya ha encontrado el VD-7 en la cafetera (Historia.CAFETERA): no lo repite
	"edificios": {},      # progreso de cada edificio: {"apartamentos": {...}} (ver EDIFICIO)
	# modo: cómo se ataca (johnny.gd, MODOS) · teclas: los controles cambiados en Opciones (controles.gd)
	# tactil_tamano, tactil_opacidad y vibracion: los ajustes del móvil (tactil.gd)
	# vida_entera, pistola_sin_fin y lanzar_solo: las ayudas de la pestaña Ayudas de Opciones (johnny.gd y
	# lanzables.gd las miran)
	"ajustes": {"musica": true, "modo": "asistido", "teclas": {},
		"tactil_tamano": 1.0, "tactil_opacidad": 1.0, "vibracion": true,
		"vida_entera": false, "pistola_sin_fin": false, "lanzar_solo": false},
}

# alerta_max: la Alerta más alta abierta (alerta.gd; 0 = ninguna) · alerta: la elegida la última vez en "Elige edificio"
const EDIFICIO := {"completado": false, "partidas": 0, "victorias": 0, "mejor_planta": 0, "mejor_tiempo": 0.0,
	"alerta_max": 0, "alerta": 0}


static func cargar() -> Dictionary:
	var s: Dictionary = NUEVO.duplicate(true)
	if not FileAccess.file_exists(archivo):
		return s
	var leido = JSON.parse_string(FileAccess.get_file_as_string(archivo))
	if not leido is Dictionary:
		return s   # guardado roto: se empieza de cero
	for clave in leido:
		if clave in s:
			s[clave] = leido[clave]
	s.ajustes = NUEVO.ajustes.duplicate(true).merged(s.ajustes, true)   # copia: las constantes no se pueden cambiar
	# JSON guarda todos los números con decimales: los que son de contar, otra vez enteros
	for clave in ["mejor_planta", "dolares", "dolares_total", "puntos", "partidas", "victorias", "muertos"]:
		s[clave] = int(s[clave])
	for t in s.talentos:
		s.talentos[t] = int(s.talentos[t])
	for id in s.baul:
		s.baul[id] = int(s.baul[id])
	for a in s.baul_armas:
		a.dano = int(a.dano)
		a.unidades = int(a.unidades)
	for id in s.edificios:
		s.edificios[id] = EDIFICIO.merged(s.edificios[id], true)
		for clave in ["partidas", "victorias", "mejor_planta", "alerta_max", "alerta"]:
			s.edificios[id][clave] = int(s.edificios[id][clave])
	return s


static func escribir(s: Dictionary) -> void:
	var f := FileAccess.open(archivo, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(s, "\t"))
	ajustes_leidos = s.ajustes.duplicate(true)
	ajustes_de = archivo


# Un ajuste, para mirarlo en cada fotograma (las ayudas): se lee del archivo una vez y se recuerda; al guardar
# se pone al día solo, así que un cambio en Opciones se nota al momento
static var ajustes_leidos := {}
static var ajustes_de := ""   # de qué archivo son (la prueba con --captura usa otro)

static func ajuste(clave: String) -> Variant:
	if ajustes_de != archivo:
		ajustes_leidos = cargar().ajustes
		ajustes_de = archivo
	return ajustes_leidos.get(clave, NUEVO.ajustes.get(clave))


# Carga, cambia y guarda en un paso. Devuelve el guardado ya cambiado
static func cambiar(cambio: Callable) -> Dictionary:
	var s := cargar()
	cambio.call(s)
	escribir(s)
	return s


# El progreso de un edificio (lo crea si aún no se ha jugado)
static func edificio(s: Dictionary, id: String) -> Dictionary:
	if not id in s.edificios:
		s.edificios[id] = EDIFICIO.duplicate()
	return s.edificios[id]
