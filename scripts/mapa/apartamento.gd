# Generador de apartamentos (la misma receta que src/apartment.js del juego JS; explicada en docs/MAPA.md)
#
# Cada apartamento es un rectángulo grande con el salón en medio y, alrededor, la cocina y de 1 a 3
# dormitorios, cada dormitorio con su baño. Sale distinto cada vez:
#
#   1. El salón empieza ocupando todo el rectángulo.
#   2. La cocina y los dormitorios se reparten en franjas, de izquierda a derecha: pegados a la pared del
#      fondo, en las esquinas de delante o dos seguidos en un lateral. Lo que queda libre es el salón, que
#      sale con forma de L, de T, de U... y toca todas las habitaciones.
#   3. A cada dormitorio se le recorta un baño en una esquina (el dormitorio se queda con forma de L).
#   4. Se abre una puerta del salón a la cocina y a cada dormitorio, y otra de cada dormitorio a su baño.
#      A veces, una más entre dos habitaciones vecinas.
#
# El apartamento de la jefa es el mismo rectángulo sin tabiques: lo ha reventado todo. Su puerta de entrada, siempre en
# el centro de la pared (la de los pisos, al azar).
#
# Hay otra receta, el piso con pasillo en T (probar_pasillo; de momento solo sale en la prueba --piso-pasillo, con
# "con_pasillo"): la puerta de entrada, siempre en el centro de la pared, da a un recibidor que sube hasta un pasillo que
# cruza el piso de lado a lado. A un lado del recibidor queda el salón y al otro la cocina (o un dormitorio); detrás del
# pasillo, en fila, lo demás: los dormitorios, el baño y, si no está delante, la cocina. Todas las puertas dan al pasillo
# (las de delante, a veces, al recibidor):
#
#     ┌──────┬────┬────────┐
#     │ dorm │baño│  dorm  │
#     ├─  ───┴─  ─┴─────  ─┤
#     │       pasillo      │
#     ├───  ─┐    ┌───  ───┤
#     │ salón│    │ cocina │
#     └──────┴─  ─┴────────┘
#             entrada
#
# Se trabaja en casillas de 32 unidades. "dueno" dice de quién es cada casilla: el número de su habitación,
# -1 si es muro y -2 si es el hueco de una puerta.
class_name Apartamento

const CASILLA := 32
const BORDE := 2          # grosor del muro de fuera, en casillas
const MINIMO := 7         # lado mínimo de un trozo de salón
const PUERTA := 2         # ancho de las puertas, en casillas (64 unidades)
const MAX_LARGO := 2.2    # cuántas veces más larga que ancha puede ser una habitación
const DELANTE := 7        # fondo mínimo de salón delante de una habitación
const HUECO := 6          # hueco mínimo de salón entre dos habitaciones del mismo lateral
const ANCHO_SALON := 5    # el salón no tiene pasos ni rincones de menos de 5 casillas
const PARTE_SALON := [0.22, 0.42]   # parte del apartamento que es salón: como poco y como mucho
const MEDIDAS := {"cocina": [9, 16], "dormitorio": [11, 20]}   # lado mínimo y máximo de cada habitación
const BANO_ANCHO := [6, 9]
const BANO_FONDO := [6, 8]
const NOMBRES := {"salon": "Salón", "cocina": "Cocina", "bano": "Baño", "dormitorio": "Dormitorio",
	"jefe": "Apartamento destrozado", "pasillo": "Pasillo"}
# El piso con pasillo (todo en casillas). Los fondos cuentan con la cara de los tabiques, que tapa las dos últimas filas
# de lo que queda encima de ellos: del pasillo se ven 4 o 5 filas
const RECIBIDOR := [4, 6]        # ancho del recibidor: par, para que quede centrado encima de la puerta
const LADO := [11, 19]           # ancho del salón y de lo que hay al otro lado del recibidor (los dos, igual)
const FONDO_DETRAS := [9, 11]    # fondo de las habitaciones de detrás del pasillo
const FONDO_PASILLO := [6, 7]
const FONDO_DELANTE := [8, 10]   # y de las de delante, las de los lados del recibidor
const ANCHOS := {"dormitorio": [11, 19], "cocina": [10, 16], "bano": [7, 10]}   # ancho de las de detrás
const A_RECIBIDOR := 0.35        # lo que salen las puertas de delante en la pared del recibidor, y no en la del pasillo

