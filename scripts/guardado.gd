# El guardado entre partidas (como src/save.js del JS): un archivo de texto en user://guardado.json.
# En Windows, user:// es %APPDATA%\Johnny Rush (config/custom_user_dir_name de project.godot).
#
# Se guarda: dólares, puntos y talentos, armas encontradas, el baúl (objetos, armas y arrojables), los supervivientes rescatados, récords, el
# progreso de cada edificio y las colecciones (lo encontrado y visto alguna vez).
# La partida a medias, solo como estaba al empezar su planta: "en_curso" (partida_guardada.gd).
#
# Se usa así:  var s := Guardado.cargar()  ·  s.dolares += 5  ·  Guardado.escribir(s)
# o, en un paso:  Guardado.cambiar(func(s): s.dolares += 5)
#
# Tres huecos de guardado (M45; se eligen en el menú principal, huecos.gd): cada uno con su progreso en su archivo,
# guardado.json (el 1, el de siempre: el guardado de antes de los huecos es el hueco 1), guardado-2.json y
# guardado-3.json. Los ajustes de Opciones son de los tres: van en guardado-ajustes.json, con el hueco en uso
# ({"hueco": 1, "ajustes": {...}}). Mientras ese archivo no existe, valen los ajustes que lleve el hueco (así pasan
# los de un guardado de antes). Cada hueco lleva también su copia de los ajustes, pero al cargar mandan los comunes
class_name Guardado

static var base := "user://guardado"   # el nombre de los archivos, sin ".json" (la prueba con --captura usa otro)
static var hueco := hueco_guardado()   # el hueco en uso (1, 2 o 3)
static var archivo := ruta(hueco)      # el archivo del hueco en uso
const HUECOS := 3
# El baúl de pruebas (la sala de pruebas, sala_armas.gd): mientras tiene algo, el baúl que se lee y se cambia es este,
# {baul, baul_equipo}, que solo vive en la memoria; al archivo se sigue escribiendo el baúl de verdad, sin tocarlo
static var baul_prueba := {}

