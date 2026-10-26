# Las plantas del edificio (como src/building.js del juego JS; diseño en docs/MAPA.md)
#
# Cada planta es un pasillo largo con cuatro puertas, dos a cada lado (A y B arriba, C y D abajo). Detrás de
# cada una hay un "sitio" aparte: un apartamento o el apartamento de la jefa (cerrado con llave); en el centro
# comercial, una tienda (tienda.gd) o la del jefe, cerrada con la tarjeta que lleva el guardia. En la planta
# baja, la puerta A es la sala de mantenimiento, donde empieza la partida, y por la puerta de su derecha se va a
# las viviendas de los supervivientes rescatados (viviendas.gd). En el pasillo hay además un
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
# La sala de mantenimiento: tres estancias de 10 × 10 casillas, una al lado de otra (el vestuario, el despacho y el
# taller), con un tabique de una casilla entre ellas y el muro de fuera alrededor (1152 × 448, algo más ancha que la
# pantalla: la cámara se mueve un poco al andar)
const SALA_ESTANCIA := 10
const SALA_COLS := 2 + SALA_ESTANCIA * 3 + 2 + 2
const SALA_FILAS := 2 + SALA_ESTANCIA + 2
const SALA_PUERTA := 6            # la fila de arriba de las dos puertas de dentro (a media altura, como la de las viviendas)
# Cada estancia, de izquierda a derecha: su uso (el estilo de su suelo y su pared, en mapa.gd) y su nombre. La del
# medio va primero (la habitación 0): ahí está la entrada y ahí empieza la partida
const SALA_ESTANCIAS := [{"uso": "vestuario", "nombre": "Vestuario"}, {"uso": "despacho", "nombre": "Despacho"},
	{"uso": "taller", "nombre": "Taller"}]
