# Los objetos (src/objetos.js del JS). Son chatarra: los sueltan los zombis al morir y Johnny los lleva en la
# mochila (MOCHILA casillas; los iguales se apilan en una). Al completar el edificio pasan al baúl de la sala de
# mantenimiento (guardado: "baul"); si Johnny cae, se pierden. Antes, al arrimarse al baúl, se pueden guardar a mano
# (ui/inventario.gd, «Guardar de la mochila»). Las piezas (PIEZAS) sirven para mejorar las armas en el banco de trabajo.
# Su dibujo es assets/ui/iconos/obj-<id>.png (el del botiquín, botiquin.png), todos de 32×32, de PixelLab (las piezas, de GPT: tools/muebles_gpt.py). La gasolina, el bidón de ácido y la
# batería son además la munición del lanzallamas, el lanza ácido y el lanza rayos: van en la mochila, pero
# ocupan los huecos de la munición (Armas.MUNICION).
#
# Las piezas (PIEZAS, «materiales» en el juego) son de 4 familias, las de las armas: cuerpo a cuerpo, a distancia,
# especiales y arrojables. Desde el 15 nov (Fase 4) salen de los muebles de los Apartamentos que se abren
# (MUEBLES_CON_PIEZA: pieza_de_mueble; desde el 16 nov, solo de las familias de las armas que lleva Johnny); los zombis ya no las sueltan. En el centro comercial y en la torre, que no tienen
# esos muebles, las sueltan los jefes (PIEZAS_JEFE). No salen al azar (al_azar)
# ni en las tiendas del centro, y no se compran.
#
# Cada edificio suelta lo suyo (parte 6 del centro comercial, docs/historial/CENTRO_COMERCIAL.md): en los Apartamentos,
# la gasolina y la batería; en el centro comercial, los de la lista de la tienda donde cae el zombi (TIENDAS). Las
# vendas (SOLO_CENTRO) solo salen allí. Eran 26: el 25 oct se quitaron del
# juego el mechero, la llave inglesa, el hacha, las cuchillas, el táser, la cuerda, las mancuernas, la cadena, el
# cable, el hielo seco y las perchas (con las armas que los pedían), y luego los clavos, el spray de pintura, la
# lejía, la pistola de agua, la cinta americana, la bombona de gas, la jeringuilla, el aceite y el bocadillo (con las
# arrojadizas del centro comercial; el lanzallamas, el lanza ácido y el lanza rayos pasaron a la tienda de
# armas).
# Uno solo lo suelta un zombi, en los dos edificios (DE_UN_ZOMBI): el bidón de ácido. Desde el 15 nov los durmientes ya no
# sueltan objetos (solo el mutágeno y un billete o munición: partida.soltar_premio_durmiente; el bidón de ácido sale como
# munición del lanza ácido): que_suelta lo usa solo el guardia.
class_name Objetos

