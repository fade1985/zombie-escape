# La partida: genera la planta (planta.gd), monta el sitio en el que está Johnny (mapa.gd) y, al cruzar una
# puerta, funde a negro y monta el del otro lado. Lo que se deja atrás no se tira: su mapa se guarda entero, con los
# zombis, los cuerpos, la sangre y lo que haya por el suelo, y al volver sigue todo como estaba (mapas). Lleva también
# la pantalla (vida, arma, avisos) y las reglas del mapa:
#   - Al entrar en un apartamento la puerta se cierra, y no se abre hasta que no queda ni un zombi.
#   - El apartamento de la jefa está cerrado con llave; la lleva un zombi al azar de los otros apartamentos y la suelta
#     al caer (zombi_de_la_llave).
#   - Al entrar, aparece la portera. Cuando cae, se abren las escaleras a la planta siguiente y Johnny arregla
#     el ascensor, que solo baja a la sala de mantenimiento y vuelve a esa planta (arreglar_ascensor).
#   - Después de la última planta, el edificio está limpio: cartel de victoria.
# La partida empieza en la sala de mantenimiento de la planta baja (por su puerta de la derecha se va a las viviendas
# de los supervivientes rescatados, mapa/viviendas.gd). Abajo, en la franja del muro, va el HUD (hud.gd)
# y arriba a la derecha, el minimapa. Esc o Start abren la pausa (menus.gd).
#
# Dinero y guardado (como game.js y game-combate.js del JS): los zombis sueltan billetes a veces (la portera,
# varios). Los dólares de la partida se guardan al acabarla: todos si completas el edificio; si caes (o abandonas),
# la mitad (DOLARES_AL_CAER). Al acabar
# (ganes, caigas o abandones) se guardan los récords y los zombis matados (guardado.gd).
#
# El ordenador de la sala de mantenimiento (ui/ordenador.gd): al arrimarse a su mesa, el juego se pausa y sale
# ConserjeOS, para comprar puntos de talento, subir talentos y comprar armas con los dólares ahorrados. Los
# talentos (talentos.gd) se aplican a Johnny al empezar la partida y al comprarlos. La taquilla (ui/taquilla.gd),
# igual: al arrimarse sale la ventanita para elegir la skin de Johnny (skins.gd).
#
# Para probar: F9, desde cualquier sitio, lleva a la sala de pruebas (sala_armas.gd) y, otra vez, de vuelta adonde
# se estaba. Allí, 1 a 8 sacan un zombi y Mayús + 1 a 0, un jefe, y la P abre el panel de pruebas (ui/panel_pruebas.gd): sacar jefes y zombis, encender y apagar las
# ayudas, ir a la exposición o a la sala de un jefe... Lo que pasa en la sala no cuenta (en_pruebas).
#
# Los tutoriales (tutoriales.gd, ui/tutorial.gd): la primera vez que Johnny se encuentra algo nuevo, una ventana con el
# juego parado explica qué pasa y cómo se hace (tutorial(); los de lo que cambia en Johnny o en la mochila, en
# mirar_tutoriales). En la sala de pruebas no salen, ni en la partida de prueba salvo en la suya (--tutorial).
#
# Con "-- --captura" no se juega esta, sino la partida de prueba (escenas/partida_prueba.tscn): la misma partida
# más las fotos y las comprobaciones, que están en scripts/pruebas/partida_prueba.gd.
extends Node2D

const ZOMBIS := {
	"normal": preload("res://escenas/personajes/zombi_normal.tscn"),
	# la vecina: dibujada entera con GPT (tools/zombi_gpt.py, 8 nov), igual que el vecino; sale en los apartamentos
	"vecina": preload("res://escenas/personajes/zombi_vecina.tscn"),
	"lento": preload("res://escenas/personajes/zombi_lento.tscn"),
	"rapido": preload("res://escenas/personajes/zombi_rapido.tscn"),
	"explosivo": preload("res://escenas/personajes/zombi_explosivo.tscn"),
	"tentaculos": preload("res://escenas/personajes/zombi_tentaculos.tscn"),
	"venenoso": preload("res://escenas/personajes/zombi_venenoso.tscn"),
	"portera": preload("res://escenas/personajes/portera.tscn"),
	"guardia": preload("res://escenas/personajes/zombi_guardia.tscn"),   # el de la tarjeta (centro comercial)
	"vigilante": preload("res://escenas/personajes/zombi_vigilante.tscn"),       # los del centro comercial
	"dependienta": preload("res://escenas/personajes/zombi_dependienta.tscn"),
	"oficinista": preload("res://escenas/personajes/zombi_oficinista.tscn"),   # los de Torre Velaria
	"escolta": preload("res://escenas/personajes/zombi_escolta.tscn"),
	"antidisturbios": preload("res://escenas/personajes/antidisturbios.tscn"),   # minijefes del centro comercial
	"mascota": preload("res://escenas/personajes/mascota.tscn"),
	"cocinero": preload("res://escenas/personajes/cocinero.tscn"),
	"modista": preload("res://escenas/personajes/modista.tscn"),
	"gerente": preload("res://escenas/personajes/gerente.tscn"),   # el jefe final del centro comercial (la azotea)
	"gloton": preload("res://escenas/personajes/gloton.tscn"),     # minijefes de los Apartamentos (docs/historial/JEFES_APARTAMENTOS.md)
	"gymbro": preload("res://escenas/personajes/gymbro.tscn"),
	"bombero": preload("res://escenas/personajes/bombero.tscn"),
	"cientifico_jefe": preload("res://escenas/personajes/cientifico_jefe.tscn"),   # el jefe final de los Apartamentos (la azotea)
	"directora": preload("res://escenas/personajes/directora.tscn"),   # minijefes de Torre Velaria (docs/PLAN_TERCER_EDIFICIO.md)
	"informatico": preload("res://escenas/personajes/informatico.tscn"),
	"presentador": preload("res://escenas/personajes/presentador.tscn"),
	"becario": preload("res://escenas/personajes/becario.tscn"),
	"sujeto_1": preload("res://escenas/personajes/sujeto_1.tscn"),   # el jefe final de Torre Velaria (el laboratorio de la planta 40)
}
# Los jefes de planta: barra de vida grande, un 35 % más duros en cada planta (JEFE_POR_PLANTA) y, al caer, billetes,
# munición, objetos y la mutación (el jefe final de un edificio, el gerente, sin lo de la planta ni la mutación: final_de())
const JEFES := ["portera", "antidisturbios", "cocinero", "modista", "mascota", "gerente", "gloton", "gymbro", "bombero",
	"cientifico_jefe", "directora", "informatico", "presentador", "becario", "sujeto_1"]
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
const TERMINAL := preload("res://scripts/mapa/terminal.gd")   # los ordenadores del código de Torre Velaria
const INVENTARIO := preload("res://scripts/ui/inventario.gd")
const PANEL_PRUEBAS := preload("res://scripts/ui/panel_pruebas.gd")
const REFUERZOS := 4               # los vigilantes que llegan al silbato del guardia (y uno más cada dos plantas). M83: antes 2
const REFUERZOS_VELOCIDAD := 165.0 # y lo deprisa que corren (M83: antes 85, la de un vigilante normal)
const BILLETES_GUARDIA := 2
# Los zombis aguantan más según el edificio (12 nov: con la pistola y la fregona se pasaba el juego entero), además de lo
# de cada planta (ZOMBI_POR_PLANTA): los Apartamentos son los de siempre. Los jefes de planta, algo menos por edificio
# (ya suben JEFE_POR_PLANTA); el jefe final y el guardia, con su vida de siempre (el guardia ya sube por planta)
const VIDA_EDIFICIO := {"apartamentos": 1.0, "centro": 1.5, "torre": 2.0}
const VIDA_EDIFICIO_JEFE := {"apartamentos": 1.0, "centro": 1.3, "torre": 1.6}
const JEFE_POR_PLANTA := 1.35     # los jefes de planta, su vida por cada planta que se sube (M72: antes 1,25)
const ZOMBI_POR_PLANTA := 0.1     # los demás zombis, vida y zarpazo de más por cada planta (M72: antes, nada)
const BILLETE_ZOMBI := 0.07        # probabilidad de que un zombi suelte un billete
# La sangre de cada tipo de zombi: el color de su piel (los trozos al reventar) y el de su mancha (del JS)
const PIELES := {"normal": Color("#8fc46a"), "lento": Color("#8fc46a"), "rapido": Color("#9ed36d"),
	"explosivo": Color("#c3d96b"), "tentaculos": Color("#86b8aa"), "venenoso": Color("#b5e655"), "portera": Color("#cbb994"),
	"vigilante": Color("#a6d655"), "dependienta": Color("#93c46a"), "guardia": Color("#a6d655"),
	"oficinista": Color("#9cb87a"), "escolta": Color("#93ad84"),
	"antidisturbios": Color("#3b4252"), "cocinero": Color("#8a9a6a"), "modista": Color("#93b07a"),
	"mascota": Color("#c9a13b"), "gerente": Color("#8f9f80"), "gloton": Color("#b9a06e"), "gymbro": Color("#c2b48a"),
	"bombero": Color("#6b6158"), "cientifico_jefe": Color("#d9d6c8"), "directora": Color("#9aa88a"),
	"informatico": Color("#a3a98c"), "presentador": Color("#a9a56e"), "becario": Color("#9fae86"),
	"sujeto_1": Color("#d6d2c4")}
const MANCHAS := {"explosivo": Color("#2b2633"), "venenoso": Color("#8fd13f"), "tentaculos": Color("#7b4fa0")}
const SANGRE := Color("#7a1f1a")   # la sangre de los demás: rojo oscuro (antes, verde oliva #5b7d3a)
const MUNICION_ZOMBI := 0.06       # ...o una caja de munición, si no ha soltado otra cosa (12 nov: antes 0,10; solo la del arma que lleva)
const ICONO_MP5 := preload("res://assets/ui/iconos/municion-mp5.png")   # la caja de munición con la MP5 en la mano
const BILLETES_JEFA := 8           # los que suelta cada jefe al caer (hasta el 27 oct, 3: lo mismo que 43 zombis)
const DOLARES_AL_CAER := 0.5       # la parte de los dólares recogidos que te quedas si caes o abandonas
const ICONOS_LANZABLES := {"molotov": preload("res://assets/ui/iconos/molotov.png"),
	"granada": preload("res://assets/ui/iconos/granada.png")}
const FUNDIDO := 0.25      # segundos del fundido a negro al cruzar una puerta
const DESPERTAR := 2.4     # tras una derrota, lo que tarda Johnny en levantarse al empezar (despertar)
# [traducir]
const FRASES_DESPERTAR := [   # lo que dice al levantarse (una al azar), encima de su cabeza (gran_aviso)
	"¡UF! ¡VAYA PESADILLA!",
	"¿ME HE VUELTO A DORMIR EN EL TRABAJO?",
	"¡JURARÍA QUE ME ESTABAN MORDIENDO!",
	"¡OTRA VEZ ESE SUEÑO DE DURMIENTES!",
]
# [/traducir]
const ARRIBA_EXTRA := 44   # lo que la cámara deja ver por encima del mapa (la cara del muro de arriba y su moldura)

var planta: Dictionary
var aqui := 0              # el sitio de la planta en el que está Johnny
var mapa: Node2D
# Los mapas de los sitios de esta planta en los que ya se ha entrado (sitio -> mapa). El que no está en uso se queda
# fuera de la escena: ahí no se mueve nada hasta que Johnny vuelve. Al dejar la planta se tiran (tirar_mapas)
var mapas := {}
var guarda_mapas := true   # si se guardan (la partida de prueba hace uno nuevo cada vez, salvo en la suya: --volver)
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
var planta_pagina5 := 1       # la planta (1 a 4) donde puede salir la página 5 del dosier en esta partida (pagina_aqui)
var sala_mantenimiento := {}  # la sala de mantenimiento de la planta baja, para bajar a ella en el ascensor
var sala_viviendas := {}      # y las viviendas de los rescatados, detrás de su puerta de la derecha (viviendas.gd)
var captura := false       # si es la partida de prueba (la pone pruebas/partida_prueba.gd)
var luz := Luz.new()       # la penumbra (luz.gd)
var menus := MENUS.new()   # la pausa y el cartel del final
var ordenador := ORDENADOR.new()   # la pantalla de ConserjeOS
var taquilla := TAQUILLA.new()     # la ventanita de la taquilla de las skins de Johnny (skins.gd)
var panel_pruebas := PANEL_PRUEBAS.new()   # el panel de la sala de pruebas (tecla P allí dentro)
var de_pruebas := {}       # de dónde se vino a la sala de pruebas (F9): {planta, sitio, pos}, para volver allí
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
var guia := Guia.new()             # el tutorial disimulado de la primera partida (guia.gd)
var mochila: Array = []    # los objetos recogidos en esta partida (objetos.gd), uno por cada: al baúl si ganas
var armas_guardadas: Array = []   # las de repuesto: como mucho una de cuerpo a cuerpo y una a distancia (llevar_arma)
var ahorrados := 0         # los dólares guardados de otras partidas
var dolares := 0           # los recogidos en esta partida
var muertos := 0           # zombis matados en esta partida
var matados := {}          # los mismos, por tipo ({"normal": 12, ...}): al acabar, a los de siempre (Colecciones)
var duracion := 0.0        # segundos jugados (sin contar la pausa)
var raton := Raton.new()
var terminada := false
var al_empezar := {}       # lo que ya se tenía al empezar (logros, skins, páginas...): el cartel del final enseña lo
                           # nuevo (conseguido())
