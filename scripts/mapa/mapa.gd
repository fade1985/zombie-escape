# Monta un sitio de la planta (el pasillo, un apartamento, la sala de mantenimiento, las viviendas de los
# rescatados, la exposición o la sala de pruebas) a partir de sus datos (planta.gd):
#   - el suelo de cada habitación y la tapa de los muros (vistos desde arriba), en un dibujo de fondo
#   - las caras de los muros (de frente, 3 casillas de alto), ordenadas con los personajes
#   - los choques de los muros, las puertas, los muebles (mueble.gd) y la llave
#   - el mapa de por dónde se puede andar (navegación), para que los zombis rodeen tabiques y muebles
#   - la niebla: en un apartamento, las habitaciones que aún no se han pisado se ven a oscuras, y lo que hay
#     dentro ni se ve ni se le puede apuntar (como src/game-mapa.js del juego JS); en las viviendas, las cerradas
#
# Las texturas son las mismas del juego JS (assets/sprites/): cada habitación elige su suelo y su pared con
# una cuenta sobre su posición, así que dos habitaciones iguales de sitio salen iguales.
extends Node2D

signal llave_cogida
signal dorada_cogida   # la tarjeta dorada de la cámara acorazada de la joyería (joyeria.gd)

const CASILLA := 32
const MURO := 64
const VELO := Color(0.68, 0.68, 0.68)   # la tapa de los muros, oscurecida para que quede por detrás del suelo
const CONTORNO := Color("#1d1b2c")      # la raya oscura "de dibujo animado" donde el suelo toca un muro (como en el JS)
const FILO := Color(1, 1, 1, 0.14)      # el filo de luz de la tapa de los muros, junto al contorno
# la pletina de latón gastado del paso entre dos habitaciones, en rayas de 1 píxel: sombra, brillo, latón y sombra
const PLETINA := [Color("#2a221c"), Color("#b8a37a"), Color("#8a7552"), Color("#4a3c2c")]
const CARA := preload("res://scripts/mapa/cara_pared.gd")
const TABIQUE := preload("res://scripts/mapa/tabique.gd")   # lo alto de las paredes, con "cajas" (poner_cajas)
const FUERA := Color(0.05, 0.04, 0.06)   # con "cajas", el muro que sobra alrededor: oscuro, como el fondo de fuera del mapa
const PUERTA := preload("res://scripts/mapa/puerta.gd")
const MUEBLE := preload("res://scripts/mapa/mueble.gd")
const ORDENADOR := preload("res://scripts/mapa/ordenador.gd")
const EXCLAMACION := preload("res://scripts/mapa/exclamacion.gd")   # el «!» de encima de la taquilla con una skin sin ver
# Lo que se usa de la sala de mantenimiento, en la pared de arriba de sus estancias (planta.gd; lo demás son muebles
# del catálogo): la mesa del ordenador, en medio de la del despacho, con el corcho colgado a su izquierda; el banco de
# trabajo y el baúl, en el taller, a la derecha de la estantería; y la taquilla de las skins de Johnny
# (skins.gd), en el vestuario, en medio de lo que deja libre el plato de ducha
const ORDENADOR_X := 576.0
const CORCHO_X := 480.0
const CORCHO := preload("res://assets/sprites/corcho.png")   # (tools/guias_mantenimiento.py)
const ARMARITO := preload("res://scripts/mapa/armarito.gd")
const ARRIMABLE := preload("res://scripts/mapa/arrimable.gd")
const BANCO_X := 918.0
const BAUL_X := 1010.0
const TAQUILLA_X := 260.0
# Los suelos y paredes de las estancias de la sala de mantenimiento: el taller, con los de siempre (cemento y la pared
# blanca y verde); el vestuario, de azulejo, como los baños de los pisos; y el despacho, con tarima y la pared beis con
# friso de madera de los salones. [suelo, pared]: sprites suelo-<x>, pared-<x> y techo-<x>
const ESTILO_MANTENIMIENTO := {"taller": ["mantenimiento", "mantenimiento"], "vestuario": ["bano-b", "bano-b"],
	"despacho": ["salon-a", "salon-c"]}
const PUERTA_BANO := preload("res://scripts/mapa/puerta_bano.gd")   # las puertas de dentro de las casas (y las cerradas de las viviendas)
const CARTEL_SALIDA := preload("res://scripts/mapa/cartel_salida.gd")   # el EXIT de la salida de incendios (encima de la pared de arriba del pasillo)
const CARTEL_SALIDA_A := 76.0   # a cuánto del fondo del pasillo va su centro
const CARTEL_TRASTEROS := preload("res://scripts/mapa/cartel_trasteros.gd")   # el de la entrada del pasillo de las viviendas
const LINEA_TRASTERO := preload("res://assets/sprites/linea-trastero.png")   # la línea amarilla del suelo de ese pasillo (tools/trastero.py)
const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const APLIQUE := preload("res://assets/sprites/aplique-pared.png")
const LLAVE := preload("res://assets/sprites/objeto-llave-puerta.png")
const MANCHAS := preload("res://assets/sprites/manchas-suelo.png")
const HELIPUERTO := preload("res://assets/sprites/helipuerto.png")   # el de la azotea (tools/azotea.py)
const VALLA := preload("res://scripts/mapa/valla.gd")
# El suelo y la pared de las habitaciones de un piso que no dependen de dónde caen (que cambia al voltear el piso):
# "<uso>-<tipo>" -> [sufijo del suelo, sufijo de la pared] (suelo-<estilo><sufijo>, pared-<estilo><sufijo>; con "" en uno, ese
# se sigue eligiendo según dónde cae). El dormitorio de matrimonio, siempre con el suelo gris azulado y el papel beige, con la
# puerta arriba y abajo; el individual, con el suelo rojo; el salón, con el suelo de madera de nogal, oscuro y con las tablas en
# horizontal (tools/suelo_salon.py), para que no se confunda con el del pasillo (que sigue con el de siempre)
const ESTILO_FIJO := {"dormitorio-matrimonio": ["-a", "-b"], "dormitorio-individual": ["-b", ""], "salon": ["-nogal", ""]}
const ESTILO_DE := {"salon": "salon", "jefe": "salon", "cocina": "cocina", "dormitorio": "dormitorio", "bano": "bano"}
# Las salas de las tiendas del centro comercial: [suelos (uno al azar), pared]. Sprites suelo-<x>, pared-<x> y
# techo-<x>. El aseo de las tiendas usa los del baño de los pisos (ESTILO_DE).
const ESTILO_TIENDA := {
	"tienda": [["venta-a", "venta-b"], "venta"], "jefe": [["venta-a", "venta-b"], "venta"],
	"almacen": [["almacen"], "almacen"], "camara": [["camara"], "camara"], "cocina": [["cocinaind"], "cocinaind"],
	"taller": [["linoleo"], "almacen"], "taquillas": [["linoleo"], "almacen"], "rebotica": [["linoleo"], "venta"],
	"probadores": [["moqueta"], "venta"],
	# la joyería (parte 9): su sala de venta con mármol ("<uso>-<tipo de tienda>" manda sobre "<uso>"), la trastienda
	# como un almacén y la cámara acorazada con suelo de chapa de acero
	"tienda-joyeria": [["marmol"], "venta"], "trastienda": [["linoleo"], "almacen"], "acorazada": [["acorazada"], "almacen"]}
# El pasillo de cada edificio (planta.gd lo apunta en "estilo"): su suelo y pared, su tapa y si lleva alfombra
const PASILLOS := {"pasillo": {"tapa": "pasillo", "alfombra": true}, "galeria": {"tapa": "centro", "alfombra": false}}
const NEON := preload("res://scripts/mapa/neon.gd")
# Los peligros de las tiendas del centro comercial, y la porquería del Glotón (peligros.gd): cada uno con su nodo
const PELIGROS := {"frio": preload("res://scripts/peligros/frio.gd"), "fuego": preload("res://scripts/peligros/fuego.gd"),
	"agua": preload("res://scripts/peligros/agua.gd"),
	"porqueria": preload("res://scripts/peligros/porqueria.gd"),   # (y la de la habitación del Glotón, en los Apartamentos)
	"tropiezos": preload("res://scripts/peligros/tropiezos.gd"),   # (las mancuernas del gimnasio y los cubos de la portera)
	"cerco": preload("res://scripts/peligros/cerco.gd"),   # (el borde en llamas de la habitación del jefe de bomberos)
	"luz_jefe": preload("res://scripts/peligros/luz_jefe.gd")}   # (no es un peligro: la luz fija de las habitaciones de los jefes de los Apartamentos)
# Lo que cuelga de la pared de arriba del cuarto de la limpieza de la portera (tools/guias_limpieza.py): fregonas
# (las que más) y cubos, uno detrás de otro con este hueco entre ellos (en píxeles del dibujo, [mínimo, máximo])
const COLGADOS := [preload("res://assets/sprites/colgado-fregona.png"), preload("res://assets/sprites/colgado-fregona.png"),
	preload("res://assets/sprites/colgado-cubo.png")]
