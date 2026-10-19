# La partida: genera la planta (planta.gd), monta el sitio en el que está Johnny (mapa.gd) y, al cruzar una
# puerta, funde a negro y monta el del otro lado. Lleva también la pantalla (vida, arma, avisos) y las reglas
# del mapa:
#   - Al entrar en un apartamento la puerta se cierra, y no se abre hasta que no queda ni un zombi.
#   - El apartamento de la jefa está cerrado con llave; la llave está en el suelo de otro apartamento.
#   - Al entrar, aparece la portera. Cuando cae, se abren las escaleras a la planta siguiente.
#   - Después de la 4ª planta, el edificio está limpio y la partida vuelve a empezar.
#
# Teclas solo para probar: F2 a F7 sacan un zombi de cada tipo y P, la portera, lejos de Johnny.
#
# Con "-- --captura" hace una prueba sola: cuenta en la terminal qué planta ha salido, mete a Johnny en un
# apartamento, dispara para despertar a los zombis, guarda una foto en captura.png, sube a la planta
# siguiente y se cierra.
extends Node2D

const ZOMBIS := {
	"normal": preload("res://escenas/personajes/zombi_normal.tscn"),
	"lento": preload("res://escenas/personajes/zombi_lento.tscn"),
	"rapido": preload("res://escenas/personajes/zombi_rapido.tscn"),
	"explosivo": preload("res://escenas/personajes/zombi_explosivo.tscn"),
	"tentaculos": preload("res://escenas/personajes/zombi_tentaculos.tscn"),
	"venenoso": preload("res://escenas/personajes/zombi_venenoso.tscn"),
	"portera": preload("res://escenas/personajes/portera.tscn"),
}
const MAPA := preload("res://scripts/mapa/mapa.gd")
const TECLAS := {KEY_F2: "normal", KEY_F3: "lento", KEY_F4: "rapido", KEY_F5: "explosivo", KEY_F6: "tentaculos",
	KEY_F7: "venenoso", KEY_P: "portera"}
const CIERRE := 110.0      # lo que hay que alejarse de la puerta de entrada para que se cierre
const FUNDIDO := 0.25      # segundos del fundido a negro al cruzar una puerta
const ARRIBA_EXTRA := 44   # lo que la cámara deja ver por encima del mapa (la cara del muro de arriba y su moldura)

var planta: Dictionary
var aqui := 0              # el sitio de la planta en el que está Johnny
var mapa: Node2D
var cambiando := false     # durante el fundido no se puede cruzar otra puerta
var cerrada := false       # si la puerta del apartamento en el que está se ha cerrado
var jefa: Node2D = null
var jefa_salio := false    # si ya ha aparecido la portera en este apartamento
var captura := false
var tiempo := 0.0

@onready var johnny := $Johnny
@onready var barra: ProgressBar = $Pantalla/Vida
@onready var cartel: Label = $Pantalla/Arma
@onready var lugar: Label = $Pantalla/Lugar
@onready var aviso: Label = $Pantalla/Mensaje
@onready var negro: ColorRect = $Pantalla/Negro


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	johnny.vida_cambiada.connect(func(vida, maxima):
		barra.max_value = maxima
		barra.value = vida)
	johnny.arma_cambiada.connect(func(texto): cartel.text = texto)
	johnny.modo_cambiado.connect(func(nombre): $Pantalla/Ayuda.text = "Modo: %s (F1 cambia) · 1-6 arma · Q cambiar · R recargar · F2-F7 zombis · P portera" % nombre)
	johnny.murio.connect(_al_morir_johnny)
	johnny.avisar_arma()

	captura = "--captura" in OS.get_cmdline_user_args()
	nueva_planta(1)
	var llegada := puerta_de_tipo("llegada")
	montar(0, llegada, false)
	if captura:
		contar_planta()
	else:
		set_process(false)
		decir("%s: limpia los apartamentos y busca la llave de la portera" % planta.nombre, 4.0)


func nueva_planta(num: int) -> void:
	planta = Planta.generar(num)


func puerta_de_tipo(tipo: String) -> int:
	var salidas: Array = planta.sitios[0].salidas
	for i in salidas.size():
		if salidas[i].tipo == tipo:
			return i
	return 0


