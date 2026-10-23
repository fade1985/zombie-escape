# Los peligros de las tiendas del centro comercial (docs/CENTRO_COMERCIAL.md, parte 3): el frío de la cámara
# frigorífica, el fuego de la cocina del restaurante y el agua con corriente de la tienda de electrónica.
# Son como los charcos (charco.gd), pero no se secan nunca. Les hacen daño a Johnny y a los zombis despiertos (a
# los dormidos no: si no, los de la cámara se morirían solos antes de que llegaras), para que se puedan usar a
# propósito: atraer a la horda al agua, encerrarla en la cámara... La esquiva los cruza sin daño, como los charcos.
#
# Aquí están sus números y dónde va cada uno. Se decide al generar la planta (planta.gd llama a de_tienda) y se
# apunta en el sitio ("peligros"): cada tienda tiene siempre el mismo y, al volver, sigue como se dejó (el fuego
# por donde iba, el cuadro eléctrico encendido o apagado). Los monta mapa.gd, cada uno con su nodo:
#   frio.gd   la cámara entera               {tipo, sala, avisado}
#   fuego.gd  casillas de la cocina           {tipo, sala, casillas, focos, arde, apagadas, quemadas, tope, nuevo, avisado}
#   agua.gd   un charco en la sala de venta   {tipo, sala, casillas, cable, cable_desde, cuadro, corriente, arreglado, avisado}
#             con cuadro.gd, el cuadro eléctrico que le quita (y le devuelve) la corriente a la tienda; "arreglado":
#             el técnico ha arreglado el cable (su rescate, averia.gd) y el agua ya no da calambres
# Y los de los minijefes de los Apartamentos (planta.gd llama a del_gloton, a del_gymbro y a de_la_portera):
#   porqueria.gd  la habitación del Glotón   {tipo, sala, casillas (casilla -> 1 charco, 2 con montón),
#                                             paredes (casilla de muro -> forma del pegote), ovalo, avisado}
#   tropiezos.gd  el gimnasio del Gymbro     {tipo, sala, cosas ([{pos, forma, giro}]: "mancuerna"), avisado}
#                 y el cuarto de la limpieza de la portera (las cosas: [{pos, forma "cubo", giro, volcado, color}])
#                 (cosas tiradas por el suelo que hacen caer a Johnny: johnny.gd, caer)
class_name Peligros

const CASILLA := 32
const LADOS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

