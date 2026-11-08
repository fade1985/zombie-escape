# Las viviendas de los supervivientes rescatados: detrás de la puerta de la derecha de la sala de mantenimiento, un
# pasillo largo con nueve habitaciones, una por superviviente (Supervivientes.DATOS). Son los trasteros del edificio (no
# pueden vivir en ningún piso: la horda los ha destrozado todos), así que todas son iguales, de chapa metálica (mapa.gd
# les pone el estilo "trastero" y la puerta azul lisa de puerta_bano.gd), y el pasillo es el de una zona de trasteros: el
# mismo hormigón, con una línea amarilla pintada a lo largo, la misma chapa con una franja de chapa lagrimada abajo,
# cajas de cartón y carretillas contra la pared y, a la izquierda de la primera puerta de arriba, el cartel de
# «TRASTEROS» (cartel_trasteros.gd). Las de los tres de los
# Apartamentos (policía, médica y militar) dan a la pared de arriba del pasillo, y las de los tres del centro
# comercial (ferretero, farmacéutica y técnico), a la de abajo; las de los tres de Torre Velaria (parte 7 del plan:
# informático, recepcionista y limpiadora), al final: una arriba, otra abajo y la tercera al fondo del pasillo, con su
# puerta en la pared de la derecha. Cada una con su puerta en medio (sin cartel con su
# nombre: no se ve quién hay detrás hasta abrirla). Las de quien aún no está rescatado (Guardado.rescatados) están
# cerradas y a oscuras, para ver lo que falta por salvar; las de los rescatados, abiertas, con él dentro (supervivientes.gd: colocar_vecinos).
#
# Es un sitio de la planta baja como los demás (planta.gd), hecho como un apartamento ("apt": su plano por casillas,
# sus habitaciones y sus puertas), así cada habitación lleva su niebla y no se ve por dentro hasta que se abre. Es
# siempre igual; qué puertas están abiertas lo decide mapa.gd al montarlo (poner_viviendas), con el guardado de ese
# momento. Por dentro, lo de un trastero: el colchón en el suelo de cada uno, en la esquina de arriba a la derecha y con
# la colcha de su color, y una estantería metálica vacía en la de arriba a la izquierda (catalogo.gd: "habitacion-<id>"
# para cada una y "pasillo-viviendas" para el pasillo, con sus "colocados"; Muebles.colocados).
#
# Cada habitación (y el pasillo) es una caja cerrada por sus cuatro tabiques, de una casilla de grueso, como se ve una
# casa por dentro desde arriba: la pared de arriba de cada una con su altura (su cara y, encima, su tabique) y los
# demás tabiques planos; el muro que sobra, alrededor, se ve oscuro, como fuera del mapa ("cajas" en el sitio: mapa.gd, poner_tabiques). La
# pared de arriba de las de abajo y la del pasillo tapan las tres últimas filas de lo que tienen detrás (dos la cara y
# una su tabique).
class_name Viviendas

const CASILLA := 32
const BORDE := 2             # el muro de fuera, en casillas (el tabique y, por fuera, una oscura)
const ANCHO := 12            # cada habitación, de ancho
const FONDO_ARRIBA := 10     # y de fondo: las de arriba (sus tres últimas filas quedan detrás de la pared del pasillo)
const FONDO_ABAJO := 7       # y las de abajo (se ven enteras): así se ve lo mismo de todas
const TAPADAS := 3           # las filas de detrás de una pared que tapan su cara (2) y su tabique (1)
const PASILLO := 8           # el fondo del pasillo (sus tres últimas filas, detrás de la pared de las de abajo)
const ENTRADA := 0           # el trozo de pasillo antes de las habitaciones: nada, la pared de la entrada es la de las primeras
const FINAL := 0             # y el que queda después de la última: nada, el pasillo acaba con las habitaciones
const PUERTA := 2            # el ancho de las puertas, en casillas
const LARGO := ENTRADA + ANCHO * 4 + 3 + FINAL   # el pasillo, de largo: cuatro habitaciones por fila (con sus tabiques)
const COLS := BORDE * 2 + LARGO + 1 + ANCHO      # y, tras su tabique de la derecha, la habitación del fondo
const FILAS := BORDE * 2 + FONDO_ARRIBA + 1 + PASILLO + 1 + FONDO_ABAJO
const PASILLO_F := BORDE + FONDO_ARRIBA + 1     # la primera fila del pasillo
const ABAJO_F := PASILLO_F + PASILLO + 1        # y la de las habitaciones de abajo
const LLEGADA := PASILLO_F + 2                  # la puerta de la izquierda (la de la sala), en esta fila y la siguiente
const CARTEL := 2.5                             # el cartel de «TRASTEROS» (mapa.gd): su centro, en la casilla 2,5 del pasillo,
                                                # en medio de la pared de la izquierda de la primera puerta de arriba
