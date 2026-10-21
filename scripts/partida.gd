# La partida: genera la planta (planta.gd), monta el sitio en el que está Johnny (mapa.gd) y, al cruzar una
# puerta, funde a negro y monta el del otro lado. Lleva también la pantalla (vida, arma, avisos) y las reglas
# del mapa:
#   - Al entrar en un apartamento la puerta se cierra, y no se abre hasta que no queda ni un zombi.
#   - El apartamento de la jefa está cerrado con llave; la llave está en el suelo de otro apartamento.
#   - Al entrar, aparece la portera. Cuando cae, se abren las escaleras a la planta siguiente.
#   - Después de la última planta, el edificio está limpio: cartel de victoria.
# La partida empieza en la sala de mantenimiento de la planta baja. Abajo, en la franja del muro, va el HUD (hud.gd)
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
	"guardia": preload("res://escenas/personajes/zombi_guardia.tscn"),   # el de la tarjeta (centro comercial)
	"vigilante": preload("res://escenas/personajes/zombi_vigilante.tscn"),       # los del centro comercial
	"dependienta": preload("res://escenas/personajes/zombi_dependienta.tscn"),
	"antidisturbios": preload("res://escenas/personajes/antidisturbios.tscn"),   # minijefes del centro comercial
	"cocinero": preload("res://escenas/personajes/cocinero.tscn"),
}
# Los jefes de planta: barra de vida grande, un 25 % más duros en cada planta y, al caer, billetes, munición,
# objetos y la mutación
const JEFES := ["portera", "antidisturbios", "cocinero"]
const MAPA := preload("res://scripts/mapa/mapa.gd")
const MINIMAPA := preload("res://scripts/minimapa.gd")
const TECLAS := {KEY_F2: "normal", KEY_F3: "lento", KEY_F4: "rapido", KEY_F5: "explosivo", KEY_F6: "tentaculos",
	KEY_F7: "venenoso", KEY_V: "vigilante", KEY_B: "dependienta", KEY_P: "portera", KEY_K: "antidisturbios",
	KEY_G: "cocinero"}
const BILLETE := preload("res://scripts/billete.gd")
const HUD := preload("res://scripts/ui/hud.gd")
const AMBIENTE := preload("res://scripts/ui/ambiente.gd")
const MENUS := preload("res://scripts/ui/menus.gd")
const ORDENADOR := preload("res://scripts/ui/ordenador.gd")
const CIENTIFICO := preload("res://scripts/mapa/cientifico.gd")
const INVENTARIO := preload("res://scripts/ui/inventario.gd")
const REFUERZOS := 2               # los vigilantes que llegan al silbato del guardia (y uno más cada dos plantas)
const BILLETES_GUARDIA := 2
const BILLETE_ZOMBI := 0.07        # probabilidad de que un zombi suelte un billete
# La sangre de cada tipo de zombi: el color de su piel (los trozos al reventar) y el de su mancha (del JS)
const PIELES := {"normal": Color("#8fc46a"), "lento": Color("#8fc46a"), "rapido": Color("#9ed36d"),
	"explosivo": Color("#c3d96b"), "tentaculos": Color("#86b8aa"), "venenoso": Color("#b5e655"), "portera": Color("#cbb994"),
	"vigilante": Color("#a6d655"), "dependienta": Color("#93c46a"), "guardia": Color("#a6d655"),
	"antidisturbios": Color("#3b4252"), "cocinero": Color("#8a9a6a")}
const MANCHAS := {"explosivo": Color("#2b2633"), "venenoso": Color("#8fd13f"), "tentaculos": Color("#7b4fa0")}
const SANGRE := Color("#7a1f1a")   # la sangre de los demás: rojo oscuro (antes, verde oliva #5b7d3a)
const MUNICION_ZOMBI := 0.1        # ...o una caja de munición, si no ha soltado otra cosa (provisional en el JS)
const ICONO_MUNICION := preload("res://assets/ui/iconos/municion.png")
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
var guardia: Node2D = null   # el guardia de seguridad, si está en el pasillo en el que está Johnny
# el edificio que se juega (lo elige el menú; su ficha, en edificios.gd)
var edificio: String = Edificios.elegido
var ed: Dictionary = Edificios.datos(edificio)
var jefa_salio := false    # si ya ha aparecido la portera en este apartamento
var orden_jefes: Array = []   # el centro comercial: el minijefe de cada planta, sorteado al empezar (edificios.gd)
var captura := false
var tiempo := 0.0
var luz := Luz.new()       # la penumbra (luz.gd)
var menus := MENUS.new()   # la pausa y el cartel del final
var ordenador := ORDENADOR.new()   # la pantalla de ConserjeOS
var lanzables := Lanzables.new()   # el molotov y la granada (lanzables.gd)
var mutaciones := Mutaciones.new() # las mutaciones de esta partida (mutaciones.gd)
var inventario := INVENTARIO.new() # las pantallas del inventario, el baúl y el banco de trabajo
var supervivientes := Supervivientes.new()   # el superviviente de la partida, la horda y los vecinos
var logros := Logros.new()         # los retos del ordenador (logros.gd)
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
	Controles.aplicar()   # las teclas cambiadas en Opciones (por si se abre la partida directamente)
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	# los textos de la pantalla, con la fuente pixel art de los menús
	for etiqueta in [lugar, aviso, $Pantalla/Ayuda]:
		etiqueta.theme = Tema.crear()
	johnny.modo_cambiado.connect(func(nombre): $Pantalla/Ayuda.text = "Modo: %s (F1 o C cambia) · Espacio esquivar · 1-6 arma · Q cambiar · R recargar · E/clic dcho. lanzar · F molotov/granada · Tab inventario · Esc pausa · F2-F7 zombis · P portera · K antidisturbios · G cocinero · M mutación · F9 exposición · F10 luz · H superviviente" % nombre)
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
	minimapa.theme = Tema.crear()
	$Pantalla.add_child(minimapa)
	$Pantalla.move_child(minimapa, negro.get_index())   # por debajo del fundido a negro
	var hud := HUD.new()
	hud.name = "HUD"
	hud.johnny = johnny
	hud.partida = self
	$Pantalla.add_child(hud)
	$Pantalla.move_child(hud, minimapa.get_index())
	# El viñeteado y la pantalla roja, por debajo de todo lo demás de la pantalla
	var ambiente := AMBIENTE.new()
	ambiente.johnny = johnny
	$Pantalla.add_child(ambiente)
	$Pantalla.move_child(ambiente, 0)
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
	add_child(logros)
	logros.preparar(self)
	# Los controles del móvil (solo salen en pantallas táctiles)
	var tactil := Tactil.new()
	tactil.partida = self
	tactil.johnny = johnny
	add_child(tactil)
	if Tactil.activo:
		$Pantalla/Ayuda.hide()   # las teclas no pintan nada en el móvil

	captura = "--captura" in OS.get_cmdline_user_args()
	if captura:
		Guardado.archivo = "user://guardado-prueba.json"   # la prueba no toca el guardado de verdad
	# Empieza una partida: se apunta, y se cuenta con los dólares ahorrados
	var s := Guardado.cambiar(func(g):
		g.partidas += 1
		Guardado.edificio(g, edificio).partidas += 1)
	ahorrados = s.dolares
	# los talentos comprados, y empieza con la vida llena y el escudo de Acero
	aplicar_talentos(s.talentos)
	johnny.vida = johnny.stats.vida_max
	lanzables.reiniciar(johnny.stats)
	Armas.olvidar_sacadas()   # las armas creadas sacadas del baúl en la partida anterior ya se gastaron
	supervivientes.elegir()
	# los minijefes del centro comercial, uno por planta en orden al azar (sin repetir)
	orden_jefes = ed.get("minijefes", []).duplicate()
	orden_jefes.shuffle()
	# en la prueba, el jefe que se ve es el de la 1ª planta (la segunda): que sea el antidisturbios, u otro
	# con "--jefe cocinero"
	var args := OS.get_cmdline_user_args()
	var cual := args.find("--jefe")
	var probar: String = args[cual + 1] if cual >= 0 and cual + 1 < args.size() else "antidisturbios"
	if captura and probar in orden_jefes:
		orden_jefes.erase(probar)
		orden_jefes.insert(1, probar)
	nueva_planta(1)
	# en la sala de mantenimiento, en medio
	montar(planta.mantenimiento, 0, false)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	if captura and "--fotos-tiendas" in OS.get_cmdline_user_args():
		fotos_tiendas()
	elif captura:
		contar_planta()
	else:
		set_process(false)
		decir("%s: %s" % [planta.nombre, ed.objetivo], 4.0)
		if not Historia.noticias_nuevas(s).is_empty():
			get_tree().create_timer(4.8, false).timeout.connect(avisar_noticias)


