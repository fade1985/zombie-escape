# Los eventos sorpresa (parte 8 del centro comercial, trozo 2): a veces, al llegar a una planta, pasa algo que la
# cambia entera. Una de cada cuatro plantas, más o menos (PROBABILIDAD), en los dos edificios; nunca en la última
# (la del jefe final) y, en una misma partida, ninguno se repite. Dentro de la sala del jefe y en la de
# mantenimiento todo sigue como siempre.
#   apagon    toda la planta a oscuras y con las lámparas apagadas: solo se ve con la linterna (Luz.evento)
#   incendio  la alarma de incendios: llueve de los aspersores, el suelo se llena de charcos que resbalan (charco.gd,
#             "agua") y en algunos cae un cable pelado que da calambrazos a Johnny y a los zombis (Cable, abajo)
#   horda     una horda grande llena el pasillo: salen todos de golpe, repartidos por él y lejos de Johnny (fuera
#             de pantalla), y van a por él; si Johnny se mete en un piso, los que quedan le esperan en el pasillo.
#             Al acabar con todos, un premio
# El apagón y el incendio también dan premio (desde el 27 oct; antes solo ponían las cosas difíciles): al subir a la
# siguiente planta, los mismos dólares que la horda, directos a la cartera de la partida (superado())
#
# Empieza la primera vez que Johnny pisa el pasillo de la planta (en la planta baja, al salir de la sala de
# mantenimiento), con un cartel grande en la pantalla. Lo que dura, toda la planta.
# Lo monta partida.gd: nueva_planta() al generar cada planta, recoger() antes de cambiar de sitio y al_montar()
# después. La prueba larga (--captura) va sin eventos; --captura --evento X fuerza ese (probar(), abajo).
class_name Eventos
extends Node

const PROBABILIDAD := 0.25
const LISTA := ["apagon", "incendio", "horda"]
const CHARCO := preload("res://escenas/armas/charco.tscn")
const LAMPARA := "res://escenas/luces/lampara.tscn"
const RAYO := Color("#9fe8ff")

# El cartel de cada uno (el texto de la horda depende del edificio: textos())
const DATOS := {
	"apagon": {"nombre": "Apagón", "titulo": "¡APAGÓN!", "color": Color("#9fb4ff"), "sonido": "apagon",
		"texto": "Se ha ido la luz en toda la planta: solo ves lo que alumbra tu linterna"},
	"incendio": {"nombre": "Alarma de incendios", "titulo": "¡ALARMA DE INCENDIOS!", "color": Color("#ff5d4a"),
		"sonido": "alarma", "texto": "Los aspersores mojan el suelo: resbala, y donde caen cables, ¡calambrazos!"},
	"horda": {"nombre": "Horda", "titulo": "¡HORDA EN EL PASILLO!", "color": Color("#ff9f1c"), "sonido": "rugido",
		"texto": "Una horda enorme avanza por el pasillo... ¡prepárate!"},
}
# Números provisionales
const APAGON := 0.4          # oscuridad de más (con la del pasillo, casi negro: el tope de luz.gd es 0,97)
const INCENDIO := {
	"charcos": [4, 9],       # charcos en cada sitio, según lo grande que sea
	"cables": 2,             # cuántos de ellos tienen un cable pelado (en los sitios pequeños, uno)
	"pulso": 1.6,            # un calambrazo cada tanto; el daño, el del agua de la tienda de electrónica (Peligros.AGUA)
	"sirena": 12.0,          # cada cuánto vuelve a sonar la sirena
}
const HORDA := {
	"zombis": 26,            # los zombis de la horda en la planta baja (hasta el 28 oct, 18: el dueño quería más peligro)...
	"por_planta": 0.15,      # ...y un 15 % más por cada planta (y con la Alerta 1, más: Alerta.mas_zombis)
	"nivel": 1,              # lo peor que sale: el nivel de cada planta (num) más este (tipos_horda)
	"primera": 4.0,          # segundos desde que Johnny pisa el pasillo hasta que sale la horda
	"goteo": 0.15,           # salen de uno en uno, con este hueco (así no se apilan)
	"lejos": 720.0,          # a cuánto de Johnny salen como poco: fuera de pantalla, nadie aparece delante de él
	"billetes": 3,           # el premio: estos billetes, uno más por planta, y una caja de munición (el apagón y
                             # el incendio, los mismos dólares, sin la caja: superado())
}

