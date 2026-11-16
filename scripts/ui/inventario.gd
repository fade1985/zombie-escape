# Las pantallas de las cosas de Johnny (en el JS, showInventario y showBaul de src/ui.js). El juego se para
# mientras están abiertas:
#   - Inventario (Tab, I o Select): Johnny grande en medio, de
#     frente, con su skin y el arma que tiene en la mano; a los lados, sus armas (a la izquierda las de cuerpo a cuerpo
#     y a la derecha las de distancia; arriba la de la mano y abajo la de repuesto: partida.llevar_arma), y debajo, los
#     3 arrojables a mano (lanzables.gd; desde el 13 nov no hay de repuesto) y, abajo del todo, el dinero, el mutágeno y el hueco de la llave (no están en el HUD). En medio, la mochila (8), la munición (8, por tipos:
#     Armas.MUNICION) y, abajo, las 2 casillas de las curas (Objetos.USABLES; son de
#     la mochila, pero van aparte y no ocupan casilla de «Objetos»). A la derecha, la ficha de lo elegido (qué es, el cargador, las
#     barras y qué hace) y sus botones: "Ponérmela" (las de repuesto), "Usar" (lo de curar:
#     Objetos.USABLES), "A la mano" y "Al repuesto" (los arrojables) y "Tirar al suelo" (los objetos, la gasolina,
#     los bidones de ácido y las baterías, de uno en uno; las balas, el hueco entero en una caja; los arrojables, de uno en
#     uno, con su calidad y su durabilidad; y las armas: la de la mano, solo si lleva otra de repuesto, que pasa a la mano). Con las flechas o el mando, la ficha sigue a la marca; A (o tocar)
#     la lleva al botón principal de la ficha (A dos veces y hecho), X (o Supr) tira, Y hace lo del botón principal y F
#     cambia el arrojable que se lanza.
#   - Baúl (al arrimarse a él en la sala de mantenimiento): la pantalla partida en
#     dos y se maneja como el inventario. A la izquierda, lo que lleva Johnny: sus armas y los arrojables a mano (solo
#     para verlos) y los objetos, la munición y los arrojables de repuesto. A la derecha, sus 32 casillas: los objetos
#     guardados, que ya no se pierden si Johnny cae. Abajo, la ficha de lo elegido
#     con su botón: «Guardar en el baúl» mete todo lo de esa casilla (también las vendas y el botiquín y todo el
#     hueco de munición, balas y cartuchos incluidos; con el baúl lleno, solo caben más de lo que ya tiene) y
#     «Sacar uno», un objeto de uno en uno (a la mochila o a la munición; la munición, la casilla entera de una vez:
#     Objetos.tanda). «Guardar todo» mete todo lo que se pueda, la munición también. En cada casilla cabe lo de un
#     hueco de munición, un montón de curas o un montón de arrojables (Objetos.monton y monton_arrojables)
#   - Banco de trabajo (al arrimarse a él en el taller): como el baúl, pero para
#     subir de calidad las armas y los paquetes de arrojables, los que lleva y los del baúl, gastando piezas de su
#     familia (ver «Banco de trabajo», abajo).
#   - «Destruir» (el botón rojo de debajo de «Tirar al suelo»; en el baúl, bajo el botón principal): quita para siempre
#     la casilla elegida, entera: los objetos de la mochila y la munición (el hueco), y en el baúl, además, sus
#     objetos, armas y paquetes de arrojables (para hacer sitio). No se puede deshacer, así que pide confirmación: sale
#     en el centro la ventanita «¿Estás seguro?» (confirmar.gd) con lo que se perdería, y con Sí se destruye. Sin atajo
#     del mando y sin arrastrar. Las armas y los arrojables que
#     lleva Johnny no se destruyen (para eso, «Tirar al suelo»)
# Van con el ratón, con flechas + Intro o con el mando (A elige, B cierra). En el inventario y en el baúl, además, las
# cosas se arrastran con el ratón o el dedo (ver «arrastrar», abajo), y lo que llega a
# su sitio nuevo da un saltito (también con los botones y el mando).
extends CanvasLayer

signal cerrado

const FONDO_CASILLA := Color("#1b1822")
const GRIS := Color("#8a8494")               # el borde de las casillas (las armas y los objetos de siempre)

var partida: Node
var fondo: ColorRect
var abierto := ""          # "inventario", "baul", "banco" o "" (nada)
var sel := ""              # la casilla elegida: "m2" la 3.ª de la mochila, "g0" la 1.ª arma guardada,
                           # "b2" el 3.er objeto del baúl, "u1" el 2.º hueco de munición, "l0" el 1.er arrojable a mano,
                           # "e3" el 4.º de repuesto, "p0" y "p1" las armas de la mano (la de cuerpo a cuerpo y la de distancia),
                           # "q1" en el banco, la 2.ª arma o paquete del baúl
var foco := ""             # el botón que tiene que quedar marcado al volver a pintar
var aviso := ""            # inventario y baúl: lo que se dice abajo una vez (por qué no se puede usar o no cabe)
var lienzo: Control        # inventario y baúl: donde va todo, cada cosa en su sitio
var viva: Control          # inventario y baúl: lo que cambia al moverse la marca (la ficha y la ayuda de abajo)
var huecos_inv: Array = [] # inventario y baúl: las casillas que se pueden elegir (para marcar la elegida)
var moviendo_marca := false   # la marca la está poniendo el juego (dar_foco), no el jugador
var sitios: Array = []     # inventario y baúl: dónde se puede soltar lo que se arrastra, [nombre, Rect2 en el lienzo, casilla]
var arrastre := {}         # lo que se está arrastrando: {"clave": su casilla} (vacío: nada)
var capa: Control          # mientras se arrastra: los sitios encendidos (encima del lienzo)
var tapa: Control          # y lo que recibe lo que se suelta (encima de todo)
var encima := ""           # el sitio encendido que está bajo el dedo (crece un poco)
var salta: Array = []      # las casillas que dan un saltito al volver a pintar (lo que acaba de llegar)
var salta_johnny := false  # y Johnny, al ponerse un arma o curarse
var encendidos := {}       # mientras se arrastra: los sitios donde se puede soltar (destinos)
var con_dedo := false      # lo que se hace ahora viene de soltar algo arrastrado (suena «soltar» en vez de «cambiar»)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abrir(que: String, p: Node) -> void:
	partida = p
	abierto = que
	if que == "baul" and Guardado.cargar().baul_nuevo:   # (ya has visto lo recién comprado: se quita el «!» del baúl)
		Guardado.cambiar(func(g): g.baul_nuevo = false)
	sel = ""
	foco = ""
	aviso = ""
	llevando = ""
	salta = []
	salta_johnny = false
	pintar(true)


func cerrar() -> void:
	if abierto == "":
		return
	if get_viewport().gui_is_dragging():   # (si se cierra con algo levantado, se suelta sin más)
		get_viewport().gui_cancel_drag()
	arrastre = {}
	llevando = ""
	abierto = ""
	if fondo:
		fondo.queue_free()
		fondo = null
	cerrado.emit()


func pintar(entrar := false) -> void:
	if fondo:
		fondo.queue_free()
	fondo = ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.06, 0.72)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	panel.add_child(columna)
	if entrar:
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2(0.9, 0.9)
		panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
		panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var primero: Control
	match abierto:
		"inventario": primero = pintar_inventario(columna)
		"baul": primero = pintar_baul(columna)
		"banco": primero = pintar_banco(columna)
	# se queda marcado el mismo botón que antes (o el primero, si ya no está o se ha apagado)
	var marcado: Control = fondo.find_child(foco, true, false) if foco != "" else null
	if marcado == null or not marcado.focus_mode == Control.FOCUS_ALL or (marcado is BaseButton and marcado.disabled):
		marcado = primero
	if marcado:
		dar_foco.call_deferred(marcado)
	salta = []   # (los saltitos ya han empezado)
	salta_johnny = false


# Pone la marca en un botón (al pintar, o al tocar una casilla del inventario). La pone el juego, no el jugador: en el
# inventario no cambia lo elegido (seguir_marca). Si mientras tanto se ha vuelto a pintar, la de la pantalla quitada
# ya no cuenta
func dar_foco(c) -> void:   # (sin tipo: puede llegar ya borrado)
	if not is_instance_valid(c) or not is_instance_valid(fondo) or not fondo.is_ancestor_of(c):
		return
	moviendo_marca = true
	c.grab_focus()
	moviendo_marca = false


# ── Inventario ──
# La pantalla «todo a la vista» (parte 3 del inventario nuevo; la maqueta es diseno-1-prueba.png), hecha para la
# pantalla de 960×640: cada cosa va en su sitio, en coordenadas de la pantalla (el panel va de 24,12 a 936,628). Al
# moverse la marca solo se vuelven a pintar la ficha y la ayuda de abajo (pintar_ficha); todo, al hacer algo.

const ORIGEN := Vector2(24, 12)    # la esquina del panel del inventario en la pantalla
# Desde el M100 (13 nov) el inventario va dentro de una mochila abierta y es más pequeño que antes (las casillas, de 52
# a 48; las armas, de 76 a 64; Johnny, a ×3), para que alrededor se vea la mochila entera. La letra, igual (16)
const LADO := 48                   # las casillas de los tres grupos de 8 (las de las armas, 64, y las de los arrojables a
# mano, 72, sin apenas margen: así sus dibujos siguen a × 2, como antes; el grande de la ficha, 96, a × 3)
const PASO := 54                   # de una casilla a la siguiente
const FICHA := Rect2(618, 146, 238, 434)   # el papel de la ficha (sin el clip, que sobresale por arriba)
const ANCHO_FICHA := 214.0         # lo ancho que es lo de dentro de la ficha
# Lo del M100, de GPT y reducido con tools/inventario_gpt.py: la mochila de fondo (su forro, de 100,140 a 860,584 de la
# pantalla), el papel de la ficha, la cinta de los títulos y la etiqueta de la llave. Todo, a 2
const MOCHILA := preload("res://assets/ui/inventario-mochila.png")
const MOCHILA_EN := Vector2(-61, -45)   # dónde va su esquina en la pantalla (lo dice tools/inventario_gpt.py)
const PAPEL := preload("res://assets/ui/inventario-papel.png")
const CINTA := preload("res://assets/ui/inventario-cinta.png")
const ETIQUETA := preload("res://assets/ui/inventario-etiqueta.png")
const CHAPA := preload("res://scripts/ui/chapa.gd")   # la pantallita del dinero, la de la tienda de armas
# Lo que hace cada arma de la tienda y cada arrojable (se traduce al enseñarlo, en que_hace; el ordenador también lo lee)
# [traducir]
const QUE_HACE := {
	"fregona": "Barre un abanico muy ancho y echa lejos a los durmientes.",
	"bate": "Un golpe fuerte que empuja a los durmientes.",
	"cuchillo": "Muy rápido, pero hay que arrimarse.",
	"motosierra": "Lenta, pero un durmiente normal cae de un solo golpe. Llega lejos, recto hacia delante.",
	"katana": "Desenvaina de golpe y corta de abajo arriba. Rápida, con un abanico medio.",
	"pistola": "Dispara de una en una, recto y lejos.",
	"escopeta": "Cinco perdigones en abanico. Se recarga de cartucho en cartucho.",
	"mp5": "Ráfagas muy rápidas. Gasta las mismas balas que la pistola.",
	"gatling": "Tarda un momento en arrancar y luego no para. Pesa: andas más despacio. Gasta cinta de balas.",
	"lanzagranadas": "Granadas que revientan al tocar algo y hacen daño alrededor (¡también a ti!). Se recarga de una en una.",
	"lanzallamas": "Llamarada continua que quema a todos. Se llena con gasolina.",
	"desintegrador": "Chorro de ácido continuo que corroe a todos. Se llena con bidones de ácido.",
	"lanza_hielo": "Nube helada que no hace daño: enfría a todos hasta congelarlos, y luego se rematan con otra arma. Se llena con bombonas de nitrógeno.",
	"pistola_electrica": "Rayo continuo que aturde y salta al durmiente de al lado. Se llena con baterías.",
	"molotov": "Se rompe y deja un charco de fuego que quema a los durmientes.",
	"granada": "Bota, rueda y explota a los 2 segundos.",
	"atraedora": "Suena, atrae a los durmientes 3 s y explota.",
	"congeladora": "Explota y deja a los durmientes congelados 3 s.",
}
# [/traducir]
const PRINCIPALES := ["poner", "usar", "a_la_mano", "al_repuesto", "guardar", "sacar", "mejorar"]   # los de la ficha que no son tirar


