# Los apartamentos de cada planta: los pisos y la habitación de cada jefe (explicado en docs/MAPA.md)
#
# Los pisos son siempre el mismo, dibujado con letras en PLANO_PASILLO: la puerta de entrada, en el centro de la pared
# que da al pasillo del edificio, lleva a un recibidor que sube hasta un pasillo que cruza el piso de lado a lado. A los
# lados del recibidor, la cocina y el salón; detrás del pasillo, el dormitorio individual y el de matrimonio, cada uno
# con su baño dentro, en la esquina de fuera. Todas las puertas dan al pasillo, menos la de cada baño, que da a su
# dormitorio. Está dibujado con la puerta abajo (los pisos de encima del pasillo del edificio); los de debajo, con la
# puerta arriba, salen volteados. (Hasta el 25 de octubre de 2026 cada piso se sorteaba, como en src/apartment.js del
# juego JS; está en git.)
#
# La habitación de cada jefe es un rectángulo sin tabiques (lo ha reventado todo), con la puerta de entrada en el centro
# de la pared. Las tiendas del centro comercial (tienda.gd) se apoyan en lo de aquí: la del jefe es esa misma
# habitación, y usan describir, voltear y fallos.
#
# Se trabaja en casillas de 32 unidades. "dueno" dice de quién es cada casilla: el número de su habitación,
# -1 si es muro y -2 si es el hueco de una puerta.
class_name Apartamento

const CASILLA := 32
const BORDE := 2          # grosor del muro de fuera, en casillas
const PUERTA := 2         # ancho de las puertas, en casillas (64 unidades)
const COLS_JEFE := 44     # la habitación de un jefe, en casillas (con su muro de fuera)
const FILAS_JEFE := 30
const NOMBRES := {"salon": "Salón", "cocina": "Cocina", "bano": "Baño", "dormitorio": "Dormitorio",
	"jefe": "Apartamento destrozado", "pasillo": "Pasillo"}
# El piso, dibujado casilla a casilla con la puerta de entrada abajo (lo lee pasillo_del_plano):
#   #  muro             (espacio)  hueco de una puerta          E  la puerta de entrada, en el muro de fuera
#   S  salón            C  cocina       M  dormitorio de matrimonio       I  dormitorio individual
#   B  baño (es del dormitorio al que da su puerta)                       .  pasillo y recibidor
# Cada trozo seguido de una misma letra es una habitación. Los tabiques de lado a lado tienen cara (3 casillas de alto),
# que tapa las dos últimas filas de lo que queda encima: del pasillo, de 7 filas, se ven 5. Los dormitorios son grandes
# para que la cama y sus muebles quepan contra la pared de arriba en las dos orientaciones: con la puerta abajo, en la
# franja de al lado del baño (11 y 12 casillas de ancho); volteado, contra la pared del pasillo, con 9 filas de fondo
# por encima del baño. Se puede retocar a mano (todas las filas, igual de largas, y la E en el centro); la prueba
# --piso dice si algo ha quedado mal.
const PLANO_PASILLO := [
	"##############################################",
	"##############################################",
	"##BBBBBBBB#IIIIIIIIIII#MMMMMMMMMMMM#BBBBBBBB##",
	"##BBBBBBBB#IIIIIIIIIII#MMMMMMMMMMMM#BBBBBBBB##",
	"##BBBBBBBB#IIIIIIIIIII#MMMMMMMMMMMM#BBBBBBBB##",
	"##BBBBBBBB#IIIIIIIIIII#MMMMMMMMMMMM#BBBBBBBB##",
	"##BBBBBBBB#IIIIIIIIIII#MMMMMMMMMMMM#BBBBBBBB##",
	"##BBBBBBBB#IIIIIIIIIII#MMMMMMMMMMMM#BBBBBBBB##",
	"########  #IIIIIIIIIII#MMMMMMMMMMMM#  ########",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"##IIIIIIIIIIIIIIIIIIII#MMMMMMMMMMMMMMMMMMMMM##",
	"###################  ####  ###################",
	"##..........................................##",
	"##..........................................##",
	"##..........................................##",
	"##..........................................##",
	"##..........................................##",
	"##..........................................##",
	"##..........................................##",
	"#######  ############....############  #######",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"##CCCCCCCCCCCCCCCCCC#....#SSSSSSSSSSSSSSSSSS##",
	"######################EE######################",
	"######################EE######################",
]
# Qué es cada letra del plano (en este orden se numeran las habitaciones: el salón, la 0, como en los otros pisos).
# "tipo": los muebles de "<uso>-<tipo>" del catálogo, si los hay (el pasillo, los de "pasillo-piso"; mapa.gd le pone el
# suelo del salón)
const LETRAS := {"S": {"uso": "salon"}, "C": {"uso": "cocina"}, "M": {"uso": "dormitorio", "tipo": "matrimonio"},
	"I": {"uso": "dormitorio", "tipo": "individual"}, "B": {"uso": "bano"}, ".": {"uso": "pasillo", "tipo": "piso"}}
