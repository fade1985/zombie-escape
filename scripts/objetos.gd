# Los objetos para crear armas (src/objetos.js del JS). Son chatarra: los sueltan los zombis al morir y Johnny
# los lleva en la mochila (MOCHILA casillas; los iguales se apilan en una). Al completar el edificio pasan al
# baúl de la sala de mantenimiento (guardado: "baul"); si Johnny cae, se pierden. En el banco de trabajo se
# juntan de dos en dos para crear armas (recetas.gd). Todos son de rareza gris (común).
# Su dibujo es assets/ui/iconos/obj-<id>.png (lo saca tools/dibujos_7b.py).
class_name Objetos

const MOCHILA := 8           # casillas de la mochila
const BAUL := 24             # casillas del baúl: una por cada objeto distinto y una por cada arma creada
const SUELTA := 0.10         # probabilidad de que un zombi suelte un objeto (provisional, como en el JS)
const SUELTA_EXPLOSIVOS := 0.25   # los explosivos, solo los zombis explosivos

const NOMBRES := {
	"clavos": "Clavos", "gasolina": "Gasolina", "cuchillas": "Cuchillas", "pistola_agua": "Pistola de agua",
	"spray": "Spray de pintura", "mechero": "Mechero", "lejia": "Lejía", "alcohol": "Botella de alcohol",
	"trapo": "Trapo", "explosivos": "Explosivos", "despertador": "Despertador", "extintor": "Extintor",
	"taser": "Táser", "llave_inglesa": "Llave inglesa", "hacha": "Hacha", "cuerda": "Cuerda",
	"mancuernas": "Mancuernas",
}


# El nombre de un objeto o de un arma (las armas de la tienda también entran en las recetas)
static func nombre(id: String) -> String:
	if id in NOMBRES:
		return NOMBRES[id]
	return Armas.DATOS[id].nombre if id in Armas.DATOS else id


# El icono para Tema.icono_y_texto: los objetos, "obj-<id>"; las armas, el suyo
static func icono(id: String) -> String:
	if id in NOMBRES:
		return "obj-" + id
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


# Qué objeto suelta un zombi al morir ("" = nada): los explosivos solo los dejan los zombis explosivos
static func que_suelta(tipo: String) -> String:
	if tipo == "explosivo":
		return "explosivos" if randf() < SUELTA_EXPLOSIVOS else ""
	return al_azar() if randf() < SUELTA else ""


# Un objeto cualquiera, menos los explosivos (la portera suelta dos seguros)
static func al_azar() -> String:
	return NOMBRES.keys().filter(func(id): return id != "explosivos").pick_random()
