# Las pantallas de las cosas de Johnny (fase 7b; en el JS, showInventario y showBaul de src/ui.js). El juego se para
# mientras están abiertas:
#   - Inventario (Tab, I o Select; «todo a la vista», la parte 3 del inventario nuevo): Johnny grande en medio, de
#     frente, con su skin y el arma que tiene en la mano; a los lados, sus armas (a la izquierda las de cuerpo a cuerpo
#     y a la derecha las de distancia; arriba la de la mano y abajo la de repuesto: partida.llevar_arma), y debajo, los
#     3 arrojables a mano (lanzables.gd). En medio, tres grupos de 8: la mochila, la munición (por tipos:
#     Armas.MUNICION) y los arrojables de repuesto. A la derecha, la ficha de lo elegido (qué es, el cargador, las
#     barras y qué hace) y sus botones: "Ponérmela" (las de repuesto), "Usar" (lo de curar:
#     Objetos.USABLES), "A la mano" y "Al repuesto" (los arrojables) y "Tirar al suelo" (los objetos, la gasolina,
#     los bidones de ácido y las baterías, de uno en uno; las balas, el hueco entero en una caja; y las armas: la de la mano, solo si
#     lleva otra de repuesto, que pasa a la mano). Con las flechas o el mando, la ficha sigue a la marca; A (o tocar)
#     la lleva al botón principal de la ficha (A dos veces y hecho), X (o Supr) tira, Y hace lo del botón principal y F
#     cambia el arrojable que se lanza.
#   - Baúl (al arrimarse a él en la sala de mantenimiento; la parte 4 del inventario nuevo): la pantalla partida en
#     dos y se maneja como el inventario. A la izquierda, lo que lleva Johnny: sus armas y los arrojables a mano (solo
#     para verlos) y los objetos, la munición y los arrojables de repuesto. A la derecha, sus 32 casillas: los objetos
#     guardados, que ya no se pierden si Johnny cae. Abajo, la ficha de lo elegido
#     con su botón: «Guardar en el baúl» mete todo lo de esa casilla (lo de curar no va, Objetos.al_baul; de la
#     munición, solo la que también es un objeto, como la gasolina; con el baúl lleno, solo caben más de lo que ya
#     tiene) y «Sacar uno», un objeto de uno en uno (a la mochila o a la munición). «Guardar todo» mete todo lo que se
#     pueda.
# Hasta el 25 oct había otra pantalla, la del banco de trabajo, que creaba armas con recetas; se quitaron, y el banco
# está en obras (partida.gd) hasta que sirva para mejorar las armas.
# Van con el ratón, con flechas + Intro o con el mando (A elige, B cierra). En el inventario y en el baúl, además, las
# cosas se arrastran con el ratón o el dedo (la parte 5 del inventario nuevo: ver «arrastrar», abajo), y lo que llega a
# su sitio nuevo da un saltito (también con los botones y el mando).
extends CanvasLayer

signal cerrado

const FONDO_CASILLA := Color("#1b1822")
const GRIS := Color("#8a8494")               # el borde de las casillas (las armas y los objetos de siempre)

var partida: Node
var fondo: ColorRect
var abierto := ""          # "inventario", "baul" o "" (nada)
var sel := ""              # la casilla elegida: "m2" la 3.ª de la mochila, "g0" la 1.ª arma guardada,
                           # "b2" el 3.er objeto del baúl, "u1" el 2.º hueco de munición, "l0" el 1.er arrojable a mano,
                           # "e3" el 4.º de repuesto, "p0" y "p1" las armas de la mano (la de cuerpo a cuerpo y la de distancia)
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
var con_dedo := false      # lo que se hace ahora viene de soltar algo arrastrado (suena «soltar» en vez de «cambiar»)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abrir(que: String, p: Node) -> void:
	partida = p
	abierto = que
	sel = ""
	foco = ""
	aviso = ""
	salta = []
	salta_johnny = false
	pintar(true)


func cerrar() -> void:
	if abierto == "":
		return
	if get_viewport().gui_is_dragging():   # (si se cierra con algo levantado, se suelta sin más)
		get_viewport().gui_cancel_drag()
	arrastre = {}
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
const LADO := 52                   # las casillas de los tres grupos de 8
const ANCHO_FICHA := 222.0         # lo ancho que es lo de dentro de la ficha
# Lo que hace cada arma de la tienda y cada arrojable
const QUE_HACE := {
	"fregona": "Barre un abanico muy ancho y echa lejos a los zombis.",
	"bate": "Un golpe fuerte que empuja a los zombis.",
	"cuchillo": "Muy rápido, pero hay que arrimarse.",
	"pistola": "Dispara de una en una, recto y lejos.",
	"escopeta": "Cinco perdigones en abanico. Se recarga de cartucho en cartucho.",
	"mp5": "Ráfagas muy rápidas. Gasta las mismas balas que la pistola.",
	"lanzallamas": "Llamarada continua que quema a todos. Se llena con gasolina.",
	"desintegrador": "Chorro de ácido continuo que corroe a todos. Se llena con bidones de ácido.",
	"pistola_electrica": "Chispas que aturden y saltan al zombi de al lado. Cada batería le llena el cargador.",
	"molotov": "Se rompe y deja un charco de fuego que quema a los zombis.",
	"granada": "Bota, rueda y explota a los 2 segundos.",
	"atraedora": "Suena, atrae a los zombis 3 s y explota.",
	"congeladora": "Explota y deja a los zombis congelados 3 s.",
}
# Cómo se dice la munición de reserva en la ficha («Reserva: 2 gasolinas»)
const RESERVA := {"balas": "balas", "cartuchos": "cartuchos", "gasolina": "gasolinas",
	"bidon_acido": "bidones de ácido", "bateria": "baterías"}
const PRINCIPALES := ["poner", "usar", "a_la_mano", "al_repuesto", "guardar", "sacar"]   # los de la ficha que no son tirar