# Lo que tiene un guardado nuevo. Al cargar uno viejo, lo que le falte se rellena con esto
const NUEVO := {
	"mejor_planta": 0,    # la planta más alta a la que se ha llegado en cualquier edificio
	"dolares": 0,         # dólares ahorrados (en el JS se llamaban "keys")
	"dolares_total": 0,   # dólares conseguidos en total
	"puntos": 0,          # solo de los guardados viejos: los puntos de talento sin gastar, que al cargar se cambian por dólares
	"mutageno": 0,        # el mutágeno guardado (15 nov): el de cada partida pasa aquí si se completa el edificio; si
	                      # se cae o se abandona, se pierde (partida.terminar). Se gasta en los talentos (talentos.gd)
	"talentos_mutageno": true, # los talentos ya se pagan con mutágeno (15 nov). Un guardado de antes no lo trae: al
	                           # cargarlo, su árbol se vacía una vez, sin devolver nada (cargar_archivo)
	"talentos": {},       # puntos puestos en cada talento: {"ataque": 3, ...}
	"armas": [],          # armas desbloqueadas (encontradas o compradas). La fregona siempre está
	"partidas": 0,
	"guia_otra_vez": false, # «Que vuelvan a salir todos» (abajo en Tutorial): la guía de la primera partida (guia.gd) sale en la próxima
	                        # de los Apartamentos aunque no sea la primera, y se apaga sola al empezarla
	"victorias": 0,
	"muertos": 0,         # zombis matados en total
	"matados": {},        # zombis matados de cada tipo desde el 8 nov ({"normal": 120, ...}, claves de Bestiario.LISTA): Colecciones
	"muertos_con_ayudas": 0, # los de "muertos" que se mataron en partidas con ayudas: no cuentan para el logro Exterminador (logros.gd)
	"baul": {},           # objetos guardados en el baúl de la sala de mantenimiento: {"gasolina": 2, ...}
	"orden_baul": [],     # en qué casilla del baúl va cada cosa, si el jugador las ha movido u ordenado (16 nov): el nombre
	                      # de lo de cada casilla ("o:balas#24", "e:bate:2#3:0:false"; ui/inventario.gd, colocar)
	"baul_equipo": [],    # las armas y los arrojables del baúl, cada uno en su casilla y con su calidad (y su
	                      # durabilidad: "quedan", las partidas que aún puede salir, y "usada" si ya ha salido en esta: Armas.nuevas)
	                      # (Armas.CALIDADES; parte 4 de la tienda y las piezas): [{"id": "bate", "calidad": 2},
	                      # {"id": "molotov", "calidad": 1, "n": 3}, ...]. Los arrojables de la misma clase y calidad,
	                      # juntos en una casilla hasta lo que cabe en un montón en la mano (Objetos.monton_arrojables)
	"montones_baul": true, # las casillas del baúl ya son de montones pequeños (15 nov; antes, 99 de todo). Un guardado
	                       # de antes no lo trae: al cargarlo, sus arrojables se reparten una vez (cargar_archivo)
	"rescatados": [],     # supervivientes rescatados (ids de Supervivientes.DATOS): viven en las viviendas (viviendas.gd)
	"acompanante": "",    # el que te acompaña en cada partida (uno de los rescatados), o "" para ir solo
	"skin": "",           # la skin que lleva Johnny (skins.gd; "" = el conserje de siempre)
	"skins": [],          # las skins desbloqueadas (ids de Skins.LISTA): se quedan para siempre
	"skins_nuevo": false, # hay una skin sin ver en la taquilla desde la última vez que se abrió (el «!» de la taquilla)
	"logros": {},         # estado de cada logro (logros.gd): {"desahucio": "conseguido" | "cobrado"}
	"logros_cuentas": {}, # lo que se cuenta solo para los logros (logros.gd), sin las partidas con ayudas: jefes
	                      # derrotados, partidas ganadas, armas con las que se ha matado y reglas del reto completadas:
	                      # {"jefes": 3, "victorias": 1, "armas": ["fregona"], "reglas": ["cuerpo"]}
	"paginas": [],        # páginas del dosier encontradas (ids de Historia.DOSIERES): no se vuelven a encontrar
	"videos_vistos": [],   # noticias ya vistas en la tele de un salón (ids de Historia.NOTICIAS): salen en VIDEOS.EXE y la tele enseña la siguiente
	"pesadilla": false,   # la última partida acabó en derrota: la siguiente empieza con Johnny despertándose (partida.despertar)
	"relatos": [],        # los textos de la historia ya salidos (claves de Historia.RELATOS): cada uno sale una sola vez
	"encontrados": [],    # objetos cogidos alguna vez (ids de Objetos.NOMBRES): Colecciones del ordenador
	"bestiario": [],      # enemigos vistos alguna vez (ids de Bestiario.LISTA): el bestiario de Colecciones
	"sujetos_nuevos": [], # enemigos vistos por primera vez y aún sin elegir en Sujetos (ids de Bestiario.LISTA): su
	                      # casilla, su pestaña y el icono llevan el «!» hasta que se hace clic en él (15 nov; antes,
	                      # "colecciones_nuevo", que se quitaba con solo abrir el programa)
	"regalo_cogido": false, # ya se ha cogido el regalo de bienvenida de la tienda de armas: la pistola gratis, una sola vez
	                        # (tienda_armas.gd). Mientras no, no se sale de la sala de mantenimiento (partida.cruzar)
	"regalos_lanzables": [], # los lanzables del regalo de bienvenida ya cogidos (15 nov: un molotov, una granada y una
	                         # atraedora gratis, una sola vez cada uno: tienda_armas.gd, REGALO_LANZABLES)
	"baul_nuevo": false,  # hay algo recién comprado en el baúl que aún no se ha visto (el «!» del baúl, hasta abrirlo:
	                      # lo comprado va al baúl desde el 15 nov)
	"fregona": {},        # la fregona mejorada (15 nov): no va al baúl, Johnny empieza cada partida con ella y gasta una
	                      # partida en cada una ({"calidad", "quedan" y "usada"}, como una casilla del baúl: Armas.estrenar;
	                      # vacío, la Normal de siempre). Al romperse, vuelve la Normal (Objetos.cerrar_baul)
	"tutoriales": [],     # tutoriales ya vistos (ids de Tutoriales.LISTA): cada uno sale una sola vez
	"edificios": {},      # progreso de cada edificio: {"apartamentos": {...}} (ver EDIFICIO)
	"en_curso": "",       # la partida a medias, al empezar la planta en la que va (partida_guardada.gd; "" = ninguna)
	"garajes": {},        # el garaje del reto del día (garaje.gd): en cada edificio, el día en que se jugó y los récords
	                      # de cada condición: {"apartamentos": {...}} (ver GARAJE). (Hasta el 16 nov, "retos": el reto
	                      # viejo, reto.gd; al no estar aquí, no se lee y desaparece al volver a escribir el guardado)
	# teclas: los controles cambiados en Opciones (controles.gd)
	# tactil_tamano, tactil_opacidad y vibracion: los ajustes del móvil (tactil.gd)
	# vida_entera, pistola_sin_fin, lanzar_solo y disparo_asistido: las ayudas de la pestaña Ayudas de Opciones (johnny.gd y
	# lanzables.gd las miran) · tutoriales: si salen las ventanas de los tutoriales (tutoriales.gd)
	# idioma: "es" o "en", el elegido en Opciones (idioma.gd); "" = nunca se ha elegido: el del sistema
	# temblor: cuánto tiembla la pantalla y cuánto se frena el juego al golpear (temblor.gd): 1 normal, 0,5 suave, 0 nada
	# brillo: el de Opciones → Pantalla (una barra), de 0 a 100 de 5 en 5; 50 es como se ve sin tocar nada (pantalla.gd, poner_brillo)
	# volumen: el de Opciones → Audio (otra barra), de 0 a 100 de 5 en 5; 100 es el de siempre y 0, nada (sonido.gd, poner_volumen)
	"ajustes": {"musica": true, "teclas": {},
		"tactil_tamano": 1.0, "tactil_opacidad": 1.0, "vibracion": true, "temblor": 1.0, "brillo": 50, "volumen": 100,
		"vida_entera": false, "pistola_sin_fin": false, "lanzar_solo": false, "disparo_asistido": false, "tutoriales": true, "idioma": "", "pantalla_completa": false},
}