const EXPO_COLS := 46            # la sala de exposición del modo pruebas
const EXPO_FILAS := 153           # (alargada para los zombis, los minijefes, el gerente, el Glotón, el Gymbro, el bombero y el científico jefe, y para los muebles de la sala de mantenimiento)
const ARMAS_CASILLAS := 34       # la sala de pruebas (cuadrada): del centro a la pared caben 15 casillas
const AZOTEA_COLS := 44           # la azotea del centro comercial, como la del juego JS (rooms.js, ROOF_COLS)
const AZOTEA_FILAS := 30
# El helipuerto (helipuerto.png, de tools/azotea.py): una plataforma un poco más alta que el suelo, siempre en el
# centro de la azotea, con la rampa a la izquierda (de cara a la escalera por la que se llega). Es el ring del jefe
# final: espera arriba y, en cuanto sube Johnny, una valla cierra la rampa hasta que cae (mapa.gd y partida.gd)
const PLATAFORMA := Vector2(512, 384)   # lo de arriba, 16 × 12 casillas (con su borde, que no se pisa)
const PLATAFORMA_ALTO := 24.0           # lo que se eleva: la cara de delante, que se ve por debajo
const PLATAFORMA_BORDE := 8.0           # el borde de arriba: choca, como la cara
const RAMPA := Vector2(128, 96)         # largo y ancho de la rampa (con sus dos barandillas)
const BARANDILLA := 6.0                 # el grosor de cada barandilla de la rampa
const PLATAFORMA_LIBRE := 64.0          # lo que queda libre alrededor de la plataforma, para rodearla andando
# La capa de choque 4 ("bordes bajos"): el borde del helipuerto. Para a los que andan (Johnny, los zombis, los jefes y
# los acompañantes la llevan en su máscara), no a lo que vuela (las balas y lo que se lanza solo miran la capa 1)
const CAPA_BORDE := 8
# Los aparatos de la azotea de cada edificio (catalogo.gd): cuántos de cada uno [mínimo, máximo]
const APARATOS := {
	"centro": {"acunit": [2, 3], "airhandler": [1, 2], "vent": [3, 4]},
	"apartamentos": {"watertank": [1, 2], "antennas": [2, 3], "clothesline": [2, 3], "vent": [1, 2]},
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
#                    "jefe", "mantenimiento", "viviendas", "expo" o "armas"), nombre, ancho, alto, apt (el apartamento, si lo es),
#                    dueno (el plano de las salas rectangulares), muebles (muebles.gd), surtido (qué variante
#                    de cada mueble lleva), salidas, zombis, limpio, visitado}. El pasillo lleva además su estilo
#                    (el del edificio: "pasillo" o "galeria", ver mapa.gd), sus apliques y, en el centro comercial,
#                    los escaparates de las tiendas de arriba ({x, tienda})
#   mantenimiento    el sitio de la sala de mantenimiento (-1 si no hay), viviendas, el de las viviendas de los
#                    rescatados (viviendas.gd), expo, el de la exposición, y armas, el de la sala de pruebas
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
# aparece allí), cerrojo ("", "llave", "jefa", "nunca"), aviso}; las puertas de tienda de la pared de arriba
# llevan "neon" (el tipo de tienda): su letrero de neón encima (neon.gd). Las puertas de los pisos llevan "placa" (su
# letra, o "llave" la de la sala de mantenimiento): una placa junto a la puerta; y el ascensor, "planta" (0 = la
# baja): el número grande que se ve a su lado (puerta.gd)
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
		"jefa_muerta": false, "mantenimiento": -1, "viviendas": -1, "expo": -1, "armas": -1, "edificio": edificio,
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
	# la jefa vive en el 4ºB; en las demás plantas, detrás de una puerta al azar (la del Gymbro, de las de arriba, A o B:
	# su gimnasio tiene la puerta abajo y todas sus máquinas en las otras tres paredes, muebles.gd, fijos)
	var posibles: Array = libres.filter(func(h): return h.dir == "arriba") if planta.jefe == "gymbro" else libres
	var de_jefa: Dictionary = posibles[rng.randi() % posibles.size()]
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
				"cerrojo": "", "aviso": "", "placa": "llave"})
			continue
		var jefe: bool = h == de_jefa
		# la puerta del apartamento está en el lado que da al pasillo
		var lado := "abajo" if h.dir == "arriba" else "arriba"
		var apt := Tienda.generar(rng.randi(), tipo_tienda, jefe, lado) if tiendas else Apartamento.generar(jefe, lado)
		if jefe and mini.has("tienda"):
			# la tienda de un minijefe se llama según quién esté (la Oficina de seguridad del antidisturbios...)
			nombre = mini.tienda
			apt.salas[0].nombre = mini.tienda
		# (planta.jefe, no su_jefe: cuando la portera sale por defecto, su_jefe llega vacío)
		if jefe and Catalogo.SALAS.has("jefe-" + planta.jefe):
			apt.tipo = planta.jefe   # sus muebles, los suyos (el Taller de costura lleno de maniquíes; el Glotón,
			# ninguno; el Gymbro, sus máquinas de gimnasio; la portera, sus cubos de basura y su carro de limpieza; el jefe
			# de bomberos, ninguno)
		# (las tiendas son "apartamento" para la partida: un sitio normal que hay que limpiar; "tienda" dice de qué)
		# Los pisos solo llevan los muebles que el dueño ha puesto a mano, cada uno en su sitio (Muebles.de_piso)
		var piso := not jefe and not tiendas
		var sitio := {"tipo": "jefe" if jefe else "apartamento", "nombre": nombre, "apt": apt, "tienda": tipo_tienda,
			"ancho": apt.cols * CASILLA, "alto": apt.filas * CASILLA, "salidas": [], "zombis": [], "limpio": false,
			"visitado": false, "muebles": Muebles.de_piso(apt) if piso else Muebles.de_apartamento(apt, rng), "surtido": rng.randi()}
		# los peligros de la tienda (el frío de la cámara, el fuego de la cocina, el agua con corriente)
		sitio.peligros = Peligros.de_tienda(sitio) if tipo_tienda != "" and not jefe else []
		if jefe and su_jefe == "gloton":
			# la habitación del Glotón (sin muebles, ver arriba): el suelo y las paredes llenos de su porquería, que quema
			sitio.peligros = Peligros.del_gloton(sitio)
		if jefe and su_jefe == "gymbro":
			# el gimnasio del Gymbro (lleno de máquinas, ver arriba): mancuernas por el suelo, que hacen caer a Johnny
			apt.salas[0].nombre = "Gimnasio"
			sitio.peligros = Peligros.del_gymbro(sitio)
		if jefe and planta.jefe == "portera":
			# el cuarto de la limpieza de la portera (ver arriba): cubos por el suelo, que hacen caer a Johnny
			apt.salas[0].nombre = "Cuarto de la limpieza"
			sitio.peligros = Peligros.de_la_portera(sitio)
		if jefe and planta.jefe == "bombero":
			# la habitación del jefe de bomberos (sin muebles, ver arriba): en llamas por todo el borde menos la puerta
			apt.salas[0].nombre = "Apartamento en llamas"
			sitio.peligros = Peligros.del_bombero(sitio)
		if jefe and planta.jefe in Peligros.LUZ_JEFE.jefes:
			# y a las cuatro habitaciones de los jefes de los Apartamentos, la misma luz blanca fija (la del gimnasio)
			sitio.peligros.append(Peligros.luz_de_jefe(sitio))
		var idx: int = planta.sitios.size()
		planta.sitios.append(sitio)
		if tipo_tienda == "joyeria":
			# la cámara acorazada (joyeria.gd): su sala, la puerta que la separa de la sala de venta (cerrada hasta
			# que se abra con la tarjeta dorada o con la alarma) y dónde anda la tarjeta dorada (la lleva el guardia)
			var acorazada: Dictionary = apt.salas.filter(func(s): return s.uso == "acorazada")[0]
			planta.joyeria = {"sitio": idx, "sala": acorazada.id, "abierta": false, "dorada": "guardia", "suelo": {},
				"alarma": -1.0, "puerta": apt.puertas.filter(func(p): return p.a == acorazada.id or p.b == acorazada.id)[0]}
		sitio.salidas.append({"dir": apt.entrada.lado, "en": (apt.entrada.c + 1) * CASILLA, "tipo": "puerta",
			"a": 0, "vuelta": pasillo.salidas.size(), "cerrojo": "", "aviso": ""})
		var puerta := {"dir": h.dir, "en": h.en, "tipo": "puerta", "a": idx, "vuelta": 0, "cerrojo": "",
			"aviso": ""}
		if tipo_tienda == "":
			puerta.placa = h.letra   # los pisos, como en un edificio de verdad: su letra en una placa junto a la puerta
		if tipo_tienda != "" and h.dir == "arriba" and not (jefe and not mini.is_empty()):
			# en la pared de arriba se ve la fachada de la tienda: su letrero de neón y un escaparate a cada lado de la
			# puerta (mapa.gd)
			puerta.neon = tipo_tienda
			for lado_x in [-1, 1]:
				pasillo.escaparates.append({"x": h.en + lado_x * ESCAPARATE_A, "tienda": tipo_tienda})
		if jefe:
			puerta.cerrojo = "llave"   # la llave o la tarjeta: se abren igual (ver partida.gd)
			puerta.aviso = "Cerrada: hace falta una tarjeta de acceso" if ed.cerrojo == "tarjeta" else "Cerrada con llave"
		pasillo.salidas.append(puerta)

	pasillo.salidas.append({"dir": "arriba", "en": ancho / 2, "tipo": "ascensor", "a": -1, "vuelta": -1,
		"cerrojo": "nunca", "aviso": "El ascensor está averiado", "planta": num - 1})
	# por donde se ha llegado (en la planta baja, el portal del edificio) y por donde se sigue subiendo
	pasillo.salidas.append({"dir": "izquierda", "en": alto / 2, "tipo": "llegada", "a": -1, "vuelta": -1, "cerrojo": "nunca",
		"aviso": "El edificio sigue infestado: aún no puedes irte" if baja else "Por ahí has subido"})
	pasillo.salidas.append({"dir": "derecha", "en": alto / 2, "tipo": "escaleras", "a": -1, "vuelta": -1,
		"cerrojo": "jefa", "aviso": "Bloqueadas: acaba antes con " + planta.el_jefe})
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
	delante_escaparates.append(Rect2(ancho / 2.0 - 130, MURO, 130, 130))   # (y el cartel de la planta, a la izquierda del ascensor)
	pasillo.muebles = Muebles.de_sala(ed.pasillo, {"cols": PASILLO_COLS, "filas": PASILLO_FILAS, "dueno": pasillo.dueno},
		pasillo.salidas, [Vector2(MURO + 40, alto / 2.0), Vector2(ancho - MURO - 40, alto / 2.0)], rng,
		delante_escaparates)
	if baja:
		planta.armas = planta.sitios.size()
		planta.sitios.append(sala_armas(planta.mantenimiento))
		planta.expo = planta.sitios.size()
		planta.sitios.append(exposicion(planta.armas))

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
	# Las viviendas de los rescatados, detrás de la puerta de la derecha de la sala de mantenimiento (la segunda de sus
	# salidas)
	if baja:
		planta.viviendas = planta.sitios.size()
		planta.sitios.append(Viviendas.generar(rng.randi(), planta.mantenimiento, 1))
		planta.sitios[planta.mantenimiento].salidas[1].a = planta.viviendas
	return planta