const COLGADOS_HUECO := [6.0, 30.0]
# Los restos sueltos del centro comercial (sprites resto-<nombre>, tools/centro_sprites.py): el juego los reparte al
# azar por el suelo y las paredes de cada tienda y de la galería, para que haya sangre y destrozo por todas partes
# sin que se note que la textura se repite. Los repetidos en la lista salen más a menudo.
const RESTOS_SUELO := ["sangre", "sangre", "cristales", "cristales", "latas", "ropa", "cascotes", "papeles", "papeles"]
const RESTOS_AZOTEA := ["sangre", "latas", "cascotes", "cascotes", "papeles"]   # en la azotea, menos y sin ropa
const RESTOS_AZOTEA_MAX := 12
const RESTOS_PARED := ["salpicon", "salpicon", "huellas", "pintada", "agujero"]
const RESTOS_POR_CASILLA := 1.0 / 30.0    # en el suelo, uno de cada tantas casillas libres (entre 4 y 24)
const RESTOS_PARED_CADA := 192.0          # en las paredes, como mucho uno por cada tramo de este largo...
const RESTOS_PARED_SUERTE := 0.45         # ...y no siempre
const OSCURO := Color(0.07, 0.063, 0.11)   # el color de la niebla
const NIEBLA := preload("res://escenas/luces/niebla.gdshader")
const NIEBLA_FONDO := 0.74                 # lo que tapa la niebla a tope (1 = no se ve nada debajo)
const ACLARA := 3.5                       # lo rápido que se aclara una habitación al descubrirla (por segundo)
# los zombis de la exposición, en el orden de las teclas de prueba
const EXPO_ZOMBIS := ["zombi_normal", "zombi_lento", "zombi_rapido", "zombi_explosivo", "zombi_tentaculos",
	"zombi_venenoso", "zombi_vigilante", "zombi_dependienta", "portera", "antidisturbios", "cocinero", "modista",
	"mascota", "gerente", "gloton", "gymbro", "bombero", "cientifico_jefe"]
const RUMBOS := ["s", "so", "o", "no", "n", "ne", "e", "se"]

var sitio: Dictionary
var cols := 0
var filas := 0
var dueno := PackedInt32Array()   # de quién es cada casilla: su habitación (0, 1...), -1 muro, -2 hueco de puerta
var estilos := {}                 # habitación -> {suelo, pared, techo} (texturas)
var tapa: Texture2D
var alfombra: Texture2D
var cosas: Node2D                 # personajes, muebles y caras de muro, ordenados por su "y"
var puertas: Array = []           # una por salida, en el mismo orden
var hojas: Array = []             # las puertas de dentro (puerta_bano.gd), una por hueco entre habitaciones
var muebles: Array = []
var ordenador: Node2D = null     # la mesa del ordenador (solo en la sala de mantenimiento)
var baul: Node2D = null          # y el baúl y el banco de trabajo
var banco: Node2D = null
var taquilla: Node2D = null      # y la taquilla de las skins de Johnny (skins.gd)
var armaritos: Array = []        # los armaritos con botiquín de los baños (armarito.gd)
# La niebla (solo en los apartamentos): por habitación, cuánta oscuridad le queda (1 negro, 0 nada). Las
# habitaciones ya descubiertas se apuntan en el sitio ("vistas"), así siguen claras al volver.
var niebla := {}
var vistas := {}
var caras := {}                   # habitación -> sus caras de muro (llevan su propia niebla)
var velo: Node2D                  # donde se pinta la niebla, por encima de todo
var sala_casilla := PackedInt32Array()   # la habitación de cada casilla (-1 muro), para la niebla
var con_niebla := PackedByteArray()      # 1 en las casillas a las que se les pinta niebla encima
var mascara: Image                # la textura de la niebla, una casilla por píxel (ver pintar_mascara)
var textura_niebla: ImageTexture
var expo_sprites: Array = []      # los zombis de la exposición, que van girando
var expo_t := 0.0
var centro := false               # si es del centro comercial (una tienda, la galería o la azotea): lleva restos sueltos
var cajas := false                # cada habitación, una caja cerrada por sus tabiques, con oscuro alrededor (viviendas.gd)
var al_aire := false              # con cajas, la azotea: el murete, gris oscuro y plano por los cuatro lados (arriba, en su cara)
var alzados := {}                 # con cajas, las casillas de la pantalla con tabique que sube (poner_tabiques): Vector2i -> true
var restos: Array = []            # los del suelo: {dibujo (textura), pos, giro, espejo}
var dado_restos := RandomNumberGenerator.new()   # con la semilla del sitio: al volver, todo sigue en su sitio
var peligros: Array = []          # los nodos de los peligros del sitio (frío, fuego, agua con corriente)
var valla: Node2D = null          # la valla de la rampa del helipuerto (solo en la azotea; valla.gd)


func montar(datos: Dictionary, llave := Vector2.INF, tarjeta := false) -> void:
	sitio = datos
	add_to_group("mapa")
	cajas = sitio.get("cajas", false)
	al_aire = cajas and sitio.get("azotea", false)
	cols = int(sitio.ancho / CASILLA)
	filas = int(sitio.alto / CASILLA)
	if sitio.has("dueno"):
		# un rectángulo con muros de 2 casillas alrededor; todo el suelo es la "habitación" 0
		dueno = sitio.dueno
		if sitio.tipo == "pasillo":
			var estilo: String = sitio.get("estilo", "pasillo")
			estilos[0] = textura(estilo, "")
			tapa = load("res://assets/sprites/tapa-%s.png" % PASILLOS[estilo].tapa)
			if PASILLOS[estilo].alfombra:
				alfombra = load("res://assets/sprites/alfombra-pasillo.png")
		elif sitio.get("estilo", "") == "azotea":
			# la azotea del centro comercial (tools/azotea.py): hormigón, y el murete con la ciudad de noche detrás
			estilos[0] = {"suelo": load("res://assets/sprites/suelo-hormigon.png"),
				"pared": load("res://assets/sprites/pared-azotea.png"), "techo": load("res://assets/sprites/techo-azotea.png")}
			tapa = load("res://assets/sprites/tapa-azotea.png")
		else:   # la exposición del modo pruebas: como el taller de la sala de mantenimiento
			estilos[0] = textura("mantenimiento", "")
			tapa = load("res://assets/sprites/tapa-generica.png")
	else:
		dueno = sitio.apt.dueno
		var tienda: bool = sitio.get("tienda", "") != ""
		# la de todo el piso, como en el JS; en el centro comercial, la suya; en las viviendas, la del pasillo; en la
		# sala de mantenimiento, la de siempre
		tapa = load("res://assets/sprites/tapa-centro.png" if tienda else "res://assets/sprites/tapa-pasillo.png"
			if sitio.tipo == "viviendas" else "res://assets/sprites/tapa-generica.png" if sitio.tipo == "mantenimiento"
			else "res://assets/sprites/tapa-salon.png")
		var comun: Dictionary = {}   # el estilo de siempre del salón: el pasillo del piso toma este, aunque el salón lleve otro suelo
		for s in sitio.apt.salas:
			if sitio.tipo == "mantenimiento":
				var de: Array = ESTILO_MANTENIMIENTO[s.uso]
				estilos[s.id] = {"suelo": load("res://assets/sprites/suelo-%s.png" % de[0]),
					"pared": load("res://assets/sprites/pared-%s.png" % de[1]), "techo": load("res://assets/sprites/techo-%s.png" % de[1])}
				continue
			var h: int = s.c0 * 7 + s.f0 * 13 + s.casillas
			if s.uso == "pasillo" and s.get("tipo", "") == "piso":
				# el de dentro de un piso con pasillo (apartamento.gd), como su salón, que va primero: como en una casa
				estilos[s.id] = comun if not comun.is_empty() else estilos[0]
				continue
			if s.uso == "pasillo":
				# el pasillo de las viviendas, el de una zona de trasteros: el suelo de hormigón de los trasteros (con su
				# línea amarilla: dibujar_fondo) y su chapa, con la franja de chapa lagrimada abajo (tools/trastero.py)
				estilos[s.id] = {"suelo": load("res://assets/sprites/suelo-trastero.png"),
					"pared": load("res://assets/sprites/pared-trastero-pasillo.png"),
					"techo": load("res://assets/sprites/techo-trastero.png")}
				continue
			if s.uso == "habitacion":
				# las habitaciones de las viviendas son los trasteros del edificio: todas iguales, de chapa crema con el suelo
				# de hormigón gris azulado (suelo-, pared- y techo-trastero: tools/trastero.py)
				estilos[s.id] = textura("trastero", "")
				continue
			var propio: String = s.uso + "-" + sitio.get("tienda", "")   # el estilo de ese tipo de tienda, si lo tiene
			if tienda and (ESTILO_TIENDA.has(propio) or ESTILO_TIENDA.has(s.uso)):
				var clave: String = propio if ESTILO_TIENDA.has(propio) else s.uso
				var suelos: Array = ESTILO_TIENDA[clave][0]
				var pared: String = ESTILO_TIENDA[clave][1]
				estilos[s.id] = {"suelo": load("res://assets/sprites/suelo-%s.png" % suelos[h % suelos.size()]),
					"pared": load("res://assets/sprites/pared-%s.png" % pared),
					"techo": load("res://assets/sprites/techo-%s.png" % pared)}
				continue
			var estilo: String = ESTILO_DE[s.uso]
			if estilo == "bano":
				# los baños de los pisos, siempre de azulejo verde (suelo y pared "-b", como el vestuario de mantenimiento); los
				# aseos de las tiendas, unos según dónde caen
				estilos[s.id] = textura("bano", "-b", "-b") if not tienda else \
					textura("bano", "-a" if h % 2 else "-b", "-a" if (h >> 1) % 2 else "-b")
			else:
				# el suelo y la pared, los de su tipo si los tiene fijos (ESTILO_FIJO) y si no, unos según dónde cae la habitación
				var fijo: Array = ESTILO_FIJO.get(s.uso + ("-" + s.tipo if s.has("tipo") else ""), [])
				var suelo_h: String = ["-a", "-b", "-c"][h % 3]
				var pared_h: String = ["-a", "-b", "-c"][(h / 3) % 3]
				if s.uso == "salon":
					comun = textura(estilo, suelo_h, pared_h)
				estilos[s.id] = textura(estilo, fijo[0] if not fijo.is_empty() and fijo[0] != "" else suelo_h,
					fijo[1] if not fijo.is_empty() and fijo[1] != "" else pared_h)

	centro = sitio.get("tienda", "") != "" or sitio.get("estilo", "") in ["galeria", "azotea"]
	if centro:
		dado_restos.seed = int(sitio.get("surtido", 0)) + 7
		preparar_restos()

	var fondo := Node2D.new()
	fondo.name = "Fondo"
	fondo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fondo.light_mask = Luz.CAPA_SUELO   # el suelo es lo único que recibe sombras (ver luz.gd)
	fondo.z_index = -10   # por debajo de todo: los charcos, las manchas y los cuerpos (z -1 y -2) quedan encima
	fondo.draw.connect(dibujar_fondo.bind(fondo))
	add_child(fondo)
	var tapas := Node2D.new()
	tapas.name = "Tapas"
	tapas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tapas.light_mask = Luz.CAPA_COSAS
	tapas.z_index = -10
	tapas.draw.connect(dibujar_tapas.bind(tapas))
	add_child(tapas)
	var navegacion := NavigationRegion2D.new()
	navegacion.name = "Navegacion"
	add_child(navegacion)
	cosas = Node2D.new()
	cosas.name = "Cosas"
	cosas.y_sort_enabled = true
	add_child(cosas)

	poner_muros()
	poner_caras()
	poner_puertas()
	poner_muebles()
	poner_helipuerto()
	poner_apliques()
	poner_escaparates()
	poner_peligros()
	for a in sitio.get("armaritos", []):
		var armarito := ARMARITO.new()
		armarito.montar(a)
		armarito.mapa = self
		armarito.zona = zona_en(Vector2(a.x, a.y + 24.0))   # la habitación que tiene delante
		cosas.add_child(armarito)
		armaritos.append(armarito)
	if llave != Vector2.INF:
		poner_llave(llave, tarjeta)
	if sitio.tipo == "expo":
		poner_exposicion()
	hornear(navegacion)
	if sitio.tipo == "armas":
		add_child(SalaArmas.new())   # la sala de pruebas: la diana, las líneas de ayuda, su panel de daño y el baúl de pruebas (sala_armas.gd)
	if sitio.has("apt"):
		preparar_niebla()
	# Johnny y los suyos vienen de otro sitio: vuelven a la capa 1 (en un apartamento, separar_salas les pone
	# la de su habitación)
	Luz.capa_johnny = Luz.CAPA_COSAS
	for quien in get_tree().get_nodes_in_group("jugador") + get_tree().get_nodes_in_group("presa"):
		quien.remove_meta("sala")
		Luz.poner_capa(quien, Luz.CAPA_COSAS)
	set_process(sitio.has("apt") or sitio.tipo == "expo")