func pintar_inventario(columna: VBoxContainer) -> Control:
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	asegurar_sel()
	preparar_lienzo(columna)
	# el fondo: la mochila de lona abierta, con todo dentro, sobre el forro (M100, de GPT; sin el marco gris ni el título
	# «Inventario» de antes). Es más grande que la pantalla: se sale por los lados, arriba y abajo
	columna.get_parent().add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var mochila := estampa(MOCHILA, MOCHILA.get_size() * 2.0)
	lienzo.add_child(mochila)
	mochila.position = MOCHILA_EN - ORIGEN
	# Johnny, grande, entre sus armas: a la izquierda las de cuerpo a cuerpo y a la derecha las de distancia (arriba
	# la de la mano y abajo la de repuesto)
	muneco(johnny)
	sitio("johnny", Rect2(186, 170, 108, 160))
	cinta(Idioma.t("Cuerpo a cuerpo"), 118, 146)
	cinta(Idioma.t("A distancia"), 362, 146, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in 2:
		var tipo: String = ["cuerpo", "fuego"][i]
		var x := 118.0 if i == 0 else 298.0
		var id: String = johnny.huecos[tipo]
		var r := Rect2(x, 172, 64, 64)
		sitio("p%d" % i, r, casilla_inv(r, "p%d" % i, Objetos.icono(id), "", borde(id), 0.0))   # (sin «12/12»: M100)
		rotulo(lienzo, Idioma.t("Equipada"), x + 32, 238, Tema.AMARILLO, HORIZONTAL_ALIGNMENT_CENTER)
		var otra: String = partida.repuesto(tipo)
		r = Rect2(x, 262, 64, 64)
		if otra != "":
			sitio("r%d" % i, r, casilla_inv(r, "g%d" % partida.armas_guardadas.find(otra), Objetos.icono(otra),
				"", borde(otra), 0.0))
		else:
			sitio("r%d" % i, r, casilla_inv(r))
		rotulo(lienzo, Idioma.t("Guardada"), x + 32, 328, Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER)
	# debajo, los arrojables a mano (F cambia entre ellos): el que se lanza ahora, con un marco amarillo alrededor
	cinta(Idioma.t("Lanzables"), 118, 356)   # (sin «F cambia» a la derecha desde el M100)
	for i in Lanzables.MANO:
		var x := 120.0 + i * 84
		var k: String = lz.mano[i] if i < lz.mano.size() else ""
		sitio("l%d" % i, Rect2(x, 382, 72, 72), arrojable(Rect2(x, 382, 72, 72), "l%d" % i, k, 8.0, false))
		if k == "":
			continue
		rotulo(lienzo, nombre_lanzable(k), x + 36, 456, Tema.TINTA, HORIZONTAL_ALIGNMENT_CENTER, 84)
		if k == lz.tipo:
			var ahora := Panel.new()
			var e := StyleBoxFlat.new()
			e.draw_center = false
			e.border_color = Tema.AMARILLO
			e.set_border_width_all(2)
			e.set_corner_radius_all(4)
			ahora.add_theme_stylebox_override("panel", e)
			ahora.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lienzo.add_child(ahora)
			ahora.position = Vector2(x - 4, 378) - ORIGEN
			ahora.size = Vector2(80, 80)
	# y abajo, la etiqueta de la llave y, a su derecha, el dinero en la pantallita de la tienda de armas (chapa.gd: el «$»
	# y la cifra en amarillo, sin los «8» apagados) y, debajo, el mutágeno, el guardado más el de esta partida (15 nov: la hélice y
	# la cifra en verde; lo mismo que en el árbol de talentos). Los dos, del mismo tamaño (4 cifras, con un «8» apagado en cada casilla; desde 10.000, «8MAX»: CHAPA, fijo).
	# En el HUD no se ven
	hueco_llave()
	var fuente: Font = Tema.FUENTE
	for m in [["dinero", partida.cartera(), CHAPA.AMARILLO, false, 488], ["mutageno", partida.mutageno_total(), CHAPA.VERDE, true, 526]]:
		var marcador := Control.new()
		marcador.name = m[0]
		marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marcador.size = CHAPA.medida_fija(fuente)
		marcador.draw.connect(func(): CHAPA.dibujar_marcador(marcador, fuente, Rect2(Vector2.ZERO, marcador.size), m[1], m[2], m[3], true))
		lienzo.add_child(marcador)
		marcador.position = Vector2(262, m[4]) - ORIGEN
	# en medio, los dos grupos de 8: los objetos de la mochila y la munición y, abajo, las 2 casillas de las curas, en
	# medio (13 nov: antes, 4, y a su izquierda 4 de arrojables de repuesto)
	raya(Rect2(380, 148, 2, 430))
	# (cada cosa en su casilla, la que le ha dado el jugador o la primera libre: pintar_grupo, 16 nov)
	cinta(Idioma.t("Objetos"), 392, 146)   # (sin «0 / 8» desde el M100; igual los demás)
	pintar_grupo("objetos", rejilla.bind(170), 10.0)
	# (los tres grupos, repartidos a lo alto hasta «Seguir», con el mismo hueco entre ellos: 13 nov)
	cinta(Idioma.t("Munición"), 392, 296)
	pintar_grupo("municion", rejilla.bind(320), 10.0)
	cinta(Idioma.t("Curas"), (cuadro(0).position.x + cuadro(Objetos.CURAS - 1).end.x) / 2.0, 446, HORIZONTAL_ALIGNMENT_CENTER)
	pintar_grupo("curas", cuadro, 10.0)
	# abajo, «Ordenar» (lo coloca todo agrupado por tipo: 16 nov) y «Seguir», que vuelve a la partida («Resume»)
	var orden := boton(lienzo, "ordenar", Idioma.t("Ordenar"), ordenar)
	orden.position = Vector2(392, 544) - ORIGEN
	orden.size = Vector2(106, 36)
	var seguir := boton(lienzo, "cerrar", Idioma.t("Seguir", "inventario"), cerrar)
	seguir.position = Vector2(502, 544) - ORIGEN
	seguir.size = Vector2(106, 36)
	for b in [orden, seguir]:
		encoger(b)
	sitio("tirar", FICHA)   # la ficha: al arrastrar algo que se puede tirar, se vuelve la zona roja
	pintar_ficha()
	return lienzo.find_child(sel, false, false)


# El hueco de la llave de la jefa (o de la tarjeta de acceso, en el centro comercial), al lado del dinero: una etiqueta
# de cartón con su cordel (M100), apagada y con su nombre desvaído hasta que Johnny la coge; entonces se enciende, con
# el nombre de la puerta que abre (hasta el M100, un recuadro con el borde amarillo)
func hueco_llave() -> void:
	var tiene: bool = partida.planta.tiene_llave
	var caja := estampa(ETIQUETA, ETIQUETA.get_size() * 2.0)
	caja.modulate = Color.WHITE if tiene else Color(0.5, 0.48, 0.45)
	lienzo.add_child(caja)
	caja.position = Vector2(118, 504) - ORIGEN
	var icono := dibujo(caja, "llave", Vector2(42, 40), 8.0)
	icono.modulate.a = 1.0 if tiene else 0.35
	var nombre: String = Idioma.t("Tarjeta") if partida.ed.cerrojo == "tarjeta" else Idioma.t("Llave")
	var t := rotulo(lienzo, partida.nombre_jefa() if tiene else nombre, 160, 513, TINTA_BANCO, HORIZONTAL_ALIGNMENT_LEFT, 0.0)
	if not tiene:
		t.modulate.a = 0.45
	# (lo que no cabe antes del ojal, con la letra más pequeña)
	var tam := 16
	while tam > 11 and Tema.FUENTE.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > 72:
		tam -= 1
	if tam < 16:
		t.add_theme_font_size_override("font_size", tam)
		t.position.y += (16 - tam) / 2.0


# Un título de grupo sobre una tira de cinta de papel (M100), con la letra oscura: la cinta se estira al largo del
# texto (sus puntas rotas, quietas) y va a 2, como todo. Como rotulo: a la izquierda, x es donde empieza el texto; a
# la derecha, donde acaba; centrado, su mitad. Con "ancho_max", si en este idioma el texto no cabe, se achica la letra (hasta 11)
func cinta(s: String, x: float, y: float, alinear := HORIZONTAL_ALIGNMENT_LEFT, ancho_max := 0.0) -> Label:
	var t := rotulo(lienzo, s, x, y, TINTA_BANCO, alinear)
	var tam := t.get_theme_font_size("font_size")
	var ancho := Tema.FUENTE.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	if ancho_max > 0.0 and ancho > ancho_max:
		var antes := tam
		while tam > 11 and ancho > ancho_max:
			tam -= 1
			ancho = Tema.FUENTE.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		t.add_theme_font_size_override("font_size", tam)
		t.position.y += floorf((antes - tam) / 2.0)
	var izquierda := x - ancho if alinear == HORIZONTAL_ALIGNMENT_RIGHT else x - floorf(ancho / 2.0) if alinear == HORIZONTAL_ALIGNMENT_CENTER else x
	var tira := NinePatchRect.new()
	tira.texture = CINTA
	tira.patch_margin_left = 4
	tira.patch_margin_right = 4
	tira.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	tira.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tira.scale = Vector2(2, 2)
	tira.size = Vector2(ceilf((ancho + 12.0) / 2.0), CINTA.get_height())
	lienzo.add_child(tira)
	lienzo.move_child(tira, t.get_index())
	tira.position = Vector2(izquierda - 6.0, y - 1.0) - ORIGEN
	return t


# El panel, sin márgenes por dentro, con el lienzo donde va cada cosa en su sitio (el inventario y el baúl)
func preparar_lienzo(columna: VBoxContainer) -> void:
	var panel: PanelContainer = columna.get_parent()
	var marco: StyleBox = panel.get_theme_stylebox("panel").duplicate()
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		marco.set_content_margin(lado, 0)
	panel.add_theme_stylebox_override("panel", marco)
	lienzo = Control.new()
	lienzo.custom_minimum_size = Vector2(912, 616)
	columna.add_child(lienzo)
	viva = null
	huecos_inv.clear()
	sitios.clear()


# Apunta un sitio donde se puede soltar lo que se arrastra (en coordenadas de la pantalla): una casilla ("nodo", para
# que crezca al pasar por encima) o una zona (Johnny, la ficha, una mitad del baúl)
func sitio(nombre: String, r: Rect2, nodo: Control = null) -> void:
	sitios.append([nombre, Rect2(r.position - ORIGEN, r.size), nodo])


# Una raya que separa las partes del lienzo (en coordenadas de la pantalla)
func raya(r: Rect2, color := Color("#3d3647")) -> void:
	var c := ColorRect.new()
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(c)
	c.position = r.position - ORIGEN
	c.size = r.size


# El sitio de la casilla i de un grupo de 8 (4 por fila) que empieza en "y"
func rejilla(i: int, y: float) -> Rect2:
	return Rect2(392 + (i % 4) * PASO, y + floori(i / 4.0) * PASO, LADO, LADO)


# Abajo, en el sitio del tercer grupo de 8, las casillas de las curas (Objetos.CURAS), en una fila y centradas
func cuadro(i: int) -> Rect2:
	var r := rejilla(i, 470)
	r.position.x += (rejilla(3, 0).end.x - rejilla(Objetos.CURAS - 1, 0).end.x) / 2.0
	return r


# Si lo elegido ya no está (o no hay nada elegido), se elige otra cosa: la ficha nunca está vacía. En el inventario, el
# arma que tiene en la mano; en el baúl, lo primero que se puede guardar (de la mochila y luego de la munición) y, si no
# hay nada, lo primero del baúl (y si está vacío, el arma de la mano)
func asegurar_sel() -> void:
	if existe(sel):
		return
	if abierto == "baul":
		if not Objetos.casillas(partida.mochila).is_empty():
			sel = "m0"
			return
		var huecos: Array = partida.johnny.huecos_municion()
		for i in huecos.size():
			if huecos[i][0] in Objetos.NOMBRES:
				sel = "u%d" % i
				return
		for clave in ["a0", "b0"]:
			if existe(clave):
				sel = clave
				return
	sel = "p0" if partida.johnny.mano == "cuerpo" else "p1"


# ¿Hay algo en esa casilla del inventario, del baúl o del banco?
func existe(clave: String) -> bool:
	if clave.length() < 2:
		return false
	var i := clave.substr(1).to_int()
	var lz: Lanzables = partida.lanzables
	match clave[0]:
		"p": return i < 2
		"g": return i < partida.armas_guardadas.size()
		"m": return i < Objetos.casillas(partida.mochila).size()
		"u": return i < partida.johnny.huecos_municion().size()
		"l": return i < lz.mano.size()
		"e": return i < lz.repuesto.size()
		"b": return i < cosas_baul(Guardado.cargar()).size()
		"q": return i < Guardado.cargar().baul_equipo.size()
	return false


# Johnny grande (× 3; × 4 hasta el M100) en medio, con su sombra: de frente y respirando, con su skin y el arma que tiene en la mano. Si
# se acaba de poner un arma o de curar, da un saltito
func muneco(johnny: Node2D) -> void:
	var pies := Vector2(240, 322) - ORIGEN
	var sombra := Control.new()
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sombra.draw.connect(func():
		sombra.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
		Formas.disco(sombra, Vector2.ZERO, 26.0, Color(0, 0, 0, 0.43)))
	lienzo.add_child(sombra)
	sombra.position = pies
	var w: Dictionary = Armas.datos(johnny.huecos[johnny.mano])
	var vista := AnimatedSprite2D.new()
	vista.name = "johnny"
	vista.sprite_frames = Skins.hoja(w.hoja, johnny.skin)
	vista.centered = false
	vista.offset = -w.pies
	vista.scale = Vector2(3, 3)
	vista.position = pies
	vista.material = johnny.sprite.material.duplicate()   # (el de partir la cintura, entero, como en la taquilla)
	vista.material.set_shader_parameter("parte", 0)
	lienzo.add_child(vista)
	vista.play("reposo_s")
	vista.speed_scale = 2.0   # respira el doble de rápido que en el juego (una vez cada 1,5 s), para que no parezca muerto (M101)
	if salta_johnny:
		saltar(vista, 12.0)


# Una casilla del inventario en su sitio (en coordenadas de la pantalla): su dibujo, lo más grande que quepa (dejando
# "margen" alrededor), y abajo a la derecha cuántos. Sin "clave", vacía (no se elige). Al llegarle la marca (flechas o
# mando), la ficha enseña lo suyo; con el ratón o el dedo, además, se arrastra (levantar). Si acaba de llegar ("salta"),
# su dibujo da un saltito
func casilla_inv(r: Rect2, clave := "", icono := "", cuenta := "", color := GRIS, margen := 12.0) -> Control:
	var c: Control
	if clave == "":
		c = Panel.new()
		c.add_theme_stylebox_override("panel", estilo(Color("#2a2631"), false, false))
	else:
		var b := Button.new()
		b.name = clave
		b.set_meta("borde", color)
		b.pressed.connect(tocar.bind(clave))
		b.focus_entered.connect(seguir_marca.bind(clave, b))
		b.set_drag_forwarding(levantar.bind(clave, b), Callable(), Callable())
		huecos_inv.append(b)
		marcar_hueco(b)
		c = b
	lienzo.add_child(c)
	c.position = r.position - ORIGEN
	c.size = r.size
	if icono != "":
		var d := dibujo(c, icono, r.size, margen)
		c.set_meta("dibujo", d)
		if clave in salta:
			saltar(d, 10.0)
	if cuenta != "":
		var t := Label.new()
		t.text = cuenta
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		t.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(t)
		t.size = r.size - Vector2(5, 1)
	return c


# El borde y el fondo de una casilla según esté elegida o no
func marcar_hueco(b: Button) -> void:
	var color: Color = b.get_meta("borde")
	var elegida: bool = b.name == sel
	b.add_theme_stylebox_override("normal", estilo(color, elegida, false))
	b.add_theme_stylebox_override("hover", estilo(color, elegida, true))
	b.add_theme_stylebox_override("pressed", estilo(color, true, true))
	b.add_theme_stylebox_override("focus", estilo(color, elegida, true))


# El dibujo de un icono en medio de una casilla de ese tamaño, lo más grande que quepa a escala entera (para que los
# píxeles no se deformen)
func dibujo(padre: Control, icono: String, lado: Vector2, margen: float) -> TextureRect:
	# las armas, con el dibujo de la tienda de armas (Objetos.textura: de 48, 13 nov; la fregona, que no se vende, también
	# tiene el suyo). Esos dibujos ya traen aire alrededor: sin margen (si no, en las fichas grandes del baúl y del banco
	# saldrían a × 1, más pequeños que el icono). En las casillas donde no cabe a × 1 (las pequeñas del baúl y del banco:
	# 16 nov), se encoge al cuadro que ocupaba el icono viejo (32, con su aire alrededor y sin tocar el borde)
	var tex := Objetos.textura(icono)
	var k := maxf(1.0, floorf(minf((lado.x - margen) / tex.get_width(), (lado.y - margen) / tex.get_height())))
	if Objetos.de_tienda(tex):
		k = floorf(minf(lado.x / tex.get_width(), lado.y / tex.get_height()))
		if k < 1.0:
			var cuadro := 32.0 * maxf(1.0, floorf(minf((lado.x - margen) / 32.0, (lado.y - margen) / 32.0)))
			k = minf(cuadro, minf(lado.x, lado.y)) / maxf(tex.get_width(), tex.get_height())
	var r := estampa(tex, (tex.get_size() * k).floor())
	padre.add_child(r)
	r.position = ((lado - r.size) / 2.0).floor()
	return r


# La casilla de un montón de arrojables ("" la deja vacía): su dibujo y cuántos quedan en él, de los que caben (con
# "con_cuenta" en falso, sin eso: así va en el inventario desde el M100; el baúl y el banco lo siguen diciendo)
func arrojable(r: Rect2, clave: String, k: String, margen := 12.0, con_cuenta := true) -> Control:
	if k == "":
		return casilla_inv(r)
	var lz: Lanzables = partida.lanzables
	return casilla_inv(r, clave, icono_lanzable(k), "%d/%d" % [lz.cuantos_en(clave), lz.maximo(k)] if con_cuenta else "",
		Armas.color(Lanzables.calidad_de(k)), margen)


# Cuántos de un montón de arrojables (por su clave) caben en el baúl, con los de su clase que ya haya
func caben_lanzables(s: Dictionary, k: String) -> int:
	return Objetos.caben_arrojables(s, Lanzables.tipo_de(k), Lanzables.calidad_de(k), partida.lanzables.quedan_de(k), true)


# El nombre de un paquete por su clave, con su calidad («Molotov (Rara)»)
func nombre_lanzable(k: String) -> String:
	return Armas.nombre(Lanzables.tipo_de(k), Lanzables.calidad_de(k))


func icono_lanzable(k: String) -> String:
	return Lanzables.tipo_de(k)   # (assets/ui/iconos/<tipo>.png)


# Lo que le queda a un arma de fuego que lleva: en el cargador (balas) o, las de depósito, en el depósito (segundos).
# La de la mano, lo de ahora; la de repuesto, lo que le quedaba al dejarla (johnny.coger) o, si no la ha llevado
# nunca en la mano, lleno
func carga(id: String) -> float:
	var johnny: Node2D = partida.johnny
	var w: Dictionary = johnny.base(id)
	var deposito: bool = w.has("deposito")
	if johnny.huecos.fuego == id:
		return johnny.deposito if deposito else float(johnny.balas)
	return float(johnny.cargadores.get(id, w.get("deposito", w.cargador)))


# Lo que se ve en la esquina de la casilla de un arma de fuego: «8/12» o, las de depósito, «6 s» ("" las de cuerpo a
# cuerpo)
func carga_corta(id: String) -> String:
	if id == "":
		return ""   # (sin arma a distancia)
	var w: Dictionary = partida.johnny.base(id)
	if w.tipo != "fuego":
		return ""
	if w.has("deposito"):
		return "%d s" % ceili(carga(id))
	return "%d/%d" % [roundi(carga(id)), w.cargador]


# ── Inventario: la ficha ──

# La ficha de lo elegido, a la derecha, con sus botones debajo, y la línea de ayuda de abajo (con lo que hacen X e Y
# con lo elegido). Es lo que cambia al moverse la marca: se quita la de antes (ya, para que no haya dos «nota») y se
# pinta la nueva. En el baúl y en el banco, la suya (pintar_ficha_baul y pintar_ficha_banco)
func pintar_ficha() -> void:
	if abierto == "baul":
		pintar_ficha_baul()
		return
	if abierto == "banco":
		pintar_ficha_banco()
		return
	if viva:
		lienzo.remove_child(viva)
		viva.queue_free()
	viva = Control.new()
	viva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(viva)
	# la ficha, en una hoja de papel cuadriculado con su clip (M100; antes, el marco oscuro de marco_ficha): el clip
	# sobresale por arriba
	var papel := estampa(PAPEL, PAPEL.get_size() * 2.0)
	viva.add_child(papel)
	papel.position = Vector2(FICHA.position.x, FICHA.end.y - papel.size.y) - ORIGEN   # (el clip sobresale por arriba)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	caja.custom_minimum_size.x = ANCHO_FICHA
	viva.add_child(caja)
	caja.position = Vector2(630, 158) - ORIGEN
	asegurar_sel()
	# lo de cada cosa: la cabeza de la ficha y lo de debajo, lo que hace ("que") y sus botones ([nombre, texto, al
	# pulsar, apagado])
	var i := sel.substr(1).to_int()
	var d: Dictionary
	match sel[0]:
		"p": d = ficha_arma(caja, partida.johnny.huecos["cuerpo" if i == 0 else "fuego"], true)
		"g": d = ficha_arma(caja, partida.armas_guardadas[i], false)
		"m": d = ficha_objeto(caja, Objetos.casillas(partida.mochila)[i])
		"u": d = ficha_municion(caja, partida.johnny.huecos_municion()[i])
		_: d = ficha_lanzable(caja, sel)   # ("l" a mano y "e" de repuesto)
	poner_mover(d)
	espacio(caja, 8)
	var texto := nota_de(d.que)
	var nota := renglon(caja, texto[0], texto[1], HORIZONTAL_ALIGNMENT_LEFT)
	nota.name = "nota"   # (las pruebas la leen)
	aviso = ""
	# los botones, abajo del todo; el principal, con las letras amarillas
	var botones := VBoxContainer.new()
	botones.add_theme_constant_override("separation", 4)
	botones.custom_minimum_size.x = 206
	viva.add_child(botones)
	var atajos := {}   # lo que hacen X e Y con lo elegido, para la línea de ayuda
	for b in d.botones:
		var pulsar := boton(botones, b[0], b[1], b[2],
			"BotonRojo" if b[0] in ["tirar", "destruir"] else "")   # no-tr
		pulsar.disabled = b[3]
		if b[0] in PRINCIPALES:
			for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				pulsar.add_theme_color_override(c, Tema.AMARILLO)
		if not b[3] and (b[0] in PRINCIPALES or b[0] == "tirar"):   # (sin atajo: «Destruir», para no destruir nada sin querer, y «Mover»)
			atajos["X" if b[0] == "tirar" else "Y"] = Idioma.t("tirar") if b[0] == "tirar" else Idioma.minusculas(b[1], true)
	botones.position = Vector2(634, 572 - botones.get_combined_minimum_size().y) - ORIGEN
	# Si en este idioma lo que hace (más largo que en español: ruso, alemán) llegaría a los botones, se achica la letra
	# (hasta 12) hasta que quepa
	var libre := (572.0 - botones.get_combined_minimum_size().y) - (158.0 + caja.get_combined_minimum_size().y - nota.get_combined_minimum_size().y) - 4.0
	var cortes := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE   # (los del texto que se parte solo)
	var tam := 16
	while tam > 12 and Tema.FUENTE.get_multiline_string_size(texto[0], HORIZONTAL_ALIGNMENT_LEFT, ANCHO_FICHA, tam, -1, cortes).y > libre:
		tam -= 1
	if tam < 16:
		nota.add_theme_font_size_override("font_size", tam)
	# sobre el papel, todo en tinta oscura y sin contorno: lo claro, marrón casi negro; lo amarillo, óxido; lo rojo, rojo
	# oscuro, y lo gris, marrón (los de encima de la madera del banco)
	for t in caja.find_children("*", "Label", true, false):
		var c: Color = t.get_theme_color("font_color")
		t.add_theme_color_override("font_color", {Tema.AMARILLO: ACENTO_BANCO, Tema.ROJO: Color("#a3161a"),
			Tema.GRIS: GRIS_BANCO}.get(c, TINTA_BANCO))
		t.add_theme_constant_override("outline_size", 0)
	pintar_ayuda(atajos)


# El marco oscuro de la ficha, en su sitio (en coordenadas de la pantalla)
func marco_ficha(padre: Control, r: Rect2) -> void:
	var marco := Panel.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color("#141119")
	e.border_color = Color("#3d3647")
	e.set_border_width_all(2)
	e.set_corner_radius_all(4)
	marco.add_theme_stylebox_override("panel", e)
	padre.add_child(marco)
	marco.position = r.position - ORIGEN
	marco.size = r.size


# La línea de ayuda de abajo: los botones del mando (A elegir, lo que hacen X e Y con lo elegido —"atajos"— y B
# cerrar) y, a la derecha, que también va con el ratón o el dedo. Solo en el inventario: el baúl y el banco ya no la
# llevan (11 nov)
func pintar_ayuda(atajos: Dictionary) -> void:
	var ayuda := HBoxContainer.new()
	ayuda.add_theme_constant_override("separation", 5)
	viva.add_child(ayuda)
	ayuda.position = Vector2(118, 598) - ORIGEN
	var partes := [["A", Idioma.t("elegir")]]
	for k in ["X", "Y"]:
		if k in atajos:
			partes.append([k, atajos[k]])
	partes.append(["B", Idioma.minusculas(Idioma.t("Cancelar"), true) if llevando != "" else Idioma.t("cerrar")])   # (llevando algo con «Mover», B lo deja)
	for p in partes:
		ayuda.add_child(tecla(p[0]))
		var t := Label.new()
		t.text = p[1]
		t.add_theme_color_override("font_color", Tema.GRIS)
		ayuda.add_child(t)
		var hueco := Control.new()
		hueco.custom_minimum_size.x = 11
		ayuda.add_child(hueco)
	rotulo(viva, Idioma.t("Ratón o dedo: tocar o arrastrar"), 842, 599,
		Tema.GRIS, HORIZONTAL_ALIGNMENT_RIGHT)


# Lo de arriba de la ficha: el dibujo grande, el nombre y, debajo, qué es
func cabeza(caja: VBoxContainer, icono: String, nombre: String, que_es: String) -> void:
	var grande := Panel.new()
	grande.custom_minimum_size = Vector2(96, 96)
	grande.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grande.add_theme_stylebox_override("panel", estilo(Tema.AMARILLO, false, false))
	caja.add_child(grande)
	dibujo(grande, icono, Vector2(96, 96), 0.0)
	espacio(caja, 4)
	renglon(caja, nombre, Color("#e6dec8")).theme_type_variation = "Titulo"
	# El «qué es» va en una sola línea: si en este idioma no cabe a tamaño 16 (ruso: «Дальний бой · Необычное · В руках»),
	# se achica la letra (hasta 12) en vez de pasar a dos líneas, que taparían lo de debajo
	var linea := renglon(caja, que_es, Tema.GRIS)
	var tam := 16
	while tam > 12 and Tema.FUENTE.get_string_size(que_es, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ANCHO_FICHA:
		tam -= 1
	if tam < 16:
		linea.add_theme_font_size_override("font_size", tam)


# Cómo se dice la familia de un arma, lo que sale en la ficha debajo de su nombre (13 nov: antes, también su calidad y
# si es la de la mano o la de repuesto)
static func familia_nombre(id: String) -> String:
	match Armas.familia(id):
		"cuerpo": return Idioma.t("Cuerpo a cuerpo")
		"especial": return Idioma.t("Especial")
	return Idioma.t("A distancia")


# La ficha de un arma ("puesta": la de la mano; si no, la de repuesto): si es de fuego, lo que le queda en el cargador
# (con sus balitas) y en la reserva; las barras, lo que hace y sus botones. La de la mano se puede tirar si lleva otra de
# repuesto (que pasa a la mano)
func ficha_arma(caja: VBoxContainer, id: String, puesta: bool) -> Dictionary:
	var johnny: Node2D = partida.johnny
	if id == "":   # el hueco de fuego vacío: nada que tirar ni que mejorar
		cabeza(caja, Objetos.icono(id), Objetos.nombre(id), Idioma.t("A distancia"))
		return {"que": Idioma.t("La pistola se ha quedado en el baúl y no llevas otra arma a distancia. Sácala de allí para volver a disparar."),
			"botones": []}
	var w: Dictionary = johnny.arma_de(id)
	cabeza(caja, Objetos.icono(id), Objetos.nombre(id), familia_nombre(id))
	renglon(caja, Armas.texto_partidas(johnny.quedan_de(id)), Tema.ROJO if johnny.quedan_de(id) <= 0 else Tema.AMARILLO)
	if w.tipo == "fuego":
		var tipo := Armas.municion(id)
		espacio(caja, 4)
		if w.has("deposito"):
			renglon(caja, Idioma.t("Depósito: %d de %d s") % [ceili(carga(id)), roundi(w.deposito)], Tema.TINTA)
		else:
			balitas(caja, tipo, roundi(carga(id)), w.cargador)
			renglon(caja, Idioma.t("Cargador %d de %d") % [roundi(carga(id)), w.cargador], Tema.TINTA)
		renglon(caja, Idioma.t("Reserva: %s") % cuenta_municion(tipo, johnny.cuanta(tipo)), Tema.GRIS)
	espacio(caja, 8)
	for b in barras(w):
		barra(caja, b[0], b[1])
	var que: String = que_hace(id)
	if not puesta:
		return {"que": que, "botones": [["poner", Idioma.t("Ponérmela"), poner_guardada, false],
			["tirar", Idioma.t("Tirar al suelo"), tirar, false]]}
	var otra: String = partida.repuesto(w.tipo)
	if otra != "":
		que += " " + Idioma.t("Si la tiras, la de repuesto pasa a la mano.")
	return {"que": que, "botones": [["tirar", Idioma.t("Tirar al suelo"), tirar, otra == ""]]}


# Las barras de la ficha de un arma, de 1 a 10 (con los talentos y la skin ya contados: johnny.arma_de): cuánto pega
# cada golpe (o cada segundo, las de depósito), lo rápido que ataca, hasta dónde llega y lo rápido que recarga; las de
# cuerpo a cuerpo, en vez de recargar, lo ancho que barren. La barra llena: 40 de daño, 8 ataques por segundo, el
# alcance del bate (cuerpo a cuerpo) o de la pistola, y el barrido de la fregona
func barras(w: Dictionary) -> Array:
	var lista := [[Idioma.t("Daño"), w.dano * w.get("perdigones", 1) / 4.0],
		[Idioma.t("Cadencia"), 10.0 if w.has("deposito") else w.ritmo / 0.8]]
	if w.tipo == "cuerpo":
		lista.append([Idioma.t("Alcance"), w.alcance / 7.0])
		lista.append([Idioma.t("Empuje"), w.arco / 14.0])
	else:
		lista.append([Idioma.t("Alcance"), w.alcance / 42.0])
		lista.append([Idioma.t("Recarga"), 10.0 - w.recarga * (w.cargador if w.cartucho else 1) * 3.0])   # (la escopeta, uno a uno)
	return lista.map(func(b): return [b[0], clampi(ceili(b[1]), 1, 10)])


# Una barra de la ficha: su nombre y 10 cuadraditos, llenos los que diga "valor"
func barra(caja: VBoxContainer, nombre: String, valor: int) -> void:
	var hilera := HBoxContainer.new()
	hilera.add_theme_constant_override("separation", 0)
	if Idioma.actual == "zh_CN":
		hilera.custom_minimum_size.y = 20   # (los hanzi llenan la línea entera: sin esto, las filas se tocan)
	caja.add_child(hilera)
	var t := Label.new()
	t.text = nombre
	hilera.add_child(t)
	t.custom_minimum_size.x = maxf(96.0, t.get_minimum_size().x + 6.0)   # (el nombre más largo, «Перезарядка», no se pega a los cuadros)
	var cuadros := Control.new()
	cuadros.custom_minimum_size = Vector2(109, 9)
	cuadros.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cuadros.draw.connect(func():
		for i in 10:
			var r := Rect2(i * 11, 0, 8, 9)
			cuadros.draw_rect(r, color_barra(valor) if i < valor else Color("#332e3a"))
			cuadros.draw_rect(r, Tema.LINEA, false, 1.0))
	hilera.add_child(cuadros)


# El color de los cuadraditos llenos de una barra (M100): rojos si hay 3 o menos, amarillos de 4 a 7 y verdes de 8 a 10
static func color_barra(valor: int) -> Color:
	if valor <= 3:
		return Color("#e0483c")
	return Tema.AMARILLO if valor <= 7 else Color("#5cc94a")


# Las balitas del cargador, una por bala (las gastadas, apagadas); los cartuchos, con su dibujo
func balitas(caja: VBoxContainer, tipo: String, llenas: int, total: int) -> void:
	var tex: Texture2D = load("res://assets/ui/iconos/%s.png" % ("cartucho" if tipo == "cartuchos" else "bala"))
	var paso := mini(7, floori(ANCHO_FICHA / total))
	var hilera := Control.new()
	hilera.custom_minimum_size = Vector2(total * paso - 2, 12)
	hilera.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hilera.draw.connect(func():
		for i in total:
			hilera.draw_texture(tex, Vector2(i * paso, 1), Color.WHITE if i < llenas else Color(0.35, 0.35, 0.4, 0.8)))
	caja.add_child(hilera)


# La ficha de una casilla de la mochila ([id, cuántos]): lo de curar se usa; lo demás, solo se lleva (hasta el 25 oct
# decía para qué recetas del banco de trabajo servía; ahora las piezas dicen para qué armas son, que_pieza)
func ficha_objeto(caja: VBoxContainer, c: Array) -> Dictionary:
	var id: String = c[0]
	var curar := id in Objetos.USABLES
	cabeza(caja, Objetos.icono(id), Objetos.nombre(id),
		Idioma.t("Para curar") if curar else Idioma.t("Material de fabricación · Mejora armas") if id in Objetos.PIEZAS else Idioma.t("Objeto · Común"))
	if c[1] > 1:
		renglon(caja, Idioma.t("Llevas %d") % c[1], Tema.TINTA)
	if curar:
		var cura := (Idioma.t("Te devuelve un tercio de vida perdido y te cura %d.") if Objetos.USABLES[id].get("tercio", false)
			else Idioma.t("Te cura %d de vida, sin pasar del tercio en el que estás.")) % partida.cura_de(id)
		return {"que": cura + " " + Idioma.t("Sin abrir el inventario, se usa con la tecla %s. Se llevan como mucho %d. Si caes, se pierde (en el baúl queda a salvo).") %
				[Controles.tecla_de(Objetos.USABLES[id].accion), Objetos.TOPE[id]],
			"botones": [["usar", Idioma.t("Usar"), usar, false], ["tirar", Idioma.t("Tirar al suelo"), tirar, false],
				["destruir", Idioma.t("Destruir"), destruir, false]]}
	return {"que": que_pieza(id) + Idioma.t("Si caes, se pierde (en el baúl queda a salvo)."),
		"botones": [["tirar", Idioma.t("Tirar al suelo"), tirar, false], ["destruir", Idioma.t("Destruir"), destruir, false]]}


# Lo que dice la ficha de una pieza (Objetos.PIEZAS): para qué armas es y dónde se gasta. De lo demás, nada ("")
func que_pieza(id: String) -> String:
	if not id in Objetos.PIEZAS:
		return ""
	return Idioma.t("Sirve para mejorar %s en el banco de trabajo del taller.") % Objetos.pieza_para(Objetos.PIEZAS[id]) + " "


# La ficha de un hueco de munición ([tipo, cuánta]): cuánta lleva y quién la gasta. La gasolina, el ácido y las
# baterías se tiran de uno en uno; las balas, el hueco entero en una caja
func ficha_municion(caja: VBoxContainer, h: Array) -> Dictionary:
	var tipo: String = h[0]
	var m: Dictionary = Armas.MUNICION[tipo]
	cabeza(caja, m.icono, Armas.municion_nombre(tipo), Idioma.t("Munición"))
	renglon(caja, Idioma.t("%d en este hueco · llevas %d") % [h[1], partida.johnny.cuanta(tipo)], Tema.TINTA)
	var que := Idioma.t("La gastan %s (caben %d en cada hueco). Al tirarlo, el hueco entero se queda en el suelo en una caja.") % [
		Armas.municion_para(tipo), m.hueco]
	if tipo in Objetos.NOMBRES:   # la gasolina, el bidón de ácido y la batería
		que = Idioma.t("Llena %s (caben %d en cada hueco). Se tira de uno en uno.") % [Armas.municion_para(tipo), m.hueco]
	return {"que": que, "botones": [["tirar", Idioma.t("Tirar al suelo"), tirar, false],
		["destruir", Idioma.t("Destruir"), destruir, false]]}


# La ficha de un montón de arrojables ("l1" a mano o "e3" de repuesto): cuántos quedan y lo que hace; se pasa de la mano
# al repuesto y al revés, y se tiran al suelo como las armas (15 nov, lo pidió el dueño)
func ficha_lanzable(caja: VBoxContainer, sitio: String) -> Dictionary:
	var lz: Lanzables = partida.lanzables
	var k := lz.clave_en(sitio)
	var a_mano := sitio.begins_with("l")
	cabeza(caja, icono_lanzable(k), nombre_lanzable(k), Idioma.t("Lanzable"))
	var todos := lz.total(Lanzables.tipo_de(k))   # (de ese tipo, en todos sus montones)
	var quedan: String
	if todos > lz.cuantos_en(sitio):
		quedan = Idioma.t("Te quedan %d de %d · %d en total") % [lz.cuantos_en(sitio), lz.maximo(k), todos]
	else:
		quedan = Idioma.t("Te quedan %d de %d") % [lz.cuantos_en(sitio), lz.maximo(k)]
	renglon(caja, quedan, Tema.TINTA)
	renglon(caja, Armas.texto_partidas(lz.quedan_de(k)), Tema.ROJO if lz.quedan_de(k) <= 0 else Tema.AMARILLO)
	var que: String = que_hace(k)
	if a_mano:
		que += " " + (Idioma.t("Es lo que lanzas ahora.") if k == lz.tipo else Idioma.t("Con F lo eliges para lanzarlo."))
		if lz.relevo(k) >= 0:
			que += " " + Idioma.t("Cuando se acabe, entra otro montón de los de repuesto.")
		if Lanzables.REPUESTO <= 0:   # (13 nov: ya no hay repuesto al que pasarlo)
			return {"que": que, "botones": [["tirar", Idioma.t("Tirar al suelo"), tirar, false]]}
		return {"que": que, "botones": [["al_repuesto", Idioma.t("Al repuesto"), mover_lanzable,
			lz.repuesto.size() >= Lanzables.REPUESTO], ["tirar", Idioma.t("Tirar al suelo"), tirar, false]]}
	var j := sitio.substr(1).to_int()
	if lz.mano_llena_de(j):
		que += " " + Idioma.t("Ya llevas a mano un montón lleno de estos: entrará cuando se acabe.")
	elif k in lz.mano:
		que += " " + Idioma.t("«A la mano» llena con estos el montón que llevas a mano.")
	elif lz.mano.size() >= Lanzables.MANO:
		que += " " + Idioma.t("«A la mano» lo cambia por %s, que pasa aquí.") % Idioma.minusculas(nombre_lanzable(lz.tipo))
	return {"que": que, "botones": [["a_la_mano", Idioma.t("A la mano"), mover_lanzable, lz.mano_llena_de(j)],
		["tirar", Idioma.t("Tirar al suelo"), tirar, false]]}


# Una línea de la ficha (si no cabe en "ancho", se parte en varias)
func renglon(caja: VBoxContainer, s: String, color: Color, alinear := HORIZONTAL_ALIGNMENT_CENTER,
		ancho := ANCHO_FICHA) -> Label:
	var t := Label.new()
	t.text = s
	t.horizontal_alignment = alinear
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = ancho
	t.add_theme_constant_override("line_spacing", -2)
	t.add_theme_color_override("font_color", color)
	caja.add_child(t)
	return t


func espacio(caja: BoxContainer, alto: int) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = alto
	caja.add_child(c)


# Una tecla del mando en la ayuda de abajo: su letra en una cajita de metal
func tecla(letra: String) -> PanelContainer:
	var c := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Tema.METAL
	e.border_color = Tema.GRIS
	e.set_border_width_all(2)
	e.set_corner_radius_all(2)
	e.content_margin_left = 6
	e.content_margin_right = 6
	c.add_theme_stylebox_override("panel", e)
	var t := Label.new()
	t.text = letra
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(t)
	return c


# Un texto en su sitio (en coordenadas de la pantalla): a la izquierda empieza en x; centrado, x es su centro, y a la
# derecha, su borde derecho. Con "ancho", se parte en líneas si no cabe
func rotulo(padre: Control, s: String, x: float, y: float, color := Tema.TINTA, alinear := HORIZONTAL_ALIGNMENT_LEFT,
		ancho := 0.0) -> Label:
	var t := Label.new()
	t.text = s
	t.horizontal_alignment = alinear
	t.add_theme_color_override("font_color", color)
	if color in [TINTA_BANCO, ACENTO_BANCO, GRIS_BANCO]:   # (los oscuros del banco, sobre la madera: sin el contorno)
		t.add_theme_constant_override("outline_size", 0)
	var w := ancho if ancho > 0.0 else 300.0
	if ancho > 0.0:
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_constant_override("line_spacing", -4)
	padre.add_child(t)
	var dx: float = {HORIZONTAL_ALIGNMENT_CENTER: w / 2.0, HORIZONTAL_ALIGNMENT_RIGHT: w}.get(alinear, 0.0)
	t.position = Vector2(x - dx, y) - ORIGEN
	t.size = Vector2(w, 0)
	return t


# ── Inventario: elegir y hacer ──

# Elige una casilla del inventario: se marca y la ficha enseña lo suyo
func elegir(clave: String) -> void:
	sel = clave
	asegurar_sel()
	for b in huecos_inv:
		marcar_hueco(b)
	pintar_ficha()


# Con las flechas o el mando, la ficha enseña lo de la casilla que tiene la marca, sin pulsar nada (con el ratón, al
# tocarla). Cuando la marca la pone el juego (dar_foco), no
func seguir_marca(clave: String, b: Control) -> void:
	if abierto in ["inventario", "baul", "banco"] and sel != clave and not moviendo_marca and llevando == "" and is_instance_valid(lienzo) \
			and lienzo.is_ancestor_of(b):
		elegir(clave)


# El botón de la ficha que hace lo suyo con lo elegido («Ponérmela», «Usar», «A la mano» o «Al repuesto»; en el baúl,
# «Guardar en el baúl» o «Sacar»; en el banco, «Mejorar»; no «Tirar al suelo»), si se puede pulsar
func principal() -> Button:
	if not is_instance_valid(viva):
		return null
	for nombre in PRINCIPALES:
		var b: Button = viva.find_child(nombre, true, false)
		if b and not b.disabled:
			return b
	return null


# Vuelve a pintar todo, con la marca donde estaba
func repintar() -> void:
	var dueno := get_viewport().gui_get_focus_owner()
	foco = String(dueno.name) if dueno and fondo and fondo.is_ancestor_of(dueno) else ""
	pintar()


# Pasa el montón de arrojables elegido de la mano al repuesto o al revés (lanzables.gd); la ficha sigue con él, en su
# sitio nuevo. Con "por" (el sitio de otro montón, al soltarlo encima), cambia con ese. Si a mano ya lleva esa clase, se
# juntan. Lo que cambia de sitio da un saltito
func mover_lanzable(por := "") -> void:
	var lz: Lanzables = partida.lanzables
	var i := sel.substr(1).to_int()
	var k := lz.clave_en(sel)
	var donde := ""   # el sitio donde queda el elegido
	var otro := ""    # y el del que cambia de sitio con él (o con el que se junta)
	if por != "" and lz.se_juntan(sel, por):
		# encima de otro montón de la misma clave que no está lleno: se le pasan los que quepan (juntar). Lo que llega da
		# el saltito y se queda elegido; si el de donde salían se ha vaciado y era de la mano, su hueco lo ocupa otro
		var vacia_mano := sel.begins_with("l") and lz.cuantos_en(sel) <= lz.maximo(k) - lz.cuantos_en(por)
		var antes_mano := lz.mano.size()
		var antes_rep := lz.repuesto.size()
		lz.juntar(sel, por)
		donde = por
		# (si se ha quitado un montón de antes en la lista de repuesto, el de destino corre un sitio)
		if por.begins_with("e") and sel.begins_with("e") and lz.repuesto.size() < antes_rep and i < por.substr(1).to_int():
			donde = "e%d" % (por.substr(1).to_int() - 1)
		elif por.begins_with("e") and vacia_mano and lz.mano.size() == antes_mano and lz.sitio_de(k).begins_with("l"):
			donde = lz.sitio_de(k)   # (el de la mano se vació y su relevo ha sido justo ese montón)
		if lz.cuantos_en(sel) > 0 and lz.clave_en(sel) == k:
			otro = sel
	elif sel.begins_with("e") and k != "" and not lz.mano_llena_de(i):
		var antes := lz.repuesto.size()
		lz.a_la_mano(i, lz.clave_en(por) if por.begins_with("l") else "")
		donde = lz.sitio_de(k)
		if lz.repuesto.size() == antes:
			otro = "e%d" % i
	elif sel.begins_with("l") and k != "" and por.begins_with("e") and lz.clave_en(por) != "":
		var j := por.substr(1).to_int()
		var vino := lz.clave_en(por)
		lz.a_la_mano(j, k)
		donde = lz.sitio_de(k) if k in lz.mano else por
		otro = lz.sitio_de(vino)
	elif sel.begins_with("l") and k != "" and lz.repuesto.size() < Lanzables.REPUESTO:
		lz.al_repuesto(i)
		donde = "e%d" % (lz.repuesto.size() - 1)
	else:
		Sonido.tocar("no")
		return
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	sel = donde
	salta = [sel]
	if otro != "" and otro != sel:
		salta.append(otro)
	foco = sel
	pintar()


# El borde de la casilla de un arma que lleva: el color de su calidad (Armas.CALIDADES; la Normal, gris)
func borde(id: String) -> Color:
	return Armas.color(partida.johnny.calidad(id))


# El objeto de la casilla de la mochila elegida ("" si no hay ninguna elegida)
func elegido() -> String:
	var llenas := Objetos.casillas(partida.mochila)
	var i := sel.substr(1).to_int()
	return llenas[i][0] if sel.begins_with("m") and i < llenas.size() else ""


# Usa lo elegido de la mochila (el botiquín): se cierra el inventario y Johnny se cura. Si no se puede (con la
# vida llena), lo dice en la ficha y no se gasta. Soltado encima de Johnny ("en_johnny"), el inventario sigue abierto
# y Johnny da un saltito
func usar(en_johnny := false) -> void:
	var id := elegido()
	var no: String = partida.usar_objeto(id)
	if no != "":
		Sonido.tocar("no")
		aviso = no
		foco = "usar"
		pintar()
		return
	sel = ""
	if not en_johnny:
		cerrar()
		return
	aviso = Idioma.t("Te has curado %d de vida.") % partida.cura_de(id)
	salta_johnny = true
	foco = ""
	pintar()


# El garaje del reto del día: lo que hoy no vale (garaje.gd, la condición del día) no sale del baúl ni se pone en la
# mano. Si es eso, lo dice abajo y devuelve true
func no_vale(id: String) -> bool:
	if not Garaje.prohibido(id):
		return false
	Sonido.tocar("no")
	aviso = Garaje.no_vale()
	pintar()
	return true


# Se pone en la mano el arma de repuesto elegida; la que llevaba (de su mismo tipo) pasa al repuesto. La ficha enseña
# la que se acaba de poner; las dos dan un saltito, y Johnny también
func poner_guardada() -> void:
	var i := sel.substr(1).to_int()
	var guardadas: Array = partida.armas_guardadas
	if not sel.begins_with("g") or i >= guardadas.size():
		return
	var johnny: Node2D = partida.johnny
	var id: String = guardadas[i]
	if no_vale(id):
		return
	var tipo: String = Armas.datos(id).tipo
	guardadas[i] = johnny.huecos[tipo]
	johnny.coger(id)
	Sonido.tocar("cambiar")
	sel = "p0" if tipo == "cuerpo" else "p1"
	salta = [sel, "g%d" % i]
	salta_johnny = true
	foco = sel
	pintar()


# Tira al suelo, a los pies de Johnny, lo elegido: un objeto de la mochila (uno), un arma (la de la mano, solo si lleva
# otra de repuesto, que pasa a la mano), un lanzable (uno, con su calidad y su durabilidad) o munición (la gasolina, los bidones de ácido y las baterías, de uno en uno; las balas, todas
# las del hueco en una caja que las devuelve). Con "todo" (soltándolo en la zona roja), la casilla o el hueco entero, en
# fila a sus pies. Si ya no queda nada de lo elegido, la ficha vuelve al arma de la mano
func tirar(todo := false) -> void:
	var i := sel.substr(1).to_int()
	var mochila: Array = partida.mochila
	var johnny: Node2D = partida.johnny
	var suelo: Vector2 = johnny.position + Vector2(0, 34)
	var a_sus_pies := func(id: String, n: int) -> void:   # tira "n" de ese objeto de la mochila
		for k in n:
			mochila.remove_at(mochila.rfind(id))
			partida.soltar_objeto(id, suelo + Vector2((k - (n - 1) / 2.0) * 14.0, 0), true)
	if sel.begins_with("u"):
		var huecos: Array = johnny.huecos_municion()
		if i >= huecos.size():
			return
		var tipo: String = huecos[i][0]
		if tipo in Objetos.NOMBRES:
			a_sus_pies.call(tipo, huecos[i][1] if todo else 1)
		else:
			var n: int = huecos[i][1]
			johnny.municion[tipo] -= n
			if johnny.municion[tipo] <= 0:
				johnny.municion.erase(tipo)
			partida.soltar_municion(suelo, tipo, n)
		johnny.avisar_arma()
		huecos = johnny.huecos_municion()
		if i >= huecos.size() or huecos[i][0] != tipo:
			sel = ""
	elif sel.begins_with("m"):
		var llenas := Objetos.casillas(mochila)
		if i >= llenas.size():
			return
		var id: String = llenas[i][0]
		a_sus_pies.call(id, llenas[i][1] if todo else 1)
		if not id in mochila:
			sel = ""
	elif sel.begins_with("l") or sel.begins_with("e"):
		var lz: Lanzables = partida.lanzables
		var k := lz.clave_en(sel)
		if k == "":
			return
		var q := lz.quedan_de(k)   # (sus partidas: vuelven con él al recogerlo)
		var n := lz.quitar(sel, lz.cuantos_en(sel) if todo else 1)
		for j in n:
			partida.soltar_lanzable(k, suelo + Vector2((j - (n - 1) / 2.0) * 14.0, 0), true, q)
		if lz.clave_en(sel) != k:
			sel = ""
	elif sel.begins_with("g"):
		var id: String = partida.armas_guardadas[i]
		partida.armas_guardadas.remove_at(i)
		partida.soltar_arma(id, suelo, johnny.calidad(id), johnny.quedan_de(id))   # (con su calidad y sus partidas)
		johnny.calidades.erase(id)
		johnny.quedan.erase(id)
		sel = ""
	elif sel.begins_with("p"):
		var tipo := "cuerpo" if sel == "p0" else "fuego"
		var otra: String = partida.repuesto(tipo)
		if otra == "":
			Sonido.tocar("no")
			return
		var id: String = johnny.huecos[tipo]
		var mano: String = johnny.mano
		partida.armas_guardadas.erase(otra)
		johnny.coger(otra)
		if johnny.mano != mano:
			johnny.sostener(mano)   # (la otra mano sigue con la suya)
		partida.soltar_arma(id, suelo, johnny.calidad(id), johnny.quedan_de(id))
		johnny.calidades.erase(id)
		johnny.quedan.erase(id)
		salta = [sel]
		salta_johnny = true
	else:
		return
	Sonido.tocar("porrazo")   # (un golpe seco: ha caído al suelo)
	foco = sel
	pintar()


# ── Baúl ──
# La pantalla del baúl (parte 4 del inventario nuevo; la maqueta es maqueta-baul-parte4.png), hecha como la del
# inventario: cada cosa en su sitio, en coordenadas de la pantalla. A la izquierda, lo que lleva Johnny: sus armas y los
# arrojables a mano y, en filas de 8, los objetos, la munición y los arrojables de repuesto con las curas. A la derecha, las casillas
# del baúl: los objetos guardados y, cada una en su casilla y con el borde del color de su calidad, las armas y los
# arrojables (cosas_baul; parte 4 de la tienda y las piezas: van al baúl todas las armas menos la fregona y la pistola
# Normales, Armas.al_baul, y todos los arrojables, juntos los de la misma clase: Objetos.arrojables_al_baul). Abajo, la ficha de lo
# elegido con su botón, «Guardar en el baúl», «Sacar uno», «Sacar 5» o «Sacar». Al moverse la marca solo se vuelve a
# pintar la ficha (pintar_ficha_baul)

const MITAD := 476.0          # donde empieza la mitad del baúl
# El banco de trabajo (12 nov): su fondo y los colores de lo que va encima del tablero de madera clara
const FONDO_BANCO := preload("res://assets/ui/banco-fondo.png")   # 456 × 308, a 2: el lienzo entero
const TINTA_BANCO := Color("#2b1d12")    # los textos: marrón muy oscuro (antes, hueso claro sobre el gris)
const ACENTO_BANCO := Color("#8a3410")   # lo que antes iba en amarillo: óxido oscuro
const GRIS_BANCO := Color("#5c4630")     # «Tienes 4»
const RAYA_BANCO := Color("#6e5236")     # las rayas que separan
const ANCHO_NOTA := 380.0     # lo ancho que es el texto de la ficha del baúl


func pintar_baul(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	asegurar_sel()
	preparar_lienzo(columna)
	rotulo(lienzo, Idioma.t("Baúl"), 480, 26, Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER).theme_type_variation = "Titulo"
	# a la izquierda, lo que lleva: arriba sus armas (de cada tipo, la de la mano y la de repuesto) y los arrojables a
	# mano; debajo, los objetos, la munición y los arrojables de repuesto
	rotulo(lienzo, Idioma.t("Lo que llevas"), 64, 86, Color("#e6dec8"))
	rotulo(lienzo, Idioma.t("Armas"), 64, 110, Tema.AMARILLO)
	rotulo(lienzo, Idioma.t("Lanzables"), en_fila(5, 0).position.x, 110, Tema.AMARILLO)
	for i in 2:
		var tipo: String = ["cuerpo", "fuego"][i]
		var id: String = johnny.huecos[tipo]
		casilla_inv(en_fila(i * 2, 132), "p%d" % i, Objetos.icono(id), carga_corta(id), borde(id), 8.0)
		var otra: String = partida.repuesto(tipo)
		if otra != "":
			casilla_inv(en_fila(i * 2 + 1, 132), "g%d" % partida.armas_guardadas.find(otra), Objetos.icono(otra),
				carga_corta(otra), borde(otra), 8.0)
		else:
			casilla_inv(en_fila(i * 2 + 1, 132))
	for i in Lanzables.MANO:
		arrojable(en_fila(5 + i, 132), "l%d" % i, lz.mano[i] if i < lz.mano.size() else "", 8.0)
	var llenas := Objetos.casillas(partida.mochila)
	var objetos := Objetos.ocupadas(partida.mochila)   # las curas van al final de "llenas"
	rotulo(lienzo, Idioma.t("Objetos  %d / %d") % [objetos, Objetos.MOCHILA], 64, 182, Tema.AMARILLO)
	pintar_grupo("objetos", en_fila.bind(204), 8.0)   # (cada cosa en su casilla, como en el inventario: 16 nov)
	var balas: Array = johnny.huecos_municion()
	rotulo(lienzo, Idioma.t("Munición  %d / %d") % [balas.size(), Armas.HUECOS_MUNICION], 64, 254, Tema.AMARILLO)
	pintar_grupo("municion", en_fila.bind(276), 8.0)
	# y en la última fila, las curas (13 nov: antes, a la derecha de 4 arrojables de repuesto)
	rotulo(lienzo, Idioma.t("Curas %d/%d") % [llenas.size() - objetos, Objetos.CURAS], en_fila(0, 348).position.x, 326, Tema.AMARILLO)
	pintar_grupo("curas", en_fila.bind(348), 8.0)
	raya(Rect2(452, 92, 2, 298))
	# a la derecha, el baúl: los objetos, con cuántos hay, y las armas y los paquetes de arrojables, con el color de su
	# calidad. Si pasa de 32 (al completar el edificio, lo que lleva entra aunque no quepa), las casillas se hacen más
	# pequeñas para que quepan todas
	var cosas := cosas_baul(s)
	var filas := maxi(ceili(Objetos.BAUL / 8.0), ceili(cosas.size() / 8.0))
	var paso := mini(52, floori(264.0 / filas))
	rotulo(lienzo, Idioma.t("Baúl  %d / %d") % [Objetos.casillas_baul(s), Objetos.BAUL], MITAD, 86, Color("#e6dec8"))
	rotulo(lienzo, Idioma.t("Objetos, armas y lanzables"), MITAD, 110, Tema.GRIS)
	# (cada cosa en su casilla: pintar_grupo, 16 nov; con «Ordenar» arriba a la derecha, que lo coloca todo por tipos, lo
	# del baúl y lo que lleva)
	pintar_grupo("baul", func(i: int) -> Rect2: return Rect2(MITAD + (i % 8) * paso, 132 + floori(i / 8.0) * paso, paso - 6, paso - 6),
		8.0, s)
	for i in range(casillas_de("baul", s), filas * 8):   # (las de la última fila que sobran, vacías)
		casilla_inv(Rect2(MITAD + (i % 8) * paso, 132 + floori(i / 8.0) * paso, paso - 6, paso - 6))
	var orden := boton(lienzo, "ordenar", Idioma.t("Ordenar"), ordenar)
	orden.position = Vector2(MITAD + 8 * 52 - 6 - 130, 78) - ORIGEN
	orden.size = Vector2(130, 30)
	encoger(orden)
	# las dos mitades, para arrastrar de una a otra (guardar y sacar), detrás de las casillas (sitio_en mira primero ellas)
	sitio("llevas", Rect2(52, 80, 394, 316))
	sitio("baul", Rect2(MITAD - 8, 80, 428, 316))
	# (los dos renglones de debajo, lo de la durabilidad y Ctrl + clic, ya no salen: 11 nov)
	# abajo, el marco de la ficha y los botones que no cambian con lo elegido (el principal va con la ficha)
	marco_ficha(lienzo, Rect2(64, 402, 832, 182))
	var todo := boton(lienzo, "guardar_todo", Idioma.t("Guardar todo"), guardar_todo)
	todo.disabled = not guardables().any(func(id): return Objetos.cabe_baul(s, id))   # (apagado si no cabe nada)
	todo.position = Vector2(600, 490) - ORIGEN
	todo.size = Vector2(280, 36)
	var salir := boton(lienzo, "cerrar", Idioma.t("Cerrar"), cerrar)
	salir.position = Vector2(600, 540) - ORIGEN
	salir.size = Vector2(280, 36)
	pintar_ficha()
	return lienzo.find_child(sel, false, false)


# El sitio de la casilla i de una fila de 8 de lo que lleva (a la izquierda del baúl) que empieza en "y"
func en_fila(i: int, y: float) -> Rect2:
	return Rect2(64 + i * 46, y, 42, 42)


# Los objetos del baúl, en el orden de Objetos.todos(): [[id, cuántos], ...], una por casilla (Objetos.monton como mucho:
# primero las llenas y al final la que sobra, así que de 50 balas salen 24, 24 y 2)
func objetos_baul(s: Dictionary) -> Array:
	var lista := []
	for id in Objetos.todos():
		var quedan: int = s.baul.get(id, 0)
		var tope := Objetos.monton(id)
		while quedan > 0:
			lista.append([id, mini(quedan, tope)])
			quedan -= tope
	return lista


# Las casillas del baúl, en orden: primero los objetos (objetos_baul) y luego las armas y los paquetes de arrojables
# ("baul_equipo" del guardado), cada uno en la suya: [{id, n (cuántos; las armas, 0), calidad, equipo (su sitio en
# "baul_equipo"; los objetos, -1)}, ...]
func cosas_baul(s: Dictionary) -> Array:
	var lista := []
	for o in objetos_baul(s):
		lista.append({"id": o[0], "n": o[1], "calidad": 0, "equipo": -1})
	for i in s.baul_equipo.size():
		var e: Dictionary = s.baul_equipo[i]
		lista.append({"id": e.id, "n": int(e.get("n", 0)), "calidad": int(e.calidad), "equipo": i})
	return lista


# ¿Se puede sacar esa casilla del baúl? Un objeto, si le cabe en la mochila o en la munición; un arma, siempre (la que
# sobre entra en el baúl en su lugar); unos arrojables, si le cabe al menos uno (en un montón suyo o en uno nuevo)
func se_saca(o: Dictionary) -> bool:
	if Garaje.prohibido(o.id):   # (el garaje del reto del día: lo que hoy no vale se queda en el baúl)
		return false
	var johnny: Node2D = partida.johnny
	if o.equipo < 0:
		return johnny.sitio(o.id) > 0 if o.id in Armas.MUNICION else Objetos.cabe(partida.mochila, o.id)
	if Armas.DATOS.has(o.id):
		return true
	return partida.lanzables.cabe(Lanzables.clave(o.id, o.calidad))


# ── Baúl: la ficha ──

# La ficha de lo elegido, abajo de lado a lado: a la izquierda, el dibujo grande; en medio, el nombre, qué es, cuántos y lo que hace o lo que pasa al guardarlo o sacarlo; a la derecha,
# su botón («Guardar todo» y «Cerrar» van fijos debajo). Y la línea de ayuda de abajo
func pintar_ficha_baul() -> void:
	if viva:
		lienzo.remove_child(viva)
		viva.queue_free()
	viva = Control.new()
	viva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(viva)
	asegurar_sel()
	var d := ficha_baul()
	poner_mover(d)
	var grande := Panel.new()
	grande.add_theme_stylebox_override("panel", estilo(Tema.AMARILLO, false, false))
	grande.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viva.add_child(grande)
	grande.position = Vector2(80, 418) - ORIGEN
	grande.size = Vector2(100, 100)
	dibujo(grande, d.icono, grande.size, 16.0)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	viva.add_child(caja)
	caja.position = Vector2(198, 410) - ORIGEN
	renglon(caja, d.nombre, Color("#e6dec8"), HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA).theme_type_variation = "Titulo"
	# (qué es y dónde está, debajo del nombre, ya no sale: 11 nov; sigue en d.que_es para las pruebas)
	if d.cuanto != "":
		renglon(caja, d.cuanto, Tema.TINTA, HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	if d.get("partidas", "") != "":   # (la durabilidad: Armas.texto_partidas; en rojo, la última)
		renglon(caja, d.partidas, Tema.ROJO if d.get("ultima", false) else Tema.AMARILLO, HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	espacio(caja, 6)
	var texto := nota_de(d.que)
	var nota := renglon(caja, texto[0], texto[1], HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	nota.name = "nota"   # (las pruebas la leen)
	aviso = ""
	if not d.boton.is_empty() and llevando == "":
		var b := boton(viva, d.boton[0], d.boton[1], d.boton[2])
		b.disabled = d.boton[3]
		for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(c, Tema.AMARILLO)
		b.position = Vector2(600, 410) - ORIGEN
		b.size = Vector2(280, 36)
	# «Mover» (16 nov) y «Destruir», en la misma fila: a la izquierda, «Mover», si lo elegido se puede cambiar de casilla
	var mover: Array = d.get("mover", [])
	if not mover.is_empty():
		var m := boton(viva, mover[0], mover[1], mover[2])
		m.position = Vector2(600, 450) - ORIGEN
		m.size = Vector2(138, 36)
		encoger(m)
	if que_se_destruye() != "" and llevando == "":   # lo de la mochila, la munición y el baúl (no las armas que lleva)
		var x := boton(viva, "destruir", Idioma.t("Destruir"), destruir, "BotonRojo")   # no-tr
		x.position = Vector2(600 + (142 if not mover.is_empty() else 0), 450) - ORIGEN
		x.size = Vector2(138 if not mover.is_empty() else 280, 36)
		encoger(x)
	# (sin la línea de las teclas de abajo: 11 nov)


# Lo que dice la ficha de lo elegido en el baúl: el dibujo, el nombre, qué es, cuántos, lo que hace o lo que pasa al
# guardarlo o sacarlo ("que") y su botón ([nombre, texto, al pulsar, apagado], o ninguno). Van al baúl lo de la
# mochila, la munición que también es un objeto (la gasolina, el bidón de ácido...), las armas (menos la fregona y la
# pistola Normales) y los montones de arrojables; del baúl se sacan los objetos de uno en uno, las armas enteras y los
# arrojables de montón en montón
func ficha_baul() -> Dictionary:
	var i := sel.substr(1).to_int()
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	var s := Guardado.cargar()
	var d := {"cuanto": "", "boton": []}
	match sel[0]:
		"p", "g":
			var id: String = johnny.huecos["cuerpo" if i == 0 else "fuego"] if sel[0] == "p" else partida.armas_guardadas[i]
			var w: Dictionary = johnny.arma_de(id)
			var calidad: int = johnny.calidad(id)
			if id == "":   # el hueco de fuego vacío: no hay nada que guardar
				d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id), "que_es": Idioma.t("A distancia"),
					"que": Idioma.t("La pistola se ha quedado en el baúl y no llevas otra arma a distancia. Sácala de allí para volver a disparar.")}, true)
				return d
			d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id),
				"que_es": "%s · %s · %s" % [Armas.tipo_nombre(w.tipo), Armas.calidad_nombre(calidad),
					Idioma.t("En la mano") if sel[0] == "p" else Idioma.t("De repuesto")],
				"que": que_hace(id) + " ", "partidas": Armas.texto_partidas(johnny.quedan_de(id)),
				"ultima": johnny.quedan_de(id) <= 0}, true)
			if Armas.al_baul(id, calidad) and not fregona_sola(sel, id):
				d.que += que_guardar_equipo(s, sel[0] == "p" and partida.repuesto(w.tipo) == "", w.tipo)
				d.boton = ["guardar", Idioma.t("Guardar en el baúl"), guardar, not Objetos.hueco_baul(s)]
			else:
				d.que += Idioma.t("La %s Normal solo va al baúl si llevas otra arma cuerpo a cuerpo de repuesto: sin ella no tendrías con qué pegar.") % 					Idioma.minusculas(Objetos.nombre(id))
			if w.tipo == "fuego":
				var carga_txt: String = Idioma.t("Depósito %d de %d s") % [ceili(carga(id)), roundi(w.deposito)] \
					if w.has("deposito") else Idioma.t("Cargador %d de %d") % [roundi(carga(id)), w.cargador]
				d.cuanto = Idioma.t("%s · reserva %d") % [carga_txt, johnny.cuanta(Armas.municion(id))]
		"l", "e":
			var k := lz.clave_en(sel)
			var n := lz.cuantos_en(sel)
			var caben := caben_lanzables(s, k)
			d.merge({"icono": icono_lanzable(k), "nombre": nombre_lanzable(k),
				"que_es": Idioma.t("Lanzable · %s · %s") % [Armas.calidad_nombre(Lanzables.calidad_de(k)),
					Idioma.t("A mano") if sel[0] == "l" else Idioma.t("De repuesto")],
				"cuanto": Idioma.t("Te quedan %d de %d") % [n, lz.maximo(k)],
				"partidas": Armas.texto_partidas(lz.quedan_de(k)), "ultima": lz.quedan_de(k) <= 0,
				"que": que_hace(k) + " "}, true)
			if caben <= 0:
				d.que += Idioma.t("El baúl está lleno: haz sitio sacando algo.")
			elif n > caben:
				d.que += Idioma.t("Solo caben %d más en el baúl (%d por casilla): el resto se queda contigo.") % [caben,
					Objetos.monton_arrojables(s, Lanzables.tipo_de(k), Lanzables.calidad_de(k))]
			else:
				d.que += Idioma.t("Se guarda el montón entero, con los que ya haya de estos.")
			d.boton = ["guardar", Idioma.t("Guardar en el baúl"), guardar, caben <= 0]
		"m":
			var c: Array = Objetos.casillas(partida.mochila)[i]
			var id: String = c[0]
			d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id),
				"que_es": Idioma.t("%s · En la mochila") % (Idioma.t("Material") if id in Objetos.PIEZAS
					else Idioma.t("Para curar") if id in Objetos.USABLES else Idioma.t("Objeto")),
				"cuanto": Idioma.t("Llevas %d") % c[1] if c[1] > 1 else ""}, true)
			d.que = que_pieza(id) + que_guardar(s, id, c[1], "casilla")
			d.boton = ["guardar", Idioma.t("Guardar en el baúl"), guardar, not Objetos.cabe_baul(s, id)]
		"u":
			var h: Array = johnny.huecos_municion()[i]
			var m: Dictionary = Armas.MUNICION[h[0]]
			d.merge({"icono": m.icono, "nombre": Armas.municion_nombre(h[0]), "que_es": Idioma.t("Munición · La llevas"),
				"cuanto": Idioma.t("%d en este hueco · llevas %d") % [h[1], johnny.cuanta(h[0])]}, true)
			# (la gasolina, el bidón de ácido y la batería llenan un arma; las balas y los cartuchos, se gastan al disparar)
			d.que = "%s %s" % [(Idioma.t("Llena %s.") if h[0] in Objetos.NOMBRES else Idioma.t("Es para %s.")) % Armas.municion_para(h[0]),
				que_guardar(s, h[0], h[1], "hueco")]
			d.boton = ["guardar", Idioma.t("Guardar en el baúl"), guardar, not Objetos.cabe_baul(s, h[0])]
		"b":
			var o: Dictionary = cosas_baul(s)[i]
			var id: String = o.id
			if o.equipo >= 0:
				d.merge(ficha_equipo(o), true)
				if Garaje.prohibido(id):
					d.que = Garaje.no_vale()   # (y su botón, apagado: se_saca)
				return d
			var municion: bool = id in Armas.MUNICION
			var cabe := se_saca(o)
			var tanda := mini(Objetos.tanda(id), o.n)   # cuántos salen de una vez (1, o de la munición, la casilla entera)
			d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id),
				"que_es": Idioma.t("%s · En el baúl") % (Idioma.t("Munición") if municion else Idioma.t("Material") if id in Objetos.PIEZAS
					else Idioma.t("Para curar") if id in Objetos.USABLES else Idioma.t("Objeto")),
				"cuanto": (Idioma.t("Hay %d en el baúl") % o.n) if s.baul.get(id, 0) <= o.n
					else Idioma.t("Hay %d en esta casilla · %d en el baúl") % [o.n, s.baul[id]],
				"boton": ["sacar", Idioma.t("Sacar uno") if tanda == 1 else Idioma.t("Sacar %d") % tanda, sacar, not cabe]}, true)
			d.que = (Idioma.t("Llena %s.") if id in Objetos.NOMBRES else Idioma.t("Es para %s.")) % Armas.municion_para(id) + " " \
				if municion else que_pieza(id)
			if cabe and tanda > 1:
				d.que += Idioma.t("Salen hasta %d de una vez a tu munición; fuera del baúl, se pierden si caes.") % tanda
			elif cabe:
				d.que += Idioma.t("Sale de uno en uno a tu munición; fuera del baúl, se pierde si caes.") if municion \
					else Idioma.t("Sale de uno en uno a tu mochila; fuera del baúl, se pierde si caes.")
			else:
				d.que += Idioma.t("No te cabe: tienes llenos los huecos de munición.") if municion \
					else Idioma.t("No te cabe: tienes la mochila llena.")
			if Garaje.prohibido(id):
				d.que = Garaje.no_vale()   # (y su botón, apagado: se_saca)
	return d