# La azotea (la última planta del centro comercial y de los Apartamentos, como en el juego JS): un solo sitio grande
# y abierto, sin pasillo ni tiendas, con el jefe final. Suelo de hormigón, el murete alrededor (mapa.gd, "azotea"), el
# helipuerto elevado en el centro (PLATAFORMA) y los aparatos sueltos alrededor (en el centro, aire acondicionado,
# climatizadoras y extractores; en los Apartamentos, depósitos de agua, antenas, tendederos y extractores; la chimenea
# de ladrillo ya no sale). Se llega por la izquierda, por la escalera, que se cierra detrás para siempre; a la
# derecha, la escalera de incendios, cerrada hasta que caiga el jefe: por ahí se acaba el edificio. Es un sitio "jefe":
# el jefe aparece al llegar, encima del helipuerto, y espera ahí a Johnny; al caer, se abren las escaleras
# (partida.gd), como en el piso de la portera.
static func azotea(num: int, edificio: String, su_jefe: String) -> Dictionary:
	var ed: Dictionary = Edificios.datos(edificio)
	var jefe: String = su_jefe if su_jefe != "" else ed.jefe
	var planta := {"num": num, "nombre": "Azotea", "azotea": true, "sitios": [], "llave": {"sitio": -1, "pos": Vector2.ZERO},
		"tiene_llave": false, "jefa_muerta": false, "mantenimiento": -1, "viviendas": -1, "expo": -1, "armas": -1, "edificio": edificio, "jefe": jefe,
		"el_jefe": ed.el_final if jefe == ed.get("final", "") else ed.el_jefe, "superviviente": {}, "cientifico": {}}
	var ancho := AZOTEA_COLS * CASILLA
	var alto := AZOTEA_FILAS * CASILLA
	var sitio := {"tipo": "jefe", "azotea": true, "nombre": "Azotea", "ancho": ancho, "alto": alto, "estilo": "azotea",
		"dueno": Muebles.plano_rectangular(AZOTEA_COLS, AZOTEA_FILAS), "zombis": [], "limpio": false, "visitado": true,
		"surtido": rng.randi(), "manchas": [], "helipuerto": Vector2(ancho / 2.0, alto / 2.0)}   # (el centro de lo de arriba)
	sitio.salidas = [
		{"dir": "izquierda", "en": alto / 2, "tipo": "llegada", "a": -1, "vuelta": -1, "cerrojo": "nunca",
			"aviso": "Ya no hay vuelta atrás"},
		{"dir": "derecha", "en": alto / 2, "tipo": "escaleras", "incendios": true, "a": -1, "vuelta": -1, "cerrojo": "jefa",
			"aviso": "Bloqueada: acaba antes con " + planta.el_jefe},
	]
	sitio.muebles = aparatos(sitio, edificio)
	# manchas de sangre sueltas (las de manchas-suelo.png), fuera del helipuerto
	var huella := huella_helipuerto(sitio)
	for i in rng.randi_range(5, 8):
		var pos := Vector2(rng.randf_range(MURO + 60, ancho - MURO - 60), rng.randf_range(MURO + 60, alto - MURO - 60))
		if not huella.any(func(h): return h.grow(40.0).has_point(pos)) and lejos_de_muebles(sitio, pos, 20.0):
			sitio.manchas.append({"pos": pos, "dibujo": rng.randi() % 10, "giro": rng.randi() % 4, "espejo": rng.randf() < 0.5})
	planta.sitios.append(sitio)
	return planta