func pintar_inventario(columna: VBoxContainer) -> Control:
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	asegurar_sel()
	preparar_lienzo(columna)
	rotulo(lienzo, "Inventario", 480, 26, Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER).theme_type_variation = "Titulo"
	# Johnny, grande, entre sus armas: a la izquierda las de cuerpo a cuerpo y a la derecha las de distancia (arriba
	# la de la mano y abajo la de repuesto)
	muneco(johnny)
	sitio("johnny", Rect2(154, 124, 140, 216))
	rotulo(lienzo, "Cuerpo a cuerpo", 64, 90, Tema.AMARILLO)
	rotulo(lienzo, "A distancia", 384, 90, Tema.AMARILLO, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in 2:
		var tipo: String = ["cuerpo", "fuego"][i]
		var x := 64.0 if i == 0 else 308.0
		var id: String = johnny.huecos[tipo]
		var r := Rect2(x, 122, 76, 76)
		sitio("p%d" % i, r, casilla_inv(r, "p%d" % i, Objetos.icono(id), carga_corta(id), borde(id)))
		rotulo(lienzo, "En la mano", x + 38, 202, Tema.AMARILLO, HORIZONTAL_ALIGNMENT_CENTER)
		var otra: String = partida.repuesto(tipo)
		r = Rect2(x, 232, 76, 76)
		if otra != "":
			sitio("r%d" % i, r, casilla_inv(r, "g%d" % partida.armas_guardadas.find(otra), Objetos.icono(otra),
				carga_corta(otra), borde(otra)))
		else:
			sitio("r%d" % i, r, casilla_inv(r))
		rotulo(lienzo, "De repuesto", x + 38, 312, Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER)
	# debajo, los arrojables a mano (F cambia entre ellos): el que se lanza ahora, con un marco amarillo alrededor
	rotulo(lienzo, "Arrojables", 64, 350, Tema.AMARILLO)
	rotulo(lienzo, "F cambia", 384, 350, Tema.GRIS, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in Lanzables.MANO:
		var x := 82.0 + i * 102
		var k: String = lz.mano[i] if i < lz.mano.size() else ""
		sitio("l%d" % i, Rect2(x, 380, 84, 84), arrojable(Rect2(x, 380, 84, 84), "l%d" % i, k))
		if k == "":
			continue
		rotulo(lienzo, nombre_lanzable(k), x + 42, 468, Tema.TINTA, HORIZONTAL_ALIGNMENT_CENTER, 100)
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
			ahora.position = Vector2(x - 4, 376) - ORIGEN
			ahora.size = Vector2(92, 92)
	# en medio, los tres grupos de 8: los objetos de la mochila, la munición y los arrojables de repuesto
	raya(Rect2(393, 92, 2, 492))
	var llenas := Objetos.casillas(partida.mochila)
	rotulo(lienzo, "Objetos  %d / %d" % [llenas.size(), Objetos.MOCHILA], 406, 89, Tema.AMARILLO)
	for i in Objetos.MOCHILA:
		if i < llenas.size():
			var n: int = llenas[i][1]
			casilla_inv(rejilla(i, 116), "m%d" % i, Objetos.icono(llenas[i][0]), "×%d" % n if n > 1 else "")
		else:
			casilla_inv(rejilla(i, 116))
	var balas: Array = johnny.huecos_municion()
	rotulo(lienzo, "Munición  %d / %d" % [balas.size(), Armas.HUECOS_MUNICION], 406, 239, Tema.AMARILLO)
	for i in Armas.HUECOS_MUNICION:
		if i < balas.size():
			casilla_inv(rejilla(i, 266), "u%d" % i, Armas.MUNICION[balas[i][0]].icono, str(balas[i][1]))
		else:
			casilla_inv(rejilla(i, 266))
	rotulo(lienzo, "Arrojables  %d / %d" % [lz.repuesto.size(), Lanzables.REPUESTO], 406, 389, Tema.AMARILLO)
	for i in Lanzables.REPUESTO:
		sitio("e%d" % i, rejilla(i, 416), arrojable(rejilla(i, 416), "e%d" % i, lz.repuesto[i] if i < lz.repuesto.size() else ""))
	var seguir := boton(lienzo, "cerrar", "Seguir", cerrar)
	seguir.position = Vector2(406, 544) - ORIGEN
	seguir.size = Vector2(226, 38)
	sitio("tirar", Rect2(650, 92, 246, 492))   # la ficha: al arrastrar algo que se puede tirar, se vuelve la zona roja
	pintar_ficha()
	return lienzo.find_child(sel, false, false)


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
func raya(r: Rect2) -> void:
	var c := ColorRect.new()
	c.color = Color("#3d3647")
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(c)
	c.position = r.position - ORIGEN
	c.size = r.size


# El sitio de la casilla i de un grupo de 8 (4 por fila) que empieza en "y"
func rejilla(i: int, y: float) -> Rect2:
	return Rect2(406 + (i % 4) * (LADO + 6), y + floori(i / 4.0) * (LADO + 6), LADO, LADO)


# Si lo elegido ya no está (o no hay nada elegido), se elige otra cosa: la ficha nunca está vacía. En el inventario, el
# arma que tiene en la mano; en el baúl, lo primero que se puede guardar (de la mochila y luego de la munición) y, si no
# hay nada, lo primero del baúl (y si está vacío, el arma de la mano)
func asegurar_sel() -> void:
	if existe(sel):
		return
	if abierto == "baul":
		var llenas := Objetos.casillas(partida.mochila)
		for i in llenas.size():
			if Objetos.al_baul(llenas[i][0]):
				sel = "m%d" % i
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


# ¿Hay algo en esa casilla del inventario o del baúl?
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
		"b": return i < objetos_baul(Guardado.cargar()).size()
	return false


# Johnny grande (× 4) en medio, con su sombra: de frente y respirando, con su skin y el arma que tiene en la mano. Si
# se acaba de poner un arma o de curar, da un saltito
func muneco(johnny: Node2D) -> void:
	var pies := Vector2(224, 330) - ORIGEN
	var sombra := Control.new()
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sombra.draw.connect(func():
		sombra.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
		sombra.draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.43)))
	lienzo.add_child(sombra)
	sombra.position = pies
	var w: Dictionary = Armas.datos(johnny.huecos[johnny.mano])
	var vista := AnimatedSprite2D.new()
	vista.name = "johnny"
	vista.sprite_frames = Skins.hoja(w.hoja, johnny.skin)
	vista.centered = false
	vista.offset = -w.pies
	vista.scale = Vector2(4, 4)
	vista.position = pies
	vista.material = johnny.sprite.material.duplicate()   # (el de partir la cintura, entero, como en la taquilla)
	vista.material.set_shader_parameter("parte", 0)
	lienzo.add_child(vista)
	vista.play("reposo_s")
	if salta_johnny:
		saltar(vista, 16.0)


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
	var tex: Texture2D = load("res://assets/ui/iconos/%s.png" % icono)
	var k := maxi(1, floori(minf((lado.x - margen) / tex.get_width(), (lado.y - margen) / tex.get_height())))
	var r := estampa(tex, tex.get_size() * k)
	padre.add_child(r)
	r.position = ((lado - r.size) / 2.0).floor()
	return r


