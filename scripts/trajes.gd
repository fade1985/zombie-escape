# Los trajes de Johnny (parte 11 del centro comercial, docs/CENTRO_COMERCIAL.md): la ropa de la tienda de ropa
# para cambiarle el aspecto. No son dibujos nuevos: el shader de la cintura (escenas/personajes/cintura.gdshader)
# reconoce por su color, en las siete hojas de Johnny y en todas sus animaciones, el peto (los vaqueros azules),
# la camisa (crema) y el pañuelo (rojo), y a cada zona le cambia el tono y le multiplica la saturación y la luz:
# el sombreado se queda como estaba. Cada zona: [tono en grados, × saturación, × luz]. Para añadir un traje, una
# entrada más en LISTA (y retocar los números mirando la foto de --captura --trajes).
#
# El puesto va en el guardado ("traje"; "" = el conserje de siempre) y se lo pone johnny.gd al empezar (vestir).
# Cómo se consiguen (trozo 2): cada traje es un objeto de la tienda de ropa (objetos.gd: "traje_<id>", en
# Objetos.TIENDAS["ropa"] y en NOMBRES, así cuenta en Colecciones) que sus zombis sueltan como los demás, pero solo
# mientras no se tenga; y la modista al caer suelta siempre uno que falte (partida.gd). Al cogerlo Johnny se lo
# pone en el acto y se queda para siempre ("trajes" del guardado; no va a la mochila ni se pierde al caer).
# Se eligen en la taquilla de la sala de mantenimiento (ui/taquilla.gd; mapa.gd la pone a la derecha del baúl).
# Tecla de prueba Z: el siguiente, sin guardarlo.
class_name Trajes

const LISTA := {
	"vigilante": {"nombre": "Uniforme de vigilante", "desc": "Azul marino, como el de los vigilantes. Con chapa y todo.",
		"peto": [225, 0.9, 0.42], "camisa": [205, 1.7, 0.95], "panuelo": [225, 0.6, 0.3]},
	"farmacia": {"nombre": "Bata de farmacéutico", "desc": "Blanca y verde menta. Huele a jarabe para la tos.",
		"peto": [150, 0.05, 1.3], "camisa": [150, 1.6, 0.9], "panuelo": [140, 1.1, 0.75]},
	"cocinero": {"nombre": "Delantal de cocinero", "desc": "Granate con la camisa blanca. Con alguna mancha de salsa.",
		"peto": [0, 1.3, 0.85], "camisa": [40, 0.05, 1.1], "panuelo": [40, 0.05, 1.08]},
	"chandal": {"nombre": "Chándal", "desc": "Morado y amarillo chillón. De la temporada 1994.",
		"peto": [290, 1.4, 1.05], "camisa": [58, 1.9, 1.0], "panuelo": [115, 1.7, 1.0]},
}
const ZONAS := ["peto", "camisa", "panuelo"]
const SIN := Vector3(-1, 1, 1)   # la ropa de siempre: el shader no toca esa zona


# El nombre de un traje ("" = el conserje de siempre)
static func nombre(id: String) -> String:
	return LISTA[id].nombre if id in LISTA else "Conserje"


# El traje que lleva puesto, según el guardado (si no es ninguno conocido, el de siempre)
static func puesto() -> String:
	var id: String = Guardado.cargar().traje
	return id if id in LISTA else ""


# Se queda con ese traje para siempre (hasta que elija otro)
static func poner(id: String) -> void:
	Guardado.cambiar(func(g): g.traje = id if id in LISTA else "")


# Le dice al shader de un dibujo de Johnny los colores de ese traje ("" = los de siempre)
static func vestir(material: ShaderMaterial, id: String) -> void:
	for zona in ZONAS:
		var v := SIN
		if id in LISTA:
			var z: Array = LISTA[id][zona]
			v = Vector3(z[0], z[1], z[2])
		material.set_shader_parameter(zona, v)


# El que va después de ese (tecla Z): el de siempre, los de la lista en orden y vuelta a empezar
static func siguiente(id: String) -> String:
	var todos: Array = [""] + LISTA.keys()
	return todos[(todos.find(id) + 1) % todos.size()]


# ── Como objetos (objetos.gd) ──

# El id del objeto de un traje ("traje_vigilante"), y vuelta
static func objeto(id: String) -> String:
	return "traje_" + id


static func es_objeto(obj: String) -> bool:
	return obj.begins_with("traje_") and obj.trim_prefix("traje_") in LISTA


static func de_objeto(obj: String) -> String:
	return obj.trim_prefix("traje_") if es_objeto(obj) else ""


# Los que ya se tienen (ids), según el guardado
static func tenidos() -> Array:
	return Guardado.cargar().trajes


# Uno al azar de los que faltan ("" si ya están todos): el que suelta la modista al caer
static func que_falta() -> String:
	var tiene := tenidos()
	var faltan: Array = LISTA.keys().filter(func(id): return not id in tiene)
	return faltan.pick_random() if not faltan.is_empty() else ""


# Al coger uno del suelo: se apunta para siempre y se queda puesto
static func encontrar(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.trajes:
			g.trajes.append(id)
		g.traje = id)