# alerta_max: la Alerta más alta abierta (alerta.gd; 0 = ninguna) · alerta: la elegida la última vez en "Elige edificio"
const EDIFICIO := {"completado": false, "partidas": 0, "victorias": 0, "mejor_planta": 0, "mejor_tiempo": 0.0,
	"alerta_max": 0, "alerta": 0}

# El garaje del reto del día de un edificio (garaje.gd): fecha (el último día en que se jugó, "2026-11-16": se juega una
# vez al día) y records (las oleadas superadas con cada condición, aparte: {"cuerpo": 7, "curas": 3})
const GARAJE := {"fecha": "", "records": {}}


static func cargar() -> Dictionary:
	var s := cargar_archivo()
	if not baul_prueba.is_empty():
		s.baul = baul_prueba.baul.duplicate(true)
		s.baul_equipo = baul_prueba.baul_equipo.duplicate(true)
	return s


# Lo que hay de verdad en el archivo (con el baúl de verdad, aunque esté puesto el de pruebas)
# (o en el de otro hueco: el resumen de la pantalla de los huecos)
static func cargar_archivo(de := archivo) -> Dictionary:
	var s: Dictionary = NUEVO.duplicate(true)
	var leido = leer_entero(de)
	if leido is Dictionary:
		for clave in leido:
			if clave in s:
				s[clave] = leido[clave]
	else:
		leido = {}   # no hay guardado (o están rotos los dos): se empieza de cero
	var comunes = leer_entero(ruta_ajustes())
	if comunes is Dictionary and comunes.get("ajustes") is Dictionary:
		s.ajustes = comunes.ajustes
	s.ajustes = NUEVO.ajustes.duplicate(true).merged(s.ajustes, true)   # copia: las constantes no se pueden cambiar
	# JSON guarda todos los números con decimales: los que son de contar, otra vez enteros
	for clave in ["mejor_planta", "dolares", "dolares_total", "mutageno", "puntos", "partidas", "victorias", "muertos", "muertos_con_ayudas"]:
		s[clave] = int(s[clave])
	for id in s.matados:
		s.matados[id] = int(s.matados[id])
	for t in s.talentos:
		s.talentos[t] = int(s.talentos[t])
		# un talento que ahora admite menos puntos (Durito, de 5 a 3 el 28 oct): los que sobran vuelven sin gastar
		var tope: int = Talentos.talento(t).get("max", s.talentos[t])
		if s.talentos[t] > tope:
			s.puntos += s.talentos[t] - tope
			s.talentos[t] = tope
	# Los talentos se pagan con mutágeno desde el 15 nov (antes, con dólares, y antes del 6 nov, con puntos de talento):
	# un guardado de antes empieza el árbol de cero, una sola vez y sin devolver nada (lo pidió el dueño: «como volver a
	# empezar»). Los puntos sin gastar de los guardados de antes del 6 nov se cambiaban por dólares, a $10: eso se queda
	if not leido.has("talentos_mutageno"):
		s.talentos = {}
		s.talentos_mutageno = true
	s.dolares += s.puntos * 10
	s.puntos = 0
	# los objetos que ya no existen desaparecen del baúl y de los encontrados (Colecciones): el mechero, la llave
	# inglesa, el hacha, las cuchillas, el táser, la cuerda, las mancuernas, la cadena, las perchas, el hielo seco, el
	# cable, los clavos, el spray de pintura, la lejía, la pistola de agua, la cinta americana, la bombona de gas, la
	# jeringuilla, el aceite y el bocadillo se quitaron del juego el 25 oct, y luego los explosivos, el despertador, el
	# extintor, el trapo y el alcohol (las piezas de mejora de las armas ocuparon su sitio). Tampoco se lee la marca
	# "cafetera" de los guardados viejos (la cafetera de Johnny se quitó el 27 oct)
	var baul := {}
	for id in s.baul:
		if id in Objetos.todos():
			baul[id] = int(s.baul[id])
	s.baul = baul
	s.encontrados = s.encontrados.filter(func(id): return Objetos.NOMBRES.has(id))
	# el equipo del baúl: solo armas y arrojables que existen, con su calidad (y los arrojables, cuántos) en enteros
	var equipo := []
	for e in s.baul_equipo:
		var id: String = str(e.get("id", "")) if e is Dictionary else ""
		var calidad := clampi(int(e.get("calidad", 0)), 0, Armas.CALIDADES.size() - 1) if e is Dictionary else 0
		var cosa := {}
		if Armas.DATOS.has(id):
			cosa = {"id": id, "calidad": calidad}
		elif Lanzables.DATOS.has(id) and int(e.get("n", 0)) > 0:
			cosa = {"id": id, "calidad": calidad, "n": int(e.n)}
		if cosa.is_empty():
			continue
		# la durabilidad (Armas.nuevas): las partidas que le quedan y si ya ha salido en esta (las de antes del 9 nov no
		# lo traen: sin estrenar)
		cosa.quedan = maxi(0, Armas.quedan_de(e))
		if e.get("usada", false):
			cosa.usada = true
		equipo.append(cosa)
	s.baul_equipo = equipo
	# Un guardado de antes de los montones pequeños del baúl (15 nov; la Fase 3 del dueño): los arrojables que pasan de
	# lo que cabe ahora en una casilla (Objetos.monton_arrojables) se reparten en varias, una sola vez (después, si se
	# quitan talentos, los montones que ya están no se tocan). Los objetos no hace falta: el baúl guarda cuántos hay y se
	# reparten solos (Objetos.monton). No se pierde nada aunque pase de las 32 casillas: lo que sobra se queda, y no se
	# puede guardar más hasta sacarlo (lo pidió el dueño)
	if not leido.has("montones_baul"):
		var repartido := []
		for e in s.baul_equipo:
			if not e.has("n"):
				repartido.append(e)
				continue
			var tope := Objetos.monton_arrojables(s, e.id, e.calidad)
			var n: int = e.n
			while n > 0:
				var trozo: Dictionary = e.duplicate()
				trozo.n = mini(n, tope)
				repartido.append(trozo)
				n -= trozo.n
		s.baul_equipo = repartido
		s.montones_baul = true
	# la fregona mejorada (15 nov: Objetos.apartar_fregona). Un guardado de antes no la tiene apartada: la mejor de su
	# baúl pasa a su sitio, una sola vez
	if not s.fregona is Dictionary or s.fregona.is_empty() or int(s.fregona.get("calidad", 0)) <= 0:
		s.fregona = {}
	else:
		var f := {"id": Armas.SIEMPRE.cuerpo, "calidad": clampi(int(s.fregona.calidad), 1, Armas.CALIDADES.size() - 1),
			"quedan": maxi(0, Armas.quedan_de(s.fregona))}
		if s.fregona.get("usada", false):
			f.usada = true
		s.fregona = f
	if not leido.has("fregona"):
		Objetos.apartar_fregona(s, {})
	# las recetas del banco de trabajo se quitaron del juego el 25 oct: las armas creadas del baúl ("baul_armas"), las
	# recetas aprendidas ("recetas") y las creadas alguna vez ("creadas", de Colecciones) de un guardado viejo no se
	# leen (solo se copia lo que está en NUEVO) y desaparecen al volver a escribirlo
	for id in s.edificios:
		s.edificios[id] = EDIFICIO.merged(s.edificios[id], true)
		for clave in ["partidas", "victorias", "mejor_planta", "alerta_max", "alerta"]:
			s.edificios[id][clave] = int(s.edificios[id][clave])
	for id in s.garajes:
		s.garajes[id] = GARAJE.duplicate(true).merged(s.garajes[id], true)   # (copia: las constantes no se pueden cambiar)
		if not s.garajes[id].records is Dictionary:
			s.garajes[id].records = {}
		for c in s.garajes[id].records:
			s.garajes[id].records[c] = int(s.garajes[id].records[c])
	# Un guardado de antes de las Colecciones (sin "encontrados"): lo encontrado se saca del baúl, una sola vez (en
	# cuanto se escriba, el archivo ya lleva la clave)
	if not leido.has("encontrados"):
		for id in s.baul:
			if s.baul[id] > 0:
				s.encontrados.append(id)
	return s