# La casilla de un arrojable ("" la deja vacía): su dibujo y cuántos quedan, de su máximo
func arrojable(r: Rect2, clave: String, k: String, margen := 12.0) -> Control:
	if k == "":
		return casilla_inv(r)
	var lz: Lanzables = partida.lanzables
	return casilla_inv(r, clave, icono_lanzable(k), "%d/%d" % [lz.cuantas(k), lz.maximo(k)], GRIS, margen)


func nombre_lanzable(k: String) -> String:
	return {"molotov": "Molotov", "granada": "Granada", "atraedora": "Atraedora", "congeladora": "Congeladora"}[k]


func icono_lanzable(k: String) -> String:
	return k   # (assets/ui/iconos/<tipo>.png)


# Lo que le queda a un arma de fuego que lleva: en el cargador (balas) o, las de depósito, en el depósito (segundos).
# La de la mano, lo de ahora; la de repuesto, lo que le quedaba al dejarla (johnny.coger) o, si no la ha llevado
# nunca en la mano, lleno
func carga(id: String) -> float:
	var johnny: Node2D = partida.johnny
	var w: Dictionary = Armas.datos(id)
	var deposito: bool = w.has("deposito")
	if johnny.huecos.fuego == id:
		return johnny.deposito if deposito else float(johnny.balas)
	return float(johnny.cargadores.get(id, w.get("deposito", w.cargador)))


# Lo que se ve en la esquina de la casilla de un arma de fuego: «8/12» o, las de depósito, «6 s» ("" las de cuerpo a
# cuerpo)
func carga_corta(id: String) -> String:
	var w: Dictionary = Armas.datos(id)
	if w.tipo != "fuego":
		return ""
	if w.has("deposito"):
		return "%d s" % ceili(carga(id))
	return "%d/%d" % [roundi(carga(id)), w.cargador]


# ── Inventario: la ficha ──

# La ficha de lo elegido, a la derecha, con sus botones debajo, y la línea de ayuda de abajo (con lo que hacen X e Y
# con lo elegido). Es lo que cambia al moverse la marca: se quita la de antes (ya, para que no haya dos «nota») y se
# pinta la nueva. En el baúl, la suya (pintar_ficha_baul)
func pintar_ficha() -> void:
	if abierto == "baul":
		pintar_ficha_baul()
		return
	if viva:
		lienzo.remove_child(viva)
		viva.queue_free()
	viva = Control.new()
	viva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(viva)
	marco_ficha(viva, Rect2(650, 92, 246, 492))
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	caja.custom_minimum_size.x = ANCHO_FICHA
	viva.add_child(caja)
	caja.position = Vector2(662, 104) - ORIGEN
	asegurar_sel()
	# lo de cada cosa: la cabeza de la ficha y lo de debajo, lo que hace ("que") y sus botones ([nombre, texto, al
	# pulsar, apagado])
	var i := sel.substr(1).to_int()
	var lz: Lanzables = partida.lanzables
	var d: Dictionary
	match sel[0]:
		"p": d = ficha_arma(caja, partida.johnny.huecos["cuerpo" if i == 0 else "fuego"], true)
		"g": d = ficha_arma(caja, partida.armas_guardadas[i], false)
		"m": d = ficha_objeto(caja, Objetos.casillas(partida.mochila)[i])
		"u": d = ficha_municion(caja, partida.johnny.huecos_municion()[i])
		"l": d = ficha_lanzable(caja, lz.mano[i], true)
		_: d = ficha_lanzable(caja, lz.repuesto[i], false)
	espacio(caja, 8)
	var nota := renglon(caja, d.que if aviso == "" else aviso, Tema.TINTA if aviso == "" else Tema.AMARILLO,
		HORIZONTAL_ALIGNMENT_LEFT)
	nota.name = "nota"   # (las pruebas la leen)
	aviso = ""
	# los botones, abajo del todo; el principal, con las letras amarillas
	var botones := VBoxContainer.new()
	botones.add_theme_constant_override("separation", 4)
	botones.custom_minimum_size.x = 214
	viva.add_child(botones)
	var atajos := {}   # lo que hacen X e Y con lo elegido, para la línea de ayuda
	for b in d.botones:
		var pulsar := boton(botones, b[0], b[1], b[2], "BotonRojo" if b[0] == "tirar" else "")
		pulsar.disabled = b[3]
		if b[0] in PRINCIPALES:
			for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				pulsar.add_theme_color_override(c, Tema.AMARILLO)
		if not b[3]:
			atajos["X" if b[0] == "tirar" else "Y"] = "tirar" if b[0] == "tirar" else b[1].to_lower()
	botones.position = Vector2(666, 578 - botones.get_combined_minimum_size().y) - ORIGEN
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
# cerrar) y, a la derecha, que también va con el ratón o el dedo
func pintar_ayuda(atajos: Dictionary) -> void:
	var ayuda := HBoxContainer.new()
	ayuda.add_theme_constant_override("separation", 5)
	viva.add_child(ayuda)
	ayuda.position = Vector2(64, 590) - ORIGEN
	var partes := [["A", "elegir"]]
	for k in ["X", "Y"]:
		if k in atajos:
			partes.append([k, atajos[k]])
	partes.append(["B", "cerrar"])
	for p in partes:
		ayuda.add_child(tecla(p[0]))
		var t := Label.new()
		t.text = p[1]
		t.add_theme_color_override("font_color", Tema.GRIS)
		ayuda.add_child(t)
		var hueco := Control.new()
		hueco.custom_minimum_size.x = 11
		ayuda.add_child(hueco)
	rotulo(viva, "Ratón o dedo: tocar o arrastrar", 896, 591, Tema.GRIS, HORIZONTAL_ALIGNMENT_RIGHT)


# Lo de arriba de la ficha: el dibujo grande, el nombre y, debajo, qué es
func cabeza(caja: VBoxContainer, icono: String, nombre: String, que_es: String) -> void:
	var grande := Panel.new()
	grande.custom_minimum_size = Vector2(108, 108)
	grande.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grande.add_theme_stylebox_override("panel", estilo(Tema.AMARILLO, false, false))
	caja.add_child(grande)
	dibujo(grande, icono, Vector2(108, 108), 12.0)
	espacio(caja, 4)
	renglon(caja, nombre, Color("#e6dec8")).theme_type_variation = "Titulo"
	renglon(caja, que_es, Tema.GRIS)


