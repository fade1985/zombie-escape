# Dónde va cada mueble (como src/furniture.js y src/rooms.js del juego JS). Qué muebles hay y qué lleva cada
# sala, en catalogo.gd; aquí solo se decide el sitio. Lo monta en el mapa mueble.gd.
#
# Los muebles van pegados a las paredes, nunca delante de una puerta, y sin cortar el paso: después de poner
# cada uno se comprueba que se sigue pudiendo andar a todas partes (si no, se quita).
#
# Cada mueble es un diccionario: {tipo, lado ("arriba", "abajo", "izquierda", "derecha": la pared en la que se
# apoya), x, y (el centro del hueco que ocupa en el suelo), w, h (su ancho y su alto en el suelo), zona}.
#
# "geo" es el plano del sitio: {cols, filas, dueno} (de quién es cada casilla: su habitación, -1 muro, -2 hueco
# de puerta; como en apartamento.gd).
class_name Muebles

const CASILLA := 32
const MURO := 64
const PUERTA := 64          # ancho de las puertas
const SEPARA := 8           # separación mínima entre los muebles de una plantilla
const HONDO := 60           # fondo del mueble más hondo: la franja de suelo que se mira para no tapar puertas
const HOLGURA := 20         # lo que necesita un personaje a cada lado para pasar


# ═════════════ Sitios enteros ═════════════

# Los muebles de un apartamento: cada habitación, los suyos
static func de_apartamento(apt: Dictionary, rng: RandomNumberGenerator) -> Array:
	var geo := {"cols": apt.cols, "filas": apt.filas, "dueno": apt.dueno}
	# Lo que tiene que quedar libre: delante de la entrada y los dos lados de cada puerta de dentro
	var fila: int = apt.filas - 3 if apt.entrada.lado == "abajo" else 2
	var en: float = (apt.entrada.c + 1) * CASILLA
	var despejar := [delante_de(geo, apt.entrada.lado, en)]
	var puntos := [Vector2(en, (fila + 0.5) * CASILLA)]
	for d in apt.puertas:
		var x: float = (d.c + d.ancho / 2.0) * CASILLA
		var y: float = (d.f + d.fondo / 2.0) * CASILLA
		if d.fondo == 1:   # hueco en un tabique horizontal: se cruza de arriba abajo
			despejar.append(Rect2(x - 64, y - 104, 128, 208))
			puntos += [Vector2(x, y - 56), Vector2(x, y + 56)]
		else:
			despejar.append(Rect2(x - 104, y - 64, 208, 128))
			puntos += [Vector2(x - 56, y), Vector2(x + 56, y)]
	var paso := Paso.new(geo, puntos)

	var lista := []
	for s in apt.salas:
		var uso: String = s.uso
		# en una tienda, primero los de su tipo (la sala de venta del supermercado, la cocina del restaurante...)
		var propio := "%s-%s" % [uso, apt.get("tipo", "")]
		if Catalogo.SALAS.has(propio):
			uso = propio
		var datos: Dictionary = Catalogo.SALAS[uso]
		var cuantos: Array = datos.cuantos
		# en las habitaciones grandes cabe algún mueble más
		var extra := mini(2, floori(s.casillas / 220.0))
		var fondo: Array = pared_fondo(uso, rng, geo, s.id, despejar, paso) if datos.has("plantillas") else []
		if not fondo.is_empty():
			lista += fondo
		else:
			lista += sueltos(uso, rng, geo, cuantos[0] + extra, cuantos[1] + extra,
				{"zona": s.id, "despejar": despejar, "paso": paso})
		if datos.has("islas"):
			lista += islas(datos.islas, rng, geo, s.id, despejar, paso, lista)
	return lista


# ═════════════ Filas en medio de la sala ═════════════

