# Las pantallas de las cosas de Johnny (fase 7b; en el JS, showInventario y showBaul de src/ui.js y el banco
# de src/banco.js). El juego se para mientras están abiertas:
#   - Inventario (Tab, I o Select): las dos armas que lleva, las que guarda (la que deja al comprar otra
#     cuerpo a cuerpo, o al sacar una creada del baúl) y la mochila. Al tocar una casilla se elige y salen sus
#     botones: "Ponérmela" (las armas guardadas), "Usar" (el botiquín de la farmacéutica: Objetos.USABLES) y
#     "Tirar al suelo" (los objetos, de uno en uno, y las armas).
#   - Baúl (al arrimarse a él en la sala de mantenimiento): los objetos guardados de otras partidas y las armas
#     creadas en el banco. Un arma creada se puede sacar para esta partida (fase 7b2): la de cuerpo a cuerpo o
#     de fuego va a la mano (y la que llevaba, al inventario); las arrojadizas, al botón de lanzar.
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
var sel := ""              # la casilla elegida: "m2" la 3.ª de la mochila, "g0" la 1.ª arma guardada, "a1" la 2.ª arma del baúl
var receta := ""           # banco: la receta elegida (su id de Recetas.LISTA)
var hecha := {}            # banco: el arma que se acaba de crear (para enseñarla)
var foco := ""             # el botón que tiene que quedar marcado al volver a pintar
var aviso := ""            # inventario: lo que se dice abajo una vez (por qué no se puede usar)


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
		"baul": primero = pintar_baul(columna)
		"banco": primero = pintar_banco(columna)
	# se queda marcado el mismo botón que antes (o el primero)
	var marcado: Control = fondo.find_child(foco, true, false) if foco != "" else null
	if marcado == null or not marcado.focus_mode == Control.FOCUS_ALL:
		marcado = primero
	if marcado:
		marcado.grab_focus.call_deferred()


# ── Inventario ──

func pintar_inventario(columna: VBoxContainer) -> Control:
	var johnny: Node2D = partida.johnny
	var mochila: Array = partida.mochila
	var guardadas: Array = partida.armas_guardadas
	titulo(columna, "Inventario")
	subtitulo(columna, "Armas", "")
	var armas := fila(columna)
	for hueco in ["cuerpo", "fuego"]:
		var id: String = johnny.huecos[hueco]
		casilla(armas, "", Objetos.icono(id), Armas.datos(id).nombre, "En la mano" if hueco == "cuerpo" else "De fuego",
			borde(id))
	for i in guardadas.size():
		casilla(armas, "g%d" % i, Objetos.icono(guardadas[i]), Objetos.nombre(guardadas[i]), "Guardada", borde(guardadas[i]))
	var llenas := Objetos.casillas(mochila)
	subtitulo(columna, "Mochila · %d / %d" % [llenas.size(), Objetos.MOCHILA], "mochila")
	var rejilla := GridContainer.new()
	rejilla.columns = 4
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	for i in Objetos.MOCHILA:
		if i < llenas.size():
			var id: String = llenas[i][0]
			var n: int = llenas[i][1]
			casilla(rejilla, "m%d" % i, Objetos.icono(id), Objetos.nombre(id), "× %d" % n if n > 1 else "", Recetas.GRIS)
		else:
			casilla(rejilla, "", "", "", "", Color(0, 0, 0, 0))
	var texto := "Lo que llevas en la mochila pasa al baúl si completas el edificio. Si caes, se pierde."
	var usable := elegido() in Objetos.USABLES
	if usable:   # el botiquín, las vendas o el bocadillo: cada uno cura lo suyo
		texto = "Te cura %d de vida. Si no lo usas, se pierde al acabar la partida (no va al baúl)." % partida.cura_de(elegido())
	elif sel != "":
		texto = "Si lo tiras, se queda en el suelo: puedes volver a cogerlo." + (" Se tira de uno en uno." if sel[0] == "m" else "")
	if aviso != "":
		texto = aviso
		aviso = ""
	nota(columna, texto)
	var botones := fila(columna, true)
	if usable:
		boton(botones, "usar", "Usar", usar, "BotonGrande")
	if sel.begins_with("g"):
		boton(botones, "poner", "Ponérmela", poner_guardada)
	if sel != "":
		boton(botones, "tirar", "Tirar al suelo", tirar, "BotonRojo")
	boton(botones, "cerrar", "Seguir", cerrar)
	return fondo.find_child("m0", true, false) if not llenas.is_empty() else fondo.find_child("cerrar", true, false)


# El borde de la casilla de un arma: el color de su rareza si es creada; si no, gris
func borde(id: String) -> Color:
	return Recetas.RAREZAS[Armas.sacadas[id].rareza].color if Armas.es_creada(id) else Recetas.GRIS


# El objeto de la casilla de la mochila elegida ("" si no hay ninguna elegida)
func elegido() -> String:
	var llenas := Objetos.casillas(partida.mochila)
	var i := sel.substr(1).to_int()
	return llenas[i][0] if sel.begins_with("m") and i < llenas.size() else ""


# Usa lo elegido de la mochila (el botiquín): se cierra el inventario y Johnny se cura. Si no se puede (con la
# vida llena), lo dice abajo y no se gasta
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


# Se pone en la mano el arma guardada elegida; la que llevaba (de su mismo tipo) pasa a las guardadas
func poner_guardada() -> void:
	var i := sel.substr(1).to_int()
	var guardadas: Array = partida.armas_guardadas
	if i >= guardadas.size():
		return
	var johnny: Node2D = partida.johnny
	var id: String = guardadas[i]
	guardadas[i] = johnny.huecos[Armas.datos(id).tipo]
	johnny.coger(id)
	Sonido.tocar("cambiar")
	sel = ""
	foco = "cerrar"
	pintar()


