# El Dosier del ordenador (DOSIER.TXT, en ordenador.gd), como una carpeta de archivo marrón abierta encima de la misma
# chapa oscura que el árbol de talentos, la tienda de armas y los logros (chapa.gd). Se ve entero, sin desplazarse.
#
# Arriba, una pestaña por edificio con las páginas que llevas de él («Apartamentos 2/5») y, a la derecha, las de todos.
# Dentro de la carpeta, a la izquierda, las páginas de ese edificio como fichas: las encontradas en papel, con
# «Página N» y su título; las que faltan, como un trozo arrancado con solo «Página N» (que falta ya se ve). A la derecha, la hoja de la página
# que se mira (hoja_dosier.gd), sujeta con un clip: se cambia al pasar por una ficha (con el ratón, el teclado o el
# mando). Quién la llevaba o dónde buscarla sale en la línea de abajo del ordenador.
#
# La carpeta se dibuja con código (_draw); encima de cada pestaña y de cada ficha hay un botón transparente
# ("b_edificio_<id>" para las pestañas, "b_<id de la página>" para las fichas), que es el que se marca y se pulsa
extends Control

const PLACA := preload("res://scripts/ui/chapa.gd")
const CARPETA := Color("#c9a66b")
const CARPETA_OSCURA := Color("#8f7448")
const CARPETA_BORDE := Color("#5a4526")
const LETRA_CARPETA := Color("#2a2015")
const ARRANCADA := Color("#d8cfb6")
const ANCHO_FICHA := 124.0
const ALTO_PESTANA := 26.0
const ARRIBA_CARPETA := 30.0         # donde empieza la carpeta (debajo de las pestañas)

# El edificio que se vio y la página que se miró la última vez: se quedan al volver a montar la ventana (al cambiar de
# pestaña) y al volver a abrir el Dosier
static var recordado := ""
static var recordada := ""

var edificio := ""                   # el edificio que se ve
var vista := ""                      # la página que se mira

var ordenador: Node
var s: Dictionary                    # el guardado
var pestanas := {}                   # edificio → su botón
var cajas_pestanas := {}             # edificio → su recuadro
var botones := {}                    # id de la página → su botón (la ficha)
var fichas := {}                     # id de la página → su recuadro
var hoja: Control                    # la hoja que se mira (hoja_dosier.gd)


func montar(o: Node, guardado: Dictionary, foco := "") -> void:
	ordenador = o
	s = guardado
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 400)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	edificio = recordado
	vista = recordada
	# el edificio: el de la página o la pestaña que se pide; si no, el de antes o, la primera vez, el que se juega
	if foco.begins_with("b_edificio_"):
		edificio = foco.trim_prefix("b_edificio_")
		vista = ""
	elif foco.begins_with("b_") and Historia.sitio_de({"id": foco.trim_prefix("b_")})[0] != "":
		vista = foco.trim_prefix("b_")
		edificio = Historia.sitio_de({"id": vista})[0]
	if not Historia.DOSIERES.has(edificio):
		edificio = ordenador.partida.edificio if Historia.DOSIERES.has(ordenador.partida.edificio) else Historia.DOSIERES.keys()[0]
	var paginas := del_edificio()
	if not paginas.any(func(p): return p.id == vista):
		# la primera que tengas de este edificio (o la primera, si no tienes ninguna)
		var tuyas := paginas.filter(func(p): return Historia.encontrada(s, p.id))
		vista = (tuyas[0] if not tuyas.is_empty() else paginas[0]).id
	recordado = edificio
	recordada = vista
	for e in Historia.DOSIERES:
		var b := boton_transparente("b_edificio_" + e)
		b.pressed.connect(cambiar_edificio.bind(e))
		pestanas[e] = b
	for p in paginas:
		var b := boton_transparente("b_" + p.id)
		b.focus_entered.connect(ver.bind(p.id))
		b.mouse_entered.connect(ver.bind(p.id))
		botones[p.id] = b
	resized.connect(colocar)


