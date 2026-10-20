# La partida: genera la planta (planta.gd), monta el sitio en el que está Johnny (mapa.gd) y, al cruzar una
# puerta, funde a negro y monta el del otro lado. Lleva también la pantalla (vida, arma, avisos) y las reglas
# del mapa:
#   - Al entrar en un apartamento la puerta se cierra, y no se abre hasta que no queda ni un zombi.
#   - El apartamento de la jefa está cerrado con llave; la llave está en el suelo de otro apartamento.
#   - Al entrar, aparece la portera. Cuando cae, se abren las escaleras a la planta siguiente.
#   - Después de la última planta, el edificio está limpio: cartel de victoria.
# La partida empieza en la sala de mantenimiento de la planta baja. Arriba a la izquierda va el HUD (hud.gd)
# y arriba a la derecha, el minimapa. Esc o Start abren la pausa (menus.gd).
#
# Dinero y guardado (como game.js y game-combate.js del JS): los zombis sueltan billetes a veces (la portera,
# varios). Los dólares de la partida solo se guardan si completas el edificio; si caes, se pierden. Al acabar
# (ganes, caigas o abandones) se guardan los récords y los zombis matados (guardado.gd).
#
# El ordenador de la sala de mantenimiento (ui/ordenador.gd): al arrimarse a su mesa, el juego se pausa y sale
# ConserjeOS, para comprar puntos de talento, subir talentos y comprar armas con los dólares ahorrados. Los
# talentos (talentos.gd) se aplican a Johnny al empezar la partida y al comprarlos.
#
# Teclas solo para probar: F2 a F7 sacan un zombi de cada tipo y P, la portera, lejos de Johnny. F9 lleva a
# la sala de exposición (todos los muebles y zombis) y vuelve a la de mantenimiento. M saca el recuadro de
# las mutaciones sin tener que matar a la portera.
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
const MINIMAPA := preload("res://scripts/minimapa.gd")
const TECLAS := {KEY_F2: "normal", KEY_F3: "lento", KEY_F4: "rapido", KEY_F5: "explosivo", KEY_F6: "tentaculos",
	KEY_F7: "venenoso", KEY_P: "portera"}
const BILLETE := preload("res://scripts/billete.gd")
const HUD := preload("res://scripts/ui/hud.gd")
const MENUS := preload("res://scripts/ui/menus.gd")
const ORDENADOR := preload("res://scripts/ui/ordenador.gd")
const INVENTARIO := preload("res://scripts/ui/inventario.gd")
const EDIFICIO := "apartamentos"   # de momento solo hay un edificio
const NOMBRE_EDIFICIO := "Apartamentos"
const BILLETE_ZOMBI := 0.07        # probabilidad de que un zombi suelte un billete
const BILLETES_JEFA := 3           # los que suelta la portera al caer
const BOTIQUIN := 50               # lo que cura el botiquín de los baños (BOTIQUIN_CURA en el JS)
const ICONOS_LANZABLES := {"molotov": preload("res://assets/ui/iconos/molotov.png"),
	"granada": preload("res://assets/ui/iconos/granada.png")}
const CIERRE := 110.0     # lo que hay que alejarse de la puerta de entrada para que se cierre
const FUNDIDO := 0.25      # segundos del fundido a negro al cruzar una puerta
const ARRIBA_EXTRA := 44   # lo que la cámara deja ver por encima del mapa (la cara del muro de arriba y su moldura)

var planta: Dictionary
var aqui := 0              # el sitio de la planta en el que está Johnny
var mapa: Node2D
var cambiando := false     # durante el fundido no se puede cruzar otra puerta
var latido := 0.0         # cuenta atrás hasta el siguiente latido (con poca vida)
var cerrada := false       # si la puerta del apartamento en el que está se ha cerrado
var jefa: Node2D = null
var jefa_salio := false    # si ya ha aparecido la portera en este apartamento
var captura := false
var tiempo := 0.0
var luz := Luz.new()       # la penumbra (luz.gd)
var menus := MENUS.new()   # la pausa y el cartel del final
var ordenador := ORDENADOR.new()   # la pantalla de ConserjeOS
var lanzables := Lanzables.new()   # el molotov y la granada (lanzables.gd)
var mutaciones := Mutaciones.new() # las mutaciones de esta partida (mutaciones.gd)
var inventario := INVENTARIO.new() # las pantallas del inventario, el baúl y el banco de trabajo
var supervivientes := Supervivientes.new()   # el superviviente de la partida, la horda y los vecinos
var mochila: Array = []    # los objetos recogidos en esta partida (objetos.gd), uno por cada: al baúl si ganas
var armas_guardadas: Array = []   # las armas que lleva sin usar (la que deja al comprar otra cuerpo a cuerpo)
var ahorrados := 0         # los dólares guardados de otras partidas
var dolares := 0           # los recogidos en esta partida
var muertos := 0           # zombis matados en esta partida
var duracion := 0.0        # segundos jugados (sin contar la pausa)
var terminada := false

