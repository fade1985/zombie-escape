# Los logros del ordenador (LOGROS.EXE, en ordenador.gd), como un archivador: la misma chapa oscura que el árbol de
# talentos y la tienda de armas (chapa.gd), con lo ahorrado arriba a la izquierda y, a la derecha, cuántos logros
# llevas y cuánto tienes por cobrar.
#
# A la izquierda, un botón por página: «Resumen» y un apartado por tema (Logros.TEMAS), cada uno con su barrita de
# progreso, su cuenta (3/9) y un «!» amarillo si tiene algo por cobrar. A la derecha, la página elegida:
#   - Resumen: lo que hay por cobrar (o, si no hay nada, lo que tienes casi hecho) y «Cómo vas»: una barra con todos los
#     logros y una por apartado.
#   - Un apartado: sus logros en filas, con el icono, el nombre (y su barra si se hace varias veces), lo que pide y, a
#     la derecha, la placa del premio: apagada si aún no lo tienes, amarilla («Cobrar $X») si falta cobrarlo y verde
#     («Hecho») si ya está cobrado.
# Se cobra pulsando la fila. Lo que pide entero sale en la línea de abajo del ordenador al pasar por encima.
#
# Todo se dibuja con código (_draw); encima de cada fila y de cada botón de la izquierda hay un botón transparente
# ("b_<id>" para los logros, "b_tema_<tema>" para las páginas), que es el que se marca y se pulsa
extends Control

const PLACA := preload("res://scripts/ui/chapa.gd")
const VERDE := Color("#7fa86a")
const VERDE_BORDE := Color("#5f8a4f")
const ANCHO_TEMAS := 160             # la columna de los botones de la izquierda
const ALTO_FILA := 36                # lo más alta que es una fila (si no caben, menos)
const ANCHO_PREMIO := 92             # la placa del premio
const ALTO_BARRA := 20               # las barras de «Cómo vas»

# La página que se ve ("resumen" o un tema). Se queda al volver a montar la ventana (al cobrar o cambiar de página)
static var pagina := "resumen"

const EXCLAMACION := preload("res://assets/ui/exclamacion-pequena.png")
var ordenador: Node
var s: Dictionary                    # el guardado
var temas := {}                      # tema (o "resumen") → su botón de la izquierda
var cajas_temas := {}                # tema → su recuadro
var botones := {}                    # id del logro → su botón (la fila)
var filas := {}                      # id del logro → su recuadro
var visibles := []                   # los logros de la página, en orden
var sobran := 0                      # en el Resumen, los que no caben en «Por cobrar»
var casi := false                    # en el Resumen, si enseña «Casi lo tienes» (no hay nada por cobrar)
var titulo_y := 0.0                  # en el Resumen, dónde va el título de arriba, y el de «Cómo vas»
var como_vas_y := 0.0


func montar(o: Node, guardado: Dictionary) -> void:
	ordenador = o
	s = guardado
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 400)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if pagina != "resumen" and not Logros.TEMAS.has(pagina):
		pagina = "resumen"
	for t in ["resumen"] + Logros.TEMAS.keys():
		var b := boton_transparente("b_tema_" + t)
		b.pressed.connect(cambiar_pagina.bind(t))
		temas[t] = b
	visibles = logros_de_la_pagina()
	for id in visibles:
		botones[id] = boton_transparente("b_" + id)
	resized.connect(colocar)


func boton_transparente(nombre: String) -> Button:
	var b := Button.new()
	b.name = nombre
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	for senal in [b.mouse_entered, b.mouse_exited, b.focus_entered, b.focus_exited, b.button_down, b.button_up]:
		senal.connect(queue_redraw)   # (lo que está debajo del ratón o marcado se dibuja con el borde claro)
	add_child(b)
	return b


# Al pulsar un botón de la izquierda: se monta la ventana otra vez con esa página
func cambiar_pagina(t: String) -> void:
	if t == pagina:
		return
	pagina = t
	Sonido.tocar("click")
	ordenador.abrir("logros", "b_tema_" + t)


# ── Cómo está cada logro ──

func estado(id: String) -> String:
	return Logros.estado(s, id)


func meta(l: Dictionary) -> int:
	return Logros.meta(l)


# Cuánto lleva (lo hecho, como mucho la meta)
func hecho(l: Dictionary) -> int:
	return meta(l) if estado(l.id) != "pendiente" else mini(ordenador.partida.logros.progreso(l.id, s), meta(l))