var avisos_dichos := {}   # los avisos de Johnny que solo salen una vez (aviso_una_vez): «portal», «ascensor_2»...
var cola_tutoriales: Array = []   # los tutoriales que esperan a salir (tutorial()); el primero, el que sale o va a salir
var tutoriales_prueba := false    # en la partida de prueba no salen, salvo en la suya (--tutorial)
var guiado_prueba := false        # ni la guía de la primera partida, salvo en la suya (--guiado)
var relatos_prueba := false       # ni los textos de la historia, salvo en la suya (--relato)
var guarda_partida := true        # si se apunta la partida a medias al empezar cada planta (partida_guardada.gd; la de
                                  # prueba, no, salvo en la suya: --continuar)
var semilla_propia := false       # si la semilla de las plantas (Planta.semilla) la ha puesto esta partida: se quita al salir

@onready var johnny := $Johnny
@onready var lugar: Label = $Pantalla/Lugar
@onready var aviso: Label = $Pantalla/Mensaje
var aviso_tween: Tween     # el que va borrando el aviso (decir)
var de_prueba := 0         # «Científico muerto» del panel de pruebas: la página del siguiente (probar_cientifico)
@onready var negro: ColorRect = $Pantalla/Negro


func _ready() -> void:
	Controles.aplicar()   # las teclas cambiadas en Opciones (por si se abre la partida directamente)
	Sonido.edificio = edificio   # al explorar, la música de este edificio (Sonido.EXPLORAR)
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	# los textos de la pantalla, con la fuente pixel art de los menús
	for etiqueta in [lugar, aviso]:
		etiqueta.theme = Tema.crear()
	# las explicaciones blancas de abajo en el centro (decir) ya no se ven: el dueño las quitó todas. Se siguen
	# escribiendo en la etiqueta, escondida, porque las pruebas las leen
	aviso.visible = false
	johnny.murio.connect(_al_morir_johnny)
	johnny.resucito.connect(func():
		Sonido.tocar("limpio")
		decir(Idioma.t("¡Desfibrilador! Vuelves con toda la vida (solo una vez por edificio)"), 3.5))
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
	menus.menu_principal.connect(ir_al_menu)
	add_child(ordenador)
	ordenador.apagado.connect(func(): get_tree().paused = false)
	add_child(inventario)
	inventario.cerrado.connect(func(): get_tree().paused = false)
	add_child(taquilla)
	# el ratón: escondido jugando en el modo asistido, la mirilla en el libre y la flecha en los menús (ui/raton.gd)
	raton.johnny = johnny
	raton.partida = self
	add_child(raton)
	add_child(panel_pruebas)
	panel_pruebas.partida = self   # (los atajos funcionan sin haber abierto antes el panel)
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
	add_child(guia)
	guia.preparar(self)
	# Los controles del móvil (solo salen en pantallas táctiles)
	var tactil := Tactil.new()
	tactil.partida = self
	tactil.johnny = johnny
	add_child(tactil)
	get_viewport().size_changed.connect(reencuadrar)

	guarda_partida = not captura
	guarda_mapas = not captura
	Tutoriales.marcas = not captura   # (los «!» de la sala de mantenimiento: en la partida de prueba, solo en la suya)
	if captura:
		preparar_prueba()   # el guardado de prueba, la alerta y el evento que se piden
	# «Continuar partida» del menú: la partida a medias, al principio de la planta en la que iba (partida_guardada.gd)
	var foto := PartidaGuardada.continuar
	PartidaGuardada.continuar = {}
	if not foto.is_empty():
		continuar_partida(foto)
		return
	if guarda_partida and Planta.semilla == 0:
		# una partida normal también lleva su semilla: así su planta sale igual si se cierra el juego y se continúa
		Planta.semilla = randi_range(1, 2000000000)
		semilla_propia = true
	if Reto.activo:
		# el reto del día (reto.gd): también el dado de siempre con la semilla de hoy, para que el orden de los
		# minijefes, la planta del superviviente y los eventos sorpresa salgan iguales para todo el mundo
		seed(Planta.semilla)
	# Empieza una partida: se apunta, y se cuenta con los dólares ahorrados. Si la de antes acabó en derrota, Johnny se
	# despierta en la sala de mantenimiento (despertar)
	var despierta: bool = Guardado.cargar().pesadilla
	var s := Guardado.cambiar(func(g):
		g.pesadilla = false
		g.partidas += 1
		Guardado.edificio(g, edificio).partidas += 1
		if Reto.activo:
			Reto.ficha(g, edificio).intentos += 1)
	ahorrados = s.dolares
	# la primera partida enseña a jugar en la planta baja de los Apartamentos (guia.gd)
	guia.activa = (s.partidas == 1 or s.guia_otra_vez) and edificio == "apartamentos" and not Reto.activo \
		and Guardado.ajuste("tutoriales") and (not captura or guiado_prueba)
	if guia.activa and s.guia_otra_vez:
		Guardado.cambiar(func(g): g.guia_otra_vez = false)   # (repetida una vez: vale solo para esta partida)
	al_empezar = {"logros": s.logros.keys(), "skins": s.skins.duplicate(), "paginas": s.paginas.duplicate(),
		"bestiario": s.bestiario.duplicate(), "encontrados": s.encontrados.duplicate(),
		"mejor_planta": Guardado.edificio(s, edificio).mejor_planta}
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
	planta_pagina5 = randi_range(1, Planta.PLANTAS - 1)   # (la 5, si ya toca, en una sola planta al azar)
	if captura:
		ordenar_jefes_prueba()   # el jefe que se quiere ver, en la 1ª planta
	if guarda_partida:
		PartidaGuardada.apuntar(self, 1)
	nueva_planta(1)
	# en la sala de mantenimiento, en medio (en medio del despacho)
	montar(planta.mantenimiento, 0, false)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	# la historia empieza con la introducción: sale ya, en negro desde el primer fotograma. Con el juego parado no corre
	# nada; la guía, el aviso de abajo y las ventanas empiezan al cerrarla
	if edificio == "apartamentos":
		await ver_relato("intro")
	if despierta and not captura:
		await despertar()
	if captura:
		empezar_prueba()
	else:
		await mutacion_al_empezar()
		# (sin la frase del objetivo, que ya lo explica el ordenador: solo la alerta, el reto y el botiquín, si los hay)
		var al_empezar: Array = []
		if Alerta.nivel > 0:
			al_empezar.append("%s: %s" % [Alerta.nombre(), Alerta.regla(Alerta.nivel, edificio)])
		if Reto.activo:
			al_empezar.append(Reto.aviso())
		if botiquin:
			al_empezar.append(Idioma.t("La Farmacéutica te ha preparado un botiquín: está en la mochila"))
		if not al_empezar.is_empty():
			decir("\n".join(al_empezar), 4.0)
		supervivientes.avisar_pista(4.8)   # (la recepcionista rescatada: dónde está la llave o el código)
		get_tree().create_timer(0.8, false).timeout.connect(tutorial.bind(tutorial_al_empezar()))


# La ventana del principio de la partida: en la primera (con la guía, guia.gd), «Moverse y esquivar», y lo demás de
# «Cómo se juega» lo enseña la guía con sus pistas (por eso se apunta ya como visto, como hacía su pista de esquivar);
# en las demás, «Cómo se juega», que ya cuenta moverse y esquivar
func tutorial_al_empezar() -> String:
	if not guia.activa:
		return "jugar"
	Tutoriales.apuntar("jugar")
	return "moverse"


# Empieza con una partida guardada (partida_guardada.gd): todo como estaba al llegar a su planta, sin volver a contar
# la partida ni el intento del reto, y Johnny entra por las escaleras (en la planta baja, en la sala de mantenimiento)
func continuar_partida(foto: Dictionary) -> void:
	PartidaGuardada.poner(self, foto)
	ahorrados = Guardado.cargar().dolares
	var num: int = foto.planta
	if num > 1:
		# la sala de mantenimiento y las viviendas son las de la planta baja (nueva_planta(1) las apunta): se sacan de ella
		var baja := Planta.generar(1, edificio, jefe_de(1))
		sala_mantenimiento = baja.sitios[baja.mantenimiento]
		if baja.viviendas >= 0:
			sala_viviendas = baja.sitios[baja.viviendas]
	nueva_planta(num)
	if num == 1:
		montar(planta.mantenimiento, 0, false)
		johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	else:
		montar(0, puerta_de_llegada(), false)
	johnny.get_node("Camara").reset_smoothing()
	if captura:
		empezar_prueba()
	else:
		decir("%s · %s" % [Idioma.t("Partida recuperada"), Planta.nombre_de(planta)], 3.0)


func _exit_tree() -> void:
	if semilla_propia:
		Planta.semilla = 0   # (la siguiente partida sortea la suya)
	tirar_mapas()


# Lo que hace la partida de prueba al empezar (pruebas/partida_prueba.gd). En la partida de verdad, nada
func preparar_prueba() -> void:
	pass


func ordenar_jefes_prueba() -> void:
	pass


func empezar_prueba() -> void:
	pass


func nueva_planta(num: int) -> void:
	guardar_guardia()   # el guardia es de la planta que se deja: se apunta antes de cambiarla (la azotea ni tiene)
	tirar_mapas()
	planta = Planta.generar(num, edificio, jefe_de(num))
	Registro.apuntar("Planta %d de %s%s" % [num, edificio, " (azotea)" if planta.get("azotea", false) else ""])   # no-tr (para el registro: registro.gd)
	if planta.mantenimiento >= 0:
		sala_mantenimiento = planta.sitios[planta.mantenimiento]
	if planta.viviendas >= 0:
		sala_viviendas = planta.sitios[planta.viviendas]
	supervivientes.nueva_planta()
	logros.planta_nueva()
	eventos.nueva_planta()
	guia.nueva_planta()   # (después de los eventos: en la planta baja de la guía no hay)
	johnny.escudo = johnny.stats.escudo + johnny.stats.escudo_mut   # Acero y Endurecimiento: escudo nuevo en cada planta
	johnny.aliento_usado = false   # (y el Segundo aliento vuelve a estar listo)


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
	EfectoSuelo.precalentar(johnny.get_parent(), "mutar")   # (que no dé un tirón al elegir)
	get_tree().paused = true
	if puede_tutorial("mutaciones"):
		await ver_tutorial("mutaciones")   # la primera vez, antes de las cartas, qué son
	menus.mutacion(opciones, mutaciones.tengo.size(), elegir_mutacion)


# La skin del Sujeto 1 (skins.gd): al empezar la partida, el recuadro de las mutaciones para elegir una. Espera a que
# la elija (con el juego parado) para que el aviso de la planta salga después
func mutacion_al_empezar() -> void:
	if not Skins.mutacion(johnny.skin) or not mutaciones.tengo.is_empty():
		return
	await get_tree().create_timer(0.6, false).timeout
	await abrir_mutacion()
	while menus.abierto == "mutacion":
		await get_tree().process_frame


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
	EfectoSuelo.soltar(johnny, "mutar", Vector2.ZERO)   # (M54: el ADN que sube, las ondas y las burbujas; le sigue)
	var m := Mutaciones.mutacion(id)
	decir(Idioma.t("¡%s!  %s") % [m.nombre, m.desc], 4.0)