@onready var johnny := $Johnny
@onready var lugar: Label = $Pantalla/Lugar
@onready var aviso: Label = $Pantalla/Mensaje
@onready var negro: ColorRect = $Pantalla/Negro


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	johnny.modo_cambiado.connect(func(nombre): $Pantalla/Ayuda.text = "Modo: %s (F1 cambia) · Espacio esquivar · 1-6 arma · Q cambiar · R recargar · E/clic dcho. lanzar · F molotov/granada · Tab inventario · Esc pausa · F2-F7 zombis · P portera · M mutación · F9 exposición · F10 luz · H superviviente" % nombre)
	johnny.murio.connect(_al_morir_johnny)
	johnny.resucito.connect(func():
		Sonido.tocar("limpio")
		decir("¡Desfibrilador! Vuelves con toda la vida (solo una vez por edificio)", 3.5))
	johnny.avisar_arma()
	add_child(luz)
	luz.seguir_a(johnny)
	var minimapa := MINIMAPA.new()
	minimapa.name = "Minimapa"
	minimapa.partida = self
	$Pantalla.add_child(minimapa)
	$Pantalla.move_child(minimapa, negro.get_index())   # por debajo del fundido a negro
	var hud := HUD.new()
	hud.name = "HUD"
	hud.johnny = johnny
	hud.partida = self
	$Pantalla.add_child(hud)
	$Pantalla.move_child(hud, minimapa.get_index())
	add_child(menus)
	menus.continuar.connect(seguir)
	menus.abandonar.connect(terminar.bind(false, true))
	menus.reintentar.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	menus.menu_principal.connect(ir_al_menu)
	add_child(ordenador)
	ordenador.apagado.connect(func(): get_tree().paused = false)
	add_child(inventario)
	inventario.cerrado.connect(func(): get_tree().paused = false)
	lanzables.johnny = johnny
	lanzables.partida = self
	add_child(lanzables)
	mutaciones.johnny = johnny
	add_child(mutaciones)
	add_child(supervivientes)
	supervivientes.preparar(self)

	captura = "--captura" in OS.get_cmdline_user_args()
	if captura:
		Guardado.archivo = "user://guardado-prueba.json"   # la prueba no toca el guardado de verdad
	# Empieza una partida: se apunta, y se cuenta con los dólares ahorrados
	var s := Guardado.cambiar(func(g):
		g.partidas += 1
		Guardado.edificio(g, EDIFICIO).partidas += 1)
	ahorrados = s.dolares
	# los talentos comprados, y empieza con la vida llena y el escudo de Acero
	aplicar_talentos(s.talentos)
	johnny.vida = johnny.stats.vida_max
	lanzables.reiniciar(johnny.stats)
	Armas.olvidar_sacadas()   # las armas creadas sacadas del baúl en la partida anterior ya se gastaron
	supervivientes.elegir()
	nueva_planta(1)
	# en la sala de mantenimiento, en medio
	montar(planta.mantenimiento, 0, false)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	if captura:
		contar_planta()
	else:
		set_process(false)
		decir("%s: limpia los apartamentos y busca la llave de la portera" % planta.nombre, 4.0)


func nueva_planta(num: int) -> void:
	planta = Planta.generar(num)
	supervivientes.nueva_planta()
	johnny.escudo = johnny.stats.escudo + johnny.stats.escudo_mut   # Acero y Endurecimiento: escudo nuevo en cada planta


# Los atributos de Johnny con los talentos comprados y las mutaciones de la partida (al empezar, al comprar
# un talento en el ordenador y al elegir una mutación)
func aplicar_talentos(talentos: Dictionary) -> void:
	johnny.poner_stats(Mutaciones.aplicar(Talentos.aplicar(Mejoras.base(), talentos), mutaciones.tengo))


