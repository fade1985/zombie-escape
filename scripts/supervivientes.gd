# El superviviente de la partida (src/superviviente.js del JS). En cada partida sale uno de los de su edificio que
# aún no viven en las viviendas, en una planta al azar (nunca la última): en los Apartamentos, uno de
# los tres de siempre, escondido en el baño de un apartamento; en el centro comercial, uno de sus tres, en la
# trastienda de su tienda (el ferretero en el almacén de la ferretería...). Siempre con la puerta
# cerrada y sin zombis dentro (lo guarda planta.gd, que pone su tienda en su planta: Planta.tienda_fija). Grita "¡Socorro!" y da golpes de
# vez en cuando para que se sepa dónde está (más flojo desde el pasillo); hay una flecha en el borde de la
# pantalla y un "!" en el minimapa. Al limpiar el piso se abre la puerta del baño y, al arrimarse, se une al equipo.
#
# La horda: al ir a salir del piso con él, la puerta de entrada se cierra de golpe. Él se pone a forzar la
# cerradura (3 minutos de trabajo) mientras entran zombis por las habitaciones, cada vez más y peores. Si Johnny
# se aleja de él, van a por él; si lo tumban, la cerradura no avanza hasta que Johnny lo levanta (quedarse a su
# lado). Va diciendo cómo lo lleva y, a mitad, suelta un molotov y una granada. Arriba, la barra y la cuenta atrás.
#
# Al ganar con él en el equipo se viene a vivir a las viviendas (Guardado: rescatados) y ya no vuelve a salir. Las
# viviendas (mapa/viviendas.gd) son un pasillo detrás de la puerta de la derecha de la sala de mantenimiento, con una
# habitación para cada uno: los rescatados esperan cada uno en la suya ("casa", Viviendas.casa), con lo suyo (las
# cámaras del técnico...: "mejora", que llega con el rescate propio de cada uno), y las de los que faltan siguen
# cerradas. Al arrimarse a uno, te acompaña (Guardado: acompanante) y empieza las partidas siguientes en el equipo.
# Solo uno a la vez.
#
# El guiño de la cafetera: la cafetera de Johnny (mapa/cafetera.gd) está en la habitación de la farmacéutica. La
# primera vez que Johnny entra allí con ella rescatada, ella le ha encontrado el doble fondo con cápsulas de VD-7 y
# se lo dice (Historia.CAFETERA).
#
# Los del centro comercial se esconden igual, pero cada uno tiene su propio rescate en vez de la horda de siempre
# (docs/CENTRO_COMERCIAL.md, «Supervivientes»): la farmacéutica ("rescate": "escolta"), sin horda, hay que llevarla
# herida hasta las escaleras (escolta.gd); el técnico ("rescate": "averia"), bajar la palanca del cuadro y aguantar
# a oscuras mientras arregla el cable (averia.gd); y el ferretero ("rescate": "barricada"), defender la puerta de
# su almacén mientras quita las tablas (barricada.gd).
#
# Lo monta partida.gd: recoger() antes de cambiar de sitio y al_montar() después.
class_name Supervivientes
extends Node

const PUERTA_BANO := preload("res://scripts/mapa/puerta_bano.gd")

# Los que se pueden rescatar (SURVIVORS de src/config.js y los tres del centro comercial). "edificio": dónde sale (y
# en qué fila de las viviendas vive: los de los Apartamentos arriba, los del centro comercial abajo); "look": los
# colores de su dibujo (persona.gd); "arma": la que lleva en la mano. Los del centro comercial llevan además "tienda"
# y "sala" (dónde se esconde), "gritos" (los suyos) y "mejora" (lo que hace ya rescatado; el ferretero no tiene: el
# dueño quitó su puesto, porque todo sale ya de los zombis). "rescate": si no es la horda de siempre, cuál
# ("escolta": escolta.gd; "averia": averia.gd; "barricada": barricada.gd); "al_abrir": lo que dice al abrirse su puerta
const DATOS := {
	"policia": {"id": "policia", "nombre": "Policía", "edificio": "apartamentos", "color": Color("#6fa8ff"), "arma": "pistola",
		"look": {"skin": Color("#f1c27d"), "hair": Color("#2b2b2b"), "shirt": Color("#3d63c9"), "pants": Color("#22336b"),
			"shoes": Color("#1d1b2c"), "hat": {"kind": "cap", "color": Color("#22336b")}},
		"desc": "Dispara con su pistola cada 1,2 s",
		"habilidad": {"tipo": "disparar", "cada": 1.2, "dano": 5, "rafaga": 1}},
	"medico": {"id": "medico", "nombre": "Médica", "edificio": "apartamentos", "color": Color("#80ed99"), "arma": "",
		"look": {"skin": Color("#ffd2a8"), "hair": Color("#c0392b"), "shirt": Color("#ffffff"), "pants": Color("#7fd1c7"),
			"shoes": Color("#3b3550"), "cross": true},
		"desc": "Te cura 3 cada 8 s y 10 al limpiar cada piso",
		"habilidad": {"tipo": "curar", "cada": 8.0, "cura": 3, "al_limpiar": 10}},
	"militar": {"id": "militar", "nombre": "Militar", "edificio": "apartamentos", "color": Color("#c9e265"), "arma": "rifle",
		"look": {"skin": Color("#c68642"), "hair": Color("#3b2a1a"), "shirt": Color("#6b8e23"), "pants": Color("#4b5320"),
			"shoes": Color("#2e2a1f"), "hat": {"kind": "helmet", "color": Color("#556b2f")}},
		"desc": "Lanza ráfagas de 3 balas cada 2,5 s",
		"habilidad": {"tipo": "disparar", "cada": 2.5, "dano": 6, "rafaga": 3, "hueco": 0.1}},
	# los del centro comercial (parte 5 del plan; tres por edificio: el dueño quitó a la camarera)
	"ferretero": {"id": "ferretero", "nombre": "Ferretero", "edificio": "centro", "color": Color("#ff9a3c"), "arma": "martillo",
		"tienda": "ferreteria", "sala": "almacen",
		"look": {"skin": Color("#d39b6a"), "hair": Color("#6e6e6e"), "shirt": Color("#4a6fa5"), "pants": Color("#3e4a5c"),
			"shoes": Color("#4a3426"), "chaleco": Color("#ff8a1f"), "bigote": true,
			"hat": {"kind": "cap", "color": Color("#3c5a3c"), "chapa": false}},
		"gritos": ["¡Socorro!", "¡Estoy en el almacén!", "¡Aquí dentro!", "¡He atrancado la puerta!", "¡Que alguien me oiga!"],
		"rescate": "barricada", "al_abrir": "¡Fuera tablas! Gracias, chaval. Vámonos de aquí",
		"desc": "Va a por los zombis que ve y les da martillazos (8 de daño)",
		"habilidad": {"tipo": "golpear", "cada": 0.9, "dano": 8, "alcance": 80.0}},   # (alcance: lo cerca que tiene que estar para pegar)
	"farmaceutica": {"id": "farmaceutica", "nombre": "Farmacéutica", "edificio": "centro", "color": Color("#3ddc84"), "arma": "",
		"tienda": "farmacia", "sala": "rebotica",
		"look": {"skin": Color("#f1c9a5"), "hair": Color("#2b1d14"), "shirt": Color("#f4f6f8"), "pants": Color("#55606e"),
			"shoes": Color("#3b3550"), "bata": Color("#8fd3e8"), "cross": true, "cross_color": Color("#2fbf5b"),
			"peinado": "moño"},
		"gritos": ["¡Socorro!", "¡Estoy en la rebotica!", "¡Estoy herida!", "¡Ayuda, por favor!", "¡Aquí detrás!"],
		"rescate": "escolta", "al_abrir": "¡Me han mordido la pierna! No puedo correr",
		"desc": "Los charcos de veneno y ácido te hacen la mitad",
		"habilidad": {"tipo": "charcos", "cada": 1.0, "parte": 0.5},
		"mejora": "Cada partida empiezas con un botiquín en la mochila"},
	"tecnico": {"id": "tecnico", "nombre": "Técnico", "edificio": "centro", "color": Color("#4fe3ff"), "arma": "",
		"tienda": "electronica", "sala": "almacen",
		"look": {"skin": Color("#8d5524"), "hair": Color("#1a1a1a"), "shirt": Color("#2a3f6b"), "pants": Color("#3a3f4b"),
			"shoes": Color("#22222a"), "cascos": Color("#e04848"), "tarjeta": true, "aparato": true},
		"gritos": ["¡Socorro!", "¡Estoy en el almacén!", "¡No toquéis el agua!", "¡Aquí dentro!", "¡Que alguien me saque!"],
		"rescate": "averia", "al_abrir": "¡Gracias! Antes de irnos tengo que arreglar ese cable pelado",
		"desc": "Cada 4 s, una descarga deja quieto 1 s al zombi más cercano",
		"habilidad": {"tipo": "aturdir", "cada": 4.0, "segundos": 1.0, "alcance": 260.0},
		"mejora": "Arregla las cámaras de seguridad: el minimapa enseña los zombis"},
}
const MAX_EQUIPO := 4

