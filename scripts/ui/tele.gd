# La tele vieja del programa Noticias (ui/ordenador.gd). Los dibujos son de PixelLab (tools/tele.py): el mueble de
# madera con su antena, sus ruedas y su altavoz, que va por encima y tiene la pantalla hueca; dentro, la calle de
# noche delante del edificio de la noticia (el número 14 o el centro comercial) con la policía, y la reportera de
# Canal 8 (Marta Ruiz) con su micro, que mueve la boca al hablar y parpadea. Por código: "EN DIRECTO" parpadeando, el
# logo, el rótulo con su nombre (solo al empezar, como en la tele de verdad), el del titular y la cinta de abajo que
# corre. Debajo, lo que dice la reportera, saliendo letra a letra (con un "bip" de voz).
# Se usa así:  var tele := Tele.new()  ·  tele.poner(noticia)   (una de Historia.NOTICIAS)
class_name Tele
extends Control

const LETRAS_POR_SEGUNDO := 30.0
const MUEBLE := preload("res://assets/ui/tele/mueble.png")
# La reportera: 4 dibujos en fila (la boca cerrada, entreabierta y abierta, y los ojos cerrados)
const REPORTERA := preload("res://assets/ui/tele/reportera.png")
const CALLES := {"14": preload("res://assets/ui/tele/calle-14.png"),
	"centro": preload("res://assets/ui/tele/calle-centro.png")}
const CONTORNO := Color("#1d1b2c")
const ROJO := Color("#c0392b")
const AZUL := Color("#1d2a6b")
const MUEBLE_EN := Vector2(24, 0)   # centrado encima del cuadro del texto
const PANTALLA := Rect2(46, 54, 288, 164)   # el hueco del mueble (lo dice tools/tele.py), más MUEBLE_EN
const CAJA_TEXTO := Rect2(0, 262, 448, 142)   # cabe la noticia más larga (unas 300 letras)
const NOMBRE_SEGUNDOS := 4.0   # lo que se ve el rótulo con el nombre de la reportera al empezar

var noticia: Dictionary
var pantalla: Control
var directo: Label
var canal: Label
var nombre: Label
var titular: Label
var cinta: Label
var texto: Label
var tiempo := 0.0
var en_antena := 0.0    # lo que lleva la noticia puesta (para el rótulo del nombre)
var letras := 0.0
var boca := 0           # el dibujo de la reportera mientras habla (0, 1 o 2)
var nieve := 0.0        # el ruido de cambiar de canal, al poner una noticia


func _init() -> void:
	custom_minimum_size = CAJA_TEXTO.end
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla = Control.new()
	pantalla.position = PANTALLA.position
	pantalla.size = PANTALLA.size
	pantalla.clip_contents = true
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.draw.connect(pintar_pantalla)
	add_child(pantalla)
	directo = rotulo(Idioma.t("EN DIRECTO"), Color.WHITE, Vector2(24, 4))
	canal = rotulo(Idioma.t("CANAL 8"), AZUL, Vector2(PANTALLA.size.x - 76, 6))
	nombre = rotulo("%s · %s" % [Historia.REPORTERA.to_upper(), Historia.canal().to_upper()], Color("#e8e8d0"),
		Vector2(6, 105))
	titular = rotulo("", Color.WHITE, Vector2(6, 126))
	cinta = rotulo("", Color("#1b1712"), Vector2(PANTALLA.size.x, 146))
	# el mueble, por encima de la emisión: su hueco tiene las esquinas redondeadas de una tele vieja
	var marco := TextureRect.new()
	marco.texture = MUEBLE
	marco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marco.position = MUEBLE_EN
	marco.size = MUEBLE.get_size() * 2.0
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marco)
	texto = Label.new()
	texto.position = CAJA_TEXTO.position + Vector2(12, 8)
	texto.size = CAJA_TEXTO.size - Vector2(24, 16)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_color_override("font_color", Color("#e8e8d0"))
	texto.add_theme_constant_override("outline_size", 0)
	texto.add_theme_font_size_override("font_size", 16)
	texto.add_theme_constant_override("line_spacing", -4)
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
	titular.text = Historia.titular_de(n)
	cinta.text = Idioma.t("ÚLTIMA HORA  ·  %s: «LA SITUACIÓN ESTÁ CONTROLADA»  ·  NO SE ACERQUEN AL EDIFICIO  ·  ") % Historia.EMPRESA.to_upper()
	cinta.position.x = PANTALLA.size.x
	texto.text = Historia.texto_de(n)
	texto.visible_characters = 0
	letras = 0.0
	en_antena = 0.0
	boca = 0
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
	directo.visible = fmod(tiempo, 1.0) < 0.6
	nombre.visible = en_antena < NOMBRE_SEGUNDOS
	canal.position.x = PANTALLA.size.x - canal.size.x - 10
	cinta.position.x -= delta * 60.0
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


# El cuadro de lo que dice la reportera (el mueble es una imagen, encima de la pantalla)
func _draw() -> void:
	draw_rect(CAJA_TEXTO, Color("#10141c"))
	draw_rect(CAJA_TEXTO, CONTORNO, false, 3.0)


# Lo de dentro de la pantalla: la calle, la reportera y los rótulos
func pintar_pantalla() -> void:
	var t := PANTALLA.size
	if nieve > 0.0:
		pantalla.draw_rect(Rect2(Vector2.ZERO, t), Color("#202020"))
		for i in 260:
			var g := randf()
			pantalla.draw_rect(Rect2(randi() % int(t.x), randi() % int(t.y), 8, 4), Color(g, g, g))
		return
	var calle: Texture2D = CALLES.get(noticia.get("sitio", "14"), CALLES["14"])
	pantalla.draw_texture_rect(calle, Rect2(Vector2.ZERO, t), false)
	# la reportera, a la izquierda; la cintura queda tapada por los rótulos
	var parpadeo := fmod(tiempo, 3.2) < 0.12
	var dibujo := 3 if parpadeo else boca
	var w := REPORTERA.get_width() / 4
	var h := REPORTERA.get_height()
	pantalla.draw_texture_rect_region(REPORTERA, Rect2(30, 128 - h * 2, w * 2, h * 2), Rect2(dibujo * w, 0, w, h))
	# EN DIRECTO y el logo
	if directo.visible:
		Formas.disco(pantalla, Vector2(14, 14), 5, ROJO)
	pantalla.draw_rect(Rect2(canal.position.x - 6, 6, canal.size.x + 12, 22), Color("#f4efe0"))
	# los rótulos de abajo: el nombre (al empezar), el titular y la cinta que corre
	if nombre.visible:
		pantalla.draw_rect(Rect2(0, 104, t.x, 20), AZUL)
	pantalla.draw_rect(Rect2(0, 124, t.x, 22), ROJO)
	pantalla.draw_rect(Rect2(0, 146, t.x, 18), Color("#e8b923"))
	# el brillo del cristal
	pantalla.draw_rect(Rect2(10, 4, t.x * 0.4, 2), Color(1, 1, 1, 0.08))
