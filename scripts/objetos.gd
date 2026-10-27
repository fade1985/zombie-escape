# Los objetos (src/objetos.js del JS). Son chatarra: los sueltan los zombis al morir y Johnny los lleva en la
# mochila (MOCHILA casillas; los iguales se apilan en una). Al completar el edificio pasan al baúl de la sala de
# mantenimiento (guardado: "baul"); si Johnny cae, se pierden. Antes, al arrimarse al baúl, se pueden guardar a mano
# (ui/inventario.gd, «Guardar de la mochila»). Hasta el 25 oct se juntaban de dos en dos en el banco de trabajo para
# crear armas; las recetas se quitaron, y los explosivos, el despertador, el extintor, el trapo y el alcohol (que ya no
# servían para nada) se fueron con ellas: en su lugar llegaron las piezas (PIEZAS), para mejorar las armas en el banco.
# Su dibujo es assets/ui/iconos/obj-<id>.png (el del botiquín, botiquin.png), todos de 32×32 y de PixelLab. La gasolina, el bidón de ácido y la
# batería son además la munición del lanzallamas, el lanza ácido y el lanza rayos: van en la mochila, pero
# ocupan los huecos de la munición (Armas.MUNICION).
#
# Las piezas (PIEZAS) son de 4 familias, las de las armas: cuerpo a cuerpo, a distancia, especiales y arrojables. Las
# suelta un zombi alguna vez (PIEZA_ZOMBI) y cada jefe, seguras (PIEZAS_JEFE); con la alerta, más (Alerta.mas_piezas).
# No salen al azar (al_azar) ni en las tiendas del centro, y no se compran: solo las sueltan los zombis y los jefes.
#
# Cada edificio suelta lo suyo (parte 6 del centro comercial, docs/historial/CENTRO_COMERCIAL.md): en los Apartamentos,
# la gasolina y la batería; en el centro comercial, los de la lista de la tienda donde cae el zombi (TIENDAS). Las
# vendas (SOLO_CENTRO) solo salen allí. Eran 26: el 25 oct se quitaron del
# juego el mechero, la llave inglesa, el hacha, las cuchillas, el táser, la cuerda, las mancuernas, la cadena, el
# cable, el hielo seco y las perchas (con las armas que los pedían), y luego los clavos, el spray de pintura, la
# lejía, la pistola de agua, la cinta americana, la bombona de gas, la jeringuilla, el aceite y el bocadillo (con las
# arrojadizas del centro comercial; el lanzallamas, el lanza ácido y el lanza rayos pasaron a la tienda de
# armas).
# Uno solo lo suelta un zombi, en los dos edificios (DE_UN_ZOMBI): el bidón de ácido.
class_name Objetos

const MOCHILA := 8           # casillas de la mochila
const BAUL := 32             # casillas del baúl: una por cada objeto distinto, y una por cada arma y cada paquete de arrojables
const SUELTA := 0.04         # probabilidad de que un zombi suelte un objeto (0,10 con 7 objetos; ahora son la gasolina y la batería)
const SUELTA_PROPIO := 0.25  # probabilidad de que un zombi de DE_UN_ZOMBI suelte lo suyo (y nada más)
# Lo que solo suelta un tipo de zombi, y nunca sale al azar: el bidón de ácido, que llena el lanza ácido, el gordo
# (venenoso)
const DE_UN_ZOMBI := {"bidon_acido": "venenoso"}
# Las piezas para mejorar las armas en el banco de trabajo (ui/inventario.gd, «Banco de trabajo»): una por familia, con la
# familia de armas a la que sirven (Armas.familia; los arrojables, aparte). Las sueltan los zombis y los jefes, y nada más
const PIEZAS := {
	"pieza_cuerpo": "cuerpo", "pieza_distancia": "distancia", "pieza_especial": "especial", "pieza_arrojable": "arrojable",
}
# Para qué armas sirve cada familia de piezas, para la ficha (ui/inventario.gd, que_pieza)
const PIEZA_PARA := {
	"cuerpo": "las armas cuerpo a cuerpo (la fregona, el cuchillo y el bate)",
	"distancia": "las armas a distancia (la pistola, la MP5 y la escopeta)",
	"especial": "las armas especiales (el lanzallamas, el lanza ácido y el lanza rayos)",
	"arrojable": "los arrojables (el molotov, la granada, la atraedora y la congeladora)",
}
const PIEZA_ZOMBI := 0.06    # probabilidad de que cualquier zombi suelte una pieza (una de las cuatro, al azar)
const PIEZAS_JEFE := 4       # las que suelta cada jefe al caer, seguras (cada una, de una familia al azar)