static var rng := RandomNumberGenerator.new()
static var con_pasillo := false   # los pisos normales, con pasillo en T (de momento, solo en la prueba --piso-pasillo)


# Genera un apartamento. "lado" es dónde está la puerta de entrada, la que da al pasillo: "abajo" o "arriba".
# Devuelve un diccionario con:
#   cols, filas   su tamaño en casillas         dueno   de quién es cada casilla (ver arriba), por filas
#   salas         [{id, uso, nombre, c0, f0, ancho, fondo, casillas, centro}] (la primera, el salón).
#                 Los baños llevan "dueno_bano" (su dormitorio) y los dormitorios, "bano"
#   puertas       [{a, b, c, f, ancho, fondo}] huecos entre las habitaciones a y b, en casillas
#   entrada       {c, lado} la casilla izquierda de la puerta de entrada
static func generar(semilla: int, jefe := false, lado := "abajo") -> Dictionary:
	for intento in 1500:
		rng.seed = semilla + intento * 7919
		var dormitorios := 0 if jefe else rng.randi_range(1, 3)
		var apt := probar_pasillo(dormitorios) if con_pasillo and not jefe else probar(dormitorios, jefe)
		if apt.is_empty() or not fallos(apt).is_empty():
			continue
		if lado == "arriba":
			voltear(apt)
		apt.lado = lado
		return apt
	push_error("No se pudo generar el apartamento (semilla %d)" % semilla)
	return {}


static func escoger(lista: Array) -> Variant:
	return lista[rng.randi() % lista.size()]


static func barajar(lista: Array) -> Array:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = lista[i]
		lista[i] = lista[j]
		lista[j] = t
	return lista