# Johnny se ha arrimado a la mesa del ordenador: se pausa el juego y se enciende
func abrir_ordenador() -> void:
	if terminada or cambiando or not johnny.vivo:
		return
	get_tree().paused = true
	if puede_tutorial("ordenador"):
		await ver_tutorial("ordenador")
	ordenador.encender(self)


func puerta_de_tipo(tipo: String) -> int:
	var salidas: Array = planta.sitios[0].salidas
	for i in salidas.size():
		if salidas[i].tipo == tipo:
			return i
	return 0


# La salida por la que se llega a la planta en la que se está: el portal de la izquierda en la planta baja y la escalera
# de la azotea; en las demás plantas, las escaleras de la derecha (las mismas por las que se salió de la de abajo)
func puerta_de_llegada() -> int:
	var i := puerta_de_tipo("llegada")
	return i if planta.sitios[0].salidas[i].tipo == "llegada" else puerta_de_tipo("escaleras")


# Monta el sitio "idx" y pone a Johnny delante de su salida "por". La primera vez se hace su mapa; al volver, se saca
# el que se guardó al salir, con todo como estaba (lo que no hay que repetir va con "nuevo")
func montar(idx: int, por: int, fundir := true) -> void:
	cambiando = true
	if fundir:
		# (el fundido no se frena en los parones de los golpes, Temblor.parar)
		await create_tween().set_ignore_time_scale().tween_property(negro, "modulate:a", 1.0, FUNDIDO).finished
	# Johnny pasa de un mapa a otro; el viejo se quita de la escena antes de poner el nuevo (si no, su
	# navegación y sus muros se mezclarían con los del nuevo). Y con él, los de su equipo
	supervivientes.recoger()
	eventos.recoger()
	joyeria.recoger()
	guia.recoger()
	johnny.get_parent().remove_child(johnny)
	if mapa:
		dejar_mapa()
	guardar_guardia()
	jefa = null
	jefa_salio = false
	$Pantalla/Jefa.hide()
	aqui = idx
	var sitio: Dictionary = planta.sitios[idx]
	sitio.visitado = true
	var nuevo: bool = not mapas.has(idx)
	if nuevo:
		hacer_mapa(idx, sitio)
	else:
		sacar_mapa(idx)
	mapa.cosas.add_child(johnny)
	johnny.position = mapa.puertas[por].llegada()
	johnny.velocity = Vector2.ZERO
	# En la sala de un jefe que aún no ha caído, Johnny no se mueve desde que entra hasta que acaba la presentación del
	# jefe (ni en el fundido ni en lo que tarda en salir; luego le para la presentación). Si ya había salido, no se repite
	var presentara: bool = sitio.tipo == "jefe" and not sitio.limpio and not jefa_salio and (not captura or presentar_en_prueba)
	if presentara:
		johnny.set_physics_process(false)
		johnny.quedarse_quieto()
	supervivientes.al_montar(idx, sitio)
	joyeria.al_montar(idx, sitio, nuevo)   # la puerta blindada de la cámara acorazada, y la tarjeta dorada si está en el suelo
	encuadrar(sitio)
	johnny.get_node("Camara").reset_smoothing()
	eventos.al_montar(idx, sitio, nuevo)   # (antes de la luz: el apagón la cambia)
	luz.poner_sitio(sitio.tipo)

	# Los zombis que esperan dentro, dormidos (la primera vez y si el piso aún no se ha limpiado)
	for z in [] if sitio.limpio or not nuevo else sitio.zombis:
		var zombi := meter_zombi(z.tipo, z.pos)
		zombi.dormido = true
		zombi.zona = mapa.zona_en(z.pos)
		if z.get("llave", false):
			zombi_de_la_llave(zombi, z)
	if nuevo and sitio.tipo == "pasillo" and planta.get("guardia", {}).get("vivo", false):
		poner_guardia()
	cerrada = false
	actualizar_puertas()
	poner_lugar()
	guia.al_montar()
	if sitio.tipo == "viviendas":
		tutorial("trasteros")   # (cómo van los supervivientes: el «!» de su puerta en la sala de mantenimiento)
	if sitio.get("peligros", []).any(func(p): return p.tipo in ["frio", "fuego", "agua"]):
		tutorial("peligros")   # (la cámara frigorífica, la cocina o el agua de las tiendas del centro comercial)
	elif sitio.get("peligros", []).any(func(p): return p.tipo in ["viento", "camaras", "gas"]):
		tutorial("peligros_torre")   # (el ventanal de Marketing, las cámaras de Seguridad o el gas de Recursos Humanos)
	if fundir:
		await create_tween().set_ignore_time_scale().tween_property(negro, "modulate:a", 0.0, FUNDIDO).finished
	cambiando = false
	Sonido.musica("jefe" if sitio.tipo == "jefe" and not sitio.limpio else "menu")   # ("menu": la de explorar el edificio)
	# En el apartamento de la jefa, aparece ella (si aún no ha caído ni está ya ahí)
	if sitio.tipo == "jefe" and not sitio.limpio and not jefa_salio:
		await get_tree().create_timer(JEFE_TARDA).timeout
		# se le suelta justo antes de la presentación, que lo vuelve a parar en el acto (sin un fotograma de por medio)
		# y lo suelta al acabar
		if presentara:
			johnny.set_physics_process(true)
		if aqui == idx and not jefa_salio:
			jefa_salio = true
			Sonido.tocar("jefe")
			# en medio de la sala (la pelea empieza en el centro, nunca junto a una pared); en la azotea, en el helipuerto
			jefa = meter_zombi(planta.jefe, sitio.helipuerto if sitio.has("helipuerto") else mapa.centro_libre())
			logros.jefe_sale(jefa)   # (empieza su pelea: Sin un rasguño y Visto y no visto)
			# (en la azotea, espera en el aro a que Johnny entre en las líneas blancas: mirar_ring)
			if sitio.has("helipuerto") and jefa is Minijefe:
				jefa.esperando = true
			# (en el laboratorio de la torre, la presidenta maneja la sala mientras dura la pelea: laboratorio.gd)
			if mapa.laboratorio:
				mapa.laboratorio.jefe = jefa
			# y su presentación: la cámara lo enfoca mientras grita y sale su nombre (en la prueba, solo en la suya)
			if presentara:
				await presentacion.presentar(self, jefa, $Pantalla/Jefa/Nombre.text)
				tutorial("jefes")
				guia.jefe_presentado()
			if sitio.has("helipuerto") and aqui == idx and jefa is Minijefe and jefa.esperando:
				decir(Idioma.t("Te espera en el helipuerto, dentro de las líneas blancas"), 3.0)


# Johnny sale del mapa: se quita de la escena y, si no se guarda, se tira. Se apunta lo que hará falta al volver
func dejar_mapa() -> void:
	mapa.quedan = get_tree().get_nodes_in_group("zombis").size()
	mapa.jefe = jefa if is_instance_valid(jefa) else null
	mapa.jefe_salio = jefa_salio
	remove_child(mapa)
	if not se_guarda():
		mapa.queue_free()


# Si el mapa de ahora se guarda al salir: no el de la planta que se deja (nueva_planta ya ha vaciado "mapas"), ni la
# sala de pruebas ni la exposición (hacer_mapa)
func se_guarda() -> bool:
	return mapas.get(aqui) == mapa


# La primera vez que se entra en un sitio: se hace su mapa
func hacer_mapa(idx: int, sitio: Dictionary) -> void:
	mapa = MAPA.new()
	mapa.name = "Mapa"
	if guarda_mapas and sitio.tipo not in ["armas", "expo"]:
		mapas[idx] = mapa
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
	if mapa.baul:   # (el de la sala de mantenimiento o el de pruebas)
		mapa.baul.usar.connect(abrir_cosas.bind("baul"))
	if mapa.tele_salon:   # (la tele del salón que enseña las noticias, M91)
		mapa.tele_salon.usar.connect(abrir_tele)
	for armarito in mapa.armaritos:
		armarito.johnny = johnny
		armarito.usar.connect(abrir_armarito.bind(armarito))
		if Reto.sin_curas():   # el reto del día "Sin curas": todos vacíos
			armarito.vaciar()
	poner_cientifico(idx)
	poner_terminales(idx)
	for puerta in mapa.puertas:
		puerta.empujada.connect(cruzar)


# En la primera partida (la de la guía, guia.gd) no se sale de la sala de mantenimiento al pasillo mientras quede alguno
# de sus «!» (mapa.marcas_sala: la taquilla, el ordenador, el banco, el baúl y la puerta de los trasteros), para que el
# que empieza lo abra todo y lea sus tutoriales. Hasta entonces, tampoco sale la flecha de la guía (guia.destino)
func falta_sala() -> bool:
	return guia.activa and mapa != null and planta.sitios[aqui].tipo == "mantenimiento" 		and mapa.marcas_sala.any(func(m): return m.activa)


# Se vuelve a un sitio: su mapa guardado, otra vez a la escena, y el jefe, si se quedó dentro (con su barra de vida)
func sacar_mapa(idx: int) -> void:
	mapa = mapas[idx]
	add_child(mapa)
	move_child(mapa, 0)
	mapa.al_entrar()
	jefa = mapa.jefe if is_instance_valid(mapa.jefe) else null
	jefa_salio = mapa.jefe_salio
	$Pantalla/Jefa.visible = jefa != null and jefa.estado != "muerto"


# Se deja la planta o la partida: los mapas guardados, a la basura. Están fuera de la escena, así que no se irían solos
# (el de ahora se va con montar o con la escena)
func tirar_mapas() -> void:
	for m in mapas.values():
		if m != mapa:
			m.free()
	mapas = {}


# El panel de pruebas: ese sitio se hace de nuevo la próxima vez que se entre
func olvidar_mapa(idx: int) -> void:
	if mapas.has(idx) and mapas[idx] != mapa:
		mapas[idx].free()
	mapas.erase(idx)


# Si cambia lo que se ve (F11, agrandar la ventana del navegador), la cámara se vuelve a encuadrar en el mismo sitio
func reencuadrar() -> void:
	if not planta.is_empty():
		encuadrar(planta.sitios[aqui])


# Los límites de la cámara: el mapa entero (y un poco por arriba). Si el mapa es más pequeño que la pantalla,
# se centra.
func encuadrar(sitio: Dictionary) -> void:
	var camara: Camera2D = johnny.get_node("Camara")
	var pantalla := get_viewport_rect().size
	var x0 := 0.0
	var x1: float = sitio.ancho
	var y0 := -float(sitio.get("arriba_extra", ARRIBA_EXTRA))
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
	# (los nombres, ya traducidos: Planta.nombre_de y Planta.nombre_de_sitio, y lo mismo mapa.nombre_zona)
	var de_planta: String = Planta.nombre_planta(1) if sitio.tipo in ["mantenimiento", "viviendas"] else Planta.nombre_de(planta)
	var nombre := Planta.nombre_de_sitio(sitio)
	var texto: String = de_planta if sitio.tipo == "pasillo" or sitio.get("azotea", false) else "%s · %s" % [de_planta, nombre]
	var zona: String = mapa.nombre_zona(mapa.zona_en(johnny.position))
	if zona != "" and zona != nombre:   # (la tienda de un minijefe y su sala se llaman igual)
		texto += " · " + zona
	lugar.text = texto + eventos.etiqueta() + Reto.etiqueta()