# Cómo se llaman los dos dormitorios del piso (por su "tipo") y su baño
const DORMITORIOS := {
	"matrimonio": {"nombre": "Dormitorio de matrimonio", "bano": "Baño principal"},
	"individual": {"nombre": "Dormitorio individual", "bano": "Baño"},
}


# Un apartamento: el piso de siempre o, con "jefe", la habitación de un jefe. "lado" es dónde está la puerta de entrada,
# la que da al pasillo del edificio: "abajo" o "arriba". Devuelve un diccionario con:
#   cols, filas   su tamaño en casillas         dueno   de quién es cada casilla (ver arriba), por filas
#   salas         [{id, uso, nombre, c0, f0, ancho, fondo, casillas, centro}] (la primera, el salón o la del jefe).
#                 Los baños llevan "dueno_bano" (su dormitorio) y los dormitorios, "bano" y "tipo" (matrimonio o
#                 individual)
#   puertas       [{a, b, c, f, ancho, fondo}] huecos entre las habitaciones a y b, en casillas
#   entrada       {c, lado} la casilla izquierda de la puerta de entrada
static func generar(jefe := false, lado := "abajo") -> Dictionary:
	var apt := habitacion_jefe() if jefe else pasillo_del_plano()
	var malos := fallos(apt)
	if not malos.is_empty():
		push_error("El %s está mal: %s" % ["apartamento del jefe" if jefe else "plano del piso (PLANO_PASILLO)", ", ".join(malos)])
	if lado == "arriba":
		voltear(apt)
	apt.lado = lado
	return apt


# La habitación de un jefe: un rectángulo sin tabiques, con la puerta de entrada en el centro de la pared de abajo. Así
# el paso limpio de la puerta al medio (el de la porquería del Glotón y el del fuego del bombero) va recto
static func habitacion_jefe() -> Dictionary:
	var dueno := PackedInt32Array()
	dueno.resize(COLS_JEFE * FILAS_JEFE)
	dueno.fill(-1)
	for f in range(BORDE, FILAS_JEFE - BORDE):
		for c in range(BORDE, COLS_JEFE - BORDE):
			dueno[f * COLS_JEFE + c] = 0
	var sala := {"id": 0, "uso": "jefe", "c0": BORDE, "f0": BORDE, "ancho": COLS_JEFE - BORDE * 2,
		"fondo": FILAS_JEFE - BORDE * 2, "puertas": []}
	var apt := {"cols": COLS_JEFE, "filas": FILAS_JEFE, "dueno": dueno, "salas": [sala], "puertas": [],
		"entrada": {"c": (COLS_JEFE - PUERTA) / 2, "lado": "abajo"}, "jefe": true}
	describir(apt)
	return apt


# ═════════════ El piso ═════════════