# Tras caer la portera: pausa y dos mutaciones para elegir una (si quedan y no lleva ya 4)
func abrir_mutacion() -> void:
	if terminada or not johnny.vivo or mutaciones.tengo.size() >= Mutaciones.MAXIMO:
		return
	var opciones := mutaciones.sortear()
	if opciones.is_empty():
		return
	# si en ese momento hay otra pantalla abierta (la pausa), se espera a que se cierre
	if get_tree().paused:
		await get_tree().create_timer(0.3, false).timeout
		abrir_mutacion()
		return
	get_tree().paused = true
	menus.mutacion(opciones, mutaciones.tengo.size(), elegir_mutacion)


func elegir_mutacion(id: String) -> void:
	if id in mutaciones.tengo:
		return
	mutaciones.tengo.append(id)
	Sonido.tocar("compra")
	var antes: int = johnny.stats.escudo_mut
	aplicar_talentos(Guardado.cargar().talentos)
	# Endurecimiento: el escudo ya, sin esperar a la siguiente planta
	johnny.escudo += johnny.stats.escudo_mut - antes
	get_tree().paused = false
	Particulas.anillo(johnny, johnny.global_position, 70.0, Color("#b5179e"), 0.5)
	var m := Mutaciones.mutacion(id)
	decir("¡%s!  %s" % [m.nombre, m.desc], 4.0)


# Johnny se ha arrimado a la mesa del ordenador: se pausa el juego y se enciende
func abrir_ordenador() -> void:
	if terminada or cambiando or not johnny.vivo:
		return
	get_tree().paused = true
	ordenador.encender(self)


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
	# navegación y sus muros se mezclarían con los del nuevo). Y con él, los de su equipo
	supervivientes.recoger()
	johnny.get_parent().remove_child(johnny)
	if mapa:
		remove_child(mapa)
		mapa.queue_free()
	jefa = null
	jefa_salio = false
	$Pantalla/Jefa.hide()
	aqui = idx
	var sitio: Dictionary = planta.sitios[idx]
	sitio.visitado = true
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
	if mapa.ordenador:
		mapa.ordenador.usar.connect(abrir_ordenador)
		mapa.baul.usar.connect(abrir_cosas.bind("baul"))
		mapa.banco.usar.connect(abrir_cosas.bind("banco"))
	for armarito in mapa.armaritos:
		armarito.johnny = johnny
		armarito.usar.connect(coger_botiquin.bind(armarito))
	for puerta in mapa.puertas:
		puerta.empujada.connect(cruzar)
	mapa.cosas.add_child(johnny)
	johnny.position = mapa.puertas[por].llegada()
	johnny.velocity = Vector2.ZERO
	supervivientes.al_montar(idx, sitio)
	encuadrar(sitio)
	johnny.get_node("Camara").reset_smoothing()
	luz.poner_sitio(sitio.tipo)

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
			Sonido.tocar("jefe")
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
	lugar.text = texto


# Johnny ha empujado la salida "i" del sitio en el que está
func cruzar(i: int) -> void:
	if cambiando or not johnny.vivo:
		return
	var sitio: Dictionary = planta.sitios[aqui]
	var salida: Dictionary = sitio.salidas[i]
	if sitio.tipo != "pasillo" and cerrada:
		decir("Aguanta: aún está forzando la cerradura" if supervivientes.en_horda() else "La puerta no se abre mientras quede algún zombi")
		Sonido.tocar("no")
		return
	match salida.cerrojo:
		"nunca":
			decir(salida.aviso)
			Sonido.tocar("no")
			return
		"llave":
			if not planta.tiene_llave:
				decir(salida.aviso)
				Sonido.tocar("no")
				return
			# La llave se gasta al abrir: la puerta queda abierta para siempre
			planta.tiene_llave = false
			planta.llave_usada = true
			salida.cerrojo = ""
			decir("Abres con la llave")
			Sonido.tocar("compra")
		"jefa":
			if not planta.jefa_muerta:
				decir(salida.aviso)
				Sonido.tocar("no")
				return
	Sonido.tocar("puerta")
	if salida.tipo == "escaleras":
		subir()
		return
	montar(salida.a, salida.vuelta)