# Lo que grita desde dentro del baño, y cada cuánto (segundos, al azar entre los dos)
const GRITOS := ["¡Socorro!", "¡Aquí dentro!", "¡Ayuda, por favor!", "¡Que alguien me saque!", "¡Estoy en el baño!"]
const CADA := [2.2, 3.4]

# La horda (números provisionales, los del JS)
const HORDA := {
	"dura": 120.0,     # segundos de trabajo para abrir la puerta (no cuentan mientras está caído)
	"tope": 40,        # zombis a la vez, como mucho
	"levantar": 2.0,   # segundos al lado del superviviente caído para levantarlo
	"lejos": 300.0,    # si Johnny está más lejos que esto de él, los zombis van a por él
	"cada": [6.0, 3.0],  # segundos entre grupo y grupo, al principio y al final
	"grupo": [2, 6],   # zombis por grupo, al principio y al final
	"empieza": 190.0,  # a qué distancia de la puerta de entrada se cierra de golpe
}
# Qué zombis entran según el minuto
const TIPOS := [
	["lento", "normal", "normal"],
	["normal", "normal", "rapido", "rapido", "explosivo", "lento"],
	["normal", "rapido", "rapido", "explosivo", "venenoso", "lento"],
]
# Lo que va diciendo según lo que lleva de cerradura (de 0 a 1)
const FRASES := [
	[0.02, "¡Está atascada! ¡Cúbreme!"],
	[0.15, "Esta cerradura está oxidada… dame tiempo"],
	[0.32, "Vale… creo que ya noto el muelle"],
	[0.5, "¡Toma, he encontrado esto!"],
	[0.62, "¡Se me ha caído la horquilla!… vale, ya la tengo"],
	[0.8, "Ya casi lo tengo…"],
	[0.92, "¡Un poco más!"],
]
# Por dónde entra cada grupo (en las tiendas, también por sus habitaciones)
const POR := {"salon": "el salón", "cocina": "la cocina", "dormitorio": "el dormitorio", "bano": "el baño",
	"tienda": "la tienda", "almacen": "el almacén", "camara": "la cámara", "taller": "el taller",
	"taquillas": "las taquillas", "probadores": "los probadores", "rebotica": "la rebotica"}

var partida: Node
var johnny: Node2D
var rescate := {}          # {def, planta, rescatado, amigo, sitio, horda_hecha} o vacío si no queda a quién salvar
var equipo: Array = []     # los Aliado que siguen a Johnny
var npc: Aliado = null     # el superviviente en su baño (mientras se está en su apartamento)
var puerta: Node2D = null  # y la puerta del baño
var vecinos: Array = []    # los rescatados de otras partidas, cada uno en su habitación de las viviendas
var barricada := Barricada.new()   # el rescate del ferretero
var socorro_t := 1.0
var sala_socorro := -1
var grito_t := -9.0
var horda := {}
var tiempo := 0.0
var capa: Control          # la flecha del borde y la barra de la horda (en la pantalla)
var escolta := Escolta.new()   # el rescate de la farmacéutica
var averia := Averia.new()     # el del técnico
var sala_cafe := -1            # en las viviendas, la habitación de la farmacéutica si aún falta el guiño de la cafetera
var contando_cafe := false     # ella lo está contando


func preparar(p: Node) -> void:
	partida = p
	johnny = p.johnny
	barricada.sup = self
	add_child(barricada)
	capa = Control.new()
	capa.name = "Superviviente"
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.draw.connect(dibujar_capa)
	var pantalla: Node = p.get_node("Pantalla")
	pantalla.add_child(capa)
	pantalla.move_child(capa, p.negro.get_index())   # por debajo del fundido a negro
	escolta.sup = self
	add_child(escolta)
	averia.sup = self
	add_child(averia)


# Al empezar la partida: quién sale y en qué planta (elegirSuperviviente), de los de este edificio. Los que ya
# viven en las viviendas no vuelven a salir; con todos rescatados no hay a quién salvar. Si es uno del
# centro comercial, su tienda tiene que salir en su planta (Planta.tienda_fija). Y el acompañante elegido
# empieza ya en el equipo
func elegir() -> void:
	var s := Guardado.cargar()
	var quedan := de_edificio(partida.edificio).filter(func(id): return not id in s.rescatados)
	Planta.tienda_fija = {}
	if not quedan.is_empty():
		poner_rescate(DATOS[quedan[randi() % quedan.size()]], randi_range(1, Planta.PLANTAS - 1))
	if s.acompanante in s.rescatados and DATOS.has(s.acompanante):
		var a := crear(DATOS[s.acompanante], "equipo")
		a.es_vecino = true
		a.casa = Viviendas.casa(s.acompanante)
		equipo.append(a)


# Los que salen en el edificio "ed" (en el orden de DATOS)
func de_edificio(ed: String) -> Array:
	return DATOS.keys().filter(func(id): return DATOS[id].edificio == ed)


# A quién hay que salvar en esta partida y en qué planta (y, si tiene tienda, que salga en esa planta)
func poner_rescate(def: Dictionary, num: int) -> void:
	rescate = {"def": def, "planta": num, "rescatado": false, "amigo": null, "sitio": -1, "horda_hecha": false}
	Planta.tienda_fija = {"planta": num, "tienda": def.tienda, "sala": def.sala} if def.has("tienda") else {}


# Al generar cada planta: si le toca a esta, se cierra la puerta de su baño (el baño ya lo ha guardado planta.gd)
func nueva_planta() -> void:
	var planta: Dictionary = partida.planta
	var sup: Dictionary = planta.superviviente
	if sup.is_empty():
		return
	sup.activo = not rescate.is_empty() and rescate.planta == planta.num
	if sup.activo:
		sup.puerta.cerrada = true
		socorro_t = 1.0


# ¿Está el superviviente esperando en esta planta? (para la flecha, el minimapa y los gritos)
func hay_sos() -> bool:
	return not rescate.is_empty() and not rescate.rescatado and partida.planta.get("superviviente", {}).get("activo", false)


func encerrado() -> bool:
	return hay_sos() and partida.planta.superviviente.puerta.get("cerrada", false)


func en_horda() -> bool:
	return not horda.is_empty()


# El superviviente rescatado en esta partida, si sigue en el equipo (al ganar, se viene a vivir a las viviendas)
func rescatado_nuevo() -> Dictionary:
	var a = rescate.get("amigo")
	return a.def if a != null and a in equipo else {}


func crear(datos: Dictionary, modo: String) -> Aliado:
	var a := Aliado.new()
	a.johnny = johnny
	a.partida = self.partida
	a.preparar(datos, modo)
	a.herido.connect(al_herir.bind(a))
	return a