func textura(estilo: String, suelo: String, pared := "") -> Dictionary:
	return {"suelo": load("res://assets/sprites/suelo-%s%s.png" % [estilo, suelo]),
		"pared": load("res://assets/sprites/pared-%s%s.png" % [estilo, pared]),
		"techo": load("res://assets/sprites/techo-%s%s.png" % [estilo, pared])}


func es_muro(c: int, f: int) -> bool:
	return c < 0 or f < 0 or c >= cols or f >= filas or dueno[f * cols + c] == -1


# La habitación de una casilla de suelo; los huecos de puerta toman la de al lado
func sala_de(c: int, f: int) -> int:
	var v := dueno[f * cols + c]
	if v != -2:
		return v
	for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]:
		if not es_muro(c + d.x, f + d.y) and dueno[(f + d.y) * cols + c + d.x] >= 0:
			return dueno[(f + d.y) * cols + c + d.x]
	return 0


# En qué habitación está un punto (-1 si es muro o está fuera)
func zona_en(pos: Vector2) -> int:
	var c := int(pos.x / CASILLA)
	var f := int(pos.y / CASILLA)
	if es_muro(c, f):
		return -1
	return sala_de(c, f)


# Cómo suena un disparo en un punto (la pistola tiene una versión de cada, en sonido.gd): "seca" al aire libre o
# donde hay sofás, camas o ropa que se comen el eco; "eco" en pasillos y salas grandes; "duro" en los cuartos
# pequeños de azulejo o metal (baño, cocina, cámara, almacén, la sala de mantenimiento...)
func acustica_en(pos: Vector2) -> String:
	if sitio.get("azotea", false):
		return "seca"
	var zona := zona_en(pos)
	if not sitio.has("apt") or zona < 0:
		return "eco"   # el pasillo de la planta, la exposición, la sala de pruebas
	match String(sitio.apt.salas[zona].uso):
		"salon", "dormitorio", "probadores", "habitacion":
			return "seca"
		"tienda":
			return "seca" if sitio.get("tienda", "") == "ropa" else "eco"
		"jefe", "pasillo":
			return "eco"
	return "duro"


func nombre_zona(zona: int) -> String:
	if not sitio.has("apt") or zona < 0:
		return ""
	return sitio.apt.salas[zona].nombre


# Las tapas de los muros, aparte del suelo: se quedan en la capa 1, que en un apartamento alumbran las lámparas
# pero no la linterna de Johnny (ver separar_salas). Si no, el haz se subiría encima de los muros y parecería
# que los atraviesa
func dibujar_tapas(lienzo: Node2D) -> void:
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if cajas:
		# la franja de encima del mapa y el muro que sobra, oscuros, como fuera del mapa; los tabiques, planos, vistos desde arriba, con
		# su filo de luz y su contorno donde se acaban (donde no sigue tabique, ni plano ni de los que suben)
		lienzo.draw_rect(Rect2(-16, -48, cols * 16 + 32, 48), FUERA)
		for f in filas:
			for c in cols:
				if not es_muro(c, f):
					continue
				var x := c * 16
				var y := f * 16
				if not es_tabique(c, f):
					lienzo.draw_rect(Rect2(x, y, 16, 16), FUERA)
					continue
				lienzo.draw_rect(Rect2(x, y, 16, 16), TABIQUE.COLOR)   # (en la azotea, el murete: del mismo gris)
				if not borde_en(c, f - 1):
					lienzo.draw_rect(Rect2(x, y + 1, 16, 1), TABIQUE.FILO)
					lienzo.draw_rect(Rect2(x, y - 1, 16, 2), CONTORNO)
				if not borde_en(c, f + 1):
					lienzo.draw_rect(Rect2(x, y + 14, 16, 1), TABIQUE.FILO)
					lienzo.draw_rect(Rect2(x, y + 15, 16, 2), CONTORNO)
				if not borde_en(c - 1, f):
					lienzo.draw_rect(Rect2(x + 1, y, 1, 16), TABIQUE.FILO)
					lienzo.draw_rect(Rect2(x - 1, y, 2, 16), CONTORNO)
				if not borde_en(c + 1, f):
					lienzo.draw_rect(Rect2(x + 14, y, 1, 16), TABIQUE.FILO)
					lienzo.draw_rect(Rect2(x + 15, y, 2, 16), CONTORNO)
		return
	# la franja de tapa de encima del mapa (la cámara deja ver un poco más arriba, por la cara del muro de arriba)
	lienzo.draw_texture_rect_region(tapa, Rect2(-16, -48, cols * 16 + 32, 48), Rect2(-16, -48, cols * 16 + 32, 48), VELO)
	for f in filas:
		var c := 0
		while c < cols:
			if not es_muro(c, f):
				c += 1
				continue
			var fin := c + 1
			while fin < cols and es_muro(fin, f):
				fin += 1
			var trozo := Rect2(c * 16, f * 16, (fin - c) * 16, 16)
			lienzo.draw_texture_rect_region(tapa, trozo, trozo, VELO)
			c = fin
	# el filo de luz por fuera del mapa, arriba y a la izquierda (como en el JS)
	lienzo.draw_rect(Rect2(2, 2, cols * 16 - 4, 2), FILO)
	lienzo.draw_rect(Rect2(2, 2, 2, filas * 16 - 4), FILO)
	# y donde el muro toca el suelo: el filo de luz en la tapa y el contorno oscuro justo en la raya (mitad en el
	# muro, mitad en el suelo), así cada muro se ve como un bloque con borde y no se funde con el suelo
	for f in filas:
		for c in cols:
			if not es_muro(c, f):
				continue
			var x := c * 16
			var y := f * 16
			if not es_muro(c, f - 1):   # suelo arriba
				lienzo.draw_rect(Rect2(x, y + 1, 16, 1), FILO)
				lienzo.draw_rect(Rect2(x, y - 1, 16, 2), CONTORNO)
			if not es_muro(c, f + 1):   # suelo abajo
				lienzo.draw_rect(Rect2(x, y + 14, 16, 1), FILO)
				lienzo.draw_rect(Rect2(x, y + 15, 16, 2), CONTORNO)
			if not es_muro(c - 1, f):   # suelo a la izquierda
				lienzo.draw_rect(Rect2(x + 1, y, 1, 16), FILO)
				lienzo.draw_rect(Rect2(x - 1, y, 2, 16), CONTORNO)
			if not es_muro(c + 1, f):   # suelo a la derecha
				lienzo.draw_rect(Rect2(x + 14, y, 1, 16), FILO)
				lienzo.draw_rect(Rect2(x + 15, y, 2, 16), CONTORNO)


# La habitación de una casilla (-1 si es muro o está fuera del mapa, -2 si es un hueco de puerta)
func dueno_en(c: int, f: int) -> int:
	return -1 if c < 0 or f < 0 or c >= cols or f >= filas else dueno[f * cols + c]