# El frío de la cámara frigorífica (el supermercado y el restaurante)
const FRIO := {
	"dps": 3.0,          # vida por segundo dentro (a todos)
	"frena": 0.4,        # lo que frena: un 40 % más lento
	"despues": 1.5,      # segundos que dura al salir, hasta entrar en calor
	"congela": 4.0,      # un zombi que pasa estos segundos seguidos dentro se congela...
	"congelado": 2.0,    # ...y se queda quieto y azul este rato
}
# El fuego de la cocina del restaurante. El fogón (o la freidora) arde siempre y de ahí se va extendiendo
const FUEGO := {
	"dps": 12.0,         # a Johnny, como el del molotov (y sigue ardiendo 2 s al salir); a los zombis los prende
	"ronda": 3.0,        # cada cuánto puede prender cada casilla que arde una de al lado...
	"prende": 0.35,      # ...con esta suerte
	"arde": [15.0, 25.0],# lo que arde una casilla antes de apagarse (los focos, siempre)
	"enfria": 10.0,      # lo que tarda una casilla apagada en poder prender otra vez
	"tope": 0.35,        # como mucho, esta parte del suelo de la cocina ardiendo a la vez
	"empieza": 3,        # casillas que ya arden alrededor del foco al generarse...
	"antes": 10,         # ...y las rondas que lleva ardiendo cuando entras por primera vez
}
# El agua con corriente de la tienda de electrónica
const AGUA := {
	"casillas": [25, 35],# lo grande que es el charco
	"pulso": 1.2,        # un calambrazo a todo el charco cada tanto
	"dano": 10,          # a Johnny...
	"tieso": 0.4,        # ...que se queda tieso este rato
	"dano_zombi": 15,    # y a los zombis...
	"aturde": 1.0,       # ...que se quedan aturdidos (y siguen dentro: les vuelve a dar)
	"lejos_entrada": 5,  # casillas libres alrededor de la puerta de la tienda
	"oscuro_con": -0.12, # con corriente, la tienda está más clara que un piso (las teles encendidas)...
	"oscuro_sin": 0.1,   # ...y sin ella, más oscura (solo se ve con la linterna)
	"teles": 4,          # cuántas estanterías de teles dan luz, como mucho
}
# La porquería del Glotón (su habitación, sin más muebles que lámparas): montones de mierda y charcos de diarrea con
# ácido por el suelo (y salpicada por las paredes), que queman a Johnny al pisarla; a los zombis no, que es suya
const PORQUERIA := {
	"dps": 7.0,          # vida por segundo pisándola...
	"despues": 1.0,      # ...y lo que sigue escociendo al salir
	"parte": 0.45,       # qué parte del suelo cubre: una franja pegada a las paredes (en medio, un óvalo limpio para pelear)
	"ondas": 0.09,       # lo que ondula el borde del óvalo (parte de su radio), para que no parezca hecho con compás
	"salientes": 3,      # charcos sueltos que desde la franja se meten un poco en el óvalo...
	"saliente_radio": [1.0, 1.8],   # ...y su radio, en casillas
	"montones": 0.22,    # parte de las casillas sucias que llevan un montón encima
	"paredes": 0.4,      # parte de las casillas de muro pegadas al suelo (lados y abajo) con un pegote encima
}
# Las cosas tiradas por el suelo con las que se tropieza (las mancuernas del gimnasio del Gymbro y los cubos del
# cuarto de la limpieza de la portera): al pisar una, Johnny se cae y tarda en levantarse (sin daño; rodando se pasa
# por encima sin caer). A los zombis y al jefe no les pasa nada. La cosa sale rodando un poco, para que al
# levantarse no se vuelva a caer con la misma
const TROPIEZOS := {
	"mancuernas": 12,    # cuántas en el gimnasio
	"cubos": 10,         # cuántos en el cuarto de la limpieza (son más grandes que una mancuerna)
	"separadas": 110.0,  # como poco, a esta distancia unas de otras
	"lejos_muebles": 26.0,   # ni pegadas a una máquina o a la pared (que se vean y se pueda pasar al lado)
	"lejos_entrada": 90.0,   # ni junto a la puerta (ahí aparece Johnny)
	"pie": 8.0,          # lo cerca que tienen que pasar los pies de Johnny para tropezar
	"caido": 2.0,        # segundos que tarda en levantarse
	"rueda": 120.0,      # lo que sale rodando la cosa al tropezar con ella
}


# Los peligros de una tienda (el sitio, ya con sus muebles). Vacío si su tipo no tiene. Con su propio dado (de la
# semilla del sitio): así no cambia nada de lo demás que sale en la planta
static func de_tienda(sitio: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sitio.surtido) + 4111
	var lista := []
	for s in sitio.apt.salas:
		if s.uso == "camara":
			lista.append({"tipo": "frio", "sala": s.id, "avisado": false})
		elif s.uso == "cocina" and sitio.tienda == "restaurante":
			var f := fuego(sitio, s, rng)
			if not f.is_empty():
				lista.append(f)
	if sitio.tienda == "electronica":
		var a := agua(sitio, rng)
		if not a.is_empty():
			lista.append(a)
	return lista


