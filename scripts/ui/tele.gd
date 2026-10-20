# La tele vieja del programa Noticias (ui/ordenador.gd), dibujada con código, sin sprites: el mueble de madera
# con su antena, sus botones y su altavoz; en la pantalla, el estudio de Canal 8 con la reportera (Marta Ruiz,
# hecha con rectángulos), "EN DIRECTO" parpadeando, el logo, el rótulo con el titular y la cinta de abajo que
# corre. Debajo, lo que dice la reportera, saliendo letra a letra (con un "bip" de voz).
# Se usa así:  var tele := Tele.new()  ·  tele.poner(noticia)   (una de Historia.NOTICIAS)
class_name Tele
extends Control

const LETRAS_POR_SEGUNDO := 30.0
const MADERA := Color("#7a5434")
const MADERA_OSCURA := Color("#563a24")
const CONTORNO := Color("#1d1b2c")
const PIEL := Color("#f1c27d")
const PELO := Color("#4a2a1a")
const CHAQUETA := Color("#2f6b8a")
const ROJO := Color("#c0392b")
const PANTALLA := Rect2(30, 48, 304, 170)   # dentro del mueble
const CAJA_TEXTO := Rect2(8, 254, 424, 140)

var noticia: Dictionary
var pantalla: Control
var directo: Label
var titular: Label
var cinta: Label
var texto: Label
var tiempo := 0.0
var letras := 0.0
var nieve := 0.0        # el ruido de cambiar de canal, al poner una noticia