# Lo que hay en un archivo de guardado: un Dictionary, o null si no existe o está roto
static func leer(de: String) -> Variant:
	if not FileAccess.file_exists(de):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(de))


# Como leer, pero si está roto o sin terminar de escribir, vale la copia de la vez anterior (.bak)
static func leer_entero(de: String) -> Variant:
	var leido = leer(de)
	if not leido is Dictionary:
		leido = leer(de + ".bak")
	return leido if leido is Dictionary else null


static var escrituras := 0   # cuántas veces se ha escrito: Bestiario mira si el archivo cambió desde que lo leyó
static var ajustes_comunes := {}   # los últimos ajustes escritos en guardado-ajustes.json

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
	escribir_json(archivo, s)
	# los ajustes comunes, solo si han cambiado (o aún no está su archivo)
	if s.ajustes != ajustes_comunes or not FileAccess.file_exists(ruta_ajustes()):
		escribir_json(ruta_ajustes(), {"hueco": hueco, "ajustes": s.ajustes})
		ajustes_comunes = s.ajustes.duplicate(true)
	ajustes_leidos = s.ajustes.duplicate(true)
	ajustes_de = archivo
	escrituras += 1


# Escribe "datos" en el archivo "a" sin que se pueda quedar a medias (ver escribir)
static func escribir_json(a: String, datos: Dictionary) -> void:
	var tmp := a + ".tmp"
	var bak := a + ".bak"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(datos, "\t"))
		var bien := f.get_error() == OK
		f.close()   # cerrar asegura que todo está ya en el disco
		if bien:
			if FileAccess.file_exists(a):
				if FileAccess.file_exists(bak):
					DirAccess.remove_absolute(bak)
				DirAccess.rename_absolute(a, bak)
			DirAccess.rename_absolute(tmp, a)


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