# Dónde espera cada uno, contando desde el medio de lo que se ve de su habitación (si no está aquí, en medio): el
# técnico, a la izquierda
const SITIO := {"tecnico": Vector2(-96, 32)}
# Los de la torre, en este orden: arriba, abajo y al fondo. Los que aún no están en Supervivientes.DATOS (se hacen uno por
# trozo) ya tienen su habitación, cerrada
const TORRE := ["programador", "recepcionista", "limpiadora"]   # no-tr (ids)


# Todos los que tienen habitación: los de Supervivientes.DATOS y los de la torre que aún falten
static func ids() -> Array:
	var todos: Array = Supervivientes.DATOS.keys()
	for id in TORRE:
		if id not in todos:
			todos.append(id)
	return todos


# El sitio entero. "mant" es la sala de mantenimiento y "vuelta", su puerta de la derecha (por donde se vuelve)
static func generar(semilla: int, mant: int, vuelta: int) -> Dictionary:
	var dueno := PackedInt32Array()
	dueno.resize(COLS * FILAS)
	dueno.fill(-1)
	# (el pasillo se llama como el sitio, para que arriba ponga solo «Viviendas»; "tipo" elige sus muebles en el catálogo)
	# ("linea", la "y" de la línea amarilla pintada a lo largo del suelo, mapa.gd: en medio de lo que se ve de él)
	# (los nombres, en español, como los de la planta: se traducen al enseñarlos, Planta.nombre_de_sitio)
	var pasillo := {"id": 0, "uso": "pasillo", "tipo": "viviendas", "nombre": "Viviendas", "c0": BORDE, "f0": PASILLO_F,   # [traducir]
		"ancho": LARGO, "fondo": PASILLO, "puertas": [], "linea": (PASILLO_F + (PASILLO - TAPADAS) / 2.0) * CASILLA}
	var salas := [pasillo]
	var puertas := []
	for id: String in ids():
		var r := habitacion(id)
		# (cada habitación se llama como el suyo, en español; se enseña con Supervivientes.nombre_de: Planta.nombre_de_sitio)
		var nombre: String = Supervivientes.DATOS[id].nombre if Supervivientes.DATOS.has(id) else "Trastero"   # [traducir]
		var sala := {"id": salas.size(), "uso": "habitacion", "tipo": id, "vecino": id, "nombre": nombre,
			"c0": r.position.x, "f0": r.position.y, "ancho": r.size.x, "fondo": r.size.y, "puertas": []}
		# la puerta, en medio de la pared que da al pasillo (el tabique de debajo o el de encima; la del fondo, en el de
		# su izquierda, a la altura de lo que se ve del pasillo)
		var p := {"a": sala.id, "b": 0, "c": r.position.x + (ANCHO - PUERTA) / 2,
			"f": r.end.y if r.position.y < PASILLO_F else r.position.y - 1, "ancho": PUERTA, "fondo": 1, "vecino": id}
		if r.position.y == PASILLO_F:
			p = {"a": 0, "b": sala.id, "c": r.position.x - 1, "f": PASILLO_F + (PASILLO - TAPADAS - PUERTA) / 2,
				"ancho": 1, "fondo": PUERTA, "vecino": id}
		sala.puertas.append(p)
		pasillo.puertas.append(p)
		puertas.append(p)
		salas.append(sala)
	for s in salas:
		for f in range(s.f0, s.f0 + s.fondo):
			for c in range(s.c0, s.c0 + s.ancho):
				dueno[f * COLS + c] = s.id
		s.casillas = s.ancho * s.fondo
		s.centro = Vector2(s.c0 + s.ancho / 2.0, s.f0 + s.fondo / 2.0) * CASILLA
	for p in puertas:
		for f in range(p.f, p.f + p.fondo):
			for c in range(p.c, p.c + p.ancho):
				dueno[f * COLS + c] = -2
	# ("entrada", para Muebles.de_apartamento: la de la izquierda; en las paredes de los lados, "c" cuenta filas)
	var apt := {"cols": COLS, "filas": FILAS, "dueno": dueno, "salas": salas, "puertas": puertas, "jefe": false,
		"entrada": {"c": LLEGADA, "lado": "izquierda"}, "tipo": "viviendas"}
	var sitio := {"tipo": "viviendas", "nombre": "Viviendas", "apt": apt, "ancho": COLS * CASILLA, "alto": FILAS * CASILLA,   # [traducir]
		"cajas": true, "arriba_extra": 68,   # (la cámara deja ver el tabique de arriba, que sube más que la moldura de siempre)
		"zombis": [], "limpio": true, "visitado": false, "surtido": semilla,
		"salidas": [{"dir": "izquierda", "en": (LLEGADA + 1) * CASILLA, "tipo": "puerta", "a": mant, "vuelta": vuelta,
			"cerrojo": "", "aviso": ""}]}
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	sitio.muebles = Muebles.de_apartamento(apt, rng)
	# y a cada habitación, lo suyo puesto a mano (su colchón y su estantería), y al pasillo, sus cajas y sus carretillas: los "colocados" de
	# cada sala en el catálogo ("habitacion-<id>" y "pasillo-viviendas")
	for s in salas:
		sitio.muebles += Muebles.colocados(Catalogo.SALAS.get(s.uso + "-" + s.tipo, {}).get("colocados", {}).get("izquierda", []), s)
	return sitio


