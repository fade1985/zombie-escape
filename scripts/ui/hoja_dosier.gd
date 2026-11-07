# Una página del dosier VD-7 dibujada como un expediente de Velaria Corp. (la monta Historia.hoja() o
# Historia.hoja_arrancada()). Sale en la ventanita de «página encontrada» (menus.gd) y en el Dosier del ordenador
# (carpeta_dosier.gd). Todo se dibuja con código (_draw):
#   - el papel viejo, con motitas y un cerco de café (cada página, siempre las mismas: salen de su id);
#   - arriba, el logo de Velaria (inventado: una luna creciente dentro de un círculo, porque el VD-7 se vende para
#     dormir), «VELARIA CORP.», «Investigación del sueño», un código de barras y la referencia (VD7-AP-01: el
#     edificio y el número de página);
#   - una franja con el edificio, dónde se encontró y el número de página;
#   - el tipo de papel en rojo, el título grande, una raya y el sello rojo y gastado de «CONFIDENCIAL», girado;
#   - el texto, a todo lo ancho (sin foto: el dueño la quitó el 7 nov);
#   - la nota a mano, en un pósit amarillo algo torcido, abajo a la derecha.
# Las que aún no se tienen («Página arrancada») son solo el trozo de arriba, roto por abajo, con lo que dice
# Historia.falta() en vez del texto.
#
# Que quepa todo: la hoja mide de alto lo que necesita. Si con eso pasa de "alto_max", prueba con la letra más
# pequeña (del texto, 16 → 14 → 12; y el título, de 32 a 16) hasta que quepa; si ni así, crece. Nunca se corta texto
extends Control

const PAPEL := Color("#e9dfc4")
const BORDE := Color("#b8a983")
const TINTA := Color("#2a2520")
const GRIS := Color("#6a5f50")
const ROJO := Color("#a3312b")
const BOLI := Color("#1f3c8a")
const POSIT := Color("#f2e27a")
const MARGEN := 14.0
const CODIGOS := {"apartamentos": "AP", "centro": "CC", "torre": "TV"}   # no-tr
# Los signos del chino que no pueden empezar una línea (se quedan pegados a lo de antes)
const PEGADOS := "，。、；：！？）」』》〉…—·"   # no-tr

var p: Dictionary
var edificio := ""
var numero := 1
var total := 1
var arrancada := false
var con_clip := false                # un clip arriba (el de la carpeta del ordenador)
var fuente: Font

# Lo que sale de colocar()
var tam := 16                        # la letra del texto (y de la nota)
var tam_titulo := 32
var tam_franja := 16
var compacta := false                # la cabecera más baja (la del ordenador, cuando no cabe la de siempre)
var alto_linea := 18.0
var franja_y := 64.0                 # donde va la franja del edificio
var tipo_y := 96.0                   # el tipo de papel (en rojo) y, debajo, el título
var titulo_y := 0.0
var cuerpo_y := 0.0                  # donde empieza lo de debajo de la raya
var lineas := []                     # [texto, posición de su base]
var caja_posit := Rect2()
var lineas_posit := []               # [texto, posición dentro del pósit]
var escrito := ""                    # el texto (o lo que dice falta())
var a_mano := ""                     # la nota ("" = sin pósit)
var semilla := 0

# Lo que se va probando hasta que cabe: [letra del texto, letra del título, cabecera compacta]
const PRUEBAS := [[16, 32, false], [14, 32, false], [14, 16, false], [14, 16, true], [12, 16, true], [10, 16, true]]


func montar(pagina: Dictionary, ed: String, n: int, de: int, rota: bool, ancho: float, alto_max: float) -> void:
	p = pagina
	edificio = ed
	numero = n
	total = de
	arrancada = rota
	fuente = Tema.FUENTE
	semilla = hash(str(p.get("id", "")))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	escrito = Historia.falta(edificio, p) if arrancada else Idioma.t(p.texto)
	a_mano = "" if arrancada else Idioma.t(p.get("nota", ""))
	# de la letra más grande a la más pequeña, hasta que quepa
	var alto := 0.0
	for prueba in PRUEBAS:
		alto = colocar(ancho, prueba[0], prueba[1], prueba[2])
		if alto <= alto_max:
			break
	custom_minimum_size = Vector2(ancho, alto)
	size = custom_minimum_size
	queue_redraw()