# Reparte la cocina y los dormitorios alrededor del salón, en franjas de izquierda a derecha.
# Cada franja puede llevar una habitación al fondo ("fondo"), una delante ("delante", solo en los laterales),
# dos, una al fondo y otra delante ("dos", solo en los laterales), o ninguna ("nada": todo salón).
# Devuelve los rectángulos (en casillas, desde la esquina del interior) o [] si esta vez no cuadra.
static func repartir(dormitorios: int, iw: int, ih: int) -> Array:
	var usos := ["cocina"]
	for i in dormitorios:
		usos.append("dormitorio")
	barajar(usos)
	var caben := {"nada": 0, "fondo": 1, "delante": 1, "dos": 2}
	var puntas := ["nada", "fondo", "fondo", "delante", "dos", "dos"]
	var izq: String = escoger(puntas)
	var der: String = escoger(puntas)
	var medio: int = usos.size() - caben[izq] - caben[der]
	if medio < 0:
		return []
	var tipos := [izq]
	for i in medio:
		tipos.append("fondo")
	tipos.append(der)
	# a veces el salón llega hasta el fondo entre dos habitaciones (y siempre, si no le queda sitio delante)
	if rng.randf() < 0.12 or not ("fondo" in tipos or "nada" in tipos):
		tipos.insert(rng.randi_range(1, tipos.size() - 1), "nada")
	var franjas := []
	for i in tipos.size():
		if tipos[i] == "nada" and i > 0 and tipos[i - 1] == "nada":
			continue
		var suyos := []
		for k in caben[tipos[i]]:
			suyos.append(usos.pop_front())
		franjas.append({"tipo": tipos[i], "usos": suyos})

	# Anchos: el mínimo de cada franja; lo que sobra se reparte al azar, primero entre las que tienen habitación
	var sobra: int = iw - (franjas.size() - 1)
	for f in franjas:
		f.ancho = MINIMO
		f.max = 9999
		if not f.usos.is_empty():
			f.ancho = 0
			f.max = 9999
			for u in f.usos:
				f.ancho = maxi(f.ancho, MEDIDAS[u][0])
				f.max = mini(f.max, MEDIDAS[u][1])
		sobra -= f.ancho
	if sobra < 0:
		return []
	while sobra > 0:
		var pueden := franjas.filter(func(f): return not f.usos.is_empty() and f.ancho < f.max)
		if pueden.is_empty():
			pueden = franjas.filter(func(f): return f.ancho < f.max)
		if pueden.is_empty():
			return []
		escoger(pueden).ancho += 1
		sobra -= 1

	# Fondos: lo más que deja el salón, o poco menos
	var margen := func(uso: String, w: int) -> Array:
		return [maxi(MEDIDAS[uso][0], ceili(w / MAX_LARGO)), mini(MEDIDAS[uso][1], floori(w * MAX_LARGO))]
	var fuera := []
	var c := 0
	for f in franjas:
		if f.tipo == "fondo" or f.tipo == "delante":
			var m: Array = margen.call(f.usos[0], f.ancho)
			var tope: int = mini(m[1], ih - 1 - (DELANTE if f.tipo == "fondo" else MINIMO))
			if tope < m[0]:
				return []
			var h := rng.randi_range(maxi(m[0], tope - 3), tope)
			fuera.append({"uso": f.usos[0], "c0": c, "f0": 0 if f.tipo == "fondo" else ih - h, "ancho": f.ancho, "fondo": h})
		elif f.tipo == "dos":
			var m1: Array = margen.call(f.usos[0], f.ancho)
			var m2: Array = margen.call(f.usos[1], f.ancho)
			var h1: int
			var h2: int
			if rng.randf() < 0.2 and ih - m1[0] - m2[0] - 2 >= HUECO:
				# separadas, con un trozo de salón entre las dos
				h1 = m1[0] + rng.randi_range(0, mini(m1[1] - m1[0], ih - m1[0] - m2[0] - 2 - HUECO))
				h2 = m2[0] + rng.randi_range(0, mini(m2[1] - m2[0], ih - h1 - m2[0] - 2 - HUECO))
			else:
				# juntas, con un tabique entre las dos
				var lo: int = maxi(m1[0], ih - 1 - m2[1])
				var hi: int = mini(m1[1], ih - 1 - m2[0])
				if hi < lo:
					return []
				h1 = rng.randi_range(lo, hi)
				h2 = ih - 1 - h1
			fuera.append({"uso": f.usos[0], "c0": c, "f0": 0, "ancho": f.ancho, "fondo": h1})
			fuera.append({"uso": f.usos[1], "c0": c, "f0": ih - h2, "ancho": f.ancho, "fondo": h2})
		c += f.ancho + 1
	return fuera


# ¿Es el salón una sola pieza, sin pasos ni rincones estrechos, y ni muy pequeño ni enorme?
static func salon_bien(dueno: PackedInt32Array, cols: int, filas: int, id: int) -> bool:
	# cada casilla tiene que caber dentro de algún cuadrado de ANCHO_SALON × ANCHO_SALON que sea todo salón
	var cubierta := PackedByteArray()
	cubierta.resize(cols * filas)
	for f in range(0, filas - ANCHO_SALON + 1):
		for c in range(0, cols - ANCHO_SALON + 1):
			var lleno := true
			for df in ANCHO_SALON:
				for dc in ANCHO_SALON:
					if dueno[(f + df) * cols + c + dc] != id:
						lleno = false
						break
				if not lleno:
					break
			if lleno:
				for df in ANCHO_SALON:
					for dc in ANCHO_SALON:
						cubierta[(f + df) * cols + c + dc] = 1
	var primera := -1
	var total := 0
	for i in dueno.size():
		if dueno[i] != id:
			continue
		if not cubierta[i]:
			return false
		if primera < 0:
			primera = i
		total += 1
	var parte := float(total) / ((cols - BORDE * 2) * (filas - BORDE * 2))
	if parte < PARTE_SALON[0] or parte > PARTE_SALON[1]:
		return false
	# y se llega andando de cualquier punto a cualquier otro
	return alcanzables(dueno, cols, primera, func(v): return v == id) == total


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