# Por las escaleras, a la planta siguiente (o, después de la última, se acabó)
func subir() -> void:
	if planta.num >= Planta.PLANTAS:
		cambiando = true
		terminar(true)
		return
	nueva_planta(planta.num + 1)
	await montar(0, puerta_de_tipo("llegada"))
	decir(planta.nombre, 2.5)


func _physics_process(delta: float) -> void:
	if not terminada:
		duracion += delta
	if mapa == null or cambiando:
		return
	# Con poca vida (menos del 30 %) se oye el corazón
	latido -= delta
	if johnny.vivo and johnny.vida < johnny.stats.vida_max * 0.3 and latido <= 0.0:
		latido = 0.9
		Sonido.tocar("latido")
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
		Sonido.tocar("portazo")
	elif not quedan:
		sitio.limpio = true
		cerrada = false
		if sitio.tipo == "jefe":
			planta.jefa_muerta = true
			decir("¡La portera ha caído! Las escaleras ya están abiertas", 4.0)
		else:
			decir("¡Piso limpio! La puerta se ha abierto")
		actualizar_puertas()
		Sonido.tocar("limpio")
		get_tree().create_timer(0.25).timeout.connect(Sonido.tocar.bind("puerta"))
		supervivientes.piso_limpio(aqui)


func _al_coger_llave() -> void:
	planta.tiene_llave = true
	Sonido.tocar("compra")
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
	# Un momento para verlo caer, y el cartel de derrota
	await get_tree().create_timer(1.5).timeout
	terminar(false)


# Los dólares que salen en el HUD: los ahorrados más los de esta partida
func cartera() -> int:
	return ahorrados + dolares


# Suelta billetes donde ha caído un zombi
func soltar_billetes(cuantos: int, donde: Vector2) -> void:
	for i in cuantos:
		var billete := BILLETE.new()
		billete.johnny = johnny
		billete.position = donde
		billete.cogido.connect(func():
			dolares += 1
			Sonido.tocar("moneda")
			numero(billete.position, "+$1", Tema.VERDE))
		mapa.cosas.add_child.call_deferred(billete)


# Un molotov o una granada en el suelo: se coge pasando por encima, si cabe en la mochila
func soltar_lanzable(k: String, donde: Vector2) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = ICONOS_LANZABLES[k]
	cosa.tamano = 1.0
	cosa.position = donde
	cosa.puede = lanzables.cabe.bind(k)
	cosa.cogido.connect(func():
		lanzables.sumar(k)
		Sonido.tocar("compra")
		numero(cosa.position, "+1 " + k, Lanzables.COLORES[k]))
	mapa.cosas.add_child.call_deferred(cosa)


# Un objeto para el banco de trabajo en el suelo: se coge pasando por encima, si cabe en la mochila. "tirado":
# lo ha tirado Johnny desde el inventario (no vuelve a la mochila hasta que se aparte)
func soltar_objeto(id: String, donde: Vector2, tirado := false) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = load("res://assets/ui/iconos/obj-%s.png" % id)
	cosa.tamano = 2.4
	cosa.tirado = tirado
	cosa.position = donde
	cosa.puede = func() -> bool: return Objetos.cabe(mochila, id)
	cosa.cogido.connect(func():
		mochila.append(id)
		Sonido.tocar("compra")
		numero(cosa.position, "+1 " + Objetos.nombre(id), Tema.TINTA))
	mapa.cosas.add_child.call_deferred(cosa)


# Un arma tirada desde el inventario: al volver a cogerla, otra vez a las guardadas
func soltar_arma(id: String, donde: Vector2) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = load("res://assets/ui/iconos/%s.png" % Objetos.icono(id))
	cosa.tamano = 1.4
	cosa.tirado = true
	cosa.position = donde
	cosa.cogido.connect(func():
		armas_guardadas.append(id)
		Sonido.tocar("compra")
		numero(cosa.position, Objetos.nombre(id), Tema.TINTA))
	mapa.cosas.add_child.call_deferred(cosa)


# Delante del armarito de un baño: el botiquín cura (más con Sanitario); con la vida llena se deja para luego
func coger_botiquin(armarito: Node2D) -> void:
	var sitio_aviso: Vector2 = armarito.position + Vector2(0, -40)
	if johnny.vida >= johnny.vida_tope():
		numero(sitio_aviso, "Tienes la vida al máximo", Tema.TINTA)
		return
	var cura: int = BOTIQUIN + johnny.stats.botiquin_extra
	johnny.curar(cura)
	armarito.vaciar()
	Sonido.tocar("gema")
	numero(sitio_aviso, "+%d" % cura, Tema.VERDE)
	for i in 12:
		Particulas.soltar(armarito, armarito.global_position + Vector2(0, -50),
			Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0), Tema.VERDE, 4.0, 0.6)


