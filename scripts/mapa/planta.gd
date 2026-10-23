# Las plantas del edificio (como src/building.js del juego JS; diseño en docs/MAPA.md)
#
# Cada planta es un pasillo largo con cuatro puertas, dos a cada lado (A y B arriba, C y D abajo). Detrás de
# cada una hay un "sitio" aparte: un apartamento o el apartamento de la jefa (cerrado con llave); en el centro
# comercial, una tienda (tienda.gd) o la del jefe, cerrada con la tarjeta que lleva el guardia. En la planta
# baja, la puerta A es la sala de mantenimiento, donde empieza la partida. En el pasillo hay además un
# ascensor averiado, por la izquierda la puerta por la que se ha llegado y, a la derecha, las escaleras, que
# no se abren hasta acabar con la jefa.
#
# Aquí solo se decide qué hay y dónde (son datos); lo dibuja y lo monta mapa.gd.
class_name Planta

const CASILLA := 32
const MURO := 64                  # grosor de los muros de fuera
const PASILLO_COLS := 56
const PASILLO_FILAS := 12
const PUERTA_A := 14 * CASILLA    # a qué distancia de cada punta del pasillo están las puertas
const ESCAPARATE_A := 100         # en el centro comercial, a qué distancia de su puerta va cada escaparate
const ESCAPARATE_MEDIO := 58      # la mitad del ancho del escaparate más ancho (escaparate-electronica, 57 píxeles)
const PLANTAS := 5                # planta baja y cuatro más (en el centro comercial, la última es la azotea)
const SALA_COLS := 30             # la sala de mantenimiento: lo que se ve en la pantalla base (960 × 640)
const SALA_FILAS := 20
const SITIO_TALLER := Rect2(MURO, MURO, 540 - MURO, 150)   # lo que se guarda para el banco, el ordenador, el baúl y la taquilla
const SITIO_VECINOS := Rect2(540, MURO, 892 - 540, 170)    # y para los supervivientes rescatados (supervivientes.gd)
const SITIO_CENTRO := Rect2(540, 250, 892 - 540, 170)      # y los del centro comercial, con el hueco de lo suyo
const EXPO_COLS := 46            # la sala de exposición del modo pruebas
const EXPO_FILAS := 139           # (alargada para los zombis, los minijefes, el gerente, el Glotón, el Gymbro, el bombero y el científico jefe)
const AZOTEA_COLS := 44           # la azotea del centro comercial, como la del juego JS (rooms.js, ROOF_COLS)
const AZOTEA_FILAS := 30
const HELIPUERTO_RADIO := 160.0   # lo que ocupa el helipuerto pintado (helipuerto.png): ahí no va ningún aparato
# Los aparatos de la azotea de cada edificio (catalogo.gd): cuántos de cada uno [mínimo, máximo]
const APARATOS := {
	"centro": {"acunit": [2, 3], "airhandler": [1, 2], "chimney": [2, 3], "vent": [3, 4]},
	"apartamentos": {"watertank": [1, 2], "antennas": [2, 3], "clothesline": [2, 3], "chimney": [2, 3], "vent": [1, 2]},
}

# El superviviente del centro comercial de esta partida: {planta, tienda, sala} (lo pone supervivientes.gd al
# empezar). En esa planta sale su tienda y se esconde en esa habitación de ella. Vacío: como siempre
static var tienda_fija := {}
# La joyería del centro comercial (parte 9): una por partida, en esta planta (la pone partida.gd al empezar; 0 =
# ninguna). Va en la segunda puerta normal de su planta, nunca en la del jefe ni en la del superviviente
static var joyeria_planta := 0

# Coste de cada zombi para "comprar" los de un apartamento con un presupuesto. Los lentos son baratos: van en grupo.
const COSTE := {"lento": 0.5, "normal": 1.0, "rapido": 1.0, "venenoso": 2.0, "explosivo": 2.0, "tentaculos": 3.0,
	"vigilante": 1.5, "dependienta": 1.5}
# Presupuesto de un apartamento: "base" más "por_nivel" por cada nivel (el nivel sube con la planta y con el
# orden del apartamento dentro de ella). Son los números del juego JS, equilibrados con partidas simuladas.
const BASE := 5.0
const POR_NIVEL := 1.1
const LEJOS_PUERTA := 340.0       # ningún zombi espera a menos de esto de la puerta de entrada

static var rng := RandomNumberGenerator.new()
# Si no es 0, las plantas salen siempre iguales: cada una con esta semilla más su número (el reto del día y las pruebas)
static var semilla := 0


static func nombre_planta(num: int) -> String:
	return "Planta baja" if num == 1 else "%dª planta" % (num - 1)


static func nombre_puerta(num: int, letra: String) -> String:
	return "Bajo " + letra if num == 1 else "%dº%s" % [num - 1, letra]