func nueva_planta(num: int) -> void:
	planta = Planta.generar(num, edificio, jefe_de(num))
	supervivientes.nueva_planta()
	logros.planta_nueva()
	johnny.escudo = johnny.stats.escudo + johnny.stats.escudo_mut   # Acero y Endurecimiento: escudo nuevo en cada planta


# El minijefe de la planta "num" (centro comercial): el que le tocó en el sorteo, si ya está hecho (tiene su
# escena en ZOMBIS); si no, "" (el jefe del edificio: la portera)
func jefe_de(num: int) -> String:
	if num > orden_jefes.size() or not ZOMBIS.has(orden_jefes[num - 1]):
		return ""
	return orden_jefes[num - 1]


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
	guardar_guardia()
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
	mapa.montar(sitio, llave, ed.cerrojo == "tarjeta")
	mapa.llave_cogida.connect(_al_coger_llave)
	if mapa.ordenador:
		mapa.ordenador.usar.connect(abrir_ordenador)
		mapa.baul.usar.connect(abrir_cosas.bind("baul"))
		mapa.banco.usar.connect(abrir_cosas.bind("banco"))
		# al volver a la sala de mantenimiento (al empezar ya avisa _ready)
		if fundir and not captura and not Historia.noticias_nuevas(Guardado.cargar()).is_empty():
			avisar_noticias()
	for armarito in mapa.armaritos:
		armarito.johnny = johnny
		armarito.usar.connect(coger_botiquin.bind(armarito))
	poner_cientifico(idx)
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
	if sitio.tipo == "pasillo" and planta.get("guardia", {}).get("vivo", false):
		poner_guardia()
	cerrada = false
	actualizar_puertas()
	poner_lugar()
	if fundir:
		await create_tween().tween_property(negro, "modulate:a", 0.0, FUNDIDO).finished
	cambiando = false
	Sonido.musica("jefe" if sitio.tipo == "jefe" and not sitio.limpio else "explorar")
	# En el apartamento de la jefa, aparece ella (si aún no ha caído)
	if sitio.tipo == "jefe" and not sitio.limpio:
		await get_tree().create_timer(0.6).timeout
		if aqui == idx and not jefa_salio:
			jefa_salio = true
			Sonido.tocar("jefe")
			jefa = meter_zombi(planta.jefe, mapa.punto_libre(johnny.position, 380.0))


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
	if zona != "" and zona != sitio.nombre:   # (la tienda de un minijefe y su sala se llaman igual)
		texto += " · " + zona
	lugar.text = texto


# Johnny ha empujado la salida "i" del sitio en el que está
func cruzar(i: int) -> void:
	if cambiando or not johnny.vivo:
		return
	var sitio: Dictionary = planta.sitios[aqui]
	var salida: Dictionary = sitio.salidas[i]
	var arreglo := supervivientes.averia.no_cruzar()   # el técnico, que no se va sin arreglar el cable
	if arreglo != "":
		decir(arreglo)
		Sonido.tocar("no")
		return
	if sitio.tipo != "pasillo" and cerrada:
		decir("Aguanta: aún está forzando la cerradura" if supervivientes.en_horda() else "La puerta no se abre mientras quede algún zombi")
		Sonido.tocar("no")
		return
	var espera := supervivientes.escolta.no_cruzar()   # la farmacéutica herida, lejos o en el suelo
	if espera != "":
		decir(espera)
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
			decir("Abres con la tarjeta de acceso" if ed.cerrojo == "tarjeta" else "Abres con la llave")
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
	logros.planta_pasada()
	if planta.num >= Planta.PLANTAS:
		cambiando = true
		terminar(true)
		return
	nueva_planta(planta.num + 1)
	await montar(0, puerta_de_tipo("llegada"))
	decir(planta.nombre, 2.5)
	if planta.num >= 3:
		logros.cumplir("sube_conserje")


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
			Sonido.musica("explorar")
			decir("¡%s ha caído! Las escaleras ya están abiertas" % (planta.el_jefe.left(1).to_upper() + planta.el_jefe.substr(1)), 4.0)
			logros.cumplir("desahucio")
		else:
			decir("¡Piso limpio! La puerta se ha abierto")
			logros.cumplir("primer_turno")
		actualizar_puertas()
		Sonido.tocar("limpio")
		get_tree().create_timer(0.25).timeout.connect(Sonido.tocar.bind("puerta"))
		supervivientes.piso_limpio(aqui)


# El científico muerto de esta planta, si está en este sitio y su página falta por encontrar (historia.gd). Si
# ya se encontró en otra partida, no sale: la historia no se repite
func poner_cientifico(idx: int) -> void:
	var c: Dictionary = planta.get("cientifico", {})
	if c.is_empty() or c.sitio != idx:
		return
	var pagina := Historia.pendiente(Guardado.cargar(), edificio, planta.num)
	if pagina.is_empty() and not c.cogida:
		return
	var cuerpo := CIENTIFICO.new()
	cuerpo.montar(pagina if not pagina.is_empty() else c.pagina, c.pos)
	cuerpo.johnny = johnny
	cuerpo.mapa = mapa
	cuerpo.zona = mapa.zona_en(c.pos)
	mapa.cosas.add_child(cuerpo)
	if c.cogida:
		cuerpo.vaciar()
	else:
		cuerpo.cogida.connect(_al_coger_pagina.bind(pagina))


func _al_coger_pagina(p: Dictionary) -> void:
	planta.cientifico.cogida = true
	planta.cientifico.pagina = p
	leer_pagina(p)


# La página que suelta el jefe del edificio al caer, si aún falta (historia.gd, del_jefe): en el centro comercial,
# la orden de recogida. La llamará el gerente al morir en la azotea (trozo 6 de la parte 4)
func pagina_del_jefe() -> void:
	var p := Historia.del_jefe(Guardado.cargar(), edificio)
	if not p.is_empty():
		leer_pagina(p)


# Apunta la página para siempre y la enseña con el juego parado; al cerrarla, avisa si trae noticias
func leer_pagina(p: Dictionary) -> void:
	Historia.apuntar(p.id)
	Sonido.tocar("compra")
	var paginas: Array = Historia.dosier(edificio).paginas
	get_tree().paused = true
	menus.pagina(p, paginas.find(p) + 1, paginas.size(), func():
		get_tree().paused = false
		if Historia.NOTICIAS.any(func(n): return n.pagina == p.id):
			avisar_noticias())


