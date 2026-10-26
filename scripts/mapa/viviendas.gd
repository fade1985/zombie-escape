# Las viviendas de los supervivientes rescatados: detrás de la puerta de la derecha de la sala de mantenimiento, un
# pasillo largo con seis habitaciones, una por superviviente (Supervivientes.DATOS). Las de los tres de los
# Apartamentos (policía, médica y militar) dan a la pared de arriba del pasillo, y las de los tres del centro
# comercial (ferretero, farmacéutica y técnico), a la de abajo; cada una con su puerta en medio (sin cartel con su
# nombre: no se ve quién hay detrás hasta abrirla). Las de quien aún no está rescatado (Guardado.rescatados) están
# cerradas y a oscuras, para ver lo que falta por salvar; las de los rescatados, abiertas, con él dentro (supervivientes.gd: colocar_vecinos)
# y lo suyo: las pantallas de las cámaras del técnico y, junto a la farmacéutica, la cafetera de Johnny.
#
# Es un sitio de la planta baja como los demás (planta.gd), hecho como un apartamento ("apt": su plano por casillas,
# sus habitaciones y sus puertas), así cada habitación lleva su niebla y no se ve por dentro hasta que se abre. Es
# siempre igual; qué puertas están abiertas lo decide mapa.gd al montarlo (poner_viviendas), con el guardado de ese
# momento. Por dentro, de momento, solo la cama individual de cada uno, en la esquina de arriba a la derecha y con la
# colcha de su color (catalogo.gd: "habitacion-<id>" para cada una y "pasillo-viviendas" para el pasillo, con sus
# "colocados"; Muebles.colocados).
class_name Viviendas

const CASILLA := 32
const BORDE := 2             # el muro de fuera, en casillas
const ANCHO := 12            # cada habitación, de ancho
const FONDO_ARRIBA := 9      # y de fondo: las de arriba (sus dos últimas filas quedan detrás de la cara del tabique)
const FONDO_ABAJO := 7       # y las de abajo (se ven enteras): así parecen igual de hondas
const PASILLO := 7           # el fondo del pasillo (sus dos últimas filas, detrás de la cara del tabique de abajo)
const ENTRADA := 6           # el trozo de pasillo antes de las habitaciones (ahí está la puerta por la que se llega)
const FINAL := 4             # y el que queda después de la última
const PUERTA := 2            # el ancho de las puertas, en casillas
const COLS := BORDE * 2 + ENTRADA + ANCHO * 3 + 2 + FINAL
const FILAS := BORDE * 2 + FONDO_ARRIBA + 1 + PASILLO + 1 + FONDO_ABAJO
const PASILLO_F := BORDE + FONDO_ARRIBA + 1     # la primera fila del pasillo
const ABAJO_F := PASILLO_F + PASILLO + 1        # y la de las habitaciones de abajo
const LLEGADA := 14                             # la puerta de la izquierda (la de la sala), en las filas 14 y 15
# Dónde espera cada uno, contando desde el medio de lo que se ve de su habitación (si no está aquí, en medio): el
# técnico, a la izquierda y más abajo (sus pantallas detrás de él no han de tapar el armario de la pared de arriba)
const SITIO := {"tecnico": Vector2(-96, 64)}


# El sitio entero. "mant" es la sala de mantenimiento y "vuelta", su puerta de la derecha (por donde se vuelve)
static func generar(semilla: int, mant: int, vuelta: int) -> Dictionary:
	var dueno := PackedInt32Array()
	dueno.resize(COLS * FILAS)
	dueno.fill(-1)
	# (el pasillo se llama como el sitio, para que arriba ponga solo «Viviendas»; "tipo" elige sus muebles en el catálogo)
	var pasillo := {"id": 0, "uso": "pasillo", "tipo": "viviendas", "nombre": "Viviendas", "c0": BORDE, "f0": PASILLO_F,
		"ancho": COLS - BORDE * 2, "fondo": PASILLO, "puertas": []}
	var salas := [pasillo]
	var puertas := []
	for id: String in Supervivientes.DATOS:
		var r := habitacion(id)
		var sala := {"id": salas.size(), "uso": "habitacion", "tipo": id, "vecino": id, "nombre": Supervivientes.DATOS[id].nombre,
			"c0": r.position.x, "f0": r.position.y, "ancho": r.size.x, "fondo": r.size.y, "puertas": []}
		# la puerta, en medio de la pared que da al pasillo (el tabique de debajo o el de encima)
		var p := {"a": sala.id, "b": 0, "c": r.position.x + (ANCHO - PUERTA) / 2,
			"f": r.end.y if r.position.y < PASILLO_F else r.position.y - 1, "ancho": PUERTA, "fondo": 1, "vecino": id}
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
		for c in range(p.c, p.c + PUERTA):
			dueno[p.f * COLS + c] = -2
	# ("entrada", para Muebles.de_apartamento: la de la izquierda; en las paredes de los lados, "c" cuenta filas)
	var apt := {"cols": COLS, "filas": FILAS, "dueno": dueno, "salas": salas, "puertas": puertas, "jefe": false,
		"entrada": {"c": LLEGADA, "lado": "izquierda"}, "tipo": "viviendas"}
	var sitio := {"tipo": "viviendas", "nombre": "Viviendas", "apt": apt, "ancho": COLS * CASILLA, "alto": FILAS * CASILLA,
		"zombis": [], "limpio": true, "visitado": false, "surtido": semilla,
		"salidas": [{"dir": "izquierda", "en": (LLEGADA + 1) * CASILLA, "tipo": "puerta", "a": mant, "vuelta": vuelta,
			"cerrojo": "", "aviso": ""}]}
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	sitio.muebles = Muebles.de_apartamento(apt, rng)
	# y a cada habitación, lo suyo puesto a mano (su cama): los "colocados" de su sala en el catálogo
	for s in salas:
		if s.uso == "habitacion":
			sitio.muebles += Muebles.colocados(Catalogo.SALAS["habitacion-" + s.tipo].get("colocados", {}).get("izquierda", []), s)
	return sitio


# La habitación de cada uno, en casillas: las de los Apartamentos arriba y las del centro comercial abajo, cada fila en
# el orden de Supervivientes.DATOS, de izquierda a derecha (caben tres por fila)
static func habitacion(id: String) -> Rect2i:
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
# sin sus dos últimas filas, que tapa la cara del tabique), o donde diga SITIO
static func casa(id: String) -> Vector2:
	var r := habitacion(id)
	var fondo := r.size.y - (2 if r.position.y < PASILLO_F else 0)
	return Vector2(r.position.x + r.size.x / 2.0, r.position.y + fondo / 2.0) * CASILLA + SITIO.get(id, Vector2.ZERO)