# El inventario (Tab, I o Select), el baúl o el banco de trabajo: se para el juego y sale su pantalla
func abrir_cosas(que: String) -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused:
		return
	get_tree().paused = true
	inventario.abrir(que, self)


# Un texto que sube y se desvanece (al coger un billete)
func numero(donde: Vector2, texto: String, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.theme = Tema.crear()
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.position = donde + Vector2(-14, -50)
	etiqueta.z_index = 50
	mapa.cosas.add_child(etiqueta)
	var tween := etiqueta.create_tween().set_parallel()
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 30, 0.7)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.chain().tween_callback(etiqueta.queue_free)


# Esc o Start: el juego se para y sale el menú de pausa
func pausar() -> void:
	if terminada or not johnny.vivo or menus.abierto != "":
		return
	get_tree().paused = true
	menus.pausa(self)


func seguir() -> void:
	menus.cerrar()
	get_tree().paused = false


# Se acabó la partida (endRun en game.js): se guardan los récords y, si ganas, los dólares. Si se abandona
# desde la pausa, no hay cartel: directo al menú principal
func terminar(gano: bool, abandona := false) -> void:
	if terminada:
		return
	terminada = true
	var record := [false]   # en una lista, para que la función de dentro pueda cambiarlo
	var nuevo := supervivientes.rescatado_nuevo() if gano else {}
	var s := Guardado.cambiar(func(g):
		# el superviviente rescatado en esta partida se viene a vivir a la sala de mantenimiento
		if not nuevo.is_empty() and not nuevo.id in g.rescatados:
			g.rescatados.append(nuevo.id)
		g.mejor_planta = maxi(g.mejor_planta, planta.num)
		g.muertos += muertos
		var e := Guardado.edificio(g, EDIFICIO)
		e.mejor_planta = maxi(e.mejor_planta, planta.num)
		if gano:
			# los objetos de la mochila pasan al baúl (si caes, se pierden)
			for id in mochila:
				g.baul[id] = g.baul.get(id, 0) + 1
			g.dolares += dolares
			g.dolares_total += dolares
			g.victorias += 1
			e.victorias += 1
			e.completado = true
			if e.mejor_tiempo == 0.0 or duracion < e.mejor_tiempo:
				e.mejor_tiempo = duracion
				record[0] = true)
	if abandona:
		ir_al_menu()
		return
	get_tree().paused = true
	$Pantalla/Aviso.hide()
	var apartamentos := 0
	var visitados := 0
	for sitio in planta.sitios:
		if sitio.has("apt"):
			apartamentos += 1
			if sitio.get("visitado", false):
				visitados += 1
	var tiempo := ""
	if gano:
		tiempo = "%d:%02d%s" % [int(duracion) / 60, int(duracion) % 60, " · ¡récord!" if record[0] else ""]
	menus.fin({
		"gano": gano,
		"titulo": "¡Edificio completado!" if gano else "¡Derrota!",
		"sub": ("Has limpiado los %s de arriba abajo%s" % [NOMBRE_EDIFICIO, "" if nuevo.is_empty()
			else ". %s se viene a vivir a la sala de mantenimiento" % nuevo.nombre]) if gano
			else ("Caíste en la %s de los %s" % [planta.nombre.to_lower(), NOMBRE_EDIFICIO]),
		"plantas": "%d / %d" % [Planta.PLANTAS if gano else planta.num - 1, Planta.PLANTAS],
		"muertos": muertos,
		"visitados": "%d / %d" % [visitados, apartamentos],
		"tiempo": tiempo,
		"dolares": dolares,
		"cartera": s.dolares,
	})


func ir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")