const MOCHILA := 8           # casillas de la mochila (los objetos)
const CURAS := 2             # y las de las curas, aparte (13 nov: antes 4, junto a los arrojables de repuesto, que ya no hay)
const BAUL := 32             # casillas del baúl: una por cada objeto distinto, una por cada arma y una por cada clase de arrojables
const MONTON := 99           # lo máximo de un mismo objeto en una casilla del baúl si no es munición ni curas (las piezas): lo demás, monton()
const SUELTA := 0.04         # probabilidad de que un zombi suelte un objeto (0,10 con 7 objetos; ahora son la gasolina y la batería)
const SUELTA_PROPIO := 0.25  # probabilidad de que un zombi de DE_UN_ZOMBI suelte lo suyo (y nada más)
# Lo que solo suelta un tipo de zombi, y nunca sale al azar: el bidón de ácido, que llena el lanza ácido, el gordo
# (venenoso)
const DE_UN_ZOMBI := {"bidon_acido": "venenoso"}
# Los objetos que son munición de un arma especial (van en los huecos de la munición): solo salen si Johnny lleva esa arma
const MUNICION_DE_OBJETO := ["gasolina", "bidon_acido", "bateria", "nitrogeno"]
# Las piezas para mejorar las armas en el banco de trabajo (ui/inventario.gd, «Banco de trabajo»): una por familia, con la
# familia de armas a la que sirven (Armas.familia; los arrojables, aparte). Salen de los muebles (y de los jefes, fuera de
# los Apartamentos)
const PIEZAS := {
	"pieza_cuerpo": "cuerpo", "pieza_distancia": "distancia", "pieza_especial": "especial", "pieza_arrojable": "arrojable",
}
# Para qué armas sirve cada familia de piezas, para la ficha (ui/inventario.gd, que_pieza; pieza_para() lo traduce). Cada
# una es una frase entera, con sus artículos y los nombres de las armas: así cada idioma las escribe como quiere
# [traducir]
const PIEZA_PARA := {
	"cuerpo": "las armas cuerpo a cuerpo (la fregona, el cuchillo, el bate, la motosierra y la katana)",
	"distancia": "las armas a distancia (la pistola, la MP5, la escopeta, la gatling y el lanzagranadas)",
	"especial": "las armas especiales (el lanzallamas, el lanza ácido, el lanza rayos y el lanza hielo)",
	"arrojable": "los lanzables (el molotov, la granada, la atraedora y la congeladora)",
}
# [/traducir]
# Los muebles que se abren como el armarito del baño (mueble.gd, partida.abrir_mueble). En los Apartamentos, el armario,
# la mesilla, el escritorio y la librería; en el centro comercial (16 nov, al dejar los jefes de soltarlos), la caja
# registradora, el perchero de ropa, el mueble de las teles, las taquillas y el mostrador de la farmacia; en la torre,
# el archivador, la mesa del despacho, la librería, el armero y el armario de los servidores. Más o menos los mismos por
# planta en los tres (unos 15-16 de media). Cada uno se abre una vez y, PIEZA_MUEBLE de las veces, suelta un material
# (cada familia, un 25 %); si no, está vacío
const MUEBLES_CON_PIEZA := ["wardrobe", "nightstand", "desk", "bookshelf",
	"checkout", "clothesrack", "tvshelf", "lockers", "pharmacycounter",
	"filecabinet", "execdesk", "bookcase", "armory", "serverrack",
	# (19 nov, el dueño) la tienda de ropa: todos los de la sala de venta menos los maniquíes, la taquilla del aseo y las estanterías y cajas del almacén
	"ropamodulo", "ropabarra", "ropazapatos", "ropavitrina", "ropaoval", "ropaperchero1", "ropaperchero2", "roparuedas",
	"ropamesa", "ropatarimas", "ropamostrador",
	"taquillaropa", "ropashelf", "ropashelf2", "ropashelf3", "ropashelf4", "cajasropa",
	"cajasropa2", "cajasropa3", "cajasropa4", "cajasropa5",
	# (24 nov) la farmacia rehecha: su mostrador nuevo, por los dos lados (el de antes, pharmacycounter, ya no sale en ella)
	"farmamostrador", "farmamostrador2", "farmamostrador3", "farmamostrador4",
	"farmapalet1", "farmapalet2", "farmapalet3", "farmapalet4", "farmapalet5",
	# (25 nov) las cajas del supermercado, por los dos lados
	"supercaja1", "supercaja2", "supercaja3", "supercaja1dentro", "supercaja2dentro", "supercaja3dentro",
	# (26 nov) y el resto de su sala de venta
	"supercarne", "supercarnedentro", "supercharcu", "supercharcudentro", "superpescado", "superpescadodentro", "superpan",
	"supernevera", "superarcon", "supercarnenevera", "supergondola1", "supergondola2", "supergondola3"]
const PIEZA_MUEBLE := 0.35   # probabilidad de que un mueble tenga un material
const PIEZAS_JEFE := 4       # las que soltaba cada jefe al caer en el centro comercial y en la torre (desde el 16 nov ya no: los muebles)