# Las salas de venta de las tiendas son grandes: además de los muebles de las paredes, filas de muebles en medio
# (góndolas, estanterías, mesas...) con pasillos entre ellas. "isla" (de Catalogo.SALAS): muebles (de qué tipos,
# al azar), fila (cuántos seguidos como mucho), entre (el hueco entre dos de la misma fila) y cada (cada cuánto va
# una fila, de pie a pie; lo bastante para que el dibujo de una no tape la de detrás y quede pasillo). Todo lejos
# de las paredes (MARGEN_ISLA), sin tapar puertas ni cortar el paso.
const MARGEN_ISLA := 104.0
const PASILLO_ISLA := 96.0   # el pasillo entre dos tramos de la misma fila

static func islas(isla: Dictionary, rng: RandomNumberGenerator, geo: Dictionary, zona: int, despejar: Array,
		paso: Paso, puestos: Array) -> Array:
	# las casillas de la sala: su rectángulo
	var c0: int = geo.cols
	var c1 := -1
	var f0: int = geo.filas
	var f1 := -1
	for f in geo.filas:
		for c in geo.cols:
			if geo.dueno[f * geo.cols + c] == zona:
				c0 = mini(c0, c)
				c1 = maxi(c1, c)
				f0 = mini(f0, f)
				f1 = maxi(f1, f)
	if c1 < 0:
		return []
	var x0 := c0 * CASILLA + MARGEN_ISLA
	var x1 := (c1 + 1) * CASILLA - MARGEN_ISLA
	var y0 := f0 * CASILLA + MARGEN_ISLA + 40.0   # arriba, más: los muebles de la pared de arriba son altos
	var y1 := (f1 + 1) * CASILLA - MARGEN_ISLA
	var puestas := []
	var y := y0 + rng.randf() * 32.0
	while true:
		# los tipos de cada fila, al azar, y cuánto mide
		var tipos := []
		for i in isla.fila:
			tipos.append(isla.muebles[rng.randi() % isla.muebles.size()])
		var fondo := 0.0
		for t in tipos:
			fondo = maxf(fondo, Catalogo.MUEBLES[t].dep)
		if y + fondo > y1:
			break
		var largo: float = -float(isla.entre)
		for t in tipos:
			largo += Catalogo.MUEBLES[t].len + isla.entre
		# cuántos tramos caben a lo ancho (con su pasillo entre uno y otro), centrados
		var tramos := floori((x1 - x0 + PASILLO_ISLA) / (largo + PASILLO_ISLA))
		var x := (x0 + x1) / 2.0 - (tramos * largo + (tramos - 1) * PASILLO_ISLA) / 2.0
		for k in tramos:
			for t in tipos:
				var l: float = Catalogo.MUEBLES[t].len
				var en := roundf((x + l / 2.0) / 2.0) * 2.0
				var m := nuevo(t, {"lado": "arriba", "base": y + fondo - Catalogo.MUEBLES[t].dep}, en, zona)
				var r := hueco(m)
				if en_sala(geo, r.grow(24.0), zona) and not despejar.any(func(d): return d.intersects(r)) \
						and not (puestos + puestas).any(func(p): return hueco(p).grow(10).intersects(r)) and paso.cabe(r):
					puestas.append(m)
				x += l + isla.entre
			x += PASILLO_ISLA - isla.entre
		y += isla.cada
	return puestas


# ¿Cae el rectángulo entero en suelo de esa habitación?
static func en_sala(geo: Dictionary, r: Rect2, zona: int) -> bool:
	for f in range(floori(r.position.y / CASILLA), floori((r.end.y - 1) / CASILLA) + 1):
		for c in range(floori(r.position.x / CASILLA), floori((r.end.x - 1) / CASILLA) + 1):
			if c < 0 or f < 0 or c >= geo.cols or f >= geo.filas or geo.dueno[f * geo.cols + c] != zona:
				return false
	return true