# Saca un zombi del tipo que se pida (o la portera) en ese sitio del mapa
func meter_zombi(tipo: String, donde: Vector2) -> Node2D:
	var zombi: Node2D = ZOMBIS[tipo].instantiate()
	zombi.position = donde
	# Al caer: se cuenta, y a veces suelta un billete (la portera, varios)
	zombi.murio.connect(func():
		muertos += 1
		var cuantos := BILLETES_JEFA if tipo == "portera" else (1 if randf() < BILLETE_ZOMBI else 0)
		soltar_billetes(cuantos, zombi.position)
		# a veces, un molotov o una granada
		for k in ["molotov", "granada"]:
			if randf() < Lanzables.DATOS[k].suelta:
				soltar_lanzable(k, zombi.position)
		# y a veces un objeto para el banco de trabajo (la portera, dos seguros)
		if tipo == "portera":
			for i in 2:
				soltar_objeto(Objetos.al_azar(), zombi.position)
		else:
			var obj := Objetos.que_suelta(tipo)
			if obj != "":
				soltar_objeto(obj, zombi.position)
		# Caníbal: cada zombi que matas te cura
		if johnny.stats.canibal > 0.0:
			johnny.curar(maxi(1, roundi(johnny.stats.canibal * johnny.stats.vida_max)))
		# la portera: un poco después de caer su cuerpo, las mutaciones
		if tipo == "portera":
			await get_tree().create_timer(2.0, false).timeout
			abrir_mutacion())
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
	if evento.is_action_pressed("pausa") and not cambiando:
		get_viewport().set_input_as_handled()
		pausar()
		return
	if evento.is_action_pressed("inventario") and not cambiando:
		get_viewport().set_input_as_handled()
		abrir_cosas("inventario")
		return
	if not (evento is InputEventKey and evento.pressed and not evento.echo) or cambiando:
		return
	if evento.keycode in TECLAS:
		meter_zombi(TECLAS[evento.keycode], mapa.punto_libre(johnny.position, 300.0))
	elif evento.keycode == KEY_F9 and planta.expo >= 0 and not cerrada:
		# a la exposición y de vuelta a la sala de mantenimiento
		montar(planta.mantenimiento if aqui == planta.expo else planta.expo, 0)
	elif evento.keycode == KEY_F10:
		luz.alternar()   # quitar o poner la penumbra, para comparar
	elif evento.keycode == KEY_M:
		abrir_mutacion()   # para probar las mutaciones sin matar a la portera
	elif evento.keycode == KEY_H:
		supervivientes.probar_aqui()   # al apartamento del superviviente, ya limpio (para probar la horda)
	elif evento.keycode == KEY_O:
		soltar_objeto(Objetos.al_azar(), johnny.position + Vector2(0, 50))   # un objeto, para probar


# ── Solo con --captura ──

func contar_planta() -> void:
	print("Planta: ", planta.nombre)
	for i in range(1, planta.sitios.size()):
		var s: Dictionary = planta.sitios[i]
		if not s.has("apt"):
			print("  %s [%s]: %d muebles" % [s.nombre, s.tipo, s.muebles.size()])
			continue
		var salas := []
		for sala in s.apt.salas:
			salas.append("%s(%d)" % [sala.nombre, sala.casillas])
		var tipos := {}
		for z in s.zombis:
			tipos[z.tipo] = tipos.get(z.tipo, 0) + 1
		print("  %s [%s] %dx%d casillas: %s | %d muebles | zombis: %s" % [s.nombre, s.tipo, s.apt.cols, s.apt.filas,
			" ".join(salas), s.muebles.size(), tipos])
	print("  pasillo: %d muebles | llave en %s" % [planta.sitios[0].muebles.size(), planta.sitios[planta.llave.sitio].nombre])