# Los suelos, en píxeles del dibujo (por eso el transform x2). La textura se repite contando desde la
# esquina del mapa, así que las baldosas casan aunque una habitación tenga forma de L.
func dibujar_fondo(lienzo: Node2D) -> void:
	lienzo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	for f in filas:
		var c := 0
		while c < cols:
			var muro := es_muro(c, f)
			var sala := -1 if muro else sala_de(c, f)
			var fin := c + 1
			while fin < cols and es_muro(fin, f) == muro and (muro or sala_de(fin, f) == sala):
				fin += 1
			var trozo := Rect2(c * 16, f * 16, (fin - c) * 16, 16)
			if not muro:
				lienzo.draw_texture_rect_region(estilos[sala].suelo, trozo, trozo)
			c = fin
	# Los huecos de puerta entre dos habitaciones: cada suelo llega hasta la mitad del paso (arriba se ha
	# pintado entero con el de una de ellas) y, donde se juntan, la pletina de latón
	for f in filas:
		for c in cols:
			if dueno_en(c, f) != -2:
				continue
			var abajo := dueno_en(c, f + 1)
			var derecha := dueno_en(c + 1, f)
			if dueno_en(c, f - 1) >= 0 and abajo >= 0:   # habitaciones arriba y abajo: pletina tumbada
				var mitad := Rect2(c * 16, f * 16 + 8, 16, 8)
				lienzo.draw_texture_rect_region(estilos[abajo].suelo, mitad, mitad)
				for i in PLETINA.size():
					lienzo.draw_rect(Rect2(c * 16, f * 16 + 6 + i, 16, 1), PLETINA[i])
			elif dueno_en(c - 1, f) >= 0 and derecha >= 0:   # a izquierda y derecha: pletina de pie
				var mitad := Rect2(c * 16 + 8, f * 16, 8, 16)
				lienzo.draw_texture_rect_region(estilos[derecha].suelo, mitad, mitad)
				for i in PLETINA.size():
					lienzo.draw_rect(Rect2(c * 16 + 6 + i, f * 16, 1, 16), PLETINA[i])
	if alfombra:
		# la alfombra larga del pasillo, por el centro y de punta a punta (a media escala)
		var largo := (cols - 4) * 16 - 56
		var y := filas * 8 - 16
		lienzo.draw_texture_rect_region(alfombra, Rect2(32 + 28, y, largo, 32), Rect2(0, 0, largo * 2, alfombra.get_height()))
	# la línea amarilla pintada a lo largo del pasillo de las viviendas (viviendas.gd: "linea"), de punta a punta
	for s in sitio.get("apt", {}).get("salas", []):
		if s.has("linea"):
			var linea := Rect2(s.c0 * 16, s.linea / 2.0 - 1, s.ancho * 16, LINEA_TRASTERO.get_height())
			lienzo.draw_texture_rect_region(LINEA_TRASTERO, linea, Rect2(linea.position.x, 0, linea.size.x, linea.size.y))
	# el helipuerto de la azotea: la plataforma, con su cara y su rampa a la izquierda (sus choques, poner_helipuerto)
	if sitio.has("helipuerto"):
		lienzo.draw_texture(HELIPUERTO, Vector2(Planta.rampa(sitio).position.x, Planta.plataforma(sitio).position.y) / 2.0)
	# las manchas de sangre de la sala de mantenimiento (y la azotea): cada una gira de 90 en 90 grados y se voltea al azar
	for m in sitio.get("manchas", []):
		lienzo.draw_set_transform(m.pos, m.giro * PI / 2.0, Vector2(-2 if m.espejo else 2, 2))
		lienzo.draw_texture_rect_region(MANCHAS, Rect2(-30, -18, 60, 36), Rect2(m.dibujo * 60, 0, 60, 36))
	# y los restos sueltos del centro comercial, igual (de 90 en 90 grados y volteados)
	for r in restos:
		var t: Texture2D = r.dibujo
		lienzo.draw_set_transform(r.pos, r.giro * PI / 2.0, Vector2(-2 if r.espejo else 2, 2))
		lienzo.draw_texture(t, -(t.get_size() / 2.0).floor())


# Los choques del helipuerto de la azotea (planta.gd): a la plataforma solo se sube por la rampa. Chocan su borde, la
# cara de delante, las barandillas de la rampa y la cara de la rampa (un triángulo, que crece hacia la plataforma), en
# la capa Planta.CAPA_BORDE: paran a los que andan, no a las balas, porque es bajo. La navegación lo recorta (grupo
# "obstaculos"), así que los zombis y el jefe también suben y bajan por la rampa. En lo alto de la rampa, la valla
# (valla.gd), metida en el suelo hasta que empieza la pelea
func poner_helipuerto() -> void:
	if not sitio.has("helipuerto"):
		return
	var p := Planta.plataforma(sitio)
	var r := Planta.rampa(sitio)
	var b := Planta.PLATAFORMA_BORDE
	var alto := Planta.PLATAFORMA_ALTO
	var bar := Planta.BARANDILLA
	var cuerpo := StaticBody2D.new()
	cuerpo.name = "Helipuerto"
	cuerpo.collision_layer = Planta.CAPA_BORDE
	cuerpo.collision_mask = 0
	cuerpo.add_to_group("obstaculos")
	add_child(cuerpo)
	for caja in [Rect2(p.position.x, p.position.y, p.size.x, b),            # el borde de arriba
			Rect2(p.end.x - b, p.position.y, b, p.size.y),                    # el de la derecha
			Rect2(p.position.x, p.end.y - b, p.size.x, b + alto),             # el de abajo, con la cara de delante
			Rect2(p.position.x, p.position.y, b, r.position.y + bar - p.position.y),   # el de la izquierda, encima
			Rect2(p.position.x, r.end.y - bar, b, p.end.y - r.end.y + bar),            # y debajo de la rampa
			Rect2(r.position.x, r.position.y, r.size.x, bar),                 # las barandillas de la rampa
			Rect2(r.position.x, r.end.y - bar, r.size.x, bar)]:
		var forma := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = caja.size
		forma.shape = rect
		forma.position = caja.get_center()
		cuerpo.add_child(forma)
	var cara := CollisionShape2D.new()
	var triangulo := ConvexPolygonShape2D.new()
	triangulo.points = PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2(r.end.x, r.end.y + alto)])
	cara.shape = triangulo
	cuerpo.add_child(cara)
	valla = VALLA.new()
	valla.montar(Rect2(p.position.x, r.position.y, b, r.size.y), self)
	cosas.add_child(valla)


# Si un punto está encima del helipuerto, donde se puede estar (sin el borde). "margen": lo que tiene que quedar
# hasta el borde (el radio de quien esté ahí)
func en_plataforma(pos: Vector2, margen := 0.0) -> bool:
	return sitio.has("helipuerto") and Planta.plataforma(sitio).grow(-Planta.PLATAFORMA_BORDE - margen).has_point(pos)


# El punto de encima del helipuerto más cercano a "pos", con "margen" hasta el borde (los zombis que llama el jefe con
# la valla cerrada: que salgan dentro del ring)
func a_la_plataforma(pos: Vector2, margen: float) -> Vector2:
	var dentro := Planta.plataforma(sitio).grow(-Planta.PLATAFORMA_BORDE - margen)
	return pos.clamp(dentro.position, dentro.end)


# Los choques de los muros: rectángulos grandes (se juntan las casillas seguidas de cada fila, y las filas
# iguales seguidas)
func poner_muros() -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = "Muros"
	cuerpo.add_to_group("obstaculos")
	add_child(cuerpo)
	var abiertos := {}   # "c0,c1" -> [fila de inicio, fila de fin]
	var cajas := []
	for f in filas + 1:
		var tramos := {}
		var c := 0
		while f < filas and c < cols:
			if es_muro(c, f):
				var fin := c
				while fin + 1 < cols and es_muro(fin + 1, f):
					fin += 1
				tramos["%d,%d" % [c, fin]] = true
				c = fin + 1
			else:
				c += 1
		for clave in abiertos.keys():
			if not tramos.has(clave):
				cajas.append([clave, abiertos[clave][0], f - 1])
				abiertos.erase(clave)
		for clave in tramos:
			if not abiertos.has(clave):
				abiertos[clave] = [f]
	for caja in cajas:
		var c0 := int(caja[0].get_slice(",", 0))
		var c1 := int(caja[0].get_slice(",", 1))
		var forma := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2((c1 - c0 + 1) * CASILLA, (caja[2] - caja[1] + 1) * CASILLA)
		forma.shape = rect
		forma.position = Vector2(c0 * CASILLA, caja[1] * CASILLA) + rect.size / 2.0
		cuerpo.add_child(forma)
		# y su sombra: la luz de una habitación no pasa a la de al lado a través del tabique
		var sombra := LightOccluder2D.new()
		var huella := OccluderPolygon2D.new()
		var r := Rect2(forma.position - rect.size / 2.0, rect.size)
		huella.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		sombra.occluder = huella
		cuerpo.add_child(sombra)