var partida: Node
var rng := RandomNumberGenerator.new()
var usados: Array = []     # los que ya han salido en esta partida
var evento := ""           # el de la planta en la que se está ("" = ninguno)
var forzado := ""          # con --captura --evento X: ese, en todas las plantas
var empezado := false      # si ya ha empezado (Johnny ha pisado el pasillo)
var activo := false        # si Johnny está en un sitio con el evento (no en la sala del jefe ni en mantenimiento)
var charcos := {}          # incendio: sitio -> [{pos, cable, avisado}]
var horda := {}            # {salio, t, goteo, cola, vivos, quedan, hecha}
var sirena_t := 0.0
var cartel: VBoxContainer
var cartel_titulo: Label
var cartel_texto: Label


func preparar(p: Node) -> void:
	partida = p
	name = "Eventos"
	rng.randomize()
	Luz.evento = 0.0   # (es de la clase: podría venir de la partida anterior)
	# el cartel grande, arriba en el centro de la pantalla
	cartel = VBoxContainer.new()
	cartel.name = "CartelEvento"
	cartel.theme = Tema.crear()
	cartel.anchor_right = 1.0
	cartel.offset_left = 40
	cartel.offset_right = -40
	cartel.offset_top = 150
	cartel.offset_bottom = 260
	cartel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartel.modulate.a = 0.0
	cartel_titulo = Label.new()
	cartel_titulo.theme_type_variation = "Titulo"
	cartel_titulo.add_theme_font_size_override("font_size", 48)
	cartel_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cartel.add_child(cartel_titulo)
	cartel_texto = Label.new()
	cartel_texto.add_theme_constant_override("outline_size", 6)
	cartel_texto.add_theme_color_override("font_outline_color", Color(0.11, 0.1, 0.17))
	cartel_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cartel_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cartel.add_child(cartel_texto)
	var pantalla: Node = partida.get_node("Pantalla")
	pantalla.add_child(cartel)
	pantalla.move_child(cartel, partida.negro.get_index())   # por debajo del fundido a negro


func _exit_tree() -> void:
	Luz.evento = 0.0


# Al generar una planta: se sortea si trae evento (con el reto del día, Planta.semilla, igual para todos)
func nueva_planta() -> void:
	var num: int = partida.planta.num
	evento = ""
	empezado = false
	activo = false
	charcos = {}
	horda = {}
	if forzado in LISTA:   # (si no es ninguno de la lista, probar() lo dice y cierra)
		evento = forzado
		return
	if partida.captura or num >= Planta.PLANTAS:
		return
	if Planta.semilla != 0:
		rng.seed = Planta.semilla * 13 + num
	if rng.randf() < PROBABILIDAD:
		# (con el reto "Todo a oscuras" ya está todo apagado: el apagón no se sortea)
		var quedan: Array = LISTA.filter(func(e): return e not in usados and not (e == "apagon" and Reto.oscuras()))
		if not quedan.is_empty():
			evento = quedan[rng.randi() % quedan.size()]
			usados.append(evento)


# Antes de cambiar de sitio: los zombis de la horda que siguen en pie se apuntan (esperarán en el pasillo)
func recoger() -> void:
	if horda.is_empty():
		return
	for z in horda.vivos:
		if is_instance_valid(z) and z.estado != "muerto":
			horda.quedan.append(z.get_meta("tipo"))
	horda.vivos = []


# El sitio nuevo ya está montado (aún sin sus zombis): si es el pasillo por primera vez, empieza; y si el evento
# vale aquí, se pone lo suyo
func al_montar(idx: int, sitio: Dictionary) -> void:
	if evento != "" and not empezado and sitio.tipo == "pasillo":
		empezar()
	activo = empezado and sitio.tipo in ["pasillo", "apartamento"]   # (las tiendas también son "apartamento")
	# A oscuras y con las luces apagadas: con el apagón o, con el reto del día "Todo a oscuras" (reto.gd), en
	# todos los sitios menos la sala de mantenimiento y las viviendas de los rescatados
	var oscuras: bool = (activo and evento == "apagon") or (Reto.oscuras() and sitio.tipo not in ["mantenimiento", "viviendas"])
	Luz.evento = APAGON if oscuras else 0.0
	if oscuras:
		apagar_luces()
	if not activo:
		return
	match evento:
		"incendio":
			mojar(idx, sitio)
		"horda":
			if idx == 0:
				for tipo in horda.quedan:
					soltar(tipo)
				horda.quedan = []