func _process(delta: float) -> void:
	tiempo += delta
	var antes := tiempo - delta
	# primero, fotos de la sala de mantenimiento (donde empieza) y de la exposición
	if antes < 0.3 and tiempo >= 0.3:
		get_viewport().get_texture().get_image().save_png("res://captura-mantenimiento.png")
		montar(planta.expo, 0, false)
		johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, 420)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.7 and tiempo >= 0.7:
		get_viewport().get_texture().get_image().save_png("res://captura-expo.png")
	# al segundo, a un apartamento normal (el que tiene más zombis)
	if antes < 1.0 and tiempo >= 1.0:
		var mejor := 1
		for i in range(1, planta.sitios.size()):
			if planta.sitios[i].zombis.size() > planta.sitios[mejor].zombis.size():
				mejor = i
		print("Entra en ", planta.sitios[mejor].nombre)
		montar(mejor, 0, false)
	# el botiquín del baño: herido, delante del armarito
	if antes < 1.1 and tiempo >= 1.1 and not mapa.armaritos.is_empty():
		var a: Node2D = mapa.armaritos[0]
		johnny.vida = 40
		johnny.position = a.position + Vector2(0, 40)
		johnny.get_node("Camara").reset_smoothing()
		$Pantalla/HUD.hide()   # para que se vea la pared de arriba en la foto
	if antes < 1.4 and tiempo >= 1.4:
		var a: Node2D = mapa.armaritos[0] if not mapa.armaritos.is_empty() else null
		print("Armaritos en el piso: %d | vida tras el botiquín: %d | cogido: %s" % [mapa.armaritos.size(), johnny.vida,
			a.datos.cogido if a else "-"])
		get_viewport().get_texture().get_image().save_png("res://captura-botiquin.png")
		$Pantalla/HUD.show()
	# una granada a un lado (explota antes de la foto)
	if antes < 2.0 and tiempo >= 2.0:
		lanzables.cambiar()
		lanzables.lanzar(johnny.global_position + Vector2(-180, 90))
		lanzables.cambiar()
	# un tiro de pistola para despertar a los de cerca
	if antes < 2.5 and tiempo >= 2.5:
		Input.action_press("arma_4")
	if antes < 2.6 and tiempo >= 2.6:
		Input.action_release("arma_4")
		Input.action_press("atacar")
	if antes < 3.2 and tiempo >= 3.2:
		Input.action_release("atacar")
		# un molotov al zombi más cercano (o por delante)
		var prueba := meter_zombi("lento", mapa.punto_libre(johnny.position, 120.0))
		var donde: Vector2 = prueba.global_position
		lanzables.lanzar(donde)
		print("Molotov hacia ", donde, " | quedan ", lanzables.cantidades)
	if antes < 4.2 and tiempo >= 4.2:
		var ardiendo := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("arder_t") != null and z.arder_t > 0.0:
				ardiendo += 1
		print("Charcos: %d | zombis ardiendo: %d | manchas: %d" % [get_tree().get_nodes_in_group("charcos").size(), ardiendo,
			get_tree().get_nodes_in_group("manchas").size()])
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
		probar_menus()


# El ordenador: con $60 en el guardado de prueba compra puntos, sube Ataque, compra la escopeta y hace fotos
func probar_ordenador() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 60
		g.puntos = 0
		g.talentos = {}
		g.armas = [])
	ahorrados = 60
	aplicar_talentos({})
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("puntos")
	ordenador.comprar(3)
	ordenador.subir("ataque")
	ordenador.subir("punteria")
	ordenador.subir("tirador")   # bloqueado: no tiene Ataque al máximo
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-ordenador.png")
	ordenador.abrir("armas")
	ordenador.comprar_arma("escopeta")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-tienda.png")
	var g := Guardado.cargar()
	print("Ordenador: $%d ahorrados, %d puntos, talentos %s, armas %s | daño x%.2f | lleva %s" % [g.dolares, g.puntos,
		g.talentos, g.armas, johnny.stats.dano, johnny.huecos])
	ordenador.abrir("")
	ordenador.apagar()


# La mochila, el banco y el baúl: unos objetos en la mochila y en el baúl, compra el bate (la fregona va al
# inventario), crea un arma y hace fotos
func probar_cosas() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 20
		g.baul = {"clavos": 1, "lejia": 2}
		g.baul_armas = [])
	ahorrados = 20
	mochila = ["gasolina", "gasolina", "cuchillas", "taser", "cuerda"]
	soltar_objeto("mechero", johnny.position + Vector2(30, 0))
	await get_tree().create_timer(0.6).timeout
	abrir_ordenador()
	ordenador.abrir("armas")
	ordenador.comprar_arma("bate")
	ordenador.abrir("")
	ordenador.apagar()
	abrir_cosas("inventario")
	inventario.tocar("m0")
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-inventario.png")
	inventario.cerrar()
	abrir_cosas("banco")
	inventario.tocar("mano")
	inventario.tocar("o_clavos")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-banco.png")
	inventario.crear_arma()
	inventario.tocar("o_gasolina")
	inventario.tocar("o_cuchillas")
	inventario.crear_arma()   # no combinan: no hace nada
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-banco2.png")
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-baul.png")
	inventario.cerrar()
	var g := Guardado.cargar()
	print("Cosas: mochila %s | guardadas %s | mano %s | baúl %s | armas del baúl %s" % [mochila, armas_guardadas,
		johnny.huecos.cuerpo, g.baul, g.baul_armas.map(func(a): return "%s %s %d" % [a.nombre, a.rareza, a.dano])])