# La ficha de un arma ("puesta": la de la mano; si no, la de repuesto): si es de fuego, lo que le queda en el cargador
# (con sus balitas) y en la reserva; las barras, lo que hace y sus botones. La de la mano se puede tirar si lleva otra de
# repuesto (que pasa a la mano)
func ficha_arma(caja: VBoxContainer, id: String, puesta: bool) -> Dictionary:
	var johnny: Node2D = partida.johnny
	var w: Dictionary = johnny.arma_de(id)
	cabeza(caja, Objetos.icono(id), Objetos.nombre(id), "%s · %s" % [Armas.HUECOS[w.tipo],
		"En la mano" if puesta else "De repuesto"])
	if w.tipo == "fuego":
		var tipo := Armas.municion(id)
		espacio(caja, 4)
		if w.has("deposito"):
			renglon(caja, "Depósito: %d de %d s" % [ceili(carga(id)), roundi(w.deposito)], Tema.TINTA)
		else:
			balitas(caja, tipo, roundi(carga(id)), w.cargador)
			renglon(caja, "Cargador %d de %d" % [roundi(carga(id)), w.cargador], Tema.TINTA)
		renglon(caja, "Reserva: %d %s" % [johnny.cuanta(tipo), RESERVA[tipo]], Tema.GRIS)
	espacio(caja, 8)
	for b in barras(w):
		barra(caja, b[0], b[1])
	var que: String = QUE_HACE.get(id, "")
	if not puesta:
		return {"que": que, "botones": [["poner", "Ponérmela", poner_guardada, false], ["tirar", "Tirar al suelo", tirar, false]]}
	var otra: String = partida.repuesto(w.tipo)
	if otra != "":
		que += " Si la tiras, la de repuesto pasa a la mano."
	return {"que": que, "botones": [["tirar", "Tirar al suelo", tirar, otra == ""]]}


# Las barras de la ficha de un arma, de 1 a 10 (con los talentos y la skin ya contados: johnny.arma_de): cuánto pega
# cada golpe (o cada segundo, las de depósito), lo rápido que ataca, hasta dónde llega y lo rápido que recarga; las de
# cuerpo a cuerpo, en vez de recargar, lo ancho que barren. La barra llena: 40 de daño, 8 ataques por segundo, el
# alcance del bate (cuerpo a cuerpo) o de la pistola, y el barrido de la fregona
func barras(w: Dictionary) -> Array:
	var lista := [["Daño", w.dano * w.get("perdigones", 1) / 4.0],
		["Ritmo", 10.0 if w.has("deposito") else w.ritmo / 0.8]]
	if w.tipo == "cuerpo":
		lista.append(["Alcance", w.alcance / 7.0])
		lista.append(["Barrido", w.arco / 14.0])
	else:
		lista.append(["Alcance", w.alcance / 42.0])
		lista.append(["Recarga", 10.0 - w.recarga * (w.cargador if w.cartucho else 1) * 3.0])   # (la escopeta, uno a uno)
	return lista.map(func(b): return [b[0], clampi(ceili(b[1]), 1, 10)])


# Una barra de la ficha: su nombre y 10 cuadraditos, llenos los que diga "valor"
func barra(caja: VBoxContainer, nombre: String, valor: int) -> void:
	var hilera := HBoxContainer.new()
	hilera.add_theme_constant_override("separation", 0)
	caja.add_child(hilera)
	var t := Label.new()
	t.text = nombre
	t.custom_minimum_size.x = 96
	hilera.add_child(t)
	var cuadros := Control.new()
	cuadros.custom_minimum_size = Vector2(109, 9)
	cuadros.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cuadros.draw.connect(func():
		for i in 10:
			var r := Rect2(i * 11, 0, 8, 9)
			cuadros.draw_rect(r, Tema.AMARILLO if i < valor else Color("#332e3a"))
			cuadros.draw_rect(r, Tema.LINEA, false, 1.0))
	hilera.add_child(cuadros)


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
# decía para qué recetas del banco de trabajo servía)
func ficha_objeto(caja: VBoxContainer, c: Array) -> Dictionary:
	var id: String = c[0]
	var curar := id in Objetos.USABLES
	cabeza(caja, Objetos.icono(id), Objetos.nombre(id), "Para curar" if curar else "Objeto · Común")
	if c[1] > 1:
		renglon(caja, "Llevas %d" % c[1], Tema.TINTA)
	if curar:
		return {"que": "Te cura %d de vida. Si no lo usas, se pierde al acabar la partida (no va al baúl)." % partida.cura_de(id),
			"botones": [["usar", "Usar", usar, false], ["tirar", "Tirar al suelo", tirar, false]]}
	return {"que": "Si caes, se pierde (en el baúl queda a salvo).",
		"botones": [["tirar", "Tirar al suelo", tirar, false]]}


# La ficha de un hueco de munición ([tipo, cuánta]): cuánta lleva y quién la gasta. La gasolina, el ácido y las
# baterías se tiran de uno en uno; las balas, el hueco entero en una caja
func ficha_municion(caja: VBoxContainer, h: Array) -> Dictionary:
	var tipo: String = h[0]
	var m: Dictionary = Armas.MUNICION[tipo]
	cabeza(caja, m.icono, m.nombre, "Munición")
	renglon(caja, "%d en este hueco · llevas %d" % [h[1], partida.johnny.cuanta(tipo)], Tema.TINTA)
	var que := "La gastan %s (caben %d en cada hueco). Al tirarlo, el hueco entero se queda en el suelo en una caja." % [
		m.para, m.hueco]
	if tipo in Objetos.NOMBRES:   # la gasolina, el bidón de ácido y la batería
		que = "Llena %s (caben %d en cada hueco). Se tira de uno en uno." % [m.para, m.hueco]
	return {"que": que, "botones": [["tirar", "Tirar al suelo", tirar, false]]}


# La ficha de un arrojable ("a_mano": de los de la mano; si no, de repuesto): cuántos quedan y lo que hace; se pasa de
# la mano al repuesto y al revés (no se tiran)
func ficha_lanzable(caja: VBoxContainer, k: String, a_mano: bool) -> Dictionary:
	var lz: Lanzables = partida.lanzables
	cabeza(caja, icono_lanzable(k), nombre_lanzable(k), "Arrojable · %s" % ("A mano" if a_mano else "De repuesto"))
	renglon(caja, "Te quedan %d de %d" % [lz.cuantas(k), lz.maximo(k)], Tema.TINTA)
	var que: String = QUE_HACE[k]
	if a_mano:
		que += " Es lo que lanzas ahora." if k == lz.tipo else " Con F lo eliges para lanzarlo."
		return {"que": que, "botones": [["al_repuesto", "Al repuesto", mover_lanzable, lz.repuesto.size() >= Lanzables.REPUESTO]]}
	if lz.mano.size() >= Lanzables.MANO:
		que += " «A la mano» lo cambia por %s, que pasa aquí." % nombre_lanzable(lz.tipo).to_lower()
	return {"que": que, "botones": [["a_la_mano", "A la mano", mover_lanzable, false]]}


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
	if abierto in ["inventario", "baul"] and sel != clave and not moviendo_marca and is_instance_valid(lienzo) \
			and lienzo.is_ancestor_of(b):
		elegir(clave)