# La ficha de un arma o de unos arrojables del baúl (o, de cosas_baul): el arma sale con «Sacar»; los arrojables, de
# montón en montón («Sacar 5»)
func ficha_equipo(o: Dictionary) -> Dictionary:
	var arma := Armas.DATOS.has(o.id)
	var cabe := se_saca(o)
	var d := {"icono": Objetos.icono(o.id), "nombre": Armas.nombre(o.id, o.calidad), "cuanto": "",
		"boton": ["sacar", Idioma.t("Sacar"), sacar, not cabe]}
	# la durabilidad (Armas.nuevas): las partidas que le quedan (si ya ha salido en esta, ya ha bajado: 16 nov)
	var casilla: Dictionary = Guardado.cargar().baul_equipo[o.equipo]
	d.partidas = Armas.texto_partidas(Armas.quedan_de(casilla))
	d.ultima = Armas.quedan_de(casilla) <= 0   # (en rojo solo con 0: la última partida)
	if arma:
		var tipo: String = Armas.datos(o.id).tipo
		d.que_es = Idioma.t("%s · %s · En el baúl") % [Armas.tipo_nombre(tipo), Armas.calidad_nombre(o.calidad)]
		if o.id == partida.johnny.huecos[tipo] or o.id in partida.armas_guardadas:
			d.que = que_hace(o.id, o.calidad) + " " + Idioma.t("Ya llevas una: se cambian, esta ocupa su sitio y la tuya entra en " +
				"el baúl en su lugar.")
		else:
			d.que = que_hace(o.id, o.calidad) + " " + Idioma.t("Sale a la mano; la que llevas pasa al repuesto (si ya llevas dos, " +
				"la de la mano entra en el baúl en su lugar).")
	else:
		var k := Lanzables.clave(o.id, o.calidad)
		var tanda := mini(o.n, partida.lanzables.maximo(k))   # (un montón)
		d.que_es = Idioma.t("Lanzable · %s · En el baúl") % Armas.calidad_nombre(o.calidad)
		d.cuanto = Idioma.t("Hay %d en el baúl") % o.n
		d.boton = ["sacar", Idioma.t("Sacar %d") % tanda, sacar, not cabe]
		d.que = que_hace(k) + " "
		if cabe:
			d.que += Idioma.t("Salen de montón en montón, %d cada vez (los que te quepan).") % tanda
		else:
			d.que += Idioma.t("No te caben: tus montones de estos están llenos y no te queda hueco para otro.")
	return d


