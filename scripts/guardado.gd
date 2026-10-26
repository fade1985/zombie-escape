# El guardado entre partidas (como src/save.js del JS): un archivo de texto en user://guardado.json.
# En Windows, user:// es %APPDATA%\Godot\app_userdata\Zombie Escape.
#
# Se guarda: dólares, puntos y talentos, armas encontradas, el baúl (objetos, armas y arrojables), los supervivientes rescatados, récords, el
# progreso de cada edificio y las colecciones (lo encontrado y visto alguna vez).
# Las partidas a medias NO se guardan: si cierras, empiezas el edificio de nuevo.
#
# Se usa así:  var s := Guardado.cargar()  ·  s.dolares += 5  ·  Guardado.escribir(s)
# o, en un paso:  Guardado.cambiar(func(s): s.dolares += 5)
class_name Guardado

static var archivo := "user://guardado.json"   # la prueba con --captura usa otro
# El baúl de pruebas (la sala de pruebas, sala_armas.gd): mientras tiene algo, el baúl que se lee y se cambia es este,
# {baul, baul_equipo}, que solo vive en la memoria; al archivo se sigue escribiendo el baúl de verdad, sin tocarlo
static var baul_prueba := {}

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
	"baul": {},           # objetos guardados en el baúl de la sala de mantenimiento: {"gasolina": 2, ...} (fase 7b)
	"baul_equipo": [],    # las armas y los paquetes de arrojables del baúl, cada uno en su casilla y con su calidad
	                      # (Armas.CALIDADES; parte 4 de la tienda y las piezas): [{"id": "bate", "calidad": 2},
	                      # {"id": "molotov", "calidad": 1, "n": 3}, ...]
	"rescatados": [],     # supervivientes rescatados (ids de Supervivientes.DATOS): viven en las viviendas (viviendas.gd)
	"acompanante": "",    # el que te acompaña en cada partida (uno de los rescatados), o "" para ir solo
	"skin": "",           # la skin que lleva Johnny (skins.gd; "" = el conserje de siempre)
	"skins": [],          # las skins desbloqueadas (ids de Skins.LISTA): se quedan para siempre
	"logros": {},         # estado de cada logro (logros.gd): {"desahucio": "conseguido" | "cobrado"}
	"paginas": [],        # páginas del dosier encontradas (ids de Historia.DOSIERES): no se vuelven a encontrar
	"noticias_vistas": [], # noticias del ordenador ya vistas (ids de Historia.NOTICIAS): el aviso no se repite
	"encontrados": [],    # objetos cogidos alguna vez (ids de Objetos.NOMBRES): Colecciones del ordenador
	"bestiario": [],      # enemigos vistos alguna vez (ids de Bestiario.LISTA): el bestiario de Colecciones
	"colecciones_nuevo": false, # hay algo nuevo en Colecciones desde la última vez que se abrió (el icono avisa)
	"edificios": {},      # progreso de cada edificio: {"apartamentos": {...}} (ver EDIFICIO)
	"retos": {},          # el reto del día (reto.gd): la marca de hoy en cada edificio: {"apartamentos": {...}} (ver RETO)
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

# El reto del día de un edificio (reto.gd): fecha (el día del reto, "2026-10-22"; si es de otro día, se empieza de
# cero), regla (la de ese día), intentos, planta (la más alta a la que se ha llegado hoy), completado y tiempo
# (el mejor de hoy, si se ha completado)
const RETO := {"fecha": "", "regla": "", "intentos": 0, "planta": 0, "completado": false, "tiempo": 0.0}


static func cargar() -> Dictionary:
	var s := cargar_archivo()
	if not baul_prueba.is_empty():
		s.baul = baul_prueba.baul.duplicate(true)
		s.baul_equipo = baul_prueba.baul_equipo.duplicate(true)
	return s