# Hay alguna emisión de Canal 8 sin ver en el programa Noticias del ordenador (historia.gd)
func avisar_noticias() -> void:
	if not terminada:
		decir("Hay noticias nuevas en el ordenador", 3.5)


func _al_coger_llave() -> void:
	planta.tiene_llave = true
	Sonido.tocar("compra")
	if ed.cerrojo == "tarjeta":
		var tienda: String = Edificios.MINIJEFES.get(planta.jefe, {}).get("la_tienda", "la tienda de " + planta.el_jefe)
		decir("Has cogido la tarjeta de acceso: abre " + tienda, 3.0)
	else:
		decir("Has cogido la llave del " + nombre_jefa(), 3.0)


# ── El guardia de seguridad (centro comercial): lleva la tarjeta y ronda el pasillo ──

# Lo saca en el pasillo, lejos de la puerta por la que llega Johnny, con la vida que le quedara
func poner_guardia() -> void:
	var g: Dictionary = planta.guardia
	var sitio: Dictionary = planta.sitios[aqui]
	var puntas := [Vector2(Planta.MURO + 70, sitio.alto / 2.0), Vector2(sitio.ancho - Planta.MURO - 70, sitio.alto / 2.0)]
	guardia = meter_zombi("guardia", mapa.punto_libre(johnny.position, 500.0))
	guardia.vida_max = int(guardia.vida_max * (1.0 + 0.2 * (planta.num - 1)))   # cada planta, algo más duro
	guardia.vida = guardia.vida_max if g.vida < 0 else g.vida
	guardia.puntas = puntas
	guardia.alerta = g.alerta
	guardia.silbidos = g.silbidos
	guardia.silbato.connect(_al_silbar)


# Al salir del pasillo, se apunta cómo estaba (si vuelves, sigue igual de herido y de alerta)
func guardar_guardia() -> void:
	if guardia and is_instance_valid(guardia) and guardia.estado != "muerto":
		planta.guardia.vida = guardia.vida
		planta.guardia.alerta = guardia.alerta
		planta.guardia.silbidos = guardia.silbidos
	guardia = null


# El silbato: llegan refuerzos corriendo por las dos puntas del pasillo
func _al_silbar() -> void:
	decir("¡El guardia ha tocado el silbato: vienen refuerzos!", 2.5)
	var sitio: Dictionary = planta.sitios[aqui]
	for i in REFUERZOS + planta.num / 2:
		var x: float = Planta.MURO + 50 if i % 2 == 0 else sitio.ancho - Planta.MURO - 50
		var donde := Vector2(x, sitio.alto / 2.0 + randf_range(-60, 60))
		if donde.distance_to(johnny.position) < 250.0:
			donde.x = sitio.ancho - donde.x   # no encima de Johnny: por la otra punta
		meter_zombi("vigilante", donde)


# Ha caído: suelta la tarjeta donde estaba (se queda en el suelo del pasillo hasta que Johnny la coja)
func _al_caer_guardia(zombi: Node2D) -> void:
	planta.guardia.vivo = false
	planta.llave = {"sitio": aqui, "pos": zombi.position}
	mapa.call_deferred("poner_llave", zombi.position, true)
	decir("¡El guardia ha caído! Ha soltado la tarjeta de acceso", 3.0)


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


# Una caja de munición: un cargador más para el arma de fuego. Va hacia Johnny solo si le cabe
func soltar_municion(donde: Vector2) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = ICONO_MUNICION
	cosa.tamano = 2.0
	cosa.position = donde
	cosa.puede = johnny.quiere_municion
	cosa.cogido.connect(func():
		johnny.sumar_municion()
		Sonido.tocar("recargado")
		numero(cosa.position, "+munición", Color("#ffd23f")))
	mapa.cosas.add_child.call_deferred(cosa)