# El botón de la ficha que hace lo suyo con lo elegido («Ponérmela», «Usar», «A la mano» o «Al repuesto»; en el baúl,
# «Guardar en el baúl» o «Sacar»; no «Tirar al suelo»), si se puede pulsar
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


# Pasa el arrojable elegido de la mano al repuesto o al revés (lanzables.gd); la ficha sigue con él, en su sitio nuevo.
# Con "por" (soltándolo encima de otro), cambia con ese. Lo que cambia de sitio da un saltito
func mover_lanzable(por := "") -> void:
	var lz: Lanzables = partida.lanzables
	var i := sel.substr(1).to_int()
	var k := ""
	var otro := ""   # el que pasa al otro lado al cambiarse
	if sel.begins_with("e") and i < lz.repuesto.size():
		k = lz.repuesto[i]
		var antes := lz.repuesto.size()
		lz.a_la_mano(k, por)
		if lz.repuesto.size() == antes:
			otro = lz.repuesto[i]
	elif sel.begins_with("l") and i < lz.mano.size() and por in lz.repuesto:
		k = lz.mano[i]
		otro = por
		lz.a_la_mano(por, k)
	elif sel.begins_with("l") and i < lz.mano.size() and lz.repuesto.size() < Lanzables.REPUESTO:
		k = lz.mano[i]
		lz.al_repuesto(k)
	else:
		Sonido.tocar("no")
		return
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	sel = "l%d" % lz.mano.find(k) if k in lz.mano else "e%d" % lz.repuesto.find(k)
	salta = [sel]
	if otro != "":
		salta.append("l%d" % lz.mano.find(otro) if otro in lz.mano else "e%d" % lz.repuesto.find(otro))
	foco = sel
	pintar()


# El borde de la casilla de un arma: gris (hasta el 25 oct, las creadas en el banco llevaban el color de su rareza)
func borde(_id: String) -> Color:
	return GRIS


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
	aviso = "Te has curado %d de vida." % partida.cura_de(id)
	salta_johnny = true
	foco = ""
	pintar()


# Se pone en la mano el arma de repuesto elegida; la que llevaba (de su mismo tipo) pasa al repuesto. La ficha enseña
# la que se acaba de poner; las dos dan un saltito, y Johnny también
func poner_guardada() -> void:
	var i := sel.substr(1).to_int()
	var guardadas: Array = partida.armas_guardadas
	if not sel.begins_with("g") or i >= guardadas.size():
		return
	var johnny: Node2D = partida.johnny
	var id: String = guardadas[i]
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
# otra de repuesto, que pasa a la mano) o munición (la gasolina, los bidones de ácido y las baterías, de uno en uno; las balas, todas
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
	elif sel.begins_with("g"):
		var id: String = partida.armas_guardadas[i]
		partida.armas_guardadas.remove_at(i)
		partida.soltar_arma(id, suelo)
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
		partida.soltar_arma(id, suelo)
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
# arrojables a mano (para verlos: no van al baúl) y, en filas de 8, los objetos, la munición y los arrojables de
# repuesto. A la derecha, las casillas del baúl: los objetos guardados (hasta el 25 oct, también las armas creadas en
# el banco de trabajo). Abajo, la ficha de lo elegido con su botón, «Guardar en el baúl» o «Sacar uno». Al moverse la
# marca solo se vuelve a pintar la ficha (pintar_ficha_baul)

const MITAD := 476.0          # donde empieza la mitad del baúl
const ANCHO_NOTA := 380.0     # lo ancho que es el texto de la ficha del baúl