func de_tema(t: String) -> Array:
	return Logros.LISTA.filter(func(l): return l.tema == t)


func conseguidos(lista: Array) -> int:
	return lista.filter(func(l): return estado(l.id) != "pendiente").size()


func por_cobrar(lista: Array) -> Array:
	return lista.filter(func(l): return estado(l.id) == "conseguido")


# Los logros de la página: los de su tema o, en el Resumen, los que hay por cobrar (o, si no hay, los que van más
# avanzados de los que se hacen varias veces: «Casi lo tienes»)
func logros_de_la_pagina() -> Array:
	if pagina != "resumen":
		return de_tema(pagina).map(func(l): return l.id)
	var lista := por_cobrar(Logros.LISTA)
	casi = lista.is_empty()
	if casi:
		lista = Logros.LISTA.filter(func(l): return estado(l.id) == "pendiente" and meta(l) > 1 and hecho(l) > 0 and hecho(l) < meta(l))
		lista.sort_custom(func(a, b): return float(hecho(a)) / meta(a) > float(hecho(b)) / meta(b))
	return lista.map(func(l): return l.id)


# ── Dónde va cada cosa (al cambiar de tamaño) ──

func colocar() -> void:
	if size.x < ANCHO_TEMAS * 3 or size.y < 200:
		return   # (aún sin su tamaño de verdad)
	var margen := 10.0
	var arriba := PLACA.ARRIBA + 6.0
	# los botones de la izquierda, del mismo alto, hasta abajo
	var lista_temas: Array = temas.keys()
	var alto_tema := floorf((size.y - arriba - margen + 4) / lista_temas.size() - 4)
	for i in lista_temas.size():
		var r := Rect2(margen + 4, arriba + i * (alto_tema + 4), ANCHO_TEMAS, alto_tema)
		cajas_temas[lista_temas[i]] = r
		temas[lista_temas[i]].position = r.position
		temas[lista_temas[i]].size = r.size
	# las filas de la derecha
	var x := margen + 4 + ANCHO_TEMAS + 12
	var ancho := size.x - x - margen - 4
	var y := arriba
	var tope := size.y - margen
	sobran = 0
	if pagina == "resumen":
		if ordenador.partida.logros.sin_logros():
			y += 20   # (el aviso de las ayudas)
		titulo_y = y
		y += 24
		var alto_como_vas := 24 + ALTO_BARRA + 8 + ceili(Logros.TEMAS.size() / 2.0) * (ALTO_BARRA + 6)
		como_vas_y = tope - alto_como_vas
		tope = como_vas_y - 6
		var caben := maxi(0, floori((tope - y + 4) / (ALTO_FILA + 4)))
		if visibles.size() > caben:   # (por cobrar, la última línea dice cuántos más hay; de los casi hechos, solo los que caben)
			sobran = visibles.size() - (caben if casi else caben - 1)
	var alto := minf(ALTO_FILA, floorf((tope - y + 4) / maxf(1, visibles.size()) - 4)) if pagina != "resumen" else float(ALTO_FILA)
	filas.clear()
	for i in visibles.size():
		var id: String = visibles[i]
		var dentro := sobran == 0 or i < visibles.size() - sobran
		botones[id].visible = dentro
		if not dentro:
			continue
		var r := Rect2(x, y + i * (alto + 4), ancho, alto)
		filas[id] = r
		botones[id].position = r.position
		botones[id].size = r.size
	poner_vecinos()
	queue_redraw()


# Con el teclado o el mando: arriba y abajo por los botones de la izquierda y por las filas; de un botón de la izquierda,
# a la derecha, a la primera fila; de una fila, a la izquierda, a su página. Arriba y abajo del todo no se mueve (si no,
# Godot buscaría solo y se iría a los iconos del escritorio); a la izquierda de los botones sí se sale a ellos
func poner_vecinos() -> void:
	var izquierda: Array = temas.values()
	var derecha: Array = visibles.filter(func(id): return filas.has(id)).map(func(id): return botones[id])
	for columna in [izquierda, derecha]:
		for i in columna.size():
			var b: Button = columna[i]
			b.focus_neighbor_top = b.get_path_to(columna[maxi(0, i - 1)])
			b.focus_neighbor_bottom = b.get_path_to(columna[mini(columna.size() - 1, i + 1)])
	for b: Button in izquierda:
		b.focus_neighbor_right = b.get_path_to(derecha[0] if not derecha.is_empty() else b)
	for b: Button in derecha:
		b.focus_neighbor_left = b.get_path_to(temas[pagina])
		b.focus_neighbor_right = b.get_path_to(b)