# Lo que hay de verdad en el archivo (con el baúl de verdad, aunque esté puesto el de pruebas)
static func cargar_archivo() -> Dictionary:
	var s: Dictionary = NUEVO.duplicate(true)
	var leido = leer(archivo)
	if not leido is Dictionary:
		leido = leer(archivo + ".bak")   # roto o sin terminar de escribir: vale la copia de la vez anterior
	if not leido is Dictionary:
		return s   # no hay guardado (o están rotos los dos): se empieza de cero
	for clave in leido:
		if clave in s:
			s[clave] = leido[clave]
	s.ajustes = NUEVO.ajustes.duplicate(true).merged(s.ajustes, true)   # copia: las constantes no se pueden cambiar
	# JSON guarda todos los números con decimales: los que son de contar, otra vez enteros
	for clave in ["mejor_planta", "dolares", "dolares_total", "puntos", "partidas", "victorias", "muertos"]:
		s[clave] = int(s[clave])
	for t in s.talentos:
		s.talentos[t] = int(s.talentos[t])
	# los objetos que ya no existen desaparecen del baúl y de los encontrados (Colecciones): el mechero, la llave
	# inglesa, el hacha, las cuchillas, el táser, la cuerda, las mancuernas, la cadena, las perchas, el hielo seco, el
	# cable, los clavos, el spray de pintura, la lejía, la pistola de agua, la cinta americana, la bombona de gas, la
	# jeringuilla, el aceite y el bocadillo se quitaron del juego el 25 oct, y luego los explosivos, el despertador, el
	# extintor, el trapo y el alcohol (las piezas de mejora de las armas ocuparon su sitio). Tampoco se lee la marca
	# "cafetera" de los guardados viejos (la cafetera de Johnny se quitó el 27 oct)
	var baul := {}
	for id in s.baul:
		if Objetos.NOMBRES.has(id):
			baul[id] = int(s.baul[id])
	s.baul = baul
	s.encontrados = s.encontrados.filter(func(id): return Objetos.NOMBRES.has(id))
	# el equipo del baúl: solo armas y arrojables que existen, con su calidad (y los arrojables, cuántos) en enteros
	var equipo := []
	for e in s.baul_equipo:
		var id: String = str(e.get("id", "")) if e is Dictionary else ""
		var calidad := clampi(int(e.get("calidad", 0)), 0, Armas.CALIDADES.size() - 1) if e is Dictionary else 0
		if Armas.DATOS.has(id):
			equipo.append({"id": id, "calidad": calidad})
		elif Lanzables.DATOS.has(id) and int(e.get("n", 0)) > 0:
			equipo.append({"id": id, "calidad": calidad, "n": int(e.n)})
	s.baul_equipo = equipo
	# las recetas del banco de trabajo se quitaron del juego el 25 oct: las armas creadas del baúl ("baul_armas"), las
	# recetas aprendidas ("recetas") y las creadas alguna vez ("creadas", de Colecciones) de un guardado viejo no se
	# leen (solo se copia lo que está en NUEVO) y desaparecen al volver a escribirlo
	for id in s.edificios:
		s.edificios[id] = EDIFICIO.merged(s.edificios[id], true)
		for clave in ["partidas", "victorias", "mejor_planta", "alerta_max", "alerta"]:
			s.edificios[id][clave] = int(s.edificios[id][clave])
	for id in s.retos:
		s.retos[id] = RETO.merged(s.retos[id], true)
		for clave in ["intentos", "planta"]:
			s.retos[id][clave] = int(s.retos[id][clave])
	# Un guardado de antes de las Colecciones (sin "encontrados"): lo encontrado se saca del baúl, una sola vez (en
	# cuanto se escriba, el archivo ya lleva la clave)
	if not leido.has("encontrados"):
		for id in s.baul:
			if s.baul[id] > 0:
				s.encontrados.append(id)
	return s


# Lo que hay en un archivo de guardado: un Dictionary, o null si no existe o está roto
static func leer(ruta: String) -> Variant:
	if not FileAccess.file_exists(ruta):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(ruta))


static var escrituras := 0   # cuántas veces se ha escrito: Bestiario mira si el archivo cambió desde que lo leyó

# Guardado seguro: si el juego se cierra a mitad de escribir, no se pierde nada. Se escribe primero en
# guardado.json.tmp; solo cuando está entero, el guardado de antes pasa a ser la copia (guardado.json.bak) y el
# nuevo ocupa su sitio. Pase lo que pase, siempre queda uno entero: el bueno o la copia (cargar mira los dos)
static func escribir(s: Dictionary) -> void:
	# con el baúl de pruebas puesto, lo que cambia en el baúl se queda en él y al archivo va el de verdad
	if not baul_prueba.is_empty():
		baul_prueba = {"baul": s.baul.duplicate(true), "baul_equipo": s.baul_equipo.duplicate(true)}
		var real := cargar_archivo()
		s = s.duplicate()
		s.baul = real.baul
		s.baul_equipo = real.baul_equipo
	var tmp := archivo + ".tmp"
	var bak := archivo + ".bak"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(s, "\t"))
		var bien := f.get_error() == OK
		f.close()   # cerrar asegura que todo está ya en el disco
		if bien:
			if FileAccess.file_exists(archivo):
				if FileAccess.file_exists(bak):
					DirAccess.remove_absolute(bak)
				DirAccess.rename_absolute(archivo, bak)
			DirAccess.rename_absolute(tmp, archivo)
	ajustes_leidos = s.ajustes.duplicate(true)
	ajustes_de = archivo
	escrituras += 1


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


# Como cambiar, pero en el baúl de verdad aunque esté puesto el de pruebas (el botón de las piezas del panel)
static func cambiar_real(cambio: Callable) -> void:
	var prueba := baul_prueba
	baul_prueba = {}
	cambiar(cambio)
	baul_prueba = prueba


# El progreso de un edificio (lo crea si aún no se ha jugado)
static func edificio(s: Dictionary, id: String) -> Dictionary:
	if not id in s.edificios:
		s.edificios[id] = EDIFICIO.duplicate()
	return s.edificios[id]