# La porquería del Glotón: una franja pegada a las paredes de su habitación (la única sala del piso del jefe), y en
# medio un óvalo limpio, la zona de pelea: así no se puede rodear al Glotón bordeando la habitación y hay que luchar
# cerca de él. El óvalo tiene el tamaño justo para que la franja cubra su parte del suelo, con el borde ondulado y
# algún charco suelto que se mete en él; lo de delante de la puerta de entrada queda limpio (ahí aparece Johnny).
# Con su propio dado, como de_tienda. Cada casilla sucia: 1, charco; 2, charco con un montón encima
static func del_gloton(sitio: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sitio.surtido) + 7331
	var apt: Dictionary = sitio.apt
	var sala: Dictionary = apt.salas[0]
	var p: Dictionary = PORQUERIA
	var entrada: Rect2 = Muebles.delante_de({"cols": apt.cols, "filas": apt.filas}, apt.entrada.lado, (apt.entrada.c + 1) * CASILLA)
	# el óvalo: con la forma de la habitación y el área que deja limpia la franja (1 - parte)
	var centro := Vector2(sala.c0 + sala.ancho / 2.0, sala.f0 + sala.fondo / 2.0)
	var escala := sqrt((1.0 - p.parte) * 4.0 / PI)
	var rx: float = sala.ancho / 2.0 * escala
	var ry: float = sala.fondo / 2.0 * escala
	var fase := rng.randf() * TAU
	var fase2 := rng.randf() * TAU
	var casillas := {}
	var sucia := func(c: int, f: int) -> void:
		if dueno(apt, c, f) == sala.id and not entrada.intersects(Rect2(c * CASILLA, f * CASILLA, CASILLA, CASILLA)):
			casillas[Vector2i(c, f)] = 1
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var d := Vector2((c + 0.5 - centro.x) / rx, (f + 0.5 - centro.y) / ry)
			var a := atan2(d.y, d.x)
			var borde: float = 1.0 + p.ondas * sin(a * 3.0 + fase) + p.ondas * 0.55 * sin(a * 7.0 + fase2)
			if d.length() > borde:
				sucia.call(c, f)
	# los charcos sueltos, con el centro en el borde del óvalo
	for i in p.salientes:
		var a := rng.randf() * TAU
		var cx: float = centro.x + cos(a) * rx
		var cy: float = centro.y + sin(a) * ry
		var r: float = rng.randf_range(p.saliente_radio[0], p.saliente_radio[1])
		for f in range(floori(cy - r), ceili(cy + r) + 1):
			for c in range(floori(cx - r), ceili(cx + r) + 1):
				if Vector2(c + 0.5 - cx, (f + 0.5 - cy) / 0.75).length() <= r:
					sucia.call(c, f)
	for key in casillas:
		if rng.randf() < p.montones:
			casillas[key] = 2
	# y los lomos de los muros de los lados y de abajo, salpicados (el de arriba lleva lo suyo en su cara): de las
	# casillas de muro pegadas al suelo, una parte, cada una con una forma (0 a 2)
	var paredes := {}
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			if dueno(apt, c, f) != sala.id:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
				var k: Vector2i = Vector2i(c, f) + d
				if dueno(apt, k.x, k.y) == -1 and not paredes.has(k) and rng.randf() < p.paredes:
					paredes[k] = rng.randi_range(0, 2)
	return [{"tipo": "porqueria", "sala": sala.id, "casillas": casillas, "paredes": paredes, "avisado": false,
		"ovalo": {"centro": centro, "rx": rx, "ry": ry}}]   # (el óvalo, para repartir las luces del resplandor)


# Las mancuernas del gimnasio del Gymbro: unas tumbadas a lo ancho y otras a lo largo (tirar_cosas)
static func del_gymbro(sitio: Dictionary) -> Array:
	return tirar_cosas(sitio, "mancuerna", TROPIEZOS.mancuernas, 5113)


# Los cubos del cuarto de la limpieza de la portera: de pie, con agua sucia, de tres colores (tirar_cosas)
static func de_la_portera(sitio: Dictionary) -> Array:
	return tirar_cosas(sitio, "cubo", TROPIEZOS.cubos, 6217)