# ── El dibujo ──

func _draw() -> void:
	var fuente := get_theme_default_font()
	PLACA.dibujar(self, size)
	PLACA.dibujar_ahorrado(self, fuente, s.dolares)
	if cajas_temas.is_empty():
		return
	# arriba a la derecha: cuántos logros llevas (lo que falta por cobrar lo avisa el «!» de cada apartado)
	var texto_logros := Idioma.t("Logros %d/%d") % [conseguidos(Logros.LISTA), Logros.LISTA.size()]
	var ancho_logros := fuente.get_string_size(texto_logros, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(fuente, Vector2(size.x - 16 - ancho_logros, 28), texto_logros, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PLACA.TEXTO)
	for t in cajas_temas:
		dibujar_tema(t, fuente)
	if pagina == "resumen":
		dibujar_resumen(fuente)
	for id in filas:
		dibujar_fila(id, fuente)


# Lo marcado: lo que tiene el foco o lo que está debajo del ratón (no con el dedo, ni jugando con el mando: el ratón
# quieto encima de una fila la dejaba iluminada y A pulsaba la que de verdad tiene el foco)
func encima(b: Button) -> bool:
	return b.has_focus() or (b.is_hovered() and not (Tactil.activo and Tactil.con_dedo) and not Controles.con_mando)


# Un botón de la izquierda: su nombre y, los de los temas, su barrita, su cuenta y el «!» si hay algo por cobrar
func dibujar_tema(t: String, fuente: Font) -> void:
	var r: Rect2 = cajas_temas[t]
	var elegido := t == pagina
	draw_rect(r, PLACA.TEXTO if encima(temas[t]) else (PLACA.AMARILLO.darkened(0.3) if elegido else PLACA.APAGADO))
	draw_rect(r.grow(-2), Color("#3a3f47") if elegido else Color("#2b2f36"))
	var lista: Array = Logros.LISTA if t == "resumen" else de_tema(t)
	var hay_cobrar := not por_cobrar(lista).is_empty()
	var nombre := Idioma.t("Resumen") if t == "resumen" else Logros.nombre_tema(t)
	var ancho := r.size.x - 16 - (14 if hay_cobrar else 0)
	var tam := ajustar(fuente, nombre, ancho, 16)
	var en_medio := t == "resumen" or r.size.y < 34   # (sin barrita: el nombre en medio)
	var base := r.position.y + (r.size.y / 2.0 + fuente.get_ascent(tam) / 2.0 - 2 if en_medio else 4 + fuente.get_ascent(tam))
	draw_string(fuente, Vector2(r.position.x + 8, base), nombre, HORIZONTAL_ALIGNMENT_LEFT, ancho, tam,
		PLACA.AMARILLO if elegido else PLACA.TEXTO)
	if hay_cobrar:
		# el «!» de GPT, de amarillo a naranja (M3; el mismo que en los iconos del escritorio)
		draw_texture(EXCLAMACION, Vector2(r.end.x - 15, r.position.y + 4))
	if en_medio:
		return
	var cuenta := "%d/%d" % [conseguidos(lista), lista.size()]
	var ancho_cuenta := fuente.get_string_size(cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	barra(Rect2(r.position.x + 8, r.end.y - 12, r.size.x - 24 - ancho_cuenta, 7), conseguidos(lista), lista.size())
	draw_string(fuente, Vector2(r.end.x - 8 - ancho_cuenta, r.end.y - 5), cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PLACA.TEXTO_SUAVE)


# Una barra hundida, rellena hasta donde va: en amarillo mientras falta y en verde al completarla. "oscura": las de
# «Cómo vas», que llevan el texto encima, con el color algo más apagado para que se lea
func barra(r: Rect2, n: int, total: int, oscura := false) -> void:
	var color := VERDE if n >= total else PLACA.AMARILLO
	if oscura:
		color = color.darkened(0.3)
	draw_rect(r, PLACA.REMACHE)
	draw_rect(r.grow(-1), Color("#0d1012"))
	if total > 0 and n > 0:
		draw_rect(Rect2(r.position + Vector2(1, 1), Vector2((r.size.x - 2) * minf(1.0, float(n) / total), r.size.y - 2)), color)


func titulo(fuente: Font, y: float, texto: String, color: Color) -> void:
	var x: float = cajas_temas["resumen"].end.x + 12
	draw_string(fuente, Vector2(x, y + 15), texto.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 14, 16, color)
	draw_rect(Rect2(x, y + 19, size.x - x - 14, 2), PLACA.APAGADO)


# El Resumen: el aviso de las ayudas, el título de lo de arriba (las filas se dibujan aparte), cuántos más hay y
# «Cómo vas»: todos los logros y cada apartado, con su nombre y su cuenta encima de la barra
func dibujar_resumen(fuente: Font) -> void:
	var x: float = cajas_temas["resumen"].end.x + 12
	var ancho := size.x - x - 14
	if ordenador.partida.logros.sin_logros():
		draw_string(fuente, Vector2(x, titulo_y - 6), Idioma.t("Partida con ayudas: no da logros"), HORIZONTAL_ALIGNMENT_LEFT, ancho, 14, Color("#e8884a"))
	if casi:
		titulo(fuente, titulo_y, Idioma.t("Casi lo tienes"), PLACA.TEXTO_SUAVE)
	else:
		titulo(fuente, titulo_y, Idioma.t("Por cobrar"), PLACA.AMARILLO)
	if sobran > 0 and not casi:
		var y := titulo_y + 24 + (visibles.size() - sobran) * (ALTO_FILA + 4) + 18
		draw_string(fuente, Vector2(x, y), Idioma.t("Y %d más: búscalos por el «!» de la izquierda.") % sobran, HORIZONTAL_ALIGNMENT_LEFT, ancho, 14, PLACA.AMARILLO)
	titulo(fuente, como_vas_y, Idioma.t("Cómo vas"), PLACA.TEXTO_SUAVE)
	var y := como_vas_y + 26
	var total := Rect2(x, y, ancho, ALTO_BARRA)
	barra(total, conseguidos(Logros.LISTA), Logros.LISTA.size(), true)
	con_sombra(fuente, total, Idioma.t("Logros conseguidos"), "%d/%d" % [conseguidos(Logros.LISTA), Logros.LISTA.size()])
	y += ALTO_BARRA + 8
	var mitad := floorf((ancho - 6) / 2.0)
	var i := 0
	for t in Logros.TEMAS:
		var r := Rect2(x + (i % 2) * (mitad + 6), y + (i / 2) * (ALTO_BARRA + 6), mitad, ALTO_BARRA)
		var lista := de_tema(t)
		barra(r, conseguidos(lista), lista.size(), true)
		con_sombra(fuente, r, Logros.nombre_tema(t), "%d/%d" % [conseguidos(lista), lista.size()])
		i += 1


# El nombre a la izquierda y la cuenta a la derecha, encima de una barra, con sombra para que se lean sobre el color
func con_sombra(fuente: Font, r: Rect2, nombre: String, cuenta: String) -> void:
	var ancho_cuenta := fuente.get_string_size(cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var ancho := r.size.x - ancho_cuenta - 20
	var tam := ajustar(fuente, nombre, ancho, 14)
	var base := r.position.y + r.size.y / 2.0 + fuente.get_ascent(14) / 2.0 - 2
	for capa in [[Vector2(1, 1), Color.BLACK], [Vector2.ZERO, PLACA.TEXTO]]:
		draw_string(fuente, Vector2(r.position.x + 6, base) + capa[0], nombre, HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, capa[1])
		draw_string(fuente, Vector2(r.end.x - 6 - ancho_cuenta, base) + capa[0], cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, capa[1])


# Una fila: el icono (apagado si aún no lo tienes), el nombre, su barra y cuánto lleva si se hace varias veces, lo que
# pide (cortado si no cabe: entero sale en la línea de abajo) y la placa del premio. Lo que falta cobrar, en amarillo
func dibujar_fila(id: String, fuente: Font) -> void:
	var r: Rect2 = filas[id]
	var l := Logros.datos(id)
	var e := estado(id)
	var cobrar := e == "conseguido"
	draw_rect(r, PLACA.TEXTO if encima(botones[id]) else (PLACA.AMARILLO if cobrar else PLACA.APAGADO))
	draw_rect(r.grow(-2), Color("#3a3520") if cobrar else Color("#2b2f36"))
	var lado := minf(32.0, r.size.y - 4)
	draw_texture_rect(icono(l.icono), en_caja(icono(l.icono), Vector2(r.position.x + 5 + lado / 2.0, r.get_center().y), lado), false,
		Color(0.55, 0.55, 0.55, 0.75) if e == "pendiente" else Color.WHITE)
	var x := r.position.x + lado + 12
	var ancho := r.end.x - ANCHO_PREMIO - 10 - x
	var con_desc := r.size.y >= 30
	var nombre := Logros.nombre_de(id)
	var base := r.position.y + (fuente.get_ascent(16) + 1 if con_desc else r.size.y / 2.0 + fuente.get_ascent(16) / 2.0 - 2)
	draw_string(fuente, Vector2(x, base), nombre, HORIZONTAL_ALIGNMENT_LEFT, ancho, 16,
		PLACA.AMARILLO if cobrar else (PLACA.TEXTO if e == "cobrado" else Color("#b8b2a0")))
	var m := meta(l)
	if m > 1 and e == "pendiente":
		var cuenta := "%d/%d" % [hecho(l), m]
		var ancho_cuenta := fuente.get_string_size(cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var bx := x + fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 8
		var ancho_barra := minf(70.0, x + ancho - ancho_cuenta - 6 - bx)
		if ancho_barra >= 24:
			barra(Rect2(bx, base - 10, ancho_barra, 9), hecho(l), m)
			draw_string(fuente, Vector2(bx + ancho_barra + 6, base), cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PLACA.TEXTO_SUAVE)
	if con_desc:
		draw_string(fuente, Vector2(x, r.end.y - 5), cortar(fuente, Logros.desc_de(id), ancho, 14), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PLACA.TEXTO_SUAVE)
	dibujar_premio(Rect2(r.end.x - ANCHO_PREMIO - 6, r.get_center().y - 11, ANCHO_PREMIO, 22), l, e, fuente)


# La placa del premio: apagada con lo que da, amarilla («Cobrar $X») o verde («Hecho»)
func dibujar_premio(r: Rect2, l: Dictionary, e: String, fuente: Font) -> void:
	var texto := "$%d" % l.premio
	var color := PLACA.TEXTO_SUAVE
	var borde := PLACA.APAGADO
	var relleno := PLACA.NEGRO
	if e == "conseguido":
		texto = Idioma.t("Cobrar $%d") % l.premio
		color = PLACA.AMARILLO
		borde = PLACA.AMARILLO
		relleno = Color("#5a4a10")
	elif e == "cobrado":
		texto = Idioma.t("Hecho")
		color = VERDE
		borde = VERDE_BORDE
		relleno = Color("#1f2a1c")
	draw_rect(r, borde)
	draw_rect(r.grow(-2), relleno)
	var tam := ajustar(fuente, texto, r.size.x - 8, 16)
	draw_string(fuente, Vector2(r.position.x, r.get_center().y + fuente.get_ascent(tam) / 2.0 - 2), texto,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam, color)


# El tamaño de letra (desde "tam", de 2 en 2, hasta 10) con el que el texto cabe en "ancho"
func ajustar(fuente: Font, texto: String, ancho: float, tam: int) -> int:
	while tam > 10 and fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
		tam -= 2
	return tam


# El texto cortado con «...» si no cabe en "ancho"
func cortar(fuente: Font, texto: String, ancho: float, tam: int) -> String:
	if fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
		return texto
	while texto.length() > 1 and fuente.get_string_size(texto + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
		texto = texto.left(-1)
	return texto.strip_edges() + "..."


# El sitio de un icono dentro de un cuadrado de lado «lado» con centro «c», sin estirarlo: los de GPT (logro-*.png) no
# siempre son cuadrados, y el lado más largo llena el cuadrado (igual que en ui/arbol_talentos.gd)
func en_caja(tex: Texture2D, c: Vector2, lado: float) -> Rect2:
	var t := tex.get_size() * (lado / maxf(tex.get_width(), tex.get_height()))
	return Rect2(c - t / 2.0, t)


# Los iconos se cargan una vez (assets/ui/iconos)
var iconos := {}
func icono(id: String) -> Texture2D:
	if not iconos.has(id):
		iconos[id] = load("res://assets/ui/iconos/%s.png" % id)
	return iconos[id]