func pintar_baul(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	asegurar_sel()
	preparar_lienzo(columna)
	rotulo(lienzo, "Baúl", 480, 26, Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER).theme_type_variation = "Titulo"
	# a la izquierda, lo que lleva: arriba sus armas (de cada tipo, la de la mano y la de repuesto) y los arrojables a
	# mano; debajo, los objetos, la munición y los arrojables de repuesto
	rotulo(lienzo, "Lo que llevas", 64, 86, Color("#e6dec8"))
	rotulo(lienzo, "Armas", 64, 110, Tema.AMARILLO)
	rotulo(lienzo, "Arrojables", en_fila(5, 0).position.x, 110, Tema.AMARILLO)
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
	rotulo(lienzo, "Objetos  %d / %d" % [llenas.size(), Objetos.MOCHILA], 64, 182, Tema.AMARILLO)
	for i in Objetos.MOCHILA:
		if i < llenas.size():
			var n: int = llenas[i][1]
			casilla_inv(en_fila(i, 204), "m%d" % i, Objetos.icono(llenas[i][0]), "×%d" % n if n > 1 else "", GRIS, 8.0)
		else:
			casilla_inv(en_fila(i, 204))
	var balas: Array = johnny.huecos_municion()
	rotulo(lienzo, "Munición  %d / %d" % [balas.size(), Armas.HUECOS_MUNICION], 64, 254, Tema.AMARILLO)
	rotulo(lienzo, "las balas no van al baúl", 428, 254, Tema.GRIS, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in Armas.HUECOS_MUNICION:
		if i < balas.size():
			casilla_inv(en_fila(i, 276), "u%d" % i, Armas.MUNICION[balas[i][0]].icono, str(balas[i][1]), GRIS, 8.0)
		else:
			casilla_inv(en_fila(i, 276))
	rotulo(lienzo, "Arrojables de repuesto  %d / %d" % [lz.repuesto.size(), Lanzables.REPUESTO], 64, 326, Tema.AMARILLO)
	for i in Lanzables.REPUESTO:
		arrojable(en_fila(i, 348), "e%d" % i, lz.repuesto[i] if i < lz.repuesto.size() else "", 8.0)
	raya(Rect2(452, 92, 2, 298))
	# las dos mitades, para arrastrar de una a otra (guardar y sacar)
	sitio("llevas", Rect2(52, 80, 394, 316))
	sitio("baul", Rect2(MITAD - 8, 80, 428, 316))
	# a la derecha, el baúl: los objetos, con cuántos hay. Si pasa de 32 (al completar el edificio, lo de la mochila
	# entra aunque no quepa), las casillas se hacen más pequeñas para que quepan todas
	var objetos := objetos_baul(s)
	var filas := maxi(ceili(Objetos.BAUL / 8.0), ceili(objetos.size() / 8.0))
	var paso := mini(52, floori(264.0 / filas))
	rotulo(lienzo, "Baúl  %d / %d" % [Objetos.casillas_baul(s), Objetos.BAUL], MITAD, 86, Color("#e6dec8"))
	rotulo(lienzo, "Objetos guardados", MITAD, 110, Tema.GRIS)
	for i in filas * 8:
		var r := Rect2(MITAD + (i % 8) * paso, 132 + floori(i / 8.0) * paso, paso - 6, paso - 6)
		if i < objetos.size():
			var o: Array = objetos[i]
			casilla_inv(r, "b%d" % i, Objetos.icono(o[0]), str(o[1]), GRIS, 8.0)
		else:
			casilla_inv(r)
	if filas * 8 == Objetos.BAUL:
		rotulo(lienzo, "Aquí no se pierde nada aunque caigas.", MITAD, 346,
			Tema.GRIS, HORIZONTAL_ALIGNMENT_LEFT, 418)
	# abajo, el marco de la ficha y los botones que no cambian con lo elegido (el principal va con la ficha)
	marco_ficha(lienzo, Rect2(64, 402, 832, 182))
	var todo := boton(lienzo, "guardar_todo", "Guardar todo", guardar_todo)
	todo.disabled = not guardables().any(func(id): return Objetos.cabe_baul(s, id))   # (apagado si no cabe nada)
	todo.position = Vector2(600, 464) - ORIGEN
	todo.size = Vector2(280, 38)
	var salir := boton(lienzo, "cerrar", "Cerrar", cerrar)
	salir.position = Vector2(600, 538) - ORIGEN
	salir.size = Vector2(280, 38)
	pintar_ficha()
	return lienzo.find_child(sel, false, false)


# El sitio de la casilla i de una fila de 8 de lo que lleva (a la izquierda del baúl) que empieza en "y"
func en_fila(i: int, y: float) -> Rect2:
	return Rect2(64 + i * 46, y, 42, 42)


# Los objetos del baúl, en el orden de Objetos.NOMBRES: [[id, cuántos], ...]
func objetos_baul(s: Dictionary) -> Array:
	var lista := []
	for id in Objetos.NOMBRES:
		if s.baul.get(id, 0) > 0:
			lista.append([id, int(s.baul[id])])
	return lista


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
	renglon(caja, d.que_es, Tema.GRIS, HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	if d.cuanto != "":
		renglon(caja, d.cuanto, Tema.TINTA, HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	espacio(caja, 6)
	var nota := renglon(caja, d.que if aviso == "" else aviso, Tema.TINTA if aviso == "" else Tema.AMARILLO,
		HORIZONTAL_ALIGNMENT_LEFT, ANCHO_NOTA)
	nota.name = "nota"   # (las pruebas la leen)
	aviso = ""
	var atajos := {}
	if not d.boton.is_empty():
		var b := boton(viva, d.boton[0], d.boton[1], d.boton[2])
		b.disabled = d.boton[3]
		for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(c, Tema.AMARILLO)
		b.position = Vector2(600, 418) - ORIGEN
		b.size = Vector2(280, 40)
		if not b.disabled:
			atajos["Y"] = d.boton[1].to_lower()
	pintar_ayuda(atajos)


# Lo que dice la ficha de lo elegido en el baúl: el dibujo, el nombre, qué es, cuántos, lo que hace o lo que pasa al
# guardarlo o sacarlo ("que") y su botón ([nombre, texto, al pulsar, apagado], o ninguno). Las armas y los arrojables
# que lleva no van al baúl; lo de la mochila y la munición que también es un objeto (la gasolina, el bidón de
# ácido...), sí; del baúl se sacan los objetos, de uno en uno
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
			d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id),
				"que_es": "%s · %s" % [Armas.HUECOS[w.tipo], "En la mano" if sel[0] == "p" else "De repuesto"],
				"que": que_hace(id) + " Las armas no van al baúl."}, true)
			if w.tipo == "fuego":
				d.cuanto = "%s · reserva %d" % ["Depósito %d de %d s" % [ceili(carga(id)), roundi(w.deposito)]
					if w.has("deposito") else "Cargador %d de %d" % [roundi(carga(id)), w.cargador],
					johnny.cuanta(Armas.municion(id))]
		"l", "e":
			var k: String = lz.mano[i] if sel[0] == "l" else lz.repuesto[i]
			d.merge({"icono": icono_lanzable(k), "nombre": nombre_lanzable(k),
				"que_es": "Arrojable · %s" % ("A mano" if sel[0] == "l" else "De repuesto"),
				"cuanto": "Te quedan %d de %d" % [lz.cuantas(k), lz.maximo(k)],
				"que": que_hace(k) + " Los arrojables no van al baúl."}, true)
		"m":
			var c: Array = Objetos.casillas(partida.mochila)[i]
			var id: String = c[0]
			d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id),
				"que_es": "%s · En la mochila" % ("Objeto" if Objetos.al_baul(id) else "Para curar"),
				"cuanto": "Llevas %d" % c[1] if c[1] > 1 else ""}, true)
			if Objetos.al_baul(id):
				d.que = que_guardar(s, id, c[1], "esta casilla")
				d.boton = ["guardar", "Guardar en el baúl", guardar, not Objetos.cabe_baul(s, id)]
			else:
				d.que = "Lo de curar no va al baúl: úsalo en la partida, porque al acabarla se pierde."
		"u":
			var h: Array = johnny.huecos_municion()[i]
			var m: Dictionary = Armas.MUNICION[h[0]]
			d.merge({"icono": m.icono, "nombre": m.nombre, "que_es": "Munición · La llevas",
				"cuanto": "%d en este hueco · llevas %d" % [h[1], johnny.cuanta(h[0])]}, true)
			if h[0] in Objetos.NOMBRES:   # la gasolina, el bidón de ácido...
				d.que = "Llena %s. %s" % [m.para, que_guardar(s, h[0], h[1], "este hueco")]
				d.boton = ["guardar", "Guardar en el baúl", guardar, not Objetos.cabe_baul(s, h[0])]
			else:
				d.que = "No va al baúl: es la munición de %s y se queda contigo." % m.para
		"b":
			var o: Array = objetos_baul(s)[i]
			var id: String = o[0]
			var municion: bool = id in Armas.MUNICION
			var cabe: bool = johnny.sitio(id) > 0 if municion else Objetos.cabe(partida.mochila, id)
			d.merge({"icono": Objetos.icono(id), "nombre": Objetos.nombre(id),
				"que_es": "%s · En el baúl" % ("Munición" if municion else "Objeto"), "cuanto": "Hay %d en el baúl" % o[1],
				"boton": ["sacar", "Sacar uno", sacar, not cabe]}, true)
			d.que = "Llena %s. " % Armas.MUNICION[id].para if municion else ""
			if cabe:
				d.que += "Sale de uno en uno a tu %s; fuera del baúl, se pierde si caes." % ("munición" if municion else "mochila")
			else:
				d.que += "No te cabe: tienes %s." % ("llenos los huecos de munición" if municion else "la mochila llena")
	return d