# Genera la planta número "num". Devuelve:
#   num, nombre      número (1 = baja) y nombre de la planta
#   sitios           [pasillo, lo de detrás de A, B, C y D]. Cada sitio: {tipo ("pasillo", "apartamento",
#                    "jefe", "mantenimiento" o "expo"), nombre, ancho, alto, apt (el apartamento, si lo es),
#                    dueno (el plano de las salas rectangulares), muebles (muebles.gd), surtido (qué variante
#                    de cada mueble lleva), salidas, zombis, limpio, visitado}. El pasillo lleva además su estilo
#                    (el del edificio: "pasillo" o "galeria", ver mapa.gd), sus apliques y, en el centro comercial,
#                    los escaparates de las tiendas de arriba ({x, tienda})
#   mantenimiento    el sitio de la sala de mantenimiento (-1 si no hay) y expo, el de la exposición
#   llave            {sitio, pos} dónde está la llave del apartamento de la jefa (con tarjeta, sitio -1 hasta que
#                    el guardia la suelte al caer; con la Alerta 5, igual: la lleva un vecino, {"llave": true} en zombis)
#   guardia          solo con tarjeta: {vivo, vida (-1: entera), alerta, silbidos} el guardia de seguridad del
#                    pasillo, que lleva la tarjeta (zombi_guardia.gd)
#   edificio         el id del edificio (edificios.gd)
#   tiene_llave, jefa_muerta
#   cientifico       {sitio, pos, cogida} dónde está el científico muerto con la página del dosier (historia.gd)
#   superviviente    {sitio, sala, puerta, pos} el baño (y su puerta, de apt.puertas) donde se esconde el
#                    superviviente si en esta partida le toca esta planta (lo decide supervivientes.gd). Ese baño
#                    no lleva zombis: si no, nadie podría limpiar el piso
# Cada salida: {dir ("arriba", "abajo", "izquierda", "derecha"), en (posición a lo largo de su muro), tipo
# ("puerta", "ascensor", "llegada", "escaleras"), a (sitio al que lleva), vuelta (salida por la que se
# aparece allí), cerrojo ("", "llave", "jefa", "nunca"), aviso, letrero}; las puertas de tienda de la pared de arriba
# llevan "neon" (el tipo de tienda): en vez del cartel, su letrero de neón (neon.gd)
# "su_jefe": el zombi jefe de esta planta (el minijefe que le toca; "" = el del edificio)
static func generar(num: int, edificio := "apartamentos", su_jefe := "") -> Dictionary:
	if semilla != 0:
		rng.seed = semilla + num
		seed(semilla + num)   # también el dado de siempre: lo usan los shuffle() de las plantas y las tiendas
	else:
		rng.randomize()
	var ed: Dictionary = Edificios.datos(edificio)
	if ed.get("azotea", false) and num == PLANTAS:
		return azotea(num, edificio, su_jefe)
	var tiendas: bool = ed.generador == "tienda"
	var mini: Dictionary = Edificios.MINIJEFES.get(su_jefe, {})
	var planta := {"num": num, "nombre": nombre_planta(num), "sitios": [], "llave": {}, "tiene_llave": false,
		"jefa_muerta": false, "mantenimiento": -1, "expo": -1, "edificio": edificio,
		"jefe": su_jefe if su_jefe != "" else ed.jefe, "el_jefe": mini.get("el", ed.el_jefe)}
	var ancho := PASILLO_COLS * CASILLA
	var alto := PASILLO_FILAS * CASILLA
	var pasillo := {"tipo": "pasillo", "nombre": planta.nombre, "ancho": ancho, "alto": alto, "salidas": [],
		"zombis": [], "limpio": true, "visitado": true, "dueno": Muebles.plano_rectangular(PASILLO_COLS, PASILLO_FILAS),
		"surtido": rng.randi(), "estilo": ed.pasillo, "escaparates": []}
	planta.sitios.append(pasillo)

	var huecos := [{"letra": "A", "dir": "arriba", "en": PUERTA_A}, {"letra": "B", "dir": "arriba", "en": ancho - PUERTA_A},
		{"letra": "C", "dir": "abajo", "en": PUERTA_A}, {"letra": "D", "dir": "abajo", "en": ancho - PUERTA_A}]
	var baja := num == 1
	var libres := huecos.filter(func(h): return not (baja and h.letra == "A"))
	# la jefa vive en el 4ºB; en las demás plantas, detrás de una puerta al azar
	var de_jefa: Dictionary = libres[rng.randi() % libres.size()]
	for h in libres:
		if nombre_puerta(num, h.letra) == "4ºB" and not tiendas:
			de_jefa = h
	# en el centro comercial, cada puerta una tienda distinta; la primera tienda normal, la del superviviente si le
	# toca esta planta (tienda_fija) o, si no, una de las que tienen aseo
	var tipos: Array = Tienda.TIPOS.keys().filter(func(t): return t != "joyeria")   # (la joyería no se sortea)
	tipos.shuffle()
	var tipo_de := {}
	var con_aseo: Array = tipos.filter(func(t): return "bano" in Tienda.TIPOS[t].salas)
	var fija: Dictionary = tienda_fija if tiendas and tienda_fija.get("planta", -1) == num else {}
	var primera: String = fija.tienda if not fija.is_empty() else con_aseo[0]
	for h in libres.filter(func(h): return h != de_jefa) + [de_jefa]:
		if tipo_de.is_empty():
			tipo_de[h.letra] = primera
		elif tiendas and joyeria_planta == num and h != de_jefa and not "joyeria" in tipo_de.values():
			tipo_de[h.letra] = "joyeria"   # la joyería de la partida: la segunda puerta normal de su planta
		else:
			tipo_de[h.letra] = tipos.filter(func(t): return t not in tipo_de.values())[0]

	for h in huecos:
		var nombre := nombre_puerta(num, h.letra)
		var tipo_tienda: String = tipo_de[h.letra] if tiendas and h in libres else ""
		if tipo_tienda != "":
			nombre = Tienda.TIPOS[tipo_tienda].nombre
		if h not in libres:
			planta.mantenimiento = planta.sitios.size()
			planta.sitios.append(mantenimiento(pasillo.salidas.size()))
			pasillo.salidas.append({"dir": h.dir, "en": h.en, "tipo": "puerta", "a": planta.mantenimiento, "vuelta": 0,
				"cerrojo": "", "aviso": "", "letrero": "Mantenimiento"})
			continue
		var jefe: bool = h == de_jefa
		# la puerta del apartamento está en el lado que da al pasillo
		var lado := "abajo" if h.dir == "arriba" else "arriba"
		var apt := Tienda.generar(rng.randi(), tipo_tienda, jefe, lado) if tiendas else Apartamento.generar(rng.randi(), jefe, lado)
		if jefe and mini.has("tienda"):
			# la tienda de un minijefe se llama según quién esté (la Oficina de seguridad del antidisturbios...)
			nombre = mini.tienda
			apt.salas[0].nombre = mini.tienda
		if jefe and Catalogo.SALAS.has("jefe-" + su_jefe):
			apt.tipo = su_jefe   # sus muebles, los suyos (el Taller de costura lleno de maniquíes; el Glotón, solo lámparas;
			# el Gymbro, sus máquinas de gimnasio)
		# (las tiendas son "apartamento" para la partida: un sitio normal que hay que limpiar; "tienda" dice de qué)
		var sitio := {"tipo": "jefe" if jefe else "apartamento", "nombre": nombre, "apt": apt, "tienda": tipo_tienda,
			"ancho": apt.cols * CASILLA, "alto": apt.filas * CASILLA, "salidas": [], "zombis": [], "limpio": false,
			"visitado": false, "muebles": Muebles.de_apartamento(apt, rng), "surtido": rng.randi()}
		# los peligros de la tienda (el frío de la cámara, el fuego de la cocina, el agua con corriente)
		sitio.peligros = Peligros.de_tienda(sitio) if tipo_tienda != "" and not jefe else []
		if jefe and su_jefe == "gloton":
			# la habitación del Glotón (solo con lámparas, ver arriba): el suelo y las paredes llenos de su porquería, que quema
			sitio.peligros = Peligros.del_gloton(sitio)
		if jefe and su_jefe == "gymbro":
			# el gimnasio del Gymbro (lleno de máquinas, ver arriba): mancuernas por el suelo, que hacen caer a Johnny
			apt.salas[0].nombre = "Gimnasio"
			sitio.peligros = Peligros.del_gymbro(sitio)
		var idx: int = planta.sitios.size()
		planta.sitios.append(sitio)
		if tipo_tienda == "joyeria":
			# la cámara acorazada (joyeria.gd): su sala, la puerta que la separa de la sala de venta (cerrada hasta
			# que se abra con la tarjeta dorada o con la alarma) y dónde anda la tarjeta dorada (la lleva el guardia)
			var acorazada: Dictionary = apt.salas.filter(func(s): return s.uso == "acorazada")[0]
			planta.joyeria = {"sitio": idx, "sala": acorazada.id, "abierta": false, "dorada": "guardia", "suelo": {},
				"alarma": -1.0, "puerta": apt.puertas.filter(func(p): return p.a == acorazada.id or p.b == acorazada.id)[0]}
		sitio.salidas.append({"dir": apt.entrada.lado, "en": (apt.entrada.c + 1) * CASILLA, "tipo": "puerta",
			"a": 0, "vuelta": pasillo.salidas.size(), "cerrojo": "", "aviso": "", "letrero": planta.nombre})
		var puerta := {"dir": h.dir, "en": h.en, "tipo": "puerta", "a": idx, "vuelta": 0, "cerrojo": "",
			"aviso": "", "letrero": nombre}
		if tipo_tienda != "" and h.dir == "arriba" and not (jefe and not mini.is_empty()):
			# en la pared de arriba se ve la fachada de la tienda: su letrero de neón (en vez del cartel) y un
			# escaparate a cada lado de la puerta (mapa.gd)
			puerta.neon = tipo_tienda
			for lado_x in [-1, 1]:
				pasillo.escaparates.append({"x": h.en + lado_x * ESCAPARATE_A, "tienda": tipo_tienda})
		if jefe:
			puerta.cerrojo = "llave"   # la llave o la tarjeta: se abren igual (ver partida.gd)
			puerta.aviso = "Cerrada: hace falta una tarjeta de acceso" if ed.cerrojo == "tarjeta" else "Cerrada con llave"
		pasillo.salidas.append(puerta)

	pasillo.salidas.append({"dir": "arriba", "en": ancho / 2, "tipo": "ascensor", "a": -1, "vuelta": -1,
		"cerrojo": "nunca", "aviso": "El ascensor está averiado", "letrero": "Averiado"})
	# por donde se ha llegado (en la planta baja, el portal del edificio) y por donde se sigue subiendo
	pasillo.salidas.append({"dir": "izquierda", "en": alto / 2, "tipo": "llegada", "a": -1, "vuelta": -1, "cerrojo": "nunca",
		"aviso": "El edificio sigue infestado: aún no puedes irte" if baja else "Por ahí has subido",
		"letrero": "Portal" if baja else "Bajada"})
	pasillo.salidas.append({"dir": "derecha", "en": alto / 2, "tipo": "escaleras", "a": -1, "vuelta": -1,
		"cerrojo": "jefa", "aviso": "Bloqueadas: acaba antes con " + planta.el_jefe, "letrero": "Escaleras"})
	# los apliques de la pared de arriba, cada 230 unidades y sin tapar puertas: son las luces del pasillo
	# (algunos fallan de vez en cuando), como en src/rooms.js
	pasillo.apliques = []
	var x := MURO + 130
	while x < ancho - MURO - 60:
		if pasillo.salidas.all(func(s): return s.dir != "arriba" or absf(s.en - x) > 90) \
				and pasillo.escaparates.all(func(e): return absf(e.x - x) > ESCAPARATE_MEDIO + 20):
			pasillo.apliques.append({"x": x, "semilla": rng.randf(), "parpadea": rng.randf() < 0.3})
		x += 230
	# los muebles del pasillo, sin tapar ninguna puerta ni escaparate y dejando ir de una punta a la otra
	var delante_escaparates: Array = pasillo.escaparates.map(func(e): return Rect2(e.x - ESCAPARATE_MEDIO, MURO,
		ESCAPARATE_MEDIO * 2, 60))
	pasillo.muebles = Muebles.de_sala(ed.pasillo, {"cols": PASILLO_COLS, "filas": PASILLO_FILAS, "dueno": pasillo.dueno},
		pasillo.salidas, [Vector2(MURO + 40, alto / 2.0), Vector2(ancho - MURO - 40, alto / 2.0)], rng,
		delante_escaparates)
	if baja:
		planta.expo = planta.sitios.size()
		planta.sitios.append(exposicion(planta.mantenimiento))

	# Dificultad: los apartamentos normales, en un orden al azar, llevan cada vez más zombis
	var normales := []
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "apartamento":
			normales.append(i)
	normales.shuffle()
	# El baño del superviviente, en un apartamento normal al azar (como floor.survivor de src/building.js); en el
	# centro comercial, en una tienda que tenga aseo (no todas tienen) o, si le toca esta planta a uno de los suyos,
	# en la habitación de su tienda (la cámara del restaurante...), cerrada por la puerta que da a la sala de venta
	var con_bano: Array = normales.filter(func(i): return planta.sitios[i].apt.salas.any(func(s): return s.uso == "bano"))
	var de_superv: int = con_bano[rng.randi() % con_bano.size()] if not con_bano.is_empty() else normales[rng.randi() % normales.size()]
	var de_su_tienda: Array = normales.filter(func(i): return planta.sitios[i].tienda == fija.tienda) if not fija.is_empty() else []
	if not de_su_tienda.is_empty():
		de_superv = de_su_tienda[0]
	var escondite: String = fija.sala if not de_su_tienda.is_empty() else "bano"
	var banos: Array = planta.sitios[de_superv].apt.salas.filter(func(s):
		return s.uso == escondite and (s.puertas.size() == 1 or escondite != "bano"))
	planta.superviviente = {}
	if not banos.is_empty():
		var bano: Dictionary = banos[rng.randi() % banos.size()]
		var en := sitio_libre(planta.sitios[de_superv], bano, Vector2.INF, [], 18.0)
		var puertas: Array = bano.puertas.filter(func(p): return p.a == 0 or p.b == 0) if not de_su_tienda.is_empty() else bano.puertas
		planta.superviviente = {"sitio": de_superv, "sala": bano.id, "puerta": puertas[0],
			"pos": bano.centro if en == Vector2.INF else en}
	for orden in normales.size():
		var sitio: Dictionary = planta.sitios[normales[orden]]
		sitio.zombis = horda(sitio, orden + 1, num, planta.superviviente.sala if normales[orden] == de_superv and not planta.superviviente.is_empty() else -1)
		sitio.armaritos = armaritos(sitio)

	# Con tarjeta, no hay llave en el suelo: la lleva el guardia de seguridad, que ronda el pasillo
	if ed.cerrojo == "tarjeta":
		planta.llave = {"sitio": -1, "pos": Vector2.ZERO}
		planta.guardia = {"vivo": true, "vida": -1, "alerta": false, "silbidos": 0}
	# La llave de la jefa, en una habitación (que no sea el salón ni un baño) de un apartamento normal
	var donde: int = normales[rng.randi() % normales.size()]
	var salas: Array = planta.sitios[donde].apt.salas.filter(func(s): return s.uso != "salon" and s.uso != "tienda" and s.uso != "bano")
	var sala: Dictionary = salas[rng.randi() % salas.size()]
	# en el centro de la habitación o, si ahí hay un mueble, en otro sitio libre de ella
	var pos: Vector2 = sala.centro
	if not lejos_de_muebles(planta.sitios[donde], pos, 26.0):
		pos = sitio_libre(planta.sitios[donde], sala, Vector2.INF, [])
		if pos == Vector2.INF:
			pos = sala.centro
	if ed.cerrojo == "llave":
		planta.llave = {"sitio": donde, "pos": pos}
		# con la Alerta 5 (alerta.gd), no está en el suelo: la lleva un vecino que espera allí y la suelta al caer
		if Alerta.guardia() > 1.0:
			planta.llave = {"sitio": -1, "pos": Vector2.ZERO}
			planta.sitios[donde].zombis.append({"tipo": "normal", "pos": pos, "llave": true})
	# El científico muerto de Velaria (historia.gd), en una habitación de otro apartamento normal si se puede (que
	# no sea el baño del superviviente). Si sale o no, lo decide la partida: solo si su página falta por encontrar
	var otros: Array = normales.filter(func(i): return i != donde)
	var de_cientifico: int = otros[rng.randi() % otros.size()] if not otros.is_empty() else donde
	var cuartos: Array = planta.sitios[de_cientifico].apt.salas.filter(func(s):
		# (ni en la cámara acorazada de la joyería, que está cerrada)
		return ((planta.superviviente.is_empty() or de_cientifico != planta.superviviente.sitio
			or s.id != planta.superviviente.sala) and s.uso != "acorazada"))
	var cuarto: Dictionary = cuartos[rng.randi() % cuartos.size()]
	var en := sitio_libre(planta.sitios[de_cientifico], cuarto, Vector2.INF, [], 40.0)
	planta.cientifico = {"sitio": de_cientifico, "pos": cuarto.centro if en == Vector2.INF else en, "cogida": false}
	return planta


