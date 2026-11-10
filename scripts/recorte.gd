# Los efectos no se pintan encima de las paredes ni al otro lado (10 nov): la explosión, la escarcha, el fuego y el
# humo del molotov, los charcos, las quemaduras, los efectos de pixelfx (EfectoSuelo) y las partículas llevan uno de
# estos materiales, que comparten todos. El mapa, al montarse, le pasa sus muros (preparar): una máscara con un punto por
# casilla. Cómo se recorta cada píxel, en escenas/armas/recorte.gdshaderinc. Se prueba con --captura --efectos-pared
class_name Recorte
extends RefCounted

const SHADER := preload("res://escenas/armas/recorte.gdshader")
const SHADER_SUMA := preload("res://escenas/armas/recorte_suma.gdshader")   # (las capas de brillo que se suman)
const MODOS := {"suelo": 0, "aire": 1, "punto": 2}

static var materiales := {}
static var mascara: ImageTexture = null
static var origen := Vector2.ZERO
static var medida := Vector2.ZERO   # (0: no hay mapa, no se recorta)
static var de_mapa: Object = null   # el mapa del que es la máscara


# El material de un modo ("suelo", "aire" o "punto"; ver recorte.gdshaderinc). "suma": para las capas que se suman
static func material(modo: String, suma := false) -> ShaderMaterial:
	var clave := modo + ("+" if suma else "")
	if not materiales.has(clave):
		var m := ShaderMaterial.new()
		m.shader = SHADER_SUMA if suma else SHADER
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