func _init() -> void:
	custom_minimum_size = Vector2(440, CAJA_TEXTO.end.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla = Control.new()
	pantalla.position = PANTALLA.position
	pantalla.size = PANTALLA.size
	pantalla.clip_contents = true
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.draw.connect(pintar_pantalla)
	add_child(pantalla)
	directo = rotulo("EN DIRECTO", Color.WHITE, Vector2(24, 4))
	rotulo("CANAL 8", Color("#1d2a6b"), Vector2(PANTALLA.size.x - 70, 6))
	rotulo("%s · %s" % [Historia.REPORTERA.to_upper(), Historia.CANAL.to_upper()], Color("#e8e8d0"), Vector2(6, 111))
	titular = rotulo("", Color.WHITE, Vector2(6, 132))
	cinta = rotulo("", Color("#1b1712"), Vector2(PANTALLA.size.x, 152))
	texto = Label.new()
	texto.position = CAJA_TEXTO.position + Vector2(12, 8)
	texto.size = CAJA_TEXTO.size - Vector2(24, 16)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_color_override("font_color", Color("#e8e8d0"))
	texto.add_theme_constant_override("outline_size", 0)
	texto.add_theme_font_size_override("font_size", 16)
	add_child(texto)


func rotulo(t: String, color: Color, donde: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.position = donde
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_font_size_override("font_size", 16)
	pantalla.add_child(l)
	return l


# Pone una noticia: la pantalla hace "nieve" un momento y la reportera empieza a hablar desde el principio
func poner(n: Dictionary) -> void:
	noticia = n
	titular.text = n.titular
	cinta.text = "ÚLTIMA HORA  ·  %s: «LA SITUACIÓN ESTÁ CONTROLADA»  ·  NO SE ACERQUEN AL EDIFICIO  ·  " % Historia.EMPRESA.to_upper()
	cinta.position.x = PANTALLA.size.x
	texto.text = n.texto
	texto.visible_characters = 0
	letras = 0.0
	nieve = 0.3


# Si está hablando, termina de golpe; si ya había terminado, vuelve a empezar
func saltar() -> void:
	if hablando():
		letras = texto.get_total_character_count()
		texto.visible_characters = -1
	elif not noticia.is_empty():
		poner(noticia)


func hablando() -> bool:
	return texto.visible_characters >= 0 and texto.visible_characters < texto.get_total_character_count()


func _process(delta: float) -> void:
	tiempo += delta
	if nieve > 0.0:
		nieve -= delta
	elif hablando():
		letras += delta * LETRAS_POR_SEGUNDO
		var antes := texto.visible_characters
		texto.visible_characters = mini(int(letras), texto.get_total_character_count())
		if texto.visible_characters > antes and texto.text[texto.visible_characters - 1] != " ":
			Sonido.tocar("voz")
	directo.visible = fmod(tiempo, 1.0) < 0.6
	cinta.position.x -= delta * 60.0
	if cinta.position.x < -cinta.size.x:
		cinta.position.x = PANTALLA.size.x
	pantalla.queue_redraw()


# El mueble: la antena, la madera con su borde, el marco de la pantalla, los botones, el altavoz y las patas.
# Debajo, la caja de lo que dice la reportera
func _draw() -> void:
	draw_line(Vector2(220, 26), Vector2(170, 2), Color("#8c8c96"), 3.0)
	draw_line(Vector2(220, 26), Vector2(274, 6), Color("#8c8c96"), 3.0)
	draw_rect(Rect2(206, 18, 28, 10), CONTORNO)
	for x in [40, 372]:
		draw_rect(Rect2(x, 240, 28, 8), CONTORNO)
	var mueble := Rect2(8, 26, 424, 214)
	draw_rect(mueble, MADERA)
	draw_rect(Rect2(mueble.position, Vector2(mueble.size.x, 6)), MADERA.lightened(0.15))
	draw_rect(Rect2(mueble.position.x, mueble.end.y - 10, mueble.size.x, 10), MADERA_OSCURA)
	draw_rect(mueble, CONTORNO, false, 3.0)
	draw_rect(PANTALLA.grow(8), Color("#2a2a2e"))
	draw_rect(PANTALLA.grow(8), CONTORNO, false, 2.0)
	for y in [80, 124]:
		draw_circle(Vector2(386, y), 14, CONTORNO)
		draw_circle(Vector2(386, y), 11, Color("#dcc896"))
		draw_line(Vector2(386, y), Vector2(386, y) + Vector2.from_angle(y * 0.7) * 9, CONTORNO, 2.0)
	for y in range(154, 224, 6):
		draw_rect(Rect2(362, y, 48, 2), MADERA_OSCURA)
	draw_rect(CAJA_TEXTO, Color("#10141c"))
	draw_rect(CAJA_TEXTO, CONTORNO, false, 3.0)


# Lo de dentro de la pantalla: el estudio, la reportera y los rótulos
func pintar_pantalla() -> void:
	var t := PANTALLA.size
	if nieve > 0.0:
		for i in 260:
			var g := randf()
			pantalla.draw_rect(Rect2(randi() % int(t.x), randi() % int(t.y), 8, 4), Color(g, g, g))
		return
	pantalla.draw_rect(Rect2(Vector2.ZERO, t), Color("#1b2a4a"))
	# la ciudad de noche, detrás (unos edificios con ventanas encendidas)
	var azotea := [60, 40, 74, 52, 34, 66, 48]
	for i in azotea.size():
		var x := 140 + i * 24
		pantalla.draw_rect(Rect2(x, azotea[i], 22, 112 - azotea[i]), Color("#24385f"))
		for v in range(azotea[i] + 6, 108, 10):
			if (x + v) % 3 != 0:
				pantalla.draw_rect(Rect2(x + 5, v, 4, 4), Color("#e8c45a", 0.8))
	# la reportera
	var cx := 92.0
	pantalla.draw_circle(Vector2(cx, 62), 25, PELO)
	pantalla.draw_rect(Rect2(cx - 25, 62, 50, 40), PELO)
	pantalla.draw_rect(Rect2(cx - 7, 86, 14, 16), PIEL.darkened(0.1))
	pantalla.draw_rect(Rect2(cx - 17, 50, 34, 40), PIEL)
	pantalla.draw_rect(Rect2(cx - 19, 44, 38, 10), PELO)
	pantalla.draw_rect(Rect2(cx - 19, 50, 6, 18), PELO)
	var parpadeo := fmod(tiempo, 3.2) < 0.12
	for x in [cx - 10, cx + 6]:
		pantalla.draw_rect(Rect2(x, 66 if not parpadeo else 68, 4, 4 if not parpadeo else 1), CONTORNO)
	var boca := 5 if hablando() and nieve <= 0.0 and int(tiempo * 9.0) % 2 == 0 else 2
	pantalla.draw_rect(Rect2(cx - 5, 80, 10, boca), Color("#7a2a2a"))
	pantalla.draw_colored_polygon(PackedVector2Array([Vector2(cx - 50, t.y), Vector2(cx - 38, 102),
		Vector2(cx + 38, 102), Vector2(cx + 50, t.y)]), CHAQUETA)
	pantalla.draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, 102), Vector2(cx + 10, 102), Vector2(cx, 118)]), Color("#e8e8e8"))
	# el micro de Canal 8
	pantalla.draw_rect(Rect2(cx + 25, 96, 6, 24), Color("#8c8c96"))
	pantalla.draw_circle(Vector2(cx + 28, 94), 8, Color("#222228"))
	pantalla.draw_rect(Rect2(cx + 21, 106, 14, 10), PIEL)
	# EN DIRECTO y el logo
	if directo.visible:
		pantalla.draw_circle(Vector2(14, 14), 5, ROJO)
	pantalla.draw_rect(Rect2(t.x - 76, 6, 68, 22), Color("#f4efe0"))
	# los rótulos de abajo: el nombre, el titular y la cinta que corre
	pantalla.draw_rect(Rect2(0, 110, t.x, 20), Color("#1d2a6b"))
	pantalla.draw_rect(Rect2(0, 130, t.x, 22), ROJO)
	pantalla.draw_rect(Rect2(0, 152, t.x, 18), Color("#e8b923"))
	# el brillo del cristal
	pantalla.draw_rect(Rect2(6, 4, t.x * 0.4, 3), Color(1, 1, 1, 0.08))