# La azotea (la última planta del centro comercial y de los Apartamentos, como en el juego JS): un solo sitio grande
# y abierto, sin pasillo ni tiendas, con el jefe final. Suelo de hormigón, el murete alrededor (mapa.gd, "azotea"), el
# helipuerto pintado y los aparatos sueltos (en el centro, aire acondicionado, climatizadoras, chimeneas y
# extractores; en los Apartamentos, depósitos de agua, antenas, tendederos, chimeneas y extractores), que sirven para
# cubrirse. Se llega por la izquierda, por la escalera, que se cierra detrás para siempre; a la derecha, la escalera de
# incendios, cerrada hasta que caiga el jefe: por ahí se acaba el edificio. Es un sitio "jefe": el jefe aparece al
# llegar y, al caer, se abren las escaleras (partida.gd), como en el piso de la portera.
static func azotea(num: int, edificio: String, su_jefe: String) -> Dictionary:
	var ed: Dictionary = Edificios.datos(edificio)
	var jefe: String = su_jefe if su_jefe != "" else ed.jefe
	var planta := {"num": num, "nombre": "Azotea", "azotea": true, "sitios": [], "llave": {"sitio": -1, "pos": Vector2.ZERO},
		"tiene_llave": false, "jefa_muerta": false, "mantenimiento": -1, "expo": -1, "edificio": edificio, "jefe": jefe,
		"el_jefe": ed.el_final if jefe == ed.get("final", "") else ed.el_jefe, "superviviente": {}, "cientifico": {}}
	var ancho := AZOTEA_COLS * CASILLA
	var alto := AZOTEA_FILAS * CASILLA
	var sitio := {"tipo": "jefe", "azotea": true, "nombre": "Azotea", "ancho": ancho, "alto": alto, "estilo": "azotea",
		"dueno": Muebles.plano_rectangular(AZOTEA_COLS, AZOTEA_FILAS), "zombis": [], "limpio": false, "visitado": true,
		"surtido": rng.randi(), "manchas": [], "helipuerto": Vector2(roundf(ancho * 0.6 / 2.0) * 2.0, roundf(alto * 0.54 / 2.0) * 2.0)}
	sitio.salidas = [
		{"dir": "izquierda", "en": alto / 2, "tipo": "llegada", "a": -1, "vuelta": -1, "cerrojo": "nunca",
			"aviso": "Ya no hay vuelta atrás", "letrero": "Escalera"},
		{"dir": "derecha", "en": alto / 2, "tipo": "escaleras", "incendios": true, "a": -1, "vuelta": -1, "cerrojo": "jefa",
			"aviso": "Bloqueada: acaba antes con " + planta.el_jefe, "letrero": "Incendios"},
	]
	sitio.muebles = aparatos(sitio, edificio)
	# manchas de sangre sueltas (las de manchas-suelo.png), fuera del helipuerto
	for i in rng.randi_range(5, 8):
		var pos := Vector2(rng.randf_range(MURO + 60, ancho - MURO - 60), rng.randf_range(MURO + 60, alto - MURO - 60))
		if pos.distance_to(sitio.helipuerto) > HELIPUERTO_RADIO and lejos_de_muebles(sitio, pos, 20.0):
			sitio.manchas.append({"pos": pos, "dibujo": rng.randi() % 10, "giro": rng.randi() % 4, "espejo": rng.randf() < 0.5})
	planta.sitios.append(sitio)
	return planta