# Johnny ha empujado la salida "i" del sitio en el que está
func cruzar(i: int) -> void:
	if cambiando or not johnny.vivo:
		return
	if aqui == planta.armas:
		return   # de la sala de pruebas no se sale por la puerta (para no salir sin querer): solo con F9
	var sitio: Dictionary = planta.sitios[aqui]
	var salida: Dictionary = sitio.salidas[i]
	# (y nunca sin haber cogido la pistola del regalo de bienvenida: Johnny empieza solo con la fregona, tienda_armas.gd)
	if sitio.tipo == "mantenimiento" and salida.tipo == "puerta" and salida.get("a", -1) == 0:
		if guia.activa:
			for marca in mapa.marcas_sala:
				marca.refrescar()   # (por si se acaba de cerrar un tutorial: se miran cada segundo)
		if falta_sala() or not Guardado.cargar().regalo_cogido:
			# (como el de «¡¡¡LA LLAVE!!!», pero por encima del letrero de la guía y más rato, que es más larga)
			gran_aviso(Idioma.t("¡MEJOR INVESTIGO UN POCO MÁS!"), Tema.AMARILLO, 160.0, 2.2)
			Sonido.tocar("no")
			return
	var arreglo := supervivientes.averia.no_cruzar()   # el técnico, que no se va sin arreglar el cable
	if arreglo == "":
		arreglo = supervivientes.copia.no_cruzar()   # el informático joven, copiando los archivos
	if arreglo == "":
		arreglo = supervivientes.tornos.no_cruzar()   # la recepcionista, abriendo los tornos
	if arreglo != "":
		decir(arreglo)
		Sonido.tocar("no")
		return
	if sitio.tipo != "pasillo" and cerrada:
		if supervivientes.en_horda():
			decir(Idioma.t("Aguanta: aún está forzando la cerradura"))
		else:
			gran_aviso(Idioma.t("¡SE HA ATASCADO!"))   # (cada vez: la puerta se abre al no quedar zombis)
		Sonido.tocar("no")
		return
	var espera := supervivientes.escolta.no_cruzar()   # la farmacéutica herida, lejos o en el suelo
	if espera != "":
		decir(espera)
		Sonido.tocar("no")
		return
	match salida.cerrojo:
		"nunca":
			if salida.tipo == "ascensor":
				aviso_una_vez("ascensor_%d" % planta.num, Idioma.t("¡TENGO QUE REPARARLO!"))
			elif salida.tipo == "llegada" and not sitio.get("azotea", false):
				aviso_una_vez("portal", Idioma.t("¡ESTÁ BLOQUEADO!"))   # (el portal de la planta baja)
			else:
				decir(Planta.aviso_de(salida))   # (ya traducido)
				Sonido.tocar("no")
			return
		"llave":
			# (en la torre, el informático joven del equipo teclea el código sin tenerlo)
			var sin_codigo: bool = ed.cerrojo == "codigo" and not planta.tiene_llave and supervivientes.abre_codigo()
			if sin_codigo:
				planta.tiene_llave = true
			if not planta.tiene_llave:
				aviso_una_vez("jefe_%d" % planta.num, falta_llave())
				return
			# La llave se gasta al abrir: la puerta queda abierta para siempre
			planta.tiene_llave = false
			planta.llave_usada = true
			salida.cerrojo = ""
			decir(Idioma.t("El informático joven se salta el teclado: la puerta se abre") if sin_codigo else
				{"tarjeta": Idioma.t("Abres con la tarjeta de acceso"), "codigo": Idioma.t("Tecleas el código: la puerta se abre")}.get(
				ed.cerrojo, Idioma.t("Abres con la llave")))
			Sonido.tocar("compra")
		"jefa":
			if not planta.jefa_muerta:
				aviso_una_vez("escaleras_%d" % planta.num, falta_llave())   # (la salida de incendios)
				return
	Sonido.tocar("puerta")
	if salida.tipo == "escaleras":
		subir()
		return
	await montar(salida.a, salida.vuelta)
	if planta.sitios[aqui].tipo != "pasillo":
		return
	tutorial({"tarjeta": "centro", "codigo": "torre"}.get(ed.cerrojo, "apartamentos"))
	if salida.tipo == "ascensor":
		decir(Planta.nombre_de(planta), 2.5)   # de vuelta de la sala de mantenimiento: en qué planta se está
	elif planta.get("ascensor_nuevo", false):
		# al salir al pasillo tras acabar con el jefe (con el ascensor ya a la vista), Johnny cuenta que lo ha arreglado
		planta.erase("ascensor_nuevo")
		decir(Idioma.t("Johnny: «¡He podido arreglar el ascensor! Ya puedo bajar a la planta baja, a la sala de mantenimiento»"), 5.0)
		tutorial("ascensor")


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
	var premio := eventos.superado()   # el apagón o el incendio de la planta que se deja: sus dólares (eventos.gd)
	var superado := eventos.evento if premio != "" else ""
	if guarda_partida:
		PartidaGuardada.apuntar(self, planta.num + 1)   # lo que se lleva al llegar a ella, por si se cierra el juego
	nueva_planta(planta.num + 1)
	await montar(0, puerta_de_llegada())
	var texto: String = Planta.nombre_de(planta)
	if planta.get("azotea", false):   # (en la torre, la planta 40, el laboratorio)
		texto = Idioma.t("%s · ¡El último combate del edificio!") % Planta.nombre_de(planta) if planta.edificio == "torre" 			else Idioma.t("Azotea · ¡El último combate del edificio!")
	decir(texto if premio == "" else "%s · %s" % [texto, premio], 2.5 if premio == "" else 3.5)
	supervivientes.avisar_pista(3.0 if premio == "" else 4.0)   # (la recepcionista rescatada: dónde está la llave o el código)
	if planta.num >= 3:
		logros.cumplir("sube_conserje")
	if superado != "":
		logros.cumplir({"apagon": "se_fue_la_luz", "incendio": "simulacro"}[superado])


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
	mirar_tutoriales()
	var sitio: Dictionary = planta.sitios[aqui]
	poner_lugar()
	if sitio.tipo == "pasillo" or sitio.limpio:
		return
	rescatar_atascados(delta)
	var quedan: bool = not get_tree().get_nodes_in_group("zombis").is_empty() or (sitio.tipo == "jefe" and not jefa_salio)
	mirar_ring(sitio)
	# Nada más entrar, la puerta se cierra detrás de Johnny: ya no se vuelve al pasillo hasta matarlos a todos (9 nov;
	# antes se cerraba al alejarse 110 de ella y daba tiempo a darse la vuelta y salir)
	if not cerrada and quedan:
		cerrada = true
		actualizar_puertas()
		decir(Idioma.t("¡La puerta se ha cerrado detrás de ti!"))
		Sonido.tocar("portazo")
		tutorial("lanzables")   # (la primera pelea)
	elif not quedan:
		sitio.limpio = true
		cerrada = false
		if sitio.tipo == "jefe":
			planta.jefa_muerta = true
			arreglar_ascensor()
			Sonido.musica("menu")
			var quien := Idioma.t(planta.el_jefe)   # («la portera», «the super»): con la primera letra en mayúscula
			quien = quien.left(1).to_upper() + quien.substr(1)
			decir((Idioma.t("¡%s ha caído!") if sitio.get("azotea", false) else Idioma.t("¡%s ha caído! Las escaleras ya están abiertas")) % quien, 4.0)
			if sitio.get("azotea", false) and final_de(planta.jefe).is_empty():
				fin_del_edificio()   # (el jefe de relleno de una azotea sin su final: el de verdad lo llama al caer)
		else:
			decir(Idioma.t("¡Piso limpio! La puerta se ha abierto"))
			encender_tele(sitio)
			logros.cumplir("primer_turno")
		actualizar_puertas()
		Sonido.tocar("limpio")
		get_tree().create_timer(0.25).timeout.connect(Sonido.tocar.bind("puerta"))
		supervivientes.piso_limpio(aqui)


# El helipuerto (la azotea): el jefe espera en el aro amarillo (minijefe.gd, esperando) y, en cuanto Johnny entra en
# las líneas blancas (planta.gd, PLATAFORMA), empieza la pelea. Los acompañantes que se hayan quedado fuera entran con
# él. (Era una plataforma elevada con su rampa: desde el 11 nov la azotea entera es la imagen de GPT, a ras de suelo)
func mirar_ring(sitio: Dictionary) -> void:
	if not sitio.has("helipuerto") or not jefa_salio:
		return
	if not (is_instance_valid(jefa) and jefa is Minijefe and jefa.esperando):
		return
	if not mapa.en_plataforma(johnny.global_position, johnny.RADIO + 6.0):
		return
	jefa.esperando = false
	var lado := -1.0
	for a in get_tree().get_nodes_in_group("aliados"):
		if not mapa.en_plataforma(a.global_position, 16.0):
			a.global_position = mapa.a_la_plataforma(johnny.global_position + Vector2(36.0, 40.0 * lado), 24.0)
			lado = -lado


# El científico muerto de esta planta, si está en este sitio y su página falta por encontrar (historia.gd). Si
# ya se encontró en otra partida, no sale: la historia no se repite
func poner_cientifico(idx: int) -> void:
	var c: Dictionary = planta.get("cientifico", {})
	if c.is_empty() or c.sitio != idx:
		return
	# la primera página que te falte (si ya la has cogido en esta planta, la que cogiste)
	var pagina: Dictionary = c.pagina if c.cogida else pagina_aqui()
	if pagina.is_empty():
		return
	var cuerpo := CIENTIFICO.new()
	cuerpo.montar(pagina, c.pos)
	cuerpo.johnny = johnny
	cuerpo.mapa = mapa
	cuerpo.zona = mapa.zona_en(c.pos)
	mapa.cosas.add_child(cuerpo)
	if c.cogida:
		cuerpo.vaciar()
	else:
		cuerpo.cogida.connect(_al_coger_pagina.bind(pagina))


# ── El código de Torre Velaria: sus tres cifras, en tres ordenadores de los departamentos (Planta.codigo) ──

# Los ordenadores de este sitio, la primera vez que se entra (luego se quedan en su mapa, leídos o no)
func poner_terminales(idx: int) -> void:
	for d in planta.get("codigo", {}).get("terminales", []):
		if d.sitio != idx:
			continue
		var terminal := TERMINAL.new()
		terminal.montar(d, mapa, johnny)
		mapa.cosas.add_child(terminal)
		terminal.leido.connect(_al_leer_terminal)


# Johnny ha leído una cifra: salta el «control de productividad» (se despiertan los zombis de aquí) y, con las tres,
# la sala del jefe se puede abrir (como con la llave: tiene_llave)
func _al_leer_terminal() -> void:
	var leidos: Array = planta.codigo.terminales.filter(func(d): return d.leido)
	var cifras := ""
	for d in planta.codigo.terminales:
		cifras += str(d.cifra) if d.leido else "_"
	gran_aviso(cifras.replace("", " ").strip_edges(), Tema.AMARILLO)
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.get("dormido"):
			z.despertar()
	# con la Alerta 5, además llegan escoltas por la puerta del departamento (como las cámaras de Seguridad)
	if Alerta.escoltas_codigo() > 0 and not mapa.puertas.is_empty():
		var puerta: Node2D = mapa.puertas[0]
		for k in Alerta.escoltas_codigo():
			var zombi: Node2D = meter_zombi("escolta", puerta.llegada() + Vector2(randf_range(-24, 24), randf_range(-24, 24)))
			if zombi and zombi.get("dormido"):
				zombi.despertar()
	if leidos.size() < planta.codigo.terminales.size():
		decir(Idioma.t("Cifra %d de %d. ¡Control de productividad: despiertan todos!") % [leidos.size(),
			planta.codigo.terminales.size()], 3.0)
		return
	planta.tiene_llave = true
	Sonido.tocar("compra")
	var sala: String = Edificios.MINIJEFES.get(planta.jefe, {}).get("la_tienda", "")
	sala = Idioma.t(sala) if sala != "" else Idioma.t("la sala de %s") % Idioma.t(planta.el_jefe)
	decir(Idioma.t("Ya tienes el código: abre %s") % sala, 3.5)


func _al_coger_pagina(p: Dictionary) -> void:
	planta.cientifico.cogida = true
	planta.cientifico.pagina = p
	leer_pagina(p)
	encender_tele()   # (si el apartamento de la tele ya estaba limpio)


# Ha caído el jefe final (el gerente mutado, en la azotea): cuando se ha visto caer, el juego sigue y
# llega el helicóptero de Velaria a por Johnny (helicoptero.gd). La
# azotea no tiene más salida: el helicóptero suelta una escalera de cuerda y, al llegar Johnny a ella, se acaba el
# edificio (subir_al_helicoptero)
func fin_del_edificio() -> void:
	var donde := aqui
	await get_tree().create_timer(1.6, false).timeout
	if donde != aqui:
		return
	if mapa.laboratorio:
		# en el laboratorio de la torre no baja el helicóptero: se abre la puerta del helipuerto y se sube por ella
		mapa.laboratorio.abrir_salida(subir_al_helicoptero)
		decir(Idioma.t("¡La puerta del helipuerto se ha abierto! Sube por ella"), 4.0)
		return
	var heli := Helicoptero.new()
	heli.destino = planta.sitios[aqui].get("helipuerto", johnny.position)
	heli.johnny = johnny
	heli.escalera_lista.connect(func(): decir(Idioma.t("¡Acércate a la escalera para subir al helicóptero!"), 4.0))
	heli.agarrada.connect(subir_al_helicoptero)
	mapa.cosas.add_child(heli)
	decir(Idioma.t("¡Un helicóptero de Velaria viene a por ti!"), 4.0)


