# Los objetos para crear armas (src/objetos.js del JS). Son chatarra: los sueltan los zombis al morir y Johnny
# los lleva en la mochila (MOCHILA casillas; los iguales se apilan en una). Al completar el edificio pasan al
# baúl de la sala de mantenimiento (guardado: "baul"); si Johnny cae, se pierden. Antes, al arrimarse al baúl, se
# pueden guardar a mano (ui/inventario.gd, «Guardar de la mochila»). En el banco de trabajo se
# juntan de dos en dos para crear armas (recetas.gd). Todos son de rareza gris (común).
# Su dibujo es assets/ui/iconos/obj-<id>.png, de 16×16 (lo saca tools/objetos16.py).
#
# Cada edificio suelta lo suyo (parte 6 del centro comercial, docs/CENTRO_COMERCIAL.md): en los Apartamentos, los
# 17 de siempre; en el centro comercial, los de la lista de la tienda donde cae el zombi (TIENDAS), que mezclan
# algunos de siempre con los nueve nuevos (SOLO_CENTRO). Las cosas de casa (SOLO_CASA) no salen en el centro.
class_name Objetos

const MOCHILA := 8           # casillas de la mochila
const BAUL := 32             # casillas del baúl: una por cada objeto distinto y una por cada arma creada
const SUELTA := 0.10         # probabilidad de que un zombi suelte un objeto (provisional, como en el JS)
const SUELTA_EXPLOSIVOS := 0.25   # los explosivos, solo los zombis explosivos

const NOMBRES := {
	"clavos": "Clavos", "gasolina": "Gasolina", "cuchillas": "Cuchillas", "pistola_agua": "Pistola de agua",
	"spray": "Spray de pintura", "mechero": "Mechero", "lejia": "Lejía", "alcohol": "Botella de alcohol",
	"trapo": "Trapo", "explosivos": "Explosivos", "despertador": "Despertador", "extintor": "Extintor",
	"taser": "Táser", "llave_inglesa": "Llave inglesa", "hacha": "Hacha", "cuerda": "Cuerda",
	"mancuernas": "Mancuernas",
	# los nueve del centro comercial
	"cinta_americana": "Cinta americana", "cadena": "Cadena", "bateria": "Batería", "cable": "Cable",
	"aceite": "Aceite", "bombona": "Bombona de gas", "hielo_seco": "Hielo seco", "jeringuilla": "Jeringuilla",
	"perchas": "Perchas",
	# los dos de curar del centro comercial (parte 9): no son chatarra, se usan desde el inventario (USABLES)
	"vendas": "Vendas", "bocadillo": "Bocadillo",
}
# Los que no son chatarra: se usan desde el inventario («Usar», partida.usar_objeto) y no entran en las recetas ni
# pasan al baúl (al acabar la partida, se pierden). El botiquín de la farmacéutica (supervivientes.gd; cura lo de
# partida.BOTIQUIN; su icono, assets/ui/iconos/botiquin.png), y los de curar de las tiendas, con lo que curan
# ("cura"; más con el talento Sanitario, y con la Alerta 4, la mitad): las vendas de la farmacia y el bocadillo del
# supermercado. Cuentan en Colecciones como los demás (están en NOMBRES y en TIENDAS)
const USABLES := {
	"botiquin": {"nombre": "Botiquín", "icono": "botiquin"},
	"vendas": {"cura": 25},
	"bocadillo": {"cura": 15},
}
const SOLO_CASA := ["despertador", "mancuernas", "pistola_agua", "trapo", "cuerda"]   # solo en los Apartamentos
const SOLO_CENTRO := ["cinta_americana", "cadena", "bateria", "cable", "aceite", "bombona", "hielo_seco",
	"jeringuilla", "perchas", "vendas", "bocadillo"]   # solo en el centro comercial
# Lo que suelta cada tienda del centro comercial (sus tipos, en Tienda.TIPOS). Los zombis del pasillo, de cualquiera
const TIENDAS := {
	"ferreteria": ["clavos", "hacha", "llave_inglesa", "cuchillas", "spray", "cinta_americana", "cadena"],
	"electronica": ["taser", "extintor", "bateria", "cable"],
	"restaurante": ["alcohol", "gasolina", "mechero", "extintor", "aceite", "bombona"],
	"supermercado": ["lejia", "alcohol", "mechero", "hielo_seco", "bocadillo"],
	"farmacia": ["alcohol", "lejia", "jeringuilla", "vendas"],
	"ropa": ["cuchillas", "spray", "perchas"],
	"joyeria": ["cadena", "cuchillas", "bateria", "spray"],
}


# El nombre de un objeto o de un arma (las armas de la tienda también entran en las recetas)
static func nombre(id: String) -> String:
	if id in NOMBRES:
		return NOMBRES[id]
	if id in USABLES:
		return USABLES[id].nombre
	if Armas.es_creada(id):
		return Armas.sacadas[id].nombre
	return Armas.DATOS[id].nombre if id in Armas.DATOS else id