# Antes de cambiar de sitio: los del equipo se sacan del mapa viejo (como Johnny) para no perderse con él
func recoger() -> void:
	for a in equipo:
		if a.get_parent():
			a.get_parent().remove_child(a)
	npc = null
	puerta = null
	vecinos = []
	sala_cafe = -1


# Recién montado el sitio "idx": el equipo, al lado de Johnny; el superviviente en su baño; y en las viviendas, los
# vecinos y, si falta, el guiño de la cafetera
func al_montar(idx: int, sitio: Dictionary) -> void:
	var mapa: Node2D = partida.mapa
	Aliado.borrar_huellas()   # el rastro de Johnny era del mapa viejo: la fila se forma de nuevo desde la puerta
	for i in equipo.size():
		var a: Aliado = equipo[i]
		a.idx = i
		mapa.cosas.add_child(a)
		a.position = johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	if hay_sos() and idx == partida.planta.superviviente.sitio:
		var sup: Dictionary = partida.planta.superviviente
		if sup.puerta.cerrada:
			puerta = PUERTA_BANO.new()
			puerta.montar(sup.puerta)
			if rescate.def.get("rescate", "") == "barricada":
				puerta.tablas = Barricada.TABLAS   # el ferretero se ha atrincherado (barricada.gd)
			mapa.cosas.add_child(puerta)
			mapa.rehornear()   # que los zombis no cuenten con pasar por ahí
		npc = crear(rescate.def, "encerrado")
		npc.asustado = not sitio.limpio
		npc.position = sup.pos
		mapa.cosas.add_child(npc)
		sala_socorro = -1
	if sitio.tipo == "viviendas":
		colocar_vecinos()
		sala_cafe = sala_cafetera(sitio)


func _process(delta: float) -> void:
	tiempo += delta
	if capa:
		capa.queue_redraw()


func _physics_process(delta: float) -> void:
	if partida == null or partida.mapa == null or partida.cambiando:
		return
	actualizar_socorro(delta)
	if npc and npc.modo == "encerrado":
		npc.visible = not partida.mapa.oculto(npc.position)
		if not encerrado() and johnny.vivo and johnny.position.distance_to(npc.position) < 60.0:
			unir(npc)
	for v in vecinos:
		hablar_vecino(v)
	if sala_cafe >= 0 and not contando_cafe and partida.mapa.zona_en(johnny.position) == sala_cafe:
		guino_cafetera()   # Johnny acaba de entrar en la habitación de la farmacéutica
	actualizar_horda(delta)


# ═════════════ Encerrado en el baño ═════════════

# Mientras la puerta sigue cerrada, grita y da golpes. Se le oye desde su apartamento (sale de la puerta del baño)
# y desde el pasillo (sale de la puerta del piso)
func actualizar_socorro(delta: float) -> void:
	if not encerrado() or barricada.activa():
		return   # (el ferretero, quitando la barricada, dice otras cosas: barricada.gd)
	var sup: Dictionary = partida.planta.superviviente
	# al entrar en un sitio desde donde se le oye, el primer grito llega enseguida
	if partida.aqui != sala_socorro:
		sala_socorro = partida.aqui
		socorro_t = minf(socorro_t, 0.8)
	socorro_t -= delta
	if socorro_t > 0.0:
		return
	socorro_t = randf_range(CADA[0], CADA[1])
	var donde := Vector2.INF
	var tamano := 18
	if partida.aqui == sup.sitio and puerta:
		donde = puerta.position + Vector2(0, -110)
		puerta.golpes = 0.45
		Sonido.tocar("socorro")
	elif partida.aqui == 0:
		var p := puerta_del_pasillo()
		if p:
			donde = p.position + Vector2(0, 50 if p.salida.dir == "arriba" else -90)
			tamano = 15
			Sonido.tocar("socorro_lejos")
	if donde == Vector2.INF:
		return
	grito_t = tiempo
	var gritos: Array = rescate.def.get("gritos", GRITOS)
	texto_flotante(donde + Vector2(randf_range(-14, 14), 0), gritos[randi() % gritos.size()], Color("#ff8a8a"), tamano)


# En el pasillo, la puerta del apartamento del superviviente
func puerta_del_pasillo() -> Node2D:
	for p in partida.mapa.puertas:
		if p.salida.a == partida.planta.superviviente.sitio:
			return p
	return null


# Como el número que sube de partida.gd, pero dura más y sube más despacio (que dé tiempo a leerlo)
func texto_flotante(donde: Vector2, texto: String, color: Color, tamano := 18, vida := 1.8) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.theme = Tema.crear()
	etiqueta.add_theme_font_size_override("font_size", 16 if tamano < 24 else 32)   # nítida solo a 16 o 32
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 4 if tamano < 24 else 8)
	etiqueta.add_theme_color_override("font_outline_color", Tema.LINEA)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.size = Vector2(400, 30)
	etiqueta.position = donde - Vector2(200, 15)
	etiqueta.z_index = 50
	partida.mapa.cosas.add_child(etiqueta)
	var tween := etiqueta.create_tween().set_parallel()
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 28.0 * vida, vida)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.5).set_delay(vida - 0.5)
	tween.chain().tween_callback(etiqueta.queue_free)


# Se ha limpiado el piso "idx": si es el suyo, se abre la puerta del baño; y la médica cura un poco. La del
# ferretero no: se queda cerrada hasta que quita la barricada (empieza sola: barricada.gd)
func piso_limpio(idx: int) -> void:
	for a in equipo:
		a.al_limpiar()
	if not encerrado() or idx != partida.planta.superviviente.sitio:
		return
	if rescate.def.get("rescate", "") != "barricada":
		abrir_escondite(idx)


# Se abre la puerta de su escondite y, al poco, dice lo suyo
func abrir_escondite(idx: int) -> void:
	var sup: Dictionary = partida.planta.superviviente
	sup.puerta.cerrada = false
	partida.mapa.vistas[sup.sala] = true
	if npc:
		npc.asustado = false
	if puerta:
		puerta.abrir()
		get_tree().create_timer(0.5, false).timeout.connect(Sonido.tocar.bind("puerta"))
		await get_tree().create_timer(0.1, false).timeout
		if partida.mapa and partida.aqui == idx:
			partida.mapa.rehornear()
	await get_tree().create_timer(0.4, false).timeout
	if npc and partida.aqui == idx:
		npc.decir(rescate.def.get("al_abrir", "¡Gracias! ¡Sácame de aquí!"))


# Johnny se le arrima con la puerta abierta: se une al equipo
func unir(a: Aliado) -> void:
	if equipo.size() >= MAX_EQUIPO:
		return
	a.modo = "equipo"
	a.idx = equipo.size()
	equipo.append(a)
	rescate.rescatado = true
	rescate.amigo = a
	rescate.sitio = partida.aqui
	npc = null
	partida.decir("¡%s se une al equipo! %s" % [a.def.nombre, a.def.desc], 3.5)
	Sonido.tocar("limpio")
	Particulas.anillo(a, a.global_position, 50.0, a.def.color, 0.5)
	if a.def.get("rescate", "") == "escolta":
		escolta.empezar(a)
	elif a.def.get("rescate", "") == "averia":
		averia.empezar(a)   # si su tienda no tuviera el agua con corriente, la horda de siempre


# ═════════════ La horda ═════════════