# Cosas con las que se tropieza ("mancuerna" o "cubo"), repartidas al azar por el suelo libre de la habitación del
# jefe (la única sala de su piso), separadas unas de otras, sin pegarse a los muebles ni a las paredes y lejos de la
# puerta de entrada. Con su propio dado, como de_tienda. La mancuerna, tumbada a lo ancho o a lo largo ("giro"); el
# cubo, de pie ("volcado": 0; al tropezar con él, vuelca: tropiezos.gd) y de uno de tres colores ("color")
static func tirar_cosas(sitio: Dictionary, forma: String, cuantas: int, semilla: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sitio.surtido) + semilla
	var apt: Dictionary = sitio.apt
	var sala: Dictionary = apt.salas[0]
	var t: Dictionary = TROPIEZOS
	var entrada: Rect2 = Muebles.delante_de({"cols": apt.cols, "filas": apt.filas}, apt.entrada.lado,
		(apt.entrada.c + 1) * CASILLA).grow(t.lejos_entrada)
	var cosas := []
	for intento in 600:
		if cosas.size() >= cuantas:
			break
		var p := Vector2(rng.randf_range(sala.c0, sala.c0 + sala.ancho), rng.randf_range(sala.f0, sala.f0 + sala.fondo)) * CASILLA
		p = (p / 2.0).round() * 2.0   # en píxeles enteros del dibujo
		if not libre_para_cosas(sitio, sala.id, p, t.lejos_muebles) or entrada.has_point(p):
			continue
		if cosas.any(func(k): return k.pos.distance_to(p) < t.separadas):
			continue
		var cosa := {"pos": p, "forma": forma, "giro": 0.0 if rng.randf() < 0.5 else PI / 2.0}
		if forma == "cubo":
			cosa.giro = 0.0
			cosa.volcado = 0
			cosa.color = rng.randi() % 3
		cosas.append(cosa)
	return [{"tipo": "tropiezos", "sala": sala.id, "cosas": cosas, "avisado": false}]


# ¿Puede estar ahí una cosa tirada? En el suelo de la sala, a "margen" de las paredes y de los muebles (por arriba
# de los muebles, más: su dibujo sube y la taparía)
static func libre_para_cosas(sitio: Dictionary, sala: int, p: Vector2, margen: float) -> bool:
	for d in [Vector2(-margen, -margen), Vector2(margen, -margen), Vector2(-margen, margen), Vector2(margen, margen)]:
		var c := casilla(p + d)
		if dueno(sitio.apt, c.x, c.y) != sala:
			return false
	for m in sitio.muebles:
		if Muebles.hueco(m).grow_individual(margen, margen + 50.0, margen, margen).has_point(p):
			return false
	return true


# ¿Hay ahí fuego o agua? (para no poner a los zombis dormidos encima: planta.gd)
static func encima(sitio: Dictionary, pos: Vector2) -> bool:
	var c := casilla(pos)
	for p in sitio.get("peligros", []):
		if p.tipo == "fuego" and p.arde.has(c):
			return true
		if p.tipo == "agua" and c in p.casillas:
			return true
	return false


# La primera vez que Johnny se mete en un peligro (o se acerca al agua con corriente), lo dice en voz alta
static func avisar(nodo: Node, datos: Dictionary, texto: String) -> void:
	if datos.avisado:
		return
	datos.avisado = true
	var partida := nodo.get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(texto)


# ── Casillas ──

static func casilla(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CASILLA), floori(pos.y / CASILLA))