# Una cara en cada tramo de muro que tiene suelo justo debajo, con el papel de la habitación de debajo
func poner_caras() -> void:
	for f in filas - 1:
		var c := 0
		while c < cols:
			if not (es_muro(c, f) and not es_muro(c, f + 1)) or (cajas and not cara_de_caja(c, f)):
				c += 1
				continue
			var sala := sala_de(c, f + 1)
			var fin := c + 1
			while fin < cols and es_muro(fin, f) and not es_muro(fin, f + 1) and sala_de(fin, f + 1) == sala 					and (not cajas or cara_de_caja(fin, f)):
				fin += 1
			var cara := CARA.new()
			cara.position = Vector2(c * CASILLA, (f + 1) * CASILLA)
			cara.ancho = (fin - c) * CASILLA
			cara.pared = estilos[sala].pared
			cara.techo = estilos[sala].techo
			cara.moldura = not cajas or al_aire   # con cajas, encima va su tabique (en la azotea no: encima, el cielo)
			cara.puede_tapar = f > 1   # el muro de fuera de arriba no tiene a nadie detrás
			if centro and sitio.get("estilo", "") != "azotea":   # (el murete es bajo: lo de encima es el cielo)
				cara.adornos = restos_de_pared(cara.ancho)
			if sitio.get("apt", {}).get("tipo", "") == "portera":
				cara.adornos += colgados(cara)
			cosas.add_child(cara)
			if not caras.has(sala):
				caras[sala] = []
			caras[sala].append(cara)
			c = fin
	# Encima de cada puerta de un tabique de lado a lado, el dintel: el trozo de muro que queda sobre su marco
	# (puerta_bano.gd), con el papel de la habitación de debajo, como lo de los lados
	for d in sitio.get("apt", {}).get("puertas", []):
		if d.fondo != 1:
			continue
		var sala := sala_de(d.c, d.f + 1)
		var dintel := CARA.new()
		dintel.position = Vector2(d.c * CASILLA, (d.f + 1) * CASILLA)
		dintel.ancho = d.ancho * CASILLA
		dintel.desde = PUERTA_BANO.DINTEL
		dintel.pared = estilos[sala].pared
		dintel.techo = estilos[sala].techo
		dintel.moldura = not cajas or al_aire
		dintel.puede_tapar = true
		cosas.add_child(dintel)
		caras.get_or_add(sala, []).append(dintel)
	if cajas:
		poner_tabiques()
		return
	# Donde un tabique cuelga de una pared con suelo encima (el pasillo de las viviendas, la cocina junto al pasillo de
	# un piso...), las paredes de los lados tienen su cara de 3 casillas pero el tabique solo empezaba al pie de ella:
	# dejaba un hueco con el suelo de arriba a la vista y la pared parecía más baja. Ahí el tabique sube hasta lo alto
	# de la pared de al lado (con la tapa del muro), así cada habitación queda cerrada por los lados a toda su altura.
	# Va al final, aparte, para no cambiar los restos al azar de las demás caras
	for f in filas - 1:
		var c := 0
		while c < cols:
			if not tabique_colgado(c, f):
				c += 1
				continue
			var fin := c + 1
			while fin < cols and tabique_colgado(fin, f):
				fin += 1
			var izq := es_muro(c - 1, f) and not es_muro(c - 1, f + 1)   # a cada lado, ¿la pared tiene cara?
			var der := es_muro(fin, f) and not es_muro(fin, f + 1)
			if izq or der:
				var tabique := CARA.new()
				tabique.position = Vector2(c * CASILLA, (f + 1) * CASILLA)
				tabique.ancho = (fin - c) * CASILLA
				tabique.tapa = tapa
				tabique.velo = VELO
				tabique.filo = FILO
				tabique.contorno = CONTORNO
				tabique.borde_izq = not es_muro(c - 1, f)   # el contorno oscuro, donde da al suelo
				tabique.borde_der = not es_muro(fin, f)
				tabique.puede_tapar = f > 1
				cosas.add_child(tabique)
			c = fin


# Un trozo de muro con muro debajo y suelo encima: de él cuelga un tabique (poner_caras)
func tabique_colgado(c: int, f: int) -> bool:
	return es_muro(c, f) and es_muro(c, f + 1) and not es_muro(c, f - 1)


# Con "cajas" (las viviendas), como se ve una casa por dentro desde arriba: cada habitación, cerrada por sus tabiques
# (es_tabique), de una casilla de grueso. Solo la pared de arriba de cada una tiene altura: su cara (poner_caras), y
# encima, a lo alto de la pared, su tabique (tabique.gd), con los de los lados subiendo hasta él. Lo demás de los
# tabiques (los lados y la pared de abajo) se ve plano, desde arriba, sin tapar nada (mapa.dibujar_tapas). Aquí se
# deciden los trozos de tabique que suben ("alzados", en casillas de la pantalla) y se ponen
func poner_tabiques() -> void:
	alzados.clear()
	if al_aire:
		return   # la azotea: el murete es bajo, ya se ve entero en su cara (lo de encima es el cielo); ninguno sube
	var tramos := []   # [fila, primera columna, la de después de la última]
	for f in filas:
		var c := 0
		while c < cols:
			if not es_tabique(c, f):
				c += 1
				continue
			var fin := c + 1
			while fin < cols and es_tabique(fin, f):
				fin += 1
			# un trozo de muro de lado a lado con alguna cara: sube entero, y donde no cae cara (las esquinas y donde
			# se junta un tabique de los lados), baja hasta su casilla, para que el tabique de los lados siga hasta arriba
			if range(c, fin).any(func(k): return cara_de_caja(k, f)):
				tramos.append([f, c, fin])
				for k in range(c, fin):
					alzados[Vector2i(k, f - TABIQUE.SUBE)] = true
					if not cara_de_caja(k, f) and dueno_en(k, f) != -2:   # (encima de una puerta, su dintel)
						for y in range(f - TABIQUE.SUBE + 1, f):
							alzados[Vector2i(k, y)] = true
			c = fin
	for t in tramos:
		var f: int = t[0]
		var tramo := TABIQUE.new()
		tramo.position = Vector2(t[1] * CASILLA, (f + 1) * CASILLA)   # ordenado con la cara que cae de él
		tramo.ancho = (t[2] - t[1]) * CASILLA
		var y := f - TABIQUE.SUBE
		for k in range(t[1], t[2]):
			var baja := alzados.has(Vector2i(k, y + 1))
			tramo.casillas.append({"baja": baja, "arriba": not borde_en(k, y - 1), "abajo": not baja,
				"izq": [not borde_en(k - 1, y), not borde_en(k - 1, y + 1), not borde_en(k - 1, y + 2)],
				"der": [not borde_en(k + 1, y), not borde_en(k + 1, y + 1), not borde_en(k + 1, y + 2)]})
		cosas.add_child(tramo)


# Con "cajas": ¿es tabique esta casilla? Los muros que tocan un suelo (también en diagonal: las esquinas) y los huecos
# de las puertas; el resto del muro se ve oscuro (FUERA)
func es_tabique(c: int, f: int) -> bool:
	var v := dueno_en(c, f)
	if v != -1:
		return v == -2
	if c < 0 or f < 0 or c >= cols or f >= filas:
		return false
	for df in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			var w := dueno_en(c + dc, f + df)
			if w >= 0 or w == -2:
				return true
	return false


# Con "cajas": ¿se ve tabique en esta casilla de la pantalla? El plano (un muro que es tabique) o uno que sube
func borde_en(c: int, y: int) -> bool:
	return (es_muro(c, y) and es_tabique(c, y) and c >= 0 and y >= 0 and c < cols and y < filas) 		or alzados.has(Vector2i(c, y))


# Con "cajas": un muro del que cae una cara: con suelo debajo y de un tabique de lado a lado (el final de uno de los
# lados, encima de una puerta entre dos habitaciones de lado, no: ese se ve plano, con el hueco de la puerta)
func cara_de_caja(c: int, f: int) -> bool:
	return es_muro(c, f) and f + 1 < filas and not es_muro(c, f + 1) and (es_tabique(c - 1, f) or es_tabique(c + 1, f))


func poner_puertas() -> void:
	for i in sitio.salidas.size():
		var salida: Dictionary = sitio.salidas[i]
		var puerta := PUERTA.new()
		puerta.salida = salida
		puerta.indice = i
		puerta.centro = centro
		puerta.name = "Puerta%d" % i
		match salida.dir:
			"arriba": puerta.position = Vector2(salida.en, MURO)
			"abajo": puerta.position = Vector2(salida.en, sitio.alto - MURO)
			"izquierda": puerta.position = Vector2(MURO, salida.en)
			"derecha": puerta.position = Vector2(sitio.ancho - MURO, salida.en)
		if salida.dir == "arriba":
			# delante de la cara del muro (que tiene su pie en la misma "y")
			puerta.position.y += 1
			cosas.add_child(puerta)
			if salida.has("neon"):
				# la fachada de una tienda del centro comercial: su letrero de neón encima de la puerta
				var neon := NEON.new()
				var tipo: Dictionary = Tienda.TIPOS[salida.neon]
				neon.texto = tipo.neon
				neon.color = tipo.color
				neon.semilla = fposmod(sin(salida.en * 12.9898) * 43758.5453, 1.0)
				neon.position = puerta.position
				cosas.add_child(neon)
		else:
			add_child(puerta)
			move_child(puerta, 1)   # justo encima del suelo, por debajo de los personajes
		if salida.tipo == "escaleras":
			# la salida de incendios: su cartel EXIT en la pared de arriba, al final del pasillo, que se enciende cuando
			# se puede pasar (la puerta se lo dice: puerta.gd)
			var cartel := CARTEL_SALIDA.new()
			cartel.position = Vector2(sitio.ancho - MURO - CARTEL_SALIDA_A, MURO + 1)
			cosas.add_child(cartel)
			puerta.cartel = cartel
		puertas.append(puerta)