func actualizar_horda(delta: float) -> void:
	var r := rescate
	if r.is_empty() or not r.rescatado or not r.amigo in equipo or partida.aqui != r.sitio:
		return
	if r.def.get("rescate", "") == "escolta" or averia.activa():
		return   # la farmacéutica no tiene horda (su escolta va en escolta.gd), ni el técnico (averia.gd)
	var a: Aliado = r.amigo
	if horda.is_empty():
		if r.horda_hecha or not johnny.vivo:
			return
		if johnny.position.distance_to(partida.mapa.puertas[0].position) < HORDA.empieza:
			empezar_horda()
		return
	var h := horda
	h.t += delta
	if a.caido:
		# caído: Johnny lo levanta quedándose a su lado
		if johnny.vivo and johnny.position.distance_to(a.position) < 60.0:
			h.levantando += delta
		else:
			h.levantando = maxf(0.0, h.levantando - delta * 2.0)
		a.levantar = h.levantando / HORDA.levantar
		if h.levantando >= HORDA.levantar:
			h.levantando = 0.0
			a.levantarse()
			a.decir("¡Gracias! Sigo con la cerradura")
			Particulas.anillo(a, a.global_position, 50.0, Tema.VERDE, 0.4)
	elif a.en_su_sitio():
		# la cerradura avanza mientras él esté de pie delante de la puerta
		h.hecho = minf(HORDA.dura, h.hecho + delta)
	var k: float = h.hecho / HORDA.dura
	while h.frase_i < FRASES.size() and k >= FRASES[h.frase_i][0]:
		var frase: Array = FRASES[h.frase_i]
		h.frase_i += 1
		a.decir(frase[1])
		if frase[0] == 0.5:
			soltar_provisiones(a)
	# los últimos 10 segundos: aviso
	if not a.caido and HORDA.dura - h.hecho <= 10.0 and not h.get("cuenta", false):
		h.cuenta = true
		Sonido.tocar("jefe")

	# los grupos de zombis
	h.grupo_t -= delta
	if h.grupo_t <= 0.0 and HORDA.dura - h.hecho > 3.0:
		h.grupo_t = lerpf(HORDA.cada[0], HORDA.cada[1], k)
		grupo(roundi(lerpf(HORDA.grupo[0], HORDA.grupo[1], k)), TIPOS[mini(2, int(h.hecho / 60.0))])
	if h.hecho >= HORDA.dura:
		acabar_horda()


# La puerta de entrada se cierra en la cara: empieza la horda
func empezar_horda() -> void:
	Sonido.musica("jefe")   # la música más tensa
	var a: Aliado = rescate.amigo
	var p: Node2D = partida.mapa.puertas[0]
	# donde se pone a trabajar: delante de la puerta, por dentro, mirándola
	var dentro: Vector2 = {"arriba": Vector2(0, 1), "abajo": Vector2(0, -1), "izquierda": Vector2(1, 0),
		"derecha": Vector2(-1, 0)}[p.salida.dir]
	a.sitio_forzar = p.position + dentro * 50.0
	a.mira_forzar = -dentro
	a.forzando = true
	a.vida = Aliado.VIDA
	a.caido = false
	a.add_to_group("presa")
	horda = {"t": 0.0, "hecho": 0.0, "grupo_t": 3.0, "frase_i": 0, "levantando": 0.0, "queja_t": -9.0}
	partida.cerrada = true
	partida.actualizar_puertas()
	partida.decir("¡La puerta se ha cerrado! Aguanta mientras %s fuerza la cerradura" % a.def.nombre, 4.0)


# Tres minutos después: la puerta se abre. Los zombis que queden siguen ahí, pero ya se puede salir
func acabar_horda() -> void:
	Sonido.musica("menu")
	var a: Aliado = rescate.amigo
	horda = {}
	rescate.horda_hecha = true
	partida.logros.cumplir("buen_vecino")
	a.forzando = false
	a.levantar = 0.0
	a.remove_from_group("presa")
	partida.cerrada = false
	partida.actualizar_puertas()
	a.decir("¡YA ESTÁ! ¡CORRE!")
	partida.decir("¡Puerta abierta! Salid de aquí", 3.0)
	Sonido.tocar("limpio")
	get_tree().create_timer(0.25, false).timeout.connect(Sonido.tocar.bind("puerta"))


# Le han dado: si se ha caído, lo dice; si Johnny anda lejos, se queja (como mucho cada 6 s)
func al_herir(cae: bool, a: Aliado) -> void:
	if escolta.ella == a:
		escolta.al_herir(cae)
		return
	if averia.el == a:
		averia.al_herir(cae)
		return
	if horda.is_empty():
		return
	if cae:
		horda.levantando = 0.0
		a.decir("¡Ayúdame, no puedo levantarme!")
	elif johnny.position.distance_to(a.position) > HORDA.lejos and horda.t - horda.queja_t > 6.0:
		horda.queja_t = horda.t
		a.decir(["¡Johnny, vuelve!", "¡No me dejes aquí!", "¡Que me comen!"][randi() % 3])


# A mitad: tira un molotov, una granada y dos cajas de munición a sus pies
func soltar_provisiones(a: Aliado) -> void:
	partida.soltar_lanzable("molotov", a.position + Vector2(-30, 30))
	partida.soltar_lanzable("granada", a.position + Vector2(30, 30))
	partida.soltar_municion(a.position + Vector2(-10, 40))
	partida.soltar_municion(a.position + Vector2(10, 40))


# Un grupo de zombis entra por una habitación (casi siempre una donde no está Johnny) y él avisa de por dónde
func grupo(n: int, tipos: Array) -> void:
	n = mini(n, HORDA.tope - get_tree().get_nodes_in_group("zombis").size())
	if n <= 0:
		return
	var sitio: Dictionary = partida.planta.sitios[partida.aqui]
	var apt: Dictionary = sitio.apt
	var aqui: int = partida.mapa.zona_en(johnny.position)
	var otras: Array = apt.salas.filter(func(s): return s.id != aqui)
	var sala: Dictionary = otras.pick_random() if not otras.is_empty() and randf() < 0.8 else apt.salas.pick_random()
	var puestos := 0
	for i in 120:
		if puestos >= n:
			break
		var pos := Vector2((sala.c0 + randf() * sala.ancho) * Planta.CASILLA, (sala.f0 + randf() * sala.fondo) * Planta.CASILLA)
		if not Planta.despejado(apt, pos, 24.0, sala.id) or pos.distance_to(johnny.position) < 180.0:
			continue
		if not Planta.lejos_de_muebles(sitio, pos, 30.0):
			continue
		partida.meter_zombi(tipos.pick_random(), pos)
		puestos += 1
	var a: Aliado = rescate.amigo
	if puestos > 0 and POR.has(sala.uso) and randf() < 0.5 and a.dicho_t > 2.5:
		a.decir("¡Vienen por %s!" % POR[sala.uso])


# ═════════════ Los vecinos, en las viviendas ═════════════

# Los rescatados en otras partidas esperan cada uno en su habitación de las viviendas (mapa/viviendas.gd; su puerta
# ya la ha abierto mapa.gd). El que te acompaña ya va en el equipo (su habitación se queda vacía)
func colocar_vecinos() -> void:
	var s := Guardado.cargar()
	for id: String in s.rescatados:
		if not DATOS.has(id) or equipo.any(func(a): return a.def.id == id):
			continue
		var v := crear(DATOS[id], "vecino")
		v.es_vecino = true
		v.casa = Viviendas.casa(id)
		v.position = v.casa
		v.armado = true
		partida.mapa.cosas.add_child(v)
		vecinos.append(v)


# El vecino más cerca de Johnny (si está a menos de 260), o null
func vecino_cerca() -> Aliado:
	var mejor: Aliado = null
	var cerca := 260.0
	for v in vecinos:
		var d := johnny.position.distance_to(v.position)
		if v.modo == "vecino" and d < cerca:
			cerca = d
			mejor = v
	return mejor


# Arrimarse a un vecino: se viene contigo (y el que te acompañaba vuelve a su habitación). Como el ordenador, hay que
# apartarse un poco antes de que vuelva a contar
func hablar_vecino(v: Aliado) -> void:
	if v.modo != "vecino":
		return
	var d := johnny.position.distance_to(v.position)
	if d > 90.0:
		v.armado = true
	elif v.armado and d < 40.0:
		v.armado = false
		llevar_vecino(v)


