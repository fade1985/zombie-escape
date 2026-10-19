# Las plantas del edificio (como src/building.js del juego JS; diseño en docs/MAPA.md)
#
# Cada planta es un pasillo largo con cuatro puertas, dos a cada lado (A y B arriba, C y D abajo). Detrás de
# cada una hay un "sitio" aparte: un apartamento o el apartamento de la jefa (cerrado con llave). En la planta
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
const PLANTAS := 5                # planta baja y cuatro más (la azotea, con el jefe final, aún no existe)
const SALA_COLS := 30             # la sala de mantenimiento: lo que se ve en la pantalla base (960 × 640)
const SALA_FILAS := 20
const SITIO_TALLER := Rect2(MURO, MURO, 480 - MURO, 150)   # lo que se guarda para el ordenador, el baúl y el banco
const EXPO_COLS := 46            # la sala de exposición del modo pruebas
const EXPO_FILAS := 72

# Coste de cada zombi para "comprar" los de un apartamento con un presupuesto. Los lentos son baratos: van en grupo.
const COSTE := {"lento": 0.5, "normal": 1.0, "rapido": 1.0, "venenoso": 2.0, "explosivo": 2.0, "tentaculos": 3.0}
# Presupuesto de un apartamento: "base" más "por_nivel" por cada nivel (el nivel sube con la planta y con el
# orden del apartamento dentro de ella). Son los números del juego JS, equilibrados con partidas simuladas.
const BASE := 5.0
const POR_NIVEL := 1.1
const LEJOS_PUERTA := 340.0       # ningún zombi espera a menos de esto de la puerta de entrada

static var rng := RandomNumberGenerator.new()


static func nombre_planta(num: int) -> String:
	return "Planta baja" if num == 1 else "%dª planta" % (num - 1)


static func nombre_puerta(num: int, letra: String) -> String:
	return "Bajo " + letra if num == 1 else "%dº%s" % [num - 1, letra]