# Los muebles de un sitio rectangular (el pasillo o la sala de mantenimiento). "salidas" son sus puertas (como
# en planta.gd): delante de ellas no se pone nada. "puntos" son los sitios entre los que se tiene que poder andar.
# "reservado": más rectángulos que dejar libres.
static func de_sala(uso: String, geo: Dictionary, salidas: Array, puntos: Array, rng: RandomNumberGenerator,
		reservado := []) -> Array:
	var despejar := reservado.duplicate()
	for s in salidas:
		despejar.append(delante_de(geo, s.dir, s.en))
	var datos: Dictionary = Catalogo.SALAS[uso]
	return sueltos(uso, rng, geo, datos.cuantos[0], datos.cuantos[1], {"despejar": despejar,
		"paso": Paso.new(geo, puntos), "fondo_max": datos.get("fondo_max", 9999)})


# El plano de un sitio rectangular: muros de 2 casillas alrededor y todo el suelo es la "habitación" 0
static func plano_rectangular(cols: int, filas: int) -> PackedInt32Array:
	var dueno := PackedInt32Array()
	dueno.resize(cols * filas)
	dueno.fill(-1)
	for f in range(2, filas - 2):
		for c in range(2, cols - 2):
			dueno[f * cols + c] = 0
	return dueno


# Lo que tiene que quedar libre delante de una puerta
static func delante_de(geo: Dictionary, dir: String, en: float) -> Rect2:
	var medio := PUERTA / 2.0 + 44.0
	var hondo := 130.0
	var ancho: float = geo.cols * CASILLA
	var alto: float = geo.filas * CASILLA
	match dir:
		"arriba": return Rect2(en - medio, MURO, medio * 2.0, hondo)
		"abajo": return Rect2(en - medio, alto - MURO - hondo, medio * 2.0, hondo)
		"izquierda": return Rect2(MURO, en - medio, hondo, medio * 2.0)
	return Rect2(ancho - MURO - hondo, en - medio, hondo, medio * 2.0)


# ═════════════ Piezas ═════════════

static func es_muro(geo: Dictionary, c: int, f: int) -> bool:
	return c < 0 or f < 0 or c >= geo.cols or f >= geo.filas or geo.dueno[f * geo.cols + c] == -1


# En la pared de arriba van todos: se les ve de frente. En las laterales, los que tienen dibujo de lado o se
# ven igual desde cualquier sitio. En la de abajo, solo estos últimos.
static func va_en(tipo: String, lado: String) -> bool:
	var paredes: String = Catalogo.MUEBLES[tipo].paredes
	return lado == "arriba" or paredes == "todas" or (lado != "abajo" and paredes == "lados")


# Tramos de pared: cada borde donde el suelo toca un muro, también los de los tabiques. Cada tramo:
# {lado, a, b (dónde empieza y acaba, a lo largo de la pared), base (la "y" de la pared en las de arriba y
# abajo, la "x" en las laterales)}. Con "zona" (>= 0) solo se miran las casillas de esa habitación.
static func tramos(geo: Dictionary, zona := -99) -> Array:
	var lista := []
	var mia := func(c: int, f: int) -> bool:
		return not es_muro(geo, c, f) and (zona == -99 or geo.dueno[f * geo.cols + c] == zona)
	# recorre una fila (o columna) y junta las casillas seguidas que tienen muro en ese lado
	var recorrer := func(lado: String, largo: int, tiene: Callable, base: float) -> void:
		var i := 0
		while i < largo:
			if not tiene.call(i):
				i += 1
				continue
			var i0 := i
			while i < largo and tiene.call(i):
				i += 1
			if (i - i0) * CASILLA - 8 >= 30:
				lista.append({"lado": lado, "a": i0 * CASILLA + 4.0, "b": i * CASILLA - 4.0, "base": base})
	for f in range(1, geo.filas - 1):
		recorrer.call("arriba", geo.cols, func(c): return mia.call(c, f) and es_muro(geo, c, f - 1), f * CASILLA)
		recorrer.call("abajo", geo.cols, func(c): return mia.call(c, f) and es_muro(geo, c, f + 1), (f + 1) * CASILLA)
	for c in range(1, geo.cols - 1):
		recorrer.call("izquierda", geo.filas, func(f): return mia.call(c, f) and es_muro(geo, c - 1, f), c * CASILLA)
		recorrer.call("derecha", geo.filas, func(f): return mia.call(c, f) and es_muro(geo, c + 1, f), (c + 1) * CASILLA)
	return lista