# Los nombres de los objetos que son chatarra, las vendas y las piezas; para enseñarlos, nombre(), que los traduce
# [traducir]
const NOMBRES := {
	"gasolina": "Gasolina",
	# el bidón de ácido, en los dos edificios: solo lo suelta el gordo (DE_UN_ZOMBI)
	"bidon_acido": "Bidón de ácido",
	# la batería, la munición del lanza rayos: en los dos edificios
	"bateria": "Batería",
	# la bombona de nitrógeno, la munición del lanza hielo: en los dos edificios (en el centro, el restaurante y el súper)
	"nitrogeno": "Bombona de nitrógeno",
	# las vendas, de curar (parte 9 del centro comercial): no son chatarra, se usan con su tecla o desde el inventario (USABLES)
	"vendas": "Vendas",
	# las piezas para mejorar las armas (PIEZAS): salen de los muebles (y de los jefes del centro y la torre)
	"pieza_cuerpo": "Material cuerpo a cuerpo", "pieza_distancia": "Material a distancia", "pieza_especial": "Material especial",
	"pieza_arrojable": "Material lanzable",
	# la comida favorita de cada superviviente (COMIDAS; M124, 16 nov): sale de la nevera y la encimera de las cocinas
	"donut": "Dónut", "manzana": "Manzana", "judias": "Lata de judías", "yogur": "Yogur de fresa",
	"bocadillo": "Bocadillo de chorizo", "energetica": "Bebida energética", "pizza": "Porción de pizza",
	"cafe": "Termo de café", "ensalada": "Ensalada",
}
# [/traducir]
# La comida favorita de cada superviviente (M124, 16 nov; la de cada uno, "comida" en Supervivientes.DATOS): para que uno
# de los trasteros te acompañe una partida, hay que dársela (supervivientes.gd, pedir_vecino). Sale solo de la nevera y
# la encimera de las cocinas de los Apartamentos (MUEBLES_CON_COMIDA: comida_de_mueble), y solo la de los que ya viven en
# los trasteros. Son objetos como los demás (van en la mochila, pasan al baúl al completar el edificio y se pierden si
# caes), pero no salen al azar ni cuentan para el logro de los objetos
const COMIDAS := ["donut", "manzana", "judias", "yogur", "bocadillo", "energetica", "pizza", "cafe", "ensalada"]
const MUEBLES_CON_COMIDA := ["fridge", "counter"]
const COMIDA_MUEBLE := 0.35   # probabilidad de que la nevera o la encimera tengan comida (como los materiales: PIEZA_MUEBLE)
# Los de curar: no son chatarra, se usan (partida.usar_objeto) desde el inventario («Usar») o con su tecla sin abrirlo
# ("accion": 1 las vendas y 2 el botiquín; sus casillas junto a la barra de vida, ui/hud.gd), y van al baúl como los
# demás. Las vendas (de las tiendas del centro comercial) curan 25 y el botiquín, 40 (el que suelta el armarito de los
# baños, y el que te prepara la farmacéutica, supervivientes.gd; su icono, assets/ui/iconos/botiquin.png); más con el
# talento Sanitario, y con la Alerta 4, la mitad ("cura"). Las vendas solo curan dentro del tercio de vida en el que
# estás; el botiquín, además, devuelve un tercio perdido ("tercio"; johnny.gd, devolver_tercio). Las vendas cuentan en
# Colecciones como los demás (están en NOMBRES y en TIENDAS); el botiquín, no. El orden es el de sus casillas en el HUD
# [traducir]
const USABLES := {
	"vendas": {"cura": 25, "accion": "usar_vendas"},
	"botiquin": {"nombre": "Botiquín", "icono": "botiquin", "cura": 40,   # (M72: antes 50)
		"accion": "usar_botiquin", "tercio": true},
}
# [/traducir]
# Las curas que caben en la mochila, como mucho (el dueño, 27 oct: con dos armaritos por piso salían unos 22
# botiquines por partida y se amontonaban sin límite); las que sobran se quedan en el suelo o en el baúl
const TOPE := {"botiquin": 2, "vendas": 3}
const SOLO_CENTRO := ["vendas"]      # solo en el centro comercial (y en los armaritos de los baños)
# Lo que suelta cada tienda del centro comercial (sus tipos, en Tienda.TIPOS). Los zombis del pasillo, de cualquiera
# (y los de una tienda que no está aquí, como la de ropa, sueltan lo de una tienda cualquiera)
const TIENDAS := {
	"ferreteria": ["bateria", "gasolina"],
	"electronica": ["bateria"],
	"restaurante": ["gasolina", "nitrogeno"],
	"supermercado": ["bateria", "vendas", "nitrogeno"],
	"farmacia": ["vendas"],
	"joyeria": ["bateria"],
}


# El nombre de un objeto o de un arma, en el idioma del jugador
static func nombre(id: String) -> String:
	if id in NOMBRES:
		return Idioma.t(NOMBRES[id])
	if id in USABLES:
		return Idioma.t(USABLES[id].nombre)
	if id in Armas.MUNICION:   # las balas y los cartuchos (en el baúl)
		return Armas.municion_nombre(id)
	if id == "":
		return Idioma.t(Armas.SIN_FUEGO.nombre)
	return Idioma.t(Armas.DATOS[id].nombre) if id in Armas.DATOS else id