const NOMBRES := {
	"gasolina": "Gasolina",
	# el bidón de ácido, en los dos edificios: solo lo suelta el gordo (DE_UN_ZOMBI)
	"bidon_acido": "Bidón de ácido",
	# la batería, la munición del lanza rayos: en los dos edificios
	"bateria": "Batería",
	# las vendas, de curar (parte 9 del centro comercial): no son chatarra, se usan con su tecla o desde el inventario (USABLES)
	"vendas": "Vendas",
	# las piezas para mejorar las armas (PIEZAS): solo las sueltan los zombis y los jefes
	"pieza_cuerpo": "Pieza cuerpo a cuerpo", "pieza_distancia": "Pieza a distancia", "pieza_especial": "Pieza especial",
	"pieza_arrojable": "Pieza arrojable",
}
# Los de curar: no son chatarra, se usan (partida.usar_objeto) desde el inventario («Usar») o con su tecla sin abrirlo
# ("accion": 1 las vendas y 2 el botiquín; sus casillas junto a la barra de vida, ui/hud.gd), y van al baúl como los
# demás. Las vendas (de las tiendas del centro comercial) curan 25 y el botiquín, 50 (el que suelta el armarito de los
# baños, y el que te prepara la farmacéutica, supervivientes.gd; su icono, assets/ui/iconos/botiquin.png); más con el
# talento Sanitario, y con la Alerta 4, la mitad ("cura"). Las vendas cuentan en Colecciones como los demás (están en
# NOMBRES y en TIENDAS); el botiquín, no. El orden es el de sus casillas en el HUD
const USABLES := {
	"vendas": {"cura": 25, "accion": "usar_vendas"},
	"botiquin": {"nombre": "Botiquín", "icono": "botiquin", "cura": 50, "accion": "usar_botiquin"},
}
const SOLO_CENTRO := ["vendas"]      # solo en el centro comercial
# Lo que suelta cada tienda del centro comercial (sus tipos, en Tienda.TIPOS). Los zombis del pasillo, de cualquiera
# (y los de una tienda que no está aquí, como la de ropa, sueltan lo de una tienda cualquiera)
const TIENDAS := {
	"ferreteria": ["bateria", "gasolina"],
	"electronica": ["bateria"],
	"restaurante": ["gasolina"],
	"supermercado": ["bateria", "vendas"],
	"farmacia": ["vendas"],
	"joyeria": ["bateria"],
}


# El nombre de un objeto o de un arma
static func nombre(id: String) -> String:
	if id in NOMBRES:
		return NOMBRES[id]
	if id in USABLES:
		return USABLES[id].nombre
	return Armas.DATOS[id].nombre if id in Armas.DATOS else id


# El icono para Tema.icono_y_texto: los objetos, "obj-<id>"; las armas, el suyo
static func icono(id: String) -> String:
	if id in NOMBRES:
		return "obj-" + id
	if id in USABLES:
		return USABLES[id].icono
	return {"mp5": "pistola"}.get(id, id)


# Las casillas de la mochila (una lista de ids, uno por objeto): [[id, cuántos], ...] en el orden en que se cogieron.
# La gasolina, el bidón de ácido y la batería no ocupan casilla de la mochila, sino de la munición (Armas.MUNICION;
# Johnny los cuenta ahí), salvo con "con_municion" (para guardarlos en el baúl)
static func casillas(mochila: Array, con_municion := false) -> Array:
	var cuantos := {}
	for id in mochila:
		if con_municion or not id in Armas.MUNICION:
			cuantos[id] = cuantos.get(id, 0) + 1
	var lista := []
	for id in cuantos:
		lista.append([id, cuantos[id]])
	return lista


# ¿Cabe uno más? Si ya lleva alguno va a su casilla; si no, hace falta una libre (la gasolina, el bidón de ácido y
# la batería van con la munición: johnny.sitio)
static func cabe(mochila: Array, id: String) -> bool:
	return id in mochila or casillas(mochila).size() < MOCHILA


# Casillas ocupadas del baúl: una por cada objeto distinto, y una por cada arma y cada paquete de arrojables
# ("baul_equipo" del guardado)
static func casillas_baul(s: Dictionary) -> int:
	var n: int = s.get("baul_equipo", []).size()
	for id in s.baul:
		if s.baul[id] > 0:
			n += 1
	return n