# Coloca todo con esa letra y devuelve lo alto que queda la hoja
func colocar(ancho: float, t: int, t_titulo: int, compacto: bool) -> float:
	tam = t
	tam_titulo = t_titulo
	compacta = compacto
	alto_linea = alto_de(tam) + 1.0
	franja_y = 36.0 if compacta else 64.0
	tipo_y = franja_y + (26.0 if compacta else 32.0)
	titulo_y = tipo_y + fuente.get_height(16) + (1 if compacta else 2)
	cuerpo_y = titulo_y + fuente.get_height(tam_titulo) + (8 if compacta else 12)
	# la franja: los tres textos en una línea (si no caben, con la letra más pequeña)
	tam_franja = 16
	while tam_franja > 10 and ancho_de(texto_edificio(), tam_franja) + ancho_de(texto_hallado(), tam_franja) \
			+ ancho_de(texto_numero(), tam_franja) + 64 > ancho - 2 * MARGEN:
		tam_franja -= 2
	lineas.clear()
	lineas_posit.clear()
	caja_posit = Rect2()
	var izquierda := MARGEN + 4
	var derecha := ancho - MARGEN - 4
	var y := escribir(escrito, cuerpo_y + 2, func(_y): return Vector2(izquierda, derecha - izquierda))
	if arrancada:
		return y + 34   # (y el trozo roto de abajo)
	var fondo := y
	if a_mano != "":
		# el pósit, abajo a la derecha, debajo del texto
		var ancho_posit := minf(330.0, (derecha - izquierda) * 0.6)
		var trozos := partir(a_mano, ancho_posit - 20)
		caja_posit = Rect2(derecha - ancho_posit, y + 6, ancho_posit, 14.0 + trozos.size() * alto_linea + 6)
		for i in trozos.size():
			lineas_posit.append([trozos[i], Vector2(10, 12 + fuente.get_ascent(tam) + i * alto_linea)])
		fondo = caja_posit.end.y + 4
	return fondo + MARGEN


# Parte el texto en líneas y las va poniendo desde "y". "sitio(y)" dice, para una línea que empieza en y, desde dónde
# y con qué ancho se escribe. Devuelve dónde acaba
func escribir(texto: String, y: float, sitio: Callable) -> float:
	for parrafo in texto.split("\n"):
		if parrafo.strip_edges() == "":
			y += alto_linea / 2.0
			continue
		var linea := ""
		var hueco: Vector2 = sitio.call(y)
		for trozo in trocear(parrafo):
			var prueba: String = linea + (" " if trozo[1] and linea != "" else "") + trozo[0]
			if linea != "" and ancho_de(prueba, tam) > hueco.y:
				lineas.append([linea, Vector2(hueco.x, y + fuente.get_ascent(tam))])
				y += alto_linea
				hueco = sitio.call(y)
				linea = trozo[0]
			else:
				linea = prueba
		lineas.append([linea, Vector2(hueco.x, y + fuente.get_ascent(tam))])
		y += alto_linea
	return y


# Las líneas de un texto con un ancho fijo (el pósit)
func partir(texto: String, ancho: float) -> Array:
	var salen := []
	for parrafo in texto.split("\n"):
		var linea := ""
		for trozo in trocear(parrafo):
			var prueba: String = linea + (" " if trozo[1] and linea != "" else "") + trozo[0]
			if linea != "" and ancho_de(prueba, tam) > ancho:
				salen.append(linea)
				linea = trozo[0]
			else:
				linea = prueba
		salen.append(linea)
	return salen


# Los trozos por los que se puede partir una línea: [trozo, si lleva un espacio delante]. Las palabras van separadas
# por espacios; el chino no los usa: cada letra es un trozo (menos los signos que no pueden empezar línea)
static func trocear(parrafo: String) -> Array:
	var trozos := []
	var palabra := ""
	var espacio_antes := false
	var espacio := false
	for c in parrafo:
		if c == " ":
			if palabra != "":
				trozos.append([palabra, espacio_antes])
				palabra = ""
			espacio = true
		elif c.unicode_at(0) >= 0x2E80 or (c in PEGADOS and c != "—" and c != "·"):
			if palabra != "":
				trozos.append([palabra, espacio_antes])
				palabra = ""
			if c in PEGADOS and not trozos.is_empty() and not espacio:
				trozos.back()[0] += c
			else:
				trozos.append([c, espacio])
			espacio = false
		else:
			if palabra == "":
				espacio_antes = espacio
			palabra += c
			espacio = false
	if palabra != "":
		trozos.append([palabra, espacio_antes])
	return trozos


# Lo alto de una línea con esa letra: lo que mide la del juego (a 16, 17), a escala. No se le pregunta a la fuente:
# con las letras de reserva del ruso y del chino, a 10, 12 o 14 dice bastante más (a 16 están igualadas, tema.gd)
static func alto_de(t: int) -> float:
	return roundf(17.0 * t / 16.0)


func ancho_de(texto: String, t: int) -> float:
	return fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x


func texto_edificio() -> String:
	var nombre: String = Idioma.t(Edificios.datos(edificio).nombre) if edificio in Edificios.LISTA else edificio
	return Idioma.t("EDIFICIO: %s") % nombre