static func probar(dormitorios: int, jefe: bool) -> Dictionary:
	# Tamaño: más habitaciones, más grande. Siempre en casillas pares para que quede centrado.
	var partes := 1 if jefe else 2 + dormitorios
	var cols := 44 if jefe else 20 + partes * 6 + rng.randi_range(-1, 1) * 2
	var filas := 30 if jefe else 20 + partes * 2 + rng.randi_range(-1, 1) * 2
	var iw := cols - BORDE * 2
	var ih := filas - BORDE * 2
	var dueno := PackedInt32Array()
	dueno.resize(cols * filas)
	dueno.fill(-1)

	# 1. El salón lo ocupa todo, de momento
	var salon := {"id": 0, "uso": "jefe" if jefe else "salon", "c0": BORDE, "f0": BORDE, "ancho": iw, "fondo": ih, "puertas": []}
	var salas := [salon]
	for f in range(BORDE, filas - BORDE):
		for c in range(BORDE, cols - BORDE):
			dueno[f * cols + c] = 0

	if not jefe:
		# 2. La cocina y los dormitorios, alrededor: primero sus tabiques y luego su suelo
		var plan := repartir(dormitorios, iw, ih)
		if plan.is_empty():
			return {}
		for p in plan:
			salas.append({"id": salas.size(), "uso": p.uso, "c0": p.c0 + BORDE, "f0": p.f0 + BORDE, "ancho": p.ancho, "fondo": p.fondo, "puertas": []})
		for s in salas.slice(1):
			for f in range(s.f0 - 1, s.f0 + s.fondo + 1):
				for c in range(s.c0 - 1, s.c0 + s.ancho + 1):
					dueno[f * cols + c] = -1
		for s in salas.slice(1):
			for f in range(s.f0, s.f0 + s.fondo):
				for c in range(s.c0, s.c0 + s.ancho):
					dueno[f * cols + c] = s.id
		if not salon_bien(dueno, cols, filas, 0):
			return {}

		# 3. Un baño en cada dormitorio, recortado en la esquina que menos da al salón
		for cuarto in salas.filter(func(s): return s.uso == "dormitorio"):
			# al dormitorio le quedan al menos 4 casillas a cada lado del baño
			var bw := rng.randi_range(BANO_ANCHO[0], mini(BANO_ANCHO[1], cuarto.ancho - 5))
			var bh := rng.randi_range(BANO_FONDO[0], mini(BANO_FONDO[1], cuarto.fondo - 5))
			var mejor := {}
			for esquina in barajar([[0, 0], [1, 0], [0, 1], [1, 1]]):
				var c0: int = cuarto.c0 + cuarto.ancho - bw if esquina[0] else cuarto.c0
				var f0: int = cuarto.f0 + cuarto.fondo - bh if esquina[1] else cuarto.f0
				var cerca := 0   # casillas de salón al otro lado del tabique
				for f in range(f0 - 2, f0 + bh + 2):
					for c in range(c0 - 2, c0 + bw + 2):
						if dueno[f * cols + c] == 0:
							cerca += 1
				if mejor.is_empty() or cerca < mejor.cerca:
					mejor = {"c0": c0, "f0": f0, "cerca": cerca}
			var bano := {"id": salas.size(), "uso": "bano", "puertas": [], "dueno_bano": cuarto.id,
				"c0": mejor.c0, "f0": mejor.f0, "ancho": bw, "fondo": bh}
			cuarto.bano = bano.id
			# el tabique en L que lo separa del dormitorio
			for f in range(bano.f0 - 1, bano.f0 + bh + 1):
				for c in range(bano.c0 - 1, bano.c0 + bw + 1):
					if c < cuarto.c0 or f < cuarto.f0 or c >= cuarto.c0 + cuarto.ancho or f >= cuarto.f0 + cuarto.fondo:
						continue
					var dentro: bool = c >= bano.c0 and c < bano.c0 + bw and f >= bano.f0 and f < bano.f0 + bh
					dueno[f * cols + c] = bano.id if dentro else -1
			salas.append(bano)

	# 4. Qué habitaciones se tocan: tramos de tabique con una habitación a cada lado
	var tramos := []   # {a, b, casillas: [Vector2i], vertical}
	for vertical in [true, false]:
		var fuera := cols if vertical else filas
		var dentro := filas if vertical else cols
		for o in range(1, fuera - 1):
			var tramo := {}
			for i in dentro + 1:
				var c: int = o if vertical else i
				var f: int = i if vertical else o
				var a := -1
				var b := -1
				if i < dentro and dueno[f * cols + c] == -1:
					a = dueno[f * cols + c - 1] if vertical else dueno[(f - 1) * cols + c]
					b = dueno[f * cols + c + 1] if vertical else dueno[(f + 1) * cols + c]
				if not tramo.is_empty() and (a != tramo.a or b != tramo.b):
					tramos.append(tramo)
					tramo = {}
				if a >= 0 and b >= 0 and a != b:
					if tramo.is_empty():
						tramo = {"a": a, "b": b, "casillas": [], "vertical": vertical}
					tramo.casillas.append(Vector2i(c, f))
	var sirven := tramos.filter(func(t): return t.casillas.size() >= PUERTA + 2)   # la puerta y un muro a cada lado
	var entre := func(a: int, b: int) -> Array:
		return sirven.filter(func(t): return (t.a == a and t.b == b) or (t.a == b and t.b == a))

	var puertas := []
	var abrir := func(a: int, b: int) -> void:
		var t: Dictionary = escoger(entre.call(a, b))
		var s := rng.randi_range(1, t.casillas.size() - PUERTA - 1)
		var huecos: Array = t.casillas.slice(s, s + PUERTA)
		for v in huecos:
			dueno[v.y * cols + v.x] = -2
		var p := {"a": a, "b": b, "c": huecos[0].x, "f": huecos[0].y,
			"ancho": 1 if t.vertical else PUERTA, "fondo": PUERTA if t.vertical else 1}
		puertas.append(p)
		salas[a].puertas.append(p)
		salas[b].puertas.append(p)

	if not jefe:
		# Del salón se entra a la cocina y a cada dormitorio; al baño, solo desde su dormitorio
		var principales := salas.filter(func(s): return s.id != 0 and s.uso != "bano")
		var banos := salas.filter(func(s): return s.uso == "bano")
		for s in principales:
			if entre.call(0, s.id).is_empty():
				return {}
		for s in banos:
			if entre.call(s.id, s.dueno_bano).is_empty():
				return {}
		# A veces, además, una puerta entre dos habitaciones vecinas
		var extra := []
		for a in principales:
			for b in principales:
				if a.id < b.id and not entre.call(a.id, b.id).is_empty():
					extra.append([a.id, b.id])
		for s in principales:
			abrir.call(0, s.id)
		for s in banos:
			abrir.call(s.id, s.dueno_bano)
		if not extra.is_empty() and rng.randf() < 0.5:
			var par: Array = escoger(extra)
			abrir.call(par[0], par[1])

	# 5. La puerta de entrada, en un tramo de la pared de delante que dé al salón
	var delante := filas - BORDE - 1
	var sitios := []
	for c in range(BORDE, cols - BORDE - PUERTA + 1):
		var vale := true
		for k in range(-2, PUERTA + 2):
			if dueno[delante * cols + c + k] != 0:
				vale = false
		if vale:
			sitios.append(c)
	if sitios.is_empty():
		return {}
	# en la habitación de un jefe, siempre en el centro de la pared: así el paso limpio de la puerta al medio (el de la
	# porquería del Glotón y el del fuego del bombero) va recto
	var entrada: int = (cols - PUERTA) / 2 if jefe else escoger(sitios)
	var apt := {"cols": cols, "filas": filas, "dueno": dueno, "salas": salas, "puertas": puertas,
		"entrada": {"c": entrada, "lado": "abajo"}, "jefe": jefe}
	describir(apt)
	return apt


