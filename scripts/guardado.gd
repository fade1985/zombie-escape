# El guardado entre partidas (como src/save.js del JS): un archivo de texto en user://guardado.json.
# En Windows, user:// es %APPDATA%\Godot\app_userdata\Zombie Escape.
#
# Se guarda: dólares, puntos y talentos, armas encontradas, el baúl, las recetas aprendidas, los supervivientes
# rescatados, récords, el progreso de cada edificio y las colecciones (lo encontrado, creado y visto alguna vez).
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
	"rescatados": [],     # supervivientes rescatados (ids de Supervivientes.DATOS): viven en las viviendas (viviendas.gd)
	"acompanante": "",    # el que te acompaña en cada partida (uno de los rescatados), o "" para ir solo
	"skin": "",           # la skin que lleva Johnny (skins.gd; "" = el conserje de siempre)
	"skins": [],          # las skins desbloqueadas (ids de Skins.LISTA): se quedan para siempre
	"logros": {},         # estado de cada logro (logros.gd): {"desahucio": "conseguido" | "cobrado"}
	"paginas": [],        # páginas del dosier encontradas (ids de Historia.DOSIERES): no se vuelven a encontrar
	"noticias_vistas": [], # noticias del ordenador ya vistas (ids de Historia.NOTICIAS): el aviso no se repite
	"encontrados": [],    # objetos cogidos alguna vez (ids de Objetos.NOMBRES): Colecciones del ordenador
	"creadas": [],        # armas creadas alguna vez en el banco de trabajo (ids de Recetas.LISTA): Colecciones
	"bestiario": [],      # enemigos vistos alguna vez (ids de Bestiario.LISTA): el bestiario de Colecciones
	"colecciones_nuevo": false, # hay algo nuevo en Colecciones desde la última vez que se abrió (el icono avisa)
	"cafetera": false,    # la farmacéutica ya ha encontrado el VD-7 en la cafetera (Historia.CAFETERA): no lo repite
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
	for id in s.baul:
		s.baul[id] = int(s.baul[id])
	for a in s.baul_armas:
		a.dano = int(a.dano)
		a.unidades = int(a.unidades)
		# los lanzallamas de antes de la llamarada continua (24 oct) se crearon con el daño de una gota (4 a 6): ahora
		# es por segundo, así que cogen el de ahora con su rareza, y su frase nueva
		if a.get("receta", "") == "lanzallamas" and a.dano < 20:
			var nuevo := Recetas.crear("lanzallamas", a.rareza)
			a.dano = nuevo.dano
			a.desc = nuevo.desc
	for id in s.edificios:
		s.edificios[id] = EDIFICIO.merged(s.edificios[id], true)
		for clave in ["partidas", "victorias", "mejor_planta", "alerta_max", "alerta"]:
			s.edificios[id][clave] = int(s.edificios[id][clave])
	for id in s.retos:
		s.retos[id] = RETO.merged(s.retos[id], true)
		for clave in ["intentos", "planta"]:
			s.retos[id][clave] = int(s.retos[id][clave])
	# Un guardado de antes de las Colecciones (sin "encontrados"): lo encontrado y lo creado se saca del baúl, una
	# sola vez (en cuanto se escriba, el archivo ya lleva las claves)
	if not leido.has("encontrados"):
		for id in s.baul:
			if s.baul[id] > 0:
				s.encontrados.append(id)
		for a in s.baul_armas:
			if not a.receta in s.creadas:
				s.creadas.append(a.receta)
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


# El progreso de un edificio (lo crea si aún no se ha jugado)
static func edificio(s: Dictionary, id: String) -> Dictionary:
	if not id in s.edificios:
		s.edificios[id] = EDIFICIO.duplicate()
	return s.edificios[id]