# ¿Queda alguna casilla libre en el baúl? (para un arma o un paquete de arrojables, que siempre van en una nueva)
static func hueco_baul(s: Dictionary) -> bool:
	return casillas_baul(s) < BAUL


# Todos los objetos que pueden ir en la mochila y en el baúl, en el orden de NOMBRES y, al final, el botiquín (que no
# es de NOMBRES: no sale al azar ni cuenta en Colecciones)
static func todos() -> Array:
	var lista := NOMBRES.keys()
	for id in USABLES:
		if not id in lista:
			lista.append(id)
	return lista


# ¿Cabe en el baúl? Si ya tiene alguno va a su casilla; si no, hace falta una libre
static func cabe_baul(s: Dictionary, id: String) -> bool:
	return s.baul.get(id, 0) > 0 or casillas_baul(s) < BAUL


# Qué objeto suelta un zombi al morir ("" = nada): el gordo, solo lo suyo (DE_UN_ZOMBI: el bidón de ácido), 1 de
# cada 4 veces. "tienda" es el tipo de la tienda donde ha caído ("" en el pasillo o en un apartamento). Las piezas van
# aparte (pieza_de_zombi)
static func que_suelta(tipo: String, edificio := "apartamentos", tienda := "") -> String:
	for id in DE_UN_ZOMBI:
		if DE_UN_ZOMBI[id] == tipo:
			return id if randf() < SUELTA_PROPIO else ""
	return al_azar(edificio, tienda) if randf() < SUELTA else ""


# Un objeto cualquiera de los que salen ahí, menos los de un solo zombi (DE_UN_ZOMBI; el jefe suelta dos seguros) y
# las piezas (PIEZAS). En los Apartamentos, la gasolina o la batería; en el centro comercial, uno de la lista de su
# tienda (en el pasillo, de una tienda cualquiera). Con el reto del día "Sin curas" (reto.gd), sin los de curar
static func al_azar(edificio := "apartamentos", tienda := "") -> String:
	var lista: Array
	if edificio == "apartamentos":
		lista = NOMBRES.keys().filter(func(id): return id not in DE_UN_ZOMBI and id not in SOLO_CENTRO and id not in PIEZAS)
	else:
		if tienda not in TIENDAS:
			tienda = TIENDAS.keys().pick_random()
		lista = TIENDAS[tienda]
	if Reto.sin_curas():
		lista = lista.filter(func(id): return not id in USABLES)
	return lista.pick_random()


# La pieza que suelta un zombi al morir ("" = ninguna): PIEZA_ZOMBI de las veces, una de las cuatro al azar. Con la
# alerta, más veces (Alerta.mas_piezas)
static func pieza_de_zombi() -> String:
	return PIEZAS.keys().pick_random() if randf() < PIEZA_ZOMBI * Alerta.mas_piezas() else ""


# Cuántas piezas suelta un jefe al caer (PIEZAS_JEFE, y más con la alerta); cada una, de una familia al azar
static func piezas_de_jefe() -> Array:
	var lista := []
	for i in roundi(PIEZAS_JEFE * Alerta.mas_piezas()):
		lista.append(PIEZAS.keys().pick_random())
	return lista


# ── Colecciones (el programa del ordenador) ──
# Lo encontrado alguna vez se apunta en el guardado ("encontrados"), y el ordenador lo cuenta por edificio.

# Los que salen en un edificio, en el orden de NOMBRES: en los Apartamentos, todos menos las vendas; en el centro
# comercial, todos. Otro valor: todos
static func de_edificio(edificio: String) -> Array:
	if edificio == "apartamentos":
		return NOMBRES.keys().filter(func(id): return not id in SOLO_CENTRO)
	return NOMBRES.keys()


# Dónde sale un objeto, para la línea de abajo de su ficha: en los Apartamentos lo suelta cualquier zombi (el bidón
# de ácido, solo el gordo, y las piezas, los zombis y los jefes, en los dos edificios); en el centro comercial, las
# tiendas que lo sueltan ("Ferretería, electrónica y supermercado")
static func donde(id: String, edificio: String) -> String:
	if id in PIEZAS:
		return "la suelta algún zombi, y los jefes seguro"
	if id == "bidon_acido":
		return "lo suelta el gordo"
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
# farmacéutica no cuenta (no está en NOMBRES); las vendas, sí
static func apuntar_encontrado(id: String) -> void:
	if not id in NOMBRES:
		return
	Guardado.cambiar(func(g):
		if not id in g.encontrados:
			g.encontrados.append(id)
			g.colecciones_nuevo = true)