func texto_hallado() -> String:
	if arrancada:
		return Idioma.t("HALLADO EN: %s") % "???"   # no-tr
	var donde := Historia.donde(p, edificio)
	return Idioma.t("HALLADO EN: %s") % (donde.left(1).to_upper() + donde.substr(1))


func texto_numero() -> String:
	return "%d / %d" % [numero, total]   # no-tr


func referencia() -> String:
	return "VD7-%s-%02d" % [CODIGOS.get(edificio, edificio.left(2).to_upper()), numero]   # no-tr


# ── El dibujo ──

func _draw() -> void:
	var w := size.x
	var h := size.y
	papel(w, h)
	cabecera(w)
	sello(w)
	for l in lineas:
		draw_string(fuente, l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, tam, TINTA)
	if not arrancada and a_mano != "":
		posit()
	if con_clip:
		clip(Vector2(w - MARGEN - 134 - 30, -14))   # (entre el nombre y el código de barras)


# El papel (con su sombra): motitas, un cerco de café y, si está arrancada, roto por abajo
func papel(w: float, h: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var forma := PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	if arrancada:
		# el borde roto: dientes de distinto tamaño, de derecha a izquierda
		var x := w
		forma.append(Vector2(w, h - 14))
		while x > 0:
			x = maxf(0, x - r.randf_range(8, 20))
			forma.append(Vector2(x, h - r.randf_range(0, 18)))
		forma.append(Vector2(0, h - 10))
	else:
		forma.append_array([Vector2(w, h), Vector2(0, h)])
	var sombra := PackedVector2Array()
	for punto in forma:
		sombra.append(punto + Vector2(4, 4))
	draw_colored_polygon(sombra, Color(0, 0, 0, 0.45))
	draw_colored_polygon(forma, PAPEL)
	var borde := forma.duplicate()
	borde.append(forma[0])
	draw_polyline(borde, BORDE, 2.0)
	for i in int(w * h / 3500):
		var t: int = [1, 1, 2, 2, 3][r.randi_range(0, 4)]
		var punto := Vector2(r.randf_range(3, w - 6), r.randf_range(3, h - 24 if arrancada else h - 6))
		draw_rect(Rect2(punto, Vector2(t, t)), Color(0.59, 0.51, 0.37, r.randf_range(0.15, 0.4)))
	# el cerco de café, abajo a la derecha
	var centro := Vector2(w * r.randf_range(0.7, 0.86), h * (0.45 if arrancada else 0.8))
	for a in range(0, 360, 4):
		var punto := centro + Vector2.from_angle(deg_to_rad(a)) * 30.0
		draw_rect(Rect2(punto.floor(), Vector2(2, 2)), Color(0.55, 0.39, 0.24, 0.27))


# Arriba: el logo, el nombre, el código de barras con la referencia, la franja, el tipo, el título y la raya. La
# compacta, más baja: el logo más pequeño y el nombre con la letra de siempre
func cabecera(w: float) -> void:
	var x := w - MARGEN - 134
	if compacta:
		# todo en una línea: el logo, el nombre y, si cabe, «Investigación del sueño»
		logo(Vector2(MARGEN + 2, 6), 24.0)
		var nombre := Historia.EMPRESA.to_upper()
		draw_string(fuente, Vector2(MARGEN + 34, 10 + fuente.get_ascent(16)), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TINTA)
		var detras := MARGEN + 34 + ancho_de(nombre, 16) + 12
		var lema := Idioma.t("Investigación del sueño")
		if detras + ancho_de(lema, 16) < x - 12:
			draw_string(fuente, Vector2(detras, 10 + fuente.get_ascent(16)), lema, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GRIS)
	else:
		logo(Vector2(MARGEN + 2, 12), 36.0)
		draw_string(fuente, Vector2(MARGEN + 46, 12 + fuente.get_ascent(32) - 2), Historia.EMPRESA.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, TINTA)
		draw_string(fuente, Vector2(MARGEN + 48, 56), Idioma.t("Investigación del sueño"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GRIS)
	var alto_barras := 10.0 if compacta else 24.0
	for i in 45:   # el código de barras del registro
		if (i * 7) % 5 != 1:
			draw_rect(Rect2(x + i * 3, 4 if compacta else 12, 2 if i % 3 == 0 else 1, alto_barras), TINTA)
	draw_string(fuente, Vector2(x, 30 if compacta else 54), Idioma.t("REF: %s") % referencia(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TINTA)
	# la franja: edificio, dónde se encontró y número
	var franja := Rect2(MARGEN - 2, franja_y, w - 2 * MARGEN + 4, 22 if compacta else 24)
	draw_rect(franja, TINTA, false, 2.0)
	var base := franja.position.y + franja.size.y / 2.0 + fuente.get_ascent(tam_franja) / 2.0 - 1
	var izq := texto_edificio()
	var der := texto_numero()
	draw_string(fuente, Vector2(franja.position.x + 8, base), izq, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_franja, TINTA)
	draw_string(fuente, Vector2(franja.end.x - 8 - ancho_de(der, tam_franja), base), der, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_franja, TINTA)
	var medio_x := franja.position.x + 8 + ancho_de(izq, tam_franja) + 24
	var medio_ancho := franja.end.x - 8 - ancho_de(der, tam_franja) - 24 - medio_x
	draw_string(fuente, Vector2(medio_x, base), texto_hallado(), HORIZONTAL_ALIGNMENT_CENTER, medio_ancho, tam_franja, TINTA)
	# el tipo, el título y la raya
	var tipo := "???" if arrancada else Idioma.t(p.tipo)   # no-tr
	draw_string(fuente, Vector2(MARGEN + 2, tipo_y + fuente.get_ascent(16)), tipo, HORIZONTAL_ALIGNMENT_LEFT, w - 2 * MARGEN, 16, ROJO)
	var titulo: String = (Idioma.t("Página arrancada") if arrancada else Historia.titulo_de(p)).to_upper()
	var t := tam_titulo
	if ancho_de(titulo, t) > w - 2 * MARGEN:
		t = 16
	draw_string(fuente, Vector2(MARGEN + 2, titulo_y + fuente.get_ascent(t)), titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, t, TINTA)
	draw_rect(Rect2(MARGEN + 2, cuerpo_y - 6, w - 2 * MARGEN - 4, 2), Color(TINTA, 0.8))


# El logo de Velaria (inventado): una luna creciente dentro de un círculo
func logo(esquina: Vector2, lado: float) -> void:
	var centro := esquina + Vector2(lado, lado) / 2.0
	draw_arc(centro, lado / 2.0 - 1.5, 0, TAU, 40, TINTA, 3.0)
	draw_circle(centro, lado / 2.0 - 8, TINTA)
	draw_circle(centro + Vector2(5, -3), lado / 2.0 - 9, PAPEL)


# El sello de «CONFIDENCIAL»: rojo, en un recuadro doble, girado y gastado (le faltan trocitos)
func sello(w: float) -> void:
	var texto := Idioma.t("CONFIDENCIAL")
	var t := 32
	if compacta or ancho_de(texto, 32) > w * 0.42:
		t = 16
	var tam_sello := Vector2(ancho_de(texto, t) + 24, alto_de(t) + 12)
	# a la derecha del título, entre la franja y el texto (lo pisa poco)
	var centro := Vector2(w - MARGEN - 16 - tam_sello.x / 2.0, titulo_y + (12 if t == 32 else 4))
	var tinta := Color(ROJO, 0.78)
	draw_set_transform(centro, deg_to_rad(-8))
	var caja := Rect2(-tam_sello / 2.0, tam_sello)
	draw_rect(caja, tinta, false, 3.0)
	draw_rect(caja.grow(-5), tinta, false, 1.0)
	draw_string(fuente, Vector2(caja.position.x, fuente.get_ascent(t) / 2.0 - 1), texto, HORIZONTAL_ALIGNMENT_CENTER, caja.size.x, t, tinta)
	var r := RandomNumberGenerator.new()
	r.seed = hash(texto)
	for i in int(caja.size.x * 1.4):   # lo gastado: motitas del color del papel
		var punto := Vector2(r.randf_range(caja.position.x, caja.end.x - 2), r.randf_range(caja.position.y, caja.end.y - 2))
		draw_rect(Rect2(punto.floor(), Vector2(2, 1 + r.randi_range(0, 1))), Color(PAPEL, 0.85))
	draw_set_transform(Vector2.ZERO)


# Un clip de papel (de arriba abajo)
func clip(punto: Vector2) -> void:
	draw_rect(Rect2(punto, Vector2(10, 32)), Color("#9aa0a8"), false, 2.0)
	draw_rect(Rect2(punto + Vector2(3, 6), Vector2(4, 22)), Color("#c8ccd2"), false, 1.0)


# La nota a mano, en un pósit amarillo algo torcido
func posit() -> void:
	draw_set_transform(caja_posit.get_center(), deg_to_rad(1.5))
	var caja := Rect2(-caja_posit.size / 2.0, caja_posit.size)
	draw_rect(Rect2(caja.position + Vector2(3, 3), caja.size), Color(0, 0, 0, 0.3))
	draw_rect(caja, POSIT)
	draw_rect(Rect2(caja.position, Vector2(caja.size.x, 6)), Color("#e6d364"))
	for l in lineas_posit:
		draw_string(fuente, caja.position + l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, tam, BOLI)
	draw_set_transform(Vector2.ZERO)