# El piso, montado tal cual a partir de su dibujo (PLANO_PASILLO), con la puerta de entrada abajo. Devuelve lo que
# cuenta generar()
static func pasillo_del_plano() -> Dictionary:
	var filas: int = PLANO_PASILLO.size()
	var cols: int = PLANO_PASILLO[0].length()
	var dueno := PackedInt32Array()
	dueno.resize(cols * filas)
	dueno.fill(-1)
	var letra := func(c: int, f: int) -> String:
		return PLANO_PASILLO[f][c]

	# 1. Las habitaciones: cada trozo seguido de una misma letra, rellenado de vecina en vecina
	var salas := []
	for l: String in LETRAS:
		for f in filas:
			for c in cols:
				if letra.call(c, f) != l or dueno[f * cols + c] != -1:
					continue
				var sala := {"id": salas.size(), "uso": LETRAS[l].uso, "puertas": []}
				if LETRAS[l].has("tipo"):
					sala.tipo = LETRAS[l].tipo
				var desde := Vector2i(c, f)   # (la esquina de arriba a la izquierda de lo que ocupa, y la de abajo a la derecha)
				var hasta := Vector2i(c, f)
				var pila := [Vector2i(c, f)]
				dueno[f * cols + c] = sala.id
				while not pila.is_empty():
					var v: Vector2i = pila.pop_back()
					desde = desde.min(v)
					hasta = hasta.max(v)
					for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
						var w: Vector2i = v + d
						if letra.call(w.x, w.y) == l and dueno[w.y * cols + w.x] == -1:
							dueno[w.y * cols + w.x] = sala.id
							pila.append(w)
				sala.c0 = desde.x
				sala.f0 = desde.y
				sala.ancho = hasta.x - desde.x + 1
				sala.fondo = hasta.y - desde.y + 1
				salas.append(sala)

	# 2. Las puertas: cada tramo de huecos, entre las dos habitaciones que tiene a los lados (arriba y abajo si va a lo
	#    ancho; a izquierda y derecha si va a lo hondo). Cada baño es del dormitorio al que da su puerta
	var puertas := []
	for f in filas:
		for c in cols:
			if letra.call(c, f) != " " or dueno[f * cols + c] == -2:
				continue
			var ancho := 1
			while letra.call(c + ancho, f) == " ":
				ancho += 1
			var fondo := 1
			while letra.call(c, f + fondo) == " ":
				fondo += 1
			var a: int = dueno[(f - 1) * cols + c] if ancho > 1 else dueno[f * cols + c - 1]
			var b: int = dueno[(f + 1) * cols + c] if ancho > 1 else dueno[f * cols + c + 1]
			var p := {"a": a, "b": b, "c": c, "f": f, "ancho": ancho, "fondo": fondo}
			for ff in range(f, f + fondo):
				for cc in range(c, c + ancho):
					dueno[ff * cols + cc] = -2
			puertas.append(p)
			salas[a].puertas.append(p)
			salas[b].puertas.append(p)
	for bano in salas.filter(func(s): return s.uso == "bano" and not s.puertas.is_empty()):
		var p: Dictionary = bano.puertas[0]
		bano.dueno_bano = p.a if p.b == bano.id else p.b
		salas[bano.dueno_bano].bano = bano.id

	# 3. La puerta de entrada: la E del muro de abajo
	var apt := {"cols": cols, "filas": filas, "dueno": dueno, "salas": salas, "puertas": puertas,
		"entrada": {"c": PLANO_PASILLO[filas - 1].find("E"), "lado": "abajo"}, "jefe": false, "forma": "pasillo"}
	describir(apt)
	return apt


# Cuántas casillas se alcanzan andando desde "desde" pisando solo las que cumplen "pisable"
static func alcanzables(dueno: PackedInt32Array, cols: int, desde: int, pisable: Callable) -> int:
	var visto := PackedByteArray()
	visto.resize(dueno.size())
	var pila := [desde]
	visto[desde] = 1
	var cuenta := 1
	while not pila.is_empty():
		var i: int = pila.pop_back()
		var c := i % cols
		for j in [i - cols, i + cols, i - 1 if c > 0 else -1, i + 1 if c < cols - 1 else -1]:
			if j >= 0 and j < dueno.size() and not visto[j] and pisable.call(dueno[j]):
				visto[j] = 1
				cuenta += 1
				pila.append(j)
	return cuenta