# Los muebles que planta.gd ha decidido para este sitio (muebles.gd), con su variante
func poner_muebles() -> void:
	for m in sitio.get("muebles", []):
		var mueble := MUEBLE.new()
		mueble.montar(m, sitio.surtido)
		cosas.add_child(mueble)
		muebles.append(mueble)
		if (m.tipo == "lamp" or m.tipo == "nightstand") and not m.get("apagada", false):
			poner_lampara(mueble, m)   # (las apagadas, sin luz ni brillo: solo el dibujo)
	if sitio.tipo == "armas":
		# el baúl de pruebas de la sala de pruebas (sala_armas.gd), arriba a la izquierda
		baul = ARRIMABLE.new()
		baul.montar("Baul", "res://assets/sprites/baul.png", MURO + 4 * Planta.CASILLA, MURO, 60.0, 36.0)
		cosas.add_child(baul)
	if sitio.tipo == "mantenimiento":
		ordenador = ORDENADOR.new()
		ordenador.montar(ORDENADOR_X, MURO)
		cosas.add_child(ordenador)
		baul = ARRIMABLE.new()
		baul.montar("Baul", "res://assets/sprites/baul.png", BAUL_X, MURO, 60.0, 36.0)
		cosas.add_child(baul)
		banco = ARRIMABLE.new()
		banco.montar("Banco", "res://assets/sprites/banco-trabajo.png", BANCO_X, MURO, 76.0, 36.0)
		cosas.add_child(banco)
		taquilla = ARRIMABLE.new()   # la de las skins de Johnny (tools/taquilla.py): al arrimarse, partida.abrir_taquilla
		taquilla.montar("Taquilla", "res://assets/sprites/taquilla.png", TAQUILLA_X, MURO, 56.0, 36.0)
		cosas.add_child(taquilla)
		var marca_skin := EXCLAMACION.new()   # (hasta que se abra la taquilla con una skin nueva: Skins.desbloquear)
		marca_skin.name = "Exclamacion"
		marca_skin.condicion = func() -> bool: return Guardado.cargar().skins_nuevo
		marca_skin.position = Vector2(0, -load("res://assets/sprites/taquilla.png").get_height() * 2.0 - 30.0)
		taquilla.add_child(marca_skin)
		# el corcho del despacho, colgado en la cara del muro de arriba (en su pie, como los escaparates de la galería,
		# para ordenarse con ella), con su borde de abajo a media pared
		var corcho := Node2D.new()
		corcho.name = "Corcho"
		corcho.position = Vector2(CORCHO_X, MURO + 1)
		var dibujo := Sprite2D.new()
		dibujo.texture = CORCHO
		dibujo.centered = false
		dibujo.scale = Vector2(2, 2)
		dibujo.position = Vector2(-CORCHO.get_width(), -28 - CORCHO.get_height() * 2)
		corcho.add_child(dibujo)
		cosas.add_child(corcho)
	if sitio.tipo == "viviendas":
		poner_viviendas()
	elif sitio.has("apt"):
		poner_hojas()


# Las puertas de dentro de los pisos, las tiendas y la sala de mantenimiento (puerta_bano.gd con "libre"): una en cada
# hueco entre habitaciones, cerrada hasta que alguien la abre. Menos en los cerrados con llave (el baño del superviviente
# y la cámara acorazada): esas las ponen supervivientes.gd y joyeria.gd
func poner_hojas() -> void:
	for d in sitio.apt.puertas:
		if d.get("cerrada", false):
			continue
		var hoja := PUERTA_BANO.new()
		hoja.libre = true
		hoja.montar(d)
		cosas.add_child(hoja)
		hojas.append(hoja)


# Las viviendas de los supervivientes (viviendas.gd). Las de quien aún no
# está rescatado, cerradas (con su hoja, que no deja pasar ni ver lo de dentro: la niebla sigue); las de los rescatados,
# abiertas y ya descubiertas. Se mira el guardado cada vez que se monta
func poner_viviendas() -> void:
	var rescatados: Array = Guardado.cargar().rescatados
	var descubiertas: Dictionary = sitio.get_or_add("vistas", {})
	descubiertas[0] = true   # el pasillo
	for d in sitio.apt.puertas:
		d.cerrada = d.vecino not in rescatados
		var hoja := PUERTA_BANO.new()
		hoja.trastero = true   # la puerta de un trastero: azul lisa, con el pomo de metal
		if d.cerrada:
			hoja.montar(d)
			descubiertas.erase(d.a)
		else:
			# la de un rescatado, abierta de par en par (libre y ya abierta: no choca ni tapa la luz)
			hoja.libre = true
			d.abierta = true
			hoja.montar(d)
			descubiertas[d.a] = true
		cosas.add_child(hoja)
	# el cartel de «TRASTEROS», en la pared de arriba, nada más entrar (en el pie de la cara del muro, para ordenarse con ella)
	var cartel := CARTEL_TRASTEROS.new()
	cartel.position = Vector2((Viviendas.BORDE + Viviendas.CARTEL) * CASILLA, Viviendas.PASILLO_F * CASILLA + 1)
	cosas.add_child(cartel)


# Las lámparas de pie y las mesillas (con su lamparita) dan luz de verdad; algunas fallan, como los apliques, y las
# lamparitas de las mesillas siempre (la casa lleva días sin que nadie la arregle). En los apartamentos (los pisos y la
# habitación de cada jefe), todas las que están encendidas: la instalación eléctrica está fallando. Cada una a su aire: la
# semilla sale de su sitio, así que dos lámparas no fallan a la vez.
# Su propia sombra se quita: la luz sale de dentro de su hueco y lo dejaría todo a oscuras.
func poner_lampara(mueble: Node2D, m: Dictionary) -> void:
	mueble.get_node("Sombra").free()
	var luz := LAMPARA.instantiate()
	luz.semilla = fposmod(sin(m.x * 12.9898 + m.y * 78.233) * 43758.5453, 1.0)
	var apartamento: bool = sitio.tipo in ["apartamento", "jefe"] and sitio.get("tienda", "") == ""
	luz.parpadea = apartamento or m.tipo == "nightstand" or luz.semilla < 0.2
	luz.alto = 72.0 if m.tipo == "lamp" else 56.0
	luz.radio = 210.0 if m.tipo == "lamp" else 150.0
	luz.mapa = self
	luz.zona = m.zona
	if sitio.has("apt"):   # en un apartamento, solo alumbra su habitación (y las tapas de los muros)
		luz.get_node("LuzCosas").range_item_cull_mask = Luz.CAPA_COSAS | Luz.capa_sala(m.zona)
	mueble.add_child(luz)


# Los apliques de la pared de arriba del pasillo (planta.gd): su dibujo y su luz. El nodo va en el pie de la
# cara del muro, para ordenarse con ella; el charco de luz cae 60 unidades más abajo, en el suelo.
func poner_apliques() -> void:
	for a in sitio.get("apliques", []):
		var luz := LAMPARA.instantiate()
		luz.position = Vector2(a.x, MURO + 1)
		luz.semilla = a.semilla
		luz.parpadea = a.parpadea
		luz.alto = 38.0
		luz.suelo = Vector2(0, 60)
		# si el centro de la luz cae dentro de un mueble, su sombra lo dejaría todo a oscuras: más abajo
		for m in muebles:
			var hueco := Rect2(m.datos.x - m.datos.w / 2.0, m.datos.y - m.datos.h / 2.0, m.datos.w, m.datos.h)
			if hueco.grow(4.0).has_point(luz.position + luz.suelo):
				luz.suelo.y = hueco.end.y + 8.0 - luz.position.y
		var dibujo := Sprite2D.new()
		dibujo.texture = APLIQUE
		dibujo.scale = Vector2(2, 2)
		dibujo.position = Vector2(0, -36)
		luz.add_child(dibujo)
		luz.move_child(dibujo, 0)
		cosas.add_child(luz)


# Los peligros de una tienda (peligros.gd): el frío de la cámara, el fuego de la cocina y el agua con corriente; y
# la porquería de la habitación del Glotón, las mancuernas del gimnasio del Gymbro, los cubos de la portera y el borde
# en llamas de la habitación del jefe de bomberos.
# Van en el suelo, por debajo de los personajes (lo que va en la pared, el cuadro y el cable, lo ponen ellos en cosas)
func poner_peligros() -> void:
	for d in sitio.get("peligros", []):
		var nodo: Node2D = PELIGROS[d.tipo].new()
		nodo.montar(d, self)
		add_child(nodo)
		peligros.append(nodo)


# Los escaparates de las tiendas, en la pared de arriba de la galería (planta.gd): el dibujo apoyado encima del
# rodapié y, a veces, un salpicón o unas huellas de sangre en el cristal. Van en el pie de la cara del muro, como
# los apliques, para ordenarse con ella.
func poner_escaparates() -> void:
	for e in sitio.get("escaparates", []):
		var nodo := Node2D.new()
		nodo.position = Vector2(e.x, MURO + 1)
		var dibujo := Sprite2D.new()
		dibujo.texture = load("res://assets/sprites/escaparate-%s.png" % e.tienda)
		dibujo.centered = false
		dibujo.scale = Vector2(2, 2)
		var t := dibujo.texture.get_size()
		dibujo.position = Vector2(-t.x, -9 - t.y * 2)   # el pie, 4 píxeles por encima del suelo (el rodapié)
		nodo.add_child(dibujo)
		if dado_restos.randf() < 0.6:
			var mancha := Sprite2D.new()
			mancha.texture = load("res://assets/sprites/resto-%s.png" % ["salpicon", "huellas"][dado_restos.randi() % 2])
			mancha.scale = Vector2(2, 2)
			mancha.flip_h = dado_restos.randf() < 0.5
			mancha.position = dibujo.position + Vector2(dado_restos.randf_range(0.25, 0.75) * t.x * 2, t.y * 0.8)
			nodo.add_child(mancha)
		cosas.add_child(nodo)


# Los restos sueltos del suelo de una tienda o de la galería: en casillas de suelo rodeadas de suelo (para que no
# se monten en un muro), con giro y volteo al azar
func preparar_restos() -> void:
	var libres := []
	for f in range(1, filas - 1):
		for c in range(1, cols - 1):
			if dueno[f * cols + c] >= 0 and not (es_muro(c - 1, f) or es_muro(c + 1, f) or es_muro(c, f - 1) or es_muro(c, f + 1)):
				libres.append(Vector2(c, f))
	if libres.is_empty():
		return
	var azotea: bool = sitio.get("estilo", "") == "azotea"
	if sitio.has("helipuerto"):   # en la azotea, nada encima del helipuerto
		var huella := Planta.huella_helipuerto(sitio)
		libres = libres.filter(func(c): return not huella.any(func(h): return h.grow(CASILLA).has_point((c + Vector2(0.5, 0.5)) * CASILLA)))
	var cuantos := clampi(roundi(libres.size() * RESTOS_POR_CASILLA), 4, RESTOS_AZOTEA_MAX if azotea else 24)
	var lista: Array = RESTOS_AZOTEA if azotea else RESTOS_SUELO
	for i in cuantos:
		var casilla: Vector2 = libres[dado_restos.randi() % libres.size()]
		var nombre: String = lista[dado_restos.randi() % lista.size()]
		restos.append({"dibujo": load("res://assets/sprites/resto-%s.png" % nombre),
			"pos": (casilla + Vector2(0.5, 0.5)) * CASILLA + Vector2(dado_restos.randi_range(-4, 4), dado_restos.randi_range(-4, 4)) * 2.0,
			"giro": dado_restos.randi() % 4, "espejo": dado_restos.randf() < 0.5})


