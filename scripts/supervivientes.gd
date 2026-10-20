# El superviviente de la partida (src/superviviente.js del JS). En cada partida sale uno de los tres que aún no
# viven en la sala de mantenimiento, en una planta al azar (nunca la última), escondido en el baño de un
# apartamento con la puerta cerrada (el baño lo guarda planta.gd, sin zombis). Grita "¡Socorro!" y da golpes de
# vez en cuando para que se sepa dónde está (más flojo desde el pasillo); hay una flecha en el borde de la
# pantalla y un "!" en el minimapa. Al limpiar el piso se abre la puerta del baño y, al arrimarse, se une al equipo.
#
# La horda: al ir a salir del piso con él, la puerta de entrada se cierra de golpe. Él se pone a forzar la
# cerradura (3 minutos de trabajo) mientras entran zombis por las habitaciones, cada vez más y peores. Si Johnny
# se aleja de él, van a por él; si lo tumban, la cerradura no avanza hasta que Johnny lo levanta (quedarse a su
# lado). Va diciendo cómo lo lleva y, a mitad, suelta un molotov y una granada. Arriba, la barra y la cuenta atrás.
#
# Al ganar con él en el equipo se viene a vivir a la sala de mantenimiento (Guardado: rescatados) y ya no vuelve a
# salir. Los rescatados esperan a la derecha del ordenador; al arrimarse a uno, te acompaña (Guardado:
# acompanante) y empieza las partidas siguientes en el equipo. Solo uno a la vez.
#
# Lo monta partida.gd: recoger() antes de cambiar de sitio y al_montar() después.
class_name Supervivientes
extends Node

const PUERTA_BANO := preload("res://scripts/mapa/puerta_bano.gd")

# Los tres que se pueden rescatar (SURVIVORS de src/config.js). "hoja": el dibujo provisional de Johnny que lleva
const DATOS := {
	"policia": {"id": "policia", "nombre": "Policía", "color": Color("#6fa8ff"), "hoja": "pistola",
		"desc": "Dispara con su pistola cada 1,2 s",
		"habilidad": {"tipo": "disparar", "cada": 1.2, "dano": 5, "rafaga": 1}},
	"medico": {"id": "medico", "nombre": "Médica", "color": Color("#80ed99"), "hoja": "guardia",
		"desc": "Te cura 3 cada 8 s y 10 al limpiar cada piso",
		"habilidad": {"tipo": "curar", "cada": 8.0, "cura": 3, "al_limpiar": 10}},
	"militar": {"id": "militar", "nombre": "Militar", "color": Color("#c9e265"), "hoja": "mp5",
		"desc": "Lanza ráfagas de 3 balas cada 2,5 s",
		"habilidad": {"tipo": "disparar", "cada": 2.5, "dano": 6, "rafaga": 3, "hueco": 0.1}},
}
const MAX_EQUIPO := 4

# Lo que grita desde dentro del baño, y cada cuánto (segundos, al azar entre los dos)
const GRITOS := ["¡Socorro!", "¡Aquí dentro!", "¡Ayuda, por favor!", "¡Que alguien me saque!", "¡Estoy en el baño!"]
const CADA := [2.2, 3.4]