# La habitación de cada uno, en casillas: las de los Apartamentos arriba y las del centro comercial abajo, cada fila en
# el orden de Supervivientes.DATOS, de izquierda a derecha; y las de la torre (TORRE), la cuarta de arriba, la cuarta
# de abajo y la del fondo (a la derecha del pasillo, tan honda como él)
static func habitacion(id: String) -> Rect2i:
	var k_torre := TORRE.find(id)
	if k_torre == 0 or k_torre == 1:
		return Rect2i(BORDE + ENTRADA + 3 * (ANCHO + 1), BORDE if k_torre == 0 else ABAJO_F, ANCHO,
			FONDO_ARRIBA if k_torre == 0 else FONDO_ABAJO)
	if k_torre == 2:
		return Rect2i(BORDE + LARGO + 1, PASILLO_F, ANCHO, PASILLO)
	var arriba: bool = Supervivientes.DATOS[id].edificio == "apartamentos"
	var k := 0
	for otro: String in Supervivientes.DATOS:
		if otro == id:
			break
		if (Supervivientes.DATOS[otro].edificio == "apartamentos") == arriba:
			k += 1
	return Rect2i(BORDE + ENTRADA + k * (ANCHO + 1), BORDE if arriba else ABAJO_F, ANCHO,
		FONDO_ARRIBA if arriba else FONDO_ABAJO)


# Dónde espera cada uno en su habitación (su "casa", en unidades): en medio de lo que se ve de ella (de las de arriba,
# sin sus tres últimas filas, que tapa la pared del pasillo), o donde diga SITIO
static func casa(id: String) -> Vector2:
	var r := habitacion(id)
	var fondo := r.size.y - (TAPADAS if r.position.y <= PASILLO_F else 0)   # (la del fondo, como el pasillo)
	return Vector2(r.position.x + r.size.x / 2.0, r.position.y + fondo / 2.0) * CASILLA + SITIO.get(id, Vector2.ZERO)


# Los apliques (mapa.gd: poner_apliques), fijos: uno en medio de la pared de arriba de cada habitación y, en la del
# pasillo, uno en cada tabique entre las puertas de arriba y otro al final (sin tapar ninguna puerta ni el cartel). En
# unidades; "zona", la habitación que alumbran
static func apliques(apt: Dictionary) -> Array:
	var lista := []
	for s in apt.salas:
		var xs := [(s.c0 + s.ancho / 2.0) * CASILLA]
		if s.id == 0:
			xs = [(BORDE + LARGO - 2.5) * CASILLA]
			for k in range(1, 4):
				xs.append((BORDE + ENTRADA + k * (ANCHO + 1) - 0.5) * CASILLA)
		for x in xs:
			lista.append({"x": x, "y": s.f0 * CASILLA + 1.0, "zona": s.id, "semilla": 0.0, "parpadea": false})
	return lista