# Para qué armas sirve una familia de piezas (PIEZA_PARA: «las armas cuerpo a cuerpo (...)»), en el idioma del jugador
static func pieza_para(familia: String) -> String:
	return Idioma.t(PIEZA_PARA[familia])


# El icono para Tema.icono_y_texto: los objetos, "obj-<id>"; las armas, el suyo
static func icono(id: String) -> String:
	if id == "":
		return "sin_arma"   # el hueco de fuego vacío (Armas.SIN_FUEGO)
	if id in NOMBRES:
		return "obj-" + id
	if id in USABLES:
		return USABLES[id].icono
	if id in Armas.MUNICION:   # las balas y los cartuchos (en el baúl)
		return Armas.MUNICION[id].icono
	return id


# El dibujo de un icono (el nombre que da icono()) para pintarlo en cualquier sitio del juego: las armas y la fregona,
# con el de la tienda de armas (assets/ui/tienda/<nombre>.png, de 48, en diagonal y llenando su cuadro: 16 nov); lo
# demás (objetos, munición, lanzables, materiales...), con el icono de siempre (assets/ui/iconos/<nombre>.png, de 32).
# null si no hay ninguno. Cada sitio lo encaja en el cuadro donde iba el icono viejo (ver de_tienda())
static func textura(nombre: String) -> Texture2D:
	for ruta in ["res://assets/ui/tienda/%s.png" % nombre, "res://assets/ui/iconos/%s.png" % nombre]:
		if ResourceLoader.exists(ruta):
			return load(ruta)
	return null


# Si ese dibujo es uno de la tienda de armas (de 48 y sin margen que quitarle: llena su cuadro)
static func de_tienda(tex: Texture2D) -> bool:
	return tex != null and tex.resource_path.begins_with("res://assets/ui/tienda/")


# Las casillas de la mochila (una lista de ids, uno por objeto): [[id, cuántos], ...] en el orden en que se cogieron y,
# al final, las curas (USABLES, en su orden): en el inventario van aparte, en su grupo «Curas» (M67), y no ocupan
# casilla de «Objetos» (ocupadas). La gasolina, el bidón de ácido y la batería no ocupan casilla de la mochila, sino
# de la munición (Armas.MUNICION; Johnny los cuenta ahí), salvo con "con_municion" (para guardarlos en el baúl)
static func casillas(mochila: Array, con_municion := false) -> Array:
	var cuantos := {}
	for id in mochila:
		if con_municion or not id in Armas.MUNICION:
			cuantos[id] = cuantos.get(id, 0) + 1
	var lista := []
	for id in cuantos:
		if not id in USABLES:
			lista.append([id, cuantos[id]])
	for id in USABLES:
		if id in cuantos:
			lista.append([id, cuantos[id]])
	return lista


# Cuántas casillas de «Objetos» ocupa la mochila (las curas no cuentan: van en su grupo)
static func ocupadas(mochila: Array) -> int:
	return casillas(mochila).filter(func(c): return not c[0] in USABLES).size()


# ¿Cabe uno más? Si ya lleva alguno va a su casilla; si no, hace falta una libre (la gasolina, el bidón de ácido y
# la batería van con la munición: johnny.sitio). Las curas, como mucho su TOPE, en su grupo (CURAS casillas, que
# siempre llegan: solo hay dos)
static func cabe(mochila: Array, id: String) -> bool:
	if mochila.count(id) >= TOPE.get(id, 1000):
		return false
	return id in mochila or id in USABLES or ocupadas(mochila) < MOCHILA


# Lo que cabe de un objeto en una casilla del baúl (la Fase 3 del dueño, 15 nov; antes, 99 de todo): la munición
# (las balas, los cartuchos, la cinta, las granadas de 40 mm y también la gasolina, el bidón de ácido, la batería y el
# nitrógeno), lo de un hueco de munición de la mochila (Armas.MUNICION: 24 balas, 12 cartuchos, 3 bidones...); las
# curas, lo de su montón en la mochila (TOPE); lo demás (las piezas), MONTON
static func monton(id: String) -> int:
	if id in Armas.MUNICION:
		return int(Armas.MUNICION[id].hueco)
	return TOPE.get(id, MONTON)