# Johnny ha llegado a la escalera de cuerda del helicóptero: se acaba el edificio, como al subir las últimas escaleras
func subir_al_helicoptero() -> void:
	if cambiando or terminada or not johnny.vivo:
		return
	cambiando = true   # (que no pase nada detrás del final del edificio)
	await ver_relato(edificio)
	subir()


# Apunta la página para siempre y la enseña con el juego parado
func leer_pagina(p: Dictionary) -> void:
	Historia.apuntar(p.id)
	Sonido.tocar("compra")
	var paginas: Array = Historia.dosier(edificio).paginas
	get_tree().paused = true
	menus.pagina(p, paginas.find(p) + 1, paginas.size(), func(): get_tree().paused = false)


# M91: la tele de la planta se enciende (pantalla en blanco y un «!» encima) al limpiar su apartamento, si has cogido la
# página del dosier de esta planta y queda una noticia de este edificio por ver (se mira al limpiar y al coger la página)
func encender_tele(_sitio := {}) -> void:
	for otro in planta.sitios:
		if otro.has("tele") and otro.limpio and otro.tele.estado == "apagada" and tele_con_pagina() \
				and not Historia.noticias_pendientes(edificio, Guardado.cargar()).is_empty():
			otro.tele.estado = "encendida"
			Sonido.tocar("compra")
			if mapa.tele_salon and mapa.sitio == otro:
				mapa.tele_salon.encender()


# La noticia se hace con la documentación que Johnny le pasa a la periodista: la tele de la planta solo se enciende si en
# esta planta ya has cogido la página del dosier del muerto (o si en esta planta no hay ninguna que coger: así las noticias
# de páginas ya cogidas no se quedan sin ver)
func tele_con_pagina() -> bool:
	return planta.get("cientifico", {}).get("cogida", false) or pagina_aqui().is_empty()


# La página que lleva el científico de esta planta, o {} si aquí no sale (Historia.pagina_de_planta: cada página tiene su
# planta mínima y la 5 solo sale tras completar el edificio, en la planta sorteada al empezar)
func pagina_aqui() -> Dictionary:
	if planta.get("cientifico", {}).is_empty():
		return {}
	return Historia.pagina_de_planta(Guardado.cargar(), edificio, planta.num, planta_pagina5)


# Con la tele del salón encendida y el clic delante de ella: salen seguidas, con el juego parado, todas las noticias de este
# edificio que aún no has visto y cuya página ya tienes (si cogiste páginas sin ver su tele, se ponen al día). Cada una
# vista entera queda en VIDEOS.EXE del ordenador; al acabar la última, la tele se apaga para siempre. Si la cierras antes,
# sigue encendida con las que falten
func abrir_tele() -> void:
	var tele: Node2D = mapa.tele_salon
	if Historia.noticias_pendientes(edificio, Guardado.cargar()).is_empty() or terminada or tele == null:
		return
	get_tree().paused = true
	poner_noticia(tele)


func poner_noticia(tele: Node2D) -> void:
	var n: Dictionary = Historia.noticias_pendientes(edificio, Guardado.cargar())[0]
	menus.noticia(n, func(entera: bool):
		if entera:
			Historia.ver_noticia(n.id)
			if not Historia.noticias_pendientes(edificio, Guardado.cargar()).is_empty():
				poner_noticia(tele)   # (la siguiente, sin soltar la pausa)
				return
			tele.apagar()   # (sin frase al acabar: ya lo explica el ordenador)
		get_tree().paused = false)


# Un grito grande encima de Johnny, como el de «¡¡¡LA LLAVE!!!», para lo que no hay que perderse (lo nuevo en el ordenador,
# un logro, una skin): letra de 32, amarilla, que sube y se apaga en 1,4 s. Va además del aviso de abajo, que se lee peor
# ("alto": lo que sube por encima de Johnny; "dura": lo que tarda en irse, más en una frase larga)
# Si Johnny está tan al borde de la pantalla que la frase se cortaría, se corre hacia dentro hasta verse entera
func gran_aviso(texto: String, color := Tema.AMARILLO, alto := 110.0, dura := 1.4) -> void:
	if johnny == null or not johnny.is_inside_tree():
		return
	var etiqueta := Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(0, -alto), texto, color, 32,
		true, dura)
	var sin_luz := CanvasItemMaterial.new()   # (que no lo apague la penumbra de los pisos)
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	etiqueta.material = sin_luz
	# Con Johnny pegado a un lado de la pantalla, la frase se corre hacia dentro lo justo para leerse entera (sigue a la
	# altura de su cabeza). "a_la_vista" es el trozo del mapa que se ve ahora mismo
	var a_la_vista: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	var ancho: float = etiqueta.get_minimum_size().x
	var margen := 12.0
	if ancho + margen * 2.0 <= a_la_vista.size.x:
		etiqueta.global_position.x = clampf(etiqueta.global_position.x, a_la_vista.position.x + margen,
			a_la_vista.end.x - ancho - margen)


# Un aviso de Johnny encima de su cabeza (como el de la llave) que solo sale la primera vez: las siguientes, ni frase ni
# sonido. "clave" dice cuándo vuelve a valer (con el número de la planta, una vez por planta)
func aviso_una_vez(clave: String, texto: String) -> void:
	if avisos_dichos.has(clave):
		return
	avisos_dichos[clave] = true
	gran_aviso(texto)
	Sonido.tocar("no")


# Lo que dice Johnny ante la puerta del jefe o la salida de incendios cerradas: le falta la llave (o la tarjeta, o el código)
func falta_llave() -> String:
	return {"tarjeta": Idioma.t("¡NECESITO UNA TARJETA!"), "codigo": Idioma.t("¡NECESITO EL CÓDIGO!")}.get(
		ed.cerrojo, Idioma.t("¡NECESITO UNA LLAVE!"))


func _al_coger_llave() -> void:
	planta.tiene_llave = true
	Sonido.tocar("compra")
	if ed.cerrojo == "tarjeta":
		var tienda: String = Edificios.MINIJEFES.get(planta.jefe, {}).get("la_tienda", "")
		tienda = Idioma.t(tienda) if tienda != "" else Idioma.t("la tienda de %s") % Idioma.t(planta.el_jefe)
		decir(Idioma.t("Has cogido la tarjeta de acceso: abre %s") % tienda, 3.0)
	else:
		decir(Idioma.t("Has cogido la llave del %s") % nombre_jefa(), 3.0)
		gran_aviso(Idioma.t("¡¡¡LA LLAVE!!!"))   # un grito grande encima de Johnny, para que se vea que la ha cogido


# ── El guardia de seguridad (centro comercial): lleva la tarjeta y ronda el pasillo ──

# Lo saca en el pasillo, lejos de la puerta por la que llega Johnny, con la vida que le quedara
func poner_guardia() -> void:
	var g: Dictionary = planta.guardia
	var sitio: Dictionary = planta.sitios[aqui]
	var puntas := [Vector2(Planta.MURO + 70, sitio.alto / 2.0), Vector2(sitio.ancho - Planta.MURO - 70, sitio.alto / 2.0)]
	guardia = meter_zombi("guardia", mapa.punto_libre(johnny.position, 500.0))
	guardia.importante = true
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
	decir(Idioma.t("¡El guardia ha tocado el silbato: vienen refuerzos!"), 2.5)
	var sitio: Dictionary = planta.sitios[aqui]
	for i in REFUERZOS + planta.num / 2:
		var x: float = Planta.MURO + 50 if i % 2 == 0 else sitio.ancho - Planta.MURO - 50
		var donde := Vector2(x, sitio.alto / 2.0 + randf_range(-60, 60))
		if donde.distance_to(johnny.position) < 250.0:
			donde.x = sitio.ancho - donde.x   # no encima de Johnny: por la otra punta
		var refuerzo: Node2D = meter_zombi("vigilante", donde)
		refuerzo.velocidad = REFUERZOS_VELOCIDAD
		if refuerzo.get("agente") != null:
			refuerzo.agente.max_speed = REFUERZOS_VELOCIDAD


# Ha caído: suelta la tarjeta donde estaba (se queda en el suelo del pasillo hasta que Johnny la coja)
func _al_caer_guardia(zombi: Node2D) -> void:
	planta.guardia.vivo = false
	planta.llave = {"sitio": aqui, "pos": zombi.position}
	mapa.call_deferred("poner_llave", zombi.position, true)
	# en la planta de la joyería lleva también la tarjeta dorada de su cámara acorazada (joyeria.gd)
	var dorada := joyeria.soltar_dorada(zombi.position + Vector2(44, 0))
	decir(Idioma.t("¡El guardia ha caído! Ha soltado la tarjeta de acceso y la tarjeta dorada de la Joyería") if dorada
		else Idioma.t("¡El guardia ha caído! Ha soltado la tarjeta de acceso"), 3.0)


# En los Apartamentos, el zombi que lleva la llave del apartamento de la jefa (planta.gd lo elige al azar entre los de
# la planta): es un zombi como los demás (no se le ve nada) y, al caer, suelta la llave donde estaba. Con la Alerta 5
# aguanta el doble, como el guardia. "dato" es su apunte en la lista de zombis del sitio: al caer se le quita la llave,
# para que no vuelva a llevarla si Johnny sale del sitio sin limpiar y vuelve a entrar
func zombi_de_la_llave(zombi: Node2D, dato: Dictionary) -> void:
	if Alerta.guardia() > 1.0:
		zombi.vida_max = int(zombi.vida_max * (1.0 + 0.2 * (planta.num - 1)) * Alerta.guardia())
		zombi.vida = zombi.vida_max
	zombi.set_meta("llave", true)
	guia.marcar_llave(zombi)   # (en la primera partida, con su llavecita encima)
	zombi.importante = true
	zombi.murio.connect(func():
		dato.erase("llave")
		planta.llave = {"sitio": aqui, "pos": zombi.position}
		mapa.call_deferred("poner_llave", zombi.position)
		decir(Idioma.t("¡Ha caído el durmiente de la llave! Ha soltado la llave del %s") % nombre_jefa(), 3.0))


# El nombre del apartamento de la jefa ("2ºC"...), ya traducido ("2C")
func nombre_jefa() -> String:
	for s in planta.sitios:
		if s.tipo == "jefe":
			return Planta.nombre_de_sitio(s)
	return ""


# Un aviso en el centro de la pantalla que se va solo (hoy escondido: ver _ready). Durante la presentación de un jefe no sale: se guarda (el
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
	if guarda_partida:
		PartidaGuardada.borrar()   # ya, por si se cierra el juego antes del cartel de derrota
	# Un momento para verlo caer, y el cartel de derrota (sin letrero encima)
	await get_tree().create_timer(1.0).timeout
	terminar(false)


# Tras una derrota (M31), la partida nueva empieza como si todo hubiera sido una pesadilla: la pantalla sale de negro,
# Johnny está tumbado en el suelo de la sala de mantenimiento, se levanta (sus dibujos del tropezón) y dice una de
# FRASES_DESPERTAR. Así se entiende por qué vuelve a estar allí y el edificio otra vez lleno de zombis
func despertar() -> void:
	negro.modulate.a = 1.0
	johnny.despertar(DESPERTAR)
	create_tween().tween_property(negro, "modulate:a", 0.0, 0.8)
	await get_tree().create_timer(0.6, false).timeout
	gran_aviso(Idioma.t(FRASES_DESPERTAR.pick_random()), Tema.AMARILLO, 110.0, DESPERTAR)
	await get_tree().create_timer(DESPERTAR, false).timeout


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
			var vale := valor_billete()
			dolares += vale
			Sonido.tocar("moneda")
			numero(billete.position, "+$%d" % vale, Tema.VERDE))
		mapa.cosas.add_child.call_deferred(billete)


var no_puedo_mas_hasta := 0   # hasta cuándo (Time.get_ticks_msec) no vuelve a decir «No puedo llevar más»