# Los aparatos sueltos por la azotea, cada uno lejos de los demás (para que se pueda pasar entre ellos, también el
# jefe), del helipuerto, de las dos puertas y del murete
static func aparatos(sitio: Dictionary, edificio: String) -> Array:
	var puestos := []
	var puertas := [Vector2(MURO, sitio.alto / 2.0), Vector2(sitio.ancho - MURO, sitio.alto / 2.0)]
	var cuantos: Dictionary = APARATOS.get(edificio, APARATOS.centro)
	for tipo in cuantos:
		for i in rng.randi_range(cuantos[tipo][0], cuantos[tipo][1]):
			var p: Dictionary = Catalogo.MUEBLES[tipo]
			for intento in 60:
				var x := roundf(rng.randf_range(MURO + 50 + p.len / 2.0, sitio.ancho - MURO - 50 - p.len / 2.0) / 2.0) * 2.0
				var y := roundf(rng.randf_range(MURO + 40, sitio.alto - MURO - 60 - p.dep) / 2.0) * 2.0
				var m := Muebles.nuevo(tipo, {"lado": "arriba", "base": y}, x, 0)
				var r := Muebles.hueco(m)
				var cerca := Vector2(clampf(sitio.helipuerto.x, r.position.x, r.end.x), clampf(sitio.helipuerto.y, r.position.y, r.end.y))
				if cerca.distance_to(sitio.helipuerto) < HELIPUERTO_RADIO + 30.0:
					continue
				if puertas.any(func(d): return d.distance_to(r.get_center()) < 220.0):
					continue
				if puestos.any(func(o): return Muebles.hueco(o).grow(90.0).intersects(r)):
					continue
				puestos.append(m)
				break
	return puestos