# ¿Cae el rectángulo entero en el suelo (sin tocar ningún muro)?
static func en_suelo(geo: Dictionary, r: Rect2) -> bool:
	for f in range(floori((r.position.y + 1) / CASILLA), floori((r.end.y - 1) / CASILLA) + 1):
		for c in range(floori((r.position.x + 1) / CASILLA), floori((r.end.x - 1) / CASILLA) + 1):
			if es_muro(geo, c, f):
				return false
	return true


static func hueco(m: Dictionary) -> Rect2:
	return Rect2(m.x - m.w / 2.0, m.y - m.h / 2.0, m.w, m.h)


# Un mueble apoyado en la pared "lado", centrado en "a_lo_largo"
static func nuevo(tipo: String, tramo: Dictionary, a_lo_largo: float, zona: int) -> Dictionary:
	var p: Dictionary = Catalogo.MUEBLES[tipo]
	var m := {"tipo": tipo, "lado": tramo.lado, "zona": zona}
	match tramo.lado:
		"arriba", "abajo":
			m.x = a_lo_largo
			m.w = p.len
			m.h = p.dep
			m.y = tramo.base + p.dep / 2.0 if tramo.lado == "arriba" else tramo.base - p.dep / 2.0
		_:
			m.y = a_lo_largo
			m.w = p.dep
			m.h = p.len
			m.x = tramo.base + p.dep / 2.0 if tramo.lado == "izquierda" else tramo.base - p.dep / 2.0
	return m


# ═════════════ Muebles sueltos ═════════════

# Entre "minimo" y "maximo" muebles al azar por las paredes. Opciones:
#   zona       solo dentro de esa habitación
#   despejar   rectángulos que tienen que quedar libres (delante de las puertas)
#   paso       el comprobador de que se sigue pudiendo pasar (Paso)
#   fondo_max  fondo máximo de los muebles (para sitios estrechos, como el pasillo)
static func sueltos(uso: String, rng: RandomNumberGenerator, geo: Dictionary, minimo: int, maximo: int,
		op: Dictionary) -> Array:
	var datos: Dictionary = Catalogo.SALAS[uso]
	var iguales: Dictionary = datos.get("iguales", {})
	var zona: int = op.get("zona", -99)
	var despejar: Array = op.get("despejar", [])
	var paso: Paso = op.get("paso")
	var surtido: Array = datos.muebles.filter(func(t): return Catalogo.MUEBLES[t].dep <= op.get("fondo_max", 9999))
	var quiere := minimo + rng.randi() % (maximo - minimo + 1)
	var todos := tramos(geo, zona)
	var de_arriba := todos.filter(func(t): return t.lado == "arriba")
	var puestos := []
	var intento := 0
	while not surtido.is_empty() and not todos.is_empty() and puestos.size() < quiere and intento < 240:
		intento += 1
		# primero la pared (mejor las de arriba, donde cabe cualquier mueble) y luego un mueble que valga para ella
		var de: Array = de_arriba if not de_arriba.is_empty() and rng.randf() < 0.55 else todos
		var tramo: Dictionary = de[rng.randi() % de.size()]
		var valen := surtido.filter(func(t): return va_en(t, tramo.lado) \
			and Catalogo.MUEBLES[t].len <= tramo.b - tramo.a \
			and puestos.filter(func(p): return p.tipo == t).size() < iguales.get(t, 1))
		if valen.is_empty():
			continue
		var tipo: String = valen[rng.randi() % valen.size()]
		var largo: float = Catalogo.MUEBLES[tipo].len
		# en píxeles enteros del dibujo (2 unidades)
		var en := roundf((tramo.a + largo / 2.0 + rng.randf() * (tramo.b - tramo.a - largo)) / 2.0) * 2.0
		var m := nuevo(tipo, tramo, en, zona)
		var r := hueco(m)
		# entero en el suelo, sin tapar una puerta, sin pegarse a otro y sin cortar el paso
		if not en_suelo(geo, r):
			continue
		if despejar.any(func(k): return k.intersects(r)):
			continue
		if puestos.any(func(p): return hueco(p).grow(10).intersects(r)):
			continue
		if paso and not paso.cabe(r):
			continue
		puestos.append(m)
	return puestos