# Los restos de una cara de muro de "ancho" unidades: [{dibujo, x, y}] en píxeles del dibujo, contando desde la
# esquina de abajo a la izquierda de la cara (cara_pared.gd los pinta encima del papel)
func restos_de_pared(ancho: float) -> Array:
	var lista := []
	var tramos := floori(ancho / RESTOS_PARED_CADA)
	for i in tramos:
		if dado_restos.randf() > RESTOS_PARED_SUERTE:
			continue
		var t: Texture2D = load("res://assets/sprites/resto-%s.png" % RESTOS_PARED[dado_restos.randi() % RESTOS_PARED.size()])
		var tramo := RESTOS_PARED_CADA / 2.0   # en píxeles del dibujo
		var x := i * tramo + dado_restos.randf_range(0.0, maxf(0.0, tramo - t.get_width()))
		var y := -dado_restos.randf_range(t.get_height() + 6.0, 44.0)   # sin pisar el rodapié ni la moldura
		lista.append({"dibujo": t, "x": floorf(x), "y": floorf(y)})
	return lista


# Las fregonas y los cubos colgados de una cara de muro del cuarto de la limpieza de la portera (planta.gd pone
# apt.tipo = "portera"): uno detrás de otro, con un hueco al azar entre ellos, colgados de lo alto, justo debajo de la
# moldura, menos delante de la puerta. Con su propio dado (de la semilla del sitio): al volver, siguen igual
func colgados(cara: Node2D) -> Array:
	var dado := RandomNumberGenerator.new()
	dado.seed = int(sitio.get("surtido", 0)) + 29 + int(cara.position.x)
	var puertas: Array = sitio.salidas.filter(func(s): return s.dir == "arriba").map(func(s): return s.en)
	var lista := []
	var x := dado.randf_range(4.0, 16.0)   # en píxeles del dibujo, desde el borde izquierdo de la cara
	while true:
		var t: Texture2D = COLGADOS[dado.randi() % COLGADOS.size()]
		var w := t.get_width()
		if x + w > cara.ancho / 2.0 - 4.0:
			break
		# lo que ocupa, en unidades del mapa (la puerta mide 2 casillas: con un poco de margen a cada lado)
		var desde: float = cara.position.x + x * 2.0
		if not puertas.any(func(en): return desde < en + 44.0 and desde + w * 2.0 > en - 44.0):
			lista.append({"dibujo": t, "x": floorf(x), "y": -46.0 if t == COLGADOS[0] else -44.0})
		x += w + dado.randf_range(COLGADOS_HUECO[0], COLGADOS_HUECO[1])
	return lista


# ═════════════ Niebla ═════════════

func preparar_niebla() -> void:
	vistas = sitio.get_or_add("vistas", {})
	for s in sitio.apt.salas:
		niebla[s.id] = 0.0 if vistas.has(s.id) else 1.0
	# De qué habitación es cada casilla (-1 los muros) y si se le pinta niebla encima. Las casillas que tapa la
	# cara de un muro de más abajo (las dos últimas filas antes de un tabique) no: ya las tapa esa cara, que
	# lleva la niebla de su habitación (si no, la cara de una habitación descubierta quedaría a oscuras)
	sala_casilla.resize(cols * filas)
	con_niebla.resize(cols * filas)
	for f in filas:
		for c in cols:
			sala_casilla[f * cols + c] = -1 if es_muro(c, f) else sala_de(c, f)
			con_niebla[f * cols + c] = 0 if es_muro(c, f) or tapada(c, f) else 1
	# Se pinta de una vez, con el shader de la niebla y una textura de una casilla por píxel (ver el shader)
	mascara = Image.create(cols, filas, false, Image.FORMAT_RGBA8)
	pintar_mascara()
	textura_niebla = ImageTexture.create_from_image(mascara)
	velo = Node2D.new()
	velo.name = "Niebla"
	velo.light_mask = 0   # las lámparas no la aclaran
	velo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # para difuminar entre casillas
	var sombra := ShaderMaterial.new()
	sombra.shader = NIEBLA
	sombra.set_shader_parameter("oscuro", OSCURO)
	sombra.set_shader_parameter("fondo", NIEBLA_FONDO)
	velo.material = sombra
	velo.draw.connect(func():
		velo.draw_texture_rect(textura_niebla, Rect2(0, 0, cols * CASILLA, filas * CASILLA), false))
	add_child(velo)
	actualizar_niebla(0.0)


# La textura de la niebla: en rojo, lo oscura que está cada casilla (los muros toman la más oscura de al lado,
# para que la niebla no se aclare al llegar a una pared, solo al llegar a una puerta); en verde, si se pinta
func pintar_mascara() -> void:
	for f in filas:
		for c in cols:
			var n := 0.0
			var sala := sala_casilla[f * cols + c]
			if sala >= 0:
				n = niebla.get(sala, 0.0)
			else:
				for df in [-1, 0, 1]:
					for dc in [-1, 0, 1]:
						var c2: int = c + dc
						var f2: int = f + df
						if c2 >= 0 and f2 >= 0 and c2 < cols and f2 < filas and sala_casilla[f2 * cols + c2] >= 0:
							n = maxf(n, niebla.get(sala_casilla[f2 * cols + c2], 0.0))
			mascara.set_pixel(c, f, Color(n, con_niebla[f * cols + c], 0.0, 1.0))


# ¿Tapa esta casilla de suelo la cara de un muro de debajo?
func tapada(c: int, f: int) -> bool:
	if cajas and alzados.has(Vector2i(c, f)):
		return true   # la tapa un tabique que sube
	for k in [1, 2]:
		if es_muro(c, f + k) and f + k + 1 < filas and not es_muro(c, f + k + 1):
			return true
	return false


# Descubre la habitación en la que está Johnny y, si está en una puerta o pegado a ella, las dos que comunica;
# y va aclarando las descubiertas
func actualizar_niebla(delta: float) -> void:
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and johnny.get_parent() == cosas:
		var c := int(johnny.position.x / CASILLA)
		var f := int(johnny.position.y / CASILLA)
		var aqui := zona_en(johnny.position)
		if aqui >= 0:
			vistas[aqui] = true
		for d in sitio.apt.puertas:
			if d.get("cerrada", false) or not d.get("abierta", true):
				continue   # una puerta cerrada (puerta_bano.gd) no deja ver lo de dentro
			if c >= d.c - 1 and c <= d.c + d.ancho and f >= d.f - 1 and f <= d.f + d.fondo:
				vistas[d.a] = true
				vistas[d.b] = true
	var cambia := delta == 0.0
	for sala in niebla:
		if vistas.has(sala) and niebla[sala] > 0.0:
			niebla[sala] = maxf(0.0, niebla[sala] - delta * ACLARA)
			cambia = true
	if not cambia:
		return
	pintar_mascara()
	textura_niebla.update(mascara)
	for sala in caras:
		for cara in caras[sala]:
			if cara.niebla != niebla.get(sala, 0.0):
				cara.niebla = niebla.get(sala, 0.0)
				cara.queue_redraw()
	for m in muebles:
		var n: float = niebla.get(m.zona, 0.0)
		m.modulate = Color(1, 1, 1).lerp(OSCURO, 0.4 * n)   # poco: encima ya va la niebla, y se intuye la silueta


# ¿Está esto en una habitación que aún no se ha pisado? (entonces ni se ve ni se le apunta)
func oculto(pos: Vector2) -> bool:
	return niebla.get(zona_en(pos), 0.0) > 0.5


# La primera pared (o puerta cerrada, o barricada) que corta la línea de "a" a "b", como la que devuelve intersect_ray
# ("position", "normal"...), o {} si el camino está libre. Los muebles no cuentan: lo que se lanza vuela por encima
func muro_entre(a: Vector2, b: Vector2) -> Dictionary:
	var excluir: Array[RID] = []
	for i in 16:
		var rayo := PhysicsRayQueryParameters2D.create(a, b, 1, excluir)
		var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
		if choque.is_empty() or not choque.collider.is_in_group("muebles"):
			return choque
		excluir.append(choque.rid)
	return {}


func _process(delta: float) -> void:
	if not niebla.is_empty():
		actualizar_niebla(delta)
		for z in get_tree().get_nodes_in_group("zombis"):
			z.visible = not oculto(z.global_position)
		separar_salas()
	if not expo_sprites.is_empty():
		# los zombis de la exposición giran por sus 8 direcciones
		var antes := int(expo_t / 0.7)
		expo_t += delta
		if int(expo_t / 0.7) != antes:
			for s in expo_sprites:
				s.play("reposo_" + RUMBOS[int(expo_t / 0.7) % RUMBOS.size()])


# Cada cosa del mapa (muros, muebles, puertas, zombis, cuerpos, objetos, aliados, Johnny...) va en la capa de
# luz de la habitación en la que tiene los pies (Luz.capa_sala), y las lámparas y la linterna solo alumbran la
# suya: así su luz (la que no hace sombras) no se cuela por las paredes. Las sombras no bastarían: con la vista
# desde arriba, la cara de un muro se dibuja encima del suelo de la habitación de detrás. Solo se cambia lo
# que ha cambiado de habitación (lo nuevo empieza en la capa 1); lo que está en un muro se queda en la 1
func separar_salas() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and zona_en(johnny.global_position) >= 0:
		Luz.capa_johnny = Luz.capa_sala(zona_en(johnny.global_position))
	for cosa in cosas.get_children():
		var sala := zona_en(cosa.global_position)
		if sala < 0 or cosa.get_meta("sala", -1) == sala:
			continue
		cosa.set_meta("sala", sala)
		Luz.poner_capa(cosa, Luz.capa_sala(sala))