# Lo que pasa al guardar un arma en el baúl ("sin_otra": es la de la mano y no lleva otra de repuesto de su tipo)
func que_guardar_equipo(s: Dictionary, sin_otra: bool, tipo: String) -> String:
	if not Objetos.hueco_baul(s):
		return Idioma.t("El baúl está lleno: haz sitio sacando algo.")
	if sin_otra and tipo == "fuego":   # (ya no hay pistola de siempre: Armas.SIEMPRE)
		return Idioma.t("Te quedas sin arma a distancia hasta que la saques.")
	if sin_otra:
		return Idioma.t("En su lugar, a la mano, la %s de siempre.") % \
			Idioma.minusculas(Objetos.nombre(Armas.SIEMPRE[tipo]))
	return Idioma.t("Se guarda en el baúl, con las partidas que le quedan.")


# ¿Es la fregona Normal de la mano sin otra arma cuerpo a cuerpo de repuesto? Esa no va al baúl: Johnny se quedaría sin
# con qué pegar (M61; con repuesto, sí, y el repuesto pasa a la mano)
func fregona_sola(clave: String, id: String) -> bool:
	return clave[0] == "p" and id == Armas.SIEMPRE.cuerpo and partida.johnny.calidad(id) == 0 and partida.repuesto("cuerpo") == ""