# La sala de mantenimiento, donde empieza la partida: una sala sencilla con su puerta abajo, unos pocos
# muebles y manchas en el suelo. La mitad izquierda de la pared de arriba queda libre: ahí irán el banco de
# trabajo, el ordenador y el baúl (fases 6 y 7; en el juego JS, en x = 135, 240 y 340) y la taquilla (parte 11), y
# hasta los vecinos no se deja nada suelto: junto a la taquilla no sale ningún mueble de sobra. "vuelta" es su
# puerta en el pasillo.
static func mantenimiento(vuelta: int) -> Dictionary:
	var ancho := SALA_COLS * CASILLA
	var alto := SALA_FILAS * CASILLA
	var sitio := {"tipo": "mantenimiento", "nombre": "Mantenimiento", "ancho": ancho, "alto": alto,
		"dueno": Muebles.plano_rectangular(SALA_COLS, SALA_FILAS), "zombis": [], "limpio": true, "visitado": false,
		"surtido": rng.randi(), "manchas": []}
	sitio.salidas = [{"dir": "abajo", "en": ancho / 2, "tipo": "puerta", "a": 0, "vuelta": vuelta, "cerrojo": "",
		"aviso": "", "letrero": "Pasillo"}]
	sitio.muebles = Muebles.de_sala("mantenimiento", {"cols": SALA_COLS, "filas": SALA_FILAS, "dueno": sitio.dueno},
		sitio.salidas, [Vector2(ancho / 2.0, alto - MURO - 40), Vector2(ancho / 2.0, alto / 2.0)], rng,
		[SITIO_TALLER, SITIO_VECINOS, SITIO_CENTRO])
	# manchas de sangre sueltas (10 dibujos en manchas-suelo.png), lejos de la pared de arriba
	for i in rng.randi_range(6, 10):
		sitio.manchas.append({"pos": Vector2(rng.randf_range(MURO + 60, ancho - MURO - 60),
			rng.randf_range(MURO + 150, alto - MURO - 50)), "dibujo": rng.randi() % 10, "giro": rng.randi() % 4,
			"espejo": rng.randf() < 0.5})
	return sitio