# Tira al suelo, a los pies de Johnny, lo elegido: un objeto de la mochila (uno) o un arma guardada
func tirar() -> void:
	var i := sel.substr(1).to_int()
	var mochila: Array = partida.mochila
	if sel.begins_with("m"):
		var llenas := Objetos.casillas(mochila)
		if i >= llenas.size():
			return
		var id: String = llenas[i][0]
		mochila.remove_at(mochila.rfind(id))
		partida.soltar_objeto(id, partida.johnny.position + Vector2(0, 34), true)
		if not id in mochila:
			sel = ""
	elif sel.begins_with("g"):
		var id: String = partida.armas_guardadas[i]
		partida.armas_guardadas.remove_at(i)
		partida.soltar_arma(id, partida.johnny.position + Vector2(0, 34))
		sel = ""
	foco = sel if sel != "" else "cerrar"
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
		casilla(rejilla, "a%d" % i, Objetos.icono(a.icono), a.nombre, Recetas.detalle(a), Recetas.RAREZAS[a.rareza].color)
		n += 1
	for id in Objetos.NOMBRES:
		if s.baul.get(id, 0) > 0:
			casilla(rejilla, "o_" + id, Objetos.icono(id), Objetos.nombre(id), "× %d" % s.baul[id], Recetas.GRIS, false)
			n += 1
	for i in range(n, maxi(Objetos.BAUL, ceili(n / 8.0) * 8)):
		casilla(rejilla, "", "", "", "", Color(0, 0, 0, 0))
	var texto := "Está vacío. Lo que lleves en la mochila se guarda aquí al completar un edificio, y aquí van las armas que crees en el banco de trabajo."
	if sel.begins_with("a"):
		var a: Dictionary = s.baul_armas[sel.substr(1).to_int()]
		texto = "%s (%s, %s): %s. %s" % [a.nombre, Recetas.RAREZAS[a.rareza].nombre.to_lower(),
			Recetas.HUECOS[a.hueco].to_lower(), a.desc, AL_SACAR[a.hueco] if a.receta != "molotov" else
			"Al sacarla, sus botellas se suman a tus molotovs."]
	elif n > 0:
		texto = "Aquí se guarda lo que traes en la mochila al completar un edificio, y las armas que creas en el banco de trabajo."
	nota(columna, texto, 640)
	var botones := fila(columna, true)
	if sel.begins_with("a"):
		boton(botones, "sacar", "Sacar", sacar, "BotonGrande")
	boton(botones, "cerrar", "Cerrar", cerrar)
	return fondo.find_child("a0", true, false) if not s.baul_armas.is_empty() else fondo.find_child("cerrar", true, false)


const AL_SACAR := {
	"cuerpo": "Al sacarla, es tuya para esta partida: te la pones y la que llevas pasa al inventario.",
	"fuego": "Al sacarla, es tuya para esta partida: va a la mano de fuego y la que llevas pasa al inventario.",
	"arrojadiza": "Al sacarla, es tuya para esta partida: se lanza como la granada (F para elegirla).",
}


# Saca del baúl el arma elegida para esta partida (sacarDelBaul en src/banco.js): la de cuerpo a cuerpo y la de
# fuego, a la mano (lo que llevara pasa al inventario); el cóctel molotov suma sus botellas a los molotovs; las
# demás arrojadizas, al botón de lanzar (lanzables.gd)
func sacar() -> void:
	var i := sel.substr(1).to_int()
	var lista: Array = Guardado.cargar().baul_armas
	if not sel.begins_with("a") or i >= lista.size():
		return
	var a: Dictionary = lista[i]
	Guardado.cambiar(func(s): s.baul_armas.remove_at(i))
	Sonido.tocar("compra")
	var johnny: Node2D = partida.johnny
	var lz: Lanzables = partida.lanzables
	if a.hueco == "arrojadiza":
		lz.sacar(a)
	else:
		partida.armas_guardadas.append(johnny.huecos[a.hueco])
		johnny.coger(Armas.apuntar(a))
	sel = ""
	foco = "cerrar"
	pintar()


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


func boton(caja: Container, nombre: String, texto: String, al_pulsar: Callable, variacion := "") -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.theme_type_variation = variacion
	b.pressed.connect(al_pulsar)
	caja.add_child(b)
	return b


# Una casilla con su dibujo, su nombre y una línea de debajo, con el borde del color de su rareza.
# Con "clave" se puede tocar (es un botón): en el inventario y el baúl se elige.
func casilla(padre: Container, clave: String, icono: String, nombre: String, sub: String, borde: Color,
		tocable := true, puesta := false) -> Control:
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
	c.custom_minimum_size = CASILLA
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
		imagen.custom_minimum_size = Vector2(0, 36)
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


# Al tocar una casilla: en el banco, una receta ("r_lanza") enseña lo que pide; en los demás, se elige (o se deja
# de elegir)
func tocar(clave: String) -> void:
	Sonido.tocar("click")
	if abierto == "banco":
		elegir_receta(clave.trim_prefix("r_"))
		return
	sel = "" if sel == clave else clave
	foco = clave
	if abierto == "inventario" and elegido() in Objetos.USABLES:
		foco = "usar"   # con el mando o las flechas, la marca salta a «Usar»: A dos veces y te curas
	pintar()


# Esc, B del mando o (en el inventario) la misma tecla que lo abrió: cerrar. Va en _input porque Godot usa el
# Tabulador para pasar de un botón a otro y no llegaría
func _input(evento: InputEvent) -> void:
	if abierto == "":
		return
	if evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa") \
			or (abierto == "inventario" and evento.is_action_pressed("inventario")):
		get_viewport().set_input_as_handled()
		cerrar()