static func centro(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * CASILLA


static func dueno(apt: Dictionary, c: int, f: int) -> int:
	if c < 0 or f < 0 or c >= apt.cols or f >= apt.filas:
		return -1
	return apt.dueno[f * apt.cols + c]


# ¿Tapa un mueble esa casilla? (su centro, dentro de su hueco)
static func bajo_mueble(sitio: Dictionary, c: Vector2i) -> bool:
	for m in sitio.muebles:
		if Muebles.hueco(m).has_point(centro(c)):
			return true
	return false


# Las casillas de alrededor de las puertas de una sala (el hueco y "margen" casillas más a cada lado)
static func junto_a_puertas(apt: Dictionary, sala: int, margen: int) -> Dictionary:
	var cerca := {}
	for p in apt.puertas:
		if p.a != sala and p.b != sala:
			continue
		for f in range(p.f - margen, p.f + p.fondo + margen):
			for c in range(p.c - margen, p.c + p.ancho + margen):
				cerca[Vector2i(c, f)] = true
	return cerca


# La casilla de suelo de la sala que está pegada a una puerta (por donde se entra en ella)
static func al_lado_de(apt: Dictionary, p: Dictionary, sala: int) -> Vector2i:
	for c in [Vector2i(p.c, p.f - 1), Vector2i(p.c, p.f + p.fondo), Vector2i(p.c - 1, p.f), Vector2i(p.c + p.ancho, p.f)]:
		if dueno(apt, c.x, c.y) == sala:
			return c
	return Vector2i(p.c, p.f)


# El camino más corto (en casillas) de "desde" a "hasta" pisando solo las de "pasa"; vacío si no hay
static func camino(pasa: Dictionary, desde: Vector2i, hasta: Vector2i) -> Array:
	var de := {desde: desde}
	var cola := [desde]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		if c == hasta:
			var ruta := [c]
			while ruta[0] != desde:
				ruta.push_front(de[ruta[0]])
			return ruta
		for d in LADOS:
			var n: Vector2i = c + d
			if pasa.has(n) and not de.has(n):
				de[n] = c
				cola.append(n)
	return []


# ── El fuego de la cocina ──
# Puede arder todo el suelo de la cocina menos junto a sus puertas y el camino de la puerta de la cocina a la del
# aseo (y una casilla a cada lado): siempre se puede llegar al superviviente. El foco, delante del fogón o de la
# freidora; si no hay, en una casilla al azar
static func fuego(sitio: Dictionary, sala: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var apt: Dictionary = sitio.apt
	var suelo := {}
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			if dueno(apt, c, f) == sala.id:
				suelo[Vector2i(c, f)] = true
	var libre := junto_a_puertas(apt, sala.id, 1)
	var entradas := []
	for p in apt.puertas:
		if p.a == sala.id or p.b == sala.id:
			entradas.append(al_lado_de(apt, p, sala.id))
	for i in range(1, entradas.size()):
		for c in camino(suelo, entradas[0], entradas[i]):
			libre[c] = true
			for d in LADOS:
				libre[c + d] = true
	var casillas := []
	for c in suelo:
		if not libre.has(c):
			casillas.append(c)
	if casillas.is_empty():
		return {}
	var focos := []
	for m in sitio.muebles:
		if m.zona == sala.id and (m.tipo == "industrialstove" or m.tipo == "fryer"):
			var h := Muebles.hueco(m)
			var c := casilla(Vector2(h.get_center().x, h.end.y + CASILLA * 0.5))
			if c in casillas and not c in focos:
				focos.append(c)
	if focos.is_empty():
		focos.append(casillas[rng.randi() % casillas.size()])
	var arde := {}
	for c in focos:
		arde[c] = INF   # los focos no se apagan nunca
	# unas pocas más alrededor del foco
	for i in FUEGO.empieza:
		var vecinas := []
		for c in arde:
			for d in LADOS:
				if c + d in casillas and not arde.has(c + d):
					vecinas.append(c + d)
		if vecinas.is_empty():
			break
		arde[vecinas[rng.randi() % vecinas.size()]] = rng.randf_range(FUEGO.arde[0], FUEGO.arde[1])
	return {"tipo": "fuego", "sala": sala.id, "casillas": casillas, "focos": focos, "arde": arde, "apagadas": {},
		"quemadas": {}, "tope": maxi(focos.size() + 2, roundi(suelo.size() * FUEGO.tope)), "nuevo": true, "avisado": false}


# ── El agua de la tienda de electrónica ──
# Un charco con forma de mancha en la sala de venta, lejos de la puerta de la tienda y de las de dentro, y que
# siempre deja camino desde la entrada a todas las habitaciones del fondo sin pisarlo. El cable pelado llega desde
# la pared más cercana. Y el cuadro eléctrico, en la pared de arriba del almacén o de las taquillas
static func agua(sitio: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var apt: Dictionary = sitio.apt
	var entrada := Vector2i(apt.entrada.c, apt.filas - Tienda.BORDE - 1 if apt.entrada.lado == "abajo" else Tienda.BORDE)
	var cerca := junto_a_puertas(apt, 0, 2)
	var suelo := {entrada: true}   # por donde se anda: suelo sin muebles y huecos de puerta
	var sitios := []               # donde puede haber agua
	for f in apt.filas:
		for c in apt.cols:
			var k := Vector2i(c, f)
			var d := dueno(apt, c, f)
			if d == -2 or (d == 0 and not bajo_mueble(sitio, k)):
				suelo[k] = true
			if d == 0 and not cerca.has(k) and Vector2(k - entrada).length() > AGUA.lejos_entrada:
				sitios.append(k)
	if sitios.is_empty():
		return {}
	var dentro: Array = apt.puertas.filter(func(p): return p.a == 0 or p.b == 0)
	var se_puede := {}
	for k in sitios:
		se_puede[k] = true
	for intento in 40:
		var cuantas := rng.randi_range(AGUA.casillas[0], AGUA.casillas[1])
		var charco := {sitios[rng.randi() % sitios.size()]: true}
		while charco.size() < cuantas:
			# las vecinas que pueden mojarse, repetidas por cada vecina mojada que tengan: sale redondeado
			var opciones := []
			for k in charco:
				for d in LADOS:
					if se_puede.has(k + d) and not charco.has(k + d):
						opciones.append(k + d)
			if opciones.is_empty():
				break
			charco[opciones[rng.randi() % opciones.size()]] = true
		if charco.size() < AGUA.casillas[0]:
			continue
		var pasa := suelo.duplicate()
		for k in charco:
			pasa.erase(k)
		if dentro.any(func(p): return camino(pasa, entrada, Vector2i(p.c, p.f)).is_empty()):
			continue
		# el cable: desde el pie de la pared (de arriba) más cercano a una casilla del charco
		var mejor := {}
		for k in charco:
			for f in range(maxi(0, k.y - 8), k.y + 1):
				for c in range(k.x - 8, k.x + 9):
					if dueno(apt, c, f) == 0 and dueno(apt, c, f - 1) == -1 and not bajo_mueble(sitio, Vector2i(c, f)):
						var largo: float = absi(c - k.x) + absi(f - k.y) + (0.5 if dueno(apt, c - 1, f - 1) != -1 or dueno(apt, c + 1, f - 1) != -1 else 0.0)
						if mejor.is_empty() or largo < mejor.largo:
							mejor = {"largo": largo, "agua": k, "pared": Vector2i(c, f)}
		if mejor.is_empty():
			continue
		var cuadro := cuadro_electrico(sitio, rng)
		if cuadro.is_empty():
			continue
		return {"tipo": "agua", "sala": 0, "casillas": charco.keys(), "cable": mejor.agua,
			"cable_desde": Vector2((mejor.pared.x + 0.5) * CASILLA, mejor.pared.y * CASILLA), "cuadro": cuadro,
			"corriente": true, "arreglado": false, "avisado": false}
	return {}


# El cuadro eléctrico, colgado en la pared de arriba de una habitación del fondo (como el armarito del baño:
# planta.armaritos): lo más centrado posible, sin tapar una puerta y sin un mueble debajo (las taquillas y las
# estanterías lo taparían). Si no cabe en ninguna, en la pared de arriba de la sala de venta. {x, y (el pie de la
# pared), alcance (hasta dónde se puede usar desde delante), sala}
static func cuadro_electrico(sitio: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var apt: Dictionary = sitio.apt
	var salas: Array = apt.salas.filter(func(s): return s.uso == "almacen" or s.uso == "taquillas")
	if rng.randf() < 0.5:
		salas.reverse()   # unas veces en una y otras en la otra
	salas.append(apt.salas[0])   # si no cabe en ninguna, en la sala de venta
	for s in salas:
		var mejor := {}
		for c in range(s.c0 + 1, s.c0 + s.ancho - 1):
			var muro := true
			for dc in [-1, 0, 1]:
				if dueno(apt, c + dc, s.f0 - 1) != -1 or dueno(apt, c + dc, s.f0) != s.id:
					muro = false
			if not muro:
				continue
			var x := (c + 0.5) * CASILLA
			var tapado := false
			for m in sitio.muebles:
				var h := Muebles.hueco(m)
				if m.zona == s.id and h.position.y < s.f0 * CASILLA + 8 and absf(m.x - x) < h.size.x / 2.0 + 18.0:
					tapado = true
			if tapado:
				continue
			var nota := absf(x - (s.c0 + s.ancho / 2.0) * CASILLA)
			if mejor.is_empty() or nota < mejor.nota:
				mejor = {"x": x, "y": float(s.f0 * CASILLA), "alcance": 70.0, "sala": s.id, "nota": nota}
		if not mejor.is_empty():
			return mejor
	return {}