# La sala de exposición del modo pruebas (tecla F9): todos los muebles y todos los zombis, para ver cómo
# quedan. Lo que se expone lo pone mapa.gd. Su puerta lleva a la sala de mantenimiento.
static func exposicion(mant: int) -> Dictionary:
	var ancho := EXPO_COLS * CASILLA
	var alto := EXPO_FILAS * CASILLA
	return {"tipo": "expo", "nombre": "Exposición", "ancho": ancho, "alto": alto, "muebles": [],
		"dueno": Muebles.plano_rectangular(EXPO_COLS, EXPO_FILAS), "zombis": [], "limpio": true, "visitado": true,
		"surtido": 0, "salidas": [{"dir": "abajo", "en": ancho / 2, "tipo": "puerta", "a": mant, "vuelta": 0,
		"cerrojo": "", "aviso": "", "letrero": "Mantenimiento"}]}


# Los zombis de un apartamento: ya están dentro, dormidos y repartidos por las habitaciones según su
# tamaño. Devuelve [{tipo, pos}]. "orden" es el puesto del apartamento dentro de la planta (1, 2, 3).
# "sin" es la habitación que se queda sin zombis (el baño del superviviente), o -1
static func horda(sitio: Dictionary, orden: int, num: int, sin := -1) -> Array:
	var apt: Dictionary = sitio.apt
	var nivel := orden + (num - 1)
	# Los tipos más peligrosos van apareciendo según se avanza
	var tipos := ["lento", "normal"]
	if nivel >= 2:
		tipos += ["rapido", "venenoso"]
	if nivel >= 3:
		tipos.append("explosivo")
	if nivel >= 4:
		tipos.append("tentaculos")
	# en las tiendas del centro comercial, además, los suyos: la dependienta desde la planta baja (una por tienda
	# como mucho) y el vigilante desde la 1ª planta
	if sitio.get("tienda", "") != "":
		tipos.append("dependienta")
		if num >= 2:
			tipos.append("vigilante")
		if sitio.tienda == "joyeria":   # la joyería tiene más seguridad: más vigilantes
			tipos += ["vigilante", "vigilante"]
	var area := 0
	for s in apt.salas:
		area += s.casillas
	# en los pisos grandes hay más, pero no en proporción: si no, los de 3 dormitorios serían eternos
	# (con la Alerta 1, más; con el reto del día "Casa llena", el doble)
	var presupuesto := (BASE + nivel * POR_NIVEL) * clampf(area / 700.0, 0.8, 1.4) * Alerta.mas_zombis() * Reto.mas_zombis()
	var peso := func(s: Dictionary) -> float:
		return s.casillas * (0.5 if s.uso == "bano" else 1.0)   # en los baños, pocos
	var total := 0.0
	# (ni su aseo; ni la cámara acorazada de la joyería: con la puerta blindada cerrada no podrían salir)
	# (sin == -1 es "ninguna": por eso lo que no tiene "dueno_bano" se compara con -2, y no con -1, que lo dejaría fuera)
	var salas: Array = apt.salas.filter(func(s): return s.id != sin and s.get("dueno_bano", -2) != sin and s.uso != "acorazada")
	for s in salas:
		total += peso.call(s)
	var salida: Dictionary = sitio.salidas[0]
	var puerta := Vector2(salida.en, MURO + 52 if salida.dir == "arriba" else sitio.alto - MURO - 52)

	var zombis := []
	for s in salas:
		# lo que le toca a esta habitación; el pico que sobra se echa a suertes
		var parte: float = presupuesto * peso.call(s) / total
		var queda := floorf(parte * 2.0) / 2.0 + (0.5 if rng.randf() < fmod(parte * 2.0, 1.0) else 0.0)
		while queda > 0.0:
			var caben := tipos.filter(func(t): return COSTE[t] <= queda)
			if caben.is_empty():
				break
			var pos := sitio_libre(sitio, s, puerta, zombis)
			if pos == Vector2.INF:
				break
			var tipo: String = caben[rng.randi() % caben.size()]
			zombis.append({"tipo": tipo, "pos": pos})
			queda -= COSTE[tipo]
			if tipo == "dependienta":
				tipos.erase("dependienta")
	return zombis