# Los aparatos sueltos por la azotea, cada uno lejos de los demás (para que se pueda pasar entre ellos, también el
# jefe), de las dos puertas y del murete. Del helipuerto, más: su base, a PLATAFORMA_LIBRE (para rodearlo andando), y
# su dibujo, que sube desde la base (los de abajo, altos, se pintarían encima de la plataforma), sin tocarlo
static func aparatos(sitio: Dictionary, edificio: String) -> Array:
	var puestos := []
	var puertas := [Vector2(MURO, sitio.alto / 2.0), Vector2(sitio.ancho - MURO, sitio.alto / 2.0)]
	var huella := huella_helipuerto(sitio)
	var cuantos: Dictionary = APARATOS.get(edificio, APARATOS.centro)
	for tipo in cuantos:
		var dibujo_alto: float = load("res://assets/sprites/mueble-%s.png" % tipo).get_height() * 2.0
		for i in rng.randi_range(cuantos[tipo][0], cuantos[tipo][1]):
			var p: Dictionary = Catalogo.MUEBLES[tipo]
			for intento in 60:
				var x := roundf(rng.randf_range(MURO + 50 + p.len / 2.0, sitio.ancho - MURO - 50 - p.len / 2.0) / 2.0) * 2.0
				var y := roundf(rng.randf_range(MURO + 40, sitio.alto - MURO - 60 - p.dep) / 2.0) * 2.0
				var m := Muebles.nuevo(tipo, {"lado": "arriba", "base": y}, x, 0)
				var r := Muebles.hueco(m)
				var dibujo := Rect2(r.position.x, r.end.y - dibujo_alto, r.size.x, dibujo_alto)
				if huella.any(func(h): return h.grow(PLATAFORMA_LIBRE).intersects(r) or h.grow(8.0).intersects(dibujo)):
					continue
				if puertas.any(func(d): return d.distance_to(r.get_center()) < 220.0):
					continue
				if puestos.any(func(o): return Muebles.hueco(o).grow(90.0).intersects(r)):
					continue
				puestos.append(m)
				break
	return puestos