# Lo que hace un arma (por su id) o un arrojable (por la clave de su paquete): lo de QUE_HACE y, si no es Normal, lo que
# le da su calidad (Armas.que_da; la del arma, la que lleva Johnny si no se dice otra)
func que_hace(id: String, calidad := -1) -> String:
	if Lanzables.DATOS.has(Lanzables.tipo_de(id)):
		calidad = Lanzables.calidad_de(id)
		id = Lanzables.tipo_de(id)
	elif calidad < 0 and Armas.DATOS.has(id):
		calidad = partida.johnny.calidad(id)
	var que: String = Idioma.t(QUE_HACE.get(id, ""))
	var da := Armas.que_da(id, calidad) if Armas.DATOS.has(id) or Lanzables.DATOS.has(id) else ""
	return que if da == "" else "%s %s" % [que, da]


# Lo que pasa al guardar en el baúl los "n" de esa casilla o hueco (o, con el baúl lleno, por qué no se puede)
func que_guardar(s: Dictionary, id: String, n: int, donde: String) -> String:   # donde: "casilla" o "hueco"
	var caben := Objetos.caben_baul(s, id)
	if caben <= 0:
		return Idioma.t("El baúl está lleno: haz sitio sacando algo.")
	if n > caben:
		return Idioma.t("Solo caben %d más en el baúl (%d por casilla): el resto se queda contigo.") % [caben, Objetos.monton(id)]
	if n > 1:
		if donde == "hueco":
			return Idioma.t("Se guardan los %d de este hueco, y en el baúl quedan a salvo aunque caigas.") % n
		return Idioma.t("Se guardan los %d de esta casilla, y en el baúl quedan a salvo aunque caigas.") % n
	return Idioma.t("En el baúl queda a salvo aunque caigas.")


# ── Baúl: guardar y sacar ──

# Ctrl + clic en el baúl: lo elegido pasa al otro lado sin pulsar el botón. De lo que lleva, la casilla entera al baúl
# (como «Guardar en el baúl»); del baúl, la casilla entera a lo que lleva: un arma o un montón de arrojables (como
# «Sacar») y, de un objeto, todos los de esa casilla que quepan (no de uno en uno). Si no cabe nada, suena el «no»
func pasar_al_momento() -> void:
	if not sel.begins_with("b"):
		guardar()
		return
	var i := sel.substr(1).to_int()
	var cosas := cosas_baul(Guardado.cargar())
	if i >= cosas.size():
		return
	var o: Dictionary = cosas[i]
	if no_vale(o.id):
		return
	if o.equipo >= 0:
		sacar_equipo(o)
		return
	var johnny: Node2D = partida.johnny
	var municion: bool = o.id in Armas.MUNICION
	var cabe := func() -> bool: return johnny.sitio(o.id) > 0 if municion else Objetos.cabe(partida.mochila, o.id)
	if not cabe.call():
		Sonido.tocar("no")
		return
	var hay := func() -> int: return int(Guardado.cargar().baul.get(o.id, 0))
	var hasta: int = hay.call() - o.n   # (lo que queda en el baúl cuando esta casilla se ha vaciado)
	while hay.call() > hasta and cabe.call():
		sel = "b%d" % i
		sacar_objeto(o.id, hay.call() - hasta)

# Saca del baúl lo elegido: un objeto, uno (sacar_objeto); un arma, entera, o un montón de arrojables (sacar_equipo)
func sacar() -> void:
	var i := sel.substr(1).to_int()
	var cosas := cosas_baul(Guardado.cargar())
	if not sel.begins_with("b") or i >= cosas.size():
		return
	if cosas[i].equipo < 0:
		sacar_objeto(cosas[i].id, cosas[i].n)
	else:
		sacar_equipo(cosas[i])


# Saca del baúl un arma o un paquete de arrojables. El arma va a la mano como al comprarla (partida.llevar_arma): la
# que llevaba pasa al repuesto o, si ya lleva dos, entra en el baúl en su lugar. Si ya llevaba esa misma (en la mano o
# de repuesto), se cambian: la del baúl ocupa su sitio y la suya entra en el baúl. Nunca se queda en el suelo, ni la
# fregona o la pistola Normales (que no se pueden guardar a mano). De los arrojables sale un montón, los que quepan
# (lanzables.meter); los demás se quedan en el baúl
func sacar_equipo(o: Dictionary) -> void:
	if no_vale(o.id):
		return
	if not se_saca(o):
		Sonido.tocar("no")
		return
	var fuera := {}
	var quedan := 0
	var de_repuesto: bool = o.id in partida.armas_guardadas   # (ya la llevaba de repuesto: se cambia ahí)
	# la durabilidad (Armas.nuevas): al salir del baúl gasta una partida, si no había salido ya en esta
	var casilla: Dictionary = Guardado.cargar().baul_equipo[o.equipo].duplicate()
	var partidas := Armas.estrenar(casilla)
	var ultima := partidas == 0   # (para el aviso: es su última partida)
	if Armas.DATOS.has(o.id):
		fuera = partida.llevar_arma(o.id, o.calidad, true, false, partidas)
	else:
		var k := Lanzables.clave(o.id, o.calidad)
		quedan = o.n - partida.lanzables.meter_de_baul(k, mini(o.n, partida.lanzables.maximo(k)), partidas)
	Guardado.cambiar(func(g):
		if quedan > 0:
			g.baul_equipo[o.equipo].n = quedan
			g.baul_equipo[o.equipo].quedan = casilla.quedan   # (los que se quedan también han salido: el montón entero)
			g.baul_equipo[o.equipo].usada = true
		elif not fuera.is_empty():
			fuera.usada = true   # (la que entra en su lugar ha salido en esta partida)
			g.baul_equipo[o.equipo] = fuera   # (en la misma casilla)
		else:
			g.baul_equipo.remove_at(o.equipo))
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	if Armas.DATOS.has(o.id):
		var mano := "p0" if Armas.datos(o.id).tipo == "cuerpo" else "p1"
		if de_repuesto:
			mano = "g%d" % partida.armas_guardadas.find(o.id)
		salta = [mano] if fuera.is_empty() else [mano, sel]
		salta_johnny = true
		if not fuera.is_empty():
			aviso = (Idioma.t("%s al repuesto; %s entra en el baúl en su lugar.") if de_repuesto
				else Idioma.t("%s a la mano; %s entra en el baúl en su lugar.")) % [Armas.nombre(o.id, o.calidad),
				Armas.nombre(fuera.id, fuera.calidad)]
	else:
		salta = [partida.lanzables.sitio_de(Lanzables.clave(o.id, o.calidad))]
	if ultima:   # (la durabilidad: Armas.nuevas)
		aviso = (aviso + " " if aviso != "" else "") + Idioma.t("%s: es su última partida; al acabarla, se destruye.") % 			Armas.nombre(o.id, o.calidad)
	foco = sel if existe(sel) else ""
	pintar()


# Saca del baúl uno de ese objeto: a la mochila o, si es munición (la gasolina, el bidón de ácido...), a sus huecos (y
# si el arma que la gasta está vacía, se carga). Si no cabe, no sale. La marca se queda en «Sacar uno» mientras queden:
# con el mando, A, A, A... y salen de uno en uno
func sacar_objeto(id: String, de_la_casilla := 0) -> void:   # de_la_casilla: los que hay en la elegida (0: no importa)
	if no_vale(id):
		return
	var johnny: Node2D = partida.johnny
	var municion: bool = id in Armas.MUNICION
	if not (johnny.sitio(id) > 0 if municion else Objetos.cabe(partida.mochila, id)):
		Sonido.tocar("no")
		return
	# cuántos salen: uno, o de la munición, su casilla entera (lo que haya en ella y lo que quepa)
	var cuantos := 1
	if municion:
		cuantos = mini(mini(Objetos.tanda(id), int(Guardado.cargar().baul.get(id, 0))), johnny.sitio(id))
		if de_la_casilla > 0:
			cuantos = mini(cuantos, de_la_casilla)
	Guardado.cambiar(func(g):
		g.baul[id] -= cuantos
		if g.baul[id] <= 0:
			g.baul.erase(id))
	if id in Objetos.NOMBRES or not municion:
		for _v in cuantos:
			partida.mochila.append(id)   # (la gasolina, el bidón de ácido y la batería, también: Johnny los cuenta ahí)
	else:
		johnny.meter_municion(id, cuantos)
	if municion:
		johnny.coger_municion(id)
		johnny.avisar_arma()
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	var i := sel.substr(1).to_int()
	var cosas := cosas_baul(Guardado.cargar())
	foco = "sacar" if i < cosas.size() and cosas[i].id == id else sel
	salta = [donde_esta(id)]
	pintar()


# La casilla de lo que lleva donde está ese objeto: en la munición (el último hueco de los suyos) o en la mochila
func donde_esta(id: String) -> String:
	if id in Armas.MUNICION:
		var tipos: Array = partida.johnny.huecos_municion().map(func(h): return h[0])
		return "u%d" % tipos.rfind(id)
	return "m%d" % Objetos.casillas(partida.mochila).map(func(c): return c[0]).find(id)


# Guarda en el baúl lo de la casilla elegida: todos los de esa casilla de la mochila o de ese hueco de munición (las
# balas, los cartuchos, la gasolina...). La marca se queda en la misma casilla, que ahora es la siguiente: con el mando o las
# flechas, A dos veces y se guarda otra
func guardar() -> void:
	var i := sel.substr(1).to_int()
	var id := ""
	var n := 0
	if sel.begins_with("m"):
		var llenas := Objetos.casillas(partida.mochila)
		if i < llenas.size():
			id = llenas[i][0]
			n = llenas[i][1]
	elif sel.begins_with("u"):
		var huecos: Array = partida.johnny.huecos_municion()
		if i < huecos.size():
			id = huecos[i][0]
			n = huecos[i][1]
	elif sel[0] in ["p", "g", "l", "e"]:
		guardar_equipo()
		return
	var llevaba := lleva(id)
	if not meter_en_baul(id, n):
		Sonido.tocar("no")
		return
	var sobran := n - (llevaba - lleva(id))
	if sobran > 0:   # (no ha cabido todo: la casilla del baúl se llena o no queda sitio)
		aviso = Idioma.t("El baúl no admite más: contigo se quedan %d de %s.") % [sobran, Idioma.minusculas(Objetos.nombre(id))]
	partida.johnny.avisar_arma()
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	salta = ["b%d" % objetos_baul(Guardado.cargar()).map(func(o): return o[0]).find(id)]   # (los objetos van primero)
	foco = sel
	pintar()


# Guarda en el baúl el arma o el montón de arrojables elegido. El arma, en una casilla nueva (al final); si es la de la
# mano, la de repuesto de su tipo pasa a la mano o, si no lleva, la de siempre (la fregona o la pistola, Normales:
# Armas.SIEMPRE). Los arrojables, con los de su clase que ya haya (Objetos.arrojables_al_baul; los que no caben, se quedan)
func guardar_equipo() -> void:
	var i := sel.substr(1).to_int()
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	var s := Guardado.cargar()
	var e := {}
	match sel[0]:
		"p", "g":
			var tipo: String = ("cuerpo" if i == 0 else "fuego") if sel[0] == "p" else Armas.datos(partida.armas_guardadas[i]).tipo
			var id: String = johnny.huecos[tipo] if sel[0] == "p" else partida.armas_guardadas[i]
			if Armas.al_baul(id, johnny.calidad(id)) and not fregona_sola(sel, id) and Objetos.hueco_baul(s):
				# (ha salido en esta partida: "usada", con las partidas que le quedan; la durabilidad, Armas.nuevas)
				e = {"id": id, "calidad": johnny.calidad(id), "quedan": johnny.quedan_de(id), "usada": true}
				johnny.calidades.erase(id)
				johnny.quedan.erase(id)
				johnny.cargadores.erase(id)
				if sel[0] == "g":
					partida.armas_guardadas.remove_at(i)
				else:
					var mano: String = johnny.mano
					var otra: String = partida.repuesto(tipo)
					if otra != "":
						partida.armas_guardadas.erase(otra)
					elif tipo == "fuego":
						otra = ""   # sin otra a distancia: Johnny se queda sin arma a distancia (vaciar_fuego)
					else:
						otra = Armas.SIEMPRE[tipo]   # (la fregona)
					if otra == "":
						johnny.vaciar_fuego()
					else:
						johnny.coger(otra)
					if johnny.mano != mano:
						johnny.sostener(mano)   # (la otra mano sigue con la suya)
					salta_johnny = true
		"l", "e":
			var k := lz.clave_en(sel)
			var caben := caben_lanzables(s, k)
			if caben > 0:
				var n := lz.cuantos_en(sel)
				e = {"id": Lanzables.tipo_de(k), "calidad": Lanzables.calidad_de(k), "quedan": lz.quedan_de(k),
					"n": lz.quitar(sel, caben)}
				if n > caben:
					aviso = Idioma.t("El baúl no admite más: contigo se quedan %d de %s.") % [n - caben, lz.nombre(k)]
	if e.is_empty():
		Sonido.tocar("no")
		return
	var antes: int = cosas_baul(s).size()
	Guardado.cambiar(func(g):
		if e.has("n"):   # (los arrojables, con los de su clase que ya haya)
			Objetos.arrojables_al_baul(g, e.id, e.calidad, e.n, e.quedan, true)
		else:
			g.baul_equipo.append(e))
	johnny.avisar_arma()
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	salta = ["b%d" % antes]
	if e.has("n"):
		var casillas := cosas_baul(Guardado.cargar())
		for j in casillas.size():
			if casillas[j].equipo >= 0 and casillas[j].id == e.id and casillas[j].calidad == e.calidad and casillas[j].n > 0:
				salta = ["b%d" % j]   # (la última de su clase: donde han entrado)
	if sel[0] == "p":
		salta.append(sel)
	foco = sel if existe(sel) else ""
	pintar()


