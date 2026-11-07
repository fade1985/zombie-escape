# La tele vieja del programa Noticias (ui/ordenador.gd). Los dibujos son de PixelLab (tools/tele.py): el mueble de
# madera con su antena, sus ruedas y su altavoz, que va por encima y tiene la pantalla hueca; dentro, la calle de
# noche delante del edificio de la noticia (el número 14 o el centro comercial) con la policía, y la reportera de
# Canal 8 (Marta Ruiz) con su micro, que mueve la boca al hablar y parpadea. Por código: "EN DIRECTO" parpadeando, el
# logo, el rótulo con su nombre (solo al empezar, como en la tele de verdad), el del titular y la cinta de abajo que
# corre. Desde el 8 nov la tele va a ×3 (cada píxel del dibujo, 3 del juego; antes a ×2, con lo que dice la reportera
# en un cuadro negro debajo) y lo que dice la reportera sale DENTRO de la pantalla, como subtítulos: en una franja
# oscura encima de los rótulos, letra a letra (con un "bip" de voz) y por trozos de dos líneas, que pasan solos al
# acabar cada uno (pulsando, se adelanta), con "1/4" en la esquina. Al ponerla por primera vez se enciende como una
# tele vieja (una raya que se abre) y, al cambiar de emisión, hace "nieve" con su siseo.
# Se usa así:  var tele := Tele.new()  ·  tele.poner(noticia)   (una de Historia.NOTICIAS)
class_name Tele
extends Control

const LETRAS_POR_SEGUNDO := 30.0
const PAUSA := 2.5   # los segundos que se queda un trozo ya dicho antes de pasar solo al siguiente
const MUEBLE := preload("res://assets/ui/tele/mueble.png")
# La reportera: 4 dibujos en fila (la boca cerrada, entreabierta y abierta, y los ojos cerrados)
const REPORTERA := preload("res://assets/ui/tele/reportera.png")
const CALLES := {"14": preload("res://assets/ui/tele/calle-14.png"), "torre": preload("res://assets/ui/tele/calle-torre.png"),
	"centro": preload("res://assets/ui/tele/calle-centro.png")}
const ROJO := Color("#c0392b")
const AZUL := Color("#1d2a6b")
const ESCALA := 3.0   # cada píxel del dibujo del mueble, 3 del juego
const PANTALLA := Rect2(33, 81, 432, 246)   # el hueco del mueble (lo dice tools/tele.py), a ×3
const LETRA := 18   # el tamaño de lo que dice la reportera (el dueño lo prefiere a 18)
const LINEAS := 2   # las líneas de cada trozo de subtítulos
const SUBTITULOS_HASTA := 172.0   # dónde acaba por abajo la franja de los subtítulos (encima del rótulo del nombre)
const AMARILLO := Color("#f6e27a")
const NOMBRE_SEGUNDOS := 4.0   # lo que se ve el rótulo con el nombre de la reportera al empezar
const ENCENDER := 0.5   # lo que tarda en encenderse

var noticia: Dictionary
var pantalla: Control
var directo: Label
var canal: Label
var nombre: Label
var titular: Label
var cinta: Label
var texto: Label        # los subtítulos (lo que dice la reportera)
var contador: Label     # "1/4": el trozo que va diciendo
var franja := Rect2()   # el fondo oscuro de los subtítulos
var tiempo := 0.0
var en_antena := 0.0    # lo que lleva la noticia puesta (para el rótulo del nombre)
var letras := 0.0
var espera := 0.0       # lo que lleva un trozo ya dicho (al llegar a PAUSA, pasa al siguiente)
var trozos: Array[String] = []   # lo que dice la reportera, en los trozos que caben en la franja
var trozo := 0                  # el que está diciendo
var boca := 0           # el dibujo de la reportera mientras habla (0, 1 o 2)
var nieve := 0.0        # el ruido de cambiar de canal, al poner una noticia
var encendido := 0.0    # lo que le queda para acabar de encenderse


func _init() -> void:
	custom_minimum_size = MUEBLE.get_size() * ESCALA
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla = Control.new()
	pantalla.position = PANTALLA.position
	pantalla.size = PANTALLA.size
	pantalla.clip_contents = true
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.draw.connect(pintar_pantalla)
	add_child(pantalla)
	directo = rotulo(Idioma.t("EN DIRECTO"), Color.WHITE, Vector2(34, 10))
	canal = rotulo(Idioma.t("CANAL 8"), AZUL, Vector2(PANTALLA.size.x - 100, 11))
	nombre = rotulo("%s · %s" % [Historia.REPORTERA.to_upper(), Historia.canal().to_upper()], Color("#e8e8d0"),
		Vector2(9, 175))
	titular = rotulo("", Color.WHITE, Vector2(9, 200))
	cinta = rotulo("", Color("#1b1712"), Vector2(PANTALLA.size.x, 224))
	texto = Label.new()
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_color_override("font_color", AMARILLO)
	texto.add_theme_constant_override("outline_size", 0)
	texto.add_theme_font_size_override("font_size", LETRA)
	texto.add_theme_constant_override("line_spacing", 4)
	pantalla.add_child(texto)
	contador = rotulo("", Color("#b8b8a0"), Vector2.ZERO)
	contador.add_theme_font_size_override("font_size", 16)
	# el mueble, por encima de la emisión: su hueco tiene las esquinas redondeadas de una tele vieja
	var marco := TextureRect.new()
	marco.texture = MUEBLE
	marco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marco.size = MUEBLE.get_size() * ESCALA
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marco)