# Lo que cabe de unos arrojables en una casilla del baúl: lo mismo que en un montón en la mano (Lanzables.cabe_en_monton:
# 2, más uno por cada punto del Artificiero y los de su calidad), con los talentos del guardado "s" (el baúl se abre en
# la sala de mantenimiento, sin partida). Si sube el Artificiero, los montones que ya están no cambian: solo caben más
# en los nuevos y en los que no estén llenos
static func monton_arrojables(s: Dictionary, id: String, calidad: int) -> int:
	return Lanzables.cabe_en_monton(id, calidad, Talentos.aplicar(Mejoras.base(), s.get("talentos", {})))


# Casillas ocupadas del baúl: las de cada objeto (el baúl guarda cuántos hay y se reparten en casillas llenas, de
# monton(), y una última con lo que sobra), y una por cada arma y cada casilla de arrojables ("baul_equipo" del
# guardado; los arrojables, hasta monton_arrojables en cada una: arrojables_al_baul). Puede pasar de BAUL (al acabar la
# partida entra todo, y un guardado de antes de los montones pequeños se reparte en más casillas): entonces no se puede
# guardar nada más hasta sacar lo que sobra
static func casillas_baul(s: Dictionary) -> int:
	var n: int = s.get("baul_equipo", []).size()
	for id in s.baul:
		if s.baul[id] > 0:
			n += ceili(s.baul[id] / float(monton(id)))
	return n


# ¿Queda alguna casilla libre en el baúl? (para un arma, que siempre va en una nueva; los arrojables: caben_arrojables)
static func hueco_baul(s: Dictionary) -> bool:
	return casillas_baul(s) < BAUL


# ── Los arrojables en el baúl ──
# Van en su "baul_equipo" ({"id": el tipo, "calidad", "n"}) y, como los objetos, los del mismo tipo y calidad se juntan
# en una casilla hasta monton_arrojables; lo que pasa, a otra (el M18 del dueño; lanzables.gd)

# ¿Esa casilla del baúl es de arrojables de ese tipo, esa calidad y esas partidas por delante (la durabilidad:
# Armas.nuevas; "quedan" -1, las de unos sin estrenar)? Los que ya han salido en esta partida ("usada") van aparte
static func es_arrojable(e: Dictionary, id: String, calidad: int, quedan := -1, usada := false) -> bool:
	var q := quedan if quedan >= 0 else Armas.nuevas(calidad) + 1
	return e.has("n") and e.id == id and int(e.get("calidad", 0)) == calidad and Armas.quedan_de(e) == q 		and bool(e.get("usada", false)) == usada


# Cuántos de esos arrojables caben en el baúl: lo que falta para llenar sus casillas y un montón por cada casilla libre
static func caben_arrojables(s: Dictionary, id: String, calidad: int, quedan := -1, usada := false) -> int:
	var tope := monton_arrojables(s, id, calidad)
	var n := maxi(0, BAUL - casillas_baul(s)) * tope
	for e in s.baul_equipo:
		if es_arrojable(e, id, calidad, quedan, usada):
			n += maxi(0, tope - int(e.n))
	return n


# Mete "n" de esos arrojables en el baúl del guardado "g": en sus casillas que no estén llenas y luego en otras nuevas
# (al final), aunque no quede sitio (al acabar la partida entra todo; al guardar a mano, se mira antes con
# caben_arrojables)
static func arrojables_al_baul(g: Dictionary, id: String, calidad: int, n: int, quedan := -1, usada := false) -> void:
	var tope := monton_arrojables(g, id, calidad)
	for e in g.baul_equipo:
		if n > 0 and es_arrojable(e, id, calidad, quedan, usada) and int(e.n) < tope:
			var entran := mini(n, tope - int(e.n))
			e.n = int(e.n) + entran
			n -= entran
	while n > 0:
		var entran := mini(n, tope)
		var e := {"id": id, "calidad": calidad, "n": entran}
		if quedan >= 0:
			e.quedan = quedan
		if usada:
			e.usada = true
		g.baul_equipo.append(e)
		n -= entran