# Un objeto para el banco de trabajo en el suelo: se coge pasando por encima, si cabe en la mochila. "tirado":
# lo ha tirado Johnny desde el inventario (no vuelve a la mochila hasta que se aparte)
func soltar_objeto(id: String, donde: Vector2, tirado := false) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = load("res://assets/ui/iconos/obj-%s.png" % id)
	cosa.tamano = 2.0   # 16×16: cada píxel del dibujo, 2 unidades (como todo el pixel art)
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
	if gano:
		logros.cumplir("fin_jornada")
	if abandona:
		Sonido.musica("")
	else:
		Sonido.jingle(gano)
	var record := [false]   # en una lista, para que la función de dentro pueda cambiarlo
	var nuevo := supervivientes.rescatado_nuevo() if gano else {}
	var s := Guardado.cambiar(func(g):
		# el superviviente rescatado en esta partida se viene a vivir a la sala de mantenimiento
		if not nuevo.is_empty() and not nuevo.id in g.rescatados:
			g.rescatados.append(nuevo.id)
		g.mejor_planta = maxi(g.mejor_planta, planta.num)
		g.muertos += muertos
		var e := Guardado.edificio(g, edificio)
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
		"sub": ("Has limpiado %s de arriba abajo%s" % [ed.el_nombre, "" if nuevo.is_empty()
			else ". %s se viene a vivir a la sala de mantenimiento" % nuevo.nombre]) if gano
			else ("Caíste en la %s de %s" % [planta.nombre.to_lower(), ed.el_nombre]),
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


# Al caer un zombi: revienta en trozos de su color y deja su mancha en el suelo (killEnemy y addDecal del JS).
# El explosivo ya tiene su explosión: sus trozos salen color fuego y sin anillo
# Si muere a golpes o a tiros (no quemado ni por los charcos), deja además un charco que se va extendiendo
func sangre(tipo: String, zombi: Node2D) -> void:
	var trozos: Color = Color("#ff9f1c") if tipo == "explosivo" else PIELES.get(tipo, PIELES.normal)
	var color: Color = MANCHAS.get(tipo, SANGRE)
	Particulas.reventon(zombi, zombi.global_position, trozos, 12, zombi.radio, tipo != "explosivo", color, zombi.get_parent())
	var jefa := tipo in JEFES
	# el temblor al matar (y, a la portera, el golpe final: tiembla mucho y el juego se para un instante)
	if jefa:
		Temblor.temblar(20.0)
		Temblor.parar(0.35)
	else:
		Temblor.temblar(3.0)
	var donde := zombi.position + Vector2(0, 10)
	if tipo != "explosivo" and (jefa or zombi.get("a_golpes")):
		Mancha.charco(zombi.get_parent(), donde, randf_range(48.0, 58.0) * (1.5 if jefa else 1.0), color)
	else:
		Mancha.sangre(zombi.get_parent(), donde, randf_range(14.0, 20.0) * (1.8 if jefa else 1.0), color)


# Saca un zombi del tipo que se pida (o la portera) en ese sitio del mapa
func meter_zombi(tipo: String, donde: Vector2) -> Node2D:
	var zombi: Node2D = ZOMBIS[tipo].instantiate()
	zombi.position = donde
	if "color_sangre" in zombi:
		zombi.color_sangre = MANCHAS.get(tipo, SANGRE)
	if "talla_restos" in zombi:
		zombi.talla_restos = {"rapido": "pequeno", "venenoso": "grande"}.get(tipo, "mediano")   # el rápido es un niño
	# Al caer: se cuenta, y a veces suelta un billete (la portera, varios)
	if zombi.has_signal("prendido"):   # la portera no arde
		zombi.prendido.connect(logros.zombi_prendido)
	zombi.murio.connect(func():
		muertos += 1
		var ardia: bool = zombi.get("arder_t") != null and zombi.arder_t > 0.0
		logros.zombi_muerto(johnny.huecos[johnny.mano] == "fregona" and not ardia)
		sangre(tipo, zombi)
		if tipo == "guardia":
			_al_caer_guardia(zombi)
		var cuantos := BILLETES_JEFA if tipo in JEFES else BILLETES_GUARDIA if tipo == "guardia" else (1 if randf() < BILLETE_ZOMBI else 0)
		soltar_billetes(cuantos, zombi.position)
		# a veces, un molotov o una granada
		var soltado := cuantos > 0
		for k in ["molotov", "granada"]:
			if randf() < Lanzables.DATOS[k].suelta:
				soltar_lanzable(k, zombi.position)
				soltado = true
		# o una caja de munición (la portera, dos seguras)
		if tipo in JEFES:
			for i in 2:
				soltar_municion(zombi.position)
		elif not soltado and randf() < MUNICION_ZOMBI:
			soltar_municion(zombi.position)
		# y a veces un objeto para el banco de trabajo (los jefes, dos seguros), de los que salen aquí
		var tienda: String = planta.sitios[aqui].get("tienda", "")
		if tipo in JEFES:
			for i in 2:
				soltar_objeto(Objetos.al_azar(edificio, tienda), zombi.position)
		else:
			var obj := Objetos.que_suelta(tipo, edificio, tienda)
			if obj != "":
				soltar_objeto(obj, zombi.position)
		# Caníbal: cada zombi que matas te cura
		if johnny.stats.canibal > 0.0:
			johnny.curar(maxi(1, roundi(johnny.stats.canibal * johnny.stats.vida_max)))
		# la portera: un poco después de caer su cuerpo, las mutaciones
		if tipo in JEFES:
			await get_tree().create_timer(2.0, false).timeout
			abrir_mutacion())
	if tipo in JEFES:
		# Cada planta, un 25 % más dura (como el vecino del juego JS)
		zombi.vida_max = int(zombi.vida_max * pow(1.25, planta.num - 1))
		# Su barra de vida grande, arriba, y los vecinos que llama
		var barra_jefa: ProgressBar = $Pantalla/Jefa
		var el: String = Edificios.MINIJEFES.get(tipo, {}).get("el", "la portera")
		$Pantalla/Jefa/Nombre.text = el.left(1).to_upper() + el.substr(1)
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
		soltar_objeto(Objetos.al_azar(edificio, planta.sitios[aqui].get("tienda", "")), johnny.position + Vector2(0, 50))   # un objeto, para probar
	elif evento.keycode == KEY_U:
		dar_objetos()   # uno de cada objeto al baúl, para probar las recetas en el banco de trabajo


# Tecla U: mete en el baúl uno de cada objeto (de los dos edificios), para probar todas las recetas
func dar_objetos() -> void:
	Guardado.cambiar(func(g):
		for id in Objetos.NOMBRES:
			g.baul[id] = g.baul.get(id, 0) + 1)
	decir("Uno de cada objeto, al baúl")


# ── Solo con --captura ──

# Con "-- --captura --edificio centro --fotos-tiendas": sin penumbra y con todo descubierto, una foto de la sala de
# venta de cada tienda de las dos primeras plantas (captura-tienda-<tipo>.png) y otra de la galería, y se cierra.
# Además, la primera vez que sale cada peligro, sus fotos (fotos_peligros)
func fotos_tiendas() -> void:
	set_process(false)
	luz.alternar()
	for num in [1, 2]:
		if num > 1:
			nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if s.get("tienda", "") == "":
				continue
			montar(i, 0, false)
			for sala in s.apt.salas:
				mapa.vistas[sala.id] = true
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			var venta: Dictionary = s.apt.salas[0]
			johnny.position = Vector2(venta.c0 + venta.ancho / 2.0, venta.f0 + venta.fondo / 2.0) * 32.0
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(0.8).timeout
			var nombre: String = "jefe" if s.tipo == "jefe" else s.tienda
			get_viewport().get_texture().get_image().save_png("res://captura-tienda-%s.png" % nombre)
			var cuenta := {}
			for z in s.zombis:
				cuenta[z.tipo] = cuenta.get(z.tipo, 0) + 1
			print("Foto: ", s.nombre, " (", nombre, ") | zombis: ", cuenta)
			if not grito_visto and s.tipo != "jefe":
				grito_visto = true
				await foto_grito()
			await fotos_peligros(s)
		montar(0, 0, false)
		johnny.position = Vector2(planta.sitios[0].ancho / 2.0, planta.sitios[0].alto / 2.0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png("res://captura-galeria-%d.png" % num)
	# los peligros que no hayan salido en esas dos plantas (las tiendas cambian en cada partida), en las siguientes
	for num in range(3, 9):
		if peligros_vistos.size() >= 3:
			break
		nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if not s.get("peligros", []).any(func(d): return not peligros_vistos.has(d.tipo)):
				continue
			montar(i, 0, false)
			for sala in s.apt.salas:
				mapa.vistas[sala.id] = true
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			await fotos_peligros(s)
	get_tree().quit()


# La dependienta (zombi_dependienta.gd): dormida delante de Johnny, se despierta, grita «¡OFERTAS!», despierta a los
# vigilantes dormidos de al lado y les mete prisa (captura-grito.png); luego, los nuevos de cerca (captura-nuevos.png)
var grito_visto := false

func foto_grito() -> void:
	var dep := meter_zombi("dependienta", johnny.position + Vector2(120, 0))
	dep.dormido = true
	var otros := []
	for i in 3:
		var v := meter_zombi("vigilante", johnny.position + Vector2(-140 + i * 90, 110))
		v.dormido = true
		otros.append(v)
	# se despierta sola al ver a Johnny (en la misma sala) y grita enseguida
	await get_tree().create_timer(0.25).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-grito.png")
	print("Grito: estado %s | despiertos %d/3 | prisa %s | velocidad máxima %s" % [dep.estado,
		otros.filter(func(o): return not o.dormido).size(), otros.map(func(o): return snappedf(o.prisa, 0.1)),
		otros.map(func(o): return o.agente.max_speed)])
	await get_tree().create_timer(2.0).timeout
	print("Dependienta a %d de Johnny (se aparta) | estado %s" % [dep.global_position.distance_to(johnny.global_position), dep.estado])
	get_viewport().get_texture().get_image().save_png("res://captura-nuevos.png")
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().process_frame


# Las fotos de los peligros (peligros.gd), con la penumbra puesta y unos zombis despiertos dentro:
#   captura-peligro-frio.png     Johnny dentro de la cámara (escarcha en la pantalla) y los zombis, congelándose
#   captura-peligro-fuego.png    desde la puerta de la cocina, con zombis ardiendo
#   captura-peligro-agua.png     en pleno calambrazo, con zombis en el agua
#   captura-peligro-sin-luz.png  después de bajar la palanca (la tienda a oscuras)
#   captura-peligro-cuadro.png   delante del cuadro eléctrico (que la vuelve a subir)
var peligros_vistos := {}

func fotos_peligros(s: Dictionary) -> void:
	for nodo in mapa.peligros:
		var d: Dictionary = nodo.datos
		if peligros_vistos.has(d.tipo):
			continue
		peligros_vistos[d.tipo] = true
		luz.alternar()
		luz.poner_sitio(s.tipo)
		var sala: Dictionary = s.apt.salas[d.sala]
		var donde: Vector2 = sala.centro
		var zombis := []
		match d.tipo:
			"frio":
				var dentro := Rect2(sala.c0 * 32.0, sala.f0 * 32.0, sala.ancho * 32.0, sala.fondo * 32.0).grow(-24.0)
				for k in [Vector2(-70, -30), Vector2(70, -20), Vector2(0, 50)]:
					zombis.append((sala.centro + k).clamp(dentro.position, dentro.end))
			"fuego":
				var puerta: Dictionary = s.apt.puertas.filter(func(p): return (p.a == d.sala or p.b == d.sala) and (p.a == 0 or p.b == 0))[0]
				donde = Peligros.centro(Peligros.al_lado_de(s.apt, puerta, d.sala)) + Vector2(16, 0)
				for c in d.arde.keys().filter(func(c): return not c in d.focos).slice(0, 3):
					zombis.append(Peligros.centro(c))
			"agua":
				for c in d.casillas:
					for v in Peligros.LADOS:
						if not c + v in d.casillas and Peligros.dueno(s.apt, c.x + v.x, c.y + v.y) == 0 and not Peligros.bajo_mueble(s, c + v):
							donde = Peligros.centro(c + v)
				var lista: Array = d.casillas.duplicate()
				lista.shuffle()
				for c in lista.slice(0, 3):
					zombis.append(Peligros.centro(c))
		johnny.position = donde
		johnny.get_node("Camara").reset_smoothing()
		for p in zombis:
			var zombi := meter_zombi("normal", p)
			zombi.vida = 300   # para que aguanten hasta la foto
		await get_tree().create_timer(4.6 if d.tipo == "frio" else 1.5).timeout
		if d.tipo == "agua":
			# la foto, en pleno calambrazo
			for i in 60:
				if nodo.destello > 0.12:
					break
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://captura-peligro-%s.png" % d.tipo)
		var vivos: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.estado != "muerto")
		print("Peligro %s en %s: Johnny %d de vida | zombis vivos %d (vida %s) | congelados %d | ardiendo %d" % [d.tipo, s.nombre,
			johnny.vida, vivos.size(), vivos.map(func(z): return z.vida), vivos.filter(func(z): return z.congelado > 0.0).size(),
			vivos.filter(func(z): return z.arder_t > 0.0).size()])
		if d.tipo == "fuego":
			print("  arden %d casillas de %d (tope %d), quemadas %d" % [d.arde.size(), d.casillas.size(), d.tope, d.quemadas.size()])
		if d.tipo == "agua":
			nodo.cambiar_corriente()
			await get_tree().create_timer(1.2).timeout
			get_viewport().get_texture().get_image().save_png("res://captura-peligro-sin-luz.png")
			print("  sin corriente: oscuridad %.2f | corriente %s" % [Luz.nivel, d.corriente])
			johnny.position = Vector2(d.cuadro.x, d.cuadro.y + 40.0)
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(1.2).timeout
			get_viewport().get_texture().get_image().save_png("res://captura-peligro-cuadro.png")
			print("  delante del cuadro: corriente %s | oscuridad %.2f" % [d.corriente, Luz.nivel])
		for z in get_tree().get_nodes_in_group("zombis"):
			z.queue_free()
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
		johnny.estados.clear()
		luz.alternar()
		luz.poner_sitio(s.tipo)


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
	print("  pasillo: %d muebles | llave en %s" % [planta.sitios[0].muebles.size(),
		planta.sitios[planta.llave.sitio].nombre if planta.llave.sitio >= 0 else "el guardia del pasillo"])


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
		# y las últimas filas de zombis (los del centro comercial, la portera y los minijefes): captura-expo-zombis.png
		var filas := []
		for s in mapa.expo_sprites:
			if s.position.y not in filas:
				filas.append(s.position.y)
		filas.sort()
		johnny.position = Vector2(560, filas[-1] - 140.0)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.9 and tiempo >= 0.9:
		get_viewport().get_texture().get_image().save_png("res://captura-expo-zombis.png")
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
	# poca vida: la pantalla roja y la barra con lo perdido en claro (luego se le devuelve la vida)
	if antes < 1.45 and tiempo >= 1.45:
		johnny.quitar_vida(johnny.vida - 18)
	if antes < 1.6 and tiempo >= 1.6:
		get_viewport().get_texture().get_image().save_png("res://captura-poca-vida.png")
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
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
	# las trazadoras (normal, perdigón y crítica), quietas al lado de Johnny para la foto
	if antes < 2.65 and tiempo >= 2.65:
		for i in 3:
			var bala := preload("res://escenas/armas/bala.tscn").instantiate()
			bala.velocidad = Vector2.from_angle(-0.4 + i * 0.4) * 600.0
			bala.radio = 3.0 if i == 1 else 4.0
			bala.critico = i == 2
			bala.altura = 22.0
			bala.set_physics_process(false)
			bala.name = "BalaFoto%d" % i
			johnny.get_parent().add_child(bala)
			bala.global_position = johnny.global_position + Vector2(-70 + i * 50, 30)
	if antes < 2.7 and tiempo >= 2.7:
		get_viewport().get_texture().get_image().save_png("res://captura-balas.png")
		for n in johnny.get_parent().get_children():
			if n.name.begins_with("BalaFoto"):
				n.queue_free()
	if antes < 3.2 and tiempo >= 3.2:
		Input.action_release("atacar")
		# un molotov al zombi más cercano (o por delante)
		var prueba := meter_zombi("lento", mapa.punto_libre(johnny.position, 120.0))
		var donde: Vector2 = prueba.global_position
		lanzables.lanzar(donde)
		print("Molotov hacia ", donde, " | quedan ", lanzables.cantidades)
		# un zombi que cae al lado de Johnny: revienta y deja su mancha
		var muerto := meter_zombi("normal", johnny.position + Vector2(-60, 40))
		muerto.recibir_golpe(999, Vector2.ZERO)
		# y dos que mueren ardiendo: uno se queda en brasas y al otro se le adelanta el reloj hasta los huesos
		for i in 2:
			var quemado := meter_zombi("normal", johnny.position + Vector2(-90 + i * 130, 10))
			quemado.name = "QuemadoFoto%d" % i
			quemado.prender()
			quemado.recibir_golpe(999, Vector2.ZERO)
	if antes < 4.3 and tiempo >= 4.3:
		for i in 2:
			var cuerpo: Node = mapa.cosas.get_node_or_null("QuemadoFoto%d" % i)
			if cuerpo:
				var q: Quemado = cuerpo.get_children().filter(func(n): return n is Quemado)[0]
				q.t = q.caida + 3.0 if i == 0 else 99.0   # uno en brasas y humo; el otro, ya en huesos
	if antes < 4.4 and tiempo >= 4.4:
		get_viewport().get_texture().get_image().save_png("res://captura-quemado.png")
	if antes < 3.35 and tiempo >= 3.35:
		get_viewport().get_texture().get_image().save_png("res://captura-sangre.png")
		# las balas: sin ninguna, a la de cuerpo a cuerpo; una caja de munición devuelve la de fuego y recarga
		var antes_balas := "%s %d +%d" % [johnny.huecos.fuego, johnny.balas, johnny.reserva]
		johnny.balas = 0
		johnny.reserva = 0
		johnny.sostener("fuego")
		johnny.lista_para_disparar()
		var sin: String = johnny.mano
		johnny.sumar_municion()
		print("Balas: %s | sin balas pasa a %s | con una caja: %s %d +%d recargando %s" % [antes_balas, sin,
			johnny.mano, johnny.balas, johnny.reserva, johnny.recargando > 0.0])
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
	# en el centro comercial, el guardia: Johnny se le acerca (silbato y refuerzos), foto, y cae con su tarjeta
	if antes < 5.35 and tiempo >= 5.35 and guardia:
		johnny.position = mapa.punto_libre(guardia.position, 0.0)
		for i in 60:
			var p: Vector2 = guardia.position + Vector2.from_angle(randf() * TAU) * 220.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
	if antes < 5.5 and tiempo >= 5.5 and guardia:
		print("Guardia: vida %d/%d | alerta %s | silbidos %d | zombis en el pasillo %d" % [guardia.vida, guardia.vida_max,
			guardia.alerta, guardia.silbidos, get_tree().get_nodes_in_group("zombis").size()])
		get_viewport().get_texture().get_image().save_png("res://captura-guardia.png")
		guardia.recibir_golpe(99999, Vector2.ZERO)
	if antes < 5.6 and tiempo >= 5.6:
		if planta.has("guardia"):
			print("Tarjeta: en el sitio %d, en %s | guardia vivo: %s" % [planta.llave.sitio, planta.llave.pos, planta.guardia.vivo])
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
	if antes < 7.7 and tiempo >= 7.7 and jefa:
		# Johnny, delante del jefe (para que salga en la foto)
		for i in 60:
			var p: Vector2 = jefa.position + Vector2.from_angle(jefa.mirada.angle() + randf_range(-0.7, 0.7)) * 230.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
		if jefa is Minijefe:
			jefa.mirada = (johnny.position - jefa.position).normalized()
		if jefa.has_method("lluvia"):
			probar_cocinero()
		if jefa.has_method("estrellarse"):
			# el antidisturbios. El escudo: un golpe de 10 por delante, de lado, por la espalda y de una explosión
			# (la fuerza va hacia donde empuja el golpe: el de delante empuja hacia atrás)
			var m: Vector2 = jefa.mirada
			var quita := []
			for golpe in [[-m, false], [m.orthogonal(), false], [m, false], [m, true]]:
				var antes_vida: int = jefa.vida
				jefa.recibir_golpe(10, golpe[0] * 300.0, golpe[1])
				quita.append(antes_vida - jefa.vida)
			print("Escudo (golpes de 10): de frente -%d, de lado -%d, por la espalda -%d, explosión -%d" % quita)
			jefa.cambiar("aviso_carga", {"quedan": 1, "aviso": 0.8})   # que salga en la foto preparando la carga
	if antes < 8.0 and tiempo >= 8.0 and jefa:
		get_viewport().get_texture().get_image().save_png("res://captura-jefe.png")
	if antes < 8.05 and tiempo >= 8.05:
		print("El jefe (%s) ha salido en '%s': %s | vida %d | puerta %s" % [planta.jefe, planta.sitios[aqui].nombre,
			jefa != null, jefa.vida_max if jefa else 0, "cerrada" if cerrada else "abierta"])
		if jefa:
			jefa.recibir_golpe(99999, Vector2.ZERO)
	if antes < 9.5 and tiempo >= 9.5:
		print("Jefa muerta: ", planta.jefa_muerta, " | ", aviso.text)
		probar_menus()


# El cocinero, para la foto del jefe: un charco de aceite debajo de él (no le quema) y otro debajo de Johnny,
# unos cuchillos ya clavados, la lluvia marcando el suelo y el abanico recién lanzado
func probar_cocinero() -> void:
	var antes_johnny: int = johnny.vida
	# que nadie le dispare mientras tanto (ni Johnny solo, ni el superviviente que le acompaña): así se ve lo que
	# le quita su aceite
	var modo: String = johnny.modo
	johnny.modo = "mira"
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_DISABLED
	for donde in [jefa.position, johnny.position]:
		var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = "hirviendo"
		charco.dueno = jefa
		charco.position = donde
		mapa.cosas.add_child(charco)
	for i in 3:
		var c := Cuchillo.new()
		c.modo = "cae"
		c.aviso = 0.05
		c.position = jefa.position.lerp(johnny.position, 0.5) + Vector2((i - 1) * 50.0, 50.0)
		mapa.cosas.add_child(c)
	jefa.lluvia(johnny)
	jefa.empezar("aviso_abanico", (johnny.position - jefa.position).angle())
	jefa.t = 0.3   # el aviso ya casi acabado: en la foto acaba de lanzar el abanico
	await get_tree().create_timer(0.1, false).timeout   # (las balas que ya volaban, que lleguen antes de contar)
	var antes_jefe: int = jefa.vida
	await get_tree().create_timer(0.19, false).timeout
	print("Cocinero: su aceite le quita %d (tiene que ser 0); a Johnny, %d | cuchillos: %d" % [antes_jefe - jefa.vida,
		antes_johnny - johnny.vida, get_tree().get_nodes_in_group("balas_zombi").size()])
	# tras la foto, se recoge todo y Johnny vuelve como estaba (si no, las pruebas de después le pillan herido)
	await get_tree().create_timer(0.1, false).timeout
	johnny.modo = modo
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_INHERIT
	for cosa in get_tree().get_nodes_in_group("balas_zombi") + get_tree().get_nodes_in_group("charcos"):
		cosa.queue_free()
	johnny.estados.clear()
	johnny.pisando.clear()
	johnny.vida = antes_johnny


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
	# los logros: uno cobrado, uno por cobrar y algo de progreso en los demás
	Guardado.cambiar(func(g): g.logros = {"primer_turno": "cobrado", "desahucio": "conseguido"})
	logros.fregonazos = 4
	ordenador.abrir("logros", "b_desahucio")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-logros.png")
	ordenador.cobrar_logro("desahucio")
	print("Logros: %s | $%d ahorrados tras cobrar" % [Guardado.cargar().logros, Guardado.cargar().dolares])
	var g := Guardado.cargar()
	print("Ordenador: $%d ahorrados, %d puntos, talentos %s, armas %s | daño x%.2f | lleva %s" % [g.dolares, g.puntos,
		g.talentos, g.armas, johnny.stats.dano, johnny.huecos])
	ordenador.abrir("")
	ordenador.apagar()


# La historia: el científico muerto de la planta (con su página sin encontrar), la página al cogerla y el Dosier
# del ordenador con dos páginas
# La sangre, en la sala de mantenimiento (con luz, para que se vea): el destello de un golpe, un zombi muerto a
# golpes que deja su charco, el lento arrastrándose con su rastro y los casquillos de unos disparos
func probar_sangre() -> void:
	# si sigue abierta la mutación de la portera, se elige una que no deja charcos (para que no salgan en la foto)
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	await montar(planta.mantenimiento, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var centro := Vector2(planta.sitios[aqui].ancho / 2.0, 330)
	johnny.position = centro
	johnny.get_node("Camara").reset_smoothing()
	johnny.invulnerable = 99.0
	johnny.coger("pistola")   # con la pistola (si lleva el desintegrador, el ácido tapa la sangre)
	# los acompañantes, quietos (si no, matan al lento antes de que se arrastre)
	for a in get_tree().get_nodes_in_group("presa"):
		if a != johnny:
			a.process_mode = Node.PROCESS_MODE_DISABLED
	var golpeado := meter_zombi("normal", centro + Vector2(110, -10))
	var lento := meter_zombi("lento", centro + Vector2(-300, 60))
	lento.despertar()
	var muerto := meter_zombi("normal", centro + Vector2(-60, 150))
	await get_tree().create_timer(0.3).timeout
	muerto.recibir_golpe(999, Vector2(-120, 60))
	golpeado.recibir_golpe(1, Vector2(150, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://captura-destello.png")
	await get_tree().create_timer(0.3).timeout
	golpeado.recibir_golpe(999, Vector2(170, 0))
	johnny.coger("pistola")
	johnny.balas = 8
	for i in 5:
		johnny.disparar(-0.3 + i * 0.15)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(2.5).timeout
	var rastro: Node = lento.get_parent().get_node_or_null("Rastro")
	print("Sangre: rastro %d | gotas %d | casquillos %d | charco %s" % [rastro.celdas.size() if rastro else 0,
		lento.get_parent().get_node("Gotas").celdas.size() if lento.get_parent().has_node("Gotas") else 0,
		lento.get_parent().get_node("Casquillos").celdas.size() if lento.get_parent().has_node("Casquillos") else 0,
		golpeado.a_golpes])
	get_viewport().get_texture().get_image().save_png("res://captura-sangre2.png")
	johnny.invulnerable = 0.0
	for a in get_tree().get_nodes_in_group("presa"):
		a.process_mode = Node.PROCESS_MODE_INHERIT


func probar_historia() -> void:
	Guardado.cambiar(func(g): g.paginas = [])
	var c: Dictionary = planta.cientifico
	await montar(c.sitio, 0, false)
	johnny.position = c.pos + Vector2(-70, 0)
	johnny.get_node("Camara").reset_smoothing()
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-cientifico.png")
	print("Científico en pantalla: ", get_viewport().get_canvas_transform() * c.pos)
	johnny.position = c.pos + Vector2(28, 30)
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-pagina.png")
	print("Página cogida: %s | en el guardado: %s" % [c.get("pagina", {}).get("id", "-"), Guardado.cargar().paginas])
	menus.leida()
	# los muertos que no llevan bata (en el centro comercial: el jefe de seguridad y la secretaria), en fila sobre
	# un fondo liso, por encima de todo (sin penumbra ni paredes): captura-cuerpos.png
	var con_ropa: Array = Historia.dosier(edificio).paginas.filter(func(p): return p.look.has("ropa"))
	if not con_ropa.is_empty():
		var capa := CanvasLayer.new()
		capa.layer = 50
		add_child(capa)
		var fondo := ColorRect.new()
		fondo.color = Color("#5a5d66")
		fondo.position = Vector2(240, 230)
		fondo.size = Vector2(480, 180)
		capa.add_child(fondo)
		for i in con_ropa.size():
			var cuerpo := CIENTIFICO.new()
			cuerpo.montar(con_ropa[i], Vector2(370 + i * 220, 320))
			cuerpo.z_index = 0
			capa.add_child(cuerpo)
		await get_tree().create_timer(0.3).timeout
		get_viewport().get_texture().get_image().save_png("res://captura-cuerpos.png")
		capa.queue_free()
	# en el ordenador, la primera y la tercera página del dosier de este edificio (en los Apartamentos, el correo)
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	Guardado.cambiar(func(g): g.paginas = [ids[0], ids[2]])
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	ordenador.abrir("dosier", "b_" + ids[2])
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-dosier.png")
	# la del jefe, si este edificio la tiene (el centro comercial): sin encontrar en el ordenador y luego soltada
	var del_jefe := Historia.del_jefe(Guardado.cargar(), edificio)
	if not del_jefe.is_empty():
		ordenador.abrir("dosier", "b_" + del_jefe.id)
		await get_tree().create_timer(0.3).timeout
		get_viewport().get_texture().get_image().save_png("res://captura-dosier-falta.png")
	ordenador.abrir("")
	ordenador.apagar()
	if not del_jefe.is_empty():
		pagina_del_jefe()
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("res://captura-pagina-jefe.png")
		print("Página del jefe: %s | en el guardado: %s" % [del_jefe.id, Guardado.cargar().paginas])
		menus.leida()
	await montar(planta.mantenimiento, 0, false)
	await probar_noticias()


# Las noticias: en los Apartamentos, con la página del correo encontrada salen tres emisiones (dos sin ver); en el
# centro comercial, con los Apartamentos completados y sus dos primeras páginas, salen cinco (dos sin ver). Abre el
# programa, deja hablar a la reportera un poco y hace la foto
func probar_noticias() -> void:
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	var centro := edificio == "centro"
	Guardado.cambiar(func(g):
		g.paginas = [ids[0], ids[1]] if centro else ["vd7_protocolo", "vd7_correo"]
		g.noticias_vistas = ["n_cierre", "n_buscado", "n_reformas"] if centro else ["n_cierre"]
		# los edificios completados, siempre igual (el final de la prueba vuelve a completar el de la partida): en el
		# centro, los Apartamentos sí y el centro no (la del helicóptero, aún sin emitir)
		Guardado.edificio(g, "apartamentos").completado = centro
		Guardado.edificio(g, "centro").completado = false)
	print("Noticias emitidas: %s | nuevas: %s" % [Historia.noticias_emitidas(Guardado.cargar()).map(func(n): return n.id),
		Historia.noticias_nuevas(Guardado.cargar()).map(func(n): return n.id)])
	avisar_noticias()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-aviso-noticias.png")
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-escritorio.png")
	ordenador.abrir("noticias")
	await get_tree().create_timer(3.0).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-noticias.png")
	print("Noticias vistas tras abrir: ", Guardado.cargar().noticias_vistas)
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


# El reparto de objetos (parte 6 del centro comercial): cuenta qué sale en cada sitio de los dos edificios y
# comprueba que las cosas de casa no salen en el centro ni las del centro en los Apartamentos. Luego deja en el
# suelo los nueve nuevos, mete uno de cada objeto en el baúl (lo de la tecla U) y hace fotos del banco y del baúl
func probar_objetos() -> void:
	var fallos := []
	for ed_id in ["apartamentos", "centro"]:
		for tienda in [""] + (Objetos.TIENDAS.keys() if ed_id == "centro" else []):
			var salen := {}
			for i in 2000:
				var id := Objetos.al_azar(ed_id, tienda)
				salen[id] = salen.get(id, 0) + 1
				if id == "explosivos" or (ed_id == "centro" and id in Objetos.SOLO_CASA) \
						or (ed_id == "apartamentos" and id in Objetos.SOLO_CENTRO):
					fallos.append("%s %s: %s" % [ed_id, tienda, id])
			print("Objetos en %s %s: %d distintos %s" % [ed_id, tienda if tienda != "" else "(pasillo)", salen.size(), salen.keys()])
	print("Reparto de objetos: ", "bien" if fallos.is_empty() else "MAL %s" % str(fallos.slice(0, 5)))
	for i in Objetos.SOLO_CENTRO.size():
		soltar_objeto(Objetos.SOLO_CENTRO[i], johnny.position + Vector2(-176 + i * 44, -100), true)
	await get_tree().create_timer(0.5).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://captura-objetos-nuevos.png")
	menus.visible = true
	for cosa in mapa.cosas.get_children():
		if cosa.get_script() == BILLETE:
			cosa.queue_free()
	var baul_antes: Dictionary = Guardado.cargar().baul
	dar_objetos()
	abrir_cosas("banco")
	inventario.tocar("o_pistola_agua")
	inventario.tocar("o_bateria")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-banco-todo.png")
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-baul-todo.png")
	inventario.cerrar()
	print("Baúl con uno de cada: %d casillas de %d" % [Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL])
	Guardado.cambiar(func(g): g.baul = baul_antes)


# Las armas de las recetas nuevas (parte 6 del centro comercial): comprueba que las nueve recetas salen en el banco
# y prueba cada arma contra zombis lentos de 500 de vida (que no muera ninguno), contando en la terminal lo que pasa
# y con una foto de cada una: captura-arma-<receta>.png
func probar_recetas() -> void:
	var nuevas := ["bate_helado", "mangual", "latigo_electrico", "pistola_electrica", "garfio", "bomba_aceite",
		"mina_despertador", "nube_somnifera", "bomba_clavos"]
	print("Recetas nuevas en el banco: ", nuevas.all(func(r): return Recetas.buscar(Recetas.LISTA[r].con[1], Recetas.LISTA[r].con[0]) == r))
	# en medio del cuarto, mirando a la derecha, y sin atacar por su cuenta (aquí ataca la prueba)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	johnny.direccion = "e"
	johnny.espera = 1000.0
	# cuerpo a cuerpo: el bate helado congela, el mangual echa a todos lejos y el látigo eléctrico salta a otro
	var z := zombis_de_prueba([Vector2(40, 0)])
	johnny.coger(Armas.apuntar(Recetas.crear("bate_helado")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await foto_arma("bate_helado")
	print("Bate helado: congelado %.1f vida %d" % [z[0].congelado, z[0].vida])
	z = zombis_de_prueba([Vector2(45, 0), Vector2(-45, 10), Vector2(0, 45)])
	johnny.coger(Armas.apuntar(Recetas.crear("mangual")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await get_tree().create_timer(0.25).timeout
	await foto_arma("mangual")
	print("Mangual: distancias %s | aturdidos %s" % [z.map(func(o): return roundi(o.distancia_a(johnny))), z.map(func(o): return o.aturdido > 0.0)])
	z = zombis_de_prueba([Vector2(90, 0), Vector2(150, 30)])
	johnny.coger(Armas.apuntar(Recetas.crear("latigo_electrico")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await foto_arma("latigo_electrico")
	print("Látigo eléctrico: aturdidos %s | vidas %s" % [z.map(func(o): return snappedf(o.aturdido, 0.1)), z.map(func(o): return o.vida)])
	# a distancia: las chispas de la pistola eléctrica y el garfio
	z = zombis_de_prueba([Vector2(160, 0), Vector2(220, 40)])
	johnny.coger(Armas.apuntar(Recetas.crear("pistola_electrica")))
	await get_tree().create_timer(0.1).timeout
	for i in 4:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await foto_arma("pistola_electrica")
	await get_tree().create_timer(0.3).timeout
	print("Pistola eléctrica: balas %d | aturdidos %s | vidas %s" % [johnny.balas, z.map(func(o): return snappedf(o.aturdido, 0.1)),
		z.map(func(o): return o.vida)])
	z = zombis_de_prueba([Vector2(260, 0)])
	johnny.coger(Armas.apuntar(Recetas.crear("garfio")))
	await get_tree().create_timer(0.1).timeout
	var lejos := roundi(z[0].distancia_a(johnny))
	johnny.disparar(0.0)
	await get_tree().create_timer(0.4).timeout
	await foto_arma("garfio")
	await get_tree().create_timer(0.75).timeout
	print("Garfio: distancia %d -> %d | balas %d (no gasta) | vida %d" % [lejos, roundi(z[0].distancia_a(johnny)), johnny.balas, z[0].vida])
	# arrojadizas: el aceite resbala y luego arde, la mina espera a que pase un zombi, la nube duerme y los clavos
	z = zombis_de_prueba([Vector2(170, 0), Vector2(190, 30)])
	for r in ["bomba_aceite", "mina_despertador", "nube_somnifera", "bomba_clavos"]:
		lanzables.sacar(Recetas.crear(r))
	for o in z:
		o.aturdido = 4.0   # que se queden en el charco
	lanzables.tipo = "bomba_aceite"
	lanzables.lanzar(johnny.global_position + Vector2(180, 10))
	await get_tree().create_timer(1.0).timeout
	var aceite := get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "aceite").size()
	await foto_arma("bomba_aceite")
	await get_tree().create_timer(2.0).timeout
	print("Bomba de aceite: charcos de aceite %d | luego fuegos %d | zombis ardiendo %s" % [aceite,
		get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "fuego").size(), z.map(func(o): return o.arder_t > 0.0)])
	await foto_arma("bomba_aceite_arde")
	z = zombis_de_prueba([])
	lanzables.tipo = "mina_despertador"
	lanzables.lanzar(johnny.global_position + Vector2(-170, 0))
	await get_tree().create_timer(1.3).timeout
	await foto_arma("mina_despertador")
	var mina: Node2D = johnny.get_parent().get_children().filter(func(n): return n.get_script() == Lanzables.BOMBA)[-1]
	var donde: Vector2 = mina.global_position - johnny.global_position
	z = zombis_de_prueba([Vector2(-330, 0)])   # viene hacia Johnny y pasa por encima
	for i in 40:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(mina):
			break
	await get_tree().create_timer(0.1).timeout
	print("Mina despertador: en %s | ha explotado %s | el zombi que pasa, vida %d (de 500) | vida de Johnny %d" % [
		donde.round(), not is_instance_valid(mina), z[0].vida, johnny.vida])
	z = zombis_de_prueba([Vector2(180, 0), Vector2(200, 40), Vector2(150, -30)])
	lanzables.tipo = "nube_somnifera"
	lanzables.lanzar(johnny.global_position + Vector2(180, 10))
	await get_tree().create_timer(1.9).timeout
	await foto_arma("nube_somnifera")
	print("Nube somnífera: dormidos %s" % [z.map(func(o): return snappedf(o.aturdido, 0.1))])
	z = zombis_de_prueba([Vector2(120, 0), Vector2(200, 50), Vector2(80, -60)])
	lanzables.tipo = "bomba_clavos"
	lanzables.lanzar(johnny.global_position + Vector2(150, 0))
	await get_tree().create_timer(2.15).timeout
	await foto_arma("bomba_clavos")
	await get_tree().create_timer(0.35).timeout
	print("Bomba de clavos: vidas %s | sangran %s | quedan %s" % [z.map(func(o): return o.vida),
		z.map(func(o): return o.has_node("herida_sangra")), lanzables.tipos()])
	zombis_de_prueba([])
	johnny.vida = johnny.stats.vida_max
	johnny.espera = 0.0


# Para probar_recetas: quita los zombis y los charcos que haya, cura a Johnny y saca zombis lentos de 500 de vida
# en esos sitios (respecto a Johnny)
func zombis_de_prueba(donde: Array) -> Array:
	for o in get_tree().get_nodes_in_group("zombis") + get_tree().get_nodes_in_group("charcos"):
		o.remove_from_group("zombis")
		o.queue_free()
	johnny.vida = johnny.stats.vida_max
	var lista := []
	for d in donde:
		var zombi := meter_zombi("lento", johnny.position + d)
		zombi.vida = 500
		lista.append(zombi)
	return lista


# Para probar_recetas: la foto de un arma nueva (sin el recuadro de las mutaciones, si ha salido)
func foto_arma(nombre: String) -> void:
	menus.visible = false
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://captura-arma-%s.png" % nombre)
	menus.visible = true


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
	await probar_objetos()
	await probar_recetas()
	await supervivientes.probar()
	await probar_sangre()
	await probar_mutaciones()
	await probar_historia()
	pausar()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-pausa.png")
	seguir()
	terminar(true)
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://captura-fin.png")
	print("Guardado de prueba: ", Guardado.cargar())
	get_tree().quit()