# ═════════════ Exposición (modo pruebas) ═════════════

# Todos los muebles del catálogo con sus variantes y su dibujo de lado, a su tamaño real y con su nombre debajo
# (el rectángulo claro es el hueco que ocupa en el suelo); y debajo, los zombis con todas sus ropas, girando.
# Nada choca: es para mirar.
func poner_exposicion() -> void:
	var x := float(MURO + 30)
	var y := float(MURO + 150)    # el pie de la fila
	var alto_fila := 0.0
	for tipo in Catalogo.MUEBLES:
		var p: Dictionary = Catalogo.MUEBLES[tipo]
		var ids := ["mueble-" + tipo]
		for letra in MUEBLE.LETRAS:
			if not MUEBLE.existe("mueble-%s-%s" % [tipo, letra]):
				break
			ids.append("mueble-%s-%s" % [tipo, letra])
		for id in ids.duplicate():
			if MUEBLE.existe(id + "-lado"):
				ids.append(id + "-lado")
		ids = ids.filter(func(id): return MUEBLE.existe(id))   # (el váter y el lavabo del vestuario solo son de lado)
		for id in ids:
			var lado: bool = id.ends_with("-lado")
			var tex: Texture2D = load(MUEBLE.ruta(id))
			var w: float = maxf(tex.get_width() * 2.0, p.dep if lado else p.len)
			if x + w > sitio.ancho - MURO - 30:
				x = MURO + 30
				y += alto_fila + 70
				alto_fila = 0.0
			alto_fila = maxf(alto_fila, tex.get_height() * 2.0)
			var pie := Vector2(x + w / 2.0, y)
			var hueco := ColorRect.new()
			hueco.color = Color(1, 1, 1, 0.18)
			hueco.size = Vector2(p.dep, p.len) if lado else Vector2(p.len, p.dep)
			hueco.position = pie - Vector2(hueco.size.x / 2.0, hueco.size.y)
			add_child(hueco)
			move_child(hueco, 1)
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.scale = Vector2(2, 2)
			sprite.centered = false
			sprite.offset = Vector2(-floorf(tex.get_width() / 2.0), -tex.get_height())
			sprite.position = pie
			cosas.add_child(sprite)
			etiqueta(id.trim_prefix("mueble-"), pie + Vector2(0, 6))
			x += maxf(w + 24, 110.0)
	# los zombis, en una fila por tipo: el de siempre y sus ropas
	y += alto_fila + 150
	for nombre in EXPO_ZOMBIS:
		if nombre == "gerente" or nombre == "cientifico_jefe":
			y += 100   # son mucho más altos que los demás: sin esto tapan la fila de encima
		var muestra: Node2D = load("res://escenas/personajes/%s.tscn" % nombre).instantiate()
		var base: AnimatedSprite2D = muestra.get_node("Sprite")
		var ropas: Array = muestra.get("ropas") if muestra.get("ropas") else [base.sprite_frames]
		x = MURO + 60
		for ropa in ropas:
			var sprite: AnimatedSprite2D = base.duplicate()
			sprite.sprite_frames = ropa
			sprite.position += Vector2(x, y)
			sprite.play("reposo_s")
			cosas.add_child(sprite)
			expo_sprites.append(sprite)
			x += 110
		etiqueta(nombre.trim_prefix("zombi_"), Vector2(MURO + 60, y + 40))
		muestra.free()
		y += 150


func etiqueta(texto: String, pos: Vector2) -> void:
	var nombre := Label.new()
	nombre.text = texto
	nombre.theme = Tema.crear()   # la fuente pixel art, a 16 para que se vea nítida
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	nombre.add_theme_constant_override("outline_size", 4)
	nombre.size = Vector2(200, 20)
	nombre.position = pos - Vector2(100, 0)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.z_index = 5
	add_child(nombre)


# La llave del apartamento de la jefa: tiene una luz blanca alrededor y sube y baja hasta que Johnny la pisa. En el centro
# comercial, la tarjeta de acceso (la suelta el guardia al caer) y, con "dorada", la tarjeta dorada de la cámara
# acorazada de la joyería (joyeria.gd; al cogerla avisa con dorada_cogida)
func poner_llave(pos: Vector2, tarjeta := false, dorada := false) -> void:
	var zona := Area2D.new()
	zona.name = "Dorada" if dorada else "Llave"
	zona.position = pos
	zona.collision_layer = 0
	zona.collision_mask = 2
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 22.0
	forma.shape = circulo
	zona.add_child(forma)
	if not tarjeta:
		# la llave, con una luz blanca alrededor para distinguirla, como la de las armas de rareza (partida.gd,
		# soltar_arma), pero blanca. Alumbra todas las capas (luz.gd): si no, en un apartamento, donde cada habitación
		# tiene la suya, no alumbraría el suelo
		var resplandor := PointLight2D.new()
		resplandor.name = "Resplandor"
		resplandor.texture = load("res://escenas/luces/luz_suave.tres")
		resplandor.texture_scale = 0.3
		resplandor.color = Color.WHITE
		resplandor.range_item_cull_mask = Luz.TODAS
		resplandor.position = Vector2(0, -16)
		zona.add_child(resplandor)
	var dibujo := Sprite2D.new()
	dibujo.texture = dibujo_tarjeta(dorada) if tarjeta else LLAVE
	# la llave (32×32), al tamaño de un bidón de ácido en el suelo; la tarjeta (12×8), al doble
	dibujo.scale = Vector2(2, 2) if tarjeta else Vector2.ONE
	dibujo.offset = Vector2(0, -8) if tarjeta else Vector2(0, -16)
	zona.add_child(dibujo)
	cosas.add_child(zona)
	var vaiven := dibujo.create_tween().set_loops()
	vaiven.tween_property(dibujo, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(dibujo, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	zona.body_entered.connect(func(cuerpo):
		if cuerpo.is_in_group("jugador"):
			if dorada:
				dorada_cogida.emit()
			else:
				llave_cogida.emit()
			zona.queue_free())


# La tarjeta de acceso, dibujada con código hasta que tenga su sprite (parte 2 del centro comercial): una
# tarjeta azul de 12 × 8 píxeles con su banda magnética, su chip dorado y el borde oscuro. La dorada (la de la
# cámara acorazada de la joyería), igual pero de oro, con el chip azul
static func dibujo_tarjeta(dorada := false) -> Texture2D:
	var fondo := Color("#e0b030") if dorada else Color("#3d7be0")
	var borde := Color("#6e4e10") if dorada else Color("#1b2f5c")
	var brillo := Color("#fff0a0") if dorada else Color("#8fb8ff")
	var chip := Color("#3d7be0") if dorada else Color("#ffd23f")
	var img := Image.create(12, 8, false, Image.FORMAT_RGBA8)
	img.fill(fondo)
	for x in 12:
		img.set_pixel(x, 0, borde)
		img.set_pixel(x, 7, borde)
		img.set_pixel(x, 2, Color("#14161f"))   # la banda
		img.set_pixel(x, 1, brillo)             # el brillo de arriba
	for y in 8:
		img.set_pixel(0, y, borde)
		img.set_pixel(11, y, borde)
	for p in [Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5)]:
		img.set_pixelv(p, chip)   # el chip
	for x in range(6, 10):
		img.set_pixel(x, 5, Color("#fff8e0") if dorada else Color("#dfe8ff"))   # el nombre
	return ImageTexture.create_from_image(img)


# "Hornear" la navegación: Godot mira los muros y los muebles (grupo "obstaculos") y recorta del suelo todo
# lo que choca, dejando el sitio justo para el radio de un zombi (como en la sala de la fase 1)
func hornear(navegacion: NavigationRegion2D) -> void:
	var poligono := NavigationPolygon.new()
	poligono.add_outline(PackedVector2Array([Vector2.ZERO, Vector2(sitio.ancho, 0), Vector2(sitio.ancho, sitio.alto),
		Vector2(0, sitio.alto)]))
	poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poligono.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	poligono.source_geometry_group_name = &"obstaculos"
	poligono.agent_radius = 18.0
	navegacion.navigation_polygon = poligono
	navegacion.bake_navigation_polygon(false)


# Otra vez, cuando algo deja de chocar (la puerta del baño del superviviente, al abrirse)
func rehornear() -> void:
	hornear(get_node("Navegacion"))


# Un punto de suelo con sitio alrededor y a más de "distancia" de "lejos_de" (para las teclas de prueba)
func punto_libre(lejos_de: Vector2, distancia: float) -> Vector2:
	for i in 300:
		var pos := Vector2(randf_range(MURO + 30, sitio.ancho - MURO - 30), randf_range(MURO + 30, sitio.alto - MURO - 30))
		if pos.distance_to(lejos_de) < distancia:
			continue
		var bien := true
		for d in [Vector2.ZERO, Vector2(-26, -26), Vector2(26, -26), Vector2(-26, 26), Vector2(26, 26)]:
			if zona_en(pos + d) < 0:
				bien = false
		if bien:
			return pos
	return Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)


# El medio del sitio donde se puede estar: en un apartamento o una tienda, el centro de su sala principal (la del
# jefe, la de venta) y, si cae en un mueble o fuera del suelo, el punto andable más cercano. Ahí sale el jefe
func centro_libre() -> Vector2:
	var p := Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
	if sitio.has("apt") and not sitio.apt.salas.is_empty() and sitio.apt.salas[0].has("c0"):
		var s: Dictionary = sitio.apt.salas[0]
		p = Vector2(s.c0 + s.ancho / 2.0, s.f0 + s.fondo / 2.0) * CASILLA
	return NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, p)