# Los objetos distintos de la mochila (también la munición que es un objeto: la gasolina, el bidón de ácido...)
func guardables() -> Array:
	var lista: Array = Objetos.casillas(partida.mochila, true).map(func(c): return c[0])
	for tipo in Armas.MUNICION:   # y las balas y los cartuchos, que van en los huecos de munición y no en la mochila
		if not tipo in lista and partida.johnny.cuanta(tipo) > 0:
			lista.append(tipo)
	return lista


# Guarda en el baúl todo lo de la mochila que se pueda; lo que no cabe (con el baúl lleno) se queda, y se dice
func guardar_todo() -> void:
	var guardados := 0
	var no_caben := []
	for id in guardables():
		if meter_en_baul(id):
			guardados += 1
			if lleva(id) > 0:   # (algo ha entrado, pero no todo: su casilla llena)
				no_caben.append(Idioma.minusculas(Objetos.nombre(id)))
		else:
			no_caben.append(Idioma.minusculas(Objetos.nombre(id)))
	Sonido.tocar("cambiar" if guardados > 0 else "no")
	if not no_caben.is_empty():
		aviso = Idioma.t("El baúl está lleno: contigo se quedan %s.") % (Idioma.t("%s y %s") % [", ".join(no_caben.slice(0, -1)),
			no_caben[-1]] if no_caben.size() > 1 else no_caben[0])
	partida.johnny.avisar_arma()
	sel = ""
	foco = ""
	pintar()


# Cuántos de ese objeto lleva Johnny encima: en la mochila o, la munición, en sus huecos
func lleva(id: String) -> int:
	if id in Armas.MUNICION and not id in Objetos.NOMBRES:
		return partida.johnny.cuanta(id)
	return partida.mochila.count(id)


# Mete en el baúl "cuantos" de ese objeto de la mochila (0: todos), si cabe. Las balas y los cartuchos, de la munición
# de Johnny. Dice si lo ha hecho
func meter_en_baul(id: String, cuantos := 0) -> bool:
	if id == "":
		return false
	var caben := Objetos.caben_baul(Guardado.cargar(), id)   # (las casillas del baúl son de Objetos.monton como mucho: lo que no cabe se queda)
	if caben <= 0:
		return false
	var n := 0
	if id in Armas.MUNICION and not id in Objetos.NOMBRES:
		var johnny: Node2D = partida.johnny
		n = mini(johnny.cuanta(id) if cuantos <= 0 else mini(cuantos, johnny.cuanta(id)), caben)
		if n <= 0:
			return false
		johnny.municion[id] = johnny.cuanta(id) - n
		if johnny.municion[id] <= 0:
			johnny.municion.erase(id)
	else:
		var mochila: Array = partida.mochila
		n = mini(mochila.count(id) if cuantos <= 0 else mini(cuantos, mochila.count(id)), caben)
		for k in n:
			mochila.remove_at(mochila.rfind(id))
	Guardado.cambiar(func(s): s.baul[id] = s.baul.get(id, 0) + n)
	return true


# ── Destruir ──

# El texto de la ficha y su color: lo suyo ("que") o un aviso que se dice una vez: [texto, color]
func nota_de(que: String) -> Array:
	if aviso != "":
		return [aviso, Tema.AMARILLO]
	return [que, Tema.TINTA]


# Qué se llevaría «Destruir» con lo elegido, dicho como va en la ficha («Pieza especial ×3», «Fregona (Épica)»), o ""
# si no se puede destruir: se puede lo de la mochila y la munición (el hueco), y en el baúl, también sus objetos, armas y
# paquetes de arrojables; no las armas ni los arrojables que lleva Johnny
func que_se_destruye() -> String:
	if sel == "" or not existe(sel):
		return ""
	var i := sel.substr(1).to_int()
	var con_numero := func(id: String, n: int) -> String:
		return "%s ×%d" % [Objetos.nombre(id), n] if n > 1 else Objetos.nombre(id)
	match sel[0]:
		"m":
			var c: Array = Objetos.casillas(partida.mochila)[i]
			return con_numero.call(c[0], c[1])
		"u":
			var h: Array = partida.johnny.huecos_municion()[i]
			return con_numero.call(h[0], h[1])
		"b":
			if abierto == "baul":
				var o: Dictionary = cosas_baul(Guardado.cargar())[i]
				if o.equipo < 0:
					return con_numero.call(o.id, o.n)
				return "%s ×%d" % [Armas.nombre(o.id, o.calidad), o.n] if o.n > 1 else Armas.nombre(o.id, o.calidad)
	return ""


# El botón «Destruir»: sale en el centro «¿Estás seguro?» (confirmar.gd) con lo que se perdería; con Sí, destruir_ya
func destruir() -> void:
	var que := que_se_destruye()
	if que == "":
		Sonido.tocar("no")
		return
	var cual := sel
	Confirmar.preguntar(self, Idioma.t("¿Destruir %s? Se pierde para siempre: no se puede deshacer.") % que).respondido.connect(func(si: bool):
		if si and abierto != "" and sel == cual:
			destruir_ya()
		elif abierto != "":
			foco = "destruir"
			pintar())


# Quita para siempre la casilla elegida entera (la de la mochila, el hueco de munición o la del baúl)
func destruir_ya() -> void:
	var que := que_se_destruye()
	if que == "":
		return
	var i := sel.substr(1).to_int()
	var johnny: Node2D = partida.johnny
	var mochila: Array = partida.mochila
	match sel[0]:
		"m":
			var id: String = Objetos.casillas(mochila)[i][0]
			while mochila.has(id):
				mochila.erase(id)
		"u":
			var h: Array = johnny.huecos_municion()[i]
			if h[0] in Objetos.NOMBRES:   # (la gasolina, el bidón de ácido y la batería van en la mochila)
				for k in h[1]:
					mochila.erase(h[0])
			else:
				johnny.municion[h[0]] = johnny.cuanta(h[0]) - h[1]
				if johnny.municion[h[0]] <= 0:
					johnny.municion.erase(h[0])
			johnny.avisar_arma()
		"b":
			var o: Dictionary = cosas_baul(Guardado.cargar())[i]
			Guardado.cambiar(func(g):
				if o.equipo < 0:
					g.baul[o.id] -= o.n   # (solo la casilla elegida: de 50 balas, 24; o todo lo que haya si cabe en ella)
					if g.baul[o.id] <= 0:
						g.baul.erase(o.id)
				else:
					g.baul_equipo.remove_at(o.equipo))
	Sonido.tocar("crujido")
	aviso = Idioma.t("Destruido: %s.") % que
	foco = sel   # (la marca vuelve a la casilla, no al botón: nada se destruye pulsando dos veces sin mirar)
	pintar()


# ── Banco de trabajo ──
# Al arrimarse al banco del taller (parte 5 de la tienda y las piezas): sube de calidad las armas y los paquetes de
# arrojables, de uno en uno y nivel a nivel (Normal → Poco común → Rara → Épica), gastando piezas de su familia
# (Armas.pieza; lo que cuesta cada nivel, Armas.coste). Valen las piezas de la mochila y las del baúl
# (se gastan primero las de la mochila, que son las que se pierden si cae). Se parece al baúl: arriba, las piezas que
# tiene; a la izquierda, sus armas y sus arrojables (las casillas de siempre: "p", "g", "l" y "e"); a la derecha, las
# armas y los paquetes del baúl ("q": su sitio en "baul_equipo"); abajo, la ficha de lo elegido, con lo que gana, lo que
# cuesta y «Mejorar». Aquí no se arrastra nada

# Cómo se titula cada familia de piezas, arriba (las frases con cuántas piezas, en cuantas_piezas)
# [traducir]
const PIEZAS_TITULO := {"pieza_cuerpo": "Cuerpo a cuerpo", "pieza_distancia": "A distancia",
	"pieza_especial": "Especiales", "pieza_arrojable": "Lanzables"}
# [/traducir]