# Genera la planta número "num". Devuelve:
#   num, nombre      número (1 = baja) y nombre de la planta
#   sitios           [pasillo, lo de detrás de A, B, C y D]. Cada sitio: {tipo ("pasillo", "apartamento",
#                    "jefe", "mantenimiento" o "expo"), nombre, ancho, alto, apt (el apartamento, si lo es),
#                    dueno (el plano de las salas rectangulares), muebles (muebles.gd), surtido (qué variante
#                    de cada mueble lleva), salidas, zombis, limpio, visitado}
#   mantenimiento    el sitio de la sala de mantenimiento (-1 si no hay) y expo, el de la exposición
#   llave            {sitio, pos} dónde está la llave del apartamento de la jefa
#   tiene_llave, jefa_muerta
# Cada salida: {dir ("arriba", "abajo", "izquierda", "derecha"), en (posición a lo largo de su muro), tipo
# ("puerta", "ascensor", "llegada", "escaleras"), a (sitio al que lleva), vuelta (salida por la que se
# aparece allí), cerrojo ("", "llave", "jefa", "nunca"), aviso, letrero}
static func generar(num: int) -> Dictionary:
	rng.randomize()
	var planta := {"num": num, "nombre": nombre_planta(num), "sitios": [], "llave": {}, "tiene_llave": false,
		"jefa_muerta": false, "mantenimiento": -1, "expo": -1}
	var ancho := PASILLO_COLS * CASILLA
	var alto := PASILLO_FILAS * CASILLA
	var pasillo := {"tipo": "pasillo", "nombre": planta.nombre, "ancho": ancho, "alto": alto, "salidas": [],
		"zombis": [], "limpio": true, "visitado": true, "dueno": Muebles.plano_rectangular(PASILLO_COLS, PASILLO_FILAS),
		"surtido": rng.randi()}
	planta.sitios.append(pasillo)

	var huecos := [{"letra": "A", "dir": "arriba", "en": PUERTA_A}, {"letra": "B", "dir": "arriba", "en": ancho - PUERTA_A},
		{"letra": "C", "dir": "abajo", "en": PUERTA_A}, {"letra": "D", "dir": "abajo", "en": ancho - PUERTA_A}]
	var baja := num == 1
	var libres := huecos.filter(func(h): return not (baja and h.letra == "A"))
	# la jefa vive en el 4ºB; en las demás plantas, detrás de una puerta al azar
	var de_jefa: Dictionary = libres[rng.randi() % libres.size()]
	for h in libres:
		if nombre_puerta(num, h.letra) == "4ºB":
			de_jefa = h

	for h in huecos:
		var nombre := nombre_puerta(num, h.letra)
		if h not in libres:
			planta.mantenimiento = planta.sitios.size()
			planta.sitios.append(mantenimiento(pasillo.salidas.size()))
			pasillo.salidas.append({"dir": h.dir, "en": h.en, "tipo": "puerta", "a": planta.mantenimiento, "vuelta": 0,
				"cerrojo": "", "aviso": "", "letrero": "Mantenimiento"})
			continue
		var jefe: bool = h == de_jefa
		# la puerta del apartamento está en el lado que da al pasillo
		var apt := Apartamento.generar(rng.randi(), jefe, "abajo" if h.dir == "arriba" else "arriba")
		var sitio := {"tipo": "jefe" if jefe else "apartamento", "nombre": nombre, "apt": apt,
			"ancho": apt.cols * CASILLA, "alto": apt.filas * CASILLA, "salidas": [], "zombis": [], "limpio": false,
			"visitado": false, "muebles": Muebles.de_apartamento(apt, rng), "surtido": rng.randi()}
		var idx: int = planta.sitios.size()
		planta.sitios.append(sitio)
		sitio.salidas.append({"dir": apt.entrada.lado, "en": (apt.entrada.c + 1) * CASILLA, "tipo": "puerta",
			"a": 0, "vuelta": pasillo.salidas.size(), "cerrojo": "", "aviso": "", "letrero": planta.nombre})
		var puerta := {"dir": h.dir, "en": h.en, "tipo": "puerta", "a": idx, "vuelta": 0, "cerrojo": "",
			"aviso": "", "letrero": nombre}
		if jefe:
			puerta.cerrojo = "llave"
			puerta.aviso = "Cerrada con llave"
		pasillo.salidas.append(puerta)

	pasillo.salidas.append({"dir": "arriba", "en": ancho / 2, "tipo": "ascensor", "a": -1, "vuelta": -1,
		"cerrojo": "nunca", "aviso": "El ascensor está averiado", "letrero": "Averiado"})
	# por donde se ha llegado (en la planta baja, el portal del edificio) y por donde se sigue subiendo
	pasillo.salidas.append({"dir": "izquierda", "en": alto / 2, "tipo": "llegada", "a": -1, "vuelta": -1, "cerrojo": "nunca",
		"aviso": "El edificio sigue infestado: aún no puedes irte" if baja else "Por ahí has subido",
		"letrero": "Portal" if baja else "Bajada"})
	pasillo.salidas.append({"dir": "derecha", "en": alto / 2, "tipo": "escaleras", "a": -1, "vuelta": -1,
		"cerrojo": "jefa", "aviso": "Bloqueadas: acaba antes con la portera", "letrero": "Escaleras"})
	# los apliques de la pared de arriba, cada 230 unidades y sin tapar puertas: son las luces del pasillo
	# (algunos fallan de vez en cuando), como en src/rooms.js
	pasillo.apliques = []
	var x := MURO + 130
	while x < ancho - MURO - 60:
		if pasillo.salidas.all(func(s): return s.dir != "arriba" or absf(s.en - x) > 90):
			pasillo.apliques.append({"x": x, "semilla": rng.randf(), "parpadea": rng.randf() < 0.3})
		x += 230
	# los muebles del pasillo, sin tapar ninguna puerta y dejando ir de una punta a la otra
	pasillo.muebles = Muebles.de_sala("pasillo", {"cols": PASILLO_COLS, "filas": PASILLO_FILAS, "dueno": pasillo.dueno},
		pasillo.salidas, [Vector2(MURO + 40, alto / 2.0), Vector2(ancho - MURO - 40, alto / 2.0)], rng)
	if baja:
		planta.expo = planta.sitios.size()
		planta.sitios.append(exposicion(planta.mantenimiento))

	# Dificultad: los apartamentos normales, en un orden al azar, llevan cada vez más zombis
	var normales := []
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "apartamento":
			normales.append(i)
	normales.shuffle()
	for orden in normales.size():
		var sitio: Dictionary = planta.sitios[normales[orden]]
		sitio.zombis = horda(sitio, orden + 1, num)

	# La llave de la jefa, en una habitación (que no sea el salón ni un baño) de un apartamento normal
	var donde: int = normales[rng.randi() % normales.size()]
	var salas: Array = planta.sitios[donde].apt.salas.filter(func(s): return s.uso != "salon" and s.uso != "bano")
	var sala: Dictionary = salas[rng.randi() % salas.size()]
	# en el centro de la habitación o, si ahí hay un mueble, en otro sitio libre de ella
	var pos: Vector2 = sala.centro
	if not lejos_de_muebles(planta.sitios[donde], pos, 26.0):
		pos = sitio_libre(planta.sitios[donde], sala, Vector2.INF, [])
		if pos == Vector2.INF:
			pos = sala.centro
	planta.llave = {"sitio": donde, "pos": pos}
	return planta