func rotulo(t: String, color: Color, donde: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.position = donde
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_font_size_override("font_size", 18)   # (finos, como los de la tele de verdad: el sitio es para la imagen)
	pantalla.add_child(l)
	return l


# La franja de los subtítulos: abajo, encima del rótulo del nombre, con el alto justo de sus LINEAS; a la derecha
# deja sitio para el "1/4"
func colocar_subtitulos() -> void:
	var alto := texto.get_line_height() * LINEAS + texto.get_theme_constant("line_spacing") * (LINEAS - 1)
	franja = Rect2(0, SUBTITULOS_HASTA - alto - 8, PANTALLA.size.x, alto + 8)
	texto.position = franja.position + Vector2(12, 4)
	texto.size = Vector2(franja.size.x - 64, alto)
	contador.position = Vector2(franja.end.x - 46, franja.position.y + 4)


# Pone una noticia: la primera vez la tele se enciende; luego, al cambiar, hace "nieve" un momento. La reportera
# empieza a hablar desde el principio
func poner(n: Dictionary) -> void:
	if noticia.is_empty():
		encendido = ENCENDER
		Sonido.tocar("tele_encender")
	else:
		nieve = 0.3
		Sonido.tocar("tele_ruido")
	noticia = n
	titular.text = Historia.titular_de(n)
	cinta.text = Idioma.t("ÚLTIMA HORA  ·  %s: «LA SITUACIÓN ESTÁ CONTROLADA»  ·  NO SE ACERQUEN AL EDIFICIO  ·  ") % Historia.EMPRESA.to_upper()
	cinta.position.x = PANTALLA.size.x
	colocar_subtitulos()
	trozos = partir(Historia.texto_de(n))
	empezar_trozo(0)
	en_antena = 0.0
	boca = 0


# Si está hablando, termina el trozo de golpe; si ya lo había terminado, sigue con el siguiente y, después del
# último, vuelve a empezar
func saltar() -> void:
	if hablando():
		letras = texto.get_total_character_count()
		texto.visible_characters = -1
	elif trozo + 1 < trozos.size():
		empezar_trozo(trozo + 1)
	elif not noticia.is_empty():
		poner(noticia)


func empezar_trozo(i: int) -> void:
	trozo = i
	texto.text = trozos[i] if i < trozos.size() else ""
	texto.visible_characters = 0
	letras = 0.0
	espera = 0.0
	contador.text = "%d/%d" % [i + 1, trozos.size()] if trozos.size() > 1 else ""


# Las líneas que caben en la franja de los subtítulos
func lineas_que_caben() -> int:
	return LINEAS


# Parte lo que dice la reportera en trozos que quepan en la franja, palabra a palabra (se mide con el mismo texto).
# En chino no hay espacios: allí cada letra cuenta como una palabra (PALABRA)
const PALABRA := "[\\x{2E80}-\\x{9FFF}\\x{FF00}-\\x{FFEF}]\\s*|[^\\s\\x{2E80}-\\x{9FFF}\\x{FF00}-\\x{FFEF}]+\\s*|\\s+"
func partir(todo: String) -> Array[String]:
	var cuantas := lineas_que_caben()
	var lista: Array[String] = []
	var actual := ""
	texto.visible_characters = -1   # (se mide con todas las letras a la vista)
	for m in RegEx.create_from_string(PALABRA).search_all(todo):
		var prueba: String = actual + m.get_string()
		texto.text = prueba.strip_edges()
		if actual.strip_edges() != "" and texto.get_line_count() > cuantas:
			lista.append(actual.strip_edges())
			actual = m.get_string()
		else:
			actual = prueba
	if actual.strip_edges() != "":
		lista.append(actual.strip_edges())
	return lista


# ¿Queda otro trozo por decir?
func hay_mas() -> bool:
	return not hablando() and trozo + 1 < trozos.size()


func hablando() -> bool:
	return texto.visible_characters >= 0 and texto.visible_characters < texto.get_total_character_count()


func _process(delta: float) -> void:
	tiempo += delta
	if encendido > 0.0:
		encendido -= delta
	elif nieve > 0.0:
		nieve -= delta
	else:
		en_antena += delta
		if hablando():
			letras += delta * LETRAS_POR_SEGUNDO
			var antes := texto.visible_characters
			texto.visible_characters = mini(int(letras), texto.get_total_character_count())
			if texto.visible_characters > antes:
				var letra := texto.text[texto.visible_characters - 1]
				if letra != " ":
					Sonido.tocar("voz")
				boca = boca_de(letra)
		else:
			boca = 0
			# acabado el trozo, al rato pasa solo al siguiente (el último se queda)
			if hay_mas():
				espera += delta
				if espera >= PAUSA:
					empezar_trozo(trozo + 1)
	# con la pantalla en negro o con nieve, sin rótulos
	var se_ve := encendido <= 0.0 and nieve <= 0.0
	for l in [canal, titular, cinta, texto, contador]:
		l.visible = se_ve
	directo.visible = se_ve and fmod(tiempo, 1.0) < 0.6
	nombre.visible = se_ve and en_antena < NOMBRE_SEGUNDOS
	canal.position.x = PANTALLA.size.x - canal.size.x - 14
	cinta.position.x -= delta * 90.0
	if cinta.position.x < -cinta.size.x:
		cinta.position.x = PANTALLA.size.x
	pantalla.queue_redraw()


# La boca para cada letra: abierta en la a, la o y la u; entreabierta en la e, la i y las demás letras que suenan;
# cerrada en los espacios, los signos y la m, la b y la p (que se dicen con los labios juntos)
func boca_de(letra: String) -> int:
	letra = letra.to_lower()
	if letra in ["a", "á", "o", "ó", "u", "ú"]:
		return 2
	if letra in ["m", "b", "p"] or not (letra >= "a" and letra <= "z" or letra in ["é", "í", "ñ", "ü"]):
		return 0
	return 1


# Lo de dentro de la pantalla: la calle, la reportera, los rótulos y la franja de los subtítulos (el mueble es una
# imagen, encima)
func pintar_pantalla() -> void:
	var t := PANTALLA.size
	if nieve > 0.0:
		pantalla.draw_rect(Rect2(Vector2.ZERO, t), Color("#202020"))
		for i in 400:
			var g := randf()
			pantalla.draw_rect(Rect2(randi() % int(t.x), randi() % int(t.y), 12, 6), Color(g, g, g))
		return
	# encenderse: primero una raya blanca que se abre a lo ancho y luego la imagen, que se abre a lo alto
	var p := 1.0 - encendido / ENCENDER if encendido > 0.0 else 1.0
	if p < 0.4:
		pantalla.draw_rect(Rect2(Vector2.ZERO, t), Color.BLACK)
		var ancho := t.x * p / 0.4
		pantalla.draw_rect(Rect2((t.x - ancho) / 2.0, t.y / 2.0 - 2, ancho, 4), Color(1, 1, 1, 0.9))
		return
	var calle: Texture2D = CALLES.get(noticia.get("sitio", "14"), CALLES["14"])
	pantalla.draw_texture_rect(calle, Rect2(Vector2.ZERO, t), false)
	# la reportera, a la izquierda; la cintura queda tapada por los rótulos
	var parpadeo := fmod(tiempo, 3.2) < 0.12
	var dibujo := 3 if parpadeo else boca
	var w := REPORTERA.get_width() / 4
	var h := REPORTERA.get_height()
	pantalla.draw_texture_rect_region(REPORTERA, Rect2(45, 200 - h * ESCALA, w * ESCALA, h * ESCALA), Rect2(dibujo * w, 0, w, h))
	# EN DIRECTO y el logo
	if directo.visible:
		Formas.disco(pantalla, Vector2(21, 21), 7, ROJO)
	if canal.visible:
		pantalla.draw_rect(Rect2(canal.position.x - 8, 9, canal.size.x + 16, 28), Color("#f4efe0"))
	# los subtítulos, sobre una franja oscura (solo con algo escrito)
	if texto.visible and texto.visible_characters != 0 and texto.text != "":
		pantalla.draw_rect(franja, Color(0, 0, 0, 0.6))
	# los rótulos de abajo: el nombre (al empezar), el titular y la cinta que corre
	if nombre.visible:
		pantalla.draw_rect(Rect2(0, 174, t.x, 24), AZUL)
	pantalla.draw_rect(Rect2(0, 198, t.x, 26), ROJO)
	pantalla.draw_rect(Rect2(0, 224, t.x, 22), Color("#e8b923"))
	# el brillo del cristal
	pantalla.draw_rect(Rect2(15, 6, t.x * 0.4, 3), Color(1, 1, 1, 0.08))
	# al acabar de encenderse, la imagen se abre desde el centro (negro arriba y abajo) con un fogonazo blanco
	if p < 1.0:
		var alto := t.y * (p - 0.4) / 0.6
		var arriba := (t.y - alto) / 2.0
		pantalla.draw_rect(Rect2(0, 0, t.x, arriba), Color.BLACK)
		pantalla.draw_rect(Rect2(0, arriba + alto, t.x, arriba + 1), Color.BLACK)
		pantalla.draw_rect(Rect2(0, arriba, t.x, alto), Color(1, 1, 1, (1.0 - p) * 0.8))
