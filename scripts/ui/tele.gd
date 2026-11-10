# La emisión de Canal 8 de las noticias, solo la pantalla de la tele (sin el mueble): la que sale al usar la tele de un salón
# (ui/menus.gd, noticia) y la que va dentro del reproductor de VIDEOS.EXE (ui/reproductor.gd). La calle de noche delante
# del edificio de la noticia (el número 14, el centro comercial o la torre, de PixelLab, tools/tele.py), con la policía, y la
# reportera de Canal 8 (Marta Ruiz) con su micro, que mueve la boca al hablar y parpadea. Por código: "EN DIRECTO"
# parpadeando, el logo, el rótulo con su nombre (solo al empezar, como en la tele de verdad), el del titular y la cinta de
# abajo que corre. Debajo de la pantalla, los subtítulos: lo que dice la reportera, saliendo letra a letra (con un "bip"
# de voz), por trozos de dos líneas.
# Se usa así:  var tele := Tele.new()  ·  tele.poner(noticia)   (una de Historia.NOTICIAS)
# "escala" (antes de añadirla): lo que se agranda la pantalla de 288 × 164 (2 en la tele del salón, 1,5 en el reproductor).
# Con tele.continuo = true no hace falta pulsar para seguir: pasa sola de un trozo al siguiente, como un vídeo.
class_name Tele
extends Control

signal acabada   # con "continuo": al terminar de decir la última frase (una sola vez por emisión)

const LETRAS_POR_SEGUNDO := 30.0
# La reportera: 4 dibujos en fila (la boca cerrada, entreabierta y abierta, y los ojos cerrados)
const REPORTERA := preload("res://assets/ui/tele/reportera.png")
const CALLES := {"14": preload("res://assets/ui/tele/calle-14.png"), "torre": preload("res://assets/ui/tele/calle-torre.png"),
	"centro": preload("res://assets/ui/tele/calle-centro.png")}
const CONTORNO := Color("#1d1b2c")
const ROJO := Color("#c0392b")
const AZUL := Color("#1d2a6b")
const PANTALLA := Rect2(0, 0, 288, 164)   # la emisión, antes de agrandarla
const LETRA := 18   # el tamaño de los subtítulos con la escala de 1,5 (con la de 2, 24)
const ENTRE_TROZOS := 1.3     # con "continuo", lo que espera entre un trozo y el siguiente (y tras el último)
const NOMBRE_SEGUNDOS := 4.0   # lo que se ve el rótulo con el nombre de la reportera al empezar

var escala := 1.5
var noticia: Dictionary
var caja_texto := Rect2()   # la franja negra de los subtítulos, debajo de la pantalla (en el sitio de la tele)
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
var trozos: Array[String] = []   # lo que dice la reportera, en los trozos que caben en el cuadro
var trozo := 0                  # el que está diciendo
var boca := 0           # el dibujo de la reportera mientras habla (0, 1 o 2)
var continuo := false     # sigue solo de un trozo al siguiente, como un vídeo (sin esperar el clic); al acabar, avisa con "acabada"
var parada := false       # en pausa (el stop de VIDEOS.EXE): la imagen se queda quieta
var terminada := false    # ya ha dicho todo (con "continuo")
var espera := 0.0         # lo que lleva esperando entre trozos (con "continuo")
var reproducido := 0.0    # los segundos que lleva puesta la noticia (el contador del reproductor)
var nieve := 0.0        # el ruido de cambiar de canal, al poner una noticia


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# Monta la pantalla y los subtítulos con la escala elegida (al entrar en el árbol: así se puede poner "escala" antes)
func _ready() -> void:
	var tam := PANTALLA.size * escala
	var letra := roundi(12.0 * escala)
	pantalla = Control.new()
	pantalla.scale = Vector2(escala, escala)
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
	# los subtítulos, debajo de la pantalla: dos líneas, centradas
	texto = Label.new()
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.add_theme_color_override("font_color", Color("#f4f0dc"))
	texto.add_theme_constant_override("outline_size", 0)
	texto.add_theme_font_size_override("font_size", letra)
	texto.add_theme_constant_override("line_spacing", 2)
	var alto_linea := texto.get_line_height() + 2
	caja_texto = Rect2(0, tam.y, tam.x, alto_linea * 2 + 14)
	texto.position = caja_texto.position + Vector2(10, 6)
	texto.size = Vector2(tam.x - 20, alto_linea * 2 + 2)
	add_child(texto)
	custom_minimum_size = caja_texto.end


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
	trozos = partir(Historia.texto_de(n))
	empezar_trozo(0)
	en_antena = 0.0
	boca = 0
	nieve = 0.9   # (todo en rayas un momento; luego aparece la imagen con todo)
	terminada = false
	parada = false
	espera = 0.0
	reproducido = 0.0


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