func llevar_vecino(v: Aliado) -> void:
	for otro in equipo.duplicate():
		if otro.es_vecino:
			equipo.erase(otro)
			otro.modo = "vecino"
			otro.armado = false
			otro.position = otro.casa
			vecinos.append(otro)
	vecinos.erase(v)
	v.modo = "equipo"
	equipo.append(v)
	for i in equipo.size():
		equipo[i].idx = i
	Guardado.cambiar(func(g): g.acompanante = v.def.id)
	partida.decir("%s te acompaña · %s" % [v.def.nombre, v.def.desc], 3.0)
	Sonido.tocar("limpio")
	Particulas.anillo(v, v.global_position, 50.0, v.def.color, 0.5)


# ═════════════ El botiquín de la farmacéutica ═════════════

# Al empezar la partida, con la farmacéutica rescatada (en los dos edificios): un botiquín en la mochila. Se usa
# desde el inventario («Usar», Objetos.USABLES) y no va al baúl. Devuelve si lo ha puesto (para decirlo al empezar)
func botiquin_al_empezar() -> bool:
	if "farmaceutica" not in Guardado.cargar().rescatados or Reto.sin_curas():   # (en ese reto, nadie te lo prepara)
		return false
	partida.mochila.append("botiquin")
	return true


# ═════════════ El guiño de la cafetera ═════════════

const CAFE_PAUSA := 1.5   # segundos en su habitación antes de que la farmacéutica empiece a contarlo
const CAFE_CADA := 3.6    # y entre frase y frase (el bocadillo dura 3,2)

# En las viviendas, la habitación de la farmacéutica (su número de sala) si ya está rescatada y aún no ha contado lo
# de la cafetera; si no, -1
func sala_cafetera(sitio: Dictionary) -> int:
	var g := Guardado.cargar()
	if g.cafetera or "farmaceutica" not in g.rescatados:
		return -1
	for s in sitio.apt.salas:
		if s.get("vecino", "") == "farmaceutica":
			return s.id
	return -1


# La primera vez que Johnny entra en la habitación de la farmacéutica (ya rescatada), donde está la cafetera de
# Johnny, ella le cuenta que le ha encontrado el doble fondo con las cápsulas de VD-7, frase a frase
# (Historia.CAFETERA): esté en su habitación o te acompañe. Se apunta en el guardado con la última frase: si Johnny
# sale de la habitación antes, lo vuelve a contar entero la próxima vez que entre. Desde entonces el café es solo
# café, y no lo repite nunca más
func guino_cafetera() -> void:
	var ella: Aliado = null
	for a in vecinos + equipo:
		if a.def.id == "farmaceutica":
			ella = a
	if ella == null:
		return
	contando_cafe = true
	var mapa: Node2D = partida.mapa
	var sala := sala_cafe
	for i in Historia.CAFETERA.size():
		await get_tree().create_timer(CAFE_PAUSA if i == 0 else CAFE_CADA, false).timeout
		if partida.mapa != mapa or not is_instance_valid(ella) or not ella.is_inside_tree() \
				or mapa.zona_en(johnny.position) != sala:
			contando_cafe = false
			return   # Johnny ha salido de su habitación
		ella.decir(Historia.CAFETERA[i])
	Guardado.cambiar(func(x): x.cafetera = true)
	sala_cafe = -1
	contando_cafe = false


# ═════════════ En la pantalla ═════════════