func boton_transparente(nombre: String) -> Button:
	var b := Button.new()
	b.name = nombre
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	for senal in [b.mouse_entered, b.mouse_exited, b.focus_entered, b.focus_exited]:
		senal.connect(queue_redraw)   # (lo que está debajo del ratón o marcado se dibuja con el borde claro)
	add_child(b)
	return b


func del_edificio(e := edificio) -> Array:
	return Historia.dosier(e).paginas


func halladas(e: String) -> int:
	return del_edificio(e).filter(func(p): return Historia.encontrada(s, p.id)).size()


func nombre_edificio(e: String) -> String:
	return Idioma.t(Edificios.datos(e).nombre) if e in Edificios.LISTA else e


# Al pulsar una pestaña: se monta la ventana otra vez con ese edificio
func cambiar_edificio(e: String) -> void:
	if e == edificio:
		return
	Sonido.tocar("click")
	ordenador.abrir("dosier", "b_edificio_" + e)


# Al pasar por una ficha: su hoja a la derecha
func ver(id: String) -> void:
	if id == vista and hoja != null:
		return
	vista = id
	recordada = id
	poner_hoja()
	queue_redraw()


# ── Dónde va cada cosa (al cambiar de tamaño) ──

func colocar() -> void:
	if size.x < 400 or size.y < 200:
		return   # (aún sin su tamaño de verdad)
	var fuente := get_theme_default_font()
	# las pestañas, una al lado de otra
	var x := 20.0
	for e in pestanas:
		var ancho := minf(ancho_texto(fuente, texto_pestana(e), 16) + 24, (size.x - 150) / pestanas.size() - 6)
		var r := Rect2(x, 5, ancho, ALTO_PESTANA)
		cajas_pestanas[e] = r
		pestanas[e].position = r.position
		pestanas[e].size = r.size
		x += ancho + 6
	# las fichas, del mismo alto, de arriba abajo de la carpeta
	var paginas := del_edificio()
	var arriba := ARRIBA_CARPETA + 10
	var alto := floorf((size.y - 14 - arriba + 6) / maxf(1, paginas.size()) - 6)
	for i in paginas.size():
		var r := Rect2(24, arriba + i * (alto + 6), ANCHO_FICHA, alto)
		fichas[paginas[i].id] = r
		botones[paginas[i].id].position = r.position
		botones[paginas[i].id].size = r.size
	poner_vecinos()
	poner_hoja()
	queue_redraw()


# La hoja de la página que se mira, a la derecha de las fichas
func poner_hoja() -> void:
	if fichas.is_empty():
		return
	if hoja != null:
		hoja.queue_free()
	var p: Dictionary = del_edificio().filter(func(q): return q.id == vista)[0]
	var x := 24 + ANCHO_FICHA + 16
	var ancho := size.x - x - 20
	var alto_max := alto_hoja()
	hoja = Historia.hoja(p, ancho, alto_max) if Historia.encontrada(s, p.id) else Historia.hoja_arrancada(edificio, p, ancho, alto_max)
	hoja.con_clip = true
	hoja.name = "hoja"
	hoja.position = Vector2(x, ARRIBA_CARPETA + 8)
	add_child(hoja)
	if hoja.size.y > alto_max + 0.5:
		push_warning("La hoja %s no cabe en la carpeta: mide %d y caben %d (letra %d)" % [p.id, hoja.size.y, alto_max, hoja.tam])


# Lo alto que puede ser la hoja sin salirse de la carpeta
func alto_hoja() -> float:
	return size.y - (ARRIBA_CARPETA + 8) - 12