# Lo de arriba del helipuerto (con su borde), en unidades
static func plataforma(sitio: Dictionary) -> Rect2:
	return Rect2(sitio.helipuerto - PLATAFORMA / 2.0, PLATAFORMA)


# La rampa, pegada a la izquierda de la plataforma y en medio de ese lado (con sus barandillas)
static func rampa(sitio: Dictionary) -> Rect2:
	var p := plataforma(sitio)
	return Rect2(p.position.x - RAMPA.x, sitio.helipuerto.y - RAMPA.y / 2.0, RAMPA.x, RAMPA.y)


# Lo que ocupa el helipuerto en el suelo: la plataforma y la rampa, cada una con su cara de delante
static func huella_helipuerto(sitio: Dictionary) -> Array:
	return [plataforma(sitio).grow_side(SIDE_BOTTOM, PLATAFORMA_ALTO), rampa(sitio).grow_side(SIDE_BOTTOM, PLATAFORMA_ALTO)]


# La sala de mantenimiento, donde empieza la partida: tres estancias una al lado de otra (SALA_ESTANCIAS), hecha como
# un apartamento ("apt": su plano por casillas, sus habitaciones y sus puertas, como las viviendas), así cada estancia
# lleva su suelo y su pared (mapa.gd) y arriba sale en cuál se está. Ninguna tiene niebla: ya están todas vistas.
#   - el vestuario, a la izquierda: el plato de ducha en la esquina, la taquilla de las skins en medio de lo que queda
#     de la pared de arriba (parte 11; la pone mapa.gd), el lavabo con su espejo y el váter de lado en la pared de la
#     izquierda y el banco largo suelto, abajo a la derecha, sin tapar la puerta
#   - el despacho, en medio: la puerta del pasillo abajo y la mesa del ordenador en medio de la pared de arriba (fases 6
#     y 7), con el corcho colgado a su izquierda (mapa.gd) y la papelera a su derecha
#   - el taller, a la derecha: la estantería con botes, el banco de trabajo y el baúl (fase 7b; los dos, mapa.gd) en la
#     pared de arriba, el carrito del conserje en la de la derecha y, en esa misma pared, la puerta de las viviendas de
#     los supervivientes rescatados (viviendas.gd; adónde lleva lo pone generar)
# Entre estancia y estancia, una puerta sin hoja, como las de dentro de los pisos. Y manchas de sangre por el suelo.
# "vuelta" es su puerta en el pasillo.
static func mantenimiento(vuelta: int) -> Dictionary:
	var ancho := SALA_COLS * CASILLA
	var alto := SALA_FILAS * CASILLA
	var dueno := PackedInt32Array()
	dueno.resize(SALA_COLS * SALA_FILAS)
	dueno.fill(-1)
	var salas := []
	var puertas := []
	for k in SALA_ESTANCIAS.size():
		var e: Dictionary = SALA_ESTANCIAS[k]
		var sala := {"id": [1, 0, 2][k], "uso": e.uso, "nombre": e.nombre, "c0": 2 + k * (SALA_ESTANCIA + 1), "f0": 2,
			"ancho": SALA_ESTANCIA, "fondo": SALA_ESTANCIA, "puertas": [], "casillas": SALA_ESTANCIA * SALA_ESTANCIA}
		sala.centro = Vector2(sala.c0 + SALA_ESTANCIA / 2.0, sala.f0 + SALA_ESTANCIA / 2.0) * CASILLA
		for f in range(sala.f0, sala.f0 + SALA_ESTANCIA):
			for c in range(sala.c0, sala.c0 + SALA_ESTANCIA):
				dueno[f * SALA_COLS + c] = sala.id
		salas.append(sala)
	salas.sort_custom(func(a, b): return a.id < b.id)
	# las dos puertas de dentro, en los tabiques del despacho: al vestuario y al taller
	for otra in [1, 2]:
		var c: int = salas[0].c0 - 1 if otra == 1 else salas[0].c0 + SALA_ESTANCIA
		var p := {"a": otra, "b": 0, "c": c, "f": SALA_PUERTA, "ancho": 1, "fondo": 2}
		for f in [SALA_PUERTA, SALA_PUERTA + 1]:
			dueno[f * SALA_COLS + c] = -2
		puertas.append(p)
		salas[0].puertas.append(p)
		salas[otra].puertas.append(p)
	var apt := {"cols": SALA_COLS, "filas": SALA_FILAS, "dueno": dueno, "salas": salas, "puertas": puertas, "jefe": false,
		"tipo": "mantenimiento"}
	var sitio := {"tipo": "mantenimiento", "nombre": "Mantenimiento", "apt": apt, "ancho": ancho, "alto": alto,
		"zombis": [], "limpio": true, "visitado": false, "surtido": rng.randi(), "manchas": [],
		"vistas": {0: true, 1: true, 2: true}}
	sitio.salidas = [{"dir": "abajo", "en": ancho / 2, "tipo": "puerta", "a": 0, "vuelta": vuelta, "cerrojo": "",
		"aviso": ""}, {"dir": "derecha", "en": alto / 2, "tipo": "puerta", "a": -1, "vuelta": 0, "cerrojo": "", "aviso": ""}]
	# Los muebles (los que se usan, el banco, el baúl, el ordenador y la taquilla, los pone mapa.gd)
	var arriba := {"lado": "arriba", "base": MURO}
	var izquierda := {"lado": "izquierda", "base": MURO}
	sitio.muebles = [
		Muebles.nuevo("showertray", arriba, MURO + Catalogo.MUEBLES.showertray.len / 2.0, 1),
		Muebles.nuevo("staffsink", izquierda, 240, 1),   # (el espejo sube mucho: más arriba se montaría en la ducha)
		Muebles.nuevo("stafftoilet", izquierda, 332, 1),
		Muebles.nuevo("lockerbench", {"lado": "arriba", "base": 302}, 270, 1),
		Muebles.nuevo("wastebasket", arriba, 650, 0),
		Muebles.nuevo("canshelf", arriba, 820, 2),
		Muebles.nuevo("janitorcart", {"lado": "derecha", "base": ancho - MURO}, 330, 2),
	]
	# manchas de sangre sueltas (10 dibujos en manchas-suelo.png), por el suelo de las tres estancias, lejos de la pared
	# de arriba y de los muebles (con su propio dado: así no cambian los pisos que salen detrás)
	var dado := RandomNumberGenerator.new()
	dado.seed = sitio.surtido
	for i in dado.randi_range(6, 9):
		for intento in 30:
			var pos := Vector2(dado.randf_range(MURO + 40, ancho - MURO - 40), dado.randf_range(MURO + 110, alto - MURO - 40))
			var aqui := dueno[int(pos.y / CASILLA) * SALA_COLS + int(pos.x / CASILLA)]
			if aqui < 0 or not despejado(apt, pos, 24.0, aqui) or not lejos_de_muebles(sitio, pos, 30.0):
				continue
			sitio.manchas.append({"pos": pos, "dibujo": dado.randi() % 10, "giro": dado.randi() % 4, "espejo": dado.randf() < 0.5})
			break
	return sitio