# Un armarito con un botiquín colgado en la pared de arriba de cada baño (Armarito en src/props.js del JS): es
# lo único que cura. Va lo más centrado posible, sin tapar una puerta y mejor donde no haya un mueble debajo; si
# lo hay, se coge desde delante del mueble ("alcance"). Cada uno: {x, y (el pie de la pared), alcance, cogido}
static func armaritos(sitio: Dictionary) -> Array:
	var apt: Dictionary = sitio.apt
	var lista := []
	for s in apt.salas.filter(func(s): return s.uso == "bano"):
		var mejor := {}
		for c in range(s.c0 + 1, s.c0 + s.ancho - 1):
			# la pared de encima (y sus vecinas) tiene que ser muro, no puerta ni suelo
			var muro := true
			for dc in [-1, 0, 1]:
				if apt.dueno[(s.f0 - 1) * apt.cols + c + dc] >= 0 or apt.dueno[(s.f0 - 1) * apt.cols + c + dc] == -2:
					muro = false
			if not muro:
				continue
			var x := (c + 0.5) * CASILLA
			var alcance := 70.0
			for m in sitio.muebles:
				var h := Muebles.hueco(m)
				if m.zona == s.id and h.position.y < s.f0 * CASILLA + 8 and absf(m.x - x) < h.size.x / 2.0 + 14.0:
					alcance = maxf(alcance, h.end.y - s.f0 * CASILLA + 60.0)
			var nota := absf(x - (s.c0 + s.ancho / 2.0) * CASILLA) + (200.0 if alcance > 70.0 else 0.0)
			if mejor.is_empty() or nota < mejor.nota:
				mejor = {"x": x, "y": float(s.f0 * CASILLA), "alcance": alcance, "cogido": false, "nota": nota}
		if not mejor.is_empty():
			lista.append(mejor)
	return lista