# La flecha en el borde hacia donde está encerrado; en la horda, la barra de la cerradura y la cuenta atrás; y en
# la escolta de la farmacéutica, lo suyo (escolta.gd); y en la barricada del ferretero, su barra (barricada.gd)
func dibujar_capa() -> void:
	if partida == null or partida.mapa == null or partida.terminada:
		return
	var letra := Tema.FUENTE
	var tam := capa.size
	barricada.dibujar(capa)
	if encerrado():
		var hacia := Vector2.INF
		if partida.aqui == partida.planta.superviviente.sitio and puerta:
			hacia = puerta.position + Vector2(0, -40)
		elif partida.aqui == 0:
			var p := puerta_del_pasillo()
			if p:
				hacia = p.position
		if hacia != Vector2.INF:
			flecha(hacia, rescate.def.color, tiempo - grito_t < 0.7)
	escolta.dibujar(capa)
	averia.dibujar(capa)
	if horda.is_empty():
		return
	var a: Aliado = rescate.amigo
	var ancho := minf(360.0, tam.x - 260.0)
	var x := (tam.x - ancho) / 2.0
	var y := 18.0
	var falta := ceili(HORDA.dura - horda.hecho)
	capa.draw_rect(Rect2(x - 8, y - 8, ancho + 16, 44), Tema.LINEA)
	capa.draw_rect(Rect2(x - 6, y - 6, ancho + 12, 40), Color(0.11, 0.1, 0.17, 0.9))
	capa.draw_rect(Rect2(x, y + 16, ancho, 10), Color("#3a2f22"))
	var relleno := (Color("#ff2d4b") if int(tiempo * 6.0) % 2 else Color("#7a2030")) if a.caido else Color("#e0b030")
	capa.draw_rect(Rect2(x, y + 16, ancho * horda.hecho / HORDA.dura, 10), relleno)
	capa.draw_rect(Rect2(x, y + 16, ancho, 10), Tema.LINEA, false, 2.0)
	var texto: String = ("¡%s ha caído!" % a.def.nombre) if a.caido \
		else "%s fuerza la cerradura · %d:%02d" % [a.def.nombre, falta / 60, falta % 60]
	capa.draw_string_outline(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
	capa.draw_string(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16,
		Color("#ff8a8a") if a.caido else Color("#f2e6c0"))
	# los últimos diez segundos, en grande y latiendo
	if falta <= 10 and not a.caido:
		var grande := 64 if fmod(horda.hecho, 1.0) < 0.5 else 72
		capa.draw_string_outline(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, 10, Tema.LINEA)
		capa.draw_string(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, Tema.AMARILLO)


# La flecha en el borde de la pantalla hacia "hacia" (si no se ve), con un "!" (más grande si "grande")
func flecha(hacia: Vector2, color: Color, grande: bool) -> void:
	var tam := capa.size
	var en := partida.get_viewport().get_canvas_transform() * hacia
	var borde := Rect2(Vector2.ZERO, tam).grow(-34)
	if borde.has_point(en):
		return
	var punto := en.clamp(borde.position, borde.end)
	var radio := 16.0 if grande else 13.0
	var dir := (en - punto).normalized()
	capa.draw_colored_polygon(PackedVector2Array([punto + dir * (radio + 10), punto + dir.orthogonal() * 8 + dir * radio * 0.6,
		punto - dir.orthogonal() * 8 + dir * radio * 0.6]), color)
	capa.draw_circle(punto, radio + 2, Tema.LINEA)
	capa.draw_circle(punto, radio, color)
	capa.draw_string(Tema.FUENTE, punto + Vector2(-20, 6), "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Tema.LINEA)


# ═════════════ Para probar ═════════════

# Tecla H: el superviviente pasa a esta planta y Johnny va a su apartamento, ya sin zombis (se abre el baño al
# entrar). Sirve para probar el rescate y la horda sin jugar hasta su planta. En el centro comercial, cada vez
# trae al siguiente de los tres (ferretero, farmacéutica, técnico) y rehace la planta con su tienda. Con "quien"
# (para las pruebas), ese
func probar_aqui(fundir := true, quien := "") -> void:
	var sup: Dictionary = partida.planta.get("superviviente", {})
	if partida.cerrada or sup.is_empty():
		partida.decir("Ahora no se puede")
		return
	if rescate.get("rescatado", false):
		partida.decir("Ya lo has rescatado en esta partida")
		return
	var propios := de_edificio(partida.edificio)
	var num: int = partida.planta.num
	if DATOS[propios[0]].has("tienda"):
		var i: int = (propios.find(rescate.def.id) + 1) % propios.size() if not rescate.is_empty() else 0
		if quien != "":
			i = propios.find(quien)
		poner_rescate(DATOS[propios[i]], num)
		partida.nueva_planta(num)   # la misma planta otra vez, ya con su tienda
		sup = partida.planta.superviviente
		if sup.is_empty():
			partida.decir("Ahora no se puede")
			return
		partida.decir("Superviviente de prueba: %s (pulsa H otra vez para el siguiente)" % rescate.def.nombre, 3.0)
	elif rescate.is_empty():
		poner_rescate(DATOS[propios.pick_random()], num)
	rescate.planta = num
	sup.activo = true
	sup.puerta.cerrada = true
	var sitio: Dictionary = partida.planta.sitios[sup.sitio]
	sitio.zombis = []
	sitio.limpio = false
	await partida.montar(sup.sitio, 0, fundir)


# Con --captura: el rescate, la horda (con la cerradura adelantada), levantarlo, y un vecino en su habitación
func probar() -> void:
	partida.menus.visible = false   # por si ha salido el recuadro de una mutación (tapa las fotos)
	await probar_aqui(false)
	for i in 2:
		if rescate.def.get("rescate", "") in ["escolta", "averia", "barricada"]:
			await probar_aqui(false)   # la horda, con otro (la escolta y la avería se prueban en escolta.gd y averia.gd)
	# la horda de siempre (en el centro comercial ya no la tiene ninguno: cada uno tiene su rescate)
	if rescate.def.get("rescate", "") == "":
		await probar_horda()
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()   # que no estorben al resto de la prueba
	# un vecino rescatado en otra partida: en su habitación de las viviendas, arrimarse a él
	var otro: String = DATOS.keys().filter(func(id): return id != rescate.def.id)[0]
	Guardado.cambiar(func(g): g.rescatados = [otro])
	partida.nueva_planta(1)   # las viviendas están en la planta baja
	await partida.montar(partida.planta.viviendas, 0, false)
	await get_tree().create_timer(0.2, false).timeout
	print("Vecinos en las viviendas: %d" % vecinos.size())
	if not vecinos.is_empty():
		await arrimarse(vecinos[0])
	print("Acompañante: '%s' | equipo %s" % [Guardado.cargar().acompanante, equipo.map(func(x): return x.def.nombre)])
	Captura.foto("captura-vecinos.png")
	await probar_viviendas()
	await probar_los_seis()
	await probar_acompanantes()
	await probar_cafetera()
	await probar_botiquin()
	await barricada.probar()
	await escolta.probar()
	await averia.probar()
	partida.menus.visible = true


# La horda de siempre (con --captura): el rescate, la horda con la cerradura adelantada y levantarlo
func probar_horda() -> void:
	await get_tree().create_timer(0.3, false).timeout
	var sup: Dictionary = partida.planta.superviviente
	print("Superviviente: %s en %s · %s | baño cerrado %s | puerta %s" % [rescate.def.nombre, partida.planta.nombre,
		partida.planta.sitios[sup.sitio].nombre, sup.puerta.get("cerrada"), puerta != null])
	johnny.position = npc.position + Vector2(0, 30) if npc else johnny.position
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	print("Rescatado: %s | equipo %d" % [rescate.rescatado, equipo.size()])
	Captura.foto("captura-superviviente.png")
	johnny.position = partida.mapa.puertas[0].llegada()
	johnny.get_node("Camara").reset_smoothing()
	rescate.amigo.position = johnny.position + Vector2(40, 0)   # le ha seguido hasta la puerta
	await get_tree().create_timer(0.3, false).timeout
	print("Horda: %s | puerta %s" % [en_horda(), "cerrada" if partida.cerrada else "abierta"])
	if not en_horda():
		return
	horda.hecho = HORDA.dura * 0.49
	horda.grupo_t = 0.0
	await get_tree().create_timer(2.0, false).timeout
	var a: Aliado = rescate.amigo
	print("Horda a %d s: zombis %d | dice '%s' | molotovs/granadas en el suelo %d" % [int(horda.hecho),
		get_tree().get_nodes_in_group("zombis").size(), a.dicho, partida.mapa.cosas.get_children().filter(
		func(n): return n.get("icono") in iconos_lanzables()).size()])
	Captura.foto("captura-horda.png")
	a.inv_t = 0.0
	a.recibir_dano(500)
	print("A %.0f de su sitio en la puerta" % a.global_position.distance_to(a.sitio_forzar))
	print("Caído: %s | cerradura parada en %.1f" % [a.caido, horda.hecho])
	johnny.position = a.position + Vector2(30, 0)
	await get_tree().create_timer(2.3, false).timeout
	print("Levantado: %s | vida %d" % [not a.caido, a.vida])
	horda.hecho = HORDA.dura - 0.3
	await get_tree().create_timer(0.6, false).timeout
	print("Fin de la horda: %s | puerta %s" % [not en_horda(), "cerrada" if partida.cerrada else "abierta"])


# Las viviendas (mapa/viviendas.gd), con cuatro rescatados (el policía, el militar, el ferretero y el técnico) y sin
# acompañante. En la sala de mantenimiento ya no espera nadie y hay una puerta a la derecha (captura-viviendas-puerta.png);
# por ella, al pasillo de las viviendas: seis puertas con su placa, cerradas las de la médica y la farmacéutica (que
# no dejan pasar, y sus habitaciones siguen a oscuras) y abiertas las demás, cada uno en la suya (el ferretero, en
# medio de la suya: captura-viviendas-ferretero.png) y las cámaras del técnico. Fotos del pasillo (captura-viviendas.png,
# la mitad de la izquierda, y captura-viviendas-derecha.png) y de una habitación por dentro
# (captura-viviendas-habitacion.png). Luego, arrimarse
# al policía (te acompaña), al militar (el policía vuelve a la suya) y volver a la sala con él por la puerta de la
# izquierda. Y en la 1ª planta, con el ascensor arreglado, también se llega desde la sala. Se deja el guardado y el
# equipo como estaban
func probar_viviendas() -> void:
	var g := Guardado.cargar()
	var antes := [g.rescatados.duplicate(), g.acompanante]
	var equipo_antes := equipo
	for a in equipo:
		if a.get_parent():
			a.get_parent().remove_child(a)
	equipo = []
	Guardado.cambiar(func(x):
		x.rescatados = ["policia", "militar", "ferretero", "tecnico"]
		x.acompanante = "")
	partida.nueva_planta(1)
	await partida.montar(partida.planta.mantenimiento, 0, false)
	var sala: Dictionary = partida.planta.sitios[partida.aqui]
	print("Mantenimiento: salidas %s · vecinos en la sala %d (esperado: [abajo, derecha], 0)" % [
		sala.salidas.map(func(s): return s.dir), vecinos.size()])
	johnny.position = partida.mapa.puertas[1].llegada() + Vector2(-60, 40)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-viviendas-puerta.png")
	# se empuja la puerta de la derecha (como al andar hacia ella)
	johnny.position = partida.mapa.puertas[1].position + Vector2(-16, 0)
	await get_tree().create_timer(1.0, false).timeout   # (el fundido a negro, de ida y de vuelta)
	var mapa: Node2D = partida.mapa
	var casas: Dictionary = partida.planta.sitios[partida.aqui]
	print("Por la puerta de la derecha: en «%s» · arriba pone «%s» · Johnny a %d de la puerta (esperado: viviendas, Planta baja · Viviendas, 0)" % [
		casas.tipo, partida.lugar.text, roundi(johnny.position.distance_to(mapa.puertas[0].llegada()))])
	var cerradas := []
	var abiertas := []
	for d in casas.apt.puertas:
		(cerradas if d.cerrada else abiertas).append(DATOS[d.vecino].nombre)
	var hojas: Array = mapa.cosas.get_children().filter(func(n): return n.get_script() == PUERTA_BANO)
	var placas: Array = mapa.cosas.get_children().filter(func(n): return n.get_script() == mapa.PLACA)
	print("Viviendas: placas %d · cerradas %s con su hoja %d · abiertas %s (esperado: 6, [Médica, Farmacéutica], 2, los otros cuatro)" % [
		placas.size(), cerradas, hojas.size(), abiertas])
	var oscuras: Array = casas.apt.salas.filter(func(s): return mapa.oculto(s.centro)).map(func(s): return s.nombre)
	print("Viviendas: a oscuras %s (esperado: [Médica, Farmacéutica])" % [oscuras])
	print("Viviendas: vecinos %s (esperado: cada uno en la suya)" % [vecinos.map(func(v):
		return "%s en «%s»" % [v.def.nombre, mapa.nombre_zona(mapa.zona_en(v.position))])])
	print("Viviendas: cuánto se aparta cada uno del medio de su habitación %s (esperado: 0 todos menos el técnico, -96)" % [
		vecinos.map(func(v):
			var r := Viviendas.habitacion(v.def.id)
			return "%s %d" % [v.def.nombre, roundi(v.position.x - (r.position.x + r.size.x / 2.0) * Planta.CASILLA)])])
	var camaras: Node2D = mapa.cosas.get_node_or_null("Camaras")
	print("Viviendas: cámaras %s en «%s» (esperado: true, Técnico)" % [camaras != null,
		mapa.nombre_zona(mapa.zona_en(camaras.position)) if camaras else "-"])
	# la habitación del ferretero, con él en medio
	johnny.position = Viviendas.casa("ferretero") + Vector2(-70, 50)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-viviendas-ferretero.png")
	# las fotos del pasillo: la mitad de la izquierda y la de la derecha
	johnny.position = Vector2(Viviendas.casa("policia").x + 120, (Viviendas.PASILLO_F + 3) * Planta.CASILLA)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-viviendas.png")
	johnny.position = Vector2(Viviendas.casa("militar").x - 120, (Viviendas.PASILLO_F + 3) * Planta.CASILLA)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-viviendas-derecha.png")
	# una puerta cerrada no deja pasar: Johnny anda hacia la de la médica un segundo y se queda en el pasillo
	var de_ella: Dictionary = casas.apt.puertas.filter(func(d): return d.vecino == "medico")[0]
	johnny.position = Vector2((de_ella.c + 1) * Planta.CASILLA, (Viviendas.PASILLO_F + 1) * Planta.CASILLA)
	Input.action_press("arriba")
	await get_tree().create_timer(1.0, false).timeout
	Input.action_release("arriba")
	print("Hacia la puerta cerrada de la médica: Johnny en «%s» (esperado: Viviendas)" % mapa.nombre_zona(mapa.zona_en(johnny.position)))
	# y una abierta sí: hacia la del militar, hasta dentro
	var del_militar: Dictionary = casas.apt.puertas.filter(func(d): return d.vecino == "militar")[0]
	johnny.position = Vector2((del_militar.c + 1) * Planta.CASILLA, (Viviendas.PASILLO_F + 1) * Planta.CASILLA)
	Input.action_press("arriba")
	await get_tree().create_timer(0.6, false).timeout
	Input.action_release("arriba")
	print("Hacia la puerta abierta del militar: Johnny en «%s» (esperado: Militar)" % mapa.nombre_zona(mapa.zona_en(johnny.position)))
	Captura.foto("captura-viviendas-habitacion.png")
	# acompañar: el policía; luego el militar (el policía vuelve a su habitación)
	var policia: Aliado = vecinos.filter(func(v): return v.def.id == "policia")[0]
	await arrimarse(policia)
	print("Acompaña: '%s' | equipo %s (esperado: policia, [Policía])" % [Guardado.cargar().acompanante,
		equipo.map(func(x): return x.def.nombre)])
	var militar: Aliado = vecinos.filter(func(v): return v.def.id == "militar")[0]
	await arrimarse(militar)
	print("Acompaña: '%s' | equipo %s | el policía, de vuelta en «%s» (esperado: militar, [Militar], Policía)" % [
		Guardado.cargar().acompanante, equipo.map(func(x): return x.def.nombre),
		mapa.nombre_zona(mapa.zona_en(policia.position))])
	# de vuelta a la sala por la puerta de la izquierda, con el militar
	johnny.position = mapa.puertas[0].position + Vector2(16, 0)
	await get_tree().create_timer(1.0, false).timeout
	print("De vuelta: en «%s», junto a la puerta de la derecha (a %d) · equipo %s · vecinos en la sala %d (esperado: mantenimiento, 0, [Militar], 0)" % [
		partida.planta.sitios[partida.aqui].tipo, roundi(johnny.position.distance_to(partida.mapa.puertas[1].llegada())),
		equipo.map(func(x): return x.def.nombre), vecinos.size()])
	# en la 1ª planta, con el ascensor arreglado: la sala que se añade lleva también a las viviendas, y de vuelta
	partida.nueva_planta(2)
	partida.arreglar_ascensor()
	var abajo: Dictionary = partida.planta.sitios[partida.planta.mantenimiento]
	var suyas: Dictionary = partida.planta.sitios[partida.planta.viviendas]
	print("1ª planta, ascensor arreglado: la sala lleva a %d, las viviendas %d vuelven a %d (esperado: %d, %d)" % [
		abajo.salidas[1].a, partida.planta.viviendas, suyas.salidas[0].a, partida.planta.viviendas, partida.planta.mantenimiento])
	await partida.montar(partida.planta.viviendas, 0, false)
	var minimapa: Node = partida.get_node("Pantalla/Minimapa")
	print("1ª planta, en las viviendas: arriba pone «%s» · el minimapa, abajo %s (esperado: Planta baja · Viviendas, true)" % [
		partida.lugar.text, minimapa.abajo()])
	for a in equipo:
		a.queue_free()
	equipo = []
	Guardado.cambiar(func(x):
		x.rescatados = antes[0]
		x.acompanante = antes[1])
	partida.nueva_planta(1)
	await partida.montar(partida.planta.mantenimiento, 0, false)
	equipo = equipo_antes
	for a in equipo:
		partida.mapa.cosas.add_child(a)
		a.position = johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))


