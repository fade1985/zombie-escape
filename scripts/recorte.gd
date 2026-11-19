# Los efectos no se pintan encima de las paredes ni al otro lado (10 nov): la explosión, la escarcha, el fuego y el
# humo del molotov, los charcos, las quemaduras, los efectos de pixelfx (EfectoSuelo) y las partículas llevan uno de
# estos materiales, que comparten todos. El mapa, al montarse, le pasa sus muros (preparar): una máscara con un punto por
# casilla. Cómo se recorta cada píxel, en escenas/armas/recorte.gdshaderinc. Se prueba con --captura --efectos-pared
class_name Recorte
extends RefCounted

const SHADER := preload("res://escenas/armas/recorte.gdshader")
const SHADER_SUMA := preload("res://escenas/armas/recorte_suma.gdshader")   # (las capas de brillo que se suman)
const SHADER_VUELA := preload("res://escenas/armas/recorte_vuela.gdshader")   # (lo que vuela con su altura: los cachos)
const MODOS := {"suelo": 0, "aire": 1, "punto": 2, "vuela": 2}
const CARA := 96.0   # lo que sube la cara de un muro desde su pie (cara_pared.gd, ALTO): lo que tapa y hasta dónde se ve

static var materiales := {}
static var mascara: ImageTexture = null
static var origen := Vector2.ZERO
static var medida := Vector2.ZERO   # (0: no hay mapa, no se recorta)
static var de_mapa: Object = null   # el mapa del que es la máscara
static var muros := PackedByteArray()   # la máscara, también aquí (para muro_en, techo y tapa): 0 en los muros
static var columnas := 0
static var casilla := 32.0


# El material de un modo ("suelo", "aire" o "punto"; ver recorte.gdshaderinc; o "vuela": recorte_vuela.gdshader).
# "suma": para las capas que se suman
static func material(modo: String, suma := false) -> ShaderMaterial:
	var clave := modo + ("+" if suma else "")
	if not materiales.has(clave):
		var m := ShaderMaterial.new()
		m.shader = SHADER_VUELA if modo == "vuela" else SHADER_SUMA if suma else SHADER
		m.set_shader_parameter("modo", MODOS[modo])
		poner(m)
		materiales[clave] = m
	return materiales[clave]


static func poner(m: ShaderMaterial) -> void:
	m.set_shader_parameter("mascara", mascara)
	m.set_shader_parameter("origen", origen)
	m.set_shader_parameter("medida", medida)


# Al montar un mapa: blanco donde se puede pisar (suelo y huecos de puerta), negro en los muros
static func preparar(mapa: Node2D) -> void:
	var datos := PackedByteArray()
	datos.resize(mapa.cols * mapa.filas)
	for f in mapa.filas:
		for c in mapa.cols:
			datos[f * mapa.cols + c] = 0 if mapa.es_muro(c, f) else 255
	mascara = ImageTexture.create_from_image(Image.create_from_data(mapa.cols, mapa.filas, false, Image.FORMAT_R8, datos))
	origen = mapa.global_position if mapa.is_inside_tree() else mapa.position
	medida = Vector2(mapa.cols, mapa.filas) * mapa.CASILLA
	de_mapa = mapa
	muros = datos
	columnas = mapa.cols
	casilla = mapa.CASILLA
	for m in materiales.values():
		poner(m)


# Al irse ese mapa (sin mapa, como en los menús, no se recorta nada)
static func quitar(mapa: Node2D) -> void:
	if de_mapa != mapa:
		return   # (ya se ha montado otro)
	de_mapa = null
	medida = Vector2.ZERO
	for m in materiales.values():
		poner(m)


# ── Lo mismo que recorte_vuela.gdshader, para lo que no se dibuja con él (20 nov: que nada del zombi explosivo pase
# las paredes). Todo en el mundo (posiciones globales) ──

# Si en ese punto hay un muro (o es fuera del mapa). Sin mapa, nunca
static func muro_en(p: Vector2) -> bool:
	if medida.x <= 0.0:
		return false
	var c := floori((p.x - origen.x) / casilla)
	var f := floori((p.y - origen.y) / casilla)
	if c < 0 or f < 0 or c >= columnas or (f * columnas + c) >= muros.size():
		return true
	return muros[f * columnas + c] == 0


# El techo de lo que vuela sobre el suelo "suelo": lo alto de la cara del primer muro de encima (hasta 4 casillas);
# más arriba ya se vería en la habitación de al lado. -INF si no hay
static func techo(suelo: Vector2) -> float:
	if medida.x <= 0.0:
		return -INF
	var f := floorf((suelo.y - origen.y) / casilla)
	for k in range(1, 5):
		if muro_en(Vector2(suelo.x, origen.y + (f - k + 0.5) * casilla)):
			return origen.y + (f - k + 1.0) * casilla - CARA
	return -INF


# Lo que vuela sobre el suelo "suelo", si está detrás de un tabique (en las filas que tapa la cara del primer muro de
# debajo, hasta 3 casillas): desde qué y la tapa esa cara. INF si nada lo tapa
static func tapa(suelo: Vector2) -> float:
	if medida.x <= 0.0:
		return INF
	var f := floorf((suelo.y - origen.y) / casilla)
	for k in range(1, 4):
		if muro_en(Vector2(suelo.x, origen.y + (f + k + 0.5) * casilla)):
			var ultima := f + k
			for j in 3:
				if not muro_en(Vector2(suelo.x, origen.y + (ultima + 1.5) * casilla)):
					break
				ultima += 1.0
			var pie_muro := origen.y + (ultima + 1.0) * casilla
			if muro_en(Vector2(suelo.x, pie_muro + casilla * 0.5)):
				return INF   # (sin suelo debajo no tiene cara)
			return pie_muro - CARA
	return INF