# La sala de mantenimiento, donde empieza la partida: una sala sencilla con su puerta abajo, unos pocos
# muebles y manchas en el suelo. La mitad izquierda de la pared de arriba queda libre: ahí irán el banco de
# trabajo, el ordenador y el baúl (fases 6 y 7; en el juego JS, en x = 135, 240 y 340). Los muebles de esta sala
# solo tienen dibujo de frente, así que van en la otra mitad. "vuelta" es su puerta en el pasillo.
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
		[SITIO_TALLER])
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
static func horda(sitio: Dictionary, orden: int, num: int) -> Array:
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
	var area := 0
	for s in apt.salas:
		area += s.casillas
	# en los pisos grandes hay más, pero no en proporción: si no, los de 3 dormitorios serían eternos
	var presupuesto := (BASE + nivel * POR_NIVEL) * clampf(area / 700.0, 0.8, 1.4)
	var peso := func(s: Dictionary) -> float:
		return s.casillas * (0.5 if s.uso == "bano" else 1.0)   # en los baños, pocos
	var total := 0.0
	for s in apt.salas:
		total += peso.call(s)
	var salida: Dictionary = sitio.salidas[0]
	var puerta := Vector2(salida.en, MURO + 52 if salida.dir == "arriba" else sitio.alto - MURO - 52)

	var zombis := []
	for s in apt.salas:
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
	return zombis


# Un punto de la habitación con sitio alrededor, lejos de la entrada, de los muebles y de los otros zombis
static func sitio_libre(sitio: Dictionary, sala: Dictionary, puerta: Vector2, otros: Array) -> Vector2:
	var apt: Dictionary = sitio.apt
	for i in 200:
		var pos := Vector2(sala.c0 * CASILLA + rng.randf() * sala.ancho * CASILLA,
			sala.f0 * CASILLA + rng.randf() * sala.fondo * CASILLA)
		if not despejado(apt, pos, 26.0, sala.id):
			continue
		if not lejos_de_muebles(sitio, pos, 30.0):
			continue
		if puerta != Vector2.INF and pos.distance_to(puerta) < LEJOS_PUERTA:
			continue
		if otros.any(func(z): return z.pos.distance_to(pos) < 60.0):
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
