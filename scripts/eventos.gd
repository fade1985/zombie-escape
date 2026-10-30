# Los eventos sorpresa (parte 8 del centro comercial, trozo 2): a veces, al llegar a una planta, pasa algo que la
# cambia entera. Una de cada cuatro plantas, más o menos (PROBABILIDAD), en los dos edificios; nunca en la última
# (la del jefe final) y, en una misma partida, ninguno se repite. Dentro de la sala del jefe y en la de
# mantenimiento todo sigue como siempre.
#   apagon    toda la planta a oscuras y con las lámparas apagadas: solo se ve con la linterna (Luz.evento)
#   incendio  la alarma de incendios: llueve de los aspersores, el suelo se llena de charcos que resbalan (charco.gd,
#             "agua") y en algunos cae un cable pelado que da calambrazos a Johnny y a los zombis (Cable, abajo)
#   horda     una horda grande llena el pasillo: no empieza hasta que Johnny llega al medio del pasillo (el dueño, 28
#             oct); entonces salen todos de golpe (a los 2 s del cartel), por los dos extremos, justo fuera de pantalla (a su izquierda y a su
#             derecha, alternando: lo cogen entre dos), y van a por él; si Johnny se mete en un piso, los que quedan le
#             esperan en el pasillo. Al acabar con todos, un premio
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