# Monta el sitio "idx" y pone a Johnny delante de su salida "por"
func montar(idx: int, por: int, fundir := true) -> void:
	cambiando = true
	if fundir:
		await create_tween().tween_property(negro, "modulate:a", 1.0, FUNDIDO).finished
	# Johnny pasa de un mapa a otro; el viejo se quita del todo antes de montar el nuevo (si no, su
	# navegación y sus muros se mezclarían con los del nuevo)
	johnny.get_parent().remove_child(johnny)
	if mapa:
		remove_child(mapa)
		mapa.queue_free()
	jefa = null
	jefa_salio = false
	$Pantalla/Jefa.hide()
	aqui = idx
	var sitio: Dictionary = planta.sitios[idx]
	mapa = MAPA.new()
	mapa.name = "Mapa"
	var llave := Vector2.INF
	if planta.llave.sitio == idx and not planta.tiene_llave and not planta.get("llave_usada", false):
		llave = planta.llave.pos
	# primero en la escena (para hornear su navegación hace falta que esté dentro) y por debajo de la pantalla
	add_child(mapa)
	move_child(mapa, 0)
	mapa.montar(sitio, llave)
	mapa.llave_cogida.connect(_al_coger_llave)
	for puerta in mapa.puertas:
		puerta.empujada.connect(cruzar)
	mapa.cosas.add_child(johnny)
	johnny.position = mapa.puertas[por].llegada()
	johnny.velocity = Vector2.ZERO
	encuadrar(sitio)
	johnny.get_node("Camara").reset_smoothing()

	# Los zombis que esperan dentro, dormidos (si el piso aún no se ha limpiado)
	for z in [] if sitio.limpio else sitio.zombis:
		var zombi := meter_zombi(z.tipo, z.pos)
		zombi.dormido = true
		zombi.zona = mapa.zona_en(z.pos)
	cerrada = false
	actualizar_puertas()
	poner_lugar()
	if fundir:
		await create_tween().tween_property(negro, "modulate:a", 0.0, FUNDIDO).finished
	cambiando = false
	# En el apartamento de la jefa, aparece ella (si aún no ha caído)
	if sitio.tipo == "jefe" and not sitio.limpio:
		await get_tree().create_timer(0.6).timeout
		if aqui == idx and not jefa_salio:
			jefa_salio = true
			jefa = meter_zombi("portera", mapa.punto_libre(johnny.position, 380.0))


# Los límites de la cámara: el mapa entero (y un poco por arriba). Si el mapa es más pequeño que la pantalla,
# se centra.
func encuadrar(sitio: Dictionary) -> void:
	var camara: Camera2D = johnny.get_node("Camara")
	var pantalla := get_viewport_rect().size
	var x0 := 0.0
	var x1: float = sitio.ancho
	var y0 := -float(ARRIBA_EXTRA)
	var y1: float = sitio.alto
	if x1 - x0 < pantalla.x:
		x0 = (x1 - pantalla.x) / 2.0
		x1 = x0 + pantalla.x
	if y1 - y0 < pantalla.y:
		var medio := (y0 + y1) / 2.0
		y0 = medio - pantalla.y / 2.0
		y1 = y0 + pantalla.y
	camara.limit_left = int(x0)
	camara.limit_right = int(x1)
	camara.limit_top = int(y0)
	camara.limit_bottom = int(y1)


# La luz de cada puerta: roja si no se puede pasar
func actualizar_puertas() -> void:
	var sitio: Dictionary = planta.sitios[aqui]
	for i in mapa.puertas.size():
		var salida: Dictionary = sitio.salidas[i]
		var abierta: bool = salida.cerrojo == ""
		if salida.cerrojo == "llave" and planta.tiene_llave:
			abierta = true
		if salida.cerrojo == "jefa" and planta.jefa_muerta:
			abierta = true
		if sitio.tipo != "pasillo" and cerrada:
			abierta = false
		mapa.puertas[i].abierta = abierta