# ── Los huecos de guardado ──

# El archivo del hueco "n"
static func ruta(n: int) -> String:
	return base + (".json" if n == 1 else "-%d.json" % n)


static func ruta_ajustes() -> String:
	return base + "-ajustes.json"


# El hueco que se usó la última vez (el de guardado-ajustes.json; 1 si aún no está)
static func hueco_guardado() -> int:
	var comunes = leer_entero(ruta_ajustes())
	return clampi(int(comunes.get("hueco", 1)), 1, HUECOS) if comunes is Dictionary else 1


# Otros archivos (la prueba con --captura): su hueco 1 y sus ajustes
static func usar(nueva_base: String) -> void:
	base = nueva_base
	hueco = 1
	archivo = ruta(1)
	ajustes_comunes = {}


# Pasa al hueco "n" y lo apunta para la próxima vez
static func elegir_hueco(n: int) -> void:
	var ajustes: Dictionary = cargar().ajustes
	hueco = n
	archivo = ruta(n)
	escribir_json(ruta_ajustes(), {"hueco": n, "ajustes": ajustes})
	ajustes_comunes = ajustes.duplicate(true)


# Si el hueco "n" tiene algo guardado
static func hueco_usado(n: int) -> bool:
	return leer_entero(ruta(n)) != null


# Borra el hueco "n" para siempre (con su copia): queda vacío, para empezar de cero
static func borrar_hueco(n: int) -> void:
	for a in [ruta(n), ruta(n) + ".bak", ruta(n) + ".tmp"]:
		if FileAccess.file_exists(a):
			DirAccess.remove_absolute(a)
	escrituras += 1          # lo que Bestiario recordaba ya no vale
	Tutoriales.vistos_de = ""   # ni lo de Tutoriales