# Al acabar la partida (ganes, caigas o abandones: partida.gd, terminar), la durabilidad (Armas.nuevas): lo que ha
# salido del baúl en ella y se ha quedado sin partidas se destruye, aunque se haya vuelto a guardar; lo demás deja de
# estar "usado". Luego entra lo que lleva encima ("equipo": partida.equipo_encima), si le quedan partidas. Devuelve lo
# destruido que merece decirse en el cartel del final ([{"id", "calidad"}]: sin la fregona ni la pistola Normales ni los
# arrojables Normales, que se rompen en todas las partidas). La fregona mejorada no se queda en el baúl: se aparta
# (apartar_fregona), también si se ha dejado en el suelo, y si se ha quedado sin partidas se rompe y el cartel lo dice.
# Y toda la munición del baúl (Armas.MUNICION: balas, cartuchos, gasolina...) se destruye: no pasa de una partida a otra
# (16 nov, lo pidió el dueño; la que lleva Johnny tampoco vuelve: partida.gd y garaje.gd no meten la de la mochila)
static func cerrar_baul(g: Dictionary, equipo: Array) -> Array:
	for id in Armas.MUNICION:
		g.baul.erase(id)
	var rotas := []
	var quedan := []
	for e in g.baul_equipo:
		if e.get("usada", false) and Armas.quedan_de(e) <= 0:
			rotas.append(e)
			continue
		e.erase("usada")
		quedan.append(e)
	g.baul_equipo = quedan
	# la fregona mejorada con la que ha empezado: ahora se mira si la lleva o la ha guardado en el baúl
	var empezada := {}
	if g.fregona.get("usada", false):
		empezada = g.fregona
		g.fregona = {}
	var llevada := {}
	for cosa in equipo:
		if int(cosa.get("quedan", 0)) <= 0:
			rotas.append(cosa)
		elif es_fregona_mejorada(cosa):
			llevada = {"id": cosa.id, "calidad": cosa.calidad, "quedan": cosa.quedan}
		elif cosa.has("n"):
			arrojables_al_baul(g, cosa.id, cosa.calidad, cosa.n, cosa.quedan)
		else:
			g.baul_equipo.append({"id": cosa.id, "calidad": cosa.calidad, "quedan": cosa.quedan})
	# si no la lleva ni está en el baúl (ni se ha roto ya, llevada o guardada en su última partida), la ha dejado en el
	# suelo: no se pierde, vuelve a su sitio con las partidas que le quedan (F22, 15 nov); si era su última, se rompe
	if not empezada.is_empty() and llevada.is_empty() and not rotas.any(es_fregona_mejorada) 			and not g.baul_equipo.any(es_fregona_mejorada):
		if Armas.quedan_de(empezada) <= 0:
			rotas.append({"id": empezada.id, "calidad": empezada.calidad, "quedan": 0})
		else:
			llevada = {"id": empezada.id, "calidad": empezada.calidad, "quedan": empezada.quedan}
	apartar_fregona(g, llevada)
	return rotas.filter(func(e): return int(e.get("calidad", 0)) > 0 		or (not e.has("n") and not e.id in Armas.SIEMPRE.values()))


# ── La fregona mejorada (15 nov, lo pidió el dueño) ──
# La fregona de calidad mayor que Normal no va al baúl: se aparta en "fregona" del guardado ({"id", "calidad", "quedan"}:
# las partidas que aún puede salir, como en el baúl) y Johnny empieza cada partida con ella en la mano, gastando una
# (Armas.estrenar: partida.dar_fregona). Es la única arma que se gasta sola. Cuando se queda sin partidas, se rompe al
# acabar (cerrar_baul, con su fila en el cartel del final) y vuelve la Normal de siempre (Armas.SIEMPRE)

static func es_fregona_mejorada(e: Dictionary) -> bool:
	return str(e.get("id", "")) == Armas.SIEMPRE.cuerpo and int(e.get("calidad", 0)) > 0 and not e.has("n")


# Aparta la mejor fregona mejorada (más calidad y, si empatan, más partidas): de la que ya estaba apartada (si no ha
# salido en esta partida), la que lleva Johnny ("llevada", al acabar: cerrar_baul) y las del baúl (las de un guardado de
# antes del 15 nov, al cargarlo: Guardado.cargar_archivo, o la que ha guardado a mano en esta partida). Las que sobran,
# si hay más de una, se quedan en el baúl
static func apartar_fregona(g: Dictionary, llevada: Dictionary) -> void:
	var fuera := []   # las que no están en el baúl
	if not g.fregona.is_empty() and not g.fregona.get("usada", false):
		fuera.append(g.fregona)
	if not llevada.is_empty():
		fuera.append(llevada)
	var todas: Array = fuera + g.baul_equipo.filter(es_fregona_mejorada)
	if todas.is_empty():
		g.fregona = {}
		return
	var mejor: Dictionary = todas[0]
	for e in todas:
		if int(e.calidad) > int(mejor.calidad) or (int(e.calidad) == int(mejor.calidad) and Armas.quedan_de(e) > Armas.quedan_de(mejor)):
			mejor = e
	for i in range(g.baul_equipo.size() - 1, -1, -1):
		if is_same(g.baul_equipo[i], mejor):
			g.baul_equipo.remove_at(i)
	for e in fuera:
		if not is_same(e, mejor):
			g.baul_equipo.append({"id": e.id, "calidad": int(e.calidad), "quedan": Armas.quedan_de(e)})
	g.fregona = {"id": Armas.SIEMPRE.cuerpo, "calidad": int(mejor.calidad), "quedan": Armas.quedan_de(mejor)}