func poner_lugar() -> void:
	var sitio: Dictionary = planta.sitios[aqui]
	var texto: String = planta.nombre if sitio.tipo == "pasillo" else "%s · %s" % [planta.nombre, sitio.nombre]
	var zona: String = mapa.nombre_zona(mapa.zona_en(johnny.position))
	if zona != "":
		texto += " · " + zona
	if planta.tiene_llave:
		texto += "\nLlevas la llave del " + nombre_jefa()
	lugar.text = texto


# Johnny ha empujado la salida "i" del sitio en el que está
func cruzar(i: int) -> void:
	if cambiando or not johnny.vivo:
		return
	var sitio: Dictionary = planta.sitios[aqui]
	var salida: Dictionary = sitio.salidas[i]
	if sitio.tipo != "pasillo" and cerrada:
		decir("La puerta no se abre mientras quede algún zombi")
		return
	match salida.cerrojo:
		"nunca":
			decir(salida.aviso)
			return
		"llave":
			if not planta.tiene_llave:
				decir(salida.aviso)
				return
			# La llave se gasta al abrir: la puerta queda abierta para siempre
			planta.tiene_llave = false
			planta.llave_usada = true
			salida.cerrojo = ""
			decir("Abres con la llave")
		"jefa":
			if not planta.jefa_muerta:
				decir(salida.aviso)
				return
	if salida.tipo == "escaleras":
		subir()
		return
	montar(salida.a, salida.vuelta)


# Por las escaleras, a la planta siguiente (o, después de la última, se acabó)
func subir() -> void:
	if planta.num >= Planta.PLANTAS:
		cambiando = true
		decir("¡Has limpiado el edificio!", 4.0)
		await get_tree().create_timer(4.0).timeout
		get_tree().reload_current_scene()
		return
	nueva_planta(planta.num + 1)
	await montar(0, puerta_de_tipo("llegada"))
	decir(planta.nombre, 2.5)


func _physics_process(_delta: float) -> void:
	if mapa == null or cambiando:
		return
	var sitio: Dictionary = planta.sitios[aqui]
	poner_lugar()
	if sitio.tipo == "pasillo" or sitio.limpio:
		return
	var quedan: bool = not get_tree().get_nodes_in_group("zombis").is_empty() or (sitio.tipo == "jefe" and not jefa_salio)
	# Al alejarse de la puerta de entrada, se cierra detrás de Johnny
	if not cerrada and quedan and johnny.position.distance_to(mapa.puertas[0].llegada()) > CIERRE:
		cerrada = true
		actualizar_puertas()
		decir("¡La puerta se ha cerrado detrás de ti!")
	elif not quedan:
		sitio.limpio = true
		cerrada = false
		if sitio.tipo == "jefe":
			planta.jefa_muerta = true
			decir("¡La portera ha caído! Las escaleras ya están abiertas", 4.0)
		else:
			decir("¡Piso limpio! La puerta se ha abierto")
		actualizar_puertas()


func _al_coger_llave() -> void:
	planta.tiene_llave = true
	decir("Has cogido la llave del " + nombre_jefa(), 3.0)


# El nombre del apartamento de la jefa ("2ºC"...)
func nombre_jefa() -> String:
	for s in planta.sitios:
		if s.tipo == "jefe":
			return s.nombre
	return ""


# Un aviso en el centro de la pantalla que se va solo
func decir(texto: String, segundos := 2.2) -> void:
	aviso.text = texto
	aviso.modulate.a = 1.0
	var tween := aviso.create_tween()
	tween.tween_interval(segundos)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.5)


func _al_morir_johnny() -> void:
	$Pantalla/Aviso.show()
	# A los 2 segundos, vuelta a empezar con un edificio nuevo
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


# Saca un zombi del tipo que se pida (o la portera) en ese sitio del mapa
func meter_zombi(tipo: String, donde: Vector2) -> Node2D:
	var zombi: Node2D = ZOMBIS[tipo].instantiate()
	zombi.position = donde
	if tipo == "portera":
		# Cada planta, un 25 % más dura (como el vecino del juego JS)
		zombi.vida_max = int(zombi.vida_max * pow(1.25, planta.num - 1))
		# Su barra de vida grande, arriba, y los vecinos que llama
		var barra_jefa: ProgressBar = $Pantalla/Jefa
		zombi.vida_cambiada.connect(func(vida, maxima):
			barra_jefa.max_value = maxima
			barra_jefa.value = vida
			barra_jefa.visible = vida > 0)
		zombi.pide_zombi.connect(meter_zombi)
	mapa.cosas.add_child(zombi)
	return zombi


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode in TECLAS and not cambiando:
		meter_zombi(TECLAS[evento.keycode], mapa.punto_libre(johnny.position, 300.0))


