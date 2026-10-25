# Las pantallas de las cosas de Johnny (fase 7b; en el JS, showInventario y showBaul de src/ui.js y el banco
# de src/banco.js). El juego se para mientras están abiertas:
#   - Inventario (Tab, I o Select; «todo a la vista», la parte 3 del inventario nuevo): Johnny grande en medio, de
#     frente, con su skin y el arma que tiene en la mano; a los lados, sus armas (a la izquierda las de cuerpo a cuerpo
#     y a la derecha las de distancia; arriba la de la mano y abajo la de repuesto: partida.llevar_arma), y debajo, los
#     3 arrojables a mano (lanzables.gd). En medio, tres grupos de 8: la mochila, la munición (por tipos:
#     Armas.MUNICION) y los arrojables de repuesto. A la derecha, la ficha de lo elegido (qué es, el cargador, las
#     barras, qué hace o para qué receta sirve) y sus botones: "Ponérmela" (las de repuesto), "Usar" (lo de curar:
#     Objetos.USABLES), "A la mano" y "Al repuesto" (los arrojables) y "Tirar al suelo" (los objetos, la gasolina,
#     los bidones de ácido y las baterías, de uno en uno; las balas, el hueco entero en una caja; y las armas: la de la mano, solo si
#     lleva otra de repuesto, que pasa a la mano). Con las flechas o el mando, la ficha sigue a la marca; A (o tocar)
#     la lleva al botón principal de la ficha (A dos veces y hecho), X (o Supr) tira, Y hace lo del botón principal y F
#     cambia el arrojable que se lanza.
#   - Baúl (al arrimarse a él en la sala de mantenimiento): los objetos guardados de otras partidas y las armas
#     creadas en el banco. Un arma creada se puede sacar para esta partida (fase 7b2): la de cuerpo a cuerpo o
#     de fuego va a la mano (y la que llevaba, al repuesto o, si ya tiene una, al suelo); las arrojadizas, al botón
#     de lanzar.
#     Con «Guardar de la mochila» se ve la mochila: se toca una casilla y «Guardar» mete en el baúl todos los de
#     esa casilla (o «Guardar todo»), y ya no se pierden si Johnny cae. Lo de curar no se guarda (Objetos.al_baul) y,
#     con el baúl lleno, solo caben más de lo que ya tiene. Los objetos no se sacan del baúl: el banco los usa ahí.
#   - Banco de trabajo (al arrimarse a él): arriba, todas las recetas (recetas.gd). Las aprendidas son hojas de
#     papel con el dibujo del arma; las que no, un "?" (las sueltan los jefes). Al tocar una hoja se ve lo que
#     pide y cuántos tienes (en la mano, guardados, en la mochila y en el baúl) y, si está todo, se puede crear el
#     arma: sale con una rareza al azar, los ingredientes se gastan (los objetos, primero de la mochila) y el arma
#     va al baúl. Sin la receta no se puede crear.
# Van con el ratón, con flechas + Intro o con el mando (A elige, B cierra).
extends CanvasLayer

signal cerrado

const CASILLA := Vector2(108, 100)
const HOJA := Vector2(92, 88)               # una receta en el banco
const PAPEL := Color("#e8dcbc")              # las hojas de las recetas
const TINTA_PAPEL := Color("#3a3226")
const FONDO_CASILLA := Color("#1b1822")

var partida: Node
var fondo: ColorRect
var abierto := ""          # "inventario", "baul", "banco" o "" (nada)
var sel := ""              # la casilla elegida: "m2" la 3.ª de la mochila, "g0" la 1.ª arma guardada, "a1" la 2.ª arma del baúl,
                           # "u1" el 2.º hueco de munición, "l0" el 1.er arrojable a mano, "e3" el 4.º de repuesto,
                           # "p0" y "p1" las armas de la mano (la de cuerpo a cuerpo y la de distancia)
var receta := ""           # banco: la receta elegida (su id de Recetas.LISTA)
var hecha := {}            # banco: el arma que se acaba de crear (para enseñarla)
var foco := ""             # el botón que tiene que quedar marcado al volver a pintar
var aviso := ""            # inventario y baúl: lo que se dice abajo una vez (por qué no se puede usar o no cabe)
var guardando := false     # baúl: en vez del baúl, la mochila, para elegir lo que se guarda en él
var lienzo: Control        # inventario: donde va todo, cada cosa en su sitio
var viva: Control          # inventario: lo que cambia al moverse la marca (la ficha y la ayuda de abajo)
var huecos_inv: Array = [] # inventario: las casillas que se pueden elegir (para marcar la elegida)
var moviendo_marca := false   # la marca la está poniendo el juego (dar_foco), no el jugador


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego en pausa


func abrir(que: String, p: Node) -> void:
	partida = p
	abierto = que
	sel = ""
	receta = ""
	hecha = {}
	foco = ""
	aviso = ""
	guardando = false
	pintar(true)


func cerrar() -> void:
	if abierto == "":
		return
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
		"baul": primero = pintar_guardar(columna) if guardando else pintar_baul(columna)
		"banco": primero = pintar_banco(columna)
	# se queda marcado el mismo botón que antes (o el primero, si ya no está o se ha apagado)
	var marcado: Control = fondo.find_child(foco, true, false) if foco != "" else null
	if marcado == null or not marcado.focus_mode == Control.FOCUS_ALL or (marcado is BaseButton and marcado.disabled):
		marcado = primero
	if marcado:
		dar_foco.call_deferred(marcado)


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
# Lo que hace cada arma de la tienda, el molotov y la granada (las creadas, lo de su receta: Recetas.LISTA)
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
}
# Cómo se dice la munición de reserva en la ficha («Reserva: 2 gasolinas»)
const RESERVA := {"balas": "balas", "cartuchos": "cartuchos", "gasolina": "gasolinas",
	"bidon_acido": "bidones de ácido", "bateria": "baterías"}