# ═════════════ Plantillas de la pared del fondo ═════════════

# Amuebla la pared del fondo de una habitación (sus tramos de arriba) con una de sus plantillas. Si la pared
# tiene una puerta, o delante de una puerta lateral hay que dejar sitio, los muebles se reparten por los trozos
# libres que quedan, en el mismo orden.
static func pared_fondo(uso: String, rng: RandomNumberGenerator, geo: Dictionary, zona: int, despejar: Array,
		paso: Paso) -> Array:
	var de_arriba := tramos(geo, zona).filter(func(t): return t.lado == "arriba")
	if de_arriba.is_empty():
		return []
	var base: float = de_arriba[0].base
	for t in de_arriba:
		base = minf(base, t.base)
	# trozos libres de la pared: sus tramos, quitando lo que tiene que quedar despejado
	var libres := []
	for t in de_arriba:
		if t.base == base:
			libres.append(Vector2(t.a, t.b))
	for k in despejar:
		if k.end.y <= base or k.position.y >= base + HONDO:
			continue
		var cortados := []
		for l in libres:
			for trozo in [Vector2(l.x, minf(l.y, k.position.x)), Vector2(maxf(l.x, k.end.x), l.y)]:
				if trozo.y - trozo.x >= 30:
					cortados.append(trozo)
		libres = cortados
	libres.sort_custom(func(p, q): return p.x < q.x)

	var datos: Dictionary = Catalogo.SALAS[uso]
	var plantillas: Array = datos.plantillas.duplicate()
	# barajadas con el dado del mapa (shuffle() usaría otro)
	for i in range(plantillas.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = plantillas[i]
		plantillas[i] = plantillas[j]
		plantillas[j] = t
	for plantilla in plantillas:
		# primero entera; si no cabe, quitando opcionales uno a uno, en el orden de "quitar"
		var tipos: Array = plantilla.map(func(t): return t.trim_suffix("?"))
		var opcionales: Array = plantilla.filter(func(t): return t.ends_with("?")).map(func(t): return t.trim_suffix("?"))
		opcionales.sort_custom(func(p, q): return datos.quitar.find(p) < datos.quitar.find(q))
		var grupos := repartir(tipos, libres)
		while grupos.is_empty() and not opcionales.is_empty():
			var fuera: String = opcionales.pop_front()
			tipos = tipos.filter(func(t): return t != fuera)   # todos los de ese tipo: las dos mesillas a la vez
			grupos = repartir(tipos, libres)
		if grupos.is_empty():
			continue
		# en cada trozo, el sitio que sobra se reparte en huecos al azar (a los lados y entre muebles)
		var puestos := []
		for g in grupos.size():
			var ts: Array = grupos[g]
			if ts.is_empty():
				continue
			var trozo: Vector2 = libres[g]
			var ocupa := 0.0
			for t in ts:
				ocupa += Catalogo.MUEBLES[t].len
			var sobra: float = trozo.y - trozo.x - ocupa - SEPARA * (ts.size() - 1)
			var cortes := []
			for t in ts:
				cortes.append(rng.randf())
			cortes += [rng.randf() * 0.5, rng.randf() * 0.5]
			var suma := 0.0
			for v in cortes:
				suma += v
			var x: float = trozo.x + sobra * cortes[ts.size()] / suma
			for i in ts.size():
				var largo: float = Catalogo.MUEBLES[ts[i]].len
				var cx := roundf((x + largo / 2.0) / 2.0) * 2.0
				puestos.append(nuevo(ts[i], {"lado": "arriba", "base": base}, cx, zona))
				x += largo + SEPARA + (sobra * cortes[i] / suma if i < ts.size() - 1 else 0.0)
		if not puestos.all(func(m): return en_suelo(geo, hueco(m))):
			continue
		# el comprobador deja apuntado cada mueble que acepta: nos quedamos con los que quepan (casi siempre, todos)
		var quedan := puestos.filter(func(m): return paso == null or paso.cabe(hueco(m)))
		if not quedan.is_empty():
			return quedan
	return []


# Reparte los muebles, por orden, en los trozos libres: cada uno en el primero donde aún quepa. Devuelve un
# grupo de tipos por trozo, o [] si no caben todos.
static func repartir(tipos: Array, libres: Array) -> Array:
	var grupos := []
	for l in libres:
		grupos.append([])
	var i := 0
	var usado := 0.0
	for t in tipos:
		var largo: float = Catalogo.MUEBLES[t].len
		while i < libres.size() and usado + (SEPARA if not grupos[i].is_empty() else 0) + largo > libres[i].y - libres[i].x:
			i += 1
			usado = 0.0
		if i >= libres.size():
			return []
		usado += (SEPARA if not grupos[i].is_empty() else 0) + largo
		grupos[i].append(t)
	return grupos


# ═════════════ ¿Se sigue pudiendo pasar? ═════════════

# Para cada mueble nuevo dice si, después de ponerlo, se sigue pudiendo andar entre todos los "puntos" y no
# queda ningún rincón de suelo aislado (un zombi o la llave podrían caer ahí); si es así, lo da por puesto.
# Trabaja en una cuadrícula fina, de media casilla, con el hueco que necesita un personaje para pasar.
class Paso:
	const LADO := 16.0
	var cols := 0
	var filas := 0
	var libre := PackedByteArray()   # 1 = ahí cabe un personaje
	var quedan := 0                  # cuántas casillas libres hay
	var metas := []
	var siempre := false             # si el plano ya venía raro: mejor muebles de más que ninguno

	func _init(geo: Dictionary, puntos: Array) -> void:
		cols = geo.cols * 2
		filas = geo.filas * 2
		libre.resize(cols * filas)
		for f in filas:
			for c in cols:
				var centro := Vector2((c + 0.5) * LADO, (f + 0.5) * LADO)
				if Muebles.en_suelo(geo, Rect2(centro - Vector2(HOLGURA, HOLGURA), Vector2(HOLGURA, HOLGURA) * 2.0)):
					libre[f * cols + c] = 1
					quedan += 1
		for p in puntos:
			metas.append(int(p.y / LADO) * cols + int(p.x / LADO))
		siempre = metas.any(func(m): return libre[m] == 0) or alcanzables() != quedan

	# a cuántas casillas se llega andando desde la primera meta
	func alcanzables() -> int:
		var visto := PackedByteArray()
		visto.resize(libre.size())
		var pila: Array[int] = [metas[0]]
		visto[metas[0]] = 1
		var n := 1
		while not pila.is_empty():
			var i: int = pila.pop_back()
			var c := i % cols
			for j in [i - cols, i + cols, i - 1 if c > 0 else -1, i + 1 if c < cols - 1 else -1]:
				if j >= 0 and j < libre.size() and libre[j] == 1 and visto[j] == 0:
					visto[j] = 1
					n += 1
					pila.append(j)
		return n

	func cabe(r: Rect2) -> bool:
		if siempre:
			return true
		var zona := r.grow(HOLGURA)
		var quitadas: Array[int] = []
		for f in range(maxi(0, floori(zona.position.y / LADO)), mini(filas - 1, floori(zona.end.y / LADO)) + 1):
			for c in range(maxi(0, floori(zona.position.x / LADO)), mini(cols - 1, floori(zona.end.x / LADO)) + 1):
				var i := f * cols + c
				var centro := Vector2((c + 0.5) * LADO, (f + 0.5) * LADO)
				if libre[i] == 1 and zona.has_point(centro):
					libre[i] = 0
					quitadas.append(i)
		if metas.all(func(m): return libre[m] == 1) and alcanzables() == quedan - quitadas.size():
			quedan -= quitadas.size()
			return true
		for i in quitadas:
			libre[i] = 1
		return false
