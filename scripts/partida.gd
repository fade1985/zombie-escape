# La partida: genera la planta (planta.gd), monta el sitio en el que está Johnny (mapa.gd) y, al cruzar una
# puerta, funde a negro y monta el del otro lado. Lleva también la pantalla (vida, arma, avisos) y las reglas
# del mapa:
#   - Al entrar en un apartamento la puerta se cierra, y no se abre hasta que no queda ni un zombi.
#   - El apartamento de la jefa está cerrado con llave; la llave está en el suelo de otro apartamento.
#   - Al entrar, aparece la portera. Cuando cae, se abren las escaleras a la planta siguiente y Johnny arregla
#     el ascensor, que solo baja a la sala de mantenimiento y vuelve a esa planta (arreglar_ascensor).
#   - Después de la última planta, el edificio está limpio: cartel de victoria.
# La partida empieza en la sala de mantenimiento de la planta baja (por su puerta de la derecha se va a las viviendas
# de los supervivientes rescatados, mapa/viviendas.gd). Abajo, en la franja del muro, va el HUD (hud.gd)
# y arriba a la derecha, el minimapa. Esc o Start abren la pausa (menus.gd).
#
# Dinero y guardado (como game.js y game-combate.js del JS): los zombis sueltan billetes a veces (la portera,
# varios). Los dólares de la partida solo se guardan si completas el edificio; si caes, se pierden. Al acabar
# (ganes, caigas o abandones) se guardan los récords y los zombis matados (guardado.gd).
#
# El ordenador de la sala de mantenimiento (ui/ordenador.gd): al arrimarse a su mesa, el juego se pausa y sale
# ConserjeOS, para comprar puntos de talento, subir talentos y comprar armas con los dólares ahorrados. Los
# talentos (talentos.gd) se aplican a Johnny al empezar la partida y al comprarlos. La taquilla (ui/taquilla.gd),
# igual: al arrimarse sale la ventanita para elegir la skin de Johnny (skins.gd).
#
# Para probar: F11, desde cualquier sitio, lleva a la sala de pruebas (sala_armas.gd) y, otra vez, de vuelta adonde
# se estaba. Allí, 1 a 8 sacan un zombi y Mayús + 1 a 0, un jefe, y la P abre el panel de pruebas (ui/panel_pruebas.gd): sacar jefes y zombis, encender y apagar las
# ayudas, ir a la exposición o a la sala de un jefe... Lo que pasa en la sala no cuenta (en_pruebas).
#
# Con "-- --captura" no se juega esta, sino la partida de prueba (escenas/partida_prueba.tscn): la misma partida
# más las fotos y las comprobaciones, que están en scripts/pruebas/partida_prueba.gd.
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
	"mascota": preload("res://escenas/personajes/mascota.tscn"),
	"cocinero": preload("res://escenas/personajes/cocinero.tscn"),
	"modista": preload("res://escenas/personajes/modista.tscn"),
	"gerente": preload("res://escenas/personajes/gerente.tscn"),   # el jefe final del centro comercial (la azotea)
	"gloton": preload("res://escenas/personajes/gloton.tscn"),     # minijefes de los Apartamentos (docs/historial/JEFES_APARTAMENTOS.md)
	"gymbro": preload("res://escenas/personajes/gymbro.tscn"),
	"bombero": preload("res://escenas/personajes/bombero.tscn"),
	"cientifico_jefe": preload("res://escenas/personajes/cientifico_jefe.tscn"),   # el jefe final de los Apartamentos (la azotea)
}
# Los jefes de planta: barra de vida grande, un 25 % más duros en cada planta y, al caer, billetes, munición,
# objetos y la mutación (el jefe final de un edificio, el gerente, sin lo del 25 % ni la mutación: final_de())
const JEFES := ["portera", "antidisturbios", "cocinero", "modista", "mascota", "gerente", "gloton", "gymbro", "bombero",
	"cientifico_jefe"]
const MAPA := preload("res://scripts/mapa/mapa.gd")
const MINIMAPA := preload("res://scripts/minimapa.gd")
const BILLETE := preload("res://scripts/billete.gd")
const HUD := preload("res://scripts/ui/hud.gd")
const AMBIENTE := preload("res://scripts/ui/ambiente.gd")
const MENUS := preload("res://scripts/ui/menus.gd")
const ORDENADOR := preload("res://scripts/ui/ordenador.gd")
const TAQUILLA := preload("res://scripts/ui/taquilla.gd")
const PRESENTACION := preload("res://scripts/ui/presentacion.gd")
const CIENTIFICO := preload("res://scripts/mapa/cientifico.gd")
const INVENTARIO := preload("res://scripts/ui/inventario.gd")
const PANEL_PRUEBAS := preload("res://scripts/ui/panel_pruebas.gd")
const REFUERZOS := 2               # los vigilantes que llegan al silbato del guardia (y uno más cada dos plantas)
const BILLETES_GUARDIA := 2
const BILLETE_ZOMBI := 0.07        # probabilidad de que un zombi suelte un billete
# La sangre de cada tipo de zombi: el color de su piel (los trozos al reventar) y el de su mancha (del JS)
const PIELES := {"normal": Color("#8fc46a"), "lento": Color("#8fc46a"), "rapido": Color("#9ed36d"),
	"explosivo": Color("#c3d96b"), "tentaculos": Color("#86b8aa"), "venenoso": Color("#b5e655"), "portera": Color("#cbb994"),
	"vigilante": Color("#a6d655"), "dependienta": Color("#93c46a"), "guardia": Color("#a6d655"),
	"antidisturbios": Color("#3b4252"), "cocinero": Color("#8a9a6a"), "modista": Color("#93b07a"),
	"mascota": Color("#c9a13b"), "gerente": Color("#8f9f80"), "gloton": Color("#b9a06e"), "gymbro": Color("#c2b48a"),
	"bombero": Color("#6b6158"), "cientifico_jefe": Color("#d9d6c8")}