# Con el teclado o el mando: a izquierda y derecha por las pestañas; de una pestaña, abajo, a la primera ficha; arriba
# y abajo por las fichas, y de la primera, arriba, a la pestaña de su edificio. En los bordes no se mueve: si no, Godot
# buscaría solo y se iría a los iconos del escritorio, que el Dosier tapa (va maximizado)
func poner_vecinos() -> void:
	var arriba: Array = pestanas.values()
	var columna: Array = del_edificio().map(func(p): return botones[p.id])
	for i in arriba.size():
		var b: Button = arriba[i]
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(columna[0])
		b.focus_neighbor_right = b.get_path_to(arriba[mini(arriba.size() - 1, i + 1)])
		b.focus_neighbor_left = b.get_path_to(arriba[maxi(0, i - 1)])
	for i in columna.size():
		var b: Button = columna[i]
		b.focus_neighbor_top = b.get_path_to(columna[i - 1] if i > 0 else pestanas[edificio])
		b.focus_neighbor_bottom = b.get_path_to(columna[mini(columna.size() - 1, i + 1)])
		b.focus_neighbor_right = b.get_path_to(b)
		b.focus_neighbor_left = b.get_path_to(b)


# ── El dibujo ──

func _draw() -> void:
	var fuente := get_theme_default_font()
	PLACA.dibujar(self, size)
	if cajas_pestanas.is_empty():
		return
	# arriba a la derecha: las páginas de todos los edificios
	var todas := 0
	var tuyas := 0
	for e in Historia.DOSIERES:
		todas += del_edificio(e).size()
		tuyas += halladas(e)
	var cuenta := Idioma.t("%d / %d páginas") % [tuyas, todas]
	draw_string(fuente, Vector2(size.x - 18 - ancho_texto(fuente, cuenta, 16), 24), cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PLACA.TEXTO)
	# las pestañas de detrás, la carpeta y la pestaña elegida (pegada a la carpeta)
	for e in cajas_pestanas:
		if e != edificio:
			pestana(e, fuente)
	var carpeta := Rect2(10, ARRIBA_CARPETA, size.x - 20, size.y - ARRIBA_CARPETA - 6)
	draw_rect(carpeta, CARPETA_BORDE)
	draw_rect(carpeta.grow(-2), CARPETA)
	draw_rect(Rect2(carpeta.position + Vector2(2, 2), Vector2(carpeta.size.x - 4, 3)), CARPETA.lightened(0.15))   # el canto
	pestana(edificio, fuente)
	for id in fichas:
		ficha(id, fuente)


func encima(b: Button) -> bool:
	return b.has_focus() or (b.is_hovered() and not (Tactil.activo and Tactil.con_dedo))


func texto_pestana(e: String) -> String:
	return "%s  %d/%d" % [nombre_edificio(e), halladas(e), del_edificio(e).size()]   # no-tr


# Una pestaña de la carpeta: el nombre del edificio y su cuenta
func pestana(e: String, fuente: Font) -> void:
	var r: Rect2 = cajas_pestanas[e]
	var elegida := e == edificio
	var caja := Rect2(r.position, r.size + (Vector2(0, 4) if elegida else Vector2.ZERO))
	draw_rect(caja, PLACA.TEXTO if encima(pestanas[e]) else CARPETA_BORDE)
	draw_rect(Rect2(caja.position + Vector2(2, 2), caja.size - Vector2(4, 2 if elegida else 4)), CARPETA if elegida else CARPETA_OSCURA)
	var cuenta := "%d/%d" % [halladas(e), del_edificio(e).size()]   # no-tr
	var ancho_cuenta := ancho_texto(fuente, cuenta, 16)
	var nombre := nombre_edificio(e)
	var hueco := r.size.x - 30 - ancho_cuenta
	var tam := ajustar(fuente, nombre, hueco, 16)
	var base := r.position.y + 6 + fuente.get_ascent(16)
	draw_string(fuente, Vector2(r.position.x + 10, base), nombre, HORIZONTAL_ALIGNMENT_LEFT, hueco, tam, LETRA_CARPETA)
	draw_string(fuente, Vector2(r.end.x - 10 - ancho_cuenta, base), cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		LETRA_CARPETA if elegida else Color("#3e3020"))