func empezar() -> void:
	empezado = true
	var d: Dictionary = DATOS[evento]
	var texto: String = d.texto
	if evento == "horda":
		horda = {"salio": false, "t": HORDA.primera, "goteo": 0.0, "cola": [], "vivos": [], "quedan": [], "hecha": false}
	sirena_t = INCENDIO.sirena
	mostrar_cartel(d.titulo, texto, d.color)
	get_tree().create_timer(0.3, false).timeout.connect(Sonido.tocar.bind(d.sonido))
	get_tree().create_timer(2.5, false).timeout.connect(partida.tutorial.bind(evento))   # (tras el cartel, la primera vez)


# El cartel: entra con un salto, se queda unos segundos y se va
func mostrar_cartel(titulo: String, texto: String, color: Color) -> void:
	cartel_titulo.text = titulo
	cartel_titulo.add_theme_color_override("font_color", color)
	cartel_texto.text = texto
	cartel.pivot_offset = Vector2(cartel.size.x / 2.0, 30)
	cartel.scale = Vector2(1.3, 1.3)
	cartel.modulate.a = 0.0
	var t := cartel.create_tween()
	t.tween_interval(0.25)
	t.tween_property(cartel, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(cartel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(3.8)
	t.tween_property(cartel, "modulate:a", 0.0, 0.6)


# Lo que se añade al nombre del sitio, arriba a la derecha, mientras dura (partida.gd, poner_lugar)
func etiqueta() -> String:
	if not activo or (evento == "horda" and horda.get("hecha", false)):
		return ""
	return " · " + DATOS[evento].nombre


func _physics_process(delta: float) -> void:
	if not activo or partida.cambiando or partida.mapa == null or partida.terminada:
		return
	if evento == "incendio":
		sirena_t -= delta
		if sirena_t <= 0.0:
			sirena_t = INCENDIO.sirena
			Sonido.tocar("alarma")
	elif evento == "horda" and partida.aqui == 0:
		avanzar_horda(delta)


# ── El apagón ──

# Todas las luces del sitio, apagadas: lámparas, apliques, los letreros de neón...
func apagar_luces() -> void:
	for n in partida.mapa.find_children("*", "", true, false):
		if n.scene_file_path == LAMPARA:
			n.fuerza = 0.0
			for hijo in ["Bombilla", "Polvo"]:
				if n.has_node(hijo):
					n.get_node(hijo).hide()


# ── La alarma de incendios ──

# Los charcos del sitio (la primera vez se reparten y se apuntan: al volver, siguen donde estaban), sus cables y
# la lluvia de los aspersores
func mojar(idx: int, sitio: Dictionary) -> void:
	if not charcos.has(idx):
		charcos[idx] = repartir_charcos(sitio)
	for c in charcos[idx]:
		var charco: Node2D = CHARCO.instantiate()
		charco.tipo = "agua"
		charco.position = c.pos
		partida.mapa.cosas.add_child(charco)
		if c.cable:
			var cable := Cable.new()
			cable.charco = charco
			cable.datos = c
			cable.position = c.pos
			partida.mapa.cosas.add_child(cable)
	partida.mapa.add_child(Lluvia.new())


func repartir_charcos(sitio: Dictionary) -> Array:
	var lista := []
	var n := clampi(roundi(sitio.ancho * sitio.alto / 90000.0), INCENDIO.charcos[0], INCENDIO.charcos[1])
	var puerta: Vector2 = partida.mapa.puertas[0].llegada()
	var mapa: Node = partida.mapa
	for i in 400:
		if lista.size() >= n:
			break
		var p := Vector2(randf_range(Planta.MURO + 50, sitio.ancho - Planta.MURO - 50),
			randf_range(Planta.MURO + 30, sitio.alto - Planta.MURO - 30))
		# entero en el suelo de una habitación (sin pisar un muro), sin muebles encima y no en la misma puerta
		var zona: int = mapa.zona_en(p)
		if zona < 0 or [Vector2(-56, 0), Vector2(56, 0), Vector2(0, -34), Vector2(0, 34)].any(func(d): return mapa.zona_en(p + d) != zona):
			continue
		if not Planta.lejos_de_muebles(sitio, p, 24.0) or p.distance_to(puerta) < 100.0:
			continue
		if lista.any(func(c): return c.pos.distance_to(p) < 150.0):
			continue
		lista.append({"pos": p, "cable": false, "avisado": false})
	for i in mini(INCENDIO.cables if n >= 6 else 1, lista.size()):
		lista[i].cable = true
	return lista


# ── La horda del pasillo ──

func avanzar_horda(delta: float) -> void:
	var h := horda
	if h.is_empty() or h.hecha:
		return
	h.vivos = h.vivos.filter(func(z): return is_instance_valid(z) and z.estado != "muerto")
	h.t -= delta
	if h.t <= 0.0 and not h.salio:
		var num: int = partida.planta.num
		var n := roundi(HORDA.zombis * (1.0 + HORDA.por_planta * (num - 1)) * Alerta.mas_zombis() * Reto.mas_zombis())
		var tipos := tipos_horda(num)
		for i in n:
			h.cola.append(tipos.pick_random())
		h.salio = true
		Sonido.tocar("rugido")
		partida.decir("¡Ahí viene la horda!", 2.5)
	h.goteo -= delta
	if not h.cola.is_empty() and h.goteo <= 0.0:
		h.goteo = HORDA.goteo
		soltar(h.cola.pop_front())
	if h.salio and h.cola.is_empty() and h.vivos.is_empty() and h.quedan.is_empty():
		h.hecha = true
		premio()


# Qué zombis salen: cada planta, peores (en el centro comercial, también vigilantes)
func tipos_horda(num: int) -> Array:
	var nivel: int = HORDA.nivel + num
	var tipos := ["lento", "normal", "normal"]
	if nivel >= 2:
		tipos += ["rapido", "rapido"]
	if nivel >= 3:
		tipos += ["explosivo", "venenoso"]
	if nivel >= 5:
		tipos.append("tentaculos")
	if partida.ed.generador == "tienda" and num >= 2:
		tipos.append("vigilante")
	return tipos


# Un zombi de la horda: sale en algún sitio del pasillo lejos de Johnny, fuera de pantalla (también los que esperaban
# cuando Johnny se fue a un piso y ha vuelto), y va a por él. No salen por ninguna puerta
func soltar(tipo: String) -> void:
	var mapa: Node = partida.mapa
	var donde: Vector2 = mapa.punto_libre(partida.johnny.position, HORDA.lejos)
	var z: Node2D = partida.meter_zombi(tipo, donde)
	z.set_meta("tipo", tipo)
	z.zona = mapa.zona_en(donde)
	horda.vivos.append(z)


func premio() -> void:
	var johnny: Node2D = partida.johnny
	var n: int = HORDA.billetes + partida.planta.num - 1
	partida.soltar_billetes(n, johnny.position + Vector2(0, 40))
	partida.soltar_municion(johnny.position + Vector2(40, 30))
	partida.decir("¡Horda vencida! Te deja $%d y una caja de munición" % n, 3.5)
	Sonido.tocar("limpio")


# Al subir a la siguiente planta (partida.gd, subir): si en esta ha habido apagón o incendio, sus dólares (los de
# la horda: HORDA.billetes, uno más por planta) van a la cartera de la partida. Devuelve lo que se dice ("" si nada)
func superado() -> String:
	if not empezado or not evento in ["apagon", "incendio"]:
		return ""
	var n: int = HORDA.billetes + partida.planta.num - 1
	partida.dolares += n
	Sonido.tocar("limpio")
	return "¡%s superado! +$%d" % ["Apagón" if evento == "apagon" else "Incendio", n]


# ═════════════ La prueba (--captura --evento X) ═════════════

# Fuerza el evento en la planta baja, sale al pasillo (empieza) y saca sus fotos
func probar(que: String) -> void:
	if not que in LISTA:
		print("No hay ningún evento sorpresa '%s': los que hay son %s" % [que, ", ".join(LISTA)])
		get_tree().quit()
		return
	var foto := func(nombre: String) -> void:
		Captura.foto("captura-evento-%s.png" % nombre)
	var esperar := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	print("Prueba del evento '%s' en %s" % [que, partida.ed.el_nombre])
	# lo de siempre: cuántos eventos salen en 2000 partidas (sin forzar), y en qué plantas
	var por_planta := {}
	var por_partida := {}
	var guardado := forzado
	forzado = ""
	partida.captura = false
	for i in 2000:
		usados = []
		var cuantos := 0
		for num in range(1, Planta.PLANTAS + 1):
			partida.planta.num = num
			nueva_planta()
			if evento != "":
				cuantos += 1
				por_planta[num] = por_planta.get(num, 0) + 1
		por_partida[cuantos] = por_partida.get(cuantos, 0) + 1
	partida.captura = true
	partida.planta.num = 1
	forzado = guardado
	usados = []
	nueva_planta()
	print("Sorteo · en 2000 partidas, eventos por planta: %s · eventos por partida: %s" % [por_planta, por_partida])
	# al pasillo: empieza
	await partida.montar(0, 0, false)
	partida.johnny.position = Vector2(400, partida.planta.sitios[0].alto / 2.0)
	partida.johnny.get_node("Camara").reset_smoothing()
	await esperar.call(0.6)
	print("Pasillo · evento '%s' empezado: %s · activo: %s · sitio: '%s' · oscuridad %.2f" % [evento, empezado, activo,
		partida.lugar.text, Luz.nivel])
	foto.call(que)
	match que:
		"apagon":
			await probar_apagon(foto, esperar)
		"incendio":
			await probar_incendio(foto, esperar)
		"horda":
			await probar_horda(foto, esperar)
	get_tree().quit()


# El piso con más zombis (para ver el evento dentro) y el del jefe (sin él)
func piso(jefe: bool) -> int:
	var mejor := -1
	for i in range(1, partida.planta.sitios.size()):
		var s: Dictionary = partida.planta.sitios[i]
		if (s.tipo == "jefe") != jefe or not s.has("apt") or s.tipo in ["viviendas", "mantenimiento"]:
			continue
		if mejor < 0 or s.zombis.size() > partida.planta.sitios[mejor].zombis.size():
			mejor = i
	return mejor


func probar_apagon(foto: Callable, esperar: Callable) -> void:
	var lamparas: Array = partida.mapa.find_children("*", "", true, false).filter(func(n): return n.scene_file_path == LAMPARA)
	print("Apagón · luces del pasillo: %d, apagadas: %d" % [lamparas.size(), lamparas.filter(func(n): return n.fuerza == 0.0).size()])
	await partida.montar(piso(false), 0, false)
	await esperar.call(1.0)
	print("Apagón · en '%s': oscuridad %.2f (Luz.evento %.2f)" % [partida.planta.sitios[partida.aqui].nombre, Luz.nivel, Luz.evento])
	foto.call("apagon-piso")
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	partida.planta.tiene_llave = true
	await partida.montar(piso(true), 0, false)
	await esperar.call(1.0)
	print("Apagón · en la sala del jefe: activo %s, oscuridad %.2f (sin evento, como siempre)" % [activo, Luz.nivel])


func probar_incendio(foto: Callable, esperar: Callable) -> void:
	var johnny: Node2D = partida.johnny
	var lista: Array = charcos.get(0, [])
	print("Incendio · charcos en el pasillo: %d, con cable: %d" % [lista.size(), lista.filter(func(c): return c.cable).size()])
	# Johnny, dentro de un charco con cable, con un zombi al lado (también dentro)
	var con: Dictionary = lista.filter(func(c): return c.cable)[0]
	johnny.position = con.pos
	johnny.set_physics_process(false)   # quieto en el charco (que no le saque un empujón de un mueble)
	johnny.get_node("Camara").reset_smoothing()
	var zombi: Node2D = partida.meter_zombi("lento", con.pos + Vector2(24, 4))
	zombi.set_physics_process(false)
	var antes: int = johnny.vida
	var antes_z: int = zombi.vida
	await esperar.call(INCENDIO.pulso + 0.3)
	print("Incendio · tras un calambrazo: Johnny %d -> %d · zombi %d -> %d" % [antes, johnny.vida,
		antes_z, zombi.vida if is_instance_valid(zombi) else 0])
	foto.call("incendio-cable")
	johnny.set_physics_process(true)
	await esperar.call(0.2)
	print("Incendio · en el charco resbala: %s" % johnny.estados.has("resbaladizo"))
	johnny.vida = johnny.stats.vida_max
	await partida.montar(piso(false), 0, false)
	await esperar.call(1.0)
	print("Incendio · en '%s': charcos %d" % [partida.planta.sitios[partida.aqui].nombre, charcos.get(partida.aqui, []).size()])
	foto.call("incendio-piso")
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await partida.montar(0, 1, false)
	await esperar.call(0.5)
	print("Incendio · al volver al pasillo, los mismos charcos: %s" % (get_tree().get_nodes_in_group("charcos").size() == lista.size()))


func probar_horda(foto: Callable, esperar: Callable) -> void:
	var johnny: Node2D = partida.johnny
	johnny.set_physics_process(false)   # quieto, que no le muevan los empujones
	johnny.position = Vector2(partida.planta.sitios[0].ancho - 520, partida.planta.sitios[0].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	await esperar.call(HORDA.primera + 5.0)
	var z := get_tree().get_nodes_in_group("zombis")
	var cerca := z.filter(func(zz): return zz.global_position.distance_to(johnny.global_position) < HORDA.lejos).size()
	print("Horda · salió %s · en el pasillo %d (esperado %d) · en cola %d · ya cerca de Johnny %d" % [horda.salio, z.size(),
		roundi(HORDA.zombis * Alerta.mas_zombis() * Reto.mas_zombis()), horda.cola.size(), cerca])
	foto.call("horda")
	# Johnny se mete en un piso: los que quedan le esperarán en el pasillo
	await partida.montar(piso(false), 0, false)
	print("Horda · al irse se apuntan %d" % horda.quedan.size())
	for zz in get_tree().get_nodes_in_group("zombis"):
		zz.queue_free()
	await partida.montar(0, 1, false)
	await esperar.call(0.3)
	print("Horda · al volver, en el pasillo: %d" % get_tree().get_nodes_in_group("zombis").size())
	# los que quedan, de golpe, y todos al suelo
	var dolares: int = partida.dolares
	horda.t = 0.0
	for i in 60:
		for zz in get_tree().get_nodes_in_group("zombis"):
			if zz.estado != "muerto":
				zz.recibir_golpe(99999, Vector2.ZERO)
		await esperar.call(0.25)
		if horda.hecha:
			break
		horda.t = minf(horda.t, 0.0)
	johnny.set_physics_process(true)
	await esperar.call(1.5)
	print("Horda · vencida: %s · dólares %d -> %d · aviso '%s' · lugar '%s'" % [horda.hecha,
		dolares, partida.dolares, partida.aviso.text, partida.lugar.text])
	foto.call("horda-premio")


# ═════════════ Lo que se dibuja ═════════════

# El cable pelado que ha caído en un charco de los aspersores: echa chispas y, cada tanto, un calambrazo a todo el
# charco (como el agua de la tienda de electrónica, agua.gd, con sus mismos daños)
class Cable extends Node2D:
	var charco: Node2D
	var datos: Dictionary
	var punta := Vector2(-10, 2)
	var desde := Vector2(78, -36)   # por donde entra el cable (fuera del charco)
	var pulso := 0.0
	var destello := 0.0
	var rayos: Array = []
	var t := 0.0
	var chispas: Node2D
	var luz: PointLight2D

	func _ready() -> void:
		name = "Cable"
		z_index = -1
		pulso = randf() * INCENDIO.pulso   # que no den todos a la vez
		chispas = Node2D.new()
		var propio := CanvasItemMaterial.new()
		propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # lo eléctrico luce por sí mismo
		chispas.material = propio
		chispas.draw.connect(dibujar_chispas)
		add_child(chispas)
		luz = PointLight2D.new()
		luz.texture = preload("res://escenas/luces/luz_suave.tres")
		luz.texture_scale = 110.0 / 128.0
		luz.color = RAYO
		luz.range_item_cull_mask = Luz.TODAS
		luz.position = punta
		add_child(luz)

	func _physics_process(delta: float) -> void:
		t += delta
		destello = maxf(0.0, destello - delta)
		var johnny := get_tree().get_first_node_in_group("jugador")
		if johnny and johnny.vivo and charco.dentro(johnny.global_position, 80.0):
			Peligros.avisar(self, datos, "¡Ojo! Ese charco tiene corriente")
		pulso += delta
		if pulso >= INCENDIO.pulso:
			pulso -= INCENDIO.pulso
			calambrazo(johnny)
		if randf() < 8.0 * delta:
			var a := randf() * TAU
			Particulas.soltar(self, global_position + punta, Vector2(cos(a), sin(a) - 0.6) * randf_range(40, 110),
				Color.WHITE if randf() < 0.4 else RAYO, 2, randf_range(0.15, 0.3))
		luz.energy = (0.5 + 0.35 * randf() + destello * 4.0) * Luz.fuerza()
		charco.modulate = Color.WHITE.lerp(Color(1.7, 2.0, 2.3), destello / 0.2)
		chispas.queue_redraw()

	func calambrazo(johnny: Node2D) -> void:
		var a: Dictionary = Peligros.AGUA
		destello = 0.2
		rayos.clear()
		for i in 4:
			var meta := Vector2.from_angle(randf() * TAU) * Vector2(50, 28) * randf_range(0.4, 1.0)
			var puntos := [punta]
			for k in range(1, 5):
				puntos.append(punta.lerp(meta, k / 4.0) + Vector2(randf_range(-7, 7), randf_range(-5, 5)))
			rayos.append(puntos)
		Luz.destello(self, global_position + punta, 240.0, 0.25, 0.8, RAYO)
		var dio := false
		if johnny and johnny.vivo and johnny.esquiva_t <= 0.0 and charco.dentro(johnny.global_position, 0.0):
			johnny.pisar({"calambre": {"despues": a.tieso}})
			johnny.recibir_dano(a.dano)
			dio = true
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi.get("dormido") or zombi.get("estado") == "muerto" or not charco.dentro(zombi.global_position, 0.0):
				continue
			zombi.herir(a.dano_zombi, Estados.LISTA.calambre.color)
			if "aturdido" in zombi:
				zombi.aturdido = maxf(zombi.aturdido, a.aturde)
			dio = true
		if dio or (johnny and johnny.global_position.distance_to(global_position) < 300.0):
			Sonido.tocar("calambre")

	# El cable por el suelo, desde fuera del charco hasta dentro, con una curva y la punta de cobre abierta
	func _draw() -> void:
		var medio := (desde + punta) / 2.0 + Vector2(0, 16)
		for i in 21:
			var k := i / 20.0
			var p := desde.lerp(medio, k).lerp(medio.lerp(punta, k), k)
			p = (p / 2.0).floor() * 2.0
			draw_rect(Rect2(p, Vector2(4, 4)), Color("#16171b"))
			draw_rect(Rect2(p, Vector2(2, 2)), Color("#3c3f47"))
		for h in [Vector2(-6, -4), Vector2(-7, 2), Vector2(-4, 6)]:
			draw_line(punta, punta + h, Color("#d9873f"), 2.0)

	func dibujar_chispas() -> void:
		for i in 3:
			if randf() < 0.5:
				chispas.draw_rect(Rect2(punta + Vector2(randi_range(-6, 4), randi_range(-6, 4)) * 2.0, Vector2(2, 2)), RAYO)
		if destello <= 0.0:
			return
		for puntos in rayos:
			for i in puntos.size() - 1:
				chispas.draw_line(puntos[i], puntos[i + 1], Color(RAYO, 0.6), 6.0)
				chispas.draw_line(puntos[i], puntos[i + 1], Color.WHITE, 2.0)


# La lluvia de los aspersores: rayitas que caen por toda la pantalla, por encima de todo (y lucen solas un poco,
# para que se vean también en lo oscuro)
class Lluvia extends Node2D:
	var gotas: Array = []   # [x, y (de 0 a 1 en la pantalla), velocidad, largo]
	var t := 0.0

	func _ready() -> void:
		name = "Lluvia"
		z_index = 40
		var propio := CanvasItemMaterial.new()
		propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = propio
		for i in 110:
			gotas.append([randf(), randf(), randf_range(0.9, 1.4), randi_range(4, 8) * 2])

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var lienzo := get_canvas_transform()
		var arriba := lienzo.affine_inverse() * Vector2.ZERO
		var tam := get_viewport_rect().size / lienzo.get_scale()
		for g in gotas:
			var y := fposmod(g[1] + t * g[2], 1.0)
			var p := arriba + Vector2(g[0] * tam.x - y * 30.0, y * tam.y)
			p = (p / 2.0).floor() * 2.0
			draw_rect(Rect2(p, Vector2(2, g[3])), Color(0.72, 0.86, 1.0, 0.32))
			if y > 0.93:   # al llegar abajo, una salpicadura
				draw_rect(Rect2(p + Vector2(-4, g[3] + 2), Vector2(2, 2)), Color(0.72, 0.86, 1.0, 0.4))
				draw_rect(Rect2(p + Vector2(4, g[3] + 2), Vector2(2, 2)), Color(0.72, 0.86, 1.0, 0.4))