# Johnny se arrima a un vecino desde el lado del pasillo (como al entrar por su puerta): primero se queda cerca y
# luego llega hasta él
func arrimarse(v: Aliado) -> void:
	var hacia := Vector2(0, 1 if v.position.y < Viviendas.PASILLO_F * Planta.CASILLA else -1)
	johnny.position = v.position + hacia * 120.0
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.2, false).timeout
	johnny.position = v.position + hacia * 20.0
	await get_tree().create_timer(0.3, false).timeout


# Los seis rescatados a la vez en las viviendas, cada uno en su habitación (sin acompañante, para que se vean
# todos): la foto, desde el medio del pasillo. Luego se deja el guardado y el equipo como estaban
func probar_los_seis() -> void:
	var g := Guardado.cargar()
	var antes := [g.rescatados.duplicate(), g.acompanante]
	var equipo_antes := equipo
	for a in equipo:
		a.get_parent().remove_child(a)
	equipo = []
	Guardado.cambiar(func(x):
		x.rescatados = DATOS.keys()
		x.acompanante = "")
	await partida.montar(partida.planta.viviendas, 0, false)
	johnny.position = Vector2(Viviendas.COLS * Planta.CASILLA / 2.0, (Viviendas.PASILLO_F + 3) * Planta.CASILLA)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	print("Los seis en las viviendas: %s | puertas cerradas %d (esperado: 0)" % [vecinos.map(func(v): return "%s en «%s»" % [
		v.def.nombre, partida.mapa.nombre_zona(partida.mapa.zona_en(v.position))]),
		partida.mapa.sitio.apt.puertas.filter(func(d): return d.cerrada).size()])
	Captura.foto("captura-viviendas-seis.png")
	Guardado.cambiar(func(x):
		x.rescatados = antes[0]
		x.acompanante = antes[1])
	equipo = equipo_antes
	for a in equipo:
		partida.mapa.cosas.add_child(a)
		a.position = johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))