# Lo que hace un arma (por su id) o un arrojable (por su tipo): lo de QUE_HACE
func que_hace(id: String) -> String:
	return QUE_HACE.get(id, "")


# Lo que pasa al guardar en el baúl los "n" de esa casilla o hueco (o, con el baúl lleno, por qué no se puede)
func que_guardar(s: Dictionary, id: String, n: int, donde: String) -> String:
	if not Objetos.cabe_baul(s, id):
		return "El baúl está lleno: solo caben más de lo que ya tiene. Haz sitio sacando algo."
	if n > 1:
		return "Se guardan los %d de %s, y en el baúl quedan a salvo aunque caigas." % [n, donde]
	return "En el baúl queda a salvo aunque caigas."


# ── Baúl: guardar y sacar ──

# Saca del baúl lo elegido: un objeto, uno (sacar_objeto). Hasta el 25 oct, también las armas creadas en el banco
func sacar() -> void:
	var i := sel.substr(1).to_int()
	var objetos := objetos_baul(Guardado.cargar())
	if sel.begins_with("b") and i < objetos.size():
		sacar_objeto(objetos[i][0])


# Saca del baúl uno de ese objeto: a la mochila o, si es munición (la gasolina, el bidón de ácido...), a sus huecos (y
# si el arma que la gasta está vacía, se carga). Si no cabe, no sale. La marca se queda en «Sacar uno» mientras queden:
# con el mando, A, A, A... y salen de uno en uno
func sacar_objeto(id: String) -> void:
	var johnny: Node2D = partida.johnny
	var municion: bool = id in Armas.MUNICION
	if not (johnny.sitio(id) > 0 if municion else Objetos.cabe(partida.mochila, id)):
		Sonido.tocar("no")
		return
	Guardado.cambiar(func(g):
		g.baul[id] -= 1
		if g.baul[id] <= 0:
			g.baul.erase(id))
	partida.mochila.append(id)
	if municion:
		johnny.coger_municion(id)
		johnny.avisar_arma()
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	var i := sel.substr(1).to_int()
	var objetos := objetos_baul(Guardado.cargar())
	foco = "sacar" if i < objetos.size() and objetos[i][0] == id else sel
	salta = [donde_esta(id)]
	pintar()


# La casilla de lo que lleva donde está ese objeto: en la munición (el último hueco de los suyos) o en la mochila
func donde_esta(id: String) -> String:
	if id in Armas.MUNICION:
		var tipos: Array = partida.johnny.huecos_municion().map(func(h): return h[0])
		return "u%d" % tipos.rfind(id)
	return "m%d" % Objetos.casillas(partida.mochila).map(func(c): return c[0]).find(id)


# Guarda en el baúl lo de la casilla elegida: todos los de esa casilla de la mochila o de ese hueco de munición (la
# gasolina, el bidón de ácido...). La marca se queda en la misma casilla, que ahora es la siguiente: con el mando o las
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
		if i < huecos.size() and huecos[i][0] in Objetos.NOMBRES:
			id = huecos[i][0]
			n = huecos[i][1]
	if not meter_en_baul(id, n):
		Sonido.tocar("no")
		return
	partida.johnny.avisar_arma()
	Sonido.tocar("soltar" if con_dedo else "cambiar")
	salta = ["b%d" % objetos_baul(Guardado.cargar()).map(func(o): return o[0]).find(id)]
	foco = sel
	pintar()


# Los objetos distintos de la mochila que pueden ir al baúl (todos menos los de curar; también la munición que es un
# objeto: la gasolina, el bidón de ácido...)
func guardables() -> Array:
	return Objetos.casillas(partida.mochila, true).map(func(c): return c[0]).filter(func(id): return Objetos.al_baul(id))


# Guarda en el baúl todo lo de la mochila que se pueda; lo que no cabe (con el baúl lleno) se queda, y se dice
func guardar_todo() -> void:
	var guardados := 0
	var no_caben := []
	for id in guardables():
		if meter_en_baul(id):
			guardados += 1
		else:
			no_caben.append(Objetos.nombre(id).to_lower())
	Sonido.tocar("cambiar" if guardados > 0 else "no")
	if not no_caben.is_empty():
		aviso = "El baúl está lleno: en la mochila se quedan %s." % (", ".join(no_caben.slice(0, -1)) + " y " +
			no_caben[-1] if no_caben.size() > 1 else no_caben[0])
	partida.johnny.avisar_arma()
	sel = ""
	foco = ""
	pintar()


# Mete en el baúl "cuantos" de ese objeto de la mochila (0: todos), si puede ir (no es de curar) y cabe. Dice si lo ha
# hecho
func meter_en_baul(id: String, cuantos := 0) -> bool:
	if id == "" or not Objetos.al_baul(id) or not Objetos.cabe_baul(Guardado.cargar(), id):
		return false
	var mochila: Array = partida.mochila
	var n := mochila.count(id) if cuantos <= 0 else mini(cuantos, mochila.count(id))
	for k in n:
		mochila.remove_at(mochila.rfind(id))
	Guardado.cambiar(func(s): s.baul[id] = s.baul.get(id, 0) + n)
	return true


# ── Inventario y baúl: arrastrar ──
# Con el ratón o el dedo (la parte 5 del inventario nuevo): se aprieta en una casilla y, al mover un poco, lo de dentro
# se levanta y sigue al dedo, y su casilla se queda apagada (levantar; va con el arrastrar de Godot, así que el botón ya
# no cuenta como tocado). Se encienden los sitios donde se puede soltar (destinos): en el inventario, la mano o el
# repuesto de su tipo (las armas se cambian), Johnny (se pone el arma o usa la cura), los arrojables de la mano al
# repuesto y al revés (encima de otro, se cambian esos dos) y la ficha, que se vuelve la zona roja de tirar (la casilla
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
				if Objetos.al_baul(id) and Objetos.cabe_baul(s, id):
					d["baul"] = "guardar"
			"u":
				var tipo: String = johnny.huecos_municion()[i][0]
				if tipo in Objetos.NOMBRES and Objetos.cabe_baul(s, tipo):
					d["baul"] = "guardar"
			"b":
				var id: String = objetos_baul(s)[i][0]
				if (johnny.sitio(id) > 0 if id in Armas.MUNICION else Objetos.cabe(partida.mochila, id)):
					d["llevas"] = "sacar"
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
			for j in Lanzables.REPUESTO:
				d["e%d" % j] = "mover"
		"e":
			for j in Lanzables.MANO:
				d["l%d" % j] = "mover"
	return d