# Las armas creadas (fase 7b2): saca cinco del baúl, golpea con la inmovilizadora, lanza el bumerán, se pone
# el desintegrador desde el inventario y dispara, y lanza la congeladora. Cuenta lo que pasa y hace una foto
func probar_creadas() -> void:
	Guardado.cambiar(func(g): g.baul_armas = [Recetas.crear("inmovilizadora", "morada"), Recetas.crear("desintegrador"),
		Recetas.crear("bumeran"), Recetas.crear("congeladora"), Recetas.crear("molotov")])
	var molotovs: int = lanzables.cantidades.molotov
	abrir_cosas("baul")
	for i in 5:
		inventario.tocar("a0")
		inventario.sacar()
	inventario.cerrar()
	print("Creadas sacadas: mano %s | guardadas %s | molotovs %d -> %d | lanzables %s | baúl %d" % [
		[Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego)], armas_guardadas.map(Objetos.nombre),
		molotovs, lanzables.cantidades.molotov, lanzables.tipos(), Guardado.cargar().baul_armas.size()])
	johnny.direccion = "e"
	johnny.sostener("cuerpo")
	var z1 := meter_zombi("lento", johnny.position + Vector2(40, 0))
	var z2 := meter_zombi("lento", johnny.position + Vector2(100, 10))
	z1.vida = 500   # que no muera ninguno (saldría el recuadro de las mutaciones y pararía el juego)
	z2.vida = 500
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	print("Inmovilizadora: zombi 1 aturdido %.1f vida %d | zombi 2 aturdido %.1f vida %d" % [z1.aturdido, z1.vida, z2.aturdido, z2.vida])
	johnny.sostener("fuego")
	johnny.disparar(0.0)
	await get_tree().create_timer(0.3).timeout
	print("Bumerán: balas %d (no gasta) | zombi 1 vida %d | zombi 2 vida %d" % [johnny.balas, z1.vida, z2.vida])
	abrir_cosas("inventario")
	inventario.tocar("g%d" % armas_guardadas.find(armas_guardadas.filter(func(id): return Objetos.nombre(id) == "Desintegrador")[0]))
	inventario.poner_guardada()
	inventario.cerrar()
	for i in 6:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await get_tree().create_timer(0.2).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://captura-creadas.png")
	menus.visible = true
	print("Desintegrador: mano %s balas %d | zombi 2 vida %d heridas %s | charcos %d" % [Objetos.nombre(johnny.huecos.fuego),
		johnny.balas, z2.vida, z2.get_children().filter(func(n): return n.name.begins_with("herida")).map(func(n): return n.name),
		get_tree().get_nodes_in_group("charcos").size()])
	var z3 := meter_zombi("lento", johnny.position + Vector2(-120, 30))
	z3.vida = 500
	lanzables.tipo = "congeladora"
	lanzables.lanzar(z3.global_position)
	await get_tree().create_timer(2.3).timeout
	print("Congeladora: zombi 3 aturdido %.1f vida %d | vida de Johnny %d | quedan %s" % [z3.aturdido, z3.vida, johnny.vida, lanzables.tipos()])


# El recuadro de las mutaciones: foto, elige la primera y comprueba que cambia los atributos
func probar_mutaciones() -> void:
	abrir_mutacion()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-mutacion.png")
	var primera: String = menus.cartas[0].id
	menus.elegir(primera)
	elegir_mutacion("insensible")
	print("Mutaciones: %s | daño recibido x%.2f | pausa %s" % [mutaciones.tengo, johnny.stats.dano_recibido, get_tree().paused])


# Fotos de la pausa y del cartel de victoria (con el juego parado solo cuentan los temporizadores)
func probar_menus() -> void:
	set_process(false)
	soltar_billetes(3, johnny.position + Vector2(60, 0))
	await get_tree().create_timer(1.2).timeout
	print("Dólares de la partida: %d | muertos: %d" % [dolares, muertos])
	await probar_ordenador()
	await probar_cosas()
	await probar_creadas()
	await supervivientes.probar()
	await probar_mutaciones()
	pausar()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-pausa.png")
	seguir()
	terminar(true)
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-fin.png")
	print("Guardado de prueba: ", Guardado.cargar())
	get_tree().quit()