# Todo lo que puede ir en el baúl como objeto, en el orden de NOMBRES y, al final, el botiquín (que no es de NOMBRES:
# no sale al azar ni cuenta en Colecciones) y la munición que no es un objeto (las balas y los cartuchos: se guardan
# en el baúl, pero en la partida no van en la mochila sino en los huecos de munición; Armas.MUNICION)
static func todos() -> Array:
	var lista := NOMBRES.keys()
	for id in USABLES:
		if not id in lista:
			lista.append(id)
	for id in Armas.MUNICION:
		if not id in lista:
			lista.append(id)
	return lista


# Cuántos salen del baúl de una vez al sacarlos: la munición (la gasolina y los bidones también), una casilla entera,
# que es un hueco de munición (monton); todo lo demás (las piezas, las curas), de uno en uno
static func tanda(id: String) -> int:
	return monton(id) if id in Armas.MUNICION else 1


# Cuántos más de ese objeto caben en el baúl: lo que falta para llenar su última casilla (hasta monton) y un montón por
# cada casilla libre
static func caben_baul(s: Dictionary, id: String) -> int:
	var hay: int = s.baul.get(id, 0)
	var tope := monton(id)
	var en_la_ultima := (tope - hay % tope) % tope
	return en_la_ultima + maxi(0, BAUL - casillas_baul(s)) * tope


# ¿Cabe al menos uno en el baúl? Si su última casilla no está llena va a ella; si no, hace falta una libre
static func cabe_baul(s: Dictionary, id: String) -> bool:
	return caben_baul(s, id) > 0


# Qué objeto suelta un zombi al morir ("" = nada; desde el 15 nov solo lo mira el guardia: partida.gd): el gordo, solo
# lo suyo (DE_UN_ZOMBI: el bidón de ácido), 1 de cada 4 veces. "tienda" es el tipo de la tienda donde ha caído ("" en
# el pasillo o en un apartamento). Las piezas van aparte (salen de los muebles: pieza_de_mueble)
static func que_suelta(tipo: String, edificio := "apartamentos", tienda := "", municion: Variant = "*") -> String:
	for id in DE_UN_ZOMBI:
		if DE_UN_ZOMBI[id] == tipo:
			return id if randf() < SUELTA_PROPIO and (municion is String or id in municion) else ""
	return al_azar(edificio, tienda, municion) if randf() < SUELTA else ""


# Un objeto cualquiera de los que salen ahí, menos los de un solo zombi (DE_UN_ZOMBI; el jefe suelta dos seguros) y
# las piezas (PIEZAS). En los Apartamentos, la gasolina o la batería; en el centro comercial, uno de la lista de su
# tienda (en el pasillo, de una tienda cualquiera).
# "municion": con la lista de la que gastan las armas que lleva Johnny (partida.municion_que_lleva: la de la mano y la de
# repuesto), solo sale la munición que le sirve (la gasolina, la batería y el bidón de ácido, los que llenan el
# lanzallamas, el lanza rayos y el lanza ácido) y, si no hay otra cosa que soltar, nada; "*" = sin mirar (las pruebas)
static func al_azar(edificio := "apartamentos", tienda := "", municion: Variant = "*") -> String:
	var lista: Array
	if edificio == "apartamentos":
		lista = NOMBRES.keys().filter(func(id): return id not in DE_UN_ZOMBI and id not in SOLO_CENTRO and id not in PIEZAS \
			and id not in COMIDAS)
	else:
		if tienda not in TIENDAS:
			tienda = TIENDAS.keys().pick_random()
		lista = TIENDAS[tienda]
	if municion is Array:
		lista = lista.filter(func(id): return not id in MUNICION_DE_OBJETO or id in municion)
	return lista.pick_random() if not lista.is_empty() else ""