# Lo suyo al acompañarte, de los tres del centro comercial a la vez: tres zombis lentos cerca de Johnny
func probar_acompanantes() -> void:
	var antes := equipo
	equipo = de_edificio("centro").map(func(id): return crear(DATOS[id], "equipo"))
	for i in equipo.size():
		equipo[i].idx = i
		partida.mapa.cosas.add_child(equipo[i])
		equipo[i].position = johnny.position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	var zombis := []
	for k in 3:
		zombis.append(partida.meter_zombi("lento", johnny.position + Vector2(-110 + k * 110, -110)))
	await get_tree().create_timer(1.8, false).timeout
	Captura.foto("captura-acompanantes.png")
	await get_tree().create_timer(1.6, false).timeout
	var como := []
	for z in zombis:
		como.append("vida %d aturdido %.1f" % [z.vida, z.aturdido] if is_instance_valid(z) else "muerto")
	print("Acompañantes: zombis %s | charcos x%.1f" % [como, Aliado.charcos_a_medias(get_tree())])
	for z in zombis:
		if is_instance_valid(z):
			z.queue_free()
	for a in equipo:
		a.queue_free()
	equipo = antes


# El guiño de la cafetera: solo la farmacéutica rescatada, con la cafetera sin descubrir. La cafetera, en su
# habitación de las viviendas y no en la sala. Con Johnny en el pasillo, delante de su puerta, no dice nada; al
# entrar él, empieza; si sale antes de acabar, lo deja sin apuntar; y al volver a entrar lo cuenta entero: la foto
# con su primera frase (captura-cafetera.png), lo que dice y si queda apuntado. La segunda vez (tras pasar por la
# sala) ya no dice nada. Se deja el guardado y el equipo como estaban
func probar_cafetera() -> void:
	var g := Guardado.cargar()
	var antes := [g.rescatados.duplicate(), g.acompanante, g.cafetera]
	var equipo_antes := equipo
	for a in equipo:
		if a.get_parent():
			a.get_parent().remove_child(a)
	equipo = []
	Guardado.cambiar(func(x):
		x.rescatados = ["farmaceutica"]
		x.acompanante = ""
		x.cafetera = false)
	await partida.montar(partida.planta.viviendas, 0, false)
	var ella: Aliado = vecinos[0]
	var mapa: Node2D = partida.mapa
	var cafetera: Node2D = mapa.cosas.get_node_or_null("Cafetera")
	print("Cafetera: en «%s» (esperado: Farmacéutica)" % (mapa.nombre_zona(mapa.zona_en(cafetera.position)) if cafetera else "ninguna parte"))
	# en el pasillo, delante de su puerta, y dentro, a su izquierda (no tan cerca como para que se venga contigo, y
	# que no lo tape su bocadillo)
	var fuera := Vector2(ella.casa.x, (Viviendas.ABAJO_F - 3.5) * Planta.CASILLA)
	var dentro := ella.casa + Vector2(-80, -48)
	johnny.position = fuera
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(CAFE_PAUSA + 0.5, false).timeout
	print("Cafetera, Johnny en «%s»: dice '%s' (esperado: Viviendas, '')" % [mapa.nombre_zona(mapa.zona_en(johnny.position)), ella.dicho])
	johnny.position = dentro
	await get_tree().create_timer(CAFE_PAUSA + 0.5, false).timeout
	var primera := ella.dicho
	ella.dicho = ""
	johnny.position = fuera   # sale antes de acabar
	await get_tree().create_timer(CAFE_CADA + 0.5, false).timeout
	print("Cafetera, sale a medias: dijo '%s' y luego '%s' | apuntada %s (esperado: la 1ª frase, '', false)" % [
		primera, ella.dicho, Guardado.cargar().cafetera])
	johnny.position = dentro   # vuelve a entrar
	await get_tree().create_timer(CAFE_PAUSA + 0.5, false).timeout
	Captura.foto("captura-cafetera.png")
	var dichas := [ella.dicho]
	for i in Historia.CAFETERA.size() - 1:
		await get_tree().create_timer(CAFE_CADA, false).timeout
		dichas.append(ella.dicho)
	print("Cafetera: %s dice %s | apuntada %s" % [ella.def.nombre, dichas, Guardado.cargar().cafetera])
	await partida.montar(partida.planta.mantenimiento, 1, false)   # por la puerta de la derecha, a la sala
	print("Cafetera: en la sala hay una %s (esperado: false)" % (partida.mapa.cosas.get_node_or_null("Cafetera") != null))
	await partida.montar(partida.planta.viviendas, 0, false)
	ella = vecinos[0]
	johnny.position = dentro
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(CAFE_PAUSA + CAFE_CADA * 2.0 + 0.5, false).timeout
	print("Cafetera, la segunda vez: dice '%s'" % ella.dicho)
	Guardado.cambiar(func(x):
		x.rescatados = antes[0]
		x.acompanante = antes[1]
		x.cafetera = antes[2])
	for a in equipo:
		a.queue_free()
	equipo = equipo_antes
	for a in equipo:
		partida.mapa.cosas.add_child(a)
		a.position = johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))


# El botiquín de la farmacéutica: sin ella no hay; con ella, en la mochila. En el inventario, con la vida a medias
# y el botiquín elegido (captura-farmaceutica-botiquin.png); con la vida llena «Usar» no lo gasta; con la vida a
# medias cura y lo gasta. Que no sale en el banco y que se puede tirar. Luego se deja todo como estaba
func probar_botiquin() -> void:
	var inv = partida.inventario
	var antes := [Guardado.cargar().rescatados.duplicate(), partida.mochila.duplicate(), johnny.vida]
	partida.mochila = []
	Guardado.cambiar(func(x): x.rescatados = ["ferretero"])
	var sin_ella := botiquin_al_empezar()
	Guardado.cambiar(func(x): x.rescatados = ["farmaceutica"])
	var con_ella := botiquin_al_empezar()
	partida.mochila.append_array(["trapo", "trapo", "alcohol"])
	johnny.vida = roundi(johnny.vida_tope() * 0.5)
	partida.abrir_cosas("inventario")
	print("Botiquín al empezar: sin ella %s | con ella %s | mochila %s | en el banco %s" % [sin_ella, con_ella,
		partida.mochila, Recetas.LISTA.values().any(func(r): return "botiquin" in r.con)])
	inv.tocar("m0")
	await get_tree().create_timer(0.4).timeout   # (sigue contando con el juego en pausa)
	var marcado := get_viewport().gui_get_focus_owner()
	print("Botiquín elegido: marcado '%s' | dice '%s'" % [marcado.name if marcado else "-",
		inv.fondo.find_child("nota", true, false).text])
	Captura.foto("captura-farmaceutica-botiquin.png")
	var vida_media: int = johnny.vida
	johnny.vida = johnny.vida_tope()
	inv.usar()
	print("Botiquín con la vida llena: abierto %s | sigue en la mochila %s" % [inv.abierto != "", "botiquin" in partida.mochila])
	johnny.vida = vida_media
	inv.usar()
	print("Botiquín usado: vida %d -> %d (cura %d) | abierto %s | juego en pausa %s | mochila %s" % [vida_media,
		johnny.vida, partida.cura_botiquin(), inv.abierto != "", get_tree().paused, partida.mochila])
	partida.mochila.append("botiquin")
	partida.abrir_cosas("inventario")
	inv.tocar("m%d" % (Objetos.casillas(partida.mochila).size() - 1))
	inv.tirar()
	inv.cerrar()
	await get_tree().process_frame
	var es_botiquin := func(c): return c.get_script() == partida.BILLETE and c.icono.resource_path.ends_with("/botiquin.png")
	var tirados: Array = partida.mapa.cosas.get_children().filter(es_botiquin)
	print("Botiquín tirado: en el suelo %d (tamaño %.1f) | mochila %s" % [tirados.size(),
		tirados[0].tamano if not tirados.is_empty() else 0.0, partida.mochila])
	for c in tirados:
		c.queue_free()
	Guardado.cambiar(func(x): x.rescatados = antes[0])
	partida.mochila = antes[1]
	johnny.vida = antes[2]


func iconos_lanzables() -> Array:
	return partida.ICONOS_LANZABLES.values()