# El cartel de cada uno: "nombre" (arriba a la derecha), "titulo" y "texto" (el cartel grande). Los textos, en español
# (las líneas marcadas); para enseñarlos, pasan por Idioma.t (empezar() y etiqueta())
const DATOS := {
	"apagon": {"color": Color("#9fb4ff"), "sonido": "apagon",
		"nombre": "Apagón", "titulo": "¡APAGÓN!",   # [traducir]
		"texto": "Se ha ido la luz en toda la planta: solo ves lo que alumbra tu linterna"},   # [traducir]
	"incendio": {"color": Color("#ff5d4a"), "sonido": "alarma",
		"nombre": "Alarma de incendios", "titulo": "¡ALARMA DE INCENDIOS!",   # [traducir]
		"texto": "Los aspersores mojan el suelo: resbala, y donde caen cables, ¡calambrazos!"},   # [traducir]
	"horda": {"color": Color("#ff9f1c"), "sonido": "rugido",
		"nombre": "Horda", "titulo": "¡HORDA EN EL PASILLO!",   # [traducir]
		"texto": "Una horda enorme avanza por el pasillo... ¡prepárate!"},   # [traducir]
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
	"zombis": 22,            # los zombis de la horda en la planta baja (hasta el 28 oct, 18; el dueño quería más peligro)...
	"por_planta": 0.15,      # ...y un 15 % más por cada planta (y con la Alerta 1, más: Alerta.mas_zombis)
	"nivel": 1,              # lo peor que sale: el nivel de cada planta (num) más este (tipos_horda)
	"medio": 200.0,          # a cuánto del medio del pasillo tiene que llegar Johnny para que empiece la horda
	"primera": 2.0,          # segundos desde que empieza (el cartel, al llegar al medio) hasta que sale la horda, toda de golpe (hasta el 28 oct, 4)
	"fuera": 520.0,          # a cuánto de Johnny, a lo largo del pasillo, salen como poco (la pantalla mide 960: nadie
                             # aparece delante de él) y hasta 180 más lejos; si por un lado no hay pasillo, por el otro
	"lejos": 720.0,          # (si no hubiera sitio por ninguno de los dos lados, a cuánto de él sale como poco)
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
var horda := {}            # {salio, t, vivos, quedan, hecha}
var lado_horda := 0        # por qué lado de Johnny sale el siguiente zombi de la horda (0 izquierda, 1 derecha)
var sirena_t := 0.0
var cartel: VBoxContainer
var cartel_titulo: Label
var cartel_texto: Label


func preparar(p: Node) -> void:
	partida = p
	name = "Eventos"   # no-tr (nombre de nodo)
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


# Antes de cambiar de sitio: los zombis de la horda que siguen en pie se apuntan (esperarán en el pasillo). Si el mapa
# se guarda, ya se quedan en él, donde estaban
func recoger() -> void:
	if horda.is_empty() or partida.se_guarda():
		return
	for z in horda.vivos:
		if is_instance_valid(z) and z.estado != "muerto":
			horda.quedan.append(z.get_meta("tipo"))
	horda.vivos = []


# El sitio nuevo ya está montado (aún sin sus zombis): si es el pasillo por primera vez, empieza; y si el evento
# vale aquí, se pone lo suyo ("nuevo": si no, el mapa guardado ya lo tiene)
func al_montar(idx: int, sitio: Dictionary, nuevo: bool) -> void:
	if evento != "" and evento != "horda" and not empezado and sitio.tipo == "pasillo":
		empezar()   # (la horda, no: espera a que Johnny llegue al medio del pasillo, en _physics_process)
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
			if nuevo:
				mojar(idx, sitio)
		"horda":
			if idx == 0:
				for tipo in horda.quedan:
					soltar(tipo)
				horda.quedan = []


func empezar() -> void:
	empezado = true
	var d: Dictionary = DATOS[evento]
	var texto: String = Idioma.t(d.texto)
	if evento == "horda":
		horda = {"salio": false, "t": HORDA.primera, "vivos": [], "quedan": [], "hecha": false}
	sirena_t = INCENDIO.sirena
	mostrar_cartel(Idioma.t(d.titulo), texto, d.color)
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
	return " · " + Idioma.t(DATOS[evento].nombre)


# ¿Está Johnny en el medio del pasillo (a HORDA.medio como mucho)? Lo que hace falta para que empiece la horda
func en_el_medio() -> bool:
	if partida.aqui != 0 or partida.cambiando or partida.mapa == null or partida.terminada:
		return false
	var sitio: Dictionary = partida.mapa.sitio
	return sitio.tipo == "pasillo" and absf(partida.johnny.position.x - sitio.ancho / 2.0) <= HORDA.medio


func _physics_process(delta: float) -> void:
	if evento == "horda" and not empezado and en_el_medio():
		empezar()   # Johnny ha llegado al medio del pasillo: ahora sí
		activo = true
		partida.poner_lugar()   # (arriba a la derecha pone «· Horda»)
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
			for hijo in ["Bombilla", "Polvo"]:   # no-tr (nombres de nodo)
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
		h.salio = true
		for i in n:
			soltar(tipos.pick_random())   # todos de golpe (el dueño, 28 oct; antes, de uno en uno)
		Sonido.tocar("rugido")
		partida.decir(Idioma.t("¡Ahí viene la horda!"), 2.5)
	if h.salio and h.vivos.is_empty() and h.quedan.is_empty():
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


# Un zombi de la horda: sale por un extremo del pasillo, justo fuera de pantalla, a un lado de Johnny y luego al otro
# (también los que esperaban cuando Johnny se fue a un piso y ha vuelto), y va a por él. Como la horda empieza con Johnny
# en el medio, suele haber pasillo por los dos lados y lo cogen entre dos; si por un lado no hay, salen por el otro.
# No salen por ninguna puerta
func soltar(tipo: String) -> void:
	var mapa: Node = partida.mapa
	var johnny_x: float = partida.johnny.position.x
	var donde := Vector2.INF
	for i in 2:   # el lado que toca y, si por ahí no cabe, el otro
		var signo := -1.0 if (lado_horda + i) % 2 == 0 else 1.0
		var x := clampf(johnny_x + signo * randf_range(HORDA.fuera, HORDA.fuera + 180.0), Planta.MURO + 30.0,
			mapa.sitio.ancho - Planta.MURO - 30.0)
		if absf(x - johnny_x) >= HORDA.fuera - 20.0:   # (con el borde del pasillo recortando, aún fuera de pantalla)
			donde = mapa.punto_libre_en_x(x)
			if donde != Vector2.INF:
				break
	lado_horda = 1 - lado_horda
	if donde == Vector2.INF:
		donde = mapa.punto_libre(partida.johnny.position, HORDA.lejos)
	var z: Node2D = partida.meter_zombi(tipo, donde)
	z.set_meta("tipo", tipo)
	z.zona = mapa.zona_en(donde)
	horda.vivos.append(z)


func premio() -> void:
	var johnny: Node2D = partida.johnny
	var n: int = HORDA.billetes + partida.planta.num - 1
	partida.soltar_billetes(n, johnny.position + Vector2(0, 40))
	partida.soltar_municion(johnny.position + Vector2(40, 30))
	partida.decir(Idioma.t("¡Horda vencida! Te deja $%d y una caja de munición") % n, 3.5)
	Sonido.tocar("limpio")
	# el logro Contra la marea, cuando ya se ha leído lo del premio (su aviso lo taparía)
	get_tree().create_timer(3.5, false).timeout.connect(partida.logros.cumplir.bind("contra_marea"))


# Al subir a la siguiente planta (partida.gd, subir): si en esta ha habido apagón o incendio, sus dólares (los de
# la horda: HORDA.billetes, uno más por planta) van a la cartera de la partida. Devuelve lo que se dice ("" si nada)
func superado() -> String:
	if not empezado or not evento in ["apagon", "incendio"]:
		return ""
	var n: int = HORDA.billetes + partida.planta.num - 1
	partida.dolares += n
	Sonido.tocar("limpio")
	if evento == "apagon":
		return Idioma.t("¡Apagón superado! +$%d") % n
	return Idioma.t("¡Incendio superado! +$%d") % n


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
	await probar_socorro(foto, esperar)
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


# Un superviviente que pide ayuda en pleno apagón (F19): desde el pasillo, con su puerta en pantalla y fuera de ella, y
# dentro de su apartamento, cada foto justo después de un grito
func probar_socorro(foto: Callable, esperar: Callable) -> void:
	var sup: Supervivientes = partida.supervivientes
	sup.poner_rescate(Supervivientes.DATOS.medico, partida.planta.num)
	partida.planta.superviviente.activo = true
	partida.planta.superviviente.puerta.cerrada = true
	var gritar := func(nombre: String) -> void:
		sup.socorro_t = 0.0
		await esperar.call(0.25)
		foto.call(nombre)
	cartel.hide()   # (que el cartel del apagón no tape las fotos)
	var johnny: Node2D = partida.johnny
	var p := sup.puerta_del_pasillo()
	var pasillo: Dictionary = partida.planta.sitios[0]
	var sentido := signf(pasillo.ancho / 2.0 - p.position.x)   # hacia dónde queda el resto del pasillo
	print("Apagón · la puerta del que pide ayuda: %s, salida por '%s'" % [p.position, p.salida.dir])
	johnny.direccion = "e" if sentido > 0.0 else "o"   # de espaldas a la puerta: la linterna no la alumbra
	johnny.position = Vector2(p.position.x + sentido * 300.0, pasillo.alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	# un compañero que le llama desde lejos: su bocadillo, en la misma foto
	var amigo := sup.crear(Supervivientes.DATOS.policia, "equipo")
	amigo.set_physics_process(false)
	partida.mapa.cosas.add_child(amigo)
	amigo.position = johnny.position + Vector2(-sentido * 150.0, 40.0)
	amigo.decir(Idioma.t(Supervivientes.LLAMADAS[0]))
	await esperar.call(0.4)
	await gritar.call("apagon-socorro-cerca")
	amigo.queue_free()
	johnny.position.x = pasillo.ancho / 2.0 + sentido * (pasillo.ancho / 2.0 - 120.0)   # en la otra punta
	johnny.get_node("Camara").reset_smoothing()
	await esperar.call(0.4)
	await gritar.call("apagon-socorro-lejos")
	await partida.montar(partida.planta.superviviente.sitio, 0, false)
	await esperar.call(0.6)
	await gritar.call("apagon-socorro-piso")
	johnny.position = sup.puerta.position + Vector2(0, 150)   # con la puerta del baño en pantalla
	johnny.get_node("Camara").reset_smoothing()
	await esperar.call(0.4)
	await gritar.call("apagon-socorro-bano")
	await partida.montar(0, 0, false)
	await esperar.call(0.2)


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
	var ancho: float = partida.planta.sitios[0].ancho
	var alto: float = partida.planta.sitios[0].alto
	# lejos del medio (como al llegar) no pasa nada, ni pasado de sobra el tiempo del cartel: espera a que llegue al medio
	johnny.position = Vector2(ancho - 520, alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	await esperar.call(HORDA.primera + 2.0)
	print("Horda · lejos del medio (a %d de él): empezada %s, salió %s (esperado: false, false)" % [
		absf(johnny.position.x - ancho / 2.0), empezado, horda.get("salio", false)])
	# en el medio: empieza (cartel) y, pasado el tiempo, salen todos, por los dos lados
	johnny.position = Vector2(ancho / 2.0 + 60.0, alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	await esperar.call(0.3)
	print("Horda · en el medio: empezada %s, salió %s (esperado: true, false) · arriba pone «%s»" % [empezado,
		horda.get("salio", false), partida.lugar.text])
	var t := 0.0
	while not horda.get("salio", false) and t < HORDA.primera + 8.0:
		await esperar.call(0.1)
		t += 0.1
	print("Horda · salió a los %.1f s del cartel (esperado: %d) y todos a la vez" % [t + 0.3, roundi(HORDA.primera)])
	var z := get_tree().get_nodes_in_group("zombis")
	var a_la_izquierda := z.filter(func(zz): return zz.global_position.x < johnny.global_position.x).size()
	var cerca := z.filter(func(zz): return zz.global_position.distance_to(johnny.global_position) < HORDA.lejos).size()
	print("Horda · salió %s · en el pasillo %d (esperado %d) · a la izquierda de Johnny %d y a la derecha %d (esperado: mitad y mitad) · ya cerca de Johnny %d" % [
		horda.salio, z.size(), roundi(HORDA.zombis * Alerta.mas_zombis() * Reto.mas_zombis()),
		a_la_izquierda, z.size() - a_la_izquierda, cerca])
	await esperar.call(2.5)   # (salen fuera de pantalla: que lleguen a verse para la foto)
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
		name = "Cable"   # no-tr (nombre de nodo)
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
			Peligros.avisar(self, datos, Idioma.t("¡Ojo! Ese charco tiene corriente"))
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
			johnny.recibir_dano(a.dano, null, "cable")
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
		name = "Lluvia"   # no-tr (nombre de nodo)
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