# La mano de un arma: 0 la de cuerpo a cuerpo y 1 la de distancia ("p0", "r1"...)
func mano_de(id: String) -> int:
	return 0 if Armas.datos(id).tipo == "cuerpo" else 1


# El sitio de donde sale lo de esa casilla: soltarlo ahí no es un error, solo vuelve
func propio(clave: String) -> String:
	if abierto == "baul":
		return "baul" if clave[0] == "b" else "llevas"
	match clave[0]:
		"g": return "r%d" % mano_de(partida.armas_guardadas[clave.substr(1).to_int()])
		"p", "l", "e": return clave
	return ""


# Enciende los sitios donde se puede soltar lo que se acaba de levantar y pone encima de todo la tapa: es la que
# recibe lo que se suelta (esté donde esté) y la que va mirando qué sitio hay bajo el dedo
func encender(clave: String) -> void:
	capa = Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(capa)
	var hay := destinos(clave)
	for s in sitios:
		if s[0] in hay:
			luz(s[0], s[1], hay[s[0]], clave)
	tapa = Control.new()
	tapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	tapa.set_drag_forwarding(Callable(), mirar, soltar)
	fondo.add_child(tapa)
	encima = ""


# Un sitio encendido, encima de lo suyo: una casilla, con un marco amarillo; Johnny, con un óvalo y lo que pasa
# («Ponérmela» o «Usar»); la ficha, la zona roja de tirar; y una mitad del baúl, con lo que pasa. Lleva dos estilos, el
# de siempre y el de cuando el dedo está encima (crecer)
func luz(nombre: String, r: Rect2, que: String, clave: String) -> void:
	var rojo := que == "tirar"
	var es_casilla := nombre.length() == 2
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
		"usar": cartel(p, ["Usar"], 0.0)
		"poner":
			if nombre == "johnny":
				cartel(p, ["Ponérmela"], 0.0)
		"guardar": cartel(p, ["Suelta aquí", "para guardarlo en el baúl"], r.size.y / 2.0 - 28.0)
		"sacar": cartel(p, ["Suelta aquí", "para sacar uno" if clave[0] == "b" else "para sacarla"], r.size.y / 2.0 - 28.0)


# La zona roja de tirar (encima de la ficha): una flecha que baja al suelo y lo que se tira, que se queda a tus pies
func zona_roja(p: Panel, clave: String) -> void:
	var rojo := Color("#d64541")
	var flecha := Control.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flecha.draw.connect(func():
		flecha.draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(14, 32), Vector2(30, 32),
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
	renglon(caja, "Suelta aquí", claro, HORIZONTAL_ALIGNMENT_CENTER, ancho).theme_type_variation = "Titulo"
	renglon(caja, "para tirarlo al suelo", claro, HORIZONTAL_ALIGNMENT_CENTER, ancho)
	espacio(caja, 18)
	renglon(caja, que_se_tira(clave), Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER, ancho)
	renglon(caja, "se queda a tus pies", Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER, ancho)
	if clave[0] == "p":
		renglon(caja, "y la de repuesto pasa a la mano", Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER, ancho)


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
			return "%d %s" % [h[1], RESERVA[h[0]]] if h[1] > 1 else Armas.MUNICION[h[0]].nombre
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
	var nuevo := sitio_en(en_lienzo(donde))
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


# El sitio que hay en ese punto del lienzo ("" ninguno)
func sitio_en(punto: Vector2) -> String:
	for s in sitios:
		if s[1].has_point(punto):
			return s[0]
	return ""


# Con el dedo encima, un sitio encendido se ilumina más y, si es una casilla, crece un poco (y al irse, vuelve)
func crecer(nombre: String, si: bool) -> void:
	if nombre == "" or not is_instance_valid(capa):
		return
	var marco: Panel = capa.get_node_or_null(NodePath("luz_" + nombre))
	if marco == null:
		return
	marco.add_theme_stylebox_override("panel", marco.get_meta("encima" if si else "normal"))
	if nombre.length() != 2:
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
	soltar_en.call_deferred(clave, sitio_en(en_lienzo(donde)), tapa.get_global_transform() * donde)


# Suelta lo de la casilla "clave" en el sitio "a_donde": si se puede, se hace lo mismo que con el botón de la ficha
# (sonando «soltar» en vez de «cambiar»); si no, vuelve a su casilla desde "punto" (donde se ha soltado). Las pruebas
# la llaman sin arrastrar
func soltar_en(clave: String, a_donde: String, punto := Vector2.INF) -> void:
	if clave == "" or not abierto in ["inventario", "baul"]:
		apagar()
		return
	var que: String = destinos(clave).get(a_donde, "")
	var mal := a_donde != "" and a_donde != propio(clave)
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
	con_dedo = false


# El arrojable que hay en ese sitio ("l1", "e3"; "" si está vacío)
func otro_lanzable(a_donde: String) -> String:
	var lz: Lanzables = partida.lanzables
	var lista: Array = lz.mano if a_donde[0] == "l" else lz.repuesto
	var i := a_donde.substr(1).to_int()
	return lista[i] if i < lista.size() else ""


# Apaga los sitios encendidos y quita la tapa (al soltar, o si se corta el arrastre)
func apagar() -> void:
	arrastre = {}
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


# ── Piezas ──

func boton(caja: Control, nombre: String, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.theme_type_variation = variacion
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


func estilo(borde: Color, elegida: bool, encima: bool) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color("#3a3226") if elegida else (Color("#26222e") if encima else FONDO_CASILLA)
	e.border_color = Tema.AMARILLO if elegida else borde
	e.set_border_width_all(3 if elegida else 2)
	e.set_corner_radius_all(3)
	return e


# Al tocar una casilla del inventario o del baúl: se elige y, si su ficha tiene un botón que hace lo suyo («Ponérmela», «Usar», «A la mano», «Al repuesto», «Guardar en el baúl»
# o «Sacar»), la marca salta a él (con el mando o las flechas, A dos veces y hecho)
func tocar(clave: String) -> void:
	Sonido.tocar("click")
	elegir(clave)
	var b: Control = principal()
	dar_foco.call_deferred(b if b else lienzo.find_child(sel, false, false))


# Esc, B del mando o (en el inventario) la misma tecla que lo abrió: cerrar. Va en _input porque Godot usa el
# Tabulador para pasar de un botón a otro y no llegaría. En el inventario y en el baúl, además, los atajos: Y hace lo
# del botón principal de la ficha y, en el inventario, F (o RB) cambia el arrojable que se lanza y X (o Supr) tira lo
# elegido
func _input(evento: InputEvent) -> void:
	if abierto == "":
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