func pintar_banco(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	asegurar_sel()
	preparar_lienzo(columna)
	# el fondo: el banco de frente, con su tablero perforado y el cajón (de GPT, tools/muebles_gpt.py; 12 nov, antes el
	# recuadro gris). Lo de encima del tablero va en oscuro (TINTA_BANCO); la ficha, en su recuadro, como siempre
	var fondo_banco := TextureRect.new()
	fondo_banco.texture = FONDO_BANCO
	fondo_banco.size = lienzo.custom_minimum_size
	fondo_banco.stretch_mode = TextureRect.STRETCH_SCALE
	fondo_banco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_banco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fondo_banco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(fondo_banco)
	# (el título, claro y con su contorno, como siempre: va sobre la barra de metal de arriba)
	rotulo(lienzo, Idioma.t("Banco de trabajo"), 480, 26, Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER).theme_type_variation = "Titulo"
	# arriba, las piezas que tiene (las pinta la ficha, que enciende las que gasta lo elegido)
	rotulo(lienzo, Idioma.t("Materiales"), 64, 66, TINTA_BANCO)   # (antes «Tus piezas», 11 nov)
	raya(Rect2(64, 146, 832, 2), RAYA_BANCO)
	# a la izquierda, lo que lleva: sus armas (de cada tipo, la de la mano y la de repuesto) y sus arrojables
	rotulo(lienzo, Idioma.t("Lo que llevas"), 64, 156, TINTA_BANCO)
	rotulo(lienzo, Idioma.t("Armas"), 64, 180, ACENTO_BANCO)
	rotulo(lienzo, Idioma.t("Lanzables"), en_fila(5, 0).position.x, 180, ACENTO_BANCO)
	for i in 2:
		var tipo: String = ["cuerpo", "fuego"][i]
		var id: String = johnny.huecos[tipo]
		casilla_inv(en_fila(i * 2, 202), "p%d" % i, Objetos.icono(id), carga_corta(id), borde(id), 8.0)
		var otra: String = partida.repuesto(tipo)
		if otra != "":
			casilla_inv(en_fila(i * 2 + 1, 202), "g%d" % partida.armas_guardadas.find(otra), Objetos.icono(otra),
				carga_corta(otra), borde(otra), 8.0)
		else:
			casilla_inv(en_fila(i * 2 + 1, 202))
	for i in Lanzables.MANO:
		arrojable(en_fila(5 + i, 202), "l%d" % i, lz.mano[i] if i < lz.mano.size() else "", 8.0)
	raya(Rect2(452, 156, 2, 138), RAYA_BANCO)
	# a la derecha, las armas y los paquetes del baúl (los objetos no se mejoran), con el color de su calidad. Caben en
	# el alto de 2 filas (M105, 15 nov: la ficha va justo debajo, dentro del tablero); si hay más, las casillas se hacen
	# más pequeñas
	var equipo: Array = s.baul_equipo
	var filas := maxi(2, ceili(equipo.size() / 8.0))
	var paso := mini(46, floori(96.0 / filas))
	rotulo(lienzo, Idioma.t("En el baúl"), MITAD, 156, TINTA_BANCO)
	rotulo(lienzo, Idioma.t("Armas y lanzables"), MITAD, 180, ACENTO_BANCO)
	for i in filas * 8:
		var r := Rect2(MITAD + (i % 8) * paso, 202 + floori(i / 8.0) * paso, paso - 4, paso - 4)
		if i < equipo.size():
			var e: Dictionary = equipo[i]
			casilla_inv(r, "q%d" % i, Objetos.icono(e.id), str(int(e.n)) if e.has("n") else "", Armas.color(int(e.calidad)),
				8.0)
		else:
			casilla_inv(r)
	# (la frase de debajo, «No tienes armas ni arrojables guardados», ya no sale: 11 nov)
	# debajo, el marco de la ficha y «Cerrar» (el botón de mejorar va con la ficha). Dentro del tablero claro (M105, 15
	# nov: antes, más abajo, 402-584, encima de la balda y del cajón)
	marco_ficha(lienzo, Rect2(64, 302, 832, 152))
	var salir := boton(lienzo, "cerrar", Idioma.t("Cerrar"), cerrar)
	salir.position = Vector2(600, 404) - ORIGEN
	salir.size = Vector2(280, 38)
	pintar_ficha()
	return lienzo.find_child(sel, false, false)


# La ficha de lo elegido en el banco, abajo, como la del baúl: el dibujo grande; el nombre, qué es y dónde está; lo que
# gana con el nivel de arriba y lo que cuesta (o por qué no se puede); y a la derecha, «Mejorar a...». Arriba, las
# piezas que tiene, con las que gasta lo elegido encendidas. Y la línea de ayuda de abajo
func pintar_ficha_banco() -> void:
	if viva:
		lienzo.remove_child(viva)
		viva.queue_free()
	viva = Control.new()
	viva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(viva)
	asegurar_sel()
	var s := Guardado.cargar()
	var o := en_banco(s)
	var pieza := Armas.pieza(o.id)
	# cada familia, centrada en su cuarto de la fila (antes, pegadas a la izquierda: sobraba hueco a la derecha, 11 nov)
	for i in Objetos.PIEZAS.size():
		var p: String = Objetos.PIEZAS.keys()[i]
		var hay := Panel.new()
		hay.name = p
		hay.add_theme_stylebox_override("panel", estilo(Tema.AMARILLO if p == pieza else Color("#3d3647"), false, false))
		hay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		viva.add_child(hay)
		hay.size = Vector2(42, 42)
		dibujo(hay, Objetos.icono(p), hay.size, 8.0)
		var titulo := rotulo(viva, Idioma.t(PIEZAS_TITULO[p]), 0, 92, ACENTO_BANCO if p == pieza else TINTA_BANCO)
		var cuantas := rotulo(viva, Idioma.t("Tienes %d") % piezas(p, s), 0, 112, GRIS_BANCO)
		var ancho := 52.0 + maxf(titulo.get_minimum_size().x, cuantas.get_minimum_size().x)
		var x := roundf(64.0 + i * 208 + (208 - ancho) / 2.0)
		hay.position = Vector2(x, 92) - ORIGEN
		titulo.position.x = x + 52 - ORIGEN.x
		cuantas.position.x = x + 52 - ORIGEN.x
	var grande := Panel.new()
	grande.add_theme_stylebox_override("panel", estilo(Tema.AMARILLO, false, false))
	grande.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viva.add_child(grande)
	grande.position = Vector2(80, 328) - ORIGEN   # (M105: la ficha, más arriba)
	grande.size = Vector2(100, 100)
	dibujo(grande, Objetos.icono(o.id), grande.size, 16.0)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	viva.add_child(caja)
	caja.position = Vector2(198, 310) - ORIGEN
	renglon(caja, Armas.nombre(o.id), Color("#e6dec8"), HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA).theme_type_variation = "Titulo"
	# (la línea de debajo del nombre, «Cuerpo a cuerpo · Normal · En la mano», ya no sale: 11 nov)
	# los lanzables se mejoran de uno en uno, y el mejorado va al baúl con los de su calidad nueva (M117, 16 nov)
	if o.has("k"):
		renglon(caja, Idioma.t("Te quedan %d de %d: se mejora uno y va al baúl") % [o.n, partida.lanzables.maximo(o.k)], Tema.TINTA,
			HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	elif o.n > 0:
		var hay_baul: String = Idioma.t("Hay %d en el baúl: se mejora uno") % o.n if o.n > 1 else Idioma.t("Hay %d en el baúl") % o.n
		renglon(caja, hay_baul, Tema.TINTA, HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	espacio(caja, 6)
	# lo que gana con el nivel de arriba (la Épica, lo que ya tiene) y lo que cuesta, o por qué no se puede
	var epica: bool = o.calidad >= Armas.CALIDADES.size() - 1
	var que := Armas.que_da(o.id, o.calidad)
	var arriba := ""
	if not epica:
		que = Idioma.t("Sube a %s") % Armas.que_da(o.id, o.calidad + 1)
		arriba = Armas.calidad_nombre(o.calidad + 1)
	var nota := renglon(caja, que if aviso == "" else aviso, Tema.TINTA if aviso == "" else Tema.AMARILLO,
		HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	nota.name = "nota"   # (las pruebas la leen)
	aviso = ""
	var no := no_mejora(o, s)
	var coste := no
	if no == "":   # (solo lo que cuesta: ni lo que tienes ni lo que falta, 11 nov)
		coste = Idioma.t("Cuesta %s.") % cuantas_piezas(Armas.coste(o.id, o.calidad + 1), pieza)
	renglon(caja, coste, Tema.AMARILLO if no != "" else Tema.TINTA, HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA).name = "coste"
	var b := boton(viva, "mejorar", Idioma.t("Ya es Épica") if epica else Idioma.t("Mejorar a %s") % arriba, mejorar)
	b.disabled = no != ""
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Tema.AMARILLO)
	b.position = Vector2(600, 318) - ORIGEN
	b.size = Vector2(280, 40)
	# (sin la línea de las teclas de abajo: 11 nov)


# Lo que hay en la casilla elegida del banco: {id (el del arma o el tipo del arrojable), calidad, donde («En la mano»,
# «De repuesto», «A mano», «En el baúl»), n (cuántos hay en el montón; las armas, 0) y, si es un montón que lleva,
# k (su clave) y sitio ("l1", "e3"), o, si está en el baúl, equipo (su sitio en "baul_equipo"). De los arrojables se
# mejora uno (M117)}
func en_banco(s: Dictionary) -> Dictionary:
	var i := sel.substr(1).to_int()
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	match sel[0]:
		"p", "g":
			var id: String = johnny.huecos["cuerpo" if i == 0 else "fuego"] if sel[0] == "p" else partida.armas_guardadas[i]
			return {"id": id, "calidad": johnny.calidad(id), "n": 0, "donde": Idioma.t("En la mano") if sel[0] == "p" else Idioma.t("De repuesto")}
		"l", "e":
			var k := lz.clave_en(sel)
			return {"id": Lanzables.tipo_de(k), "calidad": Lanzables.calidad_de(k), "k": k, "sitio": sel,
				"n": lz.cuantos_en(sel), "donde": Idioma.t("A mano") if sel[0] == "l" else Idioma.t("De repuesto")}
	var e: Dictionary = s.baul_equipo[i]
	return {"id": e.id, "calidad": int(e.calidad), "equipo": i, "n": int(e.get("n", 0)), "donde": Idioma.t("En el baúl")}


# Por qué no se puede mejorar eso ("" si se puede): ya es Épica, le faltan piezas o (un lanzable) no hay sitio en el baúl
# para el mejorado, que va allí con los de su calidad nueva (M117; si es el último de su casilla del baúl, deja su sitio)
func no_mejora(o: Dictionary, s: Dictionary) -> String:
	if o.id == "":
		return Idioma.t("No llevas arma a distancia que mejorar.")
	if o.calidad >= Armas.CALIDADES.size() - 1:
		return Idioma.t("Ya es Épica: no se puede mejorar más.")
	var pieza := Armas.pieza(o.id)
	var cuesta: int = Armas.coste(o.id, o.calidad + 1)
	var hay := piezas(pieza, s)
	if hay < cuesta:
		return Idioma.t("Cuesta %s.") % cuantas_piezas(cuesta, pieza)   # (solo lo que cuesta, 11 nov)
	var lleno := Idioma.t("El baúl está lleno: haz sitio para poder mejorarlo.")
	if o.has("k") and Objetos.caben_arrojables(s, o.id, o.calidad + 1, partida.lanzables.quedan_de(o.k) + 1, true) < 1:
		return lleno
	if o.has("equipo") and o.n > 1 and Objetos.caben_arrojables(s, o.id, o.calidad + 1,
			Armas.quedan_de(s.baul_equipo[o.equipo]) + 1, s.baul_equipo[o.equipo].get("usada", false)) < 1:
		return lleno
	return ""


# Cuántas piezas de esa tiene: las de la mochila y las del baúl
func piezas(pieza: String, s: Dictionary) -> int:
	return partida.mochila.count(pieza) + int(s.baul.get(pieza, 0))


# «1 pieza especial», «6 piezas especiales»: una frase entera por familia, con su singular y su plural
func cuantas_piezas(n: int, pieza: String) -> String:
	match pieza:
		"pieza_cuerpo": return Idioma.n("%d material cuerpo a cuerpo", "%d materiales cuerpo a cuerpo", n) % n
		"pieza_distancia": return Idioma.n("%d material a distancia", "%d materiales a distancia", n) % n
		"pieza_especial": return Idioma.n("%d material especial", "%d materiales especiales", n) % n
	return Idioma.n("%d material lanzable", "%d materiales lanzables", n) % n


# Cuántas balas, cartuchos, gasolinas... («1 gasolina», «2 gasolinas»): una frase entera por tipo, con su singular y su
# plural (cada idioma, los suyos: el ruso tiene tres)
func cuenta_municion(tipo: String, n: int) -> String:
	match tipo:
		"balas": return Idioma.n("%d bala", "%d balas", n) % n
		"cartuchos": return Idioma.n("%d cartucho", "%d cartuchos", n) % n
		"cinta": return Idioma.n("%d bala de cinta", "%d balas de cinta", n) % n
		"granadas_40": return Idioma.n("%d granada de 40 mm", "%d granadas de 40 mm", n) % n
		"gasolina": return Idioma.n("%d gasolina", "%d gasolinas", n) % n
		"bidon_acido": return Idioma.n("%d bidón de ácido", "%d bidones de ácido", n) % n
		"nitrogeno": return Idioma.n("%d bombona de nitrógeno", "%d bombonas de nitrógeno", n) % n
	return Idioma.n("%d batería", "%d baterías", n) % n


# Mejora lo elegido: gasta sus piezas (primero las de la mochila) y sube su calidad un nivel. Un arma que lleva cambia
# al momento (johnny.calidades); un arma del baúl, en su casilla. Los lanzables, de uno en uno (M117, 16 nov): el mejorado
# sale de su montón (el que lleva o el del baúl) y va al baúl, con los de su calidad nueva (Objetos.arrojables_al_baul). Suena, da un saltito y, la primera vez, el logro Manitas
func mejorar() -> void:
	var s := Guardado.cargar()
	var o := en_banco(s)
	if no_mejora(o, s) != "":
		Sonido.tocar("no")
		return
	var calidad: int = o.calidad + 1
	var pieza := Armas.pieza(o.id)
	var n: int = Armas.coste(o.id, calidad)
	while n > 0 and pieza in partida.mochila:
		partida.mochila.erase(pieza)
		n -= 1
	Guardado.cambiar(func(g):
		if n > 0:   # (las que faltan, del baúl)
			g.baul[pieza] -= n
			if g.baul[pieza] <= 0:
				g.baul.erase(pieza)
		# la durabilidad (Armas.nuevas): con la subida, una partida más que las que le quedaban
		if o.has("k"):   # uno del montón que lleva, al baúl (ha salido en esta partida: "usada")
			Objetos.arrojables_al_baul(g, o.id, calidad, 1, partida.lanzables.quedan_de(o.k) + 1, true)
		elif o.has("equipo") and o.n > 0:   # uno de la casilla del baúl, a la de su calidad nueva (si era el último, la deja)
			var e: Dictionary = g.baul_equipo[o.equipo]
			var q := Armas.quedan_de(e) + 1
			var usada: bool = e.get("usada", false)
			e.n = o.n - 1
			if e.n <= 0:
				g.baul_equipo.remove_at(o.equipo)
			Objetos.arrojables_al_baul(g, o.id, calidad, 1, q, usada)
		elif o.has("equipo"):
			g.baul_equipo[o.equipo].quedan = Armas.quedan_de(g.baul_equipo[o.equipo]) + 1
			g.baul_equipo[o.equipo].calidad = calidad)
	if o.has("k"):
		partida.lanzables.quitar(o.sitio, 1)
	if o.n > 0:   # (un lanzable: en el banco, la casilla del baúl donde ha entrado, la última de su clase: "q" y su sitio)
		var equipo: Array = Guardado.cargar().baul_equipo
		for j in equipo.size():
			if equipo[j].id == o.id and int(equipo[j].calidad) == calidad and int(equipo[j].get("n", 0)) > 0:
				sel = "q%d" % j
	elif not o.has("equipo"):
		partida.johnny.quedan[o.id] = partida.johnny.quedan_de(o.id) + 1
		partida.johnny.calidades[o.id] = calidad
		partida.johnny.avisar_arma()
	Sonido.tocar("gema")
	aviso = Idioma.t("¡Mejorado! Ahora es %s.") % Armas.nombre(o.id, calidad)
	salta = [sel]
	foco = "mejorar"
	pintar()
	partida.logros.cumplir("manitas")
	if calidad >= Armas.EPICA:
		partida.logros.cumplir("joya_corona")


# ── Inventario y baúl: arrastrar ──
# Con el ratón o el dedo: se aprieta en una casilla y, al mover un poco, lo de dentro
# se levanta y sigue al dedo, y su casilla se queda apagada (levantar; va con el arrastrar de Godot, así que el botón ya
# no cuenta como tocado). Se encienden los sitios donde se puede soltar (destinos): en el inventario, la mano o el
# repuesto de su tipo (las armas se cambian), Johnny (se pone el arma, sin marca, o usa la cura, con un óvalo), los arrojables de la mano al
# repuesto y al revés (encima de otro, se cambian esos dos; si es de la misma clave, el mismo tipo y la misma calidad, y no
# está lleno, se juntan: Lanzables.juntar, también entre dos de repuesto) y la ficha, que se vuelve la zona roja de tirar (la casilla
# entera); en el baúl, la otra mitad (guardar o sacar). El sitio que hay bajo el dedo crece un poco (mirar). Al soltar,
# se hace lo mismo que con los botones de la ficha (soltar_en) y lo que llega da un saltito; si no se puede soltar ahí,
# vuelve a su casilla y, si se ha soltado en otro sitio, tiembla (volver). Con el mando y el teclado no cambia nada

# Empieza a arrastrarse lo de una casilla: la ficha lo enseña, su casilla se apaga, lo que sigue al dedo es su dibujo
# (vista_arrastre) y se encienden los sitios donde se puede soltar
func levantar(_donde: Vector2, clave: String, b: Button) -> Variant:
	if not abierto in ["inventario", "baul"] or not arrastre.is_empty() or not existe(clave) or not b.has_meta("dibujo"):
		return null
	if sel != clave:
		elegir(clave)
	arrastre = {"clave": clave}
	for h in b.get_children():
		h.modulate.a = 0.25
	b.set_drag_preview(vista_arrastre(b.get_meta("dibujo")))
	encender(clave)
	Sonido.tocar("coger")
	return {"cosa": clave}


# Lo que sigue al dedo: el dibujo de la casilla (al menos al doble) con su sombra, un poco por encima del dedo para que
# en el móvil se vea. Sale con un pequeño salto
func vista_arrastre(d: TextureRect) -> Control:
	var lado := d.texture.get_size() * maxi(2, roundi(d.size.x / d.texture.get_width()))
	var raiz := Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sombra in [true, false]:
		var r := estampa(d.texture, lado)
		r.position = -lado / 2.0 + (Vector2(5, 0) if sombra else Vector2(0, -10))
		if sombra:
			r.modulate = Color(0, 0, 0, 0.4)
		raiz.add_child(r)
	raiz.scale = Vector2(0.75, 0.75)
	create_tween().tween_property(raiz, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return raiz


# Un dibujo de icono de ese tamaño, con los píxeles nítidos
func estampa(tex: Texture2D, lado: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = lado
	return r


# Dónde se puede soltar lo de esa casilla y qué se hace al soltarlo ahí: {sitio: "poner", "tirar", "usar", "mover" (los
# arrojables), "guardar" o "sacar"}. Lo que no se puede tirar (los arrojables; la de la mano, sin otra de repuesto) no
# enciende la zona roja; en el baúl, lo que no va al baúl o no cabe no enciende nada
func destinos(clave: String) -> Dictionary:
	var d := {}
	if not existe(clave):
		return d
	var i := clave.substr(1).to_int()
	var johnny: Node2D = partida.johnny
	if abierto == "baul":
		var s := Guardado.cargar()
		match clave[0]:
			"m":
				var id: String = Objetos.casillas(partida.mochila)[i][0]
				if Objetos.cabe_baul(s, id):
					d["baul"] = "guardar"
			"u":
				var tipo: String = johnny.huecos_municion()[i][0]
				if Objetos.cabe_baul(s, tipo):
					d["baul"] = "guardar"
			"p", "g":
				var id: String = johnny.huecos["cuerpo" if i == 0 else "fuego"] if clave[0] == "p" else partida.armas_guardadas[i]
				if Armas.al_baul(id, johnny.calidad(id)) and not fregona_sola(clave, id) and Objetos.hueco_baul(s):
					d["baul"] = "guardar"
			"l", "e":
				if caben_lanzables(s, partida.lanzables.clave_en(clave)) > 0:
					d["baul"] = "guardar"
			"b":
				if se_saca(cosas_baul(s)[i]):
					d["llevas"] = "sacar"
		otras_casillas(clave, d)
		return d
	match clave[0]:
		"g":
			d["p%d" % mano_de(partida.armas_guardadas[i])] = "poner"
			d["johnny"] = "poner"
			d["tirar"] = "tirar"
		"p":
			if partida.repuesto("cuerpo" if i == 0 else "fuego") != "":
				d["r%d" % i] = "poner"
				d["tirar"] = "tirar"
		"m":
			d["tirar"] = "tirar"
			if Objetos.casillas(partida.mochila)[i][0] in Objetos.USABLES:
				d["johnny"] = "usar"
		"u":
			d["tirar"] = "tirar"
		"l":
			d["tirar"] = "tirar"
			for j in Lanzables.REPUESTO:
				d["e%d" % j] = "mover"
		"e":
			d["tirar"] = "tirar"
			for j in Lanzables.MANO:
				d["l%d" % j] = "mover"
			# encima de otro de repuesto de la misma clave (tipo y calidad) que no esté lleno: se juntan
			for j in Lanzables.REPUESTO:
				if partida.lanzables.se_juntan(clave, "e%d" % j):
					d["e%d" % j] = "mover"
	otras_casillas(clave, d)
	return d


# Las otras casillas de su grupo (16 nov): soltarlo en una lo lleva allí o lo cambia por lo que haya (colocar_en)
func otras_casillas(clave: String, d: Dictionary) -> void:
	var grupo := grupo_de(clave)
	if grupo == "":
		return
	var propia := sitio_de(clave)
	var s := Guardado.cargar() if grupo == "baul" else {}
	for j in casillas_de(grupo, s):
		if LETRA[grupo] + str(j) != propia:
			d[LETRA[grupo] + str(j)] = "colocar"


# La mano de un arma: 0 la de cuerpo a cuerpo y 1 la de distancia ("p0", "r1"...)
func mano_de(id: String) -> int:
	return 0 if Armas.datos(id).tipo == "cuerpo" else 1


# Los sitios de donde sale lo de esa casilla: soltarlo ahí no es un error, solo vuelve (su casilla y, en el baúl, su mitad)
func propios(clave: String) -> Array:
	var lista := [sitio_de(clave)]
	if abierto == "baul":
		lista.append("baul" if clave[0] == "b" else "llevas")
	match clave[0]:
		"g": lista.append("r%d" % mano_de(partida.armas_guardadas[clave.substr(1).to_int()]))
		"p", "l", "e": lista.append(clave)
	return lista


# Enciende los sitios donde se puede soltar lo que se acaba de levantar y pone encima de todo la tapa: es la que
# recibe lo que se suelta (esté donde esté) y la que va mirando qué sitio hay bajo el dedo
func encender(clave: String) -> void:
	capa = Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(capa)
	var hay := destinos(clave)
	encendidos = hay
	for s in sitios:
		if s[0] in hay:
			luz(s[0], s[1], hay[s[0]], clave)
	tapa = Control.new()
	tapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	tapa.set_drag_forwarding(Callable(), mirar, soltar)
	fondo.add_child(tapa)
	encima = ""


# Un sitio encendido, encima de lo suyo: una casilla, con un marco amarillo; Johnny, con un óvalo y «Usar» (con un arma de
# repuesto no se enciende nada: se le puede soltar encima y se la pone, pero sin óvalo, L29); la ficha, la zona roja de
# tirar; y una mitad del baúl, con lo que pasa. Lleva dos estilos, el de siempre y el de cuando el dedo está encima (crecer)
func luz(nombre: String, r: Rect2, que: String, clave: String) -> void:
	if nombre == "johnny" and que == "poner":
		return
	var rojo := que == "tirar"
	var es_casilla := nombre.length() <= 3   # ("p0", "M3", "B12"; las zonas tienen nombres largos: "johnny", "baul")
	if es_casilla:
		r = r.grow(3)
	var p := Panel.new()
	p.name = "luz_" + nombre
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(p)
	p.position = r.position
	p.size = r.size
	for de_encima in [false, true]:
		var e := StyleBoxFlat.new()
		if rojo:
			e.bg_color = Color("#5c1a1f") if de_encima else Color("#3a1216")
			e.border_color = Color("#d64541")
		else:
			e.bg_color = Color(Tema.AMARILLO, 0.22 if de_encima else 0.08)
			e.border_color = Tema.AMARILLO
		e.set_border_width_all(4 if de_encima else (3 if rojo or es_casilla else 2))
		e.set_corner_radius_all(int(r.size.x / 2.0) if nombre == "johnny" else 4)
		p.set_meta("encima" if de_encima else "normal", e)
	p.add_theme_stylebox_override("panel", p.get_meta("normal"))
	match que:
		"tirar": zona_roja(p, clave)
		"usar": cartel(p, [Idioma.t("Usar")], 0.0)
		"guardar": cartel(p, [Idioma.t("Suelta aquí"), Idioma.t("para guardarlo en el baúl")], r.size.y / 2.0 - 28.0)
		"sacar": cartel(p, [Idioma.t("Suelta aquí"), Idioma.t("para sacar uno") if clave[0] == "b" else Idioma.t("para sacarla")],
			r.size.y / 2.0 - 28.0)


# La zona roja de tirar (encima de la ficha): una flecha que baja al suelo y lo que se tira, que se queda a tus pies
func zona_roja(p: Panel, clave: String) -> void:
	var rojo := Color("#d64541")
	var flecha := Control.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flecha.draw.connect(func():
		Formas.poligono(flecha, PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(14, 32), Vector2(30, 32),
			Vector2(0, 62), Vector2(-30, 32), Vector2(-14, 32)]), rojo)
		flecha.draw_rect(Rect2(-46, 74, 92, 4), rojo))
	p.add_child(flecha)
	flecha.position = Vector2(p.size.x / 2.0, 126)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(caja)
	caja.position = Vector2(12, 226)
	var ancho := p.size.x - 24.0
	var claro := Color("#ffc4be")
	renglon(caja, Idioma.t("Suelta aquí"), claro, HORIZONTAL_ALIGNMENT_CENTER, ancho).theme_type_variation = "Titulo"
	renglon(caja, Idioma.t("para tirarlo al suelo"), claro, HORIZONTAL_ALIGNMENT_CENTER, ancho)
	espacio(caja, 18)
	renglon(caja, que_se_tira(clave), Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER, ancho)
	renglon(caja, Idioma.t("se queda a tus pies"), Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER, ancho)
	if clave[0] == "p":
		renglon(caja, Idioma.t("y la de repuesto pasa a la mano"), Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER, ancho)


# Lo que se tira al soltar en la zona roja, con cuántos: «Escopeta», «Trapo ×2», «24 balas»...
func que_se_tira(clave: String) -> String:
	var i := clave.substr(1).to_int()
	match clave[0]:
		"g": return Objetos.nombre(partida.armas_guardadas[i])
		"p": return Objetos.nombre(partida.johnny.huecos["cuerpo" if i == 0 else "fuego"])
		"m":
			var c: Array = Objetos.casillas(partida.mochila)[i]
			return Objetos.nombre(c[0]) + (" ×%d" % c[1] if c[1] > 1 else "")
		"u":
			var h: Array = partida.johnny.huecos_municion()[i]
			return cuenta_municion(h[0], h[1]) if h[1] > 1 else Armas.municion_nombre(h[0])
		"l", "e":
			var n: int = partida.lanzables.cuantos_en(clave)
			return nombre_lanzable(partida.lanzables.clave_en(clave)) + (" ×%d" % n if n > 1 else "")
	return ""


# Un cartelito oscuro en medio de un sitio encendido, a la altura "y": la primera línea en amarillo y las demás en
# blanco
func cartel(padre: Control, lineas: Array, y: float) -> void:
	var c := PanelContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var e := StyleBoxFlat.new()
	e.bg_color = Color("#141119")
	e.border_color = Tema.AMARILLO
	e.set_border_width_all(2)
	e.set_corner_radius_all(4)
	e.set_content_margin_all(6)
	c.add_theme_stylebox_override("panel", e)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	c.add_child(caja)
	for k in lineas.size():
		var t := Label.new()
		t.text = lineas[k]
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_color_override("font_color", Tema.AMARILLO if k == 0 else Tema.TINTA)
		caja.add_child(t)
	padre.add_child(c)
	c.position = Vector2(((padre.size.x - c.get_combined_minimum_size().x) / 2.0), y).floor()


# Mientras se arrastra (la tapa lo pregunta cada vez que se mueve el dedo): el sitio encendido que hay debajo crece un
# poco y el de antes vuelve a su tamaño. Se puede soltar en cualquier sitio: si ahí no vale, vuelve a su casilla
func mirar(donde: Vector2, _datos: Variant) -> bool:
	var nuevo := sitio_en(en_lienzo(donde), encendidos)
	if not is_instance_valid(capa) or capa.get_node_or_null(NodePath("luz_" + nuevo)) == null:
		nuevo = ""
	if nuevo != encima:
		crecer(encima, false)
		crecer(nuevo, true)
		encima = nuevo
	return true


# Un punto de la tapa (la pantalla) en el lienzo
func en_lienzo(donde: Vector2) -> Vector2:
	return lienzo.get_global_transform().affine_inverse() * (tapa.get_global_transform() * donde)


# El sitio que hay en ese punto del lienzo ("" ninguno). Si hay varios (una casilla del baúl, dentro de su mitad), el
# primero de "validos" (donde se puede soltar) o, si no, el primero
func sitio_en(punto: Vector2, validos := {}) -> String:
	var primero := ""
	for s in sitios:
		if s[1].has_point(punto):
			if s[0] in validos:
				return s[0]
			if primero == "":
				primero = s[0]
	return primero


# Con el dedo encima, un sitio encendido se ilumina más y, si es una casilla, crece un poco (y al irse, vuelve)
func crecer(nombre: String, si: bool) -> void:
	if nombre == "" or not is_instance_valid(capa):
		return
	var marco: Panel = capa.get_node_or_null(NodePath("luz_" + nombre))
	if marco == null:
		return
	marco.add_theme_stylebox_override("panel", marco.get_meta("encima" if si else "normal"))
	if nombre.length() > 3:
		return
	for s in sitios:
		if s[0] == nombre and is_instance_valid(s[2]):
			for n in [marco, s[2]]:
				if n.has_meta("crece"):
					n.get_meta("crece").kill()
				n.pivot_offset = n.size / 2.0
				var t: Tween = n.create_tween()
				t.tween_property(n, "scale", Vector2(1.12, 1.12) if si else Vector2.ONE, 0.08)
				n.set_meta("crece", t)


# Al soltar: se mira en qué sitio ha caído y, en cuanto Godot acaba de soltar, se hace lo suyo (soltar_en)
func soltar(donde: Vector2, _datos: Variant) -> void:
	var clave: String = arrastre.get("clave", "")
	arrastre = {}
	soltar_en.call_deferred(clave, sitio_en(en_lienzo(donde), encendidos), tapa.get_global_transform() * donde)


# Suelta lo de la casilla "clave" en el sitio "a_donde": si se puede, se hace lo mismo que con el botón de la ficha
# (sonando «soltar» en vez de «cambiar»); si no, vuelve a su casilla desde "punto" (donde se ha soltado). Las pruebas
# la llaman sin arrastrar
func soltar_en(clave: String, a_donde: String, punto := Vector2.INF) -> void:
	if clave == "" or not abierto in ["inventario", "baul"]:
		apagar()
		return
	var que: String = destinos(clave).get(a_donde, "")
	var mal := a_donde != "" and not a_donde in propios(clave)
	apagar()
	if que == "":
		volver(clave, mal, punto)
		return
	sel = clave
	con_dedo = true
	match que:
		"poner":
			if clave[0] == "p":   # la de la mano, a su repuesto: se pone la de repuesto
				sel = "g%d" % partida.armas_guardadas.find(partida.repuesto("cuerpo" if clave == "p0" else "fuego"))
			poner_guardada()
		"tirar": tirar(true)
		"usar": usar(true)
		"mover": mover_lanzable(otro_lanzable(a_donde))
		"guardar": guardar()
		"sacar": sacar()
		"colocar": colocar_en(clave, a_donde)
	con_dedo = false


# Ese sitio ("l1", "e3") si hay un montón de arrojables en él, o "" si está vacío
func otro_lanzable(a_donde: String) -> String:
	return a_donde if partida.lanzables.clave_en(a_donde) != "" else ""


# Apaga los sitios encendidos y quita la tapa (al soltar, o si se corta el arrastre)
func apagar() -> void:
	arrastre = {}
	encendidos = {}
	crecer(encima, false)
	encima = ""
	for n in [capa, tapa]:
		if is_instance_valid(n):
			n.queue_free()
	capa = null
	tapa = null


# Lo que no se puede soltar ahí vuelve volando a su casilla y, si se había soltado en otro sitio ("mal"), suena «no» y
# la casilla tiembla
func volver(clave: String, mal: bool, punto := Vector2.INF) -> void:
	if mal:
		Sonido.tocar("no")
	var b: Control = lienzo.get_node_or_null(NodePath(clave)) if clave != "" and is_instance_valid(lienzo) else null
	if b == null:
		return
	var llegar := func():
		if not is_instance_valid(b):
			return
		for h in b.get_children():
			h.modulate.a = 1.0
		if mal:
			temblar(b)
	var d: TextureRect = b.get_meta("dibujo") if b.has_meta("dibujo") else null
	if d == null or punto == Vector2.INF:
		llegar.call()
		return
	var vuela := estampa(d.texture, d.size)
	lienzo.add_child(vuela)
	vuela.global_position = punto - d.size / 2.0
	var t := vuela.create_tween()
	t.tween_property(vuela, "global_position", d.global_position, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		vuela.queue_free()
		llegar.call())


# Un temblor de lado a lado (lo que no se ha podido soltar donde se ha soltado)
func temblar(n: Control) -> void:
	var x := n.position.x
	var t := n.create_tween()
	for dx in [5.0, -4.0, 3.0, -2.0, 0.0]:
		t.tween_property(n, "position:x", x + dx, 0.04)


# Un saltito: sube un poco y cae botando (lo que acaba de llegar a su casilla, o Johnny al ponerse un arma o curarse).
# "n" es un Control o un Node2D
func saltar(n, alto: float) -> void:
	var y: float = n.position.y
	var t: Tween = n.create_tween()
	t.tween_property(n, "position:y", y - alto, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(n, "position:y", y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# Si el arrastre se corta sin soltar en la tapa (al soltar fuera de la ventana...), lo levantado vuelve a su casilla
func _process(_delta: float) -> void:
	if not arrastre.is_empty() and not get_viewport().gui_is_dragging():
		var clave: String = arrastre.clave
		apagar()
		volver(clave, false)


# ── Colocar y ordenar (16 nov) ──
# Lo que se lleva y lo del baúl no apuntan en qué casilla va cada cosa (la mochila es una lista de ids; la munición y el
# baúl, cuántos hay de cada): el orden sale de los datos. Para que el jugador lo coloque a su gusto, encima va una lista
# de qué va en cada casilla, por su nombre («balas#24»: el tipo y, detrás de «#», lo exacto; los iguales se pueden
# cambiar entre sí): la de la mochila, la munición y las curas en la partida (partida.orden_casillas) y la del baúl en el
# guardado («orden_baul»). Al pintar, cada cosa va a la casilla que tiene apuntada (primero la de su nombre exacto y, si
# no, una de su tipo) y lo nuevo, al primer hueco libre; luego se apunta cómo ha quedado, para que no se mueva nada al
# coger otra cosa. Las claves de las casillas («m3», «b12») siguen siendo las de los datos: lo demás (la ficha, tirar,
# guardar, sacar) no se entera. Se mueve arrastrando a otra casilla del mismo grupo (vacía: va allí; con algo: se
# cambian) o con «Mover» de la ficha (mando y teclado: la marca lleva lo levantado y A lo suelta); «Ordenar» lo coloca
# todo agrupado por tipo. Prueba: --ordenar

# La letra de los sitios de las casillas de cada grupo ("M3": la 4.ª casilla de Objetos, esté vacía o no)
const LETRA := {"objetos": "M", "curas": "C", "municion": "U", "baul": "B"}
var llevando := ""         # mando y teclado: lo levantado con «Mover», que espera su casilla nueva ("" nada)


# El grupo de casillas de lo de esa clave: "objetos", "curas", "municion", "baul" o "" (las armas y los arrojables a
# mano tienen sus casillas fijas)
func grupo_de(clave: String) -> String:
	if not existe(clave):
		return ""
	match clave[0]:
		"m": return "curas" if Objetos.casillas(partida.mochila)[clave.substr(1).to_int()][0] in Objetos.USABLES else "objetos"
		"u": return "municion"
		"b": return "baul" if abierto == "baul" else ""
	return ""


# Cuántas casillas tiene un grupo (el baúl, más si pasa de las suyas: al acabar la partida entra todo)
func casillas_de(grupo: String, s := {}) -> int:
	match grupo:
		"objetos": return Objetos.MOCHILA
		"curas": return Objetos.CURAS
		"municion": return Armas.HUECOS_MUNICION
	return maxi(Objetos.BAUL, cosas_baul(s).size())


# Lo de un grupo, en el orden de los datos: [[clave, tipo, nombre exacto, id], ...]
func cosas_grupo(grupo: String, s := {}) -> Array:
	var lista := []
	match grupo:
		"objetos", "curas":
			var llenas := Objetos.casillas(partida.mochila)
			for i in llenas.size():
				if (llenas[i][0] in Objetos.USABLES) == (grupo == "curas"):
					lista.append(["m%d" % i, llenas[i][0], "%s#%d" % llenas[i], llenas[i][0]])
		"municion":
			var h: Array = partida.johnny.huecos_municion()
			for i in h.size():
				lista.append(["u%d" % i, h[i][0], "%s#%d" % h[i], h[i][0]])
		"baul":
			var cosas := cosas_baul(s)
			for i in cosas.size():
				var o: Dictionary = cosas[i]
				if o.equipo < 0:
					lista.append(["b%d" % i, "o:" + o.id, "o:%s#%d" % [o.id, o.n], o.id])
				else:
					var e: Dictionary = s.baul_equipo[o.equipo]
					var tipo := "e:%s:%d" % [o.id, o.calidad]
					lista.append(["b%d" % i, tipo, "%s#%d:%d:%s" % [tipo, Armas.quedan_de(e), o.n, e.get("usada", false)], o.id])
	return lista


# La lista apuntada de un grupo (qué va en cada casilla)
func orden_de(grupo: String, s := {}) -> Array:
	return s.get("orden_baul", []) if grupo == "baul" else partida.orden_casillas.get(grupo, [])


# Apunta qué va en cada casilla de un grupo (en el baúl, solo si ha cambiado: se escribe el guardado)
func apuntar_orden(grupo: String, lista: Array, s := {}) -> void:
	if grupo != "baul":
		partida.orden_casillas[grupo] = lista
	elif s.get("orden_baul", []) != lista:
		s["orden_baul"] = lista
		Guardado.cambiar(func(g): g.orden_baul = lista)


# Dónde va cada cosa de un grupo: {clave: casilla}. Primero, lo que tiene apuntada una casilla con su nombre exacto;
# luego, con su tipo; lo demás, en los huecos libres, en el orden de los datos
func colocar(grupo: String, s := {}) -> Dictionary:
	var cosas := cosas_grupo(grupo, s)
	var orden := orden_de(grupo, s)
	var total := casillas_de(grupo, s)
	var donde := {}
	var llenas := {}
	for exacto in [true, false]:
		for j in mini(orden.size(), total):
			var buscado: String = orden[j] if exacto else String(orden[j]).get_slice("#", 0)
			if buscado == "" or llenas.has(j):
				continue
			for c in cosas:
				if not donde.has(c[0]) and (c[2] if exacto else c[1]) == buscado:
					donde[c[0]] = j
					llenas[j] = true
					break
	var j := 0
	for c in cosas:
		if donde.has(c[0]):
			continue
		while llenas.has(j):
			j += 1
		donde[c[0]] = j
		llenas[j] = true
	return donde


# Lo que hay en cada casilla de un grupo, como se apunta: [nombre exacto o "", ...]
func lista_de(grupo: String, donde: Dictionary, s := {}) -> Array:
	var lista := []
	lista.resize(casillas_de(grupo, s))
	lista.fill("")
	for c in cosas_grupo(grupo, s):
		lista[donde[c[0]]] = c[2]
	return lista


# Pinta las casillas de un grupo, cada cosa en la suya (colocar), con su sitio para soltar ("M3"...) y, mientras se
# lleva algo de ese grupo con «Mover», las vacías también se pueden elegir. "rect" da el sitio de la casilla j. Apunta
# cómo ha quedado
func pintar_grupo(grupo: String, rect: Callable, margen: float, s := {}) -> void:
	var donde := colocar(grupo, s)
	var en := {}
	for c in donde:
		en[donde[c]] = c
	var con_marca := llevando != "" and grupo_de(llevando) == grupo
	for j in casillas_de(grupo, s):
		var r: Rect2 = rect.call(j)
		var nombre: String = LETRA[grupo] + str(j)
		var c: Control
		if en.has(j):
			var d := dibujo_de(en[j], s)
			c = casilla_inv(r, en[j], d[0], d[1], d[2], margen)
			if en[j] == llevando:
				c.modulate.a = 0.5
		elif con_marca:
			c = hueco_libre(r, nombre)
		else:
			c = casilla_inv(r)
		if con_marca and c is Button:   # (la casilla a la que iría: con el borde amarillo)
			for estado in ["focus", "hover"]:
				c.add_theme_stylebox_override(estado, estilo(Tema.AMARILLO, c.name == llevando, true))
		sitio(nombre, r, c)
	apuntar_orden(grupo, lista_de(grupo, donde, s), s)


# El dibujo, la cuenta y el borde de lo de una casilla: [icono, cuenta, color]
func dibujo_de(clave: String, s := {}) -> Array:
	var i := clave.substr(1).to_int()
	match clave[0]:
		"m":
			var c: Array = Objetos.casillas(partida.mochila)[i]
			return [Objetos.icono(c[0]), "×%d" % c[1] if c[1] > 1 else "", GRIS]
		"u":
			var h: Array = partida.johnny.huecos_municion()[i]
			return [Armas.MUNICION[h[0]].icono, str(h[1]), GRIS]
	var o: Dictionary = cosas_baul(s)[i]
	return [Objetos.icono(o.id), str(o.n) if o.n > 0 else "", GRIS if o.equipo < 0 else Armas.color(o.calidad)]


# Una casilla vacía que se puede elegir mientras se lleva algo con «Mover»: al pulsarla, lo levantado va allí
func hueco_libre(r: Rect2, nombre: String) -> Button:
	var b := Button.new()
	b.name = nombre
	for estado in ["normal", "pressed", "disabled"]:
		b.add_theme_stylebox_override(estado, estilo(Color("#2a2631"), false, false))
	b.pressed.connect(func(): colocar_en(llevando, nombre))
	lienzo.add_child(b)
	b.position = r.position - ORIGEN
	b.size = r.size
	return b


# El sitio de la casilla en la que está lo de esa clave ("M3"), o ""
func sitio_de(clave: String) -> String:
	var grupo := grupo_de(clave)
	if grupo == "":
		return ""
	var s := Guardado.cargar() if grupo == "baul" else {}
	return LETRA[grupo] + str(colocar(grupo, s).get(clave, 0))


# Lleva lo de "clave" a la casilla "a_donde" ("M3") de su grupo: si está vacía, va allí; si hay otra cosa, se cambian.
# Lo que se mueve da un saltito
func colocar_en(clave: String, a_donde: String) -> void:
	llevando = ""
	var grupo := grupo_de(clave)
	if grupo == "" or a_donde.length() < 2 or a_donde[0] != LETRA[grupo]:
		repintar()
		return
	var s := Guardado.cargar() if grupo == "baul" else {}
	var donde := colocar(grupo, s)
	var lista := lista_de(grupo, donde, s)
	var desde: int = donde[clave]
	var hasta := a_donde.substr(1).to_int()
	sel = clave
	foco = clave
	if hasta >= lista.size() or hasta == desde:
		pintar()
		return
	var otro: String = lista[hasta]
	lista[hasta] = lista[desde]
	lista[desde] = otro
	apuntar_orden(grupo, lista, s)
	salta = [clave]
	for c in donde:
		if donde[c] == hasta:
			salta.append(c)
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	pintar()


# Pone «Mover» en lo que dice la ficha "d" (sus botones: "botones" en el inventario, delante de «Tirar al suelo»;
# "mover" en el baúl, que lo pone al lado de «Destruir»), si lo elegido se puede cambiar de casilla. Mientras se lleva
# algo, el botón dice «Cancelar», es el único y la ficha cuenta cómo se suelta
func poner_mover(d: Dictionary) -> void:
	if grupo_de(sel) == "":
		return
	var b := ["mover", Idioma.t("Cancelar") if llevando != "" else Idioma.t("Mover"), mover_marca, false]
	if llevando != "":
		d.que = Idioma.t("Elige su casilla nueva con las flechas o la cruceta y pulsa A o Intro. Si tiene algo, se cambian.")
	if abierto == "baul":
		d["mover"] = b
		return
	if llevando != "":
		d.botones = [b]
		return
	var i: int = d.botones.map(func(x): return x[0]).find("tirar")
	d.botones.insert(i if i >= 0 else d.botones.size(), b)


# «Mover» de la ficha (con el mando o el teclado): levanta lo elegido y la marca se queda en su casilla; con las flechas
# o la cruceta se va a otra y A (o Intro) lo suelta allí. Pulsado otra vez («Cancelar»), lo deja donde estaba
func mover_marca() -> void:
	if llevando != "":
		dejar_de_llevar()
		return
	if grupo_de(sel) == "":
		return
	llevando = sel
	foco = sel
	Sonido.tocar("coger")
	pintar()


func dejar_de_llevar() -> void:
	foco = llevando
	llevando = ""
	pintar()


# «Ordenar»: lo coloca todo agrupado por tipo (tipo_orden): lo que lleva y, en el baúl, también lo del baúl
func ordenar() -> void:
	llevando = ""
	var s := Guardado.cargar() if abierto == "baul" else {}
	var grupos := ["objetos", "municion", "curas"] + (["baul"] if abierto == "baul" else [])
	for grupo in grupos:
		var cosas := cosas_grupo(grupo, s)
		cosas.sort_custom(func(a, b): return rango(a, grupo) < rango(b, grupo))
		var lista := []
		lista.resize(casillas_de(grupo, s))
		lista.fill("")
		for j in cosas.size():
			lista[j] = cosas[j][2]
		apuntar_orden(grupo, lista, s)
	Sonido.tocar("cambiar")
	repintar()


# Para ordenar: el tipo (tipo_orden), su sitio en la lista de su clase y, dentro de lo mismo, primero lo mejor y lo más
# lleno (y si no, como estaban)
func rango(c: Array, grupo: String) -> Array:
	var id: String = c[3]
	var de_lista := Objetos.todos().find(id)
	if Armas.DATOS.has(id):
		de_lista = Armas.DATOS.keys().find(id)
	elif Lanzables.DATOS.has(Lanzables.tipo_de(id)):
		de_lista = Lanzables.DATOS.keys().find(Lanzables.tipo_de(id))
	var equipo := grupo == "baul" and String(c[1]).begins_with("e:")
	var calidad := String(c[1]).get_slice(":", 2).to_int() if equipo else 0
	var detras := String(c[2]).get_slice("#", 1)
	var cuantos := detras.get_slice(":", 1).to_int() if equipo else detras.to_int()
	return [tipo_orden(id), de_lista, -calidad, -cuantos, String(c[0]).substr(1).to_int()]


# El orden de los tipos al ordenar: armas cuerpo a cuerpo, a distancia y especiales, lanzables, munición, curas,
# materiales, comida y lo demás
static func tipo_orden(id: String) -> int:
	if Armas.DATOS.has(id):
		return {"cuerpo": 0, "distancia": 1, "especial": 2}.get(Armas.familia(id), 2)
	if Lanzables.DATOS.has(Lanzables.tipo_de(id)):
		return 3
	if id in Armas.MUNICION:
		return 4
	if id in Objetos.USABLES:
		return 5
	if id in Objetos.PIEZAS:
		return 6
	if id in Objetos.COMIDAS:
		return 7
	return 8


# ── Piezas ──

func boton(caja: Control, nombre: String, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.theme_type_variation = variacion
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


# Si el texto de un botón no cabe en su ancho (en otros idiomas), su letra se achica hasta que quepa (hasta 12)
func encoger(b: Button) -> void:
	var fuente: Font = b.get_theme_font("font")
	var tam := b.get_theme_font_size("font_size")
	while tam > 12 and fuente.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > b.size.x - 12.0:
		tam -= 1
	if tam != b.get_theme_font_size("font_size"):
		b.add_theme_font_size_override("font_size", tam)


func estilo(borde: Color, elegida: bool, encima: bool) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color("#3a3226") if elegida else (Color("#26222e") if encima else FONDO_CASILLA)
	e.border_color = Tema.AMARILLO if elegida else borde
	e.set_border_width_all(3 if elegida else 2)
	e.set_corner_radius_all(3)
	return e


# Al tocar una casilla del inventario, del baúl o del banco: se elige y, si su ficha tiene un botón que hace lo suyo
# («Ponérmela», «Usar», «A la mano», «Al repuesto», «Guardar en el baúl», «Sacar» o «Mejorar»), la marca salta a él (con
# el mando o las flechas, A dos veces y hecho)
func tocar(clave: String) -> void:
	if llevando != "":   # (con algo levantado con «Mover»: si es de su grupo, va ahí; si no, se deja donde estaba)
		if grupo_de(clave) == grupo_de(llevando):
			colocar_en(llevando, sitio_de(clave))
			return
		llevando = ""
	if abierto == "baul" and (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)):
		elegir(clave)
		pasar_al_momento()
		return
	Sonido.tocar("click")
	elegir(clave)
	var b: Control = principal()
	dar_foco.call_deferred(b if b else lienzo.find_child(sel, false, false))


# Esc, B del mando o (en el inventario) la misma tecla que lo abrió: cerrar. Va en _input porque Godot usa el
# Tabulador para pasar de un botón a otro y no llegaría. En el inventario, el baúl y el banco, además, los atajos: Y hace lo
# del botón principal de la ficha y, en el inventario, F (o RB) cambia el arrojable que se lanza y X (o Supr) tira lo
# elegido
func _input(evento: InputEvent) -> void:
	if abierto == "" or Confirmar.abierta:   # (con «¿Estás seguro?» delante, sus atajos esperan)
		return
	if llevando != "" and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa")):   # (lo deja donde estaba)
		get_viewport().set_input_as_handled()
		dejar_de_llevar()
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa") \
			or (abierto == "inventario" and evento.is_action_pressed("inventario")):
		get_viewport().set_input_as_handled()
		cerrar()
		return
	if not arrastre.is_empty():   # (con algo levantado, los atajos esperan)
		return
	if abierto == "inventario" and evento.is_action_pressed("cambiar_lanzable"):
		get_viewport().set_input_as_handled()
		partida.lanzables.cambiar()
		repintar()
		return
	var b: Button = null
	if evento is InputEventJoypadButton and evento.pressed and evento.button_index == JOY_BUTTON_Y:
		b = principal()
	elif (evento is InputEventJoypadButton and evento.pressed and evento.button_index == JOY_BUTTON_X) \
			or (evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_DELETE):
		b = viva.find_child("tirar", true, false) if is_instance_valid(viva) else null
	if b and not b.disabled:
		get_viewport().set_input_as_handled()
		b.pressed.emit()