# El icono para Tema.icono_y_texto: los objetos, "obj-<id>"; las armas, el suyo
static func icono(id: String) -> String:
	if id in NOMBRES:
		return "obj-" + id
	if id in USABLES:
		return USABLES[id].icono
	if Armas.es_creada(id):
		return Recetas.icono_de(Armas.sacadas[id].receta)   # el de su receta (hasta que tengan el suyo, el de un ingrediente)
	return {"mp5": "pistola"}.get(id, id)


# Las casillas de la mochila (una lista de ids, uno por objeto): [[id, cuántos], ...] en el orden en que se cogieron
static func casillas(mochila: Array) -> Array:
	var cuantos := {}
	for id in mochila:
		cuantos[id] = cuantos.get(id, 0) + 1
	var lista := []
	for id in cuantos:
		lista.append([id, cuantos[id]])
	return lista


# ¿Cabe uno más? Si ya lleva alguno va a su casilla; si no, hace falta una libre
static func cabe(mochila: Array, id: String) -> bool:
	return id in mochila or casillas(mochila).size() < MOCHILA


# Casillas ocupadas del baúl: una por cada objeto distinto y una por cada arma creada
static func casillas_baul(s: Dictionary) -> int:
	var n := 0
	for id in s.baul:
		if s.baul[id] > 0:
			n += 1
	return n + s.baul_armas.size()


# ¿Va al baúl? Todo menos lo de curar (USABLES), que se pierde al acabar la partida
static func al_baul(id: String) -> bool:
	return not id in USABLES


# ¿Cabe en el baúl? Si ya tiene alguno va a su casilla; si no, hace falta una libre
static func cabe_baul(s: Dictionary, id: String) -> bool:
	return s.baul.get(id, 0) > 0 or casillas_baul(s) < BAUL


# Qué objeto suelta un zombi al morir ("" = nada): los explosivos solo los dejan los zombis explosivos. "tienda"
# es el tipo de la tienda donde ha caído ("" en el pasillo o en un apartamento)
static func que_suelta(tipo: String, edificio := "apartamentos", tienda := "") -> String:
	if tipo == "explosivo":
		return "explosivos" if randf() < SUELTA_EXPLOSIVOS else ""
	return al_azar(edificio, tienda) if randf() < SUELTA else ""


# Un objeto cualquiera de los que salen ahí, menos los explosivos (el jefe suelta dos seguros). En los
# Apartamentos, uno de los de siempre; en el centro comercial, uno de la lista de su tienda (en el pasillo, de
# una tienda cualquiera). Con el reto del día "Sin curas" (reto.gd), sin los de curar
static func al_azar(edificio := "apartamentos", tienda := "") -> String:
	var lista: Array
	if edificio == "apartamentos":
		lista = NOMBRES.keys().filter(func(id): return id != "explosivos" and id not in SOLO_CENTRO)
	else:
		if tienda not in TIENDAS:
			tienda = TIENDAS.keys().pick_random()
		lista = TIENDAS[tienda]
	if Reto.sin_curas():
		lista = lista.filter(func(id): return not id in USABLES)
	return lista.pick_random()


# ── Colecciones (el programa del ordenador) ──
# Lo encontrado alguna vez se apunta en el guardado ("encontrados"), y el ordenador lo cuenta por edificio.

# Los que salen en un edificio, en el orden de NOMBRES: en los Apartamentos, los 17 de siempre (con los
# explosivos); en el centro comercial, todos menos las cosas de casa. Otro valor: todos
static func de_edificio(edificio: String) -> Array:
	match edificio:
		"apartamentos":
			return NOMBRES.keys().filter(func(id): return not id in SOLO_CENTRO)
		"centro":
			return NOMBRES.keys().filter(func(id): return not id in SOLO_CASA)
	return NOMBRES.keys()


# Dónde sale un objeto, para la línea de abajo de su ficha: en los Apartamentos lo suelta cualquier zombi (los
# explosivos, solo el explosivo); en el centro comercial, las tiendas que lo sueltan ("Ferretería y tienda de ropa")
static func donde(id: String, edificio: String) -> String:
	if id == "explosivos":
		return "lo suelta el zombi explosivo"
	if edificio != "centro":
		return "lo suelta cualquier zombi"
	var tiendas := []
	for tipo in TIENDAS:
		if id in TIENDAS[tipo]:
			var n: String = Tienda.TIPOS[tipo].nombre
			tiendas.append(n if tiendas.is_empty() else n.to_lower())   # solo la primera con mayúscula
	if tiendas.is_empty():
		return ""
	if tiendas.size() == 1:
		return tiendas[0]
	return ", ".join(tiendas.slice(0, -1)) + " y " + tiendas[-1]


# Apunta un objeto como encontrado alguna vez (al cogerlo del suelo). El botiquín de la
# farmacéutica no cuenta (no está en NOMBRES); las vendas y el bocadillo, sí
static func apuntar_encontrado(id: String) -> void:
	if not id in NOMBRES:
		return
	Guardado.cambiar(func(g):
		if not id in g.encontrados:
			g.encontrados.append(id)
			g.colecciones_nuevo = true)