# La sala de exposición (el botón del panel de la sala de pruebas): todos los muebles y todos los zombis, para ver
# cómo quedan. Lo que se expone lo pone mapa.gd. Su puerta lleva a la sala de pruebas ("pruebas").
static func exposicion(pruebas: int) -> Dictionary:
	var ancho := EXPO_COLS * CASILLA
	var alto := EXPO_FILAS * CASILLA
	return {"tipo": "expo", "nombre": "Exposición", "ancho": ancho, "alto": alto, "muebles": [],
		"dueno": Muebles.plano_rectangular(EXPO_COLS, EXPO_FILAS), "zombis": [], "limpio": true, "visitado": true,
		"surtido": 0, "salidas": [{"dir": "abajo", "en": ancho / 2, "tipo": "puerta", "a": pruebas, "vuelta": 0,
		"cerrojo": "", "aviso": ""}]}


# La sala de pruebas (tecla F11): una habitación vacía y con luz, con un zombi que no se muere en el centro y el baúl
# de pruebas. Lo que tiene dentro lo pone sala_armas.gd. Su puerta vuelve al sitio del que se vino (partida.gd, cruzar;
# "mant" solo sirve de relleno: en las plantas de arriba es -1).
static func sala_armas(mant: int) -> Dictionary:
	var lado := ARMAS_CASILLAS * CASILLA
	return {"tipo": "armas", "nombre": "Sala de pruebas", "ancho": lado, "alto": lado, "muebles": [],
		"dueno": Muebles.plano_rectangular(ARMAS_CASILLAS, ARMAS_CASILLAS), "zombis": [], "limpio": true,
		"visitado": true, "surtido": 0, "salidas": [{"dir": "abajo", "en": lado / 2, "tipo": "puerta", "a": mant,
		"vuelta": 0, "cerrojo": "", "aviso": ""}]}


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