# Las líneas que caben en el cuadro del texto
func lineas_que_caben() -> int:
	var alto := texto.get_line_height() + texto.get_theme_constant("line_spacing")
	return maxi(1, int((texto.size.y - texto.get_line_height()) / alto) + 1)   # (dos)


# Parte lo que dice la reportera en trozos que quepan en el cuadro, palabra a palabra (se mide con el mismo texto).
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


# ¿Queda otro trozo por decir? (la flechita del cuadro)
func hay_mas() -> bool:
	return not continuo and not hablando() and trozo + 1 < trozos.size()


func hablando() -> bool:
	return texto.visible_characters >= 0 and texto.visible_characters < texto.get_total_character_count()


# Cuánto lleva dicho de la emisión, de 0 a 1 (la barra de avance de VIDEOS.EXE)
func progreso() -> float:
	if trozos.is_empty():
		return 0.0
	if terminada:
		return 1.0
	var total := maxi(1, texto.get_total_character_count())
	return (trozo + clampf(letras / total, 0.0, 1.0)) / trozos.size()


# El play de VIDEOS.EXE: sigue donde estaba y, si ya había acabado, desde el principio
func reproducir() -> void:
	if noticia.is_empty():
		return
	if terminada:
		poner(noticia)
	parada = false


# La pausa de VIDEOS.EXE: se queda quieta donde estaba (play sigue)
func pausar() -> void:
	parada = true


# El botón de en medio del reproductor: pausa si está sonando y, si no, sigue (o empieza de nuevo si había acabado)
func alternar() -> void:
	if parada or terminada:
		reproducir()
	else:
		pausar()


# El stop de VIDEOS.EXE: vuelve al principio y se queda quieta
func parar() -> void:
	if noticia.is_empty():
		return
	poner(noticia)
	nieve = 0.0
	parada = true
	texto.visible_characters = 0
	queue_redraw()   # (la barra de avance de VIDEOS.EXE se pone al día al dibujar)


func _process(delta: float) -> void:
	if parada:
		return
	tiempo += delta
	if not terminada:
		reproducido += delta
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
			if continuo and not terminada and not noticia.is_empty():
				espera += delta
				if espera >= ENTRE_TROZOS:
					espera = 0.0
					if trozo + 1 < trozos.size():
						empezar_trozo(trozo + 1)
					else:
						terminada = true
						acabada.emit()
	var hay := not noticia.is_empty() and nieve <= 0.0   # (sin nada puesto o con rayas, la pantalla sin rótulos)
	canal.visible = hay
	titular.visible = hay
	cinta.visible = hay
	directo.visible = hay and fmod(tiempo, 1.0) < 0.6
	nombre.visible = hay and en_antena < NOMBRE_SEGUNDOS
	canal.position.x = PANTALLA.size.x - canal.size.x - 10
	cinta.position.x -= delta * 60.0
	if cinta.position.x < -cinta.size.x:
		cinta.position.x = PANTALLA.size.x
	pantalla.queue_redraw()
	queue_redraw()


# La boca para cada letra: abierta en la a, la o y la u; entreabierta en la e, la i y las demás letras que suenan;
# cerrada en los espacios, los signos y la m, la b y la p (que se dicen con los labios juntos)
func boca_de(letra: String) -> int:
	letra = letra.to_lower()
	if letra in ["a", "á", "o", "ó", "u", "ú"]:
		return 2
	if letra in ["m", "b", "p"] or not (letra >= "a" and letra <= "z" or letra in ["é", "í", "ñ", "ü"]):
		return 0
	return 1


# La franja negra de los subtítulos (la pantalla va encima, en su Control)
func _draw() -> void:
	draw_rect(caja_texto, Color("#0a0a0e"))
	# la flechita de que hay más (sin "continuo", que pasa solo), abajo a la derecha, dando saltitos
	if hay_mas():
		var o := caja_texto.end - Vector2(18, 10) + Vector2(0, 2 if fmod(tiempo, 0.8) < 0.4 else 0)
		draw_colored_polygon(PackedVector2Array([o + Vector2(-6, -6), o + Vector2(6, -6), o]), Color("#e8e8d0"))


# Lo de dentro de la pantalla: la calle, la reportera y los rótulos
func pintar_pantalla() -> void:
	var t := PANTALLA.size
	if noticia.is_empty():   # (sin nada puesto, la pantalla apagada)
		pantalla.draw_rect(Rect2(Vector2.ZERO, t), Color("#06070a"))
		return
	if nieve > 0.0:
		# solo rayas blancas, grises y negras (sin ningún rótulo: salen cuando acaba)
		var grises := [0.0, 0.0, 0.3, 0.55, 0.8, 1.0]
		var y := 0
		while y < int(t.y):
			var x := 0
			var alto := 2 + randi() % 4
			while x < int(t.x):
				var ancho := 10 + randi() % 60
				var g: float = grises[randi() % grises.size()]
				pantalla.draw_rect(Rect2(x, y, ancho, alto), Color(g, g, g))
				x += ancho
			y += alto
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