# Lo que vale un billete al cogerlo: $1 (con la skin del gerente, la mitad de las veces $2: Skins.comision)
func valor_billete() -> int:
	return 2 if randf() < Skins.comision(johnny.skin) else 1


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
	cosa.al_no_caber = no_puedo_mas
	cosa.cogido.connect(func():
		lanzables.sumar(k)
		Sonido.tocar("compra")
		numero(cosa.position, Idioma.t("+1 molotov") if k == "molotov" else Idioma.t("+1 granada"), Lanzables.COLORES[k]))
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
		# (solo si lleva un arma que gaste balas: sin ella la caja no es para él, y no dice nada)
		cosa.al_no_caber = func():
			for id in [johnny.huecos.fuego, repuesto("fuego")]:
				if id != "" and not Armas.datos(id).has("relleno"):
					no_puedo_mas()
					return
	else:
		cosa.tirado = true
		cosa.puede = func() -> bool: return johnny.sitio(tipo) >= cuanta
		cosa.al_no_caber = no_puedo_mas
	cosa.cogido.connect(func():
		if tipo == "":
			johnny.sumar_municion()
		else:
			johnny.meter_municion(tipo, cuanta)
			johnny.coger_municion(tipo)
		Sonido.tocar("recargado")
		numero(cosa.position, Idioma.t("+munición"), Color("#ffd23f")))
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


# Johnny pisa algo del suelo que no le cabe (un objeto, un arrojable o munición, con todo su sitio lleno): lo dice
# encima de su cabeza, con el grito grande y amarillo de «¡¡¡LA LLAVE!!!» (gran_aviso). Como mucho una vez cada 1,5 s, para que un montón de cosas juntas no lo repita sin parar
func no_puedo_mas() -> void:
	var ahora := Time.get_ticks_msec()
	if ahora < no_puedo_mas_hasta:
		return
	no_puedo_mas_hasta = ahora + 1500
	gran_aviso(Idioma.t("¡NO PUEDO LLEVAR MÁS!"))


# Un objeto en el suelo: se coge pasando por encima, si cabe en la mochila (la gasolina, el
# bidón de ácido y la batería, si caben en la munición: johnny.sitio). "tirado": lo ha tirado Johnny desde el inventario (no vuelve
# a la mochila hasta que se aparte). "salida": hacia dónde sale despedido, en vez de a un lado al azar (el armarito del baño)
func soltar_objeto(id: String, donde: Vector2, tirado := false, salida := Vector2.ZERO) -> void:
	var cosa := BILLETE.new()
	cosa.johnny = johnny
	cosa.salida = salida
	cosa.icono = load("res://assets/ui/iconos/%s.png" % Objetos.icono(id))
	cosa.tamano = 32.0 / cosa.icono.get_width()   # los de 16×16, cada píxel 2 unidades (el botiquín es de 32×32)
	cosa.a_oscuras = id in Armas.MUNICION   # la gasolina, el bidón de ácido y la batería se ven a oscuras, como la munición
	cosa.tirado = tirado
	cosa.position = donde
	cosa.puede = func() -> bool: return johnny.sitio(id) > 0 if id in Armas.MUNICION else Objetos.cabe(mochila, id)
	cosa.al_no_caber = no_puedo_mas
	cosa.cogido.connect(func():
		mochila.append(id)
		Objetos.apuntar_encontrado(id)   # para las Colecciones del ordenador
		Sonido.tocar("compra")
		numero(cosa.position, "+1 " + Objetos.nombre(id), Tema.TINTA)
		johnny.coger_municion(id))   # si es una gasolina, el lanzallamas vacío se llena con ella (el lanza ácido, con un bidón, y el lanza rayos, con una batería)
	mapa.cosas.add_child.call_deferred(cosa)


# Un arma en el suelo (tirada desde el inventario, o la que suelta Johnny al llevar ya dos de ese tipo), con su
# calidad (las mejoradas, con un brillo de su color): al volver a cogerla, al repuesto si está libre (llevar_arma)
func soltar_arma(id: String, donde: Vector2, calidad := 0, quedan := -1) -> void:
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
		brillo.range_item_cull_mask = Luz.TODAS   # (si no, en un apartamento, con una capa de luz por habitación, no alumbra el suelo)
		brillo.position = Vector2(0, -10)
		cosa.add_child(brillo)
	cosa.cogido.connect(func():
		llevar_arma(id, calidad, false, true, quedan)   # (con las partidas que le quedaban: Armas.nuevas)
		Sonido.tocar("compra")
		numero(cosa.position, Armas.nombre(id, calidad), Armas.color(calidad) if calidad > 0 else Tema.TINTA))
	mapa.cosas.add_child.call_deferred(cosa)


# Johnny lleva como mucho dos armas de cada tipo (cuerpo a cuerpo y a distancia): la de la mano y la de repuesto
# (armas_guardadas), y una de cada arma, cada una con su calidad (johnny.calidades). Al llevarse otra (comprarla,
# sacarla del baúl o de la vitrina de la joyería), va a la mano y la que llevaba pasa al repuesto; si ya tenía una de
# repuesto, la de la mano se queda en el suelo, a sus pies (la tienda, antes, manda la de repuesto al baúl:
# repuesto_al_baul). Si ya llevaba esa misma arma, se cambian: la nueva ocupa
# su sitio (llena) y la vieja se queda en el suelo. La que coge del suelo ("a_la_mano" falso) va al repuesto si está
# libre, para no cambiarle el arma en plena pelea. Con "al_suelo" falso (al sacarla del baúl), la que sobra no se deja
# en el suelo: solo se devuelve, para guardarla en su lugar. Devuelve la que sobra ({"id", "calidad"}; vacío si ninguna)
func llevar_arma(id: String, calidad := 0, a_la_mano := true, al_suelo := true, quedan := -1) -> Dictionary:
	var tipo: String = Armas.datos(id).tipo
	var fuera := {}
	if id == johnny.huecos[tipo] or id in armas_guardadas:
		fuera = {"id": id, "calidad": johnny.calidad(id), "quedan": johnny.quedan_de(id)}
		johnny.calidades[id] = calidad
		poner_quedan(id, quedan)
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
		poner_quedan(id, quedan)
	else:
		var vieja: String = johnny.huecos[tipo]
		if vieja == "":   # (sin arma a distancia: la nueva ocupa el hueco vacío y no hay nada que mandar al repuesto)
			pass
		elif repuesto(tipo) == "":
			armas_guardadas.append(vieja)
		else:
			fuera = {"id": vieja, "calidad": johnny.calidad(vieja), "quedan": johnny.quedan_de(vieja)}
		if not fuera.is_empty():
			johnny.calidades.erase(vieja)
			johnny.quedan.erase(vieja)
		johnny.calidades[id] = calidad
		poner_quedan(id, quedan)
		johnny.coger(id)
	if not fuera.is_empty() and al_suelo:
		soltar_arma(fuera.id, johnny.position + Vector2(0, 34), fuera.calidad, fuera.quedan)
	return fuera


# Las partidas que le quedan a un arma que se lleva (la durabilidad: Armas.nuevas); -1, las de una nueva de su calidad
func poner_quedan(id: String, quedan: int) -> void:
	if quedan < 0:
		johnny.quedan.erase(id)
	else:
		johnny.quedan[id] = quedan


# Con los dos huecos de ese tipo llenos, saca el arma de repuesto y la guarda en el baúl, para que al llevarse otra (la
# tienda del ordenador, M26) la de la mano baje al repuesto en vez de quedarse en el suelo. Se guarda en el momento, como
# «Guardar en el baúl» del inventario: ya no se pierde si Johnny cae. Devuelve la guardada ({"id", "calidad"}) o vacío
# si no hace falta o no se puede (no lleva repuesto o el baúl está lleno: Armas.al_baul): entonces no cambia nada y llevar_arma deja la de la mano en el suelo, como siempre
func repuesto_al_baul(tipo: String) -> Dictionary:
	var id := repuesto(tipo)
	if id == "":
		return {}
	var calidad: int = johnny.calidad(id)
	if not Armas.al_baul(id, calidad) or not Objetos.hueco_baul(Guardado.cargar()):
		return {}
	var guardada := {"id": id, "calidad": calidad, "quedan": johnny.quedan_de(id), "usada": true}   # (ha salido en esta partida)
	armas_guardadas.erase(id)
	johnny.calidades.erase(id)
	johnny.quedan.erase(id)
	johnny.cargadores.erase(id)
	Guardado.cambiar(func(g): g.baul_equipo.append(guardada))
	return guardada


# Lo que lleva encima que vuelve al baúl al acabar la partida (Armas.al_baul), como en el guardado ("baul_equipo"): sus
# armas y todos sus montones de arrojables, cada uno con las partidas que le quedan ("quedan": la durabilidad,
# Armas.nuevas; los que no tienen ninguna se destruyen: Objetos.cerrar_baul) y los arrojables, con cuántos hay en "n"
# (en el baúl se juntan los del mismo tipo, calidad y partidas: Objetos.arrojables_al_baul)
func equipo_encima() -> Array:
	var lista := []
	for id in johnny.huecos.values() + armas_guardadas:
		if Armas.al_baul(id, johnny.calidad(id)):
			lista.append({"id": id, "calidad": johnny.calidad(id), "quedan": johnny.quedan_de(id)})
	for m in lanzables.montones():
		if m[1] > 0:
			lista.append({"id": Lanzables.tipo_de(m[0]), "calidad": Lanzables.calidad_de(m[0]), "n": m[1],
				"quedan": lanzables.quedan_de(m[0])})
	return lista


# El arma de repuesto de ese tipo ("cuerpo" o "fuego"), o "" si no lleva
func repuesto(tipo: String) -> String:
	for id in armas_guardadas:
		if Armas.datos(id).tipo == tipo:
			return id
	return ""


# Delante del armarito de un baño: se abre y suelta lo suyo al suelo (un botiquín o unas vendas, planta.gd armaritos),
# hacia Johnny, que lo coge pasando por encima (si no le cabe, se queda allí). Se usa luego con su tecla o desde el inventario
func abrir_armarito(armarito: Node2D) -> void:
	armarito.vaciar()
	Sonido.tocar("puerta")
	tutorial("curas")   # (la primera vez que se abre uno: cómo se usan las curas)
	soltar_objeto(armarito.datos.get("dentro", "botiquin"), armarito.position + Vector2(0, 8), false, Vector2(randf_range(-40.0, 40.0), randf_range(110.0, 160.0)))


# Cura "cura" de vida, con el número verde y las chispas encima de "sobre" (el armarito o Johnny)
func curar_con(cura: int, sobre: Node2D) -> void:
	johnny.curar(cura)
	Sonido.tocar("gema")
	numero(sobre.position + Vector2(0, -40), "+%d" % cura, Tema.VERDE)
	for i in 12:
		Particulas.soltar(sobre, sobre.global_position + Vector2(0, -50),
			Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0), Tema.VERDE, 4.0, 0.6)


# Usar un objeto de curar de la mochila (Objetos.USABLES: las vendas y el botiquín) desde el inventario o desde su tecla
# (1 y 2; casillas junto a la barra de vida, ui/hud.gd): se gasta y cura lo suyo (el botiquín, antes, devuelve un tercio
# perdido). Si no se puede (con la vida llena), no se gasta y devuelve por qué
func usar_objeto(id: String) -> String:
	if not id in mochila or not id in Objetos.USABLES:
		return Idioma.t("No se puede usar")
	if not puede_curar(id):
		return Idioma.t("Tienes la vida al máximo: guárdalo para luego")
	mochila.remove_at(mochila.rfind(id))
	if Objetos.USABLES[id].get("tercio", false):
		johnny.devolver_tercio()
	curar_con(cura_de(id), johnny)
	logros.curado = true   # (ya no vale para Sin tiritas)
	return ""


# ¿Le sirve ahora a Johnny? Las vendas, si le falta vida en su tercio; el botiquín, también si ha perdido un tercio
func puede_curar(id: String) -> bool:
	var tercio: bool = Objetos.USABLES[id].get("tercio", false) and johnny.tercios_vivos() < 3
	return johnny.vida < johnny.vida_tope() or tercio


# La tecla de un objeto de curar (1 las vendas, 2 el botiquín): lo usa sin abrir el inventario. Con la vida llena avisa
# y no lo gasta (en la sala de pruebas no vale: allí el 1 y el 2 sacan zombis, ui/panel_pruebas.gd; _unhandled_input)
func usar_cura(id: String) -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused or presentacion.activa or not id in mochila:
		return
	if usar_objeto(id) != "":
		Sonido.tocar("no")
		numero(johnny.position + Vector2(0, -50), Idioma.t("Tienes la vida al máximo"), Tema.TINTA)