# ═════════════ El piso con pasillo ═════════════

# Un piso con pasillo en T (ver arriba), con la puerta de entrada abajo. Devuelve lo mismo que probar(), o {} si esta vez
# no cuadra
static func probar_pasillo(dormitorios: int) -> Dictionary:
	# 1. Qué va delante, a los lados del recibidor: el salón a un lado y, al otro, la cocina o un dormitorio. Y qué va
	#    detrás del pasillo, en fila y en cualquier orden: el baño, los demás dormitorios y, si no está delante, la cocina
	var otro := "cocina" if dormitorios == 1 or rng.randf() < 0.6 else "dormitorio"
	var fila := ["bano", "dormitorio" if otro == "cocina" else "cocina"]
	for i in dormitorios - 1:
		fila.append("dormitorio")
	barajar(fila)

	# 2. Las medidas. El ancho del piso sale de lo que tiene que caber detrás; los dos lados del recibidor miden lo
	#    mismo, así el recibidor y la puerta quedan en el centro
	var recibidor: int = escoger(RECIBIDOR)
	var minimo := fila.size() - 1   # (los tabiques entre las de detrás)
	var maximo := fila.size() - 1
	for uso in fila:
		minimo += ANCHOS[uso][0]
		maximo += ANCHOS[uso][1]
	var lado_min := maxi(LADO[0], ceili((minimo - recibidor - 2) / 2.0))
	var lado_max := mini(LADO[1], floori((maximo - recibidor - 2) / 2.0))
	if lado_min > lado_max:
		return {}
	var lado := rng.randi_range(lado_min, lado_max)
	var iw := lado * 2 + recibidor + 2
	var anchos := repartir_fila(fila, iw)
	if anchos.is_empty():
		return {}
	var detras := rng.randi_range(FONDO_DETRAS[0], FONDO_DETRAS[1])
	var pasillo := rng.randi_range(FONDO_PASILLO[0], FONDO_PASILLO[1])
	var delante := rng.randi_range(FONDO_DELANTE[0], FONDO_DELANTE[1])
	var cols := iw + BORDE * 2
	var filas := BORDE * 2 + detras + 1 + pasillo + 1 + delante
	var tabique1 := BORDE + detras           # el tabique de encima del pasillo
	var tabique2 := tabique1 + pasillo + 1   # y el de debajo

	# 3. Las habitaciones: el salón primero (la habitación 0, como en los otros pisos), luego lo de delante, lo de
	#    detrás y, la última, el pasillo con su recibidor
	var izquierda := rng.randf() < 0.5   # el salón, a la izquierda del recibidor
	var c_izq := BORDE
	var c_der := BORDE + lado + 1 + recibidor + 1
	var salas := [
		{"id": 0, "uso": "salon", "c0": c_izq if izquierda else c_der, "f0": tabique2 + 1, "ancho": lado, "fondo": delante, "puertas": []},
		{"id": 1, "uso": otro, "c0": c_der if izquierda else c_izq, "f0": tabique2 + 1, "ancho": lado, "fondo": delante, "puertas": []}]
	var c := BORDE
	for i in fila.size():
		salas.append({"id": salas.size(), "uso": fila[i], "c0": c, "f0": BORDE, "ancho": anchos[i], "fondo": detras, "puertas": []})
		c += anchos[i] + 1
	for s in salas:
		if maxi(s.ancho, s.fondo) > MAX_LARGO * mini(s.ancho, s.fondo):
			return {}
	# (el pasillo, "tipo" piso: sus muebles, los de "pasillo-piso" del catálogo, y su suelo, el del salón: mapa.gd)
	var hueco := {"id": salas.size(), "uso": "pasillo", "tipo": "piso", "c0": BORDE, "f0": tabique1 + 1, "ancho": iw,
		"fondo": filas - BORDE - tabique1 - 1, "puertas": []}
	salas.append(hueco)
	var dueno := PackedInt32Array()
	dueno.resize(cols * filas)
	dueno.fill(-1)
	var trozos := salas.slice(0, -1).map(func(s): return [s.id, Rect2i(s.c0, s.f0, s.ancho, s.fondo)])
	trozos.append([hueco.id, Rect2i(BORDE, tabique1 + 1, iw, pasillo)])   # el pasillo, de lado a lado
	trozos.append([hueco.id, Rect2i(BORDE + lado + 1, tabique2, recibidor, filas - BORDE - tabique2)])   # y el recibidor
	for t in trozos:
		var r: Rect2i = t[1]
		for f in range(r.position.y, r.end.y):
			for cc in range(r.position.x, r.end.x):
				dueno[f * cols + cc] = t[0]

	# 4. Las puertas, todas al pasillo: las de detrás, en el tabique de encima; las de delante, en el de debajo o, a
	#    veces, en la pared del recibidor. Siempre con un trozo de muro a cada lado
	var puertas := []
	for s in salas.slice(0, -1):
		var p := {}
		if s.f0 == BORDE:
			p = {"c": rng.randi_range(s.c0 + 1, s.c0 + s.ancho - PUERTA - 1), "f": tabique1, "ancho": PUERTA, "fondo": 1}
		elif rng.randf() < A_RECIBIDOR:
			p = {"c": s.c0 + s.ancho if s.c0 == c_izq else s.c0 - 1, "f": rng.randi_range(tabique2 + 2, filas - BORDE - PUERTA - 2),
				"ancho": 1, "fondo": PUERTA}
		else:
			p = {"c": rng.randi_range(s.c0 + 1, s.c0 + s.ancho - PUERTA - 1), "f": tabique2, "ancho": PUERTA, "fondo": 1}
		p.a = hueco.id
		p.b = s.id
		for f in range(p.f, p.f + p.fondo):
			for cc in range(p.c, p.c + p.ancho):
				dueno[f * cols + cc] = -2
		puertas.append(p)
		s.puertas.append(p)
		hueco.puertas.append(p)

	# 5. La puerta de entrada, en el centro de la pared de abajo: da al recibidor
	var apt := {"cols": cols, "filas": filas, "dueno": dueno, "salas": salas, "puertas": puertas,
		"entrada": {"c": (cols - PUERTA) / 2, "lado": "abajo"}, "jefe": false, "forma": "pasillo"}
	describir(apt)
	return apt