const MANCHAS := {"explosivo": Color("#2b2633"), "venenoso": Color("#8fd13f"), "tentaculos": Color("#7b4fa0")}
const SANGRE := Color("#7a1f1a")   # la sangre de los demás: rojo oscuro (antes, verde oliva #5b7d3a)
const MUNICION_ZOMBI := 0.1        # ...o una caja de munición, si no ha soltado otra cosa (provisional en el JS)
const ICONO_MP5 := preload("res://assets/ui/iconos/municion-mp5.png")   # la caja de munición con la MP5 en la mano
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
var orden_jefes: Array = []   # el minijefe de cada planta, sorteado al empezar (edificios.gd)
var sala_mantenimiento := {}  # la sala de mantenimiento de la planta baja, para bajar a ella en el ascensor
var sala_viviendas := {}      # y las viviendas de los rescatados, detrás de su puerta de la derecha (viviendas.gd)
var captura := false       # si es la partida de prueba (la pone pruebas/partida_prueba.gd)
var luz := Luz.new()       # la penumbra (luz.gd)
var menus := MENUS.new()   # la pausa y el cartel del final
var ordenador := ORDENADOR.new()   # la pantalla de ConserjeOS
var taquilla := TAQUILLA.new()     # la ventanita de la taquilla de las skins de Johnny (skins.gd)
var panel_pruebas := PANEL_PRUEBAS.new()   # el panel de la sala de pruebas (tecla P allí dentro)
var de_pruebas := {}       # de dónde se vino a la sala de pruebas (F11): {planta, sitio, pos}, para volver allí
var presentacion := PRESENTACION.new()   # la presentación de cada jefe al aparecer (ui/presentacion.gd)
var presentar_en_prueba := false   # en la partida de prueba la presentación se salta, salvo en la suya (--presentacion)
const JEFE_TARDA := 0.6            # lo que tarda el jefe en salir al entrar en su sala
var lanzables := Lanzables.new()   # el molotov y la granada (lanzables.gd)
var mutaciones := Mutaciones.new() # las mutaciones de esta partida (mutaciones.gd)
var inventario := INVENTARIO.new() # las pantallas del inventario y el baúl
var supervivientes := Supervivientes.new()   # el superviviente de la partida, la horda y los vecinos
var logros := Logros.new()         # los retos del ordenador (logros.gd)
var eventos := Eventos.new()       # los eventos sorpresa de algunas plantas (eventos.gd)
var joyeria := Joyeria.new()       # la cámara acorazada de la joyería del centro comercial (joyeria.gd)
var mochila: Array = []    # los objetos recogidos en esta partida (objetos.gd), uno por cada: al baúl si ganas
var armas_guardadas: Array = []   # las de repuesto: como mucho una de cuerpo a cuerpo y una a distancia (llevar_arma)
var ahorrados := 0         # los dólares guardados de otras partidas
var dolares := 0           # los recogidos en esta partida
var muertos := 0           # zombis matados en esta partida
var duracion := 0.0        # segundos jugados (sin contar la pausa)
var terminada := false

@onready var johnny := $Johnny
@onready var lugar: Label = $Pantalla/Lugar
@onready var aviso: Label = $Pantalla/Mensaje
var aviso_tween: Tween     # el que va borrando el aviso (decir)
var de_prueba := 0         # «Científico muerto» del panel de pruebas: la página del siguiente (probar_cientifico)
@onready var negro: ColorRect = $Pantalla/Negro