# Lo que hay dentro de un mueble al abrirlo ("" = vacío): PIEZA_MUEBLE de las veces, un material al azar. Con "familias"
# (las armas que lleva Johnny: partida.familias_que_lleva), solo salen los de esas familias; si no lleva ninguna, nada.
# Sin lista, de las cuatro (las pruebas)
static func pieza_de_mueble(familias: Variant = null) -> String:
	var lista: Array = PIEZAS.keys() if familias == null \
		else PIEZAS.keys().filter(func(id): return PIEZAS[id] in familias)
	return lista.pick_random() if not lista.is_empty() and randf() < PIEZA_MUEBLE else ""


# Si la nevera y la encimera se abren: solo cuando ya vive alguien en los trasteros (si no, su comida no serviría)
static func hay_comida() -> bool:
	return not Guardado.cargar().rescatados.is_empty()


# Lo que hay en la nevera o la encimera al abrirlas ("" = vacía): COMIDA_MUEBLE de las veces, la comida favorita de uno
# de los que viven en los trasteros, al azar
static func comida_de_mueble() -> String:
	var suyas := []
	for id in Guardado.cargar().rescatados:
		var c: String = Supervivientes.DATOS.get(id, {}).get("comida", "")
		if c != "":
			suyas.append(c)
	return suyas.pick_random() if not suyas.is_empty() and randf() < COMIDA_MUEBLE else ""


# Cuántas piezas suelta un jefe al caer en el centro comercial o en la torre (PIEZAS_JEFE); cada
# una, de una familia al azar
static func piezas_de_jefe() -> Array:
	var lista := []
	for i in PIEZAS_JEFE:
		lista.append(PIEZAS.keys().pick_random())
	return lista


# ── Lo encontrado (para el logro de los objetos; Colecciones ya no lo enseña desde el 8 nov) ──
# Lo encontrado alguna vez se apunta en el guardado ("encontrados"): lo cuenta el logro (logros.gd).

# Los que salen en un edificio, en el orden de NOMBRES: en los Apartamentos, todos menos las vendas; en el centro
# comercial, todos. Otro valor: todos
static func de_edificio(edificio: String) -> Array:
	if edificio == "apartamentos":
		return NOMBRES.keys().filter(func(id): return not id in SOLO_CENTRO and not id in COMIDAS)
	return NOMBRES.keys().filter(func(id): return not id in COMIDAS)   # (la comida, aparte: COMIDAS)


# Dónde sale un objeto, para la línea de abajo de su ficha: en los Apartamentos lo suelta cualquier durmiente (el bidón
# de ácido, solo el gordo, y las piezas, los muebles que se abren, en los tres edificios); en el centro comercial, las
# tiendas que lo sueltan ("Ferretería, electrónica y supermercado")
static func donde(id: String, edificio: String) -> String:
	if id in PIEZAS:
		return Idioma.t("sale de los muebles que se abren: armarios, mesillas, escritorios, cajas registradoras, archivadores...")
	if id in COMIDAS:
		return Idioma.t("sale de las neveras y las encimeras de las cocinas. Es la comida favorita de: %s") % Supervivientes.de_comida(id)
	if id == "bidon_acido":
		return Idioma.t("lo suelta el gordo")
	if edificio != "centro":
		return Idioma.t("lo suelta cualquier durmiente")
	var tiendas := []
	for tipo in TIENDAS:
		if id in TIENDAS[tipo]:
			var n := Tienda.nombre(tipo)   # (ya traducido)
			# (en español, solo la primera con mayúscula; en inglés, los nombres de tienda se quedan como vienen)
			tiendas.append(n if tiendas.is_empty() or Idioma.actual != Idioma.ORIGEN else n.to_lower())
	if tiendas.is_empty():
		return ""
	if tiendas.size() == 1:
		return tiendas[0]
	return Idioma.t("%s y %s") % [", ".join(tiendas.slice(0, -1)), tiendas[-1]]


# Apunta un objeto como encontrado alguna vez (al cogerlo del suelo). El botiquín de la
# farmacéutica no cuenta (no está en NOMBRES); las vendas, sí
static func apuntar_encontrado(id: String) -> void:
	if not id in NOMBRES or id in COMIDAS:   # (la comida no cuenta para el logro)
		return
	Guardado.cambiar(func(g):
		if not id in g.encontrados:   # (solo para el logro: Colecciones ya no enseña los objetos)
			g.encontrados.append(id))