# Los anchos de las habitaciones de la fila de detrás del pasillo, para que con sus tabiques llenen justo "ancho"
# (cada una entre su mínimo y su máximo de ANCHOS), o [] si no caben
static func repartir_fila(fila: Array, ancho: int) -> Array:
	var anchos: Array = fila.map(func(uso): return ANCHOS[uso][0])
	var sobra: int = ancho - (fila.size() - 1)
	for a in anchos:
		sobra -= a
	while sobra > 0:
		var crecen: Array = range(fila.size()).filter(func(i): return anchos[i] < ANCHOS[fila[i]][1])
		if crecen.is_empty():
			return []
		anchos[escoger(crecen)] += 1
		sobra -= 1
	return anchos if sobra == 0 else []


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
	# los dormitorios se numeran si hay más de uno, y cada baño lleva el número del suyo (en el piso con pasillo, el
	# baño es de todos: "Baño", sin número)
	var camas: Array = apt.salas.filter(func(s): return s.uso == "dormitorio")
	if camas.size() > 1:
		for i in camas.size():
			camas[i].nombre = "Dormitorio %d" % (i + 1)
			if camas[i].has("bano"):
				apt.salas[camas[i].bano].nombre = "Baño %d" % (i + 1)


# Le da la vuelta de arriba abajo (para los que tienen el pasillo por arriba)
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
	if apt.get("forma", "") == "pasillo":
		# (en el piso con pasillo todas dan al pasillo; el baño, con una sola puerta: ahí se puede esconder el superviviente)
		for s in apt.salas:
			if s.uso == "bano" and s.puertas.size() != 1:
				malos.append("el baño no tiene una sola puerta")
	elif not apt.jefe:
		var unidas := func(a: Dictionary, b: Dictionary) -> bool:
			return a.puertas.any(func(p): return (p.a == a.id and p.b == b.id) or (p.a == b.id and p.b == a.id))
		for s in apt.salas:
			if (s.uso == "cocina" or s.uso == "dormitorio") and not unidas.call(s, apt.salas[0]):
				malos.append(s.uso + " sin puerta al salón")
			if s.uso == "bano" and (s.puertas.size() != 1 or not unidas.call(s, apt.salas[s.dueno_bano])):
				malos.append("el baño no tiene una sola puerta, la de su dormitorio")
	return malos