# Una ficha de la izquierda: en papel si la tienes («Página N» y su título) o arrancada, con solo «Página N», si falta. La que se mira sale
# un poco hacia la hoja
func ficha(id: String, fuente: Font) -> void:
	var r: Rect2 = fichas[id]
	if id == vista:
		r.position.x += 6
	var p: Dictionary = del_edificio().filter(func(q): return q.id == id)[0]
	var n := del_edificio().find(p) + 1
	var marcada := encima(botones[id])
	var titulo := Idioma.t("Página %d") % n
	if Historia.encontrada(s, id):
		draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Historia.PAPEL)
		draw_rect(r, Color.WHITE if marcada else Historia.PAPEL_BORDE, false, 2.0)
		draw_string(fuente, Vector2(r.position.x + 8, r.position.y + 4 + fuente.get_ascent(16)), titulo,
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, ajustar(fuente, titulo, r.size.x - 16, 16), Historia.ROJO)
		# el título, en las líneas que quepan (la última, con «...» si no cabe entero)
		var lineas := partir(fuente, Historia.titulo_de(p), r.size.x - 16, 16)
		var alto := Historia.HOJA.alto_de(16) + 1
		var caben := maxi(1, floori((r.size.y - 26) / alto))
		for i in mini(caben, lineas.size()):
			var linea: String = lineas[i]
			if i == caben - 1 and lineas.size() > caben:
				linea = cortar(fuente, ("" if Idioma.actual == "zh_CN" else " ").join(lineas.slice(i)), r.size.x - 16, 16)
			draw_string(fuente, Vector2(r.position.x + 8, r.position.y + 24 + i * alto + fuente.get_ascent(16)), linea,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Historia.TINTA)
	else:
		# el trozo que queda de una hoja arrancada: roto por abajo, un poco más abajo de «Página N»
		var azar := RandomNumberGenerator.new()
		azar.seed = hash(id)
		var abajo := minf(r.end.y, r.position.y + 8 + Historia.HOJA.alto_de(16) + 16)
		var forma := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, abajo - 4)])
		var x := r.end.x
		while x > r.position.x:
			x = maxf(r.position.x, x - azar.randf_range(8, 16))
			forma.append(Vector2(x, abajo - azar.randf_range(0, 9)))
		var borde := forma.duplicate()
		borde.append(forma[0])
		draw_colored_polygon(forma, ARRANCADA)
		draw_polyline(borde, Color.WHITE if marcada else Historia.PAPEL_BORDE, 2.0)
		var color := Color("#6a5838")
		var base := r.position.y + 4 + fuente.get_ascent(16)
		draw_string(fuente, Vector2(r.position.x + 8, base), titulo, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, ajustar(fuente, titulo, r.size.x - 16, 16), color)


func ancho_texto(fuente: Font, texto: String, tam: int) -> float:
	return fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x


# El tamaño de letra (desde "tam", de 2 en 2, hasta 10) con el que el texto cabe en "ancho"
func ajustar(fuente: Font, texto: String, ancho: float, tam: int) -> int:
	while tam > 10 and ancho_texto(fuente, texto, tam) > ancho:
		tam -= 2
	return tam


# El texto cortado con «...» si no cabe en "ancho"
func cortar(fuente: Font, texto: String, ancho: float, tam: int) -> String:
	if ancho_texto(fuente, texto, tam) <= ancho:
		return texto
	while texto.length() > 1 and ancho_texto(fuente, texto + "...", tam) > ancho:
		texto = texto.left(-1)
	return texto.strip_edges() + "..."


# Las líneas de un texto con un ancho fijo (las mismas reglas que la hoja: el chino se parte por cualquier letra)
func partir(fuente: Font, texto: String, ancho: float, tam: int) -> Array:
	var salen := []
	var linea := ""
	for trozo in Historia.HOJA.trocear(texto):
		var prueba: String = linea + (" " if trozo[1] and linea != "" else "") + trozo[0]
		if linea != "" and ancho_texto(fuente, prueba, tam) > ancho:
			salen.append(linea)
			linea = trozo[0]
		else:
			linea = prueba
	salen.append(linea)
	return salen