# La horda (números provisionales, los del JS)
const HORDA := {
	"dura": 180.0,     # segundos de trabajo para abrir la puerta (no cuentan mientras está caído)
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
# Por dónde entra cada grupo
const POR := {"salon": "el salón", "cocina": "la cocina", "dormitorio": "el dormitorio", "bano": "el baño"}

var partida: Node
var johnny: Node2D
var rescate := {}          # {def, planta, rescatado, amigo, sitio, horda_hecha} o vacío si no queda a quién salvar
var equipo: Array = []     # los Aliado que siguen a Johnny
var npc: Aliado = null     # el superviviente en su baño (mientras se está en su apartamento)
var puerta: Node2D = null  # y la puerta del baño
var vecinos: Array = []    # los rescatados de otras partidas, en la sala de mantenimiento
var socorro_t := 1.0
var sala_socorro := -1
var grito_t := -9.0
var horda := {}
var tiempo := 0.0
var capa: Control          # la flecha del borde y la barra de la horda (en la pantalla)


func preparar(p: Node) -> void:
	partida = p
	johnny = p.johnny
	capa = Control.new()
	capa.name = "Superviviente"
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.draw.connect(dibujar_capa)
	var pantalla: Node = p.get_node("Pantalla")
	pantalla.add_child(capa)
	pantalla.move_child(capa, p.negro.get_index())   # por debajo del fundido a negro


# Al empezar la partida: quién sale y en qué planta (elegirSuperviviente). Los que ya viven en la sala de
# mantenimiento no vuelven a salir; con los tres rescatados no hay a quién salvar. Y el acompañante elegido
# empieza ya en el equipo
func elegir() -> void:
	var s := Guardado.cargar()
	var quedan := DATOS.keys().filter(func(id): return not id in s.rescatados)
	if not quedan.is_empty():
		rescate = {"def": DATOS[quedan[randi() % quedan.size()]], "planta": randi_range(1, Planta.PLANTAS - 1),
			"rescatado": false, "amigo": null, "sitio": -1, "horda_hecha": false}
	if s.acompanante in s.rescatados and DATOS.has(s.acompanante):
		var a := crear(DATOS[s.acompanante], "equipo")
		a.es_vecino = true
		a.casa = casa_de(s.rescatados.find(s.acompanante))
		equipo.append(a)


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


# El superviviente rescatado en esta partida, si sigue en el equipo (al ganar, se viene a vivir a mantenimiento)
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


# Recién montado el sitio "idx": el equipo, al lado de Johnny; el superviviente en su baño; los vecinos
func al_montar(idx: int, sitio: Dictionary) -> void:
	var mapa: Node2D = partida.mapa
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
			mapa.cosas.add_child(puerta)
			mapa.rehornear()   # que los zombis no cuenten con pasar por ahí
		npc = crear(rescate.def, "encerrado")
		npc.asustado = not sitio.limpio
		npc.position = sup.pos
		mapa.cosas.add_child(npc)
		sala_socorro = -1
	if sitio.tipo == "mantenimiento":
		colocar_vecinos()


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
	actualizar_horda(delta)


# ═════════════ Encerrado en el baño ═════════════

# Mientras la puerta sigue cerrada, grita y da golpes. Se le oye desde su apartamento (sale de la puerta del baño)
# y desde el pasillo (sale de la puerta del piso)
func actualizar_socorro(delta: float) -> void:
	if not encerrado():
		return
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
	texto_flotante(donde + Vector2(randf_range(-14, 14), 0), GRITOS[randi() % GRITOS.size()], Color("#ff8a8a"), tamano)


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
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 6)
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


# Se ha limpiado el piso "idx": si es el suyo, se abre la puerta del baño; y la médica cura un poco
func piso_limpio(idx: int) -> void:
	for a in equipo:
		a.al_limpiar()
	if not encerrado() or idx != partida.planta.superviviente.sitio:
		return
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
		npc.decir("¡Gracias! ¡Sácame de aquí!")


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


# ═════════════ La horda ═════════════

func actualizar_horda(delta: float) -> void:
	var r := rescate
	if r.is_empty() or not r.rescatado or not r.amigo in equipo or partida.aqui != r.sitio:
		return
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
	else:
		# la cerradura avanza mientras él esté de pie
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
	var a: Aliado = rescate.amigo
	horda = {}
	rescate.horda_hecha = true
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
	if horda.is_empty():
		return
	if cae:
		horda.levantando = 0.0
		a.decir("¡Ayúdame, no puedo levantarme!")
	elif johnny.position.distance_to(a.position) > HORDA.lejos and horda.t - horda.queja_t > 6.0:
		horda.queja_t = horda.t
		a.decir(["¡Johnny, vuelve!", "¡No me dejes aquí!", "¡Que me comen!"][randi() % 3])


# A mitad: tira un molotov y una granada a sus pies (en Godot la munición aún no se acaba: no hacen falta cajas)
func soltar_provisiones(a: Aliado) -> void:
	partida.soltar_lanzable("molotov", a.position + Vector2(-30, 30))
	partida.soltar_lanzable("granada", a.position + Vector2(30, 30))


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


# ═════════════ Los vecinos de la sala de mantenimiento ═════════════

# Su sitio: a la derecha de la mesa del ordenador, en fila
func casa_de(i: int) -> Vector2:
	return Vector2(600 + i * 110, Planta.MURO + 110)


# Los rescatados en otras partidas esperan en la sala de mantenimiento. El que te acompaña ya va en el equipo
# (su sitio se queda vacío)
func colocar_vecinos() -> void:
	var s := Guardado.cargar()
	for i in s.rescatados.size():
		var id: String = s.rescatados[i]
		if not DATOS.has(id) or equipo.any(func(a): return a.def.id == id):
			continue
		var v := crear(DATOS[id], "vecino")
		v.es_vecino = true
		v.casa = casa_de(i)
		v.position = v.casa
		v.armado = true
		partida.mapa.cosas.add_child(v)
		vecinos.append(v)


# Arrimarse a un vecino: se viene contigo (y el que te acompañaba vuelve a su sitio). Como el ordenador, hay que
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


# ═════════════ En la pantalla ═════════════