func _ready() -> void:
	Controles.aplicar()   # las teclas cambiadas en Opciones (por si se abre la partida directamente)
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	# los textos de la pantalla, con la fuente pixel art de los menús
	for etiqueta in [lugar, aviso, $Pantalla/Ayuda]:
		etiqueta.theme = Tema.crear()
	johnny.modo_cambiado.connect(func(nombre): $Pantalla/Ayuda.text = "Modo: %s (F1 o C cambia) · Espacio esquivar · Q cambiar · R recargar · E/clic dcho. lanzar · F molotov/granada · Tab inventario · Esc pausa · F11 sala de pruebas (P: panel)" % nombre)
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
	add_child(taquilla)
	add_child(panel_pruebas)
	presentacion.preparar(self)
	lanzables.johnny = johnny
	lanzables.partida = self
	add_child(lanzables)
	mutaciones.johnny = johnny
	mutaciones.presentacion = presentacion
	add_child(mutaciones)
	add_child(supervivientes)
	supervivientes.preparar(self)
	add_child(logros)
	logros.preparar(self)
	add_child(eventos)
	eventos.preparar(self)
	add_child(joyeria)
	joyeria.preparar(self)
	# Los controles del móvil (solo salen en pantallas táctiles)
	var tactil := Tactil.new()
	tactil.partida = self
	tactil.johnny = johnny
	add_child(tactil)
	if Tactil.activo:
		$Pantalla/Ayuda.hide()   # las teclas no pintan nada en el móvil

	if captura:
		preparar_prueba()   # el guardado de prueba, la alerta y el evento que se piden
	if Reto.activo:
		# el reto del día (reto.gd): también el dado de siempre con la semilla de hoy, para que el orden de los
		# minijefes, la planta del superviviente y los eventos sorpresa salgan iguales para todo el mundo
		seed(Planta.semilla)
	# Empieza una partida: se apunta, y se cuenta con los dólares ahorrados
	var s := Guardado.cambiar(func(g):
		g.partidas += 1
		Guardado.edificio(g, edificio).partidas += 1
		if Reto.activo:
			Reto.ficha(g, edificio).intentos += 1)
	ahorrados = s.dolares
	# los talentos comprados, y empieza con la vida llena y el escudo de Acero
	aplicar_talentos(s.talentos)
	johnny.vida = johnny.stats.vida_max
	lanzables.reiniciar(johnny.stats)
	if Reto.sin_municion():   # el reto "Solo cuerpo a cuerpo": la pistola vacía y sin lanzables
		johnny.balas = 0
		johnny.municion.clear()
		lanzables.vaciar()
	supervivientes.elegir()
	# la joyería del centro comercial (parte 9): una por partida, en una planta al azar de la 1ª a la 3ª
	Planta.joyeria_planta = randi_range(2, Planta.PLANTAS - 1) if ed.generador == "tienda" else 0
	var botiquin := supervivientes.botiquin_al_empezar()   # la mejora de la farmacéutica
	# los minijefes, uno por planta en orden al azar (sin repetir)
	orden_jefes = ed.get("minijefes", []).duplicate()
	orden_jefes.shuffle()
	if captura:
		ordenar_jefes_prueba()   # el jefe que se quiere ver, en la 1ª planta
	nueva_planta(1)
	# en la sala de mantenimiento, en medio (en medio del despacho)
	montar(planta.mantenimiento, 0, false)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	if captura:
		empezar_prueba()
	else:
		decir("%s: %s%s" % [planta.nombre, ed.objetivo, "
%s: %s" % [Alerta.nombre(), Alerta.REGLAS[Alerta.nivel]]
			if Alerta.nivel > 0 else ""] + ("
" + Reto.aviso() if Reto.activo else "") + ("
La Farmacéutica te ha preparado un botiquín: está en la mochila" if botiquin else ""), 4.0)
		if not Historia.noticias_nuevas(s).is_empty():
			get_tree().create_timer(4.8, false).timeout.connect(avisar_noticias)


# Lo que hace la partida de prueba al empezar (pruebas/partida_prueba.gd). En la partida de verdad, nada
func preparar_prueba() -> void:
	pass


func ordenar_jefes_prueba() -> void:
	pass


func empezar_prueba() -> void:
	pass


func nueva_planta(num: int) -> void:
	planta = Planta.generar(num, edificio, jefe_de(num))
	if planta.mantenimiento >= 0:
		sala_mantenimiento = planta.sitios[planta.mantenimiento]
	if planta.viviendas >= 0:
		sala_viviendas = planta.sitios[planta.viviendas]
	supervivientes.nueva_planta()
	logros.planta_nueva()
	eventos.nueva_planta()
	johnny.escudo = johnny.stats.escudo + johnny.stats.escudo_mut   # Acero y Endurecimiento: escudo nuevo en cada planta


# El minijefe de la planta "num": el que le tocó en el sorteo, si ya está hecho (tiene su
# escena en ZOMBIS); si no, "" (el jefe del edificio: la portera)
func jefe_de(num: int) -> String:
	# en la azotea, el jefe final del edificio (el gerente), si ya está hecho
	if ed.get("azotea", false) and num == Planta.PLANTAS:
		return ed.final if ZOMBIS.has(ed.final) else ""
	if num > orden_jefes.size() or not ZOMBIS.has(orden_jefes[num - 1]):
		return ""
	return orden_jefes[num - 1]


# Los atributos de Johnny con los talentos comprados y las mutaciones de la partida (al empezar, al comprar
# un talento en el ordenador y al elegir una mutación)
func aplicar_talentos(talentos: Dictionary) -> void:
	var st := Mutaciones.aplicar(Talentos.aplicar(Mejoras.base(), talentos), mutaciones.tengo)
	st.vida_max = maxi(3, roundi(st.vida_max * Reto.vida()))   # el reto del día "De cristal": la mitad
	johnny.poner_stats(st)


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
	eventos.recoger()
	joyeria.recoger()
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
	mapa.dorada_cogida.connect(joyeria.coger_dorada)
	if mapa.ordenador:
		mapa.ordenador.usar.connect(abrir_ordenador)
		mapa.banco.usar.connect(abrir_cosas.bind("banco"))
		mapa.taquilla.usar.connect(abrir_taquilla)
		# al volver a la sala de mantenimiento (al empezar ya avisa _ready)
		if fundir and not captura and not Historia.noticias_nuevas(Guardado.cargar()).is_empty():
			avisar_noticias()
	if mapa.baul:   # (el de la sala de mantenimiento o el de pruebas)
		mapa.baul.usar.connect(abrir_cosas.bind("baul"))
	for armarito in mapa.armaritos:
		armarito.johnny = johnny
		armarito.usar.connect(coger_botiquin.bind(armarito))
		if Reto.sin_curas():   # el reto del día "Sin curas": todos vacíos
			armarito.vaciar()
	poner_cientifico(idx)
	for puerta in mapa.puertas:
		puerta.empujada.connect(cruzar)
	mapa.cosas.add_child(johnny)
	johnny.position = mapa.puertas[por].llegada()
	johnny.velocity = Vector2.ZERO
	supervivientes.al_montar(idx, sitio)
	joyeria.al_montar(idx, sitio)   # la puerta blindada de la cámara acorazada, y la tarjeta dorada si está en el suelo
	encuadrar(sitio)
	johnny.get_node("Camara").reset_smoothing()
	eventos.al_montar(idx, sitio)   # (antes de la luz: el apagón la cambia)
	luz.poner_sitio(sitio.tipo)

	# Los zombis que esperan dentro, dormidos (si el piso aún no se ha limpiado)
	for z in [] if sitio.limpio else sitio.zombis:
		var zombi := meter_zombi(z.tipo, z.pos)
		zombi.dormido = true
		zombi.zona = mapa.zona_en(z.pos)
		if z.get("llave", false):
			vecino_de_la_llave(zombi)
	if sitio.tipo == "pasillo" and planta.get("guardia", {}).get("vivo", false):
		poner_guardia()
	cerrada = false
	actualizar_puertas()
	poner_lugar()
	if fundir:
		await create_tween().tween_property(negro, "modulate:a", 0.0, FUNDIDO).finished
	cambiando = false
	Sonido.musica("jefe" if sitio.tipo == "jefe" and not sitio.limpio else "menu")   # la de los menús también suena al explorar
	# En el apartamento de la jefa, aparece ella (si aún no ha caído)
	if sitio.tipo == "jefe" and not sitio.limpio:
		await get_tree().create_timer(JEFE_TARDA).timeout
		if aqui == idx and not jefa_salio:
			jefa_salio = true
			Sonido.tocar("jefe")
			# en medio de la sala (la pelea empieza en el centro, nunca junto a una pared); en la azotea, en el helipuerto
			jefa = meter_zombi(planta.jefe, sitio.helipuerto if sitio.has("helipuerto") else mapa.centro_libre())
			# y su presentación: la cámara lo enfoca mientras grita y sale su nombre (en la prueba, solo en la suya)
			if not captura or presentar_en_prueba:
				await presentacion.presentar(self, jefa, $Pantalla/Jefa/Nombre.text)


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
	# (la sala de mantenimiento y las viviendas siempre están en la planta baja, aunque se haya bajado en el ascensor)
	var de_planta: String = Planta.nombre_planta(1) if sitio.tipo in ["mantenimiento", "viviendas"] else planta.nombre
	var texto: String = de_planta if sitio.tipo == "pasillo" or sitio.get("azotea", false) else "%s · %s" % [de_planta, sitio.nombre]
	var zona: String = mapa.nombre_zona(mapa.zona_en(johnny.position))
	if zona != "" and zona != sitio.nombre:   # (la tienda de un minijefe y su sala se llaman igual)
		texto += " · " + zona
	lugar.text = texto + eventos.etiqueta() + Reto.etiqueta()


# Johnny ha empujado la salida "i" del sitio en el que está
func cruzar(i: int) -> void:
	if cambiando or not johnny.vivo:
		return
	if aqui == planta.armas:
		pruebas()   # la puerta de la sala de pruebas vuelve adonde se estaba
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
	await montar(salida.a, salida.vuelta)
	if planta.sitios[aqui].tipo != "pasillo":
		return
	if salida.tipo == "ascensor":
		decir(planta.nombre, 2.5)   # de vuelta de la sala de mantenimiento: en qué planta se está
	elif planta.get("ascensor_nuevo", false):
		# al salir al pasillo tras acabar con el jefe (con el ascensor ya a la vista), Johnny cuenta que lo ha arreglado
		planta.erase("ascensor_nuevo")
		decir("Johnny: «¡He podido arreglar el ascensor! Ya puedo bajar a la planta baja, a la sala de mantenimiento»", 5.0)


# El ascensor (M5): al caer el jefe de la planta, Johnny lo arregla. Solo baja a la sala de mantenimiento de la
# planta baja (la misma del principio, que se añade a esta planta como un sitio más, y con ella las viviendas de su
# puerta de la derecha) y vuelve aquí, nunca a otra planta. En la planta baja no hace falta (la sala está ahí mismo)
# y la azotea no tiene
func arreglar_ascensor() -> void:
	var i := puerta_de_tipo("ascensor")
	var ascensor: Dictionary = planta.sitios[0].salidas[i]
	if planta.num == 1 or ascensor.tipo != "ascensor" or sala_mantenimiento.is_empty():
		return
	planta.mantenimiento = planta.sitios.size()
	# la sala, con su puerta cambiada: lleva al ascensor de esta planta (lo demás, lo de siempre)
	var sala: Dictionary = sala_mantenimiento.duplicate()
	sala.salidas = sala.salidas.map(func(s): return s.duplicate())
	sala.salidas[0].merge({"tipo": "ascensor", "vuelta": i}, true)
	planta.sitios.append(sala)
	# y las viviendas, con su puerta a esta sala
	if sala_viviendas.is_empty():
		return
	planta.viviendas = planta.sitios.size()
	var casas: Dictionary = sala_viviendas.duplicate()
	casas.salidas = [casas.salidas[0].duplicate()]
	casas.salidas[0].a = planta.mantenimiento
	planta.sitios.append(casas)
	sala.salidas[1].a = planta.viviendas
	ascensor.merge({"a": planta.mantenimiento, "vuelta": 0, "cerrojo": "", "aviso": ""}, true)
	planta.ascensor_nuevo = true   # (el aviso de Johnny, al salir al pasillo: ver cruzar)


# Por las escaleras, a la planta siguiente (o, después de la última, se acabó)
func subir() -> void:
	logros.planta_pasada()
	if planta.num >= Planta.PLANTAS:
		cambiando = true
		terminar(true)
		return
	nueva_planta(planta.num + 1)
	await montar(0, puerta_de_tipo("llegada"))
	decir("Azotea · ¡El último combate del edificio!" if planta.get("azotea", false) else planta.nombre, 2.5)
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
			arreglar_ascensor()
			Sonido.musica("menu")
			decir("¡%s ha caído! %s" % [planta.el_jefe.left(1).to_upper() + planta.el_jefe.substr(1),
				"La escalera de incendios ya está abierta" if sitio.get("azotea", false) else "Las escaleras ya están abiertas"], 4.0)
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
# la orden de recogida. La pide el gerente al caer en la azotea (fin_del_edificio())
func pagina_del_jefe() -> void:
	var p := Historia.del_jefe(Guardado.cargar(), edificio)
	if not p.is_empty():
		leer_pagina(p)


# Ha caído el jefe final (el gerente mutado, en la azotea): cuando se ha visto caer, su página del dosier (si aún
# falta; con el juego parado) y, al cerrarla, llega el helicóptero de Velaria a por Johnny (helicoptero.gd). La
# escalera de incendios ya se abre sola al quedar la azotea limpia: por ahí se va
func fin_del_edificio() -> void:
	var donde := aqui
	await get_tree().create_timer(1.6, false).timeout
	if donde != aqui:
		return
	pagina_del_jefe()
	await get_tree().create_timer(0.8, false).timeout   # (mientras la página está abierta, no corre)
	if donde != aqui:
		return
	var heli := Helicoptero.new()
	heli.destino = planta.sitios[aqui].get("helipuerto", johnny.position)
	heli.johnny = johnny
	mapa.cosas.add_child(heli)
	decir("¡Un helicóptero de Velaria viene a por ti! Vete por la escalera de incendios", 4.5)


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
	guardia.vida_max = int(guardia.vida_max * (1.0 + 0.2 * (planta.num - 1)) * Alerta.guardia())   # cada planta, algo más duro
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
	# en la planta de la joyería lleva también la tarjeta dorada de su cámara acorazada (joyeria.gd)
	var dorada := joyeria.soltar_dorada(zombi.position + Vector2(44, 0))
	decir("¡El guardia ha caído! Ha soltado la tarjeta de acceso" + (" y la tarjeta dorada de la Joyería" if dorada else ""), 3.0)


# Con la Alerta 5, en los Apartamentos: el vecino que lleva la llave (planta.gd) aguanta el doble, como el guardia,
# y lleva la llave flotando encima. Al caer la suelta donde estaba
func vecino_de_la_llave(zombi: Node2D) -> void:
	zombi.vida_max = int(zombi.vida_max * (1.0 + 0.2 * (planta.num - 1)) * Alerta.guardia())
	zombi.vida = zombi.vida_max
	zombi.set_meta("llave", true)
	var llave := Sprite2D.new()
	llave.texture = MAPA.LLAVE
	llave.scale = Vector2(2, 2)
	llave.position = Vector2(0, -zombi.altura - 10)
	zombi.add_child(llave)
	var vaiven := llave.create_tween().set_loops()
	vaiven.tween_property(llave, "position:y", -zombi.altura - 16, 0.6).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(llave, "position:y", -zombi.altura - 10, 0.6).set_trans(Tween.TRANS_SINE)
	zombi.murio.connect(func():
		llave.hide()
		planta.llave = {"sitio": aqui, "pos": zombi.position}
		mapa.call_deferred("poner_llave", zombi.position)
		decir("¡El vecino ha caído! Ha soltado la llave del " + nombre_jefa(), 3.0))


# El nombre del apartamento de la jefa ("2ºC"...)
func nombre_jefa() -> String:
	for s in planta.sitios:
		if s.tipo == "jefe":
			return s.nombre
	return ""


# Un aviso en el centro de la pantalla que se va solo. Durante la presentación de un jefe no sale: se guarda (el
# último) y sale al acabar (ui/presentacion.gd)
func decir(texto: String, segundos := 2.2) -> void:
	if presentacion.activa:
		presentacion.pendiente = [texto, segundos]
		return
	aviso.text = texto
	aviso.modulate.a = 1.0
	if aviso_tween:
		aviso_tween.kill()   # que el aviso de antes, al irse, no se lleve este
	var tween := aviso.create_tween()
	aviso_tween = tween
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


# Un molotov o una granada en el suelo: se coge pasando por encima, si cabe en la mochila (en el reto "Solo
# cuerpo a cuerpo", no caen)
func soltar_lanzable(k: String, donde: Vector2) -> void:
	if Reto.sin_municion():
		return
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


# Una caja de munición: un cargador más para el arma de fuego (johnny.sumar_municion). Va hacia Johnny solo si le cabe
# (en el reto "Solo cuerpo a cuerpo", no caen). Con "tipo", la que ha tirado Johnny desde el inventario: vuelve entera
# ("cuanta" de ese tipo), si le cabe
func soltar_municion(donde: Vector2, tipo := "", cuanta := 0) -> void:
	if Reto.sin_municion() and tipo == "":
		return
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	if tipo == "":
		cosa.que_icono = icono_caja   # cambia si Johnny cambia de arma antes de cogerla
		cosa.icono = icono_caja()
	else:
		cosa.icono = icono_municion(tipo)
	cosa.tamano = 32.0 / cosa.icono.get_width()
	cosa.a_oscuras = true
	cosa.add_to_group("cajas_municion")
	cosa.position = donde
	if tipo == "":
		cosa.puede = johnny.quiere_municion
	else:
		cosa.tirado = true
		cosa.puede = func() -> bool: return johnny.sitio(tipo) >= cuanta
	cosa.cogido.connect(func():
		if tipo == "":
			johnny.sumar_municion()
		else:
			johnny.meter_municion(tipo, cuanta)
			johnny.coger_municion(tipo)
		Sonido.tocar("recargado")
		numero(cosa.position, "+munición", Color("#ffd23f")))
	mapa.cosas.add_child.call_deferred(cosa)


# El dibujo de la munición de un tipo (Armas.MUNICION)
func icono_municion(tipo: String) -> Texture2D:
	return load("res://assets/ui/iconos/%s.png" % Armas.MUNICION[tipo].icono)


# El dibujo de una caja de munición del suelo: el de la munición que daría al cogerla (la del arma de
# johnny.arma_de_caja; la MP5 gasta las balas de la pistola, pero se pinta su caja verde). Si ahora no es para ninguna,
# el de la munición del arma de fuego que lleva, o las balas de pistola si esa se llena con un objeto de la mochila
func icono_caja() -> Texture2D:
	var id: String = johnny.arma_de_caja()
	if id == "" and johnny.huecos.fuego != "" and not Armas.datos(johnny.huecos.fuego).has("relleno"):
		id = johnny.huecos.fuego
	if id == "mp5":
		return ICONO_MP5
	var tipo := Armas.municion(id) if id != "" else ""
	return icono_municion(tipo if tipo in Armas.MUNICION else "balas")


# Un objeto en el suelo: se coge pasando por encima, si cabe en la mochila (la gasolina, el
# bidón de ácido y la batería, si caben en la munición: johnny.sitio). "tirado": lo ha tirado Johnny desde el inventario (no vuelve
# a la mochila hasta que se aparte)
func soltar_objeto(id: String, donde: Vector2, tirado := false) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = load("res://assets/ui/iconos/%s.png" % Objetos.icono(id))
	cosa.tamano = 32.0 / cosa.icono.get_width()   # los de 16×16, cada píxel 2 unidades (el botiquín es de 32×32)
	cosa.a_oscuras = id in Armas.MUNICION   # la gasolina, el bidón de ácido y la batería se ven a oscuras, como la munición
	cosa.tirado = tirado
	cosa.position = donde
	cosa.puede = func() -> bool: return johnny.sitio(id) > 0 if id in Armas.MUNICION else Objetos.cabe(mochila, id)
	cosa.cogido.connect(func():
		mochila.append(id)
		Objetos.apuntar_encontrado(id)   # para las Colecciones del ordenador
		Sonido.tocar("compra")
		numero(cosa.position, "+1 " + Objetos.nombre(id), Tema.TINTA)
		johnny.coger_municion(id))   # si es una gasolina, el lanzallamas vacío se llena con ella (el lanza ácido, con un bidón, y la pistola eléctrica, con una batería)
	mapa.cosas.add_child.call_deferred(cosa)


# Un arma en el suelo (tirada desde el inventario, o la que suelta Johnny al llevar ya dos de ese tipo), con su
# calidad (las mejoradas, con un brillo de su color): al volver a cogerla, al repuesto si está libre (llevar_arma)
func soltar_arma(id: String, donde: Vector2, calidad := 0) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.icono = load("res://assets/ui/iconos/%s.png" % Objetos.icono(id))
	cosa.tamano = 1.4
	cosa.tirado = true
	cosa.position = donde
	if calidad > 0:
		var brillo := PointLight2D.new()
		brillo.texture = load("res://escenas/luces/luz_suave.tres")
		brillo.texture_scale = 0.25
		brillo.color = Armas.color(calidad)
		brillo.position = Vector2(0, -10)
		cosa.add_child(brillo)
	cosa.cogido.connect(func():
		llevar_arma(id, calidad, false)
		Sonido.tocar("compra")
		numero(cosa.position, Armas.nombre(id, calidad), Armas.color(calidad) if calidad > 0 else Tema.TINTA))
	mapa.cosas.add_child.call_deferred(cosa)


# Johnny lleva como mucho dos armas de cada tipo (cuerpo a cuerpo y a distancia): la de la mano y la de repuesto
# (armas_guardadas), y una de cada arma, cada una con su calidad (johnny.calidades). Al llevarse otra (comprarla,
# sacarla del baúl o de la vitrina de la joyería), va a la mano y la que llevaba pasa al repuesto; si ya tenía una de
# repuesto, la de la mano se queda en el suelo, a sus pies. Si ya llevaba esa misma arma, se cambian: la nueva ocupa
# su sitio (llena) y la vieja se queda en el suelo. La que coge del suelo ("a_la_mano" falso) va al repuesto si está
# libre, para no cambiarle el arma en plena pelea. Con "al_suelo" falso (al sacarla del baúl), la que sobra no se deja
# en el suelo: solo se devuelve, para guardarla en su lugar. Devuelve la que sobra ({"id", "calidad"}; vacío si ninguna)
func llevar_arma(id: String, calidad := 0, a_la_mano := true, al_suelo := true) -> Dictionary:
	var tipo: String = Armas.datos(id).tipo
	var fuera := {}
	if id == johnny.huecos[tipo] or id in armas_guardadas:
		fuera = {"id": id, "calidad": johnny.calidad(id)}
		johnny.calidades[id] = calidad
		johnny.cargadores.erase(id)   # (la nueva viene llena)
		if id == johnny.huecos[tipo]:
			johnny.coger(id)
			var w: Dictionary = johnny.base(id)
			if tipo == "fuego":
				johnny.balas = w.cargador
				johnny.deposito = w.get("deposito", 0.0)
	elif not a_la_mano and repuesto(tipo) == "":
		armas_guardadas.append(id)
		johnny.calidades[id] = calidad
	else:
		var vieja: String = johnny.huecos[tipo]
		if repuesto(tipo) == "":
			armas_guardadas.append(vieja)
		else:
			fuera = {"id": vieja, "calidad": johnny.calidad(vieja)}
		johnny.calidades[id] = calidad
		johnny.coger(id)
		if not fuera.is_empty():
			johnny.calidades.erase(vieja)
	if not fuera.is_empty() and al_suelo:
		soltar_arma(fuera.id, johnny.position + Vector2(0, 34), fuera.calidad)
	return fuera


# Lo que lleva encima que va al baúl al completar el edificio (Armas.al_baul), como en el guardado ("baul_equipo"):
# sus armas, menos la fregona y la pistola Normales, y los paquetes de arrojables mejorados
func equipo_encima() -> Array:
	var lista := []
	for id in johnny.huecos.values() + armas_guardadas:
		if Armas.al_baul(id, johnny.calidad(id)):
			lista.append({"id": id, "calidad": johnny.calidad(id)})
	for k in lanzables.mano + lanzables.repuesto:
		var calidad := Lanzables.calidad_de(k)
		if calidad > 0 and lanzables.cuantas(k) > 0:
			lista.append({"id": Lanzables.tipo_de(k), "calidad": calidad, "n": lanzables.cuantas(k)})
	return lista


# El arma de repuesto de ese tipo ("cuerpo" o "fuego"), o "" si no lleva
func repuesto(tipo: String) -> String:
	for id in armas_guardadas:
		if Armas.datos(id).tipo == tipo:
			return id
	return ""


# Delante del armarito de un baño: el botiquín cura (más con Sanitario); con la vida llena se deja para luego
func coger_botiquin(armarito: Node2D) -> void:
	if johnny.vida >= johnny.vida_tope():
		numero(armarito.position + Vector2(0, -40), "Tienes la vida al máximo", Tema.TINTA)
		return
	armarito.vaciar()
	curar_con(cura_botiquin(), armarito)


# Cura "cura" de vida, con el número verde y las chispas encima de "sobre" (el armarito o Johnny)
func curar_con(cura: int, sobre: Node2D) -> void:
	johnny.curar(cura)
	Sonido.tocar("gema")
	numero(sobre.position + Vector2(0, -40), "+%d" % cura, Tema.VERDE)
	for i in 12:
		Particulas.soltar(sobre, sobre.global_position + Vector2(0, -50),
			Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0), Tema.VERDE, 4.0, 0.6)


# Usar desde el inventario un objeto de curar de la mochila (Objetos.USABLES: el botiquín de la farmacéutica y las
# vendas): se gasta y cura lo suyo. Si no se puede (con la vida llena), no se gasta y devuelve por qué
func usar_objeto(id: String) -> String:
	if not id in mochila or not id in Objetos.USABLES:
		return "No se puede usar"
	if johnny.vida >= johnny.vida_tope():
		return "Tienes la vida al máximo: guárdalo para luego"
	mochila.remove_at(mochila.rfind(id))
	curar_con(cura_de(id), johnny)
	return ""


# Lo que cura un botiquín (el de los baños o el de la farmacéutica)
func cura_botiquin() -> int:
	return cura_de("botiquin")


# Lo que cura un objeto de curar: lo suyo (el botiquín, BOTIQUIN; los demás, su "cura" de Objetos.USABLES), más el
# talento Sanitario y, con la Alerta 4, la mitad
func cura_de(id: String) -> int:
	var base: int = BOTIQUIN if id == "botiquin" else Objetos.USABLES[id].cura
	return roundi((base + johnny.stats.botiquin_extra) * Alerta.botiquin())


# El inventario (Tab, I o Select), el baúl o el banco de trabajo: se para el juego y sale su pantalla
func abrir_cosas(que: String) -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused or presentacion.activa:
		return
	get_tree().paused = true
	inventario.abrir(que, self)


# La taquilla de las skins de Johnny (ui/taquilla.gd): se para el juego y sale su ventanita
func abrir_taquilla() -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused or presentacion.activa:
		return
	get_tree().paused = true
	taquilla.abrir(self)


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
	if terminada or not johnny.vivo or menus.abierto != "" or presentacion.activa:
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
	var abierta := [0]      # la alerta que se abre al ganar (0: ninguna)
	var mejor := [false]    # el reto del día: se ha mejorado la marca de hoy
	var extra := Alerta.dolares_extra(dolares) if gano else 0   # los dólares de más por la alerta
	var nuevo := supervivientes.rescatado_nuevo() if gano else {}
	var equipo := equipo_encima() if gano else []
	var s := Guardado.cambiar(func(g):
		# el superviviente rescatado en esta partida se viene a vivir a las viviendas (su puerta ya estará abierta)
		if not nuevo.is_empty() and not nuevo.id in g.rescatados:
			g.rescatados.append(nuevo.id)
		g.muertos += muertos
		var e := Guardado.edificio(g, edificio)
		# el reto del día (reto.gd) lleva su marca aparte: no toca las plantas ni los tiempos del edificio
		if Reto.activo:
			mejor[0] = Reto.apuntar(g, edificio, planta.num, gano, duracion)
		else:
			g.mejor_planta = maxi(g.mejor_planta, planta.num)
			e.mejor_planta = maxi(e.mejor_planta, planta.num)
		if gano:
			# los objetos de la mochila pasan al baúl (si caes, se pierden); el botiquín, no (se pierde). Y las armas que
			# lleva y los paquetes de arrojables mejorados (equipo_encima), aunque no quepan
			for id in mochila:
				if Objetos.al_baul(id):
					g.baul[id] = g.baul.get(id, 0) + 1
			g.baul_equipo.append_array(equipo)
			g.dolares += dolares + extra
			g.dolares_total += dolares + extra
			g.victorias += 1
		if gano and not Reto.activo:   # (el reto no cuenta como edificio completado ni abre alertas)
			e.victorias += 1
			e.completado = true
			# completarlo con una alerta abre la siguiente (alerta.gd)
			if Alerta.nivel >= e.alerta_max and Alerta.nivel < Alerta.MAX:
				e.alerta_max = Alerta.nivel + 1
				abierta[0] = e.alerta_max
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
		if sitio.has("apt") and sitio.tipo not in ["viviendas", "mantenimiento"]:
			apartamentos += 1
			if sitio.get("visitado", false):
				visitados += 1
	var tiempo := ""
	if gano:
		tiempo = "%d:%02d%s" % [int(duracion) / 60, int(duracion) % 60, " · ¡récord!" if record[0] else ""]
	menus.fin({
		"gano": gano,
		"titulo": ("¡Reto completado!" if Reto.activo else "¡Edificio completado!") if gano else "¡Derrota!",
		"reto": Reto.nombre() if Reto.activo else "",
		"mejor": mejor[0],
		"marca": Reto.marca(Reto.ficha(s, edificio), true) if Reto.activo else "",
		"sub": ("Has limpiado %s de arriba abajo%s" % [ed.el_nombre, "" if nuevo.is_empty()
			else ". %s se viene a vivir a su habitación, junto a la sala de mantenimiento" % nuevo.nombre]) if gano
			else ("Caíste en la %s de %s" % [planta.nombre.to_lower(), ed.el_nombre]),
		"plantas": "%d / %d" % [Planta.PLANTAS if gano else planta.num - 1, Planta.PLANTAS],
		"muertos": muertos,
		"visitados": "%d / %d" % [visitados, apartamentos],
		"tiempo": tiempo,
		"dolares": dolares,
		"cartera": s.dolares,
		"alerta": Alerta.nivel,
		"extra": extra,
		"abierta": abierta[0],
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
	var de_mentira := en_pruebas()   # en la sala de pruebas no cuentan: ni se apuntan, ni sueltan nada
	if not de_mentira:
		Bestiario.apuntar(tipo)   # visto: al bestiario de las Colecciones del ordenador
	zombi.position = donde
	if "color_sangre" in zombi:
		zombi.color_sangre = MANCHAS.get(tipo, SANGRE)
	if "talla_restos" in zombi:
		zombi.talla_restos = {"rapido": "pequeno", "venenoso": "grande"}.get(tipo, "mediano")   # el rápido es un niño
	# Al caer: se cuenta, y a veces suelta un billete (la portera, varios)
	if zombi.has_signal("prendido") and not de_mentira:   # la portera no arde
		zombi.prendido.connect(logros.zombi_prendido)
	zombi.murio.connect(func():
		if de_mentira:
			sangre(tipo, zombi)
			return
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
		# y a veces un objeto (los jefes, dos seguros), de los que salen aquí
		var tienda: String = planta.sitios[aqui].get("tienda", "")
		if tipo in JEFES:
			for i in 2:
				soltar_objeto(Objetos.al_azar(edificio, tienda), zombi.position)
		else:
			var obj := Objetos.que_suelta(tipo, edificio, tienda)
			if obj != "":
				soltar_objeto(obj, zombi.position)
		# y piezas de mejora de las armas: los jefes, cuatro seguras; cualquier otro zombi, a veces una
		if tipo in JEFES:
			for pieza in Objetos.piezas_de_jefe():
				soltar_objeto(pieza, zombi.position)
		else:
			var pieza := Objetos.pieza_de_zombi()
			if pieza != "":
				soltar_objeto(pieza, zombi.position)
		# Caníbal: cada zombi que matas te cura
		if johnny.stats.canibal > 0.0:
			johnny.curar(maxi(1, roundi(johnny.stats.canibal * johnny.stats.vida_max)))
		# algunos jefes, la primera vez, sueltan una skin (skins.gd: la portera, el portero; el Glotón, el glotón; el
		# Gymbro, el gymbro), para siempre (se pone en la taquilla)
		var skin := Skins.de_jefe(tipo)
		if skin != "" and Skins.desbloquear(skin):
			Sonido.tocar("compra")
			numero(zombi.position + Vector2(0, -40), "¡Skin nueva!", Tema.TINTA)
			decir("Skin nueva: %s. Póntela en la taquilla de la sala de mantenimiento" % Skins.nombre(skin), 4.0)
		# el jefe final (el gerente mutado): su página del dosier y el helicóptero de Velaria
		if tipo in JEFES and not final_de(tipo).is_empty():
			fin_del_edificio()
		# la portera: un poco después de caer su cuerpo, las mutaciones (el jefe final, no: se acaba el edificio)
		if tipo in JEFES and final_de(tipo).is_empty():
			await get_tree().create_timer(2.0, false).timeout
			abrir_mutacion())
	if tipo in JEFES:
		# Cada planta, un 25 % más dura (como el vecino del juego JS), y con la Alerta 3, más aún y se enfada antes.
		# El jefe final (el gerente), con su vida justa: ya está en la última planta
		var de_final := final_de(tipo)
		var por_planta := pow(1.25, planta.num - 1) if de_final.is_empty() else 1.0
		zombi.vida_max = int(zombi.vida_max * por_planta * Alerta.jefe_vida())
		zombi.enfado = Alerta.jefe_enfado()
		# Su barra de vida grande, arriba (ui/barra_jefe.gd), y los vecinos que llama
		var barra_jefa: BarraJefe = $Pantalla/Jefa
		var el: String = de_final.get("el_final", Edificios.MINIJEFES.get(tipo, {}).get("el", "la portera"))
		$Pantalla/Jefa/Nombre.text = el.left(1).to_upper() + el.substr(1)
		barra_jefa.jefe = zombi
		zombi.vida_cambiada.connect(func(vida, maxima):
			barra_jefa.max_value = maxima
			barra_jefa.value = vida
			barra_jefa.visible = vida > 0 and not presentacion.activa)   # (durante la presentación, oculta)
		# la armadura (los suplementos del Gymbro enfadado), en una barra fina debajo de la de vida
		var barra_armadura := armadura_jefe()
		barra_armadura.hide()
		if zombi.has_signal("armadura_cambiada"):
			zombi.armadura_cambiada.connect(func(armadura, maxima):
				barra_armadura.max_value = maxima
				barra_armadura.value = armadura
				barra_armadura.visible = armadura > 0)
		zombi.pide_zombi.connect(meter_zombi)
	elif "velocidad" in zombi:
		# con la Alerta 2, todos un poco más rápidos; con el reto del día "Zombis rápidos", bastante más
		zombi.velocidad *= Alerta.velocidad() * Reto.velocidad()
	mapa.cosas.add_child(zombi)
	return zombi


# La barra de armadura de los jefes (la del Gymbro): se hace la primera vez que hace falta, pegada debajo de la
# barra de vida grande, del ancho de su hueco y más fina, de color acero (la pinta la barra del jefe, con el mismo
# estilo: ui/barra_jefe.gd, pintar_armadura)
func armadura_jefe() -> ProgressBar:
	var barra: ProgressBar = $Pantalla/Jefa.get_node_or_null("Armadura")
	if barra:
		return barra
	barra = ProgressBar.new()
	barra.name = "Armadura"
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.position = Vector2(BarraJefe.HUECO.position.x - 2, BarraJefe.ALTO)
	barra.size = Vector2(BarraJefe.HUECO.size.x + 4, 8)
	barra.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	barra.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	barra.draw.connect(Callable($Pantalla/Jefa, "pintar_armadura").bind(barra))
	barra.visible = false
	$Pantalla/Jefa.add_child(barra)
	return barra


# El edificio del que "tipo" es el jefe final (el gerente, del centro comercial; edificios.gd, "final"), o {}
func final_de(tipo: String) -> Dictionary:
	for e in Edificios.LISTA.values():
		if e.get("final", "") == tipo:
			return e
	return {}


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa") and not cambiando:
		get_viewport().set_input_as_handled()
		pausar()
		return
	if evento.is_action_pressed("inventario") and not cambiando:
		get_viewport().set_input_as_handled()
		abrir_cosas("inventario")
		return
	if not (evento is InputEventKey and evento.pressed and not evento.echo) or cambiando or presentacion.activa:
		return
	if evento.keycode == KEY_F11:
		pruebas()
	elif evento.keycode == KEY_P and aqui == planta.armas:
		abrir_panel_pruebas()
	elif aqui == planta.armas and panel_pruebas.atajo(evento):
		pass   # (1 a 8, un zombi; Mayús + 1 a 0, un jefe: ui/panel_pruebas.gd)


# ═════════════ La sala de pruebas ═════════════

# F11: a la sala de pruebas (sala_armas.gd) desde donde se esté y, desde ella (o desde la exposición, a la que se va
# con su panel), de vuelta al mismo sitio y al mismo punto. Con la puerta del apartamento cerrada, no se puede
func pruebas() -> void:
	if cambiando or terminada or not johnny.vivo:
		return
	if en_pruebas():
		var volver := de_pruebas
		de_pruebas = {}
		if volver.is_empty() or not is_same(volver.planta, planta):
			# (se ha cambiado de planta desde el panel: a la sala de mantenimiento o, si no la hay, al pasillo)
			await montar(maxi(planta.mantenimiento, 0), 0)
			return
		await montar(volver.sitio, 0)
		johnny.position = volver.pos
		johnny.get_node("Camara").reset_smoothing()
		return
	if cerrada:
		decir("Con la puerta cerrada no se puede ir a la sala de pruebas")
		Sonido.tocar("no")
		return
	sitio_pruebas()
	de_pruebas = {"planta": planta, "sitio": aqui, "pos": johnny.position}
	await montar(planta.armas, 0)
	decir("Sala de pruebas · P: panel de pruebas · F11: volver", 3.0)


# La sala de pruebas y la exposición, como dos sitios más de la planta (la planta baja ya las trae: planta.gd)
func sitio_pruebas() -> void:
	if planta.armas >= 0:
		return
	planta.armas = planta.sitios.size()
	planta.sitios.append(Planta.sala_armas(-1))
	planta.expo = planta.sitios.size()
	planta.sitios.append(Planta.exposicion(planta.armas))


# Si Johnny está en la sala de pruebas o en la exposición: lo que pasa ahí no cuenta
func en_pruebas() -> bool:
	return aqui == planta.armas or aqui == planta.expo


# La P en la sala de pruebas: se para el juego y sale el panel de pruebas (ui/panel_pruebas.gd)
func abrir_panel_pruebas() -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused or presentacion.activa:
		return
	get_tree().paused = true
	panel_pruebas.abrir(self)


# El panel de pruebas: un científico muerto a los pies de Johnny, cada vez con la siguiente página de todos los edificios (su
# piel y su pelo, o su ropa). Solo para verlo: su página se coge, pero no se lee ni se guarda
func probar_cientifico() -> void:
	var paginas := []
	for d in Historia.DOSIERES.values():
		paginas.append_array(d.paginas)
	var p: Dictionary = paginas[de_prueba % paginas.size()]
	de_prueba += 1
	var cuerpo := CIENTIFICO.new()
	cuerpo.montar(p, johnny.position + Vector2(0, 70))
	cuerpo.johnny = johnny
	mapa.cosas.add_child(cuerpo)
	decir("Científico de prueba: " + p.cuerpo)


# El panel de pruebas: derecho a la azotea, sin subir planta a planta
func ir_a_azotea() -> void:
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_tipo("llegada"))
	decir("Azotea · ¡El último combate del edificio!", 2.5)


# El panel de pruebas (los de los Apartamentos: el Glotón, el Gymbro, el jefe de bomberos y la portera): derecho a su
# habitación, sin jugar hasta ella. Rehace la planta que le tocó en el sorteo de esta partida (como recién llegado) y
# Johnny entra por la puerta: el jefe sale como siempre, con su presentación (acaba cuando ya ha salido)
func ir_al_jefe(tipo: String) -> void:
	var num := orden_jefes.find(tipo) + 1
	if num <= 0 or jefe_de(num) != tipo:
		decir("Ese jefe no está en este edificio")
		return
	nueva_planta(num)
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			await montar(i, 0)
			return


# El panel de pruebas: mete en el baúl de verdad 10 piezas de cada familia (Objetos.PIEZAS) y unas armas y paquetes de
# arrojables de cada calidad (PRUEBA_EQUIPO), para probar el baúl y el banco (aunque no quepan)
const PRUEBA_EQUIPO := [{"id": "bate", "calidad": 1}, {"id": "escopeta", "calidad": 2}, {"id": "lanzallamas", "calidad": 3},
	{"id": "pistola", "calidad": 2}, {"id": "molotov", "calidad": 2, "n": 4}, {"id": "congeladora", "calidad": 3, "n": 3}]

func dar_objetos() -> void:
	Guardado.cambiar_real(func(g):
		for id in Objetos.PIEZAS:
			g.baul[id] = g.baul.get(id, 0) + 10
		g.baul_equipo.append_array(PRUEBA_EQUIPO.duplicate(true)))
	decir("10 piezas de cada familia y unas armas y arrojables mejorados al baúl")