# Lo que cura un objeto de curar: lo suyo (Objetos.USABLES: vendas 25, botiquín 40), más el talento Sanitario y, con la
# Alerta 4, la mitad
func cura_de(id: String) -> int:
	# (con la skin del cocinero, un 50 % más: Skins.cura)
	return roundi((Objetos.USABLES[id].cura + johnny.stats.botiquin_extra) * Alerta.botiquin() * Skins.cura(johnny.skin))


# El inventario (Tab, I o Select), el baúl o el banco de trabajo: se para el juego y sale su pantalla
func abrir_cosas(que: String) -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused or presentacion.activa:
		return
	get_tree().paused = true
	if que in ["banco", "baul"] and puede_tutorial(que):
		await ver_tutorial(que)
	inventario.abrir(que, self)


# La taquilla de las skins de Johnny (ui/taquilla.gd): se para el juego y sale su ventanita
func abrir_taquilla() -> void:
	if terminada or cambiando or not johnny.vivo or get_tree().paused or presentacion.activa:
		return
	get_tree().paused = true
	if puede_tutorial("taquilla"):
		await ver_tutorial("taquilla")
	taquilla.abrir(self)


# La ventana del tutorial de algo nuevo (tutoriales.gd), si aún no se ha visto: en cuanto no haya otra pantalla abierta,
# ni la presentación de un jefe, ni se esté cambiando de sitio. Si llegan varios, salen uno detrás de otro
func tutorial(id: String) -> void:
	if not puede_tutorial(id) or id in cola_tutoriales or (guia.activa and id in Guia.CUBRE):   # (esos, la guía a su manera)
		return
	cola_tutoriales.append(id)
	if cola_tutoriales.size() > 1:
		return   # (ya hay otro esperando o abierto: este sale después)
	while not cola_tutoriales.is_empty():
		while terminada or get_tree().paused or presentacion.activa or cambiando or not johnny.vivo:
			if terminada:
				cola_tutoriales.clear()
				return
			await get_tree().create_timer(0.3, false).timeout   # (con el juego parado no corre)
		if puede_tutorial(cola_tutoriales[0]):   # (por si se ha ido a la sala de pruebas mientras esperaba)
			await ver_tutorial(cola_tutoriales[0])
		cola_tutoriales.pop_front()


# Los tutoriales de lo que cambia en Johnny o en la mochila (los demás los pide quien toca, con tutorial())
func mirar_tutoriales() -> void:
	if johnny.recargando > 0.0:
		tutorial("municion")
	if johnny.tercios_vivos() < 3:
		tutorial("tercios")
	if dolares > 0:
		tutorial("dolares")
	if johnny.huecos.cuerpo != "fregona" or johnny.huecos.fuego not in ["", "pistola"] or not armas_guardadas.is_empty():
		tutorial("armas")
	for id in mochila:
		tutorial("botiquin" if id == "botiquin" else "curas" if id in Objetos.USABLES else "piezas" if id in Objetos.PIEZAS else "inventario")


# En la sala de pruebas no salen, ni en la partida de prueba (salvo en la suya, --tutorial)
func puede_tutorial(id: String) -> bool:
	return Tutoriales.toca(id) and not en_pruebas() and (not captura or tutoriales_prueba)


# La enseña ya y espera a que se cierre. El juego, parado mientras tanto; luego, como estaba (el ordenador, el baúl y la
# mutación la sacan con el juego ya parado, y se abren detrás)
func ver_tutorial(id: String) -> void:
	Tutoriales.apuntar(id)
	var parado := get_tree().paused
	get_tree().paused = true
	await Tutorial.ventana(self, id).cerrado
	get_tree().paused = parado


# Un texto de la historia (historia.gd, RELATOS), una sola vez: no sale en el reto del día, ni en la sala de pruebas, ni
# en la partida de prueba (salvo en la suya, --relato). Una partida continuada no pasa por la introducción, pero el final
# del edificio sí le sale
func puede_relato(id: String) -> bool:
	return not id in Guardado.cargar().relatos and not Reto.activo and not en_pruebas() and (not captura or relatos_prueba)


# Lo enseña, si toca, con el juego parado, y espera a que se cierre. Se apunta al cerrarlo: si se cierra el juego a
# medias, sale otra vez
func ver_relato(id: String) -> void:
	if not puede_relato(id):
		return
	get_tree().paused = true
	await Relato.abrir(self, id).cerrado
	Historia.apuntar_relato(id)
	get_tree().paused = false
	# Johnny no hace caso a los mandos mientras se va el negro y medio segundo más: la pulsación que ha cerrado el
	# texto no le hace atacar
	johnny.sin_mandos = Relato.FUNDIDO + 0.5


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