# La flecha en el borde hacia donde está encerrado y, en la horda, la barra de la cerradura y la cuenta atrás
func dibujar_capa() -> void:
	if partida == null or partida.mapa == null or partida.terminada:
		return
	var letra := Tema.FUENTE
	var tam := capa.size
	if encerrado():
		var hacia := Vector2.INF
		if partida.aqui == partida.planta.superviviente.sitio and puerta:
			hacia = puerta.position + Vector2(0, -40)
		elif partida.aqui == 0:
			var p := puerta_del_pasillo()
			if p:
				hacia = p.position
		if hacia != Vector2.INF:
			var en := partida.get_viewport().get_canvas_transform() * hacia
			var borde := Rect2(Vector2.ZERO, tam).grow(-34)
			if not borde.has_point(en):
				var punto := en.clamp(borde.position, borde.end)
				var color: Color = rescate.def.color
				var radio := 16.0 if tiempo - grito_t < 0.7 else 13.0
				var dir := (en - punto).normalized()
				capa.draw_colored_polygon(PackedVector2Array([punto + dir * (radio + 10), punto + dir.orthogonal() * 8 + dir * radio * 0.6,
					punto - dir.orthogonal() * 8 + dir * radio * 0.6]), color)
				capa.draw_circle(punto, radio + 2, Tema.LINEA)
				capa.draw_circle(punto, radio, color)
				capa.draw_string(letra, punto + Vector2(-20, 6), "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Tema.LINEA)
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


# ═════════════ Para probar ═════════════

# Tecla H: el superviviente pasa a esta planta y Johnny va a su apartamento, ya sin zombis (se abre el baño al
# entrar). Sirve para probar el rescate y la horda sin jugar hasta su planta
func probar_aqui(fundir := true) -> void:
	var sup: Dictionary = partida.planta.get("superviviente", {})
	if partida.cerrada or sup.is_empty():
		partida.decir("Ahora no se puede")
		return
	if rescate.is_empty():
		var def: Dictionary = DATOS.values().pick_random()
		rescate = {"def": def, "planta": 0, "rescatado": false, "amigo": null, "sitio": -1, "horda_hecha": false}
	if rescate.rescatado:
		partida.decir("Ya lo has rescatado en esta partida")
		return
	rescate.planta = partida.planta.num
	sup.activo = true
	sup.puerta.cerrada = true
	var sitio: Dictionary = partida.planta.sitios[sup.sitio]
	sitio.zombis = []
	sitio.limpio = false
	await partida.montar(sup.sitio, 0, fundir)


# Con --captura: el rescate, la horda (con la cerradura adelantada), levantarlo, y un vecino en mantenimiento
func probar() -> void:
	partida.menus.visible = false   # por si ha salido el recuadro de una mutación (tapa las fotos)
	await probar_aqui(false)
	await get_tree().create_timer(0.3, false).timeout
	var sup: Dictionary = partida.planta.superviviente
	print("Superviviente: %s en %s · %s | baño cerrado %s | puerta %s" % [rescate.def.nombre, partida.planta.nombre,
		partida.planta.sitios[sup.sitio].nombre, sup.puerta.get("cerrada"), puerta != null])
	johnny.position = npc.position + Vector2(0, 30) if npc else johnny.position
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	print("Rescatado: %s | equipo %d" % [rescate.rescatado, equipo.size()])
	get_viewport().get_texture().get_image().save_png("res://captura-superviviente.png")
	johnny.position = partida.mapa.puertas[0].llegada()
	johnny.get_node("Camara").reset_smoothing()
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
	get_viewport().get_texture().get_image().save_png("res://captura-horda.png")
	a.inv_t = 0.0
	a.recibir_dano(500)
	print("Caído: %s | cerradura parada en %.1f" % [a.caido, horda.hecho])
	johnny.position = a.position + Vector2(30, 0)
	await get_tree().create_timer(2.3, false).timeout
	print("Levantado: %s | vida %d" % [not a.caido, a.vida])
	horda.hecho = HORDA.dura - 0.3
	await get_tree().create_timer(0.6, false).timeout
	print("Fin de la horda: %s | puerta %s" % [not en_horda(), "cerrada" if partida.cerrada else "abierta"])
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()   # que no estorben al resto de la prueba
	# un vecino rescatado en otra partida: en mantenimiento, arrimarse a él
	var otro: String = DATOS.keys().filter(func(id): return id != rescate.def.id)[0]
	Guardado.cambiar(func(g): g.rescatados = [otro])
	partida.nueva_planta(1)   # la sala de mantenimiento está en la planta baja
	await partida.montar(partida.planta.mantenimiento, 0, false)
	await get_tree().create_timer(0.2, false).timeout
	print("Vecinos en mantenimiento: %d" % vecinos.size())
	if not vecinos.is_empty():
		johnny.position = vecinos[0].position + Vector2(0, 120)
		await get_tree().create_timer(0.2, false).timeout
		johnny.position = vecinos[0].position + Vector2(0, 20)
		await get_tree().create_timer(0.3, false).timeout
	print("Acompañante: '%s' | equipo %s" % [Guardado.cargar().acompanante, equipo.map(func(x): return x.def.nombre)])
	get_viewport().get_texture().get_image().save_png("res://captura-vecinos.png")
	partida.menus.visible = true


func iconos_lanzables() -> Array:
	return partida.ICONOS_LANZABLES.values()