# Un punto de la habitación con sitio alrededor, lejos de la entrada, de los muebles y de los otros zombis
static func sitio_libre(sitio: Dictionary, sala: Dictionary, puerta: Vector2, otros: Array, hueco := 26.0) -> Vector2:
	var apt: Dictionary = sitio.apt
	for i in 200:
		var pos := Vector2(sala.c0 * CASILLA + rng.randf() * sala.ancho * CASILLA,
			sala.f0 * CASILLA + rng.randf() * sala.fondo * CASILLA)
		if not despejado(apt, pos, hueco, sala.id):
			continue
		if not lejos_de_muebles(sitio, pos, hueco + 4.0):
			continue
		if puerta != Vector2.INF and pos.distance_to(puerta) < LEJOS_PUERTA:
			continue
		if otros.any(func(z): return z.pos.distance_to(pos) < 60.0):
			continue
		# ni encima del fuego ni del agua con corriente de una tienda (peligros.gd)
		if [Vector2.ZERO, Vector2(-hueco, 0), Vector2(hueco, 0), Vector2(0, -hueco), Vector2(0, hueco)].any(
				func(d): return Peligros.encima(sitio, pos + d)):
			continue
		return pos
	return Vector2.INF


# ¿Queda el punto a más de "radio" de todos los muebles del sitio?
static func lejos_de_muebles(sitio: Dictionary, pos: Vector2, radio: float) -> bool:
	for m in sitio.get("muebles", []):
		if Muebles.hueco(m).grow(radio).has_point(pos):
			return false
	return true


# ¿Están el punto y lo que tiene alrededor (a "radio") dentro de esa habitación?
static func despejado(apt: Dictionary, pos: Vector2, radio: float, id: int) -> bool:
	for d in [Vector2.ZERO, Vector2(-radio, -radio), Vector2(radio, -radio), Vector2(-radio, radio), Vector2(radio, radio)]:
		var c := int((pos.x + d.x) / CASILLA)
		var f := int((pos.y + d.y) / CASILLA)
		if c < 0 or f < 0 or c >= apt.cols or f >= apt.filas or apt.dueno[f * apt.cols + c] != id:
			return false
	return true