const PRINCIPALES := ["poner", "usar", "a_la_mano", "al_repuesto"]   # los botones de la ficha que no son tirar


func pintar_inventario(columna: VBoxContainer) -> Control:
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	asegurar_sel()
	# el panel, sin márgenes por dentro: lo de dentro va cada cosa en su sitio
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
	rotulo(lienzo, "Inventario", 480, 26, Color("#e6dec8"), HORIZONTAL_ALIGNMENT_CENTER).theme_type_variation = "Titulo"
	# Johnny, grande, entre sus armas: a la izquierda las de cuerpo a cuerpo y a la derecha las de distancia (arriba
	# la de la mano y abajo la de repuesto)
	muneco(johnny)
	rotulo(lienzo, "Cuerpo a cuerpo", 64, 90, Tema.AMARILLO)
	rotulo(lienzo, "A distancia", 384, 90, Tema.AMARILLO, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in 2:
		var tipo: String = ["cuerpo", "fuego"][i]
		var x := 64.0 if i == 0 else 308.0
		var id: String = johnny.huecos[tipo]
		casilla_inv(Rect2(x, 122, 76, 76), "p%d" % i, Objetos.icono(id), carga_corta(id), borde(id))
		rotulo(lienzo, "En la mano", x + 38, 202, Tema.AMARILLO, HORIZONTAL_ALIGNMENT_CENTER)
		var otra: String = partida.repuesto(tipo)
		if otra != "":
			casilla_inv(Rect2(x, 232, 76, 76), "g%d" % partida.armas_guardadas.find(otra), Objetos.icono(otra),
				carga_corta(otra), borde(otra))
		else:
			casilla_inv(Rect2(x, 232, 76, 76))
		rotulo(lienzo, "De repuesto", x + 38, 312, Tema.GRIS, HORIZONTAL_ALIGNMENT_CENTER)
	# debajo, los arrojables a mano (F cambia entre ellos): el que se lanza ahora, con un marco amarillo alrededor
	rotulo(lienzo, "Arrojables", 64, 350, Tema.AMARILLO)
	rotulo(lienzo, "F cambia", 384, 350, Tema.GRIS, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in Lanzables.MANO:
		var x := 82.0 + i * 102
		var k: String = lz.mano[i] if i < lz.mano.size() else ""
		arrojable(Rect2(x, 380, 84, 84), "l%d" % i, k)
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
	var raya := ColorRect.new()
	raya.color = Color("#3d3647")
	raya.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(raya)
	raya.position = Vector2(393, 92) - ORIGEN
	raya.size = Vector2(2, 492)
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
		arrojable(rejilla(i, 416), "e%d" % i, lz.repuesto[i] if i < lz.repuesto.size() else "")
	var seguir := boton(lienzo, "cerrar", "Seguir", cerrar)
	seguir.position = Vector2(406, 544) - ORIGEN
	seguir.size = Vector2(226, 38)
	pintar_ficha()
	return lienzo.find_child(sel, false, false)


# El sitio de la casilla i de un grupo de 8 (4 por fila) que empieza en "y"
func rejilla(i: int, y: float) -> Rect2:
	return Rect2(406 + (i % 4) * (LADO + 6), y + floori(i / 4.0) * (LADO + 6), LADO, LADO)


# Si lo elegido ya no está (o no hay nada elegido), se elige el arma que tiene en la mano: la ficha nunca está vacía
func asegurar_sel() -> void:
	if not existe(sel):
		sel = "p0" if partida.johnny.mano == "cuerpo" else "p1"


# ¿Hay algo en esa casilla del inventario?
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
	return false


# Johnny grande (× 4) en medio, con su sombra: de frente y respirando, con su skin y el arma que tiene en la mano
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


# Una casilla del inventario en su sitio (en coordenadas de la pantalla): su dibujo, lo más grande que quepa, y abajo
# a la derecha cuántos. Sin "clave", vacía (no se elige). Al llegarle la marca (flechas o mando), la ficha enseña lo suyo
func casilla_inv(r: Rect2, clave := "", icono := "", cuenta := "", color := Recetas.GRIS) -> void:
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
		huecos_inv.append(b)
		marcar_hueco(b)
		c = b
	lienzo.add_child(c)
	c.position = r.position - ORIGEN
	c.size = r.size
	if icono != "":
		dibujo(c, icono, r.size, 12.0)
	if cuenta != "":
		var t := Label.new()
		t.text = cuenta
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		t.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(t)
		t.size = r.size - Vector2(5, 1)


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
func dibujo(padre: Control, icono: String, lado: Vector2, margen: float) -> void:
	var tex: Texture2D = load("res://assets/ui/iconos/%s.png" % icono)
	var k := maxi(1, floori(minf((lado.x - margen) / tex.get_width(), (lado.y - margen) / tex.get_height())))
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(r)
	r.size = tex.get_size() * k
	r.position = ((lado - r.size) / 2.0).floor()


# La casilla de un arrojable ("" la deja vacía): su dibujo y cuántos quedan (el molotov y la granada, de su máximo),
# con el borde del color de su rareza si es creado
func arrojable(r: Rect2, clave: String, k: String) -> void:
	if k == "":
		casilla_inv(r)
		return
	var lz: Lanzables = partida.lanzables
	var cuenta := "%d/%d" % [lz.cuantas(k), lz.maximo(k)] if k in Lanzables.DATOS else str(lz.cuantas(k))
	var rareza := rareza_lanzable(k)
	casilla_inv(r, clave, icono_lanzable(k), cuenta, Recetas.RAREZAS[rareza].color if rareza != "" else Recetas.GRIS)


func nombre_lanzable(k: String) -> String:
	return {"molotov": "Molotov", "granada": "Granada"}[k] if k in Lanzables.DATOS else Recetas.LISTA[k].nombre


func icono_lanzable(k: String) -> String:
	return k if k in Lanzables.DATOS else Recetas.icono_de(k)


# La rareza de un arrojable creado (la del que se lanza primero; "" el molotov y la granada)
func rareza_lanzable(k: String) -> String:
	for a in partida.lanzables.creadas:
		if a.receta == k:
			return a.rareza
	return ""


# Lo que le queda a un arma de fuego que lleva: en el cargador (balas) o, las de depósito, en el depósito (segundos).
# La de la mano, lo de ahora; la de repuesto, lo que le quedaba al dejarla (johnny.coger) o, si no la ha llevado
# nunca en la mano, lleno
func carga(id: String) -> float:
	var johnny: Node2D = partida.johnny
	var w: Dictionary = Armas.datos(id)
	var deposito: bool = w.has("deposito")
	if johnny.huecos.fuego == id:
		return johnny.deposito if deposito else float(johnny.balas)
	if Armas.es_creada(id):
		return float(Armas.sacadas[id].get("deposito" if deposito else "balas", w.get("deposito", w.cargador)))
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
# pinta la nueva
func pintar_ficha() -> void:
	if viva:
		lienzo.remove_child(viva)
		viva.queue_free()
	viva = Control.new()
	viva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(viva)
	var marco := Panel.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color("#141119")
	e.border_color = Color("#3d3647")
	e.set_border_width_all(2)
	e.set_corner_radius_all(4)
	marco.add_theme_stylebox_override("panel", e)
	viva.add_child(marco)
	marco.position = Vector2(650, 92) - ORIGEN
	marco.size = Vector2(246, 492)
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
	# la ayuda de abajo: los botones del mando
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
	rotulo(viva, "Ratón o dedo: tocar", 896, 591, Tema.GRIS, HORIZONTAL_ALIGNMENT_RIGHT)


# Lo de arriba de la ficha: el dibujo grande (con el borde del color de su rareza, si la tiene), el nombre y, debajo,
# qué es (y su rareza)
func cabeza(caja: VBoxContainer, icono: String, nombre: String, que_es: String, rareza := "") -> void:
	var grande := Panel.new()
	grande.custom_minimum_size = Vector2(108, 108)
	grande.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grande.add_theme_stylebox_override("panel", estilo(Recetas.RAREZAS[rareza].color if rareza != "" else Tema.AMARILLO,
		false, false))
	caja.add_child(grande)
	dibujo(grande, icono, Vector2(108, 108), 12.0)
	espacio(caja, 4)
	renglon(caja, nombre, Color("#e6dec8")).theme_type_variation = "Titulo"
	renglon(caja, que_es, Tema.GRIS)
	if rareza != "":
		renglon(caja, Recetas.RAREZAS[rareza].nombre, Recetas.RAREZAS[rareza].color)


# La ficha de un arma ("puesta": la de la mano; si no, la de repuesto): si es de fuego, lo que le queda en el cargador
# (con sus balitas) y en la reserva; las barras, lo que hace y sus botones. La de la mano se puede tirar si lleva otra de
# repuesto (que pasa a la mano)
func ficha_arma(caja: VBoxContainer, id: String, puesta: bool) -> Dictionary:
	var johnny: Node2D = partida.johnny
	var w: Dictionary = johnny.arma_de(id)
	cabeza(caja, Objetos.icono(id), Objetos.nombre(id), "%s · %s" % [Recetas.HUECOS[w.tipo],
		"En la mano" if puesta else "De repuesto"], Armas.sacadas[id].rareza if Armas.es_creada(id) else "")
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
	var que: String = Recetas.LISTA[Armas.sacadas[id].receta].desc + "." if Armas.es_creada(id) else QUE_HACE.get(id, "")
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


# La ficha de una casilla de la mochila ([id, cuántos]): lo de curar se usa; lo demás dice para qué recetas sirve
func ficha_objeto(caja: VBoxContainer, c: Array) -> Dictionary:
	var id: String = c[0]
	var curar := id in Objetos.USABLES
	cabeza(caja, Objetos.icono(id), Objetos.nombre(id), "Para curar" if curar else "Objeto · Común")
	if c[1] > 1:
		renglon(caja, "Llevas %d" % c[1], Tema.TINTA)
	if curar:
		return {"que": "Te cura %d de vida. Si no lo usas, se pierde al acabar la partida (no va al baúl)." % partida.cura_de(id),
			"botones": [["usar", "Usar", usar, false], ["tirar", "Tirar al suelo", tirar, false]]}
	return {"que": recetas_de(id) + " Si caes, se pierde (en el baúl queda a salvo).",
		"botones": [["tirar", "Tirar al suelo", tirar, false]]}


# Para qué recetas del banco de trabajo sirve un objeto: las que se saben, con el otro ingrediente; las que no, cuántas
func recetas_de(id: String) -> String:
	var s := Guardado.cargar()
	var sabidas := []
	var otras := 0
	for r in Recetas.LISTA:
		var con: Array = Recetas.LISTA[r].con
		if not id in con:
			continue
		if Recetas.sabe(s, r):
			sabidas.append("%s (con %s)" % [Recetas.LISTA[r].nombre, Objetos.nombre(con[1] if con[0] == id else con[0]).to_lower()])
		else:
			otras += 1
	var recetas := "una receta" if otras == 1 else "%d recetas" % otras
	if sabidas.is_empty():
		return "Sirve para %s del banco que aún no tienes (las sueltan los jefes)." % recetas if otras > 0 \
			else "No sirve para ninguna receta del banco."
	var lista: String = ", ".join(sabidas.slice(0, -1)) + " y " + sabidas[-1] if sabidas.size() > 1 else sabidas[0]
	return "Sirve para crear en el banco: %s.%s" % [lista, " Y para %s que aún no tienes." % recetas if otras > 0 else ""]


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
	cabeza(caja, icono_lanzable(k), nombre_lanzable(k), "Arrojable · %s" % ("A mano" if a_mano else "De repuesto"),
		rareza_lanzable(k))
	renglon(caja, "Te quedan %d de %d" % [lz.cuantas(k), lz.maximo(k)] if k in Lanzables.DATOS
		else "Te quedan %d" % lz.cuantas(k), Tema.TINTA)
	var que: String = QUE_HACE[k] if k in QUE_HACE else Recetas.LISTA[k].desc + "."
	if a_mano:
		que += " Es lo que lanzas ahora." if k == lz.tipo else " Con F lo eliges para lanzarlo."
		return {"que": que, "botones": [["al_repuesto", "Al repuesto", mover_lanzable, lz.repuesto.size() >= Lanzables.REPUESTO]]}
	if lz.mano.size() >= Lanzables.MANO:
		que += " «A la mano» lo cambia por %s, que pasa aquí." % nombre_lanzable(lz.tipo).to_lower()
	return {"que": que, "botones": [["a_la_mano", "A la mano", mover_lanzable, false]]}


# Una línea de la ficha (si no cabe, se parte en varias)
func renglon(caja: VBoxContainer, s: String, color: Color, alinear := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var t := Label.new()
	t.text = s
	t.horizontal_alignment = alinear
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = ANCHO_FICHA
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
	if abierto == "inventario" and sel != clave and not moviendo_marca and is_instance_valid(lienzo) \
			and lienzo.is_ancestor_of(b):
		elegir(clave)


# El botón de la ficha que hace lo suyo con lo elegido («Ponérmela», «Usar», «A la mano» o «Al repuesto»; no «Tirar
# al suelo»), si se puede pulsar
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


# Pasa el arrojable elegido de la mano al repuesto o al revés (lanzables.gd); la ficha sigue con él, en su sitio nuevo
func mover_lanzable() -> void:
	var lz: Lanzables = partida.lanzables
	var i := sel.substr(1).to_int()
	var k := ""
	if sel.begins_with("e") and i < lz.repuesto.size():
		k = lz.repuesto[i]
		lz.a_la_mano(k)
	elif sel.begins_with("l") and i < lz.mano.size() and lz.repuesto.size() < Lanzables.REPUESTO:
		k = lz.mano[i]
		lz.al_repuesto(k)
	else:
		Sonido.tocar("no")
		return
	Sonido.tocar("cambiar")
	sel = "l%d" % lz.mano.find(k) if k in lz.mano else "e%d" % lz.repuesto.find(k)
	foco = sel
	pintar()


# El borde de la casilla de un arma: el color de su rareza si es creada; si no, gris
func borde(id: String) -> Color:
	return Recetas.RAREZAS[Armas.sacadas[id].rareza].color if Armas.es_creada(id) else Recetas.GRIS


# El objeto de la casilla de la mochila elegida ("" si no hay ninguna elegida). En el baúl, para guardar, la mochila
# lleva también la gasolina, los bidones de ácido y las baterías (que en el inventario van con la munición)
func elegido() -> String:
	var llenas := Objetos.casillas(partida.mochila, guardando)
	var i := sel.substr(1).to_int()
	return llenas[i][0] if sel.begins_with("m") and i < llenas.size() else ""


# Usa lo elegido de la mochila (el botiquín): se cierra el inventario y Johnny se cura. Si no se puede (con la
# vida llena), lo dice en la ficha y no se gasta
func usar() -> void:
	var no: String = partida.usar_objeto(elegido())
	if no != "":
		Sonido.tocar("no")
		aviso = no
		foco = "usar"
		pintar()
		return
	sel = ""
	cerrar()


# Se pone en la mano el arma de repuesto elegida; la que llevaba (de su mismo tipo) pasa al repuesto. La ficha enseña
# la que se acaba de poner
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
	foco = sel
	pintar()


# Tira al suelo, a los pies de Johnny, lo elegido: un objeto de la mochila (uno), un arma (la de la mano, solo si lleva
# otra de repuesto, que pasa a la mano) o munición (la gasolina, los bidones de ácido y las baterías, de uno en uno; las balas, todas
# las del hueco en una caja que las devuelve). Si ya no queda nada de lo elegido, la ficha vuelve al arma de la mano
func tirar() -> void:
	var i := sel.substr(1).to_int()
	var mochila: Array = partida.mochila
	var johnny: Node2D = partida.johnny
	var suelo: Vector2 = johnny.position + Vector2(0, 34)
	if sel.begins_with("u"):
		var huecos: Array = johnny.huecos_municion()
		if i >= huecos.size():
			return
		var tipo: String = huecos[i][0]
		if tipo in Objetos.NOMBRES:
			mochila.remove_at(mochila.rfind(tipo))
			partida.soltar_objeto(tipo, suelo, true)
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
		mochila.remove_at(mochila.rfind(id))
		partida.soltar_objeto(id, suelo, true)
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
	else:
		return
	foco = sel
	pintar()


# ── Baúl ──

func pintar_baul(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	titulo(columna, "Baúl · %d / %d" % [Objetos.casillas_baul(s), Objetos.BAUL])
	var rejilla := GridContainer.new()
	rejilla.columns = 8
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	var n := 0
	for i in s.baul_armas.size():
		var a: Dictionary = s.baul_armas[i]
		casilla(rejilla, "a%d" % i, Recetas.icono_de(a.receta), a.nombre, Recetas.detalle(a), Recetas.RAREZAS[a.rareza].color)
		n += 1
	for id in Objetos.NOMBRES:
		if s.baul.get(id, 0) > 0:
			casilla(rejilla, "o_" + id, Objetos.icono(id), Objetos.nombre(id), "× %d" % s.baul[id], Recetas.GRIS, false)
			n += 1
	for i in range(n, maxi(Objetos.BAUL, ceili(n / 8.0) * 8)):
		casilla(rejilla, "", "", "", "", Color(0, 0, 0, 0))
	var texto := "Está vacío. Aquí van las armas que crees en el banco de trabajo y lo que traigas en la mochila: lo guardas tú o, si completas el edificio, pasa solo."
	if sel.begins_with("a"):
		var a: Dictionary = s.baul_armas[sel.substr(1).to_int()]
		texto = "%s (%s, %s): %s. %s" % [a.nombre, Recetas.RAREZAS[a.rareza].nombre.to_lower(),
			Recetas.HUECOS[a.hueco].to_lower(), a.desc, AL_SACAR[a.hueco]]
	elif not guardables().is_empty():
		texto = "Lo que llevas en la mochila se pierde si caes: con «Guardar de la mochila» lo metes aquí y queda a salvo."
	elif n > 0:
		texto = "Aquí se guarda lo que traes en la mochila (lo guardas tú o pasa solo al completar un edificio), y las armas que creas en el banco de trabajo."
	if aviso != "":
		texto = aviso
		aviso = ""
	nota(columna, texto, 640)
	var botones := fila(columna, true)
	if sel.begins_with("a"):
		boton(botones, "sacar", "Sacar", sacar, "BotonGrande")
	var mochila := boton(botones, "ver_mochila", "Guardar de la mochila", ver_mochila.bind(true))
	mochila.disabled = guardables().is_empty()
	boton(botones, "cerrar", "Cerrar", cerrar)
	if not s.baul_armas.is_empty():
		return fondo.find_child("a0", true, false)
	return fondo.find_child("cerrar" if mochila.disabled else "ver_mochila", true, false)


const AL_SACAR := {
	"cuerpo": "Al sacarla, es tuya para esta partida: te la pones y la que llevas pasa al repuesto (si ya tienes una de repuesto, se queda en el suelo).",
	"fuego": "Al sacarla, es tuya para esta partida: va a la mano de fuego y la que llevas pasa al repuesto (si ya tienes una de repuesto, se queda en el suelo).",
	"arrojadiza": "Al sacarla, es tuya para esta partida: se lanza como la granada. Va a la mano si tienes sitio (F para elegirla) y si no, al repuesto.",
}


# Saca del baúl el arma elegida para esta partida (sacarDelBaul en src/banco.js): la de cuerpo a cuerpo y la de
# fuego, a la mano (la que llevara pasa al repuesto o, si ya tiene una, al suelo: partida.llevar_arma); las
# arrojadizas, a la mano o al repuesto (lanzables.gd; si no le cabe, se queda en el baúl)
func sacar() -> void:
	var i := sel.substr(1).to_int()
	var lista: Array = Guardado.cargar().baul_armas
	if not sel.begins_with("a") or i >= lista.size():
		return
	var a: Dictionary = lista[i]
	var lz: Lanzables = partida.lanzables
	if a.hueco == "arrojadiza" and not lz.hay_hueco(a.receta):
		Sonido.tocar("no")
		aviso = "No te cabe: llevas llenos los %d huecos de arrojables a mano y los %d de repuesto." % [Lanzables.MANO, Lanzables.REPUESTO]
		foco = "sacar"
		pintar()
		return
	Guardado.cambiar(func(s): s.baul_armas.remove_at(i))
	Sonido.tocar("compra")
	if a.hueco == "arrojadiza":
		lz.sacar(a)
		if a.receta in lz.repuesto:
			aviso = "%s va al repuesto (la mano está llena): pásala a la mano desde el inventario." % a.nombre
	else:
		var suelo: String = partida.llevar_arma(Armas.apuntar(a))
		if suelo != "":
			aviso = "Ya llevabas dos armas de ese tipo: %s se queda en el suelo, a tus pies." % Objetos.nombre(suelo)
	sel = ""
	foco = "cerrar"
	pintar()


# ── Baúl: guardar lo de la mochila ──

# La mochila dentro de la ventana del baúl, en una fila de 8 (como el baúl, para que no cambie de ancho). El título
# sigue contando las casillas del baúl, para ver cuánto sitio queda
func pintar_guardar(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	var llenas := Objetos.casillas(partida.mochila, true)   # (con la gasolina y los bidones de ácido de la munición)
	titulo(columna, "Baúl · %d / %d" % [Objetos.casillas_baul(s), Objetos.BAUL])
	subtitulo(columna, "Mochila · %d / %d" % [Objetos.casillas(partida.mochila).size(), Objetos.MOCHILA], "mochila")
	var rejilla := GridContainer.new()
	rejilla.columns = 8
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	for i in maxi(Objetos.MOCHILA, ceili(llenas.size() / 8.0) * 8):
		if i < llenas.size():
			var id: String = llenas[i][0]
			var n: int = llenas[i][1]
			var sub := ("× %d" % n if n > 1 else "") if Objetos.al_baul(id) else "No va al baúl"
			casilla(rejilla, "m%d" % i, Objetos.icono(id), Objetos.nombre(id), sub, Recetas.GRIS)
		else:
			casilla(rejilla, "", "", "", "", Color(0, 0, 0, 0))
	var id := elegido()
	var cabe := id != "" and Objetos.al_baul(id) and Objetos.cabe_baul(s, id)
	var texto := "Toca lo que quieras guardar. En el baúl queda a salvo aunque caigas, y el banco de trabajo lo usa igual."
	if llenas.is_empty():
		texto = "La mochila está vacía."
	elif id != "" and not Objetos.al_baul(id):
		texto = "Lo de curar (%s) no va al baúl: úsalo en la partida, porque al acabarla se pierde." % Objetos.nombre(id).to_lower()
	elif id != "" and not cabe:
		texto = "El baúl está lleno: solo caben más de lo que ya tiene. Haz sitio sacando armas o creando alguna en el banco de trabajo."
	elif id != "":
		texto = "«Guardar» mete en el baúl todo lo de esta casilla (%s × %d) y ya no se pierde aunque caigas." % [
			Objetos.nombre(id), partida.mochila.count(id)]
	if aviso != "":
		texto = aviso
		aviso = ""
	nota(columna, texto, 640)
	var botones := fila(columna, true)
	if id != "" and Objetos.al_baul(id):
		var uno := boton(botones, "guardar", "Guardar", guardar, "BotonGrande")
		uno.disabled = not cabe
	var todo := boton(botones, "guardar_todo", "Guardar todo", guardar_todo)
	todo.disabled = guardables().is_empty()
	boton(botones, "ver_baul", "Ver el baúl", ver_mochila.bind(false))
	boton(botones, "cerrar", "Cerrar", cerrar)
	return fondo.find_child("m0", true, false) if not llenas.is_empty() else fondo.find_child("ver_baul", true, false)


# Pasa de ver el baúl a ver la mochila (para guardar) o al revés
func ver_mochila(si: bool) -> void:
	Sonido.tocar("click")
	guardando = si
	sel = ""
	foco = "" if si else "ver_mochila"
	pintar()


# Los objetos distintos de la mochila que pueden ir al baúl (todos menos los de curar; también la gasolina, los
# bidones de ácido y las baterías, que van con la munición)
func guardables() -> Array:
	return Objetos.casillas(partida.mochila, true).map(func(c): return c[0]).filter(func(id): return Objetos.al_baul(id))


# Guarda en el baúl la casilla elegida de la mochila (todos los de esa casilla). La marca se queda en el mismo
# sitio, que ahora es la casilla siguiente: con el mando o las flechas, A dos veces y se guarda otra
func guardar() -> void:
	if not meter_en_baul(elegido()):
		Sonido.tocar("no")
		return
	Sonido.tocar("cambiar")
	foco = sel
	sel = ""
	pintar()


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
	sel = ""
	foco = "ver_baul"
	pintar()


# Mete en el baúl todos los de la mochila de ese objeto, si puede ir (no es de curar) y cabe. Dice si lo ha hecho
func meter_en_baul(id: String) -> bool:
	if id == "" or not Objetos.al_baul(id) or not Objetos.cabe_baul(Guardado.cargar(), id):
		return false
	var mochila: Array = partida.mochila
	var n := mochila.count(id)
	while id in mochila:
		mochila.erase(id)
	Guardado.cambiar(func(s): s.baul[id] = s.baul.get(id, 0) + n)
	return true


# ── Banco de trabajo ──

# Cuántos tiene de un ingrediente: las armas de las recetas (bate, fregona, cuchillo), en la mano o guardadas;
# los objetos, sumando los de la mochila y los del baúl
func tiene(id: String, baul: Dictionary) -> int:
	if id in Recetas.ARMAS:
		return int(partida.johnny.huecos.cuerpo == id) + partida.armas_guardadas.count(id)
	return partida.mochila.count(id) + int(baul.get(id, 0))


func pintar_banco(columna: VBoxContainer) -> Control:
	var s := Guardado.cargar()
	var sabidas := Recetas.sabidas(s)
	titulo(columna, "Banco de trabajo")
	subtitulo(columna, "Recetas: %d de %d" % [sabidas.size(), Recetas.LISTA.size()], "")
	var rejilla := GridContainer.new()
	rejilla.columns = 8
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	for id in Recetas.LISTA:
		hoja(rejilla, id, id in sabidas)
	# la mesa: lo que pide la receta elegida + lo otro = el arma que sale
	var linea := fila(columna, true)
	var r: Dictionary = Recetas.LISTA.get(receta, {})
	var sabe := receta in sabidas
	var faltan: Array = r.con.filter(func(i): return tiene(i, s.baul) == 0) if sabe else []
	var lleno: bool = sabe and faltan.is_empty() and not cabe_en_baul(r.con)
	for i in 2:
		if sabe:
			var n := tiene(r.con[i], s.baul)
			casilla(linea, "", Objetos.icono(r.con[i]), Objetos.nombre(r.con[i]), "Tienes %d" % n if n > 0 else "No tienes",
				Recetas.GRIS if n > 0 else Color("#c0392b"))
		else:
			casilla(linea, "", "", "?", "", Color(1, 1, 1, 0.15))
		signo(linea, "+" if i == 0 else "=")
	if not hecha.is_empty():
		casilla(linea, "", Recetas.icono_de(hecha.receta), hecha.nombre, Recetas.detalle(hecha), Recetas.RAREZAS[hecha.rareza].color)
	elif sabe:
		casilla(linea, "", Recetas.icono_de(receta), r.nombre, Recetas.HUECOS[r.hueco], Recetas.GRIS)
	else:
		casilla(linea, "", "", "?", "", Color(1, 1, 1, 0.15))
	var texto := "Toca una receta para ver lo que pide. Las que no tienes las sueltan los jefes al morir."
	if not hecha.is_empty():
		texto = "¡%s %s! %s. Está en el baúl." % [hecha.nombre, Recetas.RAREZAS[hecha.rareza].nombre.to_lower(), hecha.desc]
	elif receta != "" and not sabe:
		texto = "Aún no tienes esta receta: la suelta un jefe al morir, en un papel que hay que recoger."
	elif not faltan.is_empty():
		texto = "%s. Te falta: %s." % [r.desc, ", ".join(faltan.map(func(i): return Objetos.nombre(i).to_lower()))]
	elif lleno:
		texto = "El baúl está lleno: haz sitio antes de crear otra arma."
	elif sabe:
		texto = "%s. Al crearla, los dos ingredientes se gastan (primero los de la mochila) y el arma va al baúl." % r.desc
	nota(columna, texto, 640)
	var botones := fila(columna, true)
	var crear := boton(botones, "crear", "Crear", crear_arma, "BotonGrande")
	crear.disabled = not sabe or not faltan.is_empty() or lleno or not hecha.is_empty()
	boton(botones, "cerrar", "Cerrar", cerrar)
	if not crear.disabled:
		return crear
	return fondo.find_child("r_" + (receta if receta != "" else Recetas.LISTA.keys()[0]), true, false)


# Una receta en la cuadrícula: si se sabe, una hoja de papel con el dibujo del arma que sale y su nombre; si no,
# un recuadro oscuro con un "?". Las dos se pueden tocar (la que no se sabe dice de dónde sale)
func hoja(padre: Container, id: String, sabida: bool) -> void:
	var elegida := id == receta
	var b := Button.new()
	b.name = "r_" + id
	b.custom_minimum_size = HOJA
	b.pressed.connect(tocar.bind(b.name))
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		var encima: bool = estado != "normal"
		if sabida:
			e.bg_color = PAPEL.lightened(0.08) if encima else PAPEL
			e.border_color = Tema.AMARILLO if elegida or encima else PAPEL.darkened(0.35)
		else:
			e.bg_color = Color("#26222e") if encima else FONDO_CASILLA
			e.border_color = Tema.AMARILLO if elegida or encima else Color(1, 1, 1, 0.15)
		e.set_border_width_all(3 if elegida else 2)
		e.set_corner_radius_all(1)
		b.add_theme_stylebox_override(estado, e)
	padre.add_child(b)
	if not sabida:
		var interrogacion := Label.new()
		interrogacion.text = "?"
		interrogacion.theme_type_variation = "Titulo"
		interrogacion.add_theme_color_override("font_color", Tema.GRIS)
		interrogacion.set_anchors_preset(Control.PRESET_FULL_RECT)
		interrogacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interrogacion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		interrogacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(interrogacion)
		return
	# la esquina doblada, arriba a la derecha
	b.draw.connect(func():
		var w := b.size.x
		b.draw_colored_polygon(PackedVector2Array([Vector2(w - 14, 0), Vector2(w, 0), Vector2(w, 14)]), Color("#2a2533"))
		b.draw_colored_polygon(PackedVector2Array([Vector2(w - 14, 0), Vector2(w, 14), Vector2(w - 14, 14)]), PAPEL.darkened(0.2)))
	var dentro := VBoxContainer.new()
	dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
	dentro.offset_left = 3
	dentro.offset_right = -3
	dentro.offset_top = 8
	dentro.add_theme_constant_override("separation", 0)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(dentro)
	var imagen := TextureRect.new()
	imagen.texture = load("res://assets/ui/iconos/%s.png" % Recetas.icono_de(id))
	imagen.custom_minimum_size = Vector2(0, 36)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(imagen)
	var t := Label.new()
	t.text = Recetas.LISTA[id].nombre
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD   # los nombres largos, mejor un poco apretados que partidos
	t.add_theme_font_size_override("font_size", 16 if Recetas.LISTA[id].nombre.length() < 12 else 14)
	t.add_theme_constant_override("line_spacing", -4)
	t.add_theme_constant_override("outline_size", 0)
	t.add_theme_color_override("font_color", TINTA_PAPEL)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(t)


# Toca una receta: se ve lo que pide (otra vez, la deja de ver). Si se puede crear, la marca salta a «Crear»: con
# el mando o las flechas, A dos veces y se crea
func elegir_receta(id: String) -> void:
	hecha = {}
	receta = "" if receta == id else id
	foco = "r_" + id
	pintar()
	var crear: Button = fondo.find_child("crear", true, false)
	if crear and not crear.disabled:
		crear.grab_focus.call_deferred()


func crear_arma() -> void:
	var s := Guardado.cargar()
	if not Recetas.sabe(s, receta) or not hecha.is_empty():
		Sonido.tocar("no")
		return
	var con: Array = Recetas.LISTA[receta].con
	if con.any(func(i): return tiene(i, s.baul) == 0) or not cabe_en_baul(con):
		Sonido.tocar("no")
		return
	var johnny: Node2D = partida.johnny
	# se gastan los ingredientes: las armas, primero las guardadas y si no, la de la mano; los objetos, primero los
	# de la mochila
	var sin_mano := false
	for id in con:
		if id in Recetas.ARMAS:
			if id in partida.armas_guardadas:
				partida.armas_guardadas.erase(id)
			else:
				sin_mano = true
		else:
			gastar_objeto(id)
	# si se ha gastado el arma de la mano, coge otra (la fregona, si no guarda ninguna)
	if sin_mano:
		var otra := "fregona"
		for id in partida.armas_guardadas:
			if Armas.datos(id).tipo == "cuerpo":
				otra = id
				break
		partida.armas_guardadas.erase(otra)
		johnny.coger(otra)
	hecha = Recetas.crear(receta)
	partida.logros.cumplir("manitas")
	Sonido.tocar("compra" if hecha.rareza == "verde" else "limpio")   # las raras y épicas suenan a premio
	Guardado.cambiar(func(g): g.baul_armas.append(hecha))
	Recetas.apuntar_creada(receta)   # para las Colecciones del ordenador
	foco = "r_" + receta
	pintar()


# Gasta un objeto: primero de la mochila y, si no hay ahí, del baúl
func gastar_objeto(id: String) -> void:
	var mochila: Array = partida.mochila
	if id in mochila:
		mochila.remove_at(mochila.rfind(id))
		return
	Guardado.cambiar(func(s):
		s.baul[id] = s.baul.get(id, 0) - 1
		if s.baul[id] <= 0:
			s.baul.erase(id))


# ¿Hay sitio en el baúl para el arma? Cuenta que los objetos que se gastan del baúl pueden dejar libre su casilla
func cabe_en_baul(con: Array) -> bool:
	var s := Guardado.cargar()
	var usadas := Objetos.casillas_baul(s)
	for id in con:
		if not id in Recetas.ARMAS and not id in partida.mochila and s.baul.get(id, 0) == 1:
			usadas -= 1
	return usadas < Objetos.BAUL


# ── Piezas ──

func titulo(columna: VBoxContainer, texto: String) -> void:
	var t := Label.new()
	t.theme_type_variation = "Titulo"
	t.text = texto
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(t)


func subtitulo(columna: VBoxContainer, texto: String, icono: String) -> void:
	var t := Tema.icono_y_texto(icono, texto, 20)
	t.get_child(t.get_child_count() - 1).add_theme_color_override("font_color", Tema.AMARILLO)
	columna.add_child(t)


func nota(columna: VBoxContainer, texto: String, ancho := 0) -> void:
	var t := Label.new()
	t.name = "nota"   # (una por pantalla; la prueba --baul la lee)
	t.theme_type_variation = "Sub"
	t.text = texto
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size.x = ancho if ancho > 0 else 430
	columna.add_child(t)


func fila(columna: VBoxContainer, centrada := false) -> HBoxContainer:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 6)
	if centrada:
		f.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(f)
	return f


func signo(f: HBoxContainer, texto: String) -> void:
	var t := Label.new()
	t.text = texto
	t.theme_type_variation = "Titulo"
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(t)


func boton(caja: Control, nombre: String, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.theme_type_variation = variacion
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


# Una casilla con su dibujo, su nombre y una línea de debajo, con el borde del color de su rareza.
# Con "clave" se puede tocar (es un botón): en el inventario y el baúl se elige. "tam": su tamaño (las pequeñas, con
# el dibujo más pequeño)
func casilla(padre: Container, clave: String, icono: String, nombre: String, sub: String, borde: Color,
		tocable := true, puesta := false, tam := CASILLA) -> Control:
	var c: Control
	var elegida := puesta or (clave != "" and clave == sel)
	if clave != "" and tocable:
		var b := Button.new()
		b.name = clave
		b.pressed.connect(tocar.bind(clave))
		b.add_theme_stylebox_override("normal", estilo(borde, elegida, false))
		b.add_theme_stylebox_override("hover", estilo(borde, elegida, true))
		b.add_theme_stylebox_override("pressed", estilo(borde, true, true))
		b.add_theme_stylebox_override("focus", estilo(borde, elegida, true))   # elegida con el mando: iluminada
		c = b
	else:
		c = Panel.new()
		if clave != "":
			c.name = clave
		c.add_theme_stylebox_override("panel", estilo(borde, false, false))
	c.custom_minimum_size = tam
	padre.add_child(c)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
	dentro.offset_left = 4
	dentro.offset_right = -4
	dentro.offset_top = 6
	dentro.offset_bottom = -4
	dentro.add_theme_constant_override("separation", 0)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(dentro)
	if icono != "":
		var imagen := TextureRect.new()
		imagen.texture = load("res://assets/ui/iconos/%s.png" % icono)
		imagen.custom_minimum_size = Vector2(0, minf(36, tam.y - 28))
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(imagen)
	for i in 2:
		var texto := nombre if i == 0 else sub
		if texto == "":
			continue
		var t := Label.new()
		t.text = texto
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_font_size_override("font_size", 16)
		t.add_theme_constant_override("line_spacing", -4)
		if i == 1:
			t.add_theme_color_override("font_color", Tema.GRIS)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(t)
	return c


func estilo(borde: Color, elegida: bool, encima: bool) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color("#3a3226") if elegida else (Color("#26222e") if encima else FONDO_CASILLA)
	e.border_color = Tema.AMARILLO if elegida else borde
	e.set_border_width_all(3 if elegida else 2)
	e.set_corner_radius_all(3)
	return e


# Al tocar una casilla: en el banco, una receta ("r_lanza") enseña lo que pide; en el inventario, se elige y, si su
# ficha tiene un botón que hace lo suyo («Ponérmela», «Usar», «A la mano» o «Al repuesto»), la marca salta a él (con
# el mando o las flechas, A dos veces y hecho); en el baúl, se elige (o se deja de elegir)
func tocar(clave: String) -> void:
	Sonido.tocar("click")
	if abierto == "banco":
		elegir_receta(clave.trim_prefix("r_"))
		return
	if abierto == "inventario":
		elegir(clave)
		var b: Control = principal()
		dar_foco.call_deferred(b if b else lienzo.find_child(sel, false, false))
		return
	sel = "" if sel == clave else clave
	foco = clave
	if guardando and Objetos.al_baul(elegido()) and Objetos.cabe_baul(Guardado.cargar(), elegido()):
		foco = "guardar"   # en el baúl, la marca salta a «Guardar»: A dos veces y se guarda
	pintar()


# Esc, B del mando o (en el inventario) la misma tecla que lo abrió: cerrar. Va en _input porque Godot usa el
# Tabulador para pasar de un botón a otro y no llegaría. En el inventario, además, los atajos: F (o RB) cambia el
# arrojable que se lanza, X (o Supr) tira lo elegido e Y hace lo del botón principal de la ficha
func _input(evento: InputEvent) -> void:
	if abierto == "":
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa") \
			or (abierto == "inventario" and evento.is_action_pressed("inventario")):
		get_viewport().set_input_as_handled()
		cerrar()
		return
	if abierto != "inventario":
		return
	if evento.is_action_pressed("cambiar_lanzable"):
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