# Se acabó la partida (endRun en game.js): se guardan los récords y los dólares (si no ganas, la mitad). Si se
# abandona desde la pausa, no hay cartel: directo al menú principal
func terminar(gano: bool, abandona := false) -> void:
	if terminada:
		return
	terminada = true
	if guarda_partida:
		PartidaGuardada.borrar()
	if gano:
		logros.partida_ganada()
	if abandona:
		Sonido.musica("")
	else:
		Sonido.jingle(gano)
	var record := [false]   # en una lista, para que la función de dentro pueda cambiarlo
	var abierta := [0]      # la alerta que se abre al ganar (0: ninguna)
	var mejor := [false]    # el reto del día: se ha mejorado la marca de hoy
	var rotas := []         # las armas y los arrojables que se han quedado sin partidas (Objetos.cerrar_baul), para el cartel
	var extra := Alerta.dolares_extra(dolares) if gano else 0   # los dólares de más por la alerta
	# y los del reto del día, la primera vez que se completa hoy en este edificio (reto.gd)
	var premio_reto := Reto.premio(Guardado.cargar(), edificio) if gano and Reto.activo else 0
	var salvados := dolares + extra + premio_reto if gano else roundi(dolares * DOLARES_AL_CAER)   # los que pasan a la cartera
	var nuevo := supervivientes.rescatado_nuevo() if gano else {}
	var equipo := equipo_encima()   # (vuelve al baúl ganes o no, si le quedan partidas: Objetos.cerrar_baul)
	var s := Guardado.cambiar(func(g):
		# el superviviente rescatado en esta partida se viene a vivir a las viviendas (su puerta ya estará abierta)
		if not nuevo.is_empty() and not nuevo.id in g.rescatados:
			g.rescatados.append(nuevo.id)
		g.muertos += muertos
		for id in matados:   # los de cada tipo, para las fichas de Colecciones
			g.matados[id] = int(g.matados.get(id, 0)) + matados[id]
		if logros.sin_logros():
			g.muertos_con_ayudas += muertos   # con ayudas no suman para el logro Exterminador
		var e := Guardado.edificio(g, edificio)
		# el reto del día (reto.gd) lleva su marca aparte: no toca las plantas ni los tiempos del edificio
		if Reto.activo:
			mejor[0] = Reto.apuntar(g, edificio, planta.num, gano, duracion)
		else:
			g.mejor_planta = maxi(g.mejor_planta, planta.num)
			e.mejor_planta = maxi(e.mejor_planta, planta.num)
		# las armas y los arrojables que lleva vuelven al baúl (equipo_encima) ganes, caigas o abandones, aunque no quepan,
		# si les quedan partidas; los que no, se destruyen, también los del baúl que han salido en esta (la durabilidad)
		rotas.append_array(Objetos.cerrar_baul(g, equipo))
		if gano:
			# los objetos de la mochila pasan al baúl (si caes, se pierden), también las vendas y el botiquín
			for id in mochila:
				g.baul[id] = g.baul.get(id, 0) + 1
			g.victorias += 1
		g.dolares += salvados
		g.dolares_total += salvados
		if not gano and not abandona:
			g.pesadilla = true   # la próxima partida empieza con Johnny despertándose (despertar)
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
	logros.revisar()   # (lo que acaba de guardarse: el superviviente rescatado, el edificio completado...)
	if abandona:
		ir_al_menu()
		return
	get_tree().paused = true
	var apartamentos := 0
	var visitados := 0
	for sitio in planta.sitios:
		if sitio.has("apt") and sitio.tipo not in ["viviendas", "mantenimiento"]:
			apartamentos += 1
			if sitio.get("visitado", false):
				visitados += 1
	var tiempo := ""
	if gano:
		tiempo = "%d:%02d" % [int(duracion) / 60, int(duracion) % 60]   # no-tr
	menus.fin({
		"gano": gano,
		"titulo": (Idioma.t("¡Reto completado!") if Reto.activo else Idioma.t("¡Edificio completado!")) if gano else Idioma.t("¡Derrota!"),
		"reto": Reto.nombre() if Reto.activo else "",
		"mejor": mejor[0],
		"marca": Reto.marca(Reto.ficha(s, edificio), true) if Reto.activo else "",
		"sub": ((Idioma.t("Has limpiado %s de arriba abajo") % Idioma.t(ed.el_nombre)) if nuevo.is_empty()
			else (Idioma.t("Has limpiado %s de arriba abajo. %s se viene a vivir a su habitación, junto a la sala de mantenimiento")
				% [Idioma.t(ed.el_nombre), Supervivientes.nombre_de(nuevo)])) if gano
			else (Idioma.t("Caíste en la %s de %s") % [Idioma.minusculas(Planta.nombre_de(planta)), Idioma.t(ed.el_nombre)]),
		"plantas": "%d / %d" % [Planta.PLANTAS if gano else planta.num - 1, Planta.PLANTAS],
		"muertos": muertos,
		"visitados": "%d / %d" % [visitados, apartamentos],
		"tiempo": tiempo,
		"nueva_marca": gano and (record[0] or mejor[0]),   # (el récord del edificio o la mejor marca del reto)
		"dolares": dolares,
		"salvados": salvados,
		"cartera": s.dolares,
		"alerta": Alerta.nivel,
		"extra": extra,
		"premio_reto": premio_reto,
		"abierta": abierta[0],
		"asesino": "" if gano else johnny.golpe_de,
		"conseguido": conseguido(Guardado.cargar()) + filas_rotas(rotas),   # (con los logros que acaba de dar el repaso)
	})


# Las armas y los arrojables que se han quedado sin partidas al acabar esta (la durabilidad: Objetos.cerrar_baul), para
# el cartel del final: una fila [icono, nombre, valor], como las de conseguido; ninguna si no se ha roto nada
func filas_rotas(rotas: Array) -> Array:
	if rotas.is_empty():
		return []
	var nombres: Array = rotas.map(func(e): return Armas.nombre(e.id, int(e.calidad)))
	return [[Objetos.icono(rotas[0].id), Idioma.n("Sin partidas: se ha roto", "Sin partidas: se han roto", rotas.size()),
		", ".join(nombres) if rotas.size() <= 2 else "+%d" % rotas.size()]]


# Lo conseguido en esta partida, para el cartel del final: lo que hay en el guardado "s" y no había al empezar
# (al_empezar). Cada fila, [icono, nombre, valor], ya traducida; si no hay nada nuevo, ninguna
func conseguido(s: Dictionary) -> Array:
	var filas: Array = []
	if al_empezar.is_empty():
		return filas
	var nuevos := func(lista: Array, antes: Array) -> Array: return lista.filter(func(id): return not id in antes)
	# los logros (se cobran en el ordenador: si ya se han cobrado todos, no se dice)
	var logros_nuevos: Array = nuevos.call(s.logros.keys(), al_empezar.logros)
	var sin_cobrar := logros_nuevos.any(func(id): return s.logros[id] == "conseguido")
	if logros_nuevos.size() == 1:
		filas.append(["trofeo", Idioma.t("Logro: %s") % Logros.nombre_de(logros_nuevos[0]),
			Idioma.t("cóbralo en el ordenador") if sin_cobrar else ""])
	elif logros_nuevos.size() > 1:
		filas.append(["trofeo", Idioma.n("%d logro nuevo", "%d logros nuevos", logros_nuevos.size()) % logros_nuevos.size(),
			Idioma.t("cóbralos en el ordenador") if sin_cobrar else ""])
	# las skins (con la cara de la primera), las páginas del dosier y lo nuevo de Colecciones
	var skins: Array = nuevos.call(s.skins, al_empezar.skins)
	if not skins.is_empty():
		var cara := "res://assets/ui/iconos/skin-%s.png" % skins[0]
		filas.append(["skin-" + skins[0] if ResourceLoader.exists(cara) else "skin-conserje",
			Idioma.n("Skin nueva", "Skins nuevas", skins.size()), ", ".join(skins.map(func(id): return Skins.nombre(id)))])
	var paginas: Array = nuevos.call(s.paginas, al_empezar.paginas)
	if not paginas.is_empty():
		filas.append(["dosier", Idioma.t("Páginas del dosier"), "+%d" % paginas.size()])
	var vistos: Array = nuevos.call(s.bestiario, al_empezar.bestiario)
	if not vistos.is_empty():
		filas.append(["zombi", Idioma.n("Nuevo en el bestiario", "Nuevos en el bestiario", vistos.size()),
			", ".join(vistos.map(func(id): return Bestiario.nombre(id))) if vistos.size() <= 2 else "+%d" % vistos.size()])
	# la planta más alta a la que se ha llegado en este edificio (el reto del día lleva su marca aparte)
	if not Reto.activo and planta.num > maxi(al_empezar.mejor_planta, 1):
		filas.append(["escalera", Idioma.t("¡Nueva mejor marca!"), Planta.nombre_de(planta)])
	return filas


func ir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")


# Al caer un zombi: deja su mancha en el suelo (addDecal del JS) y, si muere a golpes o a tiros (no quemado ni por los
# charcos), un charco que se va extendiendo. Los zombis que sangran ya no revientan en trozos de piel, gotas por todos
# lados y un anillo blanco (killEnemy del JS): el dueño lo veía irreal (8 nov). Les queda la sangre que salta del golpe
# que los mata, hacia donde va el golpe (zombi.gd: recibir_golpe). Siguen reventando el explosivo (su explosión: trozos
# color fuego y sin anillo) y los jefes (los trozos de su color)
func sangre(tipo: String, zombi: Node2D) -> void:
	var color: Color = MANCHAS.get(tipo, SANGRE)
	var jefa := tipo in JEFES
	if jefa or tipo == "explosivo":
		var trozos: Color = Color("#ff9f1c") if tipo == "explosivo" else PIELES.get(tipo, PIELES.normal)
		Particulas.reventon(zombi, zombi.global_position, trozos, 12, zombi.radio, tipo != "explosivo", color, zombi.get_parent())
	# de un golpe fuerte (un crítico, una explosión...), además revienta en sangre (M49; efecto_suelo.gd)
	if zombi.get("muerte_fuerte") and not jefa and tipo != "explosivo":
		EfectoSuelo.soltar(zombi.get_parent(), EfectoSuelo.SANGRE.get(tipo, "sangre"), zombi.global_position + Vector2(0, 10))
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


# Red de seguridad (10 nov): un zombi (o un jefe) con el centro dentro de un muro o fuera del mapa no se puede matar, y
# mientras quede uno la puerta no se abre y el combate no se termina. Si lleva ahí medio segundo seguido (lo normal es que
# no pase nunca: los empujones van con move_and_slide y paran en la pared), vuelve al suelo libre más cercano y, si no
# hay ninguno, se quita sin contarlo. Los que salen volando por el ventanal roto (meta "ventana") ya están muertos
const ATASCADO := 0.5
func rescatar_atascados(delta: float) -> void:
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.has_meta("ventana") or z.get("estado") == "muerto":
			continue
		if mapa.zona_en(z.position) >= 0:
			if z.has_meta("atascado"):
				z.remove_meta("atascado")
			continue
		var t: float = z.get_meta("atascado", 0.0) + delta
		z.set_meta("atascado", t)
		if t < ATASCADO:
			continue
		z.remove_meta("atascado")
		var suelo: Vector2 = mapa.suelo_cerca(z.position)
		print("Zombi atascado en ", z.position.round(), ": ", "al suelo en %s" % suelo.round() if suelo != Vector2.INF else "quitado")
		if suelo == Vector2.INF:
			z.remove_from_group("zombis")
			z.queue_free()
			continue
		z.position = suelo
		if "velocity" in z:
			z.velocity = Vector2.ZERO
		if "zona" in z:
			z.zona = mapa.zona_en(suelo)   # (la sala por la que se mueve)


# Saca un zombi del tipo que se pida (o la portera) en ese sitio del mapa. Durante la pelea del helipuerto, encima de
# él (los que llama el jefe, aunque los pida cerca del borde)
func meter_zombi(tipo: String, donde: Vector2) -> Node2D:
	if mapa.sitio.has("helipuerto") and jefa_salio and is_instance_valid(jefa) and jefa is Minijefe and not jefa.esperando:
		donde = mapa.a_la_plataforma(donde, 30.0)
	# nunca dentro de un muro ni fuera del mapa (los que llama un jefe, si los pide junto a la pared): al suelo más cercano.
	# Si no, se queda encerrado donde no se le puede matar y la puerta no se abre nunca (10 nov, la portera)
	if mapa.zona_en(donde) < 0:
		var suelo: Vector2 = mapa.suelo_cerca(donde)
		if suelo != Vector2.INF:
			donde = suelo
	var zombi: Node2D = ZOMBIS[tipo].instantiate()
	zombi.set_meta("tipo", tipo)   # quién es (Bestiario.de): el cartel de derrota dice quién te ha pillado
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
			if not zombi.has_meta("ventana"):
				sangre(tipo, zombi)
			return
		muertos += 1
		contar_matado(Bestiario.de(zombi))   # el de ahora: el gerente o el doctor, ya mutados, cuentan como lo que son
		var ardia: bool = zombi.get("arder_t") != null and zombi.arder_t > 0.0
		logros.zombi_muerto(johnny.huecos[johnny.mano], ardia)
		# tirado por el ventanal roto de la torre (peligros/viento.gd): cuenta, pero ni sangre ni suelta nada
		if zombi.has_meta("ventana"):
			return
		if tipo in JEFES:
			logros.jefe_muerto(tipo, zombi)
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
		# (la munición que sale, solo la de las armas que lleva Johnny: Armas.municion de la de fuego)
		var queda: String = Armas.municion(johnny.huecos.fuego)
		if tipo in JEFES:
			for i in 2:
				var suelto := Objetos.al_azar(edificio, tienda, queda)
				if suelto != "":
					soltar_objeto(suelto, zombi.position)
		else:
			var obj := Objetos.que_suelta(tipo, edificio, tienda, queda)
			if obj != "":
				soltar_objeto(obj, zombi.position)
				# con la skin del doctor Salas, a veces otro más al azar
				if randf() < Skins.doble(johnny.skin):
					var otro := Objetos.al_azar(edificio, tienda, queda)
					if otro != "":
						soltar_objeto(otro, zombi.position)
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
			gran_aviso(Idioma.t("¡SKIN NUEVA!"))
			decir(Idioma.t("Skin nueva: %s. Póntela en la taquilla de la sala de mantenimiento") % Skins.nombre(skin), 4.0)
		# el jefe final (el gerente mutado): su página del dosier y el helicóptero de Velaria
		if tipo in JEFES and not final_de(tipo).is_empty():
			fin_del_edificio()
		# la portera: un poco después de caer su cuerpo, las mutaciones (el jefe final, no: se acaba el edificio)
		if tipo in JEFES and final_de(tipo).is_empty():
			await get_tree().create_timer(2.0, false).timeout
			abrir_mutacion())
	if tipo in JEFES:
		# Cada planta, un 35 % más dura (JEFE_POR_PLANTA), y con la Alerta 3, más aún y se enfada antes.
		# El jefe final (el gerente), con su vida justa: ya está en la última planta
		var de_final := final_de(tipo)
		var por_planta := pow(JEFE_POR_PLANTA, planta.num - 1) if de_final.is_empty() else 1.0
		zombi.vida_max = int(zombi.vida_max * por_planta * Alerta.jefe_vida() * (VIDA_EDIFICIO_JEFE.get(edificio, 1.0) if de_final.is_empty() else 1.0))
		zombi.enfado = Alerta.jefe_enfado()
		# Su barra de vida grande, arriba (ui/barra_jefe.gd), y los vecinos que llama
		var barra_jefa: BarraJefe = $Pantalla/Jefa
		var el: String = Idioma.t(de_final.get("el_final", Edificios.MINIJEFES.get(tipo, {}).get("el", "la portera")))
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
		# Cada planta, más duros: ZOMBI_POR_PLANTA más de vida y de zarpazo por planta (M72: antes, iguales en todas). El
		# guardia, solo el zarpazo: su vida ya sube en poner_guardia(). En la sala de pruebas, como en la planta baja
		var mas: float = 1.0 + ZOMBI_POR_PLANTA * (planta.num - 1) if not de_mentira else 1.0
		if tipo != "guardia":
			var del_edificio: float = VIDA_EDIFICIO.get(edificio, 1.0) if not de_mentira and zombi.vida_max > 5 else 1.0
			zombi.vida_max = roundi(zombi.vida_max * mas * del_edificio)
		if "dano" in zombi:
			zombi.dano = roundi(zombi.dano * mas)
	mapa.cosas.add_child(zombi)
	return zombi


# La barra de armadura de los jefes (la del Gymbro): se hace la primera vez que hace falta, pegada debajo de la
# barra de vida grande, del ancho de su hueco y más fina, de color acero (la pinta la barra del jefe, con el mismo
# estilo: ui/barra_jefe.gd, pintar_armadura)
func armadura_jefe() -> ProgressBar:
	var barra: ProgressBar = $Pantalla/Jefa.get_node_or_null("Armadura")   # no-tr (nombre de nodo)
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
	for id in Objetos.USABLES:
		if evento.is_action_pressed(Objetos.USABLES[id].accion, false, true) and not cambiando and aqui != planta.armas:
			get_viewport().set_input_as_handled()
			usar_cura(id)
			return
	if not (evento is InputEventKey and evento.pressed and not evento.echo) or cambiando or presentacion.activa:
		return
	if evento.keycode == KEY_F9 and (OS.is_debug_build() or captura):   # (la sala de pruebas: en el editor y en las versiones de prueba de la web, no en el juego terminado)
		pruebas()
	elif evento.keycode == KEY_P and aqui == planta.armas:
		abrir_panel_pruebas()
	elif aqui == planta.armas and panel_pruebas.atajo(evento):
		pass   # (1 a 8, un zombi; Mayús + 1 a 0, un jefe: ui/panel_pruebas.gd)


# ═════════════ La sala de pruebas ═════════════

# F9: a la sala de pruebas (sala_armas.gd) desde donde se esté y, desde ella (o desde la exposición, a la que se va
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
		decir("Con la puerta cerrada no se puede ir a la sala de pruebas")   # no-tr (herramienta interna: F9)
		Sonido.tocar("no")
		return
	sitio_pruebas()
	de_pruebas = {"planta": planta, "sitio": aqui, "pos": johnny.position}
	await montar(planta.armas, 0)
	decir("Sala de pruebas · P: panel de pruebas · guion: líneas y daño · F9: volver", 3.5)   # no-tr


# La sala de pruebas y la exposición, como dos sitios más de la planta (la planta baja ya las trae: planta.gd)
func sitio_pruebas() -> void:
	if planta.armas >= 0:
		return
	planta.armas = planta.sitios.size()
	planta.sitios.append(Planta.sala_armas(-1))
	planta.expo = planta.sitios.size()
	planta.sitios.append(Planta.exposicion(planta.armas))


# Uno más de este tipo matado en esta partida (al acabar pasa al guardado, "matados": las fichas de Colecciones)
func contar_matado(id: String) -> void:
	if id in Bestiario.LISTA:
		matados[id] = matados.get(id, 0) + 1


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
	decir("Científico de prueba: " + p.cuerpo)   # no-tr


# El panel de pruebas: derecho a la azotea, sin subir planta a planta
func ir_a_azotea() -> void:
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada())
	decir("Azotea · ¡El último combate del edificio!", 2.5)   # no-tr (panel de pruebas)


# El panel de pruebas (los de los Apartamentos: el Glotón, el Gymbro, el jefe de bomberos y la portera): derecho a su
# habitación, sin jugar hasta ella. Rehace la planta que le tocó en el sorteo de esta partida (como recién llegado) y
# Johnny entra por la puerta: el jefe sale como siempre, con su presentación (acaba cuando ya ha salido)
func ir_al_jefe(tipo: String) -> void:
	var num := orden_jefes.find(tipo) + 1
	if num <= 0 or jefe_de(num) != tipo:
		decir("Ese jefe no está en este edificio")   # no-tr
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
	decir("10 piezas de cada familia y unas armas y arrojables mejorados al baúl")   # no-tr