# ── Solo con --captura ──

func contar_planta() -> void:
	print("Planta: ", planta.nombre)
	for i in range(1, planta.sitios.size()):
		var s: Dictionary = planta.sitios[i]
		var salas := []
		for sala in s.apt.salas:
			salas.append("%s(%d)" % [sala.nombre, sala.casillas])
		var tipos := {}
		for z in s.zombis:
			tipos[z.tipo] = tipos.get(z.tipo, 0) + 1
		print("  %s [%s] %dx%d casillas: %s | zombis: %s" % [s.nombre, s.tipo, s.apt.cols, s.apt.filas, " ".join(salas), tipos])
	print("  llave en ", planta.sitios[planta.llave.sitio].nombre)


func _process(delta: float) -> void:
	tiempo += delta
	var antes := tiempo - delta
	# al segundo, a un apartamento normal (el que tiene más zombis)
	if antes < 1.0 and tiempo >= 1.0:
		var mejor := 1
		for i in range(1, planta.sitios.size()):
			if planta.sitios[i].zombis.size() > planta.sitios[mejor].zombis.size():
				mejor = i
		print("Entra en ", planta.sitios[mejor].nombre)
		montar(mejor, 0, false)
	# un tiro de pistola para despertar a los de cerca
	if antes < 2.5 and tiempo >= 2.5:
		Input.action_press("arma_4")
	if antes < 2.6 and tiempo >= 2.6:
		Input.action_release("arma_4")
		Input.action_press("atacar")
	if antes < 3.2 and tiempo >= 3.2:
		Input.action_release("atacar")
	if int(tiempo * 2.0) != int(antes * 2.0) and tiempo > 1.2:
		var dormidos := 0
		var despiertos := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("dormido"):
				dormidos += 1
			else:
				despiertos += 1
		print("t=%.1f vida=%d puerta %s | dormidos %d, despiertos %d | %s" % [tiempo, johnny.vida,
			"cerrada" if cerrada else "abierta", dormidos, despiertos, lugar.text.replace("\n", " / ")])
	if antes < 4.5 and tiempo >= 4.5:
		get_viewport().get_texture().get_image().save_png("res://captura.png")
		print("Foto guardada. Prueba de las escaleras:")
		planta.jefa_muerta = true
		cerrada = false
		montar(0, puerta_de_tipo("escaleras"), false)
	if antes < 4.7 and tiempo >= 4.7:
		cruzar(puerta_de_tipo("escaleras"))
	if antes < 5.6 and tiempo >= 5.6:
		print("Ahora en: ", planta.nombre, " (", planta.sitios.size() - 1, " puertas)")
		get_viewport().get_texture().get_image().save_png("res://captura-pasillo.png")
		# Johnny pisa la puerta A del pasillo, como si fuera andando
		johnny.position = mapa.puertas[0].position + Vector2(0, 20)
	if antes < 6.6 and tiempo >= 6.6:
		print("Tras pisar la puerta A: en %s (aviso: '%s')" % [planta.sitios[aqui].nombre, aviso.text])
		# Prueba de la jefa: con la llave, a su apartamento
		planta.tiene_llave = true
		for i in planta.sitios.size():
			if planta.sitios[i].tipo == "jefe":
				montar(i, 0, false)
	if antes < 8.0 and tiempo >= 8.0:
		print("La portera ha salido: ", jefa != null, " | puerta ", "cerrada" if cerrada else "abierta")
		if jefa:
			jefa.recibir_golpe(99999, Vector2.ZERO)
	if antes < 9.5 and tiempo >= 9.5:
		print("Jefa muerta: ", planta.jefa_muerta, " | ", aviso.text)
		get_tree().quit()