# Pone a cada habitación su nombre, cuántas casillas tiene y su punto más despejado (en unidades)
static func describir(apt: Dictionary) -> void:
	var cols: int = apt.cols
	var filas: int = apt.filas
	var dueno: PackedInt32Array = apt.dueno
	var de := func(c: int, f: int) -> int:
		return -1 if c < 0 or f < 0 or c >= cols or f >= filas else dueno[f * cols + c]
	for s in apt.salas:
		s.nombre = NOMBRES[s.uso]
		s.casillas = 0
		var mejor := -1
		for f in range(s.f0, s.f0 + s.fondo):
			for c in range(s.c0, s.c0 + s.ancho):
				if dueno[f * cols + c] != s.id:
					continue
				s.casillas += 1
				# cuántas casillas de la misma habitación tiene alrededor, en todas direcciones
				var k := 1
				var sigue := true
				while sigue:
					for d in range(-k, k + 1):
						if de.call(c + d, f - k) != s.id or de.call(c + d, f + k) != s.id or de.call(c - k, f + d) != s.id or de.call(c + k, f + d) != s.id:
							sigue = false
							break
					if sigue:
						k += 1
				if k - 1 > mejor:
					mejor = k - 1
					s.centro = Vector2((c + 0.5) * CASILLA, (f + 0.5) * CASILLA)
	# los dos dormitorios del piso se llaman por su cama, y cada baño, por el suyo (DORMITORIOS)
	for s in apt.salas:
		if DORMITORIOS.has(s.get("tipo", "")):
			s.nombre = DORMITORIOS[s.tipo].nombre
			apt.salas[s.bano].nombre = DORMITORIOS[s.tipo].bano


# Le da la vuelta de arriba abajo (para los que tienen el pasillo del edificio por arriba: la puerta, arriba)
static func voltear(apt: Dictionary) -> void:
	var cols: int = apt.cols
	var filas: int = apt.filas
	var viejo: PackedInt32Array = apt.dueno
	var nuevo := PackedInt32Array()
	nuevo.resize(viejo.size())
	for f in filas:
		for c in cols:
			nuevo[(filas - 1 - f) * cols + c] = viejo[f * cols + c]
	apt.dueno = nuevo
	for s in apt.salas:
		s.f0 = filas - s.f0 - s.fondo
		s.centro.y = filas * CASILLA - s.centro.y
	for p in apt.puertas:
		p.f = filas - p.f - p.fondo
	apt.entrada.lado = "arriba"


# Repasa que el apartamento está bien hecho. Devuelve la lista de fallos (vacía si todo va bien).
static func fallos(apt: Dictionary) -> Array:
	var cols: int = apt.cols
	var dueno: PackedInt32Array = apt.dueno
	var malos := []
	# desde la entrada se llega andando a todo el suelo
	var suelo := 0
	for v in dueno:
		if v != -1:
			suelo += 1
	var entrada: int = (apt.filas - BORDE - 1) * cols + apt.entrada.c
	if alcanzables(dueno, cols, entrada, func(v): return v != -1) != suelo:
		malos.append("hay suelo al que no se puede llegar")
	for s in apt.salas:
		if not apt.jefe and s.puertas.is_empty():
			malos.append(s.uso + " sin puerta")
		if s.casillas < 20:
			malos.append(s.uso + " demasiado pequeño")
	if not apt.jefe:
		var unidas := func(a: Dictionary, b: Dictionary) -> bool:
			return a.puertas.any(func(p): return (p.a == a.id and p.b == b.id) or (p.a == b.id and p.b == a.id))
		var piso: bool = apt.get("forma", "") == "pasillo"   # (en el piso, todas dan al pasillo; en las tiendas, a la sala de venta)
		for s in apt.salas:
			if not piso and (s.uso == "cocina" or s.uso == "dormitorio") and not unidas.call(s, apt.salas[0]):
				malos.append(s.uso + " sin puerta al salón")
			if s.uso == "bano" and (s.puertas.size() != 1 or not unidas.call(s, apt.salas[s.dueno_bano])):
				malos.append("el baño no tiene una sola puerta, la de su dormitorio")
	return malos
